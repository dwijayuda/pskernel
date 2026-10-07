import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { readEvidenceCache } from './evidence-cache.mjs';
import { verifyExactBehavioralInterfaceReuse } from './module-interface-evidence.mjs';

export const semanticReuseCandidateContract = 'psc-semantic-reuse-candidate/1';

const fail = code => { throw new Error('PSC_SEMANTIC_REUSE_' + code); };
const copyId = value => { artifactKey(value); return JSON.parse(canonicalBytes(value)); };

export function semanticReuseCandidateArtifact({ actionId, obligations = [] }) {
  copyId(actionId);
  if (!Array.isArray(obligations) || obligations.length > 4096) fail('OBLIGATIONS');
  const normalized = obligations.map(value => {
    if (!value || typeof value !== 'object' || Array.isArray(value) ||
        Object.keys(value).sort().join(',') !== ['currentInterface','previousInterface','rule'].sort().join(','))
      fail('OBLIGATION_SCHEMA');
    return {
      previousInterface: copyId(value.previousInterface),
      currentInterface: copyId(value.currentInterface),
      rule: copyId(value.rule),
    };
  });
  return canonicalArtifact({
    schemaVersion: 1,
    contract: semanticReuseCandidateContract,
    actionId: copyId(actionId),
    obligations: normalized,
    authority: 'reuse-candidate-not-authority',
  }, 'semantic-reuse-candidate', semanticReuseCandidateContract);
}

/** QueryGraphV2 candidate validation + cache validation. Both are required.
 * Reuse-rule success does not mint pass evidence, and cache success does not
 * bypass semantic dependency validation.
 */
export async function readSemanticEvidenceCache({
  root,
  candidate,
  expectedCandidateId,
  expectedActionId,
  resolveArtifact,
  evidenceCheckers = new Map(),
  requiredEvidenceKinds,
  allowedAssumptions = [],
  limits,
}) {
  // Both selections come from the current consumer/planner, not cached bytes.
  // The candidate ID binds every obligation, including their number and order.
  if (expectedCandidateId?.domain !== 'semantic-reuse-candidate' ||
      expectedCandidateId.contract !== semanticReuseCandidateContract ||
      expectedActionId?.domain !== 'action' || expectedActionId.contract !== 'psc-action/1')
    fail('CONSUMER_SELECTION_REQUIRED');
  if (artifactKey(expectedCandidateId) !== artifactKey(candidate.identity)) fail('CANDIDATE_SELECTION');
  if (!(candidate.bytes instanceof Uint8Array) || candidate.bytes.byteLength > 2 * 1024 * 1024) fail('RESOURCE_EXHAUSTED');
  verifyArtifact(candidate.bytes, candidate.identity);
  const value = JSON.parse(candidate.bytes);
  if (!canonicalBytes(value).equals(Buffer.from(candidate.bytes)) ||
      value.schemaVersion !== 1 || value.contract !== semanticReuseCandidateContract ||
      value.authority !== 'reuse-candidate-not-authority' || !Array.isArray(value.obligations))
    fail('CANDIDATE');
  const rebuilt = semanticReuseCandidateArtifact({ actionId: value.actionId, obligations: value.obligations });
  if (artifactKey(rebuilt.identity) !== artifactKey(candidate.identity)) fail('CANDIDATE');
  if (artifactKey(value.actionId) !== artifactKey(expectedActionId)) fail('ACTION_SELECTION');
  if (typeof resolveArtifact !== 'function') fail('RESOLVER');
  const replay = [];
  for (const obligation of value.obligations) {
    const previous = { identity: obligation.previousInterface, bytes: await resolveArtifact(obligation.previousInterface) };
    const current = { identity: obligation.currentInterface, bytes: await resolveArtifact(obligation.currentInterface) };
    const rule = { identity: obligation.rule, bytes: await resolveArtifact(obligation.rule) };
    replay.push(await verifyExactBehavioralInterfaceReuse({
      previous, current, rule, resolveArtifact, evidenceCheckers,
    }));
  }
  const cache = await readEvidenceCache({
    root,
    actionId: expectedActionId,
    requiredEvidenceKinds,
    allowedAssumptions,
    evidenceCheckers,
    limits,
  });
  if (!cache.hit) return { ...cache, semanticReuse: replay };
  return Object.freeze({
    ...cache,
    semanticReuse: Object.freeze(replay),
    authority: 'validated-semantic-reuse-and-pass-data-not-kernel-capability',
  });
}
