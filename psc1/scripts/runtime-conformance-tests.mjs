// Real target execution against the repository-pinned native Lean runtime.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-runtime-conformance-'));
const evidence = path.join(root, 'dist/scoped-correctness/runtime-conformance');
fs.mkdirSync(evidence, { recursive: true });
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const records = [];
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function run(command, args, options = {}) {
  const result = spawnSync(command, args, { env, encoding: 'utf8', timeout: 180000, ...options });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 0, command + ' ' + args.join(' ') + '\n' + result.stdout + result.stderr);
  return result.stdout;
}
const oracle = JSON.parse(run(path.join(root, '.lake/build/bin/psc1_runtime_oracle'), []));
assert.equal(oracle.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
fs.writeFileSync(path.join(evidence, 'lean-runtime-oracle.json'), JSON.stringify(oracle, null, 2) + '\n');
const n = key => oracle[key];
const eqNat = (expression, expected) => 'Nat.beq (' + expression + ') ' + expected;
const q = JSON.stringify;
const groups = {
  natcheck: [
    eqNat('Nat.add huge huge', n('largeAdd')),
    eqNat('Nat.mul huge 18446744073709551617', n('largeMul')),
    eqNat('Nat.sub 3 5', n('natSub')),
    eqNat('Nat.div huge 0', n('natDivZero')),
    eqNat('Nat.mod huge 0', n('natModZero')),
    eqNat('Nat.div 17 5', n('natDiv')),
    eqNat('Nat.mod 17 5', n('natMod'))
  ],
  intcheck: [
    '(Int.repr (Int.add (-7) (-13)) == ' + q(n('intAdd')) + ')',
    '(Int.repr (Int.mul (-7) 3) == ' + q(n('intMul')) + ')'
  ],
  unicodecheck: [
    eqNat('String.Internal.length text', n('stringLength')),
    eqNat('String.utf8ByteSize text', n('utf8Bytes')),
    eqNat('Char.toNat (String.Internal.get text 1)', n('getValid')),
    eqNat('Char.toNat (String.Internal.get text 2)', n('getMiddle')),
    eqNat('Char.toNat (String.Internal.get text 7)', n('getEnd')),
    eqNat('String.Internal.next text 1', n('nextValid')),
    eqNat('String.Internal.next text 2', n('nextMiddle')),
    eqNat('String.Internal.next text 7', n('nextEnd')),
    '(String.Internal.extract text 1 5 == ' + q(n('extractValid')) + ')',
    '(String.Internal.extract text 1 3 == ' + q(n('extractMiddle')) + ')',
    eqNat('Char.toNat (Char.ofNat 55296)', n('charSurrogate')),
    eqNat('Char.toNat (Char.ofNat 1114112)', n('charOutOfRange')),
    eqNat('Char.toNat (Char.ofNat 4294967361)', n('charLarge'))
  ],
  arraycheck: [
    'Nat.beq (Array.getD base 0 0) 7',
    'Nat.beq (Array.getD changed 0 0) 11',
    'Nat.beq (Array.getD changed huge 19) 19',
    'Nat.beq (Array.getD shifted 0 0) 12',
    'Nat.beq (Prod.fst pair) 41'
  ]
};
let source = '';
for (const [name, clauses] of Object.entries(groups)) {
  source += 'def ' + name + ' (flag : Bool) : Bool :=\n';
  source += ' let huge : Nat := ' + n('huge') + ';\n';
  if (name === 'unicodecheck') source += ' let text : String := "A😀é";\n';
  if (name === 'arraycheck') {
    source += ' let base : Array Nat := Array.push (Array.emptyWithCapacity 1) 7;\n' +
      ' let changed : Array Nat := Array.setIfInBounds base 0 11;\n' +
      ' let offset : Nat := 5;\n' +
      ' let shifted : Array Nat := Array.map (fun (value : Nat) => Nat.add value offset) base;\n' +
      ' let pair : Prod Nat Bool := Prod.mk 41 flag;\n';
  }
  source += ' (' + clauses.join(') &&\n (') + ') && (flag || !flag)\n';
}
source += 'def semantic (flag : Bool) : Bool := ' +
  Object.keys(groups).map(name => name + ' flag').join(' && ') + '\n';
const names = [...Object.keys(groups), 'semantic'];
const input = path.join(evidence, 'Runtime.lean');
fs.writeFileSync(input, source);
const translated = path.join(evidence, 'Runtime.ps');
run(native, ['translate', input, '--to', 'ps', '--out', translated]);
const targets = (process.env.PSC1_CONFORMANCE_TARGETS ||
  'js,ts,rust,wasm-core,wasm-component,python,php').split(',');
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');

try {
  for (const syntax of ['lean', 'ps']) {
    const entry = syntax === 'lean' ? input : translated;
    for (const target of targets) {
      const ext = { js: 'js', ts: 'ts', rust: 'rs', 'wasm-core': 'wasm',
        'wasm-component': 'wasm', python: 'py', php: 'php' }[target];
      assert.ok(ext, target);
      const folder = path.join(work, syntax + '-' + target);
      fs.mkdirSync(folder, { recursive: true });
      const output = path.join(folder, 'module.' + ext);
      const args = ['build', entry, '--target', target];
      if (target === 'wasm-component') args.push('--export', 'semantic');
      args.push('--out', output);
      run(native, args);
      const manifest = JSON.parse(fs.readFileSync(output + '.bundle.json', 'utf8'));
      assert.equal(manifest.logicalCheckerCommit, oracle.leanCommit);
      assert.equal(manifest.runtimeContract, 'psc1-runtime-semantics/1');
      const selected = target === 'wasm-component' ? ['semantic'] : names;
      assert.deepEqual([...manifest.publicNames].sort(), [...selected].sort());
      let values;
      if (target === 'js' || target === 'ts') {
        let moduleFile = output;
        if (target === 'ts') {
          const consumer = path.join(folder, 'consumer');
          run(process.execPath, [process.env.PSC1_TSC, '--ignoreConfig', output, '--strict',
            '--target', 'ES2022', '--module', 'ES2022', '--skipLibCheck', '--outDir', consumer]);
          moduleFile = path.join(consumer, 'module.js');
        }
        const module = await import(pathToFileURL(moduleFile).href);
        values = names.map(name => [name, module[name](false), module[name](true)]);
      } else if (target === 'rust') {
        const crate = path.join(folder, 'consumer');
        fs.cpSync(fs.realpathSync(output.replace(/\.rs$/, '.cargo')), crate,
          { recursive: true, dereference: true });
        fs.appendFileSync(path.join(crate, 'src/lib.rs'),
          '\n#[cfg(test)] mod runtime_contract { use super::*; #[test] fn pinned_lean_results() {\n' +
          names.map(name => 'assert!(' + name + '(false)); assert!(' + name + '(true));').join('\n') +
          '\n} }\n');
        run('cargo', ['test', '--locked', '--manifest-path', path.join(crate, 'Cargo.toml')],
          { env: { ...env, CARGO_TARGET_DIR: path.join(work, 'cargo-target') } });
        values = names.map(name => [name, true, true]);
      } else if (target === 'wasm-core') {
        const { instance } = await WebAssembly.instantiate(fs.readFileSync(output));
        values = names.map(name => [name, Boolean(instance.exports[name](0)),
          Boolean(instance.exports[name](1))]);
      } else if (target === 'wasm-component') {
        values = [['semantic',
          run('wasmtime', ['run', '--invoke', 'semantic(false)', output]).trim() === 'true',
          run('wasmtime', ['run', '--invoke', 'semantic(true)', output]).trim() === 'true']];
      } else if (target === 'python') {
        const program = 'import importlib.util,json,sys\n' +
          'spec=importlib.util.spec_from_file_location("psc1_output",sys.argv[1])\n' +
          'module=importlib.util.module_from_spec(spec)\nspec.loader.exec_module(module)\n' +
          'names=json.loads(sys.argv[2])\n' +
          'print(json.dumps([[n,getattr(module,n)(False),getattr(module,n)(True)] for n in names]))\n';
        values = JSON.parse(run(process.env.PSC1_PYTHON || 'python3',
          ['-I', '-c', program, output, JSON.stringify(names)]));
      } else {
        const program = '$api = require $argv[1]; $names = json_decode($argv[2], true); $values = []; ' +
          'foreach ($names as $name) { $values[] = [$name, $api[$name](false), $api[$name](true)]; } ' +
          'echo json_encode($values, JSON_THROW_ON_ERROR);';
        values = JSON.parse(run(process.env.PSC1_PHP || 'php',
          ['-r', program, output, JSON.stringify(names)]));
      }
      for (const [name, no, yes] of values) {
        assert.equal(no, true, syntax + '/' + target + '/' + name + '(false)');
        assert.equal(yes, true, syntax + '/' + target + '/' + name + '(true)');
      }
      const destination = path.join(evidence, syntax + '-' + target);
      fs.cpSync(path.dirname(fs.realpathSync(output + '.bundle.json')), destination, { recursive: true });
      records.push({ syntax, target, passed: true, checks: values, sourceBytes: fs.statSync(output).size,
        runtime: manifest.targetPlans[0], generation: path.basename(path.dirname(fs.realpathSync(output))),
        publicNames: manifest.publicNames });
      console.log('PSC1_RUNTIME_CONFORMANCE_PASS: ' + syntax + '/' + target);
    }
  }
} finally {
  fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify({
    schema: 'psc1-runtime-conformance/1', commit: process.env.GITHUB_SHA || null,
    nativeLean: { version: oracle.leanVersion, commit: oracle.leanCommit },
    oracleSha256: sha(JSON.stringify(oracle)), node: process.version,
    targetCount: targets.length, records
  }, null, 2) + '\n');
  fs.rmSync(work, { recursive: true, force: true });
}
