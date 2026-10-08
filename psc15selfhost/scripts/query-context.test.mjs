import assert from 'node:assert/strict';
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import { artifactKey, canonicalArtifact, passDefinition } from './artifact-evidence.mjs';
import { createQueryKey, verifyQueryKey, applyPassEffects } from './query-context.mjs';
import { readQueryEvidenceCache } from './query-evidence-cache.mjs';
import { semanticReuseCandidateArtifact } from './semantic-query-cache.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { bindObservedBuildContext, verifyObservedContextProducts } from './observed-build-context.mjs';
const registry = canonicalArtifact(JSON.parse(await readFile(new URL('../contracts/backends/BACKEND_REGISTRY_V1.json', import.meta.url))),
  'backend-registry', 'psc-backend-registry/1');
function fixture() {
  const original = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['def answer := 1'], admissions: '{}',
    typeScript: 'export const answer = 1n;', compilerBytes: Buffer.from('fixture compiler'), compilerKind: 'fixture',
    provider: { profile: 'test-profile' }, providerSecurity: {}, kernelContract: { id: 'test-only' },
    hostSources: [], runtime: { version: 'fixture' } });
  const languageAuthority = canonicalArtifact({ languageEdition: 'test-only' }, 'language-authority', 'psc-language-authority-snapshot/1');
  const build = bindObservedBuildContext(original, { languageAuthority, backendRegistry: registry, backendId: 'typescript' });
  const resolveArtifact = identity => build.artifacts.get(artifactKey(identity));
  const query = build.queryKeys[0], action = JSON.parse(build.buildActions[0].action.bytes);
  const definitionId = action.passDefinitionId, definition = { identity: definitionId, bytes: resolveArtifact(definitionId) };
  return { build, resolveArtifact, query, action, definition };
}
test('observed query keys cover every action input and independently replay in archives', async () => {
  const f = fixture(), result = await verifyQueryKey(f.query, { expectedQueryId: f.query.identity, resolveArtifact: f.resolveArtifact });
  assert.equal(result.value.declaredInputs.length, f.action.exactInputArtifactIds.length);
  const context = await verifyObservedContextProducts(f.build.graph, { resolveArtifact: f.resolveArtifact });
  assert.equal(context.queryKeysVerified, true);
  assert.equal(context.queries.length, f.build.graph.executions.length);
  assert(context.queries.every(query => query.effects.fingerprints.length === 0));
});
test('rehashed query omission and class changes cannot satisfy the consumer selection', async () => {
  const f = fixture(), value = JSON.parse(f.query.bytes);
  delete value.schemaVersion; delete value.contract;
  const missing = createQueryKey({ ...value, declaredInputs: value.declaredInputs.slice(1) });
  await assert.rejects(verifyQueryKey(missing, { expectedQueryId: missing.identity, resolveArtifact: f.resolveArtifact }), /INPUT_COVERAGE/);
  const changed = createQueryKey({ ...value, declaredInputs: value.declaredInputs.map((input, i) =>
    i === 0 ? { ...input, fingerprintClass: 'origin' } : input) });
  await assert.rejects(verifyQueryKey(changed, { expectedQueryId: f.query.identity, resolveArtifact: f.resolveArtifact }), /CONSUMER_SELECTION/);
  assert.throws(() => createQueryKey({ ...value, declaredInputs: [{ ...value.declaredInputs[0], fingerprintClass: 'unknown' }] }), /FINGERPRINT_CLASS/);
});
test('pass effects preserve only explicit facts and enforce required analyses/profiles', () => {
  const f = fixture(), value = JSON.parse(f.definition.bytes);
  const selected = passDefinition({ ...value, effects: { ...value.effects, requiresAnalyses: ['types'],
    preservesAnalyses: ['types'], invalidatesAnalyses: ['other'], preservesInterfaces: ['structural'],
    invalidatesInterfaces: [], preservesFingerprints: ['runtime'], invalidatesFingerprints: [] } });
  const available = { semanticProfile: 'test-profile', analyses: ['types', 'other'],
    interfaces: ['structural', 'behavioral'], fingerprints: ['runtime', 'origin'] };
  const result = applyPassEffects(selected, available);
  assert.deepEqual(result.analyses, ['types']); assert.deepEqual(result.interfaces, ['structural']);
  assert.deepEqual(result.fingerprints, ['runtime']); assert.equal(result.capabilityRevalidationRequired, true);
  assert.throws(() => applyPassEffects(selected, { ...available, analyses: [] }), /ANALYSIS_REQUIRED/);
  assert.throws(() => applyPassEffects(selected, { ...available, semanticProfile: 'other-profile' }), /PROFILE_UNSUPPORTED/);
  for (const effect of [{ authorityEffect: 'trustExpanding' }, { assuranceClass: 'unassured' }]) {
    const untrusted = passDefinition({ ...value, effects: { ...JSON.parse(selected.bytes).effects, ...effect } });
    const discarded = applyPassEffects(untrusted, available);
    assert.equal(discarded.semanticReusePermitted, false);
    assert.deepEqual([discarded.analyses, discarded.interfaces, discarded.fingerprints], [[], [], []]);
  }
});
test('cache adapter derives the old action from verified current query context', async () => {
  const f = fixture(), legacy = f.action.exactInputArtifactIds.find(id => id.domain === 'action');
  const candidate = semanticReuseCandidateArtifact({ actionId: legacy });
  const options = { query: f.query, expectedQueryId: f.query.identity, candidate, expectedCandidateId: candidate.identity,
    resolveArtifact: f.resolveArtifact, root: 'nonexistent-fixture-cache', requiredEvidenceKinds: ['translation-validation'] };
  const result = await readQueryEvidenceCache(options);
  assert.equal(result.hit, false); assert.equal(result.authority, 'none');
  assert.deepEqual(result.buildActionId, JSON.parse(f.query.bytes).buildActionId);
  const other = canonicalArtifact('other action', 'action', 'psc-action/1');
  const transplanted = semanticReuseCandidateArtifact({ actionId: other.identity });
  await assert.rejects(readQueryEvidenceCache({ ...options, candidate: transplanted, expectedCandidateId: transplanted.identity }), /ACTION_SELECTION/);
});
