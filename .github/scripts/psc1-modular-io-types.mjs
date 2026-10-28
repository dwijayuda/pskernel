// Public typing and genuine callback transport through the qualified installed root.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{spawn,spawnSync}from'node:child_process';import{pathToFileURL}from'node:url';
import{fixture}from'./psc1-modular-fixture.mjs';
const f=fixture({allProviders:true}),records=[],negatives=[],typeConsumers=[];
const inputCommit=process.env.PSC1_MODULAR_INPUT_COMMIT;
const runtime=path.basename(f.runtime).startsWith('bun')?'bun':'node';
const out=path.resolve('dist/modular-toolchain');
let live;
const report={schema:'psc1-modular-installed-io-types/1',status:'running',testedCommit:process.env.GITHUB_SHA,inputCommit,
 runtime,records,negatives,typeConsumers,defaultKernel:'wasm',fullModularSelfHosting:false};

const run=path.join(f.directory,'io-build.mjs');
fs.writeFileSync(run,"import{build,compileCandidate}from'proofscript';const options=JSON.parse(process.argv[2]);console.log(JSON.stringify(process.argv[3]==='candidate'?compileCandidate(options):build(options))); ");
try{
 for(const engine of['js','ts'])for(const kind of['lean','ps'])for(const target of['js','ts']){
  const text=kind==='lean'?'def run (input : String) (dispatch : String -> String) : String := dispatch input\n':
   'def run(input : String, dispatch : String -> String) : String := dispatch(input)\n';
  const options={engine,target,entryModule:'Entry',assurance:'checked',outputAbi:'io-dispatcher',
   sources:[{module:'Entry',kind,text}],publicationProtocol:'portable-file',out:path.join(f.directory,engine,kind,target)};
  const started=performance.now();
  const r=JSON.parse(f.ok(f.runtime,[...f.flags,run,JSON.stringify(options)]));
  assert.equal(r.kernelProviders.join(','),'wasm');assert.equal(r.logicalAdmission,'accepted');
  const body="const m=await import("+JSON.stringify(pathToFileURL(r.runtimeArtifact).href)+");"+
   "let calls=0;const value=m.run('λ🙂',input=>{calls++;return'ok:'+input});"+
   "let trapped=false;const token=new Error('trap');try{m.run('x',()=>{calls++;throw token});}catch(error){trapped=error===token;}"+
   "if(value!=='ok:λ🙂'||!trapped||calls!==2)throw Error('IO callback semantics');console.log(JSON.stringify({value,trapped,calls}));";
  const actual=JSON.parse(f.ok(f.runtime,[...f.flags,'--input-type=module','-e',body]));
  records.push({engine,kind,target,actual,admissionsSha256:r.receipt.admissionsSha256,elapsedMs:Math.round(performance.now()-started)});
  const pointer=fs.readFileSync(path.join(options.out,'current.json'));
  if(target==='js'){
   const rejected=f.run(f.runtime,[...f.flags,run,JSON.stringify({...options,target:'wasm-core'})]);
   assert.notEqual(rejected.status,0);assert.match(rejected.stderr,/PSC1_SERVICE_COMPILER_REFUSED:public-api/);
   const candidate=JSON.parse(f.ok(f.runtime,[...f.flags,run,JSON.stringify({...options,target:'wasm-core'}),'candidate']));
   assert.equal(candidate.logicalAdmission,'not-run');assert.equal(candidate.publicationAuthority,false);
   assert.equal(candidate.candidate.status,'refused');assert.equal(candidate.candidate.phase,'public-api');
   assert.equal(candidate.candidate.code,'PSC1_IO_DISPATCHER_ABI_TARGET_UNSUPPORTED');
   assert.equal(candidate.candidate.source,undefined);
   assert.deepEqual(fs.readFileSync(path.join(options.out,'current.json')),pointer);
   negatives.push({engine,kind,target:'wasm-core',priorPreserved:true});
  }
 }
 const source=path.join(f.directory,'consumer.mts');
 fs.writeFileSync(source,[
  "import{compile,type CompileOptions,type CheckedCompilation}from'proofscript';",
  "import{readSources}from'proofscript/elab';import*as io from'proofscript/io';",
  "import*as generated from'proofscript/foundation/generated/runtime';",
  "const options:CompileOptions={entryModule:'Main',sources:readSources()};",
  "const invoke:()=>CheckedCompilation=()=>compile(options);void invoke;void io;void generated;",
  "// @ts-expect-error unsupported targets must remain statically closed",
  "compile({...options,target:'unknown-backend'});",
  "// @ts-expect-error source options cannot grant checker authority",
  "const bad:CompileOptions={...options,checkerExecutable:'/untrusted'};void bad;"
 ].join('\n'));
 const ts=f.manifest.targetConsumers.ts.dependencies[0],tsc=path.join(f.directory,'node_modules',ts.package,ts.entry);
 for(const mode of['NodeNext','Bundler']){
  const config=path.join(f.directory,mode+'.json');
  fs.writeFileSync(config,JSON.stringify({compilerOptions:{strict:true,noEmit:true,target:'ES2022',
   module:mode==='NodeNext'?'NodeNext':'ESNext',moduleResolution:mode,types:[],lib:['ES2022','DOM']},files:[source]}));
  const result=spawnSync(tsc,['--project',config],{encoding:'utf8',timeout:240000,maxBuffer:33554432});
  assert.equal(result.error,undefined);assert.equal(result.status,0,result.stdout+result.stderr);typeConsumers.push(mode);
 }
 assert.equal(records.length,8);assert.equal(negatives.length,4);
 const watchFile=path.join(f.directory,'Watch.ps'),watchOut=path.join(f.directory,'watch-ts');
 fs.writeFileSync(watchFile,'def answer : Nat := 42\n');
 const receipts=[];let stdout='',stderr='',exit;
 live=spawn(f.runtime,[...f.flags,f.cli,'build',watchFile,'--engine','ts','--out',watchOut,
  '--publication-protocol','portable-file','--watch','--diagnostics=json'],{cwd:f.directory,env:f.env,stdio:['ignore','pipe','pipe']});
 live.stdout.on('data',chunk=>{stdout+=chunk;assert.ok(stdout.length<33554432);for(;;){
  const end=stdout.indexOf('\n');if(end<0)break;const line=stdout.slice(0,end);stdout=stdout.slice(end+1);
  if(line)receipts.push(JSON.parse(line));}});
 live.stderr.on('data',chunk=>{stderr+=chunk;assert.ok(stderr.length<33554432);});
 live.on('close',(code,signal)=>{exit={code,signal};});
 async function until(predicate){
  const start=Date.now();while(!predicate()){
   if(exit)throw Error('TS watch exited: '+stderr);
   if(Date.now()-start>240000)throw Error('TS watch timeout: '+stderr);
   await new Promise(resolve=>setTimeout(resolve,20));
  }
 }
 await until(()=>receipts.length>=1);assert.equal(f.observe(receipts[0]),'42');
 fs.writeFileSync(watchFile,'def answer : Nat := 43\n');
 await until(()=>receipts.length>=2);assert.equal(f.observe(receipts[1]),'43');
 const pointer=fs.readFileSync(path.join(watchOut,'current.json'));
 fs.writeFileSync(watchFile,'def answer : Nat := true\n');
 await until(()=>stderr.includes('failed; waiting for changes'));
 assert.deepEqual(fs.readFileSync(path.join(watchOut,'current.json')),pointer);
 const stopped=Date.now();live.kill('SIGTERM');await until(()=>exit!==undefined);
 assert.equal(exit.code,143);assert.ok(Date.now()-stopped<6000);
 report.tsWatch={engine:'ts',builds:2,editedValue:'43',typingRefusalPreservedPointer:true,exit:143,stopMs:Date.now()-stopped};
 live=undefined;report.status='passed';
}catch(error){report.status='failed';report.failure=error.message;throw error;}
finally{
 if(live)live.kill('SIGTERM');
 fs.writeFileSync(path.join(out,'io-types-'+runtime+'.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_MODULAR_IO_TYPES '+JSON.stringify(report));
 fs.rmSync(f.directory,{recursive:true,force:true});
}
