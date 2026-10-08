import assert from 'node:assert/strict';
import { test } from 'node:test';
import { canonicalBytes, artifactKey } from './artifact-evidence.mjs';
import { semanticLock, sourceManifest, verifySemanticLock, compareSemanticLocks } from './semantic-lock.mjs';
import { semanticLockFixture } from './semantic-lock-fixture.mjs';

const check = f => verifySemanticLock(f.lock, { ...f.policy, resolveArtifact: f.resolveArtifact });
function change(f, mutate) {
  const value = JSON.parse(f.lock.bytes); mutate(value);
  f.lock = semanticLock(value); f.policy.expectedLockId = f.lock.identity; return f;
}

test('exact lock binds every declared source, context, interface and tool artifact', async () => {
  const f = semanticLockFixture(), result = await check(f);
  assert.equal(result.integrityVerified, true);
  assert.deepEqual(result.packageOrder, ['fixture']); assert.equal(result.sourceFiles, 1);
  assert.equal(result.artifactCount, f.artifacts.length - 1);
  assert.equal(result.semanticClaimsVerified, false); assert.equal(result.releaseAccepted, false);
  assert.equal(result.closureCompleteness, 'declared-inputs-only');
  const sourceKey = artifactKey(f.source.identity), original = f.resolveArtifact;
  f.resolveArtifact = id => artifactKey(id) === sourceKey ? Buffer.from('tampered') : original(id);
  await assert.rejects(check(f), /ARTIFACT_BYTES/);
});

test('consumer policy rejects identity substitution, assumptions, capabilities and absent tool roles', async () => {
  const stale = semanticLockFixture(); stale.policy.expectedSemanticIdentityId = stale.source.identity;
  await assert.rejects(check(stale), /SEMANTIC_IDENTITY/);
  const denied = semanticLockFixture(), assumption = denied.add({ axiom: 'fixture' }, 'assumption');
  change(denied, lock => lock.packages[0].assumptions.push(assumption.identity));
  await assert.rejects(check(denied), /ASSUMPTION_DENIED/);
  denied.policy.allowedAssumptions = [assumption.identity];
  assert.equal((await check(denied)).integrityVerified, true);
  change(denied, lock => lock.packages[0].capabilities.push('network'));
  await assert.rejects(check(denied), /CAPABILITY_DENIED/);
  const tool = semanticLockFixture(); tool.policy.requiredToolchainRoles.push('compiler');
  await assert.rejects(check(tool), /TOOLCHAIN_REQUIRED/);
});

function dependencyFixture() {
  const f = semanticLockFixture();
  change(f, value => {
    const provider = { ...value.packages[0], name: 'dependency' };
    value.packages[0].dependencies = [{ package: provider.name,
      structuralInterfaceId: provider.structuralInterfaceId, behavioralInterfaceId: provider.behavioralInterfaceId }];
    value.packages.push(provider);
  });
  return f;
}
test('dependency checks include behavioral interfaces, context, cycles and transitive policy', async () => {
  const f = dependencyFixture(); assert.deepEqual((await check(f)).packageOrder, ['dependency', 'fixture']);
  change(f, value => { value.packages[0].dependencies[0].behavioralInterfaceId = f.source.identity; });
  await assert.rejects(check(f), /DEPENDENCY_INTERFACE/);
  const context = dependencyFixture();
  change(context, value => { value.packages[1].targetAbiId = context.source.identity; });
  await assert.rejects(check(context), /DEPENDENCY_CONTEXT_UNSUPPORTED/);
  const cyclic = dependencyFixture();
  change(cyclic, value => { value.packages[1].dependencies = [{ ...value.packages[0].dependencies[0], package: 'fixture' }]; });
  await assert.rejects(check(cyclic), /DEPENDENCY_CYCLE/);
  const capability = dependencyFixture(); capability.policy.allowedCapabilities = ['storage'];
  change(capability, value => { value.packages[1].capabilities = ['storage']; });
  await assert.rejects(check(capability), /DEPENDENCY_POLICY_LAUNDERING/);
  const orphan = semanticLockFixture();
  change(orphan, value => { value.packages.push({ ...value.packages[0], name: 'orphan' }); });
  await assert.rejects(check(orphan), /UNREACHABLE_PACKAGE/);
});

test('byte/work budgets and missing source closure fail before lock approval', async () => {
  const f = semanticLockFixture();
  for (const resourceLimits of [{ maxArtifacts: 1 }, { maxTotalBytes: 1 }, { maxPackages: 0 }, { maxSourceFiles: 0 }]) {
    await assert.rejects(verifySemanticLock(f.lock, { ...f.policy, resolveArtifact: f.resolveArtifact, resourceLimits }), /RESOURCE_EXHAUSTED/);
  }
  f.artifacts.splice(f.artifacts.indexOf(f.source), 1);
  await assert.rejects(check(f), /ARTIFACT_BYTES/);
  assert.throws(() => sourceManifest([{ path: '../escape.ps', artifact: f.source.identity }]), /SOURCE_PATH/);
  assert.throws(() => sourceManifest([{ path: 'A.ps', artifact: f.source.identity }, { path: 'a.ps', artifact: f.source.identity }]), /DUPLICATE/);
});

test('lock difference records actual changed fields without claiming semantic equivalence', () => {
  const f = semanticLockFixture(), before = f.lock;
  change(f, value => { value.packages[0].sourceManifestId = sourceManifest([]).identity; value.trustManifestId = f.source.identity; });
  const diff = compareSemanticLocks(before, f.lock);
  assert.deepEqual(diff.packages[0].changedFields, ['sourceManifestId']);
  assert.equal(diff.declaredTrustChanged, true); assert.equal(diff.semanticIdentityChanged, false);
  assert.equal(diff.semanticEquivalence, 'not-established');
  assert.equal(diff.preservation, 'requires-independent-evidence');
  const malformed = { ...f.lock, bytes: canonicalBytes({ ...JSON.parse(f.lock.bytes), injected: true }) };
  assert.throws(() => compareSemanticLocks(before, malformed), /ARTIFACT_BYTES/);
});
