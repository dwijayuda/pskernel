/**
 * Review a bounded, real Lean 4.35.0-rc3 imported-instance witness transcript.
 * This is diagnostic evidence only: it cannot freeze Standard registrations,
 * authorize a runtime mapping, attest compiler preservation, or issue proofs.
 */
import { createHash } from 'node:crypto';
import { extractRequiredStandardSurface } from './required-standard-surface.mjs';
const sha=x=>createHash('sha256').update(x).digest('hex');
const fail=x=>{throw Error('PSC_PSCV_TYPED_WITNESS_'+x);};
const norm=x=>x.replace(/\r\n?/gu,'\n');
export const typedWitnessGoals=Object.freeze([
  Object.freeze({surfaceId:"Nat:+",leanGoal:"HAdd Nat Nat Nat"}),
  Object.freeze({surfaceId:"Nat:*",leanGoal:"HMul Nat Nat Nat"}),
  Object.freeze({surfaceId:"Nat:-",leanGoal:"HSub Nat Nat Nat"}),
  Object.freeze({surfaceId:"Int:+",leanGoal:"HAdd Int Int Int"}),
  Object.freeze({surfaceId:"String:++",leanGoal:"Append String"}),
  Object.freeze({surfaceId:"Nat:==",leanGoal:"BEq Nat"}),
  Object.freeze({surfaceId:"Bool:==",leanGoal:"BEq Bool"}),
]);
export function reviewTypedResolution({normativeReference,source,transcript}) {
  const surface=extractRequiredStandardSurface(normativeReference);
  if(typeof source!=='string'||typeof transcript!=='string'||
      Buffer.byteLength(source)>32768||Buffer.byteLength(transcript)>100000)
    fail('INPUT_BOUNDS');
  const src=norm(source),out=norm(transcript);
  // The witness source is a tiny fixed top-level program: importing any
  // other module, installing an instance or setting search options would
  // change the observed environment even if the #synth lines stayed intact.
  // Reject all such extra commands before accepting the review transcript.
  const statements=src.replace(/\/-![\s\S]*?-\//gu,'')
    .split('\n').map(line=>line.replace(/--.*$/u,'').trim()).filter(Boolean);
  const requiredStatements=[
    'import PSCVL.Policy','set_option autoImplicit false',
    ...typedWitnessGoals.map(x=>'#synth '+x.leanGoal),
    ...typedWitnessGoals.map(x=>'example : '+x.leanGoal+' := inferInstance'),
  ];
  if(JSON.stringify(statements)!==JSON.stringify(requiredStatements))
    fail('SOURCE_GOALS');
  if(/\berror:|\bsorryAx\b|\badmit\b/iu.test(out))fail('LEAN_FAILURE_OR_ADMISSION');
  // Lean 4.35.0-rc3 prints each #synth result as a bare line when
  // invoked in batch mode. Exact golden selections pin this observation;
  // `instHAdd` is generic and does NOT map any Nat-specific std.* ID.
  const outputs=out.trim().split('\n');
  const expected=["instHAdd","instHMul","instHSub","instHAdd","instAppendString","instBEqOfDecidableEq","instBEqOfDecidableEq"];
  if(JSON.stringify(outputs)!==JSON.stringify(expected))
    fail('TRANSCRIPT_COVERAGE');
  const rows=new Map(surface.requiredRows.map(x=>[x.id,x]));
  const observed=typedWitnessGoals.map((g,i)=>{
    const row=rows.get(g.surfaceId);
    if(!row||!row.referencedSnapshotIds?.length)fail('UNLISTED_GOAL');
    return {
      surfaceId:g.surfaceId,requestedLeanGoal:g.leanGoal,
      normativeRequiredSnapshotIds:row.referencedSnapshotIds,
      selectedTermText:outputs[i],
      observedIn:'imported-Lean-4.35.0-rc3-environment',
      approvedForClosedStandard:false,
      sourceDeclarationProvenanceChecked:false,
      runtimePreservationProved:false,
    };
  });
  const identity={
    schema:'psc-imported-typed-witness/0',leanVersion:'4.35.0-rc3',
    normativeSha256:surface.normativeSha256,
    witnessSourceSha256:sha(src),transcriptSha256:sha(out),
    observed,requiredSurfaceRows:surface.sourceRowsCount,
    distinctStandardIds:surface.uniqueReferencedIdsCount,
  };
  return Object.freeze({
    version:0,kind:identity.schema,status:'observed-not-standard-qualified',
    identitySha256:sha(JSON.stringify(identity)),...identity,
    goalsObserved:observed.length,sourceLocatedDirectBoolIds:3,
    unresolvedStandardSnapshotIds:191,
    mappedToClosedStandard:false,scopedInstanceSearchQualified:false,
    exactSourceLineLocatorsQualified:false,effectAndWPRegistryQualified:false,
    certifiedExecutableAvailable:false,standardEnvironmentFrozen:false,
    verifiedExecutableAuthorized:false,pscvVerified:false,
  });
}
