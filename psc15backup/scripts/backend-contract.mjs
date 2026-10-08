import { uniformJsRepresentationProfile, uniformSpecializationContract } from './uniform-specialization.mjs';
import { verifyProfileEnvironment } from './build-context.mjs';
import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { captureClaimConsumerPolicy, decodeClaimSet, verifyClaimSet, evaluateClaimPolicy } from './claim-set.mjs';

const fail = code => { throw new Error('PSC_BACKEND_' + code); };
const bound = { maxBytes: 2 * 1024 * 1024, maxDepth: 32, maxNodes: 60000 };
const copy = value => JSON.parse(canonicalBytes(value, bound));
const equal = (a, b) => canonicalBytes(a, bound).equals(canonicalBytes(b, bound));
const text = value => { if (typeof value !== 'string' || !value || value.length > 4096) fail('TEXT'); return value; };
function exact(value, keys) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...keys].sort().join(',')) fail('SCHEMA');
}
function id(value) {
  exact(value, ['algorithm', 'schemaVersion', 'domain', 'contract', 'byteLength', 'digest']);
  return artifactKey(value);
}
function list(value, check, min = 0) {
  if (!Array.isArray(value) || value.length < min || value.length > 1024) fail('LIST');
  const keys = value.map(check);
  if (new Set(keys).size !== keys.length) fail('DUPLICATE');
}
function read(record, domain, contract) {
  if (!(record?.bytes instanceof Uint8Array) || record.bytes.byteLength > bound.maxBytes) fail('RESOURCE_EXHAUSTED');
  verifyArtifact(record.bytes, record.identity); id(record.identity);
  if (record.identity.domain !== domain || record.identity.contract !== contract) fail('IDENTITY');
  const value = JSON.parse(Buffer.from(record.bytes));
  if (!canonicalBytes(value, bound).equals(Buffer.from(record.bytes))) fail('CANONICAL');
  return value;
}
export const productGroups = Object.freeze(['executableArtifacts', 'publicApiArtifacts', 'debugArtifacts', 'interfaceArtifacts']);
const backendFields = ['backendId', 'backendKind', 'packagePath', 'inputDomain', 'inputContract',
  'lowerPassId', 'targetRepresentationId', 'targetValidatorId', 'emitterId', 'runtimeContractId',
  'selfHostRole', 'assuranceClass', 'supportedCapabilities', 'unsupportedCapabilities', 'products', 'ownershipDebt'];
function registration(value) {
  exact(value, backendFields);
  for (const key of ['backendId', 'packagePath', 'inputDomain', 'inputContract', 'lowerPassId',
    'emitterId', 'runtimeContractId', 'selfHostRole', 'ownershipDebt']) text(value[key]);
  if (!['directTargetIR', 'sourceTarget', 'externalCodegenAdapter'].includes(value.backendKind)) fail('KIND');
  if (!['trustedImplementation', 'proofPreserved', 'certificateValidated', 'translationValidated',
    'targetAcceptedOnly', 'differentialOnly', 'unassured'].includes(value.assuranceClass)) fail('ASSURANCE');
  for (const key of ['targetRepresentationId', 'targetValidatorId']) if (value[key] !== null) text(value[key]);
  if (value.backendKind === 'directTargetIR' && (value.targetRepresentationId === null || value.targetValidatorId === null)) fail('TARGET_IR');
  list(value.supportedCapabilities, text); list(value.unsupportedCapabilities, text);
  if (value.supportedCapabilities.some(item => value.unsupportedCapabilities.includes(item))) fail('CAPABILITY_CONFLICT');
  exact(value.products, productGroups);
  for (const group of productGroups) list(value.products[group], product => {
    exact(product, ['role', 'domain', 'contract', 'requiresToolchain']);
    text(product.domain); text(product.contract);
    if (typeof product.requiresToolchain !== 'boolean') fail('PRODUCT');
    return text(product.role);
  }, group === 'executableArtifacts' ? 1 : 0);
  return value.backendId;
}
export function decodeBackendRegistry(record) {
  const value = read(record, 'backend-registry', 'psc-backend-registry/1');
  exact(value, ['schemaVersion', 'contract', 'masterPlan', 'backendVersion', 'artifactBundleContract', 'backends']);
  if (value.schemaVersion !== 1 || value.contract !== 'psc-backend-registry/1' ||
      value.artifactBundleContract !== 'psc-artifact-bundle/1') fail('REGISTRY');
  text(value.masterPlan); text(value.backendVersion); list(value.backends, registration, 1);
  return value;
}

export const legacyBackendSelectionContract = 'psc-backend-profile-selection/1';
export const backendSelectionContract = 'psc-backend-profile-selection/2';
export const uniformJavaScriptDerivationV2 = 'psc-uniform-js-backend-derivation/2';
export const uniformJavaScriptDerivation = 'psc-uniform-js-backend-derivation/3';
export const uniformJavaScriptDeclarationMapDerivation = 'psc-uniform-js-backend-derivation/4';
export const uniformJavaScriptMapLinkDerivation = 'psc-uniform-js-backend-derivation/5';

/** A deterministic specialization of the existing registry, not a fifth lane.
 * The base remains a separately identified input. A selected registry does not
 * establish runtime preservation or authorize a checked-session policy.
 */
export function selectUniformJavaScriptRegistryV1(baseRecord) {
  const value = decodeBackendRegistry(baseRecord);
  if (value.backends.map(item => item.backendId).sort().join(',') !== 'javascript,rust,typescript,wasm')
    fail('SELECTION_BASE_LANES');
  const backend = value.backends.find(item => item.backendId === 'javascript');
  if (backend.backendKind !== 'directTargetIR' || backend.inputDomain !== 'specialized-ir' ||
      backend.inputContract !== 'psc-runtime-ir-json/1' ||
      backend.lowerPassId !== 'psc-specialized-ir-to-js-ir/1' ||
      backend.targetRepresentationId !== 'psc-js-ir-json/1' ||
      backend.targetValidatorId !== 'psc-js-ir-validator/1' ||
      backend.emitterId !== 'psJsEmitValidatedModuleStackSafeWithTargetProfile') fail('SELECTION_BASE');
  backend.inputDomain = 'uniform-specialized-ir';
  backend.inputContract = uniformSpecializationContract;
  backend.lowerPassId = 'psc-uniform-ir-to-js-ir/1';
  // The selected staged API consumes the uniform wrapper; its final writer is
  // the same validated JsIR writer used by the closed profile.
  backend.emitterId = 'psCompilerUniformJavaScriptStagesFromPrepared';
  backend.supportedCapabilities = backend.supportedCapabilities.filter(capability =>
    !['standalone-declaration-source-maps', 'closed-structural-source-declarations'].includes(capability));
  backend.supportedCapabilities.push('uniform-generic-runtime-exports', 'uniform-structural-source-declarations');
  backend.unsupportedCapabilities = backend.unsupportedCapabilities.filter(capability =>
    capability !== 'generic-and-dependent-source-declarations');
  backend.unsupportedCapabilities.push('dependent-and-higher-rank-source-declarations', 'generic-constant-declarations',
    'uniform-source-map-composition', 'uniform-imports');
  backend.products.debugArtifacts = backend.products.debugArtifacts.filter(product =>
    !['specialization-instances', 'declaration-lineage', 'source-map', 'source-map-recipe'].includes(product.role));
  backend.ownershipDebt = 'Explicit uniform JS representation retains validated generic RuntimeIR. Generic function declarations are source-derived. Uniform source-map composition, named/dependent public types, portable declaration serializers, checked CLI selection and global preservation remain pending.';
  const registry = canonicalArtifact(value, 'backend-registry', 'psc-backend-registry/1');
  decodeBackendRegistry(registry);
  const selection = canonicalArtifact({ schemaVersion: 1, contract: legacyBackendSelectionContract,
    backendId: 'javascript', profile: uniformJsRepresentationProfile,
    baseRegistryId: baseRecord.identity, selectedRegistryId: registry.identity, authority: 'audit-record-only' },
  'backend-profile-selection', legacyBackendSelectionContract);
  return { registry, selection };
}

/** Versioned derivations preserve historical selection bytes. The backend
 * emitter remains backend-owned; driver composition is separately identified.
 * Future capabilities require a new derivation identity and retained readers.
 */
export function selectUniformJavaScriptRegistry(baseRecord, { derivationId = uniformJavaScriptDerivation } = {}) {
  if (![uniformJavaScriptDerivationV2, uniformJavaScriptDerivation, uniformJavaScriptDeclarationMapDerivation, uniformJavaScriptMapLinkDerivation].includes(derivationId)) fail('SELECTION_DERIVATION');
  const value = decodeBackendRegistry(selectUniformJavaScriptRegistryV1(baseRecord).registry);
  const backend = value.backends.find(item => item.backendId === 'javascript');
  backend.emitterId = 'psJsEmitValidatedModuleStackSafeWithTargetProfile';
  backend.supportedCapabilities.push('portable-structural-source-declarations');
  backend.ownershipDebt = 'Explicit uniform representation retains validated generic RuntimeIR. The backend owns the shared validated JsIR writer; interface-ts owns portable source declarations and the driver composes them. Uniform source-map composition, named/dependent public types, checked CLI selection and global preservation remain pending.';
  if ([uniformJavaScriptDerivation, uniformJavaScriptDeclarationMapDerivation, uniformJavaScriptMapLinkDerivation].includes(derivationId)) {
    backend.supportedCapabilities.push('standalone-declaration-source-maps');
    backend.unsupportedCapabilities = backend.unsupportedCapabilities.filter(capability => capability !== 'uniform-source-map-composition');
    backend.products.debugArtifacts.push(
      { role: 'declaration-lineage', domain: 'declaration-lineage', contract: 'psc-js-uniform-declaration-lineage/1', requiresToolchain: false },
      { role: 'source-map', domain: 'source-map-output', contract: 'psc-direct-javascript-source-map/1', requiresToolchain: false },
      { role: 'source-map-recipe', domain: 'source-map-recipe', contract: 'psc-direct-javascript-source-map-recipe/2', requiresToolchain: false });
    backend.ownershipDebt = 'The backend owns the validated JsIR writer, interface-ts owns portable source declarations and the driver composes them. Uniform declaration origins use exact retained RuntimeIR inventory with shared source-map encoding. Expression origins, declaration maps, named/dependent public types, checked CLI selection and global preservation remain pending.';
  }
  if ([uniformJavaScriptDeclarationMapDerivation, uniformJavaScriptMapLinkDerivation].includes(derivationId)) {
    const expected = [
      ['declaration-positions', 'declaration-positions', 'psc-js-declaration-positions/1'],
      ['declaration-map', 'declaration-map-output', 'psc-direct-js-declaration-map/1'],
      ['declaration-map-recipe', 'declaration-map-recipe', 'psc-direct-js-declaration-map-recipe/1'],
    ];
    if (value.backendVersion !== (derivationId === uniformJavaScriptMapLinkDerivation ? 'psc-v5-backends/3' : 'psc-v5-backends/2') ||
        expected.some(([role, domain, contract]) => !backend.products.debugArtifacts.some(product =>
          product.role === role && product.domain === domain && product.contract === contract && !product.requiresToolchain)) ||
        !backend.supportedCapabilities.includes('standalone-source-declaration-maps')) fail('SELECTION_DECLARATION_MAP_BASE');
    backend.ownershipDebt = 'Uniform source signatures and exact declaration origins feed standalone declaration maps. The source writer retains generic binders and shares coordinate composition with JavaScript maps. Expression/token origins, linking, broader named/dependent types and global preservation remain pending.';
    if (derivationId === uniformJavaScriptMapLinkDerivation) {
      const products = backend.products, required = [
        ['executableArtifacts', 'linked-javascript', 'linked-javascript-output', 'psc-direct-js-linked-javascript/1'],
        ['publicApiArtifacts', 'linked-declarations', 'linked-declarations-output', 'psc-direct-js-linked-declarations/1'],
        ['debugArtifacts', 'source-map-link-recipe', 'source-map-link-recipe', 'psc-direct-js-source-map-link/1'],
      ];
      if (!backend.supportedCapabilities.includes('explicit-source-map-linking') ||
          required.some(([group, role, domain, contract]) => !products[group].some(item =>
            item.role === role && item.domain === domain && item.contract === contract && !item.requiresToolchain)))
        fail('SELECTION_LINK_BASE');
      backend.ownershipDebt = 'Uniform source signatures and origin maps feed explicit linked output packaging without changing original source signatures or declaring preservation.';
    }
  }
  const registry = canonicalArtifact(value, 'backend-registry', 'psc-backend-registry/1');
  decodeBackendRegistry(registry);
  const selection = canonicalArtifact({ schemaVersion: 2, contract: backendSelectionContract,
    backendId: 'javascript', profile: uniformJsRepresentationProfile, derivationId,
    pipelineEntry: { packagePath: 'packages/driver-js', entryId: 'psCompilerUniformJavaScriptStagesFromPrepared' },
    baseRegistryId: baseRecord.identity, selectedRegistryId: registry.identity, authority: 'audit-record-only' },
  'backend-profile-selection', backendSelectionContract);
  return { registry, selection };
}

export async function verifyBackendProfileSelection(record, { expectedRegistryId, resolveArtifact }) {
  const contract = record?.identity?.contract;
  if (![legacyBackendSelectionContract, backendSelectionContract].includes(contract)) fail('SELECTION_VERSION');
  const current = contract === backendSelectionContract;
  const value = read(record, 'backend-profile-selection', contract);
  exact(value, ['schemaVersion', 'contract', 'backendId', 'profile', 'baseRegistryId', 'selectedRegistryId', 'authority',
    ...(current ? ['derivationId', 'pipelineEntry'] : [])]);
  if (value.schemaVersion !== (current ? 2 : 1) || value.contract !== contract ||
      value.backendId !== 'javascript' || value.profile !== uniformJsRepresentationProfile ||
      value.authority !== 'audit-record-only' || id(value.selectedRegistryId) !== id(expectedRegistryId)) fail('SELECTION');
  if (current) {
    exact(value.pipelineEntry, ['packagePath', 'entryId']);
    if (value.pipelineEntry.packagePath !== 'packages/driver-js' ||
        value.pipelineEntry.entryId !== 'psCompilerUniformJavaScriptStagesFromPrepared') fail('SELECTION_PIPELINE');
  }
  const base = { identity: value.baseRegistryId, bytes: await resolveArtifact(value.baseRegistryId) };
  const rebuilt = current ? selectUniformJavaScriptRegistry(base, { derivationId: value.derivationId }) :
    selectUniformJavaScriptRegistryV1(base);
  if (!equal(rebuilt.selection.identity, record.identity) || !equal(rebuilt.registry.identity, expectedRegistryId))
    fail('SELECTION_BINDING');
  const selected = await resolveArtifact(expectedRegistryId); verifyArtifact(selected, expectedRegistryId);
  return { profile: value.profile, selectionId: record.identity, registryId: expectedRegistryId,
    selectionContract: contract, ...(current ? { derivationId: value.derivationId } : {}),
    emitterRole: current ? 'backend-writer' : 'historical-driver-entry',
    bindingVerified: true, authority: 'audit-record-only', preservationVerified: false };
}

const bindings = ['backendId', 'implementationId', 'targetProfileId', 'externalToolchainId', 'interfaceAdapterId'];
export function createBackendDescriptor(registryRecord, fields) {
  const registry = decodeBackendRegistry(registryRecord), selected = copy(fields);
  exact(selected, bindings);
  text(selected.backendId); id(selected.implementationId); id(selected.targetProfileId);
  for (const key of ['externalToolchainId', 'interfaceAdapterId']) if (selected[key] !== null) id(selected[key]);
  const backend = registry.backends.find(item => item.backendId === selected.backendId);
  if (!backend) fail('UNREGISTERED');
  return canonicalArtifact({ schemaVersion: 1, contract: 'psc-backend-descriptor/1',
    registryId: registryRecord.identity, backendVersion: registry.backendVersion,
    artifactBundleContract: registry.artifactBundleContract, ...backend, ...selected },
  'backend-descriptor', 'psc-backend-descriptor/1');
}
export function decodeBackendDescriptor(record) {
  const value = read(record, 'backend-descriptor', 'psc-backend-descriptor/1');
  exact(value, [...backendFields, 'schemaVersion', 'contract', 'registryId', 'backendVersion',
    'artifactBundleContract', ...bindings.filter(key => key !== 'backendId')]);
  if (value.schemaVersion !== 1 || value.contract !== 'psc-backend-descriptor/1' ||
      value.artifactBundleContract !== 'psc-artifact-bundle/1') fail('DESCRIPTOR');
  const fields = Object.fromEntries(backendFields.map(key => [key, value[key]])); registration(fields);
  id(value.registryId); text(value.backendVersion); id(value.implementationId); id(value.targetProfileId);
  for (const key of ['externalToolchainId', 'interfaceAdapterId']) if (value[key] !== null) id(value[key]);
  return value;
}
function bundleValue(record) {
  const value = read(record, 'artifact-bundle', 'psc-artifact-bundle/1');
  exact(value, ['schemaVersion', 'contract', 'authority', 'backendId', 'backendDescriptorId',
    'sourceSubjectId', 'profileEnvironmentId', 'claimSetId', ...productGroups,
    'targetToolchainArtifacts', 'evidenceArtifacts']);
  if (value.schemaVersion !== 1 || value.contract !== 'psc-artifact-bundle/1' || value.authority !== 'audit-record-only') fail('BUNDLE');
  text(value.backendId);
  for (const key of ['backendDescriptorId', 'sourceSubjectId', 'profileEnvironmentId', 'claimSetId']) id(value[key]);
  if (value.profileEnvironmentId.domain !== 'profile-environment' ||
      value.profileEnvironmentId.contract !== 'psc-profile-environment/1') fail('PROFILE_ENVIRONMENT');
  if (value.claimSetId.domain !== 'claim-set' || value.claimSetId.contract !== 'psc-claim-set/1') fail('CLAIM_SET');
  const artifacts = new Set();
  for (const group of productGroups) list(value[group], product => {
    exact(product, ['role', 'artifact']);
    const key = id(product.artifact);
    if (artifacts.has(key)) fail('PRODUCT_IN_MULTIPLE_GROUPS'); artifacts.add(key);
    return text(product.role);
  }, group === 'executableArtifacts' ? 1 : 0);
  for (const group of ['targetToolchainArtifacts', 'evidenceArtifacts']) list(value[group], id);
  return value;
}
function productsMatch(value, descriptor) {
  if (value.backendId !== descriptor.backendId) fail('BACKEND_MISMATCH');
  const toolchainKeys = new Set(value.targetToolchainArtifacts.map(id));
  for (const group of productGroups) for (const product of value[group]) {
    const spec = descriptor.products[group].find(item => item.role === product.role);
    if (!spec || spec.domain !== product.artifact.domain || spec.contract !== product.artifact.contract) fail('UNSUPPORTED_PRODUCT');
    if (spec.requiresToolchain && (!descriptor.externalToolchainId || !toolchainKeys.has(id(descriptor.externalToolchainId)))) fail('TOOLCHAIN_REQUIRED');
  }
}
/** Identified products only. No claims are inferred from output presence. */
export function createArtifactBundle({ descriptor, ...fields }) {
  const backend = decodeBackendDescriptor(descriptor);
  exact(fields, ['sourceSubjectId', 'profileEnvironmentId', 'claimSetId', ...productGroups,
    'targetToolchainArtifacts', 'evidenceArtifacts']);
  const value = copy({ schemaVersion: 1, contract: 'psc-artifact-bundle/1', authority: 'audit-record-only',
    backendId: backend.backendId, backendDescriptorId: descriptor.identity, ...fields });
  const record = canonicalArtifact(value, 'artifact-bundle', 'psc-artifact-bundle/1');
  productsMatch(bundleValue(record), backend);
  return record;
}
export function decodeArtifactBundle(record) { return bundleValue(record); }

/** Requires an independently selected bundle identity. All product groups have
 * separate identities; debug products can never satisfy an evidence requirement.
 */
export async function verifyArtifactBundle(record, { expectedBundleId, resolveArtifact, claimVerification, claimPolicy } = {}) {
  const consumer = captureClaimConsumerPolicy({ claimVerification, claimPolicy });
  const value = bundleValue(record), bundleIdentity = copy(record.identity);
  if (id(expectedBundleId) !== id(bundleIdentity) || typeof resolveArtifact !== 'function') fail('CONSUMER_POLICY');
  const resolved = new Map();
  async function resolve(identity) {
    const key = id(identity);
    if (!resolved.has(key)) {
      const bytes = Buffer.from(await resolveArtifact(copy(identity))); verifyArtifact(bytes, identity); resolved.set(key, bytes);
    }
    return { identity: copy(identity), bytes: Buffer.from(resolved.get(key)) };
  }
  const descriptorRecord = await resolve(value.backendDescriptorId), descriptor = decodeBackendDescriptor(descriptorRecord);
  const registry = await resolve(descriptor.registryId);
  const rebound = createBackendDescriptor(registry, Object.fromEntries(bindings.map(key => [key, descriptor[key]])));
  if (!equal(rebound.identity, descriptorRecord.identity)) fail('DESCRIPTOR_REGISTRY_BINDING');
  productsMatch(value, descriptor);
  for (const identity of [descriptor.implementationId, descriptor.targetProfileId,
    ...(descriptor.externalToolchainId ? [descriptor.externalToolchainId] : []),
    ...(descriptor.interfaceAdapterId ? [descriptor.interfaceAdapterId] : []),
    value.sourceSubjectId, value.profileEnvironmentId, ...value.targetToolchainArtifacts, ...value.evidenceArtifacts,
    ...productGroups.flatMap(group => value[group].map(item => item.artifact))]) await resolve(identity);
  await verifyProfileEnvironment(await resolve(value.profileEnvironmentId), {
    expectedProfileEnvironmentId: value.profileEnvironmentId, resolveArtifact: async identity => (await resolve(identity)).bytes });
  const selections = value.evidenceArtifacts.filter(identity => identity.domain === 'backend-profile-selection');
  let profileSelection;
  if (descriptor.inputDomain === 'uniform-specialized-ir') {
    if (descriptor.backendId !== 'javascript' || descriptor.inputContract !== uniformSpecializationContract ||
        selections.length !== 1) fail('SELECTION_REQUIRED');
    profileSelection = await verifyBackendProfileSelection(await resolve(selections[0]), {
      expectedRegistryId: descriptor.registryId, resolveArtifact: async identity => (await resolve(identity)).bytes });
  } else if (selections.length) fail('SELECTION_UNEXPECTED');
  const claimRecord = await resolve(value.claimSetId), claims = decodeClaimSet(claimRecord);
  const subjects = new Set([value.sourceSubjectId, ...value.evidenceArtifacts,
    ...productGroups.flatMap(group => value[group].map(item => item.artifact))].map(id));
  for (const claim of claims.claims) if (id(claim.profileEnvironmentId) !== id(value.profileEnvironmentId) ||
      claim.subjects.some(subject => !subjects.has(id(subject)))) fail('CLAIM_SUBJECT');
  const verifiedClaims = consumer.claimVerification === undefined ? undefined :
    await verifyClaimSet(claimRecord, { ...consumer.claimVerification, resolveArtifact: async identity => (await resolve(identity)).bytes });
  const claimPolicyDecision = consumer.claimPolicy === undefined ? undefined :
    evaluateClaimPolicy(verifiedClaims, consumer.claimPolicy);
  if (claimPolicyDecision && !claimPolicyDecision.policySatisfied) fail('CLAIM_POLICY_UNSATISFIED');
  return Object.freeze({ bundleId: bundleIdentity, backendId: value.backendId, integrityVerified: true,
    claimsVerified: verifiedClaims !== undefined, ...(verifiedClaims ? { verifiedClaims } : {}),
    ...(claimPolicyDecision ? { claimPolicyDecision } : {}),
    ...(profileSelection ? { profileSelection } : {}),
    authority: 'audit-record-only', preservationVerified: false, releaseAccepted: false });
}
