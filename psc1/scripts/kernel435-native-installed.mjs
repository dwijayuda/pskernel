// Test the packed public API in private local/global installs, without a Lean SDK.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import assert from 'node:assert/strict';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';import {pathToFileURL} from 'node:url';import {fixtures} from './kernel435-fixtures.mjs';
const tar=path.resolve(process.argv[2]),tmp=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-native-kernel-install-')),sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const candidates=[process.env.npm_execpath,path.join(path.dirname(process.execPath),'node_modules/npm/bin/npm-cli.js'),path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js')].filter(Boolean),npm=candidates.find(fs.existsSync);assert.ok(npm,'npm JavaScript entry point required');
const env={...process.env,PATH:path.dirname(process.execPath),npm_config_cache:path.join(tmp,'cache'),npm_config_registry:'http://127.0.0.1:9',npm_config_audit:'false',npm_config_fund:'false'};
for(const k of ['LEAN_PATH','ELAN_TOOLCHAIN','LD_LIBRARY_PATH','DYLD_LIBRARY_PATH','PSC_LEAN_KERNEL_PROVIDER_BIN'])delete env[k];
function run(args){const r=spawnSync(process.execPath,[npm,...args],{cwd:tmp,env,encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,(r.stdout||'')+(r.stderr||''));return r.stdout;}
const observations=[];
for(const kind of ['local','global']){
 const prefix=path.join(tmp,kind);fs.mkdirSync(prefix);if(kind==='local')fs.writeFileSync(path.join(prefix,'package.json'),'{"private":true}');
 run(['install',...(kind==='global'?['--global']:[]),'--prefix',prefix,'--offline','--ignore-scripts','--no-audit','--no-fund',tar]);
 const packageRoot=path.join(prefix,kind==='global'&&process.platform!=='win32'?'lib/node_modules':'node_modules','@proofscript/pskernel-lean');
 const metadata=JSON.parse(fs.readFileSync(path.join(packageRoot,'package.json'),'utf8'));assert.equal(metadata.version,'4.35.0');assert.ok(!metadata.dependencies);
 const module=await import(pathToFileURL(path.join(packageRoot,'index.mjs')).href),handle=await module.createKernel({env,allowSourceCheckoutFallback:false,timeoutMs:120000});
 assert.equal(handle.metadata.leanVersion,'4.35.0');assert.equal(handle.metadata.profile,'lean4.35-core');assert.ok(Object.isFrozen(handle));
 for(const f of fixtures){const r=await handle.checkCanonicalAdmissions(f.input);assert.equal(r.accepted,f.accepted,f.id);if(f.errorKind)assert.equal(r.errorKind,f.errorKind,f.id);assert.deepEqual(module.checkCanonicalAdmissions(f.input,{env,allowSourceCheckoutFallback:false,timeoutMs:120000}),r);observations.push({install:kind,id:f.id,accepted:r.accepted,errorKind:r.errorKind});}
 await assert.rejects(module.createKernel({timeoutMs:0}));assert.throws(()=>module.checkCanonicalAdmissions({}));
 const manifest=JSON.parse(fs.readFileSync(path.join(packageRoot,'PREBUILT_MANIFEST.json'),'utf8')),target=process.platform+'-'+process.arch,entry=manifest.targets[target];assert.ok(entry);const binary=path.join(packageRoot,entry.path),bytes=fs.readFileSync(binary);assert.equal(sha(bytes),entry.sha256);assert.ok(bytes.length<7000000);
 // Mutating an installed binary must fail before it starts; restore exact bytes afterward.
 const changed=Buffer.from(bytes);changed[changed.length-1]^=1;fs.writeFileSync(binary,changed);
 try{assert.throws(()=>module.checkCanonicalAdmissions(fixtures[0].input,{env,allowSourceCheckoutFallback:false}),/checksum mismatch/);}finally{fs.writeFileSync(binary,bytes);}
 assert.equal(module.checkCanonicalAdmissions(fixtures[0].input,{env,allowSourceCheckoutFallback:false}).accepted,true);
}
const report={schema:'psc1-kernel435-native-installed/1',sourceCommit:process.env.GITHUB_SHA,status:'passed',target:process.platform+'-'+process.arch,tarballSha256:sha(fs.readFileSync(tar)),localAndGlobal:true,offline:true,installScriptsDisabled:true,noLeanSdkOnExecutionPath:true,apiCases:observations.length,syncAndAsync:true,tamperRefusal:true,observations};
fs.mkdirSync('dist/kernel435-installed',{recursive:true});fs.writeFileSync('dist/kernel435-installed/'+report.target+'.json',JSON.stringify(report,null,2)+'\n');console.log('PSC1_KERNEL435_NATIVE_INSTALLED: '+JSON.stringify(report));
