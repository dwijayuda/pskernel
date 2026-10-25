import assert from 'node:assert/strict';
import {selectPsc1Tests as select,successfulBaseline} from './select-development-tests.mjs';
assert.deepEqual(select(['psc1/AI_WORK_STATE.md','psc1/docs/PSC1_COLLECTIONS_QUALIFICATION_2026-10-21.json']),{
 static:true,focused:false,integration:false,release:false,benchmark:false,
 paths:['psc1/AI_WORK_STATE.md','psc1/docs/PSC1_COLLECTIONS_QUALIFICATION_2026-10-21.json'],reasons:[]});
for(const file of ['psc1/packages/syntax/src/Ps/Syntax/ParseDo.lean','psc1/stdlib/ProofScript/Data/List.lean']){
 const s=select([file]);assert.ok(s.focused&&s.integration);assert.equal(s.release,false);
}
assert.ok(select(['psc1/test/CompilerMFixtures.ps']).focused);
assert.equal(select(['psc1/test/CompilerMFixtures.ps']).integration,false);
for(const file of ['psc1/packages/direct/src/Ps/BackendPython/Module.lean','.github/workflows/psc1-development.yml',
 'psc1/unknown-new-input','psc1/docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json','psc1/host-tools/artifacts.mjs'])
 assert.equal(select([file]).release,true,file);
assert.equal(select(['pskernel/src/ExpressionV2.lean']).focused,false);
assert.equal(select(['psc1/legacy/packages/pskernel-core/src/Ps/Kernel/Expr.lean']).focused,false);
assert.equal(select([],{uncertain:true}).release,true);
assert.equal(select([],{full:true}).release,true);
assert.equal(select(['psc1/scripts/SpecializeQueueBenchmark.lean']).benchmark,true);
assert.equal(select(['psc1/AI_WORK_STATE.md','psc1/test/DataTests.lean']).focused,true);
console.log('PSC1_DEVELOPMENT_SELECTION: PASS static-only docs and dependency-selected fixture/source/full gates');

for(const paths of [
 ['psc1/packages/direct/src/Ps/BackendWasm/Module.lean'],
 ['psc1/scripts/compiler-m-conformance-tests.mjs'],
 ['psc1/host-tools/artifacts.mjs'],
 ['.github/workflows/psc1-development.yml']
]){
 const selected=select(paths);
 assert.ok(!selected.release||selected.focused,'full tier requires early native/JS/TS/Rust success');
}

for(const file of ['psc1/docs/PSC1_STATUS.json','psc1/docs/PSC1_QUALIFICATION_2026-10-21.lean',
 'psc1/docs/selfhost-language/reviewed-candidate.json'])
 assert.equal(select([file]).release,true,file);
assert.equal(select(['.github/workflows/pskernel-expression-v2.yml']).focused,false);

const sha='a'.repeat(40),base='b'.repeat(40),other='c'.repeat(40);
const options={workflowPath:'.github/workflows/psc1-development.yml',branch:'feature',prNumber:172,baseCommit:base,isAncestor:s=>s===sha};
const valid={id:10,display_title:'PSC1 gates base '+base,name:'PSC1 gates base '+base,path:options.workflowPath,head_branch:'feature',head_sha:sha,event:'pull_request',
 status:'completed',conclusion:'success',pull_requests:[{number:172,base:{sha:base}}]};
assert.deepEqual(successfulBaseline([{...valid,id:12,conclusion:'cancelled'},{...valid,id:11,conclusion:'failure'},valid],options),{commit:sha,runId:10});
for(const changed of [{head_sha:other},{head_branch:'other'},{path:'.github/workflows/other.yml'},{event:'push'},
 {pull_requests:[]},{display_title:'PSC1 gates base '+other},{display_title:'old unpinned workflow'}])
 assert.equal(successfulBaseline([{...valid,...changed}],options),null);
assert.equal(successfulBaseline([],options),null);

// GitHub exposes the custom run title as name; workflow file identity stays stable.
assert.deepEqual(successfulBaseline([{...valid,name:'any display title'}],options),{commit:sha,runId:10});

for(const file of ['psc1/scripts/select-development-tests.mjs','psc1/scripts/development-selection-tests.mjs']){
 const result=select([file]);assert.equal(result.focused,false);assert.equal(result.release,false);
 assert.equal(select([file,'psc1/host-tools/artifacts.mjs']).release,true);
 assert.equal(select([file,'psc1/packages/compiler/src/Ps/Compiler/Ordinary.lean']).integration,true);
}


// Only this exact data projection and its always-run pure tests are static-only.
// Contract, readiness gate, source, host, workflow or arbitrary status changes keep their tiers.
for(const file of ['psc1/docs/PSC1_PRACTICAL_CORE_STATUS.json',
 'psc1/docs/history/PSC1_PRACTICAL_CORE_STATUS_BEFORE_V1_2026-10-23.json',
 'psc1/scripts/practical-core-release-status.mjs','psc1/scripts/practical-core-readiness-tests.mjs']){
 const result=select([file]);assert.equal(result.focused,false);assert.equal(result.release,false);
 for(const dependency of ['psc1/scripts/practical-core-readiness.mjs',
  'psc1/docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json','.github/workflows/psc1-development.yml',
  'psc1/packages/elab/src/Ps/Elab/Do.lean','psc1/host-tools/typed-io.mjs']){
  const combined=select([file,dependency]),expected=select([dependency]);
  for(const tier of ['focused','integration','release','benchmark'])assert.equal(combined[tier],expected[tier]);
 }
}
