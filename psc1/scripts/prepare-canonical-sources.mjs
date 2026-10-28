// CI-only checked source promotion. Creates Git objects, never a commit or ref.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { readQualifiedArtifact, sha256 } from './kernel435-qualified-artifact.mjs';
import { readOwnedCompilerSources } from '../host-tools/compiler-source-inputs.mjs';
import { createLosslessSourceTool, createSourceOwnershipTool, createCheckedSourceConverter } from '../host-tools/source-refactoring.mjs';
import { compilerSourceClosureDigest } from '../host-tools/compiler-host-protocol.mjs';
import { uploadPreparedSourceTree } from './prepare-source-git-tree.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
process.chdir(root);
assert.ok(!fs.existsSync('CANONICAL_SOURCES.json'), 'initial migration only; authored ProofScript must never be regenerated from bootstrap references');
const args = process.argv.slice(2);
assert.ok(args.length === 0 || (args.length === 1 && args[0] === '--unified-only'));
const extended = args.length === 0;
const out = path.resolve('dist/canonical-source-preparation');
assert.ok(!fs.existsSync(out), 'fresh preparation output required');
fs.mkdirSync(out, { recursive: true });
process.on('uncaughtExceptionMonitor', error => {
  fs.writeFileSync(path.join(out, 'failure.json'), JSON.stringify({
    schema: 'psc1-canonical-source-preparation-failure/1', status: 'refused',
    testedCommit: process.env.GITHUB_SHA ?? null, runId: process.env.GITHUB_RUN_ID ?? null,
    message: String(error.message), cause: error.cause ?? null,
    stack: String(error.stack ?? '').slice(0, 16384), refsChanged: false,
  }, null, 2) + '\n');
});

const json = value => JSON.stringify(value, null, 2) + '\n';
const put = (file, value) => { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, value); };
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const decode = value => new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(value);
function run(exe, argv, options = {}) {
  const result = spawnSync(exe, argv, { encoding: 'utf8', timeout: 240000, maxBuffer: 64 * 1024 * 1024, ...options });
  assert.equal(result.error, undefined, String(result.error));
  assert.equal(result.status, 0, String(result.stdout) + String(result.stderr));
  return result.stdout;
}
function helpers(base, qualificationGraphProfile) {
  const executable = name => path.join(base, '.lake/build/bin', name);
  const lexical = createLosslessSourceTool({ executable: executable('psc1_lossless_source'), sha256: sha256(fs.readFileSync(executable('psc1_lossless_source'))) });
  const config = { lexicalTool: lexical, executable: executable('psc1_source_ownership'),
    sha256: sha256(fs.readFileSync(executable('psc1_source_ownership'))),
    checkerExecutable: executable('psc1_independent_checker'),
    checkerSha256: sha256(fs.readFileSync(executable('psc1_independent_checker'))) };
  const ownership = createSourceOwnershipTool({ ...config, qualificationGraphProfile });
  const standardOwnership = createSourceOwnershipTool(config);
  return { lexical, ownership, standardOwnership, converter: createCheckedSourceConverter({ ownershipTool: ownership }),
    hashes: { lexical: sha256(fs.readFileSync(executable('psc1_lossless_source'))), ownership: config.sha256, checker: config.checkerSha256 } };
}
const preparedCommit = run('git', ['rev-parse', 'HEAD']).trim();
const baseTree = run('git', ['rev-parse', 'HEAD^{tree}']).trim();
assert.match(preparedCommit, /^[0-9a-f]{40}$/); assert.match(baseTree, /^[0-9a-f]{40}$/);
run('git', ['diff', '--exit-code', '--', 'packages', 'stdlib']);
const pin = { run: 40618697529, job: 122611129273, artifact: 12788978661,
  commit: '5484a04df34de1bbcfa46a248b6a93ce510035d6',
  zipSha256: 'a8b98f259de6d95009bfbbecd5a2fb68091cda5ba632c7a72c74584671a4a2aa' };
const input = await readQualifiedArtifact(pin, path.join(out, 'qualified-input'));
const summary = read(path.join(input, 'summary.json'));
assert.equal(summary.status, 'qualified-linux-independent-compiler-development');
assert.equal(summary.testedCommit, pin.commit);
const archive = path.join(input, 'psc1-independent-linux-x64.tar.gz');
assert.equal(sha256(fs.readFileSync(archive)), 'c227da916348087550f696a1b9f8ad0c6faacaad6bd86d6e72244ed4d96d2fe3');
const names = run('tar', ['tzf', archive]).trim().split('\n');
assert.ok(names.every(name => name.startsWith('toolchain/') && !name.split('/').includes('..')));
const unpacked = path.join(out, 'qualified-toolchain'); fs.mkdirSync(unpacked);
run('tar', ['xzf', archive, '--no-same-owner', '-C', unpacked]);
const sourceManifest = read(path.join(unpacked, 'toolchain/metadata/SOURCE_MANIFEST.json'));
const qualifiedProject = read(path.join(unpacked, 'toolchain/compiler/project.json'));
const unified = readOwnedCompilerSources('Ps.CompilerUnified.Service');
assert.equal(unified.length, 125); assert.equal(qualifiedProject.sources.length, unified.length);
for (let i = 0; i < unified.length; i++) {
  const current = unified[i], recorded = sourceManifest.modules[i];
  assert.equal(current.module, recorded.module);
  assert.equal(current.path, recorded.bootstrapPath);
  assert.equal(sha256(Buffer.from(current.text)), recorded.bootstrapSha256, 'bootstrap source changed since qualified input: ' + current.path);
  assert.equal(qualifiedProject.sources[i].path, current.path.replace(/\.lean$/, '.ps'));
}
const nativeAdapters = new Set(['Binary', 'Component', 'RuntimePlan', 'StringAbi', 'StringComponent'].map(name => 'packages/backend-wasm/src/Ps/BackendWasm/' + name + '.lean'));
const retainedAdapters = new Set(['CanonicalExports', 'CanonicalRequest', 'LiteralEvidence', 'SelfHostAbi', 'Validate'].map(name => 'packages/backend-wasm/src/Ps/BackendWasm/' + name + '.lean'));
const processEntries = new Set(['packages/cli/src/Main.lean', 'packages/backend-python/src/Ps/BackendPython/ProviderMain.lean', 'packages/backend-php/src/Ps/BackendPhp/ProviderMain.lean']);
const classified = new Map();
for (const file of nativeAdapters) classified.set(file, { role: 'native-byte-carrier-adapter', reason: 'Native UInt8 carrier/component boundary; portable Nat-byte encoding and semantics have separate canonical owners.' });
for (const file of retainedAdapters) classified.set(file, { role: 'retained-unselected-adapter', reason: 'Not declared by the current Lake libraries or imported by the qualified unified compiler; retained explicit reference, not promoted source.' });
for (const file of processEntries) classified.set(file, { role: 'native-process-entry', reason: 'Native IO/process entry at the host boundary, outside the self-hosted semantic compiler.' });
for (const backend of ['python', 'php']) {
  const namespace = backend === 'python' ? 'BackendPython' : 'BackendPhp';
  classified.set('packages/backend-' + backend + '/src/Ps/' + namespace + '/Module.lean', {
    role: 'native-compatibility-default-adapter',
    reason: 'Native optional arguments and record defaults only; emitter semantics have one portable implementation.',
    canonicalImplementation: 'packages/backend-' + backend + '/src/Ps/' + namespace + '/Portable.ps',
  });
}
const lake = fs.readFileSync('lakefile.lean', 'utf8'), declared = [];
for (const block of lake.matchAll(/lean_lib\s+(\w+)\s+where\n([\s\S]*?)(?=\n(?:lean_|@)|$)/g)) {
  const directory = block[2].match(/srcDir\s*:=\s*"([^"]+)"/)?.[1];
  if (!directory?.startsWith('packages/') || directory.startsWith('packages/pskernel-')) continue;
  for (const match of block[2].matchAll(/\x60([\w.]+)/g))
    declared.push({ module: match[1], path: directory + '/' + match[1].replaceAll('.', '/') + '.lean' });
}
const ordered = [...unified], seen = new Set(ordered.map(row => row.module));
if (extended) for (const declaration of declared) {
  if (classified.has(declaration.path)) continue;
  for (const row of readOwnedCompilerSources(declaration.module)) {
    assert.ok(!classified.has(row.path), 'portable source crosses classified native boundary: ' + row.path);
    if (!seen.has(row.module)) { seen.add(row.module); ordered.push(row); }
  }
}
assert.equal(ordered.length, extended ? 151 : 125);
const sourceFiles = run('git', ['ls-files', '-z', '--', 'packages']).split('\0')
  .filter(file => /^packages\/[^/]+\/src\/.*\.lean$/.test(file) && !file.startsWith('packages/pskernel-')).sort();
assert.equal(sourceFiles.length, 166);
const selectedPaths = new Set(ordered.map(row => row.path));
const remainder = sourceFiles.filter(file => !selectedPaths.has(file)).map(file => {
  const role = classified.get(file) ?? (!extended ? { role: 'portable-pending', reason: 'Portable module outside this explicitly selected125-module preparation; not yet promoted.' } : null);
  assert.ok(role, 'unclassified compiler source: ' + file);
  const bytes = fs.readFileSync(file);
  return { path: file, ...role, bytes: bytes.length, sha256: sha256(bytes) };
});
assert.equal(remainder.length, extended ? 15 : 41);
const syntheticModule = 'Ps.Canonical.Repository';
const syntheticText = ordered.map(row => 'import ' + row.module).join('\n') + '\n';
const auditRows = [...ordered, { module: syntheticModule, text: syntheticText }];
const parseProbePath = path.join(out, 'parse-probe.json');
const libraryProbeFiles = run('git', ['ls-files', '-z', '--', 'stdlib/ProofScript']).split('\0').filter(file => file.endsWith('.lean')).sort();
console.log(run('lake', ['env', 'lean', '--run', 'scripts/CanonicalSourceProbe.lean', parseProbePath,
  ...ordered.map(row => row.path), ...libraryProbeFiles]));
const parseProbe = read(parseProbePath);
assert.equal(parseProbe.schema, 'psc1-canonical-parse-probe/1');
const parseRefusals = parseProbe.files.filter(row => row.status !== 'accepted-parse-only');
assert.deepEqual(parseRefusals, [], 'all intended portable owners must pass the actual parser before semantic checking');
const tools = helpers(root, 'canonical-repository-40m'), started = Date.now();
console.log('PSC1_CANONICAL_STAGE: capture-and-native-reference-admission');
const qualifiedNames = new Set(unified.map(row => row.module));
const parsedImports = new Map(parseProbe.files.map(row => [row.path, row.imports]));
const dependencies = new Map(ordered.map(row => [row.module, parsedImports.get(row.path)]));
assert.ok([...dependencies.values()].every(Array.isArray), 'every source needs actual parsed imports');
const capturedByModule = new Map(ordered.map(row => [row.module,
  tools.lexical.capture({ module: row.module, grammar: 'lean', bytes: Buffer.from(row.text) })]));
// The new audit profile must not change the ordinary five-argument helper cap.
if (extended) {
  const standardAudit = tools.lexical.capture({module:syntheticModule,grammar:'lean',bytes:Buffer.from(syntheticText)});
  let standardRefusal = null;
  try {
    tools.standardOwnership.analyze({snapshots:[...ordered.map(row=>capturedByModule.get(row.module)),standardAudit],
      entry:syntheticModule,assurance:'ordinary-checked'});
  } catch (error) {
    const diagnostic = String(error.cause?.stderr ?? '');
    const sizes = diagnostic.match(/PSC1_OWNERSHIP_GRAPH_LIMIT:admissions=(\d+):ir=(\d+)/);
    assert.ok(sizes,'Expected measured ordinary graph-capacity refusal: '+diagnostic);
    const admissionsBytes=Number(sizes[1]),originalIrBytes=Number(sizes[2]);
    assert.ok(admissionsBytes>33554432&&admissionsBytes<=41943040);
    assert.ok(originalIrBytes<=41943040);
    standardRefusal={status:'refused-at-unchanged-ordinary-capacity',admissionsBytes,originalIrBytes,
      graphFilesBytesLimit:33554432,metrics:error.cause.metrics};
  }
  assert.ok(standardRefusal,'Ordinary graph capacity must remain bounded at32MiB.');
  put(path.join(out,'standard-capacity-refusal.json'),json(standardRefusal));
  console.log('PSC1_CANONICAL_STANDARD_CAPACITY: '+JSON.stringify(standardRefusal));
}
let remainingRows = [...ordered], checkedAll = null;
const blockers = [];
for (let attempt = 0; attempt <= ordered.length - unified.length; attempt++) {
  console.log('PSC1_CANONICAL_CLOSURE_PROBE: ' + JSON.stringify({ attempt, modules: remainingRows.length }));
  const auditText = remainingRows.map(row => 'import ' + row.module).join('\n') + '\n';
  const auditSnapshot = tools.lexical.capture({ module: syntheticModule, grammar: 'lean', bytes: Buffer.from(auditText) });
  try {
    const index = tools.ownership.analyze({
      snapshots: [...remainingRows.map(row => capturedByModule.get(row.module)), auditSnapshot],
      entry: syntheticModule, assurance: 'ordinary-checked',
    });
    put(path.join(out, 'portable-closure-probe.json'), json({
      status: blockers.length ? 'blocked' : 'passed', blockers,
      checkedModules: remainingRows.map(row => row.module),
      admissionsSha256: index.admissionsSha256, originalIrSha256: index.originalIrSha256,
      checker: index.checker, admissionAuthority: false, diagnosticRemovalIsNotPromotion: true,
    }));
    if (blockers.length === 0) checkedAll = index;
    break;
  } catch (error) {
    const detail = error.cause, failed = detail?.module;
    if (error.message !== 'PSC1_LOSSLESS_OWNERSHIP_REFUSED' || typeof failed !== 'string' ||
        qualifiedNames.has(failed) || !remainingRows.some(row => row.module === failed)) throw error;
    const removed = new Set([failed]);
    for (;;) {
      const size = removed.size;
      for (const row of remainingRows)
        if (dependencies.get(row.module).some(name => removed.has(name))) removed.add(row.module);
      if (removed.size === size) break;
    }
    assert.ok([...removed].every(name => !qualifiedNames.has(name)), 'Diagnostic cannot remove a qualified compiler owner');
    blockers.push({ module: failed, detail, affectedModules: [...removed] });
    console.error('PSC1_CANONICAL_CLOSURE_BLOCKER: ' + JSON.stringify(blockers.at(-1)));
    remainingRows = remainingRows.filter(row => !removed.has(row.module));
    put(path.join(out, 'portable-closure-probe.json'), json({
      status: 'probing', blockers, remainingModules: remainingRows.map(row => row.module),
      admissionAuthority: false, diagnosticRemovalIsNotPromotion: true,
    }));
  }
}
assert.ok(checkedAll && blockers.length === 0, 'Additional portable-owner blockers recorded; no source promotion permitted.');
const before = checkedAll;
const snapshots = [...ordered.map(row => capturedByModule.get(row.module)),
  tools.lexical.capture({ module: syntheticModule, grammar: 'lean', bytes: Buffer.from(syntheticText) })];
console.log('PSC1_CANONICAL_STAGE: checked-proofscript-conversion');
const conversion = tools.converter.convert({ index: before, snapshots, targetGrammar: 'ps', commentPolicy: 'owner-notes' });
const after = tools.converter.candidateIndex(conversion), psSnapshots = tools.converter.candidateSnapshots(conversion);
const psByModule = new Map(auditRows.map(row => [row.module, Buffer.from(tools.converter.readCandidate(conversion, row.module))]));
for (const original of summary.authoritativeSource.files)
  assert.equal(sha256(psByModule.get(original.module)), original.sha256, 'qualified ProofScript bytes changed: ' + original.module);
console.log('PSC1_CANONICAL_STAGE: checked-reverse-lean-projection');
const reverse = tools.converter.convert({ index: after, snapshots: psSnapshots, targetGrammar: 'lean', commentPolicy: 'owner-notes' });
const projectionByModule = new Map(auditRows.map(row => [row.module, Buffer.from(tools.converter.readCandidate(reverse, row.module))]));
assert.equal(after.admissionsSha256, before.admissionsSha256);
assert.equal(after.originalIrSha256, before.originalIrSha256);
assert.equal(reverse.admissionsSha256, before.admissionsSha256);
assert.equal(reverse.originalIrSha256, before.originalIrSha256);

// The standard library is checked as a separate graph from the semantic compiler.
const libraryFiles = run('git', ['ls-files', '-z', '--', 'stdlib/ProofScript']).split('\0').filter(file => file.endsWith('.lean')).sort();
assert.equal(libraryFiles.length, 13);
const libraryByName = new Map(libraryFiles.map(file => {
  const module = file.slice('stdlib/'.length, -'.lean'.length).replaceAll('/', '.');
  return [module, { module, path: file, text: fs.readFileSync(file, 'utf8') }];
}));
const libraryRows = [], librarySeen = new Set(), libraryActive = new Set();
function visitLibrary(module) {
  if (librarySeen.has(module)) return;
  assert.ok(!libraryActive.has(module), 'stdlib source cycle');
  const row = libraryByName.get(module); assert.ok(row, 'stdlib import: ' + module);
  libraryActive.add(module);
  for (const match of row.text.matchAll(/^import\s+(.+)$/gm))
    for (const name of match[1].trim().split(/\s+/)) visitLibrary(name);
  libraryActive.delete(module); librarySeen.add(module); libraryRows.push(row);
}
for (const module of libraryByName.keys()) visitLibrary(module);
const libraryAuditModule = 'ProofScript.Canonical.Library';
const libraryAuditRows = [...libraryRows, { module: libraryAuditModule,
  text: libraryRows.map(row => 'import ' + row.module).join('\n') + '\n' }];
const librarySnapshots = libraryAuditRows.map(row => tools.lexical.capture({ module: row.module, grammar: 'lean', bytes: Buffer.from(row.text) }));
console.log('PSC1_CANONICAL_STAGE: standard-library-correspondence');
const libraryBefore = tools.ownership.analyze({ snapshots: librarySnapshots, entry: libraryAuditModule, assurance: 'ordinary-checked' });
const libraryConversion = tools.converter.convert({ index: libraryBefore, snapshots: librarySnapshots, targetGrammar: 'ps', commentPolicy: 'owner-notes' });
const convertedLibraryIndex = tools.converter.candidateIndex(libraryConversion);
const libraryPsByModule = new Map(libraryAuditRows.map(row => [row.module, Buffer.from(tools.converter.readCandidate(libraryConversion, row.module))]));
const existingIoPath = 'stdlib/ProofScript/System/IO.ps', existingIo = fs.readFileSync(existingIoPath);
libraryPsByModule.set('ProofScript.System.IO', existingIo);
const libraryPsSnapshots = libraryAuditRows.map(row => tools.lexical.capture({
  module: row.module, grammar: 'ps', bytes: libraryPsByModule.get(row.module) }));
const libraryAfter = tools.ownership.analyze({ snapshots: libraryPsSnapshots, entry: libraryAuditModule, assurance: 'ordinary-checked' });
assert.equal(libraryAfter.admissionsSha256, convertedLibraryIndex.admissionsSha256, 'existing IO.ps diverges from its Lean grammar reference');
assert.equal(libraryAfter.originalIrSha256, convertedLibraryIndex.originalIrSha256);
const libraryReverse = tools.converter.convert({ index: libraryAfter, snapshots: libraryPsSnapshots, targetGrammar: 'lean', commentPolicy: 'owner-notes' });
const libraryProjectionByModule = new Map(libraryAuditRows.map(row => [row.module, Buffer.from(tools.converter.readCandidate(libraryReverse, row.module))]));
const libraryCorrespondence = {
  status: 'passed', modules: libraryRows.length,
  bootstrapSourceClosureDigest: libraryBefore.sourceClosureDigest, canonicalSourceClosureDigest: libraryAfter.sourceClosureDigest,
  admissionsSha256: libraryAfter.admissionsSha256, originalIrSha256: libraryAfter.originalIrSha256,
  bootstrapChecker: libraryBefore.checker, canonicalChecker: libraryAfter.checker,
  initialPsVariant: { path: existingIoPath, bytes: existingIo.length, sha256: sha256(existingIo),
    retainedCanonicalBytes: true, sameAdmissionsAndOriginalIr: true },
  commentPolicy: 'existing IO.ps byte-for-byte; newly promoted PS preserves original Lean reference raw comments',
  reverseProjection: { admissionsSha256: libraryReverse.admissionsSha256, originalIrSha256: libraryReverse.originalIrSha256 },
  auditRoot: { module: libraryAuditModule, imports: libraryRows.map(row => row.module), authored: false },
  formalSourcePreservationProof: false,
};
const compositions = ['stdlib/SELFHOST-COLLECTIONS.lean', 'stdlib/SELFHOST-EFFECT.lean', 'stdlib/SELFHOST-JSON.lean'].map(file => {
  const value = fs.readFileSync(file);
  return { path: file, role: 'validation-composition',
    reason: 'Ordinary source fixture/composition for library validation; explicitly outside authored library modules.',
    bytes: value.length, sha256: sha256(value) };
});

// Reverse projection is tested in an isolated copy. Existing repository Lean
// references remain byte-identical even if this optional replacement probe fails.
let nativeProjectionProbe;
try {
  console.log('PSC1_CANONICAL_STAGE: native-projection-build');
  const shadow = path.join(out, 'native-projection'); fs.mkdirSync(shadow);
  const tar = path.join(out, 'native-input.tar');
  run('git', ['-C', path.dirname(root), 'archive', '--format=tar', '--output=' + tar, preparedCommit, 'psc1']);
  run('tar', ['xf', tar, '-C', shadow]);
  const nativeRoot = path.join(shadow, 'psc1');
  for (const row of ordered) put(path.join(nativeRoot, row.path), projectionByModule.get(row.module));
  const build = spawnSync('lake', ['build', 'psc1', 'psc1_unified_service_seed', 'psc1_lossless_source',
    'psc1_source_ownership', 'psc1_independent_checker', 'psc1_modular_pilot', 'psc1_backend_python', 'psc1_backend_php'],
    { cwd: nativeRoot, encoding: 'utf8', timeout: 3600000, maxBuffer: 64 * 1024 * 1024 });
  put(path.join(out, 'native-projection-build.log'), String(build.stdout || '') + String(build.stderr || ''));
  assert.equal(build.error, undefined, String(build.error));
  assert.equal(build.status, 0, 'native projection build failed; see native-projection-build.log');
  console.log('PSC1_CANONICAL_STAGE: projected-native-helper-correspondence');
  const rebuilt = helpers(nativeRoot, 'canonical-repository-40m');
  const recaptured = auditRows.map(row => rebuilt.lexical.capture({ module: row.module, grammar: 'ps', bytes: psByModule.get(row.module) }));
  const checked = rebuilt.ownership.analyze({ snapshots: recaptured, entry: syntheticModule, assurance: 'ordinary-checked' });
  assert.equal(checked.admissionsSha256, after.admissionsSha256);
  assert.equal(checked.originalIrSha256, after.originalIrSha256);
  nativeProjectionProbe = { status: 'passed', nativeBuild: true, independentlyCheckedAfterNativeRebuild: true,
    admissionsSha256: checked.admissionsSha256, originalIrSha256: checked.originalIrSha256,
    helpers: rebuilt.hashes, checker: checked.checker, referenceFilesReplaced: false };
} catch (error) {
  nativeProjectionProbe = { status: 'failed', message: String(error.message), referenceFilesReplaced: false,
    consequence: 'Reverse-rendered Lean is not qualified as a replacement; original immutable checked bootstrap references are retained.' };
  put(path.join(out, 'native-projection-failure.json'), json(nativeProjectionProbe));
  console.error('PSC1_CANONICAL_NATIVE_PROJECTION_PROBE: ' + JSON.stringify(nativeProjectionProbe));
}

const sources = new Map(), owners = [];
for (const row of [...ordered, ...libraryRows]) {
  const isLibrary = row.path.startsWith('stdlib/');
  const value = (isLibrary ? libraryPsByModule : psByModule).get(row.module);
  const file = row.path.replace(/\.lean$/, '.ps');
  const text = decode(value); assert.ok(Buffer.from(text).equals(value));
  if (fs.existsSync(file)) {
    assert.equal(file, 'stdlib/ProofScript/System/IO.ps', 'initial migration refuses to overwrite an existing ProofScript owner: ' + file);
    assert.ok(fs.readFileSync(file).equals(value), 'existing authored IO.ps bytes must remain unchanged');
  }
  sources.set(file, text); put(path.join(out, 'owners', file), value);
  const bootstrapBytes = Buffer.from(row.text);
  const module = (isLibrary ? libraryAfter : after).modules.find(item => item.module === row.module);
  assert.ok(module);
  owners.push({ module: row.module, path: file, authority: 'canonical-editable-proofscript',
    bytes: value.length, sha256: sha256(value), imports: module.imports,
    bootstrap: { path: row.path, authority: 'immutable-checked-bootstrap-reference',
      bytes: bootstrapBytes.length, sha256: sha256(bootstrapBytes),
      generatedProjectionSha256: sha256((isLibrary ? libraryProjectionByModule : projectionByModule).get(row.module)) } });
}
const unifiedPs = unified.map(row => ({ module: row.module, kind: 'ps', text: sources.get(row.path.replace(/\.lean$/, '.ps')) }));
assert.equal(compilerSourceClosureDigest(unifiedPs), summary.authoritativeSource.sourceClosureDigest);
const project = { schemaVersion: 1, entryModule: 'Ps.CompilerUnified.Service',
  sources: unified.map(row => ({ module: row.module, path: row.path.replace(/\.lean$/, '.ps') })) };
const manifest = {
  schema: 'psc1-canonical-source-ownership/1', canonicalLanguage: 'ps', preparedCommit,
  preparedRunId: process.env.GITHUB_RUN_ID ?? null,
  ownerCount: owners.length, compilerOwnerCount: ordered.length, libraryOwnerCount: libraryRows.length,
  bootstrapFileCount: sourceFiles.length + libraryFiles.length + compositions.length,
  canonicalScope: extended ? 'selected portable compiler package modules and ordinary standard library' : 'qualified unified compiler and standard library; additional portable compiler owners pending',
  owners, classifiedRemainder: [...remainder, ...compositions],
  primaryProject: 'compiler.project.json',
  bootstrapPolicy: 'Canonical .ps is the only authored owner. Existing .lean files are immutable checked bootstrap references; updates require checked projection/correspondence, never independent hand edits.',
  independentKernelsExcluded: true,
  separateOwnershipDomains: [
    { path: 'host/', authority: 'native-host-implementation' },
    { path: 'host-tools/', authority: 'host-orchestration-and-policy' },
    { path: 'scripts/', authority: 'bootstrap-validation-and-release-tools' },
    { path: 'test/', authority: 'authored-test-and-reference-oracles' },
    { path: 'legacy/', authority: 'historical-reference-material' },
    { path: 'packages/pskernel-*', authority: 'independent-kernel-projects' }
  ],
  generatedViews: [{ path: 'packages/stdlib/src/ProofScript', from: 'stdlib/ProofScript', authority: 'exact-generated-packaging-view' }],
  sourceOrdering: 'existing unified compiler dependency order, then additional portable dependency closures; standard library is a separately checked graph',
  auditRoot: { module: syntheticModule, imports: ordered.map(row => row.module), sha256: sha256(Buffer.from(syntheticText)), authored: false },
  qualifiedUnified: { input: pin, modules: unified.length, sourceClosureDigest: compilerSourceClosureDigest(unifiedPs), exactQualifiedProofScriptBytesRetained: true },
  correspondence: { status: 'passed', assurance: 'ordinary-checked',
    bootstrapSourceClosureDigest: before.sourceClosureDigest, canonicalSourceClosureDigest: after.sourceClosureDigest,
    admissionsSha256: after.admissionsSha256, originalIrSha256: after.originalIrSha256,
    sourceCoreDeclarations: after.sourceCoreDeclarations,
    partialNamesPreserved: true, importsAndMemberOwnershipPreserved: true, rawCommentsPreserved: true,
    bootstrapChecker: before.checker, canonicalChecker: after.checker, helperHashes: tools.hashes,
    reverseProjection: { admissionsSha256: reverse.admissionsSha256, originalIrSha256: reverse.originalIrSha256 },
    nativeProjectionProbe, elapsedMs: Date.now() - started,
    formalSourcePreservationProof: false, receiptGrantsAdmissionAuthority: false },
  libraryCorrespondence,
};
sources.set('compiler.project.json', json(project));
sources.set('CANONICAL_SOURCES.json', json(manifest));
sources.set('bootstrap/CANONICAL_REFERENCES.md', [
  '# Canonical ProofScript and bootstrap references', '',
  'The authored semantic compiler and ordinary standard-library sources are the .ps owners listed in ../CANONICAL_SOURCES.json.',
  'The unified compiler project is ../compiler.project.json. Ordinary standalone development reads those ProofScript bytes directly.',
  'The paired .lean files remain at their existing module paths solely as immutable, hash-pinned bootstrap references.',
  'Do not edit a paired Lean file independently. Edit the ProofScript owner and regenerate the checked reference/projection evidence.',
  'A reference pair is qualified by actual independent admission of both grammar endpoints and byte-equal canonical admissions and original strict IR.',
  'The manifest explicitly classifies native process entries, native byte-carrier adapters, retained unselected adapters and library validation compositions.',
  'The existing standard-library IO.ps retains its exact authored bytes after fresh semantic correspondence checking.',
  'Independent kernel projects, host-only implementation sources, tests and historical material retain their explicitly separate ownership.',
  'The reverse-rendered Lean/native-build probe is reported separately. Existing reference bytes are not replaced by this promotion.', '',
].join('\n'));
put(path.join(out, 'CANONICAL_SOURCES.json'), json(manifest));
put(path.join(out, 'compiler.project.json'), json(project));
put(path.join(out, 'conversion-evidence.json'), json({
  forward: conversion, reverse, libraryConversion, libraryReverse, nativeProjectionProbe }));
run('git', ['diff', '--exit-code', '--', 'packages', 'stdlib']);
assert.equal(run('git', ['rev-parse', 'HEAD']).trim(), preparedCommit);

function preparePackageMetadata() {
  const tracked = run('git', ['ls-files', '-z', '--', 'packages', 'stdlib']).split('\0').filter(Boolean);
  const ownerPaths = new Set(owners.map(row => row.path));
  for (const dir of fs.readdirSync('packages').sort()) {
    if (dir.startsWith('pskernel-')) continue;
    const file = 'packages/' + dir + '/package.json';
    if (!fs.existsSync(file)) continue;
    const meta = read(file);
    assert.ok(meta.proofscript && typeof meta.proofscript === 'object');
    const hasPs = dir === 'stdlib' || owners.some(row => row.path.startsWith('packages/' + dir + '/src/'));
    const sourceRoot = 'packages/' + dir + '/src';
    const nativeFiles = fs.existsSync(sourceRoot) ? tracked.filter(p => p.startsWith(sourceRoot + '/') && p.endsWith('.lean')) : [];
    const hasNative = nativeFiles.length > 0;
    Object.assign(meta.proofscript, {
      canonicalSources: hasPs ? 'src/**/*.ps' : hasNative ? 'src/**/*.lean' : null,
      canonicalGrammar: hasPs ? 'ps' : hasNative ? 'lean' : null,
      sourceVariants: hasPs ? ['ps', 'lean'] : hasNative ? ['lean'] : [],
      sourceOwnership: {
        role: hasPs ? 'canonical-editable-proofscript' : hasNative ? 'native-adapter-source' : 'source-free-package',
        manifest: 'dist/source-manifest.json', repositoryManifest: 'psc1/CANONICAL_SOURCES.json',
        ...(dir === 'stdlib' ? { generatedFrom: 'psc1/stdlib/ProofScript' } : {})
      },
      bootstrapReferences: hasPs ? { grammar: 'lean', role: 'immutable-checked-bootstrap-reference', manifest: 'dist/source-manifest.json' } : null
    });
    sources.set(file, json(meta));
    const readme = 'packages/' + dir + '/README.md';
    if (fs.existsSync(readme)) {
      const before = fs.readFileSync(readme, 'utf8');
      const after = before.replace(/\]\(([^)]+\.lean)\)/g, (all, target) => {
        const owned = path.posix.normalize(path.posix.join(path.posix.dirname(readme), target)).replace(/\.lean$/, '.ps');
        return ownerPaths.has(owned) ? '](' + target.replace(/\.lean$/, '.ps') + ')' : all;
      });
      if (after !== before) sources.set(readme, after);
    }
  }
}
preparePackageMetadata();

const entries = [...sources].map(([file, content]) => {
  const value = Buffer.from(content), header = Buffer.from('blob ' + value.length + '\0');
  return { path: 'psc1/' + file, mode: '100644', type: 'blob',
    sha: crypto.createHash('sha1').update(header).update(value).digest('hex'),
    bytes: value.length, sha256: sha256(value), content };
});
const result = { schema: 'psc1-canonical-source-preparation/1', status: 'prepared-checked-canonical-owners',
  preparedCommit, baseTree, treeSha: null, canonicalOwners: owners.length,
  compilerOwners: ordered.length, libraryOwners: libraryRows.length,
  classifiedRemainder: remainder.length + compositions.length,
  unifiedModules: unified.length, sourceClosureDigest: compilerSourceClosureDigest(unifiedPs),
  admissionsSha256: after.admissionsSha256, originalIrSha256: after.originalIrSha256,
  libraryCorrespondence, nativeProjectionProbe, commitsCreated: false, refsChanged: false,
  objectUploadStatus: process.env.PSC1_CREATE_SOURCE_TREE === '1' ? 'pending' : 'not-requested',
  entries: entries.map(({ content, ...entry }) => entry) };
const preparedFilesText = json({ schema: 'psc1-canonical-prepared-files/1',
  preparedCommit, baseTree, preparedRunId: process.env.GITHUB_RUN_ID ?? null,
  contentEncoding: 'utf8', commitsCreated: false, refsChanged: false, entries });
put(path.join(out, 'prepared-files.json'), preparedFilesText);
result.preparedFiles = { path: 'prepared-files.json', bytes: Buffer.byteLength(preparedFilesText),
  sha256: sha256(Buffer.from(preparedFilesText)) };
put(path.join(out, 'preparation.json'), json(result));
console.log('PSC1_CANONICAL_CHECKS_PREPARED: ' + JSON.stringify({
  preparedCommit, canonicalOwners: owners.length, entries: entries.length,
  preparedFiles: result.preparedFiles, admissionsSha256: after.admissionsSha256,
  originalIrSha256: after.originalIrSha256, nativeProjectionProbe, commitsCreated: false, refsChanged: false }));
try {
  const uploaded = await uploadPreparedSourceTree({entries,baseTree,preparedCommit,out});
  result.treeSha = uploaded.treeSha; result.objectUploadStatus = uploaded.upload.status;
} catch (error) {
  result.objectUploadStatus = 'failed';
  result.objectUploadFailure = {message:String(error.message),code:String(error.cause?.code??error.code??error.name)};
  put(path.join(out, 'preparation.json'), json(result)); throw error;
}
put(path.join(out, 'preparation.json'), json(result));
console.log('PSC1_CANONICAL_PREPARATION: ' + JSON.stringify(result));
