// Repackage pinned qualified G3 payloads; never rebuild a compiler or kernel.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';
import {readQualifiedArtifact,sha256} from './kernel435-qualified-artifact.mjs';
import {readQualifiedCompilerAssets} from './qualified-compiler-assets.mjs';
import {crosscheckCompilerAdmissions} from './crosscheck-compiler-admissions.mjs';
const input=JSON.parse(fs.readFileSync('scripts/slim-universal-input.json','utf8')),out=path.resolve('dist/slim-universal'),stage=path.join(out,'package'),version=input.qualifiedCompilerGenerations?'0.1.0-psc1.5':'0.1.0-psc1.4';
assert.ok(out.startsWith(path.resolve('dist')+path.sep));fs.rmSync(out,{recursive:true,force:true});fs.mkdirSync(out,{recursive:true});
const archive=await readQualifiedArtifact(input.qualifiedIntegration,path.join(out,'qualified-input'));
const run=(exe,args)=>{const r=spawnSync(exe,args,{encoding:'utf8',timeout:240000,maxBuffer:64*1024*1024});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
function unpack(tar,dest){fs.mkdirSync(dest,{recursive:true});assert.ok(run('tar',['tzf',tar]).split('\n').filter(Boolean).every(p=>p.startsWith('package/')&&!p.split('/').includes('..')));run('tar',['xzf',tar,'-C',dest]);return path.join(dest,'package');}
function copy(source,target){fs.mkdirSync(path.dirname(target),{recursive:true});fs.cpSync(source,target,{recursive:true,dereference:false});}
function inventory(directory,prefix=''){const rows=[];for(const name of fs.readdirSync(path.join(directory,prefix)).sort()){const relative=prefix?prefix+'/'+name:name,p=path.join(directory,relative),st=fs.lstatSync(p);assert.ok(!st.isSymbolicLink(),'no package symlinks');if(st.isDirectory())rows.push(...inventory(directory,relative));else{assert.ok(st.isFile());const b=fs.readFileSync(p);rows.push({path:relative,bytes:b.length,sha256:sha256(b)});}}return rows;}
const tar=path.join(archive,input.qualifiedIntegration.tarball);assert.equal(sha256(fs.readFileSync(tar)),input.qualifiedIntegration.tarballSha256);
const oldRoot=unpack(tar,path.join(out,'legacy')),old=JSON.parse(fs.readFileSync(path.join(oldRoot,'SELFHOST_DISTRIBUTION.json'),'utf8'));
assert.equal(old.sharedSourceClosureDigest,'07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af');assert.equal(old.allFourEngineSelfHostQualified,true);assert.equal(old.defaultKernel,'wasm');
const current=input.qualifiedCompilerGenerations
 ? await readQualifiedCompilerAssets(input.qualifiedCompilerGenerations,path.join(out,'current-compiler'),version) : null;
const compiler=current||old,compilerAssets=current?.root||oldRoot;
const packages={...input.packages,...Object.fromEntries(Object.entries(current?.optionalPackages||{}).map(([key,p])=>
 [key,{package:p.package,version:p.version,tarball:p.tarball,sha256:p.sha256}]))};
const qualifiedInput=current?{kernelIntegration:input.qualifiedIntegration,compilerGenerations:input.qualifiedCompilerGenerations}:input.qualifiedIntegration;

fs.mkdirSync(stage);
const pins=relative=>{const b=fs.readFileSync(path.join(stage,relative));return {path:relative,bytes:b.length,sha256:sha256(b)};};
const engines={};
for(const engine of ['js','ts']){
 const original=compiler.engines[engine],resources=[original.adapter,...original.dependencies];
 for(const pin of resources){assert.ok(pin.path.startsWith('selfhost/'+engine+'/'));const bytes=fs.readFileSync(path.join(compilerAssets,pin.path));assert.equal(sha256(bytes),pin.sha256);copy(path.join(compilerAssets,pin.path),path.join(stage,pin.path));}
 engines[engine]={kind:'embedded',compilerSourceClosureDigest:compiler.sharedSourceClosureDigest,qualification:original.qualification,qualifiedCommit:original.qualifiedCommit,fixedPoint:original.fixedPoint,executableSha256:original.executableSha256,adapter:pins(original.adapter.path),candidate:pins('selfhost/'+engine+'/module.js'),files:resources.map(r=>pins(r.path))};
}
const packageRoots={},tarballs=path.join(out,'tarballs');fs.mkdirSync(tarballs);
for(const [key,p]of Object.entries(packages)){
 const source=current?.optionalPackages[key]?.file||path.join(archive,'kernel435-core/tarballs',p.tarball);assert.equal(sha256(fs.readFileSync(source)),p.sha256);
 const root=unpack(source,path.join(out,'optional',key)),meta=JSON.parse(fs.readFileSync(path.join(root,'package.json'),'utf8'));assert.equal(meta.name,p.package);assert.equal(meta.version,p.version);packageRoots[key]=root;copy(source,path.join(tarballs,p.tarball));
}
const descriptor=(key)=>{const p=packages[key],root=packageRoots[key];return {package:p.package,version:p.version,entry:'index.mjs',tarballSha256:p.sha256,files:inventory(root)};};
for(const engine of ['rust','wasm-core']){
 const original=compiler.engines[engine],p=packages[engine],root=packageRoots[engine],manifest=JSON.parse(fs.readFileSync(path.join(root,'BUNDLE_MANIFEST.json'),'utf8'));
 assert.equal(manifest.engine,engine);assert.equal(manifest.compilerSourceClosureDigest,compiler.sharedSourceClosureDigest);assert.equal(manifest.executableSha256,original.executableSha256);assert.equal(manifest.publicationAuthority,false);
 const adapter='selfhost/optional-'+engine+'.mjs';fs.writeFileSync(path.join(stage,adapter),"import {psCompilerJsServiceCandidate as candidate} from '"+p.package+"';\nexport function psCompilerJsServiceCandidate(request){return candidate(request);}\n");
 engines[engine]={kind:'optional-package',...descriptor(engine),compilerSourceClosureDigest:compiler.sharedSourceClosureDigest,qualification:original.qualification,qualifiedCommit:original.qualifiedCommit,fixedPoint:original.fixedPoint,executableSha256:original.executableSha256,adapter:pins(adapter)};
}
const kernelRoot=path.join(stage,'node_modules/@proofscript/pskernel-lean-wasm');copy(packageRoots.wasmKernel,kernelRoot);
if(current)await crosscheckCompilerAdmissions({
 sourceClosureDigest:current.sharedSourceClosureDigest,admissions:current.compilerAdmissions,
 kernelRoots:{wasm:kernelRoot,native:packageRoots.nativeKernel},
 outputFile:path.join(out,'compiler-kernel-admission.json')
});

const hostFiles=[
 'host-tools/generated-compiler-session.mjs','host-tools/compiler-host-protocol.mjs','host-tools/installed-engine-resolver.mjs',
 'host-tools/typed-io.mjs','host-tools/typed-io.d.ts',
 'scripts/compiler-closure-contract.mjs','scripts/generated-compiler-runner.mjs','scripts/universal-candidate-runner.mjs',
 'npm-cli/universal.mjs','npm-cli/universal-cli.mjs','npm-cli/universal-kernel-checker.mjs','npm-cli/universal-wasm-checker.mjs','npm-cli/universal-native-checker.mjs','npm-cli/universal.d.ts'
];
for(const file of hostFiles)copy(file,path.join(stage,file));fs.chmodSync(path.join(stage,'npm-cli/universal-cli.mjs'),0o755);
const peers=Object.fromEntries(['nativeKernel','rust','wasm-core'].map(k=>[packages[k].package,packages[k].version]));
const meta={name:'proofscript',version,type:'module',private:true,license:'UNLICENSED',engines:{node:'22.23.3'},
 main:'./npm-cli/universal.mjs',types:'./npm-cli/universal.d.ts',
 exports:{'./io':{types:'./host-tools/typed-io.d.ts',import:'./host-tools/typed-io.mjs'},'.':{types:'./npm-cli/universal.d.ts',import:'./npm-cli/universal.mjs'},'./kernel':{types:'./npm-cli/universal.d.ts',import:'./npm-cli/universal.mjs'},'./metadata':'./UNIVERSAL_DISTRIBUTION.json','./package.json':'./package.json'},
 bin:{psc:'./npm-cli/universal-cli.mjs',psc1:'./npm-cli/universal-cli.mjs'},
 dependencies:{'@proofscript/pskernel-lean-wasm':'4.35.0'},bundledDependencies:['@proofscript/pskernel-lean-wasm'],
 peerDependencies:peers,peerDependenciesMeta:Object.fromEntries(Object.keys(peers).map(k=>[k,{optional:true}])),
 files:['npm-cli/','host-tools/','scripts/','selfhost/','UNIVERSAL_DISTRIBUTION.json','DISTRIBUTION_PIN.mjs','SOURCE_IDENTITIES.json','DEPENDENCY_LOCK.json','README.md'],
 proofscript:{distribution:'slim-universal',defaultEngine:'js',defaultKernel:'wasm',compilerSourceClosureDigest:compiler.sharedSourceClosureDigest,allFourEngineSelfHostQualified:true,finalCrossPlatformRelease:false}
};
fs.writeFileSync(path.join(stage,'package.json'),JSON.stringify(meta,null,2)+'\n');
const wasmMeta=JSON.parse(fs.readFileSync(path.join(kernelRoot,'package.json'),'utf8'));
const lock={name:meta.name,version,lockfileVersion:3,requires:true,packages:{'':{name:meta.name,version,dependencies:meta.dependencies,peerDependencies:peers,peerDependenciesMeta:meta.peerDependenciesMeta},'node_modules/@proofscript/pskernel-lean-wasm':{name:wasmMeta.name,version:wasmMeta.version,inBundle:true,license:wasmMeta.license,engines:wasmMeta.engines}}};
fs.writeFileSync(path.join(stage,'npm-shrinkwrap.json'),JSON.stringify(lock,null,2)+'\n');
fs.writeFileSync(path.join(stage,'DEPENDENCY_LOCK.json'),JSON.stringify(lock,null,2)+'\n');
fs.writeFileSync(path.join(stage,'SOURCE_IDENTITIES.json'),JSON.stringify({compilerSourceClosureDigest:compiler.sharedSourceClosureDigest,qualifiedInput,engines:Object.fromEntries(Object.entries(compiler.engines).map(([name,e])=>[name,{qualifiedCommit:e.qualifiedCommit,executableSha256:e.executableSha256,fixedPoint:e.fixedPoint}]))},null,2)+'\n');
fs.writeFileSync(path.join(stage,'README.md'),'# ProofScript slim universal candidate\n\nGenerated JS/TS executors and the official Lean4.35 linear-memory Wasm checker are included. No native compiler, native checker, Rust executor, compiler-Wasm executor, platform formatter, Python/PHP transport, SDK download or install-time build is included. Rust/Wasm executors are explicit optional packages pinned to the qualified G3 payloads. Native checking is optional and explicit. No fallback on absence, refusal, corruption or timeout.\n\npsc check Main.lean; psc compile Main.ps --engine ts; psc build Main.ps --out dist/app; psc build Main.ps --engine wasm-core --out dist/wasm-executor. build retains Linux fsync/atomic symlink publication; other platforms must use checked compile API/stdout until their publication release gate is qualified.\n\nExplicit proofscript/io exports the existing bounded Linux String dispatcher with host-owned capabilities, root, byte limits and descriptors. It does not select or admit programs. Only a compiler payload qualified for the explicit IO request can compile outputAbi:io-dispatcher; scalar remains the default.\n\nThe typed compile API accepts {entryModule, sources:[{module,kind,text}]} and returns checked JS and an exact logical-admission receipt. compileCandidate supports existing js/ts/rust/wasm-core output mappings but returns candidate data with no admission/publication authority. The installed candidate executor remains bounded by240 seconds; checker120 seconds and all existing IR/source/fuel/memory/stack checks remain.\n\nAll packages remain unpublished. Linux CI qualifies this milestone; complete macOS/Windows publication/release qualification and generated non-JS publication are separate. The previous native distribution with all seven output mappings remains preserved in its original qualified artifact.\n');
const distribution={schema:'psc1-universal-npm-distribution/1',packageBuildCommit:process.env.GITHUB_SHA,version,compilerSourceClosureDigest:compiler.sharedSourceClosureDigest,
 defaultEngine:'js',defaultKernel:'wasm',leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',engines,kernels:{wasm:descriptor('wasmKernel'),native:descriptor('nativeKernel')},
 hostFiles:[...hostFiles,'package.json','DEPENDENCY_LOCK.json','SOURCE_IDENTITIES.json','README.md'].map(pins),runner:pins('scripts/generated-compiler-runner.mjs'),fullCrossPlatformRelease:false,qualifiedInput};
const manifest=JSON.stringify(distribution,null,2)+'\n';fs.writeFileSync(path.join(stage,'UNIVERSAL_DISTRIBUTION.json'),manifest);
fs.writeFileSync(path.join(stage,'DISTRIBUTION_PIN.mjs'),"export const expectedDistributionSha256='"+sha256(manifest)+"';\nexport const expectedCompilerSourceClosureDigest='"+compiler.sharedSourceClosureDigest+"';\n");
const packed=JSON.parse(run('npm',['pack',stage,'--ignore-scripts','--json','--pack-destination',tarballs]));assert.equal(packed.length,1);
const file=path.join(tarballs,packed[0].filename),bytes=fs.readFileSync(file);
const inventoryRows=inventory(stage);assert.ok(!inventoryRows.some(r=>r.path.startsWith('native/')||r.path.startsWith('selfhost/rust/')||r.path.startsWith('selfhost/wasm-core/')));assert.ok(!meta.os&&!meta.cpu&&!meta.libc);
const ratio=bytes.length/fs.statSync(tar).size;assert.ok(ratio<0.5,'root must be less than half the previous root');
const receipt={schema:'psc1-slim-universal-package/1',sourceCommit:process.env.GITHUB_SHA,status:'assembled-not-yet-qualified',package:meta.name,version,tarball:packed[0].filename,bytes:bytes.length,sha256:sha256(bytes),previousRootBytes:fs.statSync(tar).size,sizeRatio:ratio,removedBytes:fs.statSync(tar).size-bytes.length,compilerSourceClosureDigest:compiler.sharedSourceClosureDigest,embeddedEngines:['js','ts'],optionalExecutionPackages:['rust','wasm-core'].map(k=>packages[k]),defaultKernel:'wasm',nativePayloadsIncluded:false,compilerSdkRequired:false,osCpuLibcRestrictions:false,publicationPlatforms:['linux'],fullCrossPlatformRelease:false,input:{...input,packages}};
fs.writeFileSync(path.join(out,'package-receipt.json'),JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_SLIM_UNIVERSAL_PACKAGE: '+JSON.stringify(receipt));
