// Focused native compiler/backend regression only: no compiler or kernel
// bootstrap generations, no whole self-host source checks, no fixed-point run.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const requireTools = createRequire(path.join(root, 'host-tools', 'package.json'));
const { TraceMap, originalPositionFor } = requireTools('@jridgewell/trace-mapping');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-scoped-backends-'));
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const records = [];
const evidence = path.join(root, 'dist/scoped-correctness');
fs.mkdirSync(evidence, { recursive: true });
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
const text = file => fs.readFileSync(file, 'utf8');
const json = file => JSON.parse(text(file));
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
function command(cmd, args, options = {}) {
  const result = spawnSync(cmd, args, { env, encoding: 'utf8', timeout: 120_000,
    maxBuffer: 64 * 1024 * 1024, cwd: root, ...options });
  if (result.error || result.status !== 0) {
    throw new Error(`PSC1_EXEC_FAILED: ${cmd} ${args.join(' ')}\n${result.error?.message ?? ''}\n${result.stdout}\n${result.stderr}`);
  }
  return result.stdout;
}
function reject(cmd, args, options = {}) {
  const result = spawnSync(cmd, args, { env, encoding: 'utf8', timeout: 120_000,
    maxBuffer: 64 * 1024 * 1024, cwd: root, ...options });
  if (result.error) throw result.error;
  assert.notEqual(result.status, 0, `unexpected success: ${cmd} ${args.join(' ')}`);
  return `${result.stdout}\n${result.stderr}`;
}
function source(name, content) {
  const file = path.join(work, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content);
  return file;
}
function output(name) { return path.join(work, name); }
function build(input, target, name, extra = []) {
  const destination = output(name);
  command(native, ['build', input, '--target', target, ...extra, '--out', destination]);
  assert.ok(fs.statSync(destination).size > 0);
  const manifest = json(destination + '.bundle.json');
  assert.equal(manifest.target, target);
  assert.equal(manifest.logicalChecker, 'lean4:4.34.0');
  const generation = path.dirname(fs.realpathSync(destination + '.bundle.json'));
  for (const item of manifest.files) {
    assert.equal(hash(path.join(generation, item.path)), item.sha256, item.path);
    assert.equal(fs.statSync(path.join(generation, item.path)).size, item.bytes);
  }
  return destination;
}
async function load(file) { return import(pathToFileURL(fs.realpathSync(file)).href); }
async function test(name, action) {
  try {
    await action();
    records.push({ name, status: 'pass' });
    console.log(`PSC1_BACKEND_PASS: ${name}`);
  } catch (error) {
    records.push({ name, status: 'fail', error: error.message });
    throw error;
  } finally {
    fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify({ sha: process.env.GITHUB_SHA,
      profile: 'psc1-checked-direct/1', fullSelfHostTests: false, cases: records }, null, 2) + '\n');
  }
}
function traceDeclaration(jsFile, name) {
  const lines = text(jsFile).split('\n');
  const index = lines.findIndex(line => line.startsWith(`export function ${name}(`) || line.startsWith(`function ${name}(`) || line.startsWith(`export const ${name} `));
  assert.ok(index >= 0, `missing printed declaration ${name}`);
  return originalPositionFor(new TraceMap(json(jsFile + '.map')), { line: index + 1, column: 0 });
}
function ts7(args) {
  const tsc = process.env.PSC1_TSC;
  assert.ok(tsc && fs.existsSync(tsc), 'PSC1_TSC must identify the isolated pinned TypeScript 7 compiler');
  return command(process.execPath, [tsc, '--ignoreConfig', ...args]);
}

let jsNat, tsNat, rustNat, coreBool, componentBool;
try {
  const nat = source('identity.lean', 'def idNat (x : Nat) : Nat := x\n');
  const psNat = source('identity.ps', 'def idNat(x : Nat) : Nat := x\n');
  const bool = source('boolean.lean', 'def answer : Bool := true\n');
  await test('native identity and npm launcher agree', () => {
    const a = command(native, ['--identity']);
    const b = command(process.execPath, [path.join(root, 'npm-cli/psc.js'), '--identity'], { env: { ...env, PSC1_NATIVE: native } });
    assert.equal(a, b);
    assert.equal(JSON.parse(a).protocol, 'psc1-native/1');
    const error = reject(process.execPath, [path.join(root, 'npm-cli/psc.js'), '--version'], {
      env: { ...env, PSC1_NATIVE: path.join(work, 'missing-native') }
    });
    assert.match(error, /PSC1_NATIVE_MISSING/);
  });
  await test('real independent source admission is required by check', () => {
    assert.match(command(native, ['check', nat]), /PSC1_KERNEL_CHECK: PASS/);
    const bad = source('ill.lean', 'def ill : Nat := true\n');
    reject(native, ['check', bad]);
    for (const [target, extension] of [['js', 'js'], ['ts', 'ts'], ['rust', 'rs'], ['wasm-core', 'wasm']]) {
      const file = output(`invalid-${target}.${extension}`);
      reject(native, ['build', bad, '--target', target, '--out', file]);
      assert.equal(fs.existsSync(file), false);
      assert.equal(fs.existsSync(file + '.bundle.json'), false);
    }
  });
  await test('DirectJS .lean and .ps execute without TypeScript compilation', async () => {
    jsNat = build(nat, 'js', 'lean/module.js');
    const fromPs = build(psNat, 'js', 'ps/module.js');
    command(process.execPath, ['--check', jsNat]);
    assert.equal((await load(jsNat)).idNat(42n), 42n);
    assert.equal((await load(fromPs)).idNat(42n), 42n);
    assert.deepEqual(Object.keys(await load(jsNat)), ['idNat']);
    assert.match(text(jsNat), /export function idNat\(x\) \{\n/);
    assert.equal(traceDeclaration(jsNat, 'idNat').source, 'identity.lean');
    assert.equal(traceDeclaration(jsNat, 'idNat').line, 1);
  });
  await test('source maps use final formatted layout and UTF-16 source columns', async () => {
    const unicode = source('unicode.lean', '/- 🌍 -/ def answer : Bool := true\n');
    const file = build(unicode, 'js', 'unicode/module.js');
    const origin = traceDeclaration(file, 'answer');
    assert.equal(origin.column, 9);
    assert.equal(origin.line, 1);
    assert.equal((await load(file)).answer, true);
    assert.ok(json(file + '.map').sourcesContent[0].includes('🌍'));
    assert.equal(originalPositionFor(new TraceMap(json(file + '.map')), { line: 1, column: 0 }).source, null);
  });
  await test('entry API excludes imported helpers while JS and Wasm retain dependencies', async () => {
    source('modules/Dep.lean', 'def hidden (x : Bool) : Bool := x\n');
    const entry = source('modules/Main.lean', 'import Dep\ndef exposed (x : Bool) : Bool := hidden x\n');
    const js = build(entry, 'js', 'modules-js/module.js');
    const module = await load(js);
    assert.deepEqual(Object.keys(module), ['exposed']);
    assert.equal(module.exposed(true), true);
    assert.equal(module.exposed(false), false);
    assert.equal(traceDeclaration(js, 'hidden').source, 'Dep.lean');
    assert.equal(traceDeclaration(js, 'exposed').source, 'Main.lean');
    assert.equal(json(js + '.map').sourcesContent.length, 2);
    assert.match(text(js.replace(/\.js$/, '.d.ts')), /export declare function exposed/);
    assert.doesNotMatch(text(js.replace(/\.js$/, '.d.ts')), /hidden/);
    const wasm = build(entry, 'wasm-core', 'modules-wasm/module.wasm');
    const { instance } = await WebAssembly.instantiate(fs.readFileSync(wasm));
    assert.deepEqual(Object.keys(instance.exports), ['exposed']);
    assert.equal(instance.exports.exposed(1), 1);
    assert.equal(instance.exports.exposed(0), 0);
    const rust = build(entry, 'rust', 'modules-rust/module.rs');
    assert.match(text(rust), /pub fn exposed/);
    assert.doesNotMatch(text(rust), /pub fn hidden/);
  });
  await test('readable TS is strictly compiled and executes with the same API', async () => {
    tsNat = build(nat, 'ts', 'typescript/module.ts');
    const destination = output('typescript-compiled');
    ts7(['--strict', '--target', 'ES2022', '--module', 'ESNext', '--moduleResolution', 'Bundler', '--outDir', destination, fs.realpathSync(tsNat)]);
    fs.writeFileSync(path.join(destination, 'package.json'), '{"type":"module"}\n');
    assert.equal((await load(path.join(destination, 'module.js'))).idNat(42n), 42n);
    assert.match(text(tsNat), /export function idNat\(x: bigint\): bigint \{\n/);
    assert.match(text(tsNat.replace(/\.ts$/, '.d.ts')), /idNat\(x: bigint\): bigint/);
  });
  await test('independent TypeScript consumer validates DirectJS declarations and rejects wrong calls', () => {
    const consumer = source('consumer.ts', `import { idNat } from './lean/module.js';\nconst result: bigint = idNat(42n);\n// @ts-expect-error scalar ABI must reject a string\nidNat('wrong');\n// @ts-expect-error return is bigint, not number\nconst wrong: number = idNat(1n);\nvoid result; void wrong;\n`);
    ts7(['--strict', '--target', 'ES2022', '--module', 'ESNext', '--moduleResolution', 'Bundler', '--noEmit', consumer]);
  });
  await test('snapshot is not reread after admission across JS and TS emission', async () => {
    const input = output('snapshot.lean');
    const js = output('snapshot-js/module.js');
    const ts = output('snapshot-ts/module.ts');
    command(path.join(root, '.lake/build/bin/psc1_snapshot_tests'), [input, js, ts]);
    assert.match(text(input), /false/);
    assert.equal((await load(js)).answer, true);
    assert.match(json(js + '.map').sourcesContent[0], /true/);
    assert.match(json(ts + '.map').sourcesContent[0], /true/);
    assert.doesNotMatch(json(js + '.map').sourcesContent[0], /false/);
  });
  await test('Rust crate contains formatted source, exact direct pins and a usable locked dependency graph', () => {
    rustNat = build(nat, 'rust', 'rust/module.rs');
    const crate = rustNat.slice(0, -3) + '.cargo';
    assert.equal(text(rustNat), text(path.join(crate, 'src/lib.rs')));
    assert.match(text(path.join(crate, 'Cargo.toml')), /num-bigint = "=0\.4\.6"/);
    assert.match(text(path.join(crate, 'Cargo.lock')), /name = "num-bigint"/);
    // Never mutate a published immutable generation when adding a test harness.
    const harness = output('rust-harness');
    fs.cpSync(fs.realpathSync(crate), harness, { recursive: true });
    fs.mkdirSync(path.join(harness, 'tests'));
    fs.writeFileSync(path.join(harness, 'tests/runtime.rs'), 'use num_bigint::BigUint;\n#[test]\nfn generated_identity() {\n    let input = BigUint::from(42u32);\n    assert_eq!(psc1_generated::idNat(input.clone()), input);\n}\n');
    command('cargo', ['test', '--locked', '--manifest-path', path.join(harness, 'Cargo.toml')]);
    command('rustfmt', ['--edition', '2021', '--check', fs.realpathSync(rustNat)]);
  });
  await test('core Wasm and readable WAT roundtrip preserve executed Bool exports', async () => {
    coreBool = build(bool, 'wasm-core', 'wasm/module.wasm');
    const bytes = fs.readFileSync(coreBool);
    assert.equal(WebAssembly.validate(bytes), true);
    const { instance } = await WebAssembly.instantiate(bytes);
    assert.equal(instance.exports.answer(), 1);
    const wat = coreBool.slice(0, -5) + '.wat';
    assert.match(text(wat), /\(module/);
    const roundtrip = output('roundtrip.wasm');
    command('wasm-tools', ['parse', wat, '-o', roundtrip]);
    command('wasm-tools', ['validate', roundtrip]);
    assert.equal((await WebAssembly.instantiate(fs.readFileSync(roundtrip))).instance.exports.answer(), 1);
    const conversion = output('converted.wat');
    command(native, ['wat', coreBool, '--out', conversion]);
    assert.equal(text(conversion), text(wat));
  });
  await test('components contain exact WIT ABI, readable WAT and executable Bool parameters', () => {
    componentBool = build(bool, 'wasm-component', 'component/module.wasm', ['--export', 'answer']);
    assert.match(command('wasmtime', ['run', '--invoke', 'answer()', componentBool]), /true/);
    const wit = text(componentBool.slice(0, -5) + '.wit');
    assert.match(wit, /\n  export answer: func\(\) -> bool;/);
    const identity = source('idbool.ps', 'def idbool(b : Bool) : Bool := b\n');
    const component = build(identity, 'wasm-component', 'component-identity/module.wasm', ['--export', 'idbool']);
    assert.match(command('wasmtime', ['run', '--invoke', 'idbool(true)', component]), /true/);
    assert.match(command('wasmtime', ['run', '--invoke', 'idbool(false)', component]), /false/);
    const roundtrip = output('component-roundtrip.wasm');
    command('wasm-tools', ['parse', component.slice(0, -5) + '.wat', '-o', roundtrip]);
    command('wasm-tools', ['validate', roundtrip]);
    assert.match(command('wasmtime', ['run', '--invoke', 'idbool(false)', roundtrip]), /false/);
    const bad = output('unknown-component.wasm');
    reject(native, ['build', identity, '--target', 'wasm-component', '--export', 'unknown', '--out', bad]);
    assert.equal(fs.existsSync(bad), false);
    const unbounded = source('unbounded.lean', 'def count : Nat := 42\n');
    const refused = output('nat-component.wasm');
    reject(native, ['build', unbounded, '--target', 'wasm-component', '--export', 'count', '--out', refused]);
    assert.equal(fs.existsSync(refused), false);
  });
  const scalarCases = [
    ['UInt8', 'u8', ['0', '255']], ['UInt16', 'u16', ['0', '65535']],
    ['UInt32', 'u32', ['0', '4294967295']], ['UInt64', 'u64', ['0', '18446744073709551615']],
    ['Int8', 's8', ['-128', '127']], ['Int16', 's16', ['-32768', '32767']],
    ['Int32', 's32', ['-2147483648', '2147483647']],
    ['Int64', 's64', ['-9223372036854775808', '9223372036854775807']],
    ['Float32', 'f32', ['-1.25', '1.25']], ['Float', 'f64', ['-1.25', '1.25']]
  ];
  for (const [type, witType, values] of scalarCases) {
    await test(`advertised scalar component ABI ${witType} executes boundary identities`, () => {
      const input = source(`scalar-${witType}.lean`, `def identity (x : ${type}) : ${type} := x\n`);
      const file = build(input, 'wasm-component', `scalar-${witType}/module.wasm`, ['--export', 'identity']);
      assert.match(text(file.slice(0, -5) + '.wit'), new RegExp(`x: ${witType}\\) -> ${witType}`));
      for (const value of values) {
        const observed = command('wasmtime', ['run', '--invoke', `identity(${value})`, file]).trim();
        assert.ok(observed.includes(value), `${witType}: ${value} -> ${observed}`);
      }
    });
  }
  await test('repeat native and npm DirectJS builds produce identical readable bytes', () => {
    const repeated = build(nat, 'js', 'repeat/module.js');
    const npmOutput = output('npm/module.js');
    command(process.execPath, [path.join(root, 'npm-cli/psc.js'), 'build', nat, '--target', 'js', '--out', npmOutput], {
      env: { ...env, PSC1_NATIVE: native }
    });
    for (const [left, right] of [[jsNat, repeated], [jsNat, npmOutput], [jsNat + '.map', repeated + '.map'],
      [jsNat.replace(/\.js$/, '.d.ts'), repeated.replace(/\.js$/, '.d.ts')]]) {
      assert.equal(text(left), text(right));
    }
    assert.equal(json(jsNat + '.bundle.json').sourceClosureSha256, json(repeated + '.bundle.json').sourceClosureSha256);
  });
  await test('failure before publication retains all existing checked artifacts', async () => {
    const input = source('replacement.lean', 'def answer : Bool := true\n');
    const file = build(input, 'js', 'replacement/module.js');
    const before = fs.realpathSync(file);
    const companions = [file, file + '.map', file.replace(/\.js$/, '.d.ts'), file + '.bundle.json'];
    const beforeHashes = companions.map(hash);
    fs.writeFileSync(input, 'def answer : Bool := false\n');
    const message = reject(native, ['build', input, '--target', 'js', '--out', file], {
      env: { ...env, PSC1_TEST_PUBLICATION_FAIL_AT: 'before-commit' }
    });
    assert.match(message, /INJECTED_PUBLICATION_FAILURE/);
    assert.equal(fs.realpathSync(file), before);
    assert.deepEqual(companions.map(hash), beforeHashes);
    assert.equal((await load(file)).answer, true);
    command(native, ['build', input, '--target', 'js', '--out', file]);
    assert.equal((await load(file)).answer, false);
  });
  for (const [name, file] of [['javascript', jsNat], ['typescript', tsNat], ['rust', rustNat], ['wasm-core', coreBool], ['component', componentBool]]) {
    const bundle = path.dirname(fs.realpathSync(file + '.bundle.json'));
    fs.cpSync(bundle, path.join(evidence, name), { recursive: true });
  }
  console.log(`PSC1_SCOPED_BACKENDS: ${records.length} passed; full self-host tests not run`);
} finally {
  console.log(`PSC1_SCOPED_EVIDENCE: ${evidence}`);
}
