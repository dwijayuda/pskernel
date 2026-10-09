import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  validateQualifiedSeedManifest, qualifiedSeedIdentity,
  readSelectedSeed, verifyQualifiedSeedCache,
} from './sh1-seed-manifest.mjs';
import { sh1GrammarProfile } from './sh1-grammar-profile.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const successorSeedKind = 'psc0-qualified-successor-seed';
export const successorSeedRecoveryRecipe = 'qualified-parent-raw-two-generation/1';
export const successorSeedSyntaxReferenceSha256 = sh1GrammarProfile.referenceSha256;
const artifactFields = [
  ['canonical-source.json', 'canonicalSurfaceSourceSha256'],
  ['admissions.json', 'normalizedCanonicalAdmissionsSha256'],
  ['index.ts', 'typescriptSha256'],
  ['index.js', 'javascriptSha256'],
];
const artifactKeys = artifactFields.map(([, field]) => field);
const toolchainKeys = ['node', 'platform', 'architecture', 'lean', 'leanGitHash', 'typescript'];
const requiredRecipeFiles = [
  'scripts/sh1-qualify.mjs',
  'scripts/sh1-successor-seed.mjs',
  'scripts/sh1-seed-manifest.mjs',
  'scripts/sh1-source-snapshot.mjs',
  'scripts/sh1-capabilities.mjs',
  'scripts/sh1-grammar-conformance.mjs',
  'scripts/sh1-projection-conformance.mjs',
  'scripts/typescript-cli.mjs',
];
const hash = (bytes) => createHash('sha256').update(bytes).digest('hex');
const sha = (value) => typeof value === 'string' && /^[a-f0-9]{64}$/u.test(value);
const commit = (value) => typeof value === 'string' && /^[a-f0-9]{40}$/u.test(value);
const clone = (value) => JSON.parse(JSON.stringify(value));
const label = (suffix) => 'PSC0_SH1_SUCCESSOR_' + suffix;

function keys(value, required, optional = [], suffix = 'OBJECT_KEYS') {
  assert(value !== null && typeof value === 'object' && !Array.isArray(value), label(suffix));
  const actual = Object.keys(value);
  for (const key of required) assert(Object.hasOwn(value, key), label(suffix + '_MISSING_' + key));
  for (const key of actual) assert(required.includes(key) || optional.includes(key),
    label(suffix + '_UNKNOWN_' + key));
}

function safeRelativePath(value) {
  return typeof value === 'string' && value.length > 0 && !value.includes('\\') &&
    !value.includes('\0') && !value.includes(':') && !value.startsWith('/') &&
    value.split('/').every((part) => part.length > 0 && part !== '.' && part !== '..');
}

function artifacts(value, suffix) {
  keys(value, artifactKeys, [], suffix);
  for (const field of artifactKeys) assert(sha(value[field]), label(suffix + '_' + field));
}

function orderedArtifacts(value) {
  return Object.fromEntries(artifactKeys.map((field) => [field, value[field]]));
}

function runtime(toolchain) {
  return Object.fromEntries(toolchainKeys.filter((field) => field !== 'typescript')
    .map((field) => [field, toolchain[field]]));
}

function validateRecipe(recipe) {
  keys(recipe, ['files', 'sha256'], [], 'RECIPE_KEYS');
  assert(Array.isArray(recipe.files) && recipe.files.length > 0, label('RECIPE_FILES'));
  const paths = new Set();
  for (const file of recipe.files) {
    keys(file, ['path', 'sha256'], [], 'RECIPE_FILE_KEYS');
    assert(safeRelativePath(file.path), label('RECIPE_PATH'));
    assert(!paths.has(file.path), label('RECIPE_DUPLICATE_PATH'));
    paths.add(file.path);
    assert(sha(file.sha256), label('RECIPE_FILE_DIGEST'));
  }
  for (const file of requiredRecipeFiles) assert(paths.has(file), label('RECIPE_REQUIRED_FILE_' + file));
  assert(sha(recipe.sha256), label('RECIPE_DIGEST'));
  assert.equal(recipe.sha256, hash(JSON.stringify(recipe.files)), label('RECIPE_IDENTITY'));
}

function authoringDescriptor() {
  return {
    family: 'PSC0-SH/1',
    capabilities: [
      {
        id: 'recursion.varying-parameters',
        status: 'compiler-qualified',
        scope: 'Root constructor descent with ordinary nondependent changing value parameters.',
      },
      {
        id: 'recursion.parameter-projection',
        status: 'compiler-qualified',
        scope: 'Bounded exact-name and local-prefix resolution with parameter-identity projection rewriting.',
      },
      {
        id: 'syntax.ps-0.9-r3-subset',
        status: 'compiler-qualified',
        scope: 'The implemented new-only ps-0.9-r3 syntax subset, with unsupported forms refused.',
      },
    ],
    normalizerVersion: 'psc0-structural-state-generalization/1',
    syntax: clone(sh1GrammarProfile),
    strictSh1Qualified: false,
  };
}

function implementationBinding(manifest) {
  return {
    sourceClosureSha256: manifest.sourceClosureSha256,
    generatedCompilerSha256: manifest.expectedArtifacts.javascriptSha256,
    scope: 'The exact source closure and generated JS bind parser, printer, normalizer, prelude and runtime implementations.',
  };
}

function evidenceReference(evidence, suffix) {
  assert(sha(evidence.receiptSha256), label(suffix + '_RECEIPT'));
  assert(safeRelativePath(evidence.reference), label(suffix + '_REFERENCE'));
  if (evidence.runId !== undefined) {
    assert(Number.isSafeInteger(evidence.runId) && evidence.runId > 0, label(suffix + '_RUN'));
  }
}

// This is a new schema. The historical v1 validator and identity are imported
// unchanged and remain the authority for the embedded parent A.
export function validateSuccessorSeedManifest(manifest) {
  keys(manifest, [
    'schemaVersion', 'kind', 'sourceRef', 'sourceClosureSha256', 'parent',
    'expectedFirstGenerationArtifacts', 'expectedArtifacts', 'authoring', 'target',
    'implementationBinding', 'toolchain', 'qualification', 'recovery',
  ], ['recoveryEvidence', 'providerEvidence'], 'MANIFEST_KEYS');
  assert.equal(manifest.schemaVersion, 1, label('MANIFEST_VERSION'));
  assert.equal(manifest.kind, successorSeedKind, label('MANIFEST_KIND'));
  assert(commit(manifest.sourceRef), label('SOURCE_REF'));
  assert(sha(manifest.sourceClosureSha256), label('SOURCE_CLOSURE'));
  keys(manifest.parent, ['manifest', 'identitySha256'], [], 'PARENT_KEYS');
  validateQualifiedSeedManifest(manifest.parent.manifest);
  assert.equal(manifest.parent.identitySha256, qualifiedSeedIdentity(manifest.parent.manifest),
    label('PARENT_IDENTITY'));
  assert.notEqual(manifest.sourceRef, manifest.parent.manifest.sourceRef, label('PARENT_SOURCE_CYCLE'));
  artifacts(manifest.expectedFirstGenerationArtifacts, 'FIRST_PRODUCTS');
  artifacts(manifest.expectedArtifacts, 'FINAL_PRODUCTS');
  assert.deepEqual(manifest.authoring, authoringDescriptor(), label('AUTHORING_DESCRIPTOR'));
  assert.equal(manifest.target, 'original-ts-to-js', label('TARGET'));
  assert.deepEqual(manifest.implementationBinding, implementationBinding(manifest),
    label('IMPLEMENTATION_BINDING'));

  keys(manifest.toolchain, toolchainKeys, [], 'TOOLCHAIN_KEYS');
  assert.equal(manifest.toolchain.typescript, 'Version 7.0.2', label('TYPESCRIPT_PIN'));
  assert.deepEqual(runtime(manifest.toolchain), runtime(manifest.parent.manifest.toolchain),
    label('PARENT_EXECUTION_RUNTIME'));
  keys(manifest.recovery, ['recipe', 'runnerSourceRef', 'runnerRecipe', 'sourceKind'], [], 'RECOVERY_KEYS');
  assert.equal(manifest.recovery.recipe, successorSeedRecoveryRecipe, label('RECOVERY_RECIPE'));
  assert.equal(manifest.recovery.runnerSourceRef, manifest.sourceRef, label('RUNNER_SOURCE_REF'));
  assert.equal(manifest.recovery.sourceKind, 'raw-authoritative-lean', label('RECOVERY_SOURCE_KIND'));
  validateRecipe(manifest.recovery.runnerRecipe);

  keys(manifest.qualification, [
    'evidence', 'sourceRef', 'compilerSha256', 'c1CompilerSha256', 'c2CompilerSha256',
    'c3CompilerSha256', 'claim',
  ], ['runId', 'artifactName'], 'QUALIFICATION_KEYS');
  assert.equal(manifest.qualification.evidence, 'compiler-qualified-current-source-fixed-point',
    label('QUALIFICATION_KIND'));
  assert.equal(manifest.qualification.sourceRef, manifest.sourceRef, label('QUALIFICATION_SOURCE'));
  assert.equal(manifest.qualification.compilerSha256, manifest.expectedArtifacts.javascriptSha256,
    label('QUALIFICATION_COMPILER'));
  assert.equal(manifest.qualification.c1CompilerSha256,
    manifest.expectedFirstGenerationArtifacts.javascriptSha256, label('QUALIFICATION_C1'));
  assert.equal(manifest.qualification.c2CompilerSha256, manifest.expectedArtifacts.javascriptSha256,
    label('QUALIFICATION_C2'));
  assert.equal(manifest.qualification.c3CompilerSha256, manifest.expectedArtifacts.javascriptSha256,
    label('QUALIFICATION_C3'));
  assert.equal(manifest.qualification.claim,
    'Compiler-qualified successor; cold recovery and selected-provider acceptance are separate evidence.',
    label('QUALIFICATION_CLAIM'));
  if (manifest.qualification.runId !== undefined) {
    assert(Number.isSafeInteger(manifest.qualification.runId) && manifest.qualification.runId > 0,
      label('QUALIFICATION_RUN'));
    assert.equal(manifest.qualification.artifactName, 'psc0-sh1-ts7.0.2-' + manifest.sourceRef,
      label('QUALIFICATION_ARTIFACT'));
  } else {
    assert.equal(manifest.qualification.artifactName, undefined, label('QUALIFICATION_ARTIFACT_WITHOUT_RUN'));
  }

  if (manifest.recoveryEvidence !== undefined) {
    const evidence = manifest.recoveryEvidence;
    keys(evidence, [
      'evidence', 'sourceRef', 'sourceClosureSha256', 'parentIdentitySha256',
      'compilerSha256', 'receiptSha256', 'reference', 'passed', 'coldSuccessorRecovery',
    ], ['runId'], 'RECOVERY_EVIDENCE_KEYS');
    assert.equal(evidence.evidence, 'qualified-successor-cold-recovery', label('RECOVERY_EVIDENCE_KIND'));
    assert.equal(evidence.sourceRef, manifest.sourceRef, label('RECOVERY_EVIDENCE_SOURCE'));
    assert.equal(evidence.sourceClosureSha256, manifest.sourceClosureSha256,
      label('RECOVERY_EVIDENCE_CLOSURE'));
    assert.equal(evidence.parentIdentitySha256, manifest.parent.identitySha256,
      label('RECOVERY_EVIDENCE_PARENT'));
    assert.equal(evidence.compilerSha256, manifest.expectedArtifacts.javascriptSha256,
      label('RECOVERY_EVIDENCE_COMPILER'));
    assert.equal(evidence.passed, true, label('RECOVERY_EVIDENCE_PASS'));
    assert.equal(evidence.coldSuccessorRecovery, true, label('RECOVERY_EVIDENCE_COLD'));
    evidenceReference(evidence, 'RECOVERY_EVIDENCE');
  }
  if (manifest.providerEvidence !== undefined) {
    const evidence = manifest.providerEvidence;
    keys(evidence, [
      'providerSourceRef', 'sourceRef', 'compilerSha256', 'receiptSha256', 'reference', 'accepted',
    ], ['runId'], 'PROVIDER_EVIDENCE_KEYS');
    assert(commit(evidence.providerSourceRef), label('PROVIDER_SOURCE_REF'));
    assert.equal(evidence.sourceRef, manifest.sourceRef, label('PROVIDER_EVIDENCE_SOURCE'));
    assert.equal(evidence.compilerSha256, manifest.expectedArtifacts.javascriptSha256,
      label('PROVIDER_EVIDENCE_COMPILER'));
    assert.equal(evidence.accepted, true, label('PROVIDER_EVIDENCE_ACCEPTED'));
    evidenceReference(evidence, 'PROVIDER_EVIDENCE');
  }
  return manifest;
}

export function successorSeedIdentity(manifest) {
  validateSuccessorSeedManifest(manifest);
  // Links and gate receipts are provenance. Adding verified cold-recovery or
  // provider evidence must not change the identity of the compiler bytes.
  return hash(JSON.stringify({
    schemaVersion: 1,
    kind: successorSeedKind,
    sourceRef: manifest.sourceRef,
    sourceClosureSha256: manifest.sourceClosureSha256,
    parentIdentitySha256: manifest.parent.identitySha256,
    expectedFirstGenerationArtifacts: orderedArtifacts(manifest.expectedFirstGenerationArtifacts),
    expectedArtifacts: orderedArtifacts(manifest.expectedArtifacts),
    toolchain: Object.fromEntries(toolchainKeys.map((field) => [field, manifest.toolchain[field]])),
    authoring: authoringDescriptor(),
    target: manifest.target,
    recovery: {
      recipe: manifest.recovery.recipe,
      runnerSourceRef: manifest.recovery.runnerSourceRef,
      runnerRecipe: manifest.recovery.runnerRecipe,
      sourceKind: manifest.recovery.sourceKind,
    },
  }));
}

function legacySelection(manifest) {
  validateQualifiedSeedManifest(manifest);
  const identitySha256 = qualifiedSeedIdentity(manifest);
  const directory = '.selfhost-seeds/qualified/' + identitySha256;
  return {
    mode: 'qualified',
    nodeVersion: manifest.toolchain.node.slice(1),
    sourceRef: manifest.sourceRef,
    compilerPath: directory + '/index.js',
    cacheKey: 'psc0-sh1-qualified-v1-' + identitySha256,
    cacheDirectory: directory,
    artifactRunId: manifest.qualification.runId ?? '',
    artifactName: manifest.qualification.artifactName ?? '',
    identitySha256,
    manifest,
    recoveryKind: manifest.recovery.recipe,
    recoveryTypeScriptVersion: '5.8.3',
    parent: null,
  };
}

// Pure routing for an unselected provisional successor. This does not require
// the two later gate receipts and never reads or writes the selected manifest.
export function successorSeedSelection(manifest) {
  const identitySha256 = successorSeedIdentity(manifest);
  const directory = '.selfhost-seeds/successors/' + identitySha256;
  return {
    mode: 'qualified',
    nodeVersion: manifest.toolchain.node.slice(1),
    sourceRef: manifest.sourceRef,
    compilerPath: directory + '/index.js',
    cacheKey: 'psc0-sh1-successor-v1-' + identitySha256,
    cacheDirectory: directory,
    artifactRunId: manifest.qualification.runId ?? '',
    artifactName: manifest.qualification.artifactName ?? '',
    identitySha256,
    manifest,
    recoveryKind: successorSeedRecoveryRecipe,
    recoveryTypeScriptVersion: '7.0.2',
    parent: legacySelection(manifest.parent.manifest),
  };
}

export async function readSelectedAuthoringSeed(manifestPath = path.join(root, 'selfhost-seed.json')) {
  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    const selected = await readSelectedSeed(manifestPath);
    return {
      ...selected, recoveryKind: 'psc0-native-recovery/1',
      recoveryTypeScriptVersion: '5.8.3', parent: null,
    };
  }
  if (manifest.kind === 'psc0-qualified-source-seed') {
    const selected = await readSelectedSeed(manifestPath);
    return {
      ...selected, recoveryKind: selected.manifest.recovery.recipe,
      recoveryTypeScriptVersion: '5.8.3', parent: null,
    };
  }
  validateSuccessorSeedManifest(manifest);
  assert(manifest.recoveryEvidence !== undefined, label('SELECTION_REQUIRES_COLD_RECOVERY'));
  assert(manifest.providerEvidence !== undefined, label('SELECTION_REQUIRES_PROVIDER_ACCEPTANCE'));
  return successorSeedSelection(manifest);
}

export function makeSuccessorSeedManifest({
  qualification, firstReceipt, secondReceipt, thirdReceipt, parentManifest, runId,
  syntaxReferenceSha256 = successorSeedSyntaxReferenceSha256,
}) {
  validateQualifiedSeedManifest(parentManifest);
  const parentIdentitySha256 = qualifiedSeedIdentity(parentManifest);
  assert.equal(syntaxReferenceSha256, successorSeedSyntaxReferenceSha256, label('SYNTAX_REFERENCE'));
  assert.equal(qualification.evidence, 'compiler-qualified-current-source-fixed-point',
    label('PROMOTION_QUALIFICATION'));
  assert.equal(qualification.rawAuthoringSourceConsumedEveryGeneration, true,
    label('PROMOTION_RAW_SOURCE'));
  assert.deepEqual(qualification.sourceGrammar, sh1GrammarProfile, label('PROMOTION_SOURCE_GRAMMAR'));
  assert.deepEqual(qualification.grammarGenerations, ['C1', 'C2', 'C3'],
    label('PROMOTION_GRAMMAR_GENERATIONS'));
  assert.deepEqual(qualification.projectionResolutionGenerations, ['C1', 'C2', 'C3'],
    label('PROMOTION_PROJECTION_GENERATIONS'));
  assert.deepEqual(qualification.rawCapabilityKinds, ['lean', 'proofScript'],
    label('PROMOTION_CAPABILITY_KINDS'));
  assert.equal(qualification.authoringSeed?.kind, 'previous-qualified-authoring-seed',
    label('PROMOTION_PARENT_KIND'));
  assert.equal(qualification.authoringSeed.sourceRef, parentManifest.sourceRef, label('PROMOTION_PARENT_REF'));
  assert.equal(qualification.authoringSeed.sourceClosureSha256, parentManifest.sourceClosureSha256,
    label('PROMOTION_PARENT_CLOSURE'));
  assert.equal(qualification.authoringSeed.identitySha256, parentIdentitySha256, label('PROMOTION_PARENT_IDENTITY'));
  assert.equal(qualification.authoringSeed.compilerSha256, parentManifest.expectedArtifacts.javascriptSha256,
    label('PROMOTION_PARENT_COMPILER'));
  assert.deepEqual(qualification.authoringSeed.producerToolchain, parentManifest.toolchain,
    label('PROMOTION_PARENT_TOOLCHAIN'));
  assert.deepEqual(firstReceipt.authoringSeed, qualification.authoringSeed, label('PROMOTION_PARENT_PROVENANCE'));
  assert.equal(firstReceipt.executingCompilerSha256, parentManifest.expectedArtifacts.javascriptSha256,
    label('PROMOTION_FIRST_EXECUTOR'));
  assert.equal(secondReceipt.executingCompilerSha256, firstReceipt.artifacts.javascriptSha256,
    label('PROMOTION_SECOND_EXECUTOR'));
  assert.equal(thirdReceipt.executingCompilerSha256, secondReceipt.artifacts.javascriptSha256,
    label('PROMOTION_THIRD_EXECUTOR'));
  for (const receipt of [firstReceipt, secondReceipt, thirdReceipt]) {
    assert.equal(receipt.evidence, 'candidate-build', label('PROMOTION_GENERATION_KIND'));
    assert.equal(receipt.sourceRef, qualification.sourceRef, label('PROMOTION_SOURCE_REF'));
    assert.equal(receipt.sourceClosureSha256, qualification.sourceClosureSha256, label('PROMOTION_SOURCE_CLOSURE'));
    assert.equal(receipt.sourceKind, 'raw-authoritative-lean', label('PROMOTION_SOURCE_KIND'));
    assert.deepEqual(receipt.toolchain, qualification.toolchain, label('PROMOTION_TOOLCHAIN'));
    assert.deepEqual(receipt.recipe, firstReceipt.recipe, label('PROMOTION_RECIPE'));
  }
  for (const receipt of [secondReceipt, thirdReceipt]) {
    assert.deepEqual(receipt.artifacts, qualification.artifacts, label('PROMOTION_FIXED_POINT_PRODUCTS'));
    assert.equal(receipt.originalIrInventory?.traversalComplete, true, label('PROMOTION_IR_TRAVERSAL'));
    assert.equal(receipt.originalIrInventory.runtimeIrTypingAccepted, true, label('PROMOTION_IR_TYPING'));
    assert.equal(receipt.originalIrInventory.sameOriginalIrCheckedBeforeEmission, true,
      label('PROMOTION_CHECKED_ORIGINAL_IR'));
  }
  assert.equal(qualification.c1CompilerSha256, firstReceipt.artifacts.javascriptSha256, label('PROMOTION_C1'));
  assert.equal(qualification.c2CompilerSha256, secondReceipt.artifacts.javascriptSha256, label('PROMOTION_C2'));
  assert.equal(qualification.c3CompilerSha256, thirdReceipt.artifacts.javascriptSha256, label('PROMOTION_C3'));
  const expectedArtifacts = orderedArtifacts(qualification.artifacts);
  const manifest = {
    schemaVersion: 1,
    kind: successorSeedKind,
    sourceRef: qualification.sourceRef,
    sourceClosureSha256: qualification.sourceClosureSha256,
    parent: { manifest: clone(parentManifest), identitySha256: parentIdentitySha256 },
    expectedFirstGenerationArtifacts: orderedArtifacts(firstReceipt.artifacts),
    expectedArtifacts,
    authoring: authoringDescriptor(),
    target: 'original-ts-to-js',
    implementationBinding: implementationBinding({
      sourceClosureSha256: qualification.sourceClosureSha256, expectedArtifacts,
    }),
    toolchain: clone(qualification.toolchain),
    qualification: {
      evidence: qualification.evidence,
      sourceRef: qualification.sourceRef,
      compilerSha256: qualification.c2CompilerSha256,
      c1CompilerSha256: qualification.c1CompilerSha256,
      c2CompilerSha256: qualification.c2CompilerSha256,
      c3CompilerSha256: qualification.c3CompilerSha256,
      ...(runId === undefined || runId === '' ? {} : {
        runId: Number(runId), artifactName: 'psc0-sh1-ts7.0.2-' + qualification.sourceRef,
      }),
      claim: 'Compiler-qualified successor; cold recovery and selected-provider acceptance are separate evidence.',
    },
    recovery: {
      recipe: successorSeedRecoveryRecipe,
      runnerSourceRef: qualification.sourceRef,
      runnerRecipe: clone(firstReceipt.recipe),
      sourceKind: 'raw-authoritative-lean',
    },
  };
  return validateSuccessorSeedManifest(manifest);
}

export async function verifySuccessorSeedCache(directory, manifest) {
  const identitySha256 = successorSeedIdentity(manifest);
  try {
    const receipt = JSON.parse(await readFile(path.join(directory, 'seed.json'), 'utf8'));
    keys(receipt, ['schemaVersion', 'kind', 'identitySha256', 'manifest', 'origin', 'kernelChecked'],
      [], 'CACHE_KEYS');
    assert.equal(receipt.schemaVersion, 1);
    assert.equal(receipt.kind, 'psc0-successor-seed-cache');
    assert.equal(receipt.identitySha256, identitySha256);
    assert.equal(successorSeedIdentity(receipt.manifest), identitySha256);
    assert.equal(receipt.kernelChecked, false);
    assert(typeof receipt.origin === 'string' && receipt.origin.length > 0);
    assert.equal(hash(await readFile(path.join(directory, 'index.js'))), manifest.expectedArtifacts.javascriptSha256);
    assert.equal(hash(await readFile(path.join(directory, 'index.ts'))), manifest.expectedArtifacts.typescriptSha256);
    return true;
  } catch {
    return false;
  }
}

export async function verifyAuthoringSeedCache(directory, manifest) {
  if (manifest?.kind === 'psc0-qualified-source-seed') {
    return verifyQualifiedSeedCache(directory, manifest);
  }
  return verifySuccessorSeedCache(directory, manifest);
}

export async function materializeSuccessorSeed({ generationDirectory, cacheDirectory, manifest, origin }) {
  const identitySha256 = successorSeedIdentity(manifest);
  assert(typeof origin === 'string' && origin.length > 0, label('CACHE_ORIGIN'));
  const contents = new Map();
  for (const [file, field] of artifactFields) {
    const bytes = await readFile(path.join(generationDirectory, file));
    assert.equal(hash(bytes), manifest.expectedArtifacts[field], label('CACHE_PRODUCT_' + file));
    contents.set(file, bytes);
  }
  await mkdir(cacheDirectory, { recursive: true });
  // Authenticate all four generation products before retaining executable bytes.
  // The receipt is written last; incomplete or mixed caches fail verification.
  await writeFile(path.join(cacheDirectory, 'index.js'), contents.get('index.js'));
  await writeFile(path.join(cacheDirectory, 'index.ts'), contents.get('index.ts'));
  await writeFile(path.join(cacheDirectory, 'seed.json'), JSON.stringify({
    schemaVersion: 1,
    kind: 'psc0-successor-seed-cache',
    identitySha256,
    manifest,
    origin,
    kernelChecked: false,
  }, null, 2) + '\n');
  assert(await verifySuccessorSeedCache(cacheDirectory, manifest), label('CACHE_INTEGRITY'));
  return identitySha256;
}
