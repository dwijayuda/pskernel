import assert from 'node:assert/strict';
import {runJsonProvider} from './run-provider.mjs';
import {makeLongBatchCorpus} from './long-batch-corpus.mjs';
const [native,wasm]=process.argv.slice(2);
if(!native)throw Error('usage: node check-long-batch.mjs <native-lean-exe> [wasm-launcher.cjs]');

const identity={
  protocol:'pskernel-lean-wasm/2',provider:'lean4-cpp',
  leanVersion:'4.35.0',
  leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
  profile:'pscv0-v7.2',
};
function run(exec,args,caseInput){
  return runJsonProvider(exec,args,caseInput,180000);
}
function checkIdentity(result,id){
  for(const [key,value] of Object.entries(identity))
    assert.equal(result?.[key],value,id+' '+key);
}
const runners=[{name:'official-native',exec:native,args:['--check']}];
if(wasm)runners.push({name:'emscripten-wasm',exec:process.execPath,
  args:[wasm,'--check']});
const fixtures=makeLongBatchCorpus();
for(const fixture of fixtures){
  let oracle=null;
  for(const runner of runners){
    const started=Date.now();
    const response=run(runner.exec,runner.args,fixture.input);
    checkIdentity(response,fixture.id+' '+runner.name);
    assert.equal(response.accepted,fixture.accepted,
      fixture.id+' '+runner.name+' accepted');
    if(!fixture.accepted){
      assert.equal(response.errorKind,fixture.errorKind);
      assert.equal(response.declarationIndex,fixture.declarationIndex);
      assert.ok(response.message?.includes(fixture.errorReason),
        fixture.id+' exact semantic rejection');
      assert.ok(!response.message.includes('deterministic-timeout'),
        fixture.id+' timeout must never count as kernel rejection');
    }
    if(oracle)assert.deepEqual(response,oracle,
      fixture.id+' native/wasm response equality');
    else oracle=response;
    console.log('PSC0_WASM_LONG_BATCH: PASS '+fixture.id+' '+
      runner.name+' declarations='+fixture.admissionCount+
      ' payloadBytes='+Buffer.byteLength(fixture.input)+
      ' elapsedMs='+(Date.now()-started));
  }
}
console.log('PSC0_WASM_LONG_BATCH_QUALIFIED '+fixtures.length+
  ' fixtures × '+runners.length+' platform(s)');
