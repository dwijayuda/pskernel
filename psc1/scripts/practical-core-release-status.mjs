// Data-only projection of an immutable, completed CI checkpoint. Never an admission or publication gate.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {validateReleaseContract} from './practical-core-readiness.mjs';
export const checkpointPath='docs/PSC1_PRACTICAL_CORE_V1_QUALIFICATION_2026-10-23.json';
export const contractBlobSha='1e49d4399d67b87097894047dd7924db04ffed99';
export function checkedFrozenContract(bytes){
 const content=Buffer.from(bytes);
 const blob=createHash('sha1').update('blob '+content.length+'\0').update(content).digest('hex');
 assert.equal(blob,contractBlobSha,'release contract bytes differ from qualified source');
 return JSON.parse(content.toString('utf8'));
}
const frozenContract=checkedFrozenContract(fs.readFileSync(new URL('../docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json',import.meta.url)));
export function releaseStatus(contract,checkpoint){
 validateReleaseContract(contract);
 assert.deepEqual(contract,frozenContract,'contract differs from qualified checkpoint');
 assert.equal(checkpoint.schema,'psc1-practical-core-v1-qualification-checkpoint/1');
 assert.equal(checkpoint.finiteContract,contract.id);
 const sha=value=>assert.match(value||'',/^[a-f0-9]{40}$/);
 for(const name of ['sourceCommit','testedMergeCommit','baseCommit'])sha(checkpoint[name]);
 assert.equal(checkpoint.status,'passed-all-selected-gates-and-finite-release-contract');
 assert.equal(checkpoint.allSelectedJobsPassed,true);
 assert.equal(checkpoint.finiteScope.scopeFrozen,contract.scopeFrozen);
 assert.deepEqual(checkpoint.finiteScope.grammars,contract.grammars);
 assert.deepEqual(checkpoint.finiteScope.targets,contract.targets);
 assert.equal(checkpoint.finiteScope.families,contract.families.length);
 const criteria=contract.families.reduce((n,f)=>n+f.acceptance.length,0);
 assert.equal(checkpoint.finiteScope.criteria,criteria);
 assert.equal(checkpoint.finiteScope.applicationCategories,contract.applications.length);
 assert.deepEqual(checkpoint.readiness,{counts:{implemented:0,tested:0,qualified:criteria,blocked:0},releaseReady:true});
 const qualification=checkpoint.qualification;
 assert.equal(qualification.schema,'psc1-seven-backend-qualification/1');
 assert.equal(qualification.testedCommit,checkpoint.testedMergeCommit);
 assert.equal(qualification.branchHeadCommit,checkpoint.sourceCommit);
 assert.deepEqual(qualification.logicalChecker,{version:contract.authority.version,commit:contract.authority.commit});
 assert.equal(qualification.qualification,'passed-scoped-execution');
 assert.deepEqual(qualification.sourceSyntaxes,contract.grammars);
 assert.ok(Number.isSafeInteger(checkpoint.runId)&&checkpoint.runId>0);
 assert.equal(checkpoint.runUrl,'https://github.com/dwijayuda/pskernel/actions/runs/'+checkpoint.runId);
 assert.equal(qualification.runUrl,checkpoint.runUrl);
 const required=['static','native / native','focused / focused (core)','focused / focused (applications)',
  'focused / php-application','g1 / generated-js','g1 / host-session-boundary',
  'closures / selected-closure (semantic-compiler, checked)',
  'closures / selected-closure (directjs-compiler, ordinary-checked)',
  'closures / selected-closure (rust-compiler, ordinary-checked)','full / linux-scoped','gate'];
 const conditionalSkips={
  'focused / focused (applications)':['Execute focused core and component String and IO boundaries','Execute typed continuation and bounded tail-driver regressions','Execute authored inputs with native references and focused consumers'],
  'focused / focused (core)':['Execute unchanged five-target compiler and CLI applications'],
  'g1 / generated-js':['Sample a failed normal generated process without changing its gate'],
  'closures / selected-closure (rust-compiler, ordinary-checked)':['Enforce the live checked-only partial-source boundary'],
  'closures / selected-closure (semantic-compiler, checked)':['Enforce the live checked-only partial-source boundary']
 };
 const requiredSteps={
  'static':['Check static contracts and source syntax'],
  'native / native':['Execute all independent native control groups','Execute census normalization behavior and source acceptance'],
  'focused / focused (core)':['Execute focused core and component String and IO boundaries','Execute typed continuation and bounded tail-driver regressions','Execute authored inputs with native references and focused consumers'],
  'focused / focused (applications)':['Execute unchanged five-target compiler and CLI applications'],
  'focused / php-application':['Execute both authored compiler and CLI applications with actual PHP IO'],
  'g1 / generated-js':['Seed once and execute actual generated compiler semantics'],
  'g1 / host-session-boundary':['Test real host state and publication with native-prepared replay fixtures'],
  'full / linux-scoped':['Consolidate exact-commit seven-target and package qualification','Derive exact-commit Practical Core readiness'],
  'gate':['Require every selected dependency']
 };
 for(const phase of ['semantic-compiler, checked','directjs-compiler, ordinary-checked','rust-compiler, ordinary-checked'])
  requiredSteps['closures / selected-closure ('+phase+')']=['Check both exact source lanes','Independently admit and strictly validate the whole selected closure'];
 assert.equal(new Set(checkpoint.jobs.map(j=>j.name)).size,checkpoint.jobs.length,'duplicate job');
 for(const name of required){
  const job=checkpoint.jobs.find(j=>j.name===name);assert.ok(job,'missing job '+name);
  assert.equal(job.conclusion,'success',name);assert.ok(job.steps?.length,name);
  assert.ok(job.steps.every(s=>s.conclusion==='success'||s.conclusion==='skipped'&&conditionalSkips[name]?.includes(s.name)),name+' incomplete steps');
  assert.equal(new Set(job.steps.map(s=>s.name)).size,job.steps.length,name+' duplicate steps');
  for(const step of requiredSteps[name])assert.equal(job.steps.find(s=>s.name===step)?.conclusion,'success',name+' missing execution '+step);
 }
 assert.ok(checkpoint.jobs.every(j=>j.conclusion==='success'||j.name==='benchmark'&&j.conclusion==='skipped'));
 assert.equal(checkpoint.g1.generatedCompilerExecution,'passed-G1-selected-corpus');
 assert.equal(checkpoint.g1.cases,10);
 assert.deepEqual(checkpoint.g1.completedCorpusGenerations,[1]);
 assert.equal(checkpoint.g1.fixedPoint,'deferred-feature-freeze');
 assert.deepEqual(checkpoint.closures.map(c=>c.phase).sort(),['directjs-compiler','rust-compiler','semantic-compiler']);
 assert.ok(checkpoint.closures.every(c=>c.passed===true&&c.canonicalAdmissionBytesParity==='accepted'&&c.canonicalIrBytesParity==='accepted'));
 const npm=qualification.npm;
 assert.equal(npm.sourceCommit,checkpoint.testedMergeCommit);
 assert.equal(npm.branchHeadCommit,checkpoint.sourceCommit);
 assert.equal(npm.qualification,'passed');assert.equal(npm.publicationStatus,'unpublished');
 assert.equal(npm.compilerIdentity.leanCommit,contract.authority.commit);
 assert.deepEqual(npm.compilerIdentity.targets,contract.targets);
 return {
  schema:'psc1-practical-core-status/2',name:'PSC1 Practical Core v1',
  authority:'Data-only projection of the finite contract and immutable Linux CI checkpoint; no admission, publication or changed-source authority.',
  contract:'docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json',contractBlobSha,qualificationReceipt:checkpointPath,
  sourceCommit:checkpoint.sourceCommit,testedMergeCommit:checkpoint.testedMergeCommit,baseCommit:checkpoint.baseCommit,
  runId:checkpoint.runId,runUrl:checkpoint.runUrl,
  scope:'frozen-finite-v1-linux',grammars:contract.grammars,targets:contract.targets,
  semanticLean:{version:contract.authority.version,commit:contract.authority.commit},
  counts:checkpoint.readiness.counts,releaseReady:checkpoint.readiness.releaseReady,
  features:contract.families.map(f=>({id:f.id,status:'qualified-finite-v1',
   acceptance:f.acceptance.map(c=>({id:c.id,meaning:c.meaning,status:'qualified'}))})),
  applications:contract.applications.map(a=>({id:a.id,status:'qualified'})),
  queue:contract.workQueue.map(t=>({id:t.id,status:'qualified',dependsOn:t.dependsOn})),
  G1:{status:'qualified-selected-corpus',cases:checkpoint.g1.cases},
  G2G3:{status:'deferred-manual-qualification',defect:'docs/PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md'},
  publication:{status:'unpublished',authorizationRequired:true},
  deferred:contract.deferred,exclusions:checkpoint.exclusions
 };
}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
 const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
 const read=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8'));
 const expected=releaseStatus(read('docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json'),read(checkpointPath));
 const file=path.join(root,'docs/PSC1_PRACTICAL_CORE_STATUS.json');
 if(process.argv.includes('--write'))fs.writeFileSync(file,JSON.stringify(expected,null,2)+'\n');
 else assert.deepEqual(read('docs/PSC1_PRACTICAL_CORE_STATUS.json'),expected,'stale release inventory; run node scripts/practical-core-release-status.mjs --write');
 console.log('PSC1_RELEASE_STATUS: PASS exact finite contract, source, gates, G1, closures and package checkpoint');
}
