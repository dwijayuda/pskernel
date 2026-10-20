// Direct Python/PHP ABI, source ownership, recursion and publication regressions.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-script-backends-'));
const evidence = path.join(root, 'dist/scoped-correctness/script-backends');
fs.mkdirSync(evidence, { recursive: true });
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const records = [];
const read = file => fs.readFileSync(file, 'utf8');
function run(cmd, args, options = {}) {
  const deadline = options.timeout ?? 120000;
  const result = spawnSync('timeout', ['--kill-after=5s', Math.ceil(deadline / 1000) + 's', cmd, ...args],
    { env, encoding: 'utf8', ...options, timeout: deadline + 10000 });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 0, cmd + ' ' + args.join(' ') + '\n' + result.stdout + result.stderr);
  return result.stdout;
}
function reject(args, options = {}) {
  const result = spawnSync(native, args, { env, encoding: 'utf8', timeout: 120000, ...options });
  assert.notEqual(result.status, 0);
  assert.match(result.stdout + result.stderr, /PSC1_|PSC2_/);
  return result;
}
function source(name, text) {
  const file = path.join(work, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
  return file;
}
function build(input, target, label, assurance) {
  const output = path.join(work, label, 'module.' + (target === 'python' ? 'py' : 'php'));
  const args = ['build', input, '--target', target, '--out', output];
  if (assurance) args.push('--assurance', assurance);
  run(native, args);
  const manifest = JSON.parse(read(output + '.bundle.json'));
  const origins = JSON.parse(read(output + '.origins.json'));
  assert.equal(manifest.logicalCheckerCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.behaviorallyVerified, false);
  assert.equal(manifest.runtimeContract, 'psc1-runtime-semantics/1');
  assert.equal(origins.schema, 'psc1-source-origins/1');
  assert.equal(origins.coverage, 'declaration-starts-only');
  for (const name of manifest.publicNames) {
    const record = origins.declarations.find(item => item.name === name);
    assert.ok(record?.original, name);
    assert.ok(record.generatedLine >= 1);
  }
  return { input, target, label, output, args, manifest };
}
const pythonProgram = String.raw`import importlib.util,json,sys
before_limit=sys.get_int_max_str_digits()
spec=importlib.util.spec_from_file_location("psc1_consumer",sys.argv[1])
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
request=json.loads(sys.argv[2])
def decode(value):
 if isinstance(value,dict) and "power10" in value: return 10 ** value["power10"]
 if isinstance(value,dict) and ("nat" in value or "int" in value): return int(next(iter(value.values())))
 if isinstance(value,dict) and "char" in value: return value["char"]
 return value
def encode(value):
 if isinstance(value,int) and not isinstance(value,bool): return str(value)
 return value
values=[]
for item in request.get("calls",[]):
 value=getattr(module,item["name"])
 result=value(*[decode(arg) for arg in item["args"]]) if "args" in item else value
 values.append(encode(result))
errors=[]
for item in request.get("reject",[]):
 try:
  getattr(module,item["name"])(*[decode(arg) for arg in item["args"]])
  errors.append(False)
 except (TypeError,ValueError,OverflowError):
  errors.append(True)
print(json.dumps({"exports":module.__all__,"values":values,"errors":errors,"runtime":sys.version.split()[0],"integerDigitLimit":sys.get_int_max_str_digits(),"integerDigitLimitUnchanged":sys.get_int_max_str_digits()==before_limit,"shapes":{n:("function" if callable(getattr(module,n)) else "value") for n in module.__all__}}))
`;
const phpProgram = String.raw`$api = require $argv[1];
$request = json_decode($argv[2], true, 512, JSON_THROW_ON_ERROR);
$decode = static function($value) {
 if (is_array($value) && array_key_exists('power10',$value)) return gmp_pow(gmp_init('10'),$value['power10']);
 if (is_array($value) && (array_key_exists('nat',$value) || array_key_exists('int',$value))) return gmp_init(array_values($value)[0],10);
 if (is_array($value) && array_key_exists('char',$value)) return $value['char'];
 return $value;
};
$values = [];
foreach (($request['calls'] ?? []) as $item) {
 $value = $api[$item['name']];
 $result = array_key_exists('args',$item) ? $value(...array_map($decode,$item['args'])) : $value;
 $values[] = $result instanceof GMP ? gmp_strval($result,10) : $result;
}
$errors = [];
foreach (($request['reject'] ?? []) as $item) {
 try { $api[$item['name']](...array_map($decode,$item['args'])); $errors[] = false; }
 catch (TypeError | ValueError | InvalidArgumentException | ArgumentCountError $error) { $errors[] = true; }
}
echo json_encode(['exports'=>array_keys($api),'values'=>$values,'errors'=>$errors,'runtime'=>PHP_VERSION,'shapes'=>array_map(static fn($value)=>is_callable($value)?'function':'value',$api)],JSON_THROW_ON_ERROR);
`;
function consumer(artifact, request, options = {}) {
  const command = artifact.target === 'python' ? (options.python || process.env.PSC1_PYTHON || 'python3')
    : (process.env.PSC1_PHP || 'php');
  const args = artifact.target === 'python'
    ? ['-I', '-X', 'int_max_str_digits=640', '-c', pythonProgram, artifact.output, JSON.stringify(request)]
    : ['-d', 'memory_limit=1G', '-r', phpProgram, artifact.output, JSON.stringify(request)];
  const result = JSON.parse(run(command, args, options));
  assert.deepEqual([...result.exports].sort(), [...artifact.manifest.publicNames].sort());
  if (artifact.target === 'python') assert.equal(result.integerDigitLimitUnchanged, true);
  if (request.reject) assert.deepEqual(result.errors, request.reject.map(() => true));
  return result;
}
function retain(artifact, observations) {
  fs.cpSync(path.dirname(fs.realpathSync(artifact.output + '.bundle.json')),
    path.join(evidence, artifact.label), { recursive: true });
  records.push({ group: artifact.label, target: artifact.target, passed: true,
    sourceBytes: fs.statSync(artifact.output).size, runtime: artifact.manifest.targetPlans[0], observations });
  console.log('PSC1_SCRIPT_BACKEND_PASS: ' + artifact.label);
}

try {
  for (const target of ['python', 'php']) {
    for (const syntax of ['lean', 'ps']) {
      const constant = build(source('constant.' + syntax, 'def answer : Bool := true\n'),
        target, target + '-constant-' + syntax);
      const result = consumer(constant, { calls: [{ name: 'answer' }] });
      assert.deepEqual(result.values, [true]);
      assert.equal(constant.manifest.targetPlans[0].runtimeFree, true);
      if (target === 'php') {
        assert.equal(Object.hasOwn(JSON.parse(read(constant.output.replace(/\.php$/, '.composer.json'))).require,
          'ext-gmp'), false);
        const noGmp = run(process.env.PSC1_PHP || 'php',
          ['-n', '-r', phpProgram, constant.output, JSON.stringify({ calls: [{ name: 'answer' }] })]);
        assert.deepEqual(JSON.parse(noGmp).values, [true]);
      }
      if (target === 'python' && process.env.PSC1_PYTHON_314) {
        assert.deepEqual(consumer(constant, { calls: [{ name: 'answer' }] },
          { python: process.env.PSC1_PYTHON_314 }).values, [true]);
      }
      retain(constant, result);
    }

    const abiSource = source(target + '-abi.lean', [
      'def echoNat (value : Nat) : Nat := value',
      'def echoInt (value : Int) : Int := value',
      'def decimal (value : Int) : String := Int.repr value',
      'def echoString (value : String) : String := value',
      'def echoChar (value : Char) : Char := value',
      'def echoUnit (value : Unit) : Unit := value',
      'def first (left : Nat) (right : Nat) : Nat := left'
    ].join('\n') + '\n');
    const abi = build(abiSource, target, target + '-public-abi');
    const huge = '900719925474099312345678901234567890';
    const result = consumer(abi, {
      calls: [
        { name: 'echoNat', args: [{ nat: huge }] },
        { name: 'echoInt', args: [{ int: '-' + huge }] },
        { name: 'echoString', args: ['A😀é\u0000Z'] },
        { name: 'echoChar', args: [{ char: '😀' }] },
        { name: 'echoUnit', args: [null] },
        { name: 'first', args: [{ nat: '11' }, { nat: '22' }] }
      ],
      reject: [
        { name: 'echoNat', args: [true] },
        { name: 'echoNat', args: [{ nat: '-1' }] },
        { name: 'echoInt', args: ['5'] },
        { name: 'echoChar', args: [{ char: '' }] },
        { name: 'echoChar', args: [{ char: 'ab' }] },
        { name: 'echoString', args: [false] },
        { name: 'echoUnit', args: [false] },
        { name: 'first', args: [{ nat: '1' }] },
        { name: 'first', args: [{ nat: '1' }, { nat: '2' }, { nat: '3' }] }
      ]
    });
    assert.deepEqual(result.values, [huge, '-' + huge, 'A😀é\u0000Z', '😀', null, '11']);
    retain(abi, result);
    if (target === 'python' && process.env.PSC1_PYTHON_314) {
      assert.deepEqual(consumer(abi, { calls: [{ name: 'echoNat', args: [{ nat: huge }] }] },
        { python: process.env.PSC1_PYTHON_314 }).values, [huge]);
    }

    const hugeDecimal = '1' + '0'.repeat(5000);
    const decimalResult = consumer(abi, {
      calls: [{ name: 'decimal', args: [{ power10: 5000 }] }]
    });
    assert.deepEqual(decimalResult.values, [hugeDecimal]);
    const literal = build(source(target + '-large-literal.lean',
      'def bigliteral (value : Nat) : Bool := Nat.beq value ' + hugeDecimal + '\n'),
      target, target + '-unbounded-literal-and-decimal');
    assert.deepEqual(consumer(literal, { calls: [
      { name: 'bigliteral', args: [{ power10: 5000 }] }
    ] }).values, [true]);
    retain(literal, { decimalDigits: 5001, exactDecimalConversion: true,
      integerDigitLimit: decimalResult.integerDigitLimit ?? null,
      processGlobalIntegerConversionLimitChanged: target === 'python' ? !decimalResult.integerDigitLimitUnchanged : false });

    source(target + '-generic/Dep.lean', 'def helper {a : Type} (value : a) : a := value\n');
    const generic = build(source(target + '-generic/Main.lean',
      'import Dep\ndef publicid (value : Nat) : Nat := helper value\n'), target, target + '-private-generic');
    assert.deepEqual(generic.manifest.publicNames, ['publicid']);
    assert.deepEqual(consumer(generic, { calls: [{ name: 'publicid', args: [{ nat: huge }] }] }).values, [huge]);
    retain(generic, { publicNames: generic.manifest.publicNames });

    source(target + '-empty/Dep.lean', 'def hidden : Bool := true\n');
    const empty = build(source(target + '-empty/Main.lean', 'import Dep\n'), target, target + '-empty-entry');
    assert.deepEqual(consumer(empty, { calls: [] }).exports, []);
    retain(empty, { publicNames: [] });

    const collision = build(source(target + '-names.lean',
      'def Util.id (value : Bool) : Bool := value\ndef Util_id : Bool := false\n'),
      target, target + '-symbol-identity');
    const inspected = consumer(collision, { calls: [] });
    const functions = Object.keys(inspected.shapes).filter(name => inspected.shapes[name] === 'function');
    const values = Object.keys(inspected.shapes).filter(name => inspected.shapes[name] === 'value');
    assert.equal(functions.length, 1);
    assert.equal(values.length, 1);
    assert.deepEqual(consumer(collision, { calls: [
      { name: functions[0], args: [true] }, { name: functions[0], args: [false] },
      { name: values[0] }
    ] }).values, [true, false, false]);
    retain(collision, inspected);

    source(target + '-ordinary-import/Dep.lean',
      'partial def ordinaryFlag (value : Bool) : Bool := if value then true else ordinaryFlag true\n');
    const imported = build(source(target + '-ordinary-import/Main.lean',
      'import Dep\ndef answer (value : Bool) : Bool := ordinaryFlag value\n'),
      target, target + '-imported-ordinary', 'ordinary');
    assert.deepEqual(imported.manifest.publicNames, ['answer']);
    assert.deepEqual(consumer(imported, { calls: [
      { name: 'answer', args: [false] }, { name: 'answer', args: [true] }
    ] }).values, [true, true]);
    retain(imported, { publicNames: imported.manifest.publicNames,
      partialDeclarations: imported.manifest.partialDeclarations });

    const recursive = build(source(target + '-recursive.lean',
      'def count (n : Nat) : Nat :=\n match n with\n | Nat.zero => Nat.zero\n | Nat.succ k => Nat.succ (count k)\n'),
      target, target + '-non-tail-recursion');
    assert.deepEqual(consumer(recursive, { calls: [{ name: 'count', args: [{ nat: '100000' }] }] }).values, ['100000']);
    retain(recursive, { input: '100000', output: '100000', executionFuel: null });

    const ordinary = build(source(target + '-ordinary.ps',
      'partial def countdown(n : Nat) : Nat := if (Nat.beq(n, 0)) { 42 } else { countdown(Nat.sub(n, 1)) }\n'),
      target, target + '-ordinary-recursion', 'ordinary');
    assert.equal(ordinary.manifest.assurance, 'ordinary-checked');
    assert.ok(ordinary.manifest.partialDeclarations.some(name => name.includes('countdown')));
    assert.deepEqual(consumer(ordinary, { calls: [{ name: 'countdown', args: [{ nat: '100000' }] }] }).values, ['42']);
    retain(ordinary, { input: '100000', output: '42', behaviorallyVerified: false });

    const divergent = build(source(target + '-spin.lean',
      'partial def spin (n : Nat) : Nat := spin n\n'), target, target + '-divergence', 'ordinary');
    const command = target === 'python' ? (process.env.PSC1_PYTHON || 'python3') : (process.env.PSC1_PHP || 'php');
    const program = target === 'python'
      ? pythonProgram : phpProgram;
    const args = target === 'python' ? ['-I', '-c', program] : ['-r', program];
    args.push(divergent.output, JSON.stringify({ calls: [{ name: 'spin', args: [{ nat: '0' }] }] }));
    const timed = spawnSync(command, args, { env, encoding: 'utf8', timeout: 1000, maxBuffer: 1024 * 1024 });
    assert.equal(timed.error?.code, 'ETIMEDOUT',
      'ordinary divergence must time out externally rather than return a witness or hit stack/runtime fuel');
    retain(divergent, { externalTimeoutMs: 1000, signal: timed.signal, error: timed.error.code });

    const before = read(abi.output + '.bundle.json');
    const companions = target === 'python' ? [abi.output, abi.output.replace(/\.py$/, '.pyi')]
      : [abi.output, abi.output.replace(/\.php$/, '.composer.json')];
    companions.push(abi.output + '.origins.json');
    const bytes = companions.map(file => [file, read(file)]);
    reject([...abi.args, '--assurance', 'verified']);
    const brokenEnv = { ...env, [target === 'python' ? 'PSC1_PYTHON' : 'PSC1_PHP']: '/bin/false' };
    reject(abi.args, { env: brokenEnv });
    reject(abi.args, { env: { ...env, PSC1_TEST_PUBLICATION_FAIL_AT: 'before-commit' } });
    fs.writeFileSync(abiSource, 'def wrong : Nat := true\n');
    reject(abi.args);
    assert.equal(read(abi.output + '.bundle.json'), before);
    for (const [file, content] of bytes) assert.equal(read(file), content);
    records.push({ group: target + '-failure-preservation', target, passed: true });

    for (const [label, body] of [
      ['unknown-axiom', 'axiom mystery : Nat\n'],
      ['unsafe', 'unsafe def danger : Nat := 1\n'],
      ['hole', 'def hole : Nat := _\n'],
      ['generic-public', 'def id {a : Type} (value : a) : a := value\n'],
      ...['UInt8', 'UInt64', 'Int64', 'Float', 'Float32'].map(type =>
        [type, 'def identity (value : ' + type + ') : ' + type + ' := value\n'])
    ]) {
      const output = path.join(work, 'refused-' + target + '-' + label + (target === 'python' ? '.py' : '.php'));
      reject(['build', source('bad-' + target + '-' + label + '.lean', body),
        '--target', target, '--out', output]);
      assert.equal(fs.existsSync(output), false);
      assert.equal(fs.existsSync(output + '.bundle.json'), false);
    }
    records.push({ group: target + '-negative-source-and-capability-boundaries', target, passed: true });
  }
} finally {
  fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify({
    schema: 'psc1-script-backend-execution/1', commit: process.env.GITHUB_SHA || null, records
  }, null, 2) + '\n');
  fs.rmSync(work, { recursive: true, force: true });
}
