import { mkdir, realpath, lstat, open, rename, rm } from 'node:fs/promises';
import { constants } from 'node:fs';
import { randomUUID } from 'node:crypto';
import path from 'node:path';
import { artifactKey, canonicalBytes, verifyArtifact, verifyPassExecution } from './artifact-evidence.mjs';

const defaults = Object.freeze({ maxRecordBytes: 8 * 1024 * 1024, maxArtifactBytes: 256 * 1024 * 1024,
  maxTotalBytes: 512 * 1024 * 1024, maxArtifacts: 4096 });
function budget(values = {}) {
  const result = { ...defaults, ...values };
  if (Object.values(result).some(value => !Number.isSafeInteger(value) || value < 0)) throw new Error('PSC_CACHE_BUDGET');
  return result;
}
const blobName = identity => 'blob-' + artifactKey(identity);
const entryName = identity => 'action-' + artifactKey(identity) + '.json';

async function boundedRead(file, limit) {
  const before = await lstat(file);
  if (!before.isFile() || before.isSymbolicLink() || before.size > limit) throw new Error('PSC_CACHE_FILE_LIMIT_OR_SHAPE');
  const flags = constants.O_RDONLY | (process.platform === 'win32' ? 0 : constants.O_NOFOLLOW);
  const handle = await open(file, flags);
  try {
    const info = await handle.stat();
    if (!info.isFile() || info.size > limit) throw new Error('PSC_CACHE_FILE_LIMIT_OR_SHAPE');
    const bytes = Buffer.alloc(info.size);
    let offset = 0;
    while (offset < bytes.length) {
      const result = await handle.read(bytes, offset, bytes.length - offset, offset);
      if (!result.bytesRead) throw new Error('PSC_CACHE_TRUNCATED');
      offset += result.bytesRead;
    }
    const extra = await handle.read(Buffer.alloc(1), 0, 1, offset);
    if (extra.bytesRead) throw new Error('PSC_CACHE_GREW_DURING_READ');
    return bytes;
  } finally { await handle.close(); }
}

async function atomicWrite(root, name, bytes) {
  const temporary = path.join(root, '.pending-' + randomUUID());
  try {
    const handle = await open(temporary, 'wx');
    try { await handle.writeFile(bytes); await handle.sync(); }
    finally { await handle.close(); }
    await rename(temporary, path.join(root, name));
  } finally { await rm(temporary, { force: true }); }
}

/** Cache writes publish proposals, never evidence of their own correctness. */
export async function storeEvidenceCache({ root, record, artifacts = [], limits }) {
  const bound = budget(limits);
  verifyArtifact(record.bytes, record.identity);
  if (record.bytes.byteLength > bound.maxRecordBytes) throw new Error('PSC_CACHE_RECORD_LIMIT');
  const value = JSON.parse(record.bytes);
  if (value.contract !== 'psc-pass-execution/1' || value.actionId?.contract !== 'psc-action/1') throw new Error('PSC_CACHE_RECORD_SCHEMA');
  const items = new Map();
  let total = 0;
  for (const item of [record, ...artifacts]) {
    const key = artifactKey(item.identity);
    if (items.has(key)) continue;
    if (!(item.bytes instanceof Uint8Array) || item.bytes.byteLength > bound.maxArtifactBytes ||
        total + item.bytes.byteLength > bound.maxTotalBytes || items.size >= bound.maxArtifacts) throw new Error('PSC_CACHE_STORE_RESOURCE_EXHAUSTED');
    const bytes = Buffer.from(item.bytes);
    verifyArtifact(bytes, item.identity);
    total += bytes.length;
    items.set(key, { identity: item.identity, bytes });
  }
  await mkdir(root, { recursive: true });
  const directory = await realpath(root);
  for (const item of items.values()) await atomicWrite(directory, blobName(item.identity), item.bytes);
  const index = canonicalBytes({ schemaVersion: 1, contract: 'psc-evidence-cache/1',
    actionId: value.actionId, executionId: record.identity }, { maxBytes: bound.maxRecordBytes });
  // The action index is published only after all supplied immutable blobs exist.
  await atomicWrite(directory, entryName(value.actionId), index);
  return { actionId: value.actionId, authority: 'untrusted-proposal' };
}

/** Every hit requires a caller-known ActionId and real checked evidence. No
 * fallback to hashes-only trust, no capability reconstruction, no final-output
 * writes during validation. A corrupt or unsupported proposal is a cache miss.
 */
export async function readEvidenceCache({ root, actionId, requiredEvidenceKinds,
  allowedAssumptions = [], evidenceCheckers = new Map(), limits }) {
  const bound = budget(limits);
  if (!Array.isArray(requiredEvidenceKinds) || requiredEvidenceKinds.length === 0) throw new Error('PSC_CACHE_EVIDENCE_POLICY_REQUIRED');
  if (actionId?.domain !== 'action' || actionId?.contract !== 'psc-action/1') throw new Error('PSC_CACHE_ACTION_REQUIRED');
  const expectedKey = artifactKey(actionId);
  try {
    const directory = await realpath(root);
    const indexBytes = await boundedRead(path.join(directory, entryName(actionId)), bound.maxRecordBytes);
    const index = JSON.parse(indexBytes);
    if (index.schemaVersion !== 1 || index.contract !== 'psc-evidence-cache/1' ||
        !canonicalBytes(index).equals(indexBytes) || artifactKey(index.actionId) !== expectedKey) throw new Error('PSC_CACHE_INDEX');
    const resolved = new Map();
    let total = indexBytes.length;
    async function resolveArtifact(identity) {
      const key = artifactKey(identity);
      if (resolved.has(key)) return resolved.get(key);
      if (resolved.size >= bound.maxArtifacts || identity.byteLength > bound.maxArtifactBytes ||
          total + identity.byteLength > bound.maxTotalBytes) throw new Error('PSC_CACHE_READ_RESOURCE_EXHAUSTED');
      const bytes = await boundedRead(path.join(directory, blobName(identity)), identity.byteLength);
      verifyArtifact(bytes, identity);
      total += bytes.length; resolved.set(key, bytes); return bytes;
    }
    if (index.executionId.byteLength > bound.maxRecordBytes) throw new Error('PSC_CACHE_RECORD_LIMIT');
    const record = { identity: index.executionId, bytes: await resolveArtifact(index.executionId) };
    const execution = JSON.parse(record.bytes);
    if (artifactKey(execution.actionId) !== expectedKey) throw new Error('PSC_CACHE_ACTION_MISMATCH');
    // A flag in an untrusted record does not establish closure: it is also bound
    // by the caller-known action and the independently checked exact subject.
    if (execution.action.parameters.inputClosureComplete !== true) throw new Error('PSC_CACHE_IMPLEMENTATION_CLOSURE_INCOMPLETE');
    const verification = await verifyPassExecution(record, {
      resolveArtifact, requiredEvidenceKinds, allowedAssumptions, evidenceCheckers,
    });
    const outputs = execution.outputs.map(identity => ({ identity,
      bytes: Buffer.from(resolved.get(artifactKey(identity))) }));
    return { hit: true, verification, outputs, authority: 'validated-data-not-kernel-capability' };
  } catch (error) {
    return { hit: false, reason: String(error.code ?? error.message), authority: 'none' };
  }
}
