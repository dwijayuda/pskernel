import {equal,throws} from 'node:assert/strict';
import {
  validateWasmIrModule,
  type WasmIrModule,
} from '../src/index.js';

const boolNot:WasmIrModule={
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

equal(validateWasmIrModule(boolNot),true);

throws(
  ()=>validateWasmIrModule({
    ...boolNot,
    functions:[{
      ...boolNot.functions[0]!,
      body:{kind:'local',name:'missing',type:'i32'},
    }],
  }),
  /PS_WASM_IR_UNKNOWN_LOCAL/,
);

console.log('ok - @proofscript/wasm-ir W1 structural validation');
