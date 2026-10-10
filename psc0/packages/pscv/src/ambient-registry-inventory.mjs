/**
 * PSCV P1-B exploratory inventory validator.
 *
 * Reads actual Lean environment-extension data obtained by RegistryProbe.lean.
 * This is an *ambient imported environment*, not the closed PSCV Standard
 * grammar/instance/verification registry. Order is canonicalized for stable
 * review, NOT the elaborator's synthesis/priority/tactic search order.
 */
import { createHash } from 'node:crypto';

export const registryInventoryProtocol = 'psc-ambient-registry-inventory/0';
const hash = text => createHash('sha256').update(text).digest('hex');
const fail = code => { throw new Error('PSC_PSCV_REGISTRY_INVENTORY_' + code); };
const obj = x => x !== null && typeof x === 'object' &&
  !Array.isArray(x) && Object.getPrototypeOf(x) === Object.prototype;
const exact = (x, keys) => obj(x) &&
  Object.keys(x).length === keys.length && keys.every(k => Object.hasOwn(x, k));
const name = x => typeof x === 'string' && x.length > 0 && x.length <= 1024 &&
  !/[\u0000-\u001f]/u.test(x);
const num = x => Number.isSafeInteger(x) && x >= 0 && x <= 1_000_000;
const schemaKeys = [
  'schemaVersion','kind','environment','selectedLeanVersion',
  'instances','defaultInstances','simpOrigins','simpToUnfold',
  'simprocBuiltins','simprocLocal','grindExtNames','grindCases',
  'rawStateOrderPreserved','sourceLineProvenanceResolved',
  'standardRegistryComplete','coercionsEnumerated','extTheoremsEnumerated',
  'grindEmatchComplete','verificationEffectRegistryComplete','pscvVerified',
  'verifiedExecutableAuthorized',
];
const groupKeys = [
  'instances','defaultInstances','simpOrigins','simpToUnfold',
  'simprocBuiltins','simprocLocal','grindExtNames','grindCases',
];
const disabled = [
  'rawStateOrderPreserved','sourceLineProvenanceResolved',
  'standardRegistryComplete','coercionsEnumerated','extTheoremsEnumerated',
  'grindEmatchComplete','verificationEffectRegistryComplete',
  'pscvVerified','verifiedExecutableAuthorized',
];

export function validateAmbientRegistryInventory(input) {
  if (!exact(input, schemaKeys) || input.schemaVersion !== 0 ||
      input.kind !== 'psc-lean-ambient-registrations/0' ||
      input.environment !== 'PSCVL.Policy imported into Lean 4.35.0-rc3' ||
      input.selectedLeanVersion !== '4.35.0-rc3' ||
      disabled.some(k => input[k] !== false) ||
      groupKeys.some(k => !Array.isArray(input[k]) || input[k].length > 400_000)) {
    fail('SCHEMA_OR_AUTHORITY');
  }
  let total = 0;
  for (const key of groupKeys) total += input[key].length;
  if (total > 1_000_000 || input.instances.length < 1 ||
      input.simpOrigins.length < 1) fail('EMPTY_OR_OVERSIZED_ENVIRONMENT');

  const objectEntries = (key, keys, additional) => {
    for (const x of input[key]) {
      if (!exact(x, keys) || !name(x.name) ||
          !additional(x)) fail('INVALID_' + key.toUpperCase());
    }
  };
  objectEntries('instances',['name','priority'],x=>num(x.priority));
  for (const entry of input.defaultInstances) {
    if (!exact(entry,['class','instances']) ||
        !name(entry.class) || !Array.isArray(entry.instances) ||
        entry.instances.length > 100_000 ||
        entry.instances.some(x=>!exact(x,['name','priority']) ||
          !name(x.name) || !num(x.priority))) fail('DEFAULT_INSTANCE_SCHEMA');
  }
  objectEntries('simpOrigins',['name'],()=>true);
  for (const key of ['simpToUnfold','grindExtNames']) {
    if (input[key].some(x=>!name(x))) fail('NAME_SCHEMA_' + key);
  }
  for (const key of ['simprocBuiltins','simprocLocal']) {
    objectEntries(key,['name','patternCount'],x=>num(x.patternCount));
  }
  objectEntries('grindCases',['name','eager'],x=>typeof x.eager==='boolean');

  const canonical = Object.fromEntries(groupKeys.map(key => [
    key, [...input[key]].sort((a,b)=>JSON.stringify(a).localeCompare(JSON.stringify(b),'en')),
  ]));
  // Explicitly exclude arbitrary fields and declare the source *not*
  // authoritative. In particular sorting loses native runtime search order.
  const identity = {
    protocol:registryInventoryProtocol,
    sourceKind:input.kind,
    environment:input.environment,
    sourceLeanVersion:input.selectedLeanVersion,
    groups:canonical,
  };
  const sha256=hash(JSON.stringify(identity));
  return Object.freeze({
    schemaVersion:0,
    kind:registryInventoryProtocol,
    state:'observed-lean-registries-not-pscv-standard',
    identitySha256:sha256,
    environment:input.environment,
    counts:Object.freeze(Object.fromEntries(groupKeys.map(k=>[k,input[k].length]))),
    // No form of "complete" flag may be set by any caller-supplied inventory.
    standardEnvironmentFrozen:false,
    registryOrderSemanticsQualified:false,
    coercionRegistryQualified:false,
    extRegistryQualified:false,
    grindAllRulesQualified:false,
    simprocRegistryQualified:false,
    sourceLineProvenanceQualified:false,
    verifiedEffectRegistryQualified:false,
    verifiedExecutableAuthorized:false,
    pscvVerified:false,
    canonicalObserved:canonical,
  });
}
