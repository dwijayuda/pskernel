import { readFile, writeFile, mkdir, mkdtemp, rename, rm, lstat } from 'node:fs/promises';
import path from 'node:path';
import { createHash, randomUUID } from 'node:crypto';

const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const absent = error => error?.code === 'ENOENT';

// Validate native Windows pathname interpretation before either target staging
// or publication writes. A colon names an NTFS stream; DOS device basenames and
// trailing spaces/dots can alias other objects even with an added extension.
export function checkedOutputPath(outputPath) {
  const output = path.resolve(outputPath);
  if (process.platform !== 'win32') return output;
  const fail = () => { throw new Error('PSC0_OUTPUT_WINDOWS_PATH: ' + output); };
  let normal = output;
  if (normal.startsWith('\\\\.\\')) fail();
  if (normal.startsWith('\\\\?\\')) {
    const extended = normal.slice(4);
    if (/^[A-Za-z]:\\/u.test(extended)) normal = extended;
    else if (/^UNC\\/iu.test(extended)) normal = '\\\\' + extended.slice(4);
    else fail(); // Other extended namespaces are not ordinary filesystem roots.
  }
  // Exclude the drive or complete UNC server/share root from component rules.
  for (const component of normal.slice(path.parse(normal).root.length).split(path.sep)) {
    const base = component.split('.')[0].replace(/ +$/u, '');
    if (/[<>:"|?*\u0000-\u001f]/u.test(component) || /[ .]$/u.test(component) ||
        /^(?:CON|PRN|AUX|NUL|COM[1-9¹²³]|LPT[1-9¹²³])$/iu.test(base) ||
        /^(?:CONIN\$|CONOUT\$)$/iu.test(component)) fail();
  }
  return output;
}

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
    if (typeof item?.name !== 'string' || !item.name || item.name.split('/').some(part => !part || part === '.' || part === '..') ||
        /[\\:\u0000-\u001f]/u.test(item.name) || path.posix.isAbsolute(item.name) || !/^[a-f0-9]{64}$/.test(item.sha256) ||
        names.has(item.name)) throw new Error('PSC0_OUTPUT_OWNERSHIP_SHAPE');
    names.add(item.name);
  }
  return names;
}


function relativeArtifact(value) {
  if (typeof value !== 'string' || value.length === 0 || value.length > 1024 ||
      /[\\:\u0000-\u001f]/u.test(value) || path.posix.isAbsolute(value) ||
      value.split('/').some(part => !part || part === '.' || part === '..' ||
        part === '.psc-output-lock' || /^\.psc-(?:stage|target)-/u.test(part))) {
    throw new Error('PSC0_OUTPUT_ARTIFACT_NAME: ' + value);
  }
  return value;
}
function insideName(directory, file) {
  return relativeArtifact(path.relative(directory, checkedOutputPath(file)).split(path.sep).join('/'));
}
function libraryNames(bundle, sources) {
  relativeArtifact(bundle);
  if (!bundle.endsWith('.ts') || !Array.isArray(sources) || sources.length === 0) {
    throw new Error('PSC0_OUTPUT_LIBRARY_LAYOUT');
  }
  const allowed = new Set([bundle]);
  const folded = new Set([bundle.toLowerCase()]);
  for (const source of sources) {
    relativeArtifact(source);
    if (!source.endsWith('.ps')) throw new Error('PSC0_OUTPUT_LIBRARY_SOURCE: ' + source);
    const name = source.slice(0, -3) + '.ts';
    if (folded.has(name.toLowerCase())) throw new Error('PSC0_OUTPUT_LIBRARY_COLLISION: ' + name);
    folded.add(name.toLowerCase()); allowed.add(name);
  }
  return allowed;
}
function previousNames(receipt, owner, allowed, layout) {
  const names = ownedNames(receipt, owner);
  let previousAllowed = allowed;
  if (layout) {
    const previous = receipt.publication;
    if (previous?.layout !== 'psc-ts-library/1' || previous.bundle !== layout.bundle) {
      throw new Error('PSC0_OUTPUT_OWNERSHIP_CONFLICT');
    }
    previousAllowed = libraryNames(previous.bundle, previous.facadeSources);
    if (names.size !== previousAllowed.size) throw new Error('PSC0_OUTPUT_OWNERSHIP_SHAPE');
  } else if (receipt.publication !== undefined) {
    throw new Error('PSC0_OUTPUT_OWNERSHIP_CONFLICT');
  }
  for (const name of names) {
    if (!previousAllowed.has(name)) throw new Error('PSC0_OUTPUT_OWNERSHIP_SHAPE');
  }
  return names;
}
async function ensureDirectory(directory) {
  const parent = path.dirname(directory);
  if (parent !== directory) await ensureDirectory(parent);
  let status;
  try { status = await lstat(directory); }
  catch (error) {
    if (!absent(error)) throw error;
    try { await mkdir(directory); }
    catch (cause) { if (cause.code !== 'EEXIST') throw cause; }
    status = await lstat(directory);
  }
  if (!status.isDirectory() || status.isSymbolicLink()) {
    throw new Error('PSC0_OUTPUT_DIRECTORY_LINK: ' + directory);
  }
}
export async function prepareCheckedOutputDirectory(outputPath) {
  const output = checkedOutputPath(outputPath);
  await ensureDirectory(path.dirname(output));
  return output;
}
async function assertDirectories(directories) {
  for (const directory of directories) {
    let current = directory;
    for (;;) {
      const status = await lstat(current);
      if (!status.isDirectory() || status.isSymbolicLink()) {
        throw new Error('PSC0_OUTPUT_DIRECTORY_LINK: ' + current);
      }
      const parent = path.dirname(current);
      if (parent === current) break;
      current = parent;
    }
  }
}
async function stageBytes(staging, name, bytes) {
  const file = path.join(staging, name);
  await mkdir(path.dirname(file), { recursive: true });
  await writeFile(file, bytes);
}

/**
 * Trusted publication helper. Only the supervisor calls this after validation.
 * This is a local multi-file transaction with a completion receipt, not a claim
 * that independent filesystem consumers observe several renames atomically.
 */
export async function publishCheckedArtifacts({ outputPath, entryPath, artifacts, receipt, beforeCommit,
  projectRoot, facadeSources }) {
  const output = checkedOutputPath(outputPath);
  const library = facadeSources !== undefined;
  const directory = library ? path.resolve(projectRoot ?? '') : path.dirname(output);
  if (library && typeof projectRoot !== 'string') throw new Error('PSC0_OUTPUT_LIBRARY_ROOT');
  const bundle = library ? insideName(directory, output) : path.basename(output);
  const stem = path.basename(output).replace(/\.(?:ts|js)$/u, '');
  if (!/\.(?:ts|js)$/u.test(output) || !stem) throw new Error('PSC0_OUTPUT_KIND');
  const receiptName = library ? bundle.slice(0, -3) + '.checked.json' : stem + '.checked.json';
  if (library && !Array.isArray(facadeSources)) throw new Error('PSC0_OUTPUT_LIBRARY_LAYOUT');
  const layout = library ? { layout: 'psc-ts-library/1', bundle,
    facadeSources: [...facadeSources] } : undefined;
  const owner = path.relative(directory, path.resolve(entryPath)).split(path.sep).join('/');
  const allowed = library ? libraryNames(bundle, facadeSources)
    : new Set(['.ts', '.js', '.d.ts', '.js.map', '.admissions.json'].map(suffix => stem + suffix));
  for (const name of allowed) checkedOutputPath(path.join(directory, name));
  if (!(artifacts instanceof Map) || artifacts.size === 0 ||
      !artifacts.has(bundle) || library && artifacts.size !== allowed.size) throw new Error('PSC0_OUTPUT_ARTIFACTS');
  const buffers = new Map();
  for (const [name, bytes] of artifacts) {
    if (!allowed.has(name) || (!Buffer.isBuffer(bytes) && typeof bytes !== 'string')) {
      throw new Error('PSC0_OUTPUT_ARTIFACT_NAME: ' + name);
    }
    buffers.set(name, Buffer.from(bytes));
  }
  await ensureDirectory(path.dirname(output));
  const receiptPath = path.join(directory, receiptName);
  const initialReceipt = await regularBytes(receiptPath);
  let initialPrevious;
  if (initialReceipt !== undefined) {
    try { initialPrevious = JSON.parse(initialReceipt.toString('utf8')); }
    catch { throw new Error('PSC0_OUTPUT_OWNERSHIP_SHAPE'); }
  }
  const priorNames = initialPrevious ? previousNames(initialPrevious, owner, allowed, layout) : new Set();
  const allNames = new Set([...priorNames, ...buffers.keys(), receiptName]);
  const folded = new Map();
  for (const name of allNames) {
    checkedOutputPath(path.join(directory, name));
    const key = name.toLowerCase();
    if (folded.has(key) && folded.get(key) !== name) throw new Error('PSC0_OUTPUT_LIBRARY_COLLISION: ' + name);
    folded.set(key, name);
  }
  const directories = [...new Set([directory, ...[...allNames].map(name =>
    path.dirname(path.join(directory, name)))])].sort();
  for (const target of directories) await ensureDirectory(target);
  const lock = path.join(directory, '.psc-output-lock');
  const locks = [];
  const transactionId = randomUUID();
  async function assertLeases() {
    await assertDirectories(directories);
    for (const acquired of locks) {
      const lease = JSON.parse((await regularBytes(path.join(acquired, 'owner.json')))?.toString('utf8') ?? 'null');
      if (lease?.transactionId !== transactionId) throw new Error('PSC0_OUTPUT_LEASE_CHANGED');
    }
  }
  let staging;
  const previous = new Map();
  const changes = [];
  let oldReceipt;
  let removedReceipt = false;
  let completed = false;
  let rollbackComplete = true;
  try {
    // Lock every destination directory, including retired facade directories.
    // This shares leases with ordinary builds and overlapping project outputs.
    for (const target of directories) {
      const acquired = path.join(target, '.psc-output-lock');
      try { await mkdir(acquired); }
      catch (error) {
        if (error.code === 'EEXIST') throw new Error('PSC0_OUTPUT_BUSY: ' + acquired);
        throw error;
      }
      locks.push(acquired);
      await writeFile(path.join(acquired, 'owner.json'),
        JSON.stringify({ transactionId, pid: process.pid, entryPath: owner, primary: lock }) + '\n');
    }
    await assertLeases();
    staging = await mkdtemp(path.join(directory, '.psc-stage-'));
    oldReceipt = await regularBytes(receiptPath);
    if ((initialReceipt === undefined) !== (oldReceipt === undefined) ||
        initialReceipt !== undefined && !initialReceipt.equals(oldReceipt)) {
      throw new Error('PSC0_OUTPUT_CHANGED_DURING_BUILD: ' + receiptName);
    }
    let previousReceipt;
    if (oldReceipt !== undefined) {
      try { previousReceipt = JSON.parse(oldReceipt.toString('utf8')); }
      catch { throw new Error('PSC0_OUTPUT_OWNERSHIP_SHAPE'); }
      const names = previousNames(previousReceipt, owner, allowed, layout);
      for (const item of previousReceipt.artifacts) {
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
      ...(layout ? { publication: layout } : {}),
      artifacts: [...buffers].map(([name, bytes]) => ({ name, sha256: digest(bytes), bytes: bytes.length })),
    };
    await mkdir(path.join(staging, 'previous'));
    for (const [name, bytes] of previous) await stageBytes(staging, 'previous/' + name, bytes);
    if (oldReceipt !== undefined) await stageBytes(staging, 'previous/' + receiptName, oldReceipt);
    for (const [name, bytes] of buffers) await stageBytes(staging, name, bytes);
    const finalReceipt = Buffer.from(JSON.stringify(published, null, 2) + '\n');
    await stageBytes(staging, receiptName, finalReceipt);
    await writeFile(path.join(lock, 'journal.json'), JSON.stringify({
      transactionId, directory, staging, receiptName, outputOwner: owner, locks,
      previousArtifacts: [...previous].map(([name, bytes]) => ({ name, sha256: digest(bytes) })),
      nextArtifacts: published.artifacts, oldReceiptSha256: oldReceipt === undefined ? null : digest(oldReceipt),
      newReceiptSha256: digest(finalReceipt), phase: 'prepared',
    }) + '\n');
    await beforeCommit?.();
    await assertLeases();

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
    await assertLeases();
    if (await regularBytes(receiptPath) !== undefined) {
      throw new Error('PSC0_OUTPUT_CHANGED_DURING_BUILD: ' + receiptName);
    }
    for (const [name, expected] of buffers) {
      const current = await regularBytes(path.join(directory, name));
      if (current === undefined || !current.equals(expected)) {
        throw new Error('PSC0_OUTPUT_CHANGED_DURING_BUILD: ' + name);
      }
    }
    for (const name of previous.keys()) {
      if (!buffers.has(name) && await regularBytes(path.join(directory, name)) !== undefined) {
        throw new Error('PSC0_OUTPUT_CHANGED_DURING_BUILD: ' + name);
      }
    }
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
        await assertDirectories(directories);
        const file = path.join(directory, item.name);
        const current = await regularBytes(file);
        const matches = item.now === undefined ? current === undefined
          : current !== undefined && current.equals(item.now);
        if (!matches) { rollbackComplete = false; continue; }
        if (item.old === undefined) await rm(file, { force: true });
        else {
          const restore = path.join(staging, item.name + '.restore');
          await stageBytes(staging, item.name + '.restore', item.old);
          await rename(restore, file);
        }
      } catch { rollbackComplete = false; }
    }
    if (removedReceipt && rollbackComplete) {
      try {
        await assertDirectories(directories);
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
        await assertDirectories(directories);
        const receiptPath = path.join(directory, receiptName);
        if (await regularBytes(receiptPath) !== undefined) rollbackComplete = false;
        else {
          const restore = path.join(staging, receiptName + '.restore');
          await stageBytes(staging, receiptName + '.restore', oldReceipt);
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
      const cleanupFailures = [];
      if (staging) await rm(staging, { recursive: true, force: true }).catch(() => cleanupFailures.push(staging));
      for (const acquired of [...locks].reverse()) {
        const lease = await regularBytes(path.join(acquired, 'owner.json')).catch(() => undefined);
        let owned = false;
        try { owned = JSON.parse(lease?.toString('utf8') ?? 'null')?.transactionId === transactionId; } catch {}
        if (owned) await rm(acquired, { recursive: true, force: true }).catch(() => cleanupFailures.push(acquired));
        else cleanupFailures.push(acquired);
      }
      if (cleanupFailures.length && completed) {
        process.stderr.write('PSC0_OUTPUT_COMMITTED_CLEANUP_REQUIRED: ' +
          JSON.stringify({ committed: true, transactionId, lock, staging, paths: cleanupFailures }) + '\n');
      }
    } else if (staging) {
      await writeFile(path.join(lock, 'recovery.json'), JSON.stringify({
        staging, output, entryPath: owner, state: 'recovery-required', locks,
      }) + '\n').catch(() => {});
    }
  }
}
