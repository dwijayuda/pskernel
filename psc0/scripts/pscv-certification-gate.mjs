/**
 * Release-owned PSCV assurance boundary: P0 policy is explicitly unavailable.
 *
 * The profile/VC/tactic packages MUST NOT construct VerifiedExecutableModule.
 * The currently qualified compiler supports "checked" only; this second
 * refusal prevents future code from mistaking preflight data or a self-asserted
 * certificate for authorization. There is intentionally no accepting branch.
 */
import { inspectProofCandidates } from '../packages/verification/src/preflight.mjs';

export const pscvGateState = Object.freeze({
  schemaVersion:0,
  kind:'psc-supervisor-pscv-gate/0',
  profile:'pscv-v1',
  policyState:'unqualified',
  verifiedExecutableSupported:false,
  proofClosureValidated:false,
  specificationCoverageValidated:false,
  sourceInterpreterValidated:false,
  environmentManifestFrozen:false,
  backendPreservationValidated:false,
});

export function previewPSCVProposal({ required, proposal }) {
  const shape = inspectProofCandidates(required, proposal);
  return Object.freeze({
    ...shape,
    gate: pscvGateState,
    status:'uncertified',
    pscvVerified:false,
    verifiedExecutableAuthorized:false,
  });
}

export function authorizePSCVExecutable() {
  throw new Error('PSC_PSCV_CERT_GATE_UNQUALIFIED: no PSCV-CERT-v1 validator or verified executable emission is qualified');
}
