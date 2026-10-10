// Complete receipt binding for the exact already-generated source checkpoint.
// This sidecar is an evidence producer, not one of the 48 generation recipe
// inputs. It runs no PSC/TypeScript compilation or conformance execution.
// The normal current-development binder receives the same one-line repair;
// immutable generation receipts and the original generation recipe stay intact.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, readFile, realpath, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { readBootstrapClosure as sourceClosure } from './sh1-source-snapshot.mjs';
import { readSelectedAuthoringSeed as readSelectedSeed } from './sh1-successor-seed.mjs';
import { sh1GrammarProfile } from './sh1-grammar-conformance.mjs';
import { resolveTypeScriptCli, expectedTypeScriptVersion, typeScriptProfileArgs } from './typescript-cli.mjs';
import { bindStrictQualificationEvidence } from './sh1-strict-evidence-finish.mjs';
import { runCommand, sha256 } from './sh1-capabilities.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const expected = Object.freeze({
  compiledSourceRef: '1fa5559a72b293defc56ef7e7020cf82d4b44b79',
  sourceRoot: '/home/runner/work/pskernel/pskernel/psc0',
  sourceClosureSha256: '46737f1e58a56cfa4cc0b575d30f531efe1dbe06ccf34002cc01e553febb1fb5',
  recipeSha256: 'a631bcaf914c0913f696eaf8a138a44449c46957f5a2d7736ec9cff8bcb63eba',
  qualifierSha256: '707fedd63f01999293cf68b39f85ea6526c31216e84c2090d6ff1b8edf6fecdb',
  originalBinderSha256: 'bd18cbb77c80fb57038b7d270e468c5b029164095dad958a84c52d113d67b049',
  correctedBinderSha256: '829c7c8c70ce3388e6a8e8044ee07b5c65649546d1556a62d599a552fdcdb606',
  correctedBinderBlob: '7700fef35acd06789b94f72078869fdef489214f',
  generationLogSha256: '1ee74d4316074988052bb6e1e86f14d6ede117c03af8e46a3f469c46e6aa3548',
  generationLogBytes: 875228,
});
const expectedArchives = [
  { runId: 38015134511, artifactId: 11658430459,
    name: 'psc0-sh1-ts7.0.2-1fa5559a72b293defc56ef7e7020cf82d4b44b79',
    sha256: '6ee7b3da60346bec004665d9bb2276ceb680a1a3d882d0aeb397398a9e1c1812',
    bytes: 5147944, fileCount: 344,
    rawArchivePath: 'dist/sh1-continuation-inputs/predecessor-verified.zip' },
  { runId: 38021634599, artifactId: 11659939542,
    name: 'psc0-sh1-continuation-ts7.0.2-38021634599',
    sha256: '599fd5160f132d0795246bc102f8b306ae3bd8d42238201cef2d3e69dbef6f80',
    bytes: 11739089, fileCount: 444,
    rawArchivePath: 'dist/sh1-evidence-finish-inputs/predecessor-verified.zip' },
];
const expectedOwnership = {
  N1: { runId: 38015134511, compilerJobId: 114103608774 },
  C1: { runId: 38015134511, compilerJobId: 114103608774 },
  C2: { runId: 38021634599, compilerJobId: 114123691566 },
  C3: { runId: 38021634599, compilerJobId: 114123691566 },
};
const fixedArtifacts = {
  canonicalSurfaceSourceSha256: '240a3e7072441f14a9ad7070e5c3b8306b42d97ef5932be59f2c458d1816a98e',
  normalizedCanonicalAdmissionsSha256: 'e77c40ccd38fc3ea6a2d3342732f23b54665d066aeeda38533d04ff54aeeb020',
  typescriptSha256: '595cd338505f7012b8f0a813a78a1ecbafe863e6ea715b9861db35333d5a254c',
  javascriptSha256: '6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3',
};
const generationPins = {
  N1: { directory: 'development/N1',
    sha256: '6768f5d50c376b50c6138aeacffe03553c9f860b17da965ea92acd3a36126404', bytes: 15827,
    artifacts: { javascriptSha256: fixedArtifacts.javascriptSha256,
      typescriptSha256: fixedArtifacts.typescriptSha256 } },
  C1: { directory: 'C1',
    sha256: '33fa94c5f4f825133be4c07f47e8f68d447546eb8a2858193d16b305afbd9d8f', bytes: 169531,
    artifacts: { canonicalSurfaceSourceSha256: fixedArtifacts.canonicalSurfaceSourceSha256,
      normalizedCanonicalAdmissionsSha256: '24b90a6cb748b9deb4f0340760e9ca50b358013dcf9d8be16e1143712465db52',
      typescriptSha256: '1c9ece3424bdb7c173c805450df10e7ec4fb1e1bc46945abdb6bef04ea4d0eba',
      javascriptSha256: '91f69e62d33bb5f670c5e9a56479280f97ebf15a60d2d9e6155ecb8ec33d49d5' } },
  C2: { directory: 'C2',
    sha256: '5da7545d89d7b28a4f296cbd1bd3b154aef5bac38af143caa836deb5c61f5a02', bytes: 166707,
    artifacts: fixedArtifacts },
  C3: { directory: 'C3',
    sha256: 'eaf6c772de3d9f27b4b1a42412746165b22be0c5cf431944827c95af7d8050d1', bytes: 166709,
    artifacts: fixedArtifacts },
};
const typescriptVersion = expectedTypeScriptVersion();
assert.equal(typescriptVersion, '7.0.2',
  'PSC0_SH1_TYPESCRIPT_PROFILE: current qualification requires TypeScript 7.0.2');
const tsc = resolveTypeScriptCli();
const typescriptProfile = Object.freeze({
  version: typescriptVersion,
  purpose: 'current-emission',
  arguments: typeScriptProfileArgs([], typescriptVersion),
});

// Verbatim helper definitions from the immutable original qualifier.

function capture(command, args, cwd = root) {
  return runCommand(command, args, {
    cwd, encoding: 'utf8', stdio: 'pipe', timeout: 30000,
  }).stdout.trim();
}

async function writeJson(file, value) {
  await mkdir(path.dirname(file), { recursive: true });
  await writeFile(file, JSON.stringify(value, null, 2) + '\n');
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
    'scripts/sh1-qualify.mjs', 'scripts/sh1-capabilities.mjs', 'scripts/sh1-resource-policy.mjs',
    'scripts/sh1-grammar-conformance.mjs', 'scripts/sh1-grammar-profile.mjs', 'scripts/sh1-projection-conformance.mjs',
    'scripts/sh1-successor-seed.mjs', 'psconfig.json',
    'scripts/sh1-function-entry.mjs',
    'scripts/sh1-fresh-name-conformance.mjs', 'scripts/sh1-migration-worker-conformance.mjs',
    'scripts/sh1-migration-worker-abi.mjs',
    'test/fixtures/selfhost-sh1-accumulators.lean', 'test/fixtures/selfhost-sh1-accumulators.ps',
    'test/fixtures/selfhost-sh1-empty.lean', 'test/fixtures/selfhost-sh1-empty.ps',
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

function argument(name) {
  const args = process.argv.slice(2);
  const index = args.indexOf(name);
  assert(index >= 0 && index + 1 < args.length && !args[index + 1].startsWith('--'),
    'PSC0_SH1_FINISH_ARGUMENT: ' + name);
  assert.equal(args.filter(value => value === name).length, 1);
  return args[index + 1];
}
const args = process.argv.slice(2);
assert.equal(args.length, 6, 'usage: --inputs path --inputs-sha256 digest --out dist/sh1');
assert.deepEqual(args.filter((_, index) => index % 2 === 0).sort(),
  ['--inputs', '--inputs-sha256', '--out'].sort());
const outDir = path.resolve(root, argument('--out'));
const inputsPath = path.resolve(root, argument('--inputs'));
const inputsSha256 = argument('--inputs-sha256');
assert.match(inputsSha256, /^[a-f0-9]{64}$/u);
assert.equal(root, expected.sourceRoot, 'preserve native source-receipt absolute path');
assert.equal(outDir, path.join(root, 'dist/sh1'));
assert.equal(inputsPath, path.join(root, 'dist/sh1-evidence-finish-inputs/inputs.json'));
assert.equal(capture('git', ['rev-parse', 'HEAD']), expected.compiledSourceRef);
assert.equal(capture('git', ['status', '--porcelain', '--untracked-files=no']), '',
  'immutable tracked source checkout must be unchanged');
assert.equal(process.version, 'v22.23.3');
assert.equal(capture('lean', ['--githash']), '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
assert.equal(capture(process.execPath, [tsc, '--version']), 'Version ' + typescriptVersion);
const config = JSON.parse(await readFile(path.join(root, 'psconfig.json'), 'utf8'));
assert.equal(config.languageVersion, '0.9-r3');
assert.deepEqual(config.sourceGrammar, sh1GrammarProfile);
const rawInputs = await readFile(inputsPath);
assert.equal(sha256(rawInputs), inputsSha256, 'authenticated finish inputs envelope');
const inputs = JSON.parse(rawInputs.toString('utf8'));
assert.equal(inputs.schemaVersion, 1);
assert.equal(inputs.kind, 'psc0-authenticated-retained-fixed-point-finish-inputs');
assert.equal(inputs.compiledSourceRef, expected.compiledSourceRef);
assert.equal(inputs.sourceRoot, root);
assert.equal(inputs.outputRoot, outDir);
assert.equal(inputs.sourceClosureSha256, expected.sourceClosureSha256);
assert.equal(inputs.recipeSha256, expected.recipeSha256);
assert.deepEqual(inputs.generationOwnership, expectedOwnership);
assert.equal(inputs.authenticatedArchives.length, expectedArchives.length);
for (let index = 0; index < expectedArchives.length; index++) {
  for (const [key, value] of Object.entries(expectedArchives[index])) {
    assert.deepEqual(inputs.authenticatedArchives[index][key], value, 'authenticated archive ' + key);
  }
}
const currentRecipe = await recipeIdentity();
assert.equal(currentRecipe.files.length, 48);
assert.equal(currentRecipe.sha256, expected.recipeSha256);
assert.deepEqual(currentRecipe.files, inputs.recipeFiles);
assert.equal(sha256(JSON.stringify(inputs.recipeFiles)), expected.recipeSha256);
const originalQualifier = await readFile(path.join(root, 'scripts/sh1-qualify.mjs'));
const originalBinder = await readFile(path.join(root, 'scripts/sh1-strict-evidence.mjs'));
assert.equal(sha256(originalQualifier), expected.qualifierSha256);
assert.equal(sha256(originalBinder), expected.originalBinderSha256);
const producer = inputs.evidenceProducer;
assert.match(producer.sourceRef, /^[a-f0-9]{40}$/u);
assert.notEqual(producer.sourceRef, expected.compiledSourceRef);
assert.equal(producer.sourceRef, process.env.GITHUB_SHA);
assert.equal(producer.currentExecution.headSha, producer.sourceRef);
assert.equal(String(producer.currentExecution.runId), process.env.GITHUB_RUN_ID);
assert.equal(String(producer.currentExecution.runAttempt), process.env.GITHUB_RUN_ATTEMPT);
for (const name of ['runId', 'workflowId', 'runAttempt', 'compilerJobId']) {
  assert(Number.isSafeInteger(producer.currentExecution[name]) && producer.currentExecution[name] > 0);
}
assert.equal(producer.finisher.path, 'scripts/sh1-finish-evidence.mjs');
assert.equal(producer.binder.path, 'scripts/sh1-strict-evidence-finish.mjs');
assert.equal(producer.binder.blob, expected.correctedBinderBlob);
assert.equal(producer.binder.sha256, expected.correctedBinderSha256);
assert.equal(producer.binder.bytes, 91977);
assert.match(producer.workflow.path, /^\.github\/workflows\/[^/]+\.yml$/u);
assert.match(producer.workflow.blob, /^[a-f0-9]{40}$/u);
assert.match(producer.workflow.sha256, /^[a-f0-9]{64}$/u);
assert(Number.isSafeInteger(producer.workflow.bytes) && producer.workflow.bytes > 0);
for (const component of [producer.finisher, producer.binder]) {
  assert.match(component.blob, /^[a-f0-9]{40}$/u);
  const bytes = await readFile(path.join(root, component.path));
  assert.equal(bytes.length, component.bytes);
  assert.equal(sha256(bytes), component.sha256);
  assert.equal(createHash('sha1').update(Buffer.from('blob ' + bytes.length + '\0')).update(bytes).digest('hex'),
    component.blob, 'exact evidence-producer Git blob');
}
const correctedBinder = await readFile(path.join(root, producer.binder.path), 'utf8');
const oldMarkerRead = '.map((line) => line.slice(pass))';
const repairedMarkerRead = '.map((line) => line.slice(pass.length))';
const oldBinderText = originalBinder.toString('utf8');
assert.equal(oldBinderText.split(oldMarkerRead).length - 1, 1);
assert.equal(correctedBinder, oldBinderText.replace(oldMarkerRead, repairedMarkerRead),
  'the sidecar differs only by the reviewed marker-prefix length correction');
assert(!inputs.recipeFiles.some(file => [producer.finisher.path, producer.binder.path].includes(file.path)),
  'evidence sidecars are not relabeled generation recipe inputs');

const importedFiles = new Map();
const allowedRoots = ['dist/sh1/', '.selfhost-seeds/', 'dist/sh1-native-seed-recovery/',
  'dist/sh1-seed-selection/', 'dist/typescript-profile/', 'dist/sh1-continuation-inputs/',
  'dist/sh1-evidence-finish-inputs/'];
for (const file of inputs.importedFiles) {
  assert(typeof file.path === 'string' && !path.isAbsolute(file.path) && !file.path.includes('\\'));
  assert(file.path.split('/').every(part => part !== '' && part !== '.' && part !== '..'));
  assert.equal(path.posix.normalize(file.path), file.path);
  assert(allowedRoots.some(prefix => file.path.startsWith(prefix)));
  assert(!importedFiles.has(file.path), 'unique imported file ' + file.path);
  assert.match(file.sha256, /^[a-f0-9]{64}$/u);
  assert(Number.isSafeInteger(file.bytes) && file.bytes >= 0);
  assert.notEqual(path.resolve(root, file.path), inputsPath, 'no self-referential input envelope');
  importedFiles.set(file.path, file);
}
assert(importedFiles.size >= 446, '444 artifact entries plus raw current archive and source job log');
async function verifyRetainedFile(file) {
  const absolute = path.resolve(root, file.path);
  assert.equal(await realpath(absolute), absolute, 'retained artifacts are regular canonical paths');
  const bytes = await readFile(absolute);
  assert.equal(bytes.length, file.bytes, file.path + ' raw byte count');
  assert.equal(sha256(bytes), file.sha256, file.path + ' raw digest');
  return bytes;
}
async function verifyAllRetainedFiles() {
  for (const file of importedFiles.values()) await verifyRetainedFile(file);
}
async function retainedBytes(relative) {
  const file = importedFiles.get(relative);
  assert(file, 'required retained evidence ' + relative);
  return verifyRetainedFile(file);
}
async function retainedJson(relative) {
  return JSON.parse((await retainedBytes(relative)).toString('utf8'));
}
await verifyAllRetainedFiles();
for (const archive of expectedArchives) {
  const file = importedFiles.get(archive.rawArchivePath);
  assert(file, 'raw authenticated archive remains retained');
  assert.equal(file.sha256, archive.sha256);
  assert.equal(file.bytes, archive.bytes);
}
for (const pathName of ['dist/sh1/resource-policy-fixed-point.json',
  'dist/sh1-continuation-inputs/inputs.json']) {
  assert(importedFiles.has(pathName), 'retain prior execution policy/provenance ' + pathName);
}
const outputNames = ['strict-enforcement-evidence.json', 'qualification.json',
  'seed-selection.json', 'evidence-completion.json'];
for (const file of outputNames) {
  assert(!existsSync(path.join(outDir, file)), 'never overwrite a retained completion output: ' + file);
}
const closureBefore = await sourceClosure(root);
assert.equal(closureBefore.sha256, expected.sourceClosureSha256);
assert.equal(closureBefore.moduleCount, 64);
const observedToolchain = await toolchainIdentity();
const retainedGenerations = {};
for (const [name, pin] of Object.entries(generationPins)) {
  const receiptPath = 'dist/sh1/' + pin.directory + '/receipt.json';
  const raw = await retainedBytes(receiptPath);
  assert.equal(sha256(raw), pin.sha256, name + ' exact producer receipt');
  assert.equal(raw.length, pin.bytes);
  const receipt = JSON.parse(raw.toString('utf8'));
  assert.equal(raw.toString('utf8'), JSON.stringify(receipt, null, 2) + '\n');
  assert.equal(receipt.schemaVersion, 1);
  assert.equal(receipt.sourceRef, expected.compiledSourceRef);
  assert.equal(receipt.sourceClosureSha256, expected.sourceClosureSha256);
  assert.equal(receipt.moduleCount, closureBefore.moduleCount);
  assert.equal(receipt.sourceKind, 'raw-authoritative-lean');
  assert.deepEqual(receipt.recipe, currentRecipe);
  assert.deepEqual(receipt.toolchain, observedToolchain);
  assert.deepEqual(receipt.typescriptProfile, typescriptProfile);
  assert.deepEqual(receipt.artifacts, pin.artifacts);
  assert.equal(receipt.evidence, name === 'N1' ? 'native-seeded-generated-compiler-candidate' : 'candidate-build');
  assert.deepEqual(receipt.provider, { status: 'not-attempted', kernelChecked: false });
  for (const [filename, key] of [['index.js', 'javascriptSha256'], ['index.ts', 'typescriptSha256'],
    ...(name === 'N1' ? [] : [['canonical-source.json', 'canonicalSurfaceSourceSha256'],
      ['admissions.json', 'normalizedCanonicalAdmissionsSha256']])]) {
    assert.equal(sha256(await retainedBytes('dist/sh1/' + pin.directory + '/' + filename)),
      receipt.artifacts[key], name + '/' + filename);
  }
  assert.deepEqual(await retainedJson('dist/sh1/' + pin.directory + '/source-closure.json'),
    closureBefore.manifest);
  retainedGenerations[name] = receipt;
}
assert.equal(retainedGenerations.C2.executingCompilerSha256,
  retainedGenerations.C1.artifacts.javascriptSha256);
assert.equal(retainedGenerations.C3.executingCompilerSha256,
  retainedGenerations.C2.artifacts.javascriptSha256);
assert.deepEqual(retainedGenerations.C2.artifacts, retainedGenerations.C3.artifacts);
assert.equal(inputs.generationLog.path, 'dist/sh1-evidence-finish-inputs/source-generation-job.log');
assert.equal(inputs.generationLog.blob, '6747dc056c2642f069cc1c45c37f9dea492e0b50');
assert.equal(inputs.generationLog.sha256, expected.generationLogSha256);
assert.equal(inputs.generationLog.bytes, expected.generationLogBytes);
const logEnvelope = importedFiles.get(inputs.generationLog.path);
assert(logEnvelope);
assert.equal(logEnvelope.sha256, expected.generationLogSha256);
assert.equal(logEnvelope.bytes, expected.generationLogBytes);
const generationLog = (await retainedBytes(inputs.generationLog.path)).toString('utf8');
const recordedMarkers = generationLog.split(/\r?\n/u).flatMap(line => {
  const match = line.match(/^\d{4}-\d{2}-\d{2}T\S+\s+(PSC0_[A-Z0-9_]+): (.*)$/u);
  return match ? [{ marker: match[1], text: match[2] }] : [];
});
const gateFiles = [
  ['PSC0_SH1_GENERATION', 'receipt.json'],
  ['PSC0_SH1_STRICT_SOURCE', 'strict-source/receipt.json'],
  ['PSC0_SH1_STRICT_TARGET', 'strict-target/receipt.json'],
  ['PSC0_SH1_STRICT_RUNTIME', 'strict-runtime/receipt.json'],
  ['PSC0_SH1_IR_CHECKER', 'ir-checker/receipt.json'],
  ['PSC0_SH1_CAPABILITIES', 'capabilities/receipt.json'],
  ['PSC0_SH1_HELPER_RUNTIME', 'helper-runtime.json'],
  ['PSC0_SH1_GENERIC_ERASURE', 'generic-erasure/receipt.json'],
];
const gateNames = new Set(gateFiles.map(([marker]) => marker));
const completedGates = recordedMarkers.filter(item => gateNames.has(item.marker));
assert.equal(completedGates.length, 16, 'two actual completed generation/gate groups');
const authenticatedGateReports = [];
for (let generationIndex = 0; generationIndex < 2; generationIndex++) {
  const generation = ['C2', 'C3'][generationIndex];
  for (let gateIndex = 0; gateIndex < gateFiles.length; gateIndex++) {
    const [marker, relative] = gateFiles[gateIndex];
    const observed = completedGates[generationIndex * gateFiles.length + gateIndex];
    assert.equal(observed.marker, marker, generation + ' actual gate order');
    const value = JSON.parse(observed.text);
    const receiptPath = 'dist/sh1/' + generation + '/' + relative;
    const recordedValue = await retainedJson(receiptPath);
    assert.deepEqual(value, recordedValue, generation + ' log/archive receipt agreement: ' + marker);
    if (gateIndex !== 0) assert.equal(value.compilerSha256, fixedArtifacts.javascriptSha256);
    authenticatedGateReports.push({ generation, marker, file: importedFiles.get(receiptPath) });
  }
}
assert(generationLog.includes('sh1-strict-evidence.mjs:969:'));
assert(generationLog.includes('sh1-strict-evidence.mjs:1740:'));
assert(generationLog.includes('sh1-qualify.mjs:1254:'));
assert(!recordedMarkers.some(item => ['PSC0_SH1_FIXED_POINT', 'PSC0_SH1_CONTINUATION_EVIDENCE',
  'PSC0_SH1_RETURNED_JSON'].includes(item.marker)),
  'the prior failed evidence producer never completed qualification');

async function finishRetainedEvidence() {
  // Verbatim original qualifier preflight, lines 1142–1198.
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
  // The preceding authenticated log/archive checks establish that these exact
  // generations and every original per-generation gate already completed.
  // Reading the immutable producer receipts does not execute a compiler.
  const second = { receipt: retainedGenerations.C2 };
  const third = { receipt: retainedGenerations.C3 };
  const secondCapabilities = await retainedJson('dist/sh1/C2/capabilities/receipt.json');
  const thirdCapabilities = await retainedJson('dist/sh1/C3/capabilities/receipt.json');

  // Every original read-only assertion surrounding the completed C2/C3 work.
  assert.equal(second.receipt.artifacts.canonicalSurfaceSourceSha256,
    nativeGrammar.canonicalSurfaceSourceSha256, 'PSC0_SH1_C2_SURFACE_MATCHES_ROUND_TRIPPED_SOURCE');
  assert.equal(second.receipt.originalIrInventory.runtimeIrTypingAccepted, true,
    'PSC0_SH1_C2_PORTABLE_IR_CHECK_REQUIRED');
  assert.equal(second.receipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission, true);
  assert.deepEqual(second.receipt.migrationWorkerAbi, firstReceipt.migrationWorkerAbi,
    'PSC0_SH1_C2_WORKER_PUBLIC_TYPES_AND_IR_SIGNATURES');
  assert.deepEqual(secondCapabilities.workerMigration, migrationReference.report,
    'PSC0_SH1_C2_WORKER_REFERENCE_CORRESPONDENCE');
  assert.deepEqual(second.receipt.artifacts, third.receipt.artifacts,
    'PSC0_SH1_C2_C3_ARTIFACT_MISMATCH');
  assert.equal(third.receipt.artifacts.canonicalSurfaceSourceSha256,
    nativeGrammar.canonicalSurfaceSourceSha256, 'PSC0_SH1_C3_SURFACE_MATCHES_ROUND_TRIPPED_SOURCE');
  assert.equal(third.receipt.originalIrInventory.runtimeIrTypingAccepted, true,
    'PSC0_SH1_C3_PORTABLE_IR_CHECK_REQUIRED');
  assert.equal(third.receipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission, true);
  assert.deepEqual(third.receipt.migrationWorkerAbi, firstReceipt.migrationWorkerAbi,
    'PSC0_SH1_C3_WORKER_PUBLIC_TYPES_AND_IR_SIGNATURES');
  assert.deepEqual(thirdCapabilities.workerMigration, migrationReference.report,
    'PSC0_SH1_C3_WORKER_REFERENCE_CORRESPONDENCE');
  // Verbatim original qualifier binding/finalization, lines 1253–1323.
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
  await verifyAllRetainedFiles();
  assert.deepEqual(await recipeIdentity(), currentRecipe, 'original generation recipe still intact');
  assert.equal((await sourceClosure(root)).sha256, expected.sourceClosureSha256);
  assert.equal(capture('git', ['status', '--porcelain', '--untracked-files=no']), '',
    'no tracked compiler/source/selection changes');
  assert.equal(sha256(await readFile(inputsPath)), inputsSha256);
  const outputFiles = {};
  for (const filename of ['strict-enforcement-evidence.json', 'qualification.json', 'seed-selection.json']) {
    const bytes = await readFile(path.join(outDir, filename));
    outputFiles[filename] = { path: 'dist/sh1/' + filename, sha256: sha256(bytes), bytes: bytes.length };
  }
  const completion = {
    schemaVersion: 1,
    kind: 'psc0-authenticated-retained-fixed-point-evidence-completion',
    status: 'evidence-completed',
    compiledSourceRef: expected.compiledSourceRef,
    sourceClosureSha256: closure.sha256,
    moduleCount: closure.moduleCount,
    generationRecipe: currentRecipe,
    originalQualifier: { path: 'scripts/sh1-qualify.mjs',
      blob: 'e2c55f900b0ba4fe29cdc7e2981160a49ef4d61d',
      sha256: expected.qualifierSha256, bytes: originalQualifier.length },
    originalBinder: { path: 'scripts/sh1-strict-evidence.mjs',
      blob: 'b0b080eea2c353640f12d744e599737d71f9c4f6',
      sha256: expected.originalBinderSha256, bytes: originalBinder.length },
    evidenceProducer: producer,
    markerBindingCorrection: { original: oldMarkerRead, repaired: repairedMarkerRead,
      sameOrdered15NativeFixtureNamesRequired: true,
      otherBinderBytesUnchanged: true },
    inputManifest: { path: path.relative(root, inputsPath), sha256: inputsSha256, bytes: rawInputs.length },
    authenticatedArchives: inputs.authenticatedArchives,
    generationOwnership: inputs.generationOwnership,
    generationReceipts: Object.fromEntries(Object.entries(generationPins).map(([name, pin]) => [
      name, importedFiles.get('dist/sh1/' + pin.directory + '/receipt.json'),
    ])),
    sourceGenerationLog: inputs.generationLog,
    actualCompletedGenerationGateReports: authenticatedGateReports,
    preservedInputs: { files: importedFiles.size,
      catalogSha256: sha256(JSON.stringify(inputs.importedFiles)), beforeAndAfterExact: true },
    outputs: outputFiles,
    compilerGenerationsRebuilt: [],
    conformanceExecutionsRepeated: [],
    selectedAuthoringSeedChanged: false,
    generationReceiptBytesChanged: false,
    generationRecipeRelabeledAsEvidenceProducer: false,
    priorExecutionConclusionsChanged: false,
    strictSh1Qualified: false,
    semanticContractQualified: false,
    generalPreservationProven: false,
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  await writeJson(path.join(outDir, 'evidence-completion.json'), completion);
  const completionBytes = await readFile(path.join(outDir, 'evidence-completion.json'));
  process.stdout.write('PSC0_SH1_EVIDENCE_COMPLETION: ' + JSON.stringify({
    path: 'dist/sh1/evidence-completion.json',
    sha256: sha256(completionBytes), bytes: completionBytes.length, value: completion,
  }) + '\n');
  process.stdout.write('PSC0_SH1_FIXED_POINT: ' + JSON.stringify(receipt) + '\n');
}
await finishRetainedEvidence();
