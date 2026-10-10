/**
 * Generate a bounded typed Lean instance-observation batch from the EXACT
 * PSCV-RC-v2 §24.3 requirement matrix, not from guessed std.* names.
 * Output is neither the closed Standard registry nor certificate authority.
 */
import {createHash} from 'node:crypto';
import {extractRequiredStandardSurface} from './required-standard-surface.mjs';

const fail=x=>{throw Error('PSC_PSCV_ARITHMETIC_BATCH_'+x)};
const hash=x=>createHash('sha256').update(x).digest('hex');
const normal=x=>x.replace(/\r\n?/gu,'\n');
const operators=Object.freeze({
 '+':Object.freeze({hetero:'HAdd',concrete:'Add'}),
 '-':Object.freeze({hetero:'HSub',concrete:'Sub'}),
 '*':Object.freeze({hetero:'HMul',concrete:'Mul'}),
});
const types=Object.freeze([
 'Nat','Int','Int8','Int16','Int32','Int64','UInt8','UInt16',
 'UInt32','UInt64','USize','ISize','Float','Float32',
]);
const stableSort=(a,b)=>a<b?-1:a>b?1:0;

export function buildArithmeticBatch(normativeReference) {
 const source=extractRequiredStandardSurface(normativeReference);
 const selected=source.requiredRows.filter(row=>{
   const parts=row.id.split(':');
   return parts.length===2&&types.includes(parts[0])&&Object.hasOwn(operators,parts[1]);
 });
 if(selected.length!==42||new Set(selected.map(x=>x.id)).size!==42)fail('ROW_CLOSURE');
 for(const ty of types)for(const op of Object.keys(operators)){
  if(!selected.some(x=>x.id===ty+':'+op))fail('TYPE_OPERATOR_MISSING');
 }
 const rows=selected.sort((a,b)=>stableSort(a.id,b.id)).map(row=>{
  const [ty,op]=row.id.split(':');
  const {hetero,concrete}=operators[op];
  return Object.freeze({
    surfaceId:row.id,operandType:ty,operator:op,
    guaranteedFamily:row.guaranteedFamily,
    genericGoal:hetero+' '+ty+' '+ty+' '+ty,
    concreteGoal:concrete+' '+ty,
    requiredSnapshotIds:row.referencedSnapshotIds,
  });
 });
 const requests=rows.flatMap(row=>[
  {surfaceId:row.surfaceId,goalKind:'generic',leanGoal:row.genericGoal},
  {surfaceId:row.surfaceId,goalKind:'concrete',leanGoal:row.concreteGoal},
 ]);
 const generatedSource=[
  'import PSCVL.Policy',
  '',
  '/-! Diagnostic only: 42 required source rows, 84 actual imported-Lean typeclass queries.',
  'No registrations, proof admission authority, or certified output. -/',
  'set_option autoImplicit false',
  '',
  ...requests.map(x=>'#synth '+x.leanGoal),
  '',
  // Each exact goal is also elaborated as a Lean-checked instance witness.
  ...requests.map(x=>'example : '+x.leanGoal+' := inferInstance'),
  '',
 ].join('\n');
 const plan={
   protocol:'psc-lean-arithmetic-typeclass-batch/0',
   normativeSourceSha256:source.normativeSha256,
   surfaceRequirementsSha256:source.sourceDigest,
   leanVersion:'4.35.0-rc3',
   sourceRows:rows,
   goals:requests,
   generatedSourceSha256:hash(generatedSource),
 };
 return Object.freeze({
  schemaVersion:0,kind:plan.protocol,status:'generated-typed-queries-not-standard',
  identitySha256:hash(JSON.stringify(plan)),
  ...plan,sourceRowCount:rows.length,typedQueryCount:requests.length,
  generatedSource,
  declarationMappingApproved:false,scopedResolutionQualified:false,
  normativeIdsApproved:0,verifiedExecutableAuthorized:false,pscvVerified:false,
 });
}

export function reviewArithmeticBatch({normativeReference,generatedSource,transcript}){
 const expected=buildArithmeticBatch(normativeReference);
 if(typeof generatedSource!=='string'||typeof transcript!=='string'||
    Buffer.byteLength(generatedSource)>80000||Buffer.byteLength(transcript)>500000)
   fail('INPUT_BOUNDS');
 const src=normal(generatedSource),stdout=normal(transcript).trim();
 if(src!==expected.generatedSource)fail('GENERATED_SOURCE');
 if(!stdout||/\bsorryAx\b|\badmit\b|(?:^|\n)[^\n]*error:/iu.test(stdout))
   fail('SYNTHESIS_ERRORS');
 const terms=stdout.split('\n').map(x=>x.trim());
 if(terms.length!==expected.typedQueryCount||
    terms.some(x=>x.length===0||x.length>4096||!/^[A-Za-z0-9_.]+$/u.test(x)))
   fail('OUTPUT_COVERAGE');
 const observations=expected.goals.map((g,i)=>Object.freeze({
  surfaceId:g.surfaceId,goalKind:g.goalKind,requestedClassGoal:g.leanGoal,
  observedSelectedTerm:terms[i],
  semanticMappingApproved:false,
  importedLeanIsClosedStandard:false,
  dependentDictionaryRelationProved:false,
 }));
 const identity={
  protocol:'psc-arithmetic-imported-lean-observation/0',
  normativeSourceSha256:expected.normativeSourceSha256,
  planSha256:expected.identitySha256,
  generatedLeanSha256:expected.generatedSourceSha256,
  transcriptSha256:hash(stdout),
  observations,
 };
 return Object.freeze({
  schemaVersion:0,kind:identity.protocol,
  state:'actual-imported-lean-arithmetic-observations-not-standard',
  identitySha256:hash(JSON.stringify(identity)),...identity,
  requiredSurfaceRows:230,requiredSnapshotIDs:194,
  observedArithmeticRows:expected.sourceRowCount,
  observedGoals:observations.length,typesExamined:types.length,
  previousSourceLocatedDirectBoolIDs:3,
  unresolvedNormativeIDs:191,
  exactGenericToConcreteDependencyProved:false,
  approvedStandardRegistryFrozen:false,
  coercionSimpProverEffectsQualified:false,
  verifiedExecutableAuthorized:false,pscvVerified:false,
 });
}
