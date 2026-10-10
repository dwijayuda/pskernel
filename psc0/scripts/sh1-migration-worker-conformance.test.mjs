import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { compareMigrationWorkerReportObservations } from './sh1-migration-worker-conformance.mjs';

// This immutable R report is already retained as qualification evidence. The
// two added empty fields below reproduce the complete C1 report logged by
// run 38011957573; this test does not execute or select a compiler.
const reference = JSON.parse(readFileSync(new URL(
  '../docs/selfhost-language/seed-evidence/fcd875c8f38db4b0524090bd10c7c2fd5024053d/F/worker-harness-reference.logged.json',
  import.meta.url), 'utf8')).report;
const referenceHash = '697616ab48daf77a44b90ce20085432593ddce9a06fdad124a5a898ece3621be';
const currentHash = '7928373c18de754fe152341d159c0f2e9d1880eb645177b25217071c91a22740';
const scopeCases = ['structures-empty-reverse-accumulator', 'inductives-empty-reverse-accumulator'];
const hash = (value) => createHash('sha256').update(JSON.stringify(value)).digest('hex');
const scopeFor = (report, name) => report.families[1].observations
  .find((item) => item.name === name).result.scope;
function rehash(report) {
  for (const family of report.families) family.observationSha256 = hash(family.observations);
  report.observationSha256 = hash({
    F1: report.families[0].observations, F2: report.families[1].observations,
  });
  return report;
}
function currentReport() {
  const report = structuredClone(reference);
  for (const name of scopeCases) scopeFor(report, name).declarationNames.runtimePrefix = '';
  rehash(report);
  assert.equal(report.observationSha256, currentHash, 'fixture must match the logged complete C1 report');
  assert.equal(report.families[1].observationSha256,
    '6e96386242ff39765ff2ba111f3ce6075c10fca8d222eb2c7e3455e7d3545ef2');
  return report;
}

test('known R/current record extension compares all 87 cases without changing raw reports', () => {
  assert.equal(reference.observationSha256, referenceHash);
  const current = currentReport();
  const beforeBytes = JSON.stringify(reference), currentBytes = JSON.stringify(current);
  assert.deepEqual(compareMigrationWorkerReportObservations(reference, current), {
    profile: 'empty-legacy-erasure-namespace/1',
    cases: 87,
    projectedPaths: scopeCases.map((name) =>
      'F2/' + name + '/result/scope/declarationNames/runtimePrefix'),
    runtimePrefix: '',
    referenceRuntimePrefixPresent: false,
    referenceObservationSha256: referenceHash,
    currentObservationSha256: currentHash,
    comparisonObservationSha256: referenceHash,
  });
  assert.equal(JSON.stringify(reference), beforeBytes);
  assert.equal(JSON.stringify(current), currentBytes);
});

test('a current reference retains its raw hash and requires the current field', () => {
  const current = currentReport();
  const result = compareMigrationWorkerReportObservations(current, current);
  assert.equal(result.referenceRuntimePrefixPresent, true);
  assert.equal(result.referenceObservationSha256, currentHash);
  assert.equal(result.currentObservationSha256, currentHash);
  assert.equal(result.comparisonObservationSha256, referenceHash);
  assert.throws(() => compareMigrationWorkerReportObservations(reference, reference),
    /CURRENT_RUNTIME_PREFIX_MISSING/u);
});

test('both exact current namespace fields must exist and be empty', () => {
  for (const name of scopeCases) {
    const missing = currentReport();
    delete scopeFor(missing, name).declarationNames.runtimePrefix;
    assert.throws(() => compareMigrationWorkerReportObservations(reference, rehash(missing)),
      /CURRENT_RUNTIME_PREFIX_MISSING/u);
    for (const value of ['__ps$source$', null, 0]) {
      const changed = currentReport();
      scopeFor(changed, name).declarationNames.runtimePrefix = value;
      assert.throws(() => compareMigrationWorkerReportObservations(reference, rehash(changed)),
        /NONEMPTY_RUNTIME_PREFIX/u);
    }
  }
});

test('a present reference namespace must also be empty', () => {
  const changed = currentReport();
  scopeFor(changed, scopeCases[0]).declarationNames.runtimePrefix = 'other';
  assert.throws(() => compareMigrationWorkerReportObservations(rehash(changed), currentReport()),
    /NONEMPTY_RUNTIME_PREFIX/u);
});

test('the same field name elsewhere and new record fields are not projected', () => {
  const changedScope = currentReport();
  scopeFor(changedScope, scopeCases[0]).runtimePrefix = '';
  assert.throws(() => compareMigrationWorkerReportObservations(reference, rehash(changedScope)));
  const changedCase = currentReport();
  changedCase.families[1].observations.find((item) => item.name === 'names-empty-state')
    .result.runtimePrefix = '';
  assert.throws(() => compareMigrationWorkerReportObservations(reference, rehash(changedCase)));
  const changedRecord = currentReport();
  scopeFor(changedRecord, scopeCases[0]).declarationNames.newField = true;
  assert.throws(() => compareMigrationWorkerReportObservations(reference, rehash(changedRecord)),
    /DECLARATION_NAMES_FIELDS/u);
});

test('case removal and changed non-scope observations remain failures', () => {
  const missingCase = currentReport();
  missingCase.families[1].observations.pop();
  assert.throws(() => compareMigrationWorkerReportObservations(reference, rehash(missingCase)),
    /F2_COVERAGE/u);
  const changed = currentReport();
  changed.families[0].observations[0].result = 'different';
  assert.throws(() => compareMigrationWorkerReportObservations(reference, rehash(changed)));
});

test('raw family and whole-report hashes are verified before comparison', () => {
  const familyHash = currentReport();
  familyHash.families[1].observationSha256 = '0'.repeat(64);
  assert.throws(() => compareMigrationWorkerReportObservations(reference, familyHash),
    /RAW_FAMILY_HASH/u);
  const reportHash = currentReport();
  reportHash.observationSha256 = '0'.repeat(64);
  assert.throws(() => compareMigrationWorkerReportObservations(reference, reportHash),
    /RAW_REPORT_HASH/u);
});
