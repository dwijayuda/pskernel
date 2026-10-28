// Full generated compiler: existing capture/transforms/printers, never another frontend.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createCompilerHostSession,compilerSourceClosureDigest} from '../../host-tools/compiler-host-protocol.mjs';
import {run,sha256} from '../../host-tools/modular/compiler.mjs';
const out=path.resolve('dist/modular-compiler');fs.mkdirSync(out,{recursive:true});
const sources=JSON.parse(fs.readFileSync('dist/modular/frozen-source/sources.json'));
const rows=JSON.parse(fs.readFileSync('dist/modular/frozen-source/rows.json'));
const digest=compilerSourceClosureDigest(sources),requestId='full-modular-compiler-source';
assert.equal(digest,'073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9');
const request=JSON.stringify(['psc1-compiler-service/1',requestId,digest,'lean','ordinary-checked',
 'Ps.CompilerUnified.Service',sources.map(s=>[s.module,s.text])]);
const input=path.join(out,'request.json');fs.writeFileSync(input,request);
const supervisor=path.resolve('host-tools/process/bounded-process.py');
const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
const measure=path.resolve('.lake/build/bin/psc1_modular_graph_measure');
const emitter=path.resolve('.lake/build/bin/psc1_modular_compiler_emit');
const tools=[supervisor,checker,measure,emitter,'/usr/bin/prlimit'].map(file=>({file,sha256:sha256(fs.readFileSync(file))}));
const verify=()=>{for(const p of tools)assert.equal(sha256(fs.readFileSync(p.file)),p.sha256);};
function bounded(label,exe,args){
 verify();const execution=JSON.parse(run('python3',[supervisor,JSON.stringify({
  command:['/usr/bin/prlimit','--as=4294967296','--stack=8388608','--cpu=240','--',exe,...args],
  directory:path.join(out,label),timeoutMs:240000,maxBuffer:33554432
 })],{timeout:245000}));
 process.stdout.write(fs.readFileSync(path.join(out,label,'tool.stdout.txt'),'utf8'));
 assert.equal(execution.error,null,JSON.stringify(execution));assert.equal(execution.status,0,fs.readFileSync(path.join(out,label,'tool.stderr.txt'),'utf8'));
 verify();return execution;
}
const captured=bounded('capture',measure,[input,out]);
const graph=JSON.parse(fs.readFileSync(path.join(out,'native-graph.json')));
assert.equal(graph.sourceClosureDigest,digest);assert.deepEqual(graph.sourceModules,sources.map(s=>s.module));
const admissions=fs.readFileSync(path.join(out,'admissions.json'),'utf8');
const receipt=createCompilerHostSession({requestId,target:'js',sources,canonicalAdmissions:admissions,checkerExecutable:checker})
 .admit(JSON.stringify({protocol:'psc1-compiler-host/1',op:'admit',requestId,target:'js',sourceClosureDigest:digest,admissions}));
const logicalPackages=['@proofscript/foundation',...rows.map(row=>{
 const match=row.path.replaceAll(path.sep,'/').match(/\/packages\/([^/]+)\/src\//);assert.ok(match);
 return match[1]==='compiler-unified'?'@proofscript/bootstrap':JSON.parse(fs.readFileSync(path.join('packages',match[1],'package.json'))).name;
})];
// Include implicit shared nominal/runtime imports before package-cycle analysis.
const packages=[...new Set(logicalPackages)],edges=new Map(packages.map(p=>[p,new Set(p==='@proofscript/foundation'?[]:['@proofscript/foundation'])]));
for(const declaration of graph.fused.declarations)for(const [,owner]of declaration.references)
 if(logicalPackages[declaration.owner]!==logicalPackages[owner])edges.get(logicalPackages[declaration.owner]).add(logicalPackages[owner]);
function reachable(n){const seen=new Set([n]),todo=[n];while(todo.length)for(const v of edges.get(todo.pop()))if(!seen.has(v)){seen.add(v);todo.push(v);}return seen;}
const reach=new Map(packages.map(n=>[n,reachable(n)])),seen=new Set(),groups=[];
for(const n of packages)if(!seen.has(n)){const group=packages.filter(m=>reach.get(n).has(m)&&reach.get(m).has(n));group.forEach(x=>seen.add(x));groups.push(group);}
const physical=new Map(groups.flatMap(group=>{const selected=group.includes('@proofscript/compiler')?'@proofscript/compiler':group[0];return group.map(n=>[n,selected]);}));
const modulePackages=logicalPackages.map(p=>physical.get(p));
const specifiers=modulePackages.map((p,i)=>p+'/generated/'+(i===0?'runtime':sources[i-1].module));
fs.writeFileSync(path.join(out,'specifiers.json'),JSON.stringify(specifiers));
console.log('PSC1_FULL_MODULE_PACKAGE_GROUPS '+JSON.stringify(groups));
const emitted=bounded('emit',emitter,[path.join(out,'fused-ir.json'),path.join(out,'native-graph.json'),path.join(out,'specifiers.json'),digest,out]);
rows.forEach(r=>assert.equal(fs.readFileSync(r.path,'utf8'),r.text));assert.equal(fs.readFileSync(input,'utf8'),request);
const modules=JSON.parse(fs.readFileSync(path.join(out,'modules.json')));
assert.equal(modules.sourceClosureDigest,digest);assert.ok(modules.units.length>100);
const report={schema:'psc1-modular-compiler-native/1',sourceClosureDigest:digest,sources:sources.length,
 sourceBytes:Buffer.byteLength(JSON.stringify(sources)),values:graph.fused.values,structures:graph.fused.structures,inductives:graph.fused.inductives,
 packageGroups:groups,logicalPackages,modulePackages,receipt,captured,emitted,tools,units:modules.units.length,
 sourceRootCommit:'4b0fa00ac1132d8f44e9db984d8fb7a3a02a1a98',
 scope:'full compiler generation from exact qualified source with independent Core admission; package execution not yet qualified'};
fs.writeFileSync(path.join(out,'native.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSC1_FULL_MODULAR_NATIVE '+JSON.stringify(report));
