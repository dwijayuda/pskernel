import assert from 'node:assert/strict';
import { test } from 'node:test';
import { SourceMap } from 'node:module';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { createJsDeclarationLineage } from './js-declaration-lineage.mjs';
import { createDirectJsSourceMap, verifyDirectJsSourceMap } from './js-source-map.mjs';
import { encodeSourceMapVlq, encodeSourceMapMappings } from './source-map-encoding.mjs';
import { createDeclarationOriginGraph } from './declaration-origins.mjs';
import { sourcePreparationRecord, createSourcePreparationArtifacts } from './source-preparation-origins.mjs';
import { fixture } from './js-origin-test-fixture.mjs';

test('ECMA-426 VLQ limits and cross-line delta state match specification vectors and Node consumer', () => {
  for (const [value, encoded] of [[0, 'A'], [1, 'C'], [-1, 'D'], [17, 'iB'], [-10, 'V'],
      [2147483647, '+/////D'], [-2147483647, '//////D'], [-2147483648, 'B']]) {
    assert.equal(encodeSourceMapVlq(value), encoded);
  }
  for (const value of [-0, 0.5, NaN, 2147483648, -2147483649]) assert.throws(() => encodeSourceMapVlq(value), /VLQ_RANGE/);
  const mappings = encodeSourceMapMappings([[0, 0], [1, 2, 1, 3, 4], [1, 7], [3, 0, 0, 1, 1]]);
  assert.equal(mappings, 'A;ECGI,K;;ADFH;');
  const consumer = new SourceMap({ version: 3, sources: ['zero', 'one'], names: [], mappings });
  assert.equal(consumer.findEntry(1, 2).originalSource, 'one');
  assert.equal(consumer.findEntry(1, 2).originalLine, 3);
  assert.equal(consumer.findEntry(1, 2).originalColumn, 4);
  assert.equal(consumer.findEntry(1, 7).originalSource, undefined);
  assert.equal(consumer.findEntry(2, 0).originalSource, undefined);
  assert.equal(consumer.findEntry(3, 0).originalSource, 'zero');
  assert.equal(consumer.findEntry(3, 0).originalLine, 1);
  assert.equal(consumer.findEntry(3, 0).originalColumn, 1);
  assert.throws(() => encodeSourceMapMappings([[1000000000, 0]], { maxBytes: 10 }), /RESOURCE/);
  assert.throws(() => encodeSourceMapMappings([[0, 1], [0, 1]]), /ORDER/);
  assert.throws(() => encodeSourceMapMappings([[0, 0, 1]]), /SEGMENT/);
});

function productFixture(original = false, uniform = false) {
  const f = fixture({ uniform }), lineage = createJsDeclarationLineage(f).lineage;
  let preparationOrigins = null, sourceSnapshot = null, originalText = null;
  if (original) {
    originalText = '\ufeffimport Lib\r\n' + f.sources[0].replace('\n', '\r\nimport Hidden\r\n') + '  \r\n';
    const records = [sourcePreparationRecord('src/with space/🔥.lean', originalText, 0)];
    assert.equal(records[0].prepared, f.sources[0]);
    sourceSnapshot = canonicalArtifact({ sourceKind: 'lean', sources: f.sources }, 'source-snapshot', 'psc-source-snapshot/1');
    const captured = createSourcePreparationArtifacts(records, sourceSnapshot);
    preparationOrigins = captured.map;
    for (const item of [sourceSnapshot, preparationOrigins, ...captured.artifacts])
      f.artifacts.set(artifactKey(item.identity), item.bytes);
  }
  f.artifacts.set(artifactKey(lineage.identity), lineage.bytes);
  const product = createDirectJsSourceMap({ lineage, resolveArtifact: f.resolveArtifact,
    preparationOrigins, sourceSnapshot, file: 'out.js' });
  const policy = { resolveArtifact: async id => f.resolveArtifact(id), expectedLineageId: lineage.identity,
    expectedJavaScriptId: JSON.parse(f.positions.map.bytes).javascriptId, expectedFile: 'out.js',
    expectedPreparationOriginsId: preparationOrigins?.identity ?? null, expectedSourceSnapshotId: sourceSnapshot?.identity ?? null };
  return { ...f, lineage, product, policy, preparationOrigins, sourceSnapshot, originalText };
}

test('standalone direct maps retain executable bytes and leave prefix, helper lines and terminators unmapped', async () => {
  const f = productFixture(), value = JSON.parse(f.product.sourceMap.bytes), consumer = new SourceMap(value);
  assert.equal(value.version, 3);
  assert.equal(value.file, 'out.js');
  assert.deepEqual(value.sourcesContent, f.sources);
  assert.equal(value.x_psc_expressionOrigins, false);
  assert.equal(consumer.findEntry(0, 0).originalSource, undefined);
  assert.equal(consumer.findEntry(1, 0).originalLine, 0);
  assert.equal(consumer.findEntry(1, 20).originalLine, 0);
  const firstLineEnd = f.javaScript.split('\n')[1].length;
  assert.equal(consumer.findEntry(1, firstLineEnd - 1).originalLine, 0);
  assert.equal(consumer.findEntry(1, firstLineEnd).originalSource, undefined);
  assert.equal(consumer.findEntry(2, 2).originalSource, undefined);
  assert.equal(consumer.findEntry(3, 0).originalSource, undefined);
  assert.equal(consumer.findEntry(4, 0).originalLine, 1);
  assert.equal(consumer.findEntry(5, 0).originalSource, undefined);
  const recipe = JSON.parse(f.product.recipe.bytes);
  assert.equal(recipe.javascriptId.digest, artifactId(Buffer.from(f.javaScript), 'javascript-output', 'psc-direct-javascript/es2022').digest);
  assert.equal(recipe.linking, 'standalone-map-executable-unchanged');
  const replay = await verifyDirectJsSourceMap(f.product, f.policy);
  assert.equal(replay.declarationMapReconstructed, true);
  assert.equal(replay.semanticPreservationProved, false);
});

test('original byte anchors survive BOM, CRLF, removed import gaps and escaped display URLs', async () => {
  const f = productFixture(true), value = JSON.parse(f.product.sourceMap.bytes), consumer = new SourceMap(value);
  assert.deepEqual(value.sourcesContent, [f.originalText]);
  assert.equal(value.sources[0], 'psc-source/0/file-src%2Fwith%20space%2F%F0%9F%94%A5.lean');
  assert.equal(consumer.findEntry(1, 0).originalLine, 1);
  assert.equal(consumer.findEntry(1, 0).originalColumn, 0);
  assert.equal(consumer.findEntry(4, 0).originalLine, 3);
  assert.equal(consumer.findEntry(4, 0).originalColumn, 0);
  assert.equal((await verifyDirectJsSourceMap(f.product, f.policy)).declarationMapReconstructed, true);
  await assert.rejects(verifyDirectJsSourceMap(f.product, { ...f.policy, expectedPreparationOriginsId: null }), /SUBJECT/);
});

test('freshly rehashed false mappings, recipes, lineage and resource exhaustion reject', async () => {
  const f = productFixture();
  const changed = JSON.parse(f.product.sourceMap.bytes); changed.mappings = 'AAAA';
  const sourceMap = canonicalArtifact(changed, 'source-map-output', 'psc-direct-javascript-source-map/1');
  const recipeValue = JSON.parse(f.product.recipe.bytes); recipeValue.sourceMapId = sourceMap.identity;
  const recipe = canonicalArtifact(recipeValue, 'source-map-recipe', 'psc-direct-javascript-source-map-recipe/1');
  await assert.rejects(verifyDirectJsSourceMap({ sourceMap, recipe }, f.policy), /BINDING/);
  const falseClaim = { ...JSON.parse(f.product.recipe.bytes), semanticPreservationProved: true };
  await assert.rejects(verifyDirectJsSourceMap({ sourceMap: f.product.sourceMap,
    recipe: canonicalArtifact(falseClaim, 'source-map-recipe', 'psc-direct-javascript-source-map-recipe/1') }, f.policy), /BINDING/);
  await assert.rejects(verifyDirectJsSourceMap(f.product, { ...f.policy, expectedFile: 'another.js' }), /SUBJECT/);
  const wrong = JSON.parse(f.lineage.bytes); wrong.edges[0][3] = 1;
  assert.throws(() => createDirectJsSourceMap({
    lineage: canonicalArtifact(wrong, 'declaration-lineage', 'psc-js-declaration-lineage/1'),
    resolveArtifact: f.resolveArtifact,
  }), /LINEAGE_BINDING/);
  assert.throws(() => createDirectJsSourceMap({ lineage: f.lineage, resolveArtifact: f.resolveArtifact, maxTotalBytes: 1 }), /RESOURCE/);
  await assert.rejects(verifyDirectJsSourceMap(f.product, { ...f.policy, maxBytes: 1 }), /export-bytes/);
});

test('source anchors convert observed scalar columns to actual UTF-16 columns', () => {
  // Coordinate-only metadata fixture, not a claim that this text elaborates.
  const f = fixture(), sources = ['😀' + f.sources[0]], table = JSON.parse(f.sourceTable);
  for (const entry of table[3]) for (const position of [entry[2], entry[3]]) {
    position[0] += 4;
    if (position[1] === 1) position[2]++;
  }
  const origin = createDeclarationOriginGraph({ table: canonicalBytes(table), sources, publicApi: f.publicApi });
  for (const item of [origin.graph, ...origin.artifacts]) f.artifacts.set(artifactKey(item.identity), item.bytes);
  const lineage = createJsDeclarationLineage({ ...f, parents: { ...f.parents, originGraphId: origin.graph.identity } }).lineage;
  const product = createDirectJsSourceMap({ lineage, resolveArtifact: f.resolveArtifact });
  const consumer = new SourceMap(JSON.parse(product.sourceMap.bytes));
  assert.equal(consumer.findEntry(1, 0).originalLine, 0);
  assert.equal(consumer.findEntry(1, 0).originalColumn, 2);
  assert.equal(consumer.findEntry(4, 0).originalColumn, 0);
});

test('uniform generic source maps reconstruct their distinct lineage and preserve original-source coordinates', async () => {
  const f = productFixture(true, true), value = JSON.parse(f.product.sourceMap.bytes), consumer = new SourceMap(value);
  assert.equal(f.product.recipe.identity.contract, 'psc-direct-javascript-source-map-recipe/2');
  assert.equal(JSON.parse(f.product.recipe.bytes).lineageId.contract, 'psc-js-uniform-declaration-lineage/1');
  assert.equal(consumer.findEntry(1, 0).originalLine, 1);
  assert.equal(consumer.findEntry(4, 0).originalLine, 3);
  assert.equal(consumer.findEntry(2, 2).originalSource, undefined);
  assert.equal((await verifyDirectJsSourceMap(f.product, f.policy)).declarationMapReconstructed, true);
  const downgrade = canonicalArtifact(JSON.parse(f.product.recipe.bytes), 'source-map-recipe', 'psc-direct-javascript-source-map-recipe/1');
  await assert.rejects(verifyDirectJsSourceMap({ ...f.product, recipe: downgrade }, f.policy), /IDENTITY/);
});
