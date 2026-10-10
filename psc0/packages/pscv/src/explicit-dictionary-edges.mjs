/**
 * P1-M: generate explicit generic instance terms with their observed
 * concrete dictionary arguments. Lean must typecheck the entire source.
 *
 * A successful witness is a source-level Lean typecheck, not a proof of
 * PSCV's closed instance search, source-to-Core mapping, or backend code.
 */
import {createHash} from 'node:crypto';
import {reviewArithmeticBatch} from './arithmetic-surface-batch.mjs';
const sha=x=>createHash('sha256').update(x).digest('hex');
const fail=x=>{throw Error('PSC_PSCV_DICTIONARY_EDGE_'+x);};
const genericHeads=Object.freeze({HAdd:'instHAdd',HSub:'instHSub',HMul:'instHMul'});
const approvedP1J='364b16cbf5b972411cb00006fc1bcf596671ba57dfcbc7ad23f8517fb63b3c4b';
export function prepareDictionaryApplications({normativeReference,source,transcript}){
 const review=reviewArithmeticBatch({normativeReference,
   generatedSource:source,transcript});
 if(review.identitySha256!==approvedP1J||review.observedGoals!==84)fail('PINNED_P1J_IDENTITY');
 const rows=new Map();
 for(const o of review.observations){
  if(!rows.has(o.surfaceId))rows.set(o.surfaceId,{surfaceId:o.surfaceId});
  rows.get(o.surfaceId)[o.goalKind]=o;
 }
 if(rows.size!==42)fail('REQUIRED_ROW_COVERAGE');
 const supported=[],excluded=[];
 for(const row of [...rows.values()].sort((a,b)=>a.surfaceId<b.surfaceId?-1:1)){
  const gen=row.generic,conc=row.concrete;
  if(!gen||!conc)fail('MISSING_GOAL_PAIR');
  const [className,ty1,ty2,ty3]=gen.requestedClassGoal.split(' ');
  if(!genericHeads[className]||ty1!==ty2||ty2!==ty3||
      conc.requestedClassGoal.split(' ').at(-1)!==ty1)fail('INVALID_PAIR_SHAPE');
  if(gen.observedSelectedTerm!==genericHeads[className]){
   excluded.push({
     surfaceId:row.surfaceId,genericGoal:gen.requestedClassGoal,
     selectedHead:gen.observedSelectedTerm,
     reason:'not-the-known-explicit-single-concrete-dictionary-constructor',
   });
   continue;
  }
  const explicitTerm='@'+gen.observedSelectedTerm+' '+ty1+' '+conc.observedSelectedTerm;
  supported.push({
    surfaceId:row.surfaceId,typeName:ty1,
    genericGoal:gen.requestedClassGoal,
    concreteGoal:conc.requestedClassGoal,
    genericInstance:gen.observedSelectedTerm,
    concreteDictionary:conc.observedSelectedTerm,
    explicitTerm,
    standardInstanceOrderingProved:false,
    genericToConcreteRuntimeSemanticsProved:false,
  });
 }
 if(supported.length<1||supported.length+excluded.length!==42)fail('NO_BOUNDED_WITNESSES');
 const generatedSource=[
  'import PSCVL.Policy',
  '',
  '/-! Typed explicit generic dictionary terms in imported Lean RC3.',
  'These are not closed PSCV Standard evidence or execution certificates. -/',
  'set_option autoImplicit false',
  '',
  ...supported.map(r=>'example : '+r.genericGoal+' := '+r.explicitTerm),
  '',
 ].join('\n');
 const identity={
  protocol:'psc-imported-explicit-dictionary-edges/0',
  normativeSourceSha256:review.normativeSourceSha256,
  priorArithmeticObservationSha256:review.identitySha256,
  leanSemanticPin:'4.35.0-rc3',
  applied:supported,excluded,
  generatedSourceSha256:sha(generatedSource),
 };
 return Object.freeze({
  schemaVersion:0,kind:identity.protocol,
  state:'candidate-explicit-dictionary-expressions-require-actual-Lean-typechecking',
  identitySha256:sha(JSON.stringify(identity)),...identity,
  testedArithmeticSurfaceRows:42,
  attemptedExplicitApplications:supported.length,
  excludedSpecializedGenericInstances:excluded.length,
  source:generatedSource,
  closedStandardQualified:false,
  runtimePreservationProved:false,
  certificateAuthorized:false,pscvVerified:false,
 });
}
export function reviewDictionaryApplications({normativeReference,originalLean,originalTranscript,
  generatedSource,leanCheckOutput}){
 const expected=prepareDictionaryApplications({
  normativeReference,source:originalLean,transcript:originalTranscript,
 });
 if(typeof generatedSource!=='string'||typeof leanCheckOutput!=='string'||
   generatedSource!==expected.source ||
   Buffer.byteLength(generatedSource)>100000 ||
   Buffer.byteLength(leanCheckOutput)>100000)fail('SOURCE_OR_OUTPUT');
 if(leanCheckOutput.trim()!=='' ||
   /sorryAx|\badmit\b/iu.test(generatedSource))fail('LEAN_TYPECHECK_DIAGNOSTIC');
 const {source,...metadata}=expected;
 return Object.freeze({
  ...metadata,status:'explicit-dictionary-source-checked-in-cloud-observational',
  actualLeanTypecheckRequired:true,
  coveredRowsWithCandidateSource:expected.attemptedExplicitApplications,
  unrelatedStdSnapshotIDsStillUnresolved:191,
  approvedStandardRegistry:false,verifiedExecutableAuthorized:false,pscvVerified:false,
 });
}
