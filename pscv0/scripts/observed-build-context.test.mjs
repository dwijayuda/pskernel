import { createClaimSet } from './claim-set.mjs';
import { createArtifactBundle, verifyArtifactBundle } from './backend-contract.mjs';
import { createBuildAction } from './build-context.mjs';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { bindObservedBuildContext, verifyObservedContextProducts, verifyObservedActionBinding } from './observed-build-context.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';
const backendRegistry = canonicalArtifact(JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V1.json', import.meta.url))),
  'backend-registry', 'psc-backend-registry/1');
function fixture() {
  const observed = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['def seven : Nat := 7'],
    admissions: '{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    typeScript: 'export const seven: bigint = 7n;', javaScript: Buffer.from('export const seven = 7n;'),
    declarations: Buffer.from('export declare const seven: bigint;'), sourceMap: Buffer.from('{}'),
    compilerBytes: Buffer.from('fixture compiler'), compilerKind: 'test-double', typeScriptCompilerBytes: Buffer.from('fixture tsc'),
    provider: { profile: 'test-profile' }, providerSecurity: { profile: 'test-security' }, kernelContract: { id: 'test-kernel' },
    hostSources: [{ path: 'test.mjs', bytes: Buffer.from('test implementation') }], runtime: { version: 'test' }, outputStem: 'seven' });
  const languageAuthority = canonicalArtifact({ languageEdition: 'test-edition' }, 'language-authority', 'psc-language-authority-snapshot/1');
  const build = bindObservedBuildContext(observed, { languageAuthority, backendRegistry, backendId: 'typescript' });
  const resolveArtifact = identity => build.artifacts.get(artifactKey(identity));
  return { build, observed, languageAuthority, resolveArtifact };
}
test('observed products carry one exact environment and one declaration per executed edge', async () => {
  const f = fixture(), result = await verifyObservedContextProducts(f.build.graph, { resolveArtifact: f.resolveArtifact });
  assert.equal(result.present, true); assert.equal(result.bindings.length, f.build.graph.executions.length);
  assert.equal(result.hermeticityVerified, false);
  assert.equal(result.artifactBundle.claimsVerified, false);
  const products = JSON.parse(f.build.artifactBundle.bytes);
  assert.equal(products.executableArtifacts.length, 2);
  assert.equal(products.publicApiArtifacts.length, 1);
  assert.equal(products.debugArtifacts.length, 1);
  assert.equal(JSON.parse(f.build.claimSet.bytes).claims.length, 0);
  assert.deepEqual(f.build.graph.executions, f.observed.graph.executions);
  assert.throws(() => bindObservedBuildContext(f.build, { languageAuthority: f.languageAuthority,
    backendRegistry, backendId: 'typescript' }), /ALREADY_BOUND/);
});
test('archive consumer independently replays the V5 binding set', async () => {
  const f = fixture(), archive = packObservedBuildArchive(f.build);
  const allowedAssumptions = [...new Set(f.build.graph.entries.filter(entry => entry.identity.domain === 'pass-definition')
    .flatMap(entry => entry.canonicalValue.assumptionIds))];
  const result = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: f.build.identity, allowedAssumptions });
  assert.equal(result.kind, 'accepted', result.reason);
  assert.equal(result.buildContext.bindings.length, f.build.graph.executions.length);
  assert.equal(result.fullInputClosureEstablished, false);
  assert.equal(result.preservationVerified, false);
});
test('partial context, changed action input and corrupt profile bytes reject', async () => {
  const f = fixture();
  const graph = { ...f.build.graph, entries: f.build.graph.entries.filter(entry => entry.identity.domain !== 'action-binding') };
  await assert.rejects(verifyObservedContextProducts(graph, { resolveArtifact: f.resolveArtifact }), /ACTION_COVERAGE/);
  const key = artifactKey(f.build.profileEnvironment.identity);
  f.build.artifacts.set(key, Buffer.from('changed'));
  await assert.rejects(verifyObservedContextProducts(f.build.graph, { resolveArtifact: f.resolveArtifact }), /ARTIFACT_BYTES/);
});

test('rehashed action cannot omit an observed input from its exact execution binding', async () => {
  const f = fixture(), original = f.build.buildActions[0];
  const fields = JSON.parse(original.action.bytes);
  delete fields.schemaVersion; delete fields.contract;
  fields.exactInputArtifactIds = fields.exactInputArtifactIds.slice(1);
  const action = createBuildAction(fields);
  f.build.artifacts.set(artifactKey(action.identity), action.bytes);
  const binding = canonicalArtifact({ ...JSON.parse(original.binding.bytes), actionId: action.identity },
    'action-binding', 'psc-observed-action-binding/1');
  await assert.rejects(verifyObservedActionBinding(binding, { resolveArtifact: f.resolveArtifact }), /EXECUTION_BINDING/);
});

function claimFixture() {
  const f = fixture(), records = [];
  const artifact = value => {
    const record = canonicalArtifact(value, 'fixture', 'test-only/1'); records.push(record); return record;
  };
  const oldBundle = JSON.parse(f.build.artifactBundle.bytes);
  const item = { kind: 'ProvenanceBound', subjects: [oldBundle.executableArtifacts[0].artifact],
    profileEnvironmentId: oldBundle.profileEnvironmentId, evidenceClass: 'provenance-check',
    evidenceIds: [artifact('exact fixture evidence').identity],
    checkerImplementationId: artifact('consumer fixture checker').identity,
    resourcePolicyId: artifact('fixture resource policy').identity, assumptionIds: ['fixture-runtime'] };
  const claims = createClaimSet([item]);
  const fields = Object.fromEntries(['sourceSubjectId', 'profileEnvironmentId', 'executableArtifacts',
    'publicApiArtifacts', 'debugArtifacts', 'interfaceArtifacts', 'targetToolchainArtifacts', 'evidenceArtifacts']
    .map(key => [key, oldBundle[key]]));
  const bundle = createArtifactBundle({ ...fields, descriptor: f.build.backendDescriptor, claimSetId: claims.identity });
  const replaced = new Set([f.build.claimSet.identity, f.build.artifactBundle.identity].map(artifactKey));
  const entries = f.build.graph.entries.filter(entry => !replaced.has(artifactKey(entry.identity)));
  const artifacts = new Map([...f.build.artifacts].filter(([key]) => !replaced.has(key)));
  for (const record of [...records, claims, bundle]) {
    entries.push({ identity: record.identity, source: { kind: 'inline' }, canonicalValue: JSON.parse(record.bytes) });
    artifacts.set(artifactKey(record.identity), record.bytes);
  }
  const graph = { ...f.build.graph, entries };
  const graphRecord = canonicalArtifact(graph, 'build-graph', 'psc-observed-build-graph/1');
  const build = { ...f.build, ...graphRecord, graph, artifacts, claimSet: claims, artifactBundle: bundle };
  const requirement = { kind: item.kind, subjects: item.subjects, profileEnvironmentId: item.profileEnvironmentId,
    evidenceClasses: [item.evidenceClass], checkerImplementationIds: [item.checkerImplementationId],
    resourcePolicyId: item.resourcePolicyId };
  const policy = (requirements = [requirement], assumptions = ['fixture-runtime']) => canonicalArtifact({
    schemaVersion: 1, contract: 'psc-claim-policy/1', requirements, allowedAssumptions: assumptions,
  }, 'claim-policy', 'psc-claim-policy/1');
  const calls = [];
  const checker = async (evidence, claim) => {
    calls.push(claim);
    return { accepted: evidence.length === 1 && evidence[0].equals(records[0].bytes), claim };
  };
  const claimVerification = { checkers: new Map([[artifactKey(item.checkerImplementationId), checker]]),
    allowedAssumptions: ['fixture-runtime'] };
  const resolveArtifact = id => build.artifacts.get(artifactKey(id));
  const archive = packObservedBuildArchive(build);
  const allowedAssumptions = [...new Set(entries.filter(entry => entry.identity.domain === 'pass-definition')
    .flatMap(entry => entry.canonicalValue.assumptionIds))];
  return { build, item, requirement, policy, calls, claimVerification, resolveArtifact, archive, allowedAssumptions };
}

test('bundle, context and archive enforce the same exact independently selected claim policy', async () => {
  const f = claimFixture();
  const options = { claimVerification: f.claimVerification, claimPolicy: f.policy(), resolveArtifact: f.resolveArtifact };
  const bundle = await verifyArtifactBundle(f.build.artifactBundle, { ...options, expectedBundleId: f.build.artifactBundle.identity });
  const context = await verifyObservedContextProducts(f.build.graph, options);
  const archive = await verifyObservedBuildArchive(f.archive.bytes, { ...options,
    expectedGraphId: f.build.identity, allowedAssumptions: f.allowedAssumptions });
  assert.equal(archive.kind, 'accepted', archive.reason);
  for (const result of [bundle, context.artifactBundle, archive.buildContext.artifactBundle]) {
    assert.equal(result.claimsVerified, true);
    assert.equal(result.verifiedClaims.verifiedClaimCount, 1);
    assert.equal(result.claimPolicyDecision.policySatisfied, true);
    assert.equal(artifactKey(result.claimPolicyDecision.policyId), artifactKey(options.claimPolicy.identity));
    assert.equal(result.claimPolicyDecision.releaseCapabilityMinted, false);
    assert.equal(result.preservationVerified, false);
    assert.equal(result.releaseAccepted, false);
  }
  assert.equal(f.calls.length, 3);
  assert.equal(archive.semanticClaimsVerified, false);
  assert.equal(archive.fullInputClosureEstablished, false);
  const unverified = await verifyObservedBuildArchive(f.archive.bytes, {
    expectedGraphId: f.build.identity, allowedAssumptions: f.allowedAssumptions });
  assert.equal(unverified.kind, 'accepted', unverified.reason);
  assert.equal(unverified.buildContext.artifactBundle.claimsVerified, false);
  assert.equal(f.calls.length, 3);
});

test('archive claim requirements reject unavailable evidence, policy drift and empty production claims', async () => {
  const f = claimFixture();
  const options = { expectedGraphId: f.build.identity, allowedAssumptions: f.allowedAssumptions,
    claimVerification: f.claimVerification, claimPolicy: f.policy() };
  const verify = changes => verifyObservedBuildArchive(f.archive.bytes, { ...options, ...changes });
  for (const [changes, reason] of [
    [{ claimVerification: undefined }, /VERIFICATION_REQUIRED/],
    [{ claimVerification: { ...f.claimVerification, checkers: new Map() } }, /CHECKER_UNAVAILABLE/],
    [{ claimVerification: { ...f.claimVerification, allowedAssumptions: [] } }, /ASSUMPTION_DENIED/],
    [{ claimPolicy: f.policy([f.requirement], []) }, /CLAIM_POLICY_UNSATISFIED/],
    [{ claimPolicy: f.policy([{ ...f.requirement, subjects: [f.build.profileEnvironment.identity] }]) }, /CLAIM_POLICY_UNSATISFIED/],
    [{ claimPolicy: f.policy([{ ...f.requirement, profileEnvironmentId: f.item.resourcePolicyId }]) }, /CLAIM_POLICY_UNSATISFIED/],
    [{ claimPolicy: f.policy([{ ...f.requirement, resourcePolicyId: f.item.checkerImplementationId }]) }, /CLAIM_POLICY_UNSATISFIED/],
    [{ claimPolicy: f.policy([{ ...f.requirement, checkerImplementationIds: [f.item.resourcePolicyId] }]) }, /CLAIM_POLICY_UNSATISFIED/],
    [{ claimPolicy: f.policy([{ ...f.requirement, kind: 'SemanticPreservationChecked', evidenceClasses: ['formal-proof'] }]) },
      /CLAIM_POLICY_UNSATISFIED/],
    [{ claimVerification: { ...f.claimVerification, checkers: new Map([[artifactKey(f.item.checkerImplementationId),
      async (_evidence, claim) => ({ accepted: true, claim: { ...claim, subjects: [] } })]]) } }, /EVIDENCE_REJECTED/],
  ]) {
    const result = await verify(changes);
    assert.equal(result.kind, 'rejectedInvalid');
    assert.match(result.reason, reason);
  }
  const empty = fixture();
  const result = await verifyObservedBuildArchive(packObservedBuildArchive(empty.build).bytes, {
    ...options, expectedGraphId: empty.build.identity });
  assert.equal(result.kind, 'rejectedInvalid');
  assert.match(result.reason, /CLAIM_POLICY_UNSATISFIED/);
});

test('consumer selection is captured before the first resolver at every public entry', async () => {
  for (const entry of ['bundle', 'context']) {
    const f = claimFixture(), selected = f.policy();
    const expectedPolicy = artifactKey(selected.identity);
    let changed = false;
    const resolveArtifact = async id => {
      if (!changed) {
        changed = true;
        f.claimVerification.checkers.clear();
        f.claimVerification.allowedAssumptions.length = 0;
        selected.bytes.fill(0); selected.identity = f.build.identity;
      }
      return f.resolveArtifact(id);
    };
    const options = { resolveArtifact, claimVerification: f.claimVerification, claimPolicy: selected };
    const result = entry === 'bundle'
      ? await verifyArtifactBundle(f.build.artifactBundle, { ...options, expectedBundleId: f.build.artifactBundle.identity })
      : (await verifyObservedContextProducts(f.build.graph, options)).artifactBundle;
    assert.equal(result.claimPolicyDecision.policySatisfied, true);
    assert.equal(artifactKey(result.claimPolicyDecision.policyId), expectedPolicy);
    assert.equal(f.calls.length, 1);
  }
});

test('archive claim callbacks cannot replace selected policy or expand pass assumptions', async () => {
  const f = claimFixture(), selected = f.policy(), expectedPolicy = artifactKey(selected.identity);
  const allowed = [];
  f.claimVerification.checkers.set(artifactKey(f.item.checkerImplementationId), async (_evidence, claim) => {
    selected.bytes.fill(0); selected.identity = f.build.identity;
    allowed.push(...f.allowedAssumptions);
    return { accepted: true, claim };
  });
  const options = { expectedGraphId: f.build.identity, claimVerification: f.claimVerification, claimPolicy: selected };
  const rejected = await verifyObservedBuildArchive(f.archive.bytes, { ...options, allowedAssumptions: allowed });
  assert.equal(rejected.kind, 'rejectedInvalid');
  assert.match(rejected.reason, /ASSUMPTION/);
  // A fresh independently allowed run still uses the policy selected at entry.
  const nextPolicy = f.policy();
  options.claimPolicy = nextPolicy;
  f.claimVerification.checkers.set(artifactKey(f.item.checkerImplementationId), async (_evidence, claim) => {
    nextPolicy.bytes.fill(0); return { accepted: true, claim };
  });
  const accepted = await verifyObservedBuildArchive(f.archive.bytes, { ...options, allowedAssumptions: f.allowedAssumptions });
  assert.equal(accepted.kind, 'accepted', accepted.reason);
  assert.equal(artifactKey(accepted.buildContext.artifactBundle.claimPolicyDecision.policyId), expectedPolicy);
});

test('legacy archives cannot silently ignore requested claim verification', async () => {
  const f = fixture();
  await assert.rejects(verifyObservedContextProducts(f.observed.graph,
    { resolveArtifact: f.resolveArtifact, claimVerification: {} }), /CLAIM_CONTEXT_REQUIRED/);
  const allowedAssumptions = [...new Set(f.observed.graph.entries.filter(entry => entry.identity.domain === 'pass-definition')
    .flatMap(entry => entry.canonicalValue.assumptionIds))];
  const archive = packObservedBuildArchive(f.observed);
  const accepted = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: f.observed.identity, allowedAssumptions });
  assert.equal(accepted.kind, 'accepted', accepted.reason);
  const rejected = await verifyObservedBuildArchive(archive.bytes, {
    expectedGraphId: f.observed.identity, allowedAssumptions, claimVerification: {} });
  assert.equal(rejected.kind, 'rejectedInvalid');
  assert.match(rejected.reason, /CLAIM_CONTEXT_REQUIRED/);
});
