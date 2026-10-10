import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { mkdtemp, mkdir, writeFile, readFile, rm, symlink } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { createSnapshotReader } from '../npm-cli/snapshot.mjs';
import { captureSourceGraph } from '../npm-cli/source-graph.mjs';
import { declaredLibraries } from '../npm-cli/libraries.mjs';
import { describeSourceLibrary, createLibraryDisclosure, libraryDisclosureNotice } from '../npm-cli/library-disclosure.mjs';
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const compiler = { psProofScriptGrammarEdition: 'ps-0.9-r3', psProofScriptGrammarMode: 'new-only' };
const mapping = { namespace: 'Demo', packageName: '@fixture/math' };
const manifestEvidence = { inputId: 'package', bytes: 2, sha256: hash('{}') };
const manifest = () => ({ name: '@fixture/math', version: '1.2.3', proofscript: { library: { schemaVersion: 1, modulePrefix: 'Demo', sourceRoot: 'src' } } });
async function fixture(t, { unused = false } = {}) {
  const root = await mkdtemp(path.join(os.tmpdir(), 'psc-library-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  const pkg = path.join(root, 'node_modules/@fixture/math');
  await mkdir(path.join(root, 'src'), { recursive: true });
  await mkdir(path.join(pkg, 'src/Demo'), { recursive: true });
  const project = { private: true, dependencies: { '@fixture/math': '1.2.3', ...(unused ? { '@fixture/missing': '1.0.0' } : {}) }, proofscript: { libraries: { Demo: '@fixture/math', ...(unused ? { Missing: '@fixture/missing' } : {}) } } };
  await writeFile(path.join(root, 'package.json'), JSON.stringify(project));
  await writeFile(path.join(pkg, 'package.json'), JSON.stringify(manifest()));
  const entry = path.join(root, 'src/Main.lean');
  await writeFile(entry, 'import Demo.Math\nimport Demo.Leaf\ndef answer : Nat := 42\n');
  await writeFile(path.join(pkg, 'src/Demo/Math.lean'), 'import Demo.Leaf\ndef math : Nat := 42\n');
  await writeFile(path.join(pkg, 'src/Demo/Leaf.lean'), 'def leaf : Nat := 1\n');
  return { root, pkg, entry, project, capture: () => captureSourceGraph(compiler, entry) };
}
test('library evidence describes original bytes including BOM, never decoded text', async t => {
  const f = await fixture(t), file = path.join(f.root, 'bom');
  const bytes = Buffer.from('\ufeffdef answer : Nat := 42\n');
  await writeFile(file, bytes);
  const io = createSnapshotReader();
  assert.throws(() => io.fileEvidence(file), /UNOBSERVED_FILE/);
  assert.equal(await io.readText(file, { id: 'bom' }), 'def answer : Nat := 42\n');
  const evidence = io.fileEvidence(file);
  assert.equal(evidence.sha256, hash(bytes)); assert.equal(evidence.bytes, bytes.length);
  assert(Object.isFrozen(evidence));
  const snapshot = io.seal();
  assert.equal(snapshot.binding.inputs[0].sha256, evidence.sha256);
  await writeFile(file, 'changed');
  assert.deepEqual(io.fileEvidence(file), evidence);
  await assert.rejects(snapshot.revalidate(), /INPUT_CHANGED/);
});
test('transitive and duplicate library imports record one entry per resolved module', async t => {
  const f = await fixture(t), graph = await f.capture();
  const d = graph.libraryDisclosure, libs = d.inventory.libraries;
  assert.equal(graph.sourceCount, 3); assert.equal(libs.length, 1);
  assert.deepEqual(libs[0].modules.map(m => m.moduleName), ['Demo.Leaf', 'Demo.Math']);
  assert.equal(libs[0].manifest.sha256, hash(await readFile(path.join(f.pkg, 'package.json'))));
  for (const m of libs[0].modules) {
    assert.equal(m.sha256, hash(await readFile(path.join(f.pkg, 'src', ...m.moduleName.split('.')) + '.lean')));
    assert.equal(graph.snapshot.binding.inputs.find(i => i.id === m.inputId).sha256, m.sha256);
  }
  assert.equal(graph.snapshot.binding.libraryDisclosureSha256, d.sha256);
  assert.equal(d.sha256, hash('PSC0/LIBRARY-DISCLOSURE/1\0' + JSON.stringify(d.inventory)));
  assert(Object.isFrozen(libs[0].modules));
  assert.deepEqual(d.inventory.executedExtensions, []); assert.equal(d.inventory.proofAuthority, 'none');
});
test('declared but unused packages are not loaded, reported as loaded, or required installed', async t => {
  const f = await fixture(t, { unused: true }), graph = await f.capture();
  assert.equal(graph.libraryDisclosure.inventory.declaredLibraries.length, 2);
  assert.equal(graph.libraryDisclosure.inventory.libraries.length, 1);
  assert(!libraryDisclosureNotice(graph.libraryDisclosure).includes('@fixture/missing'));
});
for (const [name, relative] of [['metadata', 'package.json'], ['source', 'src/Demo/Math.lean']]) {
  test('observed library ' + name + ' drift invalidates the source snapshot', async t => {
    const f = await fixture(t), graph = await f.capture();
    await writeFile(path.join(f.pkg, relative), 'changed after capture');
    await assert.rejects(graph.snapshot.revalidate(), /INPUT_CHANGED/);
  });
}
for (const field of ['trusted', 'suppressDisclosure', 'entryPoint', 'capabilities']) {
  test('source-only library manifest refuses unknown authority field ' + field, async t => {
    const f = await fixture(t), meta = manifest();
    meta.proofscript.library[field] = true;
    await writeFile(path.join(f.pkg, 'package.json'), JSON.stringify(meta));
    await assert.rejects(f.capture(), /UNSUPPORTED_MANIFEST_FIELD/);
  });
}
test('project execution requests fail even when no library is imported', async t => {
  const f = await fixture(t);
  f.project.proofscript.extensions = [];
  await writeFile(path.join(f.root, 'package.json'), JSON.stringify(f.project));
  await writeFile(f.entry, 'def answer : Nat := 42\n');
  await assert.rejects(f.capture(), /EXECUTABLE_EXTENSIONS_UNSUPPORTED/);
});
test('library execution requests cannot become implicit loading permissions', async t => {
  const f = await fixture(t), meta = manifest(); meta.proofscript.extensions = ['guest.js'];
  await writeFile(path.join(f.pkg, 'package.json'), JSON.stringify(meta));
  await assert.rejects(f.capture(), /EXECUTABLE_EXTENSIONS_UNSUPPORTED/);
});
test('fake package claims cannot promote proof authority or suppress host notice', async t => {
  const f = await fixture(t), meta = manifest();
  meta.main = './must-not-run.cjs';
  meta.scripts = { postinstall: 'node must-not-run.cjs' };
  meta.proofscript.suppressExtensionDisclosure = true;
  meta.proofscript.claims = { kernelAdmitted: true, fullPscvVerified: true };
  await writeFile(path.join(f.pkg, 'must-not-run.cjs'), 'throw new Error("LIBRARY_JS_EXECUTED");\n');
  await writeFile(path.join(f.pkg, 'package.json'), JSON.stringify(meta));
  const d = (await f.capture()).libraryDisclosure;
  assert.equal(d.inventory.proofAuthority, 'none'); assert.equal(d.inventory.installationHistory, 'not-observed');
  assert.deepEqual(d.inventory.libraries[0].declaredScriptNames, ['postinstall']);
  const text = libraryDisclosureNotice(d);
  assert(text.includes('@fixture/math')); assert(text.includes('"scriptsExecutedByCompiler":false'));
  assert(!text.includes('node must-not-run')); assert(!text.includes('"fullPscvVerified":true'));
});
test('local modules produce an explicit zero external-library inventory', async t => {
  const f = await fixture(t);
  await writeFile(f.entry, 'def answer : Nat := 42\n');
  const d = (await f.capture()).libraryDisclosure;
  assert.equal(d.inventory.libraries.length, 0); assert(libraryDisclosureNotice(d).includes('"loaded":0'));
});
test('the optional stdlib is a source library, not a special proof authority', () => {
  const meta = manifest(); meta.name = '@proofscript/stdlib'; meta.proofscript.library.modulePrefix = 'ProofScript';
  const declared = [{ namespace: 'ProofScript', packageName: '@proofscript/stdlib' }];
  const ledger = createLibraryDisclosure(declared);
  ledger.record(describeSourceLibrary(meta, declared[0], manifestEvidence), 'ProofScript.Nat', 'lean', manifestEvidence);
  assert.equal(ledger.seal().inventory.proofAuthority, 'none');
});
test('a second filesystem alias is disclosed even when compilation is deduplicated', async t => {
  const f = await fixture(t), real = path.join(f.pkg, 'src/Demo/Real');
  await mkdir(real); await writeFile(path.join(real, 'Value.lean'), 'def value : Nat := 1\n');
  await symlink(real, path.join(f.pkg, 'src/Demo/Alias'), process.platform === 'win32' ? 'junction' : 'dir');
  await writeFile(f.entry, 'import Demo.Real.Value\nimport Demo.Alias.Value\ndef answer : Nat := 42\n');
  const graph = await f.capture();
  assert.equal(graph.sourceCount, 2);
  assert.deepEqual(graph.libraryDisclosure.inventory.libraries[0].modules.map(m => m.moduleName), ['Demo.Alias.Value', 'Demo.Real.Value']);
  const other = path.join(f.pkg, 'src/Demo/Other'); await mkdir(other);
  await writeFile(path.join(other, 'Value.lean'), 'def value : Nat := 1\n');
  await rm(path.join(f.pkg, 'src/Demo/Alias'), { recursive: true });
  await symlink(other, path.join(f.pkg, 'src/Demo/Alias'), process.platform === 'win32' ? 'junction' : 'dir');
  await assert.rejects(graph.snapshot.revalidate(), /INPUT_CHANGED/);
});
test('library inventory is deterministic across observation order', () => {
  const meta = describeSourceLibrary(manifest(), mapping, manifestEvidence);
  function build(names) { const l = createLibraryDisclosure([mapping]); for (const n of names) l.record(meta, n, 'lean', manifestEvidence); return l.seal(); }
  assert.deepEqual(build(['Demo.B', 'Demo.A']), build(['Demo.A', 'Demo.B']));
});
test('closed library inventories cannot be extended or resealed', () => {
  const l = createLibraryDisclosure([mapping]); l.seal();
  assert.throws(() => l.seal(), /SEALED/);
  assert.throws(() => l.record({}, 'Demo.A', 'lean', {}), /SEALED/);
});
test('conflicting and undeclared library observations are refused', () => {
  const l = createLibraryDisclosure([mapping]), m = describeSourceLibrary(manifest(), mapping, manifestEvidence);
  l.record(m, 'Demo.A', 'lean', manifestEvidence);
  assert.throws(() => l.record({ ...m, version: '2.0.0' }, 'Demo.A', 'lean', manifestEvidence), /IDENTITY_CONFLICT/);
  assert.throws(() => l.record(m, 'Demo.A', 'lean', { ...manifestEvidence, sha256: hash('different') }), /SOURCE_CONFLICT/);
  assert.throws(() => createLibraryDisclosure([]).record(m, 'Demo.A', 'lean', manifestEvidence), /UNDECLARED_INPUT/);
});
test('declarations and script metadata have finite validated shapes', () => {
  const libraries = Object.fromEntries(Array.from({ length: 257 }, (_, i) => ['N' + i, '@fixture/p' + i]));
  assert.throws(() => declaredLibraries({ meta: { proofscript: { libraries } } }), /COUNT_LIMIT/);
  const meta = manifest(); meta.scripts = ['not a map'];
  assert.throws(() => describeSourceLibrary(meta, mapping, manifestEvidence), /SCRIPTS_SHAPE/);
  delete meta.scripts; meta.version = '1.2.3\u001b[2J';
  assert.throws(() => describeSourceLibrary(meta, mapping, manifestEvidence), /VERSION_IDENTITY/);
});
