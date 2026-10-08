// Experimental, NON-AUTHORITATIVE TS7/Bun/esbuild benchmarking.
// Never substitute these outputs for checked PSC0 artifacts without a
// separately approved semantic/strict-typechecking equivalence gate.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync } from 'node:fs';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const [engine = '', sourceArgument = '', outputArgument = ''] = process.argv.slice(2);
if (!['ts7', 'esbuild', 'bun'].includes(engine) || !sourceArgument || !outputArgument) {
  throw Error('Usage: kernel-transpiler-benchmark.mjs <ts7|esbuild|bun> <checked-source.ts> <outdir>');
}
const src = path.resolve(root, sourceArgument);
const out = path.resolve(root, outputArgument);
const digest = data => createHash('sha256').update(data).digest('hex');
const rel = p => path.relative(root, p).replaceAll(path.sep, '/');
const receiptPath = src.replace(/\.ts$/u, '.checked.json');
const admissionsPath = src.replace(/\.ts$/u, '.admissions.json');
const source = await readFile(src);
const admissions = await readFile(admissionsPath);
const receipt = JSON.parse(await readFile(receiptPath, 'utf8'));
if (receipt.kind !== 'psc2-checked-typescript' ||
    receipt.schemaVersion !== 3 || receipt.emission !== 'typescript-only' ||
    receipt.provider?.provider !== 'pskernel-core-native' ||
    receipt.compiler?.engine !== 'native-seed' ||
    receipt.sourceCount !== 79 ||
    receipt.typeScriptSha256 !== digest(source) ||
    receipt.canonicalAdmissionsSha256 !== digest(admissions)) {
  throw Error('PSC0_BENCH_SOURCE_NOT_NATIVE_KERNEL_CHECKED');
}
const bins = {
  ts7: path.join(root, 'dist/transpiler-bench/toolchains/ts7/node_modules/.bin/tsc'),
  esbuild: path.join(root, 'dist/transpiler-bench/toolchains/esbuild/node_modules/.bin/esbuild'),
  bun: 'bun',
};
const bin = bins[engine];
if (engine !== 'bun' && !existsSync(bin)) throw Error('PSC0_BENCH_TOOL_NOT_INSTALLED: ' + bin);
const version = spawnSync(bin, ['--version'], { encoding: 'utf8', timeout: 15000 });
if (version.error || version.status !== 0) throw Error('PSC0_BENCH_TOOL_VERSION_ERROR: ' + engine);
const versionText = version.stdout.trim();
if (engine === 'ts7' && versionText !== 'Version 7.0.2') {
  throw Error('PSC0_BENCH_TS7_VERSION_MISMATCH: ' + versionText);
}
const args = engine === 'ts7'
  ? [src, '--target', 'ES2022', '--module', 'ES2022',
    '--moduleResolution', 'bundler', '--strict', '--declaration',
    '--sourceMap', '--noEmitOnError', '--skipLibCheck', '--pretty', 'false',
    '--rootDir', path.dirname(src), '--outDir', out,
    '--extendedDiagnostics', '--checkers', '2']
  : engine === 'esbuild'
    ? [src, '--format=esm', '--target=es2022', '--platform=node',
      '--sourcemap=external', '--outfile=' + path.join(out, 'index.js')]
    : ['build', src, '--target=node', '--format=esm', '--outdir=' + out];
const report = {
  schemaVersion: 1, kind: 'psc0-kernel-transpiler-experiment',
  authoritative: false, engine, version: versionText,
  source: rel(src), sourceSha256: digest(source),
  canonicalAdmissionsSha256: digest(admissions), sourceBytes: source.length,
  sourceCount: receipt.sourceCount,
  nativeChecked: true, strictTypechecked: engine === 'ts7',
  // For Bun and esbuild, strict checking is a separate mandatory experiment
  // gate; these compilers only strip TS and perform syntax/JS transformation.
  strictTypecheckRequiredBeforePromotion: true,
  output: rel(out), startedAt: new Date().toISOString(),
};
await rm(out, { force: true, recursive: true });
await mkdir(out, { recursive: true });
const started = process.hrtime.bigint();
const usagePath = path.join(out, 'compiler-usage.txt');
const GNU_TIME = '/usr/bin/time';
const command = existsSync(GNU_TIME) ? GNU_TIME : bin;
const commandArgs = existsSync(GNU_TIME)
  ? ['-f', 'wallSeconds=%e peakRSSKiB=%M userCpuSeconds=%U systemCpuSeconds=%S', '-o', usagePath, bin, ...args]
  : args;
const res = spawnSync(command, commandArgs, {
  cwd: root, encoding: 'utf8', windowsHide: true, maxBuffer: 16 * 1024 * 1024,
  timeout: 900000, env: { ...process.env, NODE_OPTIONS: '--max-old-space-size=6144' },
});
report.durationSeconds = +(Number(process.hrtime.bigint() - started) / 1e9).toFixed(3);
report.status = res.error?.code ?? res.signal ?? res.status;
report.stdoutTail = res.stdout?.slice(-12000) ?? '';
report.stderrTail = res.stderr?.slice(-12000) ?? '';
try { report.resourceUsage = await readFile(usagePath, 'utf8'); } catch { /* optional */ }
const js = path.join(out, 'index.js');
if (res.error || res.status !== 0 || !existsSync(js)) {
  report.pass = false;
  report.failedStage = 'compiler';
} else {
  report.javaScriptSha256 = digest(await readFile(js));
  report.javaScriptBytes = (await readFile(js)).length;
  if (engine === 'ts7') {
    report.declarationEmitted = existsSync(path.join(out, 'index.d.ts'));
    report.sourceMapEmitted = existsSync(path.join(out, 'index.js.map'));
    if (!report.declarationEmitted || !report.sourceMapEmitted) {
      report.pass = false;
      report.failedStage = 'typescript7-emission-completeness';
    }
  }
  if (report.failedStage === undefined) {
    const smoke = spawnSync(process.execPath, [
      path.join(root, 'scripts/psc1kernel-generated-smoke.mjs'), rel(js),
    ], { cwd: root, encoding: 'utf8', timeout: 300000,
      maxBuffer: 4 * 1024 * 1024 });
    report.smokeExit = smoke.error?.code ?? smoke.signal ?? smoke.status;
    report.smokeOutput = (smoke.stdout ?? '').slice(-1600);
    report.smokeError = (smoke.stderr ?? '').slice(-1600);
    report.pass = !smoke.error && smoke.status === 0;
    if (!report.pass) report.failedStage = 'runtime-smoke';
  }
}
report.completedAt = new Date().toISOString();
const reportFile = path.join(root, 'dist/transpiler-bench/reports', engine + '.json');
await mkdir(path.dirname(reportFile), { recursive: true });
await writeFile(reportFile, JSON.stringify(report, null, 2) + '\n');
console.log('PSC0_TRANSPILER_EXPERIMENT: ' + JSON.stringify({
  engine, version: report.version, pass: report.pass,
  stage: report.failedStage ?? 'runtime-smoke-passed',
  wallSeconds: report.durationSeconds, sourceBytes: report.sourceBytes,
  generatedBytes: report.javaScriptBytes, sourceHash: report.sourceSha256,
  outputHash: report.javaScriptSha256, resourceUsage: report.resourceUsage,
  diagnostics: !report.pass ? (report.stderrTail || report.stdoutTail).slice(-2500) : undefined,
}));
if (!report.pass) process.exitCode = 1;
