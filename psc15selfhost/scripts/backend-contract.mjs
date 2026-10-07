import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeClaimSet, verifyClaimSet } from './claim-set.mjs';

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
export async function verifyArtifactBundle(record, { expectedBundleId, resolveArtifact, claimVerification } = {}) {
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
  const claimRecord = await resolve(value.claimSetId), claims = decodeClaimSet(claimRecord);
  const subjects = new Set([value.sourceSubjectId, ...value.evidenceArtifacts,
    ...productGroups.flatMap(group => value[group].map(item => item.artifact))].map(id));
  for (const claim of claims.claims) if (id(claim.profileEnvironmentId) !== id(value.profileEnvironmentId) ||
      claim.subjects.some(subject => !subjects.has(id(subject)))) fail('CLAIM_SUBJECT');
  const verifiedClaims = claimVerification === undefined ? undefined :
    await verifyClaimSet(claimRecord, { ...claimVerification, resolveArtifact: async identity => (await resolve(identity)).bytes });
  return Object.freeze({ bundleId: bundleIdentity, backendId: value.backendId, integrityVerified: true,
    claimsVerified: verifiedClaims !== undefined, ...(verifiedClaims ? { verifiedClaims } : {}),
    authority: 'audit-record-only', preservationVerified: false, releaseAccepted: false });
}
