import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildChecked } from './checked-build.mjs';
import { analyzeKernelClosure, kernelEntryRelative } from './joint-kernel-closure.mjs';
import { assertBootstrapWorkspaceManifest } from './bootstrap-manifest.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';

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

async function generate() {
  const kernelSource = await analyzeKernelClosure();
  const compilerReceipt = await ensureCompiler();
  const compilerSha = await digestFile(compiler);
  const nativeSha = await digestFile(native);
  const bootstrapWorkspace = path.join(out, 'bootstrap/workspace');
  const selfhostWorkspace = path.join(out, 'selfhost/workspace');
  const bootstrapJs = path.join(out, 'bootstrap/kernel/index.js');
  const selfhostJs = path.join(out, 'selfhost/kernel/index.js');

  // Deliberately retranslate source to avoid cached output authorizing changed source.
  run(process.execPath, [
    'scripts/bootstrap-project.mjs', kernelEntryRelative, relative(bootstrapWorkspace),
  ], 1800000);
  const firstManifest = await loadManifest(bootstrapWorkspace, 'bootstrap');
  if (firstManifest.sourceCount !== kernelSource.moduleCount) {
    throw new Error('PSC0_JOINT_KERNEL_CLOSURE_SOURCE_COUNT_MISMATCH');
  }
  const sourceKey = hash([
    'psc0-joint-checked-kernel/1', kernelSource.sourceSha256,
    firstManifest.closureSha256, compilerSha, nativeSha,
    JSON.stringify(checkedKernelIdentity('pskernel-core')),
  ].join('\n'));
  const stored = path.join(out, 'kernel-fixed-point.json');
  let old;
  try { old = await readJson(stored); } catch { /* fresh build */ }
  // Reuse only if the entire checked content (including provider executable)
  // is identical and the emitted output hashes still match the checked receipts.
  if (old?.sourceKey !== sourceKey) old = null;
  let firstReceipt;
  if (old?.bootstrapChecked && existsSync(bootstrapJs)) {
    try {
      firstReceipt = await readJson(bootstrapJs.replace(/\.js$/u, '.checked.json'));
      await assertKernelOutput(bootstrapJs, firstReceipt, firstManifest, compilerSha);
      console.log('PSC0_JOINT_REUSE_CHECKED_BOOTSTRAP: PASS');
    } catch { firstReceipt = undefined; }
  }
  if (!firstReceipt) {
    await mkdir(path.dirname(bootstrapJs), { recursive: true });
    firstReceipt = await buildChecked({
      entryPath: path.join(bootstrapWorkspace, firstManifest.entry),
      compilerPath: compiler,
      outputPath: bootstrapJs,
      kernel: 'pskernel-core',
    });
    await assertKernelOutput(bootstrapJs, firstReceipt, firstManifest, compilerSha);
  }
  console.log('PSC0_JOINT_GENERATED_KERNEL_CHECKED: PASS generation=bootstrap');
  // The output is executable semantics, not merely a TypeScript emission claim.
  run(process.execPath, ['scripts/psc1kernel-generated-smoke.mjs', relative(bootstrapJs)], 300000);
  const storedBase = {
    schemaVersion: 1, status: 'incomplete',
    sourceKey, kernelSourceSha256: kernelSource.sourceSha256,
    sourceCount: firstManifest.sourceCount, kernelClosureSha256: firstManifest.closureSha256,
    nativeProviderSha256: nativeSha, checkedCompilerSha256: compilerSha,
    bootstrapChecked: true, bootstrapJavaScriptSha256: firstReceipt.javaScriptSha256,
    bootstrapTypeScriptSha256: firstReceipt.typeScriptSha256,
    // Generated-JS checker promotion requires separate canonical wire and
    // full-compiler replay evidence; it is not established by a smoke check.
    generatedKernelAdmitsCompiler: false, jointCheckerFixedPoint: false,
  };
  await mkdir(out, { recursive: true });
  await writeFile(stored, JSON.stringify(storedBase, null, 2) + '\n');

  run(process.execPath, [
    'scripts/reemit-project-with-generated.mjs', relative(compiler),
    relative(bootstrapWorkspace), relative(selfhostWorkspace),
  ], 1200000);
  run(process.execPath, [
    'scripts/compare-source-workspaces.mjs', relative(bootstrapWorkspace), relative(selfhostWorkspace),
  ], 300000);
  const nextManifest = await loadManifest(selfhostWorkspace, 'selfhost');
  if (firstManifest.closureSha256 !== nextManifest.closureSha256) {
    throw new Error('PSC0_JOINT_KERNEL_SOURCE_FIXED_POINT_MISMATCH');
  }
  let nextReceipt;
  if (old?.selfhostChecked && existsSync(selfhostJs)) {
    try {
      nextReceipt = await readJson(selfhostJs.replace(/\.js$/u, '.checked.json'));
      await assertKernelOutput(selfhostJs, nextReceipt, nextManifest, compilerSha);
      console.log('PSC0_JOINT_REUSE_CHECKED_SELFHOST: PASS');
    } catch { nextReceipt = undefined; }
  }
  if (!nextReceipt) {
    await mkdir(path.dirname(selfhostJs), { recursive: true });
    nextReceipt = await buildChecked({
      entryPath: path.join(selfhostWorkspace, nextManifest.entry),
      compilerPath: compiler,
      outputPath: selfhostJs,
      kernel: 'pskernel-core',
    });
    await assertKernelOutput(selfhostJs, nextReceipt, nextManifest, compilerSha);
  }
  run(process.execPath, [
    'scripts/compare-selfhost.mjs', relative(bootstrapJs.replace(/\.js$/u, '.ts')),
    relative(selfhostJs.replace(/\.js$/u, '.ts')),
  ], 300000);
  if (firstReceipt.javaScriptSha256 !== nextReceipt.javaScriptSha256 ||
      firstReceipt.typeScriptSha256 !== nextReceipt.typeScriptSha256) {
    throw new Error('PSC0_JOINT_KERNEL_GENERATED_ARTIFACT_FIXED_POINT_MISMATCH');
  }
  run(process.execPath, ['scripts/psc1kernel-generated-smoke.mjs', relative(selfhostJs)], 300000);
  const final = {
    ...storedBase, status: 'kernel-generated-fixed-point',
    selfhostChecked: true, kernelSourceFixedPoint: true,
    kernelEmittedFixedPoint: true, kernelGeneratedRuntimeSmoke: true,
    selfhostJavaScriptSha256: nextReceipt.javaScriptSha256,
    selfhostTypeScriptSha256: nextReceipt.typeScriptSha256,
  };
  await writeFile(stored, JSON.stringify(final, null, 2) + '\n');
  console.log('PSC0_JOINT_KERNEL_SOURCE_AND_GENERATED_FIXED_POINT: PASS sourceModules=' + firstManifest.sourceCount);
  console.log('PSC0_JOINT_KERNEL_JS_RUNTIME_SMOKE: PASS');
  console.log('PSC0_JOINT_FULL_CHECKER_PROMOTION: NOT_YET (generated JS checker must replay compiler admissions)');
}

const mode = process.argv[2] ?? 'generate';
if (mode === 'preflight') {
  const report = await analyzeKernelClosure();
  console.log('PSC0_JOINT_PREFLIGHT: PASS sourceModules=' + report.moduleCount +
    ' sourceSha256=' + report.sourceSha256);
} else if (mode === 'generate') {
  await generate();
} else {
  throw new Error('usage: joint-selfhost.mjs preflight|generate');
}
