import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { extractRequiredStandardSurface } from '../src/required-standard-surface.mjs';

const repoRoot=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const normative=()=>execFileSync('git',[
  '-C',repoRoot,'show','HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md',
],{encoding:'utf8',timeout:15000,maxBuffer:2*1024*1024});

test('exact PSCV 24.3 guarantees 230 distinct source-defined type/operation rows',()=>{
  const out=extractRequiredStandardSurface(normative());
  assert.equal(out.kind,'psc-required-standard-surface/0');
  assert.equal(out.sourceRowsCount,230);
  assert.equal(out.requiredRows.length,230);
  assert.equal(new Set(out.requiredRows.map(x=>x.id)).size,230);
  assert(out.uniqueReferencedIdsCount>50);
  assert.equal(out.requiredRows.find(x=>x.id==='Bool:!')?.referencedSnapshotIds[0],'Bool.not');
  assert(out.requiredRows.some(x=>x.id==='Nat:+'));
  assert.match(out.sourceDigest,/^[a-f0-9]{64}$/u);
  assert.equal(out.allowedSemanticRegistry,null);
  assert.equal(out.exactInstanceOrderingQualified,false);
  assert.equal(out.declarationMappingsQualified,false);
  assert.equal(out.sourceLineProvenanceQualified,false);
  assert.equal(out.completeStandardEnvironment,false);
  assert.equal(out.verifiedExecutableAuthorized,false);
  assert.equal(out.pscvVerified,false);
});

test('a changed normative source cannot silently add or remove overloaded operations',()=>{
  const orig=normative();
  const changed=orig.replace('| '+String.fromCharCode(96)+'Bool:!', '| '+String.fromCharCode(96)+'Bool:?.');
  assert.notEqual(orig,changed);
  assert.throws(()=>extractRequiredStandardSurface(changed),
    /PSC_PSCV_REQUIRED_SURFACE_REFERENCE_IDENTITY/u);
  assert.throws(()=>extractRequiredStandardSurface(orig+'\n'),
    /PSC_PSCV_REQUIRED_SURFACE_REFERENCE_IDENTITY/u);
});

test('normative required snapshot IDs do not become checked Lean source locators',()=>{
  const out=extractRequiredStandardSurface(normative());
  for(const row of out.requiredRows){
    assert.equal(row.entryResolution,'not-extracted');
    assert.equal(row.sourceLocator,null);
    assert.equal(row.semanticallyValidated,false);
  }
});
