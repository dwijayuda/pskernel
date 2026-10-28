// Source ownership/data integrity only. No manifest grants admission authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const schema = 'psc1-canonical-source-ownership/1';
const ownerRole = 'canonical-editable-proofscript';
const referenceRole = 'immutable-checked-bootstrap-reference';
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const decode = bytes => new TextDecoder('utf-8', {fatal:true, ignoreBOM:true}).decode(bytes);
const remainderRoles = new Set(['native-byte-carrier-adapter', 'retained-unselected-adapter',
  'native-process-entry', 'native-compatibility-default-adapter', 'validation-composition', 'portable-pending']);
const compositions = new Set(['stdlib/SELFHOST-COLLECTIONS.lean', 'stdlib/SELFHOST-EFFECT.lean', 'stdlib/SELFHOST-JSON.lean']);
const view = {path:'packages/stdlib/src/ProofScript', from:'stdlib/ProofScript', authority:'exact-generated-packaging-view'};
function relativePath(value) {
  assert.equal(typeof value, 'string', 'PSC1_CANONICAL_PATH');
  assert.ok(value.length > 0 && value.length < 4096 && !value.includes('\\') && !value.includes('\0'), 'PSC1_CANONICAL_PATH');
  assert.ok(!path.posix.isAbsolute(value) && !value.split('/').some(p => !p || p === '.' || p === '..'), 'PSC1_CANONICAL_PATH');
  return value;
}
function sourcePath(value, extension) {
  relativePath(value);
  assert.ok(value.endsWith(extension), 'PSC1_CANONICAL_EXTENSION: ' + value);
  assert.ok((/^packages\/[^/]+\/src\/.+\.(lean|ps)$/.test(value) && !value.startsWith('packages/pskernel-')) ||
    /^stdlib\/ProofScript\/.+\.(lean|ps)$/.test(value) || compositions.has(value), 'PSC1_CANONICAL_SOURCE_PATH: ' + value);
  return value;
}
function sourceModule(file) {
  const tail = file.startsWith('stdlib/ProofScript/') ? file.slice('stdlib/'.length) : file.match(/^packages\/[^/]+\/src\/(.+)$/)?.[1];
  assert.ok(tail, 'PSC1_CANONICAL_MODULE_PATH: ' + file);
  return tail.replace(/\.(ps|lean)$/, '').replaceAll('/', '.');
}
function regularBytes(root, relative) {
  relativePath(relative);
  let current = root;
  const parts = relative.split('/');
  for (let i = 0; i < parts.length; i++) {
    current = path.join(current, parts[i]);
    const stat = fs.lstatSync(current);
    assert.ok(!stat.isSymbolicLink(), 'PSC1_CANONICAL_SYMLINK: ' + relative);
    assert.ok(i === parts.length - 1 ? stat.isFile() : stat.isDirectory(), 'PSC1_CANONICAL_FILE: ' + relative);
    if (i === parts.length - 1) assert.ok(stat.size <= 128 * 1024 * 1024, 'PSC1_CANONICAL_LIMIT: ' + relative);
  }
  return fs.readFileSync(current);
}
function verifyPin(root, pin, extension, permitEditedOwner = false) {
  sourcePath(pin.path, extension);
  assert.ok(Number.isSafeInteger(pin.bytes) && pin.bytes >= 0 && pin.bytes <= 128 * 1024 * 1024, 'PSC1_CANONICAL_PIN_SIZE');
  assert.match(pin.sha256, /^[0-9a-f]{64}$/, 'PSC1_CANONICAL_PIN_HASH');
  const bytes = regularBytes(root, pin.path);
  decode(bytes);
  if (!permitEditedOwner) {
    assert.equal(bytes.length, pin.bytes, 'PSC1_CANONICAL_SIZE: ' + pin.path);
    assert.equal(digest(bytes), pin.sha256, 'PSC1_CANONICAL_IDENTITY: ' + pin.path);
  }
  return bytes;
}
function walk(root, relative, {sourceOnly = true, skipGenerated = false} = {}) {
  const absolute = path.join(root, relative);
  if (!fs.existsSync(absolute)) return [];
  assert.ok(!fs.lstatSync(absolute).isSymbolicLink(), 'PSC1_CANONICAL_SYMLINK: ' + relative);
  assert.ok(fs.statSync(absolute).isDirectory(), 'PSC1_CANONICAL_DIRECTORY: ' + relative);
  return fs.readdirSync(absolute).sort().flatMap(name => {
    const file = relative + '/' + name;
    if (skipGenerated && file === view.path) return [];
    const stat = fs.lstatSync(path.join(root, file));
    assert.ok(!stat.isSymbolicLink(), 'PSC1_CANONICAL_SYMLINK: ' + file);
    if (stat.isDirectory()) return walk(root, file, {sourceOnly, skipGenerated});
    assert.ok(stat.isFile(), 'PSC1_CANONICAL_FILE: ' + file);
    return !sourceOnly || /\.(lean|ps)$/.test(file) ? [file] : [];
  });
}
function sourceInventory(root) {
  const files = [];
  for (const dir of fs.readdirSync(path.join(root, 'packages')).sort()) {
    if (dir.startsWith('pskernel-')) continue;
    const parent = path.join(root, 'packages', dir), stat = fs.lstatSync(parent);
    assert.ok(!stat.isSymbolicLink(), 'PSC1_CANONICAL_SYMLINK: packages/' + dir);
    if (stat.isDirectory()) files.push(...walk(root, 'packages/' + dir + '/src', {skipGenerated:true}));
  }
  files.push(...walk(root, 'stdlib'));
  return files.sort();
}
function verifyGeneratedView(root, manifest, permitEditedOwner) {
  assert.deepEqual(manifest.generatedViews, [view], 'PSC1_CANONICAL_GENERATED_VIEW_MAP');
  if (!fs.existsSync(path.join(root, view.path))) return;
  // A refresh candidate may have stale generated copies. They are never used as input.
  if (permitEditedOwner) return;
  const expected = walk(root, view.from, {sourceOnly:false}).map(p => p.slice(view.from.length + 1));
  const actual = walk(root, view.path, {sourceOnly:false}).map(p => p.slice(view.path.length + 1));
  assert.deepEqual(actual, expected, 'PSC1_CANONICAL_GENERATED_VIEW_INVENTORY');
  for (const suffix of expected)
    assert.ok(regularBytes(root, view.path + '/' + suffix).equals(regularBytes(root, view.from + '/' + suffix)),
      'PSC1_CANONICAL_GENERATED_VIEW_IDENTITY: ' + suffix);
}
function verifyAuditRoot(audit, rows) {
  assert.ok(audit && typeof audit.module === 'string' && audit.authored === false, 'PSC1_CANONICAL_AUDIT_ROOT');
  assert.deepEqual(audit.imports, rows.map(row => row.module), 'PSC1_CANONICAL_AUDIT_IMPORTS');
  const bytes = Buffer.from(audit.imports.map(module => 'import ' + module).join('\n') + '\n');
  if (audit.sha256 !== undefined) assert.equal(digest(bytes), audit.sha256, 'PSC1_CANONICAL_AUDIT_IDENTITY');
}
function loadOwnership(root, permitEditedOwner) {
  root = path.resolve(root);
  const manifest = JSON.parse(decode(regularBytes(root, 'CANONICAL_SOURCES.json')));
  assert.equal(manifest.schema, schema);
  assert.equal(manifest.canonicalLanguage, 'ps');
  assert.equal(manifest.correspondence?.status, 'passed');
  assert.equal(manifest.libraryCorrespondence?.status, 'passed');
  assert.ok(Array.isArray(manifest.owners) && manifest.owners.length > 0);
  assert.ok(Array.isArray(manifest.classifiedRemainder));
  const modules = new Map(), paths = new Set(), references = new Map();
  const remember = file => { assert.ok(!paths.has(file), 'PSC1_CANONICAL_DUPLICATE_PATH: ' + file); paths.add(file); };
  for (const row of manifest.owners) {
    assert.equal(row.authority, ownerRole);
    assert.equal(row.module, sourceModule(row.path));
    assert.ok(!modules.has(row.module), 'PSC1_CANONICAL_DUPLICATE_MODULE: ' + row.module);
    assert.equal(row.bootstrap?.authority, referenceRole);
    assert.equal(row.bootstrap.path, row.path.replace(/\.ps$/, '.lean'));
    assert.match(row.bootstrap.generatedProjectionSha256, /^[0-9a-f]{64}$/);
    const ps = verifyPin(root, row, '.ps', permitEditedOwner);
    const lean = verifyPin(root, row.bootstrap, '.lean');
    remember(row.path); remember(row.bootstrap.path);
    assert.ok(Array.isArray(row.imports) && row.imports.every(name => typeof name === 'string' && name.length > 0));
    const value = {...row, ps, lean, changed: ps.length !== row.bytes || digest(ps) !== row.sha256};
    modules.set(row.module, value); references.set(row.bootstrap.path, value);
  }
  for (const row of manifest.classifiedRemainder) {
    assert.ok(remainderRoles.has(row.role), 'PSC1_CANONICAL_REMAINDER_ROLE: ' + row.path);
    assert.ok(typeof row.reason === 'string' && row.reason.length > 0);
    if (row.role === 'validation-composition') assert.ok(compositions.has(row.path));
    if (row.role === 'native-compatibility-default-adapter') {
      sourcePath(row.canonicalImplementation, '.ps');
      assert.ok([...modules.values()].some(owner => owner.path === row.canonicalImplementation),
        'PSC1_CANONICAL_ADAPTER_IMPLEMENTATION: ' + row.path);
    }
    verifyPin(root, row, '.lean'); remember(row.path);
  }
  for (const row of modules.values()) for (const name of row.imports)
    assert.ok(modules.has(name), 'PSC1_CANONICAL_IMPORT_OWNER: ' + row.module + ' -> ' + name);
  const compiler = manifest.owners.filter(row => row.path.startsWith('packages/'));
  const library = manifest.owners.filter(row => row.path.startsWith('stdlib/ProofScript/'));
  assert.equal(manifest.ownerCount, modules.size);
  assert.equal(manifest.compilerOwnerCount, compiler.length);
  assert.equal(manifest.libraryOwnerCount, library.length);
  assert.equal(manifest.ownerCount, compiler.length + library.length);
  assert.equal(manifest.bootstrapFileCount, modules.size + manifest.classifiedRemainder.length);
  verifyAuditRoot(manifest.auditRoot, compiler);
  verifyAuditRoot(manifest.libraryCorrespondence.auditRoot, library);
  assert.deepEqual(sourceInventory(root), [...paths].sort(), 'PSC1_CANONICAL_UNCLASSIFIED_SOURCE');
  verifyGeneratedView(root, manifest, permitEditedOwner);
  verifyPackageSourceMetadata({root, manifest, modules});
  return {root, manifest, modules, references, candidateOnly:permitEditedOwner, admissionAuthority:false};
}
export function readCanonicalOwnership(root = process.cwd()) {
  return loadOwnership(root, false);
}
export function readCanonicalEditCandidate(root = process.cwd()) {
  // References and classifications remain pinned; only authored PS bytes may differ.
  // A caller must freshly check this candidate before writing any reference/receipt.
  return loadOwnership(root, true);
}
export function readCanonicalCompilerSources(entry, {root = process.cwd(), grammar = 'ps'} = {}) {
  assert.ok(grammar === 'ps' || grammar === 'lean-bootstrap', 'PSC1_CANONICAL_GRAMMAR');
  const ownership = readCanonicalOwnership(root), active = new Set(), visited = new Set(), result = [];
  function visit(module) {
    if (visited.has(module)) return;
    assert.ok(!active.has(module), 'PSC1_CANONICAL_IMPORT_CYCLE: ' + module);
    const row = ownership.modules.get(module);
    assert.ok(row, 'PSC1_CANONICAL_MODULE: ' + module);
    active.add(module); row.imports.forEach(visit); active.delete(module); visited.add(module);
    const isPs = grammar === 'ps';
    result.push({module, path:isPs ? row.path : row.bootstrap.path, kind:isPs ? 'ps' : 'lean',
      text:decode(isPs ? row.ps : row.lean), authority:isPs ? ownerRole : referenceRole,
      canonicalPath:row.path, canonicalSha256:row.sha256});
  }
  visit(entry); return result;
}

export function verifyPackageSourceMetadata({root, manifest, modules}) {
  const referencePaths = [...manifest.owners.map(row => row.bootstrap.path), ...manifest.classifiedRemainder.map(row => row.path)];
  for (const dir of fs.readdirSync(path.join(root, 'packages')).sort()) {
    if (dir.startsWith('pskernel-')) continue;
    const relative = 'packages/' + dir + '/package.json';
    if (!fs.existsSync(path.join(root, relative))) continue;
    const meta = JSON.parse(decode(regularBytes(root, relative))).proofscript;
    assert.ok(meta && typeof meta === 'object', 'PSC1_CANONICAL_PACKAGE_METADATA: ' + dir);
    const prefix = 'packages/' + dir + '/src/';
    const hasPs = dir === 'stdlib' || [...modules.values()].some(row => row.path.startsWith(prefix));
    const hasNative = referencePaths.some(file => file.startsWith(prefix));
    const grammar = hasPs ? 'ps' : hasNative ? 'lean' : null;
    assert.equal(meta.canonicalGrammar, grammar, 'PSC1_CANONICAL_PACKAGE_GRAMMAR: ' + dir);
    assert.equal(meta.canonicalSources, hasPs ? 'src/**/*.ps' : hasNative ? 'src/**/*.lean' : null);
    assert.deepEqual(meta.sourceVariants, hasPs ? ['ps', 'lean'] : hasNative ? ['lean'] : []);
    assert.equal(meta.sourceOwnership?.role, hasPs ? 'canonical-editable-proofscript' : hasNative ? 'native-adapter-source' : 'source-free-package');
    assert.equal(meta.sourceOwnership?.manifest, 'dist/source-manifest.json');
    assert.equal(meta.sourceOwnership?.repositoryManifest, 'psc1/CANONICAL_SOURCES.json');
    if (dir === 'stdlib') assert.equal(meta.sourceOwnership.generatedFrom, 'psc1/stdlib/ProofScript');
    if (hasPs) {
      assert.equal(meta.bootstrapReferences?.grammar, 'lean');
      assert.equal(meta.bootstrapReferences?.role, 'immutable-checked-bootstrap-reference');
      assert.equal(meta.bootstrapReferences?.manifest, 'dist/source-manifest.json');
    } else assert.equal(meta.bootstrapReferences, null);
  }
}
export function verifyTrackedSourceDomains(trackedPaths, {root = process.cwd(), ownership = null} = {}) {
  const checked = ownership ?? readCanonicalOwnership(root);
  assert.equal(checked.candidateOnly, false, 'PSC1_CANONICAL_CANDIDATE_NOT_QUALIFIED');
  root = checked.root;
  assert.ok(Array.isArray(trackedPaths) && trackedPaths.every(p => typeof p === 'string'));
  const sourcePaths = trackedPaths.filter(p => /\.(lean|ps)$/.test(p)).map(relativePath).sort();
  assert.equal(new Set(sourcePaths).size, sourcePaths.length, 'PSC1_CANONICAL_TRACKED_DUPLICATE');
  const explicit = new Map();
  for (const row of checked.manifest.owners) {
    explicit.set(row.path, ownerRole); explicit.set(row.bootstrap.path, referenceRole);
  }
  for (const row of checked.manifest.classifiedRemainder) explicit.set(row.path, row.role);
  const retained = file => {
    if (file.startsWith('host/src/')) return 'native-host-implementation';
    if (file.startsWith('scripts/')) return 'bootstrap-validation-and-release-tools';
    if (file.startsWith('standalone/')) return 'native-bootstrap-qualification-observers';
    if (file.startsWith('test/')) return 'authored-test-and-reference-oracles';
    if (file.startsWith('legacy/')) return 'historical-reference-material';
    if (/^packages\/pskernel-(?:core|lean|lean-wasm)\//.test(file)) return 'independent-kernel-projects';
    if (['lakefile.lean', 'kernel-lakefile.lean', 'lean-checked/lakefile.lean'].includes(file)) return 'native-build-configuration';
    return null;
  };
  const rows = sourcePaths.map(file => {
    const role = explicit.get(file) ?? retained(file);
    assert.ok(role, 'PSC1_CANONICAL_UNCLASSIFIED_TRACKED_SOURCE: ' + file);
    const bytes = regularBytes(root, file);
    return {path:file, role, bytes:bytes.length, sha256:digest(bytes)};
  });
  const trackedSet = new Set(sourcePaths);
  for (const file of explicit.keys()) assert.ok(trackedSet.has(file), 'PSC1_CANONICAL_UNTRACKED_OWNER_OR_REFERENCE: ' + file);
  const counts = {};
  for (const row of rows) counts[row.role] = (counts[row.role] ?? 0) + 1;
  return {schema:'psc1-repository-source-domain-inventory/1', scope:'psc1 workspace', status:'passed',
    sourceFiles:rows.length, counts, files:rows, admissionAuthority:false};
}
