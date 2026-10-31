// Linux Actions only. Reuse exact admitted G1 bytes, strip symbols without
// changing allocated ELF sections, and qualify a relocatable native runtime.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {readQualifiedArtifact,sha256 as sha} from './kernel435-qualified-artifact.mjs';
import {verifyArtifact} from '../host-tools/generated-target-tools.mjs';
import {fixtures as kernelFixtures} from './kernel435-fixtures.mjs';
import {corpus,expectedObservations,observedExpressions} from './generated-target-corpus.mjs';

assert.equal(process.env.GITHUB_ACTIONS,'true');
assert.equal(process.platform,'linux');assert.equal(process.arch,'x64');
const root=process.cwd(),input=JSON.parse(fs.readFileSync('scripts/native-psc-delivery-input.json','utf8'));
const directory=path.resolve('dist/native-delivery');
assert.ok(directory.startsWith(path.resolve('dist')+path.sep));
fs.rmSync(directory,{recursive:true,force:true});fs.mkdirSync(directory,{recursive:true});
const cleanEnv={...process.env};
for(const key of Object.keys(cleanEnv))if(key==='NODE_OPTIONS'||key.startsWith('LEAN_')||key.startsWith('ELAN_')||key.startsWith('LD_')||key.startsWith('DYLD_')||key==='PSC_LEAN_KERNEL_PROVIDER_BIN')delete cleanEnv[key];
const exec=(exe,args,options={})=>{
  const began=performance.now();
  const result=spawnSync(exe,args,{cwd:root,env:cleanEnv,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...options});
  const wallMs=performance.now()-began;
  assert.equal(result.error,undefined,String(result.error));
  assert.equal(result.status,0,(result.stderr||'')+'\n'+(result.stdout||'').slice(-4000));
  return {stdout:result.stdout,stderr:result.stderr,wallMs};
};
const save=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');
const g1Input=await readQualifiedArtifact(input.g1,path.join(directory,'input-g1'));
const original=path.join(g1Input,input.g1.directory),qualification=JSON.parse(fs.readFileSync(path.join(original,'qualification.json'),'utf8'));
assert.equal(qualification.status,'passed');assert.equal(qualification.correctnessQualification,'G1-only');
assert.equal(qualification.testedCommit,input.g1.commit);assert.equal(qualification.sourceClosureDigest,input.g1.sourceClosureDigest);
assert.equal(qualification.sourceModules,133);assert.equal(qualification.generations.length,1);
for(const row of qualification.sourceInventory){
  const bytes=fs.readFileSync(row.path);assert.equal(bytes.length,row.bytes);assert.equal(sha(bytes),row.sha256,'current compiler source differs from qualified G1');
}
const artifactFile=path.join(original,'G1-service/artifact.json');
assert.equal(sha(fs.readFileSync(artifactFile)),input.g1.manifestSha256);
const artifact=verifyArtifact(artifactFile,input.g1.manifestSha256);
const originalCompiler=path.join(original,'G1-service',artifact.executable);
assert.equal(sha(fs.readFileSync(originalCompiler)),input.g1.executableSha256);
const kernelInput=await readQualifiedArtifact(input.kernel,path.join(directory,'input-kernel'));
const kernelTar=path.join(kernelInput,input.kernel.tarball);
assert.equal(sha(fs.readFileSync(kernelTar)),input.kernel.tarballSha256);
const kernelUnpack=path.join(directory,'kernel-package');fs.mkdirSync(kernelUnpack);
exec('tar',['xzf',kernelTar,'-C',kernelUnpack]);
const kernelRoot=path.join(kernelUnpack,'package');
assert.equal(JSON.parse(fs.readFileSync(path.join(kernelRoot,'package.json'),'utf8')).version,'4.35.0');
const kernelManifest=JSON.parse(fs.readFileSync(path.join(kernelRoot,'PREBUILT_MANIFEST.json'),'utf8'));
const kernelRecord=kernelManifest.targets['linux-x64'];assert.ok(kernelRecord);
const originalChecker=path.join(kernelRoot,kernelRecord.path);
assert.equal(sha(fs.readFileSync(originalChecker)),input.kernel.executableSha256);
fs.chmodSync(originalChecker,0o755);

// Restore exact baseline inputs. No native frontend is installed or executed.
const restored=path.resolve('dist/generated-unified-rust-compiler');
assert.equal(fs.existsSync(restored),false);
fs.mkdirSync(restored,{recursive:true});
fs.copyFileSync(path.join(original,'qualification.json'),path.join(restored,'qualification.json'));
fs.cpSync(path.join(original,'G1-service'),path.join(restored,'G1-service'),{recursive:true});
fs.chmodSync(path.join(restored,'G1-service',artifact.executable),0o755);
fs.mkdirSync('.lake/build/bin',{recursive:true});
fs.copyFileSync(originalChecker,'.lake/build/bin/psc1_independent_checker');
fs.chmodSync('.lake/build/bin/psc1_independent_checker',0o755);

const packageRoot=path.join(directory,'proofscript-native-linux-x64');
for(const sub of ['compiler','kernel','scripts','bin','npm-cli','evidence','examples'])fs.mkdirSync(path.join(packageRoot,sub),{recursive:true});
const compiler=path.join(packageRoot,'compiler/psc-rust'),checker=path.join(packageRoot,'kernel/lean-checker');
fs.copyFileSync(originalCompiler,compiler);fs.chmodSync(compiler,0o755);
const compilerBytesBefore=fs.statSync(compiler).size;
exec('/usr/bin/strip',['--strip-unneeded',compiler]);
const elf=JSON.parse(exec('python3',['scripts/native-psc-elf-identity.py',originalCompiler,compiler]).stdout);
assert.equal(elf.passed,true);
fs.copyFileSync(originalChecker,checker);fs.chmodSync(checker,0o755);
const compilerBytesAfter=fs.statSync(compiler).size;
fs.cpSync('host-tools',path.join(packageRoot,'host-tools'),{recursive:true});
fs.copyFileSync('npm-cli/cli-project.mjs',path.join(packageRoot,'npm-cli/cli-project.mjs'));
fs.copyFileSync('scripts/native-psc-runtime.mjs',path.join(packageRoot,'scripts/native-psc-runtime.mjs'));
fs.copyFileSync('LICENSE',path.join(packageRoot,'LICENSE'));
fs.copyFileSync('NOTICE',path.join(packageRoot,'NOTICE'));
for(const name of ['LICENSE','LEAN_LICENSE','NOTICE'])if(fs.existsSync(path.join(kernelRoot,name)))fs.copyFileSync(path.join(kernelRoot,name),path.join(packageRoot,'kernel',name));
fs.writeFileSync(path.join(packageRoot,'package.json'),'{"private":true,"type":"module"}\n');
fs.writeFileSync(path.join(packageRoot,'bin/psc'),"#!/usr/bin/env node\nimport {main} from '../scripts/native-psc-runtime.mjs';\nprocess.exitCode=main(process.argv.slice(2));\n");
fs.chmodSync(path.join(packageRoot,'bin/psc'),0o755);
fs.writeFileSync(path.join(packageRoot,'examples/Main.ps'),'def invert(flag : Bool) : Bool := if (flag) { false } else { true }\n');
fs.writeFileSync(path.join(packageRoot,'README.md'),`# Native ProofScript developer preview\n\nLinux x64/glibc. Requires Node >=22.23.3 for host orchestration. No Lean SDK, Rust SDK, npm install, or network access is required for checked JS output.\n\nRun: node bin/psc compile examples/Main.ps\nRun: node bin/psc build examples/Main.ps --out /absolute/path/to/output\nRun: node bin/psc --identity\n\nThe compiler is the actual generated Rust-native G1; the kernel is the official Lean 4.35 native provider. Source digest ${input.g1.sourceClosureDigest}. G2/G3 and the four-minute full compiler rebuild target are not qualified by this package. The JS/TS universal distribution is unchanged. No formal backend-preservation claim.\n\nAll source captures, strict original/transformed IR, fresh independent admission, target consumers and transactional publication use the existing host. Runtime identity includes the stripped compiler and exact kernel, not the generated Rust source/audit files. Stripping preserves ELF program headers and all allocated sections. Full compiler and kernel provenance is in evidence/. There is no admission cache or silent fallback.\n\nThe fixed seal is a trusted installation bootstrap, not a signature against replacement of all installed code. Dynamic system libraries are provided by the host; only this tested Linux environment is qualified.\n`);
fs.copyFileSync(path.join(original,'qualification.json'),path.join(packageRoot,'evidence/G1.json'));
fs.copyFileSync('scripts/native-psc-delivery-input.json',path.join(packageRoot,'evidence/INPUTS.json'));
save(path.join(packageRoot,'evidence/ELF.json'),elf);
const inventory=[];
function scan(dir,relative=''){
  for(const name of fs.readdirSync(dir).sort()){
    const rel=relative?relative+'/'+name:name,file=path.join(dir,name),stat=fs.lstatSync(file);
    assert.ok(!stat.isSymbolicLink(),'symlink in runtime package');
    if(stat.isDirectory()){if(rel!=='evidence')scan(file,rel);}
    else{assert.ok(stat.isFile());const bytes=fs.readFileSync(file);if(bytes.length)inventory.push({path:rel,bytes:bytes.length,sha256:sha(bytes)});}
  }
}
scan(packageRoot);
const manifest={schema:'psc1-native-runtime-package/1',platform:'linux-x64',target:'js',compilerGeneration:'G1',
  leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',compilerSourceClosureDigest:input.g1.sourceClosureDigest,
  compilerPath:'compiler/psc-rust',checkerPath:'kernel/lean-checker',sourceCommit:process.env.GITHUB_SHA,
  compilerInput:input.g1,kernelInput:input.kernel,stripIdentity:elf,compilerBytesBefore,compilerBytesAfter,
  nodeHostOrchestration:true,independentAdmission:'fresh per request',fixedPoint:'G2/G3-not-qualified',files:inventory};
save(path.join(packageRoot,'NATIVE_MANIFEST.json'),manifest);
const manifestSha256=sha(fs.readFileSync(path.join(packageRoot,'NATIVE_MANIFEST.json')));
fs.writeFileSync(path.join(packageRoot,'scripts/native-psc-seal.mjs'),'// Trusted immutable installation bootstrap.\nexport const expectedManifestSha256='+JSON.stringify(manifestSha256)+';\n');
const dependencies=exec('/usr/bin/ldd',[compiler]).stdout+exec('/usr/bin/ldd',[checker]).stdout;
fs.writeFileSync(path.join(packageRoot,'evidence/SYSTEM_LIBRARIES.txt'),dependencies);
console.log('PSC1_NATIVE_PACKAGE_PREPARED: '+JSON.stringify({compilerBytesBefore,compilerBytesAfter,kernelBytes:fs.statSync(checker).size,manifestSha256,elf}));

// Test a relocated extraction of the exact archive bytes that will be delivered.
const archive=path.join(directory,'proofscript-native-linux-x64.tar.gz');
exec('tar',['--sort=name','--mtime=@0','--owner=0','--group=0','--numeric-owner','-czf',archive,'-C',directory,'proofscript-native-linux-x64']);
const archiveSha256=sha(fs.readFileSync(archive));
const installedParent=path.join(directory,'relocated installation');fs.mkdirSync(installedParent);
exec('tar',['xzf',archive,'-C',installedParent]);
const installed=path.join(installedParent,'proofscript-native-linux-x64');
const installedCli=path.join(installed,'bin/psc');
const testRoot=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-native-delivery-test-'));
const sandboxEnv={...cleanEnv,PATH:'/no-compiler-sdk-on-path',HOME:testRoot};
const call=(file,args,positive=true)=>{
  const began=performance.now();
  const result=spawnSync(process.execPath,[file,...args],{cwd:testRoot,env:sandboxEnv,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
  const wallMs=performance.now()-began;
  assert.equal(result.error,undefined,String(result.error));
  if(positive)assert.equal(result.status,0,result.stderr);
  else assert.notEqual(result.status,0,'expected refusal');
  return {result,wallMs,value:positive?JSON.parse(result.stdout):null};
};
const api=await import(pathToFileURL(path.join(installed,'scripts/native-psc-runtime.mjs')).href);
const positives=[],negativeCases=[],kernelCases=[],samples=[];
try{
  assert.equal(call(installedCli,['--identity']).value.verified,true);
  for(const item of kernelFixtures){
    const result=spawnSync(path.join(installed,'kernel/lean-checker'),['--check'],{env:sandboxEnv,input:item.input,encoding:'utf8',timeout:120000,maxBuffer:32*1024*1024});
    assert.equal(result.error,undefined);
    const value=JSON.parse(result.stdout);assert.equal(value.accepted,item.accepted,item.id);
    if(item.errorKind)assert.equal(value.errorKind,item.errorKind,item.id);
    assert.equal(value.leanVersion,'4.35.0');assert.equal(value.leanCommit,manifest.leanCommit);
    kernelCases.push({id:item.id,accepted:value.accepted});
  }
  for(const item of corpus){
    const sources=item.sources.map(row=>({...row,kind:item.grammar}));
    const priorPath=process.env.PATH;
    let result;
    try{process.env.PATH=sandboxEnv.PATH;result=api.nativeCompile({sources,entryModule:item.entry,assurance:item.assurance});}
    finally{process.env.PATH=priorPath;}
    const reference=JSON.parse(fs.readFileSync(path.join(original,'G1-js-'+item.id+'.candidate.json'),'utf8'));
    assert.equal(result.source,reference.source,'native emitted source parity: '+item.id);
    assert.equal(result.receipt.admissionsSha256,sha(reference.admissionRequest.admissions));
    assert.equal(result.receipt.originalIrSha256,sha(JSON.stringify(reference.originalIr)));
    assert.equal(result.receipt.specializedIrSha256,sha(JSON.stringify(reference.specializedIr)));
    const target=path.join(testRoot,'target.mjs');fs.writeFileSync(target,result.source);
    const observe=path.join(testRoot,'observe.mjs');
    fs.writeFileSync(observe,"import * as m from './target.mjs';\n"+item.consumer+'\nconsole.log(JSON.stringify('+observedExpressions[item.id]+'));\n');
    const actual=exec(process.execPath,[observe],{cwd:testRoot,env:sandboxEnv});
    assert.deepEqual(JSON.parse(actual.stdout),expectedObservations[item.id]);
    positives.push({id:item.id,grammar:item.grammar,independentlyAdmitted:true,exactSourceAndIr:true,actualRuntimeObservation:true});
  }
  const ps=path.join(testRoot,'Main.ps'),lean=path.join(testRoot,'Main.lean');
  fs.writeFileSync(ps,'def invert(flag : Bool) : Bool := if (flag) { false } else { true }\n');
  fs.writeFileSync(lean,'def invert (flag : Bool) : Bool := if flag then false else true\n');
  // The historical Lake checker is not silently relabelled: both paired variants
  // use the same previously qualified slim native kernel on this runner.
  const smallReferences=new Map();
  for(const [grammar,file] of [['ps',ps],['lean',lean]])for(let round=0;round<3;round++){
    const order=round%2?['packed','workspace']:['workspace','packed'];
    for(const variant of order){
      const script=variant==='packed'?installedCli:path.join(root,'scripts/native-psc-preview.mjs');
      const result=call(script,['compile',file]);
      assert.equal(result.value.receipt.logicalAdmission,'accepted');
      const identity={source:result.value.source,admissions:result.value.receipt.admissionsSha256,
        original:result.value.receipt.originalIrSha256,specialized:result.value.receipt.specializedIrSha256};
      if(smallReferences.has(grammar))assert.deepEqual(identity,smallReferences.get(grammar),'paired exact output/IR/admission identity');
      else smallReferences.set(grammar,identity);
      samples.push({variant,grammar,round,wallMs:result.wallMs,compilerProcessMs:result.value.timings.compilerProcessMs,
        independentKernelMs:result.value.timings.independentKernelMs,resourceVerificationMs:result.value.timings.resourceVerificationMs,
        sourceSha256:sha(result.value.source),admissionsSha256:result.value.receipt.admissionsSha256});
    }
  }
  const invalid=path.join(testRoot,'Wrong.ps');fs.writeFileSync(invalid,'def wrong : Nat := true\n');
  call(installedCli,['compile',invalid],false);negativeCases.push('typing-refusal');
  const output=path.join(testRoot,'output');
  const built=call(installedCli,['build',ps,'--out',output]).value;
  const {readPublication}=await import('../host-tools/transactional-publication.mjs');
  const before=readPublication(output,'portable-file');
  call(installedCli,['build',invalid,'--out',output],false);
  assert.deepEqual(readPublication(output,'portable-file'),before,'failed build replaced publication');
  assert.equal(before.generation,built.publication.generation);negativeCases.push('prior-publication-retained');
  for(const relative of ['compiler/psc-rust','kernel/lean-checker','host-tools/generated-rust-guard.mjs']){
    const file=path.join(installed,relative),bytes=fs.readFileSync(file);
    let changed;
    if(relative.endsWith('.mjs'))changed=Buffer.concat([bytes,Buffer.from('\n// integrity refusal test\n')]);
    else{changed=Buffer.from(bytes);changed[changed.length-1]^=1;}
    fs.writeFileSync(file,changed);
    try{const refused=call(installedCli,['compile',ps],false);assert.match(refused.result.stderr,/RESOURCE_IDENTITY/);}
    finally{fs.writeFileSync(file,bytes);}
    negativeCases.push('tamper-refusal:'+relative);
  }
  call(installedCli,['compile',ps]);
  assert.equal(sha(fs.readFileSync(archive)),archiveSha256);
  const median=values=>{const sorted=[...values].sort((a,b)=>a-b);return(sorted[(sorted.length-1)>>1]+sorted[sorted.length>>1])/2;};
  const workspaceMedianMs=median(samples.filter(x=>x.variant==='workspace').map(x=>x.wallMs));
  const packedMedianMs=median(samples.filter(x=>x.variant==='packed').map(x=>x.wallMs));
  const report={schema:'psc1-native-delivery-qualification/1',status:'passed',sourceCommit:process.env.GITHUB_SHA,
    input,archiveSha256,archiveBytes:fs.statSync(archive).size,manifestSha256,compilerBytesBefore,compilerBytesAfter,
    compilerSha256:sha(fs.readFileSync(compiler)),kernelSha256:sha(fs.readFileSync(checker)),elf,
    platform:'linux-x64',node:process.version,noCompilerSdkOnPath:true,relocatedArchiveTest:true,
    compilerGeneration:'G1',nativeG2G3:'not-qualified',compilerSourceClosureDigest:input.g1.sourceClosureDigest,
    positives,kernelCases,negativeCases,samples,
    comparison:{workspaceMedianMs,packedMedianMs,reduction:1-packedMedianMs/workspaceMedianMs,
      sameRunner:true,sameKernel:true,sameSource:true,compilerAllocatedSectionsEqual:true,
      scope:'finite paired cold tiny-program CLI measurements; not full compiler rebuild performance'},
    policy:'no compiler semantics, strict IR, admission, fuel, resource or universal package changes'};
  const delivery=path.join(directory,'delivery');fs.mkdirSync(delivery);
  fs.copyFileSync(archive,path.join(delivery,path.basename(archive)));
  save(path.join(delivery,'QUALIFICATION.json'),report);
  fs.writeFileSync(path.join(delivery,'SHA256SUMS'),archiveSha256+'  '+path.basename(archive)+'\n');
  fs.writeFileSync(path.join(delivery,'INSTALL.md'),'Extract proofscript-native-linux-x64.tar.gz, then run node proofscript-native-linux-x64/bin/psc --help. Linux x64/glibc and Node >=22.23.3 required. No SDK/install build. G1 preview only; JS output. Read QUALIFICATION.json for exact finite scope.\n');
  console.log('PSC1_NATIVE_DELIVERY: '+JSON.stringify(report));
}finally{fs.rmSync(testRoot,{recursive:true,force:true});}
