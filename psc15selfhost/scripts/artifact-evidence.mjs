import { createHash } from 'node:crypto';

const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error('PSC_EVIDENCE_' + code); };
const text = value => typeof value === 'string' && value.length > 0;
const natural = value => Number.isSafeInteger(value) && value >= 0;

/** Bounded canonical JSON subset: plain data, dense arrays and safe integers.
 * Object keys sort by UTF-16 code units, arrays keep order, strings use JSON
 * escaping. No getters, toJSON, symbols, cycles, floats or undefined values.
 */
export function canonicalBytes(value, { maxDepth = 128, maxNodes = 1000000, maxBytes = 64 * 1024 * 1024 } = {}) {
  if (![maxDepth, maxNodes, maxBytes].every(natural)) fail('CANONICAL_LIMIT');
  const active = new WeakSet(), parts = [];
  let nodes = 0, bytes = 0;
  function append(part) {
    bytes += Buffer.byteLength(part);
    if (bytes > maxBytes) fail('CANONICAL_BYTES_EXHAUSTED');
    parts.push(part);
  }
  function encode(item, depth) {
    if (++nodes > maxNodes || depth > maxDepth) fail('CANONICAL_WORK_EXHAUSTED');
    if (item === null || typeof item === 'boolean' || typeof item === 'string') { append(JSON.stringify(item)); return; }
    if (typeof item === 'number') {
      if (!Number.isSafeInteger(item) || Object.is(item, -0)) fail('CANONICAL_NUMBER');
      append(JSON.stringify(item)); return;
    }
    if (typeof item !== 'object') fail('CANONICAL_TYPE');
    const array = Array.isArray(item), proto = Object.getPrototypeOf(item);
    if (array ? proto !== Array.prototype : proto !== Object.prototype && proto !== null) fail('CANONICAL_PROTOTYPE');
    if (active.has(item)) fail('CANONICAL_CYCLE');
    active.add(item);
    const keys = Reflect.ownKeys(item);
    if (keys.some(key => typeof key !== 'string')) fail('CANONICAL_SYMBOL');
    for (const key of keys) {
      const descriptor = Object.getOwnPropertyDescriptor(item, key);
      if (!Object.hasOwn(descriptor, 'value') || (!descriptor.enumerable && !(array && key === 'length'))) fail('CANONICAL_DESCRIPTOR');
    }
    if (array) {
      if (keys.length !== item.length + 1 || !keys.includes('length')) fail('CANONICAL_ARRAY');
      append('[');
      for (let index = 0; index < item.length; index++) {
        if (!Object.hasOwn(item, index)) fail('CANONICAL_ARRAY');
        if (index) append(',');
        encode(item[index], depth + 1);
      }
      append(']');
    } else {
      append('{');
      let first = true;
      for (const key of keys.sort()) {
        if (!first) append(','); first = false;
        append(JSON.stringify(key)); append(':'); encode(item[key], depth + 1);
      }
      append('}');
    }
    active.delete(item);
  }
  encode(value, 0);
  return Buffer.from(parts.join(''));
}

export function artifactId(bytes, domain, contract) {
  if (!(bytes instanceof Uint8Array) || !text(domain) || !text(contract)) fail('ARTIFACT_INPUT');
  return Object.freeze({ algorithm: 'sha256', schemaVersion: 1, domain, contract,
    byteLength: bytes.byteLength, digest: digest(bytes) });
}

export function assertArtifactId(value) {
  if (value?.algorithm !== 'sha256' || value.schemaVersion !== 1 || !text(value.domain) ||
      !text(value.contract) || !natural(value.byteLength) || !/^[a-f0-9]{64}$/.test(value.digest ?? '')) fail('ARTIFACT_ID');
  return value;
}

export function artifactKey(value) {
  assertArtifactId(value);
  return digest(canonicalBytes(value));
}

export function verifyArtifact(bytes, identity) {
  assertArtifactId(identity);
  if (!(bytes instanceof Uint8Array) || bytes.byteLength !== identity.byteLength || digest(bytes) !== identity.digest) fail('ARTIFACT_BYTES');
  return identity;
}

export function canonicalArtifact(value, domain, contract) {
  const bytes = canonicalBytes(value);
  return { bytes, identity: artifactId(bytes, domain, contract) };
}

/** Conservative reuse only: no byte difference is silently treated as irrelevant. */
export function exactFingerprint(identity) {
  assertArtifactId(identity);
  return Object.freeze({ contract: 'psc-exact-artifact-fingerprint/1', sourceArtifact: identity });
}

export function passDefinition(fields) {
  const value = JSON.parse(canonicalBytes(fields));
  if (Object.hasOwn(value, 'schemaVersion') && value.schemaVersion !== 1) fail('PASS_DEFINITION_SCHEMA');
  if (Object.hasOwn(value, 'contract') && value.contract !== 'psc-pass-definition/1') fail('PASS_DEFINITION_SCHEMA');
  for (const key of ['passId', 'inputContract', 'outputContract', 'semanticRelationId', 'resourceContractId',
    'determinismClass', 'totalityClass']) if (!text(value[key])) fail('PASS_DEFINITION_' + key);
  if (!natural(value.version) || value.version < 1) fail('PASS_VERSION');
  assertArtifactId(value.implementationId);
  if (value.validatorId !== null && !text(value.validatorId)) fail('PASS_VALIDATOR');
  for (const key of ['theoremIds', 'assumptionIds']) {
    if (!Array.isArray(value[key]) || !value[key].every(text) || new Set(value[key]).size !== value[key].length) fail('PASS_' + key);
  }
  return canonicalArtifact({ schemaVersion: 1, contract: 'psc-pass-definition/1', ...value },
    'pass-definition', 'psc-pass-definition/1');
}

function ids(items, expectedContract) {
  if (!Array.isArray(items) || items.length === 0) fail('PASS_ARTIFACTS');
  return items.map(item => {
    verifyArtifact(item.bytes, item.identity);
    if (item.identity.contract !== expectedContract) fail('PASS_ARTIFACT_CONTRACT');
    return item.identity;
  });
}

function actionPayload(definitionId, inputs, parameters, semanticIdentity, resourcePolicy, dependencies) {
  return { schemaVersion: 1, contract: 'psc-action/1', definitionId, inputs, parameters,
    semanticIdentity, resourcePolicy, dependencies };
}

export function recordPassExecution({ definition, inputs, outputs, parameters = {}, semanticIdentity,
  resourcePolicy, dependencies = [], resourceObservation = {}, diagnostics = [], evidence = [] }) {
  verifyArtifact(definition.bytes, definition.identity);
  const declared = JSON.parse(definition.bytes);
  if (artifactKey(passDefinition(declared).identity) !== artifactKey(definition.identity)) fail('PASS_DEFINITION_BYTES');
  const inputIds = ids(inputs, declared.inputContract), outputIds = ids(outputs, declared.outputContract);
  if (!semanticIdentity || !resourcePolicy) fail('PASS_CONTEXT');
  for (const dependency of dependencies) assertArtifactId(dependency);
  const action = canonicalArtifact(actionPayload(definition.identity, inputIds, parameters,
    semanticIdentity, resourcePolicy, dependencies), 'action', 'psc-action/1');
  const record = canonicalArtifact({ schemaVersion: 1, contract: 'psc-pass-execution/1',
    passDefinitionId: definition.identity, actionId: action.identity,
    action: JSON.parse(action.bytes), inputs: inputIds, outputs: outputIds,
    inputSemanticFingerprints: inputIds.map(exactFingerprint), outputSemanticFingerprints: outputIds.map(exactFingerprint),
    evidence, assumptionIds: declared.assumptionIds, resourceObservation, diagnostics,
    authority: 'audit-record-only', preservation: 'requires-independent-evidence' },
  'pass-execution', 'psc-pass-execution/1');
  return { ...record, definition, action };
}

/** Verifies untrusted graph data. Evidence must be checked by trusted caller-
 * selected checkers against this exact subject. A successful integrity check
 * alone never claims semantic acceptance or preservation.
 */
export async function verifyPassExecution(record, { resolveArtifact, evidenceCheckers = new Map(),
  requiredEvidenceKinds = [], allowedAssumptions = [] }) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.contract !== 'psc-pass-execution/1' || record.identity.domain !== 'pass-execution') fail('PASS_EXECUTION_ID');
  const value = JSON.parse(record.bytes);
  if (!canonicalBytes(value).equals(Buffer.from(record.bytes)) || value.contract !== 'psc-pass-execution/1' ||
      value.schemaVersion !== 1 || value.authority !== 'audit-record-only' ||
      value.preservation !== 'requires-independent-evidence') fail('PASS_EXECUTION_SCHEMA');
  async function resolve(identity) { const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity); return bytes; }
  const definitionBytes = await resolve(value.passDefinitionId);
  const definition = passDefinition(JSON.parse(definitionBytes));
  if (artifactKey(definition.identity) !== artifactKey(value.passDefinitionId)) fail('PASS_DEFINITION_BYTES');
  const declared = JSON.parse(definition.bytes);
  await resolve(declared.implementationId);
  if (!Array.isArray(value.inputs) || !value.inputs.length || !Array.isArray(value.outputs) || !value.outputs.length) fail('PASS_ARTIFACTS');
  for (const [items, contract] of [[value.inputs, declared.inputContract], [value.outputs, declared.outputContract]]) {
    for (const item of items) { if (item.contract !== contract) fail('PASS_ARTIFACT_CONTRACT'); await resolve(item); }
  }
  if (!canonicalBytes(value.assumptionIds).equals(canonicalBytes(declared.assumptionIds))) fail('PASS_ASSUMPTIONS');
  if (declared.assumptionIds.some(id => !allowedAssumptions.includes(id))) fail('ASSUMPTION_DENIED');
  const action = value.action;
  const expectedAction = canonicalArtifact(actionPayload(value.passDefinitionId, value.inputs, action.parameters,
    action.semanticIdentity, action.resourcePolicy, action.dependencies), 'action', 'psc-action/1');
  if (artifactKey(expectedAction.identity) !== artifactKey(value.actionId) ||
      !canonicalBytes(action).equals(expectedAction.bytes)) fail('ACTION_ID');
  await resolve(value.actionId);
  for (const dependency of action.dependencies) await resolve(dependency);
  for (const [fingerprints, artifacts] of [[value.inputSemanticFingerprints, value.inputs], [value.outputSemanticFingerprints, value.outputs]]) {
    if (!canonicalBytes(fingerprints).equals(canonicalBytes(artifacts.map(exactFingerprint)))) fail('FINGERPRINT_PROVENANCE');
  }
  if (!Array.isArray(value.evidence) || !Array.isArray(requiredEvidenceKinds) || !requiredEvidenceKinds.every(text)) fail('EVIDENCE_POLICY');
  const verifiedKinds = new Set();
  for (const item of value.evidence) {
    if (!text(item.kind) || !text(item.checkerId)) fail('EVIDENCE_SCHEMA');
    const checker = evidenceCheckers.get(item.checkerId);
    if (typeof checker !== 'function') fail('EVIDENCE_CHECKER_UNAVAILABLE');
    const bytes = await resolve(item.artifact);
    const subject = Object.freeze({ semanticRelationId: declared.semanticRelationId,
      actionId: value.actionId, inputs: value.inputs, outputs: value.outputs, assumptionIds: value.assumptionIds });
    const outcome = await checker(bytes, subject);
    if (outcome?.verified !== true || outcome.kind !== item.kind ||
        !canonicalBytes(outcome.subject).equals(canonicalBytes(subject))) fail('EVIDENCE_REJECTED');
    verifiedKinds.add(item.kind);
  }
  for (const kind of requiredEvidenceKinds) if (!verifiedKinds.has(kind)) fail('EVIDENCE_REQUIRED_' + kind);
  return Object.freeze({ integrityVerified: true, preservationVerified: verifiedKinds.has('global-preservation'),
    verifiedEvidenceKinds: Object.freeze([...verifiedKinds]), executionId: record.identity, authority: 'audit-record-only' });
}
