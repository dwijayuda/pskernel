// Exact installed TypeScript7 target bytes + one monolithic target profile.
// No compiler/kernel semantics are implemented here. Registry authenticity and
// compiler correctness are NOT inferred from package names, versions or hashes.
import { createRequire } from 'node:module';
import { mkdir, realpath } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { captureTargetTrees, fingerprintTargetFile } from './target-files.mjs';
import { targetEnvironment, runTargetProcess } from './target-process.mjs';
import { freezeDataGraph } from './checked-session.mjs';
const require = createRequire(import.meta.url);
const digest = text => createHash('sha256').update(text).digest('hex');
export const targetFlags = Object.freeze(['--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler', '--strict', '--declaration', '--sourceMap', '--skipLibCheck', '--noEmitOnError', '--pretty', 'false']);
export async function captureTypeScriptInstallation(manifestPath) {
  const tsFile = await realpath(manifestPath);
  const tsRead = await fingerprintTargetFile(tsFile, { maxBytes: 1024 * 1024, text: true });
  const ts = JSON.parse(tsRead.text);
  const name = '@typescript/typescript-' + process.platform + '-' + process.arch;
  if (ts.name !== 'typescript' || ts.version !== '7.0.2' || ts.optionalDependencies?.[name] !== '7.0.2' || typeof ts.bin?.tsc !== 'string') throw new Error('PSC_TYPESCRIPT_PIN');
  let nativeFile;
  try { nativeFile = await realpath(createRequire(tsFile).resolve(name + '/package.json')); }
  catch { throw new Error('PSC_TYPESCRIPT_PLATFORM_BINARY_MISSING: ' + name + '@7.0.2'); }
  const nativeRead = await fingerprintTargetFile(nativeFile, { maxBytes: 1024 * 1024, text: true });
  const native = JSON.parse(nativeRead.text);
  if (native.name !== name || native.version !== '7.0.2' || !native.os?.includes(process.platform) || !native.cpu?.includes(process.arch)) throw new Error('PSC_TYPESCRIPT_PLATFORM_IDENTITY');
  const snapshot = await captureTargetTrees([{ id: 'typescript', directory: path.dirname(tsFile) }, { id: 'native', directory: path.dirname(nativeFile) }]);
  const find = id => snapshot.identity.entries.find(e => e.id === id && e.kind === 'file');
  if (find('typescript/package.json')?.sha256 !== tsRead.sha256 || find('native/package.json')?.sha256 !== nativeRead.sha256) throw new Error('PSC_TARGET_MANIFEST_CHANGED');
  const relativeExe = 'lib/tsc' + (process.platform === 'win32' ? '.exe' : '');
  const binary = find('native/' + relativeExe);
  if (!binary) throw new Error('PSC_TYPESCRIPT_PLATFORM_BINARY_MISSING: ' + relativeExe);
  const executable = path.join(path.dirname(nativeFile), relativeExe);
  const launcher = path.resolve(path.dirname(tsFile), ts.bin.tsc);
  const relativeLauncher = path.relative(path.dirname(tsFile), launcher).split(path.sep).join('/');
  if (!find('typescript/' + relativeLauncher)) throw new Error('PSC_TYPESCRIPT_LAUNCHER_ESCAPE');
  const identity = freezeDataGraph({ schema: 'psc0-typescript-target/1', version: '7.0.2', platform: process.platform, arch: process.arch, nativePackage: name, nativeExecutableSha256: binary.sha256, inventorySha256: snapshot.sha256, capturedFiles: snapshot.identity.entries.filter(e => e.kind === 'file').length, capturedBytes: snapshot.identity.bytes, registryAuthenticityVerified: false });
  return Object.freeze({ executable, launcher, identity, snapshot });
}
export async function createTypeScriptTarget({ signal } = {}) {
  const installation = await captureTypeScriptInstallation(require.resolve('typescript/package.json'));
  const environment = targetEnvironment();
  const result = await runTargetProcess(installation.executable, ['--version'], { signal, timeoutMs: 15000, maxBytes: 4096, environment });
  if (result.stdout.trim() !== 'Version 7.0.2') throw new Error('PSC_TYPESCRIPT_NATIVE_VERSION');
  await installation.snapshot.revalidate();
  const plan = freezeDataGraph({ schema: 'psc0-monolithic-ts-target/1', toolchain: installation.identity, flags: ['--ignoreConfig', '<captured-input.ts>', ...targetFlags, '--noResolve', '--typeRoots', '<private-empty-types>'], environment, maximumProcessMs: 180000, maximumDiagnosticBytes: 1024 * 1024, maximumProductBytes: 32 * 1024 * 1024, sourceCodegenProof: false });
  const planSha256 = digest('PSC0/TARGET-PLAN/1\0' + JSON.stringify(plan));
  let state = 'ready';
  const revalidate = async () => {
    if (state === 'failed') throw new Error('PSC_TARGET_SESSION_FAILED');
    try { await installation.snapshot.revalidate(); }
    catch (error) { state = 'failed'; throw error; }
  };
  return Object.freeze({ identity: installation.identity, plan, planSha256, revalidate,
    async compile(input) {
      if (state !== 'ready') throw new Error('PSC_TARGET_SESSION_STATE');
      state = 'running';
      try {
        await revalidate(); signal?.throwIfAborted();
        const source = await realpath(input), directory = path.dirname(source);
        if (!source.endsWith('.ts')) throw new Error('PSC_TARGET_INPUT_EXTENSION');
        const captured = await fingerprintTargetFile(source, { maxBytes: plan.maximumProductBytes });
        const types = path.join(directory, '.psc-empty-types');
        await mkdir(types); // Must be newly created and empty, never a project's types.
        await runTargetProcess(installation.executable, ['--ignoreConfig', source, ...targetFlags, '--noResolve', '--typeRoots', types], { cwd: directory, signal, environment });
        const after = await fingerprintTargetFile(source, { maxBytes: plan.maximumProductBytes });
        if (captured.sha256 !== after.sha256) throw new Error('PSC_TARGET_INPUT_CHANGED');
        const products = {}, artifacts = [];
        const stem = source.slice(0, -3);
        for (const extension of ['.ts', '.js', '.d.ts', '.js.map']) {
          const product = await fingerprintTargetFile(stem + extension, { maxBytes: plan.maximumProductBytes, text: true });
          products[extension] = product.text;
          artifacts.push({ extension, bytes: product.bytes, sha256: product.sha256 });
        }
        await revalidate(); signal?.throwIfAborted();
        state = 'compiled';
        return freezeDataGraph({ products, evidence: { plan, planSha256, inputTypeScriptSha256: captured.sha256, artifacts, nativeProcessClosed: true, targetSemanticsProven: false } });
      } catch (error) { state = 'failed'; throw error; }
    },
  });
}
