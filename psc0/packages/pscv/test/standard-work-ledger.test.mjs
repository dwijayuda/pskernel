import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {buildStandardWorkLedger} from '../src/standard-work-ledger.mjs';
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const git=p=>execFileSync('git',['-C',root,'show','HEAD:'+p],
 {encoding:'utf8',maxBuffer:2*1024*1024,timeout:15000});
const input=()=>({
 normativeReference:git('pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'),
 typedSource:git('PSCVL/TypedInstanceWitness.lean'),
 concreteSource:git('PSCVL/ConcreteDictionaryWitness.lean'),
 typedTranscript:['instHAdd','instHMul','instHSub','instHAdd','instAppendString',
   'instBEqOfDecidableEq','instBEqOfDecidableEq'].join('\n')+'\n',
 concreteTranscript:['instAddNat','instMulNat','instSubNat','Int.instAdd',
   'instDecidableEqNat','instDecidableEqBool','instAppendString'].join('\n')+'\n',
});
test('complete 230-row/194-ID ledger records zero guessed mappings',()=>{
 const l=buildStandardWorkLedger(input());
 assert.equal(l.requiredRowsCount,230);
 assert.equal(l.requiredIdsCount,194);
 assert.equal(l.previousDirectSourceLocations,3);
 assert.equal(l.unresolvedIdsCount,191);
 assert.equal(l.observedPilotSurfaces,7);
 assert.equal(l.surfaceRows.length,230);
 assert.equal(l.snapshotIds.length,194);
 assert(l.snapshotIds.every(x=>x.requiredBy.length>0));
 assert(l.snapshotIds.every(x=>x.selectedLeanDeclaration===null));
 assert(l.snapshotIds.every(x=>x.allowedStandardInstance===null));
 assert(l.observations.every(x=>!x.dependencyRelationProved));
 assert.equal(l.orderedStandardFrozen,false);
 assert.equal(l.verifiedExecutableAuthorized,false);
 assert.match(l.identitySha256,/^[a-f0-9]{64}$/u);
});
test('normative source, candidate source and output drift refuse the ledger',()=>{
 const x=input();
 const scenarios=[
  {...x,normativeReference:x.normativeReference+'\n'},
  {...x,typedSource:x.typedSource+'\ninstance : HAdd Nat Nat Nat := inferInstance\n'},
  {...x,concreteSource:x.concreteSource.replace('#synth Add Nat','#synth Add Bool')},
  {...x,typedTranscript:x.typedTranscript.replace('instHAdd','bogus')},
  {...x,concreteTranscript:x.concreteTranscript.replace('instAddNat','bogus')},
  {...x,concreteTranscript:x.concreteTranscript+'\nverifiedExecutableAuthorized:true'},
 ];
 for(const s of scenarios)assert.throws(()=>buildStandardWorkLedger(s),
   /PSC_PSCV_(WORK_LEDGER|REQUIRED_SURFACE|TYPED_WITNESS|CONCRETE_DICT)_/u);
});
test('pilot observations do not approve any snapshot ID',()=>{
 const l=buildStandardWorkLedger(input());
 const annotated=l.snapshotIds.filter(x=>x.observedPilotSurfaceIds.length>0);
 assert(annotated.length>0);
 assert(annotated.some(x=>x.snapshotId.startsWith('std.generic.')));
 assert(annotated.every(x=>x.selectedLeanDeclaration===null));
 assert(annotated.every(x=>!x.instanceScopeAndTieOrderProved));
 assert.equal(l.certificateAvailable,false);
});
