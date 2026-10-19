import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { lstat, mkdir, readFile, realpath, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const hostRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const nativeSeedRecoveryRecipe = 'native-lean-original-ir-four-products-ts7/1';
const recipePaths = [
  'scripts/sh1-native-seed-recovery.mjs',
  'scripts/sh1-successor-seed.mjs',
  'scripts/sh1-seed-manifest.mjs',
  'scripts/sh1-grammar-profile.mjs',
  'scripts/sh1-source-snapshot.mjs',
  'scripts/workspace-layout.mjs',
  'scripts/typescript-cli.mjs',
];
const productFields = [
  ['canonical-source.json', 'canonicalSurfaceSourceSha256'],
  ['admissions.json', 'normalizedCanonicalAdmissionsSha256'],
  ['index.ts', 'typescriptSha256'],
  ['index.js', 'javascriptSha256'],
];
const sha256 = (bytes) => createHash('sha256').update(bytes).digest('hex');
const blobSha1 = (bytes) => createHash('sha1')
  .update('blob ' + bytes.length + '\0').update(bytes).digest('hex');
const clone = (value) => JSON.parse(JSON.stringify(value));
const diagnostic = (suffix) => 'PSC0_SH1_NATIVE_SEED_' + suffix;
const sha = (value) => typeof value === 'string' && /^[a-f0-9]{64}$/u.test(value);
const gitSha = (value) => typeof value === 'string' && /^[a-f0-9]{40}$/u.test(value);

function exactKeys(value, expected, label) {
  assert(value !== null && typeof value === 'object' && !Array.isArray(value), diagnostic(label));
  assert.deepEqual(Object.keys(value).sort(), [...expected].sort(), diagnostic(label + '_KEYS'));
}

async function absent(file, label) {
  try { await lstat(file); } catch (error) {
    if (error.code === 'ENOENT') return;
    throw error;
  }
  assert.fail(diagnostic(label + '_MUST_BE_ABSENT') + ': ' + file);
}

async function regularFile(file, label) {
  assert((await lstat(file)).isFile(), diagnostic(label + '_REGULAR_FILE'));
  assert.equal(await realpath(file), file, diagnostic(label + '_NO_SYMLINK'));
  return readFile(file);
}

async function verifyRunnerFiles(root, recipe) {
  exactKeys(recipe, ['id', 'files'], 'RECIPE');
  assert.equal(recipe.id, nativeSeedRecoveryRecipe, diagnostic('RECIPE_ID'));
  assert(Array.isArray(recipe.files), diagnostic('RECIPE_FILES'));
  assert.deepEqual(recipe.files.map((item) => item.path), recipePaths, diagnostic('RECIPE_PATHS'));
  for (const item of recipe.files) {
    exactKeys(item, ['path', 'gitBlobSha1'], 'RECIPE_FILE');
    assert(gitSha(item.gitBlobSha1), diagnostic('RECIPE_BLOB'));
    const bytes = await regularFile(path.join(root, item.path), 'RECIPE_FILE');
    assert.equal(blobSha1(bytes), item.gitBlobSha1, diagnostic('RECIPE_FILE_PIN') + ': ' + item.path);
  }
  return sha256(JSON.stringify(recipe));
}

// This sidecar is an additional execution recipe. It never replaces the
// immutable parent-based recipe inside selfhost-seed.json or its seed identity.
// All imported repository modules are authenticated before the dynamic import.
export async function readNativeSeedRecoveryPolicy({ root = hostRoot } = {}) {
  root = await realpath(root);
  const policyPath = path.join(root, 'selfhost-seed-recovery.json');
  const policyBytes = await regularFile(policyPath, 'POLICY');
  const policy = JSON.parse(policyBytes.toString('utf8'));
  exactKeys(policy, [
    'schemaVersion', 'kind', 'recipe', 'selectedSeed', 'source', 'toolchain',
    'qualificationBoundary',
  ], 'POLICY');
  assert.equal(policy.schemaVersion, 1, diagnostic('POLICY_VERSION'));
  assert.equal(policy.kind, 'psc0-native-ts7-seed-recovery-policy', diagnostic('POLICY_KIND'));
  const recipeSha256 = await verifyRunnerFiles(root, policy.recipe);
  exactKeys(policy.selectedSeed, ['manifestSha256', 'identitySha256'], 'SELECTED_SEED');
  assert(sha(policy.selectedSeed.manifestSha256) && sha(policy.selectedSeed.identitySha256),
    diagnostic('SELECTED_DIGESTS'));
  exactKeys(policy.source, [
    'ref', 'closureSha256', 'moduleCount', 'kind', 'entry',
  ], 'SOURCE');
  assert(gitSha(policy.source.ref) && sha(policy.source.closureSha256), diagnostic('SOURCE_PINS'));
  assert(Number.isSafeInteger(policy.source.moduleCount) && policy.source.moduleCount > 0,
    diagnostic('MODULE_COUNT'));
  assert.equal(policy.source.kind, 'raw-authoritative-lean', diagnostic('SOURCE_KIND'));
  assert.equal(policy.source.entry, 'packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean',
    diagnostic('SOURCE_ENTRY'));
  assert.equal(policy.qualificationBoundary,
    'A separate successful isolated cold receipt is required before claiming this recovery route qualified.',
    diagnostic('QUALIFICATION_BOUNDARY'));
  const manifestPath = path.join(root, 'selfhost-seed.json');
  const manifestBytes = await regularFile(manifestPath, 'SELECTED_MANIFEST');
  assert.equal(sha256(manifestBytes), policy.selectedSeed.manifestSha256,
    diagnostic('SELECTED_MANIFEST_PIN'));
  const seeds = await import(pathToFileURL(path.join(root, 'scripts/sh1-successor-seed.mjs')).href);
  const selected = await seeds.readSelectedAuthoringSeed(manifestPath);
  assert.equal(selected.manifest?.kind, 'psc0-qualified-successor-seed', diagnostic('SELECTED_KIND'));
  assert.equal(selected.identitySha256, policy.selectedSeed.identitySha256, diagnostic('SELECTED_IDENTITY'));
  assert.equal(selected.sourceRef, policy.source.ref, diagnostic('SELECTED_SOURCE'));
  assert.equal(selected.manifest.sourceClosureSha256, policy.source.closureSha256,
    diagnostic('SELECTED_CLOSURE'));
  assert.deepEqual(policy.toolchain, selected.manifest.toolchain, diagnostic('SELECTED_TOOLCHAIN'));
  assert.equal(policy.toolchain.typescript, 'Version 7.0.2', diagnostic('TYPESCRIPT7_ONLY'));
  assert.equal(selected.manifest.authoring.strictSh1Qualified, false, diagnostic('STRICT_SCOPE'));
  return {
    root, policy, policySha256: sha256(policyBytes), recipeSha256, selected, seeds,
    manifestBytes,
  };
}

function outside(directory, container, label) {
  const relative = path.relative(container, directory);
  assert(relative === '..' || relative.startsWith('..' + path.sep) || path.isAbsolute(relative),
    diagnostic(label));
}

async function existingAncestor(file) {
  let current = path.resolve(file);
  for (;;) {
    try {
      const resolved = await realpath(current);
      return path.resolve(resolved, path.relative(current, file));
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
      const parent = path.dirname(current);
      assert.notEqual(parent, current, diagnostic('PATH_ANCESTOR'));
      current = parent;
    }
  }
}

async function installedTypeScriptPackage(launcher) {
  let directory = path.dirname(launcher);
  for (;;) {
    const file = path.join(directory, 'package.json');
    try {
      const bytes = await readFile(file);
      const metadata = JSON.parse(bytes.toString('utf8'));
      assert.equal(metadata.name, 'typescript', diagnostic('TYPESCRIPT_PACKAGE_NAME'));
      // Check metadata before invoking even --version: this route never starts TS5.
      assert.equal(metadata.version, '7.0.2', diagnostic('TYPESCRIPT_PACKAGE_VERSION'));
      assert.equal(typeof metadata.bin?.tsc, 'string', diagnostic('TYPESCRIPT_PACKAGE_BIN'));
      assert.equal(await realpath(path.resolve(directory, metadata.bin.tsc)), launcher,
        diagnostic('TYPESCRIPT_PACKAGE_OWNER'));
      return { path: file, sha256: sha256(bytes), version: metadata.version };
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
      const parent = path.dirname(directory);
      assert.notEqual(parent, directory, diagnostic('TYPESCRIPT_PACKAGE_MISSING'));
      directory = parent;
    }
  }
}

export async function recoverNativeSeed({
  sourceWorkspace, outputDirectory, cacheDirectory, cold = false, root = hostRoot,
}) {
  assert.equal(typeof cold, 'boolean', diagnostic('COLD_FLAG'));
  assert(sourceWorkspace && outputDirectory && cacheDirectory, diagnostic('PATH_ARGUMENTS'));
  const authenticated = await readNativeSeedRecoveryPolicy({ root });
  root = authenticated.root;
  const { policy, policySha256, recipeSha256, selected, seeds, manifestBytes } = authenticated;
  sourceWorkspace = await realpath(path.resolve(sourceWorkspace));
  outputDirectory = await existingAncestor(path.resolve(outputDirectory));
  cacheDirectory = await existingAncestor(path.resolve(cacheDirectory));
  assert.equal(path.basename(sourceWorkspace), 'psc0', diagnostic('SOURCE_WORKSPACE_NAME'));
  assert.notEqual(sourceWorkspace, root, diagnostic('SEPARATE_PINNED_SOURCE_CHECKOUT'));
  outside(outputDirectory, sourceWorkspace, 'OUTPUT_OUTSIDE_PINNED_SOURCE');
  outside(cacheDirectory, sourceWorkspace, 'CACHE_OUTSIDE_PINNED_SOURCE');
  outside(outputDirectory, cacheDirectory, 'OUTPUT_OUTSIDE_CACHE');
  outside(cacheDirectory, outputDirectory, 'CACHE_OUTSIDE_OUTPUT');
  await absent(outputDirectory, 'OUTPUT');
  if (cold) {
    await absent(path.join(sourceWorkspace, '.lake/build'), 'NATIVE_BUILD_CACHE');
    await absent(cacheDirectory, 'SEED_CACHE');
    await absent(path.join(sourceWorkspace, '.selfhost-seeds'), 'SOURCE_SEED_CACHE');
    await absent(path.join(sourceWorkspace, 'node_modules'), 'SOURCE_NODE_MODULES');
  }
  await mkdir(path.join(outputDirectory, 'logs'), { recursive: true });
  const productsDirectory = path.join(outputDirectory, 'products');
  await mkdir(productsDirectory);
  const started = performance.now();
  const receipt = {
    schemaVersion: 1,
    evidence: 'native-source-ts7-seed-recovery',
    passed: false,
    cold,
    sourceRef: policy.source.ref,
    sourceClosureSha256: policy.source.closureSha256,
    sourceKind: policy.source.kind,
    moduleCount: policy.source.moduleCount,
    selectedManifestSha256: policy.selectedSeed.manifestSha256,
    selectedSeedIdentitySha256: selected.identitySha256,
    policySha256,
    recipe: clone(policy.recipe),
    recipeSha256,
    expectedArtifacts: clone(selected.manifest.expectedArtifacts),
    generatedCompilerExecuted: false,
    historicalParentCompilerExecuted: false,
    historicalTypeScriptExecuted: false,
    originalSelectedManifestChanged: false,
    strictSh1Qualified: false,
    fullStandardConformance: false,
    fullPscvConformance: false,
    providerCheckedByThisRecovery: false,
    scope: 'Reproduce the selected compiler from pinned native Lean source with TS7 and compare all four final products; preserve the existing selected seed identity.',
    commands: [],
  };
  let sequence = 0;
  let commandEnvironment = { ...process.env };
  delete commandEnvironment.NODE_OPTIONS;
  delete commandEnvironment.NODE_PATH;
  delete commandEnvironment.LEAN_PATH;
  delete commandEnvironment.LEAN_SRC_PATH;
  async function run(label, executable, args, { cwd = sourceWorkspace, timeout = 180000 } = {}) {
    const logName = String(++sequence).padStart(3, '0') + '-' + label;
    const begin = performance.now();
    const result = spawnSync(executable, args, {
      cwd, env: commandEnvironment, encoding: null,
      timeout, maxBuffer: 128 * 1024 * 1024,
    });
    const stdout = result.stdout ?? Buffer.alloc(0);
    const stderr = result.stderr ?? Buffer.alloc(0);
    await writeFile(path.join(outputDirectory, 'logs', logName + '.stdout'), stdout);
    await writeFile(path.join(outputDirectory, 'logs', logName + '.stderr'), stderr);
    receipt.commands.push({
      label, executable, args, cwd, timeoutMs: timeout,
      elapsedMs: performance.now() - begin,
      status: result.status, signal: result.signal,
      stdout: 'logs/' + logName + '.stdout',
      stderr: 'logs/' + logName + '.stderr',
      stdoutSha256: sha256(stdout), stderrSha256: sha256(stderr),
      ...(result.error ? { error: { name: result.error.name, message: result.error.message } } : {}),
    });
    assert.equal(result.status, 0, diagnostic('COMMAND_' + label) + ': ' +
      (result.error?.message ?? stderr.toString('utf8').slice(-4000)));
    return stdout;
  }
  async function verifySource(label) {
    const sourceTop = (await run(label + '-root', 'git', ['rev-parse', '--show-toplevel']))
      .toString('utf8').trim();
    assert.equal(await realpath(sourceTop), path.dirname(sourceWorkspace), diagnostic('SOURCE_REPOSITORY'));
    const ref = (await run(label + '-ref', 'git', ['rev-parse', 'HEAD'])).toString('utf8').trim();
    assert.equal(ref, policy.source.ref, diagnostic('SOURCE_REF'));
    assert.equal((await run(label + '-status', 'git',
      ['status', '--porcelain', '--untracked-files=no'])).toString('utf8'), '',
    diagnostic('SOURCE_TRACKED_FILES_CLEAN'));
  }
  let completed = false;
  try {
    assert.equal(process.version, policy.toolchain.node, diagnostic('NODE_PIN'));
    assert.equal(process.platform, policy.toolchain.platform, diagnostic('PLATFORM_PIN'));
    assert.equal(process.arch, policy.toolchain.architecture, diagnostic('ARCHITECTURE_PIN'));
    assert.equal(process.env.PSC0_TYPESCRIPT_VERSION ?? '7.0.2', '7.0.2', diagnostic('TYPESCRIPT_PROFILE'));
    const currentSourceRef = (await run('runner-ref', 'git', ['rev-parse', 'HEAD'], { cwd: root }))
      .toString('utf8').trim();
    assert(gitSha(currentSourceRef), diagnostic('RUNNER_SOURCE_REF'));
    receipt.runnerSourceRef = currentSourceRef;
    await verifySource('source-before');
    const [snapshot, typescript] = await Promise.all([
      import(pathToFileURL(path.join(root, 'scripts/sh1-source-snapshot.mjs')).href),
      import(pathToFileURL(path.join(root, 'scripts/typescript-cli.mjs')).href),
    ]);
    assert.equal(typescript.expectedTypeScriptVersion(), '7.0.2', diagnostic('LOCATOR_PROFILE'));
    const tsc = typescript.resolveTypeScriptCli();
    const packageIdentity = await installedTypeScriptPackage(tsc);
    const tscBytes = await regularFile(tsc, 'TYPESCRIPT_LAUNCHER');
    commandEnvironment = {
      ...commandEnvironment, PSC0_TSC: tsc, PSC0_TYPESCRIPT_VERSION: '7.0.2',
    };
    const leanVersion = (await run('lean-version', 'lake', ['env', 'lean', '--version']))
      .toString('utf8').trim();
    const leanGitHash = (await run('lean-githash', 'lake', ['env', 'lean', '--githash']))
      .toString('utf8').trim();
    const tscVersion = (await run('typescript-version', process.execPath, [tsc, '--version'], { cwd: root }))
      .toString('utf8').trim();
    receipt.toolchain = {
      node: process.version, platform: process.platform, architecture: process.arch,
      lean: leanVersion, leanGitHash, typescript: tscVersion,
    };
    assert.deepEqual(receipt.toolchain, policy.toolchain, diagnostic('TOOLCHAIN_PIN'));
    receipt.typescriptInstallation = {
      launcher: tsc, launcherSha256: sha256(tscBytes), package: packageIdentity,
    };
    const closure = await snapshot.readBootstrapClosure(sourceWorkspace);
    assert.equal(closure.sha256, policy.source.closureSha256, diagnostic('SOURCE_CLOSURE'));
    assert.equal(closure.moduleCount, policy.source.moduleCount, diagnostic('SOURCE_MODULE_COUNT'));
    await writeFile(path.join(outputDirectory, 'source-closure.json'),
      JSON.stringify(closure.manifest, null, 2) + '\n');
    const aggregateSource = closure.ordered
      .map(({ source }) => snapshot.stripBootstrapImports(source)).join('\n\n') + '\n';
    const aggregatePath = path.join(outputDirectory, 'raw-source.lean');
    await writeFile(aggregatePath, aggregateSource);
    receipt.aggregateSourceSha256 = sha256(aggregateSource);
    receipt.rawSourceBytes = closure.bytes;
    await run('native-build', 'lake', ['build', 'psc1', 'psc1_ir_check_tests'], { timeout: 900000 });
    const nativeBuildRoot = await realpath(path.join(sourceWorkspace, '.lake/build'));
    const nativeCompiler = await realpath(path.join(sourceWorkspace, '.lake/build/bin/psc1'));
    const nativeChecker = await realpath(path.join(sourceWorkspace, '.lake/build/bin/psc1_ir_check_tests'));
    for (const binary of [nativeCompiler, nativeChecker]) {
      const relative = path.relative(nativeBuildRoot, binary);
      assert(relative !== '' && relative !== '..' && !relative.startsWith('..' + path.sep) &&
        !path.isAbsolute(relative), diagnostic('NATIVE_BINARY_INSIDE_PINNED_BUILD'));
    }
    const compilerHash = sha256(await regularFile(nativeCompiler, 'NATIVE_COMPILER'));
    const checkerHash = sha256(await regularFile(nativeChecker, 'NATIVE_CHECKER'));
    receipt.nativeBinaries = { compilerSha256: compilerHash, originalIrCheckerSha256: checkerHash };
    const typeScriptPath = path.join(productsDirectory, 'index.ts');
    await run('native-original-ir', nativeChecker, [aggregatePath, typeScriptPath]);
    const reportPath = typeScriptPath + '.ir-report.json';
    const reportBytes = await readFile(reportPath);
    const report = JSON.parse(reportBytes.toString('utf8'));
    assert.equal(report.kind, 'psc0-native-original-ir-check', diagnostic('IR_REPORT_KIND'));
    assert.equal(report.accepted, true, diagnostic('IR_ACCEPTED'));
    assert.equal(report.traversalComplete, true, diagnostic('IR_COMPLETE'));
    assert.equal(report.findingCount, 0, diagnostic('IR_FINDINGS'));
    assert.equal(report.retainedFindingCount, 0, diagnostic('IR_RETAINED_FINDINGS'));
    assert.equal(report.omittedFindingDetails, 0, diagnostic('IR_OMITTED_FINDINGS'));
    assert.equal(report.strictSh1Qualified, false, diagnostic('IR_SCOPE'));
    assert.equal(report.sourcePath, aggregatePath, diagnostic('IR_SOURCE'));
    receipt.originalIr = {
      report: 'products/index.ts.ir-report.json', reportSha256: sha256(reportBytes),
      accepted: report.accepted, traversalComplete: report.traversalComplete,
      expressionCount: report.expressionCount, visitedSteps: report.visitedSteps,
      findingCount: report.findingCount,
      sameOriginalIrCheckedBeforeEmission: true,
    };
    assert.equal(sha256(await readFile(typeScriptPath)),
      selected.manifest.expectedArtifacts.typescriptSha256, diagnostic('NATIVE_TYPESCRIPT_PRODUCT'));
    const compilationArgs = typescript.typeScriptProfileArgs([
      typeScriptPath, '--target', 'ES2022', '--module', 'ES2022',
      '--moduleResolution', 'bundler', '--strict', '--declaration', '--sourceMap',
      '--noEmitOnError', '--skipLibCheck', '--pretty', 'false',
    ], '7.0.2');
    await run('typescript-compile', process.execPath, [tsc, ...compilationArgs], { cwd: root });
    const admissions = await run('native-admissions', nativeCompiler,
      ['admissions', path.join(sourceWorkspace, policy.source.entry)]);
    await writeFile(path.join(productsDirectory, 'admissions.json'), admissions);
    const surface = [];
    for (const [index, item] of closure.ordered.entries()) {
      const translated = await run('native-ps-' + String(index + 1).padStart(2, '0'),
        nativeCompiler, ['translate', path.join(sourceWorkspace, item.path), '--to', 'ps']);
      // Keep the exact printer text; no host normalization or legacy grammar fallback.
      surface.push({ path: item.path.replace(/\.lean$/u, '.ps'), source: translated.toString('utf8') });
    }
    await writeFile(path.join(productsDirectory, 'canonical-source.json'),
      JSON.stringify(surface, null, 2) + '\n');
    const artifacts = {};
    for (const [file, field] of productFields) {
      artifacts[field] = sha256(await readFile(path.join(productsDirectory, file)));
      assert.equal(artifacts[field], selected.manifest.expectedArtifacts[field],
        diagnostic('FINAL_PRODUCT') + ': ' + file);
    }
    receipt.artifacts = artifacts;
    assert.equal(sha256(await readFile(nativeCompiler)), compilerHash, diagnostic('NATIVE_COMPILER_CHANGED'));
    assert.equal(sha256(await readFile(nativeChecker)), checkerHash, diagnostic('NATIVE_CHECKER_CHANGED'));
    assert.equal(sha256(await readFile(tsc)), sha256(tscBytes), diagnostic('TYPESCRIPT_LAUNCHER_CHANGED'));
    assert.equal((await installedTypeScriptPackage(tsc)).sha256, packageIdentity.sha256,
      diagnostic('TYPESCRIPT_PACKAGE_CHANGED'));
    assert.equal((await snapshot.readBootstrapClosure(sourceWorkspace)).sha256,
      closure.sha256, diagnostic('SOURCE_CLOSURE_CHANGED'));
    await verifySource('source-after');
    receipt.trackedSourceCleanBeforeAndAfter = true;
    receipt.sourceClosureUnchanged = true;
    assert.equal(await verifyRunnerFiles(root, policy.recipe), recipeSha256, diagnostic('RUNNER_CHANGED'));
    assert.equal(sha256(await readFile(path.join(root, 'selfhost-seed-recovery.json'))),
      policySha256, diagnostic('POLICY_CHANGED'));
    assert.deepEqual(await readFile(path.join(root, 'selfhost-seed.json')), manifestBytes,
      diagnostic('SELECTED_MANIFEST_CHANGED'));
    const identity = await seeds.materializeSuccessorSeed({
      generationDirectory: productsDirectory, cacheDirectory, manifest: selected.manifest,
      origin: nativeSeedRecoveryRecipe + '; recipe=' + recipeSha256 + '; policy=' + policySha256,
    });
    assert.equal(identity, selected.identitySha256, diagnostic('MATERIALIZED_IDENTITY'));
    assert(await seeds.verifySuccessorSeedCache(cacheDirectory, selected.manifest),
      diagnostic('MATERIALIZED_CACHE'));
    receipt.cache = { directory: cacheDirectory, identitySha256: identity, verified: true };
    receipt.passed = true;
    completed = true;
    return receipt;
  } catch (error) {
    receipt.failure = { name: error.name, message: error.message };
    throw error;
  } finally {
    receipt.elapsedMs = performance.now() - started;
    const receiptBytes = JSON.stringify(receipt, null, 2) + '\n';
    await writeFile(path.join(outputDirectory, 'receipt.json'), receiptBytes);
    // The complete object makes the exact pretty receipt reproducible from Actions logs.
    process.stdout.write('PSC0_SH1_NATIVE_SEED_RECEIPT: ' + JSON.stringify(receipt) + '\n');
    process.stdout.write('PSC0_SH1_NATIVE_SEED_RECOVERY: ' + JSON.stringify({
      passed: completed, cold, sourceRef: receipt.sourceRef,
      selectedSeedIdentitySha256: receipt.selectedSeedIdentitySha256,
      recipeSha256, policySha256, artifacts: receipt.artifacts ?? null,
      receiptPath: path.join(outputDirectory, 'receipt.json'),
      receiptFileSha256: sha256(receiptBytes),
      elapsedMs: receipt.elapsedMs,
    }) + '\n');
  }
}

function argumentsForCli(args) {
  const result = {};
  const names = new Map([
    ['--source-workspace', 'sourceWorkspace'],
    ['--out', 'outputDirectory'],
    ['--cache-directory', 'cacheDirectory'],
  ]);
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === '--cold') {
      assert(!Object.hasOwn(result, 'cold'), diagnostic('DUPLICATE_COLD'));
      result.cold = true;
    } else {
      const name = names.get(arg);
      assert(name && !Object.hasOwn(result, name), diagnostic('CLI_ARGUMENT') + ': ' + arg);
      assert(index + 1 < args.length && !args[index + 1].startsWith('--'), diagnostic('CLI_VALUE'));
      result[name] = args[++index];
    }
  }
  return result;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  await recoverNativeSeed(argumentsForCli(process.argv.slice(2)));
}
