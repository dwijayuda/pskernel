// CI evidence inventory, never an admission token or proof certificate.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {checkLanguageBackendParity} from './check-language-backend-parity.mjs';
const familyIds=['operators','local-inference','typed-do','for-loops','while-loops','mutation','early-return',
 'partial-definitions','tuples-patterns','arrays-indexing','typed-errors','call-inference','namespaces','typed-io'];
const targets=['js','ts','rust','wasm-core','wasm-component','python','php'];
export function validateReleaseContract(contract){
 assert.equal(contract.schema,'psc1-practical-core-release-contract/1');
 assert.equal(contract.id,'practical-core-v1');assert.equal(contract.scopeFrozen,true);
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
export function deriveReadiness(contract,{commit,suites={},fullQualification=null,typedIoApplication=null}={}){
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
 const families=contract.families.map(family=>{
  const cases=family.acceptance.map(criterion=>{
   const binding=criterion.execution,suite=binding&&suiteStates[binding.suite];
   if(binding&&suite)assert.ok(suite.caseContract.cases.some(c=>c.id===binding.case),'unknown finite case');
   return {id:criterion.id,status:!binding?'blocked':!suite?.implemented?'blocked':
    suite.qualified&&full?'qualified':suite.tested?'tested':'implemented',
    reason:!binding?'finite case not yet bound to an executable acceptance test':
     !suite?.implemented?'fixture or runner missing':suite.qualified&&!full?'all targets tested; full exact-commit qualification pending':null,
    execution:binding||null};
  });
  return {id:family.id,qualified:cases.every(c=>c.status==='qualified'),cases};
 });
 // Applications become eligible only with actual application runners and a versioned
 // matrix contract. No generic Boolean fixture is accepted as application evidence.
 const applications=contract.applications.map(a=>{
  const core=a.coreExecution&&suiteStates[a.coreExecution.suite];
  return {id:a.id,status:'blocked',reason:a.coreExecution?'typed IO and remaining full application criteria pending':'actual application acceptance runner pending',
   coreStatus:core?.qualified&&full?'qualified-subset':core?.tested?'tested':core?.implemented?'implemented':'blocked',
   coreScope:a.coreExecution?.scope||null,
   ioStatus:['cli','json-files'].includes(a.id)&&typedIoApplication?(full?'qualified-subset':'tested'):'blocked',
   ioScope:['cli','json-files'].includes(a.id)?'Linux Node capability host with checked JS/TS/Rust/Python/PHP guests; seven adapters and remaining application criteria pending':null};
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
  else if(task.id==='checked-order')qualified=familyQualified('operators');
  else if(task.id==='typed-io'){
   implemented=suiteStates['typed-io-protocol']?.implemented;tested=typedIoApplication!==null;
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
  typedIoApplication:fs.existsSync(path.join(root,'dist/scoped-correctness/typed-io/application.json'))?read('dist/scoped-correctness/typed-io/application.json'):null});
 fs.mkdirSync(path.join(root,'dist/development'),{recursive:true});
 fs.writeFileSync(path.join(root,'dist/development/practical-core-readiness.json'),JSON.stringify(report,null,2)+'\n');
 console.log('PSC1_PRACTICAL_CORE_READINESS: '+JSON.stringify({counts:report.counts,releaseReady:report.releaseReady}));
 if(process.argv.includes('--require-ready'))assert.equal(report.releaseReady,true,'Practical Core release contract is incomplete');
}
