// Each variant runs under the existing 240s/4GiB/8MiB supervisor.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{pathToFileURL}from'node:url';import{spawnSync}from'node:child_process';
import{checkCanonicalAdmissions}from'proofscript';import{createTypedIo}from'proofscript/io';
const [variant,graphRoot,manifestFile,manifestSha,repo,fixtureFile]=process.argv.slice(2);
const loadFile=file=>import(pathToFileURL(path.join(repo,file)));
const{loadExecutableCompiler}=await loadFile('host-tools/executable/loader.mjs');
const{loadPreparedEngine}=await loadFile('host-tools/prepared-engine.mjs');
const{createNativeWireQuoter}=await loadFile('host-tools/wire-quote.mjs');
const{compilerSourceClosureDigest,createCompilerHostSession}=await loadFile('host-tools/compiler-host-protocol.mjs');
const{createHash}=await import('node:crypto'),sha=value=>createHash('sha256').update(value).digest('hex');
const manifest=JSON.parse(fs.readFileSync(manifestFile));
const load=name=>{const matches=manifest.files.filter(row=>row.path.endsWith('/dist/'+variant+'/generated/'+name+'.mjs'));assert.equal(matches.length,1,name);return import(pathToFileURL(path.join(graphRoot,matches[0].path)));};
const json=await load('Ps.Bridge.Json'),transport=await load('Ps.Bridge.CompilerHost'),service=await load('Ps.Compiler.Service');
assert.equal(typeof service.Ps_Internal_CompilerService_compilePreparedWithQuote,'function');
const native=createNativeWireQuoter(json.psJsonQuote),quote= native.quoteString;
let scalarCount=0,chunks=0,chunk=[];
const compare=value=>assert.equal(quote(value),json.psJsonQuote(value),variant+':quote');
for(let cp=0;cp<=0x10ffff;cp++){if(cp>=0xd800&&cp<=0xdfff)continue;chunk.push(String.fromCodePoint(cp));scalarCount++;if(chunk.length===4096){compare(chunk.join(''));chunks++;chunk=[];}}
if(chunk.length){compare(chunk.join(''));chunks++;}assert.equal(scalarCount,1112064);
for(const value of['','plain','"\\\b\f\n\r\t\0','a/b','\u2028\u2029','😀','\\'.repeat(8192),'"'.repeat(8192)])compare(value);
const fallbackBefore=native.metrics().fallbackCalls;
for(const value of['\ud800','\udc00','x\ud800y','\udc00\ud800']){
 const capture=fn=>{try{return{value:fn(value)}}catch(error){return{error:String(error.message)}}};
 assert.deepEqual(capture(quote),capture(json.psJsonQuote));
}
assert.equal(native.metrics().fallbackCalls-fallbackBefore,4);assert.ok(native.metrics().nativeCalls>=chunks);
const legacy=await loadExecutableCompiler({root:graphRoot,manifestFile,manifestSha256:manifestSha,variant});
const prepared=await loadPreparedEngine({root:graphRoot,manifestFile,manifestSha256:manifestSha,variant,outputs:true});
const root=path.dirname(new URL(import.meta.resolve('proofscript/package.json')).pathname);
const oldHost=path.join(root,'node_modules/@proofscript/compiler/dist/host/host-tools');
const{loadDistribution,resolveEngine}=await import(pathToFileURL(path.join(oldHost,'installed-engine-resolver.mjs')));
const old=resolveEngine(variant,loadDistribution()),original=await import(pathToFileURL(old.candidate.path));
let serial=0;const rows=[],checker=path.join(repo,'.lake/build/bin/psc1_independent_checker');
const compareCandidate=(sources,target,assurance='checked',io=false)=>{
 const requestId='wire-quote-'+variant+'-'+(++serial),entry=sources.at(-1).module,digest=compilerSourceClosureDigest(sources);
 const fields=[io?'psc1-compiler-service/2':'psc1-compiler-service/1',requestId,digest,sources[0].kind,assurance,entry,sources.map(s=>[s.module,s.text]),...(io?['io-dispatcher']:[])];
 const request=JSON.stringify(['psc1-unified-compiler-service/2',target,fields]);
 let started=performance.now();const expected=legacy.candidate(request),legacyMs=performance.now()-started;
 started=performance.now();const prior=original.psCompilerServiceCandidate(request),priorMs=performance.now()-started;assert.equal(prior,expected,variant+':prior-byte-parity');
 started=performance.now();const actual=prepared.candidate(request),fastMs=performance.now()-started;assert.equal(actual,expected,variant+':native-byte-parity');
 const candidate=JSON.parse(actual),metrics=prepared.metrics();
 if(candidate.status==='candidate'){
  const receipt=createCompilerHostSession({requestId,target,sources,canonicalAdmissions:candidate.admissionRequest.admissions,checkerExecutable:checker}).admit(JSON.stringify(candidate.admissionRequest));
  assert.equal(receipt.checkerCommit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');assert.equal(receipt.admissionsDigest,sha(candidate.admissionRequest.admissions));
  assert.ok(metrics.nativeQuoteCalls>0);assert.equal(metrics.quoteFallbackCalls,0);
 }
 rows.push({kind:sources[0].kind,target,assurance,io,status:candidate.status,legacyMs,priorMs,fastMs,metrics,canonicalAdmission:candidate.status==='candidate'?sha(candidate.admissionRequest.admissions):null});
 return candidate;
};
for(const kind of['lean','ps'])for(const target of['js','ts','rust','wasm-core']){
 const candidate=compareCandidate([{module:'Main',kind,text:'def answer : Nat := 42\n'}],target);assert.equal(candidate.status,'candidate');
 if(target==='js'){const file=path.resolve(variant+'-'+kind+'.mjs');fs.writeFileSync(file,candidate.source);assert.equal((await import(pathToFileURL(file))).answer,42n);}
 if(target==='wasm-core'){const prefix='psc1-wasm-hex/1:';assert.ok(candidate.source.startsWith(prefix));assert.equal(WebAssembly.validate(Buffer.from(candidate.source.slice(prefix.length),'hex')),true);}
 if(target==='ts'){
  const file=path.resolve(variant+'-'+kind+'.mts');fs.writeFileSync(file,candidate.source);
  const config=path.resolve(variant+'-'+kind+'-tsconfig.json');
  fs.writeFileSync(config,JSON.stringify({compilerOptions:{strict:true,noEmit:true,target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',types:[],lib:['ES2022','DOM']},files:[file]}));
  const result=spawnSync(process.execPath,[path.join(repo,'../node_modules/typescript/bin/tsc'),'--project',config],{encoding:'utf8',timeout:240000});assert.equal(result.status,0,result.stdout+result.stderr);
 }
}
for(const kind of['lean','ps'])assert.equal(compareCandidate([{module:'Main',kind,text:'def answer : Nat := true\n'}],'js').status,'refused');
const fixture=JSON.parse(fs.readFileSync(fixtureFile));
for(const edit of['initial','body','comment']){
 const sources=fixture.sources.map((source,index)=>({...source,text:(index===fixture.sources.length-1&&edit!=='initial'?source.text.replace('Result.ok success => success','Result.ok success => if success then true else false'):source.text)+(index===fixture.sources.length-1?'\n-- quote '+edit+'\n':'')}));
 const candidate=compareCandidate(sources,'js','ordinary-checked',true);assert.equal(candidate.status,'candidate');
 const wasm=await checkCanonicalAdmissions(candidate.admissionRequest.admissions);assert.equal(wasm.accepted,true);
 const row=rows.at(-1);row.independentWasmAccepted=true;
 const folder=path.resolve('app-'+variant+'-'+edit);fs.mkdirSync(folder);fs.writeFileSync(path.join(folder,'input.json'),'[{"text":"A","count":2},{"text":"\\uD83D\\uDE00","count":-4}]');
 const guest=path.join(folder,'target.mjs');fs.writeFileSync(guest,candidate.source);
 const stdout=path.join(folder,'stdout.txt'),fd=fs.openSync(stdout,'w'),io=createTypedIo({abi:'psc1-node-linux-string-io/1',capabilities:['readUtf8','writeUtf8','writeLine'],required:['readUtf8','writeUtf8','writeLine'],root:folder,maxFileBytes:512,maxLineBytes:128,inputFd:0,outputFd:fd});
 try{assert.equal((await import(pathToFileURL(guest))).run(JSON.stringify(['transform','input.json','output.json']),request=>io.execute(request)),true);}
 finally{io.close();try{fs.closeSync(fd);}catch(error){if(error.code!=='EBADF')throw error;}}
 assert.equal(fs.readFileSync(path.join(folder,'output.json'),'utf8'),fixture.expected.output);assert.equal(fs.readFileSync(stdout,'utf8'),fixture.expected.stdout);row.actualApplication='passed';row.edit=edit;
}
console.log('PSC1_WIRE_QUOTE_VARIANT '+JSON.stringify({variant,status:'passed',scalarCount,chunks,unicode:native.metrics(),rows}));
