// Focused installed .ps development checks; no G2/G3 or broad backend rebuild.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';
import{spawn,spawnSync}from'node:child_process';import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
import{fixtures}from'../../psc1/scripts/kernel435-fixtures.mjs';
const input=path.resolve('dist/modular-toolchain'),receipt=JSON.parse(fs.readFileSync(path.join(input,'package-receipt.json')));
const directory=fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()),'psc1-development-qualification-'));
const hash=b=>createHash('sha256').update(b).digest('hex'),npm=path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js');
const report={schema:'psc1-development-qualification/1',testedCommit:process.env.GITHUB_SHA,status:'running',package:receipt,cases:[],samples:[]};
const call=(exe,args)=>spawnSync(exe,args,{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432});
const ok=(exe,args)=>{const r=call(exe,args);assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 const ts=path.join(input,'typescript-platforms/linux-x64'),sdk=JSON.parse(fs.readFileSync(path.join(ts,'resources.json')));
 const tar=path.join(input,'tarballs',receipt.tarball);assert.equal(hash(fs.readFileSync(tar)),receipt.sha256);
 ok(process.execPath,[npm,'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',
  tar,...sdk.packages.map(p=>path.join(ts,p.tarball))]);
 const root=path.join(directory,'node_modules/proofscript'),cli=path.join(root,'dist/psc.mjs');
 const program=path.join(directory,'exercise.mjs');
 fs.writeFileSync(program,"import{build,check}from'proofscript';const o=JSON.parse(process.argv[3]);console.log(JSON.stringify(process.argv[2]==='check'?check(o):build(o)));");
 const source='def answer : Nat := 42\n';
 const invoke=(command,options)=>JSON.parse(ok(process.execPath,[program,command,JSON.stringify(options)]));
 for(const engine of['js','ts'])for(const kind of['ps','lean']){
  const options={engine,entryModule:'Main',sources:[{module:'Main',kind,text:source}]};
  const c=invoke('check',options);assert.equal(c.logicalAdmission,'accepted');assert.equal(c.target,null);assert.equal(c.targetGeneration,'not-run');assert.equal(c.irValidation,'strict-original-no-transform');
  for(const target of['js','ts','wasm-core']){
   const r=invoke('build',{...options,target,out:path.join(directory,'out',engine,kind,target)});
   assert.equal(r.logicalAdmission,'accepted');assert.equal(r.evidence,'minimal');
   assert.equal(r.receipt.admissionsSha256,c.receipt.admissionsSha256);
   const actual=ok(process.execPath,['--input-type=module','-e','let m=await import('+JSON.stringify(pathToFileURL(r.runtimeArtifact).href)+');console.log(String((m.default||m).answer));']).trim();
   assert.equal(actual,'42');
   const names=fs.readdirSync(path.dirname(r.runtimeArtifact));
   for(const name of['candidate.json','request.json','admissions.json','original-ir.json','specialized-ir.json','sources.json'])assert.ok(!names.includes(name),name);
   report.cases.push({engine,kind,target,admissionAndExecution:true,minimalEvidence:true});
  }
  const bad=call(process.execPath,[program,'check',JSON.stringify({...options,sources:[{module:'Main',kind,text:'def answer : Nat := true\n'}]})]);
  assert.notEqual(bad.status,0);report.cases.push({engine,kind,negative:'typing-refusal'});
 }
 const full=invoke('build',{entryModule:'Main',sources:[{module:'Main',kind:'ps',text:source}],target:'js',evidence:'full',out:path.join(directory,'full')});
 for(const name of['candidate.json','request.json','admissions.json','original-ir.json','specialized-ir.json','sources.json'])assert.ok(fs.existsSync(path.join(path.dirname(full.runtimeArtifact),name)));
 report.fullEvidencePreserved=true;
 fs.writeFileSync(path.join(directory,'Main.ps'),source);
 for(let repeat=0;repeat<2;repeat++)for(const [command,target]of[['check',undefined],['build','js'],['build','ts']]){
  const started=performance.now(),r=JSON.parse(ok(process.execPath,[cli,command,'Main.ps',...(target?['--target',target]:[]),...(command==='build'?['--out',path.join(directory,'timing-'+target+'-'+repeat)]:[])]));
  assert.equal(r.logicalAdmission,'accepted');report.samples.push({command,target:target||'language-only',repeat,wallMs:performance.now()-started,timings:r.timings});
 }
 fs.writeFileSync(path.join(directory,'fixtures.json'),JSON.stringify(fixtures));
 fs.writeFileSync(path.join(directory,'kernel.mjs'),"import fs from'node:fs';import assert from'node:assert/strict';import{checkCanonicalAdmissions,createIndependentKernelToolchain}from'proofscript';for(const f of JSON.parse(fs.readFileSync('fixtures.json'))){const r=await checkCanonicalAdmissions(f.input);assert.equal(r.accepted,f.accepted,f.id);}assert.equal((await createIndependentKernelToolchain()).metadata.leanVersion,'4.35.0');");
 ok(process.execPath,[path.join(directory,'kernel.mjs')]);report.kernelCases=fixtures.length;
 const warmKernelTest=path.join(directory,'warm-kernel.mjs');
 fs.writeFileSync(warmKernelTest,"import fs from'node:fs';import assert from'node:assert/strict';import{prepareWarmKernel,closeWarmKernel}from'@proofscript/compiler/warm-internal';import{warmKernel}from"+JSON.stringify(pathToFileURL(path.join(root,'node_modules/@proofscript/compiler/dist/host/host-tools/warm-kernel.mjs')).href)+";import{checkCanonicalAdmissions}from'proofscript';await prepareWarmKernel();try{const run=warmKernel();assert.equal(typeof run,'function');for(const f of JSON.parse(fs.readFileSync('fixtures.json'))){const direct=run(f.input),cold=await checkCanonicalAdmissions(f.input);assert.deepEqual(direct,cold.results.wasm,f.id);assert.equal(direct.accepted,f.accepted);}}finally{await closeWarmKernel();}");
 ok(process.execPath,[warmKernelTest]);report.warmKernelCases=fixtures.length;

 const graph=JSON.parse(fs.readFileSync(path.join(root,'dist/COMPILER_GRAPH.json'))),row=graph.files.find(r=>r.path.includes('/dist/js/generated/')&&r.path.endsWith('.mjs'));
 const file=path.join(root,'node_modules',row.path),before=fs.readFileSync(file);
 try{fs.appendFileSync(file,'\n// tampered');const r=call(process.execPath,[cli,'check','Main.ps']);assert.notEqual(r.status,0);assert.match(r.stderr,/PSC1_EXECUTABLE/);report.tamperBeforeExecution=true;}
 finally{fs.writeFileSync(file,before);}
 // Actual persistent watch: exact prefix reuse, dependency invalidation and error repair.
 const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
 const project=path.join(directory,'project');fs.mkdirSync(project);
 fs.writeFileSync(path.join(project,'Base.ps'),'def base : Nat := 40\n');
 fs.writeFileSync(path.join(project,'Middle.ps'),'import Base\ndef middle : Nat := base + 1\n');
 fs.writeFileSync(path.join(project,'Main.ps'),'import Middle\ndef answer : Nat := middle + 1\n');
 fs.writeFileSync(path.join(project,'proofscript.json'),JSON.stringify({schema:'proofscript-project/1',entryModule:'Main',
  files:[{module:'Base',path:'Base.ps'},{module:'Middle',path:'Middle.ps'},{module:'Main',path:'Main.ps'}]}));
 async function watch(command,target){
  let text='',stderr='',exit;const results=[];
  const child=spawn(process.execPath,[cli,command,'-p',path.join(project,'proofscript.json'),'--watch','--diagnostics=json',
   ...(target?['--target',target,'--out',path.join(project,'out')]:[])],{cwd:directory,stdio:['ignore','pipe','pipe']});
  child.stdout.on('data',b=>{text+=b;assert.ok(text.length<33554432);for(;;){const n=text.indexOf('\n');if(n<0)break;results.push(JSON.parse(text.slice(0,n)));text=text.slice(n+1);}});
  child.stderr.on('data',b=>{stderr+=b;assert.ok(stderr.length<33554432);});child.on('close',code=>exit=code);
  const until=async predicate=>{const start=Date.now();while(!predicate()){assert.equal(exit,undefined,stderr);assert.ok(Date.now()-start<240000,stderr);await sleep(20);}};
  const stop=async()=>{child.kill('SIGTERM');const start=Date.now();while(exit===undefined){assert.ok(Date.now()-start<5000,'watch stop deadline');await sleep(20);}assert.equal(exit,143);return Date.now()-start;};
  return{results,until,stop,stderr:()=>stderr};
 }
 const w=await watch('check');
 try{
  await w.until(()=>w.results.length===1);assert.equal(w.results[0].cache.preparedModules,3);
  let start=performance.now();fs.writeFileSync(path.join(project,'Main.ps'),'import Middle\ndef answer : Nat := middle + 2\n');
  await w.until(()=>w.results.length===2);assert.equal(w.results[1].cache.prefixModules,2);assert.equal(w.results[1].cache.preparedModules,1);
  const leafMs=performance.now()-start;
  fs.writeFileSync(path.join(project,'Main.ps'),'import Middle\ndef answer : Nat := middle + 2\n');
  await w.until(()=>w.results.length===3);assert.equal(w.results[2].cache.finishHit,true);
  fs.writeFileSync(path.join(project,'Base.ps'),'def base : Nat := 41\n');
  await w.until(()=>w.results.length===4);assert.equal(w.results[3].cache.prefixModules,0);assert.equal(w.results[3].cache.preparedModules,3);
  fs.writeFileSync(path.join(project,'Main.ps'),'import Middle\ndef answer : Nat := true\n');
  await w.until(()=>w.stderr().includes('failed; waiting for changes'));
  fs.writeFileSync(path.join(project,'Main.ps'),'import Middle\ndef answer : Nat := middle + 1\n');
  await w.until(()=>w.results.length===5);assert.equal(w.results[4].logicalAdmission,'accepted');
  report.watchCheck={leafEditMs:leafMs,results:w.results.map(r=>({cache:r.cache,timings:r.timings})),dependencyInvalidated:true,errorRepair:true};
 }finally{report.watchCheckStopMs=await w.stop();}
 fs.writeFileSync(path.join(project,'Base.ps'),'def base : Nat := 40\n');
 const b=await watch('build','ts');
 try{
  await b.until(()=>b.results.length===1);
  const value=r=>ok(process.execPath,['--input-type=module','-e','const m=await import('+JSON.stringify(pathToFileURL(r.runtimeArtifact).href)+');console.log(String(m.answer));']).trim();
  assert.equal(value(b.results[0]),'42');
  const start=performance.now();fs.writeFileSync(path.join(project,'Main.ps'),'import Middle\ndef answer : Nat := middle + 2\n');
  await b.until(()=>b.results.length===2);assert.equal(value(b.results[1]),'43');
  const pointer=fs.readlinkSync(path.join(project,'out/current'));
  fs.writeFileSync(path.join(project,'Main.ps'),'import Middle\ndef answer : Nat := true\n');
  await b.until(()=>b.stderr().includes('failed; waiting for changes'));assert.equal(fs.readlinkSync(path.join(project,'out/current')),pointer);
  report.watchBuild={target:'ts',editMs:performance.now()-start,values:['42','43'],typingRefusalPreserved:true};
 }finally{report.watchBuildStopMs=await b.stop();}
 const ordinary=invoke('check',{entryModule:'Main',assurance:'ordinary-checked',sources:[{module:'Main',kind:'lean',text:'partial def again (n : Nat) : Nat := again n\n'}]});
 assert.equal(ordinary.logicalAdmission,'accepted');report.ordinaryPartialChecked=true;
 report.status='passed';
}catch(error){report.status='failed';report.failure=String(error.stack||error);throw error;}finally{
 fs.mkdirSync('dist/development-results',{recursive:true});fs.writeFileSync('dist/development-results/qualification.json',JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_DEVELOPMENT_QUALIFICATION '+JSON.stringify(report));fs.rmSync(directory,{recursive:true,force:true});
}
