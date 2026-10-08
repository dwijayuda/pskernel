import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { createClaimSet, decodeClaimSet, verifyClaimSet, evaluateClaimPolicy, captureClaimConsumerPolicy } from './claim-set.mjs';

function fixture(kind = 'TargetToolAccepted', evidenceClass = 'target-tool-acceptance') {
  const artifacts = new Map();
  const add = (value, domain = 'fixture', contract = 'test-only/1') => {
    const result = canonicalArtifact(value, domain, contract);
    artifacts.set(artifactKey(result.identity), result.bytes); return result.identity;
  };
  const item = { kind, subjects: [add('exact target')], profileEnvironmentId: add('profile'),
    checkerImplementationId: add('consumer-selected test checker'), resourcePolicyId: add('resource policy'),
    evidenceClass, evidenceIds: [add('test-double evidence')], assumptionIds: ['test-runtime'] };
  const record = createClaimSet([item]);
  const checkers = new Map([[artifactKey(item.checkerImplementationId), async (_evidence, claim) => ({ accepted: true, claim })]]);
  const options = { resolveArtifact: id => artifacts.get(artifactKey(id)), checkers, allowedAssumptions: ['test-runtime'] };
  const requirement = { kind, subjects: item.subjects, profileEnvironmentId: item.profileEnvironmentId,
    resourcePolicyId: item.resourcePolicyId, evidenceClasses: [evidenceClass], checkerImplementationIds: [item.checkerImplementationId] };
  const policy = (requirements = [requirement], allowedAssumptions = ['test-runtime']) => canonicalArtifact({
    schemaVersion: 1, contract: 'psc-claim-policy/1', requirements, allowedAssumptions,
  }, 'claim-policy', 'psc-claim-policy/1');
  return { item, record, options, add, artifacts, requirement, policy };
}

test('serialized claims are assertions; exact selected checker is required', async () => {
  const f = fixture();
  assert.equal(decodeClaimSet(f.record).authority, 'audit-record-only');
  await assert.rejects(verifyClaimSet(f.record, { ...f.options, checkers: new Map() }), /CHECKER_UNAVAILABLE/);
  const verified = await verifyClaimSet(f.record, f.options);
  assert.equal(verified.verifiedClaimCount, 1);
  assert.equal(verified.authority, 'audit-record-only');
  assert.equal(evaluateClaimPolicy(verified, f.policy()).policySatisfied, true);
  assert.equal(evaluateClaimPolicy(verified, f.policy()).releaseCapabilityMinted, false);
  assert.throws(() => evaluateClaimPolicy(JSON.parse(JSON.stringify(verified)), f.policy()), /LIVE_VERIFICATION_REQUIRED/);
});

test('target acceptance, fixed points and provenance never imply preservation', async () => {
  for (const [kind, evidenceClass] of [['TargetToolAccepted', 'target-tool-acceptance'],
    ['SelfHostFixedPoint', 'exact-fixed-point'], ['ProvenanceBound', 'provenance-check']]) {
    const f = fixture(kind, evidenceClass), verified = await verifyClaimSet(f.record, f.options);
    const required = { ...f.requirement, kind: 'SemanticPreservationChecked', evidenceClasses: ['formal-proof'] };
    assert.equal(evaluateClaimPolicy(verified, f.policy([required])).policySatisfied, false);
    assert.throws(() => createClaimSet([{ ...f.item, kind: 'SemanticPreservationChecked' }]), /EVIDENCE_CLASS/);
  }
});

test('fresh hashes cannot substitute subjects, profile, resources or checker policy', async () => {
  const f = fixture(), verified = await verifyClaimSet(f.record, f.options);
  for (const change of [
    { subjects: [f.add('other target')] }, { profileEnvironmentId: f.add('other profile') },
    { resourcePolicyId: f.add('other resource policy') },
    { checkerImplementationIds: [f.add('unselected checker')] },
  ]) assert.equal(evaluateClaimPolicy(verified, f.policy([{ ...f.requirement, ...change }])).policySatisfied, false);
  assert.equal(evaluateClaimPolicy(verified, f.policy([f.requirement], [])).policySatisfied, false);
  await assert.rejects(verifyClaimSet(f.record, { ...f.options, allowedAssumptions: [] }), /ASSUMPTION_DENIED/);
});

test('all referenced bytes and the checker exact-subject response are checked', async () => {
  const f = fixture();
  for (const id of [...f.item.subjects, f.item.profileEnvironmentId, f.item.resourcePolicyId,
    f.item.checkerImplementationId, ...f.item.evidenceIds]) {
    const key = artifactKey(id), original = f.artifacts.get(key);
    f.artifacts.set(key, Buffer.from('tampered'));
    await assert.rejects(verifyClaimSet(f.record, f.options), /ARTIFACT_BYTES/);
    f.artifacts.set(key, original);
  }
  f.options.checkers.set(artifactKey(f.item.checkerImplementationId),
    async (_evidence, claim) => ({ accepted: true, claim: { ...claim, subjects: [] } }));
  await assert.rejects(verifyClaimSet(f.record, f.options), /EVIDENCE_REJECTED/);
});

test('unknown claims, derived release claims, duplicate and unbounded assertions reject', () => {
  const f = fixture();
  for (const kind of ['Unknown', 'AssuredRelease']) assert.throws(() => createClaimSet([{ ...f.item, kind }]), /KIND/);
  assert.throws(() => createClaimSet([f.item, f.item]), /DUPLICATE/);
  assert.throws(() => createClaimSet([{ ...f.item, assurance: true }]), /SCHEMA/);
  assert.throws(() => createClaimSet([{ ...f.item, subjects: Array(65).fill(f.item.subjects[0]) }]), /LIST/);
  assert.throws(() => createClaimSet([{ ...f.item, evidenceIds: [] }]), /LIST/);
  assert.throws(() => decodeClaimSet({ identity: f.record.identity, bytes: Buffer.alloc(1024 * 1024 + 1) }), /BYTES_LIMIT/);
});

test('an empty ClaimSet conveys no implicit claims and cannot satisfy a nonempty policy', async () => {
  const f = fixture(), empty = createClaimSet();
  const verified = await verifyClaimSet(empty, f.options);
  assert.equal(verified.verifiedClaimCount, 0);
  assert.equal(evaluateClaimPolicy(verified, f.policy()).policySatisfied, false);
  assert.throws(() => evaluateClaimPolicy(verified, f.policy([])), /LIST/);
});

test('caller mutation cannot rewrite the live verified snapshot', async () => {
  const f = fixture(), verified = await verifyClaimSet(f.record, f.options);
  const expected = artifactKey(f.record.identity);
  verified.claimSetId.digest = 'f'.repeat(64);
  f.item.subjects.length = 0;
  const result = evaluateClaimPolicy(verified, f.policy([{ ...f.requirement, subjects: decodeClaimSet(f.record).claims[0].subjects }]));
  assert.equal(artifactKey(result.claimSetId), expected);
  assert.equal(result.policySatisfied, true);
});

test('consumer capture rejects implicit verification, dynamic fields and malformed policies before callbacks', () => {
  const f = fixture();
  assert.throws(() => captureClaimConsumerPolicy({ claimPolicy: f.policy() }), /VERIFICATION_REQUIRED/);
  let invoked = false;
  const getters = { get checkers() { invoked = true; return f.options.checkers; } };
  for (const claimVerification of [null, [], { resolveArtifact: f.options.resolveArtifact }, getters,
    { checkers: new Map([['invalid', 'executable path']]) }, { allowedAssumptions: ['duplicate', 'duplicate'] }]) {
    assert.throws(() => captureClaimConsumerPolicy({ claimVerification }), /POLICY|DUPLICATE/);
  }
  assert.equal(invoked, false);
  for (const claimPolicy of [f.policy([]), { identity: f.policy().identity, bytes: Buffer.from('changed') },
    { identity: f.policy().identity, bytes: Buffer.alloc(1024 * 1024 + 1) }]) {
    assert.throws(() => captureClaimConsumerPolicy({ claimVerification: {}, claimPolicy }), /LIST|ARTIFACT_BYTES|POLICY/);
  }
});
