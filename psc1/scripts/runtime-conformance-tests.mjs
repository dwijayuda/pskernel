// Real target execution against the repository-pinned native Lean runtime.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-runtime-conformance-'));
const evidence = path.join(root, 'dist/scoped-correctness', process.env.PSC1_RUNTIME_EVIDENCE || 'runtime-conformance');
fs.mkdirSync(evidence, { recursive: true });
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const records = [];
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function run(command, args, options = {}) {
  const deadline = options.timeout ?? 180000;
  const result = spawnSync('timeout', ['--kill-after=5s', Math.ceil(deadline / 1000) + 's', command, ...args],
    { env, encoding: 'utf8', ...options, timeout: deadline + 10000 });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 0, command + ' ' + args.join(' ') + '\n' + result.stdout + result.stderr);
  return result.stdout;
}
const oracle = JSON.parse(run(path.join(root, '.lake/build/bin/psc1_runtime_oracle'), []));
assert.equal(oracle.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
fs.writeFileSync(path.join(evidence, 'lean-runtime-oracle.json'), JSON.stringify(oracle, null, 2) + '\n');
console.log('PSC1_PINNED_LEAN_ORACLE: ' + JSON.stringify(oracle));
const n = key => oracle[key];
const eqNat = (expression, expected) => 'Nat.beq (' + expression + ') ' + expected;
function textChecks(expression, expected) {
  const chars = Array.from(expected);
  const checks = [eqNat('String.Internal.length (' + expression + ')', chars.length),
    eqNat('String.utf8ByteSize (' + expression + ')', Buffer.byteLength(expected))];
  let offset = 0;
  for (const character of chars) {
    checks.push(eqNat('Char.toNat (String.Internal.get (' + expression + ') ' + offset + ')', character.codePointAt(0)));
    offset += Buffer.byteLength(character);
  }
  return checks;
}
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
    ...textChecks('Int.repr (Int.add (-7) (-13))', n('intAdd')),
    ...textChecks('Int.repr (Int.mul (-7) 3)', n('intMul'))
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
    ...textChecks('String.Internal.extract text 1 5', n('extractValid')),
    ...textChecks('String.Internal.extract text 1 3', n('extractMiddle')),
    eqNat('Char.toNat (Char.ofNat 55296)', n('charSurrogate')),
    eqNat('Char.toNat (Char.ofNat 1114112)', n('charOutOfRange')),
    eqNat('Char.toNat (Char.ofNat 4294967361)', n('charLarge'))
  ],
  arraycheck: [
    'Nat.beq (Array.getD base 0 0) 7',
    'Nat.beq (Array.getD changed 0 0) 11',
    'Nat.beq (Array.getD changed huge 19) 19',
    'Nat.beq (Array.getD shifted 0 0) 12',
    'Nat.beq offset 100',
    'Nat.beq (Prod.fst pair) 41'
  ]
};
function conjoin(clauses) {
  if (clauses.length === 1) return '(' + clauses[0] + ')';
  const middle = Math.floor(clauses.length / 2);
  return '(' + conjoin(clauses.slice(0, middle)) + ' && ' + conjoin(clauses.slice(middle)) + ')';
}
let source = '';
for (const [name, clauses] of Object.entries(groups)) {
  source += 'def ' + name + ' (flag : Bool) : Bool :=\n';
  source += ' let huge : Nat := ' + n('huge') + ';\n';
  if (name === 'unicodecheck') source += ' let text : String := "A😀é";\n';
  if (name === 'arraycheck') {
    source += ' let base : Array Nat := Array.push (Array.emptyWithCapacity 1) 7;\n' +
      ' let changed : Array Nat := Array.setIfInBounds base 0 11;\n' +
      ' let offset : Nat := 5;\n' +
      ' let mapper : Nat -> Nat := fun (value : Nat) => Nat.add value offset;\n' +
      ' let offset : Nat := 100;\n' +
      ' let shifted : Array Nat := Array.map mapper base;\n' +
      ' let pair : Prod Nat Bool := Prod.mk 41 flag;\n';
  }
  source += ' ' + conjoin([...clauses, '(flag || !flag)']) + '\n';
}
// Expected observations come from native pinned Lean, not a target oracle.
const referenceChoice = stem => '(if flag then ' + n(stem + 'True') + ' else ' + n(stem + 'False') + ')';
const controlBodies = {
  mutationcheck:
    ' let observed : Id Nat := (do\n' +
    '  let mut value : Nat := 3\n' +
    '  if flag then\n' +
    '   value := value + 4\n' +
    '  else\n' +
    '   value := value + 8\n' +
    '  value := value * 2\n' +
    '  return value\n' +
    ' );\n Nat.beq (Id.run observed) ' + referenceChoice('controlMutation') + '\n',
  capturecheck:
    ' let observed : Id Nat := (do\n' +
    '  let mut value : Nat := if flag then 3 else 5\n' +
    '  let captured : Nat -> Nat := fun (n : Nat) => value + n\n' +
    '  value := 100\n' +
    '  return captured value\n' +
    ' );\n Nat.beq (Id.run observed) ' + referenceChoice('controlCapture') + '\n',
  earlycheck:
    ' let observed : Id Nat := (do\n' +
    '  let mut value : Nat := 3\n' +
    '  if flag then\n' +
    '   value := 7\n' +
    '   if Nat.beq value 7 then\n' +
    '    return value\n' +
    '   value := 50\n' +
    '  else\n' +
    '   value := 11\n' +
    '  value := value + 1\n' +
    '  return value\n' +
    ' );\n Nat.beq (Id.run observed) ' + referenceChoice('controlEarly') + '\n',
  shadowcheck:
    ' let observed : Id Nat := (do\n' +
    '  let value : Bool := false\n' +
    '  let mut value : Nat := if flag then 3 else 5\n' +
    '  value := value + 1\n' +
    '  return value\n' +
    ' );\n Nat.beq (Id.run observed) ' + referenceChoice('controlShadow') + '\n',
  danglingcheck:
    ' let observed : Id Nat := (do\n' +
    '  let mut value : Nat := 3\n' +
    '  if flag then\n' +
    '   if false then\n' +
    '    value := 99\n' +
    '  else\n' +
    '   value := 50\n' +
    '  return value\n' +
    ' );\n Nat.beq (Id.run observed) ' + referenceChoice('controlDangling') + '\n',
  errorcheck:
    ' let observed : Except Nat Nat := (do\n' +
    '  let mut value : Nat := 3\n' +
    '  value := value + 4\n' +
    '  if flag then\n' +
    '   let ignored : Unit <- Except.error value\n' +
    '   return 999\n' +
    '  return value\n' +
    ' );\n match observed with\n' +
    '  | Except.error value => Nat.beq value (if flag then ' + n('controlErrorTrueValue') +
      ' else ' + n('controlErrorFalseValue') + ') && (if flag then ' + n('controlErrorTrueTag') +
      ' else ' + n('controlErrorFalseTag') + ')\n' +
    '  | Except.ok value => Nat.beq value (if flag then ' + n('controlErrorTrueValue') +
      ' else ' + n('controlErrorFalseValue') + ') && !(if flag then ' + n('controlErrorTrueTag') +
      ' else ' + n('controlErrorFalseTag') + ')\n',
  forlistcheck:
    ' let observed : Id Nat := (do\n' +
    '  let mut total : Nat := 0\n' +
    '  for value in [1, 2, 3] do\n' +
    '   if flag && Nat.beq value 2 then\n' +
    '    return total\n' +
    '   total := total * 10 + value\n' +
    '  return total\n' +
    ' );\n Nat.beq (Id.run observed) ' + referenceChoice('forList') + '\n',
  forarraycheck:
    ' let observed : Id Nat := (do\n' +
    '  let mut values : Array Nat := if flag then #[1, 2, 3] else #[]\n' +
    '  let mut total : Nat := 0\n' +
    '  for value in values do\n' +
    '   values := #[99]\n' +
    '   total := total + value\n' +
    '  return total * 10 + Array.size values\n' +
    ' );\n Nat.beq (Id.run observed) ' + referenceChoice('forArray') + '\n',
  forrangecheck:
    ' let observed : Id Nat := (do\n' +
    '  let mut lower : Nat := if flag then 2 else 5\n' +
    '  let mut upper : Nat := if flag then 5 else 2\n' +
    '  let mut total : Nat := 0\n' +
    '  for value in [lower:upper] do\n' +
    '   lower := 100\n' +
    '   upper := 0\n' +
    '   total := total * 10 + value\n' +
    '  return total\n' +
    ' );\n let empty : Id Nat := (do\n' +
    '  let mut total : Nat := 0\n' +
    '  for value in [3:3] do\n' +
    '   total := total + 1\n' +
    '  return total\n' +
    ' );\n let zeroStart : Id Nat := (do\n' +
    '  let mut total : Nat := 0\n' +
    '  for value in [:3] do\n' +
    '   total := total * 10 + value\n' +
    '  return total\n' +
    ' );\n Nat.beq (Id.run observed) ' + referenceChoice('forRange') +
    ' && Nat.beq (Id.run empty) ' + n('forRangeEmpty') +
    ' && Nat.beq (Id.run zeroStart) ' + n('forRangeZero') + '\n'
};
for (const [name, body] of Object.entries(controlBodies)) {
  source += 'def ' + name + ' (flag : Bool) : Bool :=\n' + body;
}
const checkNames = [...Object.keys(groups), ...Object.keys(controlBodies), 'dataliteralcheck', 'optionalindexcheck'];
const names = [...checkNames, 'semantic'];
const input = path.join(evidence, 'Runtime.lean');
fs.writeFileSync(input, source);
const translated = path.join(evidence, 'Runtime.ps');
// Translation lowers literals to named calls. Append handwritten data syntax
// in each grammar after translating the common corpus to exercise both parsers.
run(native, ['translate', input, '--to', 'ps', '--out', translated]);
const literalTotal = n('literalTotal');
const literalLeanFlag = '(if flag then ' + n('literalTrueFlag') + ' else ' + n('literalFalseFlag') + ')';
const literalPsFlag = '(if (flag) { ' + n('literalTrueFlag') + ' } else { ' + n('literalFalseFlag') + ' })';
const literalLeanChecks = [
  ...textChecks('Int.repr total', literalTotal),
  eqNat('Array.size values', n('literalArraySize')),
  eqNat('Array.size empty', n('literalEmptySize')),
  'if Prod.fst (Prod.snd pair) then ' + literalLeanFlag + ' else !' + literalLeanFlag
];
function psTextChecks(expression, expected) {
  const checks = [
    'Nat.beq(String.Internal.length(' + expression + '), ' + Array.from(expected).length + ')',
    'Nat.beq(String.utf8ByteSize(' + expression + '), ' + Buffer.byteLength(expected) + ')'
  ];
  let offset = 0;
  for (const char of Array.from(expected)) {
    checks.push('Nat.beq(Char.toNat(String.Internal.get(' + expression + ', ' + offset + ')), ' + char.codePointAt(0) + ')');
    offset += Buffer.byteLength(char);
  }
  return checks;
}
const literalPsChecks = [
  ...psTextChecks('Int.repr(total)', literalTotal),
  'Nat.beq(Array.size(values), ' + n('literalArraySize') + ')',
  'Nat.beq(Array.size(empty), ' + n('literalEmptySize') + ')',
  'if (Prod.fst(Prod.snd(pair))) { ' + literalPsFlag + ' } else { !' + literalPsFlag + ' }'
];
const literalLean =
  'def dataliteralcheck (flag : Bool) : Bool :=\n' +
  ' let pair : Prod Int (Prod Bool Int) := (-7, (flag, 13));\n' +
  ' let values : Array Int := #[Prod.fst pair, Prod.snd (Prod.snd pair), 29];\n' +
  ' let empty : Array Int := #[];\n' +
  ' let total : Int := Int.add (Array.getD values 0 0) (Array.getD values 1 0);\n' +
  ' ' + conjoin(literalLeanChecks) + '\n';
const literalPs =
  'def dataliteralcheck(flag : Bool) : Bool :=\n' +
  ' let pair : Prod(Int, Prod(Bool, Int)) := (-7, (flag, 13))\n' +
  ' let values : Array(Int) := #[Prod.fst(pair), Prod.snd(Prod.snd(pair)), 29]\n' +
  ' let empty : Array(Int) := #[]\n' +
  ' let total : Int := Int.add(Array.getD(values, 0, 0), Array.getD(values, 1, 0))\n' +
  ' ' + conjoin(literalPsChecks) + '\n';
const optionalLeanTag = '(if flag then ' + n('optionalIndexTrueTag') + ' else ' + n('optionalIndexFalseTag') + ')';
const optionalPsTag = '(if (flag) { ' + n('optionalIndexTrueTag') + ' } else { ' + n('optionalIndexFalseTag') + ' })';
const optionalLeanChecks = [
  'if selectedTag then ' + optionalLeanTag + ' else !' + optionalLeanTag,
  'if flag then ' + conjoin(textChecks('Int.repr selectedValue', n('optionalIndexTrueValue'))) +
    ' else ' + conjoin(textChecks('Int.repr selectedValue', n('optionalIndexFalseValue'))),
  'if hugeAbsent then ' + n('optionalHugeAbsent') + ' else !' + n('optionalHugeAbsent'),
  'if emptyAbsent then ' + n('optionalEmptyAbsent') + ' else !' + n('optionalEmptyAbsent')
];
const optionalPsChecks = [
  'if (selectedTag) { ' + optionalPsTag + ' } else { !' + optionalPsTag + ' }',
  'if (flag) { ' + conjoin(psTextChecks('Int.repr(selectedValue)', n('optionalIndexTrueValue'))) +
    ' } else { ' + conjoin(psTextChecks('Int.repr(selectedValue)', n('optionalIndexFalseValue'))) + ' }',
  'if (hugeAbsent) { ' + n('optionalHugeAbsent') + ' } else { !' + n('optionalHugeAbsent') + ' }',
  'if (emptyAbsent) { ' + n('optionalEmptyAbsent') + ' } else { !' + n('optionalEmptyAbsent') + ' }'
];
const optionalLean =
  'def optionalindexcheck (flag : Bool) : Bool :=\n' +
  ' let values : Array Int := #[-7, 13];\n' +
  ' let index : Nat := if flag then 1 else 2;\n' +
  ' let selected : Option Int := values[index]?;\n' +
  ' let selectedTag : Bool := match selected with | Option.none => false | Option.some value => true;\n' +
  ' let selectedValue : Int := match selected with | Option.none => 0 | Option.some value => value;\n' +
  ' let hugeAbsent : Bool := match values[' + n('huge') + ']? with | Option.none => true | Option.some value => false;\n' +
  ' let empty : Array Int := #[];\n' +
  ' let emptyAbsent : Bool := match empty[0]? with | Option.none => true | Option.some value => false;\n' +
  ' ' + conjoin(optionalLeanChecks) + '\n';
const optionalPs =
  'def optionalindexcheck(flag : Bool) : Bool :=\n' +
  ' let values : Array(Int) := #[-7, 13]\n' +
  ' let index : Nat := if (flag) { 1 } else { 2 }\n' +
  ' let selected : Option(Int) := values[index]?\n' +
  ' let selectedTag : Bool := match selected with { | Option.none => false | Option.some value => true }\n' +
  ' let selectedValue : Int := match selected with { | Option.none => 0 | Option.some value => value }\n' +
  ' let hugeAbsent : Bool := match values[' + n('huge') + ']? with { | Option.none => true | Option.some value => false }\n' +
  ' let empty : Array(Int) := #[]\n' +
  ' let emptyAbsent : Bool := match empty[0]? with { | Option.none => true | Option.some value => false }\n' +
  ' ' + conjoin(optionalPsChecks) + '\n';
fs.appendFileSync(input, literalLean + optionalLean + 'def semantic (flag : Bool) : Bool := ' +
  conjoin(checkNames.map(name => name + ' flag')) + '\n');
fs.appendFileSync(translated, literalPs + optionalPs + 'def semantic(flag : Bool) : Bool := ' +
  conjoin(checkNames.map(name => name + '(flag)')) + '\n');
const targets = (process.env.PSC1_CONFORMANCE_TARGETS ||
  'js,ts,rust,wasm-core,wasm-component,python,php').split(',');
fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');

try {
  for (const syntax of ['lean', 'ps']) {
    const entry = syntax === 'lean' ? input : translated;
    for (const target of targets) {
      console.log('PSC1_RUNTIME_CONFORMANCE_START: ' + syntax + '/' + target);
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
      console.log('PSC1_RUNTIME_CONFORMANCE_BUILT: ' + syntax + '/' + target);
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
        const consumerProgram = 'import {pathToFileURL} from "node:url"; ' +
          'const module=await import(pathToFileURL(process.argv[1]).href); ' +
          'const names=JSON.parse(process.argv[2]); ' +
          'console.log(JSON.stringify(names.map(name=>[name,module[name](false),module[name](true)])));';
        values = JSON.parse(run(process.execPath, ['--input-type=module', '-e', consumerProgram,
          moduleFile, JSON.stringify(names)], { timeout: 60000 }));
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
        const consumerProgram = 'import fs from "node:fs"; ' +
          'const {instance}=await WebAssembly.instantiate(fs.readFileSync(process.argv[1])); ' +
          'const names=JSON.parse(process.argv[2]); ' +
          'console.log(JSON.stringify(names.map(name=>[name,Boolean(instance.exports[name](0)),Boolean(instance.exports[name](1))])));';
        values = JSON.parse(run(process.execPath, ['--input-type=module', '-e', consumerProgram,
          output, JSON.stringify(names)], { timeout: 60000 }));
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
    schema: 'psc1-runtime-conformance/1', commit: process.env.GITHUB_SHA || null, branchHeadCommit: process.env.PSC1_HEAD_SHA || null,
    nativeLean: { version: oracle.leanVersion, commit: oracle.leanCommit },
    oracleSha256: sha(JSON.stringify(oracle)), node: process.version,
    targetCount: targets.length,
    controlFlowChecks: Object.keys(controlBodies),
    controlFlowOracle: 'pinned-native-Lean',
    handwrittenLiteralSyntaxes: ['lean', 'ps'],
    handwrittenOptionalIndexSyntaxes: ['lean', 'ps'],
    records
  }, null, 2) + '\n');
  fs.rmSync(work, { recursive: true, force: true });
}
