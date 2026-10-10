import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {buildArithmeticBatch} from '../src/arithmetic-surface-batch.mjs';
import {selectedArithmeticNames} from '../src/arithmetic-instance-types.mjs';

const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const normative=()=>execFileSync('git',['-C',root,'show',
 'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'],{
 encoding:'utf8',timeout:15000,maxBuffer:2*1024*1024,
});
const sample=()=>{
 const normativeReference=normative(),plan=buildArithmeticBatch(normativeReference);
 return {normativeReference,generatedSource:plan.generatedSource,
  transcript:plan.goals.map(x=>x.goalKind==='generic'?'instHAdd':'instAddNat').join('\n')+'\n'};
};
test('qualified imported-observation hash cannot be imitated by arbitrary fake instance output',()=>{
 const f=sample();
 assert.throws(()=>selectedArithmeticNames(f),
  /PSC_PSCV_BATCH_DECL_TYPES_PREVIOUS_QUALIFIED_P1J_IDENTITY/u);
});
test('mutating the pinned matrix, generated goals or selected terms refuses evidence',()=>{
 const f=sample();
 for(const x of [
  {...f,normativeReference:f.normativeReference+'\n'},
  {...f,generatedSource:f.generatedSource+'\ninstance : Add Nat := inferInstance'},
  {...f,transcript:f.transcript+'\ninstHAdd'},
  {...f,transcript:f.transcript.replace('instHAdd','sorryAx')},
 ])assert.throws(()=>selectedArithmeticNames(x),
 /PSC_PSCV_(REQUIRED_SURFACE|ARITHMETIC_BATCH|BATCH_DECL_TYPES)_/u);
});
