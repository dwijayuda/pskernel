import {equal,ok} from 'node:assert/strict';
import {
  emitBinaryenWasm,
} from '../src/index.js';
import type {WasmIrModule} from '@proofscript/wasm-ir';

const module:WasmIrModule={
  kind:'proofscript-wasm-ir',
  profile:'proofscript-wasm32-gc-js-v1',
  functions:[{
    name:'not',
    parameters:[{name:'x',type:'i32'}],
    result:'i32',
    exportName:'not',
    body:{
      kind:'i32.unary',
      operation:'eqz',
      operand:{kind:'local',name:'x',type:'i32'},
    },
  }],
};

const canonical=emitBinaryenWasm(module);
ok(canonical.binary.length>0);
ok(WebAssembly.validate(canonical.binary));

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
