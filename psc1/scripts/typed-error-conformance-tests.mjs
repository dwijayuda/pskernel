// Exact shared fixture bodies run under native Lean and all seven direct targets.
// No target result is used as another target's oracle. Failure remains fatal.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-typed-errors-'));
const evidence = path.join(root, 'dist/scoped-correctness', process.env.PSC1_ERROR_EVIDENCE || 'typed-errors');
fs.mkdirSync(evidence, { recursive: true });
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const targets = (process.env.PSC1_ERROR_TARGETS || 'js,ts,rust,wasm-core,wasm-component,python,php').split(',');
assert.ok(targets.length && targets.every(t => ['js','ts','rust','wasm-core','wasm-component','python','php'].includes(t)));
const records = [], failures = [];
const read = file => fs.readFileSync(file, 'utf8');
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
function run(cmd, args, options = {}) {
  const deadline = options.timeout ?? 120000;
  const result = spawnSync('timeout', ['--kill-after=5s', Math.ceil(deadline / 1000) + 's', cmd, ...args],
    { env, encoding: 'utf8', cwd: root, maxBuffer: 32 * 1024 * 1024, ...options, timeout: deadline + 10000 });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 0, cmd + ' ' + args.join(' ') + '\n' + result.stdout + result.stderr);
  return result.stdout;
}
function reject(args) {
  const result = spawnSync(native, args, { env, encoding: 'utf8', cwd: root, timeout: 60000 });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.signal, null);
  assert.notEqual(result.status, 0, 'unexpected acceptance: ' + args.join(' '));
  assert.match(result.stdout + result.stderr, /PSC1_|PSC2_/);
  return result.stdout + result.stderr;
}
function write(file, text) { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, text); }
const oracle = JSON.parse(run(path.join(root, '.lake/build/bin/psc1_typed_error_oracle'), []));
assert.equal(oracle.leanVersion, '4.35.0');
assert.equal(oracle.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
write(path.join(evidence, 'native-oracle.json'), JSON.stringify(oracle, null, 2) + '\n');
const cases = ['errorCaught','errorUncaught','errorAfter','errorEarly','errorTerminal',
  'errorNested','errorHandlerRethrow','errorShadow','errorCapture','errorFor','errorForReturn',
  'errorNestedDo','errorBoundThrow','errorThrowShadow','errorResultPayload'];
assert.equal(Object.keys(oracle).length, (cases.length + 1) * 2 + 2);
function entry(moduleName, names) {
  const definitions = names.map((name, index) => {
    const no = oracle[name + 'False'], yes = oracle[name + 'True'];
    assert.equal(typeof no.error, 'boolean'); assert.equal(typeof yes.error, 'boolean');
    assert.match(no.value, /^\d+$/); assert.match(yes.value, /^\d+$/);
    const tag = '(if flag then ' + yes.error + ' else ' + no.error + ')';
    const value = '(if flag then ' + yes.value + ' else ' + no.value + ')';
    return 'def typedcase' + index + ' (flag : Bool) : Bool :=\n' +
      ' match ' + name + ' flag with\n' +
      ' | Except.error actual => ' + tag + ' && Nat.beq actual ' + value + '\n' +
      ' | Except.ok actual => (!' + tag + ') && Nat.beq actual ' + value + '\n';
  });
  return 'import ' + moduleName + '\n' + definitions.join('\n') +
    '\ndef semantic (flag : Bool) : Bool := ' + names.map((_, i) => '(typedcase' + i + ' flag)').join(' && ') + '\n';
}
function execute(target, output) {
  if (target === 'js' || target === 'ts') {
    let js = output;
    if (target === 'ts') {
      assert.ok(process.env.PSC1_TSC, 'independent pinned TypeScript compiler required');
      const out = path.join(path.dirname(output), 'consumer');
      run(process.execPath, [process.env.PSC1_TSC, '--ignoreConfig', '--strict', '--target', 'ES2022',
        '--module', 'ESNext', '--moduleResolution', 'Bundler', '--outDir', out, fs.realpathSync(output)]);
      write(path.join(out, 'package.json'), '{"type":"module"}\n');
      js = path.join(out, 'module.js');
    }
    run(process.execPath, ['--input-type=module', '-e',
      'import assert from "node:assert/strict"; const m=await import(' + JSON.stringify(pathToFileURL(fs.realpathSync(js)).href) +
      '); for(const name of Object.keys(m)){assert.equal(m[name](false),true,name); assert.equal(m[name](true),true,name);}']);
  } else if (target === 'rust') {
    const crate = path.join(path.dirname(output), 'consumer');
    fs.cpSync(fs.realpathSync(output.replace(/\.rs$/, '.cargo')), crate, { recursive: true, dereference: true });
    write(path.join(crate, 'tests/typed_errors.rs'),
      '#[test] fn typed_error_contract() { assert!(psc1_generated::semantic(false)); assert!(psc1_generated::semantic(true)); }\n');
    run('cargo', ['test', '--locked', '--manifest-path', path.join(crate, 'Cargo.toml')],
      { env: { ...env, CARGO_TARGET_DIR: path.join(work, 'cargo-target') } });
  } else if (target === 'wasm-core') {
    run(process.execPath, ['--input-type=module', '-e',
      'import fs from "node:fs"; import assert from "node:assert/strict"; const {instance}=await WebAssembly.instantiate(fs.readFileSync(' +
      JSON.stringify(output) + ')); for(const name of Object.keys(instance.exports)){assert.equal(instance.exports[name](0),1,name); assert.equal(instance.exports[name](1),1,name);}']);
  } else if (target === 'wasm-component') {
    for (const flag of ['false','true']) {
      assert.equal(run('wasmtime', ['run', '--invoke', 'semantic(' + flag + ')', output]).trim(), 'true');
    }
  } else if (target === 'python') {
    run(process.env.PSC1_PYTHON || 'python3', ['-I', '-c',
      'import importlib.util,sys\ns=importlib.util.spec_from_file_location("typed_errors",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)\nfor name in m.__all__:\n f=getattr(m,name);assert f(False) is True,name;assert f(True) is True,name\n', output]);
  } else {
    run(process.env.PSC1_PHP || 'php', ['-d', 'memory_limit=1G', '-r',
      '$m=require $argv[1]; foreach($m as $name=>$f){if($f(false)!==true || $f(true)!==true){fwrite(STDERR,$name);exit(1);}}', output]);
  }
}

try {
  for (const lane of [{ name: 'checked', module: 'TypedErrorFixtures', names: cases },
      { name: 'ordinary', module: 'TypedErrorWhileFixture', names: ['errorWhile'] }]) {
    const leanFolder = path.join(evidence, 'sources', lane.name, 'lean');
    const fixture = path.join(root, 'test', lane.module + '.lean');
    const leanLibrary = path.join(leanFolder, lane.module + '.lean');
    write(leanLibrary, read(fixture));
    assert.equal(hash(leanLibrary), hash(fixture));
    write(path.join(leanFolder, 'Entry.lean'), entry(lane.module, lane.names));
    write(path.join(leanFolder, 'Wrong.lean'),
      'def semantic (flag : Bool) : Bool := true\ndef invalid : Except Nat Nat := do { try { throw true } catch error => { return error } }\n');
    for (const syntax of ['lean','ps']) {
      const folder = path.join(evidence, 'sources', lane.name, syntax);
      if (syntax === 'ps') {
        fs.mkdirSync(folder, { recursive: true });
        for (const name of [lane.module, 'Entry', 'Wrong']) run(native, ['translate',
          path.join(leanFolder, name + '.lean'), '--to', 'ps', '--out', path.join(folder, name + '.ps')]);
      }
      for (const target of targets) {
        const record = { lane: lane.name, syntax, target, passed: false, observations: lane.names.length * 2 };
        const label = lane.name + '-' + syntax + '-' + target;
        const extension = {js:'js',ts:'ts',rust:'rs','wasm-core':'wasm','wasm-component':'wasm',python:'py',php:'php'}[target];
        const output = path.join(work, label, 'module.' + extension);
        const args = ['build', path.join(folder, 'Entry.' + syntax), '--target', target, '--out', output];
        if (lane.name === 'ordinary') args.push('--assurance', 'ordinary');
        if (target === 'wasm-component') args.push('--export', 'semantic');
        try {
          run(native, args);
          const manifest = JSON.parse(read(output + '.bundle.json'));
          assert.equal(manifest.logicalCheckerCommit, oracle.leanCommit);
          assert.equal(manifest.behaviorallyVerified, false);
          assert.equal(manifest.runtimeContract, 'psc1-runtime-semantics/1');
          if (lane.name === 'ordinary') assert.equal(manifest.assurance, 'ordinary-checked');
          execute(target, output);
          const before = hash(output + '.bundle.json');
          const generation = fs.realpathSync(output + '.bundle.json');
          const verifiedArgs = args.filter((v, i) => v !== '--assurance' && args[i-1] !== '--assurance');
          reject([...verifiedArgs, '--assurance', 'verified']);
          const wrong = [...args]; wrong[1] = path.join(folder, 'Wrong.' + syntax);
          reject(wrong);
          if (lane.name === 'ordinary') reject(verifiedArgs);
          assert.equal(hash(output + '.bundle.json'), before);
          assert.equal(fs.realpathSync(output + '.bundle.json'), generation);
          record.passed = true;
          record.refusals = lane.name === 'ordinary' ? 3 : 2;
          record.fixtureSha256 = hash(fixture);
          record.artifactSha256 = hash(output);
          record.sourceBytes = fs.statSync(output).size;
          console.log('PSC1_TYPED_ERROR_TARGET_PASS: ' + label);
        } catch (error) {
          record.error = error.stack || String(error);
          failures.push(label);
          console.error('PSC1_TYPED_ERROR_TARGET_FAIL: ' + label + '\n' + record.error);
        } finally {
          if (fs.existsSync(output + '.bundle.json')) fs.cpSync(path.dirname(fs.realpathSync(output + '.bundle.json')),
            path.join(evidence, 'bundles', label), { recursive: true });
          records.push(record);
        }
      }
    }
  }
  assert.deepEqual(failures, [], 'typed-error target failures');
  assert.equal(records.length, targets.length * 4);
  console.log('PSC1_TYPED_ERROR_CONFORMANCE: PASS ' + records.length + ' bundles, ' +
    records.reduce((n,r) => n + r.refusals, 0) + ' publication/assurance refusals');
} finally {
  write(path.join(evidence, 'results.json'), JSON.stringify({ schema: 'psc1-typed-error-execution/1',
    testedCommit: process.env.GITHUB_SHA || null, branchHeadCommit: process.env.PSC1_HEAD_SHA || null,
    leanVersion: oracle.leanVersion, leanCommit: oracle.leanCommit,
    nativeObservations: Object.keys(oracle).length - 2, targets, records, failures,
    passed: failures.length === 0 && records.length === targets.length * 4 }, null, 2) + '\n');
  fs.rmSync(work, { recursive: true, force: true });
}
