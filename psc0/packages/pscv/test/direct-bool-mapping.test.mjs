import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { auditDirectBooleanMapping } from '../src/direct-bool-mapping.mjs';
import { extractRequiredStandardSurface } from '../src/required-standard-surface.mjs';
import { extractLeanProvenanceBlueprint } from '../src/lean-provenance.mjs';

const root=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const normative=()=>execFileSync('git',['-C',root,'show',
  'HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md'],{
  encoding:'utf8',timeout:15000,maxBuffer:2*1024*1024,
});
const sample=[
  'noncomputable def Bool.not (x : Bool) : Bool :=',
  'def Bool.Internal.not : Bool → Bool',
  'theorem Bool.not_eq_internalNot : Eq Bool.not Bool.Internal.not :=',
  'noncomputable def Bool.and (x y : Bool) : Bool :=',
  'def Bool.Internal.and (x y : Bool) : Bool :=',
  'theorem Bool.and_eq_internalAnd : Eq Bool.and Bool.Internal.and :=',
  'noncomputable def Bool.or (x y : Bool) : Bool :=',
  'def Bool.Internal.or (x y : Bool) : Bool :=',
  'theorem Bool.or_eq_internalOr : Eq Bool.or Bool.Internal.or :=',
].join('\n');
const operations=[
  ['not','Bool.not_eq_internalNot'],
  ['and','Bool.and_eq_internalAnd'],
  ['or','Bool.or_eq_internalOr'],
];
const rawAmbient=()=>({
  schemaVersion:0,kind:'psc-lean-ambient-registrations/0',
  environment:'PSCVL.Policy imported into Lean 4.35.0-rc3',
  selectedLeanVersion:'4.35.0-rc3',
  instances:[{name:'instNat',priority:1000}],
  defaultInstances:[],simpOrigins:[{name:'Nat.add_zero'}],
  simpToUnfold:[],simprocBuiltins:[],simprocLocal:[],
  grindExtNames:[],grindCases:[],
  directBool:operations.map(([kind,theorem])=>({
    snapshotId:'Bool.'+kind,
    logicalDeclaration:'Bool.'+kind,
    internalDeclaration:'Bool.Internal.'+kind,
    equalityTheorem:theorem,
    logicalPresent:true,internalPresent:true,equalityTheoremPresent:true,
    logicalNoncomputable:true,internalNoncomputable:false,
    sourceLineProvenanceChecked:false,runtimeEquivalenceQualified:false,
    pscvVerified:false,
  })),
  rawStateOrderPreserved:false,sourceLineProvenanceResolved:false,
  standardRegistryComplete:false,coercionsEnumerated:false,
  extTheoremsEnumerated:false,grindEmatchComplete:false,
  verificationEffectRegistryComplete:false,pscvVerified:false,
  verifiedExecutableAuthorized:false,
});
const fixture=()=>{
  const normativeReference=normative();
  return {
    normativeReference,sourceText:sample,
    rawAmbient:rawAmbient(),
    surfaceWorkbook:extractRequiredStandardSurface(normativeReference),
    sourcePath:'src/Init/Prelude.lean',
    gitBlobSha1:extractLeanProvenanceBlueprint(normativeReference).roots
      .find(x=>x.path==='src/Init/Prelude.lean').gitBlobSha1,
  };
};

test('three direct Bool snapshot IDs get source locators; remaining 191 remain unresolved',()=>{
  const actual=auditDirectBooleanMapping(fixture());
  assert.equal(actual.kind,'psc-standard-mapping-review/0');
  assert.equal(actual.status,'partial-verified-Git-source-locators-only');
  assert.equal(actual.mappedDirectBooleanCount,3);
  assert.equal(actual.requiredSnapshotIds,194);
  assert.equal(actual.unresolvedCount,191);
  assert.equal(actual.mappings.length,3);
  assert.deepEqual(actual.mappings.map(x=>x.snapshotId),
    ['Bool.not','Bool.and','Bool.or']);
  for(const entry of actual.mappings){
    assert.equal(entry.logicalDeclaredNoncomputable,true);
    assert.equal(entry.theoremObservedByPinnedLean,true);
    assert.equal(entry.runtimeBridgeQualified,false);
    assert.equal(entry.allowedInClosedStandard,false);
    assert.equal(entry.independentlyKernelReplayed,false);
    assert.equal(entry.pscvVerified,false);
    assert(entry.logicalSourceLine>0);
    assert(entry.internalSourceLine>0);
    assert(entry.equalityTheoremSourceLine>0);
  }
  assert.equal(actual.completeStandardEnvironment,false);
  assert.equal(actual.verifiedExecutableAuthorized,false);
});

test('missing or altered equality theorem cannot be treated as a mapped runtime bridge',()=>{
  const good=fixture();
  for(const sourceText of [
    sample.replace('theorem Bool.not_eq_internalNot','theorem Bool.not_eq_internalNOT'),
    sample.replace('Eq Bool.and Bool.Internal.and','Eq Bool.and Bool.Internal.or'),
    sample.replace('noncomputable def Bool.or','def Bool.or'),
    sample.replace('def Bool.Internal.not','def Bool.Internal.NOt'),
  ]) assert.throws(()=>auditDirectBooleanMapping({...good,sourceText}),
    /PSC_PSCV_DIRECT_BOOL_MAPPING_/u);
});

test('forged compiler environment and non-normative surface worksheet are rejected',()=>{
  const good=fixture();
  for(const change of [
    {sourcePath:'src/Init/Data/Bool.lean'},
    {gitBlobSha1:'0'.repeat(40)},
    {rawAmbient:{...good.rawAmbient,
      directBool:good.rawAmbient.directBool.map(x=>({...x,equalityTheoremPresent:false}))}},
    {rawAmbient:{...good.rawAmbient,
      directBool:good.rawAmbient.directBool.map(x=>({...x,logicalNoncomputable:false}))}},
    {surfaceWorkbook:{...good.surfaceWorkbook,completeStandardEnvironment:true}},
    {normativeReference:good.normativeReference+'\n'},
  ]) assert.throws(()=>auditDirectBooleanMapping({...good,...change}),
    /(PSC_PSCV_DIRECT_BOOL_MAPPING_|PSC_PSCV_REGISTRY_INVENTORY_|PSC_PSCV_PIN_AUDIT_|PSC_PSCV_REQUIRED_SURFACE_)/u);
});
