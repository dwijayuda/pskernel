// Host target compilation/transport only. Compiler semantics are generated.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
export const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
export function runTool(executable,args,options={}) {
 const started=Date.now();
 const r=spawnSync(executable,args,{encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...options});
 const event={executable,args,status:r.status,signal:r.signal,elapsedMs:Date.now()-started,error:r.error?.message||null};
 if(options.logDirectory) {
  fs.writeFileSync(path.join(options.logDirectory,'tool.stdout.txt'),r.stdout||'');
  fs.writeFileSync(path.join(options.logDirectory,'tool.stderr.txt'),r.stderr||'');
 }
 if(r.error||r.status!==0) throw Error('PSC1_TARGET_TOOL_FAILED:'+JSON.stringify(event)+'\n'+(r.stderr||r.stdout||'').split('\n').slice(0,28).map(line=>line.slice(0,320)).join('\n'));
 return {stdout:r.stdout,event};
}
export function verifyArtifact(manifestFile,expectedHash) {
 assert.equal(sha(fs.readFileSync(manifestFile)),expectedHash,'PSC1_TARGET_MANIFEST_CHANGED');
 const m=JSON.parse(fs.readFileSync(manifestFile,'utf8'));
 assert.equal(m.schema,'psc1-generated-target-artifact/1');
 assert.ok(['ts','rust'].includes(m.target));
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
 const source=m.files.find(f=>f.path===(m.target==='ts'?'module.ts':'module.rs'));
 assert.ok(source);assert.equal(source.sha256,m.sourceSha256,'PSC1_TARGET_SOURCE_IDENTITY');
 assert.equal(m.executable,m.target==='ts'?'module.js':'service.bin');
 return {...m,directory};
}
export function buildTarget({target,source,directory,service=false,consumer='',publicNames=[]}) {
 assert.ok(['ts','rust'].includes(target));fs.mkdirSync(directory,{recursive:true});
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
 } else {
  const main=service ?
   'fn main() { let a: Vec<String> = std::env::args().collect(); assert_eq!(a.len(), 3); let input = std::fs::read_to_string(&a[1]).expect("request"); let output = psCompilerRustServiceCandidate(input); assert!(output.len() <= 134217728); std::fs::write(&a[2], output).expect("response"); }' :
   'fn main() { '+consumer+' }';
  fs.writeFileSync(path.join(directory,'module.rs'),source);
  fs.writeFileSync(path.join(directory,'main.rs'),source+'\n'+main+'\n');
  events.push(runTool('rustfmt',['--edition','2021',path.join(directory,'main.rs')],{logDirectory:directory}).event);
  fs.writeFileSync(path.join(directory,'Cargo.toml'),'[package]\nname="psc1-generated-target"\nversion="0.0.0"\nedition="2021"\npublish=false\n[[bin]]\nname="psc1-generated-target"\npath="main.rs"\n[dependencies]\nnum-bigint="=0.4.6"\nnum-traits="=0.2.19"\n');
  const locked=path.resolve('scripts/fixtures/selfhost-rust.Cargo.lock');
  // The first diagnostic records the exact resolver output. Once checked in,
  // every subsequent build uses that repository lock without re-resolution.
  if(fs.existsSync(locked)) fs.copyFileSync(locked,path.join(directory,'Cargo.lock'));
  else events.push(runTool('cargo',['generate-lockfile','--manifest-path',path.join(directory,'Cargo.toml')],{logDirectory:directory}).event);
  events.push(runTool('cargo',['build','--release','--locked','--manifest-path',path.join(directory,'Cargo.toml')],
   {env:{...process.env,CARGO_TARGET_DIR:path.resolve('dist/selfhost-rust-cargo')},logDirectory:directory}).event);
  executable='service.bin';
  fs.copyFileSync(path.resolve('dist/selfhost-rust-cargo/release/psc1-generated-target'),path.join(directory,executable));
  fs.chmodSync(path.join(directory,executable),0o700);
 }
 const excluded=new Set(['tool.stdout.txt','tool.stderr.txt','artifact.json']);
 const files=fs.readdirSync(directory).filter(n=>!excluded.has(n)&&fs.lstatSync(path.join(directory,n)).isFile()).sort().map(p=>{
  const b=fs.readFileSync(path.join(directory,p));return{path:p,bytes:b.length,sha256:sha(b)};
 });
 const manifest={schema:'psc1-generated-target-artifact/1',target,sourceSha256:sha(source),
  executable,service,publicNames,files,events,nodeVersion:process.version,
  compilerVersion:target==='rust'?runTool('rustc',['--version']).stdout.trim():
   runTool(process.execPath,[path.resolve('..','node_modules/typescript/bin/tsc'),'--version']).stdout.trim()};
 fs.writeFileSync(path.join(directory,'artifact.json'),JSON.stringify(manifest,null,2)+'\n');
 return {file:path.join(directory,'artifact.json'),sha256:sha(fs.readFileSync(path.join(directory,'artifact.json'))),manifest};
}
export function observeArtifact(artifact) {
 const m=verifyArtifact(artifact.file,artifact.sha256);
 const executable=m.target==='ts'?process.execPath:path.join(m.directory,m.executable);
 const args=m.target==='ts'?[path.join(m.directory,'consumer.mjs')]:[];
 const r=runTool(executable,args,{logDirectory:m.directory});
 return {observation:JSON.parse(r.stdout.trim()),event:r.event};
}
export async function executeService(manifestFile,expectedHash,requestFile,outputFile) {
 const m=verifyArtifact(manifestFile,expectedHash);assert.equal(m.service,true);
 const input=fs.readFileSync(requestFile);assert.ok(input.length<=128*1024*1024);
 const started=Date.now();let maxRssKiB;
 if(m.target==='ts') {
  const api=await import(pathToFileURL(path.join(m.directory,m.executable)).href);
  assert.deepEqual(Object.keys(api),['psCompilerTsServiceCandidate']);
  const response=api.psCompilerTsServiceCandidate(input.toString('utf8'));
  assert.equal(typeof response,'string');assert.ok(Buffer.byteLength(response)<=128*1024*1024);
  fs.writeFileSync(outputFile+'.tmp',response,{flag:'wx'});
  maxRssKiB=process.resourceUsage().maxRSS;
 } else {
  const rss=outputFile+'.rss.txt';
  runTool('/usr/bin/time',['-f','%M','-o',rss,path.join(m.directory,m.executable),requestFile,outputFile+'.tmp'],{logDirectory:path.dirname(outputFile)});
  maxRssKiB=Number(fs.readFileSync(rss,'utf8').trim());
 }
 const response=fs.readFileSync(outputFile+'.tmp');assert.ok(response.length>0&&response.length<=128*1024*1024);
 verifyArtifact(manifestFile,expectedHash);assert.equal(sha(fs.readFileSync(requestFile)),sha(input));
 fs.renameSync(outputFile+'.tmp',outputFile);
 return {protocol:'psc1-generated-target-run/1',target:m.target,serviceSha256:expectedHash,
  sourceSha256:m.sourceSha256,requestSha256:sha(input),responseSha256:sha(response),
  elapsedMs:Date.now()-started,maxRssKiB};
}
