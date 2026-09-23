import {equal,ok,throws} from 'node:assert/strict';
import {
  emitBinaryenWasm,
  instantiateProofScriptWasm,
} from '../src/index.js';
import type {WasmIrModule} from '@proofscript/wasm-ir';

const module:WasmIrModule={
  kind:'proofscript-wasm-ir',
  profile:'proofscript-wasm32-mvp-js-v1',
  functions:[{
    name:'not',
    parameters:[{name:'x',type:'i32'}],
    result:'i32',
    abi:{parameters:['bool'],result:'bool'},
    exportName:'not',
    body:{
      kind:'i32.unary',
      operation:'eqz',
      operand:{kind:'local',name:'x',type:'i32'},
    },
  }],
};

const canonical=emitBinaryenWasm(module);
const canonicalAgain=emitBinaryenWasm(module);
ok(canonical.binary.length>0);
ok(WebAssembly.validate(canonical.binary));
equal(canonical.text,canonicalAgain.text);
equal(
  Buffer.from(canonical.binary).toString('hex'),
  Buffer.from(canonicalAgain.binary).toString('hex'),
);

const compiled=new WebAssembly.Module(canonical.binary);
const instance=new WebAssembly.Instance(compiled,{});
const not=instance.exports.not;
ok(typeof not==='function');
equal((not as (value:number)=>number)(0),1);
equal((not as (value:number)=>number)(1),0);

const optimized=emitBinaryenWasm(module,{optimize:true});
ok(WebAssembly.validate(optimized.binary));
const optimizedInstance=new WebAssembly.Instance(
  new WebAssembly.Module(optimized.binary),
  {},
);
const optimizedNot=optimizedInstance.exports.not;
ok(typeof optimizedNot==='function');
equal((optimizedNot as (value:number)=>number)(0),1);
equal((optimizedNot as (value:number)=>number)(1),0);

console.log('ok - @proofscript/backend-wasm Binaryen W1 execution');

console.log('ok - @proofscript/backend-wasm canonical emission is deterministic');

const unsignedModule:WasmIrModule={
  kind:'proofscript-wasm-ir',
  profile:'proofscript-wasm32-mvp-js-v1',
  functions:[
    {
      name:'id8',
      parameters:[{name:'x',type:'i32'}],
      result:'i32',
      abi:{parameters:['uint8'],result:'uint8'},
      exportName:'id8',
      body:{
        kind:'i32.binary',
        operation:'and',
        left:{kind:'local',name:'x',type:'i32'},
        right:{kind:'i32.const',value:0xff},
      },
    },
    {
      name:'id16',
      parameters:[{name:'x',type:'i32'}],
      result:'i32',
      abi:{parameters:['uint16'],result:'uint16'},
      exportName:'id16',
      body:{
        kind:'i32.binary',
        operation:'and',
        left:{kind:'local',name:'x',type:'i32'},
        right:{kind:'i32.const',value:0xffff},
      },
    },
    {
      name:'id32',
      parameters:[{name:'x',type:'i32'}],
      result:'i32',
      abi:{parameters:['uint32'],result:'uint32'},
      exportName:'id32',
      body:{kind:'local',name:'x',type:'i32'},
    },
    {
      name:'id64',
      parameters:[{name:'x',type:'i64'}],
      result:'i64',
      abi:{parameters:['uint64'],result:'uint64'},
      exportName:'id64',
      body:{kind:'local',name:'x',type:'i64'},
    },
  ],
};
const unsignedArtifact=emitBinaryenWasm(unsignedModule);
const unsignedHost=instantiateProofScriptWasm(unsignedArtifact);
equal(unsignedHost.exports.id8?.(0xff),0xff);
equal(unsignedHost.exports.id16?.(0xffff),0xffff);
equal(unsignedHost.exports.id32?.(0xffffffff),0xffffffff);
equal(
  unsignedHost.exports.id64?.(0xffffffffffffffffn),
  0xffffffffffffffffn,
);
const rawId32=unsignedHost.raw.exports.id32;
const rawId64=unsignedHost.raw.exports.id64;
ok(typeof rawId32==='function');
ok(typeof rawId64==='function');
equal((rawId32 as (x:number)=>number)(0xffffffff),-1);
equal((rawId64 as (x:bigint)=>bigint)(-1n),-1n);
throws(
  ()=>unsignedHost.exports.id8?.(0x100),
  /PS_WASM_JS_ABI_UINT8_RANGE/u,
);
throws(
  ()=>unsignedHost.exports.id16?.(0x1_0000),
  /PS_WASM_JS_ABI_UINT16_RANGE/u,
);
throws(
  ()=>unsignedHost.exports.id32?.(0x1_0000_0000),
  /PS_WASM_JS_ABI_UINT32_RANGE/u,
);
throws(
  ()=>unsignedHost.exports.id64?.(-1n),
  /PS_WASM_JS_ABI_UINT64_RANGE/u,
);
console.log('ok - @proofscript/backend-wasm JS ABI restores unsigned semantics');
