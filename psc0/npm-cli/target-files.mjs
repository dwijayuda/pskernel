// Binary-safe target identity. Installed bytes are bound, not authenticated.
// Bounded streaming avoids decoding a native executable as source text.
import { open, lstat, realpath, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { freezeDataGraph } from './checked-session.mjs';
const sha = data => createHash('sha256').update(data).digest('hex');
const stable = (a, b) => ['dev', 'ino', 'mode', 'size', 'mtimeMs', 'ctimeMs'].every(k => a[k] === b[k]);
const fail = code => { throw new Error('PSC_TARGET_' + code); };

export async function fingerprintTargetFile(file, { maxBytes = 128 * 1024 * 1024, text = false } = {}) {
  if (!Number.isSafeInteger(maxBytes) || maxBytes < 1) fail('FILE_BUDGET');
  const initial = await lstat(file);
  if (!initial.isFile() || initial.isSymbolicLink()) fail('NOT_REGULAR_FILE');
  if (initial.size > maxBytes) fail('FILE_LIMIT');
  const fd = await open(file, 'r');
  try {
    const before = await fd.stat();
    if (!stable(initial, before)) fail('FILE_CHANGED_DURING_READ');
    const buffer = Buffer.alloc(64 * 1024), hash = createHash('sha256'), pieces = [];
    let total = 0;
    while (total <= before.size) {
      const count = Math.min(buffer.length, before.size + 1 - total);
      const { bytesRead } = await fd.read(buffer, 0, count, total);
      if (!bytesRead) break;
      total += bytesRead;
      if (total > maxBytes || total > before.size) fail('FILE_CHANGED_DURING_READ');
      hash.update(buffer.subarray(0, bytesRead));
      if (text) pieces.push(Buffer.from(buffer.subarray(0, bytesRead)));
    }
    if (total !== before.size || !stable(before, await fd.stat()) || !stable(before, await lstat(file))) fail('FILE_CHANGED_DURING_READ');
    return Object.freeze({ bytes: total, mode: before.mode & 0o777, sha256: hash.digest('hex'), ...(text ? { text: new TextDecoder('utf-8', { fatal: true }).decode(Buffer.concat(pieces)) } : {}) });
  } finally { await fd.close(); }
}

export async function captureTargetTrees(directories, options = {}) {
  const limits = Object.freeze({ maxFiles: 4096, maxTotalBytes: 256 * 1024 * 1024, maxFileBytes: 128 * 1024 * 1024, maxDepth: 24, ...options });
  for (const n of Object.values(limits)) if (!Number.isSafeInteger(n) || n < 1) fail('TREE_BUDGET');
  if (!Array.isArray(directories) || !directories.length || directories.length > 4) fail('ROOTS');
  const roots = [];
  for (const item of directories) {
    if (!/^[a-z0-9-]+$/u.test(item.id) || roots.some(r => r.id === item.id)) fail('ROOT_ID');
    const original = path.resolve(item.directory), directory = await realpath(original);
    roots.push({ id: item.id, original, directory });
  }
  async function scan() {
    const entries = [];
    let bytes = 0, count = 0;
    async function visit(root, relative, depth) {
      if (depth > limits.maxDepth || ++count > limits.maxFiles) fail('TREE_LIMIT');
      const location = path.join(root.directory, relative);
      const info = await lstat(location);
      if (info.isSymbolicLink()) fail('TREE_SYMLINK');
      const id = root.id + '/' + relative.split(path.sep).join('/');
      if (info.isDirectory()) {
        entries.push({ id, kind: 'directory' });
        const children = await readdir(location);
        if (children.length > limits.maxFiles) fail('TREE_LIMIT');
        for (const child of children.sort()) {
          // Dependencies are separate roots; do not traverse arbitrary npm installs.
          if (!relative && child === 'node_modules') continue;
          await visit(root, path.join(relative, child), depth + 1);
        }
      } else {
        const file = await fingerprintTargetFile(location, { maxBytes: limits.maxFileBytes });
        bytes += file.bytes;
        if (bytes > limits.maxTotalBytes) fail('TREE_BYTE_LIMIT');
        entries.push({ id, kind: 'file', ...file });
      }
    }
    for (const root of roots) {
      if (await realpath(root.original) !== root.directory) fail('ROOT_CHANGED');
      await visit(root, '', 0);
    }
    return { entries, bytes };
  }
  const captured = await scan();
  const identity = freezeDataGraph({ schema: 'psc0-target-tree/1', excludes: ['each-root/node_modules'], limits, ...captured });
  const digest = sha('PSC0/TARGET-TREE/1\0' + JSON.stringify(identity));
  async function revalidate() {
    const current = await scan();
    if (sha(JSON.stringify(current)) !== sha(JSON.stringify(captured))) fail('IDENTITY_CHANGED');
  }
  return Object.freeze({ identity, sha256: digest, roots: freezeDataGraph(roots), revalidate });
}
