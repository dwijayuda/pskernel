import { mkdir, lstat, open, realpath, rename, rm } from 'node:fs/promises';
import { constants } from 'node:fs';
import path from 'node:path';
import { randomUUID } from 'node:crypto';
import { artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { knowledgeObject, knowledgeContract, knowledgeKinds } from './savef-graph.mjs';

const indexContract = 'psc-savef-semantic-index/1';
const fileName = 'semantic-index.json';
const defaults = Object.freeze({ maxObjects: 100000, maxObjectBytes: 16 * 1024 * 1024, maxTotalObjectBytes: 1024 * 1024 * 1024,
  maxIndexBytes: 256 * 1024 * 1024, maxResults: 1000 });
const natural = value => Number.isSafeInteger(value) && value >= 0;
const copy = value => JSON.parse(canonicalBytes(value));
const fail = code => { throw new Error('PSC_SAVEF_INDEX_' + code); };

function bounds(values = {}) {
  const result = { ...defaults, ...copy(values) };
  if (Object.values(result).some(value => !natural(value))) fail('LIMITS');
  return result;
}
function contextIdentity(value, domain, contract) {
  return canonicalArtifact(copy(value), domain, contract).identity;
}
function normalizedRecord(record, bound) {
  if (!(record?.bytes instanceof Uint8Array) || record.bytes.byteLength > bound.maxObjectBytes) fail('OBJECT_BYTES');
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'knowledge-object' || record.identity.contract !== knowledgeContract) fail('OBJECT_ID');
  const value = JSON.parse(record.bytes);
  const rebuilt = knowledgeObject(value);
  if (!rebuilt.bytes.equals(Buffer.from(record.bytes)) || artifactKey(rebuilt.identity) !== artifactKey(record.identity)) fail('OBJECT_CANONICAL');
  return {
    objectId: copy(record.identity),
    kind: value.kind,
    authorityClass: value.authorityClass,
    semanticIdentityId: contextIdentity(value.semanticIdentity, 'savef-semantic-identity', 'psc-savef-semantic-identity/1'),
    scopeId: contextIdentity(value.scope, 'savef-scope', 'psc-savef-scope/1'),
    assumptions: [...value.assumptions],
    claims: value.claims.map(claim => ({ claimId: claim.claimId, status: claim.status })),
    dependencyIds: value.dependencies.map(edge => copy(edge.target)),
    payloadId: copy(value.payload),
    licenseId: copy(value.license),
  };
}
async function boundedRead(file, limit) {
  const before = await lstat(file);
  if (!before.isFile() || before.isSymbolicLink() || before.size > limit) fail('FILE');
  const flags = constants.O_RDONLY | (process.platform === 'win32' ? 0 : constants.O_NOFOLLOW);
  const handle = await open(file, flags);
  try {
    const stat = await handle.stat();
    if (!stat.isFile() || stat.size > limit) fail('FILE');
    const bytes = Buffer.alloc(stat.size);
    let offset = 0;
    while (offset < bytes.length) {
      const result = await handle.read(bytes, offset, bytes.length - offset, offset);
      if (!result.bytesRead) fail('TRUNCATED');
      offset += result.bytesRead;
    }
    const extra = await handle.read(Buffer.alloc(1), 0, 1, offset);
    if (extra.bytesRead) fail('GREW');
    return bytes;
  } finally { await handle.close(); }
}
function validateIndex(bytes, bound) {
  if (bytes.byteLength > bound.maxIndexBytes) fail('INDEX_BYTES');
  const value = JSON.parse(bytes);
  if (!canonicalBytes(value, { maxBytes: bound.maxIndexBytes }).equals(Buffer.from(bytes)) ||
      value.schemaVersion !== 1 || value.contract !== indexContract || value.authority !== 'derived-non-authoritative' ||
      !Array.isArray(value.entries) || value.entries.length > bound.maxObjects) fail('SCHEMA');
  let previous = '';
  for (const entry of value.entries) {
    const key = artifactKey(entry.objectId);
    if (entry.objectId.domain !== 'knowledge-object' || entry.objectId.contract !== knowledgeContract ||
        !knowledgeKinds.includes(entry.kind) || !entry.semanticIdentityId || !entry.scopeId ||
        !Array.isArray(entry.assumptions) || !Array.isArray(entry.claims) || !Array.isArray(entry.dependencyIds)) fail('ENTRY');
    artifactKey(entry.semanticIdentityId); artifactKey(entry.scopeId); artifactKey(entry.payloadId); artifactKey(entry.licenseId);
    for (const dependency of entry.dependencyIds) artifactKey(dependency);
    if (previous && previous >= key) fail('ORDER');
    previous = key;
  }
  return { value, artifact: canonicalArtifact(value, 'savef-semantic-index', indexContract) };
}

export async function buildSavefSemanticIndex({ root, records, limits }) {
  if (typeof root !== 'string' || !root || !Array.isArray(records) || records.length === 0) fail('INPUT');
  const bound = bounds(limits);
  if (records.length > bound.maxObjects) fail('OBJECT_LIMIT');
  let total = 0;
  const entries = records.map(record => {
    total += record?.bytes?.byteLength ?? 0;
    if (total > bound.maxTotalObjectBytes) fail('TOTAL_OBJECT_BYTES');
    return normalizedRecord(record, bound);
  }).sort((left, right) => artifactKey(left.objectId).localeCompare(artifactKey(right.objectId)));
  for (let index = 1; index < entries.length; index++) {
    if (artifactKey(entries[index - 1].objectId) === artifactKey(entries[index].objectId)) fail('DUPLICATE');
  }
  const artifact = canonicalArtifact({ schemaVersion: 1, contract: indexContract,
    authority: 'derived-non-authoritative', requiresValidUnderBeforeReuse: true, entries },
  'savef-semantic-index', indexContract);
  if (artifact.bytes.byteLength > bound.maxIndexBytes) fail('INDEX_BYTES');
  await mkdir(root, { recursive: true });
  const directory = await realpath(root), target = path.join(directory, fileName), temporary = path.join(directory, '.pending-' + randomUUID());
  try {
    const handle = await open(temporary, 'wx');
    try { await handle.writeFile(artifact.bytes); await handle.sync(); } finally { await handle.close(); }
    await rename(temporary, target);
  } finally { await rm(temporary, { force: true }); }
  return Object.freeze({ identity: copy(artifact.identity), objectCount: entries.length,
    authority: 'derived-non-authoritative', requiresValidUnderBeforeReuse: true });
}

export async function querySavefSemanticIndex({ root, semanticIdentity, scope, kinds, requiredClaimIds = [],
  allowedAssumptions, limit = 50, limits }) {
  if (typeof root !== 'string' || !root || !natural(limit)) fail('QUERY');
  const bound = bounds(limits);
  if (limit > bound.maxResults || !Array.isArray(requiredClaimIds) || requiredClaimIds.some(value => typeof value !== 'string'))
    fail('QUERY_LIMIT');
  if (kinds !== undefined && (!Array.isArray(kinds) || kinds.some(kind => !knowledgeKinds.includes(kind)))) fail('QUERY_KIND');
  const requestedKinds = kinds === undefined ? null : new Set(kinds);
  if (allowedAssumptions !== undefined &&
      (!Array.isArray(allowedAssumptions) || allowedAssumptions.some(value => typeof value !== 'string'))) fail('QUERY_ASSUMPTION');
  const allowed = allowedAssumptions === undefined ? null : new Set(allowedAssumptions);
  const directory = await realpath(root), bytes = await boundedRead(path.join(directory, fileName), bound.maxIndexBytes);
  const { value, artifact } = validateIndex(bytes, bound);
  const semanticIdentityId = semanticIdentity === undefined ? null :
    contextIdentity(semanticIdentity, 'savef-semantic-identity', 'psc-savef-semantic-identity/1');
  const scopeId = scope === undefined ? null : contextIdentity(scope, 'savef-scope', 'psc-savef-scope/1');
  const candidates = [];
  for (const entry of value.entries) {
    if (semanticIdentityId && artifactKey(entry.semanticIdentityId) !== artifactKey(semanticIdentityId)) continue;
    if (scopeId && artifactKey(entry.scopeId) !== artifactKey(scopeId)) continue;
    if (requestedKinds && !requestedKinds.has(entry.kind)) continue;
    if (allowed && entry.assumptions.some(assumption => !allowed.has(assumption))) continue;
    if (requiredClaimIds.some(id => !entry.claims.some(claim => claim.claimId === id))) continue;
    candidates.push(copy(entry.objectId));
    if (candidates.length >= limit) break;
  }
  return Object.freeze({ indexId: copy(artifact.identity), candidates: Object.freeze(candidates),
    authority: 'untrusted-derived-index', requiresValidUnderBeforeReuse: true });
}
