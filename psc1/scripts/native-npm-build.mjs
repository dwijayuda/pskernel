// Linux Actions packaging only. Exact G1 Rust source is cross-compiled, not rewritten.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {readQualifiedArtifact,sha256 as sha} from './kernel435-qualified-artifact.mjs';
import {verifyArtifact} from '../host-tools/generated-target-tools.mjs';
import {fixtures as kernelFixtures} from './kernel435-fixtures.mjs';
import {corpus,expectedObservations,observedExpressions} from './generated-target-corpus.mjs';
assert.equal(process.env.GITHUB_ACTIONS,'true');assert.equal(process.platform,'linux');assert.equal(process.arch,'x64');
const mode=process.argv[2],root=process.cwd(),out=path.resolve('dist/native-npm');
const version='0.1.0-psc1-native.1',leanCommit='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const input=JSON.parse(fs.readFileSync('scripts/native-psc-delivery-input.json','utf8'));
const save=(file,value)=>{fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');};
const exec=(exe,args,options={})=>{
  const start=performance.now();
  const result=spawnSync(exe,args,{cwd:root,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...options});
  assert.equal(result.error,undefined,String(result.error));
  assert.equal(result.status,0,(result.stderr||'')+'\n'+(result.stdout||'').slice(-6000));
  return {stdout:result.stdout,stderr:result.stderr,elapsedMs:performance.now()-start};
};
const npmCandidates=[process.env.npm_execpath,path.join(path.dirname(process.execPath),'node_modules/npm/bin/npm-cli.js'),path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js')].filter(Boolean);
const npm=npmCandidates.find(fs.existsSync);assert.ok(npm,'npm CLI location');
function row(base,relative){const bytes=fs.readFileSync(path.join(base,relative));assert.ok(bytes.length>0);return {path:relative,bytes:bytes.length,sha256:sha(bytes)};}
function walk(directory,relative='',skip=()=>false){
  const rows=[];
  for(const name of fs.readdirSync(path.join(directory,relative)).sort()){
    const rel=relative?relative+'/'+name:name;if(skip(rel))continue;
    const stat=fs.lstatSync(path.join(directory,rel));assert.ok(!stat.isSymbolicLink());
    if(stat.isDirectory())rows.push(...walk(directory,rel,skip));
    else if(stat.isFile()&&stat.size>0)rows.push(row(directory,rel));
  }
  return rows;
}
function license(destination){for(const name of ['LICENSE','NOTICE'])fs.copyFileSync(name,path.join(destination,name));}
if(mode==='prepare'){
  assert.ok(out.startsWith(path.resolve('dist')+path.sep));assert.equal(fs.existsSync(out),false,'fresh native npm build required');
  fs.mkdirSync(out,{recursive:true});
  const g1=await readQualifiedArtifact(input.g1,path.join(out,'g1-input'));
  const original=path.join(g1,input.g1.directory),qualification=JSON.parse(fs.readFileSync(path.join(original,'qualification.json'),'utf8'));
  assert.equal(qualification.status,'passed');assert.equal(qualification.correctnessQualification,'G1-only');
  assert.equal(qualification.testedCommit,input.g1.commit);assert.equal(qualification.sourceClosureDigest,input.g1.sourceClosureDigest);
  assert.equal(qualification.sourceModules,133);assert.equal(qualification.generations.length,1);
  for(const source of qualification.sourceInventory){const bytes=fs.readFileSync(source.path);assert.equal(bytes.length,source.bytes);assert.equal(sha(bytes),source.sha256);}
  const artifactFile=path.join(original,'G1-service/artifact.json');
  assert.equal(sha(fs.readFileSync(artifactFile)),input.g1.manifestSha256);
  const artifact=verifyArtifact(artifactFile,input.g1.manifestSha256);
  assert.equal(sha(fs.readFileSync(path.join(original,'G1-service',artifact.executable))),input.g1.executableSha256);
  const sourceDir=path.join(out,'windows-source');fs.mkdirSync(sourceDir);
  for(const file of ['Cargo.toml','Cargo.lock','main.rs','module.rs'])fs.copyFileSync(path.join(original,'G1-service',file),path.join(sourceDir,file));
  const kernelInput=await readQualifiedArtifact(input.kernel,path.join(out,'kernel-input'));
  const kernelTar=path.join(kernelInput,input.kernel.tarball);assert.equal(sha(fs.readFileSync(kernelTar)),input.kernel.tarballSha256);
  const unpack=path.join(out,'kernel-unpack');fs.mkdirSync(unpack);exec('tar',['xzf',kernelTar,'-C',unpack]);
  const kernelRoot=path.join(unpack,'package');
  const km=JSON.parse(fs.readFileSync(path.join(kernelRoot,'PREBUILT_MANIFEST.json'),'utf8'));
  assert.equal(km.leanCommit,leanCommit);assert.equal(km.leanVersion,'4.35.0');
  assert.equal(JSON.parse(fs.readFileSync(path.join(kernelRoot,'package.json'))).version,'4.35.0');
  for(const target of ['linux-x64','win32-x64']){
    const binary=km.targets[target];assert.ok(binary);const bytes=fs.readFileSync(path.join(kernelRoot,binary.path));
    assert.equal(bytes.length,binary.size);assert.equal(sha(bytes),binary.sha256);assert.ok(bytes.length<7000000);
  }
  const fixtures={corpus:corpus.map(item=>{
    const candidate=JSON.parse(fs.readFileSync(path.join(original,'G1-js-'+item.id+'.candidate.json'),'utf8'));
    return {...item,observationExpression:observedExpressions[item.id],expected:expectedObservations[item.id],reference:{
      source:candidate.source,originalIrSha256:sha(JSON.stringify(candidate.originalIr)),
      specializedIrSha256:sha(JSON.stringify(candidate.specializedIr)),admissionsSha256:sha(candidate.admissionRequest.admissions)}};
  }),kernelFixtures};
  save(path.join(out,'tests/fixtures.json'),fixtures);
  for(const file of ['native-npm-installed.mjs','native-windows-job-tests.mjs'])fs.copyFileSync('scripts/'+file,path.join(out,'tests',file));
  save(path.join(out,'INPUTS.json'),{input,sourceCommit:process.env.GITHUB_SHA,sourceFiles:walk(sourceDir),kernelTargets:km.targets});
  console.log('PSC1_NATIVE_NPM_INPUTS: '+JSON.stringify({sourceClosureDigest:input.g1.sourceClosureDigest,modules:133,windowsRustSource:'exact admitted G1 main.rs',kernelTargets:Object.keys(km.targets)}));
}else if(mode==='assemble'){
  const prepared=JSON.parse(fs.readFileSync(path.join(out,'INPUTS.json')));
  const sourceDir=path.join(out,'windows-source');
  for(const entry of prepared.sourceFiles)assert.deepEqual(row(sourceDir,entry.path),entry,'Windows cross-build source changed');
  const original=path.join(out,'g1-input',input.g1.directory,'G1-service');
  const windowsBinary=path.join(out,'cargo/x86_64-pc-windows-gnu/release/psc1-generated-target.exe');
  assert.ok(fs.statSync(windowsBinary).size>0);
  const rootPackage=path.join(out,'root'),delivery=path.join(out,'delivery');
  fs.mkdirSync(rootPackage);fs.mkdirSync(delivery);
  const kernelRoot=path.join(rootPackage,'node_modules/@proofscript/pskernel-lean');
  fs.cpSync(path.join(out,'kernel-unpack/package'),kernelRoot,{recursive:true});
  const km=JSON.parse(fs.readFileSync(path.join(kernelRoot,'PREBUILT_MANIFEST.json')));
  const compilerPackages=[],platforms={};
  for(const platform of ['linux-x64','win32-x64']){
    const windows=platform==='win32-x64';
    const name='@proofscript/compiler-rust-'+platform;
    const packageRelative='node_modules/'+name,dir=path.join(rootPackage,packageRelative);
    fs.mkdirSync(path.join(dir,'dist'),{recursive:true});
    const binaryName='psc-rust'+(windows?'.exe':'');
    const binary=path.join(dir,'dist',binaryName);
    fs.copyFileSync(windows?windowsBinary:path.join(original,'service.bin'),binary);fs.chmodSync(binary,0o755);
    let stripIdentity=null;
    if(!windows){exec('/usr/bin/strip',['--strip-unneeded',binary]);stripIdentity=JSON.parse(exec('python3',['scripts/native-psc-elf-identity.py',path.join(original,'service.bin'),binary]).stdout);assert.equal(stripIdentity.passed,true);}
    if(windows){fs.copyFileSync(path.join(out,'psc-job.exe'),path.join(dir,'dist/psc-job.exe'));fs.chmodSync(path.join(dir,'dist/psc-job.exe'),0o755);}
    const metadata={schema:'psc1-native-compiler-payload/1',package:name,version,platform,generation:'G1',
      sourceClosureDigest:input.g1.sourceClosureDigest,originalG1:input.g1,sourceCommit:process.env.GITHUB_SHA,
      target:windows?'x86_64-pc-windows-gnu':'x86_64-unknown-linux-gnu',
      files:walk(dir,'dist'),stripIdentity,publicationAuthority:false,logicalAdmissionAuthority:false,nativeG2G3Qualified:false};
    save(path.join(dir,'METADATA.json'),metadata);
    fs.writeFileSync(path.join(dir,'index.mjs'),"import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {fileURLToPath} from 'node:url';\nconst root=path.dirname(fileURLToPath(import.meta.url));\nexport const metadata=Object.freeze("+JSON.stringify(metadata)+");\nexport function getExecutable(){if(process.platform+'-'+process.arch!==metadata.platform)throw Error('PSC1_NATIVE_PAYLOAD_PLATFORM');const record=metadata.files.find(row=>row.path.endsWith('/"+binaryName+"'));const file=path.join(root,record.path),s=fs.lstatSync(file);if(!s.isFile()||s.isSymbolicLink()||s.size!==record.bytes||crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')!==record.sha256)throw Error('PSC1_NATIVE_PAYLOAD_IDENTITY');return file;}\n");
    save(path.join(dir,'package.json'),{name,version,type:'module',private:true,license:'Apache-2.0',os:[windows?'win32':'linux'],cpu:['x64'],
      main:'./index.mjs',exports:{'.':'./index.mjs','./metadata':'./METADATA.json','./package.json':'./package.json'},
      files:['dist/','METADATA.json','index.mjs','README.md','LICENSE','NOTICE'],
      description:'Prebuilt PSC1 G1 Rust-native candidate compiler; no proof admission or publication authority'});
    fs.writeFileSync(path.join(dir,'README.md'),'# '+name+'\n\nNative G1 compiler payload for '+platform+'. Install the bundled proofscript native preview for the checked psc command. This package alone returns candidate data and cannot certify proofs or publish checked output. No install scripts or SDK are needed. Native G2/G3 remains unqualified.\n');license(dir);
    const packed=JSON.parse(exec(process.execPath,[npm,'pack',dir,'--ignore-scripts','--json','--pack-destination',delivery]).stdout);
    assert.equal(packed.length,1);compilerPackages.push({name,version,tarball:packed[0].filename});
    const checkerRelative='node_modules/@proofscript/pskernel-lean/'+km.targets[platform].path;
    const kernelPins=['package.json','PREBUILT_MANIFEST.json','LEAN_SOURCE_PIN.json',km.targets[platform].path].map(rel=>row(rootPackage,'node_modules/@proofscript/pskernel-lean/'+rel));
    platforms[platform]={compilerPackage:name,compilerPath:packageRelative+'/dist/'+binaryName,checkerPath:checkerRelative,
      ...(windows?{guardPath:packageRelative+'/dist/psc-job.exe'}:{}),
      files:[...walk(rootPackage,packageRelative),...kernelPins]};
  }
  fs.mkdirSync(path.join(rootPackage,'dist'),{recursive:true});
  fs.cpSync('host-tools',path.join(rootPackage,'dist/host-tools'),{recursive:true});
  fs.mkdirSync(path.join(rootPackage,'dist/npm-cli'));fs.copyFileSync('npm-cli/cli-project.mjs',path.join(rootPackage,'dist/npm-cli/cli-project.mjs'));
  fs.copyFileSync('scripts/native-npm-runtime.mjs',path.join(rootPackage,'dist/native-runtime.mjs'));
  fs.mkdirSync(path.join(rootPackage,'bin'));fs.writeFileSync(path.join(rootPackage,'bin/psc.mjs'),"#!/usr/bin/env node\nimport {main} from '../dist/native-runtime.mjs';\nprocess.exitCode=main(process.argv.slice(2));\n");fs.chmodSync(path.join(rootPackage,'bin/psc.mjs'),0o755);
  fs.writeFileSync(path.join(rootPackage,'index.mjs'),"export {compile,getMetadata} from './dist/native-runtime.mjs';\n");
  fs.writeFileSync(path.join(rootPackage,'index.d.ts'),"export interface Source {module:string;kind:'ps'|'lean';text:string;}\nexport function getMetadata(): Readonly<Record<string,unknown>>;\nexport function compile(options:{sources:Source[];entryModule:string;assurance?:'checked'|'ordinary-checked';evidence?:'minimal'|'full';out?:string;beforePublish?:()=>void}): Readonly<Record<string,unknown>>;\n");
  fs.mkdirSync(path.join(rootPackage,'examples'));fs.writeFileSync(path.join(rootPackage,'examples/Main.ps'),'def invert(flag : Bool) : Bool := if (flag) { false } else { true }\n');
  const names=compilerPackages.map(row=>row.name);
  save(path.join(rootPackage,'package.json'),{name:'proofscript',version,type:'module',private:true,license:'Apache-2.0',description:'Native PSC1 G1 developer preview: Windows/Linux Rust compiler and official Lean native kernel',
    engines:{node:'>=22.23.3'},os:['linux','win32'],cpu:['x64'],main:'./index.mjs',types:'./index.d.ts',
    exports:{'.':{types:'./index.d.ts',import:'./index.mjs'},'./package.json':'./package.json'},bin:{psc:'./bin/psc.mjs'},
    files:['bin/','dist/','examples/','NATIVE_MANIFEST.json','index.mjs','index.d.ts','README.md','LICENSE','NOTICE'],
    dependencies:{'@proofscript/pskernel-lean':'4.35.0'},optionalDependencies:Object.fromEntries(names.map(name=>[name,version])),
    bundleDependencies:['@proofscript/pskernel-lean',...names],
    proofscript:{compilerEngine:'native-rust',kernel:'native-Lean4.35',generation:'G1',outputTargets:['js'],nodeHostRequired:true,registryPublication:false}});
  license(rootPackage);
  const instructions='# Installable native ProofScript npm preview\n\nWindows x64 / Linux x64. Node >=22.23.3 is required. No Lean, Rust, Visual Studio, MinGW, compiler download, or post-install build is needed to use checked JS output.\n\nInstall the root tarball (it already bundles its dependencies):\n\n```sh\nnpm install --global --offline --ignore-scripts ./proofscript-'+version+'.tgz\npsc --identity\npsc compile Main.ps\npsc build Main.ps --out ./out\n```\n\nLocal alternative: npm install --offline --ignore-scripts ./proofscript-'+version+'.tgz; then npx --no-install psc --identity. PowerShell may use npm.cmd and psc.cmd when script execution policy blocks .ps1 launchers.\n\nThe root proofscript package provides the psc command. Separate @proofscript/compiler-rust-win32-x64 and @proofscript/compiler-rust-linux-x64 tarballs are payloads, not independent proof-checking frontends. @proofscript/pskernel-lean retains its existing public checker API. All are included in the root tarball.\n\nOnly JS output is exposed by this native preview. Both source grammars are supported within the current PSC1 subset. The actual compiler and kernel are native executables, while Node supplies the existing checked host, strict IR checks and publication protocol. G1 is qualified separately from native G2/G3, which is not claimed. The default universal JS/TS distribution is not replaced or published.\n\nWindows builds are cross-compiled in Linux Actions, with Windows Node/npm execution tested under Wine. This is not a native Windows-host qualification. All delivery evidence distinguishes those environments. Windows uses the existing portable-atomic publication protocol: atomic visibility, not a power-loss durability guarantee. Missing or changed pinned resources fail closed.\n';
  fs.writeFileSync(path.join(rootPackage,'README.md'),instructions);
  const manifest={schema:'psc1-native-npm-distribution/1',version,sourceCommit:process.env.GITHUB_SHA,generation:'G1',outputTarget:'js',leanCommit,
    compilerSourceClosureDigest:input.g1.sourceClosureDigest,nodeHostRequired:true,platforms,
    files:walk(rootPackage,'',relative=>relative==='node_modules'),qualification:'pending-installed-tests'};
  save(path.join(rootPackage,'NATIVE_MANIFEST.json'),manifest);
  const manifestSha256=sha(fs.readFileSync(path.join(rootPackage,'NATIVE_MANIFEST.json')));
  fs.writeFileSync(path.join(rootPackage,'dist/native-seal.mjs'),'// Trusted installed bootstrap; not a publisher signature.\nexport const expectedManifestSha256='+JSON.stringify(manifestSha256)+';\n');
  const packed=JSON.parse(exec(process.execPath,[npm,'pack',rootPackage,'--ignore-scripts','--json','--pack-destination',delivery]).stdout);
  assert.equal(packed.length,1);
  const rootTar=path.join(delivery,packed[0].filename);
  const entries=exec('tar',['tzf',rootTar]).stdout;
  for(const name of names)assert.ok(entries.includes('package/node_modules/'+name+'/dist/psc-rust'),'missing bundled native payload '+name);
  assert.ok(entries.includes('package/node_modules/@proofscript/pskernel-lean/PREBUILT_MANIFEST.json'));
  fs.copyFileSync(path.join(out,'kernel-input',input.kernel.tarball),path.join(delivery,input.kernel.tarball));
  fs.writeFileSync(path.join(delivery,'INSTALL.md'),instructions);
  const packages=fs.readdirSync(delivery).filter(name=>name.endsWith('.tgz')).sort().map(file=>row(delivery,file));
  fs.writeFileSync(path.join(delivery,'SHA256SUMS'),packages.map(row=>row.sha256+'  '+row.path).join('\n')+'\n');
  save(path.join(delivery,'BUILD.json'),{schema:'psc1-native-npm-build/1',sourceCommit:process.env.GITHUB_SHA,status:'assembled-not-yet-installed',
    input,version,rootTarball:packed[0].filename,packages,manifestSha256,platforms:Object.fromEntries(Object.entries(platforms).map(([key,value])=>[key,{compilerPath:value.compilerPath,compilerSha256:row(rootPackage,value.compilerPath).sha256,checkerSha256:row(rootPackage,value.checkerPath).sha256}])),
    rust:exec('rustc',['--version']).stdout.trim(),windowsCrossTarget:'x86_64-pc-windows-gnu',nativeWindowsHostTest:false});
  console.log('PSC1_NATIVE_NPM_ASSEMBLED: '+JSON.stringify({rootTarball:packed[0].filename,packages,manifestSha256}));
}else throw Error('Use prepare or assemble');
