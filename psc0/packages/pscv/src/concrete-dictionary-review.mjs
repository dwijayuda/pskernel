/**
 * P1-F: inspect Lean's selected concrete typeclass terms, without treating
 * a #synth result as a complete dependency graph or Standard ID mapping.
 */
import {createHash} from 'node:crypto';
import {extractRequiredStandardSurface} from './required-standard-surface.mjs';
const hash=x=>createHash('sha256').update(x).digest('hex');
const fail=x=>{throw Error('PSC_PSCV_CONCRETE_DICT_'+x);};
export const concreteGoals=Object.freeze([
  Object.freeze({surfaceId:"Nat:+",leanGoal:"Add Nat",parentGoal:"HAdd Nat Nat Nat",parentSelection:"instHAdd"}),
  Object.freeze({surfaceId:"Nat:*",leanGoal:"Mul Nat",parentGoal:"HMul Nat Nat Nat",parentSelection:"instHMul"}),
  Object.freeze({surfaceId:"Nat:-",leanGoal:"Sub Nat",parentGoal:"HSub Nat Nat Nat",parentSelection:"instHSub"}),
  Object.freeze({surfaceId:"Int:+",leanGoal:"Add Int",parentGoal:"HAdd Int Int Int",parentSelection:"instHAdd"}),
  Object.freeze({surfaceId:"Nat:==",leanGoal:"DecidableEq Nat",parentGoal:"BEq Nat",parentSelection:"instBEqOfDecidableEq"}),
  Object.freeze({surfaceId:"Bool:==",leanGoal:"DecidableEq Bool",parentGoal:"BEq Bool",parentSelection:"instBEqOfDecidableEq"}),
  Object.freeze({surfaceId:"String:++",leanGoal:"Append String",parentGoal:"Append String",parentSelection:"instAppendString"}),
]);
export function inspectConcreteDictionaries({normativeReference,source,transcript}){
  const matrix=extractRequiredStandardSurface(normativeReference);
  if(typeof source!=='string'||typeof transcript!=='string'||
    Buffer.byteLength(source)>32768||Buffer.byteLength(transcript)>100000)
    fail('BOUNDS');
  const src=source.replace(/\r\n?/gu,'\n');
  const stdout=transcript.replace(/\r\n?/gu,'\n').trim();
  const statements=src.replace(/\/-![\s\S]*?-\//gu,'').split('\n')
    .map(line=>line.replace(/--.*$/u,'').trim()).filter(Boolean);
  const expected=[
    'import PSCVL.Policy','set_option autoImplicit false',
    ...concreteGoals.map(x=>'#synth '+x.leanGoal),
    ...concreteGoals.map(x=>'example : '+x.leanGoal+' := inferInstance'),
  ];
  if(JSON.stringify(statements)!==JSON.stringify(expected))fail('SOURCE_GOALS');
  // Observed from the actual pinned Lean RC3 #synth output, not guessed
  // from normative std.* identifiers. Refuse any changed selection rather
  // than accepting a plausible spelling or 'sorryAx' as proof evidence.
  const printed=stdout.split('\n').map(x=>x.trim());
  const exactObserved=["instAddNat","instMulNat","instSubNat","Int.instAdd","instDecidableEqNat","instDecidableEqBool","instAppendString"];
  if(JSON.stringify(printed)!==JSON.stringify(exactObserved))fail('TRANSCRIPT');
  const rows=new Map(matrix.requiredRows.map(x=>[x.id,x]));
  const observations=concreteGoals.map((g,i)=>{
    const row=rows.get(g.surfaceId);
    if(!row||!row.referencedSnapshotIds.length)fail('SURFACE');
    return {
      surfaceId:g.surfaceId,
      genericParentGoal:g.parentGoal,
      previouslyObservedGenericHead:g.parentSelection,
      newConcreteSynthesisGoal:g.leanGoal,
      newlyObservedSelectedTerm:printed[i],
      normativeSnapshotIdsStillNeedingApproval:row.referencedSnapshotIds,
      genericDictionaryDependencyRelationProven:false,
      sourceDeclarationIdentitiesReplayed:false,
      runtimeContractProven:false,
      acceptedForClosedStandard:false,
    };
  });
  const identity={
    kind:'psc-concrete-instance-witness-review/0',
    parentP1EObservationSha256:'0a5cdad32ace1492158fab973a9da60d9b430ff529c71a9804e415e80efea712',
    normativeSourceSha256:matrix.normativeSha256,
    leanVersion:'4.35.0-rc3',sourceSha256:hash(src),transcriptSha256:hash(stdout),
    observations,
  };
  return Object.freeze({
    version:0,...identity,identitySha256:hash(JSON.stringify(identity)),
    status:'observed-concrete-terms-not-proved-dictionary-dependencies',
    count:observations.length,
    normativeRows:matrix.sourceRowsCount,requiredSnapshotIds:matrix.uniqueReferencedIdsCount,
    sourceLocatedDirectIds:3,unresolvedStandardIds:191,
    exactGenericDependencyGraphQualified:false,
    instancePriorityAndScopeOrderQualified:false,
    completeStandardManifest:false,
    proofCertificateAvailable:false,
    verifiedExecutableAuthorized:false,
    pscvVerified:false,
  });
}
