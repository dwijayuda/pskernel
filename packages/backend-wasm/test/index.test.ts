import {equal,ok,throws} from 'node:assert/strict';
import {
  emitBinaryenWasm,
  instantiateProofScriptWasm,
} from '../src/index.js';
import type {
  WasmIrFunction,
  WasmIrFunctionImport,
  WasmIrModule,
} from '@proofscript/wasm-ir';
import {emitFrozenW2Bytes} from './w2-compat.js';

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
equal(canonical.executionRuntime.profile,'proofscript-wasm32-mvp-js-v1');
equal(canonical.executionRuntime.bigintRuntime,undefined);
equal(canonical.executionRuntime.bigintRuntimeMode,undefined);
ok(canonical.binary.length>0);
ok(WebAssembly.validate(canonical.binary));
equal(canonical.text,canonicalAgain.text);
equal(
  Buffer.from(canonical.binary).toString('hex'),
  Buffer.from(canonicalAgain.binary).toString('hex'),
);
equal(
  Buffer.from(canonical.binary).toString('hex'),
  Buffer.from(emitFrozenW2Bytes(module)).toString('hex'),
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
equal(
  Buffer.from(optimized.binary).toString('hex'),
  Buffer.from(emitFrozenW2Bytes(module,true)).toString('hex'),
);

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
equal(
  Buffer.from(unsignedArtifact.binary).toString('hex'),
  Buffer.from(emitFrozenW2Bytes(unsignedModule)).toString('hex'),
);
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

const uintAddModule:WasmIrModule={
  kind:'proofscript-wasm-ir',
  profile:'proofscript-wasm32-mvp-js-v1',
  functions:[
    {
      name:'add8',
      parameters:[{name:'a',type:'i32'},{name:'b',type:'i32'}],
      result:'i32',
      abi:{parameters:['uint8','uint8'],result:'uint8'},
      exportName:'add8',
      body:{
        kind:'i32.binary',
        operation:'and',
        left:{
          kind:'i32.binary',
          operation:'add',
          left:{kind:'local',name:'a',type:'i32'},
          right:{kind:'local',name:'b',type:'i32'},
        },
        right:{kind:'i32.const',value:0xff},
      },
    },
    {
      name:'add16',
      parameters:[{name:'a',type:'i32'},{name:'b',type:'i32'}],
      result:'i32',
      abi:{parameters:['uint16','uint16'],result:'uint16'},
      exportName:'add16',
      body:{
        kind:'i32.binary',
        operation:'and',
        left:{
          kind:'i32.binary',
          operation:'add',
          left:{kind:'local',name:'a',type:'i32'},
          right:{kind:'local',name:'b',type:'i32'},
        },
        right:{kind:'i32.const',value:0xffff},
      },
    },
    {
      name:'add32',
      parameters:[{name:'a',type:'i32'},{name:'b',type:'i32'}],
      result:'i32',
      abi:{parameters:['uint32','uint32'],result:'uint32'},
      exportName:'add32',
      body:{
        kind:'i32.binary',
        operation:'add',
        left:{kind:'local',name:'a',type:'i32'},
        right:{kind:'local',name:'b',type:'i32'},
      },
    },
    {
      name:'add64',
      parameters:[{name:'a',type:'i64'},{name:'b',type:'i64'}],
      result:'i64',
      abi:{parameters:['uint64','uint64'],result:'uint64'},
      exportName:'add64',
      body:{
        kind:'i64.binary',
        operation:'add',
        left:{kind:'local',name:'a',type:'i64'},
        right:{kind:'local',name:'b',type:'i64'},
      },
    },
  ],
};
const uintAddArtifact=emitBinaryenWasm(uintAddModule);
equal(
  Buffer.from(uintAddArtifact.binary).toString('hex'),
  Buffer.from(emitFrozenW2Bytes(uintAddModule)).toString('hex'),
);
const uintAddHost=instantiateProofScriptWasm(uintAddArtifact);
equal(uintAddHost.exports.add8?.(0xff,1),0);
equal(uintAddHost.exports.add16?.(0xffff,1),0);
equal(uintAddHost.exports.add32?.(0xffffffff,1),0);
equal(uintAddHost.exports.add64?.(0xffffffffffffffffn,1n),0n);
console.log('ok - @proofscript/backend-wasm modular fixed-width UInt addition');
console.log('ok - @proofscript/backend-wasm W2 MVP bytes remain frozen');

const bigintIdentityModule:WasmIrModule={
  kind:'proofscript-wasm-ir',
  profile:'proofscript-wasm32-ref-js-v1',
  functions:[
    {
      name:'idNat',
      parameters:[{name:'x',type:'externref'}],
      result:'externref',
      abi:{parameters:['nat'],result:'nat'},
      exportName:'idNat',
      body:{kind:'local',name:'x',type:'externref'},
    },
    {
      name:'idInt',
      parameters:[{name:'x',type:'externref'}],
      result:'externref',
      abi:{parameters:['int'],result:'int'},
      exportName:'idInt',
      body:{kind:'local',name:'x',type:'externref'},
    },
  ],
};
const bigintArtifact=emitBinaryenWasm(bigintIdentityModule);
equal(bigintArtifact.executionRuntime.profile,'proofscript-wasm32-ref-js-v1');
equal(bigintArtifact.executionRuntime.bigintRuntime,'proofscript.bigint.v1');
equal(bigintArtifact.executionRuntime.bigintRuntimeMode,'js-host');
ok(WebAssembly.validate(bigintArtifact.binary));
const bigintHost=instantiateProofScriptWasm(bigintArtifact);
const hugeNat=(1n<<100n)+123456789n;
equal(bigintHost.exports.idNat?.(hugeNat),hugeNat);
equal(bigintHost.exports.idInt?.(-hugeNat),-hugeNat);
throws(
  ()=>bigintHost.exports.idNat?.(-1n),
  /PS_WASM_JS_ABI_NAT_RANGE/u,
);
console.log('ok - @proofscript/backend-wasm W3 externref bigint identity scaffold');

const hugeLiteral=1267650600228229401496703205376n;
const bigintLiteralModule:WasmIrModule={
  kind:'proofscript-wasm-ir',
  profile:'proofscript-wasm32-ref-js-v1',
  imports:[{
    internalName:'ps$bigint$literal',
    module:'proofscript.bigint.v1',
    name:'literal',
    parameters:['i32'],
    result:'externref',
  }],
  bigintLiterals:[{kind:'nat',decimal:hugeLiteral.toString()}],
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
const bigintLiteralArtifact=emitBinaryenWasm(bigintLiteralModule);
ok(WebAssembly.validate(bigintLiteralArtifact.binary));
equal(bigintLiteralArtifact.bigintLiterals[0]?.decimal,hugeLiteral.toString());
const bigintLiteralHost=instantiateProofScriptWasm(bigintLiteralArtifact);
equal(bigintLiteralHost.exports.hugeNat?.(),hugeLiteral);
throws(
  ()=>instantiateProofScriptWasm(
    bigintLiteralArtifact,
    {'proofscript.bigint.v1':{literal:()=>0n}},
  ),
  /PS_WASM_JS_ABI_RESERVED_IMPORT_COLLISION/u,
);
console.log('ok - @proofscript/backend-wasm W3 reserved bigint literal runtime');

{
  const internalName=(name:string)=>
    ['ps','bigint',name].join(String.fromCharCode(36));
  const runtimeImport=(
    name:string,
    result:'externref'|'i32',
  ):WasmIrFunctionImport=>({
    internalName:internalName(name),
    module:'proofscript.bigint.v1',
    name,
    parameters:['externref','externref'],
    result,
  });
  const runtimeFunction=(
    name:string,
    imported:string,
    result:'nat'|'bool',
  ):WasmIrFunction=>({
    name,
    parameters:[
      {name:'a',type:'externref'},
      {name:'b',type:'externref'},
    ],
    result:result==='nat'?'externref':'i32',
    abi:{parameters:['nat','nat'],result},
    exportName:name,
    body:{
      kind:'call',
      target:internalName(imported),
      args:[
        {kind:'local',name:'a',type:'externref'},
        {kind:'local',name:'b',type:'externref'},
      ],
      result:result==='nat'?'externref':'i32',
    },
  });
  const valueOps=[
    ['addNat','nat_add'],
    ['subNat','nat_sub'],
    ['mulNat','nat_mul'],
    ['divNat','nat_div'],
    ['modNat','nat_mod'],
  ] as const;
  const compareOps=[
    ['eqNat','nat_eq'],
    ['neNat','nat_ne'],
    ['leNat','nat_le'],
    ['ltNat','nat_lt'],
  ] as const;
  const natOpsModule:WasmIrModule={
    kind:'proofscript-wasm-ir',
    profile:'proofscript-wasm32-ref-js-v1',
    imports:[
      ...valueOps.map(([,name])=>runtimeImport(name,'externref')),
      ...compareOps.map(([,name])=>runtimeImport(name,'i32')),
    ],
    functions:[
      ...valueOps.map(([name,imported])=>
        runtimeFunction(name,imported,'nat')
      ),
      ...compareOps.map(([name,imported])=>
        runtimeFunction(name,imported,'bool')
      ),
    ],
  };
  const artifact=emitBinaryenWasm(natOpsModule);
  const host=instantiateProofScriptWasm(artifact);
  const huge=(1n<<100n)+123456789n;
  equal(host.exports.addNat?.(huge,7n),huge+7n);
  equal(host.exports.subNat?.(1n,2n),0n);
  equal(host.exports.subNat?.(huge,7n),huge-7n);
  equal(host.exports.mulNat?.(huge,3n),huge*3n);
  equal(host.exports.divNat?.(huge,0n),0n);
  equal(host.exports.divNat?.(huge,3n),huge/3n);
  equal(host.exports.modNat?.(huge,0n),huge);
  equal(host.exports.modNat?.(huge,3n),huge%3n);
  equal(host.exports.eqNat?.(huge,huge),true);
  equal(host.exports.neNat?.(huge,huge+1n),true);
  equal(host.exports.leNat?.(huge,huge),true);
  equal(host.exports.ltNat?.(huge,huge+1n),true);

  const rawAdd=host.raw.exports.addNat;
  ok(typeof rawAdd==='function');
  throws(
    ()=>(rawAdd as (a:unknown,b:unknown)=>unknown)(-1n,1n),
    /PS_WASM_BIGINT_NAT_RANGE/u,
  );

  const optimizedHost=instantiateProofScriptWasm(
    emitBinaryenWasm(natOpsModule,{optimize:true}),
  );
  equal(optimizedHost.exports.addNat?.(huge,7n),huge+7n);
  equal(optimizedHost.exports.subNat?.(1n,2n),0n);
  equal(optimizedHost.exports.divNat?.(huge,0n),0n);
  equal(optimizedHost.exports.modNat?.(huge,0n),huge);
}
console.log('ok - @proofscript/backend-wasm W3a Nat bigint runtime semantics');

