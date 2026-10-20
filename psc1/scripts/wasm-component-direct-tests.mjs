// Focused direct component conformance. No compiler/kernel self-host tests.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-component-direct-'));
const trace = path.join(work, 'tools.jsonl');
const toolLookup = spawnSync('which', ['wasm-tools'], { encoding: 'utf8' });
assert.equal(toolLookup.status, 0, 'qualified wasm-tools must exist');
const actualTool = toolLookup.stdout.trim();
assert.ok(path.isAbsolute(actualTool));
const bin = path.join(work, 'bin');
fs.mkdirSync(bin);
fs.writeFileSync(path.join(bin, 'wasm-tools'), [
  '#!/usr/bin/env node',
  "const fs = require('node:fs');",
  "const { spawnSync } = require('node:child_process');",
  'const args = process.argv.slice(2);',
  "fs.appendFileSync(process.env.PSC1_COMPONENT_TRACE, JSON.stringify(args) + '\\n');",
  "if (args[0] === 'component' && ['embed', 'new'].includes(args[1])) {",
  "  process.stderr.write('PSC1_TEST_EXTERNAL_COMPONENT_ENCODER_FORBIDDEN\\n');",
  '  process.exit(77);',
  '}',
  "const result = spawnSync(process.env.PSC1_COMPONENT_REAL_TOOL, args, { stdio: 'inherit' });",
  'if (result.error) throw result.error;',
  'process.exit(result.status ?? 1);',
  '',
].join('\n'), { mode: 0o755 });
const env = { ...process.env, PATH: bin + path.delimiter + process.env.PATH,
  PSC1_COMPONENT_TRACE: trace, PSC1_COMPONENT_REAL_TOOL: actualTool,
  PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };

function run(command, args, success = true) {
  const result = spawnSync(command, args, { cwd: root, env, encoding: 'utf8',
    timeout: 120_000, maxBuffer: 64 * 1024 * 1024 });
  if (result.error) throw result.error;
  assert.equal(result.signal, null, 'must finish without timeout/signal');
  if (success) assert.equal(result.status, 0,
    command + ' ' + args.join(' ') + '\n' + result.stdout + '\n' + result.stderr);
  else assert.notEqual(result.status, 0, 'expected a normal refusal');
  return result.stdout + '\n' + result.stderr;
}
function embeddedCore(bytes) {
  let offset = 8;
  function leb() {
    let value = 0, scale = 1;
    for (let i = 0; i < 5; i++) {
      assert.ok(offset < bytes.length, 'complete section length');
      const byte = bytes[offset++];
      value += (byte & 127) * scale;
      if (!(byte & 128)) return value;
      scale *= 128;
    }
    throw new Error('invalid u32 section length');
  }
  const modules = [];
  while (offset < bytes.length) {
    const id = bytes[offset++], size = leb(), end = offset + size;
    assert.ok(end <= bytes.length, 'section within component');
    if (id === 1) modules.push(bytes.subarray(offset, end));
    offset = end;
  }
  assert.equal(modules.length, 1, 'one exact embedded implementation');
  return modules[0];
}
const results = [];
for (const syntax of ['lean', 'ps']) {
  const source = path.join(work, 'identity.' + syntax);
  fs.writeFileSync(source, syntax === 'lean'
    ? 'def identity (value : Bool) : Bool := value\n'
    : 'def identity(value : Bool) : Bool := value\n');
  const output = path.join(work, syntax, 'module.wasm');
  const build = () => run(native, ['build', source, '--target', 'wasm-component',
    '--export', 'identity', '--out', output]);
  build();
  const bytes = fs.readFileSync(output);
  assert.deepEqual(bytes.subarray(0, 8), Buffer.from([0, 97, 115, 109, 13, 0, 1, 0]));
  assert.deepEqual(embeddedCore(bytes), fs.readFileSync(output.slice(0, -5) + '.core.wasm'));
  assert.match(run('wasmtime', ['run', '--invoke', 'identity(true)', output]), /true/);
  assert.match(run('wasmtime', ['run', '--invoke', 'identity(false)', output]), /false/);
  const assembled = path.join(work, syntax + '-reassembled.wasm');
  run(actualTool, ['parse', output.slice(0, -5) + '.wat', '-o', assembled]);
  run(actualTool, ['validate', assembled]);
  assert.match(run('wasmtime', ['run', '--invoke', 'identity(false)', assembled]), /false/);
  build();
  assert.deepEqual(fs.readFileSync(output), bytes, 'deterministic direct component');
  const priorPointer = fs.realpathSync(output);
  const priorManifest = fs.readFileSync(output + '.bundle.json');
  fs.writeFileSync(source, syntax === 'lean'
    ? 'def identity (value : Nat) : Nat := value\n'
    : 'def identity(value : Nat) : Nat := value\n');
  assert.match(run(native, ['build', source, '--target', 'wasm-component',
    '--export', 'identity', '--out', output], false), /PSC1_COMPONENT_WIT_TYPE_UNSUPPORTED/);
  assert.equal(fs.realpathSync(output), priorPointer, 'refusal preserves generation');
  assert.deepEqual(fs.readFileSync(output + '.bundle.json'), priorManifest);
  assert.deepEqual(fs.readFileSync(output), bytes);
  results.push({ syntax, status: 'pass', directEncoding: true,
    exactEmbeddedCore: true, deterministic: true, refusalPreservesGeneration: true });
}
const calls = fs.readFileSync(trace, 'utf8').trim().split('\n').map(line => JSON.parse(line));
assert.ok(calls.some(args => args[0] === 'validate'));
assert.ok(calls.some(args => args[0] === 'component' && args[1] === 'wit'));
assert.ok(!calls.some(args => args[0] === 'component' && ['embed', 'new'].includes(args[1])));
const evidence = path.join(root, 'dist/scoped-correctness/wasm-component-direct.json');
fs.mkdirSync(path.dirname(evidence), { recursive: true });
fs.writeFileSync(evidence, JSON.stringify({ schema: 'psc1-direct-component-foundation/1',
  sourceCommit: process.env.GITHUB_SHA || null, fullSelfHostTests: false, results }, null, 2) + '\n');
console.log('PSC1_COMPONENT_DIRECT: both grammars passed direct encoding, embedded core, execution, WAT, determinism and refusal checks');
