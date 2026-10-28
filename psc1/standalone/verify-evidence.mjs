// Aggregate actual same-run isolated evidence; this does not run a compiler.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(process.argv[2] || 'dist/independent-development/gate');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const json = value => JSON.stringify(value, null, 2) + '\n';
const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const bootstrap = read(path.join(root, 'bootstrap/bootstrap.json'));
assert.equal(bootstrap.schema, 'psc1-independent-bootstrap/1');
assert.equal(bootstrap.sourceCommit, process.env.GITHUB_SHA);
assert.equal(bootstrap.tarball, 'psc1-independent-linux-x64.tar.gz');
const archive = fs.readFileSync(path.join(root, 'bootstrap', bootstrap.tarball));
assert.equal(archive.length, bootstrap.bytes);
assert.equal(sha(archive), bootstrap.sha256);

const phases = {};
for (const phase of ['smoke', 'baseline', 'changed']) {
  const directory = path.join(root, phase);
  const isolation = read(path.join(directory, 'isolation.json'));
  const qualification = read(path.join(directory, phase, 'qualification.json'));
  assert.equal(isolation.schema, 'psc1-independent-isolation-result/1');
  assert.equal(isolation.status, 'passed');
  assert.equal(isolation.phase, phase);
  assert.equal(isolation.exitStatus, 0);
  assert.equal(isolation.processError, null);
  assert.deepEqual(isolation.unexpectedExecutions, []);
  assert.equal(sha(fs.readFileSync(path.join(directory, 'execve.log'))), isolation.traceSha256);
  assert.deepEqual(isolation.qualification, qualification);
  assert.equal(qualification.schema, 'psc1-independent-development-qualification/1');
  assert.equal(qualification.status, 'passed');
  assert.equal(qualification.phase, phase);
  assert.equal(qualification.environment.externalToolchainsAbsent, true);
  assert.equal(qualification.environment.runtimeVersion, 'v22.23.3');
  assert.equal(qualification.distribution.manifestSha256, bootstrap.toolchainSha256);
  assert.equal(qualification.distribution.sourceCommit, bootstrap.sourceCommit);
  assert.equal(qualification.distribution.runtimeSha256, bootstrap.privateRuntimeSha256);
  assert.equal(qualification.distribution.checkerSha256, bootstrap.checkerSha256);
  assert.equal(qualification.authoritativeSource.moduleCount, bootstrap.sourceModules);
  assert.equal(qualification.authoritativeSource.sourceClosureDigest, bootstrap.sourceClosureDigest);
  const checks = isolation.executions.filter(file => file === '/toolchain/kernel/checker').length;
  assert.ok(checks >= (phase === 'smoke' ? 3 : 2), 'actual checker process count: ' + phase);
  phases[phase] = { directory, isolation, qualification, checks };
}
const original = phases.baseline.qualification.authoritativeSource;
assert.deepEqual(phases.changed.qualification.authoritativeSource, original);
assert.deepEqual(phases.smoke.qualification.authoritativeSource, original);
const expectedFiles = ['compiler.mjs', 'admissions.json', 'original-ir.json', 'specialized-ir.json', 'sources.json'];
function checkedBuild(phase, label) {
  const item = phases[phase].qualification.results.find(row =>
    row.type === 'independently-checked-build' && row.label === label);
  assert.ok(item, 'missing independently checked build: ' + label);
  assert.equal(item.checker.executed, true);
  assert.equal(item.checker.accepted, true);
  assert.equal(item.checker.sha256, bootstrap.checkerSha256);
  assert.equal(item.checker.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(item.checker.admissionsSha256, item.identities.admissionsSha256);
  assert.equal(item.execution.timeoutMs, 3600000);
  assert.deepEqual(item.publicNames, ['psCompilerServiceCandidate']);
  assert.deepEqual(item.files.map(row => row.path), expectedFiles);
  const directory = path.join(phases[phase].directory, phase, path.basename(item.directory));
  for (const pin of item.files) {
    const bytes = fs.readFileSync(path.join(directory, pin.path));
    assert.equal(bytes.length, pin.bytes);
    assert.equal(sha(bytes), pin.sha256, label + ':' + pin.path);
  }
  assert.equal(sha(fs.readFileSync(path.join(directory, 'build.json'))), item.buildReceiptSha256);
  assert.equal(sha(fs.readFileSync(path.join(directory, 'candidate.json'))), item.candidateSha256);
  return item;
}
const B1 = checkedBuild('baseline', 'baseline-generation-one');
const B2 = checkedBuild('baseline', 'baseline-generation-two');
const C1 = checkedBuild('changed', 'changed-generation-one');
const C2 = checkedBuild('changed', 'changed-generation-two');
assert.deepEqual(B1.identities, B2.identities);
assert.deepEqual(B1.files, B2.files);
assert.deepEqual(C1.identities, C2.identities);
assert.deepEqual(C1.files, C2.files);
assert.equal(B1.identities.sourceClosureDigest, original.sourceClosureDigest);
assert.notEqual(C1.identities.sourceClosureDigest, B1.identities.sourceClosureDigest);
assert.notEqual(C1.identities.sourceSha256, B1.identities.sourceSha256);
const changed = phases.changed.qualification;
assert.equal(C1.identities.sourceClosureDigest, changed.changedSource.sourceClosureDigest);
assert.equal(changed.changedSource.files.length, original.files.length);
const differences = original.files.flatMap((file, index) => {
  const next = changed.changedSource.files[index];
  assert.equal(next.module, file.module);
  assert.equal(next.path, file.path);
  return next.sha256 === file.sha256 ? [] : [{ before: file, after: next }];
});
assert.equal(differences.length, 1);
assert.equal(differences[0].before.module, 'Ps.CompilerUnified.Service');
const mutation = changed.results.find(row => row.type === 'real-compiler-source-modification');
assert.ok(mutation);
assert.equal(mutation.changedFileCount, 1);
assert.equal(mutation.originalSourceClosureDigest, original.sourceClosureDigest);
assert.equal(mutation.changedSourceClosureDigest, C1.identities.sourceClosureDigest);
assert.equal(mutation.beforeSourceSha256, differences[0].before.sha256);
assert.equal(mutation.afterSourceSha256, differences[0].after.sha256);
for (const generation of ['C1', 'C2']) {
  const behavior = changed.results.find(row => row.type === 'changed-behavior' && row.generation === generation);
  assert.ok(behavior);
  assert.equal(behavior.actual.code, 'request-arity:expected-three-fields');
  assert.equal(behavior.actual.status, 'refused');
  if (generation === 'C1') assert.equal(behavior.seed.code, 'request-arity');
}
for (const phase of ['baseline', 'changed']) {
  const fixed = phases[phase].qualification.results.filter(row => row.type === 'fixed-point');
  assert.equal(fixed.length, 1);
  assert.equal(fixed[0].status, 'passed');
}
const summary = {
  schema: 'psc1-independent-development-evidence/1',
  status: 'qualified-linux-independent-compiler-development',
  testedCommit: process.env.GITHUB_SHA,
  runId: process.env.GITHUB_RUN_ID,
  platform: 'Linux x64; Ubuntu 24.04 CI; private PID/mount/network namespace and minimal root',
  bootstrap,
  authoritativeSource: original,
  changedSource: changed.changedSource,
  sourceDifferences: differences,
  generations: [B1, B2, C1, C2].map(row => ({
    label: row.label, identities: row.identities,
    compilerElapsedMs: row.execution.elapsedMs,
    compilerMaxRssKiB: row.execution.maxRssKiB,
    sampledPeakRssKiB: row.execution.peakRssKiB,
    checkerElapsedMs: row.checker.elapsedMs,
    completeProcessElapsedMs: row.processElapsedMs,
    checkerExecuted: row.checker.executed,
    buildReceiptSha256: row.buildReceiptSha256,
  })),
  phases: Object.fromEntries(Object.entries(phases).map(([name, item]) => [name, {
    status: item.qualification.status, elapsedMs: item.qualification.elapsedMs,
    checkerExecutions: item.checks, traceSha256: item.isolation.traceSha256,
    qualificationSha256: sha(fs.readFileSync(path.join(item.directory, name, 'qualification.json'))),
  }])),
  independence: {
    separateLeanLakeRequired: false, separateNodeBunRequired: false,
    separateTypeScriptRustCCppRequired: false, privateNodeRuntimeBundled: true,
    privateRuntimeVersion: '22.23.3', proofChecker: 'precompiled official Lean4.35.0 native kernel provider',
    bootstrapToolsStillRequiredToReassembleDistribution: true,
    repositoryLeanBootstrapSourcesRetained: true,
  },
  assurances: {
    fullCurrentPsCompilerRebuild: true, modifiedCompilerRebuild: true,
    modifiedBehaviorObservedAfterSelfRebuild: true, sameSourceFixedPoints: true,
    independentLogicalAdmissionEveryBuild: true,
    formalCompilerPreservation: false, performance240sQualified: false,
    otherPlatformsQualified: false,
  },
};
fs.writeFileSync(path.join(root, 'summary.json'), json(summary));
const delivery = path.join(root, 'delivery');
fs.mkdirSync(delivery);
fs.copyFileSync(path.join(root, 'bootstrap', bootstrap.tarball), path.join(delivery, bootstrap.tarball));
fs.writeFileSync(path.join(delivery, 'summary.json'), json(summary));
fs.writeFileSync(path.join(delivery, 'SHA256SUMS'), bootstrap.sha256 + '  ' + bootstrap.tarball + '\n'
  + sha(Buffer.from(json(summary))) + '  summary.json\n');
console.log('PSC1_INDEPENDENT_DEVELOPMENT_EVIDENCE: ' + JSON.stringify(summary));
