// Linux Actions only: actual List signatures, not module/term admission.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const dir='dist/pskernel-min/list-types',matrixRoot='dist/pskernel-min/module-matrix';
fs.mkdirSync(dir,{recursive:true});fs.writeFileSync(path.join(dir,'package.json'),'{"type":"module"}\n');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
function run(command,args,input,timeout=240000){const r=spawnSync(command,args,{input,encoding:'utf8',timeout,maxBuffer:32*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+'\n'+r.stderr);return r.stdout;}
const matrix=JSON.parse(fs.readFileSync(matrixRoot+'/matrix.json'));
assert.equal(matrix.totalModules,124);
assert.equal(matrix.counts.independentlyProducedMinAdmittedClosures,1);
assert.equal(matrix.counts.fullyCompilerQualifiedModules,0);
const row=matrix.rows.find(r=>r.module==='Ps.Foundation.List');
assert.equal(row.standalone.producer,'accepted');assert.equal(row.standalone.sourceCoreDeclarations,21);
const raw=fs.readFileSync(row.standalone.packet.file);assert.equal(sha(raw),row.standalone.packet.checkedSha256);
const official=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],raw));
assert.equal(official.accepted,true);assert.equal(official.leanVersion,'4.35.0');
assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const publicMin=JSON.parse(run(process.execPath,['--max-old-space-size=256','scripts/minkernel-module-matrix-worker.mjs',row.standalone.packet.file],undefined,120000));
assert.equal(publicMin.accepted,false);assert.equal(publicMin.code,'PSC1_MIN_CORE_REFUSED');assert.equal(publicMin.delegated,false);
const packet=JSON.parse(raw),records=packet.admissions;assert.equal(records.length,21);
assert.ok(records.every(r=>r.kind==='constant'&&r.declaration.lp.length===0));
const name=n=>n.k==='a'?'':(name(n.p)?name(n.p)+'.':'')+String(n.v);
const V=i=>({kind:'var',index:String(i)}),N={kind:'nat'},B={kind:'bool'},L=element=>({kind:'list',element}),
 X=(error,result)=>({kind:'except',error,result}),P=(left,right)=>({kind:'prod',left,right}),
 A=(...types)=>types.length===1?types[0]:({kind:'arr',domain:types[0],result:A(...types.slice(1))}),
 S=(arity,body)=>({arity:String(arity),body});
const alpha=V(0),beta=V(1),error=V(2),la=L(alpha),lb=L(beta),pair=L(P(alpha,beta));
const expected={
 psListLengthAcc:S(1,A(la,N,N)),psListLength:S(1,A(la,N)),psListIsEmpty:S(1,A(la,B)),
 psListAny:S(1,A(A(alpha,B),la,B)),psListReverseAcc:S(1,A(la,la,la)),psListReverse:S(1,A(la,la)),
 psListAppend:S(1,A(la,la,la)),psListMapAcc:S(2,A(A(alpha,beta),la,lb,lb)),
 psListMap:S(2,A(A(alpha,beta),la,lb)),psListMapExceptAcc:S(3,A(A(alpha,X(error,beta)),la,lb,X(error,lb))),
 psListMapExcept:S(3,A(A(alpha,X(error,beta)),la,X(error,lb))),
 psListTakeAcc:S(1,A(N,la,la,la)),psListTake:S(1,A(N,la,la)),
 psListZipAcc:S(2,A(la,lb,pair,pair)),psListZip:S(2,A(la,lb,pair))
};
const cases=[];
for(const rec of records){const full=name(rec.declaration.n),base=full.replace(/\.\$psc0SH\.0$/,'');
 assert.ok(expected[base],'source signature drift '+full);
 for(const fuel of [0,1,256])cases.push({id:full+'/fuel-'+fuel,source:rec.declaration.t,fuel,expected:fuel===256?expected[base]:null,actualModule:true});
 const shadow=e=>Array.isArray(e)?e.map(shadow):e&&typeof e==='object'?Object.fromEntries(Object.entries(e).map(([k,v])=>[k,k==='n'&&e.k==='forall'?{k:'s',p:{k:'a'},v:'same'}:shadow(v)])):e;
 cases.push({id:full+'/shadowed-binder-names',source:shadow(rec.declaration.t),fuel:256,expected:expected[base],actualModule:false});
}
const anon={k:'a'},nm=s=>({k:'s',p:anon,v:s}),con=(s,ls=[])=>({k:'const',n:nm(s),ls}),b=i=>({k:'b',i}),sort=n=>({k:'sort',l:n===0?{k:'z'}:{k:'s',o:n===1?{k:'z'}:{k:'s',o:{k:'z'}}}}),
 all=(t,body)=>({k:'forall',n:nm('x'),bi:'default',t,b:body}),app=(f,a)=>({k:'app',f,a});
for(const [id,source,wanted] of [
 ['closed-natural',con('Nat'),S(0,N)],
 ['identity',all(sort(1),all(b(0),b(1))),S(1,A(alpha,alpha))],
 ['two-term-holes',all(sort(1),all(b(0),all(b(1),b(2)))),S(1,A(alpha,alpha,alpha))],
 ['bare-type-variable',b(0),null],['bare-sort',sort(1),null],
 ['term-cannot-be-type',all(con('Nat'),b(0)),null],
 ['term-hole-cannot-be-type',all(sort(1),all(b(0),b(0))),null],
 ['higher-rank-refused',all(all(sort(1),all(b(0),b(1))),con('Nat')),null],
 ['higher-kind-refused',all(all(sort(1),sort(1)),con('Nat')),null],
 ['sort-zero-quantifier',all(sort(0),con('Nat')),null],
 ['sort-two-quantifier',all(sort(2),con('Nat')),null],
 ['explicit-level-instance',con('Nat',[{k:'z'}]),null],
 ['unknown-carrier',con('String'),null],
 ['wrong-unary-arity',app(con('Except'),con('Nat')),null],
 ['wrong-binary-arity',app(app(con('List'),con('Nat')),con('Bool')),null],
 ['variable-not-type-constructor',all(sort(1),app(b(0),con('Nat'))),null]
])cases.push({id,source,fuel:256,expected:wanted,actualModule:false});
fs.writeFileSync(dir+'/cases.json',JSON.stringify(cases,null,2)+'\n');
const sources=readOwnedCompilerSources('Ps.MinKernel.Profile.RankOneTypes');
assert.ok(sources.some(s=>s.module==='Ps.MinKernel.Profile.RankOneTypes'));
fs.writeFileSync(dir+'/inputs.json',JSON.stringify(sources.map(s=>({moduleName:s.module.split('.'),source:s.text}))));
fs.writeFileSync(dir+'/native.log',run('lake',['env','lean','--run','scripts/MinKernelListTypes.lean']));
const native=JSON.parse(fs.readFileSync(dir+'/native.json'));assert.equal(native.length,cases.length);
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([dir+'/runtime.ts','--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
const G=await import(pathToFileURL(path.resolve(dir+'/runtime.js')).href);
const list=xs=>{let out=G.List.nil();for(let i=xs.length-1;i>=0;i--)out=G.List.cons(xs[i],out);return out;};
const gn=n=>n.k==='a'?G.PsMinCoreName.anonymous:n.k==='s'?G.PsMinCoreName.str(gn(n.p),list([...Buffer.from(n.v)].map(BigInt))):G.PsMinCoreName.num(gn(n.p),BigInt(n.v));
const gl=l=>l.k==='z'?0n:1n+gl(l.o),E=G.PsMinCoreExpr;
const ge=e=>{if(e.k==='b')return E.bvar(BigInt(e.i));if(e.k==='sort')return E.sort(gl(e.l));
 if(e.k==='const')return E.constant(gn(e.n),list(e.ls.map(gl)));
 if(e.k==='app')return E.app(ge(e.f),ge(e.a));if(e.k==='forall')return E.forallE(gn(e.n),BigInt(['default','implicit','strictImplicit','instImplicit'].indexOf(e.bi)),ge(e.t),ge(e.b));throw Error(e.k);};
const tag=v=>v[Object.getOwnPropertySymbols(v)[0]];
function gt(v){const k=tag(v);if(k==='tvar')return V(v.index);if(k==='natural')return N;if(k==='boolean')return B;if(k==='unit')return{kind:'unit'};
 if(k==='arr')return A(gt(v.domain),gt(v.result));if(k==='list')return L(gt(v.element));if(k==='option')return{kind:'option',element:gt(v.element)};
 if(k==='except')return X(gt(v.error),gt(v.result));if(k==='prod')return P(gt(v.left),gt(v.right));throw Error('unknown generated type '+String(k));}
const observations=[];
for(let i=0;i<cases.length;i++){const c=cases[i],result=G.psMinRankSignature(BigInt(c.fuel),ge(c.source));
 const scheme=tag(result)==='none'?null:{arity:String(result.value.arity),body:gt(result.value.body)};
 assert.equal(native[i].id,c.id);assert.deepEqual(native[i].scheme,c.expected,c.id+' native/source expectation');
 assert.deepEqual(scheme,c.expected,c.id+' generated/source expectation');
 observations.push({id:c.id,scheme,actualModule:c.actualModule});
}
const runtimeRaw=fs.readFileSync(dir+'/runtime.admissions.json'),runtimeBytes=runtimeRaw.at(-1)===10?runtimeRaw.subarray(0,-1):runtimeRaw;
fs.writeFileSync(dir+'/runtime.canonical.json',runtimeBytes);
const runtimeOfficial=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],runtimeBytes));
assert.equal(runtimeOfficial.accepted,true);assert.equal(runtimeOfficial.leanVersion,'4.35.0');
assert.equal(runtimeOfficial.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const policy=JSON.parse(fs.readFileSync(dir+'/source-policy.json'));
for(const key of ['sourceAccepted','targetAccepted','originalIrAccepted'])assert.equal(policy[key],true);
for(const key of ['providerChecked','semanticContractQualified','strictSh1Qualified'])assert.equal(policy[key],false);
assert.equal(policy.moduleCount,sources.length);
const receipt={schema:'psc1-actual-list-rank-one-signatures/1',head:process.env.GITHUB_SHA,platform:process.platform,
 module:row.module,source:row.source,actualSignatures:records.length,actualPacket:{bytes:raw.length,sha256:sha(raw)},
 nativeGeneratedAndIndependentExpectedPassed:true,cases:cases.length,actualPublicMin:publicMin,official,
 runtimeSources:sources.map(s=>({module:s.module,path:s.path,bytes:Buffer.byteLength(s.text),sha256:sha(s.text)})),
 runtimePolicy:policy,runtimeOfficial,files:['runtime.ts','runtime.js','runtime.canonical.json','native.json','cases.json'].map(file=>{const bytes=fs.readFileSync(dir+'/'+file);return{file,bytes:bytes.length,sha256:sha(bytes)};}),
 observations,moduleAdmissionAdvanced:false,fullyCompilerQualified:false,
 counts:matrix.counts,boundary:'Type signatures only. No term typing, recursor/foundation soundness, body model, producer preservation or public acceptance is inferred. Actual List remains refused by the unchanged public kernel.'};
fs.writeFileSync(dir+'/receipt.json',JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_ACTUAL_LIST_SIGNATURES_PASS '+JSON.stringify({actualSignatures:records.length,cases:cases.length,publicMinAccepted:false}));
