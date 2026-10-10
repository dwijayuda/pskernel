import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { loadGeneratedCompiler, readBootstrapClosure } from './sh1-source-snapshot.mjs';
import { readProofScriptImports } from './proofscript-source.mjs';
import { resolveTypeScriptCli } from './typescript-cli.mjs';
import { unwrap, valueTag } from './sh1-capabilities.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const identifier = /^[A-Za-z_$][A-Za-z0-9_$]*$/u;
const sorted = values => [...values].sort();

function compilerList(compiler, values) {
  return values.reduceRight((tail, head) => compiler.List.cons(head, tail), compiler.List.nil());
}

function options(compiler) {
  const defaults = compiler.psIrCheckDefaultOptions;
  for (const key of ['maxSteps', 'maxTypeSteps', 'maxFindings']) {
    assert.equal(typeof defaults?.[key], 'bigint', 'T1 checked IR defaults: ' + key);
  }
  return compiler.psIrCheckOptionsWithLimits(
    defaults.maxSteps, defaults.maxTypeSteps, defaults.maxFindings);
}

function prepare(compiler, sources, kind = 'proofScript') {
  const units = sources.map(source => compiler.psCompilerMakeProjectSource(
    source.sourceId, source.source, compilerList(compiler, source.exports)));
  return compiler.psCompilerPrepareProject(
    compiler.PsCompilerSourceKind[kind], compilerList(compiler, units));
}

function checkedEmission(compiler, prepared, policy = options(compiler)) {
  return compiler.psCompilerCheckedTypeScriptProjectFromPrepared(policy, prepared);
}

function inspectEmission(text, sources) {
  assert.equal(typeof text, 'string', 'project result is a JSON string');
  const result = JSON.parse(text);
  assert.equal(result.profile, 'psc-ts-library/1');
  assert.equal(typeof result.bundle, 'string');
  assert.ok(result.bundle.length > 0);
  const selectedSources = sources.filter(source => source.exports.length > 0);
  assert.equal(result.modules.length, selectedSources.length);
  assert.deepEqual(sorted(result.modules.map(module => module.sourceId)),
    sorted(selectedSources.map(source => source.sourceId)));
  const bindings = new Set();
  for (const module of result.modules) {
    const source = sources.find(source => source.sourceId === module.sourceId);
    assert.deepEqual(sorted(module.exports.map(item => item.name)), sorted(source.exports));
    for (const item of module.exports) {
      assert.ok(identifier.test(item.name), 'public identifier');
      assert.ok(identifier.test(item.binding), 'generated binding identifier');
      assert.ok(['type', 'value'].includes(item.kind), 'export kind');
      assert.ok(!bindings.has(item.binding), 'unique public binding');
      bindings.add(item.binding);
    }
  }
  return result;
}

async function command(command, args, cwd, logPrefix) {
  const result = spawnSync(command, args, {
    cwd, encoding: 'utf8', timeout: 120000, maxBuffer: 16 * 1024 * 1024,
  });
  await writeFile(logPrefix + '.stdout.log', result.stdout ?? '');
  await writeFile(logPrefix + '.stderr.log', result.stderr ?? '');
  if (result.error) throw result.error;
  assert.equal(result.status, 0,
    command + ' failed: ' + (result.stderr || result.stdout || result.signal));
  return result;
}

// This test renders the mechanically thin facade from the compiler's explicit
// export map. It never partitions emitted strings or infers ownership from names.
async function compileProject(emission, directory, tsc, tsconfig, consumer) {
  await mkdir(path.join(directory, 'src/generated'), { recursive: true });
  await writeFile(path.join(directory, 'package.json'), '{"private":true,"type":"module"}\n');
  await writeFile(path.join(directory, 'tsconfig.json'), tsconfig);
  await writeFile(path.join(directory, 'src/generated/library.ts'), emission.bundle);
  await writeFile(path.join(directory, 'emission.json'), JSON.stringify(emission, null, 2) + '\n');
  for (const module of emission.modules) {
    const facade = module.exports.map(item =>
      'export ' + (item.kind === 'type' ? 'type ' : '') +
      '{ ' + item.binding + ' as ' + item.name + " } from './generated/library.js';").join('\n') + '\n';
    await writeFile(path.join(directory, module.sourceId.replace(/\.ps$/u, '.ts')), facade);
  }
  if (consumer) await writeFile(path.join(directory, 'src/consumer.ts'), consumer);
  await command(process.execPath, [tsc, '--project', 'tsconfig.json'],
    directory, path.join(directory, 'typescript'));
  const bundlePath = path.join(directory, 'dist/generated/library.js');
  const bundle = await import(pathToFileURL(bundlePath).href);
  assert.deepEqual(sorted(Object.keys(bundle)), sorted(emission.modules.flatMap(module =>
    module.exports.filter(item => item.kind === 'value').map(item => item.binding))),
  'the bundle must not expose unchecked internal declarations or raw constructors');
  return { bundle, bundlePath };
}

export async function runT1CompilerConformance({ compilerPath, outputDirectory, phase }) {
  assert.ok(['native-generated', 'c3'].includes(phase), 'T1 phase must be explicit');
  const output = path.resolve(outputDirectory);
  await mkdir(output, { recursive: true });
  const compilerBytes = await readFile(compilerPath);
  const compilerSha256 = hash(compilerBytes);
  const closure = await readBootstrapClosure(root);
  const observations = [];
  const report = {
    schemaVersion: 1, kind: 'psc0-t1-compiler-conformance', phase,
    sourceRef: process.env.GITHUB_SHA ?? null,
    sourceClosureSha256: closure.sha256, moduleCount: closure.moduleCount,
    compilerSha256, toolchain: { node: process.version, typescript: '7.0.2' },
    kernelAdmission: 'not-attempted',
    selfHostFixedPoint: 'not-established-by-this-check',
    semanticPreservationProved: false,
    observations, passed: false,
  };
  try {
    const { compiler } = await loadGeneratedCompiler(compilerPath, { expectedSha256: compilerSha256 });
    for (const name of ['psCompilerMakeProjectSource', 'psCompilerPrepareProject',
      'psCompilerProjectAdmissionsFromPrepared', 'psCompilerCheckedTypeScriptProjectFromPrepared']) {
      assert.equal(typeof compiler[name], 'function', 'T1 compiler API ' + name);
    }
    const tsc = resolveTypeScriptCli();
    const version = await command(process.execPath, [tsc, '--version'], root,
      path.join(output, 'typescript-version'));
    assert.equal(version.stdout.trim(), 'Version 7.0.2');
    const example = path.join(root, 'examples/platform/checked-library');
    const metadata = JSON.parse(await readFile(path.join(example, 'package.json'), 'utf8'));
    const sources = await Promise.all(Object.entries(metadata.proofscript.exports).map(
      async ([sourceId, exports]) => ({
        sourceId, exports, source: await readFile(path.join(example, sourceId), 'utf8'),
      })));
    assert.deepEqual(readProofScriptImports(compiler, sources[0].source), []);
    assert.deepEqual(readProofScriptImports(compiler, sources[1].source), ['Quantity']);
    report.sources = sources.map(({ sourceId, source }) => ({ sourceId, sha256: hash(source) }));
    const prepared = unwrap(prepare(compiler, sources), 'T1_PREPARE');
    const admissions = unwrap(compiler.psCompilerProjectAdmissionsFromPrepared(prepared), 'T1_ADMISSIONS');
    assert.equal(typeof admissions, 'string');
    assert.ok(Array.isArray(JSON.parse(admissions).admissions));
    await writeFile(path.join(output, 'admissions.json'), admissions);
    report.canonicalAdmissionsSha256 = hash(admissions);
    const emission = inspectEmission(unwrap(checkedEmission(compiler, prepared), 'T1_EMIT'), sources);
    const quantityModule = emission.modules.find(module => module.sourceId === 'src/Quantity.ps');
    assert.equal(quantityModule.exports.find(item => item.name === 'Quantity').kind, 'type');
    observations.push('actual compiler prepares exact imported sources and retains selected export ownership');

    const tsconfig = await readFile(path.join(example, 'tsconfig.json'), 'utf8');
    const consumer = await readFile(path.join(example, 'src/consumer.ts'), 'utf8');
    const libraryDirectory = path.join(output, 'library');
    const { bundle, bundlePath } = await compileProject(emission, libraryDirectory, tsc, tsconfig, consumer);
    const consumerResult = await command(process.execPath, ['dist/consumer.js'],
      libraryDirectory, path.join(libraryDirectory, 'consumer'));
    assert.equal(consumerResult.stdout.trim(), 'ProofScript library answer: 42');
    observations.push('strict TS7 consumer imports both facades and shares one frozen opaque identity');
    observations.push('only selected checked value bindings are available from the bundle');

    function binding(name) {
      const selected = emission.modules.flatMap(module => module.exports).find(item => item.name === name);
      assert.equal(selected?.kind, 'value');
      assert.equal(typeof bundle[selected.binding], 'function');
      return selected.binding;
    }
    const makeBinding = binding('makeQuantity');
    const readBinding = binding('readQuantity');
    const sameBinding = binding('sameQuantity');
    const make = bundle[makeBinding], read = bundle[readBinding], same = bundle[sameBinding];
    const quantity = make(43n);
    assert.equal(read(quantity), 43n);
    assert.equal(same(quantity), quantity);
    for (const malformed of [-1n, 1, '1', null, undefined]) assert.throws(() => make(malformed));
    assert.throws(() => make());
    assert.throws(() => make(1n, 2n));
    assert.throws(() => read());
    assert.throws(() => read(quantity, quantity));
    for (const fake of [{}, Object.freeze({}), Object.create(null), new Proxy(quantity, {})]) {
      assert.throws(() => read(fake));
    }
    assert.equal(Object.isFrozen(quantity), true);
    assert.equal(Reflect.set(quantity, 'value', -1n), false);
    assert.equal(read(quantity), 43n);
    const foreign = await import(pathToFileURL(bundlePath).href + '?independent-runtime');
    assert.throws(() => read(foreign[makeBinding](1n)));
    observations.push('malformed Nat, wrong arity, forged, mutable and foreign-runtime handles are rejected');

    const zeroBudget = compiler.psIrCheckOptionsWithLimits(0n,
      compiler.psIrCheckDefaultOptions.maxTypeSteps, compiler.psIrCheckDefaultOptions.maxFindings);
    assert.equal(valueTag(checkedEmission(compiler, prepared, zeroBudget)), 'error');
    observations.push('exhausted RuntimeIR checking refuses emission');

    const invalidSelections = [
      sources.map(source => source.sourceId === 'src/Quantity.ps'
        ? { ...source, exports: [...source.exports, 'missingDeclaration'] } : source),
      sources.map(source => source.sourceId === 'src/Quantity.ps'
        ? { ...source, exports: [...source.exports, 'readQuantity'] }
        : { ...source, exports: source.exports.filter(name => name !== 'readQuantity') }),
      sources.map(source => source.sourceId === 'src/Main.ps'
        ? { ...source, exports: [...source.exports, 'internalValue'] } : source),
    ];
    for (const request of invalidSelections) {
      const result = prepare(compiler, request);
      if (valueTag(result) === 'ok') {
        assert.equal(valueTag(checkedEmission(compiler, result.value)), 'error');
      } else assert.equal(valueTag(result), 'error');
    }
    observations.push('unknown and wrong-owner exports cannot enter the public API');

    for (const source of [
      'def forbidden (n : Nat) (h : Eq n n) : Nat := n\n',
      'def forbidden (a : Type) (x : a) : a := x\n',
      'def forbidden (x : Nat) : Nat -> Nat := fun (y : Nat) => Nat.add x y\n',
    ]) {
      const unsupported = unwrap(prepare(compiler, [
        { sourceId: 'src/Unsupported.lean', source, exports: ['forbidden'] },
      ], 'lean'), 'T1_SUPPORTED_SOURCE_PREPARE');
      assert.equal(valueTag(checkedEmission(compiler, unsupported)), 'error',
        'unsupported ABI must fail after valid preparation');
    }
    observations.push('well-formed erased-proof, generic and returned-function signatures are refused at the public ABI');


    const namingSources = [{
      sourceId: 'src/Naming.ps',
      source: 'def undefined : Unit := Unit.unit\n' +
        'def toUnit(undefined : Nat) : Unit := Unit.unit\n' +
        'def pairRoundTrip(value : Nat) : Nat := Prod.fst(Prod.mk(value, value))\n' +
        'def lengthWithShadow(BigInt : Nat, text : String) : Nat := String.Internal.length(text)\n' +
        'def safeLength(text : String) : Nat := lengthWithShadow(0, text)\n' +
        'inductive Hygienic where {\n  | mk(__proto__ : Nat, tag : Nat)\n}\n' +
        'def makeHygienic(payload : Nat, marker : Nat) : Hygienic := Hygienic.mk(payload, marker)\n' +
        'def readPayload(value : Hygienic) : Nat := match value with {\n' +
        '  | Hygienic.mk payload marker => payload\n}\n' +
        'def readTag(value : Hygienic) : Nat := match value with {\n' +
        '  | Hygienic.mk payload marker => marker\n}\n',
      exports: ['undefined', 'toUnit', 'safeLength', 'pairRoundTrip', 'Hygienic', 'makeHygienic', 'readPayload', 'readTag'],
    }];
    const namingPrepared = unwrap(prepare(compiler, namingSources), 'T1_NAMING_PREPARE');
    const namingEmission = inspectEmission(
      unwrap(checkedEmission(compiler, namingPrepared), 'T1_NAMING_EMIT'), namingSources);
    const namingDirectory = path.join(output, 'naming');
    await compileProject(namingEmission, namingDirectory, tsc, tsconfig);
    const naming = await import(pathToFileURL(path.join(namingDirectory, 'dist/Naming.js')).href);
    assert.equal(Object.hasOwn(naming, 'undefined'), true);
    assert.equal(naming.undefined, undefined);
    assert.equal(naming.toUnit(1n), undefined);
    assert.throws(() => naming.toUnit(-1n));
    assert.equal(naming.safeLength(String.fromCodePoint(0x1f600) + 'a'), 2n);
    observations.push('authored top-level names and local binders cannot capture undefined or the BigInt string intrinsic');
    const hygienic = naming.makeHygienic(42n, 7n);
    assert.equal(Object.isFrozen(hygienic), true);
    assert.equal(naming.readPayload(hygienic), 42n);
    assert.equal(naming.readTag(hygienic), 7n);
    observations.push('opaque __proto__ and tag fields preserve both Nat values without object or discriminator collisions');
    assert.equal(naming.pairRoundTrip(42n), 42n);
    observations.push('private Prod construction and projection preserve namespaced builtin fields without widening the public ABI');

    const scalarSources = [{
      sourceId: 'src/Scalars.ps',
      source: 'def natIdentity(value : Nat) : Nat := value\n' +
        'def intIdentity(value : Int) : Int := value\n' +
        'def boolIdentity(value : Bool) : Bool := value\n' +
        'def stringIdentity(value : String) : String := value\n' +
        'def unitIdentity(value : Unit) : Unit := value\n',
      exports: ['natIdentity', 'intIdentity', 'boolIdentity', 'stringIdentity', 'unitIdentity'],
    }];
    const scalarPrepared = unwrap(prepare(compiler, scalarSources), 'T1_SCALAR_PREPARE');
    const scalarEmission = inspectEmission(
      unwrap(checkedEmission(compiler, scalarPrepared), 'T1_SCALAR_EMIT'), scalarSources);
    const scalarDirectory = path.join(output, 'scalars');
    await compileProject(scalarEmission, scalarDirectory, tsc, tsconfig);
    const scalar = await import(pathToFileURL(path.join(scalarDirectory, 'dist/Scalars.js')).href);
    assert.equal(scalar.natIdentity(0n), 0n);
    assert.equal(scalar.intIdentity(-5n), -5n);
    assert.equal(scalar.boolIdentity(true), true);
    assert.equal(scalar.boolIdentity(false), false);
    assert.equal(scalar.stringIdentity('ProofScript'), 'ProofScript');
    const astral = String.fromCodePoint(0x1f642);
    assert.equal(scalar.stringIdentity(astral), astral);
    assert.throws(() => scalar.stringIdentity(String.fromCharCode(0xd800)));
    assert.throws(() => scalar.stringIdentity(String.fromCharCode(0xdc00)));
    assert.equal(scalar.unitIdentity(undefined), undefined);
    for (const [name, invalid] of [
      ['natIdentity', -1n], ['natIdentity', 1], ['intIdentity', 1],
      ['boolIdentity', 1], ['stringIdentity', {}], ['unitIdentity', null],
    ]) assert.throws(() => scalar[name](invalid));
    assert.throws(() => scalar.unitIdentity());
    observations.push('the bounded Nat, Int, Bool, String and Unit ABI validates runtime values');

    assert.equal(hash(await readFile(compilerPath)), compilerSha256);
    assert.equal((await readBootstrapClosure(root)).sha256, closure.sha256);
    report.bundleSha256 = hash(emission.bundle);
    report.passed = true;
  } catch (error) {
    report.failure = { name: error.name, message: error.message };
    throw error;
  } finally {
    await writeFile(path.join(output, 'receipt.json'), JSON.stringify(report, null, 2) + '\n');
    process.stdout.write('PSC0_T1_COMPILER_CONFORMANCE: ' + JSON.stringify(report) + '\n');
  }
  return report;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2), values = {};
  while (args.length) {
    const flag = args.shift(), value = args.shift();
    const key = { '--compiler': 'compilerPath', '--out': 'outputDirectory', '--phase': 'phase' }[flag];
    assert.ok(key && value && !value.startsWith('--') && !Object.hasOwn(values, key),
      'usage: t1-compiler-conformance.mjs --compiler file.js --out directory --phase native-generated|c3');
    values[key] = value;
  }
  assert.ok(values.compilerPath && values.outputDirectory && values.phase);
  await runT1CompilerConformance(values);
}
