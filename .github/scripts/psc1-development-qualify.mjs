// Focused installed .ps development checks; no G2/G3 or broad backend rebuild.
import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';
import{spawnSync}from'node:child_process';import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
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
 const graph=JSON.parse(fs.readFileSync(path.join(root,'dist/COMPILER_GRAPH.json'))),row=graph.files.find(r=>r.path.includes('/dist/js/generated/')&&r.path.endsWith('.mjs'));
 const file=path.join(root,'node_modules',row.path),before=fs.readFileSync(file);
 try{fs.appendFileSync(file,'\n// tampered');const r=call(process.execPath,[cli,'check','Main.ps']);assert.notEqual(r.status,0);assert.match(r.stderr,/PSC1_EXECUTABLE/);report.tamperBeforeExecution=true;}
 finally{fs.writeFileSync(file,before);}
 report.status='passed';
}finally{
 fs.mkdirSync('dist/development-results',{recursive:true});fs.writeFileSync('dist/development-results/qualification.json',JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_DEVELOPMENT_QUALIFICATION '+JSON.stringify(report));fs.rmSync(directory,{recursive:true,force:true});
}
