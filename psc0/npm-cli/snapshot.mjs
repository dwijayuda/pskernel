// Bounded byte snapshot and revalidation. No mutable object supplied by a
// source package is treated as checking authority. Not an OS filesystem sandbox.
import { open, realpath, lstat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { freezeDataGraph } from './checked-session.mjs';
const digest = value => createHash('sha256').update(value).digest('hex');
const sameStat = (a, b) => ['dev', 'ino', 'size', 'mtimeMs', 'ctimeMs'].every(k => a[k] === b[k]);
const normalized = value => value.split(path.sep).join('/');
export const snapshotLimits = Object.freeze({ maxFileBytes: 4 * 1024 * 1024, maxTotalBytes: 32 * 1024 * 1024, maxFiles: 2048, maxDepth: 128 });
export function contained(root, file) {
  const rel = path.relative(root, file);
  return rel !== '..' && !rel.startsWith('..' + path.sep) && !path.isAbsolute(rel);
}
export function createSnapshotReader(options = {}) {
  const limits = Object.freeze({ ...snapshotLimits, ...options });
  for (const value of Object.values(limits)) if (!Number.isSafeInteger(value) || value < 1) throw new TypeError('Invalid snapshot budget');
  const observed = new Map();
  let bytes = 0, sealed = false;
  async function capture(filename, maximum) {
    let actual;
    try { actual = await realpath(filename); }
    catch (error) { if (error.code === 'ENOENT') return { missing: true }; throw error; }
    const handle = await open(actual, 'r');
    try {
      const before = await handle.stat();
      if (!before.isFile()) throw new Error('PSC_SNAPSHOT_NOT_FILE: ' + filename);
      if (before.size > maximum) throw new Error('PSC_SNAPSHOT_FILE_LIMIT: ' + filename);
      // At most maximum+1 bytes are read even if the file grows during capture.
      const buffer = Buffer.alloc(Math.min(before.size + 1, maximum + 1));
      let count = 0;
      while (count < buffer.length) {
        const result = await handle.read(buffer, count, buffer.length - count, count);
        if (!result.bytesRead) break;
        count += result.bytesRead;
      }
      const after = await handle.stat();
      if (count !== before.size || !sameStat(before, after) || await realpath(filename) !== actual) throw new Error('PSC_SNAPSHOT_CHANGED_DURING_READ: ' + filename);
      const value = buffer.subarray(0, count);
      return { missing: false, actual, sha256: digest(value), text: new TextDecoder('utf-8', { fatal: true }).decode(value), bytes: count };
    } finally { await handle.close(); }
  }
  async function readText(filename, { optional = false, root, id, maxBytes = limits.maxFileBytes } = {}) {
    if (sealed) throw new Error('PSC_SNAPSHOT_SEALED');
    if (!Number.isSafeInteger(maxBytes) || maxBytes < 1 || maxBytes > limits.maxTotalBytes) throw new Error('PSC_SNAPSHOT_FILE_POLICY');
    const file = path.resolve(filename);
    let entry = observed.get(file);
    if (!entry) {
      if (observed.size >= limits.maxFiles) throw new Error('PSC_SNAPSHOT_FILE_COUNT');
      const value = await capture(file, maxBytes);
      bytes += value.bytes ?? 0;
      if (bytes > limits.maxTotalBytes) throw new Error('PSC_SNAPSHOT_TOTAL_LIMIT');
      entry = { file, id: id ?? normalized(file), maximum: maxBytes, ...value };
      observed.set(file, entry);
    }
    if (entry.missing) { if (optional) return null; throw new Error('PSC_SNAPSHOT_SOURCE_MISSING: ' + file); }
    if (entry.bytes > maxBytes) throw new Error('PSC_SNAPSHOT_FILE_LIMIT: ' + file);
    if (root && !contained(await realpath(root), entry.actual)) throw new Error('PSC_SNAPSHOT_SOURCE_ESCAPE: ' + file);
    return entry.text;
  }
  async function readJson(file, options = {}) {
    const text = await readText(file, options);
    if (text === null) return null;
    const json = JSON.parse(text);
    if (!json || typeof json !== 'object' || Array.isArray(json)) throw new Error('PSC_SNAPSHOT_METADATA_SHAPE');
    return freezeDataGraph(json);
  }
  function seal(data = {}) {
    if (sealed) throw new Error('PSC_SNAPSHOT_SEALED');
    sealed = true;
    const records = [...observed.values()];
    const inputs = records.map(e => ({ id: e.id, missing: e.missing, ...(e.missing ? {} : { bytes: e.bytes, sha256: e.sha256 }) })).sort((a, b) => a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
    if (new Set(inputs.map(e => e.id)).size !== inputs.length) throw new Error('PSC_SNAPSHOT_ID_COLLISION');
    const binding = freezeDataGraph({ schema: 'psc0-source-snapshot/1', ...structuredClone(data), inputs });
    const sourceClosureSha256 = digest('PSC0/SNAPSHOT/1\0' + JSON.stringify(binding));
    const protectedPaths = Object.freeze(records.filter(e => !e.missing).map(e => e.actual));
    async function revalidate() {
      for (const entry of records) {
        const current = await capture(entry.file, entry.maximum);
        if (entry.missing !== current.missing || (!entry.missing && (entry.actual !== current.actual || entry.sha256 !== current.sha256))) throw new Error('PSC_SNAPSHOT_INPUT_CHANGED: ' + entry.file);
      }
    }
    return Object.freeze({ sourceClosureSha256, binding, protectedPaths, revalidate });
  }
  return Object.freeze({ limits, readText, readJson, seal });
}
