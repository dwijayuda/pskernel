// Exact production transforms, explicit owner edges, and genuine independent
// Core admission. SCC analysis here is diagnostic only; it cannot emit code.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {readOwnedCompilerSources} from '../../host-tools/compiler-source-inputs.mjs';
import {compilerSourceClosureDigest,createCompilerHostSession} from '../../host-tools/compiler-host-protocol.mjs';
import {run,sha256} from '../../host-tools/modular/compiler.mjs';
const entry='Ps.CompilerUnified.Service',root=path.resolve('dist/modular/transformed-graph');
fs.mkdirSync(root,{recursive:true});
const rows=readOwnedCompilerSources(entry);
const sources=rows.map(row=>({module:row.module,kind:'lean',text:row.text}));
const digest=compilerSourceClosureDigest(sources),requestId='transformed-unified-graph';
const request=JSON.stringify(['psc1-compiler-service/1',requestId,digest,'lean','ordinary-checked',entry,sources.map(s=>[s.module,s.text])]);
const input=path.join(root,'request.json'),producer=path.resolve('.lake/build/bin/psc1_modular_graph_measure');
const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
fs.writeFileSync(input,request,{flag:'wx'});
const resources=[producer,checker,path.resolve('host-tools/process/bounded-process.py'),'/usr/bin/prlimit'].map(file=>({file,sha256:sha256(fs.readFileSync(file))}));
const verify=()=>resources.forEach(pin=>assert.equal(sha256(fs.readFileSync(pin.file)),pin.sha256));
let execution;
try{
 execution=JSON.parse(run('python3',[resources[2].file,JSON.stringify({
  command:['/usr/bin/prlimit','--as=4294967296','--stack=8388608','--cpu=240','--',producer,input,root],
  directory:path.join(root,'execution'),timeoutMs:240000,maxBuffer:33554432
 })],{timeout:245000}));
 fs.writeFileSync(path.join(root,'execution.json'),JSON.stringify(execution,null,2));
 process.stdout.write(fs.readFileSync(path.join(root,'execution/tool.stdout.txt'),'utf8'));
 assert.equal(execution.status,0,fs.readFileSync(path.join(root,'execution/tool.stderr.txt'),'utf8'));
 const native=JSON.parse(fs.readFileSync(path.join(root,'native-graph.json'),'utf8'));
 assert.equal(native.sourceClosureDigest,digest);
 assert.deepEqual(native.sourceModules,sources.map(s=>s.module));
 assert.equal(native.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
 const admissions=fs.readFileSync(path.join(root,'admissions.json'),'utf8');
 const receipt=createCompilerHostSession({requestId,target:'js',sources,canonicalAdmissions:admissions,checkerExecutable:checker})
 .admit(JSON.stringify({protocol:'psc1-compiler-host/1',op:'admit',requestId,target:'js',sourceClosureDigest:digest,admissions}));
 const reports={};
 for(const stage of ['original','specialized','fused']){
  const graph=native[stage],nodes=Array.from({length:sources.length+1},(_,i)=>i),edges=nodes.map(()=>new Set());
  const names=new Map(graph.declarations.map(d=>[d.name,d.owner]));
  assert.equal(names.size,graph.values);
  for(const d of graph.declarations){
   assert.ok(nodes.includes(d.owner));
   for(const [name,owner]of d.references){assert.equal(names.get(name),owner);edges[d.owner].add(owner);}
  }
  // Transitive reachability gives exact SCCs on this bounded source-owner graph.
  const reachable=start=>{const seen=new Set([start]),todo=[start];while(todo.length){for(const n of edges[todo.pop()])if(!seen.has(n)){seen.add(n);todo.push(n);}}return seen;};
  const reach=nodes.map(reachable),assigned=new Set(),groups=[];
  for(const n of nodes)if(!assigned.has(n)){const members=nodes.filter(m=>reach[n].has(m)&&reach[m].has(n));members.forEach(m=>assigned.add(m));groups.push(members);}
  const counts=nodes.map(i=>graph.declarations.filter(d=>d.owner===i).length);
  reports[stage]={values:graph.values,structures:graph.structures,inductives:graph.inductives,
   ownerValueCounts:counts,typeOnlyOrErasedSources:nodes.slice(1).filter(n=>counts[n]===0).map(n=>sources[n-1].module),
   runtimeEdges:edges.map(e=>[...e].sort((a,b)=>a-b)),recursiveGroups:groups.filter(g=>g.length>1).map(g=>g.map(n=>n===0?'$runtime':sources[n-1].module)),
   maximumRecursiveGroup:Math.max(...groups.map(g=>g.length))};
 }
 const identities=Object.fromEntries(['original-ir.json','specialized-ir.json','fused-ir.json','admissions.json','native-graph.json'].map(file=>{
  const bytes=fs.readFileSync(path.join(root,file));assert.ok(bytes.length<=33554432);return[file,{bytes:bytes.length,sha256:sha256(bytes)}];}));
 verify();assert.equal(fs.readFileSync(input,'utf8'),request);
 rows.forEach(row=>assert.equal(fs.readFileSync(row.path,'utf8'),row.text));
 const report={schema:'psc1-transformed-compiler-graph-measurement/1',testedCommit:process.env.GITHUB_SHA,
  sourceClosureDigest:digest,sourceModules:sources.length,sourceBytes:Buffer.byteLength(JSON.stringify(sources)),entry,
  assurance:'ordinary-checked',receipt,execution,resources,identities,reports,
  specializationOrigins:native.specializationOrigins,workerOrigins:native.workerOrigins,
  scope:'production transformed graph measurement with Core admission; no modular compiler emission or self-hosting claim'};
 fs.writeFileSync(path.join(root,'measurement.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_TRANSFORMED_GRAPH '+JSON.stringify(report));
}catch(error){fs.writeFileSync(path.join(root,'failure.json'),JSON.stringify({error:String(error),execution,resources}));throw error;}
