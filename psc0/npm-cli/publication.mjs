// Immutable generation + one atomic executable switch. Products and receipt
// are inside the generation. The OS/installation owner remains trusted.
import { mkdir, mkdtemp, lstat, realpath, open, writeFile, rename, rm } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
async function absentOrRegular(file) {
  try { const s = await lstat(file); if (!s.isFile() || s.isSymbolicLink()) throw new Error('PSC_OUTPUT_UNSAFE_PATH: ' + file); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
}
async function assertNotInput(primary, protectedPaths) {
  // Both sides must use the same canonical filesystem representation. Windows
  // drive casing, short names and parent aliases can spell the same file
  // differently; string equality against a canonical parent is insufficient.
  let actual;
  try { actual = await realpath(primary); }
  catch (error) { if (error.code !== 'ENOENT') throw error; actual = primary; }
  for (const input of protectedPaths) {
    const canonical = await realpath(input);
    if (path.relative(canonical, actual) === '') throw new Error('PSC_OUTPUT_OVERWRITES_INPUT');
  }
}
export async function publishGeneration({ output, products, receipt, snapshot }) {
  if (!/\.(js|ts)$/u.test(output)) throw new Error('PSC_OUTPUT_EXTENSION');
  const requested = path.resolve(output);
  await mkdir(path.dirname(requested), { recursive: true });
  const parent = await realpath(path.dirname(requested));
  const stem = path.basename(requested).replace(/\.(js|ts)$/u, '');
  if (!/^[A-Za-z_][A-Za-z_0-9.-]*$/u.test(stem)) throw new Error('PSC_OUTPUT_NAME');
  const primary = path.join(parent, path.basename(requested));
  await absentOrRegular(primary);
  await assertNotInput(primary, snapshot.protectedPaths);
  const lockName = primary + '.psc-lock';
  const lock = await open(lockName, 'wx', 0o600);
  let directory, committed = false;
  try {
    const storage = path.join(parent, '.psc-artifacts');
    await mkdir(storage, { recursive: true });
    const info = await lstat(storage);
    if (!info.isDirectory() || info.isSymbolicLink() || await realpath(storage) !== storage) throw new Error('PSC_OUTPUT_UNSAFE_STORAGE');
    directory = await mkdtemp(path.join(storage, stem + '-'));
    const outputs = [];
    for (const extension of ['.ts', '.js', '.d.ts', '.js.map']) {
      const data = products[extension];
      if (typeof data !== 'string' || Buffer.byteLength(data) > 32 * 1024 * 1024) throw new Error('PSC_OUTPUT_PRODUCT: ' + extension);
      const name = stem + extension;
      await writeFile(path.join(directory, name), data, { flag: 'wx', mode: 0o600 });
      outputs.push({ name, bytes: Buffer.byteLength(data), sha256: hash(data) });
    }
    const audit = { ...receipt, publication: 'immutable-generation/1', generation: path.basename(directory), artifacts: outputs, artifactDirectory: directory, receiptPath: path.join(directory, 'receipt.json'), output: primary };
    await writeFile(audit.receiptPath, JSON.stringify(audit, null, 2) + '\n', { flag: 'wx', mode: 0o600 });
    const relative = './' + path.relative(parent, path.join(directory, stem + '.js')).split(path.sep).join('/');
    const launcher = '// PSC0 checked generation; evidence: ' + path.relative(parent, audit.receiptPath).split(path.sep).join('/') + '\nexport * from ' + JSON.stringify(relative) + ';\n';
    const switchFile = path.join(directory, 'entry.tmp');
    await writeFile(switchFile, launcher, { flag: 'wx', mode: 0o600 });
    await snapshot.revalidate();
    if (await realpath(path.dirname(requested)) !== parent) throw new Error('PSC_OUTPUT_PARENT_CHANGED');
    await absentOrRegular(primary);
    await assertNotInput(primary, snapshot.protectedPaths);
    await rename(switchFile, primary); // The single public commit point.
    committed = true;
    return Object.freeze(audit);
  } finally {
    // Cleanup cannot turn a completed commit into a reported failed build.
    // Interrupted/stale locks are intentionally not stolen by another writer.
    if (directory && !committed) await rm(directory, { recursive: true, force: true }).catch(e => console.warn('PSC_STAGING_CLEANUP: ' + e.message));
    await lock.close().catch(e => console.warn('PSC_LOCK_CLOSE: ' + e.message));
    await rm(lockName, { force: true }).catch(e => console.warn('PSC_LOCK_CLEANUP: ' + e.message));
  }
}
