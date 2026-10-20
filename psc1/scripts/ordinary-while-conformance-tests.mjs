// Ordinary while execution evidence against the pinned native Lean runtime.
// This suite does not claim behavioral verification or a termination proof.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-ordinary-while-'));
const evidence = path.join(root, 'dist/scoped-correctness',
  process.env.PSC1_WHILE_EVIDENCE || 'ordinary-while-conformance');
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const targets = (process.env.PSC1_CONFORMANCE_TARGETS ||
  'js,ts,rust,wasm-core,wasm-component,python,php').split(',');
const records = [];
const divergence = [];
const rejections = [];
const failures = [];
const read = file => fs.readFileSync(file, 'utf8');
const json = file => JSON.parse(read(file));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const hash = file => sha(fs.readFileSync(file));
fs.mkdirSync(evidence, { recursive: true });
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');

function invoke(command, args, options = {}) {
  const deadline = options.timeout ?? 180000;
  return spawnSync('timeout', ['--kill-after=5s', Math.ceil(deadline / 1000) + 's', command, ...args],
    { cwd: root, env, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024,
      ...options, timeout: deadline + 10000 });
}
function run(command, args, options = {}) {
  const result = invoke(command, args, options);
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 0, command + ' ' + args.join(' ') + '\n' + result.stdout + result.stderr);
  return result.stdout;
}
function reject(name, syntax, args, pattern) {
  const result = invoke(native, args);
  assert.equal(result.error, undefined, result.error?.message);
  assert.notEqual(result.status, 0, name + ': unexpected acceptance');
  assert.notEqual(result.status, 124, name + ': compiler timed out');
  const diagnostic = result.stdout + '\n' + result.stderr;
  assert.match(diagnostic, pattern, name);
  rejections.push({ name, syntax, passed: true, diagnostic });
}
function recordFailure(phase, syntax, target, error) {
  const detail = error.stack || String(error);
  const failure = { phase, syntax, target, error: detail };
  failures.push(failure);
  console.error('PSC1_WHILE_FAILURE: ' + phase + '/' + syntax + '/' + target + '\n' + detail);
  return failure;
}
function externalTimeout(command, args) {
  const result = invoke(command, args, { timeout: 2000 });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 124,
    'divergence must reach the external deadline, not return or fail by stack/fuel: ' +
    command + '\n' + result.stdout + result.stderr);
  return { externalTimeoutMs: 2000, exitCode: result.status };
}
function source(folder, name, text) {
  const file = path.join(folder, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
  return file;
}
function conjoin(clauses) {
  if (clauses.length === 1) return '(' + clauses[0] + ')';
  const middle = Math.floor(clauses.length / 2);
  return '(' + conjoin(clauses.slice(0, middle)) + ' && ' + conjoin(clauses.slice(middle)) + ')';
}
const oracle = JSON.parse(run(path.join(root, '.lake/build/bin/psc1_runtime_oracle'), []));
assert.equal(oracle.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
const n = key => {
  assert.ok(Object.hasOwn(oracle, key), 'missing native Lean observation: ' + key);
  return oracle[key];
};
const choice = stem => '(if flag then ' + n(stem + 'True') + ' else ' + n(stem + 'False') + ')';
fs.writeFileSync(path.join(evidence, 'lean-runtime-oracle.json'), JSON.stringify(oracle, null, 2) + '\n');
console.log('PSC1_WHILE_NATIVE_ORACLE: ' + JSON.stringify(Object.fromEntries(
  Object.entries(oracle).filter(([key]) => key.startsWith('while')))));

const loopsSource = `partial def whileFalse (flag : Bool) : Id Nat := do
  let mut value : Nat := if flag then 7 else 9
  while false do
    value := 99
  return value
partial def whileCount (flag : Bool) : Id Nat := do
  let limit : Nat := if flag then 100000 else 0
  let mut index : Nat := 0
  let mut total : Nat := 7
  while !(Nat.beq index limit) do
    total := total + 1
    index := index + 1
  return total
partial def whileEarly (flag : Bool) : Id Nat := do
  let mut index : Nat := 0
  let mut total : Nat := 3
  while !(Nat.beq index 100000) do
    if flag && Nat.beq index 7 then
      return total
    total := total + 2
    index := index + 1
  return total
partial def whileCapture (flag : Bool) : Id Nat := do
  let mut value : Nat := if flag then 3 else 5
  let captured : Nat -> Nat := fun (n : Nat) => value + n
  let mut steps : Nat := 0
  while !(Nat.beq steps 3) do
    value := value + 10
    steps := steps + 1
  return captured value + steps
partial def whileSequential (flag : Bool) : Id Nat := do
  let mut value : Nat := if flag then 2 else 1
  let mut index : Nat := 0
  while !(Nat.beq index 3) do
    value := value * 10 + index
    index := index + 1
  let mut tail : Nat := 0
  while !(Nat.beq tail 2) do
    value := value + 7
    tail := tail + 1
  return value
partial def whileFor (flag : Bool) : Id Nat := do
  let bounds : List Nat := List.cons (if flag then 2 else 0) (List.cons 3 List.nil)
  let mut total : Nat := 0
  for upper in bounds do
    let mut index : Nat := 0
    while !(Nat.beq index upper) do
      total := total + 1
      index := index + 1
  return total
partial def whileExcept (flag : Bool) : Except Nat Nat := do
  let mut index : Nat := 0
  let mut total : Nat := 7
  while !(Nat.beq index 3) do
    total := total + index
    if flag && Nat.beq index 1 then
      let ignored : Unit <- Except.error total
      total := 999
    index := index + 1
  return total
`;
const cases = [
  ['whilefalsecheck', 'whileFalse'], ['whilecountcheck', 'whileCount'],
  ['whileearlycheck', 'whileEarly'], ['whilecapturecheck', 'whileCapture'],
  ['whilesequentialcheck', 'whileSequential'], ['whileforcheck', 'whileFor']
];
let entrySource = 'import Loops\n';
for (const [name, implementation] of cases) {
  entrySource += 'def ' + name + ' (flag : Bool) : Bool := Nat.beq (Id.run (' +
    implementation + ' flag)) ' + choice(implementation) + '\n';
}
const errorValue = '(if flag then ' + n('whileExceptTrueValue') + ' else ' + n('whileExceptFalseValue') + ')';
const errorTag = '(if flag then ' + n('whileExceptTrueTag') + ' else ' + n('whileExceptFalseTag') + ')';
entrySource += 'def whileexceptcheck (flag : Bool) : Bool :=\n' +
  ' match whileExcept flag with\n' +
  '  | Except.error value => Nat.beq value ' + errorValue + ' && ' + errorTag + '\n' +
  '  | Except.ok value => Nat.beq value ' + errorValue + ' && !' + errorTag + '\n';
const checks = [...cases.map(([name]) => name), 'whileexceptcheck'];
const names = [...checks, 'semantic'];
entrySource += 'def semantic (flag : Bool) : Bool := ' + conjoin(checks.map(name => name + ' flag')) + '\n';
const divergenceSource = `partial def endless (flag : Bool) : Id Bool := do
  while true do
    ()
  return false
`;
const spinSource = `import Divergence
partial def spin (flag : Bool) : Id Bool := do
  while true do
    if flag then
      return true
    let unused : Bool := Id.run (endless flag)
    if !flag then
      return true
  return Id.run (endless flag)
`;

function build(input, target, syntax, kind, publicNames) {
  const ext = { js: 'js', ts: 'ts', rust: 'rs', 'wasm-core': 'wasm',
    'wasm-component': 'wasm', python: 'py', php: 'php' }[target];
  assert.ok(ext, target);
  const folder = path.join(work, syntax + '-' + target + '-' + kind);
  fs.mkdirSync(folder, { recursive: true });
  const output = path.join(folder, 'module.' + ext);
  const args = ['build', input, '--assurance', 'ordinary', '--target', target];
  if (target === 'wasm-component') args.push('--export', publicNames[0]);
  args.push('--out', output);
  run(native, args);
  const manifest = json(output + '.bundle.json');
  assert.equal(manifest.assurance, 'ordinary-checked');
  assert.equal(manifest.behaviorallyVerified, false);
  assert.equal(manifest.logicalCheckerCommit, oracle.leanCommit);
  assert.equal(manifest.runtimeContract, 'psc1-runtime-semantics/1');
  assert.ok(manifest.partialDeclarations.length > 0);
  assert.deepEqual([...manifest.publicNames].sort(), [...publicNames].sort());
  assert.ok(manifest.publicNames.every(name => !name.includes('_psc1WhileBody')));
  const generation = path.dirname(fs.realpathSync(output + '.bundle.json'));
  assert.match(read(path.join(generation, 'admissions.json')), /_psc1WhileBody/);
  fs.cpSync(generation, path.join(evidence, syntax + '-' + target + '-' + kind), { recursive: true });
  return { output, folder, manifest, artifactSha256: hash(output), manifestSha256: hash(output + '.bundle.json') };
}
function ecmaModule(artifact, target) {
  if (target === 'js') return artifact.output;
  assert.ok(process.env.PSC1_TSC && fs.existsSync(process.env.PSC1_TSC), 'pinned TypeScript checker required');
  const consumer = path.join(artifact.folder, 'consumer');
  run(process.execPath, [process.env.PSC1_TSC, '--ignoreConfig', artifact.output, '--strict',
    '--target', 'ES2022', '--module', 'ES2022', '--skipLibCheck', '--outDir', consumer]);
  return path.join(consumer, 'module.js');
}
function rustCrate(artifact) {
  const crate = path.join(artifact.folder, 'consumer');
  fs.cpSync(fs.realpathSync(artifact.output.replace(/\.rs$/, '.cargo')), crate,
    { recursive: true, dereference: true });
  fs.chmodSync(path.join(crate, 'src/lib.rs'), 0o644);
  return crate;
}
const cargoEnv = { ...env, CARGO_TARGET_DIR: path.join(work, 'cargo-target') };

function executeFinite(artifact, target) {
  if (target === 'js' || target === 'ts') {
    const moduleFile = ecmaModule(artifact, target);
    const program = 'import {pathToFileURL} from "node:url"; ' +
      'const module=await import(pathToFileURL(process.argv[1]).href); ' +
      'const names=JSON.parse(process.argv[2]); ' +
      'console.log(JSON.stringify(names.map(name=>[name,module[name](false),module[name](true)])));';
    return JSON.parse(run(process.execPath, ['--input-type=module', '-e', program,
      moduleFile, JSON.stringify(names)], { timeout: 60000 }));
  }
  if (target === 'rust') {
    const crate = rustCrate(artifact);
    fs.appendFileSync(path.join(crate, 'src/lib.rs'),
      '\n#[cfg(test)] mod ordinary_while_results { use super::*; #[test] fn native_lean_results() {\n' +
      names.map(name => 'assert!(' + name + '(false)); assert!(' + name + '(true));').join('\n') +
      '\n} }\n');
    run('cargo', ['test', '--locked', '--manifest-path', path.join(crate, 'Cargo.toml')], { env: cargoEnv });
    return names.map(name => [name, true, true]);
  }
  if (target === 'wasm-core') {
    const program = 'import fs from "node:fs"; ' +
      'const {instance}=await WebAssembly.instantiate(fs.readFileSync(process.argv[1])); ' +
      'const names=JSON.parse(process.argv[2]); ' +
      'console.log(JSON.stringify(names.map(name=>[name,instance.exports[name](0)===1,instance.exports[name](1)===1])));';
    return JSON.parse(run(process.execPath, ['--input-type=module', '-e', program,
      artifact.output, JSON.stringify(names)], { timeout: 60000 }));
  }
  if (target === 'wasm-component') {
    return [['semantic',
      run('wasmtime', ['run', '--invoke', 'semantic(false)', artifact.output]).trim() === 'true',
      run('wasmtime', ['run', '--invoke', 'semantic(true)', artifact.output]).trim() === 'true']];
  }
  if (target === 'python') {
    const program = 'import importlib.util,json,sys\n' +
      'spec=importlib.util.spec_from_file_location("psc1_output",sys.argv[1])\n' +
      'module=importlib.util.module_from_spec(spec)\nspec.loader.exec_module(module)\n' +
      'names=json.loads(sys.argv[2])\n' +
      'print(json.dumps([[n,getattr(module,n)(False),getattr(module,n)(True)] for n in names]))\n';
    return JSON.parse(run(process.env.PSC1_PYTHON || 'python3',
      ['-I', '-c', program, artifact.output, JSON.stringify(names)], { timeout: 60000 }));
  }
  const program = '$api = require $argv[1]; $names = json_decode($argv[2], true); $values = []; ' +
    'foreach ($names as $name) { $values[] = [$name, $api[$name](false), $api[$name](true)]; } ' +
    'echo json_encode($values, JSON_THROW_ON_ERROR);';
  return JSON.parse(run(process.env.PSC1_PHP || 'php',
    ['-d', 'memory_limit=1G', '-r', program, artifact.output, JSON.stringify(names)], { timeout: 60000 }));
}

function executeDivergence(artifact, target) {
  if (target === 'js' || target === 'ts') {
    const moduleFile = ecmaModule(artifact, target);
    const program = 'import {pathToFileURL} from "node:url"; ' +
      'const module=await import(pathToFileURL(process.argv[1]).href); ' +
      'const flag=process.argv[2]==="true"; ' +
      'if(module.spin(flag)!==true) throw new Error("spin result mismatch"); ' +
      'if(!flag) throw new Error("divergence returned");';
    const args = ['--input-type=module', '-e', program, moduleFile];
    run(process.execPath, [...args, 'true']);
    return externalTimeout(process.execPath, [...args, 'false']);
  }
  if (target === 'rust') {
    const crate = rustCrate(artifact);
    fs.appendFileSync(path.join(crate, 'src/lib.rs'),
      '\n#[cfg(test)] mod ordinary_while_divergence { use super::*;\n' +
      '#[test] fn terminating_path() { assert!(spin(true)); }\n' +
      '#[test] fn infinite_path() { spin(false); panic!("divergence returned"); }\n}\n');
    const messages = run('cargo', ['test', '--locked', '--no-run', '--message-format=json',
      '--manifest-path', path.join(crate, 'Cargo.toml')], { env: cargoEnv });
    const executables = messages.trim().split('\n').filter(Boolean).map(line => JSON.parse(line))
      .filter(value => value.reason === 'compiler-artifact' && value.profile?.test && value.executable)
      .map(value => value.executable);
    assert.equal(executables.length, 1, 'one precompiled Rust test executable required');
    const executable = executables[0];
    const preflight = run(executable, ['--exact', 'ordinary_while_divergence::terminating_path', '--nocapture']);
    assert.match(preflight, /1 passed/);
    return externalTimeout(executable, ['--exact', 'ordinary_while_divergence::infinite_path', '--nocapture']);
  }
  if (target === 'wasm-core') {
    const program = 'import fs from "node:fs"; ' +
      'const {instance}=await WebAssembly.instantiate(fs.readFileSync(process.argv[1])); ' +
      'const flag=process.argv[2]==="true"; ' +
      'if(instance.exports.spin(flag?1:0)!==1) throw new Error("spin result mismatch"); ' +
      'if(!flag) throw new Error("divergence returned");';
    const args = ['--input-type=module', '-e', program, artifact.output];
    run(process.execPath, [...args, 'true']);
    return externalTimeout(process.execPath, [...args, 'false']);
  }
  if (target === 'wasm-component') {
    assert.equal(run('wasmtime', ['run', '--invoke', 'spin(true)', artifact.output]).trim(), 'true');
    return externalTimeout('wasmtime', ['run', '--invoke', 'spin(false)', artifact.output]);
  }
  if (target === 'python') {
    const program = 'import importlib.util,sys\n' +
      'spec=importlib.util.spec_from_file_location("psc1_output",sys.argv[1])\n' +
      'module=importlib.util.module_from_spec(spec)\nspec.loader.exec_module(module)\n' +
      'flag=sys.argv[2]=="true"\n' +
      'assert module.spin(flag) is True, "spin result mismatch"\n' +
      'assert flag, "divergence returned"\n';
    const command = process.env.PSC1_PYTHON || 'python3';
    const args = ['-I', '-c', program, artifact.output];
    run(command, [...args, 'true']);
    return externalTimeout(command, [...args, 'false']);
  }
  const command = process.env.PSC1_PHP || 'php';
  const program = '$api=require $argv[1]; $flag=$argv[2]==="true"; ' +
    'if($api["spin"]($flag)!==true) throw new Exception("spin result mismatch"); ' +
    'if(!$flag) throw new Exception("divergence returned");';
  const args = ['-d', 'memory_limit=1G', '-r', program, artifact.output];
  run(command, [...args, 'true']);
  return externalTimeout(command, [...args, 'false']);
}

const selectedBody = /selected while requires Id or Except/;
const unsupported = [
  ['total-owner', /unrestricted while requires an explicit partial declaration/,
    `def unsupported (flag : Bool) : Id Nat := do
  while false do
    ()
  return 7
`],
  ['nested-while-body', selectedBody,
    `partial def unsupported (flag : Bool) : Id Nat := do
  while false do
    while false do
      ()
  return 7
`],
  ['nested-for-body', selectedBody,
    `partial def unsupported (flag : Bool) : Id Nat := do
  while false do
    for index in [0:1] do
      ()
  return 7
`],
  ['function-valued-result', selectedBody,
    `partial def unsupported (flag : Bool) : Id (Nat -> Nat) := do
  while false do
    ()
  return fun (value : Nat) => value
`],
  ['generic-result', selectedBody,
    `partial def unsupported (A : Type) (value : A) : Id A := do
  while false do
    ()
  return value
`],
  ['CompilerM-body', selectedBody,
    read(path.join(root, 'stdlib/ProofScript/Data/Result.lean')) + '\n' +
    read(path.join(root, 'stdlib/ProofScript/Compiler/Effect.lean')) + '\n' +
    `partial def unsupported (flag : Bool) : CompilerM Unit Nat String Nat := do
  while false do
    compilerSet 0
  return 7
`]
];

try {
  const leanFolder = path.join(evidence, 'sources', 'lean');
  const psFolder = path.join(evidence, 'sources', 'ps');
  fs.mkdirSync(psFolder, { recursive: true });
  for (const [moduleName, text] of [
    ['Loops', loopsSource], ['Entry', entrySource],
    ['Divergence', divergenceSource], ['Spin', spinSource]
  ]) {
    const lean = source(leanFolder, moduleName + '.lean', text);
    run(native, ['translate', lean, '--to', 'ps', '--out', path.join(psFolder, moduleName + '.ps')]);
  }
  for (const syntax of ['lean', 'ps']) {
    const folder = syntax === 'lean' ? leanFolder : psFolder;
    const entry = path.join(folder, 'Entry.' + syntax);
    const spin = path.join(folder, 'Spin.' + syntax);
    for (const target of targets) {
      console.log('PSC1_WHILE_CONFORMANCE_START: ' + syntax + '/' + target);
      try {
        const selected = target === 'wasm-component' ? ['semantic'] : names;
        const finite = build(entry, target, syntax, 'finite', selected);
        const values = executeFinite(finite, target);
        for (const [name, no, yes] of values) {
          assert.equal(no, true, syntax + '/' + target + '/' + name + '(false)');
          assert.equal(yes, true, syntax + '/' + target + '/' + name + '(true)');
        }
        if (target === targets[0]) {
          const prior = [hash(finite.output), hash(finite.output + '.bundle.json')];
          reject('default-refuses-unrestricted-while', syntax,
            ['build', entry, '--target', target, '--out', finite.output], /PSC1_PREPARATION_FAILED/);
          reject('verified-refuses-unrestricted-while', syntax,
            ['build', entry, '--assurance', 'verified', '--target', target, '--out', finite.output],
            /PSC1_VERIFIED_EXECUTION_UNAVAILABLE/);
          assert.deepEqual([hash(finite.output), hash(finite.output + '.bundle.json')], prior,
            'failed assurance requests changed a published artifact');
        }
        records.push({ syntax, target, passed: true, checks: values,
          assurance: finite.manifest.assurance, behaviorallyVerified: false,
          publicNames: finite.manifest.publicNames,
          partialDeclarations: finite.manifest.partialDeclarations,
          artifactSha256: finite.artifactSha256, manifestSha256: finite.manifestSha256 });
        console.log('PSC1_WHILE_CONFORMANCE_PASS: ' + syntax + '/' + target);
      } catch (error) {
        records.push({ passed: false, ...recordFailure('finite', syntax, target, error) });
      }
      try {
        const infinite = build(spin, target, syntax, 'divergence', ['spin']);
        const deadline = executeDivergence(infinite, target);
        divergence.push({ syntax, target, passed: true, ...deadline,
          earlyReturnPreflight: true, unusedNonvalueCallEvaluated: true,
          publicNames: infinite.manifest.publicNames,
          artifactSha256: infinite.artifactSha256, manifestSha256: infinite.manifestSha256 });
        console.log('PSC1_WHILE_DIVERGENCE_PASS: ' + syntax + '/' + target);
      } catch (error) {
        divergence.push({ passed: false, ...recordFailure('divergence', syntax, target, error) });
      }
    }
    for (const [name, pattern, text] of unsupported) {
      try {
        const stem = 'negative_' + name.replaceAll('-', '_');
        const lean = source(leanFolder, stem + '.lean', text);
        let input = lean;
        if (syntax === 'ps') {
          input = path.join(psFolder, stem + '.ps');
          run(native, ['translate', lean, '--to', 'ps', '--out', input]);
        }
        reject(name, syntax, ['check', input, '--assurance', 'ordinary'], pattern);
      } catch (error) {
        rejections.push({ name, passed: false, ...recordFailure('source-profile', syntax, name, error) });
      }
    }
  }
  if (failures.length) {
    throw new Error('PSC1_ORDINARY_WHILE_CONFORMANCE_FAILED: ' +
      failures.map(value => value.phase + '/' + value.syntax + '/' + value.target).join(', '));
  }
  console.log('PSC1_ORDINARY_WHILE_CONFORMANCE: PASS ' + records.length +
    ' finite bundles, ' + divergence.length + ' external divergence deadlines, ' +
    rejections.length + ' refusals');
} finally {
  fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify({
    schema: 'psc1-ordinary-while-conformance/1',
    commit: process.env.GITHUB_SHA || null,
    branchHeadCommit: process.env.PSC1_HEAD_SHA || null,
    assurance: 'ordinary-checked', behaviorallyVerified: false,
    nativeLean: { version: oracle.leanVersion, commit: oracle.leanCommit },
    oracleSha256: sha(JSON.stringify(oracle)),
    oracleFields: Object.keys(oracle).filter(key => key.startsWith('while')),
    loopChecks: checks, longLoopIterations: 100000,
    targetCount: targets.length, sourceSyntaxes: ['lean', 'ps'],
    records, divergence, rejections, failures
  }, null, 2) + '\n');
  fs.rmSync(work, { recursive: true, force: true });
}
