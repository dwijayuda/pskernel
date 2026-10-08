import assert from 'node:assert/strict';
import { test } from 'node:test';
import { canonicalBytes, canonicalArtifact, artifactKey } from './artifact-evidence.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { createDeclarationOriginGraph, decodeDeclarationOrigins, verifyDeclarationOriginGraph } from './declaration-origins.mjs';

const name = { k: 's', p: { k: 'a' }, v: 'value' };
const publicApi = publicApiArtifact(canonicalBytes(['psc-public-api-ir/1', 'all-prepared-declarations',
  [['constant', 'definition', name, [], { k: 'sort', l: { k: 'z' } }]]]));
const sources = ['😀\r\nx'];
const table = ['psc-declaration-origins/1', 'declaration-batch', 1, [[0, name, [0, 1, 1], [7, 2, 2]]]];
const policy = { sources, publicApi: publicApi.bytes };

test('origin coordinates use UTF-8 bytes and scalar columns, with exact declaration coverage', () => {
  assert.deepEqual(decodeDeclarationOrigins(canonicalBytes(table), policy), table);
  for (const update of [
    v => { v[3][0][3] = [2, 1, 2]; }, // middle of a UTF-8 code point
    v => { v[3][0][3] = [4, 1, 3]; }, // UTF-16 count is wrong for parser columns
    v => { v[3][0][0] = 1; },
    v => { v[3] = []; },
    v => { v[3][0][1] = { ...name, v: 'other' }; },
  ]) {
    const changed = structuredClone(table); update(changed);
    assert.throws(() => decodeDeclarationOrigins(canonicalBytes(changed), policy), /PSC_DECL_ORIGIN_/);
  }
});

test('origin graph binds exact source bytes, public API and table without semantic promotion', async () => {
  const product = createDeclarationOriginGraph({ table: canonicalBytes(table), sources, publicApi });
  const records = new Map(product.artifacts.map(item => [artifactKey(item.identity), item.bytes]));
  const verifyPolicy = { resolveArtifact: id => records.get(artifactKey(id)), expectedPublicApiId: publicApi.identity, expectedSources: sources };
  const checked = await verifyDeclarationOriginGraph(product.graph, verifyPolicy);
  assert.equal(checked.semanticPreservationProved, false);
  await assert.rejects(verifyDeclarationOriginGraph(product.graph, { ...verifyPolicy, expectedSources: ['😀\r\ny'] }), /SOURCE_BYTES/);
  const changed = JSON.parse(product.graph.bytes); changed.unmappedStages = [];
  await assert.rejects(verifyDeclarationOriginGraph(canonicalArtifact(changed, 'origin-graph', 'psc-origin-graph/1'), verifyPolicy), /SCHEMA/);
});
