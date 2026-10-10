import assert from 'node:assert/strict';
import { test } from 'node:test';
import { validateAmbientRegistryInventory, registryInventoryProtocol } from '../src/ambient-registry-inventory.mjs';

const base = () => ({
  schemaVersion:0,
  kind:'psc-lean-ambient-registrations/0',
  environment:'PSCVL.Policy imported into Lean 4.35.0-rc3',
  selectedLeanVersion:'4.35.0-rc3',
  instances:[{name:'instNat',priority:1000,resultClassHead:'HAdd',synthOrder:[0],imported:true},{name:'instBool',priority:100,resultClassHead:'BEq',synthOrder:[],imported:false}],
  defaultInstances:[{class:'OfNat',instances:[{name:'OfNatNat',priority:0}]}],
  simpOrigins:[{name:'Nat.add_zero'}],
  simpToUnfold:['Nat.succ'],
  simprocBuiltins:[{name:'simpFn',patternCount:1}],
  simprocLocal:[],
  grindExtNames:['List.ext'],
  grindCases:[{name:'Option',eager:false}],
  directBool:[
    {snapshotId:'Bool.not',logicalDeclaration:'Bool.not',
      internalDeclaration:'Bool.Internal.not',equalityTheorem:'Bool.not_eq_internalNot',
      logicalPresent:true,internalPresent:true,equalityTheoremPresent:true,
      logicalNoncomputable:true,internalNoncomputable:false,
      sourceLineProvenanceChecked:false,runtimeEquivalenceQualified:false,
      pscvVerified:false},
    {snapshotId:'Bool.and',logicalDeclaration:'Bool.and',
      internalDeclaration:'Bool.Internal.and',equalityTheorem:'Bool.and_eq_internalAnd',
      logicalPresent:true,internalPresent:true,equalityTheoremPresent:true,
      logicalNoncomputable:true,internalNoncomputable:false,
      sourceLineProvenanceChecked:false,runtimeEquivalenceQualified:false,
      pscvVerified:false},
    {snapshotId:'Bool.or',logicalDeclaration:'Bool.or',
      internalDeclaration:'Bool.Internal.or',equalityTheorem:'Bool.or_eq_internalOr',
      logicalPresent:true,internalPresent:true,equalityTheoremPresent:true,
      logicalNoncomputable:true,internalNoncomputable:false,
      sourceLineProvenanceChecked:false,runtimeEquivalenceQualified:false,
      pscvVerified:false}
  ],
  rawStateOrderPreserved:false,
  sourceLineProvenanceResolved:false,
  standardRegistryComplete:false,
  coercionsEnumerated:false,
  extTheoremsEnumerated:false,
  grindEmatchComplete:false,
  verificationEffectRegistryComplete:false,
  pscvVerified:false,
  verifiedExecutableAuthorized:false,
});

test('observed Lean environment inventory is never PSCV Standard certification', () => {
  const output=validateAmbientRegistryInventory(base());
  assert.equal(output.kind,registryInventoryProtocol);
  assert.equal(output.state,'observed-lean-registries-not-pscv-standard');
  assert.equal(output.counts.instances,2);
  assert.equal(output.counts.directBool,3);
  assert.equal(output.counts.defaultInstances,1);
  for (const flag of [
    'standardEnvironmentFrozen','registryOrderSemanticsQualified',
    'coercionRegistryQualified','extRegistryQualified',
    'grindAllRulesQualified','simprocRegistryQualified',
    'sourceLineProvenanceQualified','verifiedEffectRegistryQualified',
    'verifiedExecutableAuthorized','pscvVerified',
  ]) assert.equal(output[flag],false,flag);
  assert.match(output.identitySha256,/^[0-9a-f]{64}$/u);
  assert(Object.isFrozen(output));
});

test('canonical identity ignores hash-map enumeration order but changes on priority changes', () => {
  const one=base(),two=base();
  two.instances.reverse();
  assert.equal(validateAmbientRegistryInventory(one).identitySha256,
    validateAmbientRegistryInventory(two).identitySha256);
  two.instances[0].priority=88;
  assert.notEqual(validateAmbientRegistryInventory(one).identitySha256,
    validateAmbientRegistryInventory(two).identitySha256);
});

test('fake authority, missing registries, bogus versions and invented source lines are rejected', () => {
  const broken=[
    {verifiedExecutableAuthorized:true},
    {standardRegistryComplete:true},
    {sourceLineProvenanceResolved:true},
    {rawStateOrderPreserved:true},
    {verificationEffectRegistryComplete:true},
    {coercionsEnumerated:true},
    {extTheoremsEnumerated:true},
    {grindEmatchComplete:true},
    {pscvVerified:true},
    {instances:base().instances.map(x=>({...x,resultClassHead:42}))},
    {instances:base().instances.map(x=>({...x,synthOrder:'0'}))},
    {instances:base().instances.map(x=>({...x,synthOrder:[-1]}))},
    {instances:base().instances.map(x=>({...x,imported:'yes'}))},
    {instances:base().instances.map(x=>({...x,syntheticType:true}))},
    {directBool:[]},
    {directBool:base().directBool.map(x=>({...x,logicalNoncomputable:false}))},
    {directBool:base().directBool.map(x=>({...x,equalityTheoremPresent:false}))},
    {directBool:base().directBool.map(x=>({...x,runtimeEquivalenceQualified:true}))},
    {directBool:base().directBool.map(x=>({...x,sourceLineProvenanceChecked:true}))},
    {directBool:base().directBool.map(x=>({...x,pscvVerified:true}))},
    {selectedLeanVersion:'4.35.0-rc4'},
    {sourceLineProvenance:{'Nat.add_zero':'fake'}},
    {instances:[]},
    {simpOrigins:[]},
    {grindExtNames:['bad\u0000name']},
    {simprocBuiltins:[{name:'oops',patternCount:-1}]},
    {defaultInstances:[{class:'x',instances:[{name:'y',priority:'high'}]}]},
  ];
  for(const changed of broken) {
    assert.throws(()=>validateAmbientRegistryInventory({...base(),...changed}),
      /PSC_PSCV_REGISTRY_INVENTORY_/u,JSON.stringify(changed));
  }
});

test('even empty optional registry groups are reported as unqualified, not silently complete', () => {
  const p=base();p.simprocBuiltins=[];p.grindExtNames=[];
  const output=validateAmbientRegistryInventory(p);
  assert.equal(output.counts.grindExtNames,0);
  assert.equal(output.counts.simprocBuiltins,0);
  assert.equal(output.standardEnvironmentFrozen,false);
  assert.equal(output.verifiedExecutableAuthorized,false);
});
