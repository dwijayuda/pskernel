import assert from 'node:assert/strict';
import {selectPsc1Tests as select} from './select-development-tests.mjs';
assert.deepEqual(select(['psc1/AI_WORK_STATE.md','psc1/docs/old-receipt.json']),{
 static:true,focused:false,integration:false,release:false,benchmark:false,
 paths:['psc1/AI_WORK_STATE.md','psc1/docs/old-receipt.json'],reasons:[]});
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
console.log('PSC1_DEVELOPMENT_SELECTION: PASS doc-only 0 heavy jobs; fixture 2; source 7; full 8 (plus selected benchmark)');

for(const paths of [
 ['psc1/packages/direct/src/Ps/BackendWasm/Module.lean'],
 ['psc1/scripts/compiler-m-conformance-tests.mjs'],
 ['psc1/host-tools/artifacts.mjs'],
 ['.github/workflows/psc1-development.yml']
]){
 const selected=select(paths);
 assert.ok(!selected.release||selected.focused,'full tier requires early native/JS/TS/Rust success');
}
