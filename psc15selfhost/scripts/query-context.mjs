import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact, passDefinition } from './artifact-evidence.mjs';
import { decodeBuildAction, decodeProfileEnvironment, verifyBuildAction } from './build-context.mjs';

const fail = code => { throw new Error('PSC_QUERY_CONTEXT_' + code); };
const bound = { maxBytes: 2 * 1024 * 1024, maxDepth: 32, maxNodes: 60000 };
const copy = value => JSON.parse(canonicalBytes(value, bound));
const equal = (a, b) => canonicalBytes(a, bound).equals(canonicalBytes(b, bound));
const classes = new Set(['source', 'parsed', 'elaborated-public', 'checked-structural', 'certified-behavioral',
  'assumptions', 'certified-source', 'runtime-interface', 'runtime', 'verified-ir', 'specialized-ir', 'target', 'public-api', 'origin', 'action-configuration']);
function exact(value, fields) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...fields].sort().join(',')) fail('FIELDS');
}
function id(value) {
  exact(value, ['algorithm', 'schemaVersion', 'domain', 'contract', 'byteLength', 'digest']); return artifactKey(value);
}
function names(values) {
  if (!Array.isArray(values) || values.length > 4096 ||
      values.some(value => typeof value !== 'string' || !value || value.length > 4096) ||
      new Set(values).size !== values.length) fail('NAMES');
  return values;
}
/** Host-verified pass effects are invalidation data, never preservation proof.
 * Anything not explicitly preserved is discarded. Trust expansion/unassured
 * execution discards all facts and cannot authorize semantic fingerprint reuse.
 */
export function applyPassEffects(definitionRecord, { semanticProfile, analyses = [], interfaces = [], fingerprints = [] }) {
  verifyArtifact(definitionRecord.bytes, definitionRecord.identity);
  const definition = passDefinition(JSON.parse(definitionRecord.bytes));
  if (!equal(definition.identity, definitionRecord.identity)) fail('PASS_DEFINITION');
  const value = JSON.parse(definition.bytes);
  if (value.schemaVersion !== 2) fail('EFFECTS_REQUIRED');
  const effects = value.effects;
  if (!effects.supportedProfiles.includes(semanticProfile)) fail('PROFILE_UNSUPPORTED');
  const available = { analyses: names(copy(analyses)), interfaces: names(copy(interfaces)), fingerprints: names(copy(fingerprints)) };
  if (effects.requiresAnalyses.some(name => !available.analyses.includes(name))) fail('ANALYSIS_REQUIRED');
  const untrusted = effects.authorityEffect === 'trustExpanding' || effects.assuranceClass === 'unassured';
  const result = {};
  for (const [kind, suffix] of [['analyses', 'Analyses'], ['interfaces', 'Interfaces'], ['fingerprints', 'Fingerprints']]) {
    result[kind] = untrusted ? [] : available[kind].filter(name =>
      effects['preserves' + suffix].includes(name) && !effects['invalidates' + suffix].includes('*') &&
      !effects['invalidates' + suffix].includes(name));
  }
  return Object.freeze({ ...result, semanticReusePermitted: !untrusted,
    capabilityRevalidationRequired: true, originPolicy: effects.originPolicy, originReason: effects.originReason,
    authority: 'invalidation-data-not-preservation-proof' });
}
const fields = ['queryKind', 'subjectIdentity', 'profileEnvironmentId', 'implementationId', 'buildActionId', 'declaredInputs'];
function validate(value) {
  exact(value, ['schemaVersion', 'contract', ...fields]);
  if (value.schemaVersion !== 1 || value.contract !== 'psc-query-key/1' ||
      typeof value.queryKind !== 'string' || !value.queryKind || value.queryKind.length > 4096) fail('SCHEMA');
  for (const field of ['subjectIdentity', 'profileEnvironmentId', 'implementationId', 'buildActionId']) id(value[field]);
  if (value.profileEnvironmentId.domain !== 'profile-environment' || value.profileEnvironmentId.contract !== 'psc-profile-environment/1' ||
      value.buildActionId.domain !== 'build-action' || value.buildActionId.contract !== 'psc-build-action/1') fail('IDENTITY');
  if (!Array.isArray(value.declaredInputs) || value.declaredInputs.length > 4096 || !value.declaredInputs.length) fail('INPUTS');
  const roles = new Set(), artifacts = new Set();
  for (const input of value.declaredInputs) {
    exact(input, ['role', 'fingerprintClass', 'artifactId']);
    if (typeof input.role !== 'string' || !input.role || input.role.length > 4096 || roles.has(input.role)) fail('ROLE');
    if (!classes.has(input.fingerprintClass)) fail('FINGERPRINT_CLASS');
    const key = id(input.artifactId);
    if (artifacts.has(key)) fail('DUPLICATE_INPUT');
    roles.add(input.role); artifacts.add(key);
  }
}
export function createQueryKey(fields) {
  const value = { schemaVersion: 1, contract: 'psc-query-key/1', ...copy(fields) }; validate(value);
  return canonicalArtifact(value, 'query-key', 'psc-query-key/1');
}
export function decodeQueryKey(record) {
  if (!(record?.bytes instanceof Uint8Array) || record.bytes.byteLength > bound.maxBytes) fail('RESOURCE_EXHAUSTED');
  id(record.identity); verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'query-key' || record.identity.contract !== 'psc-query-key/1') fail('IDENTITY');
  const value = JSON.parse(record.bytes); validate(value);
  if (!canonicalBytes(value, bound).equals(Buffer.from(record.bytes))) fail('CANONICAL');
  return value;
}
/** Exact ActionId is a conservative barrier. Changed-input semantic reuse must
 * produce a newly validated execution; an old execution cannot be relabelled.
 */
export async function verifyQueryKey(record, { expectedQueryId, resolveArtifact } = {}) {
  const value = decodeQueryKey(record);
  if (id(expectedQueryId) !== id(record.identity) || typeof resolveArtifact !== 'function') fail('CONSUMER_SELECTION');
  const resolve = async identity => {
    id(identity);
    if (identity.byteLength > bound.maxBytes) fail('RESOURCE_EXHAUSTED');
    const bytes = await resolveArtifact(copy(identity)); verifyArtifact(bytes, identity); return { identity, bytes };
  };
  const actionRecord = await resolve(value.buildActionId), action = decodeBuildAction(actionRecord);
  await verifyBuildAction(actionRecord, { expectedActionId: value.buildActionId, resolveArtifact });
  if (!equal(action.profileEnvironmentId, value.profileEnvironmentId) ||
      !equal(action.implementationId, value.implementationId)) fail('ACTION_BINDING');
  const inputKeys = new Set(action.exactInputArtifactIds.map(artifactKey));
  if (!inputKeys.has(id(value.subjectIdentity)) || value.declaredInputs.length !== inputKeys.size ||
      value.declaredInputs.some(input => !inputKeys.has(id(input.artifactId)))) fail('INPUT_COVERAGE');
  const environment = decodeProfileEnvironment(await resolve(action.profileEnvironmentId));
  const profile = await resolve(environment.semanticProfileId);
  if (profile.identity.contract !== 'psc-observed-semantic-profile/1') fail('PROFILE_CONTRACT');
  const semanticProfile = JSON.parse(profile.bytes).profile;
  const definition = await resolve(action.passDefinitionId);
  return { value, action, definition, semanticProfile, authority: 'validated-query-data-only' };
}
