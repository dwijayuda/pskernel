#!/usr/bin/env node
// Installed native preview host. Compiler semantics remain in the generated Rust
// executable; official Lean native admission and the existing checked host remain.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {expectedManifestSha256} from './native-psc-seal.mjs';
import {captureResourceSetup, resourceDigest} from '../host-tools/resource-capture.mjs';
import {createGeneratedJsCompilerSession} from '../host-tools/generated-compiler-session.mjs';
import {runGeneratedRustCompiler} from '../host-tools/generated-rust-transport.mjs';
import {captureProject, parseCompilation} from '../npm-cli/cli-project.mjs';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const leanCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const fail=message=>{throw Error('PSC1_NATIVE_PACKAGE_'+message);};
const help=`PSC1 native Linux x64 preview — generated Rust compiler + official Lean native kernel
Usage:
  psc check Main.ps | -p project.json
  psc compile Main.ps | -p project.json
  psc build Main.ps --out directory
  psc --identity
Supported output: JS. Supported source: .ps and the PSC1 .lean subset.
Requires Node >=22.23.3 for the checked host; no Lean/Rust SDK or install-time build.
This G1 preview does not claim Rust G2/G3 or compiler semantic preservation.
`;

function regular(relative, limit=128*1024*1024){
  if(typeof relative!=='string'||!relative||relative.includes('\\')||
     relative.split('/').some(part=>!part||part==='.'||part==='..')||path.isAbsolute(relative))
    fail('PATH');
  const file=path.join(root,relative);
  for(let cursor=file;cursor!==root;cursor=path.dirname(cursor))
    if(fs.lstatSync(cursor).isSymbolicLink())fail('SYMLINK:'+relative);
  const stat=fs.lstatSync(file);
  if(!stat.isFile()||stat.size>limit||stat.size<1)fail('FILE_KIND:'+relative);
  return {file,stat};
}
function resources(){
  assert.equal(process.platform,'linux');assert.equal(process.arch,'x64');
  const manifestFile=regular('NATIVE_MANIFEST.json',2*1024*1024).file;
  const bytes=fs.readFileSync(manifestFile);
  if(sha(bytes)!==expectedManifestSha256)fail('MANIFEST_IDENTITY');
  const m=JSON.parse(bytes);
  if(m.schema!=='psc1-native-runtime-package/1'||m.leanCommit!==leanCommit||
     m.compilerGeneration!=='G1'||m.target!=='js'||m.platform!=='linux-x64'||
     m.compilerPath!=='compiler/psc-rust'||m.checkerPath!=='kernel/lean-checker'||
     !Array.isArray(m.files)||m.files.length<5||m.files.length>8192)
    fail('POLICY');
  const seen=new Set(),pins=[];
  let total=0;
  for(const row of m.files){
    if(seen.has(row.path)||!Number.isSafeInteger(row.bytes)||row.bytes<1||
       !/^[a-f0-9]{64}$/.test(row.sha256))fail('PIN');
    seen.add(row.path);total+=row.bytes;
    if(total>256*1024*1024)fail('PACKAGE_SIZE');
    const {file,stat}=regular(row.path);
    if(stat.size!==row.bytes||resourceDigest(file)!==row.sha256)fail('RESOURCE_IDENTITY:'+row.path);
    pins.push({path:file,sha256:row.sha256});
  }
  for(const required of [m.compilerPath,m.checkerPath,'scripts/native-psc-runtime.mjs',
    'host-tools/execution/unified-candidate-runner.mjs'])
    if(!seen.has(required))fail('MISSING_PIN:'+required);
  pins.push({path:manifestFile,sha256:expectedManifestSha256});
  const seal=regular('scripts/native-psc-seal.mjs').file;
  pins.push({path:seal,sha256:resourceDigest(seal)});
  return {manifest:m,pins,get:relative=>pins.find(pin=>pin.path===path.join(root,relative))};
}
export function nativeCompile({sources,entryModule,assurance='checked',evidence='minimal',out,beforePublish}){
  const started=performance.now();
  if(!['checked','ordinary-checked'].includes(assurance)||!['minimal','full'].includes(evidence))fail('OPTIONS');
  if(beforePublish!==undefined&&typeof beforePublish!=='function')fail('PUBLICATION_GUARD');
  if(out!==undefined&&(typeof out!=='string'||!out))fail('OUTPUT');
  const scratch=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-native-checked-'));
  try{
    let selected;
    const setup=captureResourceSetup(()=>{
      selected=resources();
      const binary=selected.get(selected.manifest.compilerPath);
      const checker=selected.get(selected.manifest.checkerPath);
      const runner=selected.get('host-tools/execution/unified-candidate-runner.mjs');
      return createGeneratedJsCompilerSession({
        requestId:'native-'+crypto.randomUUID(),sources,entryModule,assurance,
        outputAbi:'scalar',target:'js',publicationProtocol:'portable-file',evidence,
        operation:'compile',serviceKind:'unified-bundle',
        serviceFile:binary.path,serviceSha256:binary.sha256,
        serviceExecute:request=>runGeneratedRustCompiler({executable:binary.path,
          executableSha256:binary.sha256,request,timeoutMs:240000}),
        runnerFile:runner.path,runnerSha256:runner.sha256,
        checkerExecutable:checker.path,checkerSha256:checker.sha256,
        publicationRoot:out===undefined?path.join(scratch,'store'):path.resolve(out),
        serviceDependencies:selected.pins,
      });
    });
    const setupMs=performance.now()-started,session=setup.value;
    const receipt=session.execute();
    assert.equal(receipt.logicalAdmission,'accepted');
    const result={schema:'psc1-native-runtime-result/1',status:'accepted',
      compiler:'generated-rust-native-G1',kernel:'official-Lean-4.35.0-native',
      compilerSourceClosureDigest:selected.manifest.compilerSourceClosureDigest,
      nativeCompilerSha256:selected.get(selected.manifest.compilerPath).sha256,
      nativeCheckerSha256:selected.get(selected.manifest.checkerPath).sha256,
      sourceClosureDigest:receipt.sourceClosureDigest,target:'js',
      logicalAdmission:'accepted',irValidation:receipt.irValidation||'original-and-transformed-by-pinned-compiler',
      nodeHostOrchestration:true,fixedPoint:'not-qualified-for-native-G2-G3',
      timings:{...receipt.timings,setupMs,setupResourceReads:setup.metrics.uniqueReads,
        setupResourceBytes:setup.metrics.uniqueBytes,totalMs:performance.now()-started},receipt};
    if(out!==undefined){
      if(beforePublish)beforePublish();
      const publication=session.publish();
      return {...result,publication,timings:{...result.timings,totalMs:performance.now()-started}};
    }
    const source=fs.readFileSync(path.join(session.stagingDirectory,'target.mjs'),'utf8');
    assert.equal(sha(source),receipt.sourceSha256);
    return {...result,source,publication:'not-requested'};
  }finally{fs.rmSync(scratch,{recursive:true,force:true});}
}
export function main(args){
  try{
    const [command,...rest]=args;
    if(command==='--help'||command==='-h'||command===undefined){process.stdout.write(help);return 0;}
    if(command==='--identity'){
      assert.equal(rest.length,0);const selected=captureResourceSetup(resources).value;
      process.stdout.write(JSON.stringify({...selected.manifest,files:undefined,verified:true})+'\n');return 0;
    }
    assert.ok(['compile','check','build'].includes(command),'unsupported native command');
    const parsed=parseCompilation(rest);
    if(parsed.watch||parsed.showConfig)fail('UNSUPPORTED_OPTION');
    for(const key of parsed.options.keys())
      if(!['--project','--out','--assurance','--evidence'].includes(key))fail('UNSUPPORTED_OPTION:'+key);
    const captured=captureProject(parsed),out=parsed.options.get('--out');
    assert.equal(out!==undefined,command==='build','--out is required only for build');
    const snapshot=JSON.stringify(captured.project);
    const result=nativeCompile({...captured.project,
      assurance:parsed.options.get('--assurance')||captured.project.assurance||'checked',
      evidence:parsed.options.get('--evidence')||'minimal',out,
      beforePublish:()=>assert.equal(JSON.stringify(captureProject(parsed).project),snapshot,'source changed before publication')});
    if(command==='check')delete result.source;
    process.stdout.write(JSON.stringify(result)+'\n');return 0;
  }catch(error){console.error('PSC1_NATIVE_PACKAGE_REFUSED: '+error.message);return 1;}
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))
  process.exitCode=main(process.argv.slice(2));
