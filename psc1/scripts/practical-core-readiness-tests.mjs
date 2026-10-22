import assert from 'node:assert/strict';
import fs from 'node:fs';
import {validateReleaseContract,deriveReadiness} from './practical-core-readiness.mjs';
const contract=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json',import.meta.url)));
const commit='a'.repeat(40),clone=value=>structuredClone(value);
validateReleaseContract(contract);
assert.equal(deriveReadiness(contract,{commit}).releaseReady,false);
assert.equal(deriveReadiness(contract,{commit}).counts.blocked,37);
for(const mutate of [
 c=>c.families.pop(),c=>c.targets.pop(),c=>c.grammars.pop(),c=>c.policy.negativeTests=false,
 c=>c.families[0].acceptance.push(c.families[0].acceptance[0]),
 c=>c.families[0].dependsOn.push('local-inference'),
 c=>c.workQueue[0].dependsOn.push('feature-freeze'),c=>c.authority.expressionV2Required=true
]){
 const changed=clone(contract);mutate(changed);assert.throws(()=>validateReleaseContract(changed));
}
const full={schema:'psc1-seven-backend-qualification/1',testedCommit:'b'.repeat(40),
 qualification:'passed-scoped-execution',assurance:{checked:true,explicitOrdinary:true,verifiedRequest:'refused'}};
assert.throws(()=>deriveReadiness(contract,{commit,fullQualification:full}),/stale/);
const spec=contract.suites['compiler-m'];
const caseContract=JSON.parse(fs.readFileSync(new URL('../'+spec.contract,import.meta.url)));
const suites={'compiler-m':{caseContract,implemented:true,receipt:{
 schema:'psc1-language-backend-execution/1',contract:caseContract.id,testedCommit:commit,
 checkerCommit:contract.authority.commit,passed:true,failures:[],targets:['js'],records:[]}}};
assert.throws(()=>deriveReadiness(contract,{commit,suites}),/missing grammar/);
suites['compiler-m'].receipt.testedCommit='b'.repeat(40);
assert.throws(()=>deriveReadiness(contract,{commit,suites}),/stale/);
console.log('PSC1_RELEASE_READINESS_CONTRACT: PASS missing, stale, partial, duplicate and weakened policies refuse');

const io={schema:'psc1-typed-io-application-execution/1',testedCommit:commit,checkerCommit:contract.authority.commit,
 passed:true,failures:[],targets:['js','ts','rust','python','php'],completeFamily:false,sevenHostAdapters:false,
 records:['lean','ps'].flatMap(syntax=>['js','ts','rust','python','php'].map(target=>({
 syntax,target,passed:true,runtime:'executed',admission:'independent-official-Lean',strictIr:'required-by-production-publication',
 checks:['capability-preflight-before-load','actual-json-file-read-transform-atomic-write','actual-console-unicode-crlf-empty-eof'],
 ...Object.fromEntries(['sourceSha256','librarySha256','artifactSha256','manifestSha256','oracleSha256'].map(k=>[k,'a'.repeat(64)]))
 })))};
const ioReport=deriveReadiness(contract,{commit,typedIoApplication:io});
assert.equal(ioReport.releaseReady,false);assert.ok(ioReport.applications.every(a=>a.status==='blocked'));
assert.equal(ioReport.applications.find(a=>a.id==='json-files').ioStatus,'tested');
for(const change of [
 x=>x.testedCommit='b'.repeat(40),x=>x.records.pop(),x=>x.records.push(x.records[0]),
 x=>x.records[0].runtime='skipped',x=>x.records[0].checks=[],x=>x.completeFamily=true
]){
 const changed=clone(io);change(changed);
 assert.throws(()=>deriveReadiness(contract,{commit,typedIoApplication:changed}));
}

for(const selected of [['js','ts','rust'],['python']]){
 const subset={...clone(io),targets:selected,records:clone(io.records.filter(r=>selected.includes(r.target)))};
 const report=deriveReadiness(contract,{commit,typedIoApplication:subset});
 assert.equal(report.applications.find(a=>a.id==='json-files').ioStatus,'tested');
 assert.equal(report.releaseReady,false);
 assert.throws(()=>deriveReadiness(contract,{commit,typedIoApplication:subset,
  fullQualification:{...full,testedCommit:commit}}),/full IO guest matrix/);
}

const binding=(family,id)=>contract.families.find(f=>f.id===family).acceptance.find(c=>c.id===id).execution;
for(const [family,id,suite,caseId] of [
 ['operators','numeric','checked-order','numericCase'],
 ['local-inference','rollback','inference-control','rollbackCase'],
 ['call-inference','telescopes','inference-control','telescopeCase'],
 ['call-inference','refusals','inference-control','callCase']
])assert.deepEqual(binding(family,id),{suite,case:caseId});
assert.deepEqual(binding('operators','short-circuit'),{suite:'checked-order',case:'shortCircuitCase'});
assert.deepEqual(contract.families[0].acceptance.find(c=>c.id==='short-circuit').requiredIoChecks,
 ['short-circuit-skips-foreign-error','short-circuit-error-control-traps']);

for(const [family,id,caseId] of [["typed-do","ownership","ownerLambdaCase"],["early-return","owners","ownerLambdaCase"],["mutation","joins","joinsCase"],["typed-errors","scope","handlerScopeCase"]])
 assert.deepEqual(binding(family,id),{suite:'inference-control',case:caseId});

const requiredNative={
 'for-loops/collections':['psc1_do_tests'],'for-loops/ranges':['psc1_do_tests'],
 'for-loops/streaming':['psc1_do_tests'],
 'partial-definitions/pairing':['psc1_ordinary_tests'],'partial-definitions/recursion':['psc1_ordinary_tests'],
 'tuples-patterns/products':['psc1_data_tests'],'tuples-patterns/identity':['psc1_data_tests'],
 'arrays-indexing/operations':['psc1_data_tests','psc1_do_tests'],
 'namespaces/identity':['psc1_namespace_tests'],'namespaces/ownership':['psc1_namespace_tests']
};
for(const [key,names]of Object.entries(requiredNative)){
 const [family,id]=key.split('/');
 assert.deepEqual(contract.families.find(f=>f.id===family).acceptance.find(c=>c.id===id).requiredNativeSuites,names);
}
for(const id of ['controller','divergence'])
 assert.equal(contract.families.find(f=>f.id==='while-loops').acceptance.find(c=>c.id===id).actualWhile,id);
const meta=(f,id)=>contract.families.find(x=>x.id===f).acceptance.find(x=>x.id===id);
assert.equal(meta('for-loops','streaming').requiredCompilerApplication,true);
assert.equal(meta('tuples-patterns','identity').requiredPatternStrictness,true);
assert.equal(meta('namespaces','identity').requiredNamespacePrivacy,true);
assert.equal(meta('namespaces','ownership').requiredNamespacePrivacy,true);
const d='c'.repeat(64);
const fakeSuite=id=>{
 const spec=contract.suites[id];
 const cases=JSON.parse(fs.readFileSync(new URL('../'+spec.contract,import.meta.url)));
 const records=cases.cases.flatMap(c=>cases.grammars.flatMap(syntax=>cases.targets.map(target=>({
  id:c.id,syntax,target,passed:true,flags:[false,true],admission:'independent-official-Lean',
  strictIr:'required-by-production-publication',runtime:'executed',
  ...Object.fromEntries(['sourceSha256','entrySha256','artifactSha256','manifestSha256','oracleSha256'].map(k=>[k,d])),
  librarySha256:Object.fromEntries(cases.oracleLibraries.map(k=>[k,d])),
  refusals:Object.fromEntries(cases.requiredRefusals.map(k=>[k,d])),
  ...(cases.independentStandardReference?{independentReferenceSha256:d,referenceComparison:'native-standard-operations'}:{})
 }))));
 return {caseContract:cases,implemented:true,receipt:{schema:'psc1-language-backend-execution/1',
  contract:cases.id,testedCommit:commit,checkerCommit:contract.authority.commit,passed:true,failures:[],
  targets:cases.targets,records}};
};
const sourceSuites=Object.fromEntries(['inference-control','stdlib-collections'].map(id=>[id,fakeSuite(id)]));
const status=(report,f,id)=>report.families.find(x=>x.id===f).cases.find(x=>x.id===id).status;
const noNative=deriveReadiness(contract,{commit,suites:sourceSuites,fullQualification:{...full,testedCommit:commit}});
for(const key of Object.keys(requiredNative)){const[f,id]=key.split('/');assert.equal(status(noNative,f,id),'implemented');}
const nativeFull={...full,testedCommit:commit,practicalCore:{
 nativeSuites:['psc1_do_tests','psc1_data_tests','psc1_ordinary_tests','psc1_namespace_tests'].map(suite=>({
  suite,passed:true,logSha256:d,testSha256:d,
  sourceEvaluationCallsExactlyOnce:['evaluationItems','evaluationLower','evaluationUpper','evaluationArray','evaluationIndex']
 })),
 namespaces:{importedHelpersPrivate:true,entryNamespaceExported:true,
  boundaryChecks:['lean','ps'].map(syntax=>({syntax,passed:true,refusalChecks:6,previousArtifactPreservationChecks:5}))}
}};
const nativeReport=deriveReadiness(contract,{commit,suites:sourceSuites,fullQualification:nativeFull});
for(const[f,id]of [['for-loops','collections'],['for-loops','ranges'],['partial-definitions','pairing'],
 ['partial-definitions','recursion'],['tuples-patterns','products'],['arrays-indexing','operations'],['namespaces','identity'],['namespaces','ownership']])
 assert.equal(status(nativeReport,f,id),'qualified');
assert.equal(status(nativeReport,'for-loops','streaming'),'implemented','measured application still required');
assert.equal(status(nativeReport,'tuples-patterns','identity'),'implemented','external pattern deadline still required');
for(const mutate of [
 q=>q.practicalCore.nativeSuites[0].sourceEvaluationCallsExactlyOnce=[],
 q=>q.practicalCore.nativeSuites[0].logSha256='',
 q=>q.practicalCore.nativeSuites[0].testSha256=''
]){
 const changed=clone(nativeFull);mutate(changed);
 const report=deriveReadiness(contract,{commit,suites:sourceSuites,fullQualification:changed});
 assert.equal(status(report,'for-loops','ranges'),'implemented');
 assert.equal(status(report,'arrays-indexing','operations'),'implemented');
}
const wrongPrivacy=clone(nativeFull);wrongPrivacy.practicalCore.namespaces.boundaryChecks[0].previousArtifactPreservationChecks=0;
const privacyReport=deriveReadiness(contract,{commit,suites:sourceSuites,fullQualification:wrongPrivacy});
assert.equal(status(privacyReport,'namespaces','ownership'),'implemented');
assert.equal(privacyReport.releaseReady,false);
console.log('PSC1_BOUNDED_CORE_COMPANIONS: PASS complete source matrices cannot replace native, evaluation-count, strictness, privacy or measured-application evidence');

assert.deepEqual(meta('for-loops','collections').requiredSourceEvaluationOnce,['evaluationItems']);
assert.deepEqual(meta('for-loops','ranges').requiredSourceEvaluationOnce,['evaluationLower','evaluationUpper']);
assert.deepEqual(meta('arrays-indexing','operations').requiredSourceEvaluationOnce,['evaluationArray','evaluationIndex']);

assert.equal(contract.requireReadyOnFullQualification,true,'full qualification must enforce the completed finite contract');

 
// Published status is a data projection, never independent release evidence.
const {releaseStatus,checkpointPath}=await import('./practical-core-release-status.mjs');
const checkpoint=JSON.parse(fs.readFileSync(new URL('../'+checkpointPath,import.meta.url)));
const inventory=JSON.parse(fs.readFileSync(new URL('../docs/PSC1_PRACTICAL_CORE_STATUS.json',import.meta.url)));
assert.deepEqual(inventory,releaseStatus(contract,checkpoint),'stale public release inventory');
for(const mutate of [
 r=>r.sourceCommit='b'.repeat(40),
 r=>r.testedMergeCommit='b'.repeat(40),
 r=>r.finiteScope.targets.pop(),
 r=>r.finiteScope.criteria--,
 r=>r.readiness.counts.qualified--,
 r=>r.allSelectedJobsPassed=false,
 r=>r.jobs=r.jobs.filter(j=>j.name!=='g1 / generated-js'),
 r=>r.jobs.find(j=>j.name==='full / linux-scoped').conclusion='failure',
 r=>r.jobs.find(j=>j.name==='full / linux-scoped').steps[0].conclusion='skipped',
 r=>r.jobs.push(clone(r.jobs[0])),
 r=>r.jobs.find(j=>j.name==='g1 / generated-js').steps=r.jobs.find(j=>j.name==='g1 / generated-js').steps.filter(s=>s.name!=='Seed once and execute actual generated compiler semantics'),
 r=>r.g1.generatedCompilerExecution='pending',
 r=>r.closures[0].canonicalIrBytesParity='refused',
 r=>r.qualification.logicalChecker.commit='b'.repeat(40),
 r=>r.qualification.npm.branchHeadCommit='b'.repeat(40),
 r=>r.qualification.npm.publicationStatus='published'
]){
 const changed=clone(checkpoint);mutate(changed);
 assert.throws(()=>releaseStatus(contract,changed),'inconsistent public evidence must refuse');
}
console.log('PSC1_RELEASE_INVENTORY: PASS stale source, incomplete matrix, failed/skipped/missing/duplicate gates, G1, closure, checker and package identities refuse');
