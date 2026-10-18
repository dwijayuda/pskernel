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

// Collect all of a costly native build's results before failing the gate.
// Transport failures remain transport failures: they are never accepted as
// an expected semantic rejection. Print the official kernel's exact reason.
let failures=0;
for(const fixture of corpus){
  let result;
  try{result=runJsonProvider(native,['--check'],fixture.input);}
  catch(error){
    failures++;
    console.error('PSC0_LEAN435_NATIVE_CORPUS_TRANSPORT '+fixture.id+': '+String(error));
    continue;
  }
  console.log('PSC0_LEAN435_NATIVE_CORPUS_RESPONSE '+fixture.id+': '+JSON.stringify(result));
  const expected=[
    ['protocol',health.protocol],['provider',health.provider],
    ['leanVersion',health.leanVersion],['leanCommit',health.leanCommit],
    ['profile',health.profile],['accepted',fixture.accept],
  ];
  if(!fixture.accept){
    expected.push(['errorKind',fixture.errorKind]);
    if(typeof result.message!=='string'||result.message.length===0){
      failures++;
      console.error('PSC0_LEAN435_NATIVE_CORPUS_FAIL '+fixture.id+': rejection reason absent');
    }
  }
  if(fixture.declarationIndex!==undefined)
    expected.push(['declarationIndex',fixture.declarationIndex]);
  let caseOk=true;
  for(const [key,value] of expected){
    if(result[key]!==value){
      caseOk=false;failures++;
      console.error('PSC0_LEAN435_NATIVE_CORPUS_FAIL '+fixture.id+' '+key+
        ' expected='+JSON.stringify(value)+' got='+JSON.stringify(result[key]));
    }
  }
  if(caseOk)console.log('PSC0_LEAN435_NATIVE_CORPUS: PASS '+fixture.id);
}
assert.equal(failures,0,'native official Lean 4.35.0 admission corpus failures');
console.log('PSC0_LEAN435_NATIVE_CORPUS_PASSED '+corpus.length);
