// The complete modular engines execute the retained authored semantic corpus.
// Every successful target is independently admitted, checked, published and run.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { createExecutableCompilerSession } from '../host-tools/executable/session.mjs';
import { requireSupportedRuntime } from '../host-tools/runtime-policy.mjs';
import { root, read, write, run, sha } from './modular-corpus-common.mjs';

const resources = read(path.join(root,'resources.json'));
const prepared = read(path.join(root,'prepared.json'));
assert.equal(prepared.schema,'psc1-modular-retained-corpus/1');
assert.equal(prepared.testedCommit,process.env.GITHUB_SHA);
assert.equal(resources.testedCommit,process.env.GITHUB_SHA);
assert.equal(resources.legacyCompilerSemanticsExecuted,false);
assert.equal(prepared.records.length,16);
const runtime = requireSupportedRuntime();
const records = [], negatives = [];
const report = { schema:'psc1-modular-semantic-execution/1',testedCommit:process.env.GITHUB_SHA,
  runtime,group:resources.group,status:'running',records,negatives,
  nativeFrontendsDisabled:true,legacyExecutorsDisabled:true,
  compilerSourceClosureDigest:resources.input.graph.compilerSourceClosureDigest,
  independentChecker:'official Lean 4.35.0',defaultDistributionChanged:false,
  fullModularSelfHosting:false };
const evidence = path.join(root,'execution-'+runtime.name+'-'+resources.group);
fs.mkdirSync(evidence,{recursive:true});
const checkpoint = () => write(path.join(evidence,'qualification.json'),report);
function assertBoundary() {
  assert.equal(fs.existsSync(path.join(resources.referencePackage,'selfhost')),false);
  assert.deepEqual(fs.readdirSync('.lake/build/bin').filter(name=>
    fs.lstatSync(path.join('.lake/build/bin',name)).isFile()),['psc1_independent_checker']);
}
let serial=0;
function session(variant,fixture,target,publicationRoot,overrides={}) {
  const adapterFile = path.join(evidence,'adapters',variant+'-'+serial++ + '.mjs');
  fs.mkdirSync(path.dirname(adapterFile),{recursive:true});
  return createExecutableCompilerSession({
    ...resources.graph,variant,adapterFile,
    checkerExecutable:resources.checker,checkerSha256:resources.checkerSha256,
    publicationProtocol:'portable-file',publicationRoot,
    requestId:fixture.id,sources:fixture.sources,entryModule:'Entry',
    assurance:fixture.assurance,target,...resources.consumers[target],...overrides,
  });
}
function consume(target,published,names,directory) {
  fs.mkdirSync(directory,{recursive:true});
  const file = published.runtimeTarget;
  const valueNames = [...names].sort();
  if (['js','ts','wasm-core'].includes(target)) {
    const program = "import assert from 'node:assert/strict';" +
      "let m=await import("+JSON.stringify(pathToFileURL(file).href)+");"+
      (target==='wasm-core'?"m=m.default;":"")+
      "const names="+JSON.stringify(valueNames)+";"+
      "assert.deepEqual(Object.keys(m).sort(),names);"+
      "for(const name of names)for(const flag of [false,true])assert.equal(m[name](flag),true,name);"+
      "console.log(JSON.stringify({calls:names.length*2,accepted:true}));";
    const result=run(process.execPath,['--input-type=module','-e',program]);
    return {calls:names.length*2,events:[{status:result.status,elapsedMs:result.elapsedMs,maxRssKiB:result.maxRssKiB}]};
  }
  if (target==='rust') {
    const sdk=resources.consumers.rust.rust;
    const driver=path.join(directory,'consumer.rs'),binary=path.join(directory,'consumer');
    fs.writeFileSync(driver,'extern crate proofscript_generated;\nfn main(){'+
      names.map(name=>'assert!(proofscript_generated::'+name+'(false));assert!(proofscript_generated::'+name+'(true));').join('')+'}\n');
    run(sdk.rustc,['--edition=2021','--sysroot',sdk.sysroot,'-L','dependency='+sdk.dependencyDirectory,
      ...sdk.externs.flatMap(row=>['--extern',row.name+'='+row.file]),
      '--extern','proofscript_generated='+file,driver,'-o',binary]);
    const result=run(binary,[]);
    return {calls:names.length*2,events:[{status:result.status,elapsedMs:result.elapsedMs,maxRssKiB:result.maxRssKiB}]};
  }
  if (target==='wasm-component') {
    const events=[];
    for (const name of names) for (const flag of ['false','true']) {
      const result=run('wasmtime',['run','--invoke',name+'('+flag+')',file]);
      assert.equal(result.stdout.trim(),'true');
      events.push({status:result.status,elapsedMs:result.elapsedMs,maxRssKiB:result.maxRssKiB});
    }
    return {calls:names.length*2,events};
  }
  const tool=resources.consumers[target].optionalProvider.executable;
  let driver,args;
  if (target==='python') {
    driver=path.join(directory,'consumer.py');
    fs.writeFileSync(driver,'import importlib.util,json,sys\n'+
      's=importlib.util.spec_from_file_location("psc1",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)\n'+
      'names=json.loads(sys.argv[2]);assert sorted(m.__all__)==names\n'+
      'for name in names:\n f=getattr(m,name);assert f(False) is True,name;assert f(True) is True,name\n');
    args=['python-run',driver,file,JSON.stringify(valueNames)];
  } else {
    driver=path.join(directory,'consumer.php');
    fs.writeFileSync(driver,'<?php $m=require $argv[1];$names=json_decode($argv[2],true,512,JSON_THROW_ON_ERROR);'+
      '$keys=array_keys($m);sort($keys);if($keys!==$names)exit(1);'+
      'foreach($names as $name){if($m[$name](false)!==true||$m[$name](true)!==true)exit(2);}\n');
    args=['php-run',driver,file,JSON.stringify(valueNames)];
  }
  const result=run(tool,args);
  return {calls:names.length*2,events:[{status:result.status,elapsedMs:result.elapsedMs,maxRssKiB:result.maxRssKiB}]};
}
try {
  for (const variant of ['js','ts']) for (const fixture of prepared.records) {
    for (const target of resources.targets) {
      assertBoundary();
      const output=path.join(evidence,variant,fixture.id,target);
      const active=session(variant,fixture,target,path.join(output,'store'));
      const admitted=active.execute();
      const compilerTarget=['python','php'].includes(target)?'js':
        target==='wasm-component'?'wasm-core':target;
      const expected=fixture.expected[compilerTarget];
      assert.equal(admitted.logicalAdmission,'accepted');
      assert.equal(admitted.admissionsSha256,expected.admissionsSha256);
      assert.equal(admitted.originalIrSha256,expected.originalIrSha256);
      assert.equal(admitted.specializedIrSha256,expected.specializedIrSha256);
      assert.equal(admitted.candidateSourceSha256,expected.sourceSha256);
      assert.equal(sha(JSON.stringify(read(path.join(active.stagingDirectory,'candidate.json')))),
        expected.candidateSha256);
      const published=active.publish();
      const observation=consume(target,published,fixture.publicNames,path.join(output,'consumer'));
      records.push({variant,id:fixture.id,grammar:fixture.grammar,target,
        contract:fixture.contract.id,cases:fixture.contract.cases.map(row=>row.id),
        oracle:fixture.oracle,sourceModules:fixture.sources.length,
        sourceClosureDigest:admitted.sourceClosureDigest,
        admissionsSha256:admitted.admissionsSha256,originalIrSha256:admitted.originalIrSha256,
        specializedIrSha256:admitted.specializedIrSha256,sourceSha256:admitted.candidateSourceSha256,
        processEvents:active.events,observation,generation:published.generation});
      checkpoint();
      console.log('PSC1_MODULAR_SEMANTIC_TARGET '+JSON.stringify({runtime:runtime.name,
        variant,id:fixture.id,target,calls:observation.calls}));
    }
    if (resources.group==='core') {
      const store=path.join(evidence,variant,fixture.id,'js','store');
      const pointer=fs.readFileSync(path.join(store,'current.json'));
      for (const n of fixture.negatives) {
        const sources=fixture.sources.map(row=>row.module==='Entry'?{...row,text:n.text}:row);
        const refused=session(variant,fixture,'js',store,{requestId:fixture.id+'-'+n.id,sources});
        assert.throws(()=>refused.execute(),new RegExp('COMPILER_REFUSED:'+n.phase));
        assert.throws(()=>refused.publish(),/NOT_ADMITTED/);
        assert.deepEqual(fs.readFileSync(path.join(store,'current.json')),pointer);
        negatives.push({variant,id:fixture.id,case:n.id,phase:n.phase,priorPreserved:true});
      }
      assert.throws(()=>session(variant,fixture,'js',store,{assurance:'verified'}),/REQUEST_INVALID/);
      assert.deepEqual(fs.readFileSync(path.join(store,'current.json')),pointer);
      negatives.push({variant,id:fixture.id,case:'verified-assurance-refused',priorPreserved:true});
    }
  }
  assertBoundary();
  assert.equal(records.length,2*16*resources.targets.length);
  report.status='passed';
} catch(error) {
  report.status='failed';report.failure=error.message;throw error;
} finally { checkpoint(); console.log('PSC1_MODULAR_SEMANTIC_RESULT '+JSON.stringify(report)); }
