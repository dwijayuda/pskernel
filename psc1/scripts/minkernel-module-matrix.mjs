// Actual compiler-module diagnostics. No result here grants kernel authority.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const dir='dist/pskernel-min/module-matrix';fs.mkdirSync(dir,{recursive:true});
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
function run(command,args,{input,timeout=240000}={}){
 const r=spawnSync(command,args,{input,timeout,encoding:'utf8',maxBuffer:32*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+'\n'+r.stderr);return r.stdout;
}
const sources=readOwnedCompilerSources('Ps.CompilerUnified.Service');
assert.equal(sources.length,124,'scope drift requires explicit denominator update');
const sourceMap=new Map(sources.map(r=>[r.module,{module:r.module,path:r.path,bytes:Buffer.byteLength(r.text),sha256:sha(r.text),
 imports:[...r.text.matchAll(/^import\s+(.+)$/gm)].flatMap(m=>m[1].trim().split(/\s+/))}]));
const qualification=JSON.parse(fs.readFileSync('dist/pskernel-min/closure/compiler-qualification.json'));
const closure=JSON.parse(fs.readFileSync('dist/pskernel-min/closure/report.json'));
assert.equal(qualification.records.length,sources.length);
for(const r of qualification.records){const s=sourceMap.get(r.module);assert.ok(s);assert.equal(r.inputPath,s.path);assert.equal(r.inputUtf8Bytes,s.bytes);assert.deepEqual(r.parsedImports,s.imports);}
const name=n=>{const parts=[];while(n&&n.k!=='a'){assert.ok(n.k==='s'||n.k==='n');parts.push(String(n.v));n=n.p;}assert.equal(n?.k,'a');return parts.reverse().join('.');};
// Scan only container boundaries of the already production-checked global packet.
// Keep exact record byte slices, parsing one record at a time under 256 MiB.
function splitPacket(bytes){
 const mark=bytes.indexOf(Buffer.from('"admissions"'));assert.ok(mark>=0);
 assert.match(bytes.subarray(0,mark).toString(),/^\s*\{\s*$/);
 let p=mark+'"admissions"'.length;
 const ws=()=>{while(p<bytes.length&&[9,10,13,32].includes(bytes[p]))p++;};
 ws();assert.equal(bytes[p++],58);ws();assert.equal(bytes[p++],91);const contentStart=p,records=[];
 while(true){ws();if(bytes[p]===93)break;assert.equal(bytes[p],123);const start=p;
  let depth=0,string=false,escape=false;
  for(;p<bytes.length;p++){const c=bytes[p];if(string){if(escape)escape=false;else if(c===92)escape=true;else if(c===34)string=false;continue;}
   if(c===34)string=true;else if(c===123||c===91)depth++;else if(c===125||c===93){depth--;if(depth===0){p++;break;}}}
  assert.equal(depth,0);assert.equal(string,false);records.push(bytes.subarray(start,p));ws();
  if(bytes[p]===44){p++;continue;}assert.equal(bytes[p],93);break;
 }
 const suffix=bytes.subarray(p),prefix=bytes.subarray(0,contentStart);
 const root=JSON.parse(Buffer.concat([prefix,suffix]));assert.equal(root.format,'proofscript-checked-admissions');assert.equal(root.version,2);assert.equal(root.admissions.length,0);
 return{records,prefix,suffix};
}
const rawGlobal=fs.readFileSync('dist/pskernel-min/closure/compiler-admissions.json');
const framed=splitPacket(rawGlobal),records=[],byName=new Map(),ownerByName=new Map();
for(const m of qualification.records)for(const o of m.origins)for(const member of o.members){
 const prior=ownerByName.get(member.name);assert.ok(!prior||prior===m.module,'ambiguous source member '+member.name);ownerByName.set(member.name,m.module);
}
for(let index=0;index<framed.records.length;index++){
 const raw=framed.records[index],entry=JSON.parse(raw),d=entry.declaration;
 const names=entry.kind==='constant'?[name(d.n)]:d.ts.flatMap(t=>[name(t.n),...t.cs.map(c=>name(c.n)),name(t.n)+'.rec']);
 const refs=new Set(),features={levelParameters:d.lp.length,groupParameters:entry.kind==='inductive'?d.np:null,strings:0,projections:0,quantifiedTypes:0},pending=[d];
 while(pending.length){const value=pending.pop();if(!value||typeof value!=='object')continue;
  if(value.k==='const'||value.k==='proj')refs.add(name(value.n));
  if(value.k==='str')features.strings++;if(value.k==='proj')features.projections++;if(value.k==='forall')features.quantifiedTypes++;
  for(const child of Object.values(value))if(child&&typeof child==='object'){if(Array.isArray(child))pending.push(...child);else pending.push(child);}
 }
 const owners=[...new Set(names.map(n=>ownerByName.get(n)).filter(Boolean))];
 const r={index,names,refs:[...refs],owners,features,kind:entry.kind,declarationKind:d.k||'inductive'};records.push(r);
 for(const n of names){assert.ok(!byName.has(n),'duplicate canonical member '+n);byName.set(n,index);}
}
const edges=new Map([...sourceMap].map(([m,s])=>[m,new Set(s.imports)]));
for(const r of records)for(const owner of r.owners)for(const ref of r.refs){const target=byName.get(ref);
 if(target!==undefined)for(const dependency of records[target].owners)if(dependency!==owner)edges.get(owner).add(dependency);
}
function sourceClosure(module){const set=new Set(),visit=m=>{if(set.has(m))return;assert.ok(sourceMap.has(m));set.add(m);for(const dep of edges.get(m))visit(dep);};visit(module);return set;}
function indicesFor(modules){
 const selected=new Set(records.filter(r=>r.owners.some(m=>modules.has(m))).map(r=>r.index)),pending=[...selected];
 while(pending.length){for(const ref of records[pending.pop()].refs){const index=byName.get(ref);if(index!==undefined&&!selected.has(index)){selected.add(index);pending.push(index);}}}
 return [...selected].sort((a,b)=>a-b);
}
function packet(indices){return Buffer.concat([framed.prefix,...indices.flatMap((index,i)=>i?[Buffer.from(','),framed.records[index]]:[framed.records[index]]),framed.suffix]);}
function canonical(raw){return raw.at(-1)===10?raw.subarray(0,-1):raw;}
let apiCalls=0;
function check(file){apiCalls++;
 const r=spawnSync(process.execPath,['--max-old-space-size=256','scripts/minkernel-module-matrix-worker.mjs',file],
 {encoding:'utf8',timeout:120000,maxBuffer:1024*1024});
 if(r.error||r.status!==0)return{accepted:false,code:'MATRIX_PROCESS_FAILURE',delegated:false,status:r.status,signal:r.signal,error:r.error?.message||null,stderr:(r.stderr||'').slice(-4000)};
 const result=JSON.parse(r.stdout);assert.equal(result.delegated,false);return result;
}
function writePacket(file,raw){const checked=canonical(raw);fs.writeFileSync(file,checked);return{transportBytes:raw.length,transportSha256:sha(raw),checkedBytes:checked.length,checkedSha256:sha(checked),removedTerminalLF:raw.at(-1)===10};}
// Rebuild the unchanged ten-module checker and use its unchanged standalone API.
fs.mkdirSync('dist/pskernel-min/usable',{recursive:true});
fs.writeFileSync(path.join(dir,'runtime-compile.log'),run('lake',['env','lean','--run','scripts/MinKernelSourceCompile.lean','regular-runtime']));
const runtime='dist/pskernel-min/usable/runtime',policy=JSON.parse(fs.readFileSync(runtime+'.source.json'));
assert.equal(policy.moduleCount,10);for(const k of ['sourceAccepted','targetAccepted','originalIrAccepted'])assert.equal(policy[k],true);assert.equal(policy.providerChecked,false);
const runtimeRaw=fs.readFileSync(runtime+'.admissions.json'),runtimeBytes=canonical(runtimeRaw);
const officialRuntime=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],{input:runtimeBytes}));
assert.equal(officialRuntime.accepted,true);assert.equal(officialRuntime.leanVersion,'4.35.0');assert.equal(officialRuntime.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([runtime+'.ts','--target','ES2022','--module','ES2022','--moduleResolution','bundler','--strict','--skipLibCheck','--noEmitOnError','--pretty','false'])]);
for(const sub of ['sdk','sdk/runtime','sdk/host','packets','standalone','witnesses'])fs.mkdirSync(path.join(dir,sub),{recursive:true});
fs.copyFileSync(runtime+'.js',path.join(dir,'sdk/runtime/kernel.js'));fs.copyFileSync('packages/pskernel-min/host/ingress.mjs',path.join(dir,'sdk/host/ingress.mjs'));
fs.copyFileSync('packages/pskernel-min/standalone/index.mjs',path.join(dir,'sdk/index.mjs'));
fs.writeFileSync(path.join(dir,'sdk/package.json'),'{"type":"module"}\n');
fs.writeFileSync(path.join(dir,'sdk/metadata.mjs'),'export default Object.freeze('+JSON.stringify({sourceCommit:process.env.GITHUB_SHA,fullCompilerSupported:false,productionDefault:false,diagnosticHarness:true})+');\n');
const runtimeFile=path.join(dir,'runtime.canonical.json');fs.writeFileSync(runtimeFile,runtimeBytes);
const runtimeCheck=check(runtimeFile);assert.equal(runtimeCheck.accepted,true,'actual complete checker positive control');
const rows=[];
for(const module of sourceMap.keys()){
 const modules=sourceClosure(module),indices=indicesFor(modules),file=path.join(dir,'packets',module+'.json');
 const identity=writePacket(file,packet(indices)),min=check(file);
 const memberNames=qualification.records.filter(r=>modules.has(r.module)).flatMap(r=>r.origins.flatMap(o=>o.members.map(m=>m.name)));
 const missingMembers=memberNames.filter(n=>!indices.some(i=>records[i].names.includes(n)));
 const extraOwners=[...new Set(indices.flatMap(i=>records[i].owners))].filter(m=>!modules.has(m));
 const partial=qualification.partialNames.filter(n=>qualification.records.some(r=>modules.has(r.module)&&r.origins.some(o=>o.members.some(m=>m.name===n))));
 const row={module,path:sourceMap.get(module).path,source:sourceMap.get(module),declaredImports:sourceMap.get(module).imports,
  coreDependencies:[...edges.get(module)].sort(),dependencyClosure:[...modules].sort(),recordIndices:indices,recordCount:indices.length,
  missingSourceMembers:missingMembers,extraSourceOwners:extraOwners,partialBodyObligations:partial,
  generatedSupport:indices.filter(i=>records[i].owners.length===0).flatMap(i=>records[i].names),
  packet:{file,...identity},projectedMin:min,standalone:null,admissionQualified:false,fullyCompilerQualified:false};
 if(identity.checkedBytes>2*1024*1024){fs.rmSync(file);row.packet.retained=false;row.packet.reconstruction='closure/compiler-admissions.json exact record slices at recordIndices';}else row.packet.retained=true;
 rows.push(row);fs.writeFileSync(path.join(dir,'matrix.partial.json'),JSON.stringify({head:process.env.GITHUB_SHA,rows},null,2)+'\n');
}
// Fresh actual producer captures are mandatory for every positive projection;
// also query every dependency-free module to expose producer/auxiliary differences.
for(const row of rows.filter(r=>r.projectedMin.accepted||r.declaredImports.length===0)){
 const scope=sources.filter(s=>row.dependencyClosure.includes(s.module)),stem=path.join(dir,'standalone',row.module);
 const args=['--qualify','--assurance','ordinary-checked','--grammar','lean','--out',stem+'.qualification.json',
  '--admissions',stem+'.transport.json','--modules',...scope.flatMap(s=>[s.module,s.path])];
 const result=spawnSync('.lake/build/bin/psc1_source_census_probe',args,{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
 fs.writeFileSync(stem+'.stdout.log',result.stdout||'');fs.writeFileSync(stem+'.stderr.log',result.stderr||'');
 if(result.error||result.status!==0){row.standalone={producer:'refused',status:result.status,error:result.error?.message||null};continue;}
 const q=JSON.parse(fs.readFileSync(stem+'.qualification.json'));assert.equal(q.records.length,scope.length);
 for(const r of q.records){const s=sourceMap.get(r.module);assert.equal(r.inputUtf8Bytes,s.bytes);assert.equal(r.inputPath,s.path);}
 const file=stem+'.canonical.json',identity=writePacket(file,fs.readFileSync(stem+'.transport.json')),min=check(file);
 const freshParts=splitPacket(fs.readFileSync(file));
 const freshNames=freshParts.records.flatMap(b=>{const r=JSON.parse(b),d=r.declaration;return r.kind==='constant'?[name(d.n)]:d.ts.flatMap(t=>[name(t.n),...t.cs.map(c=>name(c.n)),name(t.n)+'.rec']);});
 const freshSet=new Set(freshNames);assert.equal(freshNames.length,freshSet.size,'duplicate fresh members');
 const expectedNames=q.records.flatMap(r=>r.origins.flatMap(o=>o.members.map(m=>m.name)));
 const missingFreshMembers=expectedNames.filter(n=>!freshSet.has(n));
 const extraFreshOwners=[...new Set(freshNames.map(n=>ownerByName.get(n)).filter(Boolean))].filter(m=>!row.dependencyClosure.includes(m));
 let official=null;if(min.accepted){official=JSON.parse(run('.lake/build/bin/psc1_independent_checker',['--check'],{input:fs.readFileSync(file)}));assert.equal(official.accepted,true);assert.equal(official.leanVersion,'4.35.0');assert.equal(official.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');}
 row.standalone={producer:'accepted',sameCheckedBytesAsProjection:identity.checkedSha256===row.packet.checkedSha256,packet:{file,...identity},min,official,preparation:q.preparation,ir:q.ir,sourceCoreDeclarations:q.sourceCoreDeclarations,logicalCoreDeclarations:q.coreDeclarations,missingFreshMembers,extraFreshOwners,partialBodyObligations:q.partialNames};
 row.admissionQualified=min.accepted&&q.preparation==='accepted'&&q.ir==='accepted'&&row.missingSourceMembers.length===0&&row.extraSourceOwners.length===0&&row.partialBodyObligations.length===0&&q.partialNames.length===0&&missingFreshMembers.length===0&&extraFreshOwners.length===0&&official?.accepted===true;
 if(!min.accepted&&identity.checkedBytes<=2*1024*1024){
  // Actual prefix calls locate the first failing record. Never grant acceptance
  // from a syntactic feature or a previous/hash-cached result.
  const parts=splitPacket(fs.readFileSync(file));
  for(let count=1;count<=Math.min(parts.records.length,8);count++){
   const prefix=Buffer.concat([parts.prefix,...parts.records.slice(0,count).flatMap((b,i)=>i?[Buffer.from(','),b]:[b]),parts.suffix]);
   const witness=stem+'.prefix-'+count+'.json';fs.writeFileSync(witness,prefix);const answer=check(witness);
   if(!answer.accepted){const r=JSON.parse(parts.records[count-1]);row.firstRefusal={prefixRecords:count,packet:witness,sha256:sha(prefix),min:answer,
    recordKind:r.kind,declarationKind:r.declaration.k||'inductive',names:r.kind==='constant'?[name(r.declaration.n)]:r.declaration.ts.map(t=>name(t.n)),
    levelParameters:r.declaration.lp.map(name),groupParameters:r.declaration.np??null};break;}
  }
 }
}
for(const row of rows){assert.equal(sha(fs.readFileSync(row.path)),row.source.sha256,'source bytes changed');}
const result={schema:'psc1-min-module-qualification-matrix/1',head:process.env.GITHUB_SHA,platform:process.platform,
 root:'Ps.CompilerUnified.Service',totalModules:rows.length,
 counts:{actualPublicApiCalls:apiCalls,
 projectedClosuresAccepted:rows.filter(r=>r.projectedMin.accepted).length,
 independentlyProducedMinAdmittedClosures:rows.filter(r=>r.admissionQualified).length,
 fullyCompilerQualifiedModules:0,minG1:false,minG2:false,minG3:false},
 runtime:{sourcePolicy:policy,official:officialRuntime,publicApiPositive:runtimeCheck,jsSha256:sha(fs.readFileSync(runtime+'.js'))},
 global:{packetBytes:rawGlobal.length,packetSha256:sha(rawGlobal),sourceInventorySha256:closure.sourceInventorySha256,
  sourceCoreMembers:qualification.sourceCoreDeclarations,logicalMembers:qualification.coreDeclarations},
 definition:'Admission-qualified means fresh actual source-closure production, exact bytes accepted by the unchanged standalone MinKernel API and official replay, complete source-member coverage and no unresolved partial body. It does not mean compiler preservation, target/runtime qualification or self-hosting.',
 rows,recordInventory:records,
 boundary:'No kernel rule/profile/limit/default change. Projected packets are dependency diagnostics and never alone qualify a module. Source/byte ownership audit is not a new compiler-preservation theorem.'};
fs.writeFileSync(path.join(dir,'matrix.json'),JSON.stringify(result,null,2)+'\n');
const lines=['# Actual PSC1 compiler module qualification matrix','',
 'Commit: '+result.head,'','Min-admitted fresh source closures: '+result.counts.independentlyProducedMinAdmittedClosures+'/'+rows.length+'. Fully compiler-qualified: 0/'+rows.length+'. No min G1/G2/G3.','',
 result.definition,'','| Module | Dependencies | Records | Projected public Min | Fresh actual producer / public Min | Admission qualified |','| --- | ---: | ---: | --- | --- | --- |',
 ...rows.map(r=>'| '+r.module+' | '+(r.dependencyClosure.length-1)+' | '+r.recordCount+' | '+r.projectedMin.code+' | '+(r.standalone?.min?.code||r.standalone?.producer||'not selected')+' | '+r.admissionQualified+' |')];
fs.writeFileSync(path.join(dir,'MATRIX.md'),lines.join('\n')+'\n');
console.log('PSC1_ACTUAL_MODULE_MATRIX '+JSON.stringify(result.counts));
