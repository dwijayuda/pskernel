import { readFile, writeFile, mkdir, mkdtemp, rm } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readCheckedSourceSnapshot } from './checked-source-snapshot.mjs';
import { readProofScriptImports, readProofScriptImportsWithSeed } from './proofscript-source.mjs';
import { createCheckedPreparedSession } from './checked-prepared-session.mjs';
import { captureProjectUnits, libraryArtifacts } from './checked-project.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';
import { checkAdmissionsWithKernel, checkedKernelDescriptor, defaultCheckedKernel } from './checked-kernel-provider.mjs';
import { loadGeneratedCompiler } from './sh1-source-snapshot.mjs';
import { expectedTypeScriptVersion, resolveTypeScriptCli, typeScriptProfileArgs } from './typescript-cli.mjs';
import { checkedOutputPath, prepareCheckedOutputDirectory, publishCheckedArtifacts } from './checked-artifact-publication.mjs';
import { completedCommandRecords, assertCommandExtensionCurrent } from './command-extensions.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const digest = data => createHash('sha256').update(data).digest('hex');
const nativeSuffix = process.platform === 'win32' ? '.exe' : '';
export const defaultCheckedSeed = path.join(root, 'lean-checked/.lake/build/bin/psc2_lean_checked_seed' + nativeSuffix);
export function checkedCompilerPath(kernel = defaultCheckedKernel) {
  checkedKernelDescriptor(kernel);
  return path.join(root, 'dist/checked', kernel, 'bootstrap/packages/compiler/index.js');
}
export const defaultCheckedCompiler = checkedCompilerPath();

async function assertSnapshotCurrent(snapshot, signal) {
  signal?.throwIfAborted();
  for (const item of snapshot.ordered) {
    const bytes = await readFile(item.path);
    if (!bytes.equals(Buffer.from(item.source, 'utf8'))) {
      throw new Error('PSC0_SOURCE_CHANGED_DURING_BUILD: ' + item.path);
    }
  }
  signal?.throwIfAborted();
}

/**
 * Trusted host entry. Compiler/provider selection belongs to the release or an
 * explicit development invocation, never to a project extension. The public
 * npm launcher supplies pinned paths and hashes and exposes no override.
 */
export async function buildChecked({
  entryPath, outputPath, compilerPath, compilerSha256, seedPath, checkOnly = false,
  kernel = defaultCheckedKernel, nativeBinaryPath, profile = 'checked', signal, extensionExecution, libraryConfig,
}) {
  if (profile !== 'checked') throw new Error('PSC0_PROFILE_UNAVAILABLE: ' + profile);
  if (typeof entryPath !== 'string' || entryPath.length === 0) throw new Error('PSC0_SOURCE_REQUIRED');
  if (compilerPath && seedPath) throw new Error('PSC2_CHECKED_SELECT_ONE_COMPILER');
  if (!checkOnly && !outputPath) throw new Error('PSC2_CHECKED_OUTPUT_REQUIRED');
  if (!checkOnly && !/\.(?:ts|js)$/u.test(outputPath)) throw new Error('PSC2_CHECKED_OUTPUT_KIND');
  const output = checkOnly ? undefined : checkedOutputPath(outputPath);
  const library = libraryConfig !== undefined;
  if (library && (seedPath || typeof libraryConfig?.projectRoot !== 'string' ||
      !checkOnly && !output.endsWith('.ts'))) throw new Error('PSC0_LIBRARY_BUILD_PROFILE');
  const projectRoot = library ? path.resolve(libraryConfig.projectRoot) : undefined;
  const projectConfigSource = libraryConfig?.configSource;
  const projectConfigPath = libraryConfig?.configPath;
  if (projectConfigSource !== undefined || projectConfigPath !== undefined) {
    if (typeof projectConfigSource !== 'string' || typeof projectConfigPath !== 'string' ||
        path.resolve(projectConfigPath) !== path.join(projectRoot, 'package.json')) {
      throw new Error('PSC0_LIBRARY_CONFIG_IDENTITY');
    }
  }
  // The historical native seed protocol attests admissions only. Its raw emit
  // response cannot satisfy the protected same-original-IR emission contract.
  if (seedPath && !checkOnly) throw new Error('PSC0_NATIVE_SEED_EMISSION_UNQUALIFIED');
  const kernelDescriptor = checkedKernelDescriptor(kernel);
  // Only a completed host-owned command execution can supply extension provenance.
  // The guest returned one integer; it never supplied a receipt, source, or output.
  const extensions = extensionExecution === undefined ? Object.freeze([])
    : completedCommandRecords(extensionExecution);
  if (extensionExecution !== undefined) await assertCommandExtensionCurrent(extensionExecution);
  signal?.throwIfAborted();

  let compiler, compilerIdentity, binary, parseImports;
  if (seedPath) {
    binary = path.resolve(seedPath);
    compilerIdentity = { engine: 'native-seed-admission-only', sha256: digest(await readFile(binary)) };
    parseImports = (source, file) => readProofScriptImportsWithSeed(binary, source, file);
  } else {
    const file = path.resolve(compilerPath ?? checkedCompilerPath(kernel));
    const loaded = await loadGeneratedCompiler(file, { expectedSha256: compilerSha256 });
    compiler = loaded.compiler;
    compilerIdentity = {
      engine: 'generated-js', sha256: loaded.compilerSha256,
      expectedDigestChecked: compilerSha256 !== undefined,
    };
    parseImports = (source, file) => readProofScriptImports(compiler, source, file);
  }
  const snapshot = await readCheckedSourceSnapshot(entryPath, { readProofScriptImports: parseImports });
  const projectUnits = library ? captureProjectUnits(snapshot, projectRoot, libraryConfig.exports) : undefined;
  const exportSelection = projectUnits?.map(unit => ({ sourceId: unit.sourceId, exports: unit.exports }));
  let admissions, typeScript, irValidation, libraryEmission;
  let actualKernel = kernelDescriptor;
  const checkAdmissions = async text => {
    signal?.throwIfAborted();
    const checked = await checkAdmissionsWithKernel(text, kernel, { nativeBinaryPath });
    if (checked.descriptor.canonicalAdmissionsSha256 !== undefined &&
        checked.descriptor.canonicalAdmissionsSha256 !== digest(text)) {
      throw new Error('PSC0_KERNEL_INPUT_BINDING');
    }
    actualKernel = checked.descriptor;
    signal?.throwIfAborted();
    return checked.result;
  };

  if (seedPath) {
    const { runCheckedSeedSession } = await import('./checked-seed-session.mjs');
    const result = await runCheckedSeedSession({
      binaryPath: binary, sourceKind: snapshot.kind, source: snapshot.source,
      sources: snapshot.sources, checkAdmissions, emit: false,
    });
    admissions = result.admissions;
  } else {
    const kind = snapshot.kind === 'ps' ? compiler.PsCompilerSourceKind?.proofScript
      : compiler.PsCompilerSourceKind?.lean;
    if (kind === undefined) throw new Error('PSC2_CHECKED_SOURCE_KIND_API_MISSING');
    const session = createCheckedPreparedSession(compiler, async text => {
      admissions = text;
      return checkAdmissions(text);
    }, checkedKernelIdentity(kernel));
    const handle = library ? await session.checkProject(kind, projectUnits)
      : await session.checkSources(kind, snapshot.sources);
    if (!checkOnly) {
      const emitted = library ? session.emitProjectChecked(handle) : session.emitChecked(handle);
      libraryEmission = emitted.library;
      typeScript = emitted.typeScript;
      irValidation = emitted.validation;
      if (irValidation.canonicalAdmissionsSha256 !== digest(admissions) ||
          irValidation.typeScriptSha256 !== digest(typeScript)) throw new Error('PSC0_EMISSION_BINDING');
    }
  }
  const receipt = {
    schemaVersion: 4, kind: 'psc0-checked-build', profile,
    provider: checkedKernelIdentity(kernel), kernel: actualKernel, compiler: compilerIdentity,
    sourceClosureSha256: snapshot.closureSha256,
    flattenedSourceSha256: digest(snapshot.source), sourceCount: snapshot.ordered.length,
    sources: snapshot.ordered.map(item => ({
      path: path.relative(snapshot.root, item.path).split(path.sep).join('/'),
      sha256: digest(Buffer.from(item.source, 'utf8')),
    })),
    canonicalAdmissionsSha256: digest(admissions),
    kernelAdmissionAccepted: true, extensions,
    ...(library ? { library: {
      profile: 'psc-ts-library/1', exportSelectionSha256: digest(JSON.stringify(exportSelection)),
      configSha256: projectConfigSource === undefined ? null : digest(projectConfigSource),
      publicInterfaceSha256: libraryEmission?.publicInterfaceSha256 ?? null,
      abiStatus: checkOnly ? 'not-requested' : 'checked-bounded',
    } } : {}),
    runtimeIr: irValidation ?? { status: 'not-requested' },
    semanticPreservationProved: false, pscvVerified: false, strictSh1Qualified: false,
  };
  const assertCurrent = async () => {
    await assertSnapshotCurrent(snapshot, signal);
    if (projectConfigSource !== undefined) {
      const current = await readFile(projectConfigPath);
      if (!current.equals(Buffer.from(projectConfigSource, 'utf8'))) {
        throw new Error('PSC0_LIBRARY_CONFIG_CHANGED_DURING_BUILD');
      }
    }
    if (extensionExecution !== undefined) await assertCommandExtensionCurrent(extensionExecution);
    signal?.throwIfAborted();
  };
  if (checkOnly) {
    await assertCurrent();
    return Object.freeze(receipt);
  }
  if (typeof typeScript !== 'string') throw new Error('PSC2_CHECKED_TS_RESULT');
  const stem = path.basename(output).replace(/\.(?:ts|js)$/u, '');
  const projectLayout = library ? libraryArtifacts({ projectRoot, outputPath: output, emission: libraryEmission }) : undefined;
  if (projectLayout) {
    for (const name of projectLayout.artifacts.keys()) checkedOutputPath(path.join(projectRoot, name));
  }
  const expectedVersion = expectedTypeScriptVersion();
  const tsc = resolveTypeScriptCli();
  const version = spawnSync(process.execPath, [tsc, '--version'], {
    encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024, windowsHide: true,
  });
  if (version.error || version.status !== 0 || version.stdout.trim() !== 'Version ' + expectedVersion) {
    throw new Error('PSC2_CHECKED_TYPESCRIPT_PIN: require TypeScript ' + expectedVersion);
  }
  await prepareCheckedOutputDirectory(output);
  const staging = await mkdtemp(path.join(path.dirname(output), '.psc-target-'));
  try {
    const tsInputs = projectLayout?.artifacts ?? new Map([[stem + '.ts', typeScript]]);
    for (const [name, text] of tsInputs) {
      const file = path.join(staging, name);
      await mkdir(path.dirname(file), { recursive: true });
      await writeFile(file, text);
    }
    const tsFiles = [...tsInputs.keys()].map(name => path.join(staging, name));
    signal?.throwIfAborted();
    const args = typeScriptProfileArgs([
      ...tsFiles, '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler',
      '--strict', '--declaration', '--sourceMap', '--noEmitOnError', '--skipLibCheck', '--pretty', 'false',
    ], expectedVersion);
    const run = spawnSync(process.execPath, [tsc, ...args], {
      encoding: 'utf8', timeout: 120000, killSignal: 'SIGKILL',
      maxBuffer: 16 * 1024 * 1024, windowsHide: true,
    });
    if (run.error) throw run.error;
    if (run.status !== 0) throw new Error('PSC2_CHECKED_TSC_FAILED: ' + run.stdout + '\n' + run.stderr);
    const js = await readFile(path.join(staging,
      projectLayout ? projectLayout.bundle.replace(/\.ts$/u, '.js') : stem + '.js'));
    receipt.typeScriptSha256 = digest(typeScript);
    receipt.targetValidation = {
      tool: 'typescript', version: expectedVersion, launcherSha256: digest(await readFile(tsc)),
      target: 'ES2022', module: 'ES2022', moduleResolution: 'bundler',
      strict: true, noEmitOnError: true, generatedJavaScriptSha256: digest(js),
      semanticPreservationProved: false,
    };
    const artifacts = projectLayout?.artifacts ?? new Map([[stem + '.ts', typeScript]]);
    if (output.endsWith('.js')) {
      artifacts.set(stem + '.js', js);
      for (const suffix of ['.d.ts', '.js.map']) {
        artifacts.set(stem + suffix, await readFile(path.join(staging, stem + suffix)));
      }
      artifacts.set(stem + '.admissions.json', admissions);
      receipt.javaScriptSha256 = digest(js);
    }
    return await publishCheckedArtifacts({
      outputPath: output, entryPath: snapshot.entry, artifacts, receipt,
      ...(projectLayout ? { projectRoot, facadeSources: projectLayout.facadeSources } : {}),
      beforeCommit: assertCurrent,
    });
  } finally {
    await rm(staging, { recursive: true, force: true }).catch(() => {});
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const options = { entryPath: args.shift() };
  while (args.length) {
    const flag = args.shift();
    if (flag === '--check') options.checkOnly = true;
    else if (['--out', '--compiler', '--compiler-sha256', '--seed', '--kernel', '--kernel-binary', '--profile'].includes(flag)) {
      const value = args.shift();
      if (!value || value.startsWith('--')) throw new Error('Missing value for ' + flag);
      options[{
        '--out': 'outputPath', '--compiler': 'compilerPath', '--compiler-sha256': 'compilerSha256',
        '--seed': 'seedPath', '--kernel': 'kernel', '--kernel-binary': 'nativeBinaryPath', '--profile': 'profile',
      }[flag]] = value;
    } else throw new Error('Unknown checked-build option: ' + flag);
  }
  if (!options.entryPath) throw new Error('usage: checked-build.mjs <entry> [--check | --out file.ts|file.js] [--compiler file.js] [--kernel-binary absolute-path]');
  process.stdout.write('PSC0_EXTENSIONS: []\n');
  const receipt = await buildChecked(options);
  process.stdout.write('PSC0_CHECKED_BUILD: PASS ' + JSON.stringify(receipt) + '\n');
}
