import path from 'node:path';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';

export const sourceFileContract = 'psc-source-file/1';
export const sourceClosureContract = 'psc-source-closure/1';

const fail = code => { throw new Error('PSC_SOURCE_CLOSURE_' + code); };
const logical = value => {
  if (typeof value !== 'string' || !value ||
      !/^[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_.-]+)*$/u.test(value) ||
      value.split('/').some(part => part === '.' || part === '..')) fail('PATH');
  return value;
};
const inside = (root, file) => {
  const value = path.relative(root, file);
  if (!value || value === '..' || value.startsWith('..' + path.sep) || path.isAbsolute(value)) fail('PATH');
  return logical(value.split(path.sep).join('/'));
};

/** Exact checked source bytes as a reusable closure object.
 * This is source identity/provenance data, not semantic acceptance.
 */
export function checkedSourceClosureArtifacts(snapshot, { maxFiles = 16384, maxFileBytes = 16 * 1024 * 1024,
  maxTotalBytes = 128 * 1024 * 1024 } = {}) {
  if (!snapshot || typeof snapshot.root !== 'string' || typeof snapshot.entry !== 'string' ||
      !['lean','ps'].includes(snapshot.kind) || typeof snapshot.closureSha256 !== 'string' ||
      !/^[0-9a-f]{64}$/u.test(snapshot.closureSha256) || !Array.isArray(snapshot.ordered)) fail('SNAPSHOT');
  if (!Number.isSafeInteger(maxFiles) || maxFiles < 1 || !Number.isSafeInteger(maxFileBytes) || maxFileBytes < 0 ||
      !Number.isSafeInteger(maxTotalBytes) || maxTotalBytes < 0 || snapshot.ordered.length > maxFiles) fail('LIMIT');
  const seen = new Set(), byPath = new Map(); let total = 0;
  for (const item of snapshot.ordered) {
    if (!item || typeof item.path !== 'string' || typeof item.source !== 'string') fail('FILE');
    const name = inside(snapshot.root, item.path);
    const folded = name.toLowerCase();
    if (seen.has(folded)) fail('DUPLICATE');
    seen.add(folded);
    const bytes = Buffer.from(item.source, 'utf8');
    if (bytes.byteLength > maxFileBytes || total + bytes.byteLength > maxTotalBytes) fail('RESOURCE_EXHAUSTED');
    total += bytes.byteLength;
    byPath.set(name, Object.freeze({ path: name, bytes, identity: artifactId(bytes, 'source-file', sourceFileContract) }));
  }
  const entry = inside(snapshot.root, snapshot.entry);
  if (!byPath.has(entry)) fail('ENTRY');
  const files = [...byPath.values()].sort((a,b)=>a.path<b.path?-1:a.path>b.path?1:0);
  const order = snapshot.ordered.map(item => inside(snapshot.root, item.path));
  if (new Set(order).size !== order.length || order.some(name => !byPath.has(name))) fail('ORDER');
  const closure = canonicalArtifact({
    schemaVersion: 1,
    contract: sourceClosureContract,
    sourceKind: snapshot.kind,
    entry,
    closureSha256: snapshot.closureSha256,
    files: files.map(item => ({ path: item.path, artifact: item.identity })),
    preparationOrder: order,
    authority: 'source-identity-only',
  }, 'source-closure', sourceClosureContract);
  return Object.freeze({ closure, files: Object.freeze(files), totalBytes: total });
}

export function verifyCheckedSourceClosure(record, { resolveArtifact, maxFiles = 16384,
  maxTotalBytes = 128 * 1024 * 1024 } = {}) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'source-closure' || record.identity.contract !== sourceClosureContract ||
      typeof resolveArtifact !== 'function') fail('IDENTITY');
  const value = JSON.parse(record.bytes);
  if (!canonicalBytes(value).equals(Buffer.from(record.bytes)) || value.schemaVersion !== 1 ||
      value.contract !== sourceClosureContract || value.authority !== 'source-identity-only' ||
      !['lean','ps'].includes(value.sourceKind) || !Array.isArray(value.files) ||
      !Array.isArray(value.preparationOrder) || value.files.length > maxFiles ||
      typeof value.closureSha256 !== 'string' || !/^[0-9a-f]{64}$/u.test(value.closureSha256)) fail('SCHEMA');
  logical(value.entry);
  const seen = new Set(), ids = new Map(); let previous = '', total = 0;
  for (const file of value.files) {
    if (!file || Object.keys(file).sort().join(',') !== 'artifact,path') fail('FILE');
    const name = logical(file.path);
    if (name <= previous || seen.has(name.toLowerCase())) fail('ORDER_OR_DUPLICATE');
    previous = name; seen.add(name.toLowerCase()); artifactKey(file.artifact);
    const bytes = Buffer.from(resolveArtifact(file.artifact));
    verifyArtifact(bytes, file.artifact); total += bytes.byteLength;
    if (total > maxTotalBytes) fail('RESOURCE_EXHAUSTED');
    ids.set(name, file.artifact);
  }
  if (!ids.has(value.entry) || value.preparationOrder.length !== value.files.length ||
      new Set(value.preparationOrder).size !== value.preparationOrder.length ||
      value.preparationOrder.some(name => !ids.has(logical(name)))) fail('PREPARATION_ORDER');
  return Object.freeze({
    contract: 'psc-source-closure-check/1',
    closureId: record.identity,
    entry: value.entry,
    sourceKind: value.sourceKind,
    fileCount: value.files.length,
    sourceBytes: total,
    preparationOrder: Object.freeze([...value.preparationOrder]),
    authority: 'source-identity-only',
  });
}
