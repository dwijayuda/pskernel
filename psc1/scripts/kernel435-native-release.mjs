import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import crypto from 'node:crypto';import os from 'node:os';import {spawnSync} from 'node:child_process';
const root=process.cwd(),suffix=process.platform==='win32'?'.exe':'',binary=path.resolve('packages/pskernel-lean/.lake/build/bin/psc2_lean_kernel_provider'+suffix),reference=path.resolve('.lake/build/bin/psc1_independent_checker'+suffix);
const run=(exe,args,opts={})=>{const r=spawnSync(exe,args,{encoding:'utf8',timeout:120000,maxBuffer:32*1024*1024,...opts});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,(r.stdout||'')+(r.stderr||''));return r.stdout;};
const expected=process.env.PSC1_RELEASE_TARGET;assert.equal(process.platform+'-'+process.arch,expected,'release runner architecture');
let stripped=false;
if(process.platform==='darwin'){run('/usr/bin/strip',['-S','-x',binary]);run('/usr/bin/codesign',['--force','--sign','-',binary]);stripped=true;}
else if(process.platform==='win32'){
 const prefix=run('lean',['--print-prefix']).trim(),candidates=[path.join(prefix,'bin/llvm-strip.exe'),path.join(process.env.ProgramFiles||'C:\\Program Files','LLVM/bin/llvm-strip.exe'),'llvm-strip','strip'];
 const tool=candidates.find(p=>{const r=spawnSync(p,['--version'],{encoding:'utf8',timeout:10000});return !r.error&&r.status===0;});
 if(tool){run(tool,['--strip-unneeded',binary]);stripped=true;}
}
assert.ok(fs.statSync(binary).size<7000000,'native provider must be below7000000 uncompressed bytes');
run(process.execPath,['scripts/kernel435-differential.mjs',reference,binary]);
const standalone=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-kernel435-')),copied=path.join(standalone,path.basename(binary));fs.copyFileSync(binary,copied);if(process.platform!=='win32')fs.chmodSync(copied,0o755);
const cleanEnv={...process.env};for(const key of ['LD_LIBRARY_PATH','DYLD_LIBRARY_PATH','LEAN_PATH','ELAN_TOOLCHAIN'])delete cleanEnv[key];
cleanEnv.PATH=process.platform==='win32'?[path.join(process.env.SystemRoot||'C:\\Windows','System32'),path.dirname(process.execPath)].join(path.delimiter):'/usr/bin:/bin';
const health=JSON.parse(run(copied,['--health'],{cwd:standalone,env:cleanEnv}));assert.equal(health.leanVersion,'4.35.0');assert.equal(health.status,'ok');
const from=path.resolve('.lake/build'),to=path.resolve('.lake/build.hidden-release');assert.ok(from.startsWith(root+path.sep)&&to.startsWith(root+path.sep));fs.renameSync(from,to);
try{assert.equal(JSON.parse(run(copied,['--health'],{cwd:standalone,env:cleanEnv})).status,'ok');}finally{fs.renameSync(to,from);}
fs.mkdirSync('dist/kernel435',{recursive:true});fs.copyFileSync(binary,path.join('dist/kernel435',path.basename(binary)));
const b=fs.readFileSync(binary),receipt={schema:'psc1-kernel435-native-release/1',sourceCommit:process.env.GITHUB_SHA,target:expected,platform:process.platform,arch:process.arch,bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex'),under7000000Bytes:true,stripped,standalone:true,noLeanSdkOnExecutionPath:true,nativeKernelVersion:'4.35.0',nativeKernelCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',signature:process.platform==='darwin'?'ad-hoc':'unsigned',scope:'native platform kernel qualification; full npm toolchain qualification is separate'};
fs.writeFileSync('dist/kernel435/native-size-'+process.arch+'.json',JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_KERNEL435_NATIVE_RELEASE: '+JSON.stringify(receipt));
