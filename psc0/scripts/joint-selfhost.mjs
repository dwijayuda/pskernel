import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { copyFile, mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildChecked, defaultCheckedSeed } from './checked-build.mjs';
import { analyzeKernelClosure, kernelEntryRelative } from './joint-kernel-closure.mjs';
import { assertBootstrapWorkspaceManifest } from './bootstrap-manifest.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';
import { checkCoreAdmissions } from './checked-kernel-core.mjs';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'dist/joint-kernel');
const compiler = path.join(root, 'dist/checked/pskernel-core/bootstrap/packages/compiler/index.js');
const native = path.join(root, '.lake/build/bin/psc_kernel_core_provider' +
  (process.platform === 'win32' ? '.exe' : ''));
const baseline = JSON.parse(await readFile(
  path.join(root, 'docs/continuity/PSC0_SOURCE_TREE_BASELINE.json'), 'utf8'));
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const relative = p => path.relative(root, p).replaceAll(path.sep, '/');

function run(command, args, timeout = 3600000) {
  console.log('PSC0_JOINT_RUN: ' + command + ' ' + args.join(' '));
  const result = spawnSync(command, args, {
    cwd: root, stdio: 'inherit', timeout, windowsHide: true,
    env: { ...process.env, PSC0_JOINT_CHECKING: '1' },
  });
  if (result.error || result.status !== 0) {
    throw new Error('PSC0_JOINT_PROCESS_FAILED: ' + command + ' ' + args.join(' ') +
      ' result=' + String(result.error?.message ?? result.signal ?? result.status));
  }
}

async function digestFile(file) { return hash(await readFile(file)); }
async function readJson(file) { return JSON.parse(await readFile(file, 'utf8')); }

async function assertCompilerReceipt() {
  if (!existsSync(compiler)) throw new Error('PSC0_JOINT_COMPILER_NOT_BOOTSTRAPPED');
  const receipt = await readJson(compiler.replace(/\.js$/u, '.checked.json'));
  const provider = checkedKernelIdentity('pskernel-core');
  for (const [name, value] of Object.entries(provider)) {
    if (receipt.provider?.[name] !== value) throw new Error('PSC0_JOINT_COMPILER_PROVIDER_MISMATCH: ' + name);
  }
  if (receipt.kind !== 'psc2-checked-build' || receipt.schemaVersion !== 3 ||
      receipt.sourceCount !== baseline.sourceCount ||
      receipt.typeScriptSha256 !== baseline.originalCompilerTypeScriptSha256 ||
      (await digestFile(compiler)) !== receipt.javaScriptSha256 ||
      (await digestFile(compiler.replace(/\.js$/u, '.ts'))) !== receipt.typeScriptSha256 ||
      (await digestFile(compiler.replace(/\.js$/u, '.admissions.json'))) !== receipt.canonicalAdmissionsSha256) {
    throw new Error('PSC0_JOINT_COMPILER_BASELINE_MISMATCH');
  }
  // Cached receipts do not authorize unchecked compiler code. Always
  // re-admit the same immutable canonical admissions under the currently
  // selected native PSKernel Core before using any cached compiler artifact.
  const admissions = await readFile(compiler.replace(/\.js$/u, '.admissions.json'), 'utf8');
  const latest = checkCoreAdmissions(admissions, { timeoutMs: 60000 });
  if (latest.accepted !== true) {
    throw new Error('PSC0_JOINT_CACHED_COMPILER_NATIVE_REJECTION: ' +
      String(latest.declarationIndex ?? '-') + ' ' +
      String(latest.message ?? latest.errorKind));
  }
  return receipt;
}

async function assertKernelOutput(js, receipt, manifest, compilerSha) {
  if (receipt.kind !== 'psc2-checked-build' || receipt.schemaVersion !== 3 ||
      receipt.sourceCount !== manifest.sourceCount ||
      receipt.sourceClosureSha256 !== manifest.closureSha256 ||
      receipt.compiler?.sha256 !== compilerSha ||
      receipt.provider?.provider !== 'pskernel-core-native' ||
      (await digestFile(js)) !== receipt.javaScriptSha256 ||
      (await digestFile(js.replace(/\.js$/u, '.ts'))) !== receipt.typeScriptSha256 ||
      (await digestFile(js.replace(/\.js$/u, '.admissions.json'))) !== receipt.canonicalAdmissionsSha256) {
    throw new Error('PSC0_JOINT_KERNEL_CHECKED_ARTIFACT_INVALID: ' + relative(js));
  }
}

async function loadManifest(workspace, generation) {
  const manifest = await readJson(path.join(workspace,
    generation === 'bootstrap' ? '.proofscript-bootstrap.json' : '.proofscript-selfhost.json'));
  await assertBootstrapWorkspaceManifest(workspace, manifest, generation);
  if (manifest.entry !== kernelEntryRelative.replace(/\.lean$/u, '.ps')) {
    throw new Error('PSC0_JOINT_KERNEL_ENTRY_DRIFT');
  }
  return manifest;
}

async function ensureCompiler() {
  // Preserve the immutable historical compiler source; never import kernel into it.
  run(process.execPath, ['scripts/selfhost-baseline.mjs', '--assert-unchanged'], 10000);
  if (!existsSync(compiler)) {
    run(process.execPath, ['scripts/checked-selfhost.mjs', 'bootstrap', '--kernel', 'pskernel-core', '--fast'], 1200000);
  }
  return assertCompilerReceipt();
}

// Fully validated Lean-native PSC0 emission is the TypeScript/JavaScript
// reference. The generated-JS compiler must still independently prepare,
// elaborate, admit and emit the same TypeScript source: it cannot inherit
// this checking decision. Identical bytes may share one expensive pinned
// TypeScript 5.8.3 compile, without disabling its strict type checker.
async function generate() {
  const kernelSource = await analyzeKernelClosure();
  await ensureCompiler();
  const compilerSha = await digestFile(compiler);
  const nativeSha = await digestFile(native);
  const nativeJs = path.join(out, 'native/kernel/index.js');
  const nativeTs = path.join(out, 'native/kernel/index.ts');
  const nativeAdmissionsPath = path.join(out, 'native/kernel/index.admissions.json');
  const nativeReceiptPath = path.join(out, 'native/kernel/index.checked.json');
  for (const required of [nativeJs, nativeTs, nativeAdmissionsPath, nativeReceiptPath]) {
    if (!existsSync(required)) {
      throw new Error('PSC0_JOINT_NATIVE_REFERENCE_MISSING: ' + relative(required));
    }
  }
  const reference = await readJson(nativeReceiptPath);
  const nativeSnapshot = await readCheckedSourceSnapshot(path.join(root, kernelEntryRelative));
  const expectedProvider = checkedKernelIdentity('pskernel-core');
  if (reference.kind !== 'psc2-checked-build' || reference.schemaVersion !== 3 ||
      reference.compiler?.engine !== 'native-seed' ||
      reference.compiler?.sha256 !== await digestFile(defaultCheckedSeed) ||
      reference.sourceCount !== kernelSource.moduleCount ||
      reference.sourceClosureSha256 !== nativeSnapshot.closureSha256 ||
      (await digestFile(nativeTs)) !== reference.typeScriptSha256 ||
      (await digestFile(nativeJs)) !== reference.javaScriptSha256 ||
      (await digestFile(nativeAdmissionsPath)) !== reference.canonicalAdmissionsSha256 ||
      Object.entries(expectedProvider).some(([field, value]) => reference.provider?.[field] !== value)) {
    throw new Error('PSC0_JOINT_NATIVE_REFERENCE_INVALID');
  }
  // A cached native receipt never authorizes the JS compiler or checker:
  // re-admit the canonical stream with the current native provider.
  const nativeDecision = checkCoreAdmissions(await readFile(nativeAdmissionsPath, 'utf8'));
  if (!nativeDecision.accepted) {
    throw new Error('PSC0_JOINT_NATIVE_REFERENCE_KERNEL_REJECTED: ' +
      String(nativeDecision.errorKind ?? nativeDecision.message));
  }
  console.log('PSC0_JOINT_NATIVE_REFERENCE: PASS typeScriptBytes=' +
    (await readFile(nativeTs)).length + ' admissionsSha256=' + reference.canonicalAdmissionsSha256);

  const bootstrapWorkspace = path.join(out, 'bootstrap/workspace');
  const selfhostWorkspace = path.join(out, 'selfhost/workspace');
  const bootstrapTs = path.join(out, 'bootstrap/source/index.ts');
  const selfhostTs = path.join(out, 'selfhost/source/index.ts');
  const bootstrapJs = path.join(out, 'bootstrap/kernel/index.js');
  const selfhostJs = path.join(out, 'selfhost/kernel/index.js');
  run(process.execPath, [
    'scripts/bootstrap-project.mjs', kernelEntryRelative, relative(bootstrapWorkspace),
  ], 1800000);
  const firstManifest = await loadManifest(bootstrapWorkspace, 'bootstrap');
  if (firstManifest.sourceCount !== kernelSource.moduleCount) {
    throw new Error('PSC0_JOINT_KERNEL_SOURCE_COUNT_MISMATCH');
  }
  const sourceKey = hash([
    'psc0-joint-source-equivalent/2', kernelSource.sourceSha256,
    firstManifest.closureSha256, compilerSha, nativeSha,
    reference.typeScriptSha256, reference.canonicalAdmissionsSha256,
    JSON.stringify(expectedProvider),
  ].join('\n'));
  const evidencePath = path.join(out, 'kernel-fixed-point.json');
  let previous;
  try { previous = await readJson(evidencePath); } catch { /* fresh */ }
  if (previous?.sourceKey !== sourceKey) previous = undefined;

  async function assertCheckedSource(tsFile, receipt, manifest, label) {
    if (receipt.kind !== 'psc2-checked-typescript' ||
        receipt.schemaVersion !== 3 || receipt.emission !== 'typescript-only' ||
        receipt.compiler?.engine !== 'generated-js' ||
        receipt.compiler?.sha256 !== compilerSha ||
        receipt.sourceCount !== manifest.sourceCount ||
        receipt.sourceClosureSha256 !== manifest.closureSha256 ||
        receipt.typeScriptSha256 !== await digestFile(tsFile) ||
        receipt.canonicalAdmissionsSha256 !==
          await digestFile(tsFile.replace(/\.ts$/u, '.admissions.json')) ||
        Object.entries(expectedProvider).some(([field, value]) => receipt.provider?.[field] !== value)) {
      throw new Error('PSC0_JOINT_GENERATED_SOURCE_RECEIPT_INVALID: ' + label);
    }
    if (receipt.typeScriptSha256 !== reference.typeScriptSha256) {
      throw new Error('PSC0_JOINT_GENERATED_TYPESCRIPT_NOT_EQUIVALENT: ' + label +
        ' generated=' + receipt.typeScriptSha256 + ' native=' + reference.typeScriptSha256);
    }
    if (receipt.canonicalAdmissionsSha256 !== reference.canonicalAdmissionsSha256) {
      throw new Error('PSC0_JOINT_GENERATED_ADMISSIONS_NOT_EQUIVALENT: ' + label +
        ' generated=' + receipt.canonicalAdmissionsSha256 +
        ' native=' + reference.canonicalAdmissionsSha256);
    }
    // A reused receipt must never substitute for the current kernel:
    // recheck its independently generated canonical admissions.
    const decision = checkCoreAdmissions(await readFile(
      tsFile.replace(/\.ts$/u, '.admissions.json'), 'utf8'));
    if (!decision.accepted) {
      throw new Error('PSC0_JOINT_GENERATED_ADMISSIONS_REJECTED: ' + label + ' ' +
        String(decision.declarationIndex ?? '-') + ' ' +
        String(decision.message ?? decision.errorKind));
    }
    console.log('PSC0_JOINT_GENERATED_SOURCE_PARITY: PASS generation=' + label +
      ' typescriptSha256=' + receipt.typeScriptSha256);
  }
  async function generateCheckedSource(entry, tsFile, manifest, generation) {
    let receipt;
    if (previous?.[generation + 'SourceChecked'] && existsSync(tsFile) &&
        existsSync(tsFile.replace(/\.ts$/u, '.checked.json'))) {
      try {
        receipt = await readJson(tsFile.replace(/\.ts$/u, '.checked.json'));
        await assertCheckedSource(tsFile, receipt, manifest, generation);
        console.log('PSC0_JOINT_REUSE_GENERATED_SOURCE: PASS ' + generation);
        return receipt;
      } catch (error) {
        console.log('PSC0_JOINT_CACHE_REJECTED: ' + String(error.message).slice(0, 250));
        receipt = undefined;
      }
    }
    await mkdir(path.dirname(tsFile), { recursive: true });
    receipt = await buildChecked({
      entryPath: entry,
      compilerPath: compiler,
      outputPath: tsFile,
      emission: 'typescript-only',
      kernel: 'pskernel-core',
    });
    await assertCheckedSource(tsFile, receipt, manifest, generation);
    return receipt;
  }
  async function shareCompiledJavaScript(tsFile, target) {
    if (await digestFile(tsFile) !== reference.typeScriptSha256) {
      throw new Error('PSC0_JOINT_UNCHECKED_JS_REUSE_FORBIDDEN');
    }
    await mkdir(path.dirname(target), { recursive: true });
    await copyFile(nativeJs, target);
    if (await digestFile(target) !== reference.javaScriptSha256) {
      throw new Error('PSC0_JOINT_COPIED_JAVASCRIPT_MISMATCH');
    }
    run(process.execPath, ['scripts/psc1kernel-generated-smoke.mjs', relative(target)], 300000);
  }

  const first = await generateCheckedSource(
    path.join(bootstrapWorkspace, firstManifest.entry), bootstrapTs, firstManifest, 'bootstrap');
  await shareCompiledJavaScript(bootstrapTs, bootstrapJs);
  const baseEvidence = {
    schemaVersion: 2,
    status: 'bootstrap-source-equivalent',
    sourceKey, kernelSourceSha256: kernelSource.sourceSha256,
    sourceCount: firstManifest.sourceCount, kernelClosureSha256: firstManifest.closureSha256,
    nativeProviderSha256: nativeSha, checkedCompilerSha256: compilerSha,
    nativeReferenceTypeScriptSha256: reference.typeScriptSha256,
    nativeReferenceJavaScriptSha256: reference.javaScriptSha256,
    nativeReferenceAdmissionsSha256: reference.canonicalAdmissionsSha256,
    bootstrapSourceChecked: true,
    bootstrapTypeScriptSha256: first.typeScriptSha256,
    bootstrapJavaScriptSha256: reference.javaScriptSha256,
    generatedCompilerSelfhost: true,
    // A generated JS kernel has not yet checked the compiler. Code is copied
    // from a FULLY typechecked native-reference TS source after independent
    // generated-JS source byte equality, not recompiled a second time.
    javaScriptProvenance: 'verified-native-tsc-output-of-byte-identical-generated-typescript',
    generatedKernelAdmitsCompiler: false,
    jointCheckerFixedPoint: false,
  };
  await mkdir(out, { recursive: true });
  await writeFile(evidencePath, JSON.stringify(baseEvidence, null, 2) + '\n');

  run(process.execPath, [
    'scripts/reemit-project-with-generated.mjs', relative(compiler),
    relative(bootstrapWorkspace), relative(selfhostWorkspace),
  ], 1200000);
  run(process.execPath, [
    'scripts/compare-source-workspaces.mjs',
    relative(bootstrapWorkspace), relative(selfhostWorkspace),
  ], 300000);
  const secondManifest = await loadManifest(selfhostWorkspace, 'selfhost');
  if (firstManifest.closureSha256 !== secondManifest.closureSha256) {
    throw new Error('PSC0_JOINT_KERNEL_SOURCE_FIXED_POINT_MISMATCH');
  }
  const second = await generateCheckedSource(
    path.join(selfhostWorkspace, secondManifest.entry), selfhostTs, secondManifest, 'selfhost');
  run(process.execPath, [
    'scripts/compare-selfhost.mjs', relative(bootstrapTs), relative(selfhostTs),
  ], 300000);
  await shareCompiledJavaScript(selfhostTs, selfhostJs);
  if (first.typeScriptSha256 !== second.typeScriptSha256 ||
      first.canonicalAdmissionsSha256 !== second.canonicalAdmissionsSha256) {
    throw new Error('PSC0_JOINT_SOURCE_OR_ADMISSIONS_FIXED_POINT_MISMATCH');
  }
  const final = {
    ...baseEvidence,
    status: 'kernel-generated-fixed-point',
    kernelSourceFixedPoint: true,
    kernelEmittedFixedPoint: true,
    kernelGeneratedRuntimeSmoke: true,
    selfhostSourceChecked: true,
    selfhostTypeScriptSha256: second.typeScriptSha256,
    selfhostJavaScriptSha256: reference.javaScriptSha256,
  };
  await writeFile(evidencePath, JSON.stringify(final, null, 2) + '\n');
  console.log('PSC0_JOINT_KERNEL_SOURCE_AND_GENERATED_FIXED_POINT: PASS sourceModules=' +
    firstManifest.sourceCount + ' execution=' + final.javaScriptProvenance);
  console.log('PSC0_JOINT_FULL_CHECKER_PROMOTION: NOT_YET (JS checker must replay compiler admissions)');
}

async function exportGeneratedPrelude() {
  const preludePath = path.join(out, 'checked-prelude.json');
  await mkdir(path.dirname(preludePath), { recursive: true });
  run('lake', ['build', 'psc2_joint_closure_inventory'], 300000);
  run('lake', ['exe', 'psc2_joint_closure_inventory', '--prelude', relative(preludePath)], 300000);
  const prelude = await readJson(preludePath);
  if (!Array.isArray(prelude) || prelude.length < 1 ||
      prelude.some(d => typeof d.name !== 'string' ||
        !d.nameWire || !Array.isArray(d.levelParameterWires))) {
    throw new Error('PSC0_JOINT_STRUCTURED_PRELUDE_INVALID');
  }
  return preludePath;
}

async function runGeneratedChecker(kernelJs, preludePath, admissionsText, maxMillis) {
  const result = spawnSync(process.execPath,
    ['scripts/generated-core-provider-cli.mjs', relative(kernelJs), relative(preludePath),
      admissionsText === null ? '--selftest' : '--check'], {
      cwd: root,
      input: admissionsText ?? undefined,
      encoding: 'utf8',
      maxBuffer: 4 * 1024 * 1024,
      timeout: maxMillis,
      windowsHide: true,
      env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=6144' },
    });
  if (result.error || result.status !== 0) {
    throw new Error('PSC0_JOINT_GENERATED_CHECKER_PROCESS_FAILED: ' +
      String(result.error?.code ?? result.signal ?? result.status));
  }
  let response;
  try { response = JSON.parse(result.stdout); }
  catch { throw new Error('PSC0_JOINT_GENERATED_CHECKER_RESPONSE_JSON'); }
  if (response.protocol !== 'pskernel-core-generated/1' ||
      response.provider !== 'pskernel-core-js-candidate' ||
      typeof response.accepted !== 'boolean') {
    throw new Error('PSC0_JOINT_GENERATED_CHECKER_RESPONSE_INVALID');
  }
  return response;
}

async function verifyGeneratedChecker() {
  const kernelJs = path.join(out, 'selfhost/kernel/index.js');
  const checkedCompiler = await assertCompilerReceipt();
  if (!existsSync(kernelJs) || !existsSync(out + '/kernel-fixed-point.json')) {
    throw new Error('PSC0_JOINT_GENERATED_KERNEL_NOT_READY');
  }
  const previous = await readJson(path.join(out, 'kernel-fixed-point.json'));
  if (previous.status !== 'kernel-generated-fixed-point' ||
      !(await digestFile(kernelJs) === previous.selfhostJavaScriptSha256)) {
    throw new Error('PSC0_JOINT_GENERATED_KERNEL_RECEIPT_MISMATCH');
  }
  const preludePath = await exportGeneratedPrelude();
  const empty = await runGeneratedChecker(kernelJs, preludePath, null, 900000);
  if (!empty.accepted) {
    throw new Error('PSC0_JOINT_GENERATED_CHECKER_EMPTY_PRELUDE_FAILED: ' +
      String(empty.message ?? empty.errorKind));
  }
  console.log('PSC0_JOINT_GENERATED_CHECKER_EMPTY_PRELUDE: PASS');
  const compilerAdmissionsPath = path.join(root,
    'dist/checked/pskernel-core/bootstrap/packages/compiler/index.admissions.json');
  const admissions = await readFile(compilerAdmissionsPath, 'utf8');
  if (hash(admissions) !== checkedCompiler.canonicalAdmissionsSha256) {
    throw new Error('PSC0_JOINT_COMPILER_ADMISSIONS_CHANGED');
  }
  const result = await runGeneratedChecker(kernelJs, preludePath, admissions, 2400000);
  if (!result.accepted) {
    throw new Error('PSC0_JOINT_GENERATED_CHECKER_COMPILER_REJECTED: ' +
      String(result.declarationIndex ?? '-') + ' ' +
      String(result.message ?? result.errorKind));
  }
  console.log('PSC0_JOINT_GENERATED_CHECKER_ADMITS_COMPILER: PASS');
  const receipt = { ...previous, generatedKernelAdmitsCompiler: true,
    // A generated checker admitting the compiler is necessary but does not
    // prove the *repeated joint compiler+kernel checker* fixed point.
    jointCheckerFixedPoint: false,
    generatedCheckerProvider: 'pskernel-core-js-candidate',
    checkedCompilerAdmissionsSha256: hash(admissions),
    checkedPreludeSha256: await digestFile(preludePath) };
  await writeFile(path.join(out, 'kernel-fixed-point.json'),
    JSON.stringify(receipt, null, 2) + '\n');
}


// Fast capability proof: the PSC0 compiler authored in Lean is compiled
// *natively* for this stage, while PSKernel Core remains its independent
// native checker. Produces executable JS kernel source without trusting an
// unbounded generated-JS compiler run. It is NOT a joint self-host fixed point.
async function generateNative() {
  run(process.execPath, ['scripts/selfhost-baseline.mjs', '--assert-unchanged'], 10000);
  const closure = await analyzeKernelClosure();
  const entry = path.join(root, kernelEntryRelative);
  run('lake', ['build', 'psc_kernel_core_provider'], 600000);
  const host = spawnSync('lake', ['build', 'psc2_lean_checked_seed'], {
    cwd: path.join(root, 'lean-checked'), stdio: 'inherit',
    timeout: 600000, windowsHide: true,
  });
  if (host.error || host.status !== 0) {
    throw new Error('PSC0_JOINT_NATIVE_SEED_BUILD_FAILED: ' +
      String(host.error?.message ?? host.signal ?? host.status));
  }
  const snapshot = await readCheckedSourceSnapshot(entry);
  if (snapshot.ordered.length !== closure.moduleCount || snapshot.kind !== 'lean') {
    throw new Error('PSC0_JOINT_NATIVE_KERNEL_SOURCE_CLOSURE_MISMATCH');
  }
  const output = path.join(out, 'native/kernel/index.js');
  await mkdir(path.dirname(output), { recursive: true });
  const receipt = await buildChecked({
    entryPath: entry, outputPath: output, seedPath: defaultCheckedSeed,
    kernel: 'pskernel-core',
  });
  if (receipt.kind !== 'psc2-checked-build' ||
      receipt.schemaVersion !== 3 ||
      receipt.sourceCount !== closure.moduleCount ||
      receipt.sourceClosureSha256 !== snapshot.closureSha256 ||
      receipt.compiler?.engine !== 'native-seed' ||
      receipt.provider?.provider !== 'pskernel-core-native' ||
      (await digestFile(output)) !== receipt.javaScriptSha256 ||
      (await digestFile(output.replace(/\.js$/u, '.ts'))) !== receipt.typeScriptSha256 ||
      (await digestFile(output.replace(/\.js$/u, '.admissions.json'))) !== receipt.canonicalAdmissionsSha256) {
    throw new Error('PSC0_JOINT_NATIVE_KERNEL_CHECKED_RESULT_INVALID');
  }
  run(process.execPath, ['scripts/psc1kernel-generated-smoke.mjs', relative(output)], 300000);
  const evidence = {
    schemaVersion: 1, status: 'native-psc0-compiler-kernel-generated',
    // Kernel is generated by the Lean-native execution of PSC0's compiler,
    // checked by PSKernel Core, NOT by an independently generated JS checker.
    generatedCompilerSelfhost: false, generatedKernelAdmitsCompiler: false,
    jointCheckerFixedPoint: false,
    compilerSeedSha256: await digestFile(defaultCheckedSeed),
    nativeCheckerSha256: await digestFile(native),
    kernelSourceSha256: closure.sourceSha256,
    sourceClosureSha256: snapshot.closureSha256,
    sourceCount: closure.moduleCount,
    checkedAdmissionsSha256: receipt.canonicalAdmissionsSha256,
    generatedJavaScriptSha256: receipt.javaScriptSha256,
    generatedTypeScriptSha256: receipt.typeScriptSha256,
  };
  await writeFile(path.join(out, 'kernel-native-generation.json'),
    JSON.stringify(evidence, null, 2) + '\n');
  console.log('PSC0_JOINT_NATIVE_CHECKED_KERNEL_GENERATION: PASS modules=' +
    closure.moduleCount + ' output=' + relative(output));
}

// Independent, bounded checking tests using the actual executable JS kernel
// already produced by the successful native PSC0 route. These do not assume
// the generated-JS PSC0 compiler's slow kernel build has completed.
async function verifyNativeGeneratedChecker() {
  const nativeJs = path.join(out, 'native/kernel/index.js');
  const receiptPath = path.join(out, 'native/kernel/index.checked.json');
  const admissionsFile = path.join(out, 'native/kernel/index.admissions.json');
  if (![nativeJs, receiptPath, admissionsFile].every(existsSync)) {
    throw new Error('PSC0_JOINT_NATIVE_CONFORMANCE_INPUT_MISSING');
  }
  const receipt = await readJson(receiptPath);
  const wireText = await readFile(admissionsFile, 'utf8');
  if (receipt.kind !== 'psc2-checked-build' || receipt.schemaVersion !== 3 ||
      receipt.compiler?.engine !== 'native-seed' ||
      receipt.provider?.provider !== 'pskernel-core-native' ||
      (await digestFile(nativeJs)) !== receipt.javaScriptSha256 ||
      hash(wireText) !== receipt.canonicalAdmissionsSha256) {
    throw new Error('PSC0_JOINT_NATIVE_CONFORMANCE_RECEIPT_INVALID');
  }
  const nativeFull = checkCoreAdmissions(wireText);
  if (!nativeFull.accepted) {
    throw new Error('PSC0_JOINT_NATIVE_KERNEL_SOURCE_REJECTED');
  }
  const prelude = await exportGeneratedPrelude();
  const wire = JSON.parse(wireText);
  if (wire.version !== 2 || wire.format !== 'proofscript-checked-admissions' ||
      !Array.isArray(wire.admissions) || wire.admissions.length === 0) {
    throw new Error('PSC0_JOINT_NATIVE_SOURCE_WIRE_UNEXPECTED');
  }
  const smallPositive = JSON.stringify({
    format: wire.format, version: 2, admissions: [wire.admissions[0]],
  });
  const cases = [
    { name: 'empty', wire: JSON.stringify({ format: wire.format, version: 2, admissions: [] }), accept: true },
    { name: 'first-kernel-declaration', wire: smallPositive, accept: true },
    { name: 'wrong-version', wire: JSON.stringify({ format: wire.format, version: 1, admissions: [] }), accept: false },
    { name: 'unknown-admission', wire: JSON.stringify({ format: wire.format, version: 2,
      admissions: [{ kind: 'unknown', declaration: {} }] }), accept: false },
    { name: 'empty-inductive', wire: JSON.stringify({ format: wire.format, version: 2,
      admissions: [{ kind: 'inductive', declaration: { lp: [], np: 0, ts: [] } }] }), accept: false },
  ];
  for (const item of cases) {
    const nativeDecision = checkCoreAdmissions(item.wire);
    const jsDecision = await runGeneratedChecker(nativeJs, prelude, item.wire, 300000);
    if (nativeDecision.accepted !== item.accept || jsDecision.accepted !== item.accept) {
      throw new Error('PSC0_JOINT_NATIVE_JS_CONFORMANCE_DISAGREEMENT: ' + item.name +
        ' native=' + String(nativeDecision.accepted) + ' js=' + String(jsDecision.accepted) +
        ' error=' + String(jsDecision.message ?? jsDecision.errorKind));
    }
    console.log('PSC0_JOINT_NATIVE_JS_DIFFERENTIAL: PASS case=' + item.name +
      ' accepted=' + String(item.accept));
  }
  console.log('PSC0_JOINT_NATIVE_JS_DIFFERENTIAL_CORPUS: PASS cases=' + cases.length +
    ' (limited conformance evidence; NOT full generated checker promotion)');
}

const mode = process.argv[2] ?? 'generate';
if (mode === 'preflight') {
  const report = await analyzeKernelClosure();
  console.log('PSC0_JOINT_PREFLIGHT: PASS sourceModules=' + report.moduleCount +
    ' sourceSha256=' + report.sourceSha256);
} else if (mode === 'generate') {
  await generate();
} else if (mode === 'generate-native') {
  await generateNative();
} else if (mode === 'verify-generated') {
  await verifyGeneratedChecker();
} else if (mode === 'verify-native-generated') {
  await verifyNativeGeneratedChecker();
} else {
  throw new Error('usage: joint-selfhost.mjs preflight|generate|generate-native|verify-generated|verify-native-generated');
}
