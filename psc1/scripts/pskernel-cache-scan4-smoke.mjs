import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const k=await import(pathToFileURL(resolve(process.argv[2])).href);
const get=n=>{if(!(n in k))throw Error('missing export '+n);return k[n];};
const unit=x=>typeof x==='function'?x():x;
const same=(a,b)=>a===b||(a!==null&&b!==null&&typeof a==='object'&&typeof b==='object'&&Reflect.ownKeys(a).length===Reflect.ownKeys(b).length&&Reflect.ownKeys(a).every(p=>Object.hasOwn(b,p)&&same(a[p],b[p])));
const L=get('List'),O=get('Option'),nil=unit(L.nil),none=unit(O.none);
const list=xs=>xs.reduceRight((tail,head)=>L.cons(head,tail),nil);
const N=get('PsKernelName'),E=get('PsKernelExpr'),V=get('PsKernelLevel');
const nm=n=>N.str(unit(N.anonymous),'scan4-'+n),zero=unit(V.zero);
const expr=n=>E.bvar(BigInt(n));
const labels=[];
function require(label,value){if(value!==true||labels.includes(label))throw Error('PSC1_CACHE_SCAN4_FAIL '+label);labels.push(label);}
let rejected=false;try{require('forced',false);}catch{rejected=true;}
require('harness-rejects',rejected);
const scan=get('psKernelExprMapGetIn4'),original=get('psKernelExprMapGetIn');
for(let count=0;count<=24;count++){
 const entries=Array.from({length:count},(_,i)=>({fst:expr(i),snd:expr(100+i)}));
 for(let target=0;target<=count;target++){
  const key=expr(target),input=list(entries);
  require('map/'+count+'/'+target,same(scan(key,input),original(key,input)));
  require('map-small-wrapper/'+count+'/'+target,same(get('psKernelExprMapGet')({small:input,index:none},key),original(key,input)));
 }
}
const bind=unit(get('PsKernelBinderInfo').default),s=E.sort(zero);
const a=E.lam(nm('a'),s,E.bvar(0n),bind),b=E.lam(nm('b'),s,E.bvar(0n),bind);
require('map-binder-name-and-first-hit',same(scan(b,list([{fst:a,snd:expr(1)},{fst:b,snd:expr(2)}])),original(b,list([{fst:a,snd:expr(1)},{fst:b,snd:expr(2)}]))));
let cache=unit(get('psKernelExprMapEmpty'));
for(let i=0;i<24;i++)cache=get('psKernelExprMapInsert')(cache,expr(i),expr(200+i));
for(let i=0;i<=24;i++){
 const key=expr(i),bucket=get('psKernelExprMapIndexBucket')(16n)(cache.index.value)(get('psKernelExprHash')(key));
 require('map-index-wrapper/'+i,same(get('psKernelExprMapGet')(cache,key),original(key,bucket)));
}
const checked=x=>{if(!Object.hasOwn(x,'value'))throw Error('arena construction failed');return x.value;};
let arena=unit(get('psKernelExprV2PagedEmpty'));const ids=[];
for(let i=0;i<6;i++){const p=checked(get('psKernelExprV2PagedMkBVar')(arena,BigInt(i)));arena=p.fst;ids.push(p.snd);}
const whnf=get('psKernelExprV2WhnfCacheFindWorker4'),oldWhnf=get('psKernelExprV2WhnfCacheFindWorker');
for(let count=0;count<=24;count++){
 const entries=Array.from({length:count},(_,i)=>({source:ids[i%ids.length],result:BigInt(100+i),hash:BigInt(i%3)}));
 for(const hash of [0n,1n,2n,7n])for(const id of [...ids,arena.size+10n]){
  const input=list(entries),expected=oldWhnf(input,arena,id,hash),tag=count+'/'+hash+'/'+id;
  require('whnf/'+tag,same(whnf(input,arena,id,hash),expected));
  require('whnf-curried/'+tag,same(get('psKernelExprV2WhnfCacheFindIn')(input)(arena)(id)(hash),expected));
 }
}
for(let position=0;position<10;position++){
 const entries=Array.from({length:12},(_,i)=>({source:i===position?arena.size+10n:ids[1],result:BigInt(i),hash:3n}));
 const input=list(entries);
 require('whnf-malformed-first-error/'+position,same(whnf(input,arena,ids[0],3n),oldWhnf(input,arena,ids[0],3n)));
 entries[position].hash=4n;const filtered=list(entries);
 require('whnf-hash-skips-malformed/'+position,same(whnf(filtered,arena,ids[0],3n),oldWhnf(filtered,arena,ids[0],3n)));
}
console.log('PSC1_CACHE_SCAN4_JS: PASS '+JSON.stringify({assertions:labels.length,labels,reference:'actual retained original exported Lean workers in same complete generated program',fullKernel:false,performanceQualified:false,internalMalformedControlsDoNotAuthorizeExternalState:true}));
