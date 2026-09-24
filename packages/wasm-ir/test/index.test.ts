import {equal,throws} from 'node:assert/strict';
import {
  validateWasmIrModule,
  type WasmIrModule,
} from '../src/index.js';

const boolNot:WasmIrModule={
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

throws(
  ()=>validateWasmIrModule({
    kind:'proofscript-wasm-ir',
    profile:'proofscript-wasm32-mvp-js-v1',
    functions:[{
      name:'badAbi',
      parameters:[{name:'x',type:'i32'}],
      result:'i32',
      abi:{parameters:['uint64'],result:'uint32'},
      exportName:'badAbi',
      body:{kind:'local',name:'x',type:'i32'},
    }],
  }),
  /PS_WASM_IR_TYPE_MISMATCH/u,
);

console.log('ok - @proofscript/wasm-ir rejects ABI/physical type drift');

const bigintIdentity={
  kind:'proofscript-wasm-ir',
  profile:'proofscript-wasm32-ref-js-v1',
  functions:[{
    name:'idNat',
    parameters:[{name:'x',type:'externref'}],
    result:'externref',
    abi:{parameters:['nat'],result:'nat'},
    exportName:'idNat',
    body:{kind:'local',name:'x',type:'externref'},
  }],
} as const;

equal(validateWasmIrModule(bigintIdentity),true);

throws(
  ()=>validateWasmIrModule({
    ...bigintIdentity,
    profile:'proofscript-wasm32-mvp-js-v1',
  }),
  /PS_WASM_IR_REFERENCE_TYPE_REQUIRES_REF_PROFILE/u,
);

console.log('ok - @proofscript/wasm-ir W3 Reference Types profile guard');

const natLiteralModule:WasmIrModule={
  kind:'proofscript-wasm-ir',
  profile:'proofscript-wasm32-ref-js-v1',
  imports:[{
    internalName:'ps$bigint$literal',
    module:'proofscript.bigint.v1',
    name:'literal',
    parameters:['i32'],
    result:'externref',
  }],
  bigintLiterals:[{kind:'nat',decimal:'1267650600228229401496703205376'}],
  functions:[{
    name:'hugeNat',
    parameters:[],
    result:'externref',
    abi:{parameters:[],result:'nat'},
    exportName:'hugeNat',
    body:{
      kind:'call',
      target:'ps$bigint$literal',
      args:[{kind:'i32.const',value:0}],
      result:'externref',
    },
  }],
};
equal(validateWasmIrModule(natLiteralModule),true);
throws(
  ()=>validateWasmIrModule({
    ...natLiteralModule,
    bigintLiterals:[
      {kind:'nat',decimal:'1'},
      {kind:'nat',decimal:'1'},
    ],
  }),
  /PS_WASM_IR_DUPLICATE_BIGINT_LITERAL/u,
);
throws(
  ()=>validateWasmIrModule({
    ...natLiteralModule,
    bigintLiterals:[{kind:'nat',decimal:'01'}],
  }),
  /PS_WASM_IR_BIGINT_LITERAL_CANONICAL/u,
);
console.log('ok - @proofscript/wasm-ir W3 canonical bigint literal table');

