import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import {
  validateQualifiedSeedManifest, qualifiedSeedIdentity, readSelectedSeed,
} from './sh1-seed-manifest.mjs';
import {
  validateSuccessorSeedManifest, successorSeedIdentity, successorSeedSelection,
  makeSuccessorSeedManifest, readSelectedAuthoringSeed,
  verifySuccessorSeedCache, verifyAuthoringSeedCache, materializeSuccessorSeed,
} from './sh1-successor-seed.mjs';
import { sh1GrammarProfile } from './sh1-grammar-conformance.mjs';

const hash = (value) => createHash('sha256').update(value).digest('hex');
const clone = (value) => JSON.parse(JSON.stringify(value));
const selectedSource = JSON.parse(await readFile(new URL('../selfhost-seed.json', import.meta.url), 'utf8'));
const parent = selectedSource.kind === 'psc0-qualified-source-seed'
  ? selectedSource : selectedSource.parent.manifest;
validateQualifiedSeedManifest(parent);
const parentBefore = JSON.stringify(parent);

// Synthetic products exercise the host manifest and cache contract only.
// They are never imported or represented as a compiler qualification.
const products = {
  'canonical-source.json': '[{"path":"Probe.ps","source":"def probe : Nat := 7\\n"}]\n',
  'admissions.json': '{"fixture":"admissions"}\n',
  'index.ts': 'export const fixtureSeed: number = 7;\n',
  'index.js': 'export const fixtureSeed = 7;\n',
};
const finalArtifacts = {
  canonicalSurfaceSourceSha256: hash(products['canonical-source.json']),
  normalizedCanonicalAdmissionsSha256: hash(products['admissions.json']),
  typescriptSha256: hash(products['index.ts']),
  javascriptSha256: hash(products['index.js']),
};
const firstArtifacts = {
  canonicalSurfaceSourceSha256: hash('old seed canonical surface;'),
  normalizedCanonicalAdmissionsSha256: hash('first admissions'),
  typescriptSha256: hash('first TypeScript'),
  javascriptSha256: hash('first JavaScript'),
};
const recipeFiles = [
  'scripts/sh1-qualify.mjs',
  'scripts/sh1-successor-seed.mjs',
  'scripts/sh1-seed-manifest.mjs',
  'scripts/sh1-source-snapshot.mjs',
  'scripts/sh1-capabilities.mjs',
  'scripts/sh1-grammar-conformance.mjs',
  'scripts/sh1-projection-conformance.mjs',
  'scripts/typescript-cli.mjs',
].map((file) => ({ path: file, sha256: hash('synthetic recipe ' + file) }));
const recipe = { files: recipeFiles, sha256: hash(JSON.stringify(recipeFiles)) };
const sourceRef = '1'.repeat(40);
const sourceClosureSha256 = '2'.repeat(64);
const toolchain = { ...parent.toolchain, typescript: 'Version 7.0.2' };
const authoringSeed = {
  kind: 'previous-qualified-authoring-seed',
  sourceRef: parent.sourceRef,
  sourceClosureSha256: parent.sourceClosureSha256,
  identitySha256: qualifiedSeedIdentity(parent),
  compilerSha256: parent.expectedArtifacts.javascriptSha256,
  producerToolchain: parent.toolchain,
};
const commonReceipt = {
  evidence: 'candidate-build', sourceRef, sourceClosureSha256,
  sourceKind: 'raw-authoritative-lean', toolchain, recipe,
};
const firstReceipt = {
  ...commonReceipt, authoringSeed,
  executingCompilerSha256: parent.expectedArtifacts.javascriptSha256,
  artifacts: firstArtifacts,
};
const checked = {
  traversalComplete: true, runtimeIrTypingAccepted: true,
  sameOriginalIrCheckedBeforeEmission: true,
};
const secondReceipt = {
  ...commonReceipt, executingCompilerSha256: firstArtifacts.javascriptSha256,
  artifacts: finalArtifacts, originalIrInventory: checked,
};
const thirdReceipt = {
  ...commonReceipt, executingCompilerSha256: finalArtifacts.javascriptSha256,
  artifacts: finalArtifacts, originalIrInventory: checked,
};
const qualification = {
  evidence: 'compiler-qualified-current-source-fixed-point',
  sourceRef, sourceClosureSha256, authoringSeed, toolchain,
  rawAuthoringSourceConsumedEveryGeneration: true,
  sourceGrammar: sh1GrammarProfile,
  grammarGenerations: ['C1', 'C2', 'C3'],
  projectionResolutionGenerations: ['C1', 'C2', 'C3'],
  rawCapabilityKinds: ['lean', 'proofScript'],
  artifacts: finalArtifacts,
  c1CompilerSha256: firstArtifacts.javascriptSha256,
  c2CompilerSha256: finalArtifacts.javascriptSha256,
  c3CompilerSha256: finalArtifacts.javascriptSha256,
};
const inputs = { qualification, firstReceipt, secondReceipt, thirdReceipt, parentManifest: parent, runId: 12345 };
const manifest = makeSuccessorSeedManifest(inputs);
const identity = successorSeedIdentity(manifest);
assert.equal(JSON.stringify(parent), parentBefore, 'the historical parent is not mutated');
assert.deepEqual(manifest.parent.manifest, parent);
assert.notEqual(manifest.parent.manifest, parent, 'the descriptor owns its parent snapshot');
assert.notEqual(manifest.expectedFirstGenerationArtifacts.canonicalSurfaceSourceSha256,
  manifest.expectedArtifacts.canonicalSurfaceSourceSha256, 'C1 may retain the parent printer surface');
const route = successorSeedSelection(manifest);
assert.equal(route.recoveryTypeScriptVersion, '7.0.2');
assert.equal(route.parent.recoveryTypeScriptVersion, '5.8.3');
assert.equal(route.parent.identitySha256, qualifiedSeedIdentity(parent));
assert(route.cacheKey.startsWith('psc0-sh1-successor-v1-'));
assert.notEqual(route.cacheKey, route.parent.cacheKey);

const refusals = [];
function invalid(name, mutate, expected = { name: 'AssertionError' }) {
  const candidate = clone(manifest);
  mutate(candidate);
  assert.throws(() => validateSuccessorSeedManifest(candidate), expected, name);
  refusals.push(name);
}
invalid('parent remains v1 TS5', (value) => { value.parent.manifest.toolchain.typescript = 'Version 7.0.2'; });
invalid('successor requires TS7', (value) => { value.toolchain.typescript = 'Version 5.8.3'; });
invalid('parent identity cannot be substituted', (value) => { value.parent.identitySha256 = '0'.repeat(64); });
invalid('source cannot be its parent', (value) => { value.sourceRef = parent.sourceRef; });
invalid('runner must be the qualified source', (value) => { value.recovery.runnerSourceRef = '3'.repeat(40); });
invalid('recipe hash is checked', (value) => { value.recovery.runnerRecipe.sha256 = '0'.repeat(64); });
invalid('recipe must preserve successor runner support', (value) => {
  value.recovery.runnerRecipe.files = value.recovery.runnerRecipe.files
    .filter((file) => file.path !== 'scripts/sh1-successor-seed.mjs');
  value.recovery.runnerRecipe.sha256 = hash(JSON.stringify(value.recovery.runnerRecipe.files));
});
invalid('recipe paths stay inside the source checkout', (value) => {
  value.recovery.runnerRecipe.files[0].path = '../other/runner.mjs';
  value.recovery.runnerRecipe.sha256 = hash(JSON.stringify(value.recovery.runnerRecipe.files));
});
invalid('unknown products cannot escape identity binding', (value) => { value.expectedArtifacts.extra = '0'.repeat(64); });
invalid('no strict SH1 claim', (value) => { value.authoring.strictSh1Qualified = true; });
invalid('no full Standard claim', (value) => { value.authoring.syntax.fullStandardConformance = true; });
invalid('no full PSCV claim', (value) => { value.authoring.syntax.fullPscvConformance = true; });
invalid('no legacy PS grammar claim', (value) => { value.authoring.syntax.mode = 'dual'; });
invalid('qualification must bind final JS', (value) => { value.qualification.compilerSha256 = '0'.repeat(64); });

const olderQualification = clone(inputs);
delete olderQualification.qualification.sourceGrammar;
assert.throws(() => makeSuccessorSeedManifest(olderQualification), /PROMOTION_SOURCE_GRAMMAR/u);
const incompleteGrammar = clone(inputs);
incompleteGrammar.qualification.grammarGenerations = ['C1', 'C2'];
assert.throws(() => makeSuccessorSeedManifest(incompleteGrammar), /PROMOTION_GRAMMAR_GENERATIONS/u);
const incompleteProjection = clone(inputs);
incompleteProjection.qualification.projectionResolutionGenerations = ['C1', 'C3'];
assert.throws(() => makeSuccessorSeedManifest(incompleteProjection), /PROMOTION_PROJECTION_GENERATIONS/u);
const wrongExecutor = clone(inputs);
wrongExecutor.secondReceipt.executingCompilerSha256 = parent.expectedArtifacts.javascriptSha256;
assert.throws(() => makeSuccessorSeedManifest(wrongExecutor), /PROMOTION_SECOND_EXECUTOR/u);
const uncheckedSecond = clone(inputs);
uncheckedSecond.secondReceipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission = false;
assert.throws(() => makeSuccessorSeedManifest(uncheckedSecond), /PROMOTION_CHECKED_ORIGINAL_IR/u);
const splitSource = clone(inputs);
splitSource.thirdReceipt.sourceClosureSha256 = '4'.repeat(64);
assert.throws(() => makeSuccessorSeedManifest(splitSource), /PROMOTION_SOURCE_CLOSURE/u);

const linked = clone(manifest);
linked.qualification.runId = 99999;
linked.recoveryEvidence = {
  evidence: 'qualified-successor-cold-recovery',
  sourceRef, sourceClosureSha256, parentIdentitySha256: manifest.parent.identitySha256,
  compilerSha256: finalArtifacts.javascriptSha256,
  receiptSha256: hash('synthetic cold recovery receipt'),
  reference: 'docs/selfhost-language/successor-recovery.json',
  passed: true, coldSuccessorRecovery: true, runId: 22222,
};
linked.providerEvidence = {
  providerSourceRef: '5'.repeat(40), sourceRef,
  compilerSha256: finalArtifacts.javascriptSha256,
  receiptSha256: hash('synthetic provider receipt'),
  reference: 'docs/selfhost-language/successor-provider.json',
  accepted: true, runId: 33333,
};
assert.equal(successorSeedIdentity(linked), identity, 'evidence must not invalidate compiler caches');
const changedClosure = clone(manifest);
changedClosure.sourceClosureSha256 = '6'.repeat(64);
changedClosure.implementationBinding.sourceClosureSha256 = changedClosure.sourceClosureSha256;
assert.notEqual(successorSeedIdentity(changedClosure), identity, 'raw source belongs to identity');
const changedFirstSurface = clone(manifest);
changedFirstSurface.expectedFirstGenerationArtifacts.canonicalSurfaceSourceSha256 = '7'.repeat(64);
assert.notEqual(successorSeedIdentity(changedFirstSurface), identity, 'the recovery intermediate belongs to identity');
const changedRecipe = clone(manifest);
changedRecipe.recovery.runnerRecipe.files[0].sha256 = '8'.repeat(64);
changedRecipe.recovery.runnerRecipe.sha256 = hash(JSON.stringify(changedRecipe.recovery.runnerRecipe.files));
assert.notEqual(successorSeedIdentity(changedRecipe), identity, 'the pinned runner belongs to identity');

const temporary = await mkdtemp(path.join(tmpdir(), 'psc0-successor-contract-'));
try {
  const generationDirectory = path.join(temporary, 'generation');
  const cacheDirectory = path.join(temporary, 'cache');
  const manifestPath = path.join(temporary, 'selected.json');
  await mkdir(generationDirectory);
  for (const [file, contents] of Object.entries(products)) {
    await writeFile(path.join(generationDirectory, file), contents);
  }
  const materialize = () => materializeSuccessorSeed({
    generationDirectory, cacheDirectory, manifest, origin: 'Synthetic host contract fixture; not a compiler.',
  });
  assert.equal(await materialize(), identity);
  assert.equal(await verifySuccessorSeedCache(cacheDirectory, manifest), true);
  assert.equal(await verifyAuthoringSeedCache(cacheDirectory, linked), true);

  await writeFile(manifestPath, JSON.stringify(manifest));
  await assert.rejects(readSelectedAuthoringSeed(manifestPath), /SELECTION_REQUIRES_COLD_RECOVERY/u);
  await writeFile(manifestPath, JSON.stringify({ ...manifest, recoveryEvidence: linked.recoveryEvidence }));
  await assert.rejects(readSelectedAuthoringSeed(manifestPath), /SELECTION_REQUIRES_PROVIDER_ACCEPTANCE/u);
  await writeFile(manifestPath, JSON.stringify(linked));
  const selected = await readSelectedAuthoringSeed(manifestPath);
  assert.equal(selected.identitySha256, identity);
  assert.equal(selected.cacheKey, route.cacheKey);
  assert.equal(selected.parent.identitySha256, route.parent.identitySha256);
  await writeFile(manifestPath, JSON.stringify({ ...linked,
    recoveryEvidence: { ...linked.recoveryEvidence, coldSuccessorRecovery: false },
  }));
  await assert.rejects(readSelectedAuthoringSeed(manifestPath), /RECOVERY_EVIDENCE_COLD/u);

  await writeFile(path.join(cacheDirectory, 'index.js'), 'wrong executable bytes');
  assert.equal(await verifySuccessorSeedCache(cacheDirectory, manifest), false);
  await materialize();
  await rm(path.join(cacheDirectory, 'index.ts'));
  assert.equal(await verifySuccessorSeedCache(cacheDirectory, manifest), false);
  await materialize();
  const receiptPath = path.join(cacheDirectory, 'seed.json');
  const wrongReceipt = JSON.parse(await readFile(receiptPath, 'utf8'));
  wrongReceipt.identitySha256 = '9'.repeat(64);
  await writeFile(receiptPath, JSON.stringify(wrongReceipt));
  assert.equal(await verifySuccessorSeedCache(cacheDirectory, manifest), false);
  await materialize();

  await writeFile(path.join(generationDirectory, 'admissions.json'), 'tampered admission stream');
  await assert.rejects(materialize(), /CACHE_PRODUCT_admissions.json/u);
  assert.equal(await verifySuccessorSeedCache(cacheDirectory, manifest), true,
    'all generation products are authenticated before existing retained bytes are changed');

  await writeFile(manifestPath, JSON.stringify(parent));
  const originalSelection = await readSelectedSeed(manifestPath);
  const dispatchedSelection = await readSelectedAuthoringSeed(manifestPath);
  for (const [field, value] of Object.entries(originalSelection)) {
    assert.deepEqual(dispatchedSelection[field], value, 'v1 selection field ' + field);
  }
  assert.equal(dispatchedSelection.recoveryTypeScriptVersion, '5.8.3');
  const missing = await readSelectedAuthoringSeed(path.join(temporary, 'missing.json'));
  assert.equal(missing.mode, 'historical');
} finally {
  await rm(temporary, { recursive: true, force: true });
}
process.stdout.write('PSC0_SH1_SUCCESSOR_CONTRACT: PASS (' + refusals.length +
  ' descriptor refusals, generation ancestry, evidence-stable identity, gated selection, cache authentication, unchanged v1 routing)\n');
