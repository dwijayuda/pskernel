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
  const synth=src.split('\n').filter(x=>x.startsWith('#synth ')).map(x=>x.slice(7));
  const instances=src.split('\n').filter(x=>x.startsWith('example : '));
  if(JSON.stringify(synth)!==JSON.stringify(typedWitnessGoals.map(x=>x.leanGoal))||
     JSON.stringify(instances)!==JSON.stringify(typedWitnessGoals.map(x=>
       'example : '+x.leanGoal+' := inferInstance'))) fail('SOURCE_GOALS');
  if(/\berror:|\bsorryAx\b|\badmit\b/iu.test(out))fail('LEAN_FAILURE_OR_ADMISSION');
  const outputs=[...out.matchAll(/(?:^|\n)[^\n]*:\d+:\d+: information: ([^\n]+)/gu)]
    .map(x=>x[1].trim());
  if(outputs.length!==typedWitnessGoals.length||
     outputs.some(x=>!x||x.length>8192))fail('TRANSCRIPT_COVERAGE');
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
