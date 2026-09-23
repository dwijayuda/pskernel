import {compileTypeScript,emitExpression,emitModule,emitV061TypeScript} from '../src/index.js';
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
