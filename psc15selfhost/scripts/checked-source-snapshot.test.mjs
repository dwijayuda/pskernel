import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, mkdir, rm, symlink } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';
import { computeBootstrapWorkspaceClosureSha256 } from './bootstrap-manifest.mjs';
async function fixture(fn) {
  const dir = await mkdtemp(path.join(tmpdir(), 'checked-snapshot-'));
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
  await writeFile(path.join(dir, 'Main.ps'), 'import Lib;\ndef main: Nat := answer;');
  await writeFile(path.join(dir, 'Lib.ps'), 'def answer: Nat := 42;');
  await writeFile(path.join(dir, 'Lib.lean'), 'def WRONG : Nat := 0');
  const snapshot = await readCheckedSourceSnapshot(path.join(dir, 'Main.ps'));
  assert.match(snapshot.source, /answer: Nat := 42/); assert.doesNotMatch(snapshot.source, /WRONG|import Lib/);
  assert.equal(snapshot.ordered.length, 2);
  assert.deepEqual(snapshot.sources, ['def answer: Nat := 42;', 'def main: Nat := answer;']);
  assert.equal(snapshot.source, snapshot.sources.join('\n\n') + '\n');
}));
test('missing PS dependency cannot fall back to Lean', () => fixture(async dir => {
  await writeFile(path.join(dir, 'Main.ps'), 'import Lib;');
  await writeFile(path.join(dir, 'Lib.lean'), 'def WRONG : Nat := 0');
  await assert.rejects(readCheckedSourceSnapshot(path.join(dir, 'Main.ps')), /ENOENT/);
}));
test('cycles rejected', () => fixture(async dir => {
  await writeFile(path.join(dir, 'Main.lean'), 'import Lib\n');
  await writeFile(path.join(dir, 'Lib.lean'), 'import Main\n');
  await assert.rejects(readCheckedSourceSnapshot(path.join(dir, 'Main.lean')), /IMPORT_CYCLE/);
}));
test('symlink dependency escape rejected', () => fixture(async dir => {
  const project = path.join(dir, 'project'); await mkdir(project);
  await writeFile(path.join(project, 'Main.lean'), 'import Lib\n');
  await writeFile(path.join(dir, 'outside.lean'), 'def wrong : Nat := 0');
  await symlink(path.join(dir, 'outside.lean'), path.join(project, 'Lib.lean'));
  await assert.rejects(readCheckedSourceSnapshot(path.join(project, 'Main.lean')), /SOURCE_ESCAPE/);
}));
test('generated manifest is verified by the same production resolver', () => fixture(async dir => {
  await mkdir(path.join(dir, 'packages'));
  const entry = 'Main.ps'; await writeFile(path.join(dir, entry), 'def answer: Nat := 42;');
  const manifest = { schemaVersion: 2, generation: 'bootstrap', entry, generated: [entry], sourceCount: 1,
    closureSha256: await computeBootstrapWorkspaceClosureSha256(dir, entry, [entry]) };
  await writeFile(path.join(dir, '.proofscript-bootstrap.json'), JSON.stringify(manifest));
  const snapshot = await readCheckedSourceSnapshot(path.join(dir, entry));
  assert.equal(snapshot.closureSha256, manifest.closureSha256);
  await writeFile(path.join(dir, entry), 'def answer: Nat := 43;');
  await assert.rejects(readCheckedSourceSnapshot(path.join(dir, entry)), /CLOSURE_MISMATCH/);
}));
