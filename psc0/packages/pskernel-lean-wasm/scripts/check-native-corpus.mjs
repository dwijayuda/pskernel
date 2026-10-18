// Independently qualify the *native*, same-source official Lean kernel
// admission endpoint before spending time on a Wasm differential run.
// Do not bypass errors or reclassify transport failures as invalid proofs.
import assert from 'node:assert/strict';
import {corpus} from './corpus.mjs';
import {runJsonProvider} from './run-provider.mjs';

const native=process.argv[2];
if(!native)throw Error('usage: node check-native-corpus.mjs <native-lean4-executable>');
const health=runJsonProvider(native,['--health']);
assert.deepEqual(health,{
  protocol:'pskernel-lean-wasm/2',
  provider:'lean4-cpp',
  leanVersion:'4.35.0',
  leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
  profile:'pscv0-v7.2',status:'ok',
},'native oracle must be pinned official Lean 4.35.0 and current v7.2');

for(const fixture of corpus){
  const result=runJsonProvider(native,['--check'],fixture.input);
  assert.equal(result.protocol,health.protocol,fixture.id+' protocol');
  assert.equal(result.provider,health.provider,fixture.id+' provider');
  assert.equal(result.leanVersion,health.leanVersion,fixture.id+' version');
  assert.equal(result.leanCommit,health.leanCommit,fixture.id+' commit');
  assert.equal(result.profile,health.profile,fixture.id+' profile');
  assert.equal(result.accepted,fixture.accept,fixture.id+' admission');
  if(!fixture.accept){
    assert.equal(result.errorKind,fixture.errorKind,fixture.id+' rejection kind');
    assert.equal(typeof result.message,'string',fixture.id+' rejection message');
    assert.ok(result.message.length>0,fixture.id+' informative rejection');
  }
  if(fixture.declarationIndex!==undefined)
    assert.equal(result.declarationIndex,fixture.declarationIndex,
      fixture.id+' exact failed admission index');
  console.log('PSC0_LEAN435_NATIVE_CORPUS: PASS '+fixture.id);
}
console.log('PSC0_LEAN435_NATIVE_CORPUS_PASSED '+corpus.length);
