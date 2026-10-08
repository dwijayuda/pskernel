import { canonicalBytes } from './artifact-evidence.mjs';
import { verifyQueryKey, applyPassEffects } from './query-context.mjs';
import { readSemanticEvidenceCache } from './semantic-query-cache.mjs';
const fail = code => { throw new Error('PSC_QUERY_CONTEXT_' + code); };
const copy = value => JSON.parse(canonicalBytes(value));

export async function readQueryEvidenceCache({ query, expectedQueryId, candidate, expectedCandidateId,
  resolveArtifact, availableAnalyses = [], ...cachePolicy }) {
  const verified = await verifyQueryKey(query, { expectedQueryId, resolveArtifact });
  const effects = applyPassEffects(verified.definition, { semanticProfile: verified.semanticProfile,
    analyses: availableAnalyses, fingerprints: [...new Set(verified.value.declaredInputs.map(input => input.fingerprintClass))] });
  if (!effects.semanticReusePermitted) fail('TRUST_EXPANSION');
  const oldActions = verified.action.exactInputArtifactIds.filter(identity => identity.domain === 'action' && identity.contract === 'psc-action/1');
  if (oldActions.length !== 1) fail('OBSERVED_ACTION_REQUIRED');
  const result = await readSemanticEvidenceCache({ ...cachePolicy, candidate, expectedCandidateId,
    expectedActionId: oldActions[0], resolveArtifact });
  return { ...result, queryId: copy(query.identity), buildActionId: copy(verified.value.buildActionId),
    effects, authority: result.hit ? 'validated-query-and-pass-data-not-kernel-capability' : 'none' };
}
