// Host filesystem protocol only. Admission remains private to compiler sessions.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
const json = value => JSON.stringify(value, null, 2) + '\n';
const fail = code => { throw Error('PSC1_SERVICE_' + code); };
const inspect = file => { try { return fs.lstatSync(file); } catch (e) { if (e.code === 'ENOENT') return null; throw e; } };
export const publicationProtocols = Object.freeze(['legacy-symlink', 'portable-file']);
export function requirePublicationPlatform(protocol) {
  if (!publicationProtocols.includes(protocol)) fail('PUBLICATION_PROTOCOL');
  // The portable layout needs no symlink privilege. Enabling another OS still
  // requires its actual directory-durability and atomic-replace release evidence.
  if (process.platform !== 'linux') fail('PUBLICATION_PLATFORM_UNQUALIFIED');
}
function syncDirectory(directory) {
  const fd = fs.openSync(directory, 'r');
  try { fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
}
function regular(file, limit = 128 * 1024 * 1024) {
  const stat = fs.lstatSync(file);
  if (!stat.isFile() || stat.isSymbolicLink() || stat.size > limit) fail('ARTIFACT_CHANGED');
  return fs.readFileSync(file);
}
function pointer(root, protocol) {
  const file = path.join(root, protocol === 'portable-file' ? 'current.json' : 'current');
  const stat = inspect(file);
  if (!stat) return null;
  if (protocol === 'legacy-symlink') {
    if (!stat.isSymbolicLink()) fail('CURRENT_INVALID');
    const link = fs.readlinkSync(file);
    if (!/^generations\/[a-f0-9]{64}$/.test(link)) fail('CURRENT_INVALID');
    return { generation: link.slice(12), token: link };
  }
  let value, bytes;
  try { bytes = regular(file, 4096); value = JSON.parse(bytes); } catch { fail('CURRENT_INVALID'); }
  if (!value || Object.keys(value).sort().join(',') !== 'generation,manifestSha256,schema' ||
      value.schema !== 'psc1-publication-pointer/1' ||
      !/^[a-f0-9]{64}$/.test(value.generation) ||
      value.manifestSha256 !== value.generation || bytes.toString('utf8') !== json(value))
    fail('CURRENT_INVALID');
  return { generation: value.generation, token: sha(bytes) };
}
function verifyGeneration(directory, generation, expectedFiles) {
  if (!inspect(directory)?.isDirectory() || inspect(directory).isSymbolicLink()) fail('GENERATION_INVALID');
  const text = regular(path.join(directory, 'manifest.json'));
  if (sha(text) !== generation) fail('MANIFEST_CHANGED');
  const manifest = JSON.parse(text);
  if (manifest.schema !== 'psc1-generated-service-bundle/1' || !Array.isArray(manifest.files))
    fail('MANIFEST_INVALID');
  if (expectedFiles && json(manifest.files) !== json(expectedFiles)) fail('ARTIFACT_CHANGED');
  const names = manifest.files.map(row => row.path);
  if (new Set(names).size !== names.length ||
      names.some(name => !/^[a-z][a-z0-9.-]*$/.test(name) || name === 'manifest.json') ||
      fs.readdirSync(directory).sort().join(',') !== [...names, 'manifest.json'].sort().join(','))
    fail('ARTIFACT_CHANGED');
  for (const row of manifest.files) {
    const bytes = regular(path.join(directory, row.path));
    if (bytes.length !== row.bytes || sha(bytes) !== row.sha256) fail('ARTIFACT_CHANGED');
  }
  return manifest;
}
export function readPublication(root, protocol = 'legacy-symlink') {
  requirePublicationPlatform(protocol);
  root = path.resolve(root);
  const value = pointer(root, protocol);
  if (!value) return null;
  const directory = path.join(root, 'generations', value.generation);
  const manifest = verifyGeneration(directory, value.generation);
  const targetFile = manifest.targetFile || 'target.mjs';
  if (!manifest.files.some(row => row.path === targetFile)) fail('MANIFEST_INVALID');
  return Object.freeze({ generation: value.generation, directory,
    manifestSha256: value.generation, target: path.join(directory, targetFile),
    protocol, durability: 'confirmed-at-commit', manifest });
}
export function openPublicationStore(root, protocol = 'legacy-symlink') {
  requirePublicationPlatform(protocol);
  root = path.resolve(root);
  for (const directory of [root, path.join(root, 'generations')]) {
    const stat = inspect(directory);
    if (stat && (!stat.isDirectory() || stat.isSymbolicLink())) fail('STORE_INVALID');
    fs.mkdirSync(directory, { recursive: true });
  }
  const pointerName = protocol === 'portable-file' ? 'current.json' : 'current';
  if (fs.readdirSync(root).some(name =>
    !['generations', pointerName, '.publish.lock'].includes(name))) fail('STORE_UNMANAGED');
  const prior = pointer(root, protocol);
  let consumed = false;
  return Object.freeze({
    root, protocol,
    publish({ stage, manifest, verify, fault = () => {} }) {
      if (consumed) fail('PUBLICATION_CONSUMED');
      consumed = true;
      if (path.dirname(path.resolve(stage)) !== path.join(root, 'generations') ||
          !path.basename(stage).startsWith('.stage-')) fail('STAGE_OUTSIDE_OUTPUT_STORE');
      const lock = path.join(root, '.publish.lock');
      let fd, committed = false, temporary, result;
      try {
        fd = fs.openSync(lock, 'wx', 0o600);
        fs.writeFileSync(fd, json({ schema: 'psc1-publication-lock/1',
          pid: process.pid, host: os.hostname(), nonce: crypto.randomUUID() }));
        fs.fsyncSync(fd);
        if ((pointer(root, protocol)?.token ?? null) !== (prior?.token ?? null))
          fail('PRIOR_PUBLICATION_CHANGED');
        verify();
        fault('before-seal');
        const text = json(manifest), generation = sha(text);
        fs.writeFileSync(path.join(stage, 'manifest.json'), text, { flag: 'wx' });
        for (const name of fs.readdirSync(stage)) {
          const file = fs.openSync(path.join(stage, name), 'r');
          try { fs.fsyncSync(file); } finally { fs.closeSync(file); }
        }
        syncDirectory(stage);
        const directory = path.join(root, 'generations', generation);
        if (inspect(directory)) fail('GENERATION_ALREADY_EXISTS');
        fs.renameSync(stage, directory);
        syncDirectory(path.join(root, 'generations'));
        fault('after-seal');
        verify();
        verifyGeneration(directory, generation, manifest.files);
        const targetFile = manifest.targetFile || 'target.mjs';
        if (!manifest.files.some(row => row.path === targetFile)) fail('MANIFEST_INVALID');
        temporary = path.join(root, '.current-' + crypto.randomUUID());
        if (protocol === 'legacy-symlink') fs.symlinkSync('generations/' + generation, temporary);
        else {
          const file = fs.openSync(temporary, 'wx', 0o600);
          try {
            fs.writeFileSync(file, json({ schema: 'psc1-publication-pointer/1',
              generation, manifestSha256: generation }));
            fs.fsyncSync(file);
          } finally { fs.closeSync(file); }
        }
        syncDirectory(root);
        fault('before-commit');
        fs.renameSync(temporary, path.join(root, pointerName));
        temporary = undefined;
        committed = true;
        result = Object.freeze({ generation, directory, manifestSha256: generation,
          target: path.join(directory, targetFile), immutableTarget: path.join(directory, targetFile),
          ...(protocol === 'legacy-symlink' ? { currentAlias: path.join(root, 'current', targetFile) } : {}),
          protocol, durability: 'confirmed' });
        fault('after-commit');
        syncDirectory(root);
        return result;
      } catch (error) {
        if (committed) {
          const uncertain = Error('PSC1_SERVICE_PUBLICATION_COMMITTED_DURABILITY_UNCERTAIN', { cause: error });
          Object.defineProperty(uncertain, 'committedPublication',
            { value: Object.freeze({ ...result, durability: 'unconfirmed' }), enumerable: true });
          throw uncertain;
        }
        throw error;
      } finally {
        if (temporary && inspect(temporary)) fs.unlinkSync(temporary);
        if (fd !== undefined) { fs.closeSync(fd); fs.unlinkSync(lock); }
      }
    },
  });
}
