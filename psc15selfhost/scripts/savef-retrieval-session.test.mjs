import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { knowledgeObject } from './savef-graph.mjs';
import { buildSavefSemanticIndex } from './savef-index.mjs';
import { createKnowledgeReuseSession } from './savef-lifecycle.mjs';
import { createSavefRetrievalSession } from './savef-retrieval-session.mjs';

const artifact = value => canonicalArtifact(value, 'fixture', 'fixture/1');

test('persistent index retrieval requires ValidUnder, supports reuse, and only acceptance publishes reuse', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'psc-savef-retrieval-'));
  try {
    const semanticIdentity = { language: 'proofscript', profile: 'psc-v3' };
    const scope = { package: 'fixture', version: 1 };
    const payload = artifact({ operation: 'increment' });
    const license = artifact({ spdx: 'MIT' });
    const knowledge = knowledgeObject({
      contract: 'psc-knowledge-object/2', kind: 'compiler', semanticIdentity,
      authorityClass: 'advisory', scope, dependencies: [], assumptions: [], claims: [],
      payload: payload.identity, implementationWitnesses: [], evidence: [], provenance: [],
      resourceEvidence: [], license: license.identity, supersedes: [], migrations: [],
    });
    const blobs = new Map([payload, license, knowledge].map(item => [artifactKey(item.identity), item.bytes]));
    await buildSavefSemanticIndex({ root, records: [knowledge] });
    const task = artifact({ task: 'next-untrusted-proposal' }), input = artifact({ value: 4 });
    const reuse = createKnowledgeReuseSession({
      context: { semanticIdentity, scope, allowedAssumptions: [], requiredClaims: [] },
      claimPolicies: new Map(), resolveArtifact: async id => blobs.get(artifactKey(id)),
      assuranceBefore: { verified: true },
      operations: new Map([['increment', { identity: payload.identity, useType: 'pass',
        run: async ({ input }) => artifact({ result: JSON.parse(input.bytes).value + 1 }) }]]),
      acceptOutput: async ({ output, subject, uses }) => uses.length === 1 && uses[0].output.bytes.equals(output.bytes)
        ? { kind: 'accepted', subject, assuranceAfter: { verified: true } }
        : { kind: 'rejectedInvalid' },
    });
    const tool = createSavefRetrievalSession({
      indexRoot: root, reuseSession: reuse, resolveArtifact: async id => blobs.get(artifactKey(id)),
    });
    const found = await tool.retrieve({ semanticIdentity, scope, kinds: ['compiler'] });
    assert.equal(found.results.length, 1);
    assert.equal(found.authority, 'validated-knowledge-context-not-semantic-authority');
    const used = await tool.reuse({ token: found.results[0].token, operationId: 'increment', task, input });
    assert.deepEqual(JSON.parse(used.output.bytes), { result: 5 });
    const rejected = await tool.accept({ task, output: artifact({ result: 9 }), useTokens: [used.useToken],
      counterfactualArm: 'B3', costObservation: { modelCalls: 1 } });
    assert.equal(rejected.kind, 'rejectedInvalid');
    const accepted = await tool.accept({ task, output: used.output, useTokens: [used.useToken],
      counterfactualArm: 'B3', costObservation: { modelCalls: 1 } });
    assert.equal(accepted.kind, 'accepted');
    assert.equal(accepted.events.length, 1);
    assert.equal(JSON.parse(accepted.events[0].bytes).causalImprovement, 'not-established');
    await assert.rejects(tool.accept({ task, output: used.output, useTokens: [used.useToken],
      counterfactualArm: 'B3', costObservation: {} }), /USE_TOKEN/);
    tool.close();
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('an index hit cannot bypass fresh ValidUnder resolution', async () => {
  const root = await mkdtemp(path.join(tmpdir(), 'psc-savef-retrieval-negative-'));
  try {
    const semanticIdentity = { language: 'proofscript', profile: 'psc-v3' }, scope = { package: 'fixture', version: 1 };
    const payload = artifact({ value: 1 }), license = artifact({ spdx: 'MIT' });
    const knowledge = knowledgeObject({ contract: 'psc-knowledge-object/2', kind: 'artifact', semanticIdentity,
      authorityClass: 'advisory', scope, dependencies: [], assumptions: [], claims: [], payload: payload.identity,
      implementationWitnesses: [], evidence: [], provenance: [], resourceEvidence: [], license: license.identity,
      supersedes: [], migrations: [] });
    await buildSavefSemanticIndex({ root, records: [knowledge] });
    const reuse = createKnowledgeReuseSession({
      context: { semanticIdentity, scope, allowedAssumptions: [], requiredClaims: [] },
      claimPolicies: new Map(), resolveArtifact: async () => Buffer.from('tampered'),
      assuranceBefore: {}, operations: new Map(), acceptOutput: async () => ({ kind: 'rejectedInvalid' }),
    });
    const tool = createSavefRetrievalSession({ indexRoot: root, reuseSession: reuse,
      resolveArtifact: async id => artifactKey(id) === artifactKey(knowledge.identity) ? knowledge.bytes : Buffer.from('tampered') });
    await assert.rejects(tool.retrieve({ semanticIdentity, scope }), /ARTIFACT_BYTES/);
    tool.close();
  } finally { await rm(root, { recursive: true, force: true }); }
});
