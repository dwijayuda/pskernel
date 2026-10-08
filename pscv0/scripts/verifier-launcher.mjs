import { createHash } from 'node:crypto';
import { constants } from 'node:fs';
import { lstat, open } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

// This is copied to the distribution root. Load only Node built-ins until the
// independently supplied manifest hash and all declared files have checked.
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error('PSC_VERIFIER_DISTRIBUTION_' + code); };
async function boundedFile(file, maximum) {
  const before = await lstat(file);
  if (!before.isFile() || before.isSymbolicLink() || before.size > maximum) fail('FILE_SHAPE_OR_SIZE');
  const handle = await open(file, constants.O_RDONLY | (process.platform === 'win32' ? 0 : constants.O_NOFOLLOW));
  try {
    const info = await handle.stat();
    if (!info.isFile() || info.size > maximum) fail('FILE_SHAPE_OR_SIZE');
    const bytes = Buffer.alloc(info.size); let offset = 0;
    while (offset < bytes.length) {
      const result = await handle.read(bytes, offset, bytes.length - offset, offset);
      if (!result.bytesRead) fail('FILE_TRUNCATED'); offset += result.bytesRead;
    }
    if ((await handle.read(Buffer.alloc(1), 0, 1, offset)).bytesRead) fail('FILE_GREW');
    return bytes;
  } finally { await handle.close(); }
}
async function main() {
  const args = process.argv.slice(2);
  if (args[0] !== '--manifest-sha256' || !/^[a-f0-9]{64}$/u.test(args[1] ?? '') ||
      !(args.length === 6 && ['--capsule', '--build-archive'].includes(args[2]) && args[4] === '--policy') &&
      !(args.length === 5 && args[2] === '--diff-locks')) {
    throw new Error('Usage: pscv-verify.mjs --manifest-sha256 PINNED_HASH --capsule FILE --policy LOCAL_POLICY | --build-archive FILE --policy LOCAL_POLICY | --diff-locks LEFT RIGHT');
  }
  if (Number(process.versions.node.split('.')[0]) < 22) fail('NODE_VERSION');
  const root = path.dirname(fileURLToPath(import.meta.url));
  const bytes = await boundedFile(path.join(root, 'manifest.json'), 4 * 1024 * 1024);
  if (digest(bytes) !== args[1]) fail('MANIFEST_HASH');
  const manifest = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
  if (manifest.contract !== 'psc-verifier-distribution/1' || !['wasm-literal-offline/1', 'lean434-wasm-offline/1'].includes(manifest.profile) ||
      !Array.isArray(manifest.files) || manifest.files.length > 128) fail('MANIFEST_SCHEMA');
  let previous = '', total = 0;
  for (const file of manifest.files) {
    if (typeof file.path !== 'string' || !/^[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_.-]+)*$/u.test(file.path) ||
        file.path.split('/').some(part => part === '.' || part === '..') || file.path <= previous ||
        !Number.isSafeInteger(file.byteLength) || file.byteLength < 0 || file.byteLength > 16 * 1024 * 1024 ||
        !/^[a-f0-9]{64}$/u.test(file.sha256)) fail('FILE_DESCRIPTOR');
    previous = file.path; total += file.byteLength;
    if (total > 32 * 1024 * 1024) fail('TOTAL_BYTES');
    let parent = root;
    for (const part of file.path.split('/').slice(0, -1)) {
      parent = path.join(parent, part); const info = await lstat(parent);
      if (!info.isDirectory() || info.isSymbolicLink()) fail('DIRECTORY_SHAPE');
    }
    const actual = await boundedFile(path.join(root, file.path), file.byteLength);
    if (actual.length !== file.byteLength || digest(actual) !== file.sha256) fail('FILE_HASH: ' + file.path);
  }
  if (!manifest.files.some(file => file.path === 'scripts/offline-verifier-cli.mjs') ||
      !manifest.files.some(file => file.path === 'pscv-verify.mjs')) fail('ENTRY_REQUIRED');
  // Filesystem/Node execution is a trusted host assumption. Hashing does not
  // sandbox a hostile host or prevent mutation between this check and import.
  const api = await import(pathToFileURL(path.join(root, 'scripts/offline-verifier-cli.mjs')).href);
  const withLean = manifest.profile === 'lean434-wasm-offline/1';
  const result = args[2] === '--diff-locks' ? await api.compareSemanticLockFiles(args[3], args[4]) :
    args[2] === '--build-archive' ? await api.verifyBuildArchiveCommand(args[3], args[5]) :
    await api.verifyCapsuleCommand(args[3], args[5], { allowedCheckerKinds: withLean ? ['core-proof', 'wasm-literal'] : ['wasm-literal'],
      allowedCoreProviders: withLean ? ['lean434-wasm'] : [] });
  process.stdout.write(JSON.stringify(result) + '\n');
  if (result.kind && result.kind !== 'accepted') process.exitCode = 1;
}
main().catch(error => { process.stderr.write(error.message + '\n'); process.exitCode = 1; });
