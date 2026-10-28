// Installed preview acceptance against retained, independently checked M3 values.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {fixture} from './modular-toolchain-fixture.mjs';
import {corpus,refusals,expectedObservations,observedExpressions,rustObservations,
 pythonObservations,phpObservations} from './generated-target-corpus.mjs';
import {sha256} from './kernel435-qualified-artifact.mjs';
const f=fixture({allProviders:true}),records=[],negatives=[];
const out=path.resolve('dist/modular-toolchain'),runtime=path.basename(f.runtime).startsWith('bun')?'bun':'node';
const reference=JSON.parse(fs.readFileSync('scripts/modular-toolchain-reference.json'));
const report={schema:'psc1-modular-installed-qualification/1',testedCommit:process.env.GITHUB_SHA,
 runtime,status:'running',records,negatives,sourceGraph:reference.compilerSourceClosureDigest,
 defaultKernel:'wasm',fullModularSelfHosting:false};
const save=()=>fs.writeFileSync(path.join(out,'qualification-'+runtime+'.json'),JSON.stringify(report,null,2)+'\n');
const program=path.join(f.directory,'build.mjs');
fs.writeFileSync(program,"import {build}from'proofscript';console.log(JSON.stringify(build(JSON.parse(process.argv[2]))));\n");
function build(options){return JSON.parse(f.ok(f.runtime,[...f.flags,program,JSON.stringify(options)]));}
function external(exe,args){
 const r=spawnSync(exe,args,{encoding:'utf8',timeout:240000,maxBuffer:33554432});
 assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;
}
function observe(target,item,result){
 const file=result.runtimeArtifact,directory=path.join(f.directory,'observe',item.id,target);
 fs.mkdirSync(directory,{recursive:true});
 if(['js','ts','wasm-core'].includes(target)){
  const body='let m=await import('+JSON.stringify(pathToFileURL(file).href)+');'+
   (target==='wasm-core'?'m=m.default;':'')+item.consumer+
   '\nconsole.log(JSON.stringify('+observedExpressions[item.id]+'));\n';
  return JSON.parse(f.ok(f.runtime,[...f.flags,'--input-type=module','-e',body]));
 }
 if(target==='rust'){
  const root=f.resources.rustRoot,meta=f.manifest.targetConsumers.rust;
  const sdk=f.resources.tarballs.find(r=>r.package===meta.package);assert.ok(sdk);
  const installed=path.join(f.directory,'node_modules',meta.package);
  const driver=path.join(directory,'consumer.rs'),binary=path.join(directory,'consumer');
  fs.writeFileSync(driver,'extern crate proofscript_generated;use proofscript_generated::*;type PsNat=num_bigint::BigUint;fn main(){'+rustObservations[item.id]+'}');
  const externs=['num_bigint','num_traits'].flatMap(n=>{
   const selected=meta.files.filter(p=>p.path.startsWith('deps/lib'+n+'-')&&p.path.endsWith('.rlib'));
   assert.equal(selected.length,1);return ['--extern',n+'='+path.join(installed,selected[0].path)];
  });
  external(path.join(root,'bin/rustc'),['--edition=2021','--sysroot',root,'-L','dependency='+path.join(installed,'deps'),...externs,
   '--extern','proofscript_generated='+file,driver,'-o',binary]);
  return JSON.parse(external(binary,[]));
 }
 const descriptor=f.manifest.dispatchPackages[target];
 const tool=path.join(f.directory,'node_modules',descriptor.package,descriptor.entry);
 const python=target==='python',driver=path.join(directory,python?'consumer.py':'consumer.php');
 fs.writeFileSync(driver,python?
  'import importlib.util,json,sys\ns=importlib.util.spec_from_file_location("psc1",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)\nprint(json.dumps(eval(sys.argv[2]),ensure_ascii=False))\n':
  '<?php $m=require $argv[1];echo json_encode(eval("return ".$argv[2].";"),JSON_THROW_ON_ERROR)."\\n";\n');
 return JSON.parse(external(tool,[python?'python-run':'php-run',driver,file,(python?pythonObservations:phpObservations)[item.id]]));
}
try{
 for(const engine of ['js','ts'])for(const item of corpus)for(const target of ['js','ts','rust','wasm-core','python','php']){
  const options={engine,target,entryModule:item.entry,assurance:item.assurance,
   sources:item.sources.map(row=>({...row,kind:item.grammar})),publicationProtocol:'portable-file',
   rustToolchainRoot:f.resources.rustRoot,out:path.join(f.directory,'stores',engine,target)};
  const result=build(options),expected=reference.records.find(row=>row.id===item.id&&row.target===target);
  for(const field of ['sourceClosureDigest','admissionsSha256','originalIrSha256','specializedIrSha256','candidateSourceSha256'])
   assert.equal(result.receipt[field],expected[field],item.id+'/'+target+'/'+field);
  assert.equal(result.receipt.sourceSha256,expected.finalSourceSha256);
  assert.equal(result.kernelProviders.join(','),'wasm');
  const actual=observe(target,item,result);assert.deepEqual(actual,expectedObservations[item.id]);assert.deepEqual(actual,expected.actual);
  records.push({engine,target,id:item.id,generation:result.generation,actual,
   sourceSha256:result.receipt.sourceSha256,admissionsSha256:result.receipt.admissionsSha256,
   originalIrSha256:result.receipt.originalIrSha256,specializedIrSha256:result.receipt.specializedIrSha256});
  save();console.log('PSC1_MODULAR_INSTALLED_TARGET '+JSON.stringify({runtime,engine,target,id:item.id}));
 }
 for(const engine of ['js','ts']){
  const store=path.join(f.directory,'stores',engine,'js'),pointer=fs.readFileSync(path.join(store,'current.json'));
  for(const wrong of refusals){
   const options={engine,target:'js',entryModule:'Entry',assurance:wrong.assurance,
    sources:[{module:'Entry',kind:wrong.grammar,text:wrong.source}],publicationProtocol:'portable-file',out:store};
   const refused=f.run(f.runtime,[...f.flags,program,JSON.stringify(options)]);
   assert.notEqual(refused.status,0);assert.match(refused.stderr,wrong.assurance==='verified'?/ASSURANCE/:/COMPILER_REFUSED/);
   assert.deepEqual(fs.readFileSync(path.join(store,'current.json')),pointer);
   negatives.push({engine,id:wrong.id,priorPreserved:true});
  }
  for(const kind of ['lean','ps']){
   const options={engine,target:'wasm-component',entryModule:'Entry',assurance:'checked',
    sources:[{module:'Entry',kind,text:kind==='lean'?'def echo (flag : Bool) : Bool := flag\n':'def echo(flag : Bool) : Bool := flag\n'}],
    publicationProtocol:'portable-file',out:path.join(f.directory,'component',engine,kind)};
   const result=build(options);
   for(const flag of ['false','true'])assert.equal(external(process.env.PSC1_TEST_WASMTIME,['run','--invoke','echo('+flag+')',result.runtimeArtifact]).trim(),flag);
   records.push({engine,target:'wasm-component',id:kind+'-bool-echo',actual:[false,true],generation:result.generation});
  }
 }
 // Every installed owner is ordinary npm code with declared edges and owned bodies.
 const nodes=path.join(f.root,'node_modules'),manifest=JSON.parse(fs.readFileSync(path.join(f.root,'dist/COMPILER_GRAPH.json')));
 assert.equal(manifest.packages.length,20);assert.equal(manifest.units.length,127);
 for(const p of manifest.packages){
  const meta=JSON.parse(fs.readFileSync(path.join(nodes,p.name,'package.json')));
  assert.equal(meta.name,p.name);assert.ok(!Object.hasOwn(meta.dependencies||{},'proofscript'));
  if(!['@proofscript/compiler','@proofscript/cli'].includes(p.name))
   assert.ok(!Object.hasOwn(meta.dependencies||{},'@proofscript/compiler'),p.name+' must not import orchestration');
 }
 const kernelProgram=path.join(f.directory,'kernel.mjs');
 fs.writeFileSync(kernelProgram,"import fs from'node:fs';import{checkCanonicalAdmissions}from'proofscript';const r=await checkCanonicalAdmissions(fs.readFileSync(process.argv[2],'utf8'));if(!r.accepted)throw Error(JSON.stringify(r));console.log(JSON.stringify(r));");
 const admissions=path.join(out,'compiler-admissions.json');
 assert.equal(sha256(fs.readFileSync(admissions)),manifest.admissionsDigest);
 const compilerAdmission=JSON.parse(f.ok(f.runtime,[...f.flags,kernelProgram,admissions]));
 assert.equal(compilerAdmission.accepted,true);report.fullCompilerWasmAdmissionSha256=compilerAdmission.admissionsSha256;
 // Fresh global root-only installation; no hidden source/native checkout is selected.
 const global=fixture({global:true});
 try{
  assert.equal(JSON.parse(global.invoke(['--identity'])).compilerSourceClosureDigest,reference.compilerSourceClosureDigest);
  global.invoke(['init'],global.directory);
  assert.equal(JSON.parse(global.invoke(['check'],global.directory)).logicalAdmission,'accepted');
  const result=JSON.parse(global.invoke(['build','--out','out','--publication-protocol','portable-file'],global.directory));
  assert.equal(global.observe(result),'42');report.globalRootOnlyCheckAndBuild=true;
 }finally{fs.rmSync(global.directory,{recursive:true,force:true});}
 assert.equal(records.length,64);assert.equal(negatives.length,10);
 report.status='passed';
}catch(error){report.status='failed';report.failure=error.message;throw error;}
finally{save();console.log('PSC1_MODULAR_INSTALLED_QUALIFICATION '+JSON.stringify(report));fs.rmSync(f.directory,{recursive:true,force:true});}
