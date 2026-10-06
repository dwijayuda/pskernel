import { lstat, readdir, realpath } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import path from 'node:path';
import { pinnedTypeScriptVersion } from './typescript-cli.mjs';
import { readObservedFileBytes as readBounded } from './observed-file-bytes.mjs';

const defaults = Object.freeze({ maxFiles: 2048, maxFileBytes: 64 * 1024 * 1024,
  maxTotalBytes: 80 * 1024 * 1024, maxDepth: 24, maxMetadataBytes: 1024 * 1024 });
const captures = new WeakMap();
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const fail = code => { throw new Error('PSC_TYPESCRIPT_INPUTS_' + code); };
const order = (a, b) => a < b ? -1 : a > b ? 1 : 0;
function budgets(overrides = {}) {
  if (Object.keys(overrides).some(key => !Object.hasOwn(defaults, key))) fail('BUDGET');
  const result = { ...defaults, ...overrides };
  if (Object.values(result).some(value => !Number.isSafeInteger(value) || value < 0)) fail('BUDGET');
  return result;
}
async function manifest(file, bound) {
  try {
    const bytes = await readBounded(file, bound.maxMetadataBytes);
    return { value: JSON.parse(bytes), sha256: hash(bytes) };
  }
  catch (error) {
    if (error instanceof SyntaxError) fail('PACKAGE_JSON');
    throw error;
  }
}
async function inventory(roots, bound) {
  const files = [], pending = roots.map(root => ({ ...root, relative: '', depth: 0 }));
  let total = 0, directories = 0;
  while (pending.length) {
    const item = pending.pop();
    if (++directories > bound.maxFiles || item.depth > bound.maxDepth) fail('RESOURCE_EXHAUSTED');
    const directory = path.join(item.root, item.relative), info = await lstat(directory);
    if (!info.isDirectory() || info.isSymbolicLink() || await realpath(directory) !== directory) fail('DIRECTORY_SHAPE');
    const entries = await readdir(directory, { withFileTypes: true });
    if (entries.length > bound.maxFiles) fail('RESOURCE_EXHAUSTED');
    for (const entry of entries) {
      // Only the selected platform dependency is separately included below.
      if (entry.name === 'node_modules' && entry.isDirectory()) continue;
      const relative = path.join(item.relative, entry.name), absolute = path.join(item.root, relative);
      if (entry.isSymbolicLink()) fail('SYMLINK');
      if (entry.isDirectory()) pending.push({ ...item, relative, depth: item.depth + 1 });
      else {
        if (!entry.isFile()) fail('FILE_SHAPE');
        if (files.length >= bound.maxFiles) fail('RESOURCE_EXHAUSTED');
        const bytes = await readBounded(absolute, Math.min(bound.maxFileBytes, bound.maxTotalBytes - total));
        total += bytes.length;
        files.push({ path: item.name + '/' + relative.split(path.sep).join('/'), bytes });
      }
    }
  }
  return files.sort((a, b) => order(a.path, b.path));
}

/** Installed TypeScript 7 profile: snapshot both package trees and invoke the
 * selected native executable directly. Custom launchers retain entry-only
 * coverage. This is observed input data, not compiler correctness or a sandbox.
 */
export async function captureTypeScriptToolInputs(cli, limits) {
  const bound = budgets(limits), entry = await realpath(cli);
  const root = path.dirname(path.dirname(entry));
  let packageMetadata;
  if (path.basename(entry) === 'tsc' && path.basename(path.dirname(entry)) === 'bin') {
    try { packageMetadata = await manifest(path.join(root, 'package.json'), bound); }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  let roots = [], files, command = process.execPath, argumentsPrefix = [entry];
  let coverage = 'explicit-entry-only', nativePath = null;
  const packageInfo = packageMetadata?.value;
  if (packageInfo?.name === 'typescript') {
    if (packageInfo.version !== pinnedTypeScriptVersion || packageInfo.bin?.tsc !== './bin/tsc') fail('PACKAGE_PROFILE');
    const nativeName = '@typescript/typescript-' + process.platform + '-' + process.arch;
    if (packageInfo.optionalDependencies?.[nativeName] !== pinnedTypeScriptVersion) fail('NATIVE_PACKAGE_PROFILE');
    const nativeManifest = createRequire(entry).resolve(nativeName + '/package.json');
    const nativeRoot = await realpath(path.dirname(nativeManifest));
    const nativeMetadata = await manifest(path.join(nativeRoot, 'package.json'), bound);
    const nativeInfo = nativeMetadata.value;
    if (nativeInfo.name !== nativeName || nativeInfo.version !== pinnedTypeScriptVersion ||
        !nativeInfo.os?.includes(process.platform) || !nativeInfo.cpu?.includes(process.arch)) fail('NATIVE_PACKAGE_PROFILE');
    roots = [{ name: 'typescript', root }, { name: nativeName, root: nativeRoot }];
    files = await inventory(roots, bound);
    if (hash(files.find(item => item.path === 'typescript/package.json')?.bytes ?? Buffer.alloc(0)) !== packageMetadata.sha256 ||
        hash(files.find(item => item.path === nativeName + '/package.json')?.bytes ?? Buffer.alloc(0)) !== nativeMetadata.sha256) fail('CHANGED');
    nativePath = nativeName + '/lib/tsc' + (process.platform === 'win32' ? '.exe' : '');
    if (!files.some(item => item.path === nativePath) || !files.some(item => item.path === 'typescript/bin/tsc')) fail('MISSING_EXECUTABLE');
    command = path.join(nativeRoot, 'lib', 'tsc' + (process.platform === 'win32' ? '.exe' : ''));
    argumentsPrefix = [];
    coverage = 'installed-package-and-selected-native-package';
  } else files = [{ path: 'explicit-entry', bytes: await readBounded(entry, Math.min(bound.maxFileBytes, bound.maxTotalBytes)) }];
  if (files.length > bound.maxFiles) fail('RESOURCE_EXHAUSTED');
  const details = Object.freeze({ contract: 'psc-typescript-tool-inputs/1', version: pinnedTypeScriptVersion,
    coverage, platform: process.platform, arch: process.arch,
    entryPath: coverage === 'explicit-entry-only' ? 'explicit-entry' : 'typescript/bin/tsc', nativePath,
    fullInputClosureEstablished: false,
    excluded: Object.freeze(['unselected optional dependencies', 'host runtime and OS libraries',
      'ambient environment and filesystem resolution outside these package trees']),
    files: Object.freeze(files.map(item => Object.freeze({ path: item.path, byteLength: item.bytes.length, sha256: hash(item.bytes) }))) });
  const handle = Object.freeze({ command, argumentsPrefix: Object.freeze(argumentsPrefix), details });
  captures.set(handle, { entry, roots, bound, files, details });
  return handle;
}

/** Compare complete inventories and bytes after execution. A trusted local
 * filesystem is still assumed; before/after hashes do not defeat hostile ABA.
 */
export async function verifyTypeScriptToolInputs(handle) {
  const captured = captures.get(handle);
  if (!captured) fail('UNKNOWN_CAPTURE');
  const { entry, roots, bound, files, details } = captured;
  if (await realpath(entry) !== entry) fail('CHANGED');
  const current = roots.length ? await inventory(roots, bound)
    : [{ path: 'explicit-entry', bytes: await readBounded(entry, Math.min(bound.maxFileBytes, bound.maxTotalBytes)) }];
  if (current.length !== files.length || current.some((item, index) =>
    item.path !== details.files[index].path || hash(item.bytes) !== details.files[index].sha256)) fail('CHANGED');
  return Object.freeze({ details, files: Object.freeze(files.map(item => Object.freeze({ path: item.path, bytes: Buffer.from(item.bytes) }))) });
}
