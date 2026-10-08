import { uniformJsRepresentationProfile } from './uniform-specialization.mjs';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { createJsDeclarationLineage, verifyJsDeclarationLineage } from './js-declaration-lineage.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';

import { fixture } from './js-origin-test-fixture.mjs';

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
  const changed = canonicalArtifact(value, 'verified-ir', 'psc-runtime-ir-json/1');
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
  assert.equal(built.directSourceMap.sourceMap.identity.contract, 'psc-direct-javascript-source-map/1');
  assert.ok(built.graph.entries.some(entry => entry.source.suffix === '.js.map'));
  const definitions = built.graph.entries.filter(entry => entry.identity.domain === 'pass-definition').map(entry => entry.canonicalValue);
  const definition = definitions.find(item => item.passId === 'psc-compose-js-declaration-lineage/1');
  assert.equal(definition.effects.authorityEffect, 'none');
  const packed = packObservedBuildArchive(built);
  const replay = await verifyObservedBuildArchive(packed.bytes, { expectedGraphId: built.identity,
    allowedAssumptions: [...new Set(definitions.flatMap(item => item.assumptionIds))] });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.preservationVerified, false);
});

test('uniform lineage joins retained generic declarations without specialization witnesses', async () => {
  const f = fixture({ uniform: true }), product = createJsDeclarationLineage(f);
  const value = JSON.parse(product.lineage.bytes);
  assert.equal(product.lineage.identity.contract, 'psc-js-uniform-declaration-lineage/1');
  assert.equal(value.edgeOrder, 'generated-position-runtime-declaration-erasure-entry-source-origin-entry');
  assert.deepEqual(value.edges, [[0, 0, 0, 0], [1, 1, 1, 1]]);
  assert.equal(value.specializationMapId, undefined);
  assert.equal(product.artifacts.some(item => item.identity.domain === 'specialization-map'), false);
  assert.equal((await verifyJsDeclarationLineage(product.lineage, {
    resolveArtifact: f.resolveArtifact, expectedParents: f.parents, profile: uniformJsRepresentationProfile,
  })).semanticPreservationProved, false);
  await assert.rejects(verifyJsDeclarationLineage(product.lineage, {
    resolveArtifact: f.resolveArtifact, expectedParents: f.parents }), /PARENTS/);
  const changed = JSON.parse(f.uniformSpecializedIr.bytes); changed[2][4].pop();
  const wrong = canonicalArtifact(changed, 'uniform-specialized-ir', 'psc-uniform-specialized-ir/1');
  f.artifacts.set(artifactKey(wrong.identity), wrong.bytes);
  assert.throws(() => createJsDeclarationLineage({ ...f,
    parents: { ...f.parents, uniformSpecializedIrId: wrong.identity } }), /PAYLOAD_CHANGED/);
  assert.throws(() => createJsDeclarationLineage(fixture({ uniform: true, parameter: 'renamed' })), /TARGET_DECLARATION_INVENTORY/);
  const falseEdge = structuredClone(value); falseEdge.edges[0][1] = 1;
  await assert.rejects(verifyJsDeclarationLineage(
    canonicalArtifact(falseEdge, 'declaration-lineage', 'psc-js-uniform-declaration-lineage/1'), {
      resolveArtifact: f.resolveArtifact, expectedParents: f.parents, profile: uniformJsRepresentationProfile }), /BINDING/);
});
