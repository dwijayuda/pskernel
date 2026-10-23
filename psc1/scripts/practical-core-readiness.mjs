// CI evidence inventory, never an admission token or proof certificate.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {checkLanguageBackendParity} from './check-language-backend-parity.mjs';
import {checkCompilerApplication} from './check-compiler-application.mjs';
import {checkPracticalApplications} from './check-practical-applications.mjs';
import {checkWhileExecution} from './check-while-execution.mjs';
import {checkTypedIoExecution} from './check-typed-io-execution.mjs';
const familyIds=['operators','local-inference','typed-do','for-loops','while-loops','mutation','early-return',
 'partial-definitions','tuples-patterns','arrays-indexing','typed-errors','call-inference','namespaces','typed-io'];
const targets=['js','ts','rust','wasm-core','wasm-component','python','php'];
export function validateReleaseContract(contract){
 assert.equal(contract.schema,'psc1-practical-core-release-contract/1');
 assert.equal(contract.id,'practical-core-v1');assert.equal(contract.scopeFrozen,true);
 if(contract.requireReadyOnFullQualification!==undefined)assert.equal(contract.requireReadyOnFullQualification,true);
 assert.deepEqual(contract.grammars,['lean','ps']);assert.deepEqual(contract.targets,targets);
 assert.equal(contract.authority.commit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
 assert.equal(contract.authority.expressionV2Required,false);
 assert.deepEqual(contract.families.map(f=>f.id),familyIds);
 for(const key of ['retainWorkingFeatures','portableSemantics','strictOriginalAndTransformedIr','negativeTests','unsupportedAbiRefusal','limitsUnchanged'])
  assert.equal(contract.policy[key],true,key);
 for(const family of contract.families){
  assert.ok(family.acceptance.length);
  assert.equal(new Set(family.acceptance.map(c=>c.id)).size,family.acceptance.length);
  for(const dependency of family.dependsOn)assert.ok(familyIds.includes(dependency)&&dependency!==family.id);
  for(const criterion of family.acceptance){
   assert.ok(criterion.id&&criterion.meaning);
   if(criterion.execution)assert.ok(contract.suites[criterion.execution.suite]);
   if(criterion.actualWhile){
    assert.equal(family.id,'while-loops');assert.equal(criterion.actualWhile,criterion.id);
    assert.ok(['controller','divergence'].includes(criterion.actualWhile));
    assert.ok(contract.actualWhile?.runner&&contract.actualWhile?.receipt&&contract.actualWhile?.minimumReceipt);
   }
   if(criterion.requiredNativeSuites){
    assert.ok(criterion.execution&&criterion.requiredNativeSuites.length);
    assert.equal(new Set(criterion.requiredNativeSuites).size,criterion.requiredNativeSuites.length);
    assert.ok(criterion.requiredNativeSuites.every(id=>['psc1_do_tests','psc1_data_tests','psc1_ordinary_tests','psc1_namespace_tests'].includes(id)));
   }
   if(criterion.requiredSourceEvaluationOnce){
    assert.ok(criterion.requiredNativeSuites?.includes('psc1_do_tests'));
    assert.ok(criterion.requiredSourceEvaluationOnce.every(n=>['evaluationItems','evaluationLower','evaluationUpper','evaluationArray','evaluationIndex'].includes(n)));
   }
   if(criterion.requiredIoChecks){
    assert.equal(family.id,'operators');assert.equal(criterion.id,'short-circuit');
    assert.deepEqual(criterion.execution,{suite:'checked-order',case:'shortCircuitCase'});
    assert.deepEqual(criterion.requiredIoChecks,['short-circuit-skips-foreign-error','short-circuit-error-control-traps']);
   }
   if(criterion.actualIo){assert.equal(family.id,'typed-io');assert.equal(criterion.actualIo,criterion.id);
    assert.ok(['console','files','adapters'].includes(criterion.actualIo));assert.ok(contract.actualIo?.contract&&contract.actualIo?.runner&&contract.actualIo?.receipt);}
  }
 }
 const visited=new Set(),visiting=new Set();
 const visit=id=>{assert.ok(!visiting.has(id),'cyclic family dependencies');if(visited.has(id))return;
  visiting.add(id);for(const d of contract.families.find(f=>f.id===id).dependsOn)visit(d);
  visiting.delete(id);visited.add(id);};
 familyIds.forEach(visit);
 assert.deepEqual(contract.applications.map(a=>a.id),['cli','json-files','multi-module-library','compiler-like']);
 const done=new Set();
 for(const task of contract.workQueue){
  assert.ok(task.id&&task.acceptance&&!done.has(task.id));
  assert.ok(task.dependsOn.every(id=>done.has(id)),'queue must be dependency ordered');
  done.add(task.id);
 }
 return contract;
}
export function deriveReadiness(contract,{commit,suites={},fullQualification=null,typedIoApplication=null,typedIoExecution=null,ioExecutionContract=null,ioExecutionImplemented=false,practicalApplications=null,applicationContract=null,applicationImplemented=false,compilerApplicationReceipt=null,compilerApplicationContract=null,compilerImplemented=false,whileExecution=null,minimumWhileExecution=null,whileExecutionImplemented=false}={}){
 validateReleaseContract(contract);assert.match(commit||'',/^[a-f0-9]{40}$/);
 const suiteStates={};
 for(const [id,{caseContract,receipt,implemented}] of Object.entries(suites)){
  assert.ok(contract.suites[id],'unknown suite');
  assert.deepEqual(caseContract.grammars,contract.grammars);
  assert.deepEqual(caseContract.targets,contract.targets);
  let tested=false,qualified=false;
  if(receipt){
   assert.equal(receipt.schema,'psc1-language-backend-execution/1');
   assert.equal(receipt.contract,caseContract.id);assert.equal(receipt.testedCommit,commit,'stale receipt');
   assert.equal(receipt.checkerCommit,contract.authority.commit);
   assert.equal(receipt.passed,true);assert.deepEqual(receipt.failures,[]);
   checkLanguageBackendParity(caseContract,receipt.records,{targets:receipt.targets});
   tested=true;
   qualified=targets.every(t=>receipt.targets.includes(t));
  }
  suiteStates[id]={caseContract,implemented:implemented===true,tested,qualified};
 }
 const full=fullQualification!==null;
 if(full){
  assert.equal(fullQualification.schema,'psc1-seven-backend-qualification/1');
  assert.equal(fullQualification.testedCommit,commit,'stale full qualification');
  assert.equal(fullQualification.qualification,'passed-scoped-execution');
  assert.ok(fullQualification.assurance?.checked&&fullQualification.assurance?.explicitOrdinary);
  assert.equal(fullQualification.assurance.verifiedRequest,'refused');
 }

 if(typedIoApplication){
  assert.equal(typedIoApplication.schema,'psc1-typed-io-application-execution/1');
  assert.equal(typedIoApplication.testedCommit,commit,'stale IO application evidence');
  assert.equal(typedIoApplication.checkerCommit,contract.authority.commit);
  assert.equal(typedIoApplication.passed,true);assert.deepEqual(typedIoApplication.failures,[]);
  assert.equal(typedIoApplication.completeFamily,false);
  assert.equal(typedIoApplication.sevenHostAdapters,false);
  const ioTargets=typedIoApplication.targets;
  const supportedIoTargets=['js','ts','rust','python','php'];
  assert.ok(Array.isArray(ioTargets)&&ioTargets.length);
  assert.equal(new Set(ioTargets).size,ioTargets.length);
  assert.ok(ioTargets.every(t=>supportedIoTargets.includes(t)));
  if(full)assert.deepEqual(ioTargets,supportedIoTargets,'full IO guest matrix');
  assert.deepEqual(typedIoApplication.records.map(r=>r.syntax+'/'+r.target).sort(),
   ['lean','ps'].flatMap(s=>ioTargets.map(t=>s+'/'+t)).sort(),'complete unique IO subset');
  for(const row of typedIoApplication.records){
   assert.equal(row.passed,true);assert.equal(row.runtime,'executed');
   assert.equal(row.admission,'independent-official-Lean');
   assert.equal(row.strictIr,'required-by-production-publication');
   for(const key of ['sourceSha256','librarySha256','artifactSha256','manifestSha256','oracleSha256'])
    assert.match(row[key]||'',/^[a-f0-9]{64}$/);
   for(const check of ['capability-preflight-before-load','actual-json-file-read-transform-atomic-write','actual-console-unicode-crlf-empty-eof'])
    assert.ok(row.checks.includes(check),'missing actual IO application observation');
  }
 }
 let actualIo=false;
 if(typedIoExecution){
  assert.ok(ioExecutionContract,'IO execution contract required');
  checkTypedIoExecution(ioExecutionContract,typedIoExecution,{commit,checkerCommit:contract.authority.commit});
  actualIo=true;
 }
 let actualApplications=false,allApplicationTargets=false;
 if(practicalApplications){
  assert.ok(applicationContract,'application contract required');
  assert.equal(applicationContract.checkerCommit,contract.authority.commit);
  assert.deepEqual(applicationContract.grammars,contract.grammars);assert.deepEqual(applicationContract.targets,contract.targets);
  checkPracticalApplications(applicationContract,practicalApplications,{commit,targets:practicalApplications.targets});
  actualApplications=true;allApplicationTargets=targets.every(t=>practicalApplications.targets.includes(t));
  if(full)assert.equal(allApplicationTargets,true,'full application matrix required');
 }
 let compilerTested=false,compilerAllTargets=false;
 if(compilerApplicationReceipt){
  assert.ok(compilerApplicationContract,'compiler application contract required');
  assert.equal(compilerApplicationContract.checkerCommit,contract.authority.commit);
  assert.deepEqual(compilerApplicationContract.grammars,contract.grammars);
  assert.deepEqual(compilerApplicationContract.targets,contract.targets);
  checkCompilerApplication(compilerApplicationContract,compilerApplicationReceipt,{commit,targets:compilerApplicationReceipt.targets});
  compilerTested=true;compilerAllTargets=targets.every(t=>compilerApplicationReceipt.targets.includes(t));
  if(full)assert.equal(compilerAllTargets,true,'full compiler application matrix required');
 }
 let actualWhile=false;
 if(whileExecution){
  checkWhileExecution(whileExecution,{commit,checkerCommit:contract.authority.commit});
  if(minimumWhileExecution){
   checkWhileExecution(minimumWhileExecution,{commit,checkerCommit:contract.authority.commit,targets:['python']});
   assert.equal(minimumWhileExecution.oracleSha256,whileExecution.oracleSha256,'different native while oracle');
  }
  actualWhile=minimumWhileExecution!==null;
 }
 const nativeComplete=names=>(names||[]).every(id=>{
  const row=fullQualification?.practicalCore?.nativeSuites?.find(r=>r.suite===id);
  return row?.passed===true&&/^[a-f0-9]{64}$/.test(row.logSha256||'')&&/^[a-f0-9]{64}$/.test(row.testSha256||'');
 });
 const sourceCallsComplete=names=>(names||[]).every(name=>
  fullQualification?.practicalCore?.nativeSuites?.find(r=>r.suite==='psc1_do_tests')?.sourceEvaluationCallsExactlyOnce?.includes(name));
 const namespaceComplete=()=>{
  const n=fullQualification?.practicalCore?.namespaces;
  return n?.importedHelpersPrivate===true&&n?.entryNamespaceExported===true&&
   JSON.stringify(n?.boundaryChecks?.map(r=>r.syntax).sort())===JSON.stringify(['lean','ps'])&&
   n.boundaryChecks.every(r=>r.passed===true&&r.refusalChecks===6&&r.previousArtifactPreservationChecks===5);
 };
 const families=contract.families.map(family=>{
  const cases=family.acceptance.map(criterion=>{
   const binding=criterion.execution,suite=binding&&suiteStates[binding.suite];
   if(binding&&suite)assert.ok(suite.caseContract.cases.some(c=>c.id===binding.case),'unknown finite case');
   if(criterion.actualWhile)return {id:criterion.id,
    status:actualWhile?(full?'qualified':'tested'):whileExecutionImplemented?'implemented':'blocked',
    reason:actualWhile?null:'exact-commit seven-target controller, refusal and external deadline evidence pending',
    execution:null,actualWhile:criterion.actualWhile};
   if(criterion.actualIo)return {id:criterion.id,
    status:actualIo?(full?'qualified':'tested'):ioExecutionImplemented?'implemented':'blocked',
    reason:actualIo?null:'exact-commit seven-adapter execution and policy evidence pending',
    execution:null,actualIo:criterion.actualIo};
   const extraIo=!criterion.requiredIoChecks||actualIo&&criterion.requiredIoChecks.every(check=>
    typedIoExecution.records.every(row=>row.checks.includes(check)));
   const extraNative=nativeComplete(criterion.requiredNativeSuites)&&sourceCallsComplete(criterion.requiredSourceEvaluationOnce);
   const extraPattern=!criterion.requiredPatternStrictness||actualWhile;
   const extraCompiler=!criterion.requiredCompilerApplication||compilerTested&&compilerAllTargets;
   const extraNamespace=!criterion.requiredNamespacePrivacy||namespaceComplete();
   const complete=extraIo&&extraNative&&extraPattern&&extraCompiler&&extraNamespace;
   return {id:criterion.id,status:!binding?'blocked':!suite?.implemented?'blocked':
    suite.qualified&&full&&complete?'qualified':suite.tested&&complete?'tested':'implemented',
    reason:!binding?'finite case not yet bound to an executable acceptance test':
     !suite?.implemented?'fixture or runner missing':!extraIo?'exact-commit seven-adapter foreign-error short-circuit evidence pending':!complete?'exact-commit native, strictness, privacy or measured application companion evidence pending':suite.qualified&&!full?'all targets tested; full exact-commit qualification pending':null,
    execution:binding||null};
  });
  return {id:family.id,qualified:cases.every(c=>c.status==='qualified'),cases};
 });
 // Applications become eligible only with actual application runners and a versioned
 // matrix contract. No generic Boolean fixture is accepted as application evidence.
 const applications=contract.applications.map(a=>{
  const core=a.coreExecution&&suiteStates[a.coreExecution.suite];
  if(a.id==='compiler-like')return {id:a.id,
   status:compilerTested?(compilerAllTargets&&full?'qualified':'tested'):compilerImplemented?'implemented':'blocked',
   reason:compilerTested?null:'actual source parsing, typed locations and 100000-item measured workload pending',
   scope:compilerApplicationContract?.scope||null};

  if(a.completeExecutionSuite){
   const suite=suiteStates[a.completeExecutionSuite];
   assert.equal(a.id,'multi-module-library');
   if(suite){assert.equal(suite.caseContract.id,'multi-module-library-application-v1');assert.deepEqual(suite.caseContract.requiredModules,['PracticalLibrary/Input','PracticalLibrary/Transform']);assert.equal(suite.caseContract.independentStandardReference,true);assert.deepEqual(suite.caseContract.applicationBoundaryChecks,['entry-only-exports','private-imports','missing-module-refusal','duplicate-module-refusal']);}
   return {id:a.id,status:suite?.qualified&&full?'qualified':suite?.tested?'tested':suite?.implemented?'implemented':'blocked',reason:suite?.qualified&&full?null:'exact-commit complete library application and full qualification pending',coreScope:a.coreExecution.scope};
  }
  const bound=applicationContract?.applications.includes(a.id)||['cli','json-files'].includes(a.id)&&contract.actualApplications;
  return {id:a.id,status:bound?(actualApplications?(allApplicationTargets&&full?'qualified':'tested'):applicationImplemented?'implemented':'blocked'):'blocked',reason:bound&&actualApplications?null:a.coreExecution?'typed IO and remaining full application criteria pending':'actual application acceptance runner pending',
   coreStatus:core?.qualified&&full?'qualified-subset':core?.tested?'tested':core?.implemented?'implemented':'blocked',
   coreScope:a.coreExecution?.scope||null,
   ioStatus:['cli','json-files'].includes(a.id)&&(typedIoApplication||actualIo)?(full?'qualified-subset':'tested'):'blocked',
   ioScope:['cli','json-files'].includes(a.id)?(actualIo?
    (actualApplications?'Actual checked CLI/JSON application receipt; library/compiler-like/performance acceptance remains separate':'Seven explicit synchronous IO adapters; complete CLI/JSON application acceptance remains pending'):
    'Linux Node capability host with checked JS/TS/Rust/Python/PHP guests; seven adapters and remaining application criteria pending'):null};
 });
 const familyQualified=id=>families.find(f=>f.id===id)?.qualified===true;
 const queue=contract.workQueue.map(task=>{
  let qualified=false,tested=false,implemented=false;
  if(task.id==='collection-reference'){
   const suite=suiteStates['stdlib-collections'];
   implemented=suite?.implemented;tested=suite?.tested;qualified=suite?.qualified&&full;
  }else if(task.id==='json-application'){
   const suite=suiteStates['json-application'];
   implemented=suite?.implemented;tested=suite?.tested;qualified=suite?.qualified&&full;
  }else if(task.id==='inference-control'){
   implemented=suiteStates['inference-control']?.implemented;tested=suiteStates['inference-control']?.tested;
   qualified=['local-inference','call-inference','typed-do','for-loops','while-loops','mutation','early-return','tuples-patterns','typed-errors'].every(familyQualified);
  }
  else if(task.id==='checked-order'){
   const order=families.find(f=>f.id==='operators')?.cases.find(c=>c.id==='order');
   qualified=order?.status==='qualified';tested=order?.status==='tested';implemented=order?.status==='implemented';
  }
  else if(task.id==='typed-io'){
   implemented=ioExecutionImplemented||suiteStates['typed-io-protocol']?.implemented;tested=actualIo||typedIoApplication!==null;
   qualified=familyQualified('typed-io');
  }
  else if(task.id==='application-performance')qualified=applications.every(a=>a.status==='qualified');
  else if(task.id==='feature-freeze')qualified=families.every(f=>f.qualified)&&applications.every(a=>a.status==='qualified');
  return {id:task.id,status:qualified?'qualified':tested?'tested':implemented?'implemented':'blocked',dependsOn:task.dependsOn};
 });
 return {schema:'psc1-practical-core-readiness/1',contract:contract.id,testedCommit:commit,
  fullScopedQualification:full,families,applications,
  counts:Object.fromEntries(['implemented','tested','qualified','blocked'].map(status=>
   [status,families.flatMap(f=>f.cases).filter(c=>c.status===status).length])),
  queue,deferred:contract.deferred,releaseReady:families.every(f=>f.qualified)&&applications.every(a=>a.status==='qualified'),
  authority:'data-only CI inventory; no publication or admission authority'};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
 const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
 const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
 const contract=read('docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json'),suites={};
 for(const [id,spec] of Object.entries(contract.suites)){
  const exists=p=>fs.existsSync(path.join(root,p));
  suites[id]={caseContract:read(spec.contract),
   receipt:exists(spec.receipt)?read(spec.receipt):null,
   implemented:['.lean','.ps'].every(ext=>exists(spec.fixture+ext))&&exists(spec.runner)};
 }
 const qualification='dist/scoped-correctness/SEVEN_BACKEND_QUALIFICATION.json';
 const report=deriveReadiness(contract,{commit:process.env.GITHUB_SHA,suites,
  fullQualification:fs.existsSync(path.join(root,qualification))?read(qualification):null,
  whileExecutionImplemented:fs.existsSync(path.join(root,contract.actualWhile.runner)),
  whileExecution:fs.existsSync(path.join(root,contract.actualWhile.receipt))?read(contract.actualWhile.receipt):null,
  minimumWhileExecution:fs.existsSync(path.join(root,contract.actualWhile.minimumReceipt))?read(contract.actualWhile.minimumReceipt):null,
  ioExecutionContract:read(contract.actualIo.contract),
  ioExecutionImplemented:fs.existsSync(path.join(root,contract.actualIo.runner))&&
   ['host-tools/typed-io.mjs','host-tools/typed_io.py','host-tools/typed-io-rust/src/lib.rs',
    'host-tools/typed-io.php','host-tools/typed-io-wasm.mjs','host-tools/typed_io_component.py'].every(p=>fs.existsSync(path.join(root,p))),
  compilerApplicationContract:read(contract.actualCompilerApplication.contract),
  compilerImplemented:fs.existsSync(path.join(root,contract.actualCompilerApplication.runner))&&
   ['.lean','.ps'].every(ext=>fs.existsSync(path.join(root,'test/applications/MiniCompiler/Syntax'+ext))),
  compilerApplicationReceipt:fs.existsSync(path.join(root,contract.actualCompilerApplication.receipt))?read(contract.actualCompilerApplication.receipt):null,
  applicationContract:read(contract.actualApplications.contract),
  applicationImplemented:fs.existsSync(path.join(root,contract.actualApplications.runner)),
  practicalApplications:fs.existsSync(path.join(root,contract.actualApplications.receipt))?read(contract.actualApplications.receipt):null,
  typedIoExecution:fs.existsSync(path.join(root,contract.actualIo.receipt))?read(contract.actualIo.receipt):null,
  typedIoApplication:fs.existsSync(path.join(root,'dist/scoped-correctness/typed-io/application.json'))?read('dist/scoped-correctness/typed-io/application.json'):null});
 fs.mkdirSync(path.join(root,'dist/development'),{recursive:true});
 fs.writeFileSync(path.join(root,'dist/development/practical-core-readiness.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_PRACTICAL_CORE_READINESS: '+JSON.stringify({counts:report.counts,releaseReady:report.releaseReady}));
 if(process.argv.includes('--require-ready')||process.argv.includes('--full-qualification')&&contract.requireReadyOnFullQualification)
  assert.equal(report.releaseReady,true,'Practical Core release contract is incomplete');
}
