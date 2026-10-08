import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { verifyKnowledgeGraph } from './savef-graph.mjs';

const copy = value => JSON.parse(canonicalBytes(value));
const same = (left, right) => canonicalBytes(left).equals(canonicalBytes(right));
const fail = code => { throw new Error('PSC_REUSE_' + code); };
const natural = value => Number.isSafeInteger(value) && value >= 0;
const text = value => typeof value === 'string' && value.length > 0;

/** Negative knowledge is scoped advice, never authority to reject a proof. */
export function failureKnowledge(fields) {
  const value = copy(fields);
  if (value.contract !== 'psc-failure-knowledge/1' || !text(value.cause) || !text(value.scope) ||
      !natural(value.validUntilEpochMs) || !Array.isArray(value.evidenceIds) || !value.evidenceIds.length ||
      !Array.isArray(value.supersedes)) fail('FAILURE_SCHEMA');
  for (const id of [value.contextId, value.failedStrategyId, value.reproducerId, ...value.evidenceIds, ...value.supersedes]) artifactKey(id);
  return canonicalArtifact({ ...value, authority: 'advisory' }, 'failure-knowledge', 'psc-failure-knowledge/1');
}

export async function validFailureKnowledge(record, { contextId, scope, nowEpochMs, resolveArtifact, supersededIds = [] }) {
  verifyArtifact(record.bytes, record.identity);
  const value = JSON.parse(record.bytes), expected = failureKnowledge(value);
  if (artifactKey(expected.identity) !== artifactKey(record.identity) || !natural(nowEpochMs) ||
      artifactKey(value.contextId) !== artifactKey(contextId) || value.scope !== scope || nowEpochMs > value.validUntilEpochMs ||
      supersededIds.some(id => artifactKey(id) === artifactKey(record.identity))) return { kind: 'declinedUnsupported', feature: 'stale-negative-knowledge' };
  for (const id of [value.contextId, value.failedStrategyId, value.reproducerId, ...value.evidenceIds, ...value.supersedes]) {
    verifyArtifact(await resolveArtifact(id), id);
  }
  return { kind: 'accepted', objectId: record.identity, authority: 'advisory', cause: value.cause };
}

/** All preservation subjects bind the actual source, destination, contexts,
 * transformation and declared losses. A migration never changes graph context
 * implicitly; destination validity must still be checked separately.
 */
export function knowledgeMigrationSubject(fields) {
  const value = copy(fields);
  if (value.contract !== 'psc-knowledge-migration/1' || !text(value.preservationClaimId) ||
      !Array.isArray(value.losses) || !value.losses.every(text) || new Set(value.losses).size !== value.losses.length) fail('MIGRATION_SCHEMA');
  for (const field of ['sourceContextId', 'destinationContextId', 'sourceObjectId', 'destinationObjectId', 'transformationId']) artifactKey(value[field]);
  return canonicalArtifact(value, 'migration-subject', 'psc-knowledge-migration/1');
}

export async function verifyKnowledgeMigration({ subject, certificate, policy, resolveArtifact, certificateBoundary }) {
  policy = copy(policy);
  verifyArtifact(subject.bytes, subject.identity);
  const value = JSON.parse(subject.bytes), expected = knowledgeMigrationSubject(value);
  if (artifactKey(expected.identity) !== artifactKey(subject.identity) || artifactKey(policy.subjectId) !== artifactKey(subject.identity) ||
      !Array.isArray(policy.allowedLosses) || value.losses.some(loss => !policy.allowedLosses.includes(loss))) fail('MIGRATION_POLICY');
  for (const field of ['sourceContextId', 'destinationContextId', 'sourceObjectId', 'destinationObjectId', 'transformationId']) {
    verifyArtifact(await resolveArtifact(value[field]), value[field]);
  }
  const result = await certificateBoundary.check({ subject, certificate });
  if (result.kind !== 'accepted') return result;
  const receipt = certificateBoundary.describe(result.value); certificateBoundary.revoke(result.value);
  if (receipt.checkerId !== policy.checkerId || receipt.claimClass !== policy.claimClass) fail('MIGRATION_CLAIM');
  return { kind: 'accepted', subjectId: subject.identity, validationId: result.receipt.identity,
    sourceObjectId: value.sourceObjectId, destinationObjectId: value.destinationObjectId,
    losses: value.losses, destinationValidity: 'requires-fresh-context-check', authority: 'audit-record-only' };
}

/** Registry operations and output acceptance are trusted adapters. Retrieval
 * only creates a live validity handle. Reuse requires a real registered call,
 * and its event is published only when output acceptance verifies the use.
 */
export function createKnowledgeReuseSession({ context, claimPolicies, certificateBoundary, resolveArtifact,
  operations, acceptOutput, assuranceBefore, maxArtifactBytes = 16 * 1024 * 1024 }) {
  if (!(operations instanceof Map) || typeof acceptOutput !== 'function' || !natural(maxArtifactBytes)) fail('CONFIGURATION');
  context = copy(context); assuranceBefore = copy(assuranceBefore);
  claimPolicies = new Map([...claimPolicies].map(([name, policy]) => [name, copy(policy)]));
  const selected = new Map([...operations].map(([name, entry]) => [name, { ...entry, identity: copy(entry.identity) }]));
  for (const [name, entry] of selected) {
    if (!text(name) || typeof entry.run !== 'function' || !['theorem', 'interface', 'pass', 'negative-strategy', 'certificate'].includes(entry.useType)) fail('OPERATION');
    artifactKey(entry.identity);
  }
  const knowledge = new WeakMap(), executions = new WeakMap(); let closed = false;
  const counts = { graphChecks: 0, certificateChecks: 0, outputChecks: 0, operationCalls: 0 };
  const measuredBoundary = certificateBoundary ? {
    check: async value => { counts.certificateChecks++; return certificateBoundary.check(value); },
    describe: handle => certificateBoundary.describe(handle), revoke: handle => certificateBoundary.revoke(handle),
  } : undefined;
  function open() { if (closed) fail('CLOSED'); }
  function snapshot(item) {
    if (!(item.bytes instanceof Uint8Array) || item.bytes.byteLength > maxArtifactBytes) fail('RESOURCE_EXHAUSTED');
    const bytes = Buffer.from(item.bytes), identity = copy(item.identity);
    verifyArtifact(bytes, identity); return { bytes, identity };
  }
  return Object.freeze({
    measurements() { return { ...counts }; },
    operationInfo(operationId) {
      open(); const operation = selected.get(operationId);
      if (!operation) fail('OPERATION');
      return { identity: copy(operation.identity), useType: operation.useType };
    },
    async acquire(roots) {
      open(); const blobs = new Map();
      counts.graphChecks++;
      const validity = await verifyKnowledgeGraph({ roots, context, claimPolicies, certificateBoundary: measuredBoundary,
        limits: { maxArtifactBytes }, resolveArtifact: async identity => {
          const item = snapshot({ identity, bytes: await resolveArtifact(identity) });
          blobs.set(artifactKey(identity), item.bytes); return item.bytes;
        } });
      open();
      const handle = Object.freeze({ capability: 'psc-live-knowledge-validity/1' });
      knowledge.set(handle, { validity: copy(validity), blobs }); return handle;
    },
    async apply(handle, { operationId, task, input }) {
      open(); const found = knowledge.get(handle), operation = selected.get(operationId);
      if (!found || !operation) fail('HANDLE_OR_OPERATION');
      task = snapshot(task); input = snapshot(input);
      counts.operationCalls++;
      const output = snapshot(await operation.run({ task: snapshot(task), input: snapshot(input),
        validity: copy(found.validity), resolveArtifact: identity => {
          const bytes = found.blobs.get(artifactKey(identity));
          if (!bytes) fail('OPERATION_ARTIFACT_OUTSIDE_VALIDATED_CLOSURE');
          return Buffer.from(bytes);
        } }));
      open(); if (!knowledge.has(handle)) fail('REVOKED');
      const record = canonicalArtifact({ contract: 'psc-knowledge-use/1', operationId,
        operationIdentity: operation.identity, useType: operation.useType, taskId: task.identity,
        inputId: input.identity, outputId: output.identity, knowledgeIds: found.validity.objectIds,
        context: found.validity.context, authority: 'observed-operation-only' }, 'knowledge-use', 'psc-knowledge-use/1');
      const execution = Object.freeze({ capability: 'psc-live-knowledge-use/1' });
      executions.set(execution, { record, task, input, output, knowledgeHandle: handle });
      return { execution, record, output: snapshot(output) };
    },
    async accept({ task, output, uses, counterfactualArm, costObservation }) {
      open(); task = snapshot(task); output = snapshot(output); uses = [...uses];
      costObservation = copy(costObservation);
      if (!text(counterfactualArm) || new Set(uses).size !== uses.length) fail('EVENT_FIELDS');
      const observed = uses.map(handle => {
        const found = executions.get(handle);
        if (!found || !knowledge.has(found.knowledgeHandle) || artifactKey(found.task.identity) !== artifactKey(task.identity)) fail('USE_NOT_LIVE_FOR_TASK');
        return found;
      });
      const subject = { taskId: task.identity, outputId: output.identity, useIds: observed.map(item => item.record.identity) };
      counts.outputChecks++;
      const result = await acceptOutput({ task: snapshot(task), output: snapshot(output), subject: copy(subject),
        uses: observed.map(item => ({ record: snapshot(item.record), input: snapshot(item.input), output: snapshot(item.output) })) });
      open();
      if (result?.kind !== 'accepted') return result;
      if (!same(result.subject, subject) || !result.assuranceAfter) fail('ACCEPTANCE_SUBJECT');
      for (const [index, handle] of uses.entries()) {
        if (!executions.has(handle) || !knowledge.has(observed[index].knowledgeHandle)) fail('REVOKED');
      }
      const events = observed.map(item => canonicalArtifact({ contract: 'psc-reuse-event/1',
        consumerTaskId: task.identity, consumedKnowledgeIds: JSON.parse(item.record.bytes).knowledgeIds,
        useId: item.record.identity, useType: JSON.parse(item.record.bytes).useType,
        acceptedOutputId: output.identity, counterfactualArm, costObservation,
        assuranceBefore, assuranceAfter: result.assuranceAfter, authority: 'observed-accepted-reuse',
        causalImprovement: 'not-established' }, 'reuse-event', 'psc-reuse-event/1'));
      for (const handle of uses) executions.delete(handle);
      return { kind: 'accepted', subject, events, assuranceAfter: copy(result.assuranceAfter) };
    },
    revoke(handle) { open(); if (!knowledge.delete(handle) && !executions.delete(handle)) fail('HANDLE_NOT_LIVE'); },
    close() { closed = true; },
  });
}
