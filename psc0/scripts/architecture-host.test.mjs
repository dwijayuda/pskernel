import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, mkdir, writeFile, readFile, readdir, symlink, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { createCheckedPreparedSession } from '../npm-cli/checked-session.mjs';
import { createSnapshotReader } from '../npm-cli/snapshot.mjs';
import { captureSourceGraph } from '../npm-cli/source-graph.mjs';
import { publishGeneration } from '../npm-cli/publication.mjs';
const identity = Object.freeze({ protocol: 'test/1', provider: 'test', profile: 'test' });
const tag = Symbol('Except');
const ok = value => ({ [tag]: 'ok', value });
function fake(checker = () => ({ ...identity, accepted: true })) {
  let prepared, count = 0;
  const compiler = {
    psProofScriptGrammarEdition: 'ps-0.9-r3', psProofScriptGrammarMode: 'new-only',
    List: { nil: () => null, cons: (head, tail) => ({ head, tail }) },
    psCompilerPrepareSource: (_, source) => ok(prepared = { declarations: [source] }),
    psCompilerPrepareSources: (_, list) => { const declarations = []; for (let p = list; p; p = p.tail) declarations.push(p.head); return ok(prepared = { declarations }); },
    psCompilerAdmissionsFromPrepared: value => ok(JSON.stringify(value.declarations)),
    psCompilerTypeScriptFromPrepared: () => { count++; return ok('export const answer = 42n;'); },
  };
  return { compiler, session: createCheckedPreparedSession(compiler, a => checker(a, prepared), identity), emitted: () => count };
}
async function directory(t) {
  const dir = await mkdtemp(path.join(os.tmpdir(), 'psc-host-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  return dir;
}
const products = { '.js': 'export const answer = 42n;\n', '.ts': 'export const answer = 42n;\n', '.d.ts': 'export declare const answer: bigint;\n', '.js.map': '{}\n' };

test('checked handles bind a captured snapshot and reject cloning/reuse', async () => {
  const { session } = fake();
  const binding = { sourceClosureSha256: 'original' };
  const h = await session.checkSources('lean', ['hello'], binding);
  binding.sourceClosureSha256 = 'changed';
  assert.equal(h.binding.sourceClosureSha256, 'original');
  assert.throws(() => session.emit({ ...h }), /UNCHECKED_MODULE/);
  assert.equal(session.emit(h), products['.js'].trim());
  session.revoke(h); assert.throws(() => session.emit(h), /UNCHECKED_MODULE/);
});
test('contradictory acceptance cannot authorize emission', async () => {
  const f = fake(() => ({ ...identity, accepted: true, errorKind: 'failed' }));
  await assert.rejects(f.session.check('lean', 'hello'), /CONTRADICTORY/);
  assert.equal(f.emitted(), 0);
});
test('the prepared object is frozen before admission', async () => {
  const f = fake((_, prepared) => {
    assert(Object.isFrozen(prepared.declarations));
    assert.throws(() => prepared.declarations.push('changed'), TypeError);
    return { ...identity, accepted: true };
  });
  await f.session.check('lean', 'hello');
});
test('snapshot binds bytes, not mutable metadata or a late source read', async t => {
  const dir = await directory(t), file = path.join(dir, 'Main.lean');
  await writeFile(file, 'original');
  const io = createSnapshotReader();
  assert.equal(await io.readText(file, { id: 'entry', root: dir }), 'original');
  const s = io.seal({ kind: 'lean' });
  await writeFile(file, 'modified');
  await assert.rejects(s.revalidate(), /INPUT_CHANGED/);
  await assert.rejects(io.readText(file), /SEALED/);
});
test('snapshot records absent package and lock inputs', async t => {
  const dir = await directory(t), file = path.join(dir, 'package-lock.json');
  const io = createSnapshotReader();
  assert.equal(await io.readText(file, { optional: true, id: 'lock' }), null);
  const s = io.seal(); await s.revalidate();
  await writeFile(file, '{}');
  await assert.rejects(s.revalidate(), /INPUT_CHANGED/);
});
test('source bytes, aggregate bytes and file counts have independent budgets', async t => {
  const dir = await directory(t), a = path.join(dir, 'A'), b = path.join(dir, 'B');
  await writeFile(a, '123456'); await writeFile(b, 'abcdef');
  await assert.rejects(createSnapshotReader({ maxFileBytes: 5 }).readText(a), /FILE_LIMIT/);
  const total = createSnapshotReader({ maxFileBytes: 8, maxTotalBytes: 10 });
  await total.readText(a); await assert.rejects(total.readText(b), /TOTAL_LIMIT/);
  const files = createSnapshotReader({ maxFiles: 1 });
  await files.readText(a); await assert.rejects(files.readText(b), /FILE_COUNT/);
});
test('invalid UTF-8 is not silently repaired', async t => {
  const dir = await directory(t), file = path.join(dir, 'bad');
  await writeFile(file, Buffer.from([0xff, 0xfe]));
  await assert.rejects(createSnapshotReader().readText(file), /encoded data|encoding|UTF-8/i);
});
test('directory junction cannot escape a source root', async t => {
  const dir = await directory(t), outside = await directory(t);
  await writeFile(path.join(outside, 'Source.lean'), 'outside');
  await symlink(outside, path.join(dir, 'link'), process.platform === 'win32' ? 'junction' : 'dir');
  await assert.rejects(createSnapshotReader().readText(path.join(dir, 'link/Source.lean'), { root: dir }), /SOURCE_ESCAPE/);
});
test('graph catches cycles and prevents unbounded recursive imports', async t => {
  const dir = await directory(t); await mkdir(path.join(dir, 'src'));
  await writeFile(path.join(dir, 'package.json'), '{}');
  await writeFile(path.join(dir, 'src/Main.lean'), 'import A\ndef answer : Nat := 42');
  await writeFile(path.join(dir, 'src/A.lean'), 'import Main');
  await assert.rejects(captureSourceGraph(fake().compiler, path.join(dir, 'src/Main.lean')), /IMPORT_CYCLE/);
  await writeFile(path.join(dir, 'src/A.lean'), 'import B');
  await writeFile(path.join(dir, 'src/B.lean'), 'def b : Nat := 0');
  await assert.rejects(captureSourceGraph(fake().compiler, path.join(dir, 'src/Main.lean'), { limits: { maxDepth: 1 } }), /DEPTH_LIMIT/);
});
test('new higher-priority local source invalidates a snapshot', async t => {
  const dir = await directory(t); await mkdir(path.join(dir, 'src'));
  await writeFile(path.join(dir, 'package.json'), '{}');
  await writeFile(path.join(dir, 'src/Main.lean'), 'import A\ndef answer : Nat := 42');
  await writeFile(path.join(dir, 'A.lean'), 'def a : Nat := 0');
  const graph = await captureSourceGraph(fake().compiler, path.join(dir, 'src/Main.lean'));
  await writeFile(path.join(dir, 'src/A.lean'), 'def a : Nat := 1');
  await assert.rejects(graph.snapshot.revalidate(), /INPUT_CHANGED/);
});
test('publication has one executable commit and keeps products in the generation', async t => {
  const dir = await directory(t); await writeFile(path.join(dir, 'package.json'), '{"type":"module"}');
  const output = path.join(dir, 'Main.js');
  const snapshot = { protectedPaths: [], revalidate: async () => {} };
  const audit = await publishGeneration({ output, products, snapshot, receipt: { kernelAdmitted: true } });
  assert.equal((await import(pathToFileURL(output).href)).answer, 42n);
  assert.equal(JSON.parse(await readFile(audit.receiptPath, 'utf8')).kernelAdmitted, true);
  assert.equal(await readFile(path.join(audit.artifactDirectory, 'Main.ts'), 'utf8'), products['.ts']);
  assert.equal(existsSync(output + '.psc-lock'), false);
});
test('input drift preserves old executable and deletes the rejected generation', async t => {
  const dir = await directory(t), output = path.join(dir, 'Main.js');
  await writeFile(output, 'old committed executable');
  const snapshot = { protectedPaths: [], revalidate: async () => { throw new Error('PSC_SNAPSHOT_INPUT_CHANGED'); } };
  await assert.rejects(publishGeneration({ output, products, snapshot, receipt: {} }), /INPUT_CHANGED/);
  assert.equal(await readFile(output, 'utf8'), 'old committed executable');
  assert.deepEqual(await readdir(path.join(dir, '.psc-artifacts')), []);
  assert.equal(existsSync(output + '.psc-lock'), false);
});
test('publication rejects input overwrite and simultaneous writer ownership', async t => {
  const dir = await directory(t), output = path.join(dir, 'Main.js');
  await writeFile(output, 'source');
  await assert.rejects(publishGeneration({ output, products, receipt: {}, snapshot: { protectedPaths: [output], revalidate: async () => {} } }), /OVERWRITES_INPUT/);
  await writeFile(output + '.psc-lock', 'another writer');
  await assert.rejects(publishGeneration({ output, products, receipt: {}, snapshot: { protectedPaths: [], revalidate: async () => {} } }), /EEXIST/);
  assert.equal(await readFile(output, 'utf8'), 'source');
});
