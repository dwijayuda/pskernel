import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { createClaimSet } from './claim-set.mjs';
import { createBackendDescriptor, decodeBackendDescriptor, createArtifactBundle, verifyArtifactBundle } from './backend-contract.mjs';

const registryValue = JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V1.json', import.meta.url), 'utf8'));
function fixture(backendId) {
  const records = new Map();
  const add = record => { records.set(artifactKey(record.identity), record.bytes); return record; };
  const artifact = (value, domain = 'fixture', contract = 'test-only/1') => add(canonicalArtifact(value, domain, contract));
  const registry = add(canonicalArtifact(registryValue, 'backend-registry', 'psc-backend-registry/1'));
  const selected = registryValue.backends.find(item => item.backendId === backendId);
  const implementationId = artifact('fixture compiler').identity;
  const targetProfileId = artifact('fixture target profile').identity;
  const externalToolchainId = selected.backendKind === 'sourceTarget' ? artifact('fixture pinned toolchain').identity : null;
  const descriptor = add(createBackendDescriptor(registry, { backendId, implementationId,
    targetProfileId, externalToolchainId, interfaceAdapterId: null }));
  const product = selected.products.executableArtifacts[0];
  const executable = artifact('fixture target bytes', product.domain, product.contract);
  const sourceSubjectId = artifact('fixture source').identity;
  const profileEnvironmentId = artifact({ fixture: true }, 'profile-environment', 'psc-profile-environment/1').identity;
  const claims = add(createClaimSet());
  const fields = { descriptor, sourceSubjectId, profileEnvironmentId, claimSetId: claims.identity,
    executableArtifacts: [{ role: product.role, artifact: executable.identity }],
    publicApiArtifacts: [], debugArtifacts: [], interfaceArtifacts: [],
    targetToolchainArtifacts: externalToolchainId ? [externalToolchainId] : [], evidenceArtifacts: [] };
  const bundle = add(createArtifactBundle(fields));
  const policy = { expectedBundleId: bundle.identity, resolveArtifact: id => records.get(artifactKey(id)) };
  return { records, add, artifact, descriptor, fields, bundle, policy, registry, executable, externalToolchainId };
}

test('all four lanes share identified bundles without inferred semantic claims', async () => {
  assert.deepEqual(registryValue.backends.map(item => item.backendId), ['typescript', 'javascript', 'wasm', 'rust']);
  for (const backend of registryValue.backends) {
    const f = fixture(backend.backendId), result = await verifyArtifactBundle(f.bundle, f.policy);
    assert.equal(result.integrityVerified, true); assert.equal(result.claimsVerified, false);
    assert.equal(result.preservationVerified, false); assert.equal(result.releaseAccepted, false);
    const checkedEmpty = await verifyArtifactBundle(f.bundle, { ...f.policy, claimVerification: {} });
    assert.equal(checkedEmpty.verifiedClaims.verifiedClaimCount, 0);
    assert.equal(decodeBackendDescriptor(f.descriptor).backendKind, backend.backendKind);
  }
});

test('direct JS cannot silently substitute tsc declarations or maps', () => {
  const f = fixture('javascript');
  const declaration = f.artifact('declaration', 'declarations-output', 'typescript-emitted-file/1');
  assert.throws(() => createArtifactBundle({ ...f.fields,
    publicApiArtifacts: [{ role: 'declaration', artifact: declaration.identity }] }), /UNSUPPORTED_PRODUCT/);
  assert.throws(() => createArtifactBundle({ ...f.fields, backendId: 'typescript' }), /SCHEMA/);
});

test('source backend tool products require the exact declared toolchain artifact', () => {
  const f = fixture('typescript');
  const js = f.artifact('javascript', 'javascript-output', 'typescript-emitted-file/1');
  const products = [{ role: 'javascript', artifact: js.identity }];
  assert.throws(() => createArtifactBundle({ ...f.fields, executableArtifacts: products, targetToolchainArtifacts: [] }), /TOOLCHAIN_REQUIRED/);
  assert.throws(() => createArtifactBundle({ ...f.fields, executableArtifacts: products,
    targetToolchainArtifacts: [f.artifact('other toolchain').identity] }), /TOOLCHAIN_REQUIRED/);
  assert.doesNotThrow(() => createArtifactBundle({ ...f.fields, executableArtifacts: products }));
});

test('bundle identity, registry binding and every referenced byte are checked', async () => {
  const f = fixture('wasm');
  await assert.rejects(verifyArtifactBundle(f.bundle, { ...f.policy, expectedBundleId: f.artifact('other').identity }), /CONSUMER_POLICY/);
  const key = artifactKey(f.executable.identity), bytes = f.records.get(key);
  f.records.set(key, Buffer.from('changed'));
  await assert.rejects(verifyArtifactBundle(f.bundle, f.policy), /ARTIFACT_BYTES/);
  f.records.set(key, bytes);
  const value = JSON.parse(f.descriptor.bytes); value.emitterId = 'unregistered-emitter';
  const descriptor = f.add(canonicalArtifact(value, 'backend-descriptor', 'psc-backend-descriptor/1'));
  const changed = f.add(createArtifactBundle({ ...f.fields, descriptor }));
  await assert.rejects(verifyArtifactBundle(changed, { ...f.policy, expectedBundleId: changed.identity }), /DESCRIPTOR_REGISTRY_BINDING/);
});

test('missing debug products are independent from claims and cannot hide a missing executable', () => {
  const f = fixture('typescript');
  assert.doesNotThrow(() => createArtifactBundle({ ...f.fields, debugArtifacts: [] }));
  assert.throws(() => createArtifactBundle({ ...f.fields, executableArtifacts: [] }), /LIST/);
  const map = f.artifact('map', 'source-map-output', 'typescript-emitted-file/1');
  assert.throws(() => createArtifactBundle({ ...f.fields,
    publicApiArtifacts: [{ role: 'source-map', artifact: map.identity }] }), /UNSUPPORTED_PRODUCT/);
});

test('ClaimSet subjects and profiles cannot be transplanted into another bundle', async () => {
  const f = fixture('javascript');
  for (const changed of ['subject', 'profile']) {
    const claim = { kind: 'TargetToolAccepted', subjects: [changed === 'subject' ? f.artifact('other').identity : f.executable.identity],
      profileEnvironmentId: changed === 'profile' ? f.artifact('other profile').identity : f.fields.profileEnvironmentId,
      evidenceClass: 'target-tool-acceptance', evidenceIds: [f.artifact('test-only evidence').identity],
      checkerImplementationId: f.artifact('test checker').identity, resourcePolicyId: f.artifact('test resource policy').identity,
      assumptionIds: [] };
    const claims = f.add(createClaimSet([claim]));
    const bundle = f.add(createArtifactBundle({ ...f.fields, claimSetId: claims.identity }));
    await assert.rejects(verifyArtifactBundle(bundle, { ...f.policy, expectedBundleId: bundle.identity }), /CLAIM_SUBJECT/);
  }
});
