// Small source-level regressions for previously audited export, specialization
// and recursion risks. This does not build a self-hosted compiler or kernel.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-source-edges-'));
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
const records = [];
const evidence = path.join(root, 'dist/scoped-correctness');
fs.mkdirSync(evidence, { recursive: true });
function source(name, text) {
  const file = path.join(work, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
  return file;
}
async function compile(input, folder) {
  const output = path.join(work, folder, 'module.js');
  const result = spawnSync(native, ['build', input, '--target', 'js', '--out', output], {
    env: { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') },
    encoding: 'utf8', timeout: 120_000, maxBuffer: 16 * 1024 * 1024
  });
  if (result.error || result.status !== 0) {
    throw new Error(`PSC1_EDGE_COMPILE_FAILED: ${input}\n${result.error?.message ?? ''}\n${result.stdout}\n${result.stderr}`);
  }
  const module = await import(pathToFileURL(fs.realpathSync(output)).href);
  const declarations = fs.readFileSync(output.replace(/\.js$/, '.d.ts'), 'utf8');
  const manifest = JSON.parse(fs.readFileSync(output + '.bundle.json', 'utf8'));
  assert.deepEqual(Object.keys(module).sort(), [...manifest.publicNames].sort());
  return { module, declarations, output, manifest };
}
async function test(name, action) {
  try {
    await action();
    records.push({ name, status: 'pass' });
    console.log(`PSC1_SOURCE_EDGE_PASS: ${name}`);
  } catch (error) {
    records.push({ name, status: 'fail', error: error.message });
    throw error;
  } finally {
    fs.writeFileSync(path.join(evidence, 'source-edges.json'), JSON.stringify({
      sha: process.env.GITHUB_SHA, fullSelfHostTests: false, cases: records
    }, null, 2) + '\n');
  }
}

await test('imported generic helper specializes without leaking into public declarations', async () => {
  source('generic/Dep.lean', 'def helper {a : Type} (x : a) : a := x\n');
  const entry = source('generic/Main.lean', 'import Dep\ndef publicid (x : Nat) : Nat := helper x\n');
  const result = await compile(entry, 'generic-output');
  assert.deepEqual(Object.keys(result.module), ['publicid']);
  assert.equal(result.module.publicid(42n), 42n);
  assert.match(result.declarations, /publicid\(x: bigint\): bigint/);
  assert.doesNotMatch(result.declarations, /helper/);
});
await test('qualified and underscore-like source names keep distinct runtime identities', async () => {
  const entry = source('names.lean', 'def Util.id (x : Bool) : Bool := x\ndef Util_id : Bool := false\n');
  const result = await compile(entry, 'names-output');
  assert.equal(Object.keys(result.module).length, 2);
  const functions = Object.values(result.module).filter(value => typeof value === 'function');
  assert.equal(functions.length, 1);
  assert.equal(functions[0](true), true);
  assert.equal(functions[0](false), false);
  assert.equal(Object.values(result.module).filter(value => value === false).length, 1);
});
await test('an import-only entry is an empty public ECMAScript module', async () => {
  source('empty/Dep.lean', 'def hidden : Bool := true\n');
  const entry = source('empty/Main.lean', 'import Dep\n');
  const result = await compile(entry, 'empty-output');
  assert.deepEqual(Object.keys(result.module), []);
  assert.match(result.declarations, /export\s*\{\s*\}/);
});
await test('non-tail recursive Nat execution uses the stack-safe direct printer', async () => {
  const entry = source('count.lean', 'def count (n : Nat) : Nat :=\n  match n with\n  | Nat.zero => Nat.zero\n  | Nat.succ k => Nat.succ (count k)\n');
  const result = await compile(entry, 'count-output');
  assert.equal(result.module.count(0n), 0n);
  assert.equal(result.module.count(100000n), 100000n);
  assert.match(fs.readFileSync(result.output, 'utf8'), /function\*/);
});
await test('unused runtime prelude names cannot hide an entry declaration', async () => {
  for (const kind of ['lean', 'ps']) {
    const text = kind === 'lean'
      ? 'def Id_run (flag : Bool) : Bool := flag\n'
      : 'def Id_run(flag : Bool) : Bool := flag\n';
    const entry = source('unused-prelude-' + kind + '/Main.' + kind, text);
    const result = await compile(entry, 'unused-prelude-' + kind);
    assert.deepEqual(Object.keys(result.module), ['Id_run']);
    assert.equal(result.module.Id_run(false), false);
    assert.equal(result.module.Id_run(true), true);
    assert.match(result.declarations, /Id_run\(flag: boolean\): boolean/);
  }
});
console.log(`PSC1_SOURCE_EDGE_TESTS: ${records.length} passed`);
