// Execute only in GitHub Actions Linux; tests the exact packed artifact.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {resolveTypeScriptCli,typeScriptProfileArgs} from './typescript-cli.mjs';
assert.equal(process.platform,'linux');assert.equal(process.env.GITHUB_ACTIONS,'true');
const dir='dist/pskernel-min/usable',build=JSON.parse(fs.readFileSync(path.join(dir,'build-receipt.json')));
assert.equal(build.head,process.env.GITHUB_SHA);
const tarball=path.resolve(build.tarball),sha=b=>crypto.createHash('sha256').update(b).digest('hex');
assert.equal(sha(fs.readFileSync(tarball)),build.sha256);
const root=fs.mkdtempSync(path.join(os.tmpdir(),'pskernel-min usability '));
const local=path.join(root,'local'),global=path.join(root,'global');
for(const dir of [local,global])fs.mkdirSync(dir,{recursive:true});
function run(command,args,{input,cwd,env,expected=0,timeout=240000}={}){
 const r=spawnSync(command,args,{input,cwd,env,encoding:'utf8',timeout,maxBuffer:8*1024*1024});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,expected,r.stdout+'\n'+r.stderr);return r;
}
const offline={...process.env,npm_config_offline:'true',npm_config_registry:'http://127.0.0.1:9',npm_config_audit:'false',npm_config_fund:'false'};
run('npm',['install','--offline','--ignore-scripts','--no-audit','--no-fund','--prefix',local,tarball],{env:offline});
run('npm',['install','--global','--offline','--ignore-scripts','--no-audit','--no-fund','--prefix',global,tarball],{env:offline});
const packageDir=path.join(local,'node_modules/@proofscript/pskernel-min');
const globalDir=path.join(global,'lib/node_modules/@proofscript/pskernel-min');
const installed=JSON.parse(fs.readFileSync(path.join(packageDir,'package.json')));
assert.equal(installed.private,true);assert.equal(installed.dependencies,undefined);assert.equal(installed.scripts,undefined);
const manifest=JSON.parse(fs.readFileSync(path.join(packageDir,'manifest.json')));
for(const item of manifest.files)for(const parent of [packageDir,globalDir]){
 const bytes=fs.readFileSync(path.join(parent,item.path));assert.equal(bytes.length,item.bytes);assert.equal(sha(bytes),item.sha256);
}
const api=await import(pathToFileURL(path.join(packageDir,'index.mjs')).href);
assert.equal(api.metadata.fullCompilerSupported,false);assert.equal(api.metadata.productionDefault,false);
assert.equal(api.metadata.generatedCodePreservation,'not-proved');
const generated=await import(pathToFileURL(path.join(packageDir,'runtime/kernel.js')).href);
assert.equal(Object.hasOwn(generated,'psMinRegCoreCandidate'),false,'no test-vector declaration shipped');
const cases=JSON.parse(fs.readFileSync('scripts/minkernel-regular-ingress-cases.json'));
const observations=[];
for(const c of cases){
 const result=api.checkBytes(new Uint8Array(Buffer.from(c.source)));
 assert.equal(result.accepted,c.expected,c.id);assert.equal(result.delegated,false);assert.equal(Object.isFrozen(result),true);
 assert.doesNotThrow(()=>JSON.stringify(result));observations.push({id:c.id,accepted:result.accepted,code:result.code});
}
const forged=JSON.parse(cases.find(c=>c.id==='nat-definition').source);
forged.accepted=true;forged.kernel='lean-native';forged.canonicalBridgeQualified=true;
assert.equal(api.checkBytes(new Uint8Array(Buffer.from(JSON.stringify(forged)))).accepted,false);
let touched=0;const sample=new Uint8Array(Buffer.from(cases.find(c=>c.id==='nat-definition').source));
const hostile=[Buffer.from(sample),Array.from(sample),new Proxy(sample,{get(){touched++;throw Error('get');}}),
 new(class extends Uint8Array{})(sample),new DataView(sample.buffer),{get length(){touched++;throw Error('get');}}];
if(typeof SharedArrayBuffer==='function')hostile.push(new Uint8Array(new SharedArrayBuffer(1)));
for(const value of hostile){const r=api.checkBytes(value);assert.equal(r.accepted,false);assert.equal(r.delegated,false);}
assert.equal(touched,0);
const own=new Uint8Array(sample);Object.defineProperty(own,'length',{get(){touched++;throw Error('get');}});
Object.defineProperty(own,Symbol.iterator,{get(){touched++;throw Error('get');}});
assert.equal(api.checkBytes(own).accepted,true);assert.equal(touched,0);
const bin=path.join(local,'node_modules/.bin/pskernel-min'),globalBin=path.join(global,'bin/pskernel-min');
const example=path.join(packageDir,'examples/nat-definition.json');
const cli=(args,options={})=>JSON.parse(run(bin,args,options).stdout);
const accepted=cli(['check',example]);assert.equal(accepted.accepted,true);assert.equal(accepted.removedTerminalLF,false);
assert.equal(accepted.input.sha256,accepted.checked.sha256);
assert.equal(JSON.parse(run(globalBin,['check',example]).stdout).accepted,true);
const info=cli(['info']);assert.equal(info.sourceCommit,build.head);assert.equal(info.workerOldSpaceMiB,256);
assert.equal(info.workerTimeoutMs,120000);assert.equal(cli(['examples']).examples.length,3);
run(bin,['--help']);assert.equal(run(bin,['--version']).stdout.trim(),installed.version);
assert.equal(cli(['check',path.join(packageDir,'examples/negative-self.json')],{expected:1}).accepted,false);
const exact=fs.readFileSync(example),framed=Buffer.concat([exact,Buffer.from('\n')]);
assert.equal(cli(['check','-'],{input:exact}).accepted,true);
assert.equal(cli(['check','-'],{input:framed,expected:1}).code,'PSC1_MIN_CORE_ASCII_PROFILE');
const adapted=cli(['check','-','--transport-lf'],{input:framed});
assert.equal(adapted.accepted,true);assert.equal(adapted.removedTerminalLF,true);
assert.equal(adapted.input.byteLength,adapted.checked.byteLength+1);assert.equal(adapted.checked.sha256,sha(exact));
assert.equal(cli(['check','-','--transport-lf'],{input:Buffer.concat([framed,Buffer.from('\n')]),expected:1}).accepted,false);
assert.equal(cli(['check','-'],{input:Buffer.from([255]),expected:1}).accepted,false);
assert.equal(cli(['check','-'],{input:Buffer.alloc(2*1024*1024+1),expected:1}).code,'PSC1_MIN_CORE_BYTE_BUDGET');
const oversized=path.join(root,'oversized.json');fs.writeFileSync(oversized,Buffer.alloc(2*1024*1024+1));
assert.equal(cli(['check',oversized],{expected:1}).code,'PSC1_MIN_CORE_BYTE_BUDGET');
assert.equal(cli(['check',path.join(root,'missing')],{expected:2}).code,'PSC1_MIN_CLI_IO');
assert.equal(cli(['check',root],{expected:2}).code,'PSC1_MIN_CLI_IO');
const fifo=path.join(root,'fifo');run('mkfifo',[fifo]);assert.equal(cli(['check',fifo],{expected:2,timeout:5000}).code,'PSC1_MIN_CLI_IO');
assert.equal(cli(['check',example,'--provider=lean'],{expected:2}).code,'PSC1_MIN_CLI_USAGE');
const noTools={...process.env,PATH:''};
assert.equal(JSON.parse(run(process.execPath,[path.join(packageDir,'cli.mjs'),'check',example],{env:noTools}).stdout).accepted,true);
const consumer=path.join(local,'consumer.mts');
fs.writeFileSync(consumer,"import {checkBytes,metadata,type CheckResult} from '@proofscript/pskernel-min';\nconst r:CheckResult=checkBytes(new Uint8Array());\nconst neverPromoted:false=metadata.fullCompilerSupported;\nconsole.log(r.code,neverPromoted);\n");
run(process.execPath,[resolveTypeScriptCli(),...typeScriptProfileArgs([consumer,'--target','ES2022','--module','NodeNext','--moduleResolution','NodeNext','--strict','--noEmit','--pretty','false'])]);
const packet=path.resolve(dir,'runtime.canonical.admissions.json');
const full=cli(['check',packet],{timeout:150000});assert.equal(full.accepted,true);assert.equal(full.delegated,false);
assert.equal(full.checked.sha256,build.manifest.metadata.runtimePacket.sha256);
const sdkCode="import fs from 'node:fs';import {checkBytes} from "+JSON.stringify(pathToFileURL(path.join(packageDir,'index.mjs')).href)+";const r=checkBytes(new Uint8Array(fs.readFileSync("+JSON.stringify(packet)+")));console.log(JSON.stringify({...r,resourceUsage:process.resourceUsage()}));";
const fullSdk=JSON.parse(run(process.execPath,['--max-old-space-size=256','--input-type=module','-e',sdkCode],{timeout:150000}).stdout);
assert.equal(fullSdk.accepted,true);assert.equal(fullSdk.delegated,false);
const compilerPacket=path.resolve('dist/pskernel-min/closure/compiler-admissions.json');
assert.equal(cli(['check',compilerPacket],{expected:1}).code,'PSC1_MIN_CORE_BYTE_BUDGET');
assert.equal(sha(fs.readFileSync(tarball)),build.sha256,'tested tarball bytes immutable');
const receipt={schema:'pskernel-min/usable-qualification/1',status:'passed',head:build.head,platform:process.platform,node:process.version,
 package:{name:installed.name,version:installed.version,tarball:path.basename(tarball),bytes:build.bytes,sha256:build.sha256},
 sourceModules:10,sourceBytes:build.manifest.metadata.sourceBytes,nativeAndOfficialCorpus:'same-source portability job required before this step',
 sdkCases:observations,hostileCases:hostile.length,localOfflineInstalled:true,globalOfflineInstalled:true,
 installedFilesIdentical:true,strictTypeConsumer:true,noExternalToolsRuntime:true,cliExitCodes:[0,1,2],explicitLfFraming:true,
 fifoRefusedWithoutBlocking:true,completeRuntime:{cli:full,sdk:fullSdk},currentCompiler:{supported:false,code:'PSC1_MIN_CORE_BYTE_BUDGET',qualifiedModules:0,totalModules:124},
 generatedCodePreservation:'not-proved',productionDefault:false,fullCompilerSupported:false,
 boundary:'Usable bounded R4B checker; source consistency proof and finite installed/runtime validation, with compiler/engine assumptions. Full compiler support remains an open workstream.'};
fs.writeFileSync(path.join(dir,'qualification.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSKERNEL_MIN_USABLE_PASS '+JSON.stringify(receipt));
