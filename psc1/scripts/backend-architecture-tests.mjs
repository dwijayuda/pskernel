// Focused direct planning/publication regression. Run in Linux cloud CI only.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const native = process.env.PSC1_NATIVE || path.join(root, '.lake/build/bin/psc1');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-backend-architecture-'));
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, 'host-tools/artifacts.mjs') };
const records = [];
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const command = (cmd, args, options = {}) => {
  const result = spawnSync(cmd, args, { env, encoding: 'utf8', timeout: 120000, ...options });
  assert.equal(result.error, undefined, result.error?.message);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  return result.stdout;
};
const reject = (args, pattern, options = {}) => {
  const result = spawnSync(native, args, { env, encoding: 'utf8', timeout: 120000, ...options });
  assert.notEqual(result.status, 0);
  assert.match(result.stdout + result.stderr, pattern);
};
const read = file => fs.readFileSync(file, 'utf8');
try {
  fs.writeFileSync(path.join(work, 'package.json'), '{"type":"module"}\n');
  const input = path.join(work, 'main.lean');
  const source = 'def negate (value : Bool) : Bool := if value then false else true\n';
  fs.writeFileSync(input, source);
  const out = path.join(work, 'out');
  const args = ['build', input, '--targets', 'ts,js', '--out-dir', out];
  command(native, args);
  const stem = path.join(out, 'main');
  const receipt = stem + '.ecma.bundle.json';
  const manifest = JSON.parse(read(receipt));
  assert.equal(manifest.target, 'ecma');
  assert.deepEqual(manifest.targets, ['ts', 'js']);
  assert.equal(manifest.sharedCheckedInput, true);
  assert.equal(manifest.runtimeContract, 'psc1-runtime-semantics/1');
  assert.deepEqual(manifest.targetPlans.map(plan => plan.target), ['js', 'ts']);
  for (const plan of manifest.targetPlans) {
    assert.equal(plan.runtimeFree, true);
    assert.equal(plan.runtimeBytes, 0);
    assert.deepEqual(plan.runtimeRequirements, []);
    assert.equal(plan.runtimeSha256, digest(''));
  }
  assert.deepEqual(manifest.publicNames, ['negate']);
  assert.equal(manifest.logicalCheckerCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(manifest.behaviorallyVerified, false);
  for (const extension of ['.js', '.ts', '.d.ts', '.js.map', '.ts.map']) {
    assert.ok(fs.statSync(stem + extension).size > 0, extension);
  }
  for (const extension of ['.js', '.ts']) {
    assert.doesNotMatch(read(stem + extension), /__ps\$(run|utf8|implementations)/);
    assert.match(read(stem + extension), /function negate/);
  }
  const js = await import(pathToFileURL(stem + '.js').href);
  assert.deepEqual(Object.keys(js), ['negate']);
  assert.equal(js.negate(true), false);
  assert.equal(js.negate(false), true);
  const checker = process.env.PSC1_TSC;
  assert.ok(checker, 'the separate TypeScript consumer checker must be installed for this test');
  const consumer = path.join(work, 'consumer');
  command(process.execPath, [checker, '--ignoreConfig', stem + '.ts', '--target', 'ES2020', '--module', 'ES2022',
    '--strict', '--skipLibCheck', '--outDir', consumer]);
  const ts = await import(pathToFileURL(path.join(consumer, 'main.js')).href);
  assert.equal(ts.negate(true), false);
  assert.equal(ts.negate(false), true);
  for (const extension of ['.js', '.ts']) {
    const map = JSON.parse(read(stem + extension + '.map'));
    assert.equal(map.version, 3);
    assert.equal(map.file, 'main' + extension);
    assert.ok(map.sources.some(file => file.endsWith('main.lean')));
    assert.ok(map.sourcesContent.includes(source));
  }
  records.push({ group: 'one-admission-independent-ts-js', passed: true,
    jsBytes: fs.statSync(stem + '.js').size, tsBytes: fs.statSync(stem + '.ts').size });


  // Reserved source spellings are bindings, not host keywords. Exercise the
  // common erasure name map, collisions and both independent target consumers.
  const reservedFixtures = {
    lean: [
      'def _throw (flag : Bool) : Bool := flag',
      'def throw (flag : Bool) : Bool := if flag then false else true',
      'def keyword (flag : Bool) : Bool :=',
      '  let _throw : Bool := flag;',
      '  let throw : Bool := if flag then false else true;',
      '  let await : Bool -> Bool := fun (yield : Bool) => if yield then throw else _throw;',
      '  if flag then !(await true) && await false else await true && !(await false)',
      ''
    ].join('\n'),
    ps: [
      'def _throw(flag : Bool) : Bool := flag',
      'def throw(flag : Bool) : Bool := if (flag) { false } else { true }',
      'def keyword(flag : Bool) : Bool :=',
      '  let _throw : Bool := flag',
      '  let throw : Bool := if (flag) { false } else { true }',
      '  let await : Bool -> Bool := fun (yield : Bool) => if (yield) { throw } else { _throw }',
      '  if (flag) { !(await(true)) && await(false) } else { await(true) && !(await(false)) }',
      ''
    ].join('\n')
  };
  for (const [syntax, reservedSource] of Object.entries(reservedFixtures)) {
    const folder = path.join(work, 'reserved-' + syntax);
    fs.mkdirSync(folder, { recursive: true });
    const reservedInput = path.join(folder, 'reserved.' + syntax);
    fs.writeFileSync(reservedInput, reservedSource);
    const outputDirectory = path.join(folder, 'out');
    command(native, ['build', reservedInput, '--targets', 'ts,js', '--out-dir', outputDirectory]);
    const reservedStem = path.join(outputDirectory, 'reserved');
    const reservedManifest = JSON.parse(read(reservedStem + '.ecma.bundle.json'));
    // The existing public contract uses canonical runtime identifiers. Escaping
    // reserves _throw for its earlier authored binding and allocates _throw_ for throw.
    assert.deepEqual([...reservedManifest.publicNames].sort(), ['_throw', '_throw_', 'keyword'].sort());
    const reservedJs = await import(pathToFileURL(reservedStem + '.js').href);
    const reservedConsumer = path.join(folder, 'consumer');
    command(process.execPath, [checker, '--ignoreConfig', reservedStem + '.ts',
      '--target', 'ES2020', '--module', 'ES2022', '--strict', '--skipLibCheck', '--outDir', reservedConsumer]);
    const reservedTs = await import(pathToFileURL(path.join(reservedConsumer, 'reserved.js')).href);
    for (const [target, module] of [['js', reservedJs], ['ts', reservedTs]]) {
      assert.deepEqual(Object.keys(module).sort(), ['_throw', '_throw_', 'keyword'].sort(), target);
      for (const flag of [false, true]) {
        assert.equal(module._throw(flag), flag, target + ' authored escaped-looking global');
        assert.equal(module._throw_(flag), !flag, target + ' reserved global collision');
        assert.equal(module.keyword(flag), true, target + ' local/capture keyword shadowing');
      }
    }
    const declarations = read(reservedStem + '.d.ts');
    assert.match(declarations, /export declare function _throw\(/);
    assert.match(declarations, /export declare function _throw_\(/);
    const generation = path.dirname(fs.realpathSync(reservedStem + '.js'));
    const provenance = JSON.parse(read(path.join(generation, 'psc1-input.json')));
    const captured = provenance.sources.find(source => source.text === reservedSource);
    assert.ok(captured, 'source text remains exact');
    assert.equal(captured.origins.find(origin => origin.sourceName === '_throw')?.name, '_throw');
    assert.equal(captured.origins.find(origin => origin.sourceName === 'throw')?.name, '_throw_');
    assert.equal(read(path.join(generation, 'admissions.json')), command(native, ['admissions', reservedInput]),
      'runtime binding escape must not rewrite canonical logical declarations');
    for (const extension of ['.js', '.ts']) {
      const sourceMap = JSON.parse(read(reservedStem + extension + '.map'));
      assert.ok(sourceMap.sourcesContent.includes(reservedSource), extension + ' source identity');
    }
    records.push({ group: syntax + '-reserved-identifiers-collisions-and-origins',
      passed: true, publicNames: reservedManifest.publicNames });
  }


  // Runtime intrinsics must not resolve to legal source declarations or captures.
  // These paired sources are authored independently, not obtained by translation.
  const ambientFixtures = {
    lean: [
      'def _BigInt (n : Nat) : Nat := n',
      'def BigInt (n : Nat) : Nat := 99',
      'def globalRuntime (flag : Bool) : Bool := Nat.beq (String.Internal.length "🙂a") 2',
      'def lexicalRuntime (BigInt : Nat) (Number : Nat) (String : Nat) (Array : Nat) : Bool :=',
      '  Nat.beq (_root_.String.Internal.length "🙂a") 2 && Nat.beq (_root_.Char.toNat (_root_.Char.ofNat 65)) 65',
      'structure Labels where',
      '  BigInt : Nat',
      '  Number : Nat',
      'def labels (flag : Bool) : Bool :=',
      '  let x : Labels := Labels.mk 5 7;',
      '  Nat.beq x.BigInt 5 && Nat.beq x.Number 7',
      ''
    ].join('\n'),
    ps: [
      'def _BigInt(n : Nat) : Nat := n',
      'def BigInt(n : Nat) : Nat := 99',
      'def globalRuntime(flag : Bool) : Bool := Nat.beq(String.Internal.length("🙂a"), 2)',
      'def lexicalRuntime(BigInt : Nat, Number : Nat, String : Nat, Array : Nat) : Bool :=',
      '  Nat.beq(_root_.String.Internal.length("🙂a"), 2) && Nat.beq(_root_.Char.toNat(_root_.Char.ofNat(65)), 65)',
      'structure Labels where {',
      '  BigInt : Nat',
      '  Number : Nat',
      '}',
      'def labels(flag : Bool) : Bool :=',
      '  let x : Labels := Labels.mk(5, 7)',
      '  Nat.beq(x.BigInt, 5) && Nat.beq(x.Number, 7)',
      ''
    ].join('\n')
  };
  const hygieneFailures = [];
  for (const [syntax, ambientSource] of Object.entries(ambientFixtures)) {
    try {
    const folder = path.join(work, 'ambient-' + syntax);
    fs.mkdirSync(folder, { recursive: true });
    const ambientInput = path.join(folder, 'ambient.' + syntax);
    fs.writeFileSync(ambientInput, ambientSource);
    const outputDirectory = path.join(folder, 'out');
    command(native, ['build', ambientInput, '--targets', 'ts,js', '--out-dir', outputDirectory]);
    const ambientStem = path.join(outputDirectory, 'ambient');
    const ambientJs = await import(pathToFileURL(ambientStem + '.js').href);
    assert.equal(ambientJs.globalRuntime(false), true, 'DirectJS ambient intrinsic global capture');
    assert.equal(ambientJs.lexicalRuntime(0n, 0n, 0n, 0n), true, 'DirectJS ambient intrinsic lexical capture');
    const ambientConsumer = path.join(folder, 'consumer');
    command(process.execPath, [checker, '--ignoreConfig', ambientStem + '.ts',
      '--target', 'ES2020', '--module', 'ES2022', '--strict', '--skipLibCheck', '--outDir', ambientConsumer]);
    const ambientTs = await import(pathToFileURL(path.join(ambientConsumer, 'ambient.js')).href);
    for (const [target, module] of [['js', ambientJs], ['ts', ambientTs]]) {
      assert.equal(module._BigInt(7n), 7n, target + ' authored escaped-looking global');
      assert.equal(module._BigInt_(7n), 99n, target + ' ambient global collision');
      for (const flag of [false, true]) {
        assert.equal(module.globalRuntime(flag), true, target + ' global intrinsic hygiene');
        assert.equal(module.labels(flag), true, target + ' unchanged property labels');
      }
      assert.equal(module.lexicalRuntime(0n, 0n, 0n, 0n), true, target + ' lexical intrinsic hygiene');
    }
    const generation = path.dirname(fs.realpathSync(ambientStem + '.js'));
    assert.equal(read(path.join(generation, 'admissions.json')), command(native, ['admissions', ambientInput]));
    const provenance = JSON.parse(read(path.join(generation, 'psc1-input.json')));
    const captured = provenance.sources.find(item => item.text === ambientSource);
    assert.ok(captured);
    assert.equal(captured.origins.find(origin => origin.sourceName === 'BigInt')?.name, '_BigInt_');
    records.push({ group: syntax + '-runtime-intrinsic-hygiene', passed: true });
    } catch (error) {
      hygieneFailures.push(syntax + '-runtime-intrinsic-hygiene');
      console.error('PSC1_RUNTIME_HYGIENE_FAIL: ' + syntax + '\n' + error.stack);
    }
  }


  // __proto__ is an own source field, never an object-literal prototype setter.
  const protoFixtures = {
    lean: 'structure Labels where\n  __proto__ : Nat\n  Number : Nat\ndef labels (flag : Bool) : Bool :=\n  let x : Labels := Labels.mk 5 7;\n  Nat.beq x.__proto__ 5 && Nat.beq x.Number 7\ndef recordLabels (flag : Bool) : Bool :=\n  let x : Labels := { __proto__ := 5, Number := 7 };\n  Nat.beq x.__proto__ 5 && Nat.beq x.Number 7\n',
    ps: 'structure Labels where {\n  __proto__ : Nat\n  Number : Nat\n}\ndef labels(flag : Bool) : Bool :=\n  let x : Labels := Labels.mk(5, 7)\n  Nat.beq(x.__proto__, 5) && Nat.beq(x.Number, 7)\ndef recordLabels(flag : Bool) : Bool :=\n  let x : Labels := { __proto__ := 5, Number := 7 }\n  Nat.beq(x.__proto__, 5) && Nat.beq(x.Number, 7)\n'
  };
  for (const [syntax, protoSource] of Object.entries(protoFixtures)) {
    try {
      const folder = path.join(work, 'proto-' + syntax);
      fs.mkdirSync(folder, { recursive: true });
      const protoInput = path.join(folder, 'proto.' + syntax);
      fs.writeFileSync(protoInput, protoSource);
      const outputDirectory = path.join(folder, 'out');
      command(native, ['build', protoInput, '--targets', 'ts,js', '--out-dir', outputDirectory]);
      const protoStem = path.join(outputDirectory, 'proto');
      const protoJs = await import(pathToFileURL(protoStem + '.js').href);
      const protoConsumer = path.join(folder, 'consumer');
      command(process.execPath, [checker, '--ignoreConfig', protoStem + '.ts',
        '--target', 'ES2020', '--module', 'ES2022', '--strict', '--skipLibCheck', '--outDir', protoConsumer]);
      const protoTs = await import(pathToFileURL(path.join(protoConsumer, 'proto.js')).href);
      for (const [target, module] of [['js', protoJs], ['ts', protoTs]]) {
        assert.equal(module.labels(false), true, target + ' prototype-named source field');
        assert.equal(module.labels(true), true, target + ' prototype-named source field');
        assert.equal(module.recordLabels(false), true, target + ' prototype-named record literal');
        assert.equal(module.recordLabels(true), true, target + ' prototype-named record literal');
      }
      records.push({ group: syntax + '-prototype-property-hygiene', passed: true });
    } catch (error) {
      hygieneFailures.push(syntax + '-prototype-property-hygiene');
      console.error('PSC1_PROTOTYPE_HYGIENE_FAIL: ' + syntax + '\n' + error.stack);
    }
  }
  assert.deepEqual(hygieneFailures, [], 'all source binding/property hygiene cases must pass');

  for (const [target, extension] of [['rust', '.rs'], ['wasm-core', '.wasm']]) {
    const output = path.join(work, 'small-' + target + extension);
    command(native, ['build', input, '--target', target, '--out', output]);
    const emittedPlan = JSON.parse(read(output + '.bundle.json')).targetPlans[0];
    assert.equal(emittedPlan.runtimeFree, true, target);
    assert.deepEqual(emittedPlan.runtimeRequirements, [], target);
    if (target === 'rust') {
      assert.doesNotMatch(read(output), /num_bigint|num_traits|fn __ps_/);
      assert.doesNotMatch(read(output.replace(/\.rs$/, '.cargo/Cargo.toml')), /num-bigint|num-traits/);
    } else {
      const wasm = await WebAssembly.instantiate(fs.readFileSync(output));
      assert.equal(wasm.instance.exports.negate(1), 0);
      assert.equal(wasm.instance.exports.negate(0), 1);
    }
    records.push({ group: target + '-boolean-runtime-free', passed: true,
      artifactBytes: fs.statSync(output).size });
  }

  const before = read(receipt);
  const files = ['.js', '.ts', '.d.ts', '.js.map', '.ts.map'].map(ext => [stem + ext, read(stem + ext)]);
  command(native, args);
  assert.equal(read(receipt), before, 'same inputs produce identical generation');
  fs.writeFileSync(input, 'def negate (value : Bool) : Bool := value\n');
  reject(args, /PSC1_INJECTED_PUBLICATION_FAILURE/, {
    env: { ...env, PSC1_TEST_PUBLICATION_FAIL_AT: 'before-commit' }
  });
  assert.equal(read(receipt), before);
  for (const [file, content] of files) assert.equal(read(file), content);
  fs.writeFileSync(input, 'def bad : Nat := true\n');
  reject(args, /PSC1_|PSC2_/);
  assert.equal(read(receipt), before);
  for (const [file, content] of files) assert.equal(read(file), content);
  records.push({ group: 'atomic-pair-failure-preservation-and-determinism', passed: true });

  reject(['build', input, '--targets', 'js,js', '--out-dir', path.join(work, 'duplicate')],
    /PSC1_TARGET_SET_UNSUPPORTED/);
  reject(['build', input, '--assurance', 'verified', '--targets', 'ts,js', '--out-dir', out],
    /PSC1_VERIFIED_EXECUTION_UNAVAILABLE/);
  assert.equal(read(receipt), before);
  records.push({ group: 'combined-request-negative-boundaries', passed: true });

  const evidence = path.join(root, 'dist/scoped-correctness/backend-architecture');
  fs.mkdirSync(evidence, { recursive: true });
  fs.cpSync(path.dirname(fs.realpathSync(receipt)), path.join(evidence, 'boolean-ts-js'),
    { recursive: true });
  fs.writeFileSync(path.join(evidence, 'results.json'), JSON.stringify({
    schema: 'psc1-backend-architecture-execution/1',
    commit: process.env.GITHUB_SHA || null, node: process.version, records,
    manifestSha256: digest(before)
  }, null, 2) + '\n');
  for (const record of records) console.log('PSC1_BACKEND_ARCHITECTURE_PASS: ' + record.group);
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
