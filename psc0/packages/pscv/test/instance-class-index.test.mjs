import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { extractRequiredStandardSurface } from '../src/required-standard-surface.mjs';
import { indexImportedInstanceClassHeads } from '../src/instance-class-index.mjs';
const repoRoot=path.resolve(fileURLToPath(new URL('../../../../',import.meta.url)));
const normative=()=>execFileSync('git',[
  '-C',repoRoot,'show','HEAD:pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md',
],{encoding:'utf8',timeout:15000,maxBuffer:2*1024*1024});
const direct=['not','and','or'].map(x=>({
  snapshotId:'Bool.'+x,logicalDeclaration:'Bool.'+x,
  internalDeclaration:'Bool.Internal.'+x,
  equalityTheorem:'Bool.'+x+'_eq_internal'+x[0].toUpperCase()+x.slice(1),
  logicalPresent:true,internalPresent:true,equalityTheoremPresent:true,
  logicalNoncomputable:true,internalNoncomputable:false,
  sourceLineProvenanceChecked:false,runtimeEquivalenceQualified:false,
  pscvVerified:false,
}));
const raw=()=>({
  schemaVersion:0,kind:'psc-lean-ambient-registrations/0',
  environment:'PSCVL.Policy imported into Lean 4.35.0-rc3',
  selectedLeanVersion:'4.35.0-rc3',
  instances:[
    {name:'declA',priority:1000,resultClassHead:'HAdd',synthOrder:[0],imported:true},
    {name:'declB',priority:900,resultClassHead:'BEq',synthOrder:[],imported:false},
    {name:'declC',priority:1500,resultClassHead:'HAdd',synthOrder:[1,0],imported:true},
    {name:'unknown',priority:1000,resultClassHead:null,synthOrder:[],imported:true},
  ],
  defaultInstances:[],simpOrigins:[{name:'Nat.add_zero'}],
  simpToUnfold:[],simprocBuiltins:[],simprocLocal:[],grindExtNames:[],grindCases:[],
  directBool:direct,
  rawStateOrderPreserved:false,sourceLineProvenanceResolved:false,
  standardRegistryComplete:false,coercionsEnumerated:false,
  extTheoremsEnumerated:false,grindEmatchComplete:false,
  verificationEffectRegistryComplete:false,pscvVerified:false,
  verifiedExecutableAuthorized:false,
});
const fixture=()=>{
  const normativeReference=normative();
  return {normativeReference,rawAmbient:raw(),
    requiredSurface:extractRequiredStandardSurface(normativeReference)};
};

test('typed class-index groups actual instance result heads, NOT source snapshot ID mappings',()=>{
  const x=indexImportedInstanceClassHeads(fixture());
  assert.equal(x.kind,'psc-imported-class-head-review/0');
  assert.equal(x.state,'typed-candidate-index-not-authoritative');
  assert.equal(x.classCount,2);
  assert.equal(x.instancesWithNoSyntacticClassHead,1);
  assert.equal(x.importedInstances,3);
  const hadd=x.classes.find(v=>v.classHead==='HAdd');
  assert.equal(hadd.candidateCount,2);
  assert.deepEqual(hadd.members.map(v=>v.name),['declC','declA']);
  assert.deepEqual(hadd.members[0].synthOrder,[1,0]);
  assert.equal(hadd.members[0].imported,true);
  assert.equal(x.stillUnresolvedSnapshotIds,191);
  assert.equal(x.declarationMappingApproved,false);
  assert.equal(x.importedScopeAndTieOrderQualified,false);
  assert.equal(x.sourceLineProvenanceComplete,false);
  assert.equal(x.standardEnvironmentFrozen,false);
  assert.equal(x.verifiedExecutableAuthorized,false);
  assert.match(x.identitySha256,/^[a-f0-9]{64}$/u);
});

test('candidate identity ignores ambient hash-map order, preserving priority changes',()=>{
  const first=fixture(),other=fixture();
  other.rawAmbient.instances.reverse();
  assert.equal(indexImportedInstanceClassHeads(first).identitySha256,
    indexImportedInstanceClassHeads(other).identitySha256);
  other.rawAmbient.instances[0].priority=2;
  assert.notEqual(indexImportedInstanceClassHeads(first).identitySha256,
    indexImportedInstanceClassHeads(other).identitySha256);
});

test('no guessed snapshot mapping or forged full source authority can slip into the review',()=>{
  const f=fixture();
  for(const change of [
    {rawAmbient:{...f.rawAmbient,instances:f.rawAmbient.instances.map(x=>({...x,approvedForPSCV:true}))}},
    {rawAmbient:{...f.rawAmbient,instances:f.rawAmbient.instances.map(x=>({...x,synthOrder:'all'}))}},
    {rawAmbient:{...f.rawAmbient,instances:[]}},
    {rawAmbient:{...f.rawAmbient,standardRegistryComplete:true}},
    {requiredSurface:{...f.requiredSurface,completeStandardEnvironment:true}},
    {normativeReference:f.normativeReference+'\n'},
  ]) {
    assert.throws(()=>indexImportedInstanceClassHeads({...f,...change}),
      /PSC_PSCV_(INSTANCE_CLASS_INDEX|REGISTRY_INVENTORY|REQUIRED_SURFACE)_/u);
  }
});
