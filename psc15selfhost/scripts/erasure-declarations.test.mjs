import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { createErasureDeclarationMap, decodeErasureDeclarations, verifyErasureDeclarationMap } from './erasure-declarations.mjs';

const name = (value, parent = { k: 'a' }) => ({ k: 's', p: parent, v: value });
const natural = { k: 'const', n: name('Nat'), ls: [] };
const api = ['psc-public-api-ir/1', 'all-prepared-declarations', [
  ['constant', 'definition', name('B', name('A')), [], natural],
  ['constant', 'partial', name('A.B'), [], natural],
  ['constant', 'definition', name('proof'), [], { k: 'sort', l: { k: 'z' } }],
  ['constant', 'theorem', name('theorem'), [], { k: 'sort', l: { k: 'z' } }],
]];
const ir = ['psc-runtime-ir-json/1', [], [], [], ['A_B', 'A_B_'].map(value =>
  [value, [], [], ['primitive', 'nat'], ['literal', ['natural', '1']]])];
const table = ['psc-erasure-declarations/1', 'declaration-inventory', [
  [api[2][0][2], ['runtime', 'A_B']], [api[2][1][2], ['runtime', 'A_B_']],
  [api[2][2][2], ['proof-erased']], [api[2][3][2], ['no-runtime-declaration']],
]];
const publicApi = publicApiArtifact(canonicalBytes(api));
const runtimeBytes = canonicalBytes(ir);
const runtimeIr = { bytes: runtimeBytes, identity: artifactId(runtimeBytes, 'runtime-ir', 'psc-runtime-ir-json/1') };
const policy = { publicApi: publicApi.bytes, runtimeIr: runtimeIr.bytes };

test('structured names and actual runtime spellings retain exhaustive ordered inventories', () => {
  assert.deepEqual(decodeErasureDeclarations(canonicalBytes(table), policy), table);
  for (const update of [
    value => value[2].pop(),
    value => { [value[2][0], value[2][1]] = [value[2][1], value[2][0]]; },
    value => { value[2][0][1] = ['runtime', 'A_B_']; },
    value => { value[2][1][1] = ['runtime', 'A_B']; },
    value => { value[2][0][1] = ['no-runtime-declaration']; },
    value => { value[2][3][1] = ['proof-erased']; },
    value => { value[2][2][1] = ['invented']; },
  ]) {
    const changed = structuredClone(table); update(changed);
    assert.throws(() => decodeErasureDeclarations(canonicalBytes(changed), policy), /PSC_ERASURE_DECL_/);
  }
  const extra = structuredClone(ir); extra[4].push(['extra', [], [], ['primitive', 'nat'], ['literal', ['natural', '1']]]);
  assert.throws(() => decodeErasureDeclarations(canonicalBytes(table), { ...policy, runtimeIr: canonicalBytes(extra) }), /RUNTIME_COVERAGE/);
});

test('replay pins API and runtime subjects and cannot turn inventories into semantic proofs', async () => {
  const { map, artifacts } = createErasureDeclarationMap({ table: canonicalBytes(table), publicApi, runtimeIr });
  const records = new Map(artifacts.map(item => [artifactKey(item.identity), item.bytes]));
  const pinned = { resolveArtifact: id => records.get(artifactKey(id)),
    expectedPublicApiId: publicApi.identity, expectedRuntimeIrId: runtimeIr.identity };
  const result = await verifyErasureDeclarationMap(map, pinned);
  assert.equal(result.inventoryCorrespondenceChecked, true);
  assert.equal(result.semanticPreservationProved, false);
  assert.equal(result.proofDispositionIndependentlyChecked, false);
  await assert.rejects(verifyErasureDeclarationMap(map, { ...pinned, expectedRuntimeIrId: publicApi.identity }), /SCHEMA/);
  const changed = JSON.parse(map.bytes); changed.semanticPreservationProved = true;
  await assert.rejects(verifyErasureDeclarationMap(canonicalArtifact(changed, 'erasure-map', 'psc-erasure-declaration-map/1'), pinned), /BINDING/);
  await assert.rejects(verifyErasureDeclarationMap(map, { ...pinned, maxBytes: 1 }), /export-bytes/);
});
