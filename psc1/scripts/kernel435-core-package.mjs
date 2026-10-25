// Augment the qualified compiler package. Compiler/G3 bytes are never regenerated here.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';import {readQualifiedArtifact,sha256} from './kernel435-qualified-artifact.mjs';
const root=process.cwd(),out=path.resolve('dist/kernel435-core'),work=path.join(out,'work'),stage=path.join(work,'package'),inputs=JSON.parse(fs.readFileSync('scripts/kernel435-integrated-inputs.json','utf8'));
const run=(exe,args)=>{const r=spawnSync(exe,args,{encoding:'utf8',timeout:240000,maxBuffer:64*1024*1024});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,(r.stdout||'')+(r.stderr||''));return r.stdout;};
assert.ok(out.startsWith(path.join(root,'dist')+path.sep));fs.rmSync(out,{recursive:true,force:true});fs.mkdirSync(work,{recursive:true});
const archives={};for(const key of ['core','native','wasm'])archives[key]=await readQualifiedArtifact(inputs[key],path.join(out,'inputs',key));
function unpack(file,directory){fs.mkdirSync(directory,{recursive:true});const entries=run('tar',['tzf',file]).split('\n').filter(Boolean);assert.ok(entries.every(p=>p.startsWith('package/')&&!p.split('/').includes('..')));run('tar',['xzf',file,'-C',directory]);}
const coreTar=path.join(archives.core,inputs.core.tarball);assert.equal(sha256(fs.readFileSync(coreTar)),inputs.core.tarballSha256);unpack(coreTar,work);
const meta=JSON.parse(fs.readFileSync(path.join(stage,'package.json'),'utf8')),old=JSON.parse(fs.readFileSync(path.join(stage,'SELFHOST_DISTRIBUTION.json'),'utf8')),nativeDistribution=JSON.parse(fs.readFileSync(path.join(stage,'NATIVE_DISTRIBUTION.json'),'utf8'));
assert.equal(meta.name,'proofscript');assert.equal(old.sharedSourceClosureDigest,'07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af');assert.equal(old.allFourEngineSelfHostQualified,true);assert.equal(old.allFourEngineReleaseQualified,false);
const filePin=rel=>{const b=fs.readFileSync(path.join(stage,rel));return {path:rel,bytes:b.length,sha256:sha256(b)};};
for(const engine of Object.values(old.engines))for(const pin of [engine.adapter,...engine.dependencies])assert.equal(filePin(pin.path).sha256,pin.sha256,'preserve qualified engine asset');
const providers={};
for(const key of ['native','wasm']){
 const input=inputs[key],tar=path.join(archives[key],input.tarball);assert.equal(sha256(fs.readFileSync(tar)),input.tarballSha256);
 const extracted=path.join(out,key);unpack(tar,extracted);const pkg=path.join(extracted,'package'),pmeta=JSON.parse(fs.readFileSync(path.join(pkg,'package.json'),'utf8')),name=key==='native'?'@proofscript/pskernel-lean':'@proofscript/pskernel-lean-wasm';assert.equal(pmeta.name,name);assert.equal(pmeta.version,'4.35.0');
 const dst='node_modules/'+name;assert.equal(fs.existsSync(path.join(stage,dst)),false);fs.mkdirSync(path.dirname(path.join(stage,dst)),{recursive:true});fs.cpSync(pkg,path.join(stage,dst),{recursive:true});
 const files=[];for(const rel of ['index.mjs','package.json',key==='native'?'PREBUILT_MANIFEST.json':'PREBUILT_WASM_MANIFEST.json'])files.push(filePin(dst+'/'+rel));
 function walk(dir){for(const e of fs.readdirSync(path.join(stage,dst,dir),{withFileTypes:true})){const rel=dir+'/'+e.name;if(e.isDirectory())walk(rel);else{assert.ok(e.isFile()&&!e.isSymbolicLink());files.push(filePin(dst+'/'+rel));}}}
 walk('host');walk(key==='native'?'prebuilt':'wasm');
 providers[key]={package:name,version:'4.35.0',entry:dst+'/index.mjs',files};
 meta.dependencies[name]='4.35.0';meta.bundledDependencies=[...new Set([...meta.bundledDependencies,name])];
}
const nativeManifest=JSON.parse(fs.readFileSync(path.join(stage,'node_modules/@proofscript/pskernel-lean/PREBUILT_MANIFEST.json'),'utf8')),wasmManifest=JSON.parse(fs.readFileSync(path.join(stage,'node_modules/@proofscript/pskernel-lean-wasm/PREBUILT_WASM_MANIFEST.json'),'utf8'));
assert.equal(nativeManifest.sourceClosureDigest,wasmManifest.sourceClosureDigest);assert.equal(nativeManifest.sourceClosureDigest,'f1bd2a7d42b9473945028ffa698f244b33afeb937224c5c8e37d8c50d9de0a2b');assert.equal(wasmManifest.memoryModel,'linear');assert.equal(wasmManifest.leanVersion,'4.35.0');
const nativeCompiler=filePin('native/bin/psc1');assert.equal(nativeCompiler.sha256,nativeDistribution.nativeSha256);
const distribution={schema:'psc1-installed-independent-kernels/1',packageBuildCommit:process.env.GITHUB_SHA,leanVersion:'4.35.0',leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',canonicalAdmissionsVersion:2,sourceClosureDigest:nativeManifest.sourceClosureDigest,nativeCompiler,providers,publication:'unpublished',corePlatformScope:'linux-x64-glibc; kernel packages separately qualified on five platforms'};
fs.writeFileSync(path.join(stage,'KERNEL_DISTRIBUTION.json'),JSON.stringify(distribution,null,2)+'\n');
for(const rel of ['host-tools/kernel-toolchain.mjs','host-tools/generated-compiler-session.mjs','npm-cli/kernel.mjs','npm-cli/kernel-checker.mjs','npm-cli/generated-entry.mjs','npm-cli/generated.mjs']){fs.copyFileSync(rel,path.join(stage,rel));}
const selected=nativeManifest.targets[process.platform+'-'+process.arch];assert.ok(selected);old.checker=filePin('node_modules/@proofscript/pskernel-lean/'+selected.path);old.session=filePin('host-tools/generated-compiler-session.mjs');
const globalHost=['host-tools/kernel-toolchain.mjs','npm-cli/generated.mjs','npm-cli/generated-entry.mjs','npm-cli/kernel-checker.mjs','npm-cli/kernel.mjs','KERNEL_DISTRIBUTION.json'];
old.hostDependencies=[...(old.hostDependencies||[]).filter(p=>!globalHost.includes(p.path)),...globalHost.map(filePin),...providers.native.files];
old.additionalCheckers={wasm:{script:filePin('npm-cli/kernel-checker.mjs'),dependencies:[filePin('host-tools/kernel-toolchain.mjs'),filePin('KERNEL_DISTRIBUTION.json'),...providers.wasm.files]}};
old.kernelPackages={native:'4.35.0',wasm:'4.35.0',wasmMemoryModel:'linear'};old.packageBuildCommit=process.env.GITHUB_SHA;
fs.writeFileSync(path.join(stage,'SELFHOST_DISTRIBUTION.json'),JSON.stringify(old,null,2)+'\n');
// Remove only the redundant staging copy after every replacement pin is established.
const obsolete=path.join(stage,'native/bin/psc1_independent_checker');assert.ok(obsolete.startsWith(stage+path.sep));fs.unlinkSync(obsolete);
meta.files=[...new Set([...meta.files,'KERNEL_DISTRIBUTION.json'])];meta.exports={...meta.exports,'./kernel':'./host-tools/kernel-toolchain.mjs','./kernel-metadata':'./KERNEL_DISTRIBUTION.json'};meta.proofscript.kernelPackages=old.kernelPackages;
fs.writeFileSync(path.join(stage,'package.json'),JSON.stringify(meta,null,2)+'\n');
const lockPath=path.join(stage,'npm-shrinkwrap.json');assert.ok(fs.existsSync(lockPath));const lock=JSON.parse(fs.readFileSync(lockPath,'utf8'));lock.packages[''].dependencies=meta.dependencies;lock.packages[''].bundleDependencies=meta.bundledDependencies;
for(const p of Object.values(providers))lock.packages['node_modules/'+p.package]={version:'4.35.0',inBundle:true,license:'UNLICENSED',engines:{node:'>=22.23.3'}};
fs.writeFileSync(lockPath,JSON.stringify(lock,null,2)+'\n');
fs.appendFileSync(path.join(stage,'README.md'),'\nCompatible independent Lean4.35.0 native and Emscripten linear-memory Wasm kernel packages are bundled. No kernel install-time SDK/download/build is needed. psc kernel --identity; psc kernel check admissions.json --provider both; psc kernel check-source Main.ps --provider both. psc generated build Main.ps --engine ts --kernel both --out dist/generated checks the identical captured admission graph with both kernels before publication. Native admission remains mandatory. This integrated core candidate retains its Linux x64/glibc platform scope; the kernel packages have separate five-platform qualification. No final cross-platform compiler release is claimed.\n');
const tarballs=path.join(out,'tarballs');fs.mkdirSync(tarballs);const packed=JSON.parse(run('npm',['pack',stage,'--ignore-scripts','--json','--pack-destination',tarballs]));assert.equal(packed.length,1);const tar=path.join(tarballs,packed[0].filename),b=fs.readFileSync(tar);
for(const [target,p]of Object.entries(inputs.core.optional||{})){const file=path.join(archives.core,p.file);assert.equal(sha256(fs.readFileSync(file)),p.sha256);fs.copyFileSync(file,path.join(tarballs,path.basename(file)));}
const receipt={schema:'psc1-integrated-kernel-package/1',sourceCommit:process.env.GITHUB_SHA,status:'assembled-not-yet-qualified',compilerSourceClosureDigest:old.sharedSourceClosureDigest,kernelSourceClosureDigest:distribution.sourceClosureDigest,tarball:path.basename(tar),sha256:sha256(b),bytes:b.length,kernelVersions:{native:'4.35.0',wasm:'4.35.0'},wasmMemoryModel:'linear',qualifiedInputs:inputs,allFourEngineSelfHostQualified:true,allFourEngineReleaseQualified:false,corePlatformScope:distribution.corePlatformScope};
fs.writeFileSync(path.join(out,'package-receipt.json'),JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_KERNEL435_CORE_PACKAGE: '+JSON.stringify(receipt));
