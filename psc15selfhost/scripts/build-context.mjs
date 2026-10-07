import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact, passDefinition } from './artifact-evidence.mjs';

const bound = { maxBytes: 2 * 1024 * 1024, maxDepth: 32, maxNodes: 60000 };
const fail = code => { throw new Error('PSC_BUILD_CONTEXT_' + code); };
const copy = value => JSON.parse(canonicalBytes(value, bound));
const equal = (left, right) => canonicalBytes(left, bound).equals(canonicalBytes(right, bound));
function exact(value, fields) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...fields].sort().join(',')) fail('FIELDS');
}
function text(value) {
  if (typeof value !== 'string' || !value || value.length > 4096) fail('TEXT');
  return value;
}
function id(value, domain, contract) {
  exact(value, ['algorithm', 'schemaVersion', 'domain', 'contract', 'byteLength', 'digest']);
  if ((domain && value.domain !== domain) || (contract && value.contract !== contract)) fail('IDENTITY');
  return artifactKey(value);
}
function list(value, check = id) {
  if (!Array.isArray(value) || value.length > 4096) fail('LIST');
  const keys = value.map(item => check(item));
  if (new Set(keys).size !== keys.length) fail('DUPLICATE');
}
function read(record, domain, contract) {
  if (!(record?.bytes instanceof Uint8Array) || record.bytes.byteLength > bound.maxBytes) fail('RESOURCE_EXHAUSTED');
  id(record.identity, domain, contract); verifyArtifact(record.bytes, record.identity);
  const value = JSON.parse(Buffer.from(record.bytes));
  if (!canonicalBytes(value, bound).equals(Buffer.from(record.bytes))) fail('CANONICAL');
  return value;
}
function artifact(fields, domain, contract, validate) {
  const value = { schemaVersion: 1, contract, ...copy(fields) };
  validate(value);
  return canonicalArtifact(value, domain, contract);
}
function schema(value, contract, fields) {
  exact(value, ['schemaVersion', 'contract', ...fields]);
  if (value.schemaVersion !== 1 || value.contract !== contract) fail('SCHEMA');
}

function extensions(value) {
  schema(value, 'psc-extension-set/1', ['extensions']);
  list(value.extensions, entry => {
    exact(entry, ['extensionId', 'implementationId', 'influenceClass']);
    id(entry.implementationId);
    if (!['E0', 'E1', 'E2', 'E3', 'E4', 'E5', 'E6'].includes(entry.influenceClass)) fail('EXTENSION_CLASS');
    return id(entry.extensionId);
  });
}
export function createExtensionSet(entries = []) {
  return artifact({ extensions: entries }, 'extension-set', 'psc-extension-set/1', extensions);
}
export function decodeExtensionSet(record) {
  const value = read(record, 'extension-set', 'psc-extension-set/1'); extensions(value); return value;
}
const profileFields = ['languageEdition', 'semanticProfileId', 'standardEnvironmentId', 'extensionSetId',
  'importedStructuralInterfaceIds', 'importedBehavioralInterfaceIds', 'semanticOptions'];
function profile(value) {
  schema(value, 'psc-profile-environment/1', profileFields);
  text(value.languageEdition); id(value.semanticProfileId, 'semantic-profile');
  id(value.standardEnvironmentId); id(value.extensionSetId, 'extension-set', 'psc-extension-set/1');
  list(value.importedStructuralInterfaceIds); list(value.importedBehavioralInterfaceIds);
  if (!value.semanticOptions || typeof value.semanticOptions !== 'object' || Array.isArray(value.semanticOptions)) fail('OPTIONS');
}
export function createProfileEnvironment(fields) {
  return artifact(fields, 'profile-environment', 'psc-profile-environment/1', profile);
}
export function decodeProfileEnvironment(record) {
  const value = read(record, 'profile-environment', 'psc-profile-environment/1'); profile(value); return value;
}
function resolver(resolveArtifact) {
  if (typeof resolveArtifact !== 'function') fail('RESOLVER');
  const seen = new Map();
  let total = 0;
  return async identity => {
    const key = id(identity);
    if (!seen.has(key)) {
      if (seen.size >= 4096 || identity.byteLength > 256 * 1024 * 1024 ||
          total + identity.byteLength > 512 * 1024 * 1024) fail('RESOURCE_EXHAUSTED');
      const raw = await resolveArtifact(copy(identity));
      if (!(raw instanceof Uint8Array)) fail('MISSING_ARTIFACT');
      const bytes = Buffer.from(raw); verifyArtifact(bytes, identity);
      total += bytes.byteLength; seen.set(key, bytes);
    }
    return { identity: copy(identity), bytes: Buffer.from(seen.get(key)) };
  };
}
/** Exact declared interpretation context. Integrity is not proof that the
 * declaration covers every input observed by a compiler or extension sandbox.
 */
export async function verifyProfileEnvironment(record, { expectedProfileEnvironmentId, resolveArtifact } = {}) {
  const value = decodeProfileEnvironment(record);
  if (id(expectedProfileEnvironmentId) !== id(record.identity)) fail('CONSUMER_PROFILE');
  const resolve = resolver(resolveArtifact);
  for (const identity of [value.semanticProfileId, value.standardEnvironmentId,
    ...value.importedStructuralInterfaceIds, ...value.importedBehavioralInterfaceIds]) await resolve(identity);
  const extensionSet = decodeExtensionSet(await resolve(value.extensionSetId));
  for (const entry of extensionSet.extensions) {
    await resolve(entry.extensionId); await resolve(entry.implementationId);
  }
  return Object.freeze({ profileEnvironmentId: copy(record.identity), declaredInputsVerified: true,
    observedClosureVerified: false, authority: 'audit-record-only' });
}

const actionFields = ['actionKind', 'passDefinitionId', 'implementationId', 'semanticProfileId',
  'profileEnvironmentId', 'exactInputArtifactIds', 'exactToolchainIds', 'targetProfileId',
  'extensionSetId', 'declaredEnvironment', 'resourcePolicyId', 'outputContracts'];
function action(value) {
  schema(value, 'psc-build-action/1', actionFields);
  text(value.actionKind); id(value.passDefinitionId, 'pass-definition'); id(value.implementationId);
  id(value.semanticProfileId, 'semantic-profile');
  id(value.profileEnvironmentId, 'profile-environment', 'psc-profile-environment/1');
  id(value.extensionSetId, 'extension-set', 'psc-extension-set/1'); id(value.resourcePolicyId);
  list(value.exactInputArtifactIds); list(value.exactToolchainIds);
  if (!value.exactInputArtifactIds.length) fail('INPUT_REQUIRED');
  if (value.targetProfileId !== null) id(value.targetProfileId);
  list(value.declaredEnvironment, entry => {
    exact(entry, ['name', 'value']); text(entry.name);
    if (typeof entry.value !== 'string' || entry.value.length > 65536) fail('ENVIRONMENT');
    return entry.name;
  });
  const environmentNames = value.declaredEnvironment.map(entry => entry.name);
  if (!equal(environmentNames, [...environmentNames].sort())) fail('ENVIRONMENT_ORDER');
  list(value.outputContracts, spec => {
    exact(spec, ['role', 'domain', 'contract']); text(spec.domain); text(spec.contract); return text(spec.role);
  });
  if (!value.outputContracts.length) fail('OUTPUT_REQUIRED');
}
export function createBuildAction(fields) {
  return artifact(fields, 'build-action', 'psc-build-action/1', action);
}
export function decodeBuildAction(record) {
  const value = read(record, 'build-action', 'psc-build-action/1'); action(value); return value;
}
/** BuildAction IDs describe intent; neither an ID nor a declaration asserts
 * hermetic execution. The consumer selects the expected ID before resolving.
 */
export async function verifyBuildAction(record, { expectedActionId, resolveArtifact } = {}) {
  const value = decodeBuildAction(record);
  if (id(expectedActionId) !== id(record.identity)) fail('CONSUMER_ACTION');
  const resolve = resolver(resolveArtifact);
  const profileRecord = await resolve(value.profileEnvironmentId), environment = decodeProfileEnvironment(profileRecord);
  if (!equal(environment.semanticProfileId, value.semanticProfileId) ||
      !equal(environment.extensionSetId, value.extensionSetId)) fail('ACTION_PROFILE');
  await verifyProfileEnvironment(profileRecord, { expectedProfileEnvironmentId: value.profileEnvironmentId,
    resolveArtifact: async identity => (await resolve(identity)).bytes });
  const definitionRecord = await resolve(value.passDefinitionId);
  const definition = passDefinition(JSON.parse(definitionRecord.bytes));
  if (!equal(definition.identity, definitionRecord.identity)) fail('PASS_DEFINITION');
  const declared = JSON.parse(definition.bytes);
  if (declared.passId !== value.actionKind || !equal(declared.implementationId, value.implementationId)) fail('PASS_BINDING');
  if (declared.schemaVersion === 2 ? !equal(declared.outputArtifacts, value.outputContracts) :
      value.outputContracts.some(spec => spec.contract !== declared.outputContract)) fail('OUTPUT_CONTRACT');
  for (const identity of [value.implementationId, value.resourcePolicyId, ...value.exactInputArtifactIds,
    ...value.exactToolchainIds, ...(value.targetProfileId === null ? [] : [value.targetProfileId])]) await resolve(identity);
  return Object.freeze({ actionId: copy(record.identity), profileEnvironmentId: value.profileEnvironmentId,
    declaredInputsVerified: true, hermeticityVerified: false, authority: 'audit-record-only' });
}
