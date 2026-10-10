/**
 * P1-H imported declaration type/module review. This does not locate source
 * lines, approve registrations, prove a generic dictionary dependency, or
 * supply independent Core replay.
 */
import {createHash} from 'node:crypto';
import {buildStandardWorkLedger} from './standard-work-ledger.mjs';
const sha=x=>createHash('sha256').update(x).digest('hex');
const fail=x=>{throw Error('PSC_PSCV_DECL_TYPES_'+x);};
const object=x=>x!==null&&typeof x==='object'&&!Array.isArray(x)&&
  Object.getPrototypeOf(x)===Object.prototype;
const exact=(x,keys)=>object(x)&&Object.keys(x).length===keys.length&&
  keys.every(k=>Object.hasOwn(x,k));
const names=Object.freeze([
 'instHAdd','instHMul','instHSub','instAppendString',
 'instBEqOfDecidableEq','instAddNat','instMulNat','instSubNat',
 'Int.instAdd','instDecidableEqNat','instDecidableEqBool',
]);

export function reviewSelectedDeclarationTypes({normativeReference,
 typedSource,typedTranscript,concreteSource,concreteTranscript,rawTypes}) {
 const ledger=buildStandardWorkLedger({
  normativeReference,typedSource,typedTranscript,concreteSource,concreteTranscript,
 });
 if(!exact(rawTypes,['kind','leanVersion','declarations',
    'importedModuleIsSourceLineProof','closedStandardMapped',
    'verifiedExecutableAuthorized'])||
    rawTypes.kind!=='psc-lean-selected-declaration-types/0'||
    rawTypes.leanVersion!=='4.35.0-rc3'||
    rawTypes.importedModuleIsSourceLineProof!==false||
    rawTypes.closedStandardMapped!==false||
    rawTypes.verifiedExecutableAuthorized!==false||
    !Array.isArray(rawTypes.declarations)||
    rawTypes.declarations.length!==names.length)fail('RAW_SCHEMA');
 const observedNames=new Set(ledger.observations.flatMap(x=>[
   x.importedGenericSelection,x.importedConcreteSelection]));
 if(observedNames.size!==names.length||names.some(x=>!observedNames.has(x)))
   fail('WRONG_DECLARATION_SELECTION');
 const records=rawTypes.declarations.map((x,i)=>{
  if(!exact(x,['name','present','importedModule','typeExprRepr'])||
     x.name!==names[i]||x.present!==true||
     typeof x.importedModule!=='string'||
     !/^[A-Za-z0-9_.]+$/u.test(x.importedModule)||
     x.importedModule.length>256||
     typeof x.typeExprRepr!=='string'||
     x.typeExprRepr.length<5||x.typeExprRepr.length>16384||
     /[\u0000-\u0008\u000b-\u001f]/u.test(x.typeExprRepr)) {
    fail('DECLARATION_ENTRY');
  }
  return {
   name:x.name,importedModule:x.importedModule,
   typeExprRepr:x.typeExprRepr,
   typeObservedByPinnedLean:true,
   sourcePathSourceBlobAndLineApproved:false,
   genericToConcreteDependencyProven:false,
   standardRegistrationApproved:false,
  };
 });
 const identity={
  protocol:'psc-imported-selected-constant-types/0',
  normativeSourceSha256:ledger.normativeSourceSha256,
  ledgerSha256:ledger.identitySha256,
  pinnedLeanVersion:'4.35.0-rc3',
  selectedDeclarations:records,
 };
 return Object.freeze({
  schemaVersion:0,kind:identity.protocol,
  status:'imported-type-module-observation-no-source-line',
  identitySha256:sha(JSON.stringify(identity)),
  ...identity,
  observedDeclarationCount:records.length,
  normativeSnapshotIds:ledger.requiredIdsCount,
  remainingUnresolvedIDs:ledger.unresolvedIdsCount,
  exactSourceLineAndBlobQualified:false,
  scopedSearchOrderQualified:false,
  normativeStandardFrozen:false,
  compilerRuntimePreservationProved:false,
  verifiedExecutableAuthorized:false,
  pscvVerified:false,
 });
}
