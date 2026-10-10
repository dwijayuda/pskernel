import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  canonicalRequiredObligations,
  inspectProofCandidates,
  requiredObligationsProtocol,
  verificationProposalProtocol,
  verificationPreflightProtocol,
} from '../src/preflight.mjs';

const required = () => ({
  protocol:requiredObligationsProtocol,
  sourceSha256:'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  environmentSha256:'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  specificationSha256:'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
  semanticsSha256:'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
  assurancePolicy:'pscv-closed-v1',
  roots:['App.main'],
  obligations:[
    {id:'vc.post',rootId:'App.main',kind:'function-postcondition',goalSha256:'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'},
    {id:'vc.call',rootId:'App.main',kind:'call-precondition',goalSha256:'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'}
  ],
});
const candidate = x => ({
  protocol:verificationProposalProtocol,
  requirementsSha256:canonicalRequiredObligations(x).requirementsSha256,
  proofCandidates:x.obligations.map(item=>({
    obligationId:item.id,goalSha256:item.goalSha256,proofSha256:'1'.repeat(64),
  })),
});

test('two-proposition preflight is NEVER a PSCV certificate even when all proof hashes match', () => {
  const r=required(),p=candidate(r);
  const result=inspectProofCandidates(r,p);
  assert.equal(result.protocol,verificationPreflightProtocol);
  assert.equal(result.status,'uncertified');
  assert.equal(result.suppliedCandidates,2);
  assert.equal(result.requiredObligations,2);
  assert.equal(result.kernelAdmissionAccepted,false);
  assert.equal(result.verifiedExecutableAuthorized,false);
  assert.equal(result.pscvVerified,false);
  assert.equal(result.semanticPreservationProved,false);
  assert(result.diagnostics.includes('required-obligation-coverage-not-established'));
  assert(result.diagnostics.includes('proof-candidates-not-kernel-admitted'));
  assert(result.diagnostics.includes('compiler-preservation-not-established'));
  assert(Object.isFrozen(result));
});

test('canonical request digest does not change when order of source obligations changes', () => {
  const r=required();
  const baseline=canonicalRequiredObligations(r).requirementsSha256;
  r.obligations.reverse();
  assert.equal(canonicalRequiredObligations(r).requirementsSha256,baseline);
  r.obligations[0].goalSha256='2'.repeat(64);
  assert.notEqual(canonicalRequiredObligations(r).requirementsSha256,baseline);
});

test('missing, mismatched and unknown VCs are diagnostics, never successes', () => {
  const r=required(),p=candidate(r);
  p.proofCandidates.pop();
  let result=inspectProofCandidates(r,p);
  assert(result.diagnostics.includes('missing-proposal:vc.call'));
  p.proofCandidates.push({
    obligationId:'unrequested.extra',goalSha256:'e'.repeat(64),proofSha256:'2'.repeat(64),
  });
  result=inspectProofCandidates(r,p);
  assert(result.diagnostics.includes('unknown-obligation:unrequested.extra'));
  assert(result.diagnostics.includes('missing-proposal:vc.call'));
  p.proofCandidates[0].goalSha256='9'.repeat(64);
  result=inspectProofCandidates(r,p);
  assert(result.diagnostics.includes('goal-identity-mismatch:vc.post'));
  p.requirementsSha256='9'.repeat(64);
  result=inspectProofCandidates(r,p);
  assert(result.diagnostics.includes('requirements-identity-mismatch'));
  assert.equal(result.verifiedExecutableAuthorized,false);
});

test('additional authority fields, duplicate proofs and unsupported promises are refused', () => {
  const r=required(),p=candidate(r);
  const forged={...p,verified:true};
  assert.throws(()=>inspectProofCandidates(r,forged),/PSC_VERIFICATION_PREFLIGHT_PROPOSAL_SCHEMA/u);
  assert.throws(()=>inspectProofCandidates(r,{...p,
    proofCandidates:[...p.proofCandidates,p.proofCandidates[0]],
  }),/PSC_VERIFICATION_PREFLIGHT_DUPLICATE_PROOF_CANDIDATE/u);
  const forgedGoal={...p,proofCandidates:[{
    ...p.proofCandidates[0],acceptedByKernel:true,
  }]};
  assert.throws(()=>inspectProofCandidates(r,forgedGoal),/PSC_VERIFICATION_PREFLIGHT_PROOF_CANDIDATE_SCHEMA/u);
  assert.throws(()=>inspectProofCandidates(r,{...p,
    proofCandidates:[{...p.proofCandidates[0],goalSha256:'never checked'}],
  }),/PSC_VERIFICATION_PREFLIGHT_PROOF_CANDIDATE_SCHEMA/u);
});

test('no-empty, no-ambiguous, no-invented required coverage and source policy', () => {
  const r=required();
  for(const variant of [
    {...r,obligations:[]},
    {...r,roots:[]},
    {...r,roots:['App.main','App.main']},
    {...r,obligations:[r.obligations[0],r.obligations[0]]},
    {...r,obligations:[{...r.obligations[0],rootId:'Nonexistent.root'}]},
    {...r,assurancePolicy:'unchecked'},
    {...r,coverageComplete:true},
    {...r,specificationSha256:'pending'},
    {...r,sourceSha256:'not-pinned'},
    {...r,obligations:Array.from({length:4097},()=>r.obligations[0])},
  ]) {
    assert.throws(()=>canonicalRequiredObligations(variant),/PSC_VERIFICATION_PREFLIGHT_/u);
  }
});

test('even a structurally acceptable empty proof-candidate list cannot be certified', () => {
  const r=required();
  const p={protocol:verificationProposalProtocol,
    requirementsSha256:canonicalRequiredObligations(r).requirementsSha256,
    proofCandidates:[]};
  const result=inspectProofCandidates(r,p);
  assert.equal(result.status,'uncertified');
  assert.equal(result.verifiedExecutableAuthorized,false);
  assert.equal(result.suppliedCandidates,0);
  assert(result.diagnostics.includes('missing-proposal:vc.call'));
  assert(result.diagnostics.includes('missing-proposal:vc.post'));
});
