import { readFile, writeFile, mkdir, mkdtemp, rename, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';
import { createCheckedPreparedSession } from './checked-prepared-session.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';
import {
  checkAdmissionsWithKernel,
  checkedKernelDescriptor,
  defaultCheckedKernel,
} from './checked-kernel-provider.mjs';
import { runCheckedSeedSession } from './checked-seed-session.mjs';
import { assertPinnedTypeScriptCli, strictTypeScriptArgs, checkedTypeScriptToolchain } from './typescript-cli.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const digest = data => createHash('sha256').update(data).digest('hex');
const nativeSuffix = process.platform === 'win32' ? '.exe' : '';
export const defaultCheckedSeed = path.join(root, 'lean-checked/.lake/build/bin/psc2_lean_checked_seed' + nativeSuffix);
export function checkedCompilerPath(kernel = defaultCheckedKernel) {
  checkedKernelDescriptor(kernel);
  return path.join(root, 'dist/checked', kernel, 'bootstrap/packages/compiler/index.js');
}
export const defaultCheckedCompiler = checkedCompilerPath();

export async function buildChecked({
  entryPath,
  outputPath,
  compilerPath,
  seedPath,
  checkOnly = false,
  emission = 'full',
  kernel = defaultCheckedKernel,
}) {
  const kernelDescriptor = checkedKernelDescriptor(kernel);
  if (!['full', 'typescript-only'].includes(emission)) throw new Error('PSC2_CHECKED_EMISSION_MODE');
  if (checkOnly && emission !== 'full') throw new Error('PSC2_CHECKED_CHECK_ONLY_EMISSION');
  const startTime = process.hrtime.bigint();
  const trace = (stage, details = '') => {
    if (process.env.PSC0_BUILD_TRACE !== '1') return;
    const elapsed = Number(process.hrtime.bigint() - startTime) / 1e9;
    const heapMiB = Math.round(process.memoryUsage().heapUsed / 1048576);
    console.log('PSC2_CHECKED_STAGE: ' + stage + ' elapsedSeconds=' + elapsed.toFixed(3) +
      ' heapMiB=' + heapMiB + (details ? ' ' + details : ''));
  };
  if (compilerPath && seedPath) throw new Error('PSC2_CHECKED_SELECT_ONE_COMPILER');
  if (!checkOnly && !outputPath) throw new Error('PSC2_CHECKED_OUTPUT_REQUIRED');
  const snapshot = await readCheckedSourceSnapshot(entryPath);
  trace('source-snapshot', 'modules=' + snapshot.ordered.length);
  let admissions;
  let typeScript;
  let compilerIdentity;
  const checkAdmissions = async text => {
    trace('admissions-ready', 'admissionsBytes=' + Buffer.byteLength(text, 'utf8'));
    const checked = await checkAdmissionsWithKernel(text, kernel);
    trace('native-kernel-complete', 'accepted=' + String(checked.result?.accepted));
    return checked.result;
  };

  if (seedPath) {
    const binary = path.resolve(seedPath);
    compilerIdentity = { engine: 'native-seed', sha256: digest(await readFile(binary)) };
    const result = await runCheckedSeedSession({
      binaryPath: binary,
      sourceKind: snapshot.kind,
      source: snapshot.source,
      sources: snapshot.sources,
      checkAdmissions,
      emit: !checkOnly,
    });
    admissions = result.admissions;
    typeScript = result.typeScript;
    trace('native-seed-finished');
  } else {
    const file = path.resolve(compilerPath ?? checkedCompilerPath(kernel));
    compilerIdentity = { engine: 'generated-js', sha256: digest(await readFile(file)) };
    const compiler = await import(pathToFileURL(file).href);
    const kind = snapshot.kind === 'ps'
      ? compiler.PsCompilerSourceKind?.proofScript
      : compiler.PsCompilerSourceKind?.lean;
    if (kind === undefined) throw new Error('PSC2_CHECKED_SOURCE_KIND_API_MISSING');
    const session = createCheckedPreparedSession(compiler, async text => {
      admissions = text;
      return checkAdmissions(text);
    }, checkedKernelIdentity(kernel));
    const handle = await session.checkSources(kind, snapshot.sources);
    trace('generated-compiler-prepared-and-checked');
    if (!checkOnly) {
      typeScript = session.emit(handle);
      trace('generated-compiler-emitted', 'typescriptBytes=' + Buffer.byteLength(typeScript, 'utf8'));
    }
  }

  const receipt = {
    schemaVersion: 3,
    kind: 'psc2-checked-build',
    provider: checkedKernelIdentity(kernel),
    kernel: kernelDescriptor,
    compiler: compilerIdentity,
    sourceClosureSha256: snapshot.closureSha256,
    flattenedSourceSha256: digest(snapshot.source),
    sourceCount: snapshot.ordered.length,
    canonicalAdmissionsSha256: digest(admissions),
  };
  if (checkOnly) return receipt;
  receipt.typeScriptToolchain = checkedTypeScriptToolchain;
  if (typeof typeScript !== 'string') throw new Error('PSC2_CHECKED_TS_RESULT');
  const output = path.resolve(outputPath);
  if (!/\.(?:ts|js)$/u.test(output)) throw new Error('PSC2_CHECKED_OUTPUT_KIND');
  const stem = path.basename(output).replace(/\.(?:ts|js)$/u, '');
  trace('typescript-ready', 'typescriptBytes=' + Buffer.byteLength(typeScript, 'utf8'));

  // Explicit diagnostic/equality mode: kernel admission is mandatory and the
  // result is a typed *source* receipt, never a checked executable. No tsc
  // subprocess is started. A separate fully checked native build must compile
  // identical TypeScript before its JavaScript can be reused.
  if (emission === 'typescript-only') {
    if (!output.endsWith('.ts')) throw new Error('PSC2_CHECKED_TYPESCRIPT_OUTPUT_REQUIRED');
    if (existsSync(output.replace(/\.ts$/u, '.js'))) {
      throw new Error('PSC2_CHECKED_TYPESCRIPT_ONLY_STALE_JAVASCRIPT');
    }
    await mkdir(path.dirname(output), { recursive: true });
    const staging = await mkdtemp(path.join(path.dirname(output), '.checked-source-stage-'));
    try {
      receipt.kind = 'psc2-checked-typescript';
      receipt.emission = 'typescript-only';
      receipt.typeScriptSha256 = digest(typeScript);
      receipt.typeScriptBytes = Buffer.byteLength(typeScript, 'utf8');
      await writeFile(path.join(staging, stem + '.ts'), typeScript);
      await writeFile(path.join(staging, stem + '.admissions.json'), admissions);
      // Publish the audit receipt last; it grants no authority to emit JS.
      await rename(path.join(staging, stem + '.ts'), output);
      await rename(path.join(staging, stem + '.admissions.json'),
        output.replace(/\.ts$/u, '.admissions.json'));
      await writeFile(path.join(staging, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
      await rename(path.join(staging, 'receipt.json'), output.replace(/\.ts$/u, '.checked.json'));
    } finally {
      await rm(staging, { recursive: true, force: true });
    }
    trace('checked-typescript-published');
    return receipt;
  }

  // Kernel acceptance has already happened. TypeScript writes only into staging;
  // a failed tsc cannot create a new final output or checked receipt.
  const tsc = assertPinnedTypeScriptCli();
  await mkdir(path.dirname(output), { recursive: true });
  const staging = await mkdtemp(path.join(path.dirname(output), '.checked-stage-'));
  try {
    const tsFile = path.join(staging, stem + '.ts');
    await writeFile(tsFile, typeScript);
    trace('tsc-start', 'typescriptBytes=' + Buffer.byteLength(typeScript, 'utf8'));
    const run = spawnSync(process.execPath, [tsc, tsFile, ...strictTypeScriptArgs], {
      encoding: 'utf8', timeout: 120000, maxBuffer: 16 * 1024 * 1024, windowsHide: true,
    });
    trace('tsc-completed', 'exit=' + String(run.error?.code ?? run.status));
    if (run.error) throw run.error;
    if (run.status !== 0) throw new Error(`PSC2_CHECKED_TSC_FAILED: ${run.stdout}\n${run.stderr}`);
    receipt.typeScriptSha256 = digest(typeScript);
    receipt.javaScriptSha256 = digest(await readFile(path.join(staging, stem + '.js')));
    await writeFile(path.join(staging, stem + '.admissions.json'), admissions);
    for (const suffix of ['.ts', '.js', '.d.ts', '.js.map', '.admissions.json']) {
      await rename(path.join(staging, stem + suffix), path.join(path.dirname(output), stem + suffix));
    }
    // This receipt is an audit record, not a transferable proof/capability.
    await writeFile(path.join(staging, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
    await rename(path.join(staging, 'receipt.json'), path.join(path.dirname(output), stem + '.checked.json'));
  } finally {
    await rm(staging, { recursive: true, force: true });
  }
  return receipt;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const entryPath = args.shift();
  const options = { entryPath };
  while (args.length) {
    const flag = args.shift();
    if (flag === '--check') options.checkOnly = true;
    else if (flag === '--typescript-only') options.emission = 'typescript-only';
    else if (['--out', '--compiler', '--seed', '--kernel'].includes(flag)) {
      const value = args.shift();
      if (!value || value.startsWith('--')) throw new Error(`Missing value for ${flag}`);
      options[{ '--out': 'outputPath', '--compiler': 'compilerPath', '--seed': 'seedPath', '--kernel': 'kernel' }[flag]] = value;
    } else throw new Error(`Unknown checked-build option: ${flag}`);
  }
  if (!entryPath) {
    throw new Error('usage: checked-build.mjs <entry> [--check | --out file.js] [--compiler file.js | --seed binary] [--kernel lean434-wasm|pskernel-core|lean434]');
  }
  const receipt = await buildChecked(options);
  console.log('PSC2_CHECKED_BUILD: PASS ' + JSON.stringify(receipt));
}
