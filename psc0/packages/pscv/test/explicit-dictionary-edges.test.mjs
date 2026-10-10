import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {buildArithmeticBatch} from '../src/arithmetic-surface-batch.mjs';
import {prepareDictionaryApplications} from '../src/explicit-dictionary-edges.mjs';
const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const normative=()=>execFileSync('git',['-C',root,'show',
 'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'],{
 encoding:'utf8',timeout:15000,maxBuffer:2*1024*1024,
});
test('fake generic/concrete selected names cannot become typed witness evidence',()=>{
 const normativeReference=normative();
 const batch=buildArithmeticBatch(normativeReference);
 const fake=batch.goals.map(g=>g.goalKind==='generic'?'instHAdd':'instAddNat').join('\n');
 assert.throws(()=>prepareDictionaryApplications({
  normativeReference,source:batch.generatedSource,transcript:fake,
 }),/PSC_PSCV_DICTIONARY_EDGE_PINNED_P1J_IDENTITY/u);
});
test('source identity drift and bogus transcript claims must fail',()=>{
 const normativeReference=normative();
 const batch=buildArithmeticBatch(normativeReference);
 const transcript=batch.goals.map(g=>g.goalKind==='generic'?'instHAdd':'instAddNat').join('\n');
 for(const changed of [
  {normativeReference:normativeReference+'\n',source:batch.generatedSource,transcript},
  {normativeReference,source:batch.generatedSource+'\ninstance : Add Nat := inferInstance',transcript},
  {normativeReference,source:batch.generatedSource,transcript:transcript+'\nfalseCertificate'},
 ])assert.throws(()=>prepareDictionaryApplications(changed),
 /PSC_PSCV_(DICTIONARY_EDGE|ARITHMETIC_BATCH|REQUIRED_SURFACE)_/u);
});
