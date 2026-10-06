import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { knowledgeObject } from './savef-graph.mjs';
import { createKnowledgeReuseSession } from './savef-lifecycle.mjs';
import { factoryBenchArms, freezeFactoryHoldout, runFactoryBench } from './factory-bench.mjs';

const artifact = value => canonicalArtifact(value, 'fixture', 'fixture/1');
function fixture({ limits = {}, assurance = ['fixture-exact-output'], producerRun } = {}) {
  const identities = { producerId: artifact({ producer: 'fixture' }).identity, modelId: artifact({ model: 'fixture' }).identity,
    acceptorId: artifact({ acceptor: 'fixture' }).identity, toolPolicyId: artifact({ tools: 'fixture' }).identity };
  const policy = artifact({ contract: 'psc-factory-policy/1', ...identities, minimumTasks: 1,
    requiredAssurance: ['fixture-exact-output'], limits: { maxModelCalls: 3, maxTokens: 100, maxToolCalls: 20,
      maxCandidateBytes: 2048, maxWallMs: 1000, ...limits } });
  const tasks = [{ taskId: 'private-fixture-task', prompt: artifact({ instruction: 'return the fixture result' }), oracle: artifact({ result: 10 }) }];
  const holdout = freezeFactoryHoldout({ tasks, policy });
  const payload = artifact({ operation: 'fixture-increment' }), license = artifact({ spdx: 'MIT' });
  const context = { semanticIdentity: { fixture: 1 }, scope: { fixture: true }, allowedAssumptions: [], requiredClaims: [] };
  const knowledge = knowledgeObject({ contract: 'psc-knowledge-object/2', kind: 'compiler', authorityClass: 'advisory',
    semanticIdentity: context.semanticIdentity, scope: context.scope, dependencies: [], assumptions: [], claims: [],
    payload: payload.identity, license: license.identity, implementationWitnesses: [], evidence: [], provenance: [],
    resourceEvidence: [], supersedes: [], migrations: [] });
  const blobs = new Map([knowledge, payload, license].map(item => [artifactKey(item.identity), item.bytes]));
  const acceptor = { identity: identities.acceptorId, run: async ({ oracle, candidate, subject }) =>
    oracle.bytes.equals(candidate.bytes) ? { kind: 'accepted', subject, assurance } : { kind: 'rejectedInvalid' } };
  const createReuseSession = (_prompt, oracle) => createKnowledgeReuseSession({ context, claimPolicies: new Map(),
    resolveArtifact: id => blobs.get(artifactKey(id)), assuranceBefore: { fixture: true },
    operations: new Map([['increment', { identity: payload.identity, useType: 'pass',
      run: async ({ input }) => artifact({ result: JSON.parse(input.bytes).value + 1 }) }]]),
    acceptOutput: async ({ output, subject, uses }) => oracle.bytes.equals(output.bytes) && uses.every(use => use.output.bytes.equals(output.bytes))
      ? { kind: 'accepted', subject, assuranceAfter: { fixture: true } } : { kind: 'rejectedInvalid' } });
  const producer = { identity: identities.producerId, run: producerRun ?? (async ({ arm, tools }) => {
    // Registered deterministic fixture adapter. No actual model service or
    // real holdout is used by these focused instrumentation tests.
    const generated = await tools.model({ instruction: 'fixture' });
    if (arm === 'B0') return { candidate: artifact(generated) };
    const retrieved = await tools.retrieve('fixture');
    if (['B3', 'B4'].includes(arm)) {
      const used = await tools.reuse({ objectId: retrieved[0].objectId, operationId: 'increment', input: artifact({ value: 9 }) });
      return { candidate: used.output, usedTokens: [used.useToken] };
    }
    return { candidate: artifact(generated) };
  }) };
  const model = { identity: identities.modelId, run: async () => ({ output: { result: 10 }, usage: { inputTokens: 2, outputTokens: 3 } }) };
  const corpus = [{ kind: 'knowledge', text: 'fixture increment', originTaskIds: [], artifact: knowledge }];
  return { holdout, policy, producer, model, acceptor, corpus, createReuseSession,
    toolPolicyId: identities.toolPolicyId, tasks };
}

test('balanced B0-B4 records measured calls and accepted reuse, never counts retrieval as reuse', async () => {
  const f = fixture(), report = await runFactoryBench(f), value = JSON.parse(report.bytes);
  assert.deepEqual(value.rows.map(row => row.arm), factoryBenchArms);
  assert(value.rows.every(row => row.metrics.accepted));
  assert.deepEqual(value.rows.map(row => row.metrics.reuseCount), [0, 0, 0, 1, 1]);
  assert.deepEqual(value.rows.map(row => row.metrics.verifierCalls), [1, 1, 2, 3, 3]);
  assert(value.rows.every(row => row.metrics.modelCalls === 1 && row.metrics.tokens === 5));
  assert.equal(value.selfAmplification, 'not-established'); assert.equal(value.releaseAccepted, false);
  assert(report.privateArtifacts.length >= 3);
  const seal = JSON.parse(f.holdout.seal.bytes);
  assert.equal(seal.searchableByFactory, false);
  assert(!f.holdout.seal.bytes.includes(Buffer.from('return the fixture result')));
});

test('frozen policy changes, task-origin leakage and exact prompt/oracle leakage are rejected', async () => {
  const f = fixture();
  const changed = JSON.parse(f.policy.bytes); changed.limits.maxTokens++;
  await assert.rejects(runFactoryBench({ ...f, policy: artifact(changed) }), /SEAL/);
  await assert.rejects(runFactoryBench({ ...f, corpus: [{ ...f.corpus[0], originTaskIds: [f.tasks[0].taskId] }] }), /LEAKAGE/);
  await assert.rejects(runFactoryBench({ ...f, corpus: [{ ...f.corpus[0], artifact: f.tasks[0].oracle }] }), /LEAKAGE/);
  await assert.rejects(runFactoryBench({ ...f, corpus: [{ ...f.corpus[0], text: f.tasks[0].prompt.bytes.toString() }] }), /LEAKAGE/);
});

test('assurance regression and invented reuse tokens cannot count as accepted output', async () => {
  const weak = JSON.parse((await runFactoryBench(fixture({ assurance: [] }))).bytes);
  assert(weak.rows.every(row => !row.metrics.accepted && row.code === 'assurance-regression'));
  const forged = fixture({ producerRun: async () => ({ candidate: artifact({ result: 10 }), usedTokens: [0] }) });
  const result = JSON.parse((await runFactoryBench(forged)).bytes);
  assert(result.rows.every(row => !row.metrics.accepted && row.metrics.reuseCount === 0));
});

test('resource limits stop further calls and incomplete model usage stays explicitly incomplete', async () => {
  const capped = JSON.parse((await runFactoryBench(fixture({ limits: { maxModelCalls: 0 } }))).bytes);
  assert(capped.rows.every(row => row.outcome === 'resourceExhausted' && row.metrics.modelCalls === 0));
  const missing = fixture(); missing.model.run = async () => ({ output: {} });
  const result = JSON.parse((await runFactoryBench(missing)).bytes);
  assert(result.rows.every(row => row.outcome === 'infrastructureUnavailable' && row.metrics.tokensComplete === false));
});

test('arm restrictions and rejected-candidate revisions are measured through actual tool calls', async () => {
  const denied = fixture({ producerRun: async ({ tools }) => {
    await tools.retrieve('fixture'); return { candidate: artifact({ result: 10 }) };
  } });
  const blocked = JSON.parse((await runFactoryBench(denied)).bytes);
  assert.equal(blocked.rows[0].metrics.accepted, false);
  const repaired = fixture({ producerRun: async ({ tools }) => {
    await tools.verify(artifact({ result: 9 })); return { candidate: artifact({ result: 10 }) };
  } });
  const result = JSON.parse((await runFactoryBench(repaired)).bytes);
  assert(result.rows.every(row => row.metrics.accepted && row.metrics.repairCycles === 1 && row.metrics.verifierCalls === 2));
});
