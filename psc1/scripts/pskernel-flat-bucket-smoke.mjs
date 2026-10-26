import {pathToFileURL} from 'node:url';
import {resolve} from 'node:path';
const load=p=>import(pathToFileURL(resolve(p)).href);
const [k,reference]=await Promise.all([load(process.argv[2]),load(process.argv[3])]);
const unit=x=>typeof x==='function'?x():x;
const tag=x=>Object.getOwnPropertySymbols(x).map(s=>x[s]).find(v=>typeof v==='string');
const asNumbers=xs=>{
 const values=[];
 while(tag(xs)==='cons'){
  const p=xs.head;
  if(tag(p.fst)!=='lit'||tag(p.snd)!=='lit'||tag(p.fst.value)!=='nat'||tag(p.snd.value)!=='nat')throw Error('Non-literal fixture result');
  values.push([String(p.fst.value.value),String(p.snd.value.value)]);xs=xs.tail;
 }
 if(tag(xs)!=='nil')throw Error('Bad list tail');
 return JSON.stringify(values);
};
function fixtures(m){
 const E=m.PsKernelExpr,L=m.PsKernelLiteral,T=m.List,M=m.PsKernelExprMapIndex,P=m.PsKernelExprPairSetIndex;
 const list=xs=>xs.reduceRight((t,h)=>T.cons(h,t),unit(T.nil));
 const pair=(a,b)=>({fst:E.lit(L.nat(BigInt(a))),snd:E.lit(L.nat(BigInt(b)))});
 const a=list([pair(1,2)]),b=list([pair(3,4),pair(5,6)]);
 const ma=M.bucket(a),mb=M.bucket(b),pa=P.bucket(a),pb=P.bucket(b);
 const result=[[unit(M.empty),unit(P.empty)],[ma,pa],[mb,pb],
  [M.branch(unit(M.empty),unit(M.empty)),P.branch(unit(P.empty),unit(P.empty))],
  [M.branch(ma,mb),P.branch(pa,pb)],[M.branch(M.branch(ma,unit(M.empty)),mb),P.branch(P.branch(pa,unit(P.empty)),pb)]];
 for(const depth of [0,1,2,4,8,16,17,32]){
  let m=ma,p=pa;
  for(let i=0;i<depth;i++){m=M.branch(m,mb);p=P.branch(p,pb);}
  result.push([m,p]);
 }
 return result;
}
const fs=fixtures(k),rs=fixtures(reference),labels=[];
const require=(label,ok)=>{if(!ok)throw Error('PSC1_FLAT_BUCKET_FAIL '+label);labels.push(label);};
let rejected=false;try{require('forced-failure',false);}catch{rejected=true;}
require('harness-rejection-active',rejected);
const hashes=[0n,1n,2n,3n,7n,15n,16n,65520n,65521n,2n**128n+3n];
for(const fuel of [0,1,2,3,4,8,16,17,32])for(let hi=0;hi<hashes.length;hi++)for(let i=0;i<fs.length;i++){
 const hash=hashes[hi];
 for(const [kind,position,name]of[['map',0,'psKernelExprMapIndexBucket'],['pair',1,'psKernelExprPairSetIndexBucket']]){
  const actual=k[name](BigInt(fuel))(fs[i][position])(hash);
  const old=reference[name](BigInt(fuel))(rs[i][position])(hash);
  require(`${kind}/${fuel}/${hi}/${i}`,asNumbers(actual)===asNumbers(old));
 }
}
if(labels.length!==2521||new Set(labels).size!==2521)throw Error('Incomplete inventory');
console.log('PSC1_FLAT_BUCKET_JS: PASS '+JSON.stringify({assertions:labels.length,labels,exactOriginal:true,
 reference:'actual qualified baseline complete program',allFuelBoundaries:true,publicCurriedABI:true,
 fullKernel:false,performanceQualified:false}));

// Diagnostic only: fixed same-process warmup and balanced order; no whole-workload claim.
const rows=[],iterations=10000;
for(const [kind,position,name]of[['map',0,'psKernelExprMapIndexBucket'],['pair',1,'psKernelExprPairSetIndexBucket']]){
 const run=variant=>{
  const m=variant==='A'?reference:k,tree=variant==='A'?rs[11][position]:fs[11][position];
  let last;
  for(let i=0;i<2000;i++)last=m[name](16n)(tree)(0n);
  const start=process.hrtime.bigint();
  for(let i=0;i<iterations;i++)last=m[name](16n)(tree)(0n);
  const nanoseconds=process.hrtime.bigint()-start;
  if(asNumbers(last)!=='[["1","2"]]')throw Error('Measured traversal returned wrong entries');
  return Number(nanoseconds)/1e6;
 };
 for(const [order,variant]of['A','B','B','A','B','A','A','B'].entries())rows.push({kind,order,variant,iterations,depth:16,milliseconds:run(variant)});
}
console.log('PSC1_FLAT_BUCKET_MICRO: '+JSON.stringify({diagnosticOnly:true,processModel:'same process, two exact complete programs, 2000 warmup per observation',
 rows,performanceQualified:false,wholeWorkloadInference:false}));
