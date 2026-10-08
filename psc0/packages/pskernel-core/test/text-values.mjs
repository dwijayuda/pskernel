// Test adapters: all judgments and byte validation run generated owned transitions.
import {k,tag,list,expression,drive} from './checker-values.mjs';
import {nat} from './binding-values.mjs';
import {runtimeName} from './fixture-values.mjs';
import {N,Z,S,U,B,C,app,pi,lam,definition} from './unit-values.mjs';
import {bootstrap} from './nat-values.mjs';
export {k,tag,list,expression,drive,nat,N,Z,S,U,B,C,app,pi,lam,definition,bootstrap,runtimeName};
export const literal=value=>['text',value];
export const rawText=bytes=>bytes.reduceRight((rest,b)=>k.PsKernelText.byte(nat(b),rest),k.PsKernelText.empty);
export const rawLiteral=bytes=>k.PsKernelExpr.lit(k.PsKernelLiteral.text(rawText(bytes)));
export const environment=()=>{const r=bootstrap([]);if(r.status!=='admitted')throw Error(JSON.stringify(r));return r.result.environment;};
export function utf8(bytes,budget=100000){let state=k.psKernelUtf8Start(rawText(bytes));for(let i=0;i<budget;i++){const out=k.psKernelUtf8Step(state);if(tag(out)!=='next')return{status:tag(out),steps:i+1};state=out.state;}return{status:'outOfFuel',steps:budget};}
export const checkRaw=(value,type,env=environment(),budget=1000000)=>drive(k.psKernelTypeStep,k.psKernelCheckStart(env,value,type),budget);
export const inferRaw=(value,env=environment(),budget=1000000)=>drive(k.psKernelTypeStep,k.psKernelInferStart(env,value),budget);
export const convertRaw=(left,right,env=environment(),budget=1000000)=>drive(k.psKernelConversionStep,k.psKernelConversionStart(env,left,right),budget);
export const typeString=()=>expression(C('String'));
export const wireName=x=>x[0]==='anonymous'?{k:'a'}:{k:x[0]==='str'?'s':'n',p:wireName(x[1]),v:x[2]};
export const wireLevel=x=>x[0]==='zero'?{k:'z'}:x[0]==='succ'?{k:'s',o:wireLevel(x[1])}:x[0]==='param'?{k:'p',n:wireName(x[1])}:{k:x[0],l:wireLevel(x[1]),r:wireLevel(x[2])};
export function wireExpr(x){switch(x[0]){case'b':return{k:'b',i:Number(x[1])};case'sort':return{k:'sort',l:wireLevel(x[1])};case'const':return{k:'const',n:wireName(x[1]),ls:x[2].map(wireLevel)};case'text':return{k:'str',v:x[1]};case'nat':return{k:'nat',v:x[1]};case'app':return{k:'app',f:wireExpr(x[1]),a:wireExpr(x[2])};case'lam':case'pi':return{k:x[0]==='lam'?'lam':'forall',n:wireName(x[1]),t:wireExpr(x[2]),b:wireExpr(x[3]),bi:'default'};case'let':return{k:'let',n:wireName(x[1]),t:wireExpr(x[2]),v:wireExpr(x[3]),b:wireExpr(x[4])};default:throw Error('UNSUPPORTED_TEST_EXPR:'+x[0]);}}
export const wireDeclaration=d=>({kind:'constant',declaration:{k:'definition',n:wireName(d.name),lp:d.parameters.map(wireName),t:wireExpr(d.type),v:wireExpr(d.value),s:'safe',h:{k:'regular',h:'1'}}});
export const wire=entries=>JSON.stringify({format:'proofscript-checked-admissions',version:2,admissions:entries.map(wireDeclaration)});
export const equalityWitness=(a,b)=>{const family=pi('s',C('String'),U(S(Z)));return definition('TextWitness',[],pi('F',family,pi('x',app(B(0),b),app(B(1),a))),lam('F',family,lam('x',app(B(0),b),B(0))));};
