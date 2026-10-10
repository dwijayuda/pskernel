import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { before, test } from 'node:test';
import { buildChecked } from './checked-build.mjs';
import { coreNativeArtifactPins } from './checked-kernel-provider.mjs';

// Dedicated cloud gate: absence of a real qualified input is a failure, never a
// skip. No test double supplies compiler output or a kernel acceptance decision.
const release = JSON.parse(await readFile(new URL('../release/release.json', import.meta.url), 'utf8'));
const compilerSha256 = release.compiler.sha256;
assert.match(compilerSha256, /^[a-f0-9]{64}$/u, 'qualified release compiler pin');
const nativeArtifact = coreNativeArtifactPins[process.platform + '-' + process.arch];
assert.ok(nativeArtifact, 'integration requires a qualified native platform');
const kernelSha256 = nativeArtifact.expectedBinarySha256;
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
function requiredPath(name) {
  const value = process.env[name];
  assert.equal(typeof value, 'string', name + ' must identify the real cloud input');
  assert.ok(value.length > 0 && path.isAbsolute(value), name + ' must be an absolute path');
  assert.ok(existsSync(value), name + ' does not exist');
  return value;
}
const compilerPath = requiredPath('PSC0_PLATFORM_COMPILER');
const nativeBinaryPath = requiredPath('PSC0_TEST_KERNEL_CORE_PROVIDER_BIN');
requiredPath('PSC0_TSC');
const inputs = Object.freeze({ compilerPath, compilerSha256, nativeBinaryPath, profile: 'checked' });

before(async () => {
  assert.equal(hash(await readFile(compilerPath)), compilerSha256, 'qualified release compiler bytes');
  assert.equal(hash(await readFile(nativeBinaryPath)), kernelSha256, 'qualified native Core bytes');
});

async function project(t, kind, source = 'def answer : Nat := 42\n') {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc platform real spaces-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  await writeFile(path.join(directory, 'package.json'), '{"type":"module"}\n');
  const entryPath = path.join(directory, 'main.' + kind);
  await writeFile(entryPath, source);
  return { directory, entryPath, source };
}

function admissionReceipt(receipt) {
  assert.equal(receipt.schemaVersion, 4);
  assert.equal(receipt.kind, 'psc0-checked-build');
  assert.equal(receipt.profile, 'checked');
  assert.equal(receipt.kernelAdmissionAccepted, true);
  assert.deepEqual(receipt.extensions, []);
  assert.equal(receipt.compiler.engine, 'generated-js');
  assert.equal(receipt.compiler.sha256, compilerSha256);
  assert.equal(receipt.compiler.expectedDigestChecked, true);
  assert.equal(receipt.provider.protocol, 'pskernel-core/1');
  assert.equal(receipt.provider.provider, 'pskernel-core-native');
  assert.equal(receipt.provider.profile, 'lean4.34-core');
  assert.equal(receipt.provider.leanVersion, '4.34.0');
  assert.equal(receipt.kernel.sourceCommit, '963030dc2d154008fccc82e7c8ed29331f138799');
  assert.equal(receipt.kernel.binarySha256, kernelSha256);
  assert.equal(receipt.kernel.platform, process.platform);
  assert.equal(receipt.kernel.architecture, process.arch);
  assert.deepEqual(receipt.kernel.runtimeDependencies, nativeArtifact.dependencies);
  assert.equal(receipt.kernel.canonicalAdmissionsSha256, receipt.canonicalAdmissionsSha256);
  for (const field of ['strictSh1Qualified', 'pscvVerified', 'semanticPreservationProved']) {
    assert.equal(receipt[field], false, field + ' must not be inferred from checked admission');
  }
}

function buildReceipt(receipt, emitter = 'psCompilerCheckedTypeScriptFromPrepared') {
  admissionReceipt(receipt);
  assert.equal(receipt.runtimeIr.kind, 'psc0-runtime-ir-checked-emission');
  assert.equal(receipt.runtimeIr.emitter, emitter);
  assert.equal(receipt.runtimeIr.runtimeIrTypingAccepted, true);
  assert.equal(receipt.runtimeIr.traversalComplete, true);
  assert.equal(receipt.runtimeIr.sameOriginalIrCheckedBeforeEmission, true);
  assert.equal(receipt.runtimeIr.strictSh1Qualified, false);
  assert.equal(receipt.runtimeIr.semanticContractQualified, false);
  assert.equal(receipt.runtimeIr.sourceSha256, receipt.flattenedSourceSha256);
  assert.equal(receipt.runtimeIr.canonicalAdmissionsSha256, receipt.canonicalAdmissionsSha256);
  assert.equal(receipt.runtimeIr.typeScriptSha256, receipt.typeScriptSha256);
  for (const name of ['maxSteps', 'maxTypeSteps', 'maxFindings']) {
    assert.ok(Number.isSafeInteger(receipt.runtimeIr.options[name]) && receipt.runtimeIr.options[name] >= 0);
  }
  assert.equal(receipt.targetValidation.tool, 'typescript');
  assert.equal(receipt.targetValidation.version, '7.0.2');
  assert.equal(receipt.targetValidation.strict, true);
  assert.equal(receipt.targetValidation.noEmitOnError, true);
  assert.equal(receipt.targetValidation.semanticPreservationProved, false);
}

async function publishedFiles(outputPath, receipt, expectedNames) {
  const directory = path.dirname(outputPath);
  const stem = path.basename(outputPath).replace(/\.(?:ts|js)$/u, '');
  const receiptName = stem + '.checked.json';
  assert.deepEqual(receipt.artifacts.map(item => item.name).sort(), [...expectedNames].sort());
  const files = new Map();
  for (const artifact of receipt.artifacts) {
    const bytes = await readFile(path.join(directory, artifact.name));
    assert.equal(hash(bytes), artifact.sha256, artifact.name + ' receipt digest');
    assert.equal(bytes.length, artifact.bytes, artifact.name + ' receipt length');
    files.set(artifact.name, bytes);
  }
  const saved = await readFile(path.join(directory, receiptName));
  assert.deepEqual(JSON.parse(saved.toString('utf8')), receipt);
  files.set(receiptName, saved);
  return files;
}

// Constant syntax is exercised by checked-build.test.mjs and the qualified
// grammar gate. Nat's generated JS representation is bigint, as exercised by
// sh1-generic-erasure-conformance.mjs. These are deliberately small fixtures.
for (const [kind, invalid] of [
  ['ps', 'def answer : Nat := (\n'],
  ['lean', 'theorem invalidProof (P : Prop) (Q : Prop) (h : P) : Q := h\n'],
]) {
  test('real .' + kind + ' build, execution, and failed replacement preserve checked output', async t => {
    const fixture = await project(t, kind);
    const outputPath = path.join(fixture.directory, 'out', 'bundle.js');
    const receipt = await buildChecked({ ...inputs, entryPath: fixture.entryPath, outputPath });
    buildReceipt(receipt);
    assert.equal(receipt.sourceCount, 1);
    assert.equal(receipt.sources[0].sha256, hash(Buffer.from(fixture.source, 'utf8')));
    assert.equal(receipt.outputOwner, '../main.' + kind);
    const previous = await publishedFiles(outputPath, receipt, [
      'bundle.ts', 'bundle.js', 'bundle.d.ts', 'bundle.js.map', 'bundle.admissions.json',
    ]);
    assert.equal(hash(previous.get('bundle.ts')), receipt.typeScriptSha256);
    assert.equal(hash(previous.get('bundle.js')), receipt.javaScriptSha256);
    assert.equal(hash(previous.get('bundle.admissions.json')), receipt.canonicalAdmissionsSha256);
    assert.equal(receipt.targetValidation.generatedJavaScriptSha256, receipt.javaScriptSha256);
    assert.equal((await import(pathToFileURL(outputPath).href)).answer, 42n);

    await writeFile(fixture.entryPath, invalid);
    const refused = /PSC2_(?:SOURCE_PARSE_FAILED|CHECKED_PREPARE_FAILED|KERNEL_REJECTED)/;
    await assert.rejects(buildChecked({ ...inputs, entryPath: fixture.entryPath, outputPath }), refused);
    for (const [name, bytes] of previous) {
      assert.deepEqual(await readFile(path.join(path.dirname(outputPath), name)), bytes,
        name + ' must survive a failed rebuild');
    }
    assert.deepEqual((await readdir(path.dirname(outputPath))).sort(), [...previous.keys()].sort());
    const fresh = path.join(fixture.directory, 'failed-new', 'bundle.js');
    await assert.rejects(buildChecked({ ...inputs, entryPath: fixture.entryPath, outputPath: fresh }), refused);
    assert.equal(existsSync(path.dirname(fresh)), false, 'invalid source must not create a publication');
  });
}

test('a valid .ps module publishes only neighboring TypeScript and its receipt for .ts output', async t => {
  const fixture = await project(t, 'ps');
  const outputPath = path.join(fixture.directory, 'main.ts');
  const receipt = await buildChecked({ ...inputs, entryPath: fixture.entryPath, outputPath });
  buildReceipt(receipt);
  assert.equal(receipt.outputOwner, 'main.ps');
  await publishedFiles(outputPath, receipt, ['main.ts']);
  assert.equal(await readFile(fixture.entryPath, 'utf8'), fixture.source);
  assert.equal(hash(await readFile(outputPath)), receipt.typeScriptSha256);
  assert.equal(Object.hasOwn(receipt, 'javaScriptSha256'), false);
  assert.deepEqual((await readdir(fixture.directory)).sort(),
    ['main.checked.json', 'main.ps', 'main.ts', 'package.json']);
});

test('check-only records real admission without claiming RuntimeIR checking or publishing files', async t => {
  const fixture = await project(t, 'lean');
  const outputPath = path.join(fixture.directory, 'not-requested', 'bundle.js');
  const receipt = await buildChecked({
    ...inputs, entryPath: fixture.entryPath, outputPath, checkOnly: true,
  });
  admissionReceipt(receipt);
  assert.deepEqual(receipt.runtimeIr, { status: 'not-requested' });
  for (const field of ['artifacts', 'typeScriptSha256', 'javaScriptSha256', 'targetValidation']) {
    assert.equal(Object.hasOwn(receipt, field), false, field + ' is not evidence for check-only');
  }
  assert.equal(existsSync(path.dirname(outputPath)), false);
});

test('PSCV and contracts profiles and unsupported contract syntax fail explicitly', async t => {
  const fixture = await project(t, 'ps');
  const outputPath = path.join(fixture.directory, 'unsupported', 'bundle.js');
  for (const profile of ['pscv', 'contracts']) {
    await assert.rejects(buildChecked({
      ...inputs, entryPath: fixture.entryPath, outputPath, profile,
    }), /PSC0_PROFILE_UNAVAILABLE/);
  }
  // Exact refused syntax from sh1-grammar-conformance.mjs, contract-not-enabled.
  await writeFile(fixture.entryPath, 'function probe(x : Nat) : Nat requires { true } := x\n');
  await assert.rejects(buildChecked({
    ...inputs, entryPath: fixture.entryPath, outputPath,
  }), /PSC2_SOURCE_PARSE_FAILED/);
  assert.equal(existsSync(path.dirname(outputPath)), false);
});

test('wrong compiler hashes fail before compiler import and publication', async t => {
  const fixture = await project(t, 'ps');
  const outputPath = path.join(fixture.directory, 'wrong-compiler', 'bundle.js');
  await assert.rejects(buildChecked({
    ...inputs, entryPath: fixture.entryPath, outputPath, compilerSha256: '0'.repeat(64),
  }), /PSC0_SH1_COMPILER_PIN_MISMATCH/);

  // This is a hostile artifact fixture, never an acceptance mock. If it is
  // imported before the pinned-byte check it leaves observable evidence.
  const marker = path.join(fixture.directory, 'compiler-was-imported');
  const poisonedCompiler = path.join(fixture.directory, 'poisoned-compiler.js');
  await writeFile(poisonedCompiler,
    "import { writeFileSync } from 'node:fs';\n" +
    'writeFileSync(' + JSON.stringify(marker) + ', "imported");\n' +
    'throw new Error("UNQUALIFIED_COMPILER_EXECUTED");\n');
  await assert.rejects(buildChecked({
    ...inputs, entryPath: fixture.entryPath, outputPath, compilerPath: poisonedCompiler,
  }), /PSC0_SH1_COMPILER_PIN_MISMATCH/);
  assert.equal(existsSync(marker), false, 'unqualified compiler code must never be imported');
  assert.equal(existsSync(path.dirname(outputPath)), false);
});

test('real T1 library shares checked opaque values through two facades and preserves a rejected generation', async t => {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc real library spaces-'));
  t.after(() => rm(directory, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 }));
  const example = new URL('../examples/platform/checked-library/', import.meta.url);
  const sources = ['README.md', 'package.json', 'tsconfig.json',
    'src/Quantity.ps', 'src/Main.ps', 'src/consumer.ts'];
  for (const file of sources) {
    await mkdir(path.dirname(path.join(directory, file)), { recursive: true });
    await writeFile(path.join(directory, file), await readFile(new URL(file, example)));
  }
  const configPath = path.join(directory, 'package.json');
  const configSource = await readFile(configPath, 'utf8');
  const config = JSON.parse(configSource).proofscript;
  const outputPath = path.join(directory, config.out);
  const arguments_ = {
    ...inputs, entryPath: path.join(directory, config.entry), outputPath,
    libraryConfig: { projectRoot: directory, exports: config.exports, configPath, configSource },
  };
  const receipt = await buildChecked(arguments_);
  buildReceipt(receipt, 'psCompilerCheckedTypeScriptProjectFromPrepared');
  assert.equal(receipt.sourceCount, 2);
  assert.equal(receipt.outputOwner, config.entry);
  assert.equal(receipt.library.profile, 'psc-ts-library/1');
  assert.equal(receipt.library.abiStatus, 'checked-bounded');
  assert.equal(receipt.library.configSha256, hash(Buffer.from(configSource, 'utf8')));
  assert.equal(receipt.library.publicInterfaceSha256, receipt.runtimeIr.publicInterfaceSha256);
  assert.equal(receipt.publication.layout, 'psc-ts-library/1');
  assert.equal(receipt.publication.bundle, config.out);
  assert.deepEqual([...receipt.publication.facadeSources].sort(), Object.keys(config.exports).sort());
  assert.deepEqual(receipt.artifacts.map(item => item.name).sort(),
    [config.out, 'src/Quantity.ts', 'src/Main.ts'].sort());
  const published = new Map();
  for (const artifact of receipt.artifacts) {
    const bytes = await readFile(path.join(directory, artifact.name));
    assert.equal(hash(bytes), artifact.sha256);
    assert.equal(bytes.length, artifact.bytes);
    published.set(artifact.name, bytes);
  }
  assert.equal(hash(published.get(config.out)), receipt.typeScriptSha256);
  const receiptName = config.out.replace(/\.ts$/u, '.checked.json');
  const receiptBytes = await readFile(path.join(directory, receiptName));
  assert.deepEqual(JSON.parse(receiptBytes.toString('utf8')), receipt);
  published.set(receiptName, receiptBytes);
  const tsc = spawnSync(process.execPath, [process.env.PSC0_TSC, '--project', 'tsconfig.json'], {
    cwd: directory, encoding: 'utf8', timeout: 120000,
  });
  assert.ifError(tsc.error);
  assert.equal(tsc.status, 0, tsc.stdout + '\n' + tsc.stderr);
  const consumer = spawnSync(process.execPath, ['dist/consumer.js'], {
    cwd: directory, encoding: 'utf8', timeout: 30000,
  });
  assert.ifError(consumer.error);
  assert.equal(consumer.status, 0, consumer.stdout + '\n' + consumer.stderr);
  assert.equal(consumer.stdout.trim(), 'ProofScript library answer: 42');
  for (const file of ['package.json', 'tsconfig.json', 'src/consumer.ts']) {
    assert.deepEqual(await readFile(path.join(directory, file)), await readFile(new URL(file, example)));
  }

  const quantityPath = path.join(directory, 'src/Quantity.ps');
  const quantity = await readFile(quantityPath, 'utf8');
  const invalid = quantity.replace('Quantity.mk(value)', '0');
  assert.notEqual(invalid, quantity);
  await writeFile(quantityPath, invalid);
  await assert.rejects(buildChecked(arguments_),
    /PSC2_(?:CHECKED_(?:PROJECT_)?(?:PREPARE|EMIT)_FAILED|KERNEL_REJECTED)/u);
  for (const [file, bytes] of published) {
    assert.deepEqual(await readFile(path.join(directory, file)), bytes,
      file + ' remains the last completed checked generation');
  }
});
