// Offline installed qualification, actual unchanged G3 engines and genuine kernels.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';import {createHash} from 'node:crypto';
import {corpus,expectedObservations,pythonObservations,phpObservations} from './generated-target-corpus.mjs';
const out=path.resolve('dist/slim-universal'),assembly=JSON.parse(fs.readFileSync(path.join(out,'package-receipt.json')));
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-dispatch-installed-'));fs.writeFileSync(path.join(work,'package.json'),'{"private":true,"type":"module"}');
const npm=path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),tarballs=path.join(out,'tarballs');
const env={...process.env,PATH:path.dirname(process.execPath)};
for(const k of Object.keys(env))if(k==='NODE_OPTIONS'||k.startsWith('PSC1_')||k==='LEAN_PATH'||k==='ELAN_TOOLCHAIN'||k==='LD_LIBRARY_PATH'||k.startsWith('DYLD_')||k==='PSC_LEAN_KERNEL_PROVIDER_BIN')delete env[k];
const run=(exe,args,extra={})=>{const r=spawnSync(exe,args,{cwd:work,env,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,...extra});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
const install=files=>run(process.execPath,[npm,'install','--prefix',work,'--cache',path.join(work,'empty-cache'),'--offline','--registry','http://127.0.0.1:9','--ignore-scripts','--no-audit','--no-fund',...files.map(f=>path.join(tarballs,f))]);
install([assembly.tarball,...['rust','wasm-core','nativeKernel'].map(k=>assembly.input.packages[k].tarball)]);
const consumer=path.join(work,'consumer.mjs'),records=path.join(work,'records.json'),refusals=[];
const emit=program=>{fs.writeFileSync(consumer,program);return run(process.execPath,[consumer]);};
const base="import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {build,compile,readPublication,getCompilerMetadata} from 'proofscript';\n";
for(const target of ['wasm-component','python','php']){
 assert.equal(fs.existsSync(path.join(work,'node_modules',assembly.dispatchPackages[target].package)),false);
 emit(base+"assert.throws(()=>build({sources:[{module:'Entry',kind:'lean',text:'def truth : Bool := true\\n'}],entryModule:'Entry',target:"+JSON.stringify(target)+",publicationProtocol:'portable-file',out:'absent-"+target+"'}),/OPTIONAL_PACKAGE_MISSING/);");
 refusals.push({target,kind:'absent-by-default'});
}
install(Object.values(assembly.dispatchPackages).map(d=>d.tarball));
const sources=corpus.map(c=>({...c,sources:c.sources.map(s=>({...s,kind:c.grammar}))}));
const program=base+`
const rows=[],io=[],components=[],negatives=[];
for(const engine of ['js','ts','rust','wasm-core']) {
 for(const target of ['python','php']) {
  for(const entry of ${JSON.stringify(sources)}) {
   const out=path.resolve('stores',engine,target,entry.id);
   const result=build({engine,target,out,publicationProtocol:'portable-file',assurance:entry.assurance,entryModule:entry.entry,sources:entry.sources});
   const read=readPublication({out,publicationProtocol:'portable-file'});assert.equal(read.target,result.artifact);assert.equal(result.receipt.targetArtifact.provider.strictIr,'native-rechecked-roundtrip-exact');
   assert.equal(result.receipt.compilerTarget,'js');assert.equal(result.receipt.targetArtifact.provider.publicationAuthority,false);
   assert.equal(result.logicalAdmission,'accepted');assert.equal(result.durability,'confirmed');
   assert.throws(()=>build({engine,target,out,publicationProtocol:'portable-file',entryModule:'Entry',sources:[{module:'Entry',kind:entry.grammar,text:'def truth : Bool := 42\\n'}]}));
   assert.equal(readPublication({out,publicationProtocol:'portable-file'}).generation,result.generation);
   negatives.push({engine,target,id:entry.id,priorPreserved:true});
   rows.push({engine,target,id:entry.id,artifact:result.artifact,generation:result.generation,receipt:result.receipt});
   console.log('PSC1_PROVIDER_CASE '+JSON.stringify({engine,target,id:entry.id}));
  }
  for(const kind of ['lean','ps']){
   const text=kind==='lean'?'def run (input : String) (dispatch : String -> String) : String := dispatch input\\n':'def run(input : String, dispatch : String -> String) : String := dispatch(input)\\n';
   const result=build({engine,target,outputAbi:'io-dispatcher',publicationProtocol:'portable-file',out:path.resolve('io',engine,target,kind),entryModule:'Entry',sources:[{module:'Entry',kind,text}]});
   io.push({engine,target,kind,artifact:result.artifact,receipt:result.receipt});
  }
 }
 for(const kind of ['lean','ps']){
  const options={engine,target:'wasm-component',publicationProtocol:'portable-file',out:path.resolve('components',engine,kind),entryModule:'Entry',sources:[{module:'Entry',kind,text:kind==='lean'?'def truth : Bool := true\\ndef negate (value : Bool) : Bool := Bool.not value\\n':'def truth : Bool := true\\ndef negate(value : Bool) : Bool := Bool.not(value)\\n'}]};
  const result=build(options);assert.equal(result.receipt.compilerTarget,'wasm-core');
  assert.equal(result.artifact,result.runtimeArtifact);assert.equal(result.receipt.targetArtifact.schema.length,2);
  const first=fs.readFileSync(result.artifact);assert.deepEqual([...first.subarray(0,8)],[0,97,115,109,13,0,1,0]);
  const next=build(options);assert.deepEqual(fs.readFileSync(next.artifact),first);assert.notEqual(result.generation,next.generation);
  for(const text of ['def value : Nat := 42\\n','def _invalid : Bool := true\\n','def truth : Bool := 42\\n']){
   assert.throws(()=>build({...options,sources:[{module:'Entry',kind,text}]}));
   assert.equal(readPublication(options).generation,next.generation);
   negatives.push({engine,target:'wasm-component',kind,priorPreserved:true});
  }
  assert.throws(()=>build({...options,outputAbi:'io-dispatcher',sources:[{module:'Entry',kind,text:kind==='lean'?'def run (input : String) (dispatch : String -> String) : String := dispatch input\\n':'def run(input : String, dispatch : String -> String) : String := dispatch(input)\\n'}]}));
  const compiled=compile(options);assert.equal(compiled.sourceEncoding,'psc1-wasm-component-hex/1');
  assert.equal(compiled.source,'psc1-wasm-component-hex/1:'+first.toString('hex'));
  components.push({engine,kind,artifact:result.artifact,generation:result.generation,receipt:result.receipt});
  console.log('PSC1_COMPONENT_CASE '+JSON.stringify({engine,kind}));
 }
}
fs.writeFileSync(${JSON.stringify(records)},JSON.stringify({rows,io,components,negatives}));
`;
emit(program);
const actual=JSON.parse(fs.readFileSync(records));
const pythonDriver=path.join(work,'observe.py'),phpDriver=path.join(work,'observe.php');
fs.writeFileSync(pythonDriver,'import importlib.util,json,sys\ns=importlib.util.spec_from_file_location("psc1",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)\nprint(json.dumps(eval(sys.argv[2])))\n');
fs.writeFileSync(phpDriver,'<?php $m=require $argv[1];echo json_encode(eval("return ".$argv[2].";"),JSON_THROW_ON_ERROR)."\\n";');
const tool=t=>path.join(work,'node_modules',assembly.dispatchPackages[t].package,'tool');
for(const row of actual.rows){
 const expression=(row.target==='python'?pythonObservations:phpObservations)[row.id];
 const stdout=run(tool(row.target),[row.target+'-run',row.target==='python'?pythonDriver:phpDriver,row.artifact,expression]);
 assert.deepEqual(JSON.parse(stdout),expectedObservations[row.id]);row.runtime='executed';
}
for(const row of actual.io){
 const expression=row.target==='python'?'{"text":m.run("λ🙂",lambda value:"ok:"+value)}':'["text"=>$m["run"]("λ🙂",fn($value)=>"ok:".$value)]';
 const stdout=run(tool(row.target),[row.target+'-run',row.target==='python'?pythonDriver:phpDriver,row.artifact,expression]);
 assert.deepEqual(JSON.parse(stdout),{text:'ok:λ🙂'});row.runtime='executed';
 const trapDriver=path.join(work,'trap-'+row.target+(row.target==='python'?'.py':'.php'));
 fs.writeFileSync(trapDriver,row.target==='python'?
 'import importlib.util,sys\ns=importlib.util.spec_from_file_location("psc1",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)\ndef trap(value): raise RuntimeError("host trap")\ntry: m.run("x",trap)\nexcept RuntimeError as error: assert str(error)=="host trap"\nelse: raise AssertionError("missing host trap")\n':
 '<?php $m=require $argv[1];try{$m["run"]("x",function($value){throw new RuntimeException("host trap");});throw new RuntimeException("missing host trap");}catch(RuntimeException $e){if($e->getMessage()!=="host trap")throw $e;}');
 run(tool(row.target),[row.target+'-run',trapDriver,row.artifact]);row.hostTrapPreserved=true;
}
for(const row of actual.components){
 const wasmTime=process.env.PSC1_WASMTIME;assert.ok(wasmTime);
 assert.match(run(wasmTime,['run','--invoke','truth()',row.artifact]),/true/);
 assert.match(run(wasmTime,['run','--invoke','negate(false)',row.artifact]),/true/);
 assert.match(run(wasmTime,['run','--invoke','negate(true)',row.artifact]),/false/);
 row.runtime='executed';
}
for(const target of Object.keys(assembly.dispatchPackages)){
 const root=path.join(work,'node_modules',assembly.dispatchPackages[target].package),metaFile=path.join(root,'package.json'),original=fs.readFileSync(metaFile);
 const options={target,entryModule:'Entry',sources:[{module:'Entry',kind:'lean',text:'def truth : Bool := true\n'}]};
 for(const [label,mutate]of [['authority',m=>m.proofscript.publicationAuthority=true],['source',m=>m.proofscript.sourceCommit='0'.repeat(40)],['frontend',m=>m.proofscript.compilerFrontend=true]]){
  const m=JSON.parse(original);mutate(m);fs.writeFileSync(metaFile,JSON.stringify(m));
  try{emit(base+'assert.throws(()=>compile('+JSON.stringify(options)+'),/RESOURCE_IDENTITY|DISPATCH_AUTHORITY/);');}finally{fs.writeFileSync(metaFile,original);}
  refusals.push({target,label});
 }
 const binary=path.join(root,'tool'),saved=fs.readFileSync(binary),changed=Buffer.from(saved);changed[changed.length-1]^=1;fs.writeFileSync(binary,changed);
 try{emit(base+'assert.throws(()=>compile('+JSON.stringify(options)+'),/RESOURCE_IDENTITY/);');}finally{fs.writeFileSync(binary,saved);}
 refusals.push({target,label:'binary-integrity'});
 const link=path.join(root,'tool-held');fs.renameSync(binary,link);fs.symlinkSync(link,binary);
 try{emit(base+'assert.throws(()=>compile('+JSON.stringify(options)+'),/RESOURCE_SYMLINK/);');}finally{fs.unlinkSync(binary);fs.renameSync(link,binary);}
 refusals.push({target,label:'binary-symlink'});
}
// Direct malformed worker requests remain candidate-only and never publish.
for(const target of ['python','php']){
 const original=JSON.parse(fs.readFileSync(path.join(path.dirname(actual.rows.find(r=>r.target===target).artifact),'provider-request.json')));
 for(const [label,mutate]of [
  ['schema',r=>r.push('unexpected')],['target',r=>r[1]='js'],['protocol',r=>r[0]='other/1'],
  ['extra-ir-field',r=>r[2].push([])],['missing-public',r=>r[3]=['missing']],['duplicate-public',r=>r[3]=['answer','answer']],
  ['unbound-ir',r=>r[2][4][0][4]=['var','missing']],
  ['noncanonical-nat',r=>{r[2]=['psc1-ir/1',[],[],[],[['answer',[],[],['primitive','nat'],['literal',['natural','042']]]]];r[3]=['answer'];}]
 ]){
  const changed=structuredClone(original);mutate(changed);const file=path.join(work,'malformed.json'),text=JSON.stringify(changed);fs.writeFileSync(file,text);
  const digest=createHash('sha256').update(text).digest('hex'),r=spawnSync(tool(target),['emit-portable',file],{cwd:work,env:{...env,PSC1_BACKEND_REQUEST_SHA256:digest},encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});
  assert.equal(r.error,undefined);assert.notEqual(r.status,0);assert.equal(r.stdout,'');refusals.push({target,label});
 }
}
assert.equal(actual.rows.length,40);assert.equal(actual.io.length,16);assert.equal(actual.components.length,8);
const receipt={schema:'psc1-checked-dispatch-qualification/1',testedCommit:process.env.GITHUB_SHA,status:'passed',compilerSourceClosureDigest:assembly.compilerSourceClosureDigest,rootSha256:assembly.sha256,
 unchangedG3:true,independentAdmission:true,strictOriginalAndTransformedIr:true,optionalEmitterNativeRevalidation:true,
 offline:true,installScripts:false,executorPath:'Node-only',platform:'Linux x64 only',formalPreservation:'not-provided',
 ...actual,refusals:[...actual.negatives,...refusals]};
fs.writeFileSync(path.join(out,'checked-dispatch.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_CHECKED_DISPATCH: '+JSON.stringify({source:receipt.compilerSourceClosureDigest,providers:40,io:16,components:8,refusals:receipt.refusals.length}));
