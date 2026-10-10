// The sole checked build path used by the installed CLI. Host IO only;
// compiler source, grammar, kernel rules and default provider are unchanged.
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { readFile, readdir, mkdir, mkdtemp, writeFile, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as compiler from '@proofscript/compiler';
import { checkCanonicalAdmissions } from '@proofscript/pskernel-core/check';
import { createCheckedPreparedSession } from './checked-session.mjs';
import { captureSourceGraph } from './source-graph.mjs';
import { publishGeneration } from './publication.mjs';
const require = createRequire(import.meta.url);
const hash = b => createHash('sha256').update(b).digest('hex');
const host = path.dirname(fileURLToPath(import.meta.url));
const compilerPath = require.resolve('@proofscript/compiler');
const compilerIdentity = hash(readFileSync(compilerPath));
const coreRoot = path.dirname(require.resolve('@proofscript/pskernel-core/package.json'));
const coreManifest = JSON.parse(readFileSync(path.join(coreRoot, 'dist/kernel-manifest.json'), 'utf8'));
const expectedKernel = Object.freeze({ protocol: 'pskernel-core-js/1', provider: 'psc0-generated-js-core', leanVersion: '4.34.0', profile: 'lean4.34-core', kernelSha256: coreManifest.kernelSha256, kernelSourceRevision: coreManifest.baseMainCommit });

function typeScript() {
  const manifestPath = require.resolve('typescript/package.json');
  const meta = JSON.parse(readFileSync(manifestPath, 'utf8'));
  if (meta.name !== 'typescript' || meta.version !== '7.0.2') throw new Error('PSC_TYPESCRIPT_PIN');
  const bin = typeof meta.bin === 'string' ? meta.bin : meta.bin?.tsc;
  if (!bin) throw new Error('PSC_TYPESCRIPT_BIN_MISSING');
  const launcher = path.resolve(path.dirname(manifestPath), bin);
  const version = spawnSync(process.execPath, [launcher, '--version'], { encoding: 'utf8', timeout: 15000, maxBuffer: 1024 * 1024 });
  if (version.error || version.status !== 0 || version.stdout.trim() !== 'Version 7.0.2') throw new Error('PSC_TYPESCRIPT_PLATFORM_BINARY_MISSING: @typescript/typescript-' + process.platform + '-' + process.arch + '@7.0.2; install the matching platform package with optional dependencies enabled');
  return { manifestPath, launcher };
}

export async function runCheckedBuild({ entry, output, checkOnly = false, version = 'development' }) {
  const target = path.resolve(output || entry.replace(/\.(ps|lean)$/u, '.js'));
  if (!checkOnly && !/\.(js|ts)$/u.test(target)) throw new Error('PSC_OUTPUT_EXTENSION');
  const tsc = checkOnly ? null : typeScript();
  const trustedFiles = [['compiler', compilerPath], ['compiler-package', require.resolve('@proofscript/compiler/package.json')], ['kernel-package', require.resolve('@proofscript/pskernel-core/package.json')]];
  for (const name of ['index.js', 'kernel-manifest.json', 'prelude.json', 'core-checker.mjs', 'core-cli.mjs', 'generated-core-provider.mjs']) trustedFiles.push(['kernel/' + name, path.join(coreRoot, 'dist', name)]);
  for (const name of (await readdir(host)).filter(n => n.endsWith('.mjs') || n === 'psc.js').sort()) trustedFiles.push(['host/' + name, path.join(host, name)]);
  if (tsc) trustedFiles.push(['typescript-package', tsc.manifestPath], ['typescript-launcher', tsc.launcher]);
  const graph = await captureSourceGraph(compiler, entry, { trustedFiles });
  if (hash(await readFile(compilerPath)) !== compilerIdentity) throw new Error('PSC_COMPILER_IDENTITY_CHANGED');
  const sourceKind = graph.kind === 'ps' ? compiler.PsCompilerSourceKind.proofScript : compiler.PsCompilerSourceKind.lean;
  const session = createCheckedPreparedSession(compiler, text => checkCanonicalAdmissions(text, { timeoutMs: 120000 }), expectedKernel);
  const handle = await session.checkSources(sourceKind, graph.sources, { sourceClosureSha256: graph.snapshot.sourceClosureSha256, compilerSha256: compilerIdentity, grammar: 'ps-0.9-r3/new-only', kernel: expectedKernel, profile: 'bounded-compiler' });
  let stage;
  try {
    await graph.snapshot.revalidate();
    const audit = { schemaVersion: 2, kind: checkOnly ? 'psc0-npm-checked' : 'psc0-npm-checked-build', version, entry: path.resolve(entry), sourceCount: graph.sourceCount, sourceClosureSha256: graph.snapshot.sourceClosureSha256, canonicalAdmissionsSha256: handle.canonicalAdmissionsSha256, compilerSha256: compilerIdentity, kernel: expectedKernel, inputs: graph.snapshot.binding, claims: { kernelAdmitted: true, fullPscvVerified: false, compilerSemanticsProven: false, newSelfhostFixedPoint: false }, receiptIsAuthority: false };
    if (checkOnly) return Object.freeze(audit);
    const typeScriptSource = session.emit(handle);
    if (Buffer.byteLength(typeScriptSource) > 32 * 1024 * 1024) throw new Error('PSC_OUTPUT_SIZE_LIMIT');
    await mkdir(path.dirname(target), { recursive: true });
    stage = await mkdtemp(path.join(path.dirname(target), '.psc-stage-'));
    const stem = path.basename(target).replace(/\.(js|ts)$/u, '');
    if (!/^[A-Za-z_][A-Za-z_0-9.-]*$/u.test(stem)) throw new Error('PSC_OUTPUT_NAME');
    const input = path.join(stage, stem + '.ts');
    await writeFile(input, typeScriptSource, { flag: 'wx', mode: 0o600 });
    const result = spawnSync(process.execPath, [tsc.launcher, '--ignoreConfig', input, '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler', '--strict', '--declaration', '--sourceMap', '--skipLibCheck', '--noEmitOnError', '--pretty', 'false'], { encoding: 'utf8', timeout: 180000, maxBuffer: 16 * 1024 * 1024, windowsHide: true });
    if (result.error || result.status !== 0) throw new Error('PSC_TSC_FAILED: ' + String(result.stderr || result.stdout || result.error).slice(0,4000));
    const products = {};
    for (const extension of ['.ts', '.js', '.d.ts', '.js.map']) products[extension] = await readFile(path.join(stage, stem + extension), 'utf8');
    session.assertCurrent(handle);
    await graph.snapshot.revalidate();
    return await publishGeneration({ output: target, products, snapshot: graph.snapshot, receipt: { ...audit, typescript: '7.0.2', outputSha256: hash(products['.js']) } });
  } finally {
    session.revoke(handle);
    // The executable switch is the commit boundary. Cleanup failure must not
    // report that a committed build failed or mask the original refusal.
    if (stage) await rm(stage, { recursive: true, force: true }).catch(error => console.warn('PSC_STAGING_CLEANUP: ' + error.message));
  }
}
