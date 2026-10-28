// Qualification supervision only. Canonical compiler and official kernel own semantics.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {compilerRequestLimit} from '../../scripts/selfhost-qualification-profiles.mjs';
import {createCompilerHostSession} from '../compiler-host-protocol.mjs';
import {packageGraph} from './package.mjs';
import {verify} from './verify.mjs';
import {sha256,json,put,files,run} from './tools.mjs';
export const nodeFlags=['--max-old-space-size=4096','--stack-size=8192'];
export function supervised({label,command,directory,profile='performance-240s',request='G1',native=false}){
 const policy=compilerRequestLimit(profile,request),seconds=policy.timeoutMs/1000;
 const result=spawnSync('python3',[path.resolve('host-tools/process/bounded-process.py'),JSON.stringify({
  command:['/usr/bin/prlimit',...(native?['--as=4294967296']:[]),'--stack=8388608','--cpu='+seconds,'--',...command],
  directory:path.join(directory,'execution',label),...policy,maxBuffer:33554432
 })],{encoding:'utf8',timeout:policy.timeoutMs+5000,maxBuffer:33554432});
 assert.equal(result.error,undefined,result.error?.message);
 assert.equal(result.status,0,result.stderr);
 const report=JSON.parse(result.stdout);
 console.log('PSC1_MODULAR_EXECUTION '+label+' '+JSON.stringify(report));
 const stderr=fs.readFileSync(path.join(directory,'execution',label,'tool.stderr.txt'),'utf8');
 const stdout=fs.readFileSync(path.join(directory,'execution',label,'tool.stdout.txt'),'utf8');
 assert.ok(!report.error&&report.status===0,stderr+'\n'+stdout);
 return {report,stdout};
}
export function admitAndPackage(stage,sourceRows,sources,reference,{label,compilerCommit}){
 const read=file=>fs.readFileSync(path.join(stage,file),'utf8');
 const capture=JSON.parse(read('capture.json')),emission=JSON.parse(read('modules.json'));
 assert.equal(capture.schema,'psc1-executable-capture/1');
 assert.equal(capture.sourceClosureDigest,reference.sourceClosureDigest);
 assert.equal(capture.assurance,'ordinary-checked');
 assert.equal(capture.leanVersion,'4.35.0');
 assert.equal(capture.leanCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
 assert.deepEqual(capture.sourceModules,sources.map(x=>x.module));
 // Every generation must reproduce the same source-derived IR and exact admission.
 for(const file of ['admissions.json','original-ir.json','specialized-ir.json','fused-ir.json'])
  assert.equal(sha256(read(file)),reference.identities[file],'PSC1_MODULAR_GENERATION_IDENTITY:'+file);
 const nativeCapture=reference.capture;
 for(const key of ['sourceModules','owners','logicalDeclarations','counts','partialNames',
   'specializationOriginCount','workerOriginCount'])
  assert.deepEqual(capture[key],nativeCapture[key],'PSC1_MODULAR_CAPTURE:'+key);
 assert.deepEqual(emission,reference.emission,'PSC1_MODULAR_PLAN_AND_EXPORTS');
 for(const row of reference.emittedFiles)
  assert.equal(sha256(fs.readFileSync(path.join(stage,row.path))),row.sha256,'PSC1_MODULAR_RENDERED_BYTES:'+row.path);
 const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
 const pin=sha256(fs.readFileSync(checker));
 const session=createCompilerHostSession({requestId:capture.requestId,target:'js',sources,
  canonicalAdmissions:read('admissions.json'),checkerExecutable:checker});
 const start=performance.now();
 const receipt=session.admit(JSON.stringify({protocol:'psc1-compiler-host/1',op:'admit',
  requestId:capture.requestId,target:'js',sourceClosureDigest:capture.sourceClosureDigest,admissions:read('admissions.json')}));
 assert.equal(receipt.accepted,true);
 assert.equal(receipt.checkerCommit,capture.leanCommit);
 assert.equal(pin,sha256(fs.readFileSync(checker)));
 const admitted={...receipt,elapsedMs:Math.round(performance.now()-start)};
 put(path.join(stage,'independent-admission.json'),json(admitted));
 const graph=packageGraph(emission,sourceRows,receipt,capture,{
  output:stage,version:'0.1.0-psc1-modular.2',labelPrefix:label+'/',compilerCommit});
 verify(graph.root,graph.manifestBytes,graph.manifestHash);
 return {...graph,admitted};
}
export function packGraph(graph,directory){
 fs.mkdirSync(directory);
 return graph.manifest.packages.map(pkg=>{
  const packed=JSON.parse(run('npm',['pack',path.join(graph.root,'node_modules',pkg.name),
   '--ignore-scripts','--json','--pack-destination',directory]));
  assert.equal(packed.length,1);
  const file=path.join(directory,packed[0].filename);
  return {name:pkg.name,filename:path.basename(file),bytes:fs.statSync(file).size,sha256:sha256(fs.readFileSync(file))};
 });
}
export function exactGraphs(left,right){
 assert.deepEqual(right.manifest,left.manifest,'PSC1_MODULAR_MANIFEST_FIXED_POINT');
 assert.deepEqual(files(right.root),files(left.root),'PSC1_MODULAR_COMPLETE_FILE_FIXED_POINT');
 assert.equal(right.manifestHash,left.manifestHash);
}


export function attachNativeTestReferences(stage,base,reference){
 // These are test oracles outside the executable graph, not generation outputs.
 for(const row of reference.nativeOracleFiles){
  const bytes=fs.readFileSync(path.join(base,row.path));
  assert.equal(bytes.length,row.bytes);assert.equal(sha256(bytes),row.sha256);
  put(path.join(stage,path.basename(row.path)),bytes);
 }
}
