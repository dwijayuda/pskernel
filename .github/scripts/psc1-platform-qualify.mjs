// One focused installed-runtime qualification per supported OS/architecture.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';
import assert from 'node:assert/strict';import{spawnSync,spawn}from'node:child_process';
import{pathToFileURL}from'node:url';import{createHash,randomUUID}from'node:crypto';
import{fixtures}from'../../psc1/scripts/kernel435-fixtures.mjs';
const base=path.resolve('dist/modular-toolchain'),receipt=JSON.parse(fs.readFileSync(path.join(base,'package-receipt.json')));
assert.equal(receipt.version,'0.1.0-psc1-modular.4');assert.equal(receipt.sourceUnits,134);assert.equal(receipt.corePackages,20);
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const tar=path.join(base,'tarballs',receipt.tarball);assert.equal(hash(fs.readFileSync(tar)),receipt.sha256);
const parent=fs.realpathSync(os.tmpdir()),directory=fs.mkdtempSync(path.join(parent,'psc1 cross platform λ '));
const report={schema:'psc1-cross-platform-installed/1',status:'running',testedCommit:process.env.GITHUB_SHA,
 platform:process.platform,arch:process.arch,node:process.version,tarballSha256:receipt.sha256,records:[],negativeCases:[],publication:[]};
const npm=[path.join(path.dirname(process.execPath),'node_modules/npm/bin/npm-cli.js'),
 path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js')].find(file=>fs.existsSync(file));
assert.ok(npm);
const env={...process.env};delete env.NODE_OPTIONS;delete env.LD_PRELOAD;delete env.LD_LIBRARY_PATH;
const call=(exe,args,cwd=directory)=>spawnSync(exe,args,{cwd,env,encoding:'utf8',timeout:240000,maxBuffer:33554432,windowsHide:true});
const ok=(exe,args,cwd)=>{const r=call(exe,args,cwd);assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
const install=tars=>ok(process.execPath,[npm,'install','--offline','--ignore-scripts','--no-audit','--no-fund',
 '--registry','http://127.0.0.1:9','--cache',path.join(directory,'empty-cache'),...tars]);
const root=path.join(directory,'node_modules/proofscript'),cliFile=path.join(root,'dist/psc.mjs');
const cli=args=>call(process.execPath,[cliFile,...args]);
const cliOk=args=>ok(process.execPath,[cliFile,...args]);
const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
let live;
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 install([tar]);report.offlineRootOnlyInstall=true;
 assert.ok(cliOk(['--help']).includes('psc check'));assert.equal(cliOk(['--version']).trim(),'proofscript '+receipt.version);
 const identity=JSON.parse(cliOk(['--identity']));assert.equal(identity.compilerSourceClosureDigest,receipt.compilerSourceClosureDigest);
 assert.equal(identity.defaultKernel,'wasm');
 const protocol=process.platform==='win32'?'portable-atomic':process.platform==='darwin'?'portable-file':'legacy-symlink';
 assert.equal(identity.defaultPublicationProtocol,protocol);report.defaultPublicationProtocol=protocol;
 for(const name of['backend-python','backend-php','compiler-rust-linux-x64','compiler-wasm'])
  assert.equal(fs.existsSync(path.join(root,'node_modules/@proofscript',name)),false);
 const kernelFile=path.join(directory,'kernel.mjs');
 const selected=fixtures.filter(row=>['nat-accept','kernel-type-rejection'].includes(row.id));assert.equal(selected.length,2);
 fs.writeFileSync(path.join(directory,'fixtures.json'),JSON.stringify(selected));
 fs.writeFileSync(kernelFile,"import fs from'node:fs';import assert from'node:assert/strict';import{checkCanonicalAdmissions}from'proofscript';for(const f of JSON.parse(fs.readFileSync('fixtures.json'))){const r=await checkCanonicalAdmissions(f.input);assert.equal(r.accepted,f.accepted);assert.equal(r.leanVersion,'4.35.0');assert.equal(r.wasmMemoryModel,'linear');}console.log('real-kernel-pass');");
 assert.equal(ok(process.execPath,[kernelFile]).trim(),'real-kernel-pass');report.realKernelAcceptanceAndRejection=true;
 const program=path.join(directory,'build.mjs');
 fs.writeFileSync(program,"import{build,compile}from'proofscript';const o=JSON.parse(process.argv[2]);console.log(JSON.stringify(process.argv[3]==='compile'?compile(o):build(o)));");
 const source='def answer : Nat := 42\ndef huge : Int := -9007199254740993123456789\ndef text : String := "λ🙂"\n';
 const observe=result=>JSON.parse(ok(process.execPath,['--input-type=module','-e',
  'let m=await import('+JSON.stringify(pathToFileURL(result.runtimeArtifact).href)+');if(m.default)m=m.default;console.log(JSON.stringify({answer:String(m.answer),huge:String(m.huge),text:m.text}));']));
 const expected={answer:'42',huge:'-9007199254740993123456789',text:'λ🙂'};
 for(const engine of['js','ts'])for(const kind of['lean','ps'])for(const target of['js','wasm-core']){
  const options={engine,target,entryModule:'Main',sources:[{module:'Main',kind,text:source}],
   out:path.join(directory,'out',engine,kind,target)};
  const r=JSON.parse(ok(process.execPath,[program,JSON.stringify(options)]));
  assert.equal(r.logicalAdmission,'accepted');assert.deepEqual(r.kernelProviders,['wasm']);
  assert.equal(r.publicationProtocol,protocol);
  assert.equal(r.durability,protocol==='portable-atomic'?'visibility-only':'confirmed');
  assert.deepEqual(observe(r),expected);report.records.push({engine,kind,target,durability:r.durability,sourceClosureDigest:r.sourceClosureDigest});
 }
 const compiled=JSON.parse(ok(process.execPath,[program,JSON.stringify({engine:'js',target:'js',entryModule:'Main',
  sources:[{module:'Main',kind:'ps',text:source}]}),'compile']));
 assert.equal(compiled.publication,'not-requested');report.compileWithoutPublication=true;
 const sourceFile=path.join(directory,'Main.ps');
 cliOk(['init']);fs.writeFileSync(sourceFile,source); // Root-only CLI project workflow, independently from API fixtures.
 assert.equal(JSON.parse(cliOk(['check'])).logicalAdmission,'accepted');
 const commandStore=path.join(directory,'cli-out');
 const first=JSON.parse(cliOk(['build',sourceFile,'--out',commandStore]));assert.deepEqual(observe(first),expected);
 const pointer=protocol==='legacy-symlink'?'current':'current.json';
 const readPointer=()=>protocol==='legacy-symlink'?fs.readlinkSync(path.join(commandStore,pointer)):fs.readFileSync(path.join(commandStore,pointer),'utf8');
 const prior=readPointer();fs.writeFileSync(sourceFile,'def answer : Nat := true\n');
 const bad=cli(['build',sourceFile,'--out',commandStore]);assert.notEqual(bad.status,0);assert.equal(readPointer(),prior);
 report.negativeCases.push('typing-refusal-preserves-publication');fs.writeFileSync(sourceFile,source);
 if(process.platform==='win32'){
  const strong=cli(['build',sourceFile,'--out',commandStore,'--publication-protocol','portable-file']);
  assert.notEqual(strong.status,0);assert.match(strong.stderr,/PUBLICATION_PLATFORM_UNQUALIFIED/);
  assert.equal(readPointer(),prior);report.negativeCases.push('durable-protocol-not-silently-downgraded');
 }
 if(process.platform!=='linux'){
  const unsupported=cli(['compile',sourceFile,'--target','rust']);
  assert.notEqual(unsupported.status,0);assert.match(unsupported.stderr,/RUST_CONSUMER_PLATFORM/);
  report.negativeCases.push('unsupported-rust-sdk-platform');
 }
 const graphFile=path.join(root,'dist/COMPILER_GRAPH.json'),graphBytes=fs.readFileSync(graphFile);
 const manifest=JSON.parse(graphBytes),module=manifest.files.find(row=>row.path.includes('/dist/js/generated/')&&row.path.endsWith('.mjs'));
 const moduleFile=path.join(root,'node_modules',module.path),moduleBytes=fs.readFileSync(moduleFile);
 try{
  fs.appendFileSync(moduleFile,"\nthrow Error('UNVERIFIED_MODULE_EXECUTED');");
  const refused=cli(['--identity']);assert.notEqual(refused.status,0);assert.match(refused.stderr,/PSC1_EXECUTABLE/);
  assert.doesNotMatch(refused.stderr,/UNVERIFIED_MODULE_EXECUTED/);report.negativeCases.push('tampered-module-before-import');
 }finally{fs.writeFileSync(moduleFile,moduleBytes);}
 // Install only the two exact optional TypeScript packages for this platform.
 const resources=path.resolve('dist/platform-typescript'),sdk=JSON.parse(fs.readFileSync(path.join(resources,'resources.json')));
 assert.equal(sdk.platform,process.platform+'-'+process.arch);
 for(const row of sdk.packages)assert.equal(hash(fs.readFileSync(path.join(resources,row.tarball))),row.sha256);
 install(sdk.packages.map(row=>path.join(resources,row.tarball)));assert.deepEqual(fs.readFileSync(graphFile),graphBytes);
 for(const engine of['js','ts'])for(const kind of['lean','ps']){
  const r=JSON.parse(ok(process.execPath,[program,JSON.stringify({engine,target:'ts',entryModule:'Main',
   sources:[{module:'Main',kind,text:source}],out:path.join(directory,'typescript',engine,kind)})]));
  assert.deepEqual(observe(r),expected);assert.equal(r.logicalAdmission,'accepted');
  report.records.push({engine,kind,target:'ts',durability:r.durability});
 }
 const native=sdk.packages.find(row=>row.package!=='typescript'),nativeMeta=path.join(directory,'node_modules',native.package,'package.json');
 const originalMeta=fs.readFileSync(nativeMeta);
 try{
  fs.appendFileSync(nativeMeta,' ');
  const refused=cli(['build',sourceFile,'--target','ts','--out',commandStore]);
  assert.notEqual(refused.status,0);assert.match(refused.stderr,/RESOURCE_IDENTITY/);assert.equal(readPointer(),prior);
  report.negativeCases.push('optional-sdk-tamper-before-execution');
 }finally{fs.writeFileSync(nativeMeta,originalMeta);}
 // Focused filesystem-only protocol tests. These do not manufacture admission.
 const publisher=await import(pathToFileURL(path.join(root,'node_modules/@proofscript/compiler/dist/host/host-tools/transactional-publication.mjs')));
 const modes=process.platform==='linux'?['legacy-symlink','portable-file','portable-atomic']:[protocol];
 for(const mode of modes){
  const store=path.join(directory,'protocol-'+mode),stage=(label)=>{
   const directory=fs.mkdtempSync(path.join(store,'generations/.stage-')),text='export const tag='+JSON.stringify(label)+';\n';
   fs.writeFileSync(path.join(directory,'target.mjs'),text);
   return{stage:directory,manifest:{schema:'psc1-generated-service-bundle/1',targetFile:'target.mjs',
    files:[{path:'target.mjs',bytes:Buffer.byteLength(text),sha256:hash(text)}]},verify:()=>{}};
  };
  const initial=publisher.openPublicationStore(store,mode).publish(stage('initial'));
  const before=publisher.readPublication(store,mode).generation;
  assert.throws(()=>publisher.openPublicationStore(store,mode).publish({...stage('before'),
   fault:phase=>{if(phase==='before-commit')throw Error('injected-before');}}),/injected-before/);
  assert.equal(publisher.readPublication(store,mode).generation,before);
  let committed;
  try{publisher.openPublicationStore(store,mode).publish({...stage('after'),
   fault:phase=>{if(phase==='after-commit')throw Error('injected-after');}});}catch(error){committed=error;}
  assert.match(committed.message,/COMMITTED_DURABILITY_UNCERTAIN/);
  assert.equal(committed.committedPublication.durability,'unconfirmed');
  assert.equal(publisher.readPublication(store,mode).generation,committed.committedPublication.generation);
  const stale=publisher.openPublicationStore(store,mode);
  publisher.openPublicationStore(store,mode).publish(stage('newer'));
  assert.throws(()=>stale.publish(stage('stale')),/PRIOR_PUBLICATION_CHANGED/);
  report.publication.push({protocol:mode,initialDurability:initial.durability,
   precommitPreserved:true,postcommitUncertainty:true,staleSessionRefused:true});
 }
 // A small real watch cycle: edit, reject, repair, then stop the owned process tree.
 const watchFile=path.join(directory,'Watch.ps'),watchStore=path.join(directory,'watch-out');
 fs.writeFileSync(watchFile,'def answer : Nat := 42\n');
 const lines=[];let stdout='',stderr='',exit;
 live=spawn(process.execPath,[cliFile,'build',watchFile,'--engine','ts','--out',watchStore,'--watch','--diagnostics=json'],
  {cwd:directory,env,stdio:['ignore','pipe','pipe'],windowsHide:true});
 live.stdout.on('data',bytes=>{stdout+=bytes;assert.ok(stdout.length<33554432);for(;;){
  const end=stdout.indexOf('\n');if(end<0)break;const line=stdout.slice(0,end);stdout=stdout.slice(end+1);if(line)lines.push(JSON.parse(line));}});
 live.stderr.on('data',bytes=>{stderr+=bytes;assert.ok(stderr.length<33554432);});
 live.on('close',(code,signal)=>{exit={code,signal};});
 const until=async predicate=>{const started=Date.now();while(!predicate()){
  if(exit)throw Error('watch exited '+stderr);assert.ok(Date.now()-started<240000,'watch deadline '+stderr);await sleep(25);}};
 const answer=r=>ok(process.execPath,['--input-type=module','-e','const m=await import('+JSON.stringify(pathToFileURL(r.runtimeArtifact).href)+');console.log(String(m.answer));']).trim();
 await until(()=>lines.length>=1);assert.equal(answer(lines[0]),'42');
 fs.writeFileSync(watchFile,'def answer : Nat := 43\n');await until(()=>lines.length>=2);assert.equal(answer(lines[1]),'43');
 const watchPointer=protocol==='legacy-symlink'?fs.readlinkSync(path.join(watchStore,'current')):fs.readFileSync(path.join(watchStore,'current.json'),'utf8');
 fs.writeFileSync(watchFile,'def answer : Nat := true\n');await until(()=>stderr.includes('failed; waiting for changes'));
 assert.equal(protocol==='legacy-symlink'?fs.readlinkSync(path.join(watchStore,'current')):fs.readFileSync(path.join(watchStore,'current.json'),'utf8'),watchPointer);
 fs.writeFileSync(watchFile,'def answer : Nat := 44\n');await until(()=>lines.length>=3);assert.equal(answer(lines[2]),'44');
 const stopped=Date.now();
 if(process.platform==='win32'){
  ok(path.join(process.env.SystemRoot,'System32/taskkill.exe'),['/PID',String(live.pid),'/T','/F']);
 }else live.kill('SIGTERM');
 while(!exit){assert.ok(Date.now()-stopped<6000,'watch stop deadline');await sleep(25);}
 if(process.platform!=='win32')assert.equal(exit.code,143);
 report.watch={engine:'ts',builds:3,values:['42','43','44'],typingRefusalPreserved:true,
  stopMethod:process.platform==='win32'?'Windows taskkill owned tree':'SIGTERM',stopMs:Date.now()-stopped,exit};
 live=undefined;
 // Actual global npm installation and registered command execution.
 const prefix=path.join(directory,'global');
 ok(process.execPath,[npm,'install','--global','--prefix',prefix,'--offline','--ignore-scripts','--no-audit','--no-fund',
  '--registry','http://127.0.0.1:9','--cache',path.join(directory,'global-cache'),tar]);
 const globalRoot=path.join(prefix,process.platform==='win32'?'node_modules/proofscript':'lib/node_modules/proofscript');
 assert.equal(ok(process.execPath,[path.join(globalRoot,'dist/psc.mjs'),'--version']).trim(),'proofscript '+receipt.version);
 assert.ok(ok(process.execPath,[npm,'exec','--offline','--','psc','--help']).includes('psc check'));
 report.globalRootOnlyInstall=true;assert.equal(report.records.length,12);
 report.status='passed';
}catch(error){report.status='failed';report.error=error.stack;throw error;}
finally{
 if(live){if(process.platform==='win32')call(path.join(process.env.SystemRoot,'System32/taskkill.exe'),['/PID',String(live.pid),'/T','/F']);else live.kill('SIGKILL');}
 const out=path.resolve('dist/platform-results');fs.mkdirSync(out,{recursive:true});
 fs.writeFileSync(path.join(out,process.env.PSC1_PLATFORM_LABEL+'.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_CROSS_PLATFORM_INSTALLED '+JSON.stringify(report));
 const relative=path.relative(parent,directory);assert.ok(relative&&!relative.startsWith('..')&&!path.isAbsolute(relative));fs.rmSync(directory,{recursive:true,force:true});
}
