// CI evidence only. Not imported by psc, and never a kernel/checking authority.
// A signature authenticates this report's workflow origin, not its truth or
// compiler semantics. Keep inherited runtime source distinct from current host.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { open, lstat, readdir, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
export const repository = 'dwijayuda/pskernel';
export const branchRef = 'refs/heads/psc0/npm-modular-packages-v1';
export const workflow = repository + '/.github/workflows/psc0-checked-host.yml';
export const expectedTests = 100; // 85 retained tests + 15 evidence-boundary tests.
export const platforms = Object.freeze({ Linux: { node: 'v22.23.3', platform: 'linux', job: 'host (ubuntu-latest, 22.23.3)' }, Windows: { node: 'v26.7.0', platform: 'win32', job: 'host (windows-latest, 26.7.0)' } });
export const retained = Object.freeze({ source: '2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a', runId: 38075437516, compilerSha256: '6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3', kernelSha256: 'c3912cdbc078d8a56736ef2790221567f2fab8b129a0a26e80b437b79f95ba27', qualifiedCompilerSource: '1fa5559a72b293defc56ef7e7020cf82d4b44b79', sourceInventorySha256: 'fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de' });
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const json = bytes => JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
const encoded = value => Buffer.from(JSON.stringify(value, null, 2) + '\n');
const yes = names => Object.fromEntries(names.split(' ').map(name => [name, true]));
const reportNames = ['source-preservation.json', ...['ps', 'lean'].flatMap(v => ['repack', 'installed', 'frontend', 'target', 'library'].map(n => n + '-' + v + '.json')), 'host-tests.tap'].sort();
function match(actual, expected, label) {
  if (expected && typeof expected === 'object' && !Array.isArray(expected)) {
    assert(actual && typeof actual === 'object' && !Array.isArray(actual), 'PSC_EVIDENCE_OBJECT: ' + label);
    for (const [key, value] of Object.entries(expected)) match(actual[key], value, label + '.' + key);
  } else assert.deepEqual(actual, expected, 'PSC_EVIDENCE_VALUE: ' + label);
}
export function contextFromEnv(env) {
  assert.equal(env.GITHUB_REPOSITORY, repository, 'PSC_EVIDENCE_REPOSITORY');
  assert.equal(env.GITHUB_REF, branchRef, 'PSC_EVIDENCE_REF');
  assert.equal(env.GITHUB_WORKFLOW_REF, workflow + '@' + branchRef, 'PSC_EVIDENCE_WORKFLOW');
  assert.match(env.GITHUB_SHA || '', /^[0-9a-f]{40}$/u, 'PSC_EVIDENCE_SOURCE');
  for (const key of ['GITHUB_RUN_ID', 'GITHUB_RUN_ATTEMPT']) assert(/^[1-9][0-9]*$/u.test(env[key] || '') && Number.isSafeInteger(Number(env[key])), 'PSC_EVIDENCE_RUN');
  return { repository, ref: branchRef, workflow, source: env.GITHUB_SHA, runId: Number(env.GITHUB_RUN_ID), runAttempt: Number(env.GITHUB_RUN_ATTEMPT) };
}
export function reportContracts(source, platform) {
  const info = platforms[platform]; assert(info, 'PSC_EVIDENCE_PLATFORM');
  const reports = { 'source-preservation.json': { schema: 'psc0-host-change-selfhost-preservation/1', source, qualifiedCompilerSource: retained.qualifiedCompilerSource, reusedRuntimeSource: retained.source, grammar: 'ps-0.9-r3/new-only', sourceFiles: 69, closureModules: 64, sourceInventorySha256: retained.sourceInventorySha256, ...yes('compilerSourceUnchanged compilerQualificationInherited kernelSourceUnchanged'), expensiveFixedPointExecuted: false, newInstalledFixedPointClaimed: false } };
  for (const variant of ['ps', 'lean']) {
    const base = { source, variant }, installed = { ...base, node: info.node, platform: info.platform }, noGeneration = { compilerRegenerated: false, kernelRegenerated: false, fullFixedPointExecuted: false };
    reports['repack-' + variant + '.json'] = { ...base, schema: 'psc0-reused-runtime-candidate/1', retainedRuntimeSource: retained.source, retainedRuntimeRun: retained.runId, compilerSha256: retained.compilerSha256, kernelSha256: retained.kernelSha256, compilerRegenerated: false, kernelRegenerated: false, newFixedPointClaimed: false, hostRepacked: true };
    reports['installed-' + variant + '.json'] = { ...installed, packageScope: 13, installedCompilerClosureModules: 64, checkedSourceModules: 2, kernelProvider: 'psc0-generated-js-core', ...yes('installedCompilerClosureParsed importedSourceLibrary acceptedGraphBound immutableGeneration previousOutputSurvivesRefusal unexpectedFlagsRefused'), fullFixedPointExecuted: false };
    reports['frontend-' + variant + '.json'] = { ...installed, ...noGeneration, schema: 'psc0-frontend-resource-qualification/1', selectedKernelCalls: 1, ...yes('realOwnedChild directAdmissionsEqual directTypeScriptEqual copiedHandleRefused closedHandleRefused installedTimeoutRefused timeoutPreservesExistingOutput explicitResourceLimitChecked') };
    reports['target-' + variant + '.json'] = { ...installed, ...noGeneration, schema: 'psc0-target-installed-qualification/1', toolchain: { schema: 'psc0-typescript-target/1', version: '7.0.2', platform: info.platform, arch: 'x64', registryAuthenticityVerified: false }, originalLauncherProductsEqual: ['ts', 'js', 'd.ts', 'js.map'], ...yes('actualCompilerEmittedFixture pinnedDefaultExcludesAmbientTypes explicitForeignTypeControlRejected surroundingProjectConfigIgnored freshTargetProductsRequired ambientTypesExcludedFromOwnedTarget planBoundToCheckedHandle nativeDriftRefusesPublication previousExecutablePreserved libraryDriftRefused toolchainBytesRestored') };
    reports['library-' + variant + '.json'] = { ...installed, ...noGeneration, schema: 'psc0-library-disclosure-qualification/1', ...yes('receiptAndCheckedBindingAgree sourceAndManifestRawHashesMatch canonicalAdmissionsUnchanged jsonStdoutPreserved hostStderrDisclosureUnsuppressibleByPackageMetadata packageEntrypointNotExecuted declaredScriptsNotExecutedByCompiler invalidLibraryRefused executableExtensionRequestRefused previousExecutablePreserved fixturesRestored') };
  }
  return reports;
}
export function platformEnvelope(files, context, platform) {
  assert.deepEqual(Object.keys(files).sort(), reportNames, 'PSC_EVIDENCE_FILE_SET');
  const contracts = reportContracts(context.source, platform), hashes = [];
  let total = 0;
  for (const name of reportNames) {
    const bytes = files[name]; assert(Buffer.isBuffer(bytes) && bytes.length <= 1024 * 1024, 'PSC_EVIDENCE_FILE_LIMIT');
    total += bytes.length; assert(total <= 4 * 1024 * 1024, 'PSC_EVIDENCE_TOTAL_LIMIT');
    hashes.push({ name, bytes: bytes.length, sha256: digest(bytes) });
    if (name.endsWith('.json')) match(json(bytes), contracts[name], name);
  }
  const tap = new TextDecoder('utf-8', { fatal: true }).decode(files['host-tests.tap']).replaceAll('\r\n', '\n');
  for (const [key, value] of Object.entries({ tests: expectedTests, pass: expectedTests, fail: 0, cancelled: 0, skipped: 0, todo: 0 })) {
    const entries = [...tap.matchAll(new RegExp('^# ' + key + ' ([0-9]+)$', 'gm'))];
    assert.equal(entries.length, 1, 'PSC_EVIDENCE_TAP_SUMMARY'); assert.equal(Number(entries[0][1]), value, 'PSC_EVIDENCE_TAP_RESULT');
  }
  assert.equal([...tap.matchAll(/^1\.\.[0-9]+$/gm)].map(m => m[0]).join(), '1..' + expectedTests, 'PSC_EVIDENCE_TAP_PLAN');
  assert.equal([...tap.matchAll(/^ok [0-9]+ - /gm)].length, expectedTests, 'PSC_EVIDENCE_TAP_CASES');
  assert(!/^not ok |^Bail out!|^ok .*# (?:SKIP|TODO)/gmi.test(tap), 'PSC_EVIDENCE_TAP_REFUSED');
  return { schema: 'psc0-ci-platform-envelope/1', ...context, platform, node: platforms[platform].node, hostTests: expectedTests, reports: hashes };
}
export function assembleQualification(bundles, context, jobResponse) {
  assert.deepEqual(Object.keys(bundles).sort(), Object.keys(platforms).sort(), 'PSC_EVIDENCE_PLATFORM_SET');
  assert(Array.isArray(jobResponse.jobs) && jobResponse.total_count === jobResponse.jobs.length && jobResponse.jobs.length <= 100, 'PSC_EVIDENCE_JOBS_INCOMPLETE');
  const results = [];
  for (const [platform, info] of Object.entries(platforms)) {
    const { files, envelope } = bundles[platform];
    assert.deepEqual(envelope, platformEnvelope(files, context, platform), 'PSC_EVIDENCE_ENVELOPE_MISMATCH');
    const jobs = jobResponse.jobs.filter(j => j.name === info.job); assert.equal(jobs.length, 1, 'PSC_EVIDENCE_JOB_AMBIGUOUS');
    const job = jobs[0];
    match(job, { run_id: context.runId, run_attempt: context.runAttempt, head_sha: context.source, status: 'completed', conclusion: 'success' }, info.job);
    assert(Number.isSafeInteger(job.id) && job.id > 0, 'PSC_EVIDENCE_JOB_ID');
    assert(Array.isArray(job.steps) && job.steps.length > 0 && job.steps.every(s => s.status === 'completed' && s.conclusion === 'success'), 'PSC_EVIDENCE_INCOMPLETE_STEP');
    results.push({ ...envelope, jobId: job.id, conclusion: 'success' });
  }
  return { schema: 'psc0-ci-qualification/1', ...context, subjectKind: 'qualification-report-not-executable', inheritedRuntime: retained, platforms: results, jobMetadata: { name: 'jobs.json', sha256: digest(encoded(jobResponse)) }, claims: { boundedCiChecksPassed: true, compilerSourceQualificationInherited: true, newInstalledFixedPoint: false, compilerOrKernelRegenerated: false, formalKernelSoundness: false, targetSemanticsProven: false, npmPublisherAuthenticated: false, releasedExecutable: false, receiptIsProofAuthority: false }, authentication: 'requires-separate-Sigstore-verification' };
}
export async function readEvidenceFile(file) {
  const before = await lstat(file); assert(before.isFile() && !before.isSymbolicLink() && before.size <= 1024 * 1024, 'PSC_EVIDENCE_FILE_KIND_OR_SIZE');
  const handle = await open(file, 'r');
  try {
    const opened = await handle.stat(); assert.equal(opened.ino, before.ino, 'PSC_EVIDENCE_FILE_CHANGED'); assert.equal(opened.dev, before.dev, 'PSC_EVIDENCE_FILE_CHANGED');
    const buffer = Buffer.alloc(before.size + 1); let count = 0;
    while (count < buffer.length) { const r = await handle.read(buffer, count, buffer.length - count, count); if (!r.bytesRead) break; count += r.bytesRead; }
    const after = await handle.stat();
    assert.equal(count, before.size, 'PSC_EVIDENCE_FILE_CHANGED');
    for (const key of ['size', 'mtimeMs', 'ctimeMs']) assert.equal(after[key], before[key], 'PSC_EVIDENCE_FILE_CHANGED');
    return buffer.subarray(0, count);
  } finally { await handle.close(); }
}
async function readPlatform(directory, sealed) {
  const s = await lstat(directory); assert(s.isDirectory() && !s.isSymbolicLink(), 'PSC_EVIDENCE_DIRECTORY');
  const names = (await readdir(directory)).sort();
  assert.deepEqual(names, [...reportNames, ...(sealed ? ['platform-envelope.json'] : [])].sort(), 'PSC_EVIDENCE_DIRECTORY_SET');
  const files = Object.create(null);
  for (const name of reportNames) files[name] = await readEvidenceFile(path.join(directory, name));
  return { files, ...(sealed ? { envelope: json(await readEvidenceFile(path.join(directory, 'platform-envelope.json'))) } : {}) };
}
export async function verifyDirectory(directory, context) {
  const manifest = json(await readEvidenceFile(path.join(directory, 'qualification.json')));
  const jobs = json(await readEvidenceFile(path.join(directory, 'jobs.json'))), bundles = {};
  for (const platform of Object.keys(platforms)) bundles[platform] = await readPlatform(path.join(directory, 'evidence', platform), true);
  assert.deepEqual(manifest, assembleQualification(bundles, context, jobs), 'PSC_EVIDENCE_MANIFEST_MISMATCH');
  return manifest;
}
async function main() {
  const [mode, input, output, jobsFile] = process.argv.slice(2), context = contextFromEnv(process.env);
  if (mode === 'seal-platform') {
    const { files } = await readPlatform(input, false);
    const envelope = platformEnvelope(files, context, process.env.RUNNER_OS);
    await writeFile(path.join(input, 'platform-envelope.json'), encoded(envelope), { flag: 'wx' });
  } else if (mode === 'assemble') {
    const jobs = json(await readEvidenceFile(jobsFile)), bundles = {};
    for (const platform of Object.keys(platforms)) bundles[platform] = await readPlatform(path.join(input, platform), true);
    const manifest = assembleQualification(bundles, context, jobs);
    await mkdir(output, { recursive: true });
    for (const [platform, bundle] of Object.entries(bundles)) {
      const destination = path.join(output, 'evidence', platform); await mkdir(destination, { recursive: true });
      for (const [name, bytes] of Object.entries(bundle.files)) await writeFile(path.join(destination, name), bytes, { flag: 'wx' });
      await writeFile(path.join(destination, 'platform-envelope.json'), encoded(bundle.envelope), { flag: 'wx' });
    }
    await writeFile(path.join(output, 'jobs.json'), encoded(jobs), { flag: 'wx' });
    await writeFile(path.join(output, 'qualification.json'), encoded(manifest), { flag: 'wx' });
    await verifyDirectory(output, context);
  } else if (mode === 'verify') await verifyDirectory(input, context);
  else throw new Error('PSC_EVIDENCE_COMMAND');
  console.log('PSC_CI_EVIDENCE: PASS ' + mode + ' source=' + context.source + ' run=' + context.runId + '/' + context.runAttempt);
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
