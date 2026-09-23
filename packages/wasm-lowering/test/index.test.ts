import {equal,throws} from 'node:assert/strict';
import type {VerifiedIrModule} from '@proofscript/compiler-ir/verified';
import {
  lowerVerifiedIrToWasm,
  WasmLoweringError,
} from '../src/index.js';

const boolModule:VerifiedIrModule={
  kind:'proofscript-verified-ir',
  declarations:[{
    name:'not',
    typeParameters:[],
    parameters:[{
      name:'x',
      type:{kind:'primitive',name:'Bool'},
    }],
    resultType:{kind:'primitive',name:'Bool'},
    body:{
      kind:'intrinsic',
      operation:'bool.not',
      args:[{kind:'var',name:'x'}],
    },
  }],
};

const lowered=lowerVerifiedIrToWasm(boolModule);
equal(lowered.functions[0]?.name,'not');
equal(lowered.functions[0]?.parameters[0]?.type,'i32');
equal(lowered.functions[0]?.result,'i32');
equal(lowered.functions[0]?.body.kind,'i32.unary');
if(lowered.functions[0]?.body.kind==='i32.unary'){
  equal(lowered.functions[0].body.operand.kind,'i32.binary');
  if(lowered.functions[0].body.operand.kind==='i32.binary'){
    equal(lowered.functions[0].body.operand.operation,'ne');
  }
}

throws(
  ()=>lowerVerifiedIrToWasm({
    kind:'proofscript-verified-ir',
    declarations:[{
      name:'badNat',
      typeParameters:[],
      parameters:[{
        name:'x',
        type:{kind:'primitive',name:'Nat'},
      }],
      resultType:{kind:'primitive',name:'Nat'},
      body:{kind:'var',name:'x'},
    }],
  }),
  (error:unknown)=>
    error instanceof WasmLoweringError&&
    error.code==='PS_WASM_UNSUPPORTED_NAT_RUNTIME',
);

console.log('ok - @proofscript/wasm-lowering W1 semantic Bool lowering');

throws(
  ()=>lowerVerifiedIrToWasm({
    kind:'proofscript-verified-ir',
    imports:[{
      localName:'hostNot',
      source:'host',
      importedName:'not',
      type:{
        kind:'function',
        parameters:[{kind:'primitive',name:'Bool'}],
        result:{kind:'primitive',name:'Bool'},
      },
    }],
    declarations:[],
  }),
  (error:unknown)=>
    error instanceof WasmLoweringError&&
    error.code==='PS_WASM_UNSUPPORTED_EXTERNAL_IMPORTS',
);

console.log('ok - @proofscript/wasm-lowering W1 rejects external imports');
