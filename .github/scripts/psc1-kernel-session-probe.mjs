// Experimental execution adapter only. Exact official launcher/Wasm bytes are unchanged.
import fs from 'node:fs';import path from 'node:path';import assert from'node:assert/strict';
import vm from'node:vm';import{createRequire}from'node:module';import{pathToFileURL}from'node:url';import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
import{fixtures}from'../../psc1/scripts/kernel435-fixtures.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_DEVELOPMENT_QUALIFICATION_2026-10-29.json'));
const archive=await readQualifiedArtifact(q.qualification,'dist/kernel-session-input'),tar=path.join(archive,'modular-toolchain/tarballs',q.package.tarball);
assert.equal(sha256(fs.readFileSync(tar)),q.package.sha256);
const directory=path.resolve('dist/kernel-session-root');fs.mkdirSync(directory,{recursive:true});
const extraction=spawnSync('tar',['xzf',tar,'-C',directory],{encoding:'utf8',timeout:120000});assert.equal(extraction.status,0,extraction.stderr);
const pkg=path.join(directory,'package/node_modules/@proofscript/pskernel-lean-wasm/dist/implementation');
const original=await import(pathToFileURL(path.join(pkg,'index.mjs')));
const launcher=path.join(pkg,'wasm/pskernel-lean.cjs'),wasm=fs.readFileSync(path.join(pkg,'wasm/pskernel-lean.wasm')),code=fs.readFileSync(launcher,'utf8');
const compilation=performance.now(),compiled=new WebAssembly.Module(wasm),script=new vm.Script(code,{filename:launcher});
const compileMs=performance.now()-compilation;
async function execute(input,command='--check'){
 const bytes=Buffer.from(input??''),out=[],err=[];let cursor=0;
 const append=(a,c)=>{if(c!==null){if(a.length>=33554432)throw Error('KERNEL_PROBE_OUTPUT_LIMIT');a.push(c);}};
 const processView={argv:[process.execPath,launcher,command],env:{...process.env},platform:process.platform,versions:process.versions,version:process.version,hrtime:process.hrtime,cwd:()=>process.cwd(),exitCode:0};
 const Module={arguments:[command],stdin:()=>cursor<bytes.length?bytes[cursor++]:null,stdout:c=>append(out,c),stderr:c=>append(err,c),
  instantiateWasm(imports,success){const instance=new WebAssembly.Instance(compiled,imports);success(instance);return instance.exports;}};
 const context=vm.createContext({Module,require:createRequire(launcher),module:{exports:{}},__filename:launcher,__dirname:path.dirname(launcher),process:processView,console,Buffer,TextDecoder,TextEncoder,performance,setTimeout,clearTimeout});
 try{await script.runInContext(context,{timeout:120000});}catch(error){console.error('PSC1_KERNEL_PROBE_FAILURE '+String(error?.message||error));throw new Error('PSC1_KERNEL_PROBE:'+String(error?.message||error));}
 assert.equal(processView.exitCode,0,Buffer.from(err).toString());
 const text=Buffer.from(out).toString('utf8').trim();assert.ok(text.length,text+Buffer.from(err).toString());
 return JSON.parse(text);
}
const results=[];
for(const fixture of [...fixtures,...fixtures.slice().reverse()]){
 const start=performance.now(),actual=await execute(fixture.input),elapsedMs=performance.now()-start;
 const expected=await original.checkCanonicalAdmissions(fixture.input,{timeoutMs:120000,maxBuffer:33554432});
 assert.deepEqual(actual,expected,fixture.id);assert.equal(actual.accepted,fixture.accepted,fixture.id);
 results.push({id:fixture.id,accepted:actual.accepted,elapsedMs});
}
const health=await execute(undefined,'--health');assert.equal(health.status,'ok');
fs.mkdirSync('dist/kernel-session-results',{recursive:true});
const report={schema:'psc1-kernel-session-probe/1',commit:process.env.GITHUB_SHA,status:'passed',launcherSha256:sha256(code),wasmSha256:sha256(wasm),compileMs,freshInstancePerRequest:true,officialKernelUnchanged:true,health,results};
fs.writeFileSync('dist/kernel-session-results/probe.json',JSON.stringify(report,null,2)+'\n');console.log('PSC1_KERNEL_SESSION_PROBE '+JSON.stringify(report));
