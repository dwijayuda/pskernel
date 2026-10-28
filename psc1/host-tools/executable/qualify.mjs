// Whole-compiler execution evidence, not modular generation/fixed-point proof.
// Every successful application candidate is independently admitted before use.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {createCompilerHostSession,compilerSourceClosureDigest} from '../compiler-host-protocol.mjs';
import {verify} from './verify.mjs';
import {put,sha256,json,bounded,run,files,output as defaultOutput} from './tools.mjs';
const output=path.resolve(process.argv[2]??defaultOutput);
const bytes=fs.readFileSync(path.join(output,'manifest.json')),hash=sha256(bytes);
const root=path.join(output,'candidate'),manifest=verify(root,bytes,hash);
const checker=path.resolve('.lake/build/bin/psc1_independent_checker'),checkerPin=sha256(fs.readFileSync(checker));
const nodeFlags=['--max-old-space-size=4096','--stack-size=8192'];
const consumer=path.resolve('host-tools/executable/consume.mjs');
const reference=path.join(output,'reference-consumer.mjs');
put(reference,"import fs from 'node:fs';\nimport {psCompilerServiceCandidate} from './reference.mjs';\nprocess.stdout.write(psCompilerServiceCandidate(fs.readFileSync(process.argv[2],'utf8')));\n");
const rustDescriptor=JSON.parse(fs.readFileSync('dist/rust-target-consumer/descriptor.json'));
assert.equal(rustDescriptor.locked,true);assert.equal(rustDescriptor.toolchain.version,'1.90.0');
const rustPackage=path.resolve('dist/rust-target-consumer/package');
const rustSysroot=run('rustup',['run','1.90.0','rustc','--print','sysroot']).trim();
const rustc=path.join(rustSysroot,'bin/rustc'),rustPins=[...rustDescriptor.files.map(row=>({...row,file:path.join(rustPackage,row.path)})),
 ...rustDescriptor.toolchain.files.map(row=>({...row,file:path.join(rustSysroot,row.path)}))];
const verifyRust=()=>{for(const row of rustPins)assert.equal(sha256(fs.readFileSync(row.file)),row.sha256);};
verifyRust();
const externs=['num_bigint','num_traits'].flatMap(name=>{
 const matches=rustDescriptor.files.filter(row=>row.path.startsWith('deps/lib'+name+'-')&&row.path.endsWith('.rlib'));
 assert.equal(matches.length,1);
 return ['--extern',name+'='+path.join(rustPackage,matches[0].path)];
});

const observations=[],requests=[];
for(const grammar of ['lean','ps']){
 const sources=[{module:'Lib',kind:grammar,text:'def increment(x : Nat) : Nat := Nat.add x 1\n'},
  {module:'Entry',kind:grammar,text:'import Lib\n\ndef answer : Nat := increment 41\n'}];
 for(const target of ['js','ts','rust','wasm-core']){
  requests.push({name:grammar+'-'+target,sources,target,positive:true});
 }
 requests.push({name:grammar+'-invalid',target:'js',positive:false,sources:[
  {module:'Entry',kind:grammar,text:'def answer : Nat := true\n'}]});
}
for(const target of ['python','php','unknown']){
 requests.push({name:'optional-'+target,target,positive:false,sources:[
  {module:'Entry',kind:'lean',text:'def answer : Nat := 42\n'}]});
}
const admit=(candidate,item)=>{
 const requestId='production-module-'+item.name;
 assert.equal(candidate.status,'candidate');assert.equal(candidate.candidateOnly,true);
 const session=createCompilerHostSession({requestId,target:item.target,sources:item.sources,
  canonicalAdmissions:candidate.admissionRequest.admissions,checkerExecutable:checker});
 assert.equal(sha256(fs.readFileSync(checker)),checkerPin);
 const receipt=session.admit(JSON.stringify(candidate.admissionRequest));
 assert.equal(sha256(fs.readFileSync(checker)),checkerPin);return receipt;
};
for(const item of requests){
 const requestId='production-module-'+item.name,digest=compilerSourceClosureDigest(item.sources);
 const request=['psc1-unified-compiler-service/2',item.target,
  ['psc1-compiler-service/1',requestId,digest,item.sources[0].kind,'checked','Entry',
   item.sources.map(s=>[s.module,s.text])]];
 const requestFile=path.join(output,'requests',item.name+'.json');put(requestFile,JSON.stringify(request));
 const baseline=bounded('reference-'+item.name,[process.execPath,...nodeFlags,reference,requestFile],{addressSpace:false});
 const expected=JSON.parse(baseline.stdout);
 if(item.positive)admit(expected,item);
 else assert.equal(expected.status,'refused');
 for(const variant of ['js','ts']){
  const execution=bounded(variant+'-'+item.name,[process.execPath,...nodeFlags,consumer,root,
   path.join(output,'manifest.json'),hash,variant,requestFile],{addressSpace:false});
  assert.equal(execution.stdout,baseline.stdout,'PSC1_EXECUTABLE_REFERENCE_DIFFERENCE:'+variant+':'+item.name);
  const candidate=JSON.parse(execution.stdout);
  const receipt=item.positive?admit(candidate,item):null;
  if(!item.positive){
   assert.equal(candidate.status,'refused');assert.equal(candidate.source,undefined);
  }else{
   const dir=path.join(output,'applications',variant,item.name);
   fs.mkdirSync(dir,{recursive:true});
   put(path.join(dir,'admission.json'),json(receipt));
   if(item.target==='js'){
    const file=path.join(dir,'result.mjs');put(file,candidate.source);
    const observe=path.join(dir,'observe.mjs');
    put(observe,"import assert from 'node:assert/strict';\nimport {answer} from './result.mjs';\nassert.equal(answer,42n);\nconsole.log('42n');\n");
    const result=bounded('application-'+variant+'-'+item.name,[process.execPath,...nodeFlags,observe],{addressSpace:false});
    assert.equal(result.stdout.trim(),'42n');
   }else if(item.target==='ts'){
    const file=path.join(dir,'result.mts');put(file,candidate.source);
    const config=path.join(dir,'tsconfig.json');put(config,json({compilerOptions:{strict:true,noEmitOnError:true,
     target:'ES2022',module:'NodeNext',moduleResolution:'NodeNext',types:[],lib:['ES2022','DOM'],
     declaration:true,outDir:path.join(dir,'out')},files:[file]}));
    bounded('application-types-'+variant+'-'+item.name,[process.execPath,...nodeFlags,
     path.resolve('../node_modules/typescript/bin/tsc'),'--project',config],{addressSpace:false});
    const observe=path.join(dir,'observe.mjs');
    put(observe,"import assert from 'node:assert/strict';\nimport {answer} from './out/result.mjs';\nassert.equal(answer,42n);\nconsole.log('42n');\n");
    const result=bounded('application-'+variant+'-'+item.name,[process.execPath,...nodeFlags,observe],{addressSpace:false});
    assert.equal(result.stdout.trim(),'42n');
   }else if(item.target==='rust'){
    const file=path.join(dir,'result.rs');put(file,candidate.source+'\nfn main(){assert_eq!(answer().to_string(), "42"); println!("42n");}\n');
    verifyRust();
    bounded('application-rust-'+variant+'-'+item.name,[rustc,'--edition=2021',...externs,
     '-L','dependency='+path.join(rustPackage,'deps'),'--crate-name','psc1_modular_application',file,'-o',path.join(dir,'result')]);
    verifyRust();
    const result=bounded('application-rust-run-'+variant+'-'+item.name,[path.join(dir,'result')]);
    assert.equal(result.stdout.trim(),'42n');
   }else{
    const prefix='psc1-wasm-hex/1:';assert.ok(candidate.source.startsWith(prefix));
    const wasm=Buffer.from(candidate.source.slice(prefix.length),'hex');
    assert.equal(WebAssembly.validate(wasm),true);put(path.join(dir,'result.wasm'),wasm);
   }
  }
  observations.push({variant,case:item.name,target:item.target,status:candidate.status,
   exactReferenceBytes:true,sourceClosureDigest:digest,admission:receipt,
   elapsedMs:execution.report.elapsedMs,peakTreeRssKiB:execution.report.peakTreeRssKiB});
 }
}
verify(root,bytes,hash);
// Exercise the generated cohort guard itself in a fresh process, separately
// from the stronger pre-import inventory checks. Only a known guard literal is
// changed for this negative, then the exact tested bytes are restored.
const runtimeGuards=[];
for(const variant of ['js','ts']){
 const unit=manifest.graphEvidence[variant].find(row=>row.specifier.endsWith('/Ps.Foundation.Name'));
 assert.ok(unit);
 const module=unit.specifier.split('/')[3],owner=unit.specifier.split('/').slice(0,2).join('/');
 const file=path.join(root,'node_modules',owner,'dist',variant,'generated',module+'.mjs');
 const original=fs.readFileSync(file,'utf8');
 const guard=manifest.protocol+':'+variant+':'+manifest.sourceClosureDigest;
 assert.ok(original.includes(guard));
 fs.writeFileSync(file,original.replace(guard,manifest.protocol+':'+variant+':'+'0'.repeat(64)));
 const probe=spawnSync(process.execPath,[...nodeFlags,'--input-type=module','-e',
  'await import('+JSON.stringify(pathToFileURL(file).href)+')'],{encoding:'utf8',timeout:240000,maxBuffer:33554432});
 fs.writeFileSync(file,original);
 assert.notEqual(probe.status,0);assert.match(probe.stderr,/PSC1_MODULE_RUNTIME_COHORT/);
 runtimeGuards.push(variant);
}
verify(root,bytes,hash);

const tarballs=path.join(output,'tarballs');fs.mkdirSync(tarballs,{recursive:true});
const records=[];
for(const pkg of manifest.packages){
 const metadata=JSON.parse(run('npm',['pack',path.join(root,'node_modules',pkg.name),
  '--ignore-scripts','--json','--pack-destination',tarballs]));
 assert.equal(metadata.length,1);const file=path.join(tarballs,metadata[0].filename);
 records.push({name:pkg.name,file,sha256:sha256(fs.readFileSync(file))});
}
const installed=path.join(output,'installed');fs.mkdirSync(installed);
put(path.join(installed,'package.json'),json({private:true,type:'module',name:'psc1-production-module-consumer',version:'0.0.0'}));
run('npm',['install','--offline','--ignore-scripts','--no-audit','--no-fund','--package-lock=false',...records.map(r=>r.file)],{cwd:installed});
// Exact npm package bytes must match the tested candidate tree, including
// compiler source-owned executable files. Root-only umbrella is still M4.
for(const pkg of manifest.packages){
 const before=path.join(root,'node_modules',pkg.name),after=path.join(installed,'node_modules',pkg.name);
 assert.deepEqual(files(after),files(before),'PSC1_EXECUTABLE_PACKED_BYTES:'+pkg.name);
}
const representative=path.join(output,'requests/lean-js.json');
for(const variant of ['js','ts']){
 const runner=path.join(installed,'consume-'+variant+'.mjs');
 const specifier=manifest.entry[variant].replace(/^node_modules\//,'').replace('/dist/'+variant+'/generated/','/generated/').replace(/\.mjs$/,'')+(variant==='ts'?'/ts':'');
 put(runner,"import fs from 'node:fs';\nimport {psCompilerServiceCandidate} from "+JSON.stringify(specifier)+";\nprocess.stdout.write(psCompilerServiceCandidate(fs.readFileSync(process.argv[2],'utf8')));\n");
 const result=bounded('installed-'+variant,[process.execPath,...nodeFlags,runner,representative],{addressSpace:false});
 assert.equal(JSON.parse(result.stdout).status,'candidate');
}
const receipt={schema:'psc1-executable-compiler-execution/1',testedCommit:process.env.GITHUB_SHA,
 manifestSha256:hash,compilerSourceClosureDigest:manifest.sourceClosureDigest,
 observations,runtimeCohortRefusals:runtimeGuards,installedPackages:records.map(({file,...rest})=>({...rest,tarball:path.basename(file)})),
 exactPackagedBytes:true,offlineMultiPackageInstallation:true,
 rustConsumer:{version:'1.90.0',locked:true,descriptorSha256:sha256(fs.readFileSync('dist/rust-target-consumer/descriptor.json'))},
 scope:'complete modular JS/TS compiler candidates, two source grammars, four core targets, exact same-IR reference and independent application admission',
 remaining:['M4 checked root-only umbrella/CLI/watch','retained application and seven-backend qualification corpus',
  'portable modular graph emission by generated compiler','new modular G1/G2/G3 and fixed points','platform/publication qualification'],
 fullModularSelfHosting:false,rootUmbrellaPromotion:false};
put(path.join(output,'execution-receipt.json'),json(receipt));
console.log('PSC1_EXECUTABLE_COMPILER_EXECUTION '+JSON.stringify(receipt));
