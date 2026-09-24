import {equal,throws} from 'node:assert/strict';
import type {
  VerifiedIrDeclaration,
  VerifiedIrIntrinsicOperation,
  VerifiedIrModule,
} from '@proofscript/compiler-ir/verified';
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

{
  const loweredNat=lowerVerifiedIrToWasm({
    kind:'proofscript-verified-ir',
    declarations:[{
      name:'idNat',
      typeParameters:[],
      parameters:[{
        name:'x',
        type:{kind:'primitive',name:'Nat'},
      }],
      resultType:{kind:'primitive',name:'Nat'},
      body:{kind:'var',name:'x'},
    }],
  });
  equal(loweredNat.profile,'proofscript-wasm32-ref-js-v1');
  equal(loweredNat.functions[0]?.parameters[0]?.type,'externref');
  equal(loweredNat.functions[0]?.result,'externref');
  equal(loweredNat.functions[0]?.abi.parameters[0],'nat');
  equal(loweredNat.functions[0]?.abi.result,'nat');
  equal(loweredNat.functions[0]?.body.kind,'local');
}
console.log('ok - @proofscript/wasm-lowering W3a Nat externref pass-through');

{
  const huge=1n<<100n;
  const loweredLiterals=lowerVerifiedIrToWasm({
    kind:'proofscript-verified-ir',
    declarations:[
      {
        name:'hugeNat',
        typeParameters:[],
        parameters:[],
        resultType:{kind:'primitive',name:'Nat'},
        body:{kind:'literal',value:huge},
      },
      {
        name:'sameHugeNat',
        typeParameters:[],
        parameters:[],
        resultType:{kind:'primitive',name:'Nat'},
        body:{kind:'literal',value:huge},
      },
    ],
  });
  equal(loweredLiterals.profile,'proofscript-wasm32-ref-js-v1');
  equal(loweredLiterals.imports?.length,1);
  equal(loweredLiterals.imports?.[0]?.name,'literal');
  equal(loweredLiterals.bigintLiterals?.length,1);
  equal(loweredLiterals.bigintLiterals?.[0]?.kind,'nat');
  equal(loweredLiterals.bigintLiterals?.[0]?.decimal,huge.toString());
  equal(loweredLiterals.functions[0]?.body.kind,'call');
  if(loweredLiterals.functions[0]?.body.kind==='call'){
    equal(loweredLiterals.functions[0].body.target,'ps$bigint$literal');
  }
}
console.log('ok - @proofscript/wasm-lowering W3a Nat literal table lowering');

{
  type NatOperation=Extract<
    VerifiedIrIntrinsicOperation,
    `nat.${string}`
  >;
  const declaration=(
    name:string,
    operation:NatOperation,
    result:'Nat'|'Bool',
  ):VerifiedIrDeclaration=>({
    name,
    typeParameters:[],
    parameters:[
      {name:'a',type:{kind:'primitive',name:'Nat'}},
      {name:'b',type:{kind:'primitive',name:'Nat'}},
    ],
    resultType:{kind:'primitive',name:result},
    body:{
      kind:'intrinsic',
      operation,
      args:[
        {kind:'var',name:'a'},
        {kind:'var',name:'b'},
      ],
    },
  });
  const cases:readonly [
    string,
    NatOperation,
    'Nat'|'Bool',
    string,
  ][]=[
    ['addNat','nat.add','Nat','nat_add'],
    ['subNat','nat.sub','Nat','nat_sub'],
    ['mulNat','nat.mul','Nat','nat_mul'],
    ['divNat','nat.div','Nat','nat_div'],
    ['modNat','nat.mod','Nat','nat_mod'],
    ['eqNat','nat.eq','Bool','nat_eq'],
    ['neNat','nat.ne','Bool','nat_ne'],
    ['leNat','nat.le','Bool','nat_le'],
    ['ltNat','nat.lt','Bool','nat_lt'],
  ];
  const loweredNatOps=lowerVerifiedIrToWasm({
    kind:'proofscript-verified-ir',
    declarations:cases.map(
      ([name,operation,result])=>
        declaration(name,operation,result),
    ),
  });
  equal(loweredNatOps.profile,'proofscript-wasm32-ref-js-v1');
  equal(
    loweredNatOps.imports?.map((item)=>item.name).join(','),
    cases.map((item)=>item[3]).join(','),
  );
  loweredNatOps.functions.forEach((fn,index)=>{
    equal(fn.body.kind,'call');
    if(fn.body.kind==='call'){
      equal(fn.body.target,'ps$bigintconsole.log('ok - @proofscript/wasm-lowering W1 semantic Bool lowering');

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
+cases[index]![3]);
      equal(
        fn.body.result,
        cases[index]![2]==='Bool'?'i32':'externref',
      );
    }
  });
}
console.log('ok - @proofscript/wasm-lowering W3a Nat intrinsic imports');

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
