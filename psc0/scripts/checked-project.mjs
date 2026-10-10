import path from 'node:path';
import { createHash } from 'node:crypto';

const hash = text => createHash('sha256').update(text, 'utf8').digest('hex');
const identifier = value => typeof value === 'string' && /^[A-Za-z_$][A-Za-z0-9_$]*$/u.test(value);
const ownKeys = (value, keys) => value !== null && typeof value === 'object' &&
  !Array.isArray(value) && Object.keys(value).length === keys.length &&
  keys.every(key => Object.hasOwn(value, key));
const fail = detail => { throw new Error('PSC0_LIBRARY_INTERFACE: ' + detail); };

export function projectSourceId(projectRoot, file) {
  const name = path.relative(path.resolve(projectRoot), path.resolve(file)).split(path.sep).join('/');
  if (!name || !name.endsWith('.ps') || /[\\:\u0000-\u001f]/u.test(name) ||
      path.posix.isAbsolute(name) || name.split('/').some(part => !part || part === '.' || part === '..' ||
        part === '.psc-output-lock' || /^\.psc-(?:stage|target)-/u.test(part))) {
    fail('source must be a project-relative .ps file: ' + name);
  }
  return name;
}

export function validateProjectExports(value) {
  if (value === undefined) return;
  if (value === null || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).length === 0 || Object.keys(value).length > 128) {
    fail('exports must map 1..128 source paths to public names');
  }
  const folded = new Set();
  for (const [sourceId, names] of Object.entries(value)) {
    if (projectSourceId(path.parse(process.cwd()).root, path.resolve(path.parse(process.cwd()).root, sourceId)) !== sourceId ||
        folded.has(sourceId.toLowerCase())) fail('noncanonical or colliding source path');
    folded.add(sourceId.toLowerCase());
    if (!Array.isArray(names) || names.length === 0 || names.length > 256 ||
        names.some(name => !identifier(name)) || new Set(names).size !== names.length) {
      fail('public names must be distinct supported identifiers: ' + sourceId);
    }
  }
}

// Capture the explicit public selection once; every unit still participates in
// preparation/admission. Dependency modules with no selection remain private.
export function captureProjectUnits(snapshot, projectRoot, exports) {
  validateProjectExports(exports);
  if (exports === undefined || snapshot.kind !== 'ps') fail('library builds require .ps sources and explicit exports');
  const remaining = new Set(Object.keys(exports));
  const units = snapshot.ordered.map(item => {
    const sourceId = projectSourceId(projectRoot, item.path);
    remaining.delete(sourceId);
    return Object.freeze({ sourceId, source: item.source,
      exports: Object.freeze(Object.hasOwn(exports, sourceId) ? [...exports[sourceId]] : []) });
  });
  if (remaining.size) fail('selected source is outside the entry closure: ' + [...remaining].join(', '));
  if (new Set(units.map(unit => unit.sourceId.toLowerCase())).size !== units.length) fail('colliding source identities');
  return Object.freeze(units);
}

export function validateLibraryEmission(encoded, units) {
  if (typeof encoded !== 'string' || Buffer.byteLength(encoded) > 128 * 1024 * 1024) fail('encoded result');
  let value;
  try { value = JSON.parse(encoded); } catch { fail('invalid JSON'); }
  const selected = units.filter(unit => unit.exports.length !== 0);
  if (!ownKeys(value, ['profile', 'bundle', 'modules']) || value.profile !== 'psc-ts-library/1' ||
      typeof value.bundle !== 'string' || !Array.isArray(value.modules) ||
      value.modules.length !== selected.length) fail('result shape');
  const expected = new Map(selected.map(unit => [unit.sourceId, unit]));
  const modules = [];
  const bindings = new Set();
  for (const module of value.modules) {
    if (!ownKeys(module, ['sourceId', 'exports']) || !expected.has(module.sourceId) ||
        !Array.isArray(module.exports)) fail('module identity');
    const unit = expected.get(module.sourceId); expected.delete(module.sourceId);
    const names = new Set(unit.exports);
    if (module.exports.length !== names.size) fail('public export coverage');
    const exports = module.exports.map(item => {
      if (!ownKeys(item, ['name', 'kind', 'binding']) || !names.delete(item.name) ||
          !identifier(item.name) || !identifier(item.binding) || bindings.has(item.binding) ||
          !['type', 'value'].includes(item.kind)) {
        fail('public export descriptor');
      }
      bindings.add(item.binding);
      return Object.freeze({ name: item.name, kind: item.kind, binding: item.binding });
    });
    modules.push(Object.freeze({ sourceId: module.sourceId, exports: Object.freeze(exports) }));
  }
  if (expected.size) fail('incomplete source coverage');
  return Object.freeze({ profile: value.profile, typeScript: value.bundle,
    publicInterfaceSha256: hash(encoded), modules: Object.freeze(modules) });
}

// Facades contain declarations only. All executable wrappers, datatype handles,
// calling support and initialization live once in the checked project bundle.
export function libraryArtifacts({ projectRoot, outputPath, emission }) {
  const root = path.resolve(projectRoot);
  const bundle = projectSourceId(root, outputPath.replace(/\.ts$/u, '.ps')).replace(/\.ps$/u, '.ts');
  if (!outputPath.endsWith('.ts')) fail('bundle output must end in .ts');
  const artifacts = new Map([[bundle, emission.typeScript]]);
  const facadeSources = [];
  const folded = new Set([bundle.toLowerCase()]);
  for (const module of emission.modules) {
    if (module.exports.length === 0) continue;
    const file = module.sourceId.slice(0, -3) + '.ts';
    if (folded.has(file.toLowerCase())) fail('bundle/facade path collision: ' + file);
    folded.add(file.toLowerCase()); facadeSources.push(module.sourceId);
    let specifier = path.posix.relative(path.posix.dirname(file), bundle).replace(/\.ts$/u, '.js');
    if (!specifier.startsWith('.')) specifier = './' + specifier;
    const lines = module.exports.map(item => 'export ' + (item.kind === 'type' ? 'type ' : '') +
      '{ ' + item.binding + ' as ' + item.name + ' } from ' + JSON.stringify(specifier) + ';');
    artifacts.set(file, '// Generated by PSC; owned by the project checked receipt.\n' + lines.join('\n') + '\n');
  }
  if (facadeSources.length === 0) fail('no public facade');
  return Object.freeze({ bundle, artifacts, facadeSources: Object.freeze(facadeSources) });
}
