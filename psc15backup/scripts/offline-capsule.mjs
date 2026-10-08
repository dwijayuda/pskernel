import { createPublicKey, verify as verifySignature } from 'node:crypto';
import { lstat, open } from 'node:fs/promises';
import { constants } from 'node:fs';
import { artifactId, artifactKey, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { verifyKnowledgeGraph } from './savef-graph.mjs';
import { verifySemanticLock } from './semantic-lock.mjs';

const copy = value => JSON.parse(canonicalBytes(value));
const fail = code => { throw new Error('PSC_CAPSULE_' + code); };
const defaults = { maxCapsuleBytes: 192 * 1024 * 1024, maxArtifactBytes: 16 * 1024 * 1024,
  maxTotalBytes: 128 * 1024 * 1024, maxArtifacts: 16384, maxObjects: 4096 };
export const archiveRoles = Object.freeze(['canonical-source', 'semantic-lock', 'schema', 'profile', 'certificate',
  'checker-identity', 'verifier', 'toolchain', 'target', 'provenance', 'license', 'migration']);
function limits(values = {}) {
  const bound = { ...defaults, ...values };
  if (Object.values(bound).some(n => !Number.isSafeInteger(n) || n < 0)) fail('LIMIT_POLICY');
  return bound;
}
function exact(value, fields) {
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !== [...fields].sort().join(',')) fail('SCHEMA');
}
function base64(value, sizeLimit) {
  if (typeof value !== 'string' || value.length > Math.ceil(sizeLimit / 3) * 4) fail('BASE64');
  const bytes = Buffer.from(value, 'base64');
  if (bytes.length > sizeLimit || bytes.toString('base64') !== value) fail('BASE64');
  return bytes;
}

export function archiveSignatureBytes(manifestId) {
  artifactKey(manifestId);
  return canonicalBytes({ contract: 'psc-archive-signature/1', manifestId });
}

/** Single self-contained data file; no archive paths, extraction or executable
 * checker code is taken from it. Exporting one is not validating its claims.
 */
export function packOfflineCapsule({ manifest, artifacts, signatures = [], resourceLimits }) {
  const bound = limits(resourceLimits), items = new Map();
  let total = 0;
  for (const item of [manifest, ...artifacts]) {
    verifyArtifact(item.bytes, item.identity);
    const key = artifactKey(item.identity);
    if (items.has(key)) continue;
    if (items.size >= bound.maxArtifacts || item.bytes.byteLength > bound.maxArtifactBytes ||
        total + item.bytes.byteLength > bound.maxTotalBytes) fail('RESOURCE_EXHAUSTED');
    total += item.bytes.byteLength;
    items.set(key, { identity: item.identity, data: Buffer.from(item.bytes).toString('base64') });
  }
  const bytes = canonicalBytes({ contract: 'psc-offline-capsule/1', manifestId: manifest.identity,
    artifacts: [...items].sort(([left], [right]) => left < right ? -1 : left > right ? 1 : 0).map(([, item]) => item),
    signatures }, { maxBytes: bound.maxCapsuleBytes });
  return { bytes, identity: artifactId(bytes, 'offline-capsule', 'psc-offline-capsule/1') };
}

export function unpackOfflineCapsule(input, { expectedManifestId, resourceLimits } = {}) {
  const bound = limits(resourceLimits);
  artifactKey(expectedManifestId);
  if (!(input instanceof Uint8Array) || input.byteLength > bound.maxCapsuleBytes) fail('RESOURCE_EXHAUSTED');
  const bytes = Buffer.from(input);
  const value = decodeComparatorJson(bytes, { maxBytes: bound.maxCapsuleBytes });
  exact(value, ['contract', 'manifestId', 'artifacts', 'signatures']);
  if (value.contract !== 'psc-offline-capsule/1' || artifactKey(value.manifestId) !== artifactKey(expectedManifestId) ||
      value.manifestId.domain !== 'evidence-manifest' || value.manifestId.contract !== 'psc-evidence-manifest/1') fail('MANIFEST_ID');
  if (!Array.isArray(value.artifacts) || value.artifacts.length > bound.maxArtifacts ||
      !Array.isArray(value.signatures)) fail('RESOURCE_EXHAUSTED');
  const blobs = new Map(); let total = 0, previous = '';
  for (const item of value.artifacts) {
    exact(item, ['identity', 'data']);
    const key = artifactKey(item.identity);
    if (key <= previous) fail('ARTIFACT_ORDER_OR_DUPLICATE');
    previous = key;
    if (item.identity.byteLength > bound.maxArtifactBytes || total + item.identity.byteLength > bound.maxTotalBytes) fail('RESOURCE_EXHAUSTED');
    const data = base64(item.data, item.identity.byteLength);
    verifyArtifact(data, item.identity); total += data.length;
    blobs.set(key, data);
  }
  function resolveArtifact(identity) {
    const key = artifactKey(identity), found = blobs.get(key);
    if (!found) fail('MISSING_ARTIFACT');
    return Buffer.from(found);
  }
  const manifest = decodeComparatorJson(resolveArtifact(value.manifestId), { maxBytes: bound.maxArtifactBytes });
  exact(manifest, ['contract', 'semanticLockId', 'roots', 'archive']);
  if (manifest.contract !== 'psc-evidence-manifest/1' || !Array.isArray(manifest.archive)) fail('MANIFEST_SCHEMA');
  resolveArtifact(manifest.semanticLockId);
  const roles = new Set(), entries = new Set();
  for (const entry of manifest.archive) {
    exact(entry, ['role', 'artifact']);
    if (!archiveRoles.includes(entry.role)) fail('ARCHIVE_ROLE');
    const key = entry.role + ':' + artifactKey(entry.artifact);
    if (entries.has(key)) fail('ARCHIVE_DUPLICATE');
    entries.add(key); roles.add(entry.role); resolveArtifact(entry.artifact);
  }
  return Object.freeze({ manifest: copy(manifest), manifestId: copy(value.manifestId),
    signatures: copy(value.signatures), archiveRoles: [...roles], resolveArtifact,
    artifactCount: blobs.size, artifactBytes: total });
}

/** Trusted local public keys authenticate provenance only. They do not prove
 * semantics, and the manifest cannot replace consumer policy or choose keys.
 */
function checkSignatures(capsule, publicKeys, requiredSignerIds) {
  if (!(publicKeys instanceof Map) || !Array.isArray(requiredSignerIds) ||
      requiredSignerIds.some(id => typeof id !== 'string' || !id) ||
      new Set(requiredSignerIds).size !== requiredSignerIds.length) fail('SIGNATURE_POLICY');
  const keys = new Map([...publicKeys].map(([id, key]) => {
    const selected = typeof key === 'object' && key?.type === 'public' ? key : createPublicKey(key);
    if (selected.asymmetricKeyType !== 'ed25519') fail('SIGNATURE_ALGORITHM');
    return [id, selected];
  }));
  const verified = new Set(), seen = new Set();
  for (const signature of capsule.signatures) {
    exact(signature, ['signerId', 'algorithm', 'signature']);
    if (typeof signature.signerId !== 'string' || !signature.signerId || seen.has(signature.signerId) ||
        signature.algorithm !== 'ed25519') fail('SIGNATURE_SCHEMA');
    seen.add(signature.signerId);
    const key = keys.get(signature.signerId);
    if (!key) fail('SIGNER_UNTRUSTED');
    const bytes = base64(signature.signature, 64);
    if (bytes.length !== 64 || !verifySignature(null, archiveSignatureBytes(capsule.manifestId), key, bytes)) fail('SIGNATURE_INVALID');
    verified.add(signature.signerId);
  }
  for (const signer of requiredSignerIds) if (!verified.has(signer)) fail('SIGNATURE_REQUIRED');
  return [...verified];
}

export async function verifyOfflineCapsule(bytes, { expectedManifestId, expectedSemanticLockId, context, claimPolicies,
  certificateBoundary, semanticLockPolicy, publicKeys = new Map(), requiredSignerIds = [], requiredArchiveRoles = [], resourceLimits } = {}) {
  try {
    const capsule = unpackOfflineCapsule(bytes, { expectedManifestId, resourceLimits });
    if (artifactKey(capsule.manifest.semanticLockId) !== artifactKey(expectedSemanticLockId)) fail('SEMANTIC_LOCK');
    if (!semanticLockPolicy || artifactKey(context?.semanticIdentity?.semanticLockId) !== artifactKey(expectedSemanticLockId)) fail('SEMANTIC_LOCK_POLICY');
    const lockCheck = await verifySemanticLock({ identity: expectedSemanticLockId,
      bytes: capsule.resolveArtifact(expectedSemanticLockId) }, { ...semanticLockPolicy,
      expectedLockId: expectedSemanticLockId, resolveArtifact: capsule.resolveArtifact });
    if (!Array.isArray(requiredArchiveRoles) || requiredArchiveRoles.some(role => !archiveRoles.includes(role))) fail('ARCHIVE_POLICY');
    for (const role of requiredArchiveRoles) if (!capsule.archiveRoles.includes(role)) fail('ARCHIVE_ROLE_REQUIRED');
    const signers = checkSignatures(capsule, publicKeys, requiredSignerIds);
    const validity = await verifyKnowledgeGraph({ roots: capsule.manifest.roots,
      resolveArtifact: capsule.resolveArtifact, context, claimPolicies, certificateBoundary,
      limits: resourceLimits });
    return { kind: 'accepted', contract: 'psc-offline-verification/1', manifestId: capsule.manifestId,
      semanticLockId: capsule.manifest.semanticLockId, lockCheck, signers, validity,
      artifactCount: capsule.artifactCount, artifactBytes: capsule.artifactBytes,
      authority: 'audit-record-only', releaseAccepted: false };
  } catch (error) {
    return { kind: error.kind === 'rejected' ? 'rejectedInvalid' : error.kind === 'inconclusive' ? 'declinedUnsupported' :
      error.kind ?? (/EXHAUSTED/u.test(error.message) ? 'resourceExhausted' : 'rejectedInvalid'),
      code: error.message, ...(error.detail ? { detail: error.detail } : {}) };
  }
}

export async function readOfflineCapsule(file, resourceLimits) {
  const bound = limits(resourceLimits), before = await lstat(file);
  if (!before.isFile() || before.isSymbolicLink() || before.size > bound.maxCapsuleBytes) fail('FILE_SHAPE_OR_RESOURCE_EXHAUSTED');
  const handle = await open(file, constants.O_RDONLY | (process.platform === 'win32' ? 0 : constants.O_NOFOLLOW));
  try {
    const info = await handle.stat();
    if (!info.isFile() || info.size > bound.maxCapsuleBytes) fail('FILE_SHAPE_OR_RESOURCE_EXHAUSTED');
    const bytes = Buffer.alloc(info.size); let offset = 0;
    while (offset < bytes.length) {
      const result = await handle.read(bytes, offset, bytes.length - offset, offset);
      if (!result.bytesRead) fail('FILE_TRUNCATED');
      offset += result.bytesRead;
    }
    if ((await handle.read(Buffer.alloc(1), 0, 1, offset)).bytesRead) fail('FILE_GREW');
    return bytes;
  } finally { await handle.close(); }
}
