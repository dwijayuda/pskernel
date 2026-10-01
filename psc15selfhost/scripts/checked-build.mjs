import { readFile, writeFile, mkdir, mkdtemp, rename, rm } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';
import { createCheckedPreparedSession, leanCheckedIdentity } from './checked-prepared-session.mjs';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const digest = data => createHash('sha256').update(data).digest('hex');
const nativeSuffix = process.platform === 'win32' ? '.exe' : '';
export const defaultCheckedSeed = path.join(root, 'lean-checked/.lake/build/bin/psc2_lean_checked_seed' + nativeSuffix);
export const defaultCheckedCompiler = path.join(root, 'dist/lean-checked/bootstrap/packages/compiler/index.js');

async function providerCheck(admissions) {
  const provider = await import('../packages/pskernel-lean/index.mjs');
  const developmentBinary = path.join(root, 'lean-checked/.lake/build/bin/psc2_lean_kernel_provider' + nativeSuffix);
  // Use the package's public API and its normal bundle verification. A source
  // checkout can use its freshly built provider; no alternate checker is used.
  return provider.checkCanonicalAdmissions(admissions,
    !process.env.PSC_LEAN_KERNEL_PROVIDER_BIN && existsSync(developmentBinary)
      ? { binaryPath: developmentBinary, timeoutMs: 60000 } : { timeoutMs: 60000 });
}
function requireIdentity(result) {
  for (const [key, expected] of Object.entries(leanCheckedIdentity)) {
    if (result?.[key] !== expected) throw new Error(`PSC2_CHECKED_PROVIDER_IDENTITY: ${key}`);
  }
  if (result.accepted !== true || typeof result.admissions !== 'string') {
    throw new Error('PSC2_CHECKED_SEED_RESULT');
  }
}
export async function buildChecked({ entryPath, outputPath, compilerPath, seedPath, checkOnly = false, kernel = 'lean434' }) {
  if (kernel !== 'lean434') throw new Error(`PSC2_CHECKED_KERNEL_UNSUPPORTED: ${kernel}`);
  if (compilerPath && seedPath) throw new Error('PSC2_CHECKED_SELECT_ONE_COMPILER');
  if (!checkOnly && !outputPath) throw new Error('PSC2_CHECKED_OUTPUT_REQUIRED');
  const snapshot = await readCheckedSourceSnapshot(entryPath);
  let admissions; let typeScript; let compilerIdentity;
  if (seedPath) {
    const binary = path.resolve(seedPath);
    compilerIdentity = { engine: 'native-seed', sha256: digest(await readFile(binary)) };
    const run = spawnSync(binary, [`--${checkOnly ? 'check' : 'emit'}-${snapshot.kind}`], {
      input: snapshot.source, encoding: 'utf8', timeout: 300000, maxBuffer: 64 * 1024 * 1024,
      windowsHide: true, killSignal: 'SIGKILL',
    });
    if (run.error) throw run.error;
    if (run.status !== 0) throw new Error(`PSC2_CHECKED_SEED_FAILED: ${run.stderr}`);
    const result = JSON.parse(run.stdout); requireIdentity(result);
    admissions = result.admissions; typeScript = result.typescript;
  } else {
    const file = path.resolve(compilerPath ?? defaultCheckedCompiler);
    compilerIdentity = { engine: 'generated-js', sha256: digest(await readFile(file)) };
    const compiler = await import(pathToFileURL(file).href);
    const kind = snapshot.kind === 'ps' ? compiler.PsCompilerSourceKind?.proofScript : compiler.PsCompilerSourceKind?.lean;
    if (kind === undefined) throw new Error('PSC2_CHECKED_SOURCE_KIND_API_MISSING');
    const session = createCheckedPreparedSession(compiler, text => { admissions = text; return providerCheck(text); });
    const handle = await session.check(kind, snapshot.source);
    if (!checkOnly) typeScript = session.emit(handle);
  }
  const receipt = {
    schemaVersion: 1, kind: 'psc2-lean-checked-build', provider: leanCheckedIdentity,
    compiler: compilerIdentity, sourceClosureSha256: snapshot.closureSha256,
    flattenedSourceSha256: digest(snapshot.source), sourceCount: snapshot.ordered.length,
    canonicalAdmissionsSha256: digest(admissions),
  };
  if (checkOnly) return receipt;
  if (typeof typeScript !== 'string') throw new Error('PSC2_CHECKED_TS_RESULT');
  const output = path.resolve(outputPath);
  if (!/\.(?:ts|js)$/u.test(output)) throw new Error('PSC2_CHECKED_OUTPUT_KIND');
  const stem = path.basename(output).replace(/\.(?:ts|js)$/u, '');
  // Checking has already succeeded. TypeScript writes only into staging; a
  // failed tsc cannot create a new final output or checked receipt.
  const version = spawnSync('tsc', ['--version'], { encoding: 'utf8', timeout: 10000 });
  if (version.error || version.status !== 0 || version.stdout.trim() !== 'Version 5.8.3') {
    throw new Error('PSC2_CHECKED_TYPESCRIPT_PIN: require TypeScript 5.8.3');
  }
  await mkdir(path.dirname(output), { recursive: true });
  const staging = await mkdtemp(path.join(path.dirname(output), '.checked-stage-'));
  try {
    const tsFile = path.join(staging, stem + '.ts'); await writeFile(tsFile, typeScript);
    const run = spawnSync('tsc', [tsFile, '--target', 'ES2022', '--module', 'ES2022',
      '--moduleResolution', 'bundler', '--strict', '--declaration', '--sourceMap',
      '--noEmitOnError', '--skipLibCheck', '--pretty', 'false'], {
      encoding: 'utf8', timeout: 120000, maxBuffer: 16 * 1024 * 1024, windowsHide: true,
    });
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
  } finally { await rm(staging, { recursive: true, force: true }); }
  return receipt;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2); const entryPath = args.shift();
  const options = { entryPath };
  while (args.length) {
    const flag = args.shift();
    if (flag === '--check') options.checkOnly = true;
    else if (['--out', '--compiler', '--seed', '--kernel'].includes(flag)) {
      const value = args.shift(); if (!value || value.startsWith('--')) throw new Error(`Missing value for ${flag}`);
      options[{ '--out': 'outputPath', '--compiler': 'compilerPath', '--seed': 'seedPath', '--kernel': 'kernel' }[flag]] = value;
    } else throw new Error(`Unknown checked-build option: ${flag}`);
  }
  if (!entryPath) throw new Error('usage: checked-build.mjs <entry> [--check | --out file.js] [--compiler file.js | --seed binary] [--kernel lean434]');
  const receipt = await buildChecked(options);
  console.log('PSC2_LEAN_CHECKED_BUILD: PASS ' + JSON.stringify(receipt));
}
