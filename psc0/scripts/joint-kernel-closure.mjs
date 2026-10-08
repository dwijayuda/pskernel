import { createHash } from 'node:crypto';
import { readdir, readFile, realpath } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseImports } from './workspace-layout.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sourceRoot = path.join(root, 'packages/pskernel-core/src');
export const kernelEntry = 'Ps.KernelCore.SelfHost';
export const kernelEntryRelative = 'packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean';

export function kernelModuleRelative(name) {
  if (typeof name !== 'string' || !/^Ps\.KernelCore(?:\.[A-Za-z_][A-Za-z0-9_]*)+$/u.test(name)) {
    throw new Error('PSC0_JOINT_IMPORT_OUTSIDE_IMPLEMENTATION: ' + String(name));
  }
  return name.replaceAll('.', '/') + '.lean';
}

function assertWithin(rootDir, filename) {
  const relative = path.relative(rootDir, filename);
  if (!relative || relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative)) {
    throw new Error('PSC0_JOINT_SOURCE_BOUNDARY: ' + filename);
  }
}

export async function analyzeKernelClosure({ requireFull = true } = {}) {
  const resolvedRoot = await realpath(sourceRoot);
  const seen = new Set();
  const visiting = new Set();
  const ordered = [];
  const hash = createHash('sha256');
  hash.update('psc0-joint-kernel-implementation/1\0', 'utf8');
  async function visit(name) {
    const relative = kernelModuleRelative(name);
    if (visiting.has(relative)) throw new Error('PSC0_JOINT_IMPORT_CYCLE: ' + relative);
    if (seen.has(relative)) return;
    const candidate = path.join(sourceRoot, relative);
    assertWithin(sourceRoot, candidate);
    let actual;
    try { actual = await realpath(candidate); }
    catch { throw new Error('PSC0_JOINT_SOURCE_MISSING: ' + relative); }
    assertWithin(resolvedRoot, actual);
    const source = await readFile(actual, 'utf8');
    visiting.add(relative);
    for (const imported of parseImports(source)) await visit(imported);
    visiting.delete(relative);
    seen.add(relative);
    ordered.push({ path: relative, source });
  }
  await visit(kernelEntry);
  const diskFiles = [];
  async function walk(directory) {
    const items = await readdir(directory, { withFileTypes: true });
    for (const item of items) {
      const absolute = path.join(directory, item.name);
      if (item.isSymbolicLink()) throw new Error('PSC0_JOINT_SYMLINK_FORBIDDEN: ' + absolute);
      if (item.isDirectory()) await walk(absolute);
      else if (item.isFile() && item.name.endsWith('.lean')) {
        diskFiles.push(path.relative(sourceRoot, absolute).split(path.sep).join('/'));
      }
    }
  }
  await walk(sourceRoot);
  diskFiles.sort();
  const missing = diskFiles.filter(p => !seen.has(p));
  if (requireFull && missing.length) {
    throw new Error('PSC0_JOINT_ORPHAN_IMPLEMENTATION_MODULES: ' + missing.join(','));
  }
  const canonical = [...ordered].sort((a, b) => a.path.localeCompare(b.path, 'en'));
  for (const item of canonical) {
    hash.update(item.path + '\0', 'utf8');
    hash.update(item.source, 'utf8');
    hash.update('\0', 'utf8');
  }
  return Object.freeze({
    schemaVersion: 1,
    entry: kernelEntryRelative,
    moduleCount: ordered.length,
    sourceFiles: diskFiles.length,
    missing,
    sourceSha256: hash.digest('hex'),
    modules: ordered.map(v => 'packages/pskernel-core/src/' + v.path),
    proofModules: 0,
    metatheoryModules: 0,
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  if (args.some(x => !['--json', '--assert-full'].includes(x))) {
    throw new Error('usage: joint-kernel-closure.mjs [--json] [--assert-full]');
  }
  const report = await analyzeKernelClosure({ requireFull: true });
  if (args.includes('--json')) console.log(JSON.stringify(report));
  else console.log('PSC0_JOINT_KERNEL_IMPLEMENTATION_CLOSURE: PASS modules=' +
    report.moduleCount + ' sha256=' + report.sourceSha256 +
    ' proof=0 metatheory=0');
}
