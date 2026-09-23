import {compileTypeScript,emitExpression,emitModule,emitVerifiedTypeScript,emitV061TypeScript} from '../src/index.js';
import {lowerCheckedSoftwareModule} from '@proofscript/compiler-ir';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
equal(emitExpression({kind:'literal',value:3n}),'3n');
equal(emitExpression({kind:'call',fn:{kind:'var',name:'f'},args:[{kind:'literal',value:1}]}),'f(1)');
const output=emitModule({name:'Demo',bindings:[{name:'main',value:{kind:'ctor',tag:'Some',fields:[{kind:'literal',value:1}]}}]});
equal(output.includes('export const main'),true);
equal(output.includes('"Some"'),true);
console.log('ok - @proofscript/backend-ts foundation');

{
  const source=emitV061TypeScript(lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[],
    declarations:[
      {kind:'const',name:'answer',params:[],resultType:'Nat',body:{kind:'nat',value:42n,resultType:'Nat'}},
      {kind:'function',name:'id',params:[{name:'x',type:'Nat'}],resultType:'Nat',body:{kind:'reference',name:'x',resultType:'Nat'}},
    ],
  }));
  equal(source.includes('export const answer: bigint = 42n;'),true);
  equal(source.includes('export function id(x: bigint): bigint'),true);
  const compiled=compileTypeScript(source,'main.ts');
  equal(compiled.javascript.includes('export const answer = 42n;'),true);
  equal(compiled.declaration.includes('export declare const answer: bigint;'),true);
  equal(compiled.typescriptVersion.length>0,true);
}
console.log('ok - @proofscript/backend-ts TypeScript compiler pipeline');

{
  const source=emitV061TypeScript(lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[],
    declarations:[{
      kind:'function',name:'incTwice',params:[{name:'x',type:'Nat'}],resultType:'Nat',
      body:{
        kind:'let',name:'y',declaredType:'Nat',resultType:'Nat',
        value:{kind:'binary',operator:'+',resultType:'Nat',left:{kind:'reference',name:'x',resultType:'Nat'},right:{kind:'nat',value:1n,resultType:'Nat'}},
        body:{kind:'binary',operator:'+',resultType:'Nat',left:{kind:'reference',name:'y',resultType:'Nat'},right:{kind:'nat',value:1n,resultType:'Nat'}},
      },
    }],
  }));
  equal(source.includes('const y: bigint = x + 1n; return y + 1n;'),true);
}
console.log('ok - @proofscript/backend-ts compiler IR boundary');

{
  const source=emitV061TypeScript(lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[],
    declarations:[
      {
        kind:'const',name:'increment',params:[],
        resultType:{kind:'function',parameter:'Nat',result:'Nat'},
        body:{
          kind:'lambda',binders:[{name:'x',type:'Nat'}],
          resultType:{kind:'function',parameter:'Nat',result:'Nat'},
          body:{
            kind:'binary',operator:'+',resultType:'Nat',
            left:{kind:'reference',name:'x',resultType:'Nat'},
            right:{kind:'nat',value:1n,resultType:'Nat'},
          },
        },
      },
      {
        kind:'function',name:'main',params:[{name:'x',type:'Nat'}],resultType:'Nat',
        body:{
          kind:'call',callee:'increment',callStyle:'curried',resultType:'Nat',
          args:[{kind:'reference',name:'x',resultType:'Nat'}],
        },
      },
    ],
  }));
  equal(source.includes('export const increment: (_arg: bigint) => bigint'),true);
  equal(source.includes('(x: bigint) => x + 1n'),true);
  equal(source.includes('return increment(x);'),true);
  const compiled=compileTypeScript(source,'lambda.ts');
  equal(compiled.javascript.includes('increment = (x) => x + 1n'),true);
}
console.log('ok - @proofscript/backend-ts curried lambda TypeScript emission');

{
  const source=emitV061TypeScript(lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[],
    declarations:[{
      kind:'function',name:'choose',params:[{name:'flag',type:'Bool'}],resultType:'Nat',
      body:{
        kind:'match',resultType:'Nat',
        scrutinee:{kind:'reference',name:'flag',resultType:'Bool'},
        alternatives:[
          {pattern:{kind:'bool',value:true},body:{kind:'nat',value:1n,resultType:'Nat'}},
          {pattern:{kind:'bool',value:false},body:{kind:'nat',value:2n,resultType:'Nat'}},
        ],
      },
    }],
  }));
  equal(source.includes('return (flag ? 1n : 2n);'),true);
  const compiled=compileTypeScript(source,'match.ts');
  equal(compiled.javascript.includes('flag ? 1n : 2n'),true);
}
console.log('ok - @proofscript/backend-ts Bool match TypeScript emission');

{
  const userType={kind:'nominal',name:'User'} as const;
  const source=emitV061TypeScript(lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[{name:'User',fields:[{name:'name',type:'String'},{name:'age',type:'Nat'}]}],
    declarations:[
      {
        kind:'const',name:'ada',params:[],resultType:userType,
        body:{
          kind:'record',structure:'User',resultType:userType,
          fields:[
            {name:'name',value:{kind:'string',value:'Ada',resultType:'String'}},
            {name:'age',value:{kind:'nat',value:33n,resultType:'Nat'}},
          ],
        },
      },
      {
        kind:'function',name:'age',params:[{name:'user',type:userType}],resultType:'Nat',
        body:{
          kind:'projection',field:'age',resultType:'Nat',
          target:{kind:'reference',name:'user',resultType:userType},
        },
      },
    ],
  }));
  equal(source.includes('export interface User {'),true);
  equal(source.includes('unique symbol = Symbol("ProofScript.User")'),true);
  equal(source.includes('readonly [__ps_brand_User_'),true);
  equal(source.includes('readonly age: bigint;'),true);
  equal(source.includes('export const ada: User = { [__ps_brand_User_'),true);
  equal(source.includes('name: "Ada", age: 33n };'),true);
  equal(source.includes('return user.age;'),true);
  const compiled=compileTypeScript(source,'structure.ts');
  equal(compiled.declaration.includes('declare const __ps_brand_User_'),true);
  equal(compiled.declaration.includes('unique symbol'),true);
  equal(compiled.declaration.includes('export interface User'),true);
}
console.log('ok - @proofscript/backend-ts nominal structure TypeScript emission');

{
  const maybe={kind:'nominal',name:'MaybeNat'} as const;
  const source=emitV061TypeScript(lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    inductives:[],
    structures:[],
    inductives:[{
      name:'MaybeNat',
      constructors:[
        {name:'none',qualifiedName:'MaybeNat.none',fields:[]},
        {name:'some',qualifiedName:'MaybeNat.some',fields:[{name:'value',type:'Nat'}]},
      ],
    }],
    declarations:[
      {
        kind:'const',name:'one',params:[],resultType:maybe,
        body:{
          kind:'constructor',inductive:'MaybeNat',constructor:'some',resultType:maybe,
          fields:[{name:'value',value:{kind:'nat',value:1n,resultType:'Nat'}}],
        },
      },
      {
        kind:'function',name:'get',params:[{name:'value',type:maybe}],resultType:'Nat',
        body:{
          kind:'match',resultType:'Nat',
          scrutinee:{kind:'reference',name:'value',resultType:maybe},
          alternatives:[
            {
              pattern:{kind:'constructor',inductive:'MaybeNat',constructor:'none',binders:[]},
              body:{kind:'nat',value:0n,resultType:'Nat'},
            },
            {
              pattern:{
                kind:'constructor',inductive:'MaybeNat',constructor:'some',
                binders:[{name:'x',field:'value',type:'Nat'}],
              },
              body:{kind:'reference',name:'x',resultType:'Nat'},
            },
          ],
        },
      },
    ],
  }));
  equal(source.includes('export type MaybeNat ='),true);
  equal(source.includes('unique symbol = Symbol("ProofScript.MaybeNat.tag")'),true);
  equal(source.includes('"some": (__field0: bigint): MaybeNat'),true);
  equal(source.includes('MaybeNat["some"](1n)'),true);
  equal(source.includes('switch (__ps$match[__ps_tag_MaybeNat_'),true);
  const compiled=compileTypeScript(source,'adt.ts');
  equal(compiled.declaration.includes('export type MaybeNat ='),true);
  equal(compiled.declaration.includes('export declare const MaybeNat'),true);
}
console.log('ok - @proofscript/backend-ts nominal inductive TypeScript emission');


{
  const source=emitV061TypeScript(lowerCheckedSoftwareModule({
    kind:'checked-v061-software-module',
    structures:[],
    inductives:[],
    declarations:[{
      kind:'function',
      name:'f',
      params:[{name:'x',type:'Nat'}],
      resultType:'Nat',
      body:{
        kind:'call',
        callee:'helper',
        args:[{kind:'reference',name:'x',resultType:'Nat'}],
        callStyle:'direct',
        resultType:'Nat',
      },
      whereDeclarations:[{
        name:'helper',
        params:[{name:'y',type:'Nat'}],
        resultType:'Nat',
        body:{
          kind:'binary',
          operator:'+',
          resultType:'Nat',
          left:{kind:'reference',name:'y',resultType:'Nat'},
          right:{kind:'nat',value:1n,resultType:'Nat'},
        },
      }],
    }],
  }));
  equal(
    source.includes('function helper(y: bigint): bigint { return y + 1n; }'),
    true,
  );
  equal(source.includes('return helper(x);'),true);
  const compiled=compileTypeScript(source,'where.ts');
  equal(compiled.javascript.includes('function helper(y)'),true);
}
console.log('ok - @proofscript/backend-ts where helper TypeScript emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    declarations:[{
      name:'identity',
      typeParameters:[{name:'T0'}],
      parameters:[{
        name:'x',
        type:{kind:'typeParameter',name:'T0'},
      }],
      resultType:{kind:'typeParameter',name:'T0'},
      body:{kind:'var',name:'x'},
    }],
  });
  equal(source.includes(
    'export function identity<T0>(x: T0): T0 { return x; }',
  ),true);
  const compiled=compileTypeScript(source,'verified-identity.ts');
  equal(
    compiled.javascript.includes('export function identity(x)'),
    true,
  );
  equal(compiled.javascript.includes('T0'),false);
  equal(
    compiled.declaration.includes(
      'export declare function identity<T0>(x: T0): T0;',
    ),
    true,
  );
}
console.log('ok - @proofscript/backend-ts verified generic TypeScript emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    declarations:[
      {
        name:'add',
        typeParameters:[],
        parameters:[
          {name:'x',type:{kind:'primitive',name:'Nat'}},
          {name:'y',type:{kind:'primitive',name:'Nat'}},
        ],
        resultType:{kind:'primitive',name:'Nat'},
        body:{
          kind:'intrinsic',
          operation:'nat.add',
          args:[
            {kind:'var',name:'x'},
            {kind:'var',name:'y'},
          ],
        },
      },
      {
        name:'sub',
        typeParameters:[],
        parameters:[
          {name:'x',type:{kind:'primitive',name:'Nat'}},
          {name:'y',type:{kind:'primitive',name:'Nat'}},
        ],
        resultType:{kind:'primitive',name:'Nat'},
        body:{
          kind:'intrinsic',
          operation:'nat.sub',
          args:[
            {kind:'var',name:'x'},
            {kind:'var',name:'y'},
          ],
        },
      },
    ],
  });
  equal(source.includes('return (x + y);'),true);
  equal(source.includes('__ps_a >= __ps_b ? __ps_a - __ps_b : 0n'),true);
  const compiled=compileTypeScript(source,'verified-nat.ts');
  equal(compiled.javascript.includes('x + y'),true);
  equal(compiled.javascript.includes('__ps_a >= __ps_b'),true);
}
console.log('ok - @proofscript/backend-ts verified Nat intrinsic emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    structures:[{
      name:'User',
      fields:[{
        name:'age',
        type:{kind:'primitive',name:'Nat'},
      }],
    }],
    declarations:[
      {
        name:'make',
        typeParameters:[],
        parameters:[{
          name:'age',
          type:{kind:'primitive',name:'Nat'},
        }],
        resultType:{kind:'named',name:'User',args:[]},
        body:{
          kind:'record',
          structure:'User',
          fields:[{
            name:'age',
            value:{kind:'var',name:'age'},
          }],
        },
      },
      {
        name:'get',
        typeParameters:[],
        parameters:[{
          name:'user',
          type:{kind:'named',name:'User',args:[]},
        }],
        resultType:{kind:'primitive',name:'Nat'},
        body:{
          kind:'projection',
          target:{kind:'var',name:'user'},
          field:'age',
        },
      },
    ],
  });
  equal(source.includes('export interface User {'),true);
  equal(source.includes('unique symbol = Symbol("ProofScript.User")'),true);
  equal(source.includes('return { [__ps$brand$0]: true, age: age };'),true);
  equal(source.includes('return user.age;'),true);
  const compiled=compileTypeScript(source,'verified-structure.ts');
  equal(compiled.declaration.includes('export interface User'),true);
  equal(compiled.javascript.includes('Symbol("ProofScript.User")'),true);
}
console.log('ok - @proofscript/backend-ts verified nominal structure emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    inductives:[{
      name:'MaybeNat',
      constructors:[
        {name:'none',fields:[]},
        {
          name:'some',
          fields:[{
            name:'value',
            type:{kind:'primitive',name:'Nat'},
          }],
        },
      ],
    }],
    declarations:[
      {
        name:'noneValue',
        typeParameters:[],
        parameters:[],
        resultType:{kind:'named',name:'MaybeNat',args:[]},
        body:{
          kind:'constructor',
          inductive:'MaybeNat',
          constructor:'none',
          fields:[],
        },
      },
      {
        name:'oneValue',
        typeParameters:[],
        parameters:[],
        resultType:{kind:'named',name:'MaybeNat',args:[]},
        body:{
          kind:'constructor',
          inductive:'MaybeNat',
          constructor:'some',
          fields:[{
            name:'value',
            value:{kind:'literal',value:1n},
          }],
        },
      },
    ],
  });
  equal(source.includes('export type MaybeNat ='),true);
  equal(source.includes('unique symbol = Symbol("ProofScript.MaybeNat.tag")'),true);
  equal(source.includes('"none": { [__ps$tag$0]: "none" } as MaybeNat'),true);
  equal(source.includes('"some": (__field0: bigint): MaybeNat'),true);
  equal(source.includes('MaybeNat["some"](1n)'),true);
  const compiled=compileTypeScript(source,'verified-adt.ts');
  equal(compiled.declaration.includes('export type MaybeNat ='),true);
  equal(compiled.declaration.includes('export declare const MaybeNat'),true);
}
console.log('ok - @proofscript/backend-ts verified ADT constructor emission');


{
  const source=emitVerifiedTypeScript({
    kind:'proofscript-verified-ir',
    inductives:[{
      name:'MaybeNat',
      constructors:[
        {name:'none',fields:[]},
        {
          name:'some',
          fields:[{
            name:'value',
            type:{kind:'primitive',name:'Nat'},
          }],
        },
      ],
    }],
    declarations:[{
      name:'getOrZero',
      typeParameters:[],
      parameters:[{
        name:'value',
        type:{kind:'named',name:'MaybeNat',args:[]},
      }],
      resultType:{kind:'primitive',name:'Nat'},
      body:{
        kind:'match',
        inductive:'MaybeNat',
        scrutinee:{kind:'var',name:'value'},
        alternatives:[
          {
            constructor:'none',
            bindings:[],
            body:{kind:'literal',value:0n},
          },
          {
            constructor:'some',
            bindings:[{field:'value',name:'x'}],
            body:{kind:'var',name:'x'},
          },
        ],
      },
    }],
  });
  equal(source.includes('switch (__ps$match$0[__ps$tag$0])'),true);
  equal(source.includes('case "none": return 0n;'),true);
  equal(
    source.includes(
      'case "some": return ((x) => x)(__ps$match$0.value);',
    ),
    true,
  );
  const compiled=compileTypeScript(source,'verified-match.ts');
  equal(compiled.javascript.includes('switch (__ps$match$0[__ps$tag$0])'),true);
}
console.log('ok - @proofscript/backend-ts verified ADT match emission');
