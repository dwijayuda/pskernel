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
