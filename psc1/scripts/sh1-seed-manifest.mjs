import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const historicalSeedRef = '37f63c39d4a07189938046c64152bba25d789450';
const artifactFields = [
  ['canonical-source.json', 'canonicalSurfaceSourceSha256'],
  ['admissions.json', 'normalizedCanonicalAdmissionsSha256'],
  ['index.ts', 'typescriptSha256'],
  ['index.js', 'javascriptSha256'],
];
const hash = (bytes) => createHash('sha256').update(bytes).digest('hex');
const sha = (value) => typeof value === 'string' && /^[a-f0-9]{64}$/u.test(value);
const commit = (value) => typeof value === 'string' && /^[a-f0-9]{40}$/u.test(value);

function authoringDescriptor() {
  return {
    family: 'PSC0-SH/1',
    capabilities: [{
      id: 'recursion.varying-parameters',
      status: 'compiler-qualified',
      scope: 'Root constructor descent with ordinary nondependent changing value parameters.',
    }],
    normalizerVersion: 'psc0-structural-state-generalization/1',
    strictSh1Qualified: false,
  };
}

function implementationBinding(manifest) {
  return {
    sourceClosureSha256: manifest.sourceClosureSha256,
    generatedCompilerSha256: manifest.expectedArtifacts.javascriptSha256,
    scope: 'The exact source closure and generated JS bind the normalizer, prelude and runtime implementations.',
  };
}

export function validateQualifiedSeedManifest(manifest) {
  assert.equal(manifest?.schemaVersion, 1, 'PSC0_SH1_SEED_MANIFEST_VERSION');
  assert.equal(manifest?.kind, 'psc0-qualified-source-seed', 'PSC0_SH1_SEED_MANIFEST_KIND');
  assert(commit(manifest.sourceRef), 'PSC0_SH1_SEED_SOURCE_REF');
  assert(sha(manifest.sourceClosureSha256), 'PSC0_SH1_SEED_SOURCE_CLOSURE');
  assert.equal(manifest.bootstrap?.sourceRef, historicalSeedRef, 'PSC0_SH1_SEED_BOOTSTRAP_REF');
  assert(sha(manifest.bootstrap?.compilerSha256), 'PSC0_SH1_SEED_BOOTSTRAP_DIGEST');
  for (const [, field] of artifactFields) assert(sha(manifest.expectedArtifacts?.[field]),
    'PSC0_SH1_SEED_EXPECTED_ARTIFACT: ' + field);
  assert.equal(manifest.toolchain?.leanGitHash, '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
  assert.equal(manifest.toolchain?.typescript, 'Version 5.8.3');
  assert(/^v22\.\d+\.\d+$/u.test(manifest.toolchain?.node ?? ''), 'PSC0_SH1_SEED_NODE_PIN');
  assert.equal(manifest.toolchain?.platform, 'linux', 'PSC0_SH1_SEED_PLATFORM');
  assert.equal(manifest.toolchain?.architecture, 'x64', 'PSC0_SH1_SEED_ARCHITECTURE');
  assert(typeof manifest.toolchain?.lean === 'string' && manifest.toolchain.lean.length > 0);
  assert.equal(manifest.qualification?.evidence, 'compiler-qualified-current-source-fixed-point');
  assert.equal(manifest.qualification?.sourceRef, manifest.sourceRef);
  assert.equal(manifest.qualification?.compilerSha256, manifest.expectedArtifacts.javascriptSha256);
  assert.equal(manifest.recovery?.recipe, 'historical-seed(A); first-generation(A); compare-pinned-products/1');
  assert.deepEqual(manifest.authoring, authoringDescriptor(), 'PSC0_SH1_AUTHORING_DESCRIPTOR');
  assert.equal(manifest.target, 'original-ts-to-js', 'PSC0_SH1_TARGET');
  assert.deepEqual(manifest.implementationBinding, implementationBinding(manifest),
    'PSC0_SH1_PRELUDE_RUNTIME_BINDING');
  if (manifest.providerEvidence !== undefined) {
    assert(commit(manifest.providerEvidence.providerSourceRef), 'PSC0_SH1_PROVIDER_REFERENCE');
    assert(sha(manifest.providerEvidence.receiptSha256), 'PSC0_SH1_PROVIDER_RECEIPT');
    assert(typeof manifest.providerEvidence.reference === 'string' &&
      manifest.providerEvidence.reference.length > 0, 'PSC0_SH1_PROVIDER_EVIDENCE_REFERENCE');
  }
  if (manifest.qualification.runId !== undefined) {
    assert(Number.isSafeInteger(manifest.qualification.runId) && manifest.qualification.runId > 0);
    assert.equal(manifest.qualification.artifactName, 'psc0-sh1-' + manifest.sourceRef);
  }
  return manifest;
}

export function qualifiedSeedIdentity(manifest) {
  validateQualifiedSeedManifest(manifest);
  // Evidence links are provenance, not code-generation inputs. Changing a link
  // does not discard an otherwise identical, hash-verified compiler.
  return hash(JSON.stringify({
    schemaVersion: 1,
    kind: manifest.kind,
    sourceRef: manifest.sourceRef,
    sourceClosureSha256: manifest.sourceClosureSha256,
    bootstrap: {
      sourceRef: manifest.bootstrap.sourceRef,
      compilerSha256: manifest.bootstrap.compilerSha256,
    },
    expectedArtifacts: Object.fromEntries(artifactFields.map(([, field]) => [
      field, manifest.expectedArtifacts[field],
    ])),
    toolchain: Object.fromEntries(['node', 'platform', 'architecture', 'lean', 'leanGitHash', 'typescript']
      .map((field) => [field, manifest.toolchain[field]])),
    authoring: authoringDescriptor(),
    target: manifest.target,
    recovery: manifest.recovery.recipe,
  }));
}

export async function readSelectedSeed(manifestPath = path.join(root, 'selfhost-seed.json')) {
  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    return {
      mode: 'historical',
      nodeVersion: '22',
      sourceRef: historicalSeedRef,
      compilerPath: '.selfhost-seeds/' + historicalSeedRef + '/index.js',
      cacheKey: '',
      cacheDirectory: '',
      artifactRunId: '',
      artifactName: '',
    };
  }
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
  };
}

export function makeQualifiedSeedManifest({ qualification, firstReceipt, secondReceipt, runId }) {
  assert.equal(qualification.evidence, 'compiler-qualified-current-source-fixed-point');
  assert.equal(qualification.authoringSeed?.kind, 'historical-aggregate-implementation',
    'PSC0_SH1_PROMOTION_REQUIRES_HISTORICAL_RECOVERY_EDGE');
  assert.equal(qualification.authoringSeed.sourceRef, historicalSeedRef);
  assert.equal(firstReceipt.executingCompilerSha256, qualification.authoringSeed.compilerSha256);
  assert.equal(firstReceipt.sourceClosureSha256, qualification.sourceClosureSha256);
  assert.equal(secondReceipt.sourceClosureSha256, qualification.sourceClosureSha256);
  assert.deepEqual(secondReceipt.artifacts, qualification.artifacts);
  assert.equal(qualification.c2CompilerSha256, qualification.c3CompilerSha256);
  return validateQualifiedSeedManifest({
    schemaVersion: 1,
    kind: 'psc0-qualified-source-seed',
    sourceRef: qualification.sourceRef,
    sourceClosureSha256: qualification.sourceClosureSha256,
    bootstrap: {
      sourceRef: historicalSeedRef,
      compilerSha256: firstReceipt.executingCompilerSha256,
    },
    expectedArtifacts: qualification.artifacts,
    authoring: authoringDescriptor(),
    target: 'original-ts-to-js',
    implementationBinding: implementationBinding({
      sourceClosureSha256: qualification.sourceClosureSha256,
      expectedArtifacts: qualification.artifacts,
    }),
    toolchain: secondReceipt.toolchain,
    qualification: {
      evidence: qualification.evidence,
      sourceRef: qualification.sourceRef,
      compilerSha256: qualification.c2CompilerSha256,
      ...(runId ? {
        runId: Number(runId),
        artifactName: 'psc0-sh1-' + qualification.sourceRef,
      } : {}),
      claim: 'Compiler-qualified seed; selected-provider acceptance is a separate receipt.',
    },
    recovery: {
      recipe: 'historical-seed(A); first-generation(A); compare-pinned-products/1',
      sourceAuthority: 'Pinned raw A source, which was accepted by the historical generated seed.',
      promotion: 'Copy this file to psc0/selfhost-seed.json only after reviewing qualification evidence.',
    },
  });
}

export async function verifyQualifiedSeedCache(directory, manifest) {
  const identity = qualifiedSeedIdentity(manifest);
  try {
    const receipt = JSON.parse(await readFile(path.join(directory, 'seed.json'), 'utf8'));
    assert.equal(receipt.kind, 'psc0-qualified-seed-cache');
    assert.equal(receipt.identitySha256, identity);
    assert.equal(receipt.sourceRef, manifest.sourceRef);
    assert.equal(receipt.sourceClosureSha256, manifest.sourceClosureSha256);
    assert.deepEqual(receipt.expectedArtifacts, manifest.expectedArtifacts);
    assert.deepEqual(receipt.toolchain, manifest.toolchain);
    assert.equal(hash(await readFile(path.join(directory, 'index.js'))),
      manifest.expectedArtifacts.javascriptSha256);
    assert.equal(hash(await readFile(path.join(directory, 'index.ts'))),
      manifest.expectedArtifacts.typescriptSha256);
    return true;
  } catch {
    return false;
  }
}

export async function materializeQualifiedSeed({ generationDirectory, cacheDirectory, manifest, origin }) {
  const identitySha256 = qualifiedSeedIdentity(manifest);
  const contents = new Map();
  for (const [file, field] of artifactFields) {
    const bytes = await readFile(path.join(generationDirectory, file));
    assert.equal(hash(bytes), manifest.expectedArtifacts[field], 'PSC0_SH1_PROMOTED_PRODUCT: ' + file);
    contents.set(file, bytes);
  }
  await mkdir(cacheDirectory, { recursive: true });
  // The reusable seed needs executable bytes, its TS source and provenance.
  // Full canonical admissions remain in the qualification/recovery artifacts.
  await writeFile(path.join(cacheDirectory, 'index.js'), contents.get('index.js'));
  await writeFile(path.join(cacheDirectory, 'index.ts'), contents.get('index.ts'));
  await writeFile(path.join(cacheDirectory, 'seed.json'), JSON.stringify({
    schemaVersion: 1,
    kind: 'psc0-qualified-seed-cache',
    identitySha256,
    sourceRef: manifest.sourceRef,
    sourceClosureSha256: manifest.sourceClosureSha256,
    expectedArtifacts: manifest.expectedArtifacts,
    toolchain: manifest.toolchain,
    origin,
    qualification: manifest.qualification,
    kernelChecked: false,
  }, null, 2) + '\n');
  assert(await verifyQualifiedSeedCache(cacheDirectory, manifest), 'PSC0_SH1_PROMOTED_CACHE_INTEGRITY');
  return identitySha256;
}
