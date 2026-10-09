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
  readSelectedSeed, qualifiedSeedIdentity, validateQualifiedSeedManifest,
  makeQualifiedSeedManifest, verifyQualifiedSeedCache, materializeQualifiedSeed,
} from './sh1-seed-manifest.mjs';
import { resolveTypeScriptCli, expectedTypeScriptVersion, typeScriptProfileArgs } from './typescript-cli.mjs';
import { createGeneratedPreparationSession } from './generated-preparation-session.mjs';
import { inventoryOriginalIr } from './original-ir-inventory.mjs';
import { runIrCheckerConformance, runNativeIrCheckerConformance } from './sh1-ir-checker-conformance.mjs';
import { runFoundationConformance } from './sh1-foundation-conformance.mjs';
import { runHelperConformance, runHelperRuntimeConformance } from './sh1-helper-conformance.mjs';
import { runGenericErasureConformance } from './sh1-generic-erasure-conformance.mjs';
import { runIterationConformance } from './sh1-iteration-conformance.mjs';
import {
  compileTypeScript, runCommand, runSh1Capabilities, sha256, unwrap,
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
const historicalCommands = new Set(['seed-identity', 'recover-seed', 'recover-qualified-seed']);
const typescriptVersion = expectedTypeScriptVersion();
assert.equal(typescriptVersion, historicalCommands.has(command) ? '5.8.3' : '7.0.2',
  'PSC0_SH1_TYPESCRIPT_PROFILE: recovery requires 5.8.3; current qualification requires 7.0.2');
const tsc = resolveTypeScriptCli();
const typescriptProfile = Object.freeze({
  version: typescriptVersion,
  purpose: historicalCommands.has(command) ? 'historical-seed-recovery' : 'current-emission',
  arguments: typeScriptProfileArgs([], typescriptVersion),
});

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
    'scripts/typescript-cli.mjs', 'scripts/check-typescript-profile.mjs', 'scripts/workspace-layout.mjs',
    'scripts/generated-preparation-session.mjs', 'scripts/original-ir-inventory.mjs',
    'scripts/original-ir-carrier.mjs', 'scripts/sh1-ir-checker-conformance.mjs',
    'test/IrCheckerTests.lean',
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

async function verifySeedExecutionRuntime(producerToolchain) {
  assert.equal(producerToolchain?.typescript, 'Version 5.8.3',
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
  const compilerPath = path.resolve(root, compilerOverride ?? selected.compilerPath);
  let expectedSha256;
  let identitySha256;
  let sourceClosureSha256;
  let producerToolchain;
  if (selected.mode === 'qualified') {
    await verifySeedExecutionRuntime(selected.manifest.toolchain);
    expectedSha256 = selected.manifest.expectedArtifacts.javascriptSha256;
    identitySha256 = selected.identitySha256;
    sourceClosureSha256 = selected.manifest.sourceClosureSha256;
    producerToolchain = selected.manifest.toolchain;
  } else {
    // An explicit --seed override must still be the verified historical seed.
    // Its claimed ancestry cannot be inferred from the supplied filename.
    const directory = path.dirname(path.resolve(root, selected.compilerPath));
    const recordedReceipt = JSON.parse(await readFile(path.join(directory, 'seed.json'), 'utf8'));
    producerToolchain = recordedReceipt.identity?.toolchain;
    assert(producerToolchain, 'PSC0_SH1_HISTORICAL_PRODUCER_TOOLCHAIN_REQUIRED');
    const historical = await historicalIdentity(path.resolve(root, '../historical-source/psc0'), producerToolchain);
    const receipt = await verifyHistoricalSeedReceipt(directory, historical);
    expectedSha256 = receipt.artifacts['index.js'];
    identitySha256 = historical.identitySha256;
    sourceClosureSha256 = historical.closure.sha256;
  }
  assert.equal(sha256(await readFile(compilerPath)), expectedSha256,
    'PSC0_SH1_SELECTED_SEED_DIGEST');
  return {
    compilerPath, expectedSha256, mode: selected.mode,
    provenance: {
      kind: selected.mode === 'qualified' ? 'previous-qualified-authoring-seed' : 'historical-aggregate-implementation',
      sourceRef: selected.sourceRef,
      sourceClosureSha256,
      compilerSha256: expectedSha256,
      identitySha256,
      independentAlgorithm: selected.mode === 'historical',
      priorQualification: selected.manifest?.qualification ?? null,
      producerToolchain,
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
  if ('psCompilerPreparationStart' in compiler) {
    const session = createGeneratedPreparationSession(compiler, { compilerSha256 });
    const result = session.prepare('lean', inputs);
    prepared = result.prepared;
    preparation = result.receipt;
    const warm = session.prepare('lean', inputs);
    assert.equal(warm.prepared, prepared, 'PSC0_SH1_WARM_PREPARED_IDENTITY');
    assert.equal(warm.receipt.cache.preparedModules, 0);
    assert.equal(warm.receipt.cache.finishHit, true);
    preparation = { ...result.receipt, warmNoChange: warm.receipt };
  } else {
    prepared = unwrap(compiler.psCompilerPrepareSources(kind,
      list(compiler, inputs.map((item) => item.source))), 'PREPARE');
    preparation = { mode: 'historical-aggregate-api' };
  }
  const prepareDone = performance.now();
  const admissions = admissionText(compiler, prepared);
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
  const ir = unwrap(compiler.psCompilerVerifiedIrFromPrepared(prepared), 'ERASE');
  const irInventory = inventoryOriginalIr(compiler, ir, {
    compilerSha256, legacyBoundary: legacyIrBoundary,
  });
  const legacyBoundary = irInventory.portableChecker.status === 'unavailable-at-explicit-seed-boundary';
  if (!legacyBoundary && (!irInventory.runtimeIrTypingAccepted || !irInventory.traversalComplete)) {
    await writeJson(path.join(outDir, 'original-ir-inventory.json'), irInventory);
    process.stdout.write('PSC0_SH1_IR_REJECTED: ' + JSON.stringify(irInventory) + '\n');
    throw new Error('PSC0_SH1_ORIGINAL_IR_TYPES_REJECTED');
  }
  // No mutation or asynchronous operation separates a successful portable check
  // from emission of this exact original IR object.
  const typeScript = unwrap(compiler.psTsEmitModule(ir), 'EMIT');
  const emitDone = performance.now();
  const outputJs = await compileTypeScript(typeScript, outDir, tsc, root, typescriptVersion);
  const javascript = await readFile(outputJs);
  await writeJson(path.join(outDir, 'original-ir-inventory.json'), irInventory);
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
    language: { implementation: 'PSC1', candidateCapability: 'PSC0-SH/1 structural state generalization' },
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
    { path: 'session/base.ps', source: 'def sh1Base : Nat := 12;\n' },
    { path: 'session/use.ps', source: 'def sh1Result : Nat := Nat.add(sh1Base, 8);\n' },
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

async function recoverQualifiedSeed({ sourceRoot, bootstrapCompiler, artifactDirectory, outDir }) {
  const selected = await readSelectedSeed();
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

async function retainPromotableSeed(qualification, firstReceipt, secondReceipt, outDir) {
  const selected = await readSelectedSeed();
  if (selected.mode === 'qualified') {
    // The initial authoring seed A remains sufficient while B uses its language.
    // Do not silently claim S0 can rebuild migrated B or discard A's recovery path.
    await writeJson(path.join(outDir, 'seed-selection.json'), {
      status: 'existing-qualified-authoring-seed-retained',
      sourceRef: selected.sourceRef,
      compilerSha256: selected.manifest.expectedArtifacts.javascriptSha256,
      futurePromotion: 'A later language capability promotion needs an explicit parent-seed recovery plan.',
    });
    return;
  }
  if (typescriptVersion !== '5.8.3') {
    await writeJson(path.join(outDir, 'seed-selection.json'), {
      status: 'historical-authoring-seed-retained',
      sourceRef: selected.sourceRef,
      reason: 'A TypeScript 7 product needs an explicit new seed manifest and parent-seed recovery recipe.',
    });
    return;
  }
  const manifest = makeQualifiedSeedManifest({
    qualification, firstReceipt, secondReceipt, runId: process.env.GITHUB_RUN_ID,
  });
  const identity = qualifiedSeedIdentity(manifest);
  const relativeDirectory = '.selfhost-seeds/qualified/' + identity;
  await materializeQualifiedSeed({
    generationDirectory: path.join(outDir, 'C2'),
    cacheDirectory: path.join(root, relativeDirectory),
    manifest,
    origin: 'Fresh C2/C3 current-source qualification; root seed selection remains unchanged.',
  });
  await writeJson(path.join(outDir, 'seed-promotion.json'), manifest);
  if (process.env.GITHUB_OUTPUT) {
    await appendFile(process.env.GITHUB_OUTPUT,
      'promoted-seed-cache-key=psc0-sh1-qualified-v1-' + identity + '\n' +
      'promoted-seed-cache-directory=psc0/' + relativeDirectory + '\n');
  }
  process.stdout.write('PSC0_SH1_SEED_PROMOTION: ' + JSON.stringify(manifest) + '\n');
}

async function nativeCandidate(nativeCompiler, closure, outDir) {
  const start = performance.now();
  const directory = path.join(outDir, 'N1');
  await mkdir(directory, { recursive: true });
  const nativeCompilerSha256 = sha256(await readFile(nativeCompiler));
  const nativeCommand = ['build', entryRelative, '--out', path.join(directory, 'index.js')];
  runCommand(nativeCompiler, nativeCommand, { cwd: root });
  assert.equal(sha256(await readFile(nativeCompiler)), nativeCompilerSha256,
    'PSC0_SH1_NATIVE_BINARY_CHANGED');
  const outputJs = path.join(directory, 'index.js');
  const compilerSha256 = sha256(await readFile(outputJs));
  const sourceRef = capture('git', ['rev-parse', 'HEAD']);
  const nativeIr = await runNativeIrCheckerConformance({
    nativeChecker: path.join(root, '.lake/build/bin/psc1_ir_check_tests'),
    closure, nativeTypeScript: path.join(directory, 'index.ts'),
    root, outDir: path.join(directory, 'ir-checker-native'),
  });
  const loaded = await loadCompiler(outputJs, { expectedSha256: compilerSha256 });
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
      binarySha256: nativeCompilerSha256,
      path: path.relative(root, nativeCompiler),
      command: nativeCommand,
      buildContext: 'CI builds the current native target with lake build psc1; binary and workspace identities are recorded separately.',
    },
    artifacts: {
      javascriptSha256: compilerSha256,
      typescriptSha256: sha256(await readFile(path.join(directory, 'index.ts'))),
    },
    recipe: await recipeIdentity(), toolchain: await toolchainIdentity(), typescriptProfile,
    candidateClaim: 'Native PSC frontend consumes raw current compiler source; generated current compiler executes the raw language and iteration corpus.',
    selectedSeedBootstrapProven: false, currentSourceFixedPointProven: false,
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

function option(args, name, fallback) {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  assert(index + 1 < args.length && !args[index + 1].startsWith('--'), 'PSC0_SH1_ARGUMENT: ' + name);
  return args[index + 1];
}

const outDir = path.resolve(root, option(args, '--out', 'dist/sh1'));
if (command === 'seed-identity') {
  const sourceRoot = path.resolve(root, option(args, '--source', '../historical-source/psc0'));
  const { identitySha256 } = await historicalIdentity(sourceRoot);
  if (process.env.GITHUB_OUTPUT) await appendFile(process.env.GITHUB_OUTPUT, 'identity=' + identitySha256 + '\n');
  process.stdout.write('PSC0_SH1_SEED_IDENTITY: ' + identitySha256 + '\n');
} else if (command === 'recover-seed') {
  const sourceRoot = path.resolve(root, option(args, '--source', '../historical-source/psc0'));
  await recoverSeed(sourceRoot, outDir);
} else if (command === 'recover-qualified-seed') {
  await recoverQualifiedSeed({
    sourceRoot: path.resolve(root, option(args, '--source', '../qualified-source/psc0')),
    bootstrapCompiler: path.resolve(root, option(args, '--bootstrap', '.selfhost-seeds/' + historicalRef + '/index.js')),
    artifactDirectory: path.resolve(root, option(args, '--artifact', '../qualified-artifact/dist/sh1')),
    outDir,
  });
} else if (command === 'native-candidate') {
  const nativeCompiler = path.resolve(root, option(args, '--native', '.lake/build/bin/psc1'));
  await nativeCandidate(nativeCompiler, await sourceClosure(root), outDir);
} else if (command === 'candidate') {
  const authoring = await selectedAuthoringSeed(option(args, '--seed', undefined));
  const closure = await sourceClosure(root);
  const libraryCompiler = await loadCompiler(authoring.compilerPath, {
    expectedSha256: authoring.expectedSha256,
  });
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
      reason: 'The explicitly pinned pre-checker Q may produce C1; current C1/C2/C3 checker consumers remain mandatory.',
    },
  });
  await sessionConformance(authoring.compilerPath, generation.outputJs, outDir, {
    oracle: authoring.provenance, candidateSha256: generation.receipt.artifacts.javascriptSha256,
  });
  const loaded = await loadCompiler(generation.outputJs, {
    expectedSha256: generation.receipt.artifacts.javascriptSha256,
  });
  await runIrCheckerConformance({
    ...loaded, compilerPath: generation.outputJs, root, outDir: path.join(outDir, 'C1/ir-checker'), tsc,
  });
  await runHelperRuntimeConformance({ ...loaded, outDir: path.join(outDir, 'C1') });
  await runGenericErasureConformance({
    ...loaded, root, outDir: path.join(outDir, 'C1/generic-erasure'), tsc,
    nativeCompiler: option(args, '--native', undefined),
  });
  const nativeArg = option(args, '--native', undefined);
  await runSh1Capabilities({
    ...loaded, root, outDir: path.join(outDir, 'C1/capabilities'), tsc,
    nativeCompiler: nativeArg ? path.resolve(root, nativeArg) : undefined,
  });
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
  assert.equal(second.receipt.originalIrInventory.runtimeIrTypingAccepted, true,
    'PSC0_SH1_C2_PORTABLE_IR_CHECK_REQUIRED');
  assert.equal(second.receipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission, true);
  await runIrCheckerConformance({
    ...secondCompiler, compilerPath: second.outputJs, root, outDir: path.join(outDir, 'C2/ir-checker'), tsc,
  });
  await runSh1Capabilities({ ...secondCompiler, root, outDir: path.join(outDir, 'C2/capabilities'), tsc });
  await runHelperRuntimeConformance({ ...secondCompiler, outDir: path.join(outDir, 'C2') });
  await runGenericErasureConformance({
    ...secondCompiler, root, outDir: path.join(outDir, 'C2/generic-erasure'), tsc,
  });
  const third = await buildGeneration(second.outputJs, closure, path.join(outDir, 'C3'), {
    expectedSha256: second.receipt.artifacts.javascriptSha256,
  });
  assert.deepEqual(second.receipt.artifacts, third.receipt.artifacts,
    'PSC0_SH1_C2_C3_ARTIFACT_MISMATCH');
  const thirdCompiler = await loadCompiler(third.outputJs, {
    expectedSha256: third.receipt.artifacts.javascriptSha256,
  });
  assert.equal(third.receipt.originalIrInventory.runtimeIrTypingAccepted, true,
    'PSC0_SH1_C3_PORTABLE_IR_CHECK_REQUIRED');
  assert.equal(third.receipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission, true);
  await runIrCheckerConformance({
    ...thirdCompiler, compilerPath: third.outputJs, root, outDir: path.join(outDir, 'C3/ir-checker'), tsc,
  });
  await runSh1Capabilities({ ...thirdCompiler, root, outDir: path.join(outDir, 'C3/capabilities'), tsc });
  await runHelperRuntimeConformance({ ...thirdCompiler, outDir: path.join(outDir, 'C3') });
  await runGenericErasureConformance({
    ...thirdCompiler, root, outDir: path.join(outDir, 'C3/generic-erasure'), tsc,
  });
  assert.equal((await sourceClosure(root)).sha256, closure.sha256, 'PSC0_SH1_SOURCE_CHANGED_DURING_RUN');
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
    canonicalSourceContract: 'Existing surface printer; normalized worker representation is compared through canonical admissions.',
    portableIrCheckerGenerations: ['C1', 'C2', 'C3'],
    originalIrCheckedBuilds: ['C2', 'C3'],
    originalIrChecking: 'C1 checks the exact current-source IR emitted as C2; C2 checks the exact IR emitted as C3.',
    immutableSeedBoundary: firstReceipt.originalIrInventory.portableChecker,
    runtimeIrTypingEnforced: true,
    runtimeIrStrictQualification: 'not-claimed',
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  await writeJson(path.join(outDir, 'qualification.json'), receipt);
  await retainPromotableSeed(receipt, firstReceipt, second.receipt, outDir);
  process.stdout.write('PSC0_SH1_FIXED_POINT: ' + JSON.stringify(receipt) + '\n');
} else {
  throw new Error('usage: node scripts/sh1-qualify.mjs seed-identity|recover-seed|recover-qualified-seed|native-candidate|candidate|fixed-point [--out directory] [--source historical-psc0] [--seed compiler.js] [--native native-psc1]');
}
