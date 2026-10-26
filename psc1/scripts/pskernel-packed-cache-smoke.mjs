import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const k=await import(pathToFileURL(resolve(process.argv[2])).href);
const get=n=>{if(!(n in k))throw Error('Missing export '+n);return k[n];};
const unit=x=>typeof x==='function'?x():x;
const E=get('PsKernelExpr'),N=get('PsKernelName'),L=get('PsKernelLevel'),Lit=get('PsKernelLiteral'),List=get('List');
const nil=unit(List.nil),name=N.str(unit(N.anonymous),'PackedCacheCheck'),bi=unit(get('PsKernelBinderInfo').default);
const zero=unit(L.zero),one=L.succ(zero),sort=E.sort(one);
const list=xs=>xs.reduceRight((tail,head)=>List.cons(head,tail),nil);
const reference=get('psKernelExprClosedCacheAnalysis'),candidate=get('psKernelExprClosedCachePackedAnalysis');
const same=(a,b)=>a===b||(a!==null&&b!==null&&typeof a==='object'&&typeof b==='object'&&Reflect.ownKeys(a).length===Reflect.ownKeys(b).length&&Reflect.ownKeys(a).every(p=>Object.hasOwn(b,p)&&same(a[p],b[p])));
const seeds=[E.bvar(0n),E.bvar(1000000000000000000n),E.fvar(name),E.mvar(name),sort,
 E.sort(L.max(one,L.succ(one))),E.sort(L.imax(one,L.param(name))),E.sort(L.mvar(name)),
 E.const(name,nil),E.const(name,list([one,L.param(name)])),E.lit(Lit.nat(65521n)),
 E.lit(Lit.nat(1000000000000000000000000000n)),E.lit(Lit.str('Aé€😀')),E.lit(Lit.str(''))];
const pool=[...seeds],labels=[];let open=0,closed=0,state=0x1684;
const next=()=>{state=(Math.imul(state,1664525)+1013904223)>>>0;return state;};
const take=()=>pool[next()%pool.length];
for(let i=0;i<2400;i++){
 let expr;
 if(i<seeds.length)expr=seeds[i];
 else switch(i%12){
 case 0:expr=E.app(take(),take());break;
 case 1:expr=E.lam(name,take(),take(),bi);break;
 case 2:expr=E.forallE(name,take(),take(),bi);break;
 case 3:expr=E.letE(name,take(),take(),take(),false);break;
 case 4:expr=E.letE(name,take(),take(),take(),true);break;
 case 5:expr=E.mdata(BigInt(next()),take());break;
 case 6:expr=E.proj(name,BigInt(next()),take());break;
 case 7:expr=E.app(E.fvar(name),take());break;
 case 8:expr=E.app(sort,E.fvar(N.num(name,BigInt(next()))));break;
 case 9:expr=E.const(N.num(name,BigInt(next())),list([L.max(one,zero),L.imax(zero,one)]));break;
 case 10:expr=E.lit(Lit.str('closed-'+i+'-é😀'));break;
 default:expr=E.mvar(N.num(name,BigInt(next())));
 }
 const a=reference(expr),b=candidate(expr);
 if(!same(a,b))throw Error('Packed analysis mismatch at '+i);
 if(a.snd===true)open++;else if(a.snd===false)closed++;else throw Error('Bad reference result');
 labels.push('expression-'+i);
 if(pool.length<512)pool.push(expr);else pool[seeds.length+(next()%(512-seeds.length))]=expr;
}
if(open===0||closed===0||labels.length!==new Set(labels).size)throw Error('Bad case inventory');
console.log('PSC1_PACKED_CACHE_JS: PASS '+JSON.stringify({assertions:labels.length,labels,open,closed,
 reference:'actual byte-preserved original psKernelExprClosedCacheAnalysis export in same complete program',
 exactPairEquality:true,fullKernel:false,performanceQualified:false}));
