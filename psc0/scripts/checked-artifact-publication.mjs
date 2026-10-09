import { readFile, writeFile, mkdir, mkdtemp, rename, rm, lstat } from 'node:fs/promises';
import path from 'node:path';
import { createHash, randomUUID } from 'node:crypto';

const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const absent = error => error?.code === 'ENOENT';

async function regularBytes(file) {
  let status;
  try { status = await lstat(file); } catch (error) { if (absent(error)) return undefined; throw error; }
  if (!status.isFile() || status.isSymbolicLink()) throw new Error('PSC0_OUTPUT_NOT_REGULAR: ' + file);
  return readFile(file);
}
function ownedNames(receipt, owner) {
  if (receipt?.schemaVersion !== 4 || receipt?.kind !== 'psc0-checked-build' ||
      receipt?.outputOwner !== owner || !Array.isArray(receipt.artifacts) || receipt.artifacts.length === 0) {
    throw new Error('PSC0_OUTPUT_OWNERSHIP_CONFLICT');
  }
  const names = new Set();
  for (const item of receipt.artifacts) {
    if (typeof item?.name !== 'string' || path.basename(item.name) !== item.name ||
        item.name === '.' || item.name === '..' || !/^[a-f0-9]{64}$/.test(item.sha256) ||
        names.has(item.name)) throw new Error('PSC0_OUTPUT_OWNERSHIP_SHAPE');
    names.add(item.name);
  }
  return names;
}

/**
 * Trusted publication helper. Only the supervisor calls this after validation.
 * This is a local multi-file transaction with a completion receipt, not a claim
 * that independent filesystem consumers observe several renames atomically.
 */
export async function publishCheckedArtifacts({ outputPath, entryPath, artifacts, receipt, beforeCommit }) {
  const output = path.resolve(outputPath);
  const directory = path.dirname(output);
  const stem = path.basename(output).replace(/\.(?:ts|js)$/u, '');
  if (!/\.(?:ts|js)$/u.test(output) || !stem) throw new Error('PSC0_OUTPUT_KIND');
  const receiptName = stem + '.checked.json';
  const owner = path.relative(directory, path.resolve(entryPath)).split(path.sep).join('/');
  const allowed = new Set(['.ts', '.js', '.d.ts', '.js.map', '.admissions.json'].map(suffix => stem + suffix));
  if (!(artifacts instanceof Map) || artifacts.size === 0 ||
      !artifacts.has(path.basename(output))) throw new Error('PSC0_OUTPUT_ARTIFACTS');
  const buffers = new Map();
  for (const [name, bytes] of artifacts) {
    if (!allowed.has(name) || (!Buffer.isBuffer(bytes) && typeof bytes !== 'string')) {
      throw new Error('PSC0_OUTPUT_ARTIFACT_NAME: ' + name);
    }
    buffers.set(name, Buffer.from(bytes));
  }
  await mkdir(directory, { recursive: true });
  const lock = path.join(directory, '.' + stem + '.psc-lock');
  try { await mkdir(lock); }
  catch (error) {
    if (error.code === 'EEXIST') throw new Error('PSC0_OUTPUT_BUSY: ' + lock);
    throw error;
  }
  const transactionId = randomUUID();
  let staging;
  const previous = new Map();
  const changes = [];
  let oldReceipt;
  let removedReceipt = false;
  let completed = false;
  let rollbackComplete = true;
  try {
    await writeFile(path.join(lock, 'owner.json'), JSON.stringify({ transactionId, pid: process.pid, entryPath: owner }) + '\n');
    staging = await mkdtemp(path.join(directory, '.psc-stage-'));
    const receiptPath = path.join(directory, receiptName);
    oldReceipt = await regularBytes(receiptPath);
    let previousReceipt;
    if (oldReceipt !== undefined) {
      try { previousReceipt = JSON.parse(oldReceipt.toString('utf8')); }
      catch { throw new Error('PSC0_OUTPUT_OWNERSHIP_SHAPE'); }
      const names = ownedNames(previousReceipt, owner);
      for (const item of previousReceipt.artifacts) {
        if (!allowed.has(item.name)) throw new Error('PSC0_OUTPUT_OWNERSHIP_SHAPE');
        const bytes = await regularBytes(path.join(directory, item.name));
        if (bytes === undefined || digest(bytes) !== item.sha256) {
          throw new Error('PSC0_OUTPUT_MODIFIED: ' + item.name);
        }
        previous.set(item.name, bytes);
      }
      for (const name of buffers.keys()) {
        if (!names.has(name) && await regularBytes(path.join(directory, name)) !== undefined) {
          throw new Error('PSC0_OUTPUT_UNOWNED: ' + name);
        }
      }
    } else {
      for (const name of buffers.keys()) {
        if (await regularBytes(path.join(directory, name)) !== undefined) {
          throw new Error('PSC0_OUTPUT_UNOWNED: ' + name);
        }
      }
    }
    const published = {
      ...receipt, schemaVersion: 4, kind: 'psc0-checked-build', outputOwner: owner,
      transactionId,
      artifacts: [...buffers].map(([name, bytes]) => ({ name, sha256: digest(bytes), bytes: bytes.length })),
    };
    await mkdir(path.join(staging, 'previous'));
    for (const [name, bytes] of previous) await writeFile(path.join(staging, 'previous', name), bytes);
    if (oldReceipt !== undefined) await writeFile(path.join(staging, 'previous', receiptName), oldReceipt);
    for (const [name, bytes] of buffers) await writeFile(path.join(staging, name), bytes);
    const finalReceipt = Buffer.from(JSON.stringify(published, null, 2) + '\n');
    await writeFile(path.join(staging, receiptName), finalReceipt);
    await writeFile(path.join(lock, 'journal.json'), JSON.stringify({
      transactionId, directory, staging, receiptName, outputOwner: owner,
      previousArtifacts: [...previous].map(([name, bytes]) => ({ name, sha256: digest(bytes) })),
      nextArtifacts: published.artifacts, oldReceiptSha256: oldReceipt === undefined ? null : digest(oldReceipt),
      newReceiptSha256: digest(finalReceipt), phase: 'prepared',
    }) + '\n');
    await beforeCommit?.();
    const lease = JSON.parse((await regularBytes(path.join(lock, 'owner.json')))?.toString('utf8') ?? 'null');
    if (lease?.transactionId !== transactionId) throw new Error('PSC0_OUTPUT_LEASE_CHANGED');

    // Recheck observed ownership after asynchronous validation. This is not an
    // OS-level compare-and-swap against arbitrary concurrent filesystem writers.
    const observedReceipt = await regularBytes(receiptPath);
    if ((oldReceipt === undefined) !== (observedReceipt === undefined) ||
        oldReceipt !== undefined && !oldReceipt.equals(observedReceipt)) {
      throw new Error('PSC0_OUTPUT_CHANGED_DURING_BUILD: ' + receiptName);
    }
    for (const name of new Set([...previous.keys(), ...buffers.keys()])) {
      const bytes = await regularBytes(path.join(directory, name));
      const old = previous.get(name);
      if (old === undefined ? bytes !== undefined : bytes === undefined || !old.equals(bytes)) {
        throw new Error('PSC0_OUTPUT_CHANGED_DURING_BUILD: ' + name);
      }
    }
    if (oldReceipt !== undefined) {
      await rm(receiptPath);
      removedReceipt = true;
    }
    for (const [name, bytes] of buffers) {
      const old = previous.get(name);
      if (old !== undefined && old.equals(bytes)) continue;
      await rename(path.join(staging, name), path.join(directory, name));
      changes.push({ name, now: bytes, old });
    }
    for (const [name, bytes] of previous) {
      if (!buffers.has(name)) {
        await rm(path.join(directory, name));
        changes.push({ name, now: undefined, old: bytes });
      }
    }
    // Observe known invalidation again after the awaited artifact operations.
    // This does not claim an instantaneous snapshot against arbitrary writers.
    await beforeCommit?.();
    // This audit receipt is never a portable proof or a transferable capability.
    await rename(path.join(staging, receiptName), receiptPath);
    completed = true;
    return Object.freeze(published);
  } catch (error) {
    // Restore only bytes still attributable to this transaction. Never overwrite
    // a concurrent user edit to make rollback look successful.
    rollbackComplete = true;
    for (const item of changes.reverse()) {
      try {
        const file = path.join(directory, item.name);
        const current = await regularBytes(file);
        const matches = item.now === undefined ? current === undefined
          : current !== undefined && current.equals(item.now);
        if (!matches) { rollbackComplete = false; continue; }
        if (item.old === undefined) await rm(file, { force: true });
        else {
          const restore = path.join(staging, item.name + '.restore');
          await writeFile(restore, item.old);
          await rename(restore, file);
        }
      } catch { rollbackComplete = false; }
    }
    if (removedReceipt && rollbackComplete) {
      try {
        for (const [name, old] of previous) {
          const current = await regularBytes(path.join(directory, name));
          if (current === undefined || !current.equals(old)) {
            rollbackComplete = false;
            break;
          }
        }
        for (const name of buffers.keys()) {
          if (!previous.has(name) && await regularBytes(path.join(directory, name)) !== undefined) {
            rollbackComplete = false;
          }
        }
      } catch { rollbackComplete = false; }
    }
    if (removedReceipt && rollbackComplete) {
      try {
        const receiptPath = path.join(directory, receiptName);
        if (await regularBytes(receiptPath) !== undefined) rollbackComplete = false;
        else {
          const restore = path.join(staging, receiptName + '.restore');
          await writeFile(restore, oldReceipt);
          await rename(restore, receiptPath);
        }
      } catch { rollbackComplete = false; }
    }
    if (!rollbackComplete) {
      throw new Error('PSC0_OUTPUT_RECOVERY_REQUIRED: ' + output, { cause: error });
    }
    throw error;
  } finally {
    // An interrupted process or incomplete rollback keeps a visible lock. Never
    // break another writer's lease automatically. Private backups are retained
    // when explicit recovery is required; no completed result is reported.
    if (completed || rollbackComplete) {
      if (staging) await rm(staging, { recursive: true, force: true }).catch(() => {});
      const lease = await regularBytes(path.join(lock, 'owner.json')).catch(() => undefined);
      let owned = false;
      try { owned = JSON.parse(lease?.toString('utf8') ?? 'null')?.transactionId === transactionId; } catch {}
      if (owned) await rm(lock, { recursive: true, force: true }).catch(() => {});
    } else if (staging) {
      await writeFile(path.join(lock, 'recovery.json'), JSON.stringify({
        staging, output, entryPath: owner, state: 'recovery-required',
      }) + '\n').catch(() => {});
    }
  }
}
