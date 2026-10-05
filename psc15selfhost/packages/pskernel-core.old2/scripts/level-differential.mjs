import './verify-build.mjs';
// Bounded comparison with the actual Lean provider's kernel level conversion.
// No source frontend or native computation is used in submitted declarations.
import fs from'node:fs';import path from'node:path';import{spawnSync}from'node:child_process';import{fileURLToPath}from'node:url';import{createHash}from'node:crypto';
import{checkedTool,verifySource}from'./source.mjs';
import{levelCheck,normalize,decodeLevel,randomGenerator,randomLevel,P,S,M,I,Z}from'../test/universe-values.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');verifySource(root);
const tools=JSON.parse(fs.readFileSync(path.join(root,'manifests/TOOLCHAIN.json'),'utf8')),provider=checkedTool(process.env.LEAN_PROVIDER,tools.leanProviderSha256,'LEAN_PROVIDER');
const hash=x=>createHash('sha256').update(x).digest('hex');
const call=(args,input)=>{const r=spawnSync(provider,args,{input,encoding:'utf8',timeout:120000,maxBuffer:4*1024*1024});if(r.error||r.signal)throw r.error||Error('ORACLE_SIGNAL:'+r.signal);const result=JSON.parse(r.stdout);if(result.protocol!=='pskernel-lean/1'||result.provider!=='lean4-cpp'||result.leanVersion!==tools.leanVersion||result.leanCommit!==tools.leanCommit||result.profile!=='lean4.34-core')throw Error('ORACLE_RESPONSE_IDENTITY');return result;};
const identity=call(['--version']);if(identity.protocol!=='pskernel-lean/1'||identity.leanVersion!==tools.leanVersion||identity.leanCommit!==tools.leanCommit||identity.provider!=='lean4-cpp')throw Error('PROVIDER_IDENTITY');
const nam=d=>typeof d==='string'?{k:'s',p:{k:'a'},v:d}:d[0]==='anonymous'?{k:'a'}:{k:d[0]==='str'?'s':'n',p:nam(d[1]),v:d[2]};
const lvl=x=>x[0]==='zero'?{k:'z'}:x[0]==='param'?{k:'p',n:nam(x[1])}:x[0]==='succ'?{k:'s',o:lvl(x[1])}:{k:x[0],l:lvl(x[1]),r:lvl(x[2])};
const b=i=>({k:'b',i}),sort=l=>({k:'sort',l:lvl(l)}),bind=(k,n,t,body)=>({k,n:nam(n),bi:'default',t,b:body});
function sorted(x){if(Array.isArray(x))return x.map(sorted);if(x&&typeof x==='object')return Object.fromEntries(Object.keys(x).sort().map(k=>[k,sorted(x[k])]));return x;}
function request(a,c){const params=new Map();const visit=x=>{if(x[0]==='param')params.set(JSON.stringify(x[1]),nam(x[1]));else if(x[0]==='succ')visit(x[1]);else if(x[0]==='max'||x[0]==='imax'){visit(x[1]);visit(x[2]);}};visit(a);visit(c);
 const t=bind('forall','A',sort(a),bind('forall','x',b(0),b(1)));
 const v=bind('lam','A',sort(c),bind('lam','x',b(0),b(0)));
 return JSON.stringify(sorted({format:'proofscript-checked-admissions',version:2,admissions:[{kind:'constant',declaration:{k:'definition',n:nam('LevelConversionProbe'),lp:[...params.values()],t,v,h:{k:'regular',h:'1'},s:'safe'}}]}));}
const fixtures=JSON.parse(fs.readFileSync(path.join(root,'test/universe-cases.json'),'utf8'));
const cases=[];
for(const c of fixtures){cases.push({label:'normalization/'+c.label,a:c.input,b:c.expected});cases.push({label:'strict-successor/'+c.label,a:c.input,b:S(c.input)});}
const r=randomGenerator(4991);
for(let i=0;i<50;i++){const a=randomLevel(r,3),b=randomLevel(r,3);cases.push({label:'max-swap/'+i,a:M(a,b),b:M(b,a)});cases.push({label:'random/'+i,a,b});}
for(let i=0;i<100;i++){
 const a=randomLevel(r,4),b=randomLevel(r,3),c=randomLevel(r,3);
 cases.push({label:'max-association/'+i,a:M(M(a,b),c),b:M(a,M(b,c))});
 cases.push({label:'max-zero-context/'+i,a,b:M(Z,a)});
 cases.push({label:'max-duplicate-context/'+i,a,b:M(a,a)});
 cases.push({label:'successor-distribution/'+i,a:S(M(a,b)),b:M(S(a),S(b))});
 cases.push({label:'normalizer-output/'+i,a,b:decodeLevel(normalize(a,50000).result.value)});
}
// Explicit native-incomplete raw imax cases, not silently repaired to a stronger algebra.
cases.push({label:'raw-imax-successor-distribution',a:S(I(P('v'),S(P('u')))),b:M(S(P('v')),S(S(P('u'))))});
const records=[];
for(const c of cases){
 const req=request(c.a,c.b),predicted=levelCheck(c.a,c.b,50000);
 let result;
 try{result=call(['--check'],req);}catch(error){
  console.error(JSON.stringify({failedCase:c.label,requestSha256:hash(req),completed:records.length,error:String(error)}));
  throw error;
 }
 if(result.accepted!==true&&(result.accepted!==false||result.errorKind!=='kernel-rejection'||result.declarationIndex!==0))throw Error('INVALID_PROBE '+c.label+' '+JSON.stringify(result));
 records.push({...c,predicted,native:result.accepted?'equal':'different',requestSha256:hash(req),...(result.accepted?{}:{errorKind:result.errorKind,message:result.message})});
 if(records.length%50===0)console.log('PSKERNEL_LEVEL_DIFFERENTIAL_PROGRESS: '+records.length+'/'+cases.length);
}
const mismatches=records.filter(x=>x.predicted!==x.native);
const report={schemaVersion:1,scope:'Bounded direct kernel conversion probes on the recorded provider prelude; not full Lean compatibility',provider:identity,sourceManifestSha256:hash(fs.readFileSync(path.join(root,'manifests/SOURCE.json'))),harnessSha256:hash(fs.readFileSync(fileURLToPath(import.meta.url))),cases:records.length,matched:records.length-mismatches.length,mismatches,records};
const recordsPath='dist/evidence/level-differential-records.json',recordsText=JSON.stringify(records,null,2)+'\n';
fs.mkdirSync(path.join(root,'dist/evidence'),{recursive:true});fs.writeFileSync(path.join(root,recordsPath),recordsText);
fs.writeFileSync(path.join(root,'manifests/LEVEL_DIFFERENTIAL.json'),JSON.stringify({...report,records:undefined,recordsPath,recordsSha256:hash(recordsText)},null,2)+'\n');console.log(JSON.stringify({cases:report.cases,matched:report.matched,mismatches},null,2));if(mismatches.length)process.exitCode=1;
