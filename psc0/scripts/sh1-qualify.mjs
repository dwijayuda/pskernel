import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { appendFile, mkdir, readFile, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { performance } from 'node:perf_hooks';
import { packageBySection, parseImports } from './workspace-layout.mjs';
import { resolveTypeScriptCli } from './typescript-cli.mjs';
import { createGeneratedPreparationSession } from './generated-preparation-session.mjs';
import { inventoryOriginalIr } from './original-ir-inventory.mjs';
import {
  compileTypeScript, runCommand, runSh1Capabilities, sha256, unwrap,
} from './sh1-capabilities.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const historicalRef = '37f63c39d4a07189938046c64152bba25d789450';
const historicalTree = '02207b677c91471d6bb5cb3f6418995aed0d0102';
const entryRelative = 'packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean';
const historicalRecipe = Object.freeze({
  id: 'psc0-native-recovery/1',
  build: ['lake', 'build', 'psc1'],
  compile: ['.lake/build/bin/psc1', 'build', entryRelative, '--out', '<output>/index.js'],
  artifacts: ['index.ts', 'index.js', 'index.d.ts', 'index.js.map'],
  leanGitHash: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
});
const allowedPackages = new Set([
  'bootstrap', 'foundation', 'syntax', 'core', 'environment', 'meta', 'elab',
  'bridge', 'compiler-ir', 'erasure', 'compiler', 'backend-ts',
]);
const tsc = resolveTypeScriptCli();
let importSequence = 0;

function capture(command, args, cwd = root) {
  return runCommand(command, args, {
    cwd, encoding: 'utf8', stdio: 'pipe', timeout: 30000,
  }).stdout.trim();
}

assert.equal(capture(process.execPath, [tsc, '--version']), 'Version 5.8.3',
  'PSC0_SH1_TYPESCRIPT_PIN');

async function writeJson(file, value) {
  await mkdir(path.dirname(file), { recursive: true });
  await writeFile(file, JSON.stringify(value, null, 2) + '\n');
}

function stripImports(source) {
  return source.split(/\r?\n/u)
    .filter((line) => !/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line))
    .join('\n').trim();
}

async function sourceClosure(workspace) {
  const ordered = [];
  const complete = new Set();
  const active = new Set();
  async function visit(relative) {
    if (complete.has(relative)) return;
    assert(!active.has(relative), 'PSC0_SH1_IMPORT_CYCLE: ' + relative);
    assert(!relative.startsWith('..') && !path.isAbsolute(relative), 'PSC0_SH1_SOURCE_OUTSIDE_ROOT');
    active.add(relative);
    const source = await readFile(path.join(workspace, relative), 'utf8');
    for (const moduleName of parseImports(source)) {
      const parts = moduleName.split('.');
      const packageName = parts[0] === 'Ps' ? packageBySection.get(parts[1]) : undefined;
      assert(allowedPackages.has(packageName), 'PSC0_SH1_CLOSURE_PACKAGE: ' + moduleName);
      await visit(path.posix.join('packages', packageName, 'src', ...parts) + '.lean');
    }
    active.delete(relative);
    complete.add(relative);
    ordered.push({ path: relative, source, sha256: sha256(source) });
  }
  await visit(entryRelative);
  const manifest = ordered.map(({ path: sourcePath, sha256: digest }) => ({
    path: sourcePath, sha256: digest,
  }));
  return {
    ordered,
    manifest,
    sha256: sha256(JSON.stringify(manifest)),
    moduleCount: ordered.length,
    bytes: ordered.reduce((count, item) => count + Buffer.byteLength(item.source), 0),
  };
}

async function loadCompiler(file) {
  const bytes = await readFile(file);
  const compilerSha256 = sha256(bytes);
  // Generated compiler bundles are standalone. Import precisely the bytes hashed,
  // with an independent namespace per load; never transfer their tagged objects.
  const sequence = ++importSequence;
  const diagnosticTrailer = '\n//# sourceURL=psc0-sh1-' + compilerSha256 + '-' + sequence + '.mjs\n';
  const exactBody = Buffer.concat([bytes, Buffer.from(diagnosticTrailer)]);
  const compiler = await import('data:text/javascript;base64,' + exactBody.toString('base64'));
  // The only loader addition is the recorded diagnostic sourceURL comment above.
  for (const name of [
    'PsCompilerSourceKind', 'List', 'psCompilerPrepareSource', 'psCompilerPrepareSources',
    'psCompilerAdmissionsFromPrepared', 'psCompilerTypeScriptFromPrepared',
    'psCompilerTranslateSource',
  ]) assert(name in compiler, 'PSC0_SH1_COMPILER_EXPORT: ' + name);
  return { compiler, compilerSha256 };
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
    'scripts/typescript-cli.mjs', 'scripts/workspace-layout.mjs',
    'scripts/generated-preparation-session.mjs', 'scripts/original-ir-inventory.mjs',
  ];
  const contents = [];
  for (const file of files) contents.push({ path: file, sha256: sha256(await readFile(path.join(root, file))) });
  return { files: contents, sha256: sha256(JSON.stringify(contents)) };
}

async function historicalIdentity(sourceRoot) {
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
    toolchain: await toolchainIdentity(),
    recipe: historicalRecipe,
  };
  assert.equal(identity.toolchain.leanGitHash, historicalRecipe.leanGitHash,
    'PSC0_SH1_LEAN_PIN');
  return { closure, identity, identitySha256: sha256(JSON.stringify(identity)) };
}

async function recoverSeed(sourceRoot, outDir) {
  const { closure, identity, identitySha256 } = await historicalIdentity(sourceRoot);
  const receiptPath = path.join(outDir, 'seed.json');
  let cached = false;
  if (existsSync(receiptPath)) {
    try {
      const receipt = JSON.parse(await readFile(receiptPath, 'utf8'));
      assert.equal(receipt.identitySha256, identitySha256);
      for (const [name, expected] of Object.entries(receipt.artifacts)) {
        assert.equal(sha256(await readFile(path.join(outDir, name))), expected);
      }
      assert('index.js' in receipt.artifacts && 'index.ts' in receipt.artifacts);
      cached = true;
    } catch {
      process.stdout.write('PSC0_SH1_SEED_CACHE: RECOMPUTE (identity or artifact mismatch)\n');
    }
  }
  if (!cached) {
    runCommand(historicalRecipe.build[0], historicalRecipe.build.slice(1), { cwd: sourceRoot });
    await mkdir(outDir, { recursive: true });
    const command = historicalRecipe.compile.map((item) => item.replace('<output>', outDir));
    runCommand(path.join(sourceRoot, command[0]), command.slice(1), { cwd: sourceRoot });
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

async function buildGeneration(compilerPath, closure, outDir) {
  const start = performance.now();
  const loaded = await loadCompiler(compilerPath);
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
  const irInventory = inventoryOriginalIr(compiler, ir, { compilerSha256 });
  const typeScript = unwrap(compiler.psTsEmitModule(ir), 'EMIT');
  const emitDone = performance.now();
  const outputJs = await compileTypeScript(typeScript, outDir, tsc, root);
  const javascript = await readFile(outputJs);
  await writeJson(path.join(outDir, 'original-ir-inventory.json'), irInventory);
  await writeFile(path.join(outDir, 'admissions.json'), admissions);
  await writeFile(path.join(outDir, 'canonical-source.json'), canonicalText);
  await writeJson(path.join(outDir, 'source-closure.json'), closure.manifest);
  const receipt = {
    schemaVersion: 1,
    executingCompilerSha256: compilerSha256,
    sourceRef: capture('git', ['rev-parse', 'HEAD']),
    sourceClosureSha256: closure.sha256,
    moduleCount: closure.moduleCount,
    sourceBytes: closure.bytes,
    sourceKind: 'raw-authoritative-lean',
    language: { implementation: 'PSC1', candidateCapability: 'PSC0-SH/1 structural state generalization' },
    recipe: await recipeIdentity(),
    toolchain: await toolchainIdentity(),
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

async function sessionConformance(seedPath, candidatePath, outDir) {
  const seed = await loadCompiler(seedPath);
  const candidate = await loadCompiler(candidatePath);
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
      list(seed.compiler, sources.map((item) => item.source))), 'SESSION_OLD_ORACLE');
    const result = session.prepare('lean', sources);
    assert.equal(admissionText(candidate.compiler, result.prepared), admissionText(seed.compiler, oldPrepared),
      'PSC0_SH1_SESSION_OLD_SEED_CORRESPONDENCE');
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
  const independent = await loadCompiler(candidatePath);
  const independentSession = createGeneratedPreparationSession(independent.compiler, {
    compilerSha256: independent.compilerSha256,
  });
  const fresh = independentSession.prepare('lean', sourceSets[0]);
  assert.equal(fresh.receipt.cache.prefixModules, 0);
  assert.equal(fresh.receipt.cache.preparedModules, 2);
  receipts.push(fresh.receipt);
  const oracle = unwrap(seed.compiler.psCompilerPrepareSources(seed.compiler.PsCompilerSourceKind.lean,
    list(seed.compiler, sourceSets[0].map((item) => item.source))), 'SESSION_FRESH_ORACLE');
  assert.equal(admissionText(independent.compiler, fresh.prepared), admissionText(seed.compiler, oracle));
  const byteBound = 48;
  const bounded = createGeneratedPreparationSession(candidate.compiler, {
    compilerSha256: candidate.compilerSha256, maxParsedSourceBytes: byteBound,
  });
  const boundedResult = bounded.prepare('lean', sourceSets[0]);
  assert(boundedResult.receipt.cache.retainedParsedSourceBytes <= byteBound);
  assert.equal(admissionText(candidate.compiler, boundedResult.prepared), admissionText(seed.compiler, oracle));
  receipts.push(boundedResult.receipt);
  await writeJson(path.join(outDir, 'session-conformance.json'), {
    schemaVersion: 1,
    evidence: 'old-seed-admission-correspondence-and-incremental-state-transitions',
    seedCompilerSha256: seed.compilerSha256,
    candidateCompilerSha256: candidate.compilerSha256,
    receipts,
  });
  process.stdout.write('PSC0_SH1_SESSION_CONFORMANCE: PASS (old-seed oracle; warm, prefix, body edit, failure recovery, source kind, fresh instance)\n');
}

function option(args, name, fallback) {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  assert(index + 1 < args.length && !args[index + 1].startsWith('--'), 'PSC0_SH1_ARGUMENT: ' + name);
  return args[index + 1];
}

const [command, ...args] = process.argv.slice(2);
const outDir = path.resolve(root, option(args, '--out', 'dist/sh1'));
if (command === 'seed-identity') {
  const sourceRoot = path.resolve(root, option(args, '--source', '../historical-source/psc0'));
  const { identitySha256 } = await historicalIdentity(sourceRoot);
  if (process.env.GITHUB_OUTPUT) await appendFile(process.env.GITHUB_OUTPUT, 'identity=' + identitySha256 + '\n');
  process.stdout.write('PSC0_SH1_SEED_IDENTITY: ' + identitySha256 + '\n');
} else if (command === 'recover-seed') {
  const sourceRoot = path.resolve(root, option(args, '--source', '../historical-source/psc0'));
  await recoverSeed(sourceRoot, outDir);
} else if (command === 'candidate') {
  const seedPath = path.resolve(root, option(args, '--seed',
    '.selfhost-seeds/' + historicalRef + '/index.js'));
  const closure = await sourceClosure(root);
  const generation = await buildGeneration(seedPath, closure, path.join(outDir, 'C1'));
  await sessionConformance(seedPath, generation.outputJs, outDir);
  const loaded = await loadCompiler(generation.outputJs);
  const nativeArg = option(args, '--native', undefined);
  await runSh1Capabilities({
    ...loaded, root, outDir: path.join(outDir, 'C1/capabilities'), tsc,
    nativeCompiler: nativeArg ? path.resolve(root, nativeArg) : undefined,
  });
  assert.equal((await sourceClosure(root)).sha256, closure.sha256, 'PSC0_SH1_SOURCE_CHANGED_DURING_RUN');
  process.stdout.write('PSC0_SH1_CANDIDATE: PASS (current raw source and generated capability execution)\n');
} else if (command === 'fixed-point') {
  const closure = await sourceClosure(root);
  const firstDir = path.join(outDir, 'C1');
  const firstReceipt = JSON.parse(await readFile(path.join(firstDir, 'receipt.json')));
  assert.equal(firstReceipt.sourceClosureSha256, closure.sha256, 'PSC0_SH1_STALE_CANDIDATE_SOURCE');
  assert.equal(firstReceipt.artifacts.javascriptSha256, sha256(await readFile(path.join(firstDir, 'index.js'))),
    'PSC0_SH1_CANDIDATE_DIGEST');
  assert.deepEqual(firstReceipt.recipe, await recipeIdentity(), 'PSC0_SH1_CANDIDATE_RECIPE');
  assert.deepEqual(firstReceipt.toolchain, await toolchainIdentity(), 'PSC0_SH1_CANDIDATE_TOOLCHAIN');
  const capabilityReceipt = JSON.parse(await readFile(path.join(firstDir, 'capabilities/receipt.json')));
  assert.equal(capabilityReceipt.compilerSha256, firstReceipt.artifacts.javascriptSha256);
  assert.deepEqual(capabilityReceipt.sourceKinds.map((item) => item.sourceKind).sort(), ['lean', 'ps']);
  for (const capability of capabilityReceipt.sourceKinds) {
    assert(['lean', 'ps'].includes(capability.sourceKind));
    assert.equal(capability.sourceSha256, sha256(await readFile(path.join(root,
      'test/fixtures/selfhost-sh1-accumulators.' + capability.sourceKind))));
    assert.equal(capability.behavior, 'pass');
  }
  const second = await buildGeneration(path.join(firstDir, 'index.js'), closure, path.join(outDir, 'C2'));
  const secondCompiler = await loadCompiler(second.outputJs);
  await runSh1Capabilities({ ...secondCompiler, root, outDir: path.join(outDir, 'C2/capabilities'), tsc });
  const third = await buildGeneration(second.outputJs, closure, path.join(outDir, 'C3'));
  assert.deepEqual(second.receipt.artifacts, third.receipt.artifacts,
    'PSC0_SH1_C2_C3_ARTIFACT_MISMATCH');
  const thirdCompiler = await loadCompiler(third.outputJs);
  await runSh1Capabilities({ ...thirdCompiler, root, outDir: path.join(outDir, 'C3/capabilities'), tsc });
  assert.equal((await sourceClosure(root)).sha256, closure.sha256, 'PSC0_SH1_SOURCE_CHANGED_DURING_RUN');
  const receipt = {
    schemaVersion: 1,
    sourceRef: capture('git', ['rev-parse', 'HEAD']),
    sourceClosureSha256: closure.sha256,
    moduleCount: closure.moduleCount,
    evidence: 'compiler-qualified-current-source-fixed-point',
    equation: 'C1=S0(A); C2=C1(A); C3=C2(A); compare C2 and C3 products',
    rawAuthoringSourceConsumedEveryGeneration: true,
    artifacts: second.receipt.artifacts,
    c1CompilerSha256: firstReceipt.artifacts.javascriptSha256,
    c2CompilerSha256: second.receipt.artifacts.javascriptSha256,
    c3CompilerSha256: third.receipt.artifacts.javascriptSha256,
    rawCapabilityKinds: ['lean', 'proofScript'],
    canonicalSourceContract: 'Existing surface printer; normalized worker representation is compared through canonical admissions.',
    runtimeIrStrictQualification: 'not-claimed',
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  await writeJson(path.join(outDir, 'qualification.json'), receipt);
  process.stdout.write('PSC0_SH1_FIXED_POINT: ' + JSON.stringify(receipt) + '\n');
} else {
  throw new Error('usage: node scripts/sh1-qualify.mjs seed-identity|recover-seed|candidate|fixed-point [--out directory] [--source historical-psc0] [--seed compiler.js] [--native native-psc1]');
}
