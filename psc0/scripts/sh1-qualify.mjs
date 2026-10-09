import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { appendFile, mkdir, readFile, realpath, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { performance } from 'node:perf_hooks';
import {
  bootstrapEntryRelative as entryRelative,
  readBootstrapClosure as sourceClosure,
  stripBootstrapImports as stripImports,
  loadGeneratedCompiler as loadCompiler,
} from './sh1-source-snapshot.mjs';
import {
  qualifiedSeedIdentity, validateQualifiedSeedManifest,
  makeQualifiedSeedManifest, verifyQualifiedSeedCache, materializeQualifiedSeed,
} from './sh1-seed-manifest.mjs';
import {
  readSelectedAuthoringSeed as readSelectedSeed, successorSeedSelection,
  validateSuccessorSeedManifest, makeSuccessorSeedManifest, successorSeedIdentity,
  verifySuccessorSeedCache, materializeSuccessorSeed,
} from './sh1-successor-seed.mjs';
import { runSh1GrammarClosureRoundTrip, sh1GrammarProfile } from './sh1-grammar-conformance.mjs';
import { resolveTypeScriptCli, expectedTypeScriptVersion, typeScriptProfileArgs } from './typescript-cli.mjs';
import { createGeneratedPreparationSession } from './generated-preparation-session.mjs';
import { inventoryOriginalIr } from './original-ir-inventory.mjs';
import { compileStrictSources, strictSourceInputsFromClosure } from './sh1-strict-source.mjs';
import { runStrictSourceConformance } from './sh1-strict-source-conformance.mjs';
import { runStrictTargetConformance } from './sh1-strict-target-conformance.mjs';
import { bindStrictQualificationEvidence } from './sh1-strict-evidence.mjs';
import { runNativeStrictRuntimeReference, runStrictRuntimeConformance } from './sh1-strict-runtime-conformance.mjs';
import { runIrCheckerConformance, runNativeIrCheckerConformance } from './sh1-ir-checker-conformance.mjs';
import { runFoundationConformance } from './sh1-foundation-conformance.mjs';
import { runHelperConformance, runHelperRuntimeConformance } from './sh1-helper-conformance.mjs';
import { runGenericErasureConformance } from './sh1-generic-erasure-conformance.mjs';
import { runIterationConformance } from './sh1-iteration-conformance.mjs';
import { runMigrationWorkerConformance } from './sh1-migration-worker-conformance.mjs';
import { runMigrationWorkerAbi } from './sh1-migration-worker-abi.mjs';
import {
  compileTypeScript, runCommand, runSh1Capabilities, sha256, unwrap, valueTag,
} from './sh1-capabilities.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const historicalRef = '37f63c39d4a07189938046c64152bba25d789450';
const historicalTree = '02207b677c91471d6bb5cb3f6418995aed0d0102';
const historicalRecipe = Object.freeze({
  id: 'psc0-native-recovery/1',
  build: ['lake', 'build', 'psc1'],
  compile: ['.lake/build/bin/psc1', 'build', entryRelative, '--out', '<output>/index.js'],
  artifacts: ['index.ts', 'index.js', 'index.d.ts', 'index.js.map'],
  leanGitHash: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
});
const [command, ...args] = process.argv.slice(2);
const historicalCommands = new Set([
  'seed-identity', 'recover-seed', 'recover-qualified-seed', 'recover-successor-seed',
]);
if (historicalCommands.has(command)) {
  throw new Error('PSC0_SH1_LEGACY_RECOVERY_RETIRED: current development uses TypeScript 7 only; ' +
    'use scripts/sh1-native-seed-recovery.mjs for the selected seed. Historical recipes remain at their immutable source revisions.');
}
const typescriptVersion = expectedTypeScriptVersion();
assert.equal(typescriptVersion, '7.0.2',
  'PSC0_SH1_TYPESCRIPT_PROFILE: current qualification requires TypeScript 7.0.2');
const tsc = resolveTypeScriptCli();
const typescriptProfile = Object.freeze({
  version: typescriptVersion,
  purpose: 'current-emission',
  arguments: typeScriptProfileArgs([], typescriptVersion),
});

if (!historicalCommands.has(command)) {
  const config = JSON.parse(await readFile(path.join(root, 'psconfig.json'), 'utf8'));
  assert.equal(config.languageVersion, '0.9-r3', 'PSC0_SH1_GRAMMAR_VERSION');
  assert.deepEqual(config.sourceGrammar, sh1GrammarProfile, 'PSC0_SH1_GRAMMAR_PROFILE');
}

function capture(command, args, cwd = root) {
  return runCommand(command, args, {
    cwd, encoding: 'utf8', stdio: 'pipe', timeout: 30000,
  }).stdout.trim();
}

assert.equal(capture(process.execPath, [tsc, '--version']), 'Version ' + typescriptVersion,
  'PSC0_SH1_TYPESCRIPT_PIN');

async function writeJson(file, value) {
  await mkdir(path.dirname(file), { recursive: true });
  await writeFile(file, JSON.stringify(value, null, 2) + '\n');
}

function list(compiler, values) {
  return values.reduceRight((tail, head) => compiler.List.cons(head, tail), compiler.List.nil());
}

function admissionText(compiler, prepared) {
  return unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared), 'ADMISSIONS');
}

async function toolchainIdentity() {
  return {
    node: process.version,
    platform: process.platform,
    architecture: process.arch,
    lean: capture('lean', ['--version']),
    leanGitHash: capture('lean', ['--githash']),
    typescript: capture(process.execPath, [tsc, '--version']),
  };
}

async function recipeIdentity() {
  const files = [
    'scripts/sh1-qualify.mjs', 'scripts/sh1-capabilities.mjs',
    'scripts/sh1-grammar-conformance.mjs', 'scripts/sh1-projection-conformance.mjs',
    'scripts/sh1-successor-seed.mjs', 'psconfig.json',
    'scripts/sh1-fresh-name-conformance.mjs', 'scripts/sh1-migration-worker-conformance.mjs',
    'scripts/sh1-migration-worker-abi.mjs',
    'test/fixtures/selfhost-sh1-accumulators.lean', 'test/fixtures/selfhost-sh1-accumulators.ps',
    'scripts/proofscript-source.mjs', 'scripts/checked-source-snapshot.mjs',
    'scripts/selfhost-source-workspace.mjs', 'scripts/LeanCheckedSeed.lean',
    'scripts/typescript-cli.mjs', 'scripts/check-typescript-profile.mjs', 'scripts/workspace-layout.mjs',
    'scripts/generated-preparation-session.mjs', 'scripts/original-ir-inventory.mjs',
    'scripts/original-ir-carrier.mjs', 'scripts/sh1-ir-checker-conformance.mjs',
    'test/IrCheckerTests.lean',
    'scripts/sh1-strict-source.mjs', 'scripts/sh1-strict-source-conformance.mjs',
    'scripts/sh1-strict-target-conformance.mjs', 'scripts/sh1-strict-evidence.mjs',
    'scripts/sh1-strict-runtime-conformance.mjs', 'scripts/StrictSourceCompile.lean',
    'test/StrictRuntimeReference.lean',
    'docs/selfhost-language/strict/enabled-runtime-contract.json',
    'scripts/sh1-source-snapshot.mjs', 'scripts/sh1-seed-manifest.mjs',
    'scripts/sh1-iterate.mjs', 'scripts/sh1-iteration-conformance.mjs',
    'scripts/sh1-foundation-conformance.mjs',
    'test/fixtures/selfhost-sh1-foundation-reference.lean',
    'test/fixtures/selfhost-sh1-foundation-probe.lean',
    'scripts/sh1-helper-conformance.mjs',
    'test/fixtures/selfhost-sh1-helpers-reference.lean',
    'test/fixtures/selfhost-sh1-helpers-probe.lean',
    'scripts/sh1-generic-erasure-conformance.mjs',
    'test/fixtures/selfhost-sh1-generic-erasure.lean',
  ];
  const contents = [];
  for (const file of files) contents.push({ path: file, sha256: sha256(await readFile(path.join(root, file))) });
  return { files: contents, sha256: sha256(JSON.stringify(contents)) };
}

function executionRuntime(toolchain) {
  const { typescript, ...runtime } = toolchain;
  return runtime;
}

async function verifySeedExecutionRuntime(producerToolchain, producerVersion = '5.8.3') {
  assert(['5.8.3', '7.0.2'].includes(producerVersion), 'PSC0_SH1_SEED_PRODUCER_PROFILE');
  assert.equal(producerToolchain?.typescript, 'Version ' + producerVersion,
    'PSC0_SH1_SEED_PRODUCER_TYPESCRIPT_PIN');
  assert.deepEqual(executionRuntime(await toolchainIdentity()), executionRuntime(producerToolchain),
    'PSC0_SH1_SELECTED_SEED_EXECUTION_RUNTIME');
}

async function historicalIdentity(sourceRoot, producerToolchain) {
  // Authenticating existing seed bytes uses their recorded producer toolchain.
  // Rebuilding those bytes still requires the actual original TypeScript CLI.
  if (producerToolchain) await verifySeedExecutionRuntime(producerToolchain);
  else assert.equal(typescriptVersion, '5.8.3', 'PSC0_SH1_HISTORICAL_RECOVERY_TYPESCRIPT_PIN');
  assert.equal(capture('git', ['rev-parse', 'HEAD'], sourceRoot), historicalRef,
    'PSC0_SH1_HISTORICAL_REF');
  assert.equal(capture('git', ['rev-parse', 'HEAD:psc0'], sourceRoot), historicalTree,
    'PSC0_SH1_HISTORICAL_TREE');
  assert.equal(capture('git', ['status', '--porcelain', '--untracked-files=no', '--', '.'], sourceRoot), '',
    'PSC0_SH1_HISTORICAL_CHECKOUT_MODIFIED');
  const closure = await sourceClosure(sourceRoot);
  const baseline = JSON.parse(await readFile(path.join(root, 'docs/selfhost-language/baseline-evidence.json')));
  assert.equal(closure.moduleCount, 55, 'PSC0_SH1_HISTORICAL_MODULES');
  assert.equal(closure.ordered.length, baseline.orderedModules.length);
  for (let index = 0; index < closure.ordered.length; index++) {
    const item = closure.ordered[index];
    const expected = baseline.orderedModules[index];
    assert.equal('psc0/' + item.path, expected.path, 'PSC0_SH1_HISTORICAL_ORDER');
    const bytes = Buffer.from(item.source);
    const blob = createHash('sha1').update('blob ' + bytes.length + '\0').update(bytes).digest('hex');
    assert.equal(blob, expected.blobSha, 'PSC0_SH1_HISTORICAL_BLOB: ' + item.path);
  }
  const identity = {
    sourceRef: historicalRef,
    sourceTree: historicalTree,
    sourceClosureSha256: closure.sha256,
    toolchain: producerToolchain ?? await toolchainIdentity(),
    recipe: historicalRecipe,
  };
  assert.equal(identity.toolchain.leanGitHash, historicalRecipe.leanGitHash,
    'PSC0_SH1_LEAN_PIN');
  return { closure, identity, identitySha256: sha256(JSON.stringify(identity)) };
}

async function verifyHistoricalSeedReceipt(directory, { closure, identity, identitySha256 }) {
  const receipt = JSON.parse(await readFile(path.join(directory, 'seed.json'), 'utf8'));
  assert.equal(receipt.identitySha256, identitySha256, 'PSC0_SH1_HISTORICAL_CACHE_IDENTITY');
  assert.deepEqual(receipt.identity, identity, 'PSC0_SH1_HISTORICAL_CACHE_PROVENANCE');
  assert.deepEqual(receipt.modules, closure.manifest, 'PSC0_SH1_HISTORICAL_CACHE_MODULES');
  assert.equal(receipt.evidence, 'native-recovery-seed-from-preserved-55-module-source');
  assert.deepEqual(Object.keys(receipt.artifacts).sort(), [...historicalRecipe.artifacts].sort(),
    'PSC0_SH1_HISTORICAL_CACHE_PRODUCTS');
  for (const name of historicalRecipe.artifacts) {
    assert.equal(sha256(await readFile(path.join(directory, name))), receipt.artifacts[name],
      'PSC0_SH1_HISTORICAL_CACHE_DIGEST: ' + name);
  }
  return receipt;
}

async function historicalChildEnvironment(sourceRoot, outDir) {
  assert.equal(typescriptVersion, '5.8.3', 'PSC0_SH1_HISTORICAL_CHILD_PROFILE');
  // Pin after the Actions runner has augmented PATH. Frozen S0 cannot read
  // PSC0_TSC and must discover this exact installed launcher itself.
  const env = { ...process.env,
    PATH: path.dirname(tsc) + path.delimiter + (process.env.PATH ?? ''),
  };
  const receipt = {
    schemaVersion: 1,
    evidence: 'frozen-historical-typescript-resolution',
    sourceRef: historicalRef,
    expectedLauncher: await realpath(tsc),
    expectedVersion: 'Version 5.8.3',
    cwd: sourceRoot,
    effectivePath: env.PATH,
    passed: false,
    resolver: 'Exact cwd/PATH candidate ordering from immutable S0 TypeScriptCompiler.lean.',
  };
  try {
    let selected;
    // This intentionally mirrors the frozen resolver, including cwd-local
    // precedence. Any conflicting local installation is rejected before build.
    for (const directory of [sourceRoot, ...env.PATH.split(path.delimiter)]) {
      const base = path.resolve(sourceRoot, directory || '.');
      for (const candidate of [
        path.join(base, 'node_modules/typescript/bin/tsc'),
        path.join(base, '../typescript/bin/tsc'), path.join(base, 'tsc'),
      ]) {
        if (existsSync(candidate)) {
          const resolved = await realpath(candidate);
          if (resolved.replaceAll("\\", '/').endsWith('/typescript/bin/tsc')) {
            selected = resolved;
            break;
          }
        }
      }
      if (selected) break;
    }
    receipt.selectedLauncher = selected ?? null;
    assert.equal(selected, receipt.expectedLauncher, 'PSC0_SH1_HISTORICAL_CHILD_LAUNCHER');
    receipt.reportedVersion = runCommand(process.execPath, [selected, '--version'], {
      cwd: sourceRoot, env, encoding: 'utf8', stdio: 'pipe', timeout: 10000,
    }).stdout.trim();
    assert.equal(receipt.reportedVersion, receipt.expectedVersion,
      'PSC0_SH1_HISTORICAL_CHILD_TYPESCRIPT_PIN');
    receipt.passed = true;
    return env;
  } catch (error) {
    receipt.error = { name: error.name, message: error.message };
    throw error;
  } finally {
    await writeJson(path.join(outDir, 'historical-typescript-resolution.json'), receipt);
    process.stdout.write('PSC0_SH1_HISTORICAL_TYPESCRIPT_RESOLUTION: ' + JSON.stringify(receipt) + '\n');
  }
}

async function recoverSeed(sourceRoot, outDir) {
  const { closure, identity, identitySha256 } = await historicalIdentity(sourceRoot);
  const receiptPath = path.join(outDir, 'seed.json');
  let cached = false;
  if (existsSync(receiptPath)) {
    try {
      await verifyHistoricalSeedReceipt(outDir, { closure, identity, identitySha256 });
      cached = true;
    } catch {
      process.stdout.write('PSC0_SH1_SEED_CACHE: RECOMPUTE (identity or artifact mismatch)\n');
    }
  }
  if (!cached) {
    const env = await historicalChildEnvironment(sourceRoot, outDir);
    runCommand(historicalRecipe.build[0], historicalRecipe.build.slice(1), { cwd: sourceRoot, env });
    await mkdir(outDir, { recursive: true });
    const command = historicalRecipe.compile.map((item) => item.replace('<output>', outDir));
    runCommand(path.join(sourceRoot, command[0]), command.slice(1), { cwd: sourceRoot, env });
    const artifacts = {};
    for (const name of historicalRecipe.artifacts) {
      artifacts[name] = sha256(await readFile(path.join(outDir, name)));
    }
    await writeJson(receiptPath, {
      schemaVersion: 1,
      identitySha256,
      identity,
      artifacts,
      modules: closure.manifest,
      evidence: 'native-recovery-seed-from-preserved-55-module-source',
      historicalFixedPointReproduced: false,
      kernelChecked: false,
      recovery: 'Rebuild from immutable sourceRef with the recorded recipe and pinned toolchain.',
    });
  }
  const loaded = await loadCompiler(path.join(outDir, 'index.js'));
  const small = 'def seedSmoke : Nat := 7\n';
  unwrap(loaded.compiler.psCompilerPrepareSource(loaded.compiler.PsCompilerSourceKind.lean, small), 'SEED_SMOKE');
  process.stdout.write('PSC0_SH1_SEED: ' + JSON.stringify({
    cacheHit: cached, identitySha256, compilerSha256: loaded.compilerSha256, sourceRef: historicalRef,
  }) + '\n');
}

async function selectedAuthoringSeed(compilerOverride) {
  const selected = await readSelectedSeed();
  assert.equal(selected.mode, 'qualified', 'PSC0_SH1_MIGRATION_QUALIFIED_SEED_REQUIRED');
  assert.equal(selected.manifest.kind, 'psc0-qualified-successor-seed',
    'PSC0_SH1_MIGRATION_PROJECTION_SUCCESSOR_REQUIRED');
  // The dispatch reader requires both authentic cold-recovery and provider
  // evidence. Historical S0/A recipes are archived at their original revisions.
  await verifySeedExecutionRuntime(selected.manifest.toolchain, selected.recoveryTypeScriptVersion);
  const compilerPath = path.resolve(root, compilerOverride ?? selected.compilerPath);
  const expectedSha256 = selected.manifest.expectedArtifacts.javascriptSha256;
  assert.equal(sha256(await readFile(compilerPath)), expectedSha256,
    'PSC0_SH1_SELECTED_SEED_DIGEST');
  return {
    compilerPath, expectedSha256, mode: selected.mode,
    provenance: {
      kind: 'previous-qualified-authoring-seed',
      sourceRef: selected.sourceRef,
      sourceClosureSha256: selected.manifest.sourceClosureSha256,
      compilerSha256: expectedSha256,
      identitySha256: selected.identitySha256,
      independentAlgorithm: false,
      priorQualification: selected.manifest.qualification,
      producerToolchain: selected.manifest.toolchain,
      executionRuntime: executionRuntime(await toolchainIdentity()),
    },
  };
}

async function buildGeneration(compilerPath, closure, outDir, {
  workspace = root, expectedSha256, authoringSeed, legacyIrBoundary,
} = {}) {
  const start = performance.now();
  const loaded = await loadCompiler(compilerPath, { expectedSha256 });
  const { compiler, compilerSha256 } = loaded;
  const inputs = closure.ordered.map(({ path: sourcePath, source }) => ({
    path: sourcePath, source: stripImports(source),
  }));
  const kind = compiler.PsCompilerSourceKind.lean;
  let prepared;
  let preparation;
  let strict = null;
  if (typeof compiler.psCompilerSh1TypeScriptSources === 'function') {
    strict = compileStrictSources(compiler, strictSourceInputsFromClosure(closure), { compilerSha256 });
    prepared = strict.prepared;
    preparation = { mode: 'portable-atomic-source-and-target',
      fullSourcePreparations: 1, portableIrChecks: 1,
      sourcePolicy: strict.evidence.sourcePolicy, targetPolicy: strict.evidence.targetPolicy,
      cache: { status: 'not-used-by-this-atomic-generation' } };
  } else {
    assert.equal(legacyIrBoundary?.kind, 'selected-authoring-seed',
      'PSC0_SH1_STRICT_CURRENT_COMPILER_API_REQUIRED');
    assert.equal(legacyIrBoundary.executingCompilerSha256, compilerSha256);
    assert.equal(authoringSeed?.sourceRef, 'fe2560aba0f347b1caf8d000d371464642d44f23',
      'PSC0_SH1_STRICT_BOOTSTRAP_REQUIRES_SELECTED_R');
    const session = createGeneratedPreparationSession(compiler, { compilerSha256 });
    const result = session.prepare('lean', inputs);
    prepared = result.prepared;
    const warm = session.prepare('lean', inputs);
    assert.equal(warm.prepared, prepared, 'PSC0_SH1_WARM_PREPARED_IDENTITY');
    assert.equal(warm.receipt.cache.preparedModules, 0);
    assert.equal(warm.receipt.cache.finishHit, true);
    preparation = { ...result.receipt, warmNoChange: warm.receipt,
      strictSourceBoundary: 'unavailable-on-immutable-selected-R-authoring-compiler',
      strictSh1Qualified: false };
  }
  const prepareDone = performance.now();
  const admissions = strict ? strict.admissions : admissionText(compiler, prepared);
  const admissionDone = performance.now();
  const canonical = [];
  for (const item of closure.ordered) {
    canonical.push({
      path: item.path.replace(/\.lean$/u, '.ps'),
      source: unwrap(compiler.psCompilerTranslateSource(kind,
        compiler.PsCompilerSourceKind.proofScript, item.source), 'CANONICAL_SURFACE'),
    });
  }
  const canonicalText = JSON.stringify(canonical, null, 2) + '\n';
  const canonicalDone = performance.now();
  const ir = strict ? strict.originalIr : unwrap(compiler.psCompilerVerifiedIrFromPrepared(prepared), 'ERASE');
  // Reuse the exact source-owned objects. In the atomic path this is readback
  // after emission; the selected-R bootstrap path retains its prior ordering.
  const migrationWorkerAbi = runMigrationWorkerAbi(compiler, prepared, ir, valueTag);
  const irInventory = strict ? strict.irInventory : inventoryOriginalIr(compiler, ir, {
    compilerSha256, legacyBoundary: legacyIrBoundary,
  });
  const legacyBoundary = irInventory.portableChecker.status === 'unavailable-at-explicit-seed-boundary';
  if (!legacyBoundary && (!irInventory.runtimeIrTypingAccepted || !irInventory.traversalComplete)) {
    await writeJson(path.join(outDir, 'original-ir-inventory.json'), irInventory);
    process.stdout.write('PSC0_SH1_IR_REJECTED: ' + JSON.stringify(irInventory) + '\n');
    throw new Error('PSC0_SH1_ORIGINAL_IR_TYPES_REJECTED');
  }
  // Current compilers already emitted this same IR inside the atomic API.
  // The immutable R bootstrap route checks/emits its own exact IR here.
  const typeScript = strict ? strict.typeScript : unwrap(compiler.psTsEmitModule(ir), 'EMIT');
  const emitDone = performance.now();
  const outputJs = await compileTypeScript(typeScript, outDir, tsc, root, typescriptVersion);
  const javascript = await readFile(outputJs);
  await writeJson(path.join(outDir, 'original-ir-inventory.json'), irInventory);
  if (strict) await writeJson(path.join(outDir, 'strict-source.json'), strict.evidence);
  await writeFile(path.join(outDir, 'admissions.json'), admissions);
  await writeFile(path.join(outDir, 'canonical-source.json'), canonicalText);
  await writeJson(path.join(outDir, 'source-closure.json'), closure.manifest);
  const receipt = {
    schemaVersion: 1,
    executingCompilerSha256: compilerSha256,
    ...(authoringSeed ? { authoringSeed } : {}),
    sourceRef: capture('git', ['rev-parse', 'HEAD'], workspace),
    sourceClosureSha256: closure.sha256,
    moduleCount: closure.moduleCount,
    sourceBytes: closure.bytes,
    sourceKind: 'raw-authoritative-lean',
    language: {
      implementation: 'PSC1',
      candidateCapability: 'PSC0-SH/1 structural state generalization and parameter projections',
      canonicalSourceGrammar: typeof compiler.psLexProofScript === 'function'
        ? sh1GrammarProfile
        : { mode: 'immutable-authoring-seed-output',
          executingSourceRef: legacyIrBoundary?.executingSourceRef ?? authoringSeed?.sourceRef ?? null },
    },
    recipe: await recipeIdentity(),
    toolchain: await toolchainIdentity(),
    typescriptProfile,
    artifacts: {
      canonicalSurfaceSourceSha256: sha256(canonicalText),
      normalizedCanonicalAdmissionsSha256: sha256(admissions),
      typescriptSha256: sha256(typeScript),
      javascriptSha256: sha256(javascript),
    },
    preparation,
    strictSourceEnforcement: strict ? {
      status: 'accepted-complete-source-and-target', report: 'strict-source.json',
      compilerSha256, sameOriginalIrCheckedBeforeEmission: true,
      fullSourcePreparations: 1, portableIrChecks: 1, strictSh1Qualified: false,
    } : {
      status: 'unavailable-at-explicit-selected-R-boundary',
      executingSourceRef: authoringSeed.sourceRef, compilerSha256, strictSh1Qualified: false,
    },
    ...(migrationWorkerAbi ? { migrationWorkerAbi } : {}),
    originalIrInventory: {
      report: 'original-ir-inventory.json',
      traversalComplete: irInventory.traversalComplete,
      findingCounts: irInventory.findingCounts,
      findingCount: irInventory.findingCount ?? null,
      findingCountsCoverage: irInventory.findingCountsCoverage ?? 'legacy-inventory',
      portableChecker: irInventory.portableChecker,
      runtimeIrTypingAccepted: irInventory.runtimeIrTypingAccepted,
      sameOriginalIrCheckedBeforeEmission: !legacyBoundary,
      strictSh1Qualified: false,
    },
    timingMode: strict ? 'atomic preparation-through-emission is included in loadAndPrepare; later phases reuse its outputs' : 'selected-R staged preparation and emission',
    timingsMs: {
      loadAndPrepare: prepareDone - start,
      admissions: admissionDone - prepareDone,
      canonicalSurface: canonicalDone - admissionDone,
      emit: emitDone - canonicalDone,
      tscAndWrite: performance.now() - emitDone,
      total: performance.now() - start,
    },
    normalizationEvidence: 'Elaborated worker representation is compared in canonical admissions; source comparison uses canonical surface syntax.',
    evidence: 'candidate-build',
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  await writeJson(path.join(outDir, 'receipt.json'), receipt);
  process.stdout.write('PSC0_SH1_GENERATION: ' + JSON.stringify(receipt) + '\n');
  return { ...loaded, outputJs, receipt };
}

async function sessionConformance(seedPath, candidatePath, outDir, {
  oracle, candidateSha256,
}) {
  const seed = await loadCompiler(seedPath, { expectedSha256: oracle.compilerSha256 });
  const candidate = await loadCompiler(candidatePath, { expectedSha256: candidateSha256 });
  const session = createGeneratedPreparationSession(candidate.compiler, {
    compilerSha256: candidate.compilerSha256,
  });
  const first = { path: 'session/base.lean', source: 'def sh1Base : Nat := 11\n' };
  const last = { path: 'session/use.lean', source: 'def sh1Result : Nat := Nat.add sh1Base 7\n' };
  const sourceSets = [
    [first, last],
    [{ ...first, source: 'def sh1Base : Nat := 12\n' }, last],
    [{ ...first, source: 'def sh1Base : Nat := 12\n' },
      { ...last, source: 'def sh1Result : Nat := Nat.add sh1Base 8\n' }],
  ];
  const receipts = [];
  for (let index = 0; index < sourceSets.length; index++) {
    const sources = sourceSets[index];
    const oldPrepared = unwrap(seed.compiler.psCompilerPrepareSources(seed.compiler.PsCompilerSourceKind.lean,
      list(seed.compiler, sources.map((item) => item.source))), 'SESSION_REFERENCE_ORACLE');
    const result = session.prepare('lean', sources);
    assert.equal(admissionText(candidate.compiler, result.prepared), admissionText(seed.compiler, oldPrepared),
      'PSC0_SH1_SESSION_AGGREGATE_CORRESPONDENCE');
    assert.equal(result.receipt.cache.prefixModules, index === 2 ? 1 : 0);
    assert.equal(result.receipt.cache.preparedModules, index === 2 ? 1 : 2);
    receipts.push(result.receipt);
    assert.throws(() => { result.prepared.declarations.head.value = 'changed'; }, TypeError);
    const warm = session.prepare('lean', sources);
    assert.equal(warm.prepared, result.prepared);
    assert.equal(admissionText(candidate.compiler, warm.prepared), admissionText(seed.compiler, oldPrepared));
    assert.equal(warm.receipt.cache.preparedModules, 0);
    assert.equal(warm.receipt.cache.finishHit, true);
    receipts.push(warm.receipt);
  }
  const changed = sourceSets[2];
  assert.throws(() => session.prepare('lean', [changed[0], {
    ...last, source: 'def sh1Result : Nat := sh1Unknown\n',
  }]));
  const repaired = session.prepare('lean', changed);
  assert.equal(repaired.receipt.cache.prefixModules, 1);
  assert.equal(repaired.receipt.cache.preparedModules, 1);
  receipts.push(repaired.receipt);
  const proofScript = [
    { path: 'session/base.ps', source: 'def sh1Base : Nat := 12\n' },
    { path: 'session/use.ps', source: 'def sh1Result : Nat := Nat.add(sh1Base, 8)\n' },
  ];
  const switched = session.prepare('proofScript', proofScript);
  assert.equal(switched.receipt.cache.prefixModules, 0);
  assert.equal(switched.receipt.cache.preparedModules, 2);
  receipts.push(switched.receipt);
  const independent = await loadCompiler(candidatePath, { expectedSha256: candidateSha256 });
  const independentSession = createGeneratedPreparationSession(independent.compiler, {
    compilerSha256: independent.compilerSha256,
  });
  const fresh = independentSession.prepare('lean', sourceSets[0]);
  assert.equal(fresh.receipt.cache.prefixModules, 0);
  assert.equal(fresh.receipt.cache.preparedModules, 2);
  receipts.push(fresh.receipt);
  const oraclePrepared = unwrap(seed.compiler.psCompilerPrepareSources(seed.compiler.PsCompilerSourceKind.lean,
    list(seed.compiler, sourceSets[0].map((item) => item.source))), 'SESSION_FRESH_ORACLE');
  assert.equal(admissionText(independent.compiler, fresh.prepared), admissionText(seed.compiler, oraclePrepared));
  const byteBound = 48;
  const bounded = createGeneratedPreparationSession(candidate.compiler, {
    compilerSha256: candidate.compilerSha256, maxParsedSourceBytes: byteBound,
  });
  const boundedResult = bounded.prepare('lean', sourceSets[0]);
  assert(boundedResult.receipt.cache.retainedParsedSourceBytes <= byteBound);
  assert.equal(admissionText(candidate.compiler, boundedResult.prepared), admissionText(seed.compiler, oraclePrepared));
  receipts.push(boundedResult.receipt);
  const invalid = [sourceSets[0][0], {
    path: 'session/invalid.lean', source: 'def sh1Invalid : Nat := (\n',
  }];
  const errorSession = createGeneratedPreparationSession(candidate.compiler, {
    compilerSha256: candidate.compilerSha256,
  });
  let firstError;
  assert.throws(() => errorSession.prepare('lean', invalid), (error) => {
    firstError = error;
    assert.equal(error.stage, 'parse');
    const tag = Object.getOwnPropertySymbols(error.compilerError)
      .find((symbol) => typeof error.compilerError[symbol] === 'string');
    assert(tag, 'PSC0_SH1_PARSE_ERROR_TAG');
    assert.throws(() => { error.compilerError[tag] = 'changed'; }, TypeError);
    return true;
  });
  assert.throws(() => errorSession.prepare('lean', invalid), (error) => {
    assert.equal(error.message, firstError.message);
    assert.equal(error.preparationReceipt.cache.parseHits, 1);
    assert.equal(error.preparationReceipt.cache.parseMisses, 0);
    receipts.push(firstError.preparationReceipt, error.preparationReceipt);
    return true;
  });
  await writeJson(path.join(outDir, 'session-conformance.json'), {
    schemaVersion: 1,
    evidence: 'aggregate-admission-correspondence-and-incremental-state-transitions',
    oracle,
    seedCompilerSha256: seed.compilerSha256,
    candidateCompilerSha256: candidate.compilerSha256,
    receipts,
  });
  process.stdout.write('PSC0_SH1_SESSION_CONFORMANCE: PASS (recorded aggregate oracle; warm, prefix, body edit, failure recovery, frozen parse errors, source kind, fresh instance)\n');
}


async function verifySelectedSeedTypeScript(directory, manifest, outDir) {
  assert.equal(typescriptVersion, '5.8.3', 'PSC0_SH1_SEED_REPLAY_TYPESCRIPT_PIN');
  const outputDirectory = path.join(outDir, 'typescript5-replay');
  await mkdir(outputDirectory, { recursive: true });
  const receipt = {
    schemaVersion: 1,
    evidence: 'selected-seed-typescript-recovery-replay',
    sourceRef: manifest.sourceRef,
    toolchain: await toolchainIdentity(),
    typescriptProfile,
    expectedTypeScriptSha256: manifest.expectedArtifacts.typescriptSha256,
    expectedJavaScriptSha256: manifest.expectedArtifacts.javascriptSha256,
    passed: false,
    scope: 'Recompile authenticated A TypeScript with the original 5.8.3 arguments; source reconstruction is a separate recovery route.',
  };
  const start = performance.now();
  try {
    const source = await readFile(path.join(directory, 'index.ts'));
    receipt.typescriptSha256 = sha256(source);
    assert.equal(receipt.typescriptSha256, receipt.expectedTypeScriptSha256);
    const input = path.join(outputDirectory, 'index.ts');
    await writeFile(input, source);
    const compilerArgs = [
      tsc, input, '--target', 'ES2022', '--module', 'ES2022',
      '--moduleResolution', 'bundler', '--strict', '--declaration',
      '--sourceMap', '--noEmitOnError', '--skipLibCheck', '--pretty', 'false',
    ];
    const compileStarted = performance.now();
    const output = spawnSync(process.execPath, compilerArgs, {
      cwd: root, encoding: 'utf8', stdio: 'pipe', timeout: 120000,
      maxBuffer: 64 * 1024 * 1024,
    });
    receipt.compile = {
      command: process.execPath, args: compilerArgs, cwd: root,
      elapsedMs: performance.now() - compileStarted, timeoutMs: 120000,
      maxBufferBytes: 64 * 1024 * 1024,
      status: output.status, signal: output.signal,
      error: output.error ? { name: output.error.name, message: output.error.message, code: output.error.code } : null,
      diagnosticsComplete: !output.error && output.signal === null,
      stdout: 'compile.stdout.log', stderr: 'compile.stderr.log',
    };
    await writeFile(path.join(outputDirectory, 'compile.stdout.log'), output.stdout ?? '');
    await writeFile(path.join(outputDirectory, 'compile.stderr.log'), output.stderr ?? '');
    await writeJson(path.join(outputDirectory, 'compile.command.json'), receipt.compile);
    assert.equal(receipt.compile.error, null, 'PSC0_SH1_SEED_REPLAY_PROCESS');
    assert.equal(output.status, 0, 'PSC0_SH1_SEED_REPLAY_COMPILE: retained logs contain the diagnostics');
    receipt.javascriptSha256 = sha256(await readFile(path.join(outputDirectory, 'index.js')));
    assert.equal(receipt.javascriptSha256, receipt.expectedJavaScriptSha256,
      'PSC0_SH1_SEED_REPLAY_JAVASCRIPT_DIGEST');
    receipt.declarationSha256 = sha256(await readFile(path.join(outputDirectory, 'index.d.ts')));
    receipt.sourceMapSha256 = sha256(await readFile(path.join(outputDirectory, 'index.js.map')));
    receipt.passed = true;
  } catch (error) {
    receipt.error = { name: error.name, message: error.message };
    throw error;
  } finally {
    receipt.elapsedMs = performance.now() - start;
    await writeJson(path.join(outputDirectory, 'receipt.json'), receipt);
    process.stdout.write('PSC0_SH1_SEED_TYPESCRIPT_REPLAY: ' + JSON.stringify(receipt) + '\n');
  }
}

async function recoverQualifiedSeed({ sourceRoot, bootstrapCompiler, artifactDirectory, outDir, manifestPath }) {
  // An explicit parent descriptor must exist and remain a v1 TS5 recovery.
  if (manifestPath) validateQualifiedSeedManifest(JSON.parse(await readFile(manifestPath, 'utf8')));
  const selected = await readSelectedSeed(manifestPath);
  assert.equal(selected.mode, 'qualified', 'PSC0_SH1_QUALIFIED_PIN_REQUIRED');
  const manifest = validateQualifiedSeedManifest(selected.manifest);
  assert.deepEqual(await toolchainIdentity(), manifest.toolchain, 'PSC0_SH1_QUALIFIED_TOOLCHAIN');
  const cacheDirectory = path.join(root, selected.cacheDirectory);
  if (await verifyQualifiedSeedCache(cacheDirectory, manifest)) {
    await verifySelectedSeedTypeScript(cacheDirectory, manifest, outDir);
    process.stdout.write('PSC0_SH1_QUALIFIED_SEED: CACHE_HIT ' + selected.identitySha256 + '\n');
    return;
  }
  if (artifactDirectory && existsSync(path.join(artifactDirectory, 'qualification.json'))) {
    let artifactRestored = false;
    try {
      const qualification = JSON.parse(await readFile(path.join(artifactDirectory, 'qualification.json')));
      assert.equal(qualification.evidence, 'compiler-qualified-current-source-fixed-point');
      assert.equal(qualification.sourceRef, manifest.sourceRef);
      assert.equal(qualification.sourceClosureSha256, manifest.sourceClosureSha256);
      assert.deepEqual(qualification.artifacts, manifest.expectedArtifacts);
      assert.equal(qualification.c2CompilerSha256, manifest.expectedArtifacts.javascriptSha256);
      assert.equal(qualification.c3CompilerSha256, manifest.expectedArtifacts.javascriptSha256);
      for (const name of ['C2', 'C3']) {
        const receipt = JSON.parse(await readFile(path.join(artifactDirectory, name, 'receipt.json')));
        assert.equal(receipt.sourceRef, manifest.sourceRef);
        assert.equal(receipt.sourceClosureSha256, manifest.sourceClosureSha256);
        assert.deepEqual(receipt.toolchain, manifest.toolchain);
        assert.deepEqual(receipt.artifacts, manifest.expectedArtifacts);
      }
      await materializeQualifiedSeed({
        generationDirectory: path.join(artifactDirectory, 'C3'), cacheDirectory, manifest,
        origin: 'Hash-verified immutable qualification artifact, generation C3.',
      });
      artifactRestored = true;
    } catch (error) {
      process.stdout.write('PSC0_SH1_QUALIFIED_ARTIFACT: RECOMPUTE (' + String(error.message).slice(0, 512) + ')\n');
    }
    if (artifactRestored) {
      await verifySelectedSeedTypeScript(cacheDirectory, manifest, outDir);
      process.stdout.write('PSC0_SH1_QUALIFIED_SEED: ARTIFACT_HIT ' + selected.identitySha256 + '\n');
      return;
    }
  }
  assert.equal(capture('git', ['rev-parse', 'HEAD'], sourceRoot), manifest.sourceRef,
    'PSC0_SH1_QUALIFIED_SOURCE_REF');
  assert.equal(capture('git', ['status', '--porcelain', '--untracked-files=no', '--', '.'], sourceRoot), '',
    'PSC0_SH1_QUALIFIED_SOURCE_MODIFIED');
  const closure = await sourceClosure(sourceRoot);
  assert.equal(closure.sha256, manifest.sourceClosureSha256, 'PSC0_SH1_QUALIFIED_SOURCE_CLOSURE');
  assert.equal(sha256(await readFile(bootstrapCompiler)), manifest.bootstrap.compilerSha256,
    'PSC0_SH1_QUALIFIED_BOOTSTRAP_DIGEST');
  const first = await buildGeneration(bootstrapCompiler, closure, path.join(outDir, 'C1'), {
    workspace: sourceRoot, expectedSha256: manifest.bootstrap.compilerSha256,
    legacyIrBoundary: {
      kind: 'immutable-seed-recovery', executingSourceRef: historicalRef,
      executingCompilerSha256: manifest.bootstrap.compilerSha256,
      reason: 'Immutable S0 predates the portable checker; this reconstructs the pinned selected seed A.',
    },
  });
  const second = await buildGeneration(first.outputJs, closure, path.join(outDir, 'C2'), {
    workspace: sourceRoot, expectedSha256: first.receipt.artifacts.javascriptSha256,
    legacyIrBoundary: {
      kind: 'immutable-seed-recovery', executingSourceRef: manifest.sourceRef,
      executingCompilerSha256: first.receipt.artifacts.javascriptSha256,
      reason: 'Immutable C1(A) predates the portable checker; expected selected-seed products are verified afterward.',
    },
  });
  assert.deepEqual(second.receipt.artifacts, manifest.expectedArtifacts,
    'PSC0_SH1_QUALIFIED_RECOVERY_PRODUCTS');
  assert.equal((await sourceClosure(sourceRoot)).sha256, manifest.sourceClosureSha256,
    'PSC0_SH1_QUALIFIED_SOURCE_CHANGED_DURING_RECOVERY');
  await materializeQualifiedSeed({
    generationDirectory: path.join(outDir, 'C2'), cacheDirectory, manifest,
    origin: 'Rebuilt from pinned raw A through historical S0(A) then C1(A), with exact product comparison.',
  });
  process.stdout.write('PSC0_SH1_QUALIFIED_SEED: RECOVERED ' + selected.identitySha256 + '\n');
}

async function recoverSuccessorSeed({
  manifestPath, parentCompiler, cacheDirectory: cacheOverride, artifactDirectory, outDir, cold,
}) {
  assert.equal(typescriptVersion, '7.0.2', 'PSC0_SH1_SUCCESSOR_RECOVERY_TYPESCRIPT_PIN');
  assert(manifestPath, 'PSC0_SH1_SUCCESSOR_MANIFEST_REQUIRED');
  const manifest = validateSuccessorSeedManifest(JSON.parse(await readFile(manifestPath, 'utf8')));
  const selected = successorSeedSelection(manifest);
  const cacheDirectory = path.resolve(root, cacheOverride ?? selected.cacheDirectory);
  const parent = manifest.parent.manifest;
  const parentPath = path.resolve(root, parentCompiler ?? selected.parent.compilerPath);
  // The runner belongs to the same immutable revision as the source it rebuilds.
  // A later checkout may invoke this file, but may not substitute its own recipe.
  assert.equal(capture('git', ['rev-parse', 'HEAD']), manifest.recovery.runnerSourceRef,
    'PSC0_SH1_SUCCESSOR_RUNNER_REF');
  assert.equal(capture('git', ['status', '--porcelain', '--untracked-files=no', '--', '.']), '',
    'PSC0_SH1_SUCCESSOR_SOURCE_MODIFIED');
  assert.deepEqual(await recipeIdentity(), manifest.recovery.runnerRecipe,
    'PSC0_SH1_SUCCESSOR_RUNNER_RECIPE');
  assert.deepEqual(await toolchainIdentity(), manifest.toolchain, 'PSC0_SH1_SUCCESSOR_TOOLCHAIN');
  const closure = await sourceClosure(root);
  assert.equal(closure.sha256, manifest.sourceClosureSha256, 'PSC0_SH1_SUCCESSOR_SOURCE_CLOSURE');
  if (cold) {
    assert(!existsSync(outDir), 'PSC0_SH1_SUCCESSOR_COLD_OUTPUT_MUST_BE_NEW');
    assert(!existsSync(cacheDirectory), 'PSC0_SH1_SUCCESSOR_COLD_CACHE_MUST_BE_ABSENT');
  }
  const start = performance.now();
  const receipt = {
    schemaVersion: 1,
    evidence: cold ? 'qualified-successor-cold-recovery' : 'qualified-successor-recovery',
    sourceRef: manifest.sourceRef,
    sourceClosureSha256: manifest.sourceClosureSha256,
    parentIdentitySha256: manifest.parent.identitySha256,
    parentCompilerSha256: parent.expectedArtifacts.javascriptSha256,
    compilerSha256: manifest.expectedArtifacts.javascriptSha256,
    successorIdentitySha256: selected.identitySha256,
    runnerSourceRef: manifest.recovery.runnerSourceRef,
    runnerRecipeSha256: manifest.recovery.runnerRecipe.sha256,
    toolchain: await toolchainIdentity(),
    expectedFirstGenerationArtifacts: manifest.expectedFirstGenerationArtifacts,
    expectedArtifacts: manifest.expectedArtifacts,
    coldSuccessorRecovery: Boolean(cold),
    passed: false,
    selectedSeedChanged: false,
    strictSh1Qualified: false,
    fullPscvConformance: false,
  };
  try {
    if (!cold && await verifySuccessorSeedCache(cacheDirectory, manifest)) {
      receipt.method = 'verified-successor-cache';
      receipt.passed = true;
      return;
    }
    if (!cold && artifactDirectory &&
        existsSync(path.join(artifactDirectory, 'qualification.json'))) {
      let restored = false;
      try {
        const qualified = JSON.parse(await readFile(path.join(artifactDirectory, 'qualification.json'), 'utf8'));
        assert.equal(qualified.evidence, 'compiler-qualified-current-source-fixed-point');
        assert.equal(qualified.sourceRef, manifest.sourceRef);
        assert.equal(qualified.sourceClosureSha256, manifest.sourceClosureSha256);
        assert.deepEqual(qualified.artifacts, manifest.expectedArtifacts);
        assert.equal(qualified.c1CompilerSha256, manifest.expectedFirstGenerationArtifacts.javascriptSha256);
        assert.equal(qualified.c2CompilerSha256, manifest.expectedArtifacts.javascriptSha256);
        assert.equal(qualified.c3CompilerSha256, manifest.expectedArtifacts.javascriptSha256);
        await materializeSuccessorSeed({
          generationDirectory: path.join(artifactDirectory, 'C3'), cacheDirectory, manifest,
          origin: 'Hash-verified immutable successor qualification artifact, generation C3.',
        });
        restored = true;
      } catch (error) {
        process.stdout.write('PSC0_SH1_SUCCESSOR_ARTIFACT: RECOMPUTE (' +
          String(error.message).slice(0, 512) + ')\n');
      }
      if (restored) {
        receipt.method = 'verified-successor-qualification-artifact';
        receipt.passed = true;
        return;
      }
    }
    await verifySeedExecutionRuntime(parent.toolchain, '5.8.3');
    assert(await verifyQualifiedSeedCache(path.dirname(parentPath), parent),
      'PSC0_SH1_SUCCESSOR_PARENT_CACHE_INTEGRITY');
    assert.equal(sha256(await readFile(parentPath)), parent.expectedArtifacts.javascriptSha256,
      'PSC0_SH1_SUCCESSOR_PARENT_EXECUTABLE');
    const first = await buildGeneration(parentPath, closure, path.join(outDir, 'C1'), {
      expectedSha256: parent.expectedArtifacts.javascriptSha256,
      legacyIrBoundary: {
        kind: 'selected-authoring-seed', executingSourceRef: parent.sourceRef,
        executingCompilerSha256: parent.expectedArtifacts.javascriptSha256,
        reason: 'The exact embedded v1 parent produces the first successor generation from raw source.',
      },
    });
    assert.deepEqual(first.receipt.artifacts, manifest.expectedFirstGenerationArtifacts,
      'PSC0_SH1_SUCCESSOR_FIRST_PRODUCTS');
    const second = await buildGeneration(first.outputJs, closure, path.join(outDir, 'C2'), {
      expectedSha256: first.receipt.artifacts.javascriptSha256,
    });
    assert.deepEqual(second.receipt.artifacts, manifest.expectedArtifacts,
      'PSC0_SH1_SUCCESSOR_FINAL_PRODUCTS');
    assert.equal(second.receipt.originalIrInventory.traversalComplete, true);
    assert.equal(second.receipt.originalIrInventory.runtimeIrTypingAccepted, true);
    assert.equal(second.receipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission, true);
    assert.equal((await sourceClosure(root)).sha256, manifest.sourceClosureSha256,
      'PSC0_SH1_SUCCESSOR_SOURCE_CHANGED_DURING_RECOVERY');
    assert.deepEqual(await recipeIdentity(), manifest.recovery.runnerRecipe,
      'PSC0_SH1_SUCCESSOR_RECIPE_CHANGED_DURING_RECOVERY');
    await materializeSuccessorSeed({
      generationDirectory: path.join(outDir, 'C2'), cacheDirectory, manifest,
      origin: 'Rebuilt through the pinned v1 parent and first successor generation under TypeScript 7; all four products compared.',
    });
    receipt.method = 'pinned-parent-two-new-raw-source-generations';
    receipt.actualFirstGenerationArtifacts = first.receipt.artifacts;
    receipt.actualArtifacts = second.receipt.artifacts;
    receipt.originalIrCheckedBeforeEmission = true;
    receipt.parentCacheVerified = true;
    receipt.passed = true;
  } catch (error) {
    receipt.error = { name: error.name, message: error.message };
    throw error;
  } finally {
    receipt.elapsedMs = performance.now() - start;
    await writeJson(path.join(outDir, 'receipt.json'), receipt);
    const receiptSha256 = sha256(await readFile(path.join(outDir, 'receipt.json')));
    process.stdout.write('PSC0_SH1_SUCCESSOR_RECOVERY: ' +
      JSON.stringify({ ...receipt, receiptSha256 }) + '\n');
  }
}

async function retainPromotableSeed(qualification, firstReceipt, secondReceipt, thirdReceipt, outDir) {
  const selected = await readSelectedSeed();
  assert.equal(selected.mode, 'qualified', 'PSC0_SH1_CURRENT_QUALIFIED_SEED_REQUIRED');
  assert.equal(selected.manifest.kind, 'psc0-qualified-successor-seed',
    'PSC0_SH1_CURRENT_SUCCESSOR_REQUIRED');
  // Current migrations retain the already qualified successor. A new promotion
  // requires its own qualified recovery contract and explicit selection.
  await writeJson(path.join(outDir, 'seed-selection.json'), {
    status: 'existing-qualified-authoring-seed-retained',
    sourceRef: selected.sourceRef,
    compilerSha256: selected.manifest.expectedArtifacts.javascriptSha256,
    futurePromotion: 'A later language capability promotion needs an explicit TypeScript 7 recovery plan.',
  });
}

async function nativeCandidate(nativeCompiler, closure, outDir) {
  const start = performance.now();
  const directory = path.join(outDir, 'N1');
  await mkdir(directory, { recursive: true });
  const nativeCompilerSha256 = sha256(await readFile(nativeCompiler));
  const strictNativeCompiler = path.join(root, '.lake/build/bin/psc1_sh1_compile');
  const strictNativeCompilerSha256 = sha256(await readFile(strictNativeCompiler));
  const nativeSourceReceipt = path.join(directory, 'strict-source-native.json');
  const nativeCommand = ['--kind', 'lean', '--out', path.join(directory, 'index.ts'),
    '--admissions', path.join(directory, 'admissions.json'), '--report', nativeSourceReceipt,
    '--sources', ...closure.ordered.map((item) => item.path)];
  const nativeExecution = spawnSync(strictNativeCompiler, nativeCommand, {
    cwd: root, encoding: 'utf8', timeout: 300000, maxBuffer: 16 * 1024 * 1024,
  });
  await writeFile(path.join(directory, 'strict-native.stdout.log'), nativeExecution.stdout ?? '');
  await writeFile(path.join(directory, 'strict-native.stderr.log'), nativeExecution.stderr ?? '');
  process.stdout.write(nativeExecution.stdout ?? '');
  process.stderr.write(nativeExecution.stderr ?? '');
  if (nativeExecution.error) throw nativeExecution.error;
  assert.equal(nativeExecution.status, 0, 'PSC0_SH1_STRICT_NATIVE_EXECUTION');
  assert.equal(sha256(await readFile(strictNativeCompiler)), strictNativeCompilerSha256,
    'PSC0_SH1_STRICT_NATIVE_BINARY_CHANGED');
  assert.equal(sha256(await readFile(nativeCompiler)), nativeCompilerSha256,
    'PSC0_SH1_NATIVE_BINARY_CHANGED');
  const nativeTypeScript = await readFile(path.join(directory, 'index.ts'), 'utf8');
  const outputJs = await compileTypeScript(nativeTypeScript, directory, tsc, root, typescriptVersion);
  const compilerSha256 = sha256(await readFile(outputJs));
  const sourceRef = capture('git', ['rev-parse', 'HEAD']);
  const nativeIr = await runNativeIrCheckerConformance({
    nativeChecker: path.join(root, '.lake/build/bin/psc1_ir_check_tests'),
    closure, nativeTypeScript: path.join(directory, 'index.ts'), nativeSourceReceipt,
    root, outDir: path.join(directory, 'ir-checker-native'),
  });
  const loaded = await loadCompiler(outputJs, { expectedSha256: compilerSha256 });
  const strictRuntimeReference = await runNativeStrictRuntimeReference({
    root, outDir: path.join(directory, 'strict-runtime-reference'),
  });
  await runStrictSourceConformance({ ...loaded, outDir: path.join(directory, 'strict-source') });
  await runStrictTargetConformance({ ...loaded, outDir: path.join(directory, 'strict-target') });
  await runStrictRuntimeConformance({ ...loaded, root, outDir: path.join(directory, 'strict-runtime'),
    tsc, reference: strictRuntimeReference });
  const grammarClosure = runSh1GrammarClosureRoundTrip({ ...loaded, closure });
  await writeJson(path.join(directory, 'grammar-closure.json'), grammarClosure);
  process.stdout.write('PSC0_SH1_GRAMMAR_CLOSURE: ' + JSON.stringify({
    compilerSha256, closureSha256: closure.sha256, moduleCount: grammarClosure.moduleCount,
    proofScriptBytes: grammarClosure.proofScriptBytes, comparison: grammarClosure.comparison,
  }) + '\n');
  const irConformance = await runIrCheckerConformance({
    ...loaded, compilerPath: outputJs, root, outDir: path.join(directory, 'ir-checker'), tsc,
  });
  await runHelperRuntimeConformance({ ...loaded, outDir: directory });
  await runGenericErasureConformance({
    ...loaded, root, outDir: path.join(directory, 'generic-erasure'), tsc, nativeCompiler,
  });
  await sessionConformance(outputJs, outputJs, outDir, {
    oracle: {
      kind: 'current-native-generated-aggregate-implementation',
      sourceRef, sourceClosureSha256: closure.sha256, compilerSha256,
      independentAlgorithm: false, priorQualification: null,
    },
    candidateSha256: compilerSha256,
  });
  await runSh1Capabilities({
    ...loaded, root, outDir: path.join(directory, 'capabilities'), tsc, nativeCompiler,
  });
  await runIterationConformance({
    ...loaded, compilerPath: outputJs, root, outDir: path.join(outDir, 'iteration'),
  });
  await runFoundationConformance({
    ...loaded, root, outDir: path.join(outDir, 'foundation'), tsc,
    executingCompiler: 'Current native-generated compiler consumes both raw library sources.',
  });
  await runHelperConformance({
    ...loaded, root, outDir: path.join(outDir, 'helpers'), tsc,
    executingCompiler: 'Current native-generated compiler consumes both raw helper source slices.',
  });
  assert.equal((await sourceClosure(root)).sha256, closure.sha256,
    'PSC0_SH1_SOURCE_CHANGED_DURING_RUN');
  const receipt = {
    schemaVersion: 1,
    evidence: 'native-seeded-generated-compiler-candidate',
    sourceRef, sourceClosureSha256: closure.sha256,
    sourceKind: 'raw-authoritative-lean', moduleCount: closure.moduleCount,
    nativeCompiler: {
      binarySha256: strictNativeCompilerSha256,
      path: path.relative(root, strictNativeCompiler),
      command: nativeCommand,
      generalCompilerBinarySha256: nativeCompilerSha256,
      buildContext: 'CI builds psc1_sh1_compile and psc1; the atomic source executable builds N1, while the general CLI is a separate capability reference.',
    },
    artifacts: {
      javascriptSha256: compilerSha256,
      typescriptSha256: sha256(await readFile(path.join(directory, 'index.ts'))),
    },
    recipe: await recipeIdentity(), toolchain: await toolchainIdentity(), typescriptProfile,
    candidateClaim: 'Native PSC frontend consumes raw current compiler source; generated current compiler executes the raw language and iteration corpus.',
    selectedSeedBootstrapProven: false, currentSourceFixedPointProven: false,
    strictSourceEnforcement: { nativeReport: 'strict-source-native.json',
      sourceConformance: 'strict-source/receipt.json', targetConformance: 'strict-target/receipt.json',
      runtimeConformance: 'strict-runtime/receipt.json',
      nativeRuntimeReference: 'strict-runtime-reference/reference.json',
      fullSourcePreparations: 1, portableIrChecks: 1, strictSh1Qualified: false },
    sourceGrammar: sh1GrammarProfile,
    canonicalSourceCorrespondence: {
      report: 'grammar-closure.json',
      reportSha256: sha256(await readFile(path.join(directory, 'grammar-closure.json'))),
      moduleCount: grammarClosure.moduleCount,
    },
    runtimeIrTyping: {
      nativeCurrentSource: { report: 'ir-checker-native/receipt.json', ...nativeIr.fullCompilerIr },
      generatedConformance: { report: 'ir-checker/receipt.json', compilerSha256: irConformance.compilerSha256,
        negativeCases: irConformance.rejected.length, behavior: irConformance.behavior },
      generatedFullCompilerIrChecked: false, strictSh1Qualified: false,
    },
    provider: { status: 'not-attempted', kernelChecked: false },
    timingsMs: { total: performance.now() - start },
  };
  await writeJson(path.join(directory, 'receipt.json'), receipt);
  await writeJson(path.join(directory, 'source-closure.json'), closure.manifest);
  process.stdout.write('PSC0_SH1_NATIVE_CANDIDATE: ' + JSON.stringify(receipt) + '\n');
}

async function readStrictRuntimeReference(outDir) {
  const candidates = [
    path.join(outDir, 'development/N1/strict-runtime-reference/reference.json'),
    path.join(outDir, 'N1/strict-runtime-reference/reference.json'),
  ];
  const referencePath = candidates.find((file) => existsSync(file));
  assert(referencePath, 'PSC0_SH1_STRICT_NATIVE_REFERENCE_REQUIRED');
  return JSON.parse(await readFile(referencePath, 'utf8'));
}

async function runCurrentStrictConformance(loaded, outDir, referenceRoot) {
  const source = await runStrictSourceConformance({
    ...loaded, outDir: path.join(outDir, 'strict-source'),
  });
  const target = await runStrictTargetConformance({
    ...loaded, outDir: path.join(outDir, 'strict-target'),
  });
  const runtime = await runStrictRuntimeConformance({
    ...loaded, root, outDir: path.join(outDir, 'strict-runtime'), tsc,
    reference: await readStrictRuntimeReference(referenceRoot),
  });
  return { source, target, runtime };
}

function option(args, name, fallback) {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  assert(index + 1 < args.length && !args[index + 1].startsWith('--'), 'PSC0_SH1_ARGUMENT: ' + name);
  return args[index + 1];
}

const outDir = path.resolve(root, option(args, '--out', 'dist/sh1'));
if (command === 'native-candidate') {
  const nativeCompiler = path.resolve(root, option(args, '--native', '.lake/build/bin/psc1'));
  await nativeCandidate(nativeCompiler, await sourceClosure(root), outDir);
} else if (command === 'candidate') {
  const authoring = await selectedAuthoringSeed(option(args, '--seed', undefined));
  const closure = await sourceClosure(root);
  const libraryCompiler = await loadCompiler(authoring.compilerPath, {
    expectedSha256: authoring.expectedSha256,
  });
  const referenceWorkerReport = runMigrationWorkerConformance(libraryCompiler.compiler, valueTag);
  const referenceWorkerReceipt = {
    schemaVersion: 1,
    evidence: 'selected-successor-migration-worker-reference',
    sourceRef: authoring.provenance.sourceRef,
    compilerSha256: libraryCompiler.compilerSha256,
    seedIdentitySha256: authoring.provenance.identitySha256,
    report: referenceWorkerReport,
  };
  await writeJson(path.join(outDir, 'worker-migration-reference.json'), referenceWorkerReceipt);
  await runFoundationConformance({
    ...libraryCompiler,
    executingCompiler: 'Same verified selected authoring seed consumes both raw library sources.',
    root, outDir: path.join(outDir, 'foundation'), tsc,
  });
  await runHelperConformance({
    ...libraryCompiler,
    executingCompiler: 'Same verified selected authoring seed consumes both raw helper source slices.',
    root, outDir: path.join(outDir, 'helpers'), tsc,
  });
  const generation = await buildGeneration(authoring.compilerPath, closure, path.join(outDir, 'C1'), {
    expectedSha256: authoring.expectedSha256, authoringSeed: authoring.provenance,
    legacyIrBoundary: {
      kind: 'selected-authoring-seed', executingSourceRef: authoring.provenance.sourceRef,
      executingCompilerSha256: authoring.expectedSha256,
      reason: 'The explicitly pinned R predates strict source/target admission and may produce C1; current N1/C1/C2/C3 strict consumers remain mandatory.',
    },
  });
  await sessionConformance(authoring.compilerPath, generation.outputJs, outDir, {
    oracle: authoring.provenance, candidateSha256: generation.receipt.artifacts.javascriptSha256,
  });
  const loaded = await loadCompiler(generation.outputJs, {
    expectedSha256: generation.receipt.artifacts.javascriptSha256,
  });
  await runCurrentStrictConformance(loaded, path.join(outDir, 'C1'), outDir);
  await runIrCheckerConformance({
    ...loaded, compilerPath: generation.outputJs, root, outDir: path.join(outDir, 'C1/ir-checker'), tsc,
  });
  await runHelperRuntimeConformance({ ...loaded, outDir: path.join(outDir, 'C1') });
  await runGenericErasureConformance({
    ...loaded, root, outDir: path.join(outDir, 'C1/generic-erasure'), tsc,
    nativeCompiler: option(args, '--native', undefined),
  });
  const nativeArg = option(args, '--native', undefined);
  const candidateCapabilities = await runSh1Capabilities({
    ...loaded, root, outDir: path.join(outDir, 'C1/capabilities'), tsc,
    nativeCompiler: nativeArg ? path.resolve(root, nativeArg) : undefined,
  });
  assert.deepEqual(candidateCapabilities.workerMigration, referenceWorkerReport,
    'PSC0_SH1_MIGRATION_WORKER_REFERENCE_CORRESPONDENCE');
  const migrationCorrespondence = {
    schemaVersion: 1,
    evidence: 'finite-migration-worker-R-F-correspondence',
    beforeSourceRef: authoring.provenance.sourceRef,
    beforeCompilerSha256: libraryCompiler.compilerSha256,
    afterSourceRef: generation.receipt.sourceRef,
    afterCompilerSha256: loaded.compilerSha256,
    casesPerCompiler: referenceWorkerReport.cases,
    observationSha256: referenceWorkerReport.observationSha256,
    referenceReport: 'worker-migration-reference.json',
    referenceReportSha256: sha256(await readFile(path.join(outDir, 'worker-migration-reference.json'))),
    candidateReport: 'C1/capabilities/receipt.json',
    candidateReportSha256: sha256(await readFile(path.join(outDir, 'C1/capabilities/receipt.json'))),
    passed: true,
  };
  await writeJson(path.join(outDir, 'worker-migration-correspondence.json'), migrationCorrespondence);
  process.stdout.write('PSC0_SH1_MIGRATION_CORRESPONDENCE: ' + JSON.stringify(migrationCorrespondence) + '\n');
  await runIterationConformance({
    ...loaded, compilerPath: generation.outputJs, root, outDir: path.join(outDir, 'iteration'),
  });
  assert.equal((await sourceClosure(root)).sha256, closure.sha256, 'PSC0_SH1_SOURCE_CHANGED_DURING_RUN');
  process.stdout.write('PSC0_SH1_CANDIDATE: PASS (verified selected seed, current raw source and generated capability execution)\n');
} else if (command === 'fixed-point') {
  const authoring = await selectedAuthoringSeed();
  const closure = await sourceClosure(root);
  const firstDir = path.join(outDir, 'C1');
  const firstReceipt = JSON.parse(await readFile(path.join(firstDir, 'receipt.json')));
  assert.equal(firstReceipt.evidence, 'candidate-build', 'PSC0_SH1_CANDIDATE_KIND');
  assert.equal(firstReceipt.sourceRef, capture('git', ['rev-parse', 'HEAD']));
  assert.equal(firstReceipt.executingCompilerSha256, authoring.expectedSha256);
  assert.deepEqual(firstReceipt.authoringSeed, authoring.provenance, 'PSC0_SH1_CANDIDATE_SEED_PROVENANCE');
  assert.equal(firstReceipt.sourceClosureSha256, closure.sha256, 'PSC0_SH1_STALE_CANDIDATE_SOURCE');
  assert.equal(firstReceipt.artifacts.javascriptSha256, sha256(await readFile(path.join(firstDir, 'index.js'))),
    'PSC0_SH1_CANDIDATE_DIGEST');
  assert.deepEqual(firstReceipt.recipe, await recipeIdentity(), 'PSC0_SH1_CANDIDATE_RECIPE');
  assert.deepEqual(firstReceipt.toolchain, await toolchainIdentity(), 'PSC0_SH1_CANDIDATE_TOOLCHAIN');
  const irCheckerReceipt = JSON.parse(await readFile(path.join(firstDir, 'ir-checker/receipt.json')));
  assert.equal(irCheckerReceipt.evidence, 'portable-original-ir-checker-conformance');
  assert.equal(irCheckerReceipt.compilerSha256, firstReceipt.artifacts.javascriptSha256);
  assert.equal(irCheckerReceipt.acceptedFixture.runtimeIrTypingAccepted, true);
  const capabilityReceipt = JSON.parse(await readFile(path.join(firstDir, 'capabilities/receipt.json')));
  assert.equal(capabilityReceipt.compilerSha256, firstReceipt.artifacts.javascriptSha256);
  assert.deepEqual(capabilityReceipt.sourceKinds.map((item) => item.sourceKind).sort(), ['lean', 'ps']);
  assert.equal(capabilityReceipt.grammar.evidence, 'generated-compiler-source-grammar-api');
  assert.equal(capabilityReceipt.grammar.compilerSha256, firstReceipt.artifacts.javascriptSha256);
  assert.deepEqual(capabilityReceipt.grammar.sourceGrammar, sh1GrammarProfile);
  assert.equal(firstReceipt.migrationWorkerAbi.workerCount, 12, 'PSC0_SH1_C1_WORKER_ABI');
  const migrationReferencePath = path.join(outDir, 'worker-migration-reference.json');
  const migrationReference = JSON.parse(await readFile(migrationReferencePath, 'utf8'));
  const migrationCorrespondencePath = path.join(outDir, 'worker-migration-correspondence.json');
  const migrationCorrespondence = JSON.parse(await readFile(migrationCorrespondencePath, 'utf8'));
  assert.equal(migrationReference.evidence, 'selected-successor-migration-worker-reference');
  assert.equal(migrationReference.sourceRef, authoring.provenance.sourceRef);
  assert.equal(migrationReference.compilerSha256, authoring.expectedSha256);
  assert.equal(migrationReference.seedIdentitySha256, authoring.provenance.identitySha256);
  assert.equal(migrationCorrespondence.evidence, 'finite-migration-worker-R-F-correspondence');
  assert.equal(migrationCorrespondence.passed, true);
  assert.equal(migrationCorrespondence.beforeCompilerSha256, authoring.expectedSha256);
  assert.equal(migrationCorrespondence.afterCompilerSha256, firstReceipt.artifacts.javascriptSha256);
  assert.equal(migrationCorrespondence.afterSourceRef, firstReceipt.sourceRef);
  assert.equal(migrationCorrespondence.referenceReportSha256, sha256(await readFile(migrationReferencePath)));
  assert.equal(migrationCorrespondence.candidateReportSha256,
    sha256(await readFile(path.join(firstDir, 'capabilities/receipt.json'))));
  assert.equal(migrationReference.report.cases, 87);
  assert.deepEqual(capabilityReceipt.workerMigration, migrationReference.report);
  const nativeGrammarFile = path.join(outDir, 'development/N1/grammar-closure.json');
  const nativeGrammar = JSON.parse(await readFile(nativeGrammarFile, 'utf8'));
  const nativeReceipt = JSON.parse(await readFile(path.join(outDir, 'development/N1/receipt.json'), 'utf8'));
  assert.equal(nativeReceipt.sourceRef, capture('git', ['rev-parse', 'HEAD']));
  assert.equal(nativeGrammar.compilerSha256, nativeReceipt.artifacts.javascriptSha256);
  assert.equal(nativeGrammar.closureSha256, closure.sha256);
  assert.equal(nativeGrammar.moduleCount, closure.moduleCount);
  assert.deepEqual(nativeGrammar.sourceGrammar, sh1GrammarProfile);
  assert.equal(nativeReceipt.canonicalSourceCorrespondence.reportSha256, sha256(await readFile(nativeGrammarFile)));
  for (const capability of capabilityReceipt.sourceKinds) {
    assert(['lean', 'ps'].includes(capability.sourceKind));
    assert.equal(capability.sourceSha256, sha256(await readFile(path.join(root,
      'test/fixtures/selfhost-sh1-accumulators.' + capability.sourceKind))));
    assert.equal(capability.behavior, 'pass');
  }
  const second = await buildGeneration(path.join(firstDir, 'index.js'), closure, path.join(outDir, 'C2'), {
    expectedSha256: firstReceipt.artifacts.javascriptSha256,
  });
  const secondCompiler = await loadCompiler(second.outputJs, {
    expectedSha256: second.receipt.artifacts.javascriptSha256,
  });
  await runCurrentStrictConformance(secondCompiler, path.join(outDir, 'C2'), outDir);
  assert.equal(second.receipt.artifacts.canonicalSurfaceSourceSha256,
    nativeGrammar.canonicalSurfaceSourceSha256, 'PSC0_SH1_C2_SURFACE_MATCHES_ROUND_TRIPPED_SOURCE');
  assert.equal(second.receipt.originalIrInventory.runtimeIrTypingAccepted, true,
    'PSC0_SH1_C2_PORTABLE_IR_CHECK_REQUIRED');
  assert.equal(second.receipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission, true);
  await runIrCheckerConformance({
    ...secondCompiler, compilerPath: second.outputJs, root, outDir: path.join(outDir, 'C2/ir-checker'), tsc,
  });
  assert.deepEqual(second.receipt.migrationWorkerAbi, firstReceipt.migrationWorkerAbi,
    'PSC0_SH1_C2_WORKER_PUBLIC_TYPES_AND_IR_SIGNATURES');
  const secondCapabilities = await runSh1Capabilities({
    ...secondCompiler, root, outDir: path.join(outDir, 'C2/capabilities'), tsc,
  });
  assert.deepEqual(secondCapabilities.workerMigration, migrationReference.report,
    'PSC0_SH1_C2_WORKER_REFERENCE_CORRESPONDENCE');
  await runHelperRuntimeConformance({ ...secondCompiler, outDir: path.join(outDir, 'C2') });
  await runGenericErasureConformance({
    ...secondCompiler, root, outDir: path.join(outDir, 'C2/generic-erasure'), tsc,
  });
  const third = await buildGeneration(second.outputJs, closure, path.join(outDir, 'C3'), {
    expectedSha256: second.receipt.artifacts.javascriptSha256,
  });
  assert.deepEqual(second.receipt.artifacts, third.receipt.artifacts,
    'PSC0_SH1_C2_C3_ARTIFACT_MISMATCH');
  assert.equal(third.receipt.artifacts.canonicalSurfaceSourceSha256,
    nativeGrammar.canonicalSurfaceSourceSha256, 'PSC0_SH1_C3_SURFACE_MATCHES_ROUND_TRIPPED_SOURCE');
  const thirdCompiler = await loadCompiler(third.outputJs, {
    expectedSha256: third.receipt.artifacts.javascriptSha256,
  });
  await runCurrentStrictConformance(thirdCompiler, path.join(outDir, 'C3'), outDir);
  assert.equal(third.receipt.originalIrInventory.runtimeIrTypingAccepted, true,
    'PSC0_SH1_C3_PORTABLE_IR_CHECK_REQUIRED');
  assert.equal(third.receipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission, true);
  await runIrCheckerConformance({
    ...thirdCompiler, compilerPath: third.outputJs, root, outDir: path.join(outDir, 'C3/ir-checker'), tsc,
  });
  assert.deepEqual(third.receipt.migrationWorkerAbi, firstReceipt.migrationWorkerAbi,
    'PSC0_SH1_C3_WORKER_PUBLIC_TYPES_AND_IR_SIGNATURES');
  const thirdCapabilities = await runSh1Capabilities({
    ...thirdCompiler, root, outDir: path.join(outDir, 'C3/capabilities'), tsc,
  });
  assert.deepEqual(thirdCapabilities.workerMigration, migrationReference.report,
    'PSC0_SH1_C3_WORKER_REFERENCE_CORRESPONDENCE');
  await runHelperRuntimeConformance({ ...thirdCompiler, outDir: path.join(outDir, 'C3') });
  await runGenericErasureConformance({
    ...thirdCompiler, root, outDir: path.join(outDir, 'C3/generic-erasure'), tsc,
  });
  assert.equal((await sourceClosure(root)).sha256, closure.sha256, 'PSC0_SH1_SOURCE_CHANGED_DURING_RUN');
  const strictEvidence = await bindStrictQualificationEvidence({
    outDir, closure, nativeReceipt, firstReceipt, secondReceipt: second.receipt, thirdReceipt: third.receipt,
  });
  await writeJson(path.join(outDir, 'strict-enforcement-evidence.json'), strictEvidence);
  const receipt = {
    schemaVersion: 1,
    sourceRef: capture('git', ['rev-parse', 'HEAD']),
    sourceClosureSha256: closure.sha256,
    moduleCount: closure.moduleCount,
    evidence: 'compiler-qualified-current-source-fixed-point',
    equation: authoring.mode === 'historical'
      ? 'C1=S0(A); C2=C1(A); C3=C2(A); compare C2 and C3 products'
      : 'Q is the pinned qualified compiler from A; C1=Q(B); C2=C1(B); C3=C2(B); compare C2 and C3 products',
    authoringSeed: authoring.provenance,
    toolchain: await toolchainIdentity(),
    typescriptProfile,
    rawAuthoringSourceConsumedEveryGeneration: true,
    artifacts: second.receipt.artifacts,
    c1CompilerSha256: firstReceipt.artifacts.javascriptSha256,
    c2CompilerSha256: second.receipt.artifacts.javascriptSha256,
    c3CompilerSha256: third.receipt.artifacts.javascriptSha256,
    rawCapabilityKinds: ['lean', 'proofScript'],
    helperSourceCorrespondence: 'helpers/receipt.json',
    helperRuntimeGenerations: ['C1', 'C2', 'C3'],
    recursiveGenericErasureGenerations: ['C1', 'C2', 'C3'],
    sourceGrammar: sh1GrammarProfile,
    grammarGenerations: ['C1', 'C2', 'C3'],
    projectionResolutionGenerations: ['C1', 'C2', 'C3'],
    canonicalSourceContract: 'C2/C3 emit and consume the bounded new-only ps-0.9-r3 grammar. The pinned parent may emit its historical canonical form as the C1 build artifact; it is not a current parser mode.',
    nativeCanonicalSourceCorrespondence: {
      report: 'development/N1/grammar-closure.json',
      reportSha256: sha256(await readFile(nativeGrammarFile)),
      compilerSha256: nativeGrammar.compilerSha256,
      moduleCount: nativeGrammar.moduleCount,
    },
    workerMigration: {
      workers: 12, families: { F1: 4, F2: 8 }, removedTypedIdentityAliases: 3,
      runtimeGenerations: ['C1', 'C2', 'C3'], casesPerCompiler: migrationReference.report.cases,
      observationSha256: migrationReference.report.observationSha256,
      completePublicTypeAndOriginalIrBuilds: ['C1', 'C2', 'C3'],
      abiObservationSha256: firstReceipt.migrationWorkerAbi.observationSha256,
      referenceSourceRef: authoring.provenance.sourceRef,
      referenceCompilerSha256: authoring.expectedSha256,
      correspondence: 'worker-migration-correspondence.json',
      correspondenceSha256: sha256(await readFile(migrationCorrespondencePath)),
      fullBaselineClosurePreparedAgain: false,
    },
    strictSourceAndRuntimeConformanceGenerations: ['N1', 'C1', 'C2', 'C3'],
    atomicRawSourceBuilds: ['native N1', 'C1 produces C2', 'C2 produces C3'],
    strictEnforcementEvidence: { report: 'strict-enforcement-evidence.json',
      sha256: sha256(await readFile(path.join(outDir, 'strict-enforcement-evidence.json'))),
      ...strictEvidence },
    strictSourceEnforced: true,
    strictTargetAdmissionEnforced: true,
    strictSh1Qualified: false,
    semanticContractQualified: false,
    enabledRuntimeConformance: { operations: 45, reference: 'development/N1/strict-runtime-reference/reference.json',
      reports: ['development/N1/strict-runtime/receipt.json', 'C1/strict-runtime/receipt.json',
        'C2/strict-runtime/receipt.json', 'C3/strict-runtime/receipt.json'],
      scope: 'Finite pinned-native/generated observations; general semantic preservation is not inferred.' },
    portableIrCheckerGenerations: ['C1', 'C2', 'C3'],
    originalIrCheckedBuilds: ['C2', 'C3'],
    originalIrChecking: 'C1 checks the exact current-source IR emitted as C2; C2 checks the exact IR emitted as C3.',
    immutableSeedBoundary: firstReceipt.originalIrInventory.portableChecker,
    runtimeIrTypingEnforced: true,
    runtimeIrStrictQualification: 'not-claimed',
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  await writeJson(path.join(outDir, 'qualification.json'), receipt);
  await retainPromotableSeed(receipt, firstReceipt, second.receipt, third.receipt, outDir);
  process.stdout.write('PSC0_SH1_FIXED_POINT: ' + JSON.stringify(receipt) + '\n');
} else {
  throw new Error('usage: node scripts/sh1-qualify.mjs native-candidate|candidate|fixed-point [--out directory] [--seed compiler.js] [--native native-psc1]');
}
