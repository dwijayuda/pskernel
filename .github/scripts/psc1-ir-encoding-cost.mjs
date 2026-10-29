// Isolate legacy IR serialization after the real unchanged generated pipeline.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';import{pathToFileURL}from'node:url';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_SEMANTIC_REUSE_QUALIFICATION_2026-10-29.json')),archive=await readQualifiedArtifact(q.qualification,'dist/ir-cost-input');
const tar=path.join(archive,'modular-toolchain/tarballs',q.package.tarball);assert.equal(sha256(fs.readFileSync(tar)),q.package.sha256);
const sources=[],seen=new Set(),active=new Set();
function visit(module){
 if(seen.has(module))return;assert.match(module,/^[A-Za-z_][A-Za-z0-9_.]*$/);assert.ok(!active.has(module));
 const relative=module.replaceAll('.','/')+'.lean',matches=['test/applications','stdlib'].map(root=>path.join(root,relative)).filter(fs.existsSync);assert.equal(matches.length,1,module);
 const text=fs.readFileSync(matches[0],'utf8');active.add(module);
 for(const m of text.matchAll(/^import\s+(.+)$/gm))for(const dependency of m[1].trim().split(/\s+/))visit(dependency);
 active.delete(module);seen.add(module);sources.push({module,kind:'lean',text});
}
visit('PracticalCli.Run');
const expected=JSON.parse(fs.readFileSync('docs/PSC1_APPLICATION_EXECUTION_CONTRACT.json')).cases.find(c=>c.id==='unicode-records');assert.ok(expected);

const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-ir-cost-'));
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 const npm=path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),install=spawnSync(process.execPath,[npm,'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',tar],{cwd:directory,encoding:'utf8',timeout:120000});assert.equal(install.status,0,install.stdout+install.stderr);
 const root=path.join(directory,'node_modules/proofscript'),host=path.join(root,'node_modules/@proofscript/compiler/dist/host/host-tools');
 const load=(owner,name)=>import(pathToFileURL(path.join(root,'node_modules/@proofscript',owner,'dist/js/generated',name+'.mjs')));
 const [service,api,json,ir,encoder,emitter,protocol]=await Promise.all([load('compiler','Ps.Compiler.Service'),load('compiler','Ps.Compiler.Api'),load('bridge','Ps.Bridge.Json'),load('compiler-ir','Ps.CompilerIr.Validate'),load('compiler-ir','Ps.CompilerIr.Encode'),load('backend-js','Ps.BackendJs.Emit'),import(pathToFileURL(path.join(host,'compiler-host-protocol.mjs')))]);
 const fields=v=>v?.['$ps$fields']??v,tag=v=>v?.['$ps$tag'],unwrap=r=>{assert.equal(tag(r),'ok',String(fields(r)?.error?.phase)+':'+fields(r)?.error?.code);return fields(r).value;},nil=()=>({'$ps$tag':'nil','$ps$fields':{}}),cons=(head,tail)=>({'$ps$tag':'cons','$ps$fields':{head,tail}});
 const requestFields=['psc1-compiler-service/2','ir-cost',protocol.compilerSourceClosureDigest(sources),'lean','ordinary-checked','PracticalCli.Run',sources.map(s=>[s.module,s.text]),'io-dispatcher'];
 const selected=unwrap(service.Ps_Internal_CompilerService_decodeOutputRequestFields(fields(unwrap(json.psJsonParse(JSON.stringify(requestFields)))).values)),request=selected.fst;
 const timings={},time=(name,fn)=>{const start=performance.now(),v=fn();timings[name]=performance.now()-start;return v;};
 const captured=time('captureMs',()=>unwrap(service.Ps_Internal_CompilerService_captureWorker(request,request.sources)({state:api.psCompilerPreparationStart(request.kind),seen:nil(),graphRev:nil(),originsRev:nil(),entry:{'$ps$tag':'none','$ps$fields':{}}})));
 unwrap(service.Ps_Internal_CompilerService_exactClosureWorker(captured.graphRev)(cons(request.entry,nil())));
 const work=time('prepareMs',()=>unwrap(service.Ps_Internal_CompilerService_prepare(request,captured)));time('strictOriginalIrMs',()=>unwrap(ir.psStrictValidateModule(work.raw)));
 let closed;
 const wire=time('pipelineMs',()=>unwrap(service.Ps_Internal_CompilerService_compilePreparedWithOutputAbi(selected.snd,{'$ps$tag':'js','$ps$fields':{}},module=>names=>{closed=module;return time('printMs',()=>emitter.Ps_Internal_JsCompilerService_emit(module,names));},request,captured,fields(captured.entry).value,work)));
 const candidate=JSON.parse(wire);assert.equal(candidate.status,'candidate');
 const original=time('isolatedOriginalEncodingMs',()=>unwrap(encoder.psIrEncodeModule(work.raw))),specialized=time('isolatedSpecializedEncodingMs',()=>unwrap(encoder.psIrEncodeModule(closed.raw)));
 assert.deepEqual(JSON.parse(original),candidate.originalIr);assert.deepEqual(JSON.parse(specialized),candidate.specializedIr);
 const nativeOriginal=time('nativeOriginalStringifyMs',()=>JSON.stringify(candidate.originalIr)),nativeSpecialized=time('nativeSpecializedStringifyMs',()=>JSON.stringify(candidate.specializedIr));
 const report={schema:'psc1-ir-encoding-cost/1',commit:process.env.GITHUB_SHA,packageSha256:q.package.sha256,status:'passed',scope:'isolated encoders after actual generated pipeline; warmed JIT; observational, not additive stage attribution or new qualification',timings,bytes:{original:Buffer.byteLength(original),specialized:Buffer.byteLength(specialized),wire:Buffer.byteLength(wire),printed:Buffer.byteLength(candidate.source)},nativeBytes:{original:Buffer.byteLength(nativeOriginal),specialized:Buffer.byteLength(nativeSpecialized)}};
 fs.mkdirSync('dist/ir-cost',{recursive:true});fs.writeFileSync('dist/ir-cost/report.json',JSON.stringify(report,null,2)+'\n');console.log('PSC1_IR_ENCODING_COST '+JSON.stringify(report));
}finally{fs.rmSync(directory,{recursive:true,force:true});}
