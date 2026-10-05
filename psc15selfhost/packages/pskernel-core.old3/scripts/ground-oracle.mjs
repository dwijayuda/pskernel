// Test-only serialization and external-oracle harness. NOT a kernel implementation.
// The subject is owned source compiled by PSC; its computations are checked by the
// pinned reference provider. A ground computation proof is not a soundness proof.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {root, json, sha256, checkedTool, sourceClosure} from './source.mjs';
export const name=s=>s.split('.').reduce((p,v)=>({k:'s',p,v}),{k:'a'});
export const C=s=>({k:'const',n:name(s),ls:[]});
export const app=(f,...xs)=>xs.reduce((f,a)=>({k:'app',f,a}),f);
export const ctor=(t,c,...xs)=>app(C('PsKernel'+t+'.'+c),...xs);
export const list=(t,xs)=>xs.reduceRight((r,x)=>ctor('List','cons',t,x,r),ctor('List','nil',t));
export function natural(n){n=BigInt(n);if(n<0n)throw Error('NEGATIVE_NATURAL');if(n===0n)return C('PsKernelNatural.zero');let p=C('PsKernelPositive.one');for(const b of n.toString(2).slice(1))p=ctor('Positive',b==='0'?'bit0':'bit1',p);return ctor('Natural','positive',p);}
export const text=s=>[...new TextEncoder().encode(s)].reduceRight((r,b)=>ctor('Text','byte',natural(b),r),C('PsKernelText.empty'));
export const ownName=d=>d[0]==='anonymous'?C('PsKernelName.anonymous'):ctor('Name',d[0],ownName(d[1]),d[0]==='str'?text(d[2]):natural(d[2]));
export const level=d=>d[0]==='zero'?C('PsKernelLevel.zero'):d[0]==='param'?ctor('Level','param',ownName(d[1])):d[0]==='succ'?ctor('Level','succ',level(d[1])):ctor('Level',d[0],level(d[1]),level(d[2]));
export function expr(d){switch(d[0]){
case'b':case'f':return ctor('Expr',d[0]==='b'?'bvar':'fvar',natural(d[1]));
case'sort':return ctor('Expr','sortE',level(d[1]));
case'const':return ctor('Expr','constE',ownName(d[1]),list(C('PsKernelLevel'),d[2].map(level)));
case'app':return ctor('Expr','app',expr(d[1]),expr(d[2]));
case'lam':case'pi':return ctor('Expr',d[0]==='lam'?'lam':'forallE',ownName(d[1]),expr(d[2]),expr(d[3]),C('PsKernelBinder.'+d[4]));
case'let':return ctor('Expr','letE',ownName(d[1]),expr(d[2]),expr(d[3]),expr(d[4]));
case'proj':return ctor('Expr','proj',ownName(d[1]),natural(d[2]),expr(d[3]));
case'nat':case'text':return ctor('Expr','lit',ctor('Literal',d[0]==='nat'?'natural':'text',d[0]==='nat'?natural(d[1]):text(d[1])));
default:throw Error('EXPR_FIXTURE');}}
export const ownedDefinition=d=>ctor('Definition','definition',ownName(['str',['anonymous'],d.name]),expr(d.type),expr(d.value));
export const definitions=ds=>list(C('PsKernelDefinition'),ds.map(ownedDefinition));
export function createGroundOracle(prefix){
 const pin=json(path.join(root,'manifests/TOOLCHAIN.json'));
 const psc=checkedTool(process.env.PSC1,pin.psc1Sha256,'PSC1');
 const provider=checkedTool(process.env.LEAN_PROVIDER,pin.leanProviderSha256,'LEAN_PROVIDER');
 function run(exe,args,input){const r=spawnSync(exe,args,{cwd:root,input,encoding:'utf8',timeout:180000,maxBuffer:128*1024*1024});if(r.error||r.signal)throw r.error||Error('ORACLE_SIGNAL:'+r.signal);return r;}
 const identity=JSON.parse(run(provider,['--version']).stdout);
 function verifyIdentity(r){if(r.protocol!=='pskernel-lean/1'||r.provider!=='lean4-cpp'||r.leanVersion!==pin.leanVersion||r.leanCommit!==pin.leanCommit||r.profile!=='lean4.34-core')throw Error('ORACLE_IDENTITY');}
 verifyIdentity(identity);
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'pskernel-ground-'));
 let base;
 try{const src=path.join(tmp,'owned.lean');fs.writeFileSync(src,sourceClosure(root));const r=run(psc,['admissions',src]);if(r.status!==0)throw Error('PSC_ADMISSIONS:'+r.stderr+r.stdout);base=JSON.parse(r.stdout).admissions;}finally{fs.rmSync(tmp,{recursive:true,force:true});}
 const helper=[],fuelMemo=new Map(),eqMemo=new Map();let counter=0;
 const defn=(n,t,v)=>({kind:'constant',declaration:{k:'definition',n:name(n),lp:[],t,v,h:{k:'regular',h:'1'},s:'safe'}});
 const pi=(n,t,b)=>({k:'forall',n:name(n),bi:'default',t,b}),b=i=>({k:'b',i});
 function fuel(n){if(!Number.isSafeInteger(n)||n<0||n>4096)throw Error('INVALID_ORACLE_FUEL');if(!fuelMemo.has(n)){let v=C('PsKernelFuel.stop');for(let i=0;i<n;i++)v=ctor('Fuel','more',v);const nme=prefix+'.fuel'+n;helper.push(defn(nme,C('PsKernelFuel'),v));fuelMemo.set(n,C(nme));}return fuelMemo.get(n);}
 function equality(t){if(!eqMemo.has(t)){const n=prefix+'.Equal'+t,T=C('PsKernel'+t);helper.push({kind:'inductive',declaration:{lp:[],np:1,ts:[{n:name(n),t:pi('expected',T,pi('actual',T,{k:'sort',l:{k:'z'}})),cs:[{n:name(n+'.refl'),t:pi('expected',T,app(C(n),b(0),b(0)))}]}]}});eqMemo.set(t,n);}return eqMemo.get(t);}
 function theorem(type,expected,actual){const n=equality(type);return{kind:'constant',declaration:{k:'theorem',n:name(prefix+'.case'+counter++),lp:[],t:app(C(n),expected,actual),v:app(C(n+'.refl'),expected)}};}
 function sorted(x){if(Array.isArray(x))return x.map(sorted);if(x&&typeof x==='object')return Object.fromEntries(Object.keys(x).sort().map(k=>[k,sorted(x[k])]));return x;}
 function check(ds){const request=JSON.stringify(sorted({format:'proofscript-checked-admissions',version:2,admissions:[...base,...helper,...ds]}));const r=run(provider,['--check'],request);let result;try{result=JSON.parse(r.stdout);}catch{throw Error('ORACLE_RESPONSE:'+r.stderr);}verifyIdentity(result);if(r.status!==0&&result.accepted!==false)throw Error('ORACLE_EXIT:'+r.status);return{requestSha256:sha256(request),result};}
 return{pin,identity,fuel,theorem,check,baseCount:base.length,helperCount:()=>helper.length};
}
