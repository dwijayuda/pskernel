/**
 * P1-K: selected-instance declaration type/origin discovery for the entire
 * pinned 84-query source-derived P1-J Lean observation.
 * Imported module/type observations do not approve PSCV Standard mapping.
 */
import {createHash} from 'node:crypto';
import {reviewArithmeticBatch} from './arithmetic-surface-batch.mjs';
const sha=s=>createHash('sha256').update(s).digest('hex');
const fail=x=>{throw Error('PSC_PSCV_BATCH_DECL_TYPES_'+x);};
const cmp=(a,b)=>a<b?-1:a>b?1:0;
const exact=(x,keys)=>x!==null&&typeof x==='object'&&!Array.isArray(x)&&
  Object.getPrototypeOf(x)===Object.prototype&&
  Object.keys(x).length===keys.length&&keys.every(k=>Object.hasOwn(x,k));
const expectedP1J='364b16cbf5b972411cb00006fc1bcf596671ba57dfcbc7ad23f8517fb63b3c4b';
export function selectedArithmeticNames({normativeReference,generatedSource,transcript}){
 const review=reviewArithmeticBatch({normativeReference,generatedSource,transcript});
 if(review.identitySha256!==expectedP1J||review.observedGoals!==84||
    review.observedArithmeticRows!==42)fail('PREVIOUS_QUALIFIED_P1J_IDENTITY');
 const names=[...new Set(review.observations.map(x=>x.observedSelectedTerm))].sort(cmp);
 if(names.length<3||names.length>90||
    names.some(s=>!/^[A-Za-z0-9_.]+$/u.test(s)))fail('SELECTED_NAMES');
 return Object.freeze({review,names:Object.freeze(names)});
}
export function reviewSelectedArithmeticTypes({normativeReference,generatedSource,
 transcript,selectedNames,rawTypes}){
 const {review,names}=selectedArithmeticNames({normativeReference,generatedSource,transcript});
 if(!Array.isArray(selectedNames)||JSON.stringify(selectedNames)!==JSON.stringify(names)||
    !exact(rawTypes,['protocol','leanVersion','declarations',
       'closedStandardQualified','sourceLineProvenanceQualified',
       'verifiedExecutableAuthorized'])||
    rawTypes.protocol!=='psc-arithmetic-constant-types/0'||
    rawTypes.leanVersion!=='4.35.0-rc3'||
    rawTypes.closedStandardQualified!==false||
    rawTypes.sourceLineProvenanceQualified!==false||
    rawTypes.verifiedExecutableAuthorized!==false||
    !Array.isArray(rawTypes.declarations)||
    rawTypes.declarations.length!==names.length)fail('RAW_DATA_SCHEMA');
 const records=rawTypes.declarations.map((x,i)=>{
  if(!exact(x,['name','present','importedModule','typeExprRepr'])||
     x.name!==names[i]||x.present!==true||
     typeof x.importedModule!=='string'||
     !/^[A-Za-z0-9_.]+$/u.test(x.importedModule)||
     x.importedModule.length>256||
     typeof x.typeExprRepr!=='string'||
     x.typeExprRepr.length<3||x.typeExprRepr.length>65536||
     /[\u0000-\u0008\u000b-\u001f]/u.test(x.typeExprRepr))
     fail('MISSING_IMPORTED_CONSTANT_OR_TYPE');
  return Object.freeze({
    name:x.name,importedModule:x.importedModule,typeExprRepr:x.typeExprRepr,
    sourcePathGitBlobAndLineLocated:false,
    genericToConcreteDependencyProved:false,
    standardRegistrationApproved:false,
  });
 });
 const identity={
   protocol:'psc-imported-arithmetic-instance-types/0',
   leanVersion:'4.35.0-rc3',
   normativeSha256:review.normativeSourceSha256,
   arithmeticObservationSha256:review.identitySha256,
   selectedNames:names,selectedDeclarations:records,
 };
 return Object.freeze({
   schemaVersion:0,kind:identity.protocol,
   status:'typed-imported-declarations-not-closed-Standard',
   identitySha256:sha(JSON.stringify(identity)),...identity,
   selectedDeclarationCount:names.length,
   arithmeticGoalsReviewed:review.observedGoals,
   normativeRowsReviewed:review.observedArithmeticRows,
   remainingRequiredStandardIds:191,
   pinnedSourceLineProvenanceQualified:false,
   scopedInstanceSelectionQualified:false,
   completeStandardEnvironment:false,
   verifiedExecutableAuthorized:false,pscvVerified:false,
 });
}
