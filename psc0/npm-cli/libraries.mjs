// npm is a distribution mechanism, not proof authority. Read source/JSON only.
import { realpath } from 'node:fs/promises';
import path from 'node:path';
import { createSnapshotReader, contained } from './snapshot.mjs';
const namespacePattern = /^[A-Za-z_][A-Za-z_0-9]*(?:\.[A-Za-z_][A-Za-z_0-9]*)*$/u;
const packagePattern = /^(?:@[a-z0-9][a-z0-9._-]*\/)?[a-z0-9][a-z0-9._-]*$/u;
const fail = (code, detail = '') => { throw new Error('PSC_LIBRARY_' + code + (detail ? ': ' + detail : '')); };
const slash = p => p.split(path.sep).join('/');

export async function nearestProject(directory, io = createSnapshotReader()) {
  const start = path.resolve(directory);
  let here = start;
  for (let i = 0; i < 64; i++) {
    const file = path.join(here, 'package.json');
    const meta = await io.readJson(file, { optional: true, id: 'project-search/' + i, maxBytes: 1024 * 1024 });
    if (meta) return Object.freeze({ root: here, meta, file });
    const parent = path.dirname(here);
    if (parent === here) break;
    here = parent;
  }
  return Object.freeze({ root: start, meta: Object.freeze({}), file: null });
}

export async function findPackage(packageName, directory, io, { optional = false, scope = 'project' } = {}) {
  if (!packagePattern.test(packageName)) fail('PACKAGE_NAME', packageName);
  const start = path.resolve(directory);
  let here = start;
  for (let i = 0; i < 64; i++) {
    const file = path.join(here, 'node_modules', packageName, 'package.json');
    const meta = await io.readJson(file, { optional: true, id: 'npm/' + scope + '/' + packageName + '/' + slash(path.relative(start, file)), maxBytes: 1024 * 1024 });
    if (meta) {
      if (meta.name !== packageName || typeof meta.version !== 'string') fail('PACKAGE_IDENTITY', packageName);
      return Object.freeze({ file, meta, root: path.dirname(file) });
    }
    const parent = path.dirname(here);
    if (parent === here) break;
    here = parent;
  }
  if (optional) return null;
  fail('PACKAGE_NOT_INSTALLED', packageName);
}

function declaredLibraries(project) {
  const cfg = project.meta.proofscript;
  if (cfg === undefined) return [];
  if (!cfg || typeof cfg !== 'object' || Array.isArray(cfg)) fail('PROJECT_POLICY');
  const libs = cfg.libraries;
  if (libs === undefined) return [];
  if (!libs || typeof libs !== 'object' || Array.isArray(libs)) fail('LIBRARIES_SHAPE');
  return Object.entries(libs).map(([namespace, packageName]) => {
    if (!namespacePattern.test(namespace) || namespace === 'Ps' || namespace.startsWith('Ps.')) fail('RESERVED_NAMESPACE', namespace);
    if ((namespace === 'ProofScript' || namespace.startsWith('ProofScript.')) && packageName !== '@proofscript/stdlib') fail('RESERVED_STDLIB', namespace);
    if (typeof packageName !== 'string' || !packagePattern.test(packageName)) fail('PACKAGE_NAME', namespace);
    if (!Object.hasOwn(project.meta.dependencies || {}, packageName) && !Object.hasOwn(project.meta.devDependencies || {}, packageName)) fail('UNDECLARED_DEPENDENCY', packageName);
    return { namespace, packageName };
  }).sort((a, b) => b.namespace.length - a.namespace.length);
}

export async function resolveSourceDescriptor(moduleName, sourceKind, project, io = createSnapshotReader()) {
  if (!namespacePattern.test(moduleName)) fail('MODULE_NAME', String(moduleName));
  if (!['ps', 'lean'].includes(sourceKind)) fail('SOURCE_KIND', String(sourceKind));
  if (moduleName === 'Ps' || moduleName.startsWith('Ps.')) fail('RESERVED_MODULE', moduleName);
  const parts = moduleName.split('.');
  const mapping = declaredLibraries(project).find(m => moduleName === m.namespace || moduleName.startsWith(m.namespace + '.'));
  if (!mapping) {
    if (parts[0] === 'ProofScript') fail('STDLIB_NOT_CONFIGURED', 'install @proofscript/stdlib and register it');
    for (const base of ['src', '.']) {
      const filename = path.join(project.root, base, ...parts) + '.' + sourceKind;
      const text = await io.readText(filename, { optional: true, root: project.root, id: 'local/' + base + '/' + moduleName });
      if (text !== null) return { path: filename, root: project.root };
    }
    fail('MODULE_NOT_FOUND', moduleName);
  }
  const pkg = await findPackage(mapping.packageName, project.root, io);
  const library = pkg.meta.proofscript?.library;
  if (library?.schemaVersion !== 1 || library.modulePrefix !== mapping.namespace || library.sourceRoot !== 'src') fail('PACKAGE_MANIFEST', mapping.packageName);
  const filename = path.join(pkg.root, 'src', ...parts) + '.' + sourceKind;
  if (!contained(await realpath(pkg.root), await realpath(filename))) fail('PACKAGE_SOURCE_ESCAPE', filename);
  return { path: filename, root: pkg.root };
}
export async function resolveSourceModule(moduleName, sourceKind, project, io) {
  return (await resolveSourceDescriptor(moduleName, sourceKind, project, io)).path;
}
