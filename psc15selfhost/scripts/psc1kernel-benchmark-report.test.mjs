import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { validateSample, summarizeSamples, runBenchmark } from './psc1kernel-benchmark-report.mjs';

// Actual green native output at 33b59ded58aa5ab745ab6b7f729cf487dc608e20.
const fixture = readFileSync(new URL('./fixtures/pskernel-native-benchmark.log', import.meta.url), 'utf8');

test('accepts the complete green corpus and reports within-run ratios', () => {
  const sample = validateSample(fixture);
  assert.equal(sample.fingerprint.length, 33);
  assert.equal(sample.ratios.nested, 53931117 / 17189380);
  const summary = summarizeSamples([sample, sample, sample]);
  assert.equal(summary.sampleCount, 3);
  assert.equal(summary.pskernelOverLean.nested.median, sample.ratios.nested);
});

test('rejects partial and equally failed comparisons', () => {
  for (const replacement of ['hits=999/1000', 'hits=0/0']) {
    assert.throws(() => validateSample(fixture.replace('hits=1000/1000', replacement)), /Incomplete\/failed/);
  }
});

test('rejects failed setup, missing rows, and duplicate rows', () => {
  assert.throws(() => validateSample(fixture.replace('nested_wide_setup=ok', 'nested_wide_setup=error')));
  const lines = fixture.trim().split('\n');
  assert.throws(() => validateSample(lines.slice(1).join('\n')), /Incomplete\/failed/);
  assert.throws(() => validateSample(fixture + lines[0]), /duplicate/);
});

test('rejects invalid timings and missing comparison data', () => {
  for (const invalid of ['NaN', '-1', 'Infinity', '0', '9007199254740992']) {
    assert.throws(() => validateSample(fixture.replace('1674853', invalid)), /Invalid/);
  }
  assert.throws(() => validateSample(fixture.replace(' beta_lean_ns=294439', '')), /Missing comparison/);
});

test('uses medians of matched ratios and preserves their range', () => {
  const logs = ['100', '300', '200'].map(value => fixture.replace('beta_pskernel_ns=602704', `beta_pskernel_ns=${value}`));
  const report = summarizeSamples(logs.map(validateSample));
  assert.deepEqual(report.pskernelOverLean.beta, { median: 200 / 294439, min: 100 / 294439, max: 300 / 294439 });
});

test('rejects corpus drift between samples', () => {
  assert.throws(() => summarizeSamples([validateSample(fixture), validateSample(fixture.replace('arity=8', 'arity=9'))]), /corpus changed/);
});

test('caps sample count before launching a process', () => {
  for (const count of [0, 1, 2, 4, 6, NaN, 1.5]) {
    assert.throws(() => runBenchmark('must-not-run', count, 'must-not-write'), /exactly 3/);
  }
  assert.throws(() => summarizeSamples([]), /1 to 5/);
});

test('requires the declared admission work count even when hit counts look successful', () => {
  assert.throws(() => validateSample(fixture.replace('iterations=100', 'iterations=10')), /Wrong workload size/);
});

test('records input-dependence guards only for a unique complete success marker', () => {
  const marker = 'PSKERNEL_ADMISSION_INPUT_GUARDS: PASS variants=16\n';
  assert.equal(validateSample(fixture).admissionInputGuards, false);
  assert.equal(validateSample(fixture + marker).admissionInputGuards, true);
  assert.equal(validateSample(fixture + marker + marker).admissionInputGuards, false);
  assert.equal(validateSample(fixture + marker.replace('16', '1')).admissionInputGuards, false);
});
