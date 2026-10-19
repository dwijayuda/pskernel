// Focused ordinary partial execution. No self-host compiler/kernel generation,
// census or fixed-point qualification runs in this suite.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { pathToFileURL, fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-ordinary-'));
const evidence = path.join(root, 'dist/scoped-correctness/ordinary');
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const records = [];
fs.mkdirSync(evidence, { recursive: true });
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
const read = file => fs.readFileSync(file, 'utf8');
const json = file => JSON.parse(read(file));
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
function run(command, args, options = {}) {
  const result = spawnSync(command, args, { cwd: root, env, encoding: 'utf8',
    timeout: 120_000, maxBuffer: 64 * 1024 * 1024, ...options });
  if (result.error || result.status !== 0) {
    throw new Error(command + ' ' + args.join(' ') + '\n' +
      (result.error?.message || '') + '\n' + result.stdout + '\n' + result.stderr);
  }
  return result.stdout;
}
function reject(args, pattern) {
  const result = spawnSync(native, args, { cwd: root, env, encoding: 'utf8',
    timeout: 120_000, maxBuffer: 64 * 1024 * 1024 });
  if (result.error) throw result.error;
  assert.notEqual(result.status, 0, 'unexpected ordinary acceptance');
  const diagnostic = result.stdout + '\n' + result.stderr;
  if (pattern) assert.match(diagnostic, pattern);
  return diagnostic;
}
function source(name, text) {
  const file = path.join(work, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
  return file;
}
function build(input, target, name, extra = []) {
  const output = path.join(work, name);
  run(native, ['build', input, '--assurance', 'ordinary',
    '--target', target, ...extra, '--out', output]);
  const manifest = json(output + '.bundle.json');
  assert.equal(manifest.target, target);
  assert.equal(manifest.logicalChecker, 'lean4:4.35.0');
  assert.equal(manifest.logicalCheckerCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.assurance, 'ordinary-checked');
  assert.equal(manifest.behaviorallyVerified, false);
  assert.ok(manifest.partialDeclarations.length > 0);
  const generation = path.dirname(fs.realpathSync(output + '.bundle.json'));
  for (const item of manifest.files) {
    assert.equal(hash(path.join(generation, item.path)), item.sha256);
    assert.equal(fs.statSync(path.join(generation, item.path)).size, item.bytes);
  }
  return output;
}
const load = file => import(pathToFileURL(fs.realpathSync(file)).href);
function ts7(args) {
  assert.ok(process.env.PSC1_TSC && fs.existsSync(process.env.PSC1_TSC),
    'isolated pinned TypeScript compiler required for TS execution test');
  return run(process.execPath, [process.env.PSC1_TSC, '--ignoreConfig', ...args]);
}
async function test(name, action) {
  try {
    await action();
    records.push({ name, status: 'pass' });
    console.log('PSC1_ORDINARY_PASS: ' + name);
  } catch (error) {
    records.push({ name, status: 'fail', error: error.message });
    throw error;
  } finally {
    fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify({
      sha: process.env.GITHUB_SHA, assurance: 'ordinary-checked',
      behaviorallyVerified: false, fullSelfHostTests: false, cases: records
    }, null, 2) + '\n');
  }
}

try {
  const lean = source('countdown.lean',
    'partial def countdown (n : Nat) : Nat := if Nat.beq n 0 then 42 else countdown (Nat.sub n 1)\n');
  const ps = source('countdown.ps',
    'partial def countdown(n : Nat) : Nat := if (Nat.beq(n, 0)) { 42 } else { countdown(Nat.sub(n, 1)) }\n');
  source('modules/Dep.lean',
    'partial def ordinaryFlag (b : Bool) : Bool := if b then true else ordinaryFlag true\n');
  const entry = source('modules/Main.lean',
    'import Dep\ndef answer (b : Bool) : Bool := ordinaryFlag b\n');
  let countdownJs;
  await test('explicit ordinary JS executes the exact body in both source forms', async () => {
    countdownJs = build(lean, 'js', 'lean/countdown.js');
    const fromPs = build(ps, 'js', 'ps/countdown.js');
    assert.equal((await load(countdownJs)).countdown(7n), 42n);
    assert.equal((await load(fromPs)).countdown(7n), 42n);
    assert.equal((await load(countdownJs)).countdown(100000n), 42n);
    assert.equal((await load(countdownJs)).countdown(0n), 42n);
    const generation = path.dirname(fs.realpathSync(countdownJs));
    const admissions = read(path.join(generation, 'admissions.json'));
    assert.match(admissions, /"k":"opaque"/);
    assert.match(admissions, /_psc1PartialBody/);
    assert.doesNotMatch(read(countdownJs), /_psc1PartialBody/);
    assert.deepEqual(Object.keys(await load(countdownJs)), ['countdown']);
    const map = json(countdownJs + '.map');
    assert.ok(map.sourcesContent.some(text => text.includes('partial def countdown')));
    fs.copyFileSync(countdownJs, path.join(evidence, 'countdown.js'));
    fs.copyFileSync(path.join(generation, 'admissions.json'), path.join(evidence, 'countdown-admissions.json'));
  });
  await test('checked default and verified requests fail before publication', () => {
    const before = hash(countdownJs + '.bundle.json');
    reject(['build', lean, '--target', 'js', '--out', countdownJs], /PSC1_PREPARATION_FAILED/);
    reject(['build', lean, '--assurance', 'verified', '--target', 'js', '--out', countdownJs],
      /PSC1_VERIFIED_EXECUTION_UNAVAILABLE/);
    reject(['build', lean, '--assurance', 'ordinary', '--assurance', 'verified',
      '--target', 'js', '--out', countdownJs], /PSC1_ASSURANCE_DUPLICATE/);
    assert.equal(hash(countdownJs + '.bundle.json'), before);
  });
  await test('transitive partial dependencies stay internal to the entry API', async () => {
    const output = build(entry, 'js', 'imported/module.js');
    const module = await load(output);
    assert.deepEqual(Object.keys(module), ['answer']);
    assert.equal(module.answer(false), true);
    assert.equal(module.answer(true), true);
    assert.deepEqual(json(output + '.bundle.json').partialDeclarations, ['ordinaryFlag']);
    assert.doesNotMatch(read(output.replace(/\.js$/, '.d.ts')), /ordinaryFlag/);
    assert.equal(json(output + '.map').sourcesContent.length, 2);
  });
  await test('ordinary TS compiles strictly and executes the same recursive body', async () => {
    const output = build(entry, 'ts', 'ts/module.ts');
    const checked = path.join(work, 'ts-checked');
    ts7(['--strict', '--target', 'ES2022', '--module', 'ES2022',
      '--outDir', checked, output]);
    assert.equal((await import(pathToFileURL(path.join(checked, 'module.js')).href)).answer(false), true);
  });
  await test('ordinary Rust crate compiles and executes the recursive Bool dependency', () => {
    const output = build(entry, 'rust', 'rust/module.rs');
    const crate = path.join(work, 'rust-test');
    fs.cpSync(fs.realpathSync(output.replace(/\.rs$/, '.cargo')), crate, { recursive: true });
    fs.appendFileSync(path.join(crate, 'src/lib.rs'),
      '\n#[cfg(test)] mod ordinary_tests { use super::*; #[test] fn exact_body() { assert!(answer(false)); assert!(answer(true)); } }\n');
    run('cargo', ['test', '--locked', '--manifest-path', path.join(crate, 'Cargo.toml')], {
      env: { ...env, CARGO_TARGET_DIR: path.join(os.tmpdir(), 'psc1-scoped-cargo-target') }
    });
  });
  await test('ordinary core Wasm executes the admitted Bool closure', async () => {
    const output = build(entry, 'wasm-core', 'core/module.wasm');
    const { instance } = await WebAssembly.instantiate(fs.readFileSync(output));
    assert.deepEqual(Object.keys(instance.exports), ['answer']);
    assert.equal(instance.exports.answer(0), 1);
    assert.equal(instance.exports.answer(1), 1);
  });
  await test('ordinary component Wasm keeps the public ABI Bool only', () => {
    const output = build(entry, 'wasm-component', 'component/module.wasm', ['--export', 'answer']);
    assert.match(read(output.replace(/\.wasm$/, '.wit')), /func\(b: bool\) -> bool/);
    const result = run('wasmtime', ['run', '--invoke', 'answer(false)', output]).trim();
    assert.match(result, /true/);
    const unsupported = path.join(work, 'component-nat.wasm');
    reject(['build', lean, '--assurance', 'ordinary', '--target', 'wasm-component',
      '--export', 'countdown', '--out', unsupported], /PSC1_COMPONENT/);
    assert.equal(fs.existsSync(unsupported), false);
  });
  await test('ordinary still rejects missing inhabitants, value partials and bad bodies', () => {
    const missing = source('missing.lean',
      'partial def impossible {a : Type} (n : Nat) : a := impossible n\n');
    reject(['check', missing, '--assurance', 'ordinary'], /PSC1_PARTIAL_NO_CHECKED_INHABITANT/);
    const value = source('value.lean', 'partial def value : Nat := 1\n');
    reject(['check', value, '--assurance', 'ordinary'], /PSC1_PARTIAL_EXPECTED_FUNCTION/);
    const ill = source('ill.lean', 'partial def ill (n : Nat) : Nat := true\n');
    reject(['check', ill, '--assurance', 'ordinary']);
    const hole = source('hole.lean', 'partial def hole (n : Nat) : Nat := _\n');
    reject(['check', hole, '--assurance', 'ordinary']);
    const axiom = source('axiom.lean', 'axiom invented : Nat\n');
    reject(['check', axiom, '--assurance', 'ordinary']);
    const unsafe = source('unsafe.lean', 'unsafe def danger : Nat := 1\n');
    reject(['check', unsafe, '--assurance', 'ordinary']);
  });
  await test('intentional divergence is bounded only by an external process timeout', () => {
    const divergent = source('spin.lean', 'partial def spin (n : Nat) : Nat := spin n\n');
    const output = build(divergent, 'js', 'diverge/spin.js');
    const runner = source('run-spin.mjs',
      'import { spin } from ' + JSON.stringify(pathToFileURL(fs.realpathSync(output)).href) +
      ';\nspin(0n);\nthrow new Error("divergence returned");\n');
    const result = spawnSync(process.execPath, [runner], {
      cwd: work, env, encoding: 'utf8', timeout: 1000, maxBuffer: 1024 * 1024
    });
    assert.equal(result.error?.code, 'ETIMEDOUT',
      'divergence must time out externally, not return a witness or fail by runtime fuel/stack');
    fs.writeFileSync(path.join(evidence, 'divergence.json'), JSON.stringify({
      externalTimeoutMs: 1000, errorCode: result.error.code, signal: result.signal
    }, null, 2) + '\n');
  });
  console.log('PSC1_ORDINARY_EXECUTION: all focused cases passed');
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
