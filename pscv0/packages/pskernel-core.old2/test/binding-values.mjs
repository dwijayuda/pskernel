// Independent test adapters/specification; never used as kernel semantics.
import * as k from '../dist/foundation.js';
import { runtimeNatural,runtimeLevel,runtimeName,runtimeText,runtimeFuel } from './fixture-values.mjs';
export { k };
export const tag=x=>x[Object.getOwnPropertySymbols(x)[0]];
export const nat=n=>runtimeNatural(k,String(n));
export const nil=()=>k.PsKernelList.nil();
export const list=xs=>xs.reduceRight((t,x)=>k.PsKernelList.cons(x,t),nil());
export const pname=s=>['str',['anonymous'],s];
export function naturalValue(x){if(tag(x)==='zero')return 0n;let p=x.value,n=0n,w=1n;while(tag(p)!=='one'){if(tag(p)==='bit1')n+=w;w*=2n;p=p.high;}return n+w;}
export function expression(x){const E=k.PsKernelExpr;switch(x[0]){
case'b':return E.bvar(nat(x[1]));case'f':return E.fvar(nat(x[1]));
case'sort':return E.sortE(runtimeLevel(k,x[1]));case'const':return E.constE(runtimeName(k,x[1]),list(x[2].map(v=>runtimeLevel(k,v))));
case'app':return E.app(expression(x[1]),expression(x[2]));
case'lam':case'pi':return E[x[0]==='lam'?'lam':'forallE'](runtimeName(k,x[1]),expression(x[2]),expression(x[3]),k.PsKernelBinder[x[4]]);
case'let':return E.letE(runtimeName(k,x[1]),expression(x[2]),expression(x[3]),expression(x[4]));
case'nat':return E.lit(k.PsKernelLiteral.natural(nat(x[1])));case'text':return E.lit(k.PsKernelLiteral.text(runtimeText(k,x[1])));
case'proj':return E.proj(runtimeName(k,x[1]),nat(x[2]),expression(x[3]));default:throw Error('unknown fixture expression');}}
export function mode(x){switch(x[0]){case'lift':return k.PsKernelBindingMode.lift(nat(x[1]));case'instantiate':return k.PsKernelBindingMode.instantiate(expression(x[1]));case'abstract':return k.PsKernelBindingMode.abstract(nat(x[1]));case'closed':return k.PsKernelBindingMode.closed;default:throw Error('unknown fixture mode');}}
export const runBinding=(c,budget=c.fuel??1024)=>k.psKernelBindingRun(runtimeFuel(k,budget),k.psKernelBindingStart(mode(c.mode),nat(c.depth??'0'),expression(c.input)));
export const checkExpected=c=>c.status==='done'?k.PsKernelBindingResult.done(expression(c.expected)):k.PsKernelBindingResult[c.status];
export function spec(x,op,depth=0n){switch(x[0]){
case'b':{const i=BigInt(x[1]);if(op[0]==='closed'){if(i>=depth)throw Error('scope');return x;}if(op[0]==='lift')return['b',String(i<depth?i:i+BigInt(op[1]))];if(op[0]==='abstract')return x;return i<depth?x:i===depth?spec(op[1],['lift',String(depth)],0n):['b',String(i-1n)];}
case'f':if(op[0]==='closed')throw Error('scope');return op[0]==='abstract'&&x[1]===op[1]?['b',String(depth)]:x;
case'app':return['app',spec(x[1],op,depth),spec(x[2],op,depth)];
case'lam':case'pi':return[x[0],x[1],spec(x[2],op,depth),spec(x[3],op,depth+1n),x[4]];
case'let':return['let',x[1],spec(x[2],op,depth),spec(x[3],op,depth),spec(x[4],op,depth+1n)];
case'proj':return['proj',x[1],x[2],spec(x[3],op,depth)];default:return x;}}
export function randomGenerator(seed){let s=BigInt(seed);return n=>{s=(s*1664525n+1013904223n)&0xffffffffn;return Number(s%BigInt(n));};}
export function randomExpression(rand,depth){if(depth===0)return rand(2)?['b',String(rand(6))]:['f',String(rand(4))];const a=()=>randomExpression(rand,depth-1),b=['explicit','implicit','strictImplicit','instanceImplicit'][rand(4)];switch(rand(9)){
case 0:return['app',a(),a()];case 1:return['lam',pname('x'),a(),a(),b];case 2:return['pi',pname('A'),a(),a(),b];case 3:return['let',pname('y'),a(),a(),a()];case 4:return['proj',pname('S'),'4294967296',a()];case 5:return['nat','9007199254740993'];case 6:return['text','λ\u0000😀'];case 7:return['const',pname('C'),[['imax',['zero'],['param',pname('u')]]]];default:return['sort',['succ',['zero']]];}}
