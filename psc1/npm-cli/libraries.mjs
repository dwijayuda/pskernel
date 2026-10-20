// npm filesystem/metadata transport only. Source parsing, declaration closure,
// independent admission and target planning remain in the native Lean compiler.
import { createRequire } from 'node:module';
import { readFile, realpath } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ownFile = fileURLToPath(import.meta.url);
const pin = JSON.parse(await readFile(new URL('../NATIVE_SOURCE_PIN.json', import.meta.url), 'utf8'));
const modulePattern = /^[A-Za-z_][A-Za-z_0-9]*(?:\.[A-Za-z_][A-Za-z_0-9]*)*$/u;
const packagePattern = /^(?:@[a-z0-9._-]+\/)?[a-z0-9][a-z0-9._-]*$/u;
const fail = (code, detail = '') => { throw Error('PSC1_LIBRARY_' + code + (detail ? ': ' + detail : '')); };
const within = (prefix, name) => name === prefix || name.startsWith(prefix + '.');
const reserved = name => within('Ps', name) || within('ProofScript', name);
const object = x => x !== null && typeof x === 'object' && !Array.isArray(x);
function inside(root, filename) {
  const rel = path.relative(root, filename);
  return rel !== '' && rel !== '..' && !rel.startsWith('..' + path.sep) && !path.isAbsolute(rel);
}
async function json(file) {
  const bytes = await readFile(file);
  if (bytes.length > 1024 * 1024) fail('METADATA_LIMIT', file);
  let value;
  try { value = JSON.parse(bytes.toString('utf8')); } catch { fail('METADATA_JSON', file); }
  if (!object(value)) fail('METADATA_SHAPE', file);
  return value;
}
export async function nearestProject(directory) {
  let root = path.resolve(directory);
  for (let i = 0; i < 64; i++) {
    const file = path.join(root, 'package.json');
    if (existsSync(file)) return { root: await realpath(root), file, meta: await json(file) };
    const parent = path.dirname(root);
    if (parent === root) break;
    root = parent;
  }
  return { root: path.resolve(directory), file: null, meta: {} };
}
function mappings(project) {
  const cfg = project.meta.proofscript;
  if (cfg === undefined) return [];
  if (!object(cfg)) fail('PROJECT_POLICY');
  if (cfg.libraries === undefined) return [];
  if (!object(cfg.libraries)) fail('LIBRARIES_SHAPE');
  const result = [];
  for (const [prefix, name] of Object.entries(cfg.libraries)) {
    if (!modulePattern.test(prefix) || reserved(prefix)) fail('RESERVED_NAMESPACE', prefix);
    if (typeof name !== 'string' || !packagePattern.test(name)) fail('PACKAGE_NAME', prefix);
    const allowed = Object.hasOwn(project.meta.dependencies || {}, name) ||
      (!cfg.library && Object.hasOwn(project.meta.devDependencies || {}, name));
    if (!allowed) fail('UNDECLARED_DEPENDENCY', name);
    if (result.some(other => within(other.prefix, prefix) || within(prefix, other.prefix))) {
      fail('OVERLAPPING_NAMESPACE', prefix);
    }
    result.push({ prefix, name });
  }
  return result.sort((a, b) => a.prefix.localeCompare(b.prefix, 'en'));
}
function contract(project, expectedPrefix) {
  const lib = project.meta.proofscript?.library;
  if (!object(lib) || lib.schemaVersion !== 2 || lib.kind !== 'portable-source' ||
      lib.sourceRoot !== 'src' || !['ps', 'lean'].includes(lib.sourceKind) ||
      !modulePattern.test(lib.modulePrefix || '') || reserved(lib.modulePrefix) ||
      (expectedPrefix && lib.modulePrefix !== expectedPrefix)) fail('PACKAGE_MANIFEST', project.meta.name || '');
  if (lib.compilerProfile !== pin.compilerProfile || lib.leanVersion !== pin.version ||
      lib.leanCommit !== pin.commit) fail('PROFILE_MISMATCH', project.meta.name || '');
  if (!Array.isArray(lib.publicModules) || lib.publicModules.length === 0 ||
      lib.publicModules.some(name => typeof name !== 'string' || !modulePattern.test(name) ||
        !within(lib.modulePrefix, name)) || new Set(lib.publicModules).size !== lib.publicModules.length) {
    fail('PUBLIC_MODULES', project.meta.name || '');
  }
  // A source package cannot confer new logical or host authority.
  for (const key of ['axioms', 'plugins', 'kernel', 'trust', 'ffi', 'runtimeAdapter']) {
    if (Object.hasOwn(lib, key)) fail('UNSUPPORTED_AUTHORITY', key);
  }
  return lib;
}
async function sourceIn(project, moduleName, lib, external) {
  if (external && !lib.publicModules.includes(moduleName)) fail('PRIVATE_MODULE', moduleName);
  const candidate = path.join(project.root, 'src', ...moduleName.split('.')) + '.' + lib.sourceKind;
  if (!existsSync(candidate)) fail('SOURCE_MISSING', moduleName);
  const resolved = await realpath(candidate);
  if (!inside(project.root, resolved)) fail('SOURCE_ESCAPE', moduleName);
  if (/[\r\n\0]/u.test(resolved)) fail('PATH_CONTROL');
  return resolved;
}
async function installedLibrary(project, mapping) {
  if (!project.file) fail('PROJECT_MANIFEST_MISSING');
  const req = createRequire(project.file);
  let file;
  try { file = req.resolve(mapping.name + '/package.json'); } catch { fail('PACKAGE_NOT_INSTALLED', mapping.name); }
  const root = await realpath(path.dirname(file));
  const meta = await json(file);
  if (meta.name !== mapping.name) fail('PACKAGE_IDENTITY', mapping.name);
  const loaded = { root, file, meta };
  const lib = contract(loaded, mapping.prefix);
  return { loaded, lib };
}
export async function resolveImportedSource(moduleName, entryDirectory, importerPath) {
  if (typeof moduleName !== 'string' || !moduleName || /[\r\n\0/\\]/u.test(moduleName) ||
      moduleName.split('.').some(part => !part)) fail('MODULE_NAME', String(moduleName));
  const project = await nearestProject(path.dirname(path.resolve(importerPath)));
  const own = project.meta.proofscript?.library;
  // Compiler development retains native module resolution. A portable package
  // cannot acquire compiler-owned source authority through that fallback.
  if (reserved(moduleName)) {
    if (own !== undefined) fail('RESERVED_MODULE', moduleName);
    return null;
  }
  if (!modulePattern.test(moduleName)) {
    if (own !== undefined) fail('MODULE_NAME', moduleName);
    return null;
  }
  if (own !== undefined) {
    const lib = contract(project);
    if (within(lib.modulePrefix, moduleName)) return sourceIn(project, moduleName, lib, false);
  }
  const mapping = mappings(project).find(x => within(x.prefix, moduleName));
  if (mapping) {
    const { loaded, lib } = await installedLibrary(project, mapping);
    return sourceIn(loaded, moduleName, lib, true);
  }
  if (own !== undefined) fail('UNDECLARED_IMPORT', moduleName);
  // Ordinary project source is still source, with exactly-one-variant selection.
  const rootProject = await nearestProject(entryDirectory);
  const bases = [...new Set([path.resolve(entryDirectory), path.join(rootProject.root, 'src'), rootProject.root])];
  for (const base of bases) {
    const stem = path.join(base, ...moduleName.split('.'));
    const found = ['.lean', '.ps'].map(ext => stem + ext).filter(existsSync);
    if (found.length > 1) fail('SOURCE_AMBIGUITY', moduleName);
    if (found.length === 1) {
      const resolved = await realpath(found[0]);
      if (!inside(rootProject.root, resolved)) fail('SOURCE_ESCAPE', moduleName);
      if (/[\r\n\0]/u.test(resolved)) fail('PATH_CONTROL');
      return resolved;
    }
  }
  return null;
}
if (process.argv[1] && path.resolve(process.argv[1]) === ownFile) {
  try {
    const [command, moduleName, root, importer, ...extra] = process.argv.slice(2);
    if (command !== 'resolve' || !moduleName || !root || !importer || extra.length) fail('USAGE');
    const resolved = await resolveImportedSource(moduleName, root, importer);
    if (resolved !== null) process.stdout.write('PSC1_LIBRARY_PATH_V2\n' + resolved + '\n');
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
