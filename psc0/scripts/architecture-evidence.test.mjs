import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, writeFile, rm, mkdir, symlink } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { platformEnvelope, assembleQualification, reportContracts, contextFromEnv, readEvidenceFile, repository, workflow, branchRef, expectedTests } from './architecture-evidence.mjs';
const source = '1'.repeat(40);
const context = { repository, workflow, ref: branchRef, source, runId: 123, runAttempt: 1 };
const env = { GITHUB_REPOSITORY: repository, GITHUB_REF: branchRef, GITHUB_WORKFLOW_REF: workflow + '@' + branchRef, GITHUB_SHA: source, GITHUB_RUN_ID: '123', GITHUB_RUN_ATTEMPT: '1' };
function fixture(platform = 'Linux') {
  const files = Object.fromEntries(Object.entries(reportContracts(source, platform)).map(([name, value]) => [name, Buffer.from(JSON.stringify(value))]));
  files['host-tests.tap'] = Buffer.from(['TAP version 13', ...Array.from({ length: expectedTests }, (_, i) => 'ok ' + (i + 1) + ' - fixture ' + i), '1..' + expectedTests, '# tests ' + expectedTests, '# pass ' + expectedTests, '# fail 0', '# cancelled 0', '# skipped 0', '# todo 0', ''].join('\n'));
  return files;
}
function change(files, file, edit) { const object = JSON.parse(files[file]); edit(object); files[file] = Buffer.from(JSON.stringify(object)); }
function two() {
  const bundles = Object.fromEntries(['Linux', 'Windows'].map(platform => { const files = fixture(platform); return [platform, { files, envelope: platformEnvelope(files, context, platform) }]; }));
  const jobs = { total_count: 2, jobs: ['host (ubuntu-latest, 22.23.3)', 'host (windows-latest, 26.7.0)'].map((name, i) => ({ name, id: i + 1, run_id: 123, run_attempt: 1, head_sha: source, status: 'completed', conclusion: 'success', steps: [{ status: 'completed', conclusion: 'success' }] })) };
  return { bundles, jobs };
}
test('complete evidence produces deterministic envelopes without stronger proof claims', () => {
  const { bundles, jobs } = two(), result = assembleQualification(bundles, context, jobs);
  assert.deepEqual(platformEnvelope(bundles.Linux.files, context, 'Linux'), bundles.Linux.envelope);
  assert.equal(result.subjectKind, 'qualification-report-not-executable');
  assert.equal(result.claims.formalKernelSoundness, false); assert.equal(result.claims.newInstalledFixedPoint, false);
});
test('CI context rejects another repository, workflow, ref and malformed invocation', () => {
  assert.deepEqual(contextFromEnv(env), context);
  for (const key of Object.keys(env)) assert.throws(() => contextFromEnv({ ...env, [key]: 'wrong' }), /PSC_EVIDENCE/);
});
test('missing PS or Lean evidence cannot be sealed', () => {
  for (const name of ['target-ps.json', 'repack-lean.json', 'host-tests.tap']) {
    const files = fixture(); delete files[name]; assert.throws(() => platformEnvelope(files, context, 'Linux'), /FILE_SET/);
  }
});
test('unexpected evidence files are refused rather than signed blindly', () => {
  const files = fixture(); files['pretend-proof.json'] = Buffer.from('{}');
  assert.throws(() => platformEnvelope(files, context, 'Linux'), /FILE_SET/);
});
test('reports from a different source commit are refused', () => {
  const files = fixture(); change(files, 'library-ps.json', r => r.source = '2'.repeat(40));
  assert.throws(() => platformEnvelope(files, context, 'Linux'), /source/);
});
test('retained compiler and kernel identities cannot be replaced', () => {
  for (const field of ['compilerSha256', 'kernelSha256', 'retainedRuntimeSource']) {
    const files = fixture(); change(files, 'repack-lean.json', r => r[field] = 'wrong');
    assert.throws(() => platformEnvelope(files, context, 'Linux'), /PSC_EVIDENCE_VALUE/);
  }
});
test('platform and Node identity cannot be relabeled', () => {
  const files = fixture(); change(files, 'installed-ps.json', r => r.platform = 'win32');
  assert.throws(() => platformEnvelope(files, context, 'Linux'), /platform/);
});
test('wrong schemas and missing mandatory check outcomes decline', () => {
  const files = fixture(); change(files, 'frontend-ps.json', r => r.schema = 'other/1');
  assert.throws(() => platformEnvelope(files, context, 'Linux'), /schema/);
  const missing = fixture(); change(missing, 'library-lean.json', r => delete r.invalidLibraryRefused);
  assert.throws(() => platformEnvelope(missing, context, 'Linux'), /invalidLibraryRefused/);
});
test('only literal successful outcomes count; truthy strings do not', () => {
  for (const value of [false, 'true', 1, null]) {
    const files = fixture(); change(files, 'target-ps.json', r => r.nativeDriftRefusesPublication = value);
    assert.throws(() => platformEnvelope(files, context, 'Linux'), /nativeDriftRefusesPublication/);
  }
});
test('regeneration and new fixed-point claims cannot be inferred from host tests', () => {
  const files = fixture(); change(files, 'repack-ps.json', r => r.newFixedPointClaimed = true);
  assert.throws(() => platformEnvelope(files, context, 'Linux'), /newFixedPointClaimed/);
});
test('failed, skipped, cancelled and truncated TAP cannot become a full pass', () => {
  const original = fixture()['host-tests.tap'].toString();
  for (const text of [original.replace('# fail 0', '# fail 1'), original.replace('# skipped 0', '# skipped 1'), original.replace('# cancelled 0', '# cancelled 1'), original.replace('# todo 0', ''), original.replace('ok 1 -', 'not ok 1 -'), original.replace('1..100', '1..99')]) {
    const files = fixture(); files['host-tests.tap'] = Buffer.from(text);
    assert.throws(() => platformEnvelope(files, context, 'Linux'), /PSC_EVIDENCE_TAP/);
  }
});
test('raw report changes after sealing invalidate the envelope', () => {
  const { bundles, jobs } = two(); bundles.Linux.files['installed-ps.json'] = Buffer.concat([bundles.Linux.files['installed-ps.json'], Buffer.from(' ')]);
  assert.throws(() => assembleQualification(bundles, context, jobs), /ENVELOPE_MISMATCH/);
});
test('different run attempts and missing platforms cannot be aggregated', () => {
  const { bundles, jobs } = two(); bundles.Windows.envelope.runAttempt = 2;
  assert.throws(() => assembleQualification(bundles, context, jobs), /ENVELOPE_MISMATCH/);
  delete bundles.Windows; assert.throws(() => assembleQualification(bundles, context, jobs), /PLATFORM_SET/);
});
test('failed, skipped, duplicate or stale GitHub job records cannot authorize signing', () => {
  for (const alter of [j => j.jobs[0].conclusion = 'failure', j => j.jobs[0].steps[0].conclusion = 'skipped', j => j.jobs[0].run_attempt = 2, j => j.jobs[0].head_sha = '2'.repeat(40), j => { j.jobs.push(j.jobs[0]); j.total_count++; }, j => j.total_count++]) {
    const { bundles, jobs } = two(); alter(jobs);
    assert.throws(() => assembleQualification(bundles, context, jobs), /PSC_EVIDENCE/);
  }
});
test('evidence reader rejects directories, symlinks and oversized data', async t => {
  const root = await mkdtemp(path.join(os.tmpdir(), 'psc-evidence-'));
  t.after(() => rm(root, { recursive: true, force: true }));
  const file = path.join(root, 'input.json'); await writeFile(file, '{}');
  assert.equal((await readEvidenceFile(file)).toString(), '{}');
  await assert.rejects(readEvidenceFile(root), /FILE_KIND_OR_SIZE/);
  await mkdir(path.join(root, 'directory'));
  const link = path.join(root, 'alias'); await symlink(path.join(root, 'directory'), link, process.platform === 'win32' ? 'junction' : 'dir');
  await assert.rejects(readEvidenceFile(link), /FILE_KIND_OR_SIZE/);
  await writeFile(file, Buffer.alloc(1024 * 1024 + 1));
  await assert.rejects(readEvidenceFile(file), /FILE_KIND_OR_SIZE/);
});
