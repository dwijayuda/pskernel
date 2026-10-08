import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';

export const claimSetContract = 'psc-claim-set/1';
export const claimEvidenceClasses = Object.freeze({
  Parsed: Object.freeze(['parser-validation']),
  Resolved: Object.freeze(['resolver-validation']),
  Elaborated: Object.freeze(['elaboration-validation']),
  ProfileConformant: Object.freeze(['profile-validation']),
  KernelAccepted: Object.freeze(['kernel-check']),
  SpecificationCovered: Object.freeze(['specification-coverage']),
  PSCVCertified: Object.freeze(['certification-check']),
  RuntimeIRValidated: Object.freeze(['invariant-validation']),
  SpecializationValidated: Object.freeze(['translation-validation']),
  TargetIRValidated: Object.freeze(['target-ir-validation']),
  TargetToolAccepted: Object.freeze(['target-tool-acceptance']),
  SemanticPreservationChecked: Object.freeze(['formal-proof', 'translation-validation']),
  IndependentCheckerAccepted: Object.freeze(['independent-check']),
  SelfHostFixedPoint: Object.freeze(['exact-fixed-point']),
  Reproducible: Object.freeze(['reproducibility-check']),
  ProvenanceBound: Object.freeze(['provenance-check']),
  SourceBinaryCorrespondenceDDC: Object.freeze(['diverse-double-compilation']),
});
const bound = Object.freeze({ maxBytes: 1024 * 1024, maxDepth: 24, maxNodes: 30000 });
const fail = code => { throw new Error('PSC_CLAIM_' + code); };
const copy = value => JSON.parse(canonicalBytes(value, bound));
const verifiedSets = new WeakMap();
const nonempty = value => typeof value === 'string' && value.length > 0 && value.length <= 4096;
function exact(value, keys) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...keys].sort().join(',')) fail('SCHEMA');
}
function identity(value) {
  exact(value, ['algorithm', 'schemaVersion', 'domain', 'contract', 'digest', 'byteLength']);
  return artifactKey(value);
}
function list(values, validate, min = 0, max = 256) {
  if (!Array.isArray(values) || values.length < min || values.length > max) fail('LIST');
  const keys = values.map(validate);
  if (new Set(keys).size !== keys.length) fail('DUPLICATE');
}
function text(value) { if (!nonempty(value)) fail('TEXT'); return value; }
function claim(value) {
  exact(value, ['kind', 'subjects', 'profileEnvironmentId', 'evidenceClass', 'evidenceIds',
    'checkerImplementationId', 'assumptionIds', 'resourcePolicyId']);
  if (!Object.hasOwn(claimEvidenceClasses, value.kind)) fail('KIND');
  if (!claimEvidenceClasses[value.kind].includes(value.evidenceClass)) fail('EVIDENCE_CLASS');
  list(value.subjects, identity, 1, 64);
  identity(value.profileEnvironmentId); identity(value.checkerImplementationId); identity(value.resourcePolicyId);
  list(value.evidenceIds, identity, 1);
  list(value.assumptionIds, text);
  return canonicalBytes(value, bound).toString('utf8');
}
function valueOf(record) {
  if (!(record?.bytes instanceof Uint8Array) || record.bytes.byteLength > bound.maxBytes) fail('BYTES_LIMIT');
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'claim-set' || record.identity.contract !== claimSetContract) fail('IDENTITY');
  const value = JSON.parse(Buffer.from(record.bytes));
  exact(value, ['schemaVersion', 'contract', 'authority', 'claims']);
  if (value.schemaVersion !== 1 || value.contract !== claimSetContract || value.authority !== 'audit-record-only') fail('SCHEMA');
  list(value.claims, claim);
  if (!canonicalBytes(value, bound).equals(Buffer.from(record.bytes))) fail('CANONICAL');
  return value;
}

/** Creates bounded assertions, never accepted claims or live capabilities. */
export function createClaimSet(claims = []) {
  const value = copy({ schemaVersion: 1, contract: claimSetContract, authority: 'audit-record-only', claims });
  list(value.claims, claim);
  return canonicalArtifact(value, 'claim-set', claimSetContract);
}

export function decodeClaimSet(record) { return copy(valueOf(record)); }

/** All checker implementations and assumptions are selected by the consumer.
 * Claim bytes cannot install checkers. Every dependency is resolved and rehashed.
 * This host verifier does not mint Checked/Certified/Validated capabilities.
 */
export async function verifyClaimSet(record, { resolveArtifact, checkers = new Map(), allowedAssumptions = [] } = {}) {
  const value = valueOf(record), verifiedIdentity = copy(record.identity);
  list(allowedAssumptions, text);
  if (typeof resolveArtifact !== 'function' || !(checkers instanceof Map)) fail('POLICY');
  const assumptions = new Set(allowedAssumptions), selected = new Map(checkers);
  const resolved = new Map();
  async function resolve(id) {
    const key = identity(id);
    if (!resolved.has(key)) {
      const bytes = Buffer.from(await resolveArtifact(copy(id)));
      verifyArtifact(bytes, id); resolved.set(key, bytes);
    }
    return Buffer.from(resolved.get(key));
  }
  for (const item of value.claims) {
    if (item.assumptionIds.some(id => !assumptions.has(id))) fail('ASSUMPTION_DENIED');
    const selectedChecker = selected.get(identity(item.checkerImplementationId));
    if (typeof selectedChecker !== 'function') fail('CHECKER_UNAVAILABLE');
    for (const id of [...item.subjects, item.profileEnvironmentId, item.resourcePolicyId, item.checkerImplementationId]) await resolve(id);
    const evidence = [];
    for (const id of item.evidenceIds) evidence.push(await resolve(id));
    const expected = copy(item);
    const outcome = await selectedChecker(evidence, copy(expected));
    if (outcome?.accepted !== true || !canonicalBytes(outcome.claim, bound).equals(canonicalBytes(expected, bound))) fail('EVIDENCE_REJECTED');
  }
  const result = Object.freeze({ claimSetId: copy(verifiedIdentity), integrityVerified: true,
    verifiedClaimCount: value.claims.length, authority: 'audit-record-only' });
  verifiedSets.set(result, { value: copy(value), identity: verifiedIdentity });
  return result;
}

function policyValue(policyArtifact) {
  if (!(policyArtifact?.bytes instanceof Uint8Array) || policyArtifact.bytes.byteLength > bound.maxBytes) fail('POLICY');
  verifyArtifact(policyArtifact.bytes, policyArtifact.identity);
  if (policyArtifact.identity.domain !== 'claim-policy' || policyArtifact.identity.contract !== 'psc-claim-policy/1') fail('POLICY');
  const policy = JSON.parse(Buffer.from(policyArtifact.bytes));
  exact(policy, ['schemaVersion', 'contract', 'requirements', 'allowedAssumptions']);
  if (policy.schemaVersion !== 1 || policy.contract !== 'psc-claim-policy/1' ||
      !canonicalBytes(policy, bound).equals(Buffer.from(policyArtifact.bytes))) fail('POLICY');
  list(policy.allowedAssumptions, text);
  list(policy.requirements, requirement => {
    exact(requirement, ['kind', 'subjects', 'profileEnvironmentId', 'evidenceClasses', 'checkerImplementationIds', 'resourcePolicyId']);
    if (!Object.hasOwn(claimEvidenceClasses, requirement.kind)) fail('KIND');
    list(requirement.subjects, identity, 1, 64); identity(requirement.profileEnvironmentId); identity(requirement.resourcePolicyId);
    list(requirement.evidenceClasses, name => {
      if (!claimEvidenceClasses[requirement.kind].includes(name)) fail('EVIDENCE_CLASS'); return name;
    }, 1);
    list(requirement.checkerImplementationIds, identity, 1);
    return canonicalBytes(requirement, bound).toString('utf8');
  }, 1);
  return policy;
}

/** Capture consumer choices before any resolver or checker can run.
 * Archived assertions never supply this policy or install implementations.
 * Each public consumer captures again, so a caller-held snapshot is not authority.
 */
export function captureClaimConsumerPolicy({ claimVerification, claimPolicy } = {}) {
  if (claimPolicy !== undefined && claimVerification === undefined) fail('VERIFICATION_REQUIRED');
  if (claimVerification === undefined) return Object.freeze({});
  if (!claimVerification || typeof claimVerification !== 'object' || Array.isArray(claimVerification) ||
      ![Object.prototype, null].includes(Object.getPrototypeOf(claimVerification))) fail('POLICY');
  const fields = {};
  for (const key of Reflect.ownKeys(claimVerification)) {
    const field = Object.getOwnPropertyDescriptor(claimVerification, key);
    if (!['checkers', 'allowedAssumptions'].includes(key) || !field || !Object.hasOwn(field, 'value')) fail('POLICY');
    fields[key] = field.value;
  }
  const checkers = fields.checkers === undefined ? new Map() : fields.checkers;
  if (!(checkers instanceof Map)) fail('POLICY');
  const selected = new Map(Map.prototype.entries.call(checkers));
  for (const [key, checker] of selected) if (typeof key !== 'string' || typeof checker !== 'function') fail('POLICY');
  const assumptions = copy(fields.allowedAssumptions === undefined ? [] : fields.allowedAssumptions);
  list(assumptions, text);
  let policy;
  if (claimPolicy !== undefined) {
    if (!(claimPolicy?.bytes instanceof Uint8Array) || claimPolicy.bytes.byteLength > bound.maxBytes) fail('POLICY');
    policy = { identity: copy(claimPolicy.identity), bytes: Buffer.from(claimPolicy.bytes) };
    policyValue(policy);
    Object.freeze(policy);
  }
  return Object.freeze({
    claimVerification: Object.freeze({ checkers: selected, allowedAssumptions: Object.freeze(assumptions) }),
    ...(policy ? { claimPolicy: policy } : {}),
  });
}

/** Policy-defined exact conjunction; no implicit lattice promotion.
 * A live verification result is required. Serialization cannot recreate it.
 * Satisfaction is an audit decision, not an authority-bearing release capability.
 */
export function evaluateClaimPolicy(verified, policyArtifact) {
  const stored = verifiedSets.get(verified);
  if (!stored) fail('LIVE_VERIFICATION_REQUIRED');
  const value = stored.value;
  const policy = policyValue(policyArtifact);
  const equal = (a, b) => canonicalBytes(a, bound).equals(canonicalBytes(b, bound));
  const missing = policy.requirements.filter(required => !value.claims.some(item =>
    item.kind === required.kind && equal(item.subjects, required.subjects) &&
    identity(item.profileEnvironmentId) === identity(required.profileEnvironmentId) &&
    identity(item.resourcePolicyId) === identity(required.resourcePolicyId) &&
    required.evidenceClasses.includes(item.evidenceClass) &&
    required.checkerImplementationIds.some(id => identity(id) === identity(item.checkerImplementationId)) &&
    item.assumptionIds.every(id => policy.allowedAssumptions.includes(id))));
  return Object.freeze({ policyId: copy(policyArtifact.identity), claimSetId: copy(stored.identity),
    policySatisfied: missing.length === 0, missing: copy(missing), authority: 'audit-record-only',
    releaseCapabilityMinted: false });
}
