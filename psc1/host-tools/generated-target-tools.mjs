// Host target compilation/transport only. Compiler semantics are generated.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {compilerRequestLimit,supervisorLimit,PERFORMANCE_PROFILE} from '../scripts/selfhost-qualification-profiles.mjs';
import {generatedTarget} from './generated-target-profiles.mjs';
import {decodeWasmHex} from './generated-wasm-transport.mjs';
export const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
export function boundedRun(executable,args,options={}) {
 const temporary=!options.logDirectory;
 const directory=options.logDirectory||fs.mkdtempSync(path.join(os.tmpdir(),'psc1-target-process-'));
 fs.mkdirSync(directory,{recursive:true});
 const started=Date.now();
 fs.appendFileSync(path.join(directory,'tool-events.jsonl'),JSON.stringify({
  state:'started',executable,args,at:new Date(started).toISOString()})+'\n');
 const limits=supervisorLimit(options.timeoutMs,options.timeoutPolicy);
 const control=spawnSync('python3',[path.resolve('scripts/bounded-process.py'),JSON.stringify({
  command:[executable,...args],directory,...limits,maxBuffer:32*1024*1024})],
  {encoding:'utf8',timeout:limits.supervisorGuardMs,killSignal:'SIGKILL',maxBuffer:1024*1024,
   cwd:options.cwd,env:options.env||process.env});
 if(control.error||control.status!==0)throw Error('PSC1_SUPERVISOR_FAILED:'+(control.error?.message||control.stderr));
 const result=JSON.parse(control.stdout);
 result.stdout=fs.readFileSync(path.join(directory,'tool.stdout.txt'),'utf8');
 result.stderr=fs.readFileSync(path.join(directory,'tool.stderr.txt'),'utf8');
 fs.appendFileSync(path.join(directory,'tool-events.jsonl'),JSON.stringify({state:'finished',
  executable,args,status:result.status,signal:result.signal,error:result.error,
  elapsedMs:result.elapsedMs,maxRssKiB:result.maxRssKiB,peakTreeRssKiB:result.peakTreeRssKiB,timeoutMs:result.timeoutMs,timeoutPolicy:result.timeoutPolicy,stdoutBytes:result.stdoutBytes,stderrBytes:result.stderrBytes})+'\n');
 if(temporary)fs.rmSync(directory,{recursive:true,force:true});
 return result;
}
export function runTool(executable,args,options={}) {
 const r=boundedRun(executable,args,options);
 const event={executable,args,status:r.status,signal:r.signal,elapsedMs:r.elapsedMs,maxRssKiB:r.maxRssKiB,peakTreeRssKiB:r.peakTreeRssKiB,error:r.error?.message||null};
 if(r.error||r.status!==0)throw Error('PSC1_TARGET_TOOL_FAILED:'+JSON.stringify(event)+'\n'+
  (r.stderr||r.stdout||'').split('\n').slice(0,28).map(line=>line.slice(0,320)).join('\n'));
 return {stdout:r.stdout,event};
}
export function verifyArtifact(manifestFile,expectedHash) {
 assert.equal(sha(fs.readFileSync(manifestFile)),expectedHash,'PSC1_TARGET_MANIFEST_CHANGED');
 const m=JSON.parse(fs.readFileSync(manifestFile,'utf8'));
 assert.equal(m.schema,'psc1-generated-target-artifact/1');
 const definition=generatedTarget(m.target);
 const directory=path.dirname(manifestFile);
 assert.ok(m.files.length>0&&new Set(m.files.map(f=>f.path)).size===m.files.length);
 for(const f of m.files) {
  assert.match(f.path,/^[a-zA-Z0-9_.-]+$/);
  const file=path.join(directory,f.path),stat=fs.lstatSync(file);
  assert.ok(stat.isFile()&&!stat.isSymbolicLink());
  assert.equal(stat.size,f.bytes);assert.equal(sha(fs.readFileSync(file)),f.sha256,'PSC1_TARGET_FILE_CHANGED');
 }
 assert.ok(m.files.some(f=>f.path===m.executable));
 assert.equal(typeof m.service,'boolean');
 assert.ok(Array.isArray(m.publicNames)&&new Set(m.publicNames).size===m.publicNames.length);
 const source=m.files.find(f=>f.path===definition.sourceFile);
 assert.ok(source);assert.equal(source.sha256,m.sourceSha256,'PSC1_TARGET_SOURCE_IDENTITY');
 assert.equal(m.executable,definition.executable);
 if(m.target==='wasm-core'){
  assert.equal(m.transport,'psc1-wasm-selfhost-gc/1');assert.ok(Array.isArray(m.publicTypes));
  assert.deepEqual(decodeWasmHex(fs.readFileSync(path.join(directory,definition.sourceFile),'utf8')),fs.readFileSync(path.join(directory,m.executable)));
 }
 return {...m,directory};
}
export function buildTarget({target,source,directory,service=false,consumer='',publicNames=[],publicTypes=[]}) {
 const definition=generatedTarget(target);fs.mkdirSync(directory,{recursive:true});
 const events=[];
 let executable;
 if(target==='ts') {
  fs.writeFileSync(path.join(directory,'module.ts'),source);
  fs.writeFileSync(path.join(directory,'package.json'),JSON.stringify({type:'module',private:true}));
  const config={compilerOptions:{target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',
   strict:true,noEmitOnError:true,declaration:true,sourceMap:true,skipLibCheck:false,types:[],lib:['ES2022','DOM']},files:['module.ts']};
  fs.writeFileSync(path.join(directory,'tsconfig.json'),JSON.stringify(config));
  const compiler=path.resolve('..','node_modules/typescript/bin/tsc');
  events.push(runTool(process.execPath,[compiler,'--project',path.join(directory,'tsconfig.json')],{logDirectory:directory}).event);
  executable='module.js';
  const api=runTool(process.execPath,['--input-type=module','-e',
   "import{pathToFileURL}from'node:url';const m=await import(pathToFileURL(process.argv[1]).href);if(JSON.stringify(Object.keys(m).sort())!==process.argv[2])throw Error('PSC1_TARGET_API_MISMATCH');",
   path.join(directory,executable),JSON.stringify([...publicNames].sort())],{logDirectory:directory});
  events.push(api.event);
  if(!service) {
   fs.writeFileSync(path.join(directory,'consumer.mjs'),"import * as m from './module.js';\n"+consumer);
  }
 } else if(target==='js') {
  fs.writeFileSync(path.join(directory,'module.js'),source);
  fs.writeFileSync(path.join(directory,'package.json'),JSON.stringify({type:'module',private:true}));
  events.push(runTool(process.execPath,['--check',path.join(directory,'module.js')],{logDirectory:directory}).event);
  executable='module.js';
  events.push(runTool(process.execPath,['--input-type=module','-e',
   "import{pathToFileURL}from'node:url';const m=await import(pathToFileURL(process.argv[1]).href);if(JSON.stringify(Object.keys(m).sort())!==process.argv[2])throw Error('PSC1_TARGET_API_MISMATCH');",
   path.join(directory,executable),JSON.stringify([...publicNames].sort())],{logDirectory:directory}).event);
  if(!service)fs.writeFileSync(path.join(directory,'consumer.mjs'),"import * as m from './module.js';\n"+consumer);
 } else if(target==='wasm-core') {
  fs.writeFileSync(path.join(directory,'module.wasm.hex'),source);
  fs.writeFileSync(path.join(directory,'module.wasm'),decodeWasmHex(source));
  const transport=pathToFileURL(path.resolve('host-tools/generated-wasm-transport.mjs')).href;
  const probe="import{loadWasmApi}from "+JSON.stringify(transport)+";import fs from 'node:fs';loadWasmApi(fs.readFileSync(new URL('./module.wasm',import.meta.url)),"+JSON.stringify(publicTypes)+","+JSON.stringify(publicNames)+");\n";
  fs.writeFileSync(path.join(directory,'probe.mjs'),probe);
  events.push(runTool('wasm-tools',['validate',path.join(directory,'module.wasm')],{logDirectory:directory}).event);
  events.push(runTool(process.execPath,[path.join(directory,'probe.mjs')],{logDirectory:directory}).event);
  executable='module.wasm';
  if(!service)fs.writeFileSync(path.join(directory,'consumer.mjs'),
   "import{loadWasmArtifact}from "+JSON.stringify(transport)+";import{fileURLToPath}from'node:url';const m=loadWasmArtifact(fileURLToPath(new URL('./artifact.json',import.meta.url)));\n"+consumer);
 } else if(target==='python'||target==='php') {
  const python=target==='python',sourceFile=definition.sourceFile;
  fs.writeFileSync(path.join(directory,sourceFile),source);
  const adapter=python?'generated-python-transport.py':'generated-php-transport.php';
  fs.copyFileSync(path.resolve('host-tools',adapter),path.join(directory,adapter));
  executable=sourceFile;
  const command=python?'python3':'php';
  const flags=python?['-I']:['-d','memory_limit=1G'];
  if(python){
   events.push(runTool(command,['-I','-c',"import ast,pathlib,sys;ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))",path.join(directory,sourceFile)],{logDirectory:directory}).event);
  }else events.push(runTool(command,[...flags,'-l',path.join(directory,sourceFile)],{logDirectory:directory}).event);
  events.push(runTool(command,[...flags,path.join(directory,adapter),path.join(directory,sourceFile),'probe',JSON.stringify(publicNames)],{logDirectory:directory}).event);
  if(!service)fs.writeFileSync(path.join(directory,python?'consumer.py':'consumer.php'),python?
   "import importlib.util,json,pathlib\nspec=importlib.util.spec_from_file_location('psc1_observed',pathlib.Path(__file__).with_name('module.py'))\nm=importlib.util.module_from_spec(spec)\nspec.loader.exec_module(m)\n"+consumer:
   "<?php\ndeclare(strict_types=1);\n$m=require __DIR__.'/module.php';\n"+consumer);
 } else {
  const main=service ?
   'fn main() { let a: Vec<String> = std::env::args().collect(); assert_eq!(a.len(), 3); let input = std::fs::read_to_string(&a[1]).expect("request"); let output = psCompilerRustServiceCandidate(input); assert!(output.len() <= 134217728); std::fs::write(&a[2], output).expect("response"); }' :
   'fn main() { '+consumer+' }';
  fs.writeFileSync(path.join(directory,'module.rs'),source);
  fs.writeFileSync(path.join(directory,'main.rs'),source+'\n'+main+'\n');
  fs.writeFileSync(path.join(directory,'Cargo.toml'),'[package]\nname="psc1-generated-target"\nversion="0.0.0"\nedition="2021"\npublish=false\n[[bin]]\nname="psc1-generated-target"\npath="main.rs"\n[dependencies]\nnum-bigint="=0.4.6"\nnum-traits="=0.2.19"\n[profile.release]\nopt-level=1\n');
  const locked=path.resolve('scripts/fixtures/selfhost-rust.Cargo.lock');
  // The first diagnostic records the exact resolver output. Once checked in,
  // every subsequent build uses that repository lock without re-resolution.
  if(fs.existsSync(locked)) fs.copyFileSync(locked,path.join(directory,'Cargo.lock'));
  else events.push(runTool('cargo',['generate-lockfile','--manifest-path',path.join(directory,'Cargo.toml')],{logDirectory:directory}).event);
  events.push(runTool('cargo',['build','--release','--locked','--message-format=short','--manifest-path',path.join(directory,'Cargo.toml')],
   {env:{...process.env,CARGO_TARGET_DIR:path.resolve('dist/selfhost-rust-cargo')},logDirectory:directory}).event);
  executable='service.bin';
  fs.copyFileSync(path.resolve('dist/selfhost-rust-cargo/release/psc1-generated-target'),path.join(directory,executable));
  fs.chmodSync(path.join(directory,executable),0o700);
 }
 const excluded=new Set(['tool.stdout.txt','tool.stderr.txt','tool-events.jsonl','artifact.json']);
 const files=fs.readdirSync(directory).filter(n=>!excluded.has(n)&&fs.lstatSync(path.join(directory,n)).isFile()).sort().map(p=>{
  const b=fs.readFileSync(path.join(directory,p));return{path:p,bytes:b.length,sha256:sha(b)};
 });
 const manifest={schema:'psc1-generated-target-artifact/1',target,sourceSha256:sha(source),
  executable,service,publicNames,files,events,nodeVersion:process.version,
  rustOptimizationLevel:target==='rust'?1:null,
  compilerVersion:target==='python'?runTool('python3',['--version']).stdout.trim():target==='php'?runTool('php',['-r','echo PHP_VERSION;']).stdout.trim():target==='js'?process.version:target==='wasm-core'?runTool('wasm-tools',['--version']).stdout.trim():target==='rust'?runTool('rustc',['--version']).stdout.trim():
   runTool(process.execPath,[path.resolve('..','node_modules/typescript/bin/tsc'),'--version']).stdout.trim()};
 if(target==='wasm-core'){manifest.transport='psc1-wasm-selfhost-gc/1';manifest.publicTypes=publicTypes;}
 fs.writeFileSync(path.join(directory,'artifact.json'),JSON.stringify(manifest,null,2)+'\n');
 return {file:path.join(directory,'artifact.json'),sha256:sha(fs.readFileSync(path.join(directory,'artifact.json'))),manifest};
}
export function observeArtifact(artifact) {
 const m=verifyArtifact(artifact.file,artifact.sha256);
 const executable=m.target==='python'?'python3':m.target==='php'?'php':m.target!=='rust'?process.execPath:path.join(m.directory,m.executable);
 const args=m.target==='python'?['-I',path.join(m.directory,'consumer.py')]:m.target==='php'?['-d','memory_limit=1G',path.join(m.directory,'consumer.php')]:m.target!=='rust'?[path.join(m.directory,'consumer.mjs')]:[];
 const r=runTool(executable,args,{logDirectory:m.directory});
 return {observation:JSON.parse(r.stdout.trim()),event:r.event};
}
export async function executeService(manifestFile,expectedHash,requestFile,outputFile,profile=PERFORMANCE_PROFILE) {
 const m=verifyArtifact(manifestFile,expectedHash);assert.equal(m.service,true);
 const input=fs.readFileSync(requestFile);assert.ok(input.length<=128*1024*1024);
 // Invalid wire must still reach the generated compiler's existing refusal path.
 let id;
 try {
  const wire=JSON.parse(input.toString('utf8'));
  if(Array.isArray(wire)&&wire[0]==='psc1-compiler-service/1')id=wire[1];
 } catch {}
 const limits=compilerRequestLimit(profile,id);
 const started=Date.now();let maxRssKiB;
 if(m.target==='ts'||m.target==='js'||m.target==='wasm-core') {
  const api=m.target==='wasm-core'?(await import('./generated-wasm-transport.mjs')).loadWasmArtifact(manifestFile):await import(pathToFileURL(path.join(m.directory,m.executable)).href);
  const exported=generatedTarget(m.target).exportName;
  assert.deepEqual(Object.keys(api),[exported]);
  const response=api[exported](input.toString('utf8'));
  assert.equal(typeof response,'string');assert.ok(Buffer.byteLength(response)<=128*1024*1024);
  fs.writeFileSync(outputFile+'.tmp',response,{flag:'wx'});
  maxRssKiB=process.resourceUsage().maxRSS;
 } else {
  const rss=outputFile+'.rss.txt';
  const command=m.target==='python'?['python3','-I',path.join(m.directory,'generated-python-transport.py'),path.join(m.directory,m.executable),'execute',JSON.stringify(m.publicNames),requestFile,outputFile+'.tmp']:m.target==='php'?['php','-d','memory_limit=1G',path.join(m.directory,'generated-php-transport.php'),path.join(m.directory,m.executable),'execute',JSON.stringify(m.publicNames),requestFile,outputFile+'.tmp']:[path.join(m.directory,m.executable),requestFile,outputFile+'.tmp'];
  runTool('/usr/bin/time',['-f','%M','-o',rss,...command],{logDirectory:path.dirname(outputFile),...limits});
  maxRssKiB=Number(fs.readFileSync(rss,'utf8').trim());
 }
 const response=fs.readFileSync(outputFile+'.tmp');assert.ok(response.length>0&&response.length<=128*1024*1024);
 verifyArtifact(manifestFile,expectedHash);assert.equal(sha(fs.readFileSync(requestFile)),sha(input));
 fs.renameSync(outputFile+'.tmp',outputFile);
 return {protocol:'psc1-generated-target-run/1',target:m.target,serviceSha256:expectedHash,
  sourceSha256:m.sourceSha256,requestSha256:sha(input),responseSha256:sha(response),
  elapsedMs:Date.now()-started,maxRssKiB};
}
