import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {reviewSelectedDeclarationTypes} from '../src/selected-declaration-review.mjs';
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const git=p=>execFileSync('git',['-C',root,'show','HEAD:'+p],
 {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const names=['instHAdd','instHMul','instHSub','instAppendString',
 'instBEqOfDecidableEq','instAddNat','instMulNat','instSubNat',
 'Int.instAdd','instDecidableEqNat','instDecidableEqBool'];
const inputs=()=>({
 normativeReference:git('pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'),
 typedSource:git('PSCVL/TypedInstanceWitness.lean'),
 concreteSource:git('PSCVL/ConcreteDictionaryWitness.lean'),
 typedTranscript:['instHAdd','instHMul','instHSub','instHAdd',
  'instAppendString','instBEqOfDecidableEq','instBEqOfDecidableEq'].join('\n')+'\n',
 concreteTranscript:['instAddNat','instMulNat','instSubNat','Int.instAdd',
  'instDecidableEqNat','instDecidableEqBool','instAppendString'].join('\n')+'\n',
 rawTypes:{
  kind:'psc-lean-selected-declaration-types/0',leanVersion:'4.35.0-rc3',
  declarations:names.map(name=>({name,present:true,importedModule:'Init.Core',
    typeExprRepr:'Lean.Expr.app (Lean.Expr.const '+name+')'})),
  importedModuleIsSourceLineProof:false,
  closedStandardMapped:false,verifiedExecutableAuthorized:false,
 },
});
test('selected constant declarations have typed module observation without authority',()=>{
 const x=reviewSelectedDeclarationTypes(inputs());
 assert.equal(x.observedDeclarationCount,11);
 assert.equal(x.normativeSnapshotIds,194);
 assert.equal(x.remainingUnresolvedIDs,191);
 assert.equal(x.exactSourceLineAndBlobQualified,false);
 assert.equal(x.normativeStandardFrozen,false);
 assert.equal(x.pscvVerified,false);
 assert(x.selectedDeclarations.every(y=>y.typeObservedByPinnedLean));
 assert(x.selectedDeclarations.every(y=>!y.standardRegistrationApproved));
 assert.match(x.identitySha256,/^[a-f0-9]{64}$/u);
});
test('data injections, version substitutions and unbound selected declarations fail',()=>{
 const x=inputs();
 for(const altered of [
   {...x,normativeReference:x.normativeReference+'\n'},
   {...x,rawTypes:{...x.rawTypes,verifiedExecutableAuthorized:true}},
   {...x,rawTypes:{...x.rawTypes,leanVersion:'4.35.0-rc4'}},
   {...x,rawTypes:{...x.rawTypes,declarations:x.rawTypes.declarations.slice(1)}},
   {...x,rawTypes:{...x.rawTypes,declarations:x.rawTypes.declarations.map((d,i)=>
      i===0?{...d,name:'forged'}:d)}},
   {...x,rawTypes:{...x.rawTypes,declarations:x.rawTypes.declarations.map((d,i)=>
      i===0?{...d,sourceLineQualified:true}:d)}},
   {...x,rawTypes:{...x.rawTypes,declarations:x.rawTypes.declarations.map((d,i)=>
      i===0?{...d,importedModule:null}:d)}},
   {...x,typedTranscript:x.typedTranscript.replace('instHAdd','other')},
   {...x,concreteTranscript:x.concreteTranscript.replace('instAddNat','other')},
 ]) assert.throws(()=>reviewSelectedDeclarationTypes(altered),
  /PSC_PSCV_(DECL_TYPES|WORK_LEDGER|TYPED_WITNESS|CONCRETE_DICT|REQUIRED_SURFACE)_/u);
});
