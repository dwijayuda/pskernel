import {compileTypeScript,emitExpression,emitModule,emitV061TypeScript} from '../src/index.js';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
equal(emitExpression({kind:'literal',value:3n}),'3n');
equal(emitExpression({kind:'call',fn:{kind:'var',name:'f'},args:[{kind:'literal',value:1}]}),'f(1)');
const output=emitModule({name:'Demo',bindings:[{name:'main',value:{kind:'ctor',tag:'Some',fields:[{kind:'literal',value:1}]}}]});
equal(output.includes('export const main'),true);
equal(output.includes('"Some"'),true);
console.log('ok - @proofscript/backend-ts foundation');

{
  const source=emitV061TypeScript({
    kind:'checked-v061-software-module',
    declarations:[
      {kind:'const',name:'answer',params:[],resultType:'Nat',body:{kind:'nat',value:42n,resultType:'Nat'}},
      {kind:'function',name:'id',params:[{name:'x',type:'Nat'}],resultType:'Nat',body:{kind:'reference',name:'x',resultType:'Nat'}},
    ],
  });
  equal(source.includes('export const answer: bigint = 42n;'),true);
  equal(source.includes('export function id(x: bigint): bigint'),true);
  const compiled=compileTypeScript(source,'main.ts');
  equal(compiled.javascript.includes('export const answer = 42n;'),true);
  equal(compiled.declaration.includes('export declare const answer: bigint;'),true);
  equal(compiled.typescriptVersion.length>0,true);
}
console.log('ok - @proofscript/backend-ts TypeScript compiler pipeline');
