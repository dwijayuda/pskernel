import assert from 'node:assert/strict';
import { test } from 'node:test';
import { canonicalArtifact, canonicalBytes, artifactKey } from './artifact-evidence.mjs';
import { knowledgeObject } from './savef-graph.mjs';
import { failureKnowledge, validFailureKnowledge, knowledgeMigrationSubject,
  verifyKnowledgeMigration, createKnowledgeReuseSession } from './savef-lifecycle.mjs';
import { createCertificateBoundary } from './certificate-boundary.mjs';

const artifact = value => canonicalArtifact(value, 'fixture', 'fixture/1');
function fixture() {
  const payload = artifact({ pass: 'increment-fixture' }), license = artifact({ spdx: 'MIT' });
  const context = { semanticIdentity: { fixture: 1 }, scope: { fixture: true }, allowedAssumptions: [], requiredClaims: [] };
  const knowledge = knowledgeObject({ contract: 'psc-knowledge-object/2', kind: 'compiler', semanticIdentity: context.semanticIdentity,
    authorityClass: 'advisory', scope: context.scope, dependencies: [], assumptions: [], claims: [], payload: payload.identity,
    license: license.identity, evidence: [], provenance: [], implementationWitnesses: [], resourceEvidence: [], supersedes: [], migrations: [] });
  const blobs = new Map([payload, license, knowledge].map(item => [artifactKey(item.identity), item.bytes]));
  const session = createKnowledgeReuseSession({ context, claimPolicies: new Map(), resolveArtifact: id => blobs.get(artifactKey(id)),
    assuranceBefore: { fixtureValidated: true }, operations: new Map([['increment', { identity: payload.identity, useType: 'pass',
      run: async ({ input }) => artifact({ result: JSON.parse(input.bytes).value + 1 }) }]]),
    acceptOutput: async ({ output, subject, uses }) => {
      if (uses.length && !uses.every(use => use.output.bytes.equals(output.bytes))) return { kind: 'rejectedInvalid' };
      return { kind: 'accepted', subject, assuranceAfter: { fixtureValidated: true } };
    } });
  return { session, knowledge, task: artifact({ task: 'fixture' }), input: artifact({ value: 4 }) };
}

test('retrieval creates no reuse event; a performed operation needs output acceptance', async () => {
  const f = fixture(), handle = await f.session.acquire([f.knowledge.identity]);
  const noUse = await f.session.accept({ task: f.task, output: artifact({ result: 5 }), uses: [], counterfactualArm: 'B2', costObservation: {} });
  assert.deepEqual(noUse.events, []);
  const use = await f.session.apply(handle, { operationId: 'increment', task: f.task, input: f.input });
  const rejected = await f.session.accept({ task: f.task, output: artifact({ result: 9 }), uses: [use.execution], counterfactualArm: 'B3', costObservation: {} });
  assert.equal(rejected.kind, 'rejectedInvalid');
  const accepted = await f.session.accept({ task: f.task, output: use.output, uses: [use.execution], counterfactualArm: 'B3', costObservation: { modelCalls: 1 } });
  assert.equal(accepted.events.length, 1);
  assert.equal(JSON.parse(accepted.events[0].bytes).causalImprovement, 'not-established');
  await assert.rejects(f.session.accept({ task: f.task, output: use.output, uses: [use.execution], counterfactualArm: 'B3', costObservation: {} }), /USE_NOT_LIVE/);
});

test('serialized handles, cross-task use and revoked knowledge cannot count as reuse', async () => {
  const f = fixture(), handle = await f.session.acquire([f.knowledge.identity]);
  await assert.rejects(f.session.apply(JSON.parse(JSON.stringify(handle)), { operationId: 'increment', task: f.task, input: f.input }), /HANDLE_OR_OPERATION/);
  const use = await f.session.apply(handle, { operationId: 'increment', task: f.task, input: f.input });
  await assert.rejects(f.session.accept({ task: artifact({ task: 'another' }), output: use.output, uses: [use.execution], counterfactualArm: 'B3', costObservation: {} }), /USE_NOT_LIVE/);
  f.session.revoke(handle);
  await assert.rejects(f.session.accept({ task: f.task, output: use.output, uses: [use.execution], counterfactualArm: 'B3', costObservation: {} }), /USE_NOT_LIVE/);
});

test('failure knowledge requires the exact context, validity horizon and evidence bytes', async () => {
  const context = artifact({ context: 1 }), strategy = artifact({ strategy: 'fixture' }), evidence = artifact({ failure: 'fixture' });
  const blobs = new Map([context, strategy, evidence].map(item => [artifactKey(item.identity), item.bytes]));
  const record = failureKnowledge({ contract: 'psc-failure-knowledge/1', contextId: context.identity, scope: 'fixture-only',
    validUntilEpochMs: 1000, failedStrategyId: strategy.identity, reproducerId: strategy.identity, evidenceIds: [evidence.identity],
    cause: 'fixture failure', supersedes: [] });
  const policy = { contextId: context.identity, scope: 'fixture-only', nowEpochMs: 999, resolveArtifact: id => blobs.get(artifactKey(id)) };
  assert.equal((await validFailureKnowledge(record, policy)).authority, 'advisory');
  assert.equal((await validFailureKnowledge(record, { ...policy, nowEpochMs: 1001 })).kind, 'declinedUnsupported');
  assert.equal((await validFailureKnowledge(record, { ...policy, supersededIds: [record.identity] })).kind, 'declinedUnsupported');
  blobs.set(artifactKey(evidence.identity), Buffer.from('tampered'));
  await assert.rejects(validFailureKnowledge(record, policy), /ARTIFACT_BYTES/);
});

test('migration validation binds both contexts, exact objects and declared losses', async () => {
  const source = artifact({ source: 1 }), destination = artifact({ destination: 1 });
  const subject = knowledgeMigrationSubject({ contract: 'psc-knowledge-migration/1', sourceContextId: source.identity,
    destinationContextId: destination.identity, sourceObjectId: source.identity, destinationObjectId: destination.identity,
    transformationId: source.identity, preservationClaimId: 'fixture-migration', losses: ['fixture-annotation'] });
  const boundary = createCertificateBoundary({ checkers: new Map([['fixture-migration', {
    claimClass: 'fixture-migration', identity: { fixture: true }, verify: async (bytes, requested) => {
      if (!bytes.equals(canonicalBytes({ fixture: true }))) return { kind: 'rejectedInvalid' };
      return { kind: 'accepted', subjectId: requested.identity, claimClass: 'fixture-migration', evidence: {} };
    },
  }]]) });
  const certificate = canonicalArtifact({ contract: 'psc-certificate/1', checkerId: 'fixture-migration', subjectId: subject.identity,
    payload: { fixture: true } }, 'certificate', 'psc-certificate/1');
  const policy = { subjectId: subject.identity, checkerId: 'fixture-migration', claimClass: 'fixture-migration', allowedLosses: [] };
  const resolveArtifact = id => artifactKey(id) === artifactKey(source.identity) ? source.bytes : destination.bytes;
  await assert.rejects(verifyKnowledgeMigration({ subject, certificate, policy, resolveArtifact, certificateBoundary: boundary }), /MIGRATION_POLICY/);
  const result = await verifyKnowledgeMigration({ subject, certificate, policy: { ...policy, allowedLosses: ['fixture-annotation'] }, resolveArtifact, certificateBoundary: boundary });
  assert.equal(result.kind, 'accepted'); assert.equal(result.destinationValidity, 'requires-fresh-context-check');
});
