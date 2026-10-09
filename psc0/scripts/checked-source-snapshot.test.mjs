import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, mkdir, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';
import { computeBootstrapWorkspaceClosureSha256 } from './bootstrap-manifest.mjs';
// Exact parser results isolate filesystem behavior here. The production adapters
// call the actual generated/native parser; proofscript-source.test.mjs and the
// checked-build integration cases exercise those grammar boundaries.
function parsedFixtures(entries) {
  const imports = new Map(entries);
  return { readProofScriptImports(source) {
    assert(imports.has(source), 'unexpected raw parser input: ' + JSON.stringify(source));
    return imports.get(source);
  } };
}
async function fixture(fn) {
  const dir = await mkdtemp(path.join(tmpdir(), 'checked snapshot λ '));
  try { await fn(dir); } finally { await rm(dir, { recursive: true, force: true }); }
}
test('standalone source snapshot does not reread changed files', () => fixture(async dir => {
  const entry = path.join(dir, 'Main.lean'); await writeFile(entry, 'def answer : Nat := 42');
  const snapshot = await readCheckedSourceSnapshot(entry);
  await writeFile(entry, 'def answer : Nat := 43');
  assert.match(snapshot.source, /42/); assert.ok(Object.isFrozen(snapshot));
  assert.deepEqual(snapshot.sources, ['def answer : Nat := 42']);
  assert.ok(Object.isFrozen(snapshot.sources));
  assert.notEqual(snapshot.closureSha256, (await readCheckedSourceSnapshot(entry)).closureSha256);
}));
test('PS dependency cannot be shadowed by Lean sibling', () => fixture(async dir => {
  const main = 'import Lib\ndef main: Nat := answer\n';
  const lib = 'def answer: Nat := 42\n';
  await writeFile(path.join(dir, 'Main.ps'), main);
  await writeFile(path.join(dir, 'Lib.ps'), lib);
  await writeFile(path.join(dir, 'Lib.lean'), 'def WRONG : Nat := 0');
  const snapshot = await readCheckedSourceSnapshot(path.join(dir, 'Main.ps'),
    parsedFixtures([[main, ['Lib']], [lib, []]]));
  assert.match(snapshot.source, /answer: Nat := 42/); assert.doesNotMatch(snapshot.source, /WRONG/);
  assert.match(snapshot.source, /import Lib/);
  assert.equal(snapshot.ordered.length, 2);
  assert.deepEqual(snapshot.sources, [lib, main]);
  assert.equal(snapshot.source, snapshot.sources.join('\n\n') + '\n');
}));
test('missing PS dependency cannot fall back to Lean', () => fixture(async dir => {
  const source = 'import Lib\n';
  await writeFile(path.join(dir, 'Main.ps'), source);
  await writeFile(path.join(dir, 'Lib.lean'), 'def WRONG : Nat := 0');
  await assert.rejects(readCheckedSourceSnapshot(path.join(dir, 'Main.ps'),
    parsedFixtures([[source, ['Lib']]])), /ENOENT/);
}));
test('cycles rejected', () => fixture(async dir => {
  await writeFile(path.join(dir, 'Main.lean'), 'import Lib\n');
  await writeFile(path.join(dir, 'Lib.lean'), 'import Main\n');
  await assert.rejects(readCheckedSourceSnapshot(path.join(dir, 'Main.lean')), /IMPORT_CYCLE/);
}));
test('linked directory dependency escape rejected', () => fixture(async dir => {
  const project = path.join(dir, 'project'); await mkdir(project);
  const outside = path.join(dir, 'outside'); await mkdir(outside);
  await writeFile(path.join(project, 'Main.lean'), 'import Linked.Lib\n');
  await writeFile(path.join(outside, 'Lib.lean'), 'def wrong : Nat := 0');
  // A directory junction needs no file-symlink privilege on Windows and still
  // resolves to a dependency outside the real workspace boundary.
  await symlink(outside, path.join(project, 'Linked'),
    process.platform === 'win32' ? 'junction' : 'dir');
  await assert.rejects(readCheckedSourceSnapshot(path.join(project, 'Main.lean')), /SOURCE_ESCAPE/);
}));
test('generated manifest is verified by the same production resolver', () => fixture(async dir => {
  await mkdir(path.join(dir, 'packages'));
  const entry = 'Main.ps', before = 'def answer: Nat := 42\n', after = 'def answer: Nat := 43\n';
  const parser = parsedFixtures([[before, []], [after, []]]);
  await writeFile(path.join(dir, entry), before);
  const manifest = { schemaVersion: 2, generation: 'bootstrap', entry, generated: [entry], sourceCount: 1,
    closureSha256: await computeBootstrapWorkspaceClosureSha256(dir, entry, [entry]) };
  await writeFile(path.join(dir, '.proofscript-bootstrap.json'), JSON.stringify(manifest));
  const snapshot = await readCheckedSourceSnapshot(path.join(dir, entry), parser);
  assert.equal(snapshot.closureSha256, manifest.closureSha256);
  await writeFile(path.join(dir, entry), after);
  await assert.rejects(readCheckedSourceSnapshot(path.join(dir, entry), parser), /CLOSURE_MISMATCH/);
}));

test('PS snapshot requires an actual parser adapter', () => fixture(async dir => {
  const entry = path.join(dir, 'Main.ps');
  await writeFile(entry, 'def answer : Nat := 42\n');
  await assert.rejects(readCheckedSourceSnapshot(entry), /SOURCE_PARSER_REQUIRED/);
}));
test('PS snapshot validates raw import bytes before dependency access', () => fixture(async dir => {
  const entry = path.join(dir, 'Main.ps'), source = '\timport Missing;\n';
  await writeFile(entry, source);
  await assert.rejects(readCheckedSourceSnapshot(entry, {
    readProofScriptImports(raw, file) {
      assert.equal(raw, source); assert.equal(file, entry);
      throw new Error('ACTUAL_PARSER_REJECTED');
    },
  }), /ACTUAL_PARSER_REJECTED/);
}));
test('PS import cycles retain their dependency error', () => fixture(async dir => {
  const main = 'import Lib\n', lib = 'import Main\n';
  await writeFile(path.join(dir, 'Main.ps'), main);
  await writeFile(path.join(dir, 'Lib.ps'), lib);
  await assert.rejects(readCheckedSourceSnapshot(path.join(dir, 'Main.ps'),
    parsedFixtures([[main, ['Lib']], [lib, ['Main']]])), /IMPORT_CYCLE/);
}));

test('source snapshots preserve raw bytes across native path spellings', () => fixture(async dir => {
  const entry = path.join(dir, 'Main.ps');
  const source = '\uFEFFdef answer : Nat := 42\r\n';
  await writeFile(entry, source);
  const parser = parsedFixtures([[source, []]]);
  const expected = await readCheckedSourceSnapshot(entry, parser);
  const aliases = [dir + path.sep + 'unused' + path.sep + '..' + path.sep + 'Main.ps'];
  if (process.platform === 'win32') {
    aliases.push(entry.split(path.sep).join('/'));
    aliases.push(entry.replace(/^[A-Za-z]:/u, drive => drive[0] === drive[0].toUpperCase()
      ? drive.toLowerCase() : drive.toUpperCase()));
  }
  for (const alias of aliases) {
    const actual = await readCheckedSourceSnapshot(alias, parser);
    assert.deepEqual(actual.sources, [source], alias);
    assert.equal(actual.closureSha256, expected.closureSha256, alias);
    assert.equal(actual.ordered.length, 1, alias);
  }
}));

if (process.platform === 'win32') {
  test('Windows source filename casing cannot hide an import cycle', () => fixture(async dir => {
    const entry = path.join(dir, 'Main.ps'), lib = path.join(dir, 'Lib.ps');
    const mainSource = 'import lib\n', libSource = 'import MAIN\n';
    await writeFile(entry, mainSource);
    await writeFile(lib, libSource);
    await assert.rejects(readCheckedSourceSnapshot(entry,
      parsedFixtures([[mainSource, ['lib']], [libSource, ['MAIN']]])), /IMPORT_CYCLE/);
  }));
}
