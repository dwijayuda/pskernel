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

{
  const nat={kind:'primitive',name:'Nat'} as const;
  const bool={kind:'primitive',name:'Bool'} as const;
  const compositionIr:VerifiedIrModule={
    kind:'proofscript-verified-ir',
    declarations:[
      {
        name:'incNat',
        typeParameters:[],
        parameters:[{name:'x',type:nat}],
        resultType:nat,
        body:{
          kind:'intrinsic',
          operation:'nat.add',
          args:[
            {kind:'var',name:'x'},
            {kind:'literal',value:1n},
          ],
        },
      },
      {
        name:'letNat',
        typeParameters:[],
        parameters:[{name:'x',type:nat}],
        resultType:nat,
        body:{
          kind:'let',
          name:'y',
          value:{kind:'var',name:'x'},
          body:{kind:'var',name:'y'},
        },
      },
      {
        name:'chooseNat',
        typeParameters:[],
        parameters:[
          {name:'condition',type:bool},
          {name:'a',type:nat},
          {name:'b',type:nat},
        ],
        resultType:nat,
        body:{
          kind:'if',
          condition:{kind:'var',name:'condition'},
          thenBranch:{kind:'var',name:'a'},
          elseBranch:{kind:'var',name:'b'},
        },
      },
      {
        name:'callNat',
        typeParameters:[],
        parameters:[{name:'x',type:nat}],
        resultType:nat,
        body:{
          kind:'call',
          fn:{kind:'var',name:'incNat'},
          args:[{kind:'var',name:'x'}],
        },
      },
    ],
  };

  const tsSource=emitVerifiedTypeScript(compositionIr);
  const tsEmitted=compileTypeScript(tsSource,'wasm-nat-composition.ts');
  const tsModule=await import(
    'data:text/javascript;base64,'+
    Buffer.from(tsEmitted.javascript,'utf8').toString('base64'),
  ) as Record<string,(...args:never[])=>unknown>;

  const wasmIr=lowerVerifiedIrToWasm(compositionIr);
  const wasm=instantiateProofScriptWasm(emitBinaryenWasm(wasmIr));
  const optimized=instantiateProofScriptWasm(
    emitBinaryenWasm(wasmIr,{optimize:true}),
  );
  const huge=(1n<<100n)+99n;

  const cases=[
    ['incNat',[huge]],
    ['letNat',[huge]],
    ['chooseNat',[true,huge,7n]],
    ['chooseNat',[false,huge,7n]],
    ['callNat',[huge]],
  ] as const;

  for(const [name,args] of cases){
    const expected=(tsModule[name] as (...values:unknown[])=>unknown)(...args);
    equal(wasm.exports[name]?.(...args),expected);
    equal(optimized.exports[name]?.(...args),expected);
  }
}
console.log('ok - @proofscript/compiler Nat call/let/if composition');
