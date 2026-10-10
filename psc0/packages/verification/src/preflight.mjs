/**
 * Reusable, NON-AUTHORITATIVE verification proposal preflight.
 *
 * A caller's obligation list is not a trusted coverage plan merely because it
 * matches this schema. Only the release-owned PSCV supervisor (not yet
 * implemented/qualified) can establish complete required obligations, source
 * interpretation, proof admission, trust closure, and executable authority.
 *
 * No function in this module may produce PSCV-CERT-v1 or a verified executable
 * handle. This is a data/shape boundary for future proof-producing tools.
 */
import { createHash } from 'node:crypto';

export const requiredObligationsProtocol = 'psc-required-obligations/0';
export const verificationProposalProtocol = 'psc-verification-proposal/0';
export const verificationPreflightProtocol = 'psc-verification-preflight/0';
const sha = x => createHash('sha256').update(x, 'utf8').digest('hex');
const hex = x => typeof x === 'string' && /^[a-f0-9]{64}$/u.test(x);
const field = x => typeof x === 'string' && x.length > 0 && x.length <= 128 &&
  /^[A-Za-z0-9_.:/-]+$/u.test(x);
const object = x => x !== null && typeof x === 'object' &&
  !Array.isArray(x) && Object.getPrototypeOf(x) === Object.prototype;
const exact = (x, keys) => object(x) &&
  Object.keys(x).length === keys.length && keys.every(k => Object.hasOwn(x, k));
const reject = name => { throw new Error('PSC_VERIFICATION_PREFLIGHT_' + name); };

const requiredKeys = Object.freeze([
  'protocol', 'sourceSha256', 'environmentSha256', 'specificationSha256',
  'semanticsSha256', 'assurancePolicy', 'roots', 'obligations',
]);
const obligationKeys = Object.freeze(['id', 'rootId', 'kind', 'goalSha256']);
const proposalKeys = Object.freeze(['protocol', 'requirementsSha256', 'proofCandidates']);
const proofKeys = Object.freeze(['obligationId', 'goalSha256', 'proofSha256']);
const closure = value => Object.freeze(value);

export function canonicalRequiredObligations(required) {
  if (!exact(required, requiredKeys) || required.protocol !== requiredObligationsProtocol ||
      !hex(required.sourceSha256) || !hex(required.environmentSha256) ||
      !hex(required.specificationSha256) || !hex(required.semanticsSha256) ||
      !['pscv-closed-v1', 'pscv-boundary-v1'].includes(required.assurancePolicy) ||
      !Array.isArray(required.roots) || required.roots.length < 1 ||
      required.roots.length > 128 || !Array.isArray(required.obligations) ||
      required.obligations.length < 1 || required.obligations.length > 4096) {
    reject('REQUIREMENTS_SCHEMA');
  }
  const roots = new Set();
  for (const root of required.roots) {
    if (!field(root) || roots.has(root)) reject('ROOT_ID');
    roots.add(root);
  }
  const obligations = new Set();
  for (const obligation of required.obligations) {
    if (!exact(obligation, obligationKeys) ||
        !field(obligation.id) || !field(obligation.rootId) ||
        !field(obligation.kind) || !hex(obligation.goalSha256) ||
        !roots.has(obligation.rootId) || obligations.has(obligation.id)) {
      reject('OBLIGATION_IDENTITY');
    }
    obligations.add(obligation.id);
  }
  const identity = {
    protocol: requiredObligationsProtocol,
    sourceSha256: required.sourceSha256,
    environmentSha256: required.environmentSha256,
    specificationSha256: required.specificationSha256,
    semanticsSha256: required.semanticsSha256,
    assurancePolicy: required.assurancePolicy,
    roots: [...required.roots].sort(),
    obligations: required.obligations.map(x => ({
      id: x.id, rootId: x.rootId, kind: x.kind, goalSha256: x.goalSha256,
    })).sort((a,b) => a.id < b.id ? -1 : a.id > b.id ? 1 : 0),
  };
  return closure({ ...identity,
    requirementsSha256: sha(JSON.stringify(identity)),
  });
}

/**
 * A package can only propose proof candidates for exact goals selected by
 * another caller. A matching digest is NEVER kernel evidence. Even when every
 * listed obligation has a proposal, completeness of that list and logical
 * admission have not been shown.
 */
export function inspectProofCandidates(required, proposal) {
  const plan = canonicalRequiredObligations(required);
  if (!exact(proposal, proposalKeys) ||
      proposal.protocol !== verificationProposalProtocol ||
      !hex(proposal.requirementsSha256) ||
      !Array.isArray(proposal.proofCandidates) ||
      proposal.proofCandidates.length > 4096) {
    reject('PROPOSAL_SCHEMA');
  }
  const reasons = [];
  if (proposal.requirementsSha256 !== plan.requirementsSha256) {
    reasons.push('requirements-identity-mismatch');
  }
  const known = new Map(plan.obligations.map(x => [x.id, x]));
  const seen = new Set();
  for (const proof of proposal.proofCandidates) {
    if (!exact(proof, proofKeys) ||
        !field(proof.obligationId) || !hex(proof.goalSha256) || !hex(proof.proofSha256)) {
      reject('PROOF_CANDIDATE_SCHEMA');
    }
    if (seen.has(proof.obligationId)) reject('DUPLICATE_PROOF_CANDIDATE');
    seen.add(proof.obligationId);
    const expected = known.get(proof.obligationId);
    if (!expected) reasons.push('unknown-obligation:' + proof.obligationId);
    else if (expected.goalSha256 !== proof.goalSha256) {
      reasons.push('goal-identity-mismatch:' + proof.obligationId);
    }
  }
  for (const id of known.keys()) if (!seen.has(id)) {
    reasons.push('missing-proposal:' + id);
  }
  // IMPORTANT: the presence of bytes/digests is not kernel admission, and
  // an asserted "complete" list is not an independent VCG coverage proof.
  reasons.push('required-obligation-coverage-not-established');
  reasons.push('proof-candidates-not-kernel-admitted');
  reasons.push('approved-specification-not-authenticated');
  reasons.push('imported-dependency-and-trust-closure-not-validated');
  reasons.push('effect-and-erasure-closure-not-validated');
  reasons.push('compiler-preservation-not-established');
  return closure({
    schemaVersion: 0,
    protocol: verificationPreflightProtocol,
    status: 'uncertified',
    requirementsSha256: plan.requirementsSha256,
    suppliedCandidates: seen.size,
    requiredObligations: plan.obligations.length,
    diagnostics: closure(reasons),
    kernelAdmissionAccepted: false,
    verifiedExecutableAuthorized: false,
    pscvVerified: false,
    semanticPreservationProved: false,
  });
}
