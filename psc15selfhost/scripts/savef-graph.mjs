import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const knowledgeContract = 'psc-knowledge-object/2';
export const knowledgeKinds = Object.freeze(['specification', 'proof', 'theory', 'compiler', 'assumption', 'artifact']);
const authorities = ['semantic-authority', 'validation-authority', 'formal-evidence', 'empirical-evidence', 'provenance-evidence', 'advisory'];
const statuses = ['proved', 'validated', 'empirical', 'target-unproved', 'advisory'];
const text = value => typeof value === 'string' && value.length > 0;
const copy = value => JSON.parse(canonicalBytes(value));
const same = (left, right) => canonicalBytes(left).equals(canonicalBytes(right));
const fail = code => { throw new Error('PSC_KNOWLEDGE_' + code); };
function exact(value, fields) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...fields].sort().join(',')) fail('SCHEMA');
}
function list(value, predicate) {
  if (!Array.isArray(value) || !value.every(predicate)) fail('LIST');
}
function unique(items, key) {
  if (new Set(items.map(key)).size !== items.length) fail('DUPLICATE');
}
function id(value) { artifactKey(value); return true; }
function knowledgeId(value) {
  id(value);
  if (value.domain !== 'knowledge-object' || value.contract !== knowledgeContract) fail('OBJECT_ID');
  return true;
}

/** V2 is deliberately separate from the historical metadata-only prototype. */
export function knowledgeObject(fields) {
  const value = copy(fields);
  validateShape(value);
  return canonicalArtifact(value, 'knowledge-object', knowledgeContract);
}

function validateShape(value) {
  exact(value, ['contract', 'kind', 'semanticIdentity', 'authorityClass', 'scope', 'dependencies',
    'assumptions', 'claims', 'payload', 'implementationWitnesses', 'evidence', 'provenance',
    'resourceEvidence', 'license', 'supersedes', 'migrations']);
  if (value.contract !== knowledgeContract || !knowledgeKinds.includes(value.kind) ||
      !authorities.includes(value.authorityClass) || !value.semanticIdentity || !value.scope) fail('CONTRACT');
  id(value.payload); id(value.license);
  list(value.assumptions, text); unique(value.assumptions, value => value);
  for (const field of ['implementationWitnesses', 'evidence', 'provenance', 'resourceEvidence', 'migrations']) {
    list(value[field], id); unique(value[field], artifactKey);
  }
  list(value.supersedes, knowledgeId); unique(value.supersedes, artifactKey);
  list(value.dependencies, item => {
    exact(item, ['relation', 'target']);
    if (!knowledgeKinds.includes(item.relation)) fail('EDGE_TYPE');
    return knowledgeId(item.target);
  });
  unique(value.dependencies, item => item.relation + ':' + artifactKey(item.target));
  list(value.claims, claim => {
    exact(claim, ['claimId', 'status', 'subjectId', 'certificateId']);
    if (!text(claim.claimId) || !statuses.includes(claim.status)) fail('CLAIM');
    id(claim.subjectId);
    if (claim.certificateId !== null) id(claim.certificateId);
    if (['proved', 'validated'].includes(claim.status) && claim.certificateId === null) fail('CLAIM_CERTIFICATE_REQUIRED');
    return true;
  });
  unique(value.claims, claim => claim.claimId);
}

/** Consumer policy is trusted input. Retrieved objects cannot select their own
 * semantic context, assumption budget, claim interpretation, or checker.
 * Exact context equality is conservative: migrations never implicitly widen it.
 */
export async function verifyKnowledgeGraph({ roots, resolveArtifact, context, claimPolicies = new Map(),
  certificateBoundary, limits = {} }) {
  context = copy(context); roots = copy(roots);
  if (!context.semanticIdentity || !context.scope) fail('CONTEXT');
  list(context.allowedAssumptions, text); list(context.requiredClaims, text);
  if (!(claimPolicies instanceof Map) || typeof resolveArtifact !== 'function') fail('POLICY');
  const policies = new Map([...claimPolicies].map(([key, value]) => [key, copy(value)]));
  for (const [name, value] of policies) {
    if (!text(name) || !text(value.claimClass) || !text(value.checkerId)) fail('CLAIM_POLICY');
    id(value.subjectId);
  }
  const bound = { maxObjects: 4096, maxArtifacts: 16384, maxArtifactBytes: 16 * 1024 * 1024,
    maxTotalBytes: 128 * 1024 * 1024, ...copy(limits) };
  if (Object.values(bound).some(n => !Number.isSafeInteger(n) || n < 0)) fail('LIMIT_POLICY');
  list(roots, knowledgeId); unique(roots, artifactKey);
  if (roots.length === 0) fail('ROOTS_REQUIRED');
  const resolved = new Map(), objects = new Map(), order = [], state = new Map(), claims = [];
  let total = 0;
  async function resolve(identity) {
    const key = artifactKey(identity);
    if (resolved.has(key)) return resolved.get(key);
    if (resolved.size >= bound.maxArtifacts || identity.byteLength > bound.maxArtifactBytes ||
        total + identity.byteLength > bound.maxTotalBytes) fail('RESOURCE_EXHAUSTED');
    const supplied = await resolveArtifact(copy(identity));
    if (!(supplied instanceof Uint8Array) || supplied.byteLength !== identity.byteLength) fail('ARTIFACT_BYTES');
    const bytes = Buffer.from(supplied);
    verifyArtifact(bytes, identity);
    total += bytes.length; resolved.set(key, bytes);
    return bytes;
  }
  // Iterative postorder avoids consuming the JS call stack for deep DAGs.
  const pending = roots.toReversed().map(identity => ({ identity, exit: false }));
  while (pending.length) {
    const { identity, exit } = pending.pop(), key = artifactKey(identity);
    if (exit) { state.set(key, 'done'); order.push(identity); continue; }
    if (state.get(key) === 'done') continue;
    if (state.has(key)) fail('DEPENDENCY_CYCLE');
    if (objects.size >= bound.maxObjects) fail('RESOURCE_EXHAUSTED');
    const value = decodeComparatorJson(await resolve(identity), { maxBytes: bound.maxArtifactBytes });
    validateShape(value);
    if (!same(value.semanticIdentity, context.semanticIdentity) || !same(value.scope, context.scope)) fail('STALE_CONTEXT');
    if (value.assumptions.some(assumption => !context.allowedAssumptions.includes(assumption))) fail('ASSUMPTION_DENIED');
    objects.set(key, value); state.set(key, 'active');
    pending.push({ identity, exit: true });
    for (const edge of value.dependencies.toReversed()) pending.push({ identity: edge.target, exit: false });
  }
  for (const identity of order) {
    const value = objects.get(artifactKey(identity));
    for (const edge of value.dependencies) {
      if (objects.get(artifactKey(edge.target))?.kind !== edge.relation) fail('EDGE_TYPE');
    }
    // Supersession is historical metadata, not permission to import a stale
    // object's claims. Its exact bytes still have to exist in the archive.
    for (const reference of [value.payload, value.license, ...value.implementationWitnesses,
      ...value.evidence, ...value.provenance, ...value.resourceEvidence, ...value.supersedes, ...value.migrations]) await resolve(reference);
    for (const claim of value.claims) {
      const subject = { identity: claim.subjectId, bytes: await resolve(claim.subjectId) };
      const certificate = claim.certificateId === null ? null : {
        identity: claim.certificateId, bytes: await resolve(claim.certificateId) };
      if (!['proved', 'validated'].includes(claim.status)) continue;
      const policy = policies.get(claim.claimId);
      if (!policy || artifactKey(policy.subjectId) !== artifactKey(subject.identity)) fail('CLAIM_INTERPRETATION_UNAVAILABLE');
      if (!certificateBoundary) fail('CHECKER_UNAVAILABLE');
      const checked = await certificateBoundary.check({ subject, certificate });
      if (checked.kind !== 'accepted') {
        const error = new Error('PSC_KNOWLEDGE_CERTIFICATE_' + checked.kind);
        error.kind = checked.kind; error.detail = checked; throw error;
      }
      const receipt = certificateBoundary.describe(checked.value);
      certificateBoundary.revoke(checked.value);
      if (receipt.claimClass !== policy.claimClass || receipt.checkerId !== policy.checkerId ||
          artifactKey(receipt.subjectId) !== artifactKey(subject.identity)) fail('CLAIM_INTERPRETATION_MISMATCH');
      claims.push({ objectId: identity, claimId: claim.claimId, subjectId: subject.identity,
        claimClass: receipt.claimClass, checkerId: receipt.checkerId, validationId: checked.receipt.identity });
    }
  }
  for (const required of context.requiredClaims) if (!claims.some(claim => claim.claimId === required)) fail('REQUIRED_CLAIM');
  return Object.freeze({ kind: 'accepted', contract: 'psc-knowledge-validity/1',
    validity: 'valid-under-exact-context', context, roots, objectIds: order, verifiedClaims: claims,
    resolvedArtifacts: resolved.size, resolvedBytes: total, authority: 'audit-record-only', releaseAccepted: false });
}
