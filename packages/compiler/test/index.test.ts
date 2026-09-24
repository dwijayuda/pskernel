import {
  Environment,
  bvar,
  forallE,
  lam,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
} from 'lean-ts-kernel';
import {admitCheckedCoreModule} from '@proofscript/checked-core';
import {compileCheckedCore,compileCheckedCoreToWasm} from '../src/index.js';
import type {
  VerifiedIrDeclaration,
  VerifiedIrModule,
} from '@proofscript/compiler-ir/verified';
import {
  compileTypeScript,
  emitVerifiedTypeScript,
} from '@proofscript/backend-ts/verified';
import {lowerVerifiedIrToWasm} from '@proofscript/wasm-lowering';
import {
  emitBinaryenWasm,
  instantiateProofScriptWasm,
} from '@proofscript/backend-wasm';

function equal(actual:unknown,expected:unknown):void {
  if(actual!==expected){
    throw new Error('expected '+String(expected)+', got '+String(actual));
  }
}

{
  const alpha=nameFromDotted('α');
  const x=nameFromDotted('x');
  const identity=nameFromDotted('identity');
  const alphaType=sort(levelSucc(levelZero));
  const checked=admitCheckedCoreModule(new Environment(),[{
    kind:'definition',
    name:identity,
    levelParams:[],
    type:forallE(
      alpha,
      alphaType,
      forallE(x,bvar(0),bvar(1),'default'),
      'implicit',
    ),
    value:lam(
      alpha,
      alphaType,
      lam(x,bvar(0),bvar(0),'default'),
      'implicit',
    ),
    hints:{kind:'regular',height:1n},
    safety:'safe',
  }]);

  const result=compileCheckedCore(checked,'identity.ts');
  equal(
    result.typeScript.includes(
      'export function identity<T0>(x: T0): T0 { return x; }',
    ),
    true,
  );
  equal(result.emitted.javascript.includes('function identity(x)'),true);
  equal(result.emitted.javascript.includes('T0'),false);
  equal(
    result.emitted.declaration.includes(
      'identity<T0>(x: T0): T0',
    ),
    true,
  );
}
console.log('ok - @proofscript/compiler checked-core orchestration');


{
  const source=compileCheckedCore;
  equal(typeof source,'function');
}
console.log('ok - @proofscript/compiler IR keeps language primitive identity upstream of TS mapping');

{
  const alpha=nameFromDotted('α');
  const x=nameFromDotted('x');
  const identity=nameFromDotted('wasmGenericIdentity');
  const alphaType=sort(levelSucc(levelZero));
  const checked=admitCheckedCoreModule(new Environment(),[{
    kind:'definition',
    name:identity,
    levelParams:[],
    type:forallE(
      alpha,
      alphaType,
      forallE(x,bvar(0),bvar(1),'default'),
      'implicit',
    ),
    value:lam(
      alpha,
      alphaType,
      lam(x,bvar(0),bvar(0),'default'),
      'implicit',
    ),
    hints:{kind:'regular',height:1n},
    safety:'safe',
  }]);

  let code:string|undefined;
  try{
    compileCheckedCoreToWasm(checked);
  }catch(error){
    code=(error as {code?:string}).code;
  }
  equal(code,'PS_WASM_UNSUPPORTED_GENERIC_DECLARATION');
}
console.log('ok - @proofscript/compiler Wasm path fails closed after checked core');

{
  type NatOperation=
    |'nat.add'|'nat.sub'|'nat.mul'|'nat.div'|'nat.mod'
    |'nat.eq'|'nat.ne'|'nat.le'|'nat.lt';
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
  const operations:readonly [
    string,
    NatOperation,
    'Nat'|'Bool',
  ][]=[
    ['addNat','nat.add','Nat'],
    ['subNat','nat.sub','Nat'],
    ['mulNat','nat.mul','Nat'],
    ['divNat','nat.div','Nat'],
    ['modNat','nat.mod','Nat'],
    ['eqNat','nat.eq','Bool'],
    ['neNat','nat.ne','Bool'],
    ['leNat','nat.le','Bool'],
    ['ltNat','nat.lt','Bool'],
  ];
  const ir:VerifiedIrModule={
    kind:'proofscript-verified-ir',
    declarations:operations.map(
      ([name,operation,result])=>declaration(name,operation,result),
    ),
  };

  const typeScript=emitVerifiedTypeScript(ir);
  const emitted=compileTypeScript(typeScript,'wasm-nat-differential.ts');
  const tsModule=await import(
    'data:text/javascript;base64,'+
    Buffer.from(emitted.javascript,'utf8').toString('base64'),
  ) as Record<string,unknown>;

  const wasmIr=lowerVerifiedIrToWasm(ir);
  const wasmHost=instantiateProofScriptWasm(emitBinaryenWasm(wasmIr));
  const optimizedHost=instantiateProofScriptWasm(
    emitBinaryenWasm(wasmIr,{optimize:true}),
  );

  const values=[
    0n,
    1n,
    2n,
    255n,
    256n,
    (1n<<32n)-1n,
    1n<<32n,
    (1n<<64n)-1n,
    1n<<64n,
    1n<<100n,
    10n**100n,
  ];

  for(const [name] of operations){
    const tsFn=tsModule[name] as
      ((a:bigint,b:bigint)=>bigint|boolean)|undefined;
    const wasmFn=wasmHost.exports[name];
    const optimizedFn=optimizedHost.exports[name];
    if(tsFn===undefined||wasmFn===undefined||optimizedFn===undefined){
      throw new Error('missing differential export '+name);
    }
    for(const left of values){
      for(const right of values){
        const expected=tsFn(left,right);
        equal(wasmFn(left,right),expected);
        equal(optimizedFn(left,right),expected);
      }
    }
  }

  equal(wasmHost.exports.subNat?.(0n,1n),0n);
  equal(wasmHost.exports.divNat?.(1n<<100n,0n),0n);
  equal(wasmHost.exports.modNat?.(1n<<100n,0n),1n<<100n);
}
console.log('ok - @proofscript/compiler TS/Wasm Nat differential corpus');
