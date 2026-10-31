// Installed native npm host. No compiler semantics or admission cache here.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {expectedManifestSha256} from './native-seal.mjs';
import {captureResourceSetup,resourceDigest} from './host-tools/resource-capture.mjs';
import {requireSupportedRuntime} from './host-tools/runtime-policy.mjs';
import {createGeneratedJsCompilerSession} from './host-tools/generated-compiler-session.mjs';
import {runGeneratedRustCompiler} from './host-tools/generated-rust-transport.mjs';
import {runGeneratedRustWindowsCompiler} from './host-tools/generated-rust-windows-transport.mjs';
import {captureProject,parseCompilation} from './npm-cli/cli-project.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const leanCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const fail=message=>{throw Error('PSC1_NATIVE_NPM_'+message);};
const help=`ProofScript native npm preview — generated Rust compiler + official native Lean kernel
Usage:
  psc check Main.ps
  psc compile Main.ps
  psc compile -p proofscript.json
  psc build Main.ps --out directory
  psc --identity
  psc --version
Windows x64 and Linux x64. Node >=22.23.3 is required for the checked host.
No Rust, Lean, build tools, downloads or install scripts are needed for JS output.
Input: .ps or the supported .lean subset. Output in this preview: JavaScript.
Compiler generation: G1. Native G2/G3 and semantic preservation are not claimed.
`;
function regular(relative,maximum=128*1024*1024){
  if(typeof relative!=='string'||!relative||!/^[-A-Za-z0-9_@.+/]+$/.test(relative)||
     relative.split('/').some(p=>!p||p==='.'||p==='..')||path.isAbsolute(relative))fail('PATH');
  const file=path.join(root,...relative.split('/'));
  for(let cursor=file;cursor!==root;cursor=path.dirname(cursor))
    if(fs.lstatSync(cursor).isSymbolicLink())fail('SYMLINK:'+relative);
  const stat=fs.lstatSync(file);
  if(!stat.isFile()||stat.size<1||stat.size>maximum)fail('RESOURCE_KIND:'+relative);
  return {file,stat};
}
function resources(){
  requireSupportedRuntime();
  const platform=process.platform+'-'+process.arch;
  if(!['linux-x64','win32-x64'].includes(platform))fail('PLATFORM:'+platform);
  const manifestFile=regular('NATIVE_MANIFEST.json',2*1024*1024).file;
  const bytes=fs.readFileSync(manifestFile);
  if(sha(bytes)!==expectedManifestSha256)fail('MANIFEST_IDENTITY');
  const manifest=JSON.parse(bytes),selected=manifest.platforms?.[platform];
  if(manifest.schema!=='psc1-native-npm-distribution/1'||manifest.leanCommit!==leanCommit||
     manifest.generation!=='G1'||manifest.outputTarget!=='js'||!selected||
     !Array.isArray(manifest.files)||!Array.isArray(selected.files))fail('POLICY');
  const pins=[],seen=new Set();let total=0;
  for(const row of [...manifest.files,...selected.files]){
    if(seen.has(row.path)||!Number.isSafeInteger(row.bytes)||row.bytes<1||!/^[a-f0-9]{64}$/.test(row.sha256))fail('PIN');
    seen.add(row.path);total+=row.bytes;
    if(total>256*1024*1024||seen.size>8192)fail('SIZE');
    const {file,stat}=regular(row.path);
    if(stat.size!==row.bytes||resourceDigest(file)!==row.sha256)fail('RESOURCE_IDENTITY:'+row.path);
    pins.push({path:file,sha256:row.sha256});
  }
  for(const required of ['package.json','dist/native-runtime.mjs',selected.compilerPath,selected.checkerPath,
      'dist/host-tools/execution/unified-candidate-runner.mjs',...(platform==='win32-x64'?[selected.guardPath]:[])])
    if(!seen.has(required))fail('MISSING_PIN:'+required);
  pins.push({path:manifestFile,sha256:expectedManifestSha256});
  const seal=regular('dist/native-seal.mjs').file;pins.push({path:seal,sha256:resourceDigest(seal)});
  return {manifest,selected,platform,pins,get:relative=>pins.find(pin=>pin.path===path.join(root,...relative.split('/')))};
}
export function getMetadata(){
  const r=captureResourceSetup(resources).value;
  return Object.freeze({schema:'psc1-native-npm-identity/1',verified:true,version:r.manifest.version,
    platform:r.platform,compiler:'generated-rust-native-G1',kernel:'official-Lean-4.35.0-native',
    compilerSourceClosureDigest:r.manifest.compilerSourceClosureDigest,leanCommit,
    nativeCompilerSha256:r.get(r.selected.compilerPath).sha256,nativeCheckerSha256:r.get(r.selected.checkerPath).sha256,
    publicationProtocol:r.platform==='win32-x64'?'portable-atomic':'portable-file',
    nodeHostRequired:true,outputTargets:['js'],nativeG2G3:'not-qualified'});
}
export function compile({sources,entryModule,assurance='checked',evidence='minimal',out,beforePublish}){
  const started=performance.now();
  if(!['checked','ordinary-checked'].includes(assurance)||!['minimal','full'].includes(evidence))fail('OPTIONS');
  if(out!==undefined&&(typeof out!=='string'||!out))fail('OUTPUT');
  if(beforePublish!==undefined&&typeof beforePublish!=='function')fail('PUBLICATION_GUARD');
  const scratch=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-native-checked-'));
  try{
    let resourcesForCall;
    const setup=captureResourceSetup(()=>{
      const r=resources();resourcesForCall=r;
      const binary=r.get(r.selected.compilerPath),checker=r.get(r.selected.checkerPath);
      const runner=r.get('dist/host-tools/execution/unified-candidate-runner.mjs');
      const guard=r.platform==='win32-x64'?r.get(r.selected.guardPath):null;
      const serviceExecute=request=>guard?runGeneratedRustWindowsCompiler({
        executable:binary.path,executableSha256:binary.sha256,guard:guard.path,guardSha256:guard.sha256,request,
      }):runGeneratedRustCompiler({executable:binary.path,executableSha256:binary.sha256,request});
      return createGeneratedJsCompilerSession({
        requestId:'native-npm-'+crypto.randomUUID(),sources,entryModule,assurance,evidence,
        outputAbi:'scalar',target:'js',operation:'compile',serviceKind:'unified-bundle',
        publicationProtocol:r.platform==='win32-x64'?'portable-atomic':'portable-file',
        serviceFile:binary.path,serviceSha256:binary.sha256,serviceExecute,
        runnerFile:runner.path,runnerSha256:runner.sha256,
        checkerExecutable:checker.path,checkerSha256:checker.sha256,
        serviceDependencies:r.pins,publicationRoot:out===undefined?path.join(scratch,'store'):path.resolve(out),
      });
    });
    const setupMs=performance.now()-started,session=setup.value,receipt=session.execute(),r=resourcesForCall;
    assert.equal(receipt.logicalAdmission,'accepted');
    const response={schema:'psc1-native-npm-result/1',status:'accepted',engine:'rust',kernel:'native',
      platform:r.platform,compilerGeneration:'G1',compilerSourceClosureDigest:r.manifest.compilerSourceClosureDigest,
      sourceClosureDigest:receipt.sourceClosureDigest,target:'js',nodeHostRequired:true,
      logicalAdmission:'accepted',formalPreservation:'not-provided',nativeG2G3:'not-qualified',
      nativeCompilerSha256:r.get(r.selected.compilerPath).sha256,nativeCheckerSha256:r.get(r.selected.checkerPath).sha256,
      timings:{...receipt.timings,setupMs,setupResourceBytes:setup.metrics.uniqueBytes,totalMs:performance.now()-started},receipt};
    if(out!==undefined){
      if(beforePublish)beforePublish();
      const publication=session.publish();
      return {...response,publication,timings:{...response.timings,totalMs:performance.now()-started}};
    }
    const source=fs.readFileSync(path.join(session.stagingDirectory,'target.mjs'),'utf8');
    assert.equal(sha(source),receipt.sourceSha256);
    return {...response,source,publication:'not-requested'};
  }finally{fs.rmSync(scratch,{recursive:true,force:true,maxRetries:10,retryDelay:50});}
}
export function main(args){
  try{
    const [command,...rest]=args;
    if(command===undefined||command==='-h'||command==='--help'){process.stdout.write(help);return 0;}
    if(command==='--identity'||command==='--version'){
      assert.equal(rest.length,0);const identity=getMetadata();
      process.stdout.write(command==='--version'?identity.version+'\n':JSON.stringify(identity)+'\n');return 0;
    }
    assert.ok(['check','compile','build'].includes(command),'unsupported command');
    const parsed=parseCompilation(rest);
    if(parsed.watch||parsed.showConfig)fail('UNSUPPORTED_OPTION');
    for(const key of parsed.options.keys())if(!['--project','--out','--assurance','--evidence'].includes(key))fail('UNSUPPORTED_OPTION:'+key);
    const captured=captureProject(parsed),out=parsed.options.get('--out');
    assert.equal(out!==undefined,command==='build','--out is required only for build');
    const snapshot=JSON.stringify(captured.project);
    const result=compile({...captured.project,assurance:parsed.options.get('--assurance')||captured.project.assurance||'checked',
      evidence:parsed.options.get('--evidence')||'minimal',out,
      beforePublish:()=>assert.equal(JSON.stringify(captureProject(parsed).project),snapshot,'source changed before publication')});
    if(command==='check')delete result.source;
    process.stdout.write(JSON.stringify(result)+'\n');return 0;
  }catch(error){console.error('PSC1_NATIVE_NPM_REFUSED: '+error.message);return 1;}
}
