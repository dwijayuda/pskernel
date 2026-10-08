import assert from 'node:assert/strict';
import { test } from 'node:test';
import { SourceMap } from 'node:module';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { createDeclarationOriginGraph } from './declaration-origins.mjs';
import { sourcePreparationRecord, createSourcePreparationArtifacts } from './source-preparation-origins.mjs';
import { createDirectJsDeclarations, createDirectJsDeclarationPositions, directJsDeclarationProfile,
  directJsUniformDeclarationProfile } from './js-declarations.mjs';
import { createDirectJsDeclarationMap, verifyDirectJsDeclarationMap } from './js-declaration-map.mjs';
import { uniformSpecializationArtifact, uniformJsRepresentationProfile } from './uniform-specialization.mjs';

const name = v => ({ k: 's', p: { k: 'a' }, v });
const constant = v => ({ k: 'const', n: name(v), ls: [] });
const forall = (n, t, b) => ({ k: 'forall', n: name(n), t, b, bi: 'default' });
const record = (value, domain, contract = 'psc-runtime-ir-json/1') => canonicalArtifact(value, domain, contract);
const raw = (value, domain, contract) => {
  const bytes = Buffer.from(value); return { bytes, identity: artifactId(bytes, domain, contract) };
};

function fixture(uniform = false, original = false) {
  const profile = uniform ? directJsUniformDeclarationProfile : directJsDeclarationProfile;
  const prefix = '/- 🔥 -/ ';
  const first = uniform ? 'def forward (A : Type) (x : A) : A := x' : 'def forward (x : Nat) : Nat := x';
  const second = uniform ? 'def answer : Nat := forward Nat 7' : 'def answer : Nat := forward 7';
  const sources = [prefix + first + '\n' + second];
  const generic = forall('A', { k: 'sort', l: { k: 's', o: { k: 'z' } } },
    forall('x', { k: 'b', i: 0 }, { k: 'b', i: 1 }));
  const publicApi = publicApiArtifact(canonicalBytes(['psc-public-api-ir/1', 'all-prepared-declarations', [
    ['constant', 'definition', name('forward'), [], uniform ? generic : forall('x', constant('Nat'), constant('Nat'))],
    ['constant', 'definition', name('answer'), [], constant('Nat')],
  ]]));
  const nat = ['primitive', 'nat'], parameter = uniform ? ['typeParameter', 'A'] : nat;
  const seven = ['literal', ['natural', '7']];
  const runtimeCall = ['call', ['var', 'g'], uniform ? [nat] : [], [seven]];
  const runtime = ['psc-runtime-ir-json/1', [], [], [], [
    ['g', uniform ? ['A'] : [], [['x', parameter]], parameter, ['var', 'x']],
    ['answer', [], [], nat, runtimeCall],
  ]];
  const subjects = { publicApi,
    erasureTable: record(['psc-erasure-declarations/1', 'declaration-inventory', [
      [name('forward'), ['runtime', 'g']], [name('answer'), ['runtime', 'answer']],
    ]], 'erasure-table', 'psc-erasure-declarations/1'),
    runtimeIr: record(runtime, 'runtime-ir'), verifiedIr: record(runtime, 'verified-ir'),
    ...(uniform ? { uniformSpecializedIr: uniformSpecializationArtifact(canonicalBytes([
      'psc-uniform-specialized-ir/1', uniformJsRepresentationProfile, runtime])) } :
      { specializedIr: record(runtime, 'specialized-ir') }),
    jsIr: record(['psc-js-ir-json/1', [], [
      ['g', ['x'], ['var', 'x']],
      ['answer', [], ['call', ['var', 'g'], [seven]]],
    ]], 'js-ir', 'psc-js-ir-json/1'),
    javaScript: raw('export function g(x) { return x; }\nexport const answer = g(7n);\n',
      'javascript-output', 'psc-direct-javascript/es2022'),
  };
  const firstEnd = Buffer.byteLength(prefix + first), secondStart = firstEnd + 1;
  const table = canonicalBytes(['psc-declaration-origins/1', 'declaration-batch', 1, [
    [0, name('forward'), [Buffer.byteLength(prefix), 1, [...prefix].length + 1], [firstEnd, 1, [...prefix].length + first.length + 1]],
    [0, name('answer'), [secondStart, 2, 1], [Buffer.byteLength(sources[0]), 2, second.length + 1]],
  ]]);
  const origin = createDeclarationOriginGraph({ table, sources, publicApi });
  const declarations = createDirectJsDeclarations({ subjects, profile });
  const records = [...Object.values(subjects), ...origin.artifacts, origin.graph, ...Object.values(declarations)];
  let preparationOrigins = null, sourceSnapshot = null, originalText = sources[0];
  if (original) {
    originalText = '\ufeffimport Lib\r\n' + sources[0].replace('\n', '\r\nimport Hidden\r\n') + '  \r\n';
    const prepared = sourcePreparationRecord('src/with space/🔥.lean', originalText, 0);
    assert.equal(prepared.prepared, sources[0]);
    sourceSnapshot = canonicalArtifact({ sourceKind: 'lean', sources }, 'source-snapshot', 'psc-source-snapshot/1');
    const captured = createSourcePreparationArtifacts([prepared], sourceSnapshot);
    preparationOrigins = captured.map;
    records.push(sourceSnapshot, preparationOrigins, ...captured.artifacts);
  }
  const artifacts = new Map(records.map(item => [artifactKey(item.identity), item.bytes]));
  const resolveArtifact = id => artifacts.get(artifactKey(id));
  const inputs = { ...declarations, originGraph: origin.graph, profile, preparationOrigins, sourceSnapshot,
    file: 'out.d.ts', resolveArtifact };
  const product = createDirectJsDeclarationMap(inputs);
  const options = { resolveArtifact, expectedDeclarationsId: declarations.declarations.identity,
    expectedSourceSignaturesId: declarations.sourceSignatures.identity, expectedBindingId: declarations.binding.identity,
    expectedOriginGraphId: origin.graph.identity, expectedProfile: profile,
    expectedPreparationOriginsId: preparationOrigins?.identity ?? null, expectedSourceSnapshotId: sourceSnapshot?.identity ?? null,
    expectedFile: 'out.d.ts' };
  return { subjects, sources, prefix, profile, originalText, declarations, origin, artifacts, inputs, product, options };
}

for (const uniform of [false, true]) for (const original of [false, true])
test('source declaration chunks replay with ' + (uniform ? 'uniform generics' : 'closed types') +
  ' and ' + (original ? 'original' : 'prepared') + ' coordinates', async () => {
  const f = fixture(uniform, original), withPositions = createDirectJsDeclarationPositions({ subjects: f.subjects, profile: f.profile });
  for (const key of ['declarations', 'sourceSignatures', 'binding'])
    assert.equal(artifactKey(withPositions[key].identity), artifactKey(f.declarations[key].identity));
  const positions = JSON.parse(withPositions.declarationPositions.bytes);
  assert.deepEqual(positions.positions.map(item => [item[0], item[1], item[2][1]]),
    [[0, 'declaration', 0], [0, 'export', 1], [1, 'declaration', 2], [1, 'export', 3]]);
  const map = JSON.parse(f.product.declarationMap.bytes), consumer = new SourceMap(map);
  assert.equal(map.file, 'out.d.ts');
  assert.deepEqual(map.sourcesContent, [f.originalText]);
  for (const line of [0, 1]) {
    assert.equal(consumer.findEntry(line, 0).originalLine, original ? 1 : 0);
    assert.equal(consumer.findEntry(line, 0).originalColumn, f.prefix.length);
  }
  for (const line of [2, 3]) {
    assert.equal(consumer.findEntry(line, 0).originalLine, original ? 3 : 1);
    assert.equal(consumer.findEntry(line, 0).originalColumn, 0);
  }
  for (const [index, line] of f.declarations.declarations.bytes.toString().trimEnd().split('\n').entries())
    assert.equal(consumer.findEntry(index, line.length).originalSource, undefined);
  assert.equal(consumer.findEntry(4, 0).originalSource, undefined);
  assert.equal(map.x_psc_expressionOrigins, false);
  const replay = await verifyDirectJsDeclarationMap(f.product, f.options);
  assert.equal(replay.declarationMapReconstructed, true);
  assert.equal(replay.semanticPreservationProved, false);
  assert.equal(JSON.parse(f.product.recipe.bytes).linking, 'standalone-map-declarations-unchanged');
});

test('fresh hashes cannot transplant declaration positions, maps, parents or selected profile', async () => {
  const f = fixture(true, true);
  for (const key of ['declarationPositions', 'declarationMap', 'recipe']) {
    const value = JSON.parse(f.product[key].bytes);
    if (key === 'declarationPositions') value.positions[0][0] = 1;
    else if (key === 'declarationMap') value.mappings = '';
    else value.file = 'substituted.d.ts';
    const changed = canonicalArtifact(value, f.product[key].identity.domain, f.product[key].identity.contract);
    await assert.rejects(verifyDirectJsDeclarationMap({ ...f.product, [key]: changed }, f.options), /SUBJECT|BINDING/);
  }
  await assert.rejects(verifyDirectJsDeclarationMap(f.product, { ...f.options, expectedProfile: directJsDeclarationProfile }), /SUBJECT/);
  await assert.rejects(verifyDirectJsDeclarationMap(f.product, {
    ...f.options, expectedDeclarationsId: f.subjects.javaScript.identity }), /SUBJECT/);
  await assert.rejects(verifyDirectJsDeclarationMap(f.product, {
    ...f.options, expectedSourceSnapshotId: null }), /PREPARATION_PAIR/);
  assert.throws(() => createDirectJsDeclarationMap({ ...f.inputs, maxBytes: 1 }), /RESOURCE/);
  assert.throws(() => createDirectJsDeclarationMap({ ...f.inputs, maxTotalBytes: 1 }), /RESOURCE/);
});

test('consumer map selection and output records survive mutation during asynchronous resolution', async () => {
  const f = fixture(true, true), product = { ...f.product }, options = { ...f.options };
  const expected = options.expectedDeclarationsId;
  let changed = false;
  options.resolveArtifact = async id => {
    if (!changed) {
      changed = true;
      product.recipe.bytes.fill(0);
      product.declarationMap.bytes.fill(0);
      options.expectedDeclarationsId = f.subjects.javaScript.identity;
    }
    return f.options.resolveArtifact(id);
  };
  const result = await verifyDirectJsDeclarationMap(product, options);
  assert.equal(result.declarationMapReconstructed, true);
  assert.equal(artifactKey(expected), artifactKey(f.declarations.declarations.identity));
});
