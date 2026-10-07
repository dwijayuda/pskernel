import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { createDeclarationOriginGraph } from './declaration-origins.mjs';
import { createErasureDeclarationMap } from './erasure-declarations.mjs';
import { createSpecializationInstanceMap } from './specialization-correspondence.mjs';
import { createJsGeneratedPositionMap } from './js-generated-positions.mjs';
import { createJsDeclarationLineage, verifyJsDeclarationLineage } from './js-declaration-lineage.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';

const name = v => ({ k: 's', p: { k: 'a' }, v });
const nat = ['primitive', 'nat'], ref = n => ['var', n];
const module = declarations => ['psc-runtime-ir-json/1', [], [], [], declarations];
function record(value, domain, contract = 'psc-runtime-ir-json/1') {
  const bytes = canonicalBytes(value); return { bytes, identity: artifactId(bytes, domain, contract) };
}
function fixture({ parameter = 'x' } = {}) {
  const lines = ['def forward (A : Type) (x : A) : A := x', 'def answer : Nat := forward Nat 7'];
  const sources = [lines.join('\n') + '\n'];
  const genericType = { k: 'forall', n: name('A'), bi: 'default', t: { k: 'sort', l: { k: 's', o: { k: 'z' } } },
    b: { k: 'forall', n: name('x'), bi: 'default', t: { k: 'b', i: 0 }, b: { k: 'b', i: 1 } } };
  const publicApi = publicApiArtifact(canonicalBytes(['psc-public-api-ir/1', 'all-prepared-declarations', [
    ['constant', 'definition', name('forward'), [], genericType],
    ['constant', 'definition', name('answer'), [], { k: 'const', n: name('Nat'), ls: [] }],
  ]]));
  const sourceTable = canonicalBytes(['psc-declaration-origins/1', 'declaration-batch', 1, [
    [0, name('forward'), [0, 1, 1], [lines[0].length, 1, lines[0].length + 1]],
    [0, name('answer'), [lines[0].length + 1, 2, 1], [sources[0].length - 1, 2, lines[1].length + 1]],
  ]]);
  const runtime = module([
    ['g', ['A'], [['x', ['typeParameter', 'A']]], ['typeParameter', 'A'], ref('x')],
    ['answer', [], [], nat, ['call', ref('g'), [nat], [['literal', ['natural', '7']]]]],
  ]);
  const specialized = module([
    ['chosen', [], [['x', nat]], nat, ref('x')],
    ['answer', [], [], nat, ['call', ref('chosen'), [], [['literal', ['natural', '7']]]]],
  ]);
  const runtimeIr = record(runtime, 'runtime-ir'), verifiedIr = record(runtime, 'verified-ir');
  const specializedIr = record(specialized, 'specialized-ir');
  const jsIr = record(['psc-js-ir-json/1', [], [
    ['chosen', [parameter], ref(parameter)],
    ['answer', [], ['call', ref('chosen'), [['literal', ['natural', '7']]]]],
  ]], 'js-ir', 'psc-js-ir-json/1');
  const erasureTable = canonicalBytes(['psc-erasure-declarations/1', 'declaration-inventory', [
    [name('forward'), ['runtime', 'g']], [name('answer'), ['runtime', 'answer']],
  ]]);
  const chunks = ['// synthetic runtime\n', 'export function chosen(x) { return x; }\n', 'export const answer = chosen(7n);\n'];
  const javaScript = chunks.join('');
  const generatedTable = canonicalBytes(['psc-js-generated-positions/1', 'declaration-emission-chunk', [
    ['chosen', [chunks[0].length, 1, 0], [chunks[0].length + chunks[1].length, 2, 0]],
    ['answer', [chunks[0].length + chunks[1].length, 2, 0], [javaScript.length, 3, 0]],
  ]]);
  const origin = createDeclarationOriginGraph({ table: sourceTable, sources, publicApi });
  const erasure = createErasureDeclarationMap({ table: erasureTable, publicApi, runtimeIr });
  const specialization = createSpecializationInstanceMap(verifiedIr, specializedIr);
  const positions = createJsGeneratedPositionMap({ table: generatedTable, javaScript, jsIr });
  const records = [...origin.artifacts, origin.graph, ...erasure.artifacts, erasure.map,
    verifiedIr, specializedIr, specialization.map, ...positions.artifacts, positions.map];
  const artifacts = new Map(records.map(item => [artifactKey(item.identity), item.bytes]));
  const parents = { originGraphId: origin.graph.identity, erasureMapId: erasure.map.identity,
    specializationMapId: specialization.map.identity, generatedPositionMapId: positions.map.identity,
    verifiedIrId: verifiedIr.identity };
  return { parents, artifacts, resolveArtifact: id => artifacts.get(artifactKey(id)),
    origin, erasure, specialization, positions, sources, publicApi, sourceTable, erasureTable, generatedTable,
    runtimeIr, verifiedIr, specializedIr, jsIr, javaScript };
}

test('exact lineage composes actual renamed instances without guessing mangling or granting proof authority', async () => {
  const f = fixture(), product = createJsDeclarationLineage(f);
  const value = JSON.parse(product.lineage.bytes);
  assert.deepEqual(value.edges, [[0, 0, 0, 0], [1, 1, 1, 1]]);
  assert.equal(value.semanticPreservationProved, false);
  assert.equal(value.expressionCorrespondenceChecked, false);
  const replay = await verifyJsDeclarationLineage(product.lineage, { resolveArtifact: async id => f.resolveArtifact(id), expectedParents: f.parents });
  assert.equal(replay.declarationCompositionChecked, true);
  assert.equal(replay.semanticPreservationProved, false);
  for (const mutate of [
    v => { v.edges[0][2] = 1; },
    v => { v.edges.pop(); },
    v => { v.semanticPreservationProved = true; },
    v => { v.unknown = true; },
  ]) {
    const changed = structuredClone(value); mutate(changed);
    await assert.rejects(verifyJsDeclarationLineage(
      canonicalArtifact(changed, 'declaration-lineage', 'psc-js-declaration-lineage/1'),
      { resolveArtifact: f.resolveArtifact, expectedParents: f.parents }), /BINDING/);
  }
  await assert.rejects(verifyJsDeclarationLineage(product.lineage, {
    resolveArtifact: f.resolveArtifact, expectedParents: { ...f.parents, originGraphId: f.erasure.map.identity },
  }), /PARENT_KIND/);
});

test('rehashed false parent claims, cross-stage subject changes and target inventory drift reject', () => {
  for (const key of ['originGraphId', 'erasureMapId', 'specializationMapId', 'generatedPositionMapId']) {
    const f = fixture(), id = f.parents[key], value = JSON.parse(f.resolveArtifact(id));
    value.authority = 'semantic-proof';
    const changed = canonicalArtifact(value, id.domain, id.contract);
    f.artifacts.set(artifactKey(changed.identity), changed.bytes);
    assert.throws(() => createJsDeclarationLineage({ ...f, parents: { ...f.parents, [key]: changed.identity } }), /PARENT_BINDING/);
  }
  const f = fixture(), value = JSON.parse(f.verifiedIr.bytes);
  value[4][1][4][3][0][1][1] = '9';
  const changed = record(value, 'verified-ir');
  f.artifacts.set(artifactKey(changed.identity), changed.bytes);
  assert.throws(() => createJsDeclarationLineage({ ...f, parents: { ...f.parents, verifiedIrId: changed.identity } }), /CHAIN_SUBJECT/);
  assert.throws(() => createJsDeclarationLineage(fixture({ parameter: 'renamed' })), /TARGET_DECLARATION_INVENTORY/);
  assert.throws(() => createJsDeclarationLineage({ ...f, maxBytes: 1 }), /RESOURCE/);
  assert.throws(() => createJsDeclarationLineage({ ...f, maxTotalBytes: 1 }), /RESOURCE/);
  assert.throws(() => createJsDeclarationLineage({ ...f, resolveArtifact: async id => f.resolveArtifact(id) }), /SYNCHRONOUS_BYTES_REQUIRED/);
});

test('actual graph producer publishes typed lineage and archive replay reconstructs its pinned parents', async () => {
  const f = fixture();
  // Synthetic audit provenance is explicit; no kernel acceptance is asserted.
  const admissions = '{"admissions":[],"format":"proofscript-checked-admissions","version":2}';
  const canonicalAdmissionsId = artifactId(Buffer.from(admissions), 'canonical-admissions', 'proofscript-checked-admissions/2');
  const pscvCertificate = canonicalArtifact({ contract: 'pscv-cert/1', canonicalAdmissionsId, fixture: true }, 'pscv-cert', 'pscv-cert/1');
  const certifiedSourceArtifact = canonicalArtifact({ contract: 'psc-certified-source/1', canonicalAdmissionsId,
    certificateId: pscvCertificate.identity, fixture: true }, 'certified-source', 'psc-certified-source/1');
  const built = createCheckedBuildGraph({ sourceKind: 'lean', sources: f.sources, admissions,
    directJavaScript: f.javaScript, publicApi: f.publicApi.bytes.toString(), declarationOrigins: f.sourceTable.toString(),
    erasureCorrespondence: f.erasureTable.toString(), generatedPositions: f.generatedTable.toString(),
    irStages: Object.fromEntries(['runtimeIr', 'verifiedIr', 'specializedIr', 'jsIr'].map(key => [key, f[key].bytes.toString()])),
    compilerBytes: Buffer.from('fixture compiler provenance'), compilerKind: 'fixture', pscvCertificate, certifiedSourceArtifact,
    provider: { profile: 'fixture' }, providerSecurity: { profile: 'fixture' }, kernelContract: { id: 'fixture' },
    hostSources: [], runtime: { implementation: 'fixture' } });
  assert.equal(built.declarationLineage.identity.contract, 'psc-js-declaration-lineage/1');
  assert.ok(built.graph.entries.some(entry => entry.source.suffix === '.declaration-lineage.json'));
  const definitions = built.graph.entries.filter(entry => entry.identity.domain === 'pass-definition').map(entry => entry.canonicalValue);
  const definition = definitions.find(item => item.passId === 'psc-compose-js-declaration-lineage/1');
  assert.equal(definition.effects.authorityEffect, 'none');
  const packed = packObservedBuildArchive(built);
  const replay = await verifyObservedBuildArchive(packed.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.preservationVerified, false);
});
