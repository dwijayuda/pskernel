// CI-only public ABI validation, using the retained generated-target corpus.
// The native oracle phase ends before target resources disable all frontends.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { corpus, refusals, expectedObservations, observedExpressions,
  rustObservations, pythonObservations, phpObservations } from '../../psc1/scripts/generated-target-corpus.mjs';
import { compilerSourceClosureDigest, runIndependentChecker } from '../../psc1/host-tools/compiler-host-protocol.mjs';
import { createExecutableCompilerSession } from '../../psc1/host-tools/executable/session.mjs';
import { requireSupportedRuntime } from '../../psc1/host-tools/runtime-policy.mjs';
import { root, read, write, run, sha } from '../../psc1/scripts/modular-corpus-common.mjs';

const mode=process.argv[2],preparedFile=path.join(root,'public-abi-prepared.json');
const targets=['js','ts','rust','wasm-core','python','php'];
const captured=item=>item.sources.map(source=>({...source,kind:item.grammar}));
if(mode==='prepare') {
  const probe=path.resolve('.lake/build/bin/psc1_output_abi_probe');
  const checker=path.resolve('.lake/build/bin/psc1_independent_checker');
  const records=[];
  for(const fixture of corpus) {
    const sources=captured(fixture),expected={};
    for(const target of ['js','ts','rust','wasm-core']) {
      const wire=['psc1-compiler-service/1',fixture.id,compilerSourceClosureDigest(sources),
        fixture.grammar,fixture.assurance,fixture.entry,sources.map(row=>[row.module,row.text])];
      const input=path.join(root,'abi-native',fixture.id+'-'+target+'.request.json');
      const output=input.replace('.request.json','.candidate.json');
      write(input,wire);
      run('prlimit',['--as=4294967296','--stack=8388608','--',probe,target,input,output],
        {timeoutMs:240000,timeoutPolicy:'standard-240s',
         env:{...process.env,LEAN_MAIN_USE_THREAD:'0',LEAN_NUM_THREADS:'0',LEAN_STACK_SIZE_KB:'8192'}});
      const c=read(output);
      assert.equal(c.status,'candidate',JSON.stringify(c));
      runIndependentChecker(checker,c.admissionRequest.admissions);
      expected[target]={candidateSha256:sha(JSON.stringify(c)),
        admissionsSha256:sha(c.admissionRequest.admissions),
        originalIrSha256:sha(JSON.stringify(c.originalIr)),
        specializedIrSha256:sha(JSON.stringify(c.specializedIr)),sourceSha256:sha(c.source)};
    }
    records.push({id:fixture.id,expected});
  }
  write(preparedFile,{schema:'psc1-modular-public-abi-native/1',
    testedCommit:process.env.GITHUB_SHA,records});
  console.log('PSC1_MODULAR_PUBLIC_ABI_NATIVE '+JSON.stringify({fixtures:records.length,targets:4}));
} else {
  assert.equal(mode,'execute');
  const prepared=read(preparedFile),resources=read(path.join(root,'resources.json'));
  assert.equal(prepared.testedCommit,process.env.GITHUB_SHA);
  assert.equal(resources.testedCommit,process.env.GITHUB_SHA);
  assert.equal(resources.legacyCompilerSemanticsExecuted,false);
  const runtime=requireSupportedRuntime(),records=[],negativeRecords=[];
  const evidence=path.join(root,'public-abi-'+runtime.name);
  const report={schema:'psc1-modular-public-abi/1',status:'running',
    testedCommit:process.env.GITHUB_SHA,compilerControllerCommit:process.env.PSC1_CONTROLLER_COMMIT,
    compilerSourceClosureDigest:resources.input.graph.compilerSourceClosureDigest,
    runtime,records,negatives:negativeRecords,nativeFrontendsDisabled:true,
    referenceExecutorsDisabled:true,defaultDistributionChanged:false,modularG2G3Qualified:false};
  let serial=0;
  const checkpoint=()=>write(path.join(evidence,'qualification.json'),report);
  function boundary() {
    assert.equal(fs.existsSync(path.join(resources.referencePackage,'selfhost')),false);
    assert.deepEqual(fs.readdirSync('.lake/build/bin').filter(name=>
      fs.lstatSync(path.join('.lake/build/bin',name)).isFile()),['psc1_independent_checker']);
  }
  function session(variant,item,target,publicationRoot) {
    const adapterFile=path.join(evidence,'adapters',variant+'-'+serial++ +'.mjs');
    fs.mkdirSync(path.dirname(adapterFile),{recursive:true});
    return createExecutableCompilerSession({...resources.graph,variant,adapterFile,
      requestId:item.id,sources:captured(item),entryModule:item.entry,
      assurance:item.assurance,target,publicationProtocol:'portable-file',publicationRoot,
      checkerExecutable:resources.checker,checkerSha256:resources.checkerSha256,
      ...resources.consumers[target]});
  }
  function observe(target,item,file,directory) {
    fs.mkdirSync(directory,{recursive:true});
    if(['js','ts','wasm-core'].includes(target)) {
      const program='let m=await import('+JSON.stringify(pathToFileURL(file).href)+');'+
        (target==='wasm-core'?'m=m.default;':'')+item.consumer+
        '\nconsole.log(JSON.stringify('+observedExpressions[item.id]+'));\n';
      return JSON.parse(run(process.execPath,['--input-type=module','-e',program]).stdout);
    }
    if(target==='rust') {
      const sdk=resources.consumers.rust.rust,driver=path.join(directory,'consumer.rs'),binary=path.join(directory,'consumer');
      fs.writeFileSync(driver,'extern crate proofscript_generated;use proofscript_generated::*;'+
        'type PsNat=num_bigint::BigUint;fn main(){'+rustObservations[item.id]+'}\n');
      run(sdk.rustc,['--edition=2021','--sysroot',sdk.sysroot,'-L','dependency='+sdk.dependencyDirectory,
        ...sdk.externs.flatMap(row=>['--extern',row.name+'='+row.file]),
        '--extern','proofscript_generated='+file,driver,'-o',binary]);
      return JSON.parse(run(binary,[]).stdout);
    }
    const tool=resources.consumers[target].optionalProvider.executable;
    const python=target==='python',driver=path.join(directory,python?'observe.py':'observe.php');
    fs.writeFileSync(driver,python?
      'import importlib.util,json,sys\ns=importlib.util.spec_from_file_location("psc1",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)\nprint(json.dumps(eval(sys.argv[2]),ensure_ascii=False))\n':
      '<?php $m=require $argv[1];echo json_encode(eval("return ".$argv[2].";"),JSON_THROW_ON_ERROR)."\\n";\n');
    return JSON.parse(run(tool,[python?'python-run':'php-run',driver,file,
      (python?pythonObservations:phpObservations)[item.id]]).stdout);
  }
  try {
    for(const variant of ['js','ts']) {
      for(const item of corpus) for(const target of targets) {
        boundary();
        const store=path.join(evidence,variant,target,'store');
        const active=session(variant,item,target,store),admitted=active.execute();
        const expected=prepared.records.find(row=>row.id===item.id).expected[
          ['python','php'].includes(target)?'js':target];
        for(const field of ['admissionsSha256','originalIrSha256','specializedIrSha256'])
          assert.equal(admitted[field],expected[field]);
        assert.equal(admitted.candidateSourceSha256,expected.sourceSha256);
        assert.equal(sha(JSON.stringify(read(path.join(active.stagingDirectory,'candidate.json')))),
          expected.candidateSha256);
        const published=active.publish(),actual=observe(target,item,published.runtimeTarget,
          path.join(evidence,variant,target,item.id));
        assert.deepEqual(actual,expectedObservations[item.id]);
        records.push({variant,target,id:item.id,logicalAdmission:admitted.logicalAdmission,
          sourceClosureDigest:admitted.sourceClosureDigest,admissionsSha256:admitted.admissionsSha256,
          originalIrSha256:admitted.originalIrSha256,specializedIrSha256:admitted.specializedIrSha256,
          candidateSourceSha256:admitted.candidateSourceSha256,
          finalSourceSha256:admitted.sourceSha256,runtimeArtifactSha256:sha(fs.readFileSync(published.runtimeTarget)),
          actual,processEvents:active.events,generation:published.generation});
        checkpoint();
      }
      const store=path.join(evidence,variant,'js','store');
      const pointer=fs.readFileSync(path.join(store,'current.json'));
      for(const wrong of refusals) {
        const item={id:wrong.id,grammar:wrong.grammar,assurance:wrong.assurance,entry:'Entry',
          sources:[{module:'Entry',text:wrong.source}]};
        if(wrong.assurance==='verified') assert.throws(()=>session(variant,item,'js',store),/REQUEST_INVALID/);
        else {
          const denied=session(variant,item,'js',store);
          assert.throws(()=>denied.execute(),new RegExp('COMPILER_REFUSED:'+wrong.phase));
          assert.throws(()=>denied.publish(),/NOT_ADMITTED/);
        }
        assert.deepEqual(fs.readFileSync(path.join(store,'current.json')),pointer);
        negativeRecords.push({variant,id:wrong.id,phase:wrong.phase,priorPreserved:true});
      }
    }
    boundary();assert.equal(records.length,60);assert.equal(negativeRecords.length,10);
    report.status='passed';
  } catch(error) {report.status='failed';report.failure=error.message;throw error;}
  finally {checkpoint();console.log('PSC1_MODULAR_PUBLIC_ABI_RESULT '+JSON.stringify(report));}
}
