// Public typing and genuine callback transport through the qualified installed root.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{spawnSync}from'node:child_process';import{pathToFileURL}from'node:url';
import{fixture}from'./psc1-modular-fixture.mjs';
const f=fixture({allProviders:true}),records=[],negatives=[],typeConsumers=[];
const inputCommit=process.env.PSC1_MODULAR_INPUT_COMMIT;
const runtime=path.basename(f.runtime).startsWith('bun')?'bun':'node';
const out=path.resolve('dist/modular-toolchain');
const run=path.join(f.directory,'io-build.mjs');
fs.writeFileSync(run,"import{build}from'proofscript';console.log(JSON.stringify(build(JSON.parse(process.argv[2]))));");
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
   assert.notEqual(rejected.status,0);assert.match(rejected.stderr,/PSC1_IO_DISPATCHER_ABI_TARGET_UNSUPPORTED/);
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
 const report={schema:'psc1-modular-installed-io-types/1',status:'passed',testedCommit:process.env.GITHUB_SHA,inputCommit,
  runtime,records,negatives,typeConsumers,defaultKernel:'wasm',fullModularSelfHosting:false};
 fs.writeFileSync(path.join(out,'io-types-'+runtime+'.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_MODULAR_IO_TYPES '+JSON.stringify(report));
}finally{fs.rmSync(f.directory,{recursive:true,force:true});}
