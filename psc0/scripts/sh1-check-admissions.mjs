import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { performance } from 'node:perf_hooks';
import { runCommand, sha256 } from './sh1-capabilities.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const providerRef = '963030dc2d154008fccc82e7c8ed29331f138799';
const args = process.argv.slice(2);
function argument(name, fallback) {
  const index = args.indexOf(name);
  if (index < 0) return fallback;
  assert(args[index + 1] && !args[index + 1].startsWith('--'), 'PSC0_SH1_PROVIDER_ARGUMENT');
  return args[index + 1];
}
const providerRoot = path.resolve(root, argument('--provider-root', '../provider-source/psc0'));
const artifactsRoot = path.resolve(root, argument('--artifacts', '../qualification-artifacts/dist/sh1'));
const capture = (command, commandArgs, cwd = providerRoot) =>
  runCommand(command, commandArgs, { cwd, stdio: 'pipe', encoding: 'utf8', timeout: 30000 }).stdout.trim();
assert.equal(capture('git', ['rev-parse', 'HEAD']), providerRef, 'PSC0_SH1_PROVIDER_REF');
assert.equal(capture('git', ['status', '--porcelain', '--untracked-files=no', '--', '.']), '',
  'PSC0_SH1_PROVIDER_TRACKED_SOURCE_CHANGED');
assert.equal(capture('lean', ['--githash']), '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  'PSC0_SH1_PROVIDER_LEAN_PIN');
const binaryPath = path.join(providerRoot, '.lake/build/bin/psc_kernel_core_provider');
const binarySha256 = sha256(await readFile(binaryPath));
const { checkCoreAdmissions } = await import(pathToFileURL(
  path.join(providerRoot, 'scripts/checked-kernel-core.mjs')).href);
const qualification = JSON.parse(await readFile(path.join(artifactsRoot, 'qualification.json')));
assert.equal(qualification.evidence, 'compiler-qualified-current-source-fixed-point');
assert.equal(qualification.c2CompilerSha256, qualification.c3CompilerSha256);
const streams = new Map();
async function addStream(relative, expectedSha256, label) {
  const source = await readFile(path.join(artifactsRoot, relative), 'utf8');
  const digest = sha256(source);
  assert.equal(digest, expectedSha256, 'PSC0_SH1_PROVIDER_ADMISSIONS_DIGEST: ' + relative);
  const prior = streams.get(digest);
  if (prior) {
    assert.equal(prior.source, source, 'PSC0_SH1_PROVIDER_DIGEST_COLLISION');
    prior.artifacts.push(label);
  } else streams.set(digest, { source, artifacts: [label] });
}
for (const generation of ['C2', 'C3']) {
  const receipt = JSON.parse(await readFile(path.join(artifactsRoot, generation, 'receipt.json')));
  assert.equal(receipt.sourceClosureSha256, qualification.sourceClosureSha256);
  assert.deepEqual(receipt.artifacts, qualification.artifacts);
  assert.equal(sha256(await readFile(path.join(artifactsRoot, generation, 'index.js'))),
    receipt.artifacts.javascriptSha256);
  assert.equal(sha256(await readFile(path.join(artifactsRoot, generation, 'index.ts'))),
    receipt.artifacts.typescriptSha256);
  await addStream(generation + '/admissions.json',
    receipt.artifacts.normalizedCanonicalAdmissionsSha256, generation + ' compiler source');
  const capabilities = JSON.parse(await readFile(
    path.join(artifactsRoot, generation, 'capabilities/receipt.json')));
  assert.equal(capabilities.compilerSha256, receipt.artifacts.javascriptSha256);
  assert.deepEqual(capabilities.sourceKinds.map((item) => item.sourceKind).sort(), ['lean', 'ps']);
  for (const capability of capabilities.sourceKinds) {
    assert(['lean', 'ps'].includes(capability.sourceKind));
    assert.equal(capability.behavior, 'pass');
    await addStream(generation + '/capabilities/' + capability.sourceKind + '/admissions.json',
      capability.admissionsSha256, generation + ' raw ' + capability.sourceKind + ' capability source');
  }
}
const receipt = {
  schemaVersion: 1,
  evidence: 'selected-provider-acceptance-for-qualified-compiler-admissions',
  sourceRef: qualification.sourceRef,
  sourceClosureSha256: qualification.sourceClosureSha256,
  compilerSha256: qualification.c2CompilerSha256,
  provider: {
    sourceRef: providerRef,
    sourceTree: capture('git', ['rev-parse', 'HEAD:psc0']),
    binarySha256,
    metadata: JSON.parse(capture(binaryPath, ['--version'])),
    lean: capture('lean', ['--version']),
    node: process.version,
    command: ['psc_kernel_core_provider', '--check'],
    resourcePolicy: 'Pinned compilerSelfHostResourcePolicy; default fuel 131072, unchanged.',
    timeoutMs: 60000,
  },
  streams: [],
  accepted: false,
  emissionWasGatedByThisCheck: false,
  qualificationBoundary: 'Compiler-only artifacts were generated first; promotion may use this additional exact-stream provider acceptance.',
};
const receiptPath = path.join(artifactsRoot, 'kernel-admissions.json');
try {
  for (const [canonicalAdmissionsSha256, stream] of streams) {
    const start = performance.now();
    const result = checkCoreAdmissions(stream.source, { binaryPath, timeoutMs: 60000 });
    receipt.streams.push({
      canonicalAdmissionsSha256,
      artifacts: stream.artifacts,
      durationMs: performance.now() - start,
      result,
    });
    await writeFile(receiptPath, JSON.stringify(receipt, null, 2) + '\n');
    assert.equal(result.accepted, true, 'PSC0_SH1_PROVIDER_REJECTED: ' + JSON.stringify(result));
  }
  assert.equal(sha256(await readFile(binaryPath)), binarySha256, 'PSC0_SH1_PROVIDER_BINARY_CHANGED');
  receipt.accepted = true;
} finally {
  await writeFile(receiptPath, JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_PROVIDER_ADMISSIONS: ' + JSON.stringify(receipt) + '\n');
}
