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
equal(lowered.functions[0]?.abi.parameters[0],'bool');
equal(lowered.functions[0]?.abi.result,'bool');
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

throws(
  ()=>lowerVerifiedIrToWasm({
    kind:'proofscript-verified-ir',
    declarations:[{
      name:'broken-name',
      typeParameters:[],
      parameters:[],
      resultType:{kind:'primitive',name:'Bool'},
      body:{kind:'literal',value:true},
    }],
  }),
  /invalid verified IR identifier/u,
);

console.log('ok - @proofscript/wasm-lowering validates input IR');

{
  const uintModule:VerifiedIrModule={
    kind:'proofscript-verified-ir',
    declarations:[
      {
        name:'id8',
        typeParameters:[],
        parameters:[{
          name:'x',
          type:{kind:'primitive',name:'UInt8'},
        }],
        resultType:{kind:'primitive',name:'UInt8'},
        body:{kind:'var',name:'x'},
      },
      {
        name:'id16',
        typeParameters:[],
        parameters:[{
          name:'x',
          type:{kind:'primitive',name:'UInt16'},
        }],
        resultType:{kind:'primitive',name:'UInt16'},
        body:{kind:'var',name:'x'},
      },
      {
        name:'id32',
        typeParameters:[],
        parameters:[{
          name:'x',
          type:{kind:'primitive',name:'UInt32'},
        }],
        resultType:{kind:'primitive',name:'UInt32'},
        body:{kind:'var',name:'x'},
      },
      {
        name:'id64',
        typeParameters:[],
        parameters:[{
          name:'x',
          type:{kind:'primitive',name:'UInt64'},
        }],
        resultType:{kind:'primitive',name:'UInt64'},
        body:{kind:'var',name:'x'},
      },
    ],
  };
  const loweredUInt=lowerVerifiedIrToWasm(uintModule);
  equal(loweredUInt.functions[0]?.parameters[0]?.type,'i32');
  equal(loweredUInt.functions[1]?.parameters[0]?.type,'i32');
  equal(loweredUInt.functions[2]?.parameters[0]?.type,'i32');
  equal(loweredUInt.functions[3]?.parameters[0]?.type,'i64');
  equal(loweredUInt.functions[0]?.abi.result,'uint8');
  equal(loweredUInt.functions[1]?.abi.result,'uint16');
  equal(loweredUInt.functions[2]?.abi.result,'uint32');
  equal(loweredUInt.functions[3]?.abi.result,'uint64');
  equal(loweredUInt.functions[0]?.body.kind,'i32.binary');
  equal(loweredUInt.functions[1]?.body.kind,'i32.binary');
  equal(loweredUInt.functions[2]?.body.kind,'local');
  equal(loweredUInt.functions[3]?.body.kind,'local');
}
console.log('ok - @proofscript/wasm-lowering fixed-width UInt pass-through');

{
  const primitive=(name:'UInt8'|'UInt16'|'UInt32'|'UInt64')=>({
    kind:'primitive' as const,
    name,
  });
  const add=(
    name:string,
    type:'UInt8'|'UInt16'|'UInt32'|'UInt64',
    operation:'uint8.add'|'uint16.add'|'uint32.add'|'uint64.add',
  )=>({
    name,
    typeParameters:[],
    parameters:[
      {name:'a',type:primitive(type)},
      {name:'b',type:primitive(type)},
    ],
    resultType:primitive(type),
    body:{
      kind:'intrinsic' as const,
      operation,
      args:[
        {kind:'var' as const,name:'a'},
        {kind:'var' as const,name:'b'},
      ],
    },
  });
  const loweredAdd=lowerVerifiedIrToWasm({
    kind:'proofscript-verified-ir',
    declarations:[
      add('add8','UInt8','uint8.add'),
      add('add16','UInt16','uint16.add'),
      add('add32','UInt32','uint32.add'),
      add('add64','UInt64','uint64.add'),
    ],
  });
  equal(loweredAdd.functions[0]?.body.kind,'i32.binary');
  equal(loweredAdd.functions[1]?.body.kind,'i32.binary');
  equal(loweredAdd.functions[2]?.body.kind,'i32.binary');
  equal(loweredAdd.functions[3]?.body.kind,'i64.binary');
  if(loweredAdd.functions[0]?.body.kind==='i32.binary'){
    equal(loweredAdd.functions[0].body.operation,'and');
  }
  if(loweredAdd.functions[2]?.body.kind==='i32.binary'){
    equal(loweredAdd.functions[2].body.operation,'add');
  }
  if(loweredAdd.functions[3]?.body.kind==='i64.binary'){
    equal(loweredAdd.functions[3].body.operation,'add');
  }
}
console.log('ok - @proofscript/wasm-lowering modular fixed-width UInt addition');
