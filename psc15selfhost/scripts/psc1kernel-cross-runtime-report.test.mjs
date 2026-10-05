import assert from 'node:assert/strict';
import test from 'node:test';
import { admissionRequest, iterations, requestCases, workloads } from './psc1kernel-cross-runtime-corpus.mjs';
import { parseNative, stats, validateWorker } from './psc1kernel-cross-runtime-report.mjs';

const valid = () => ({ runtime: 'js', guards: true, importNs: 10, peakRssKiB: 100,
  rows: workloads.map((name, kind) => ({ name, kind, hits: iterations, ns: 100, firstCallNs: 10 })),
  admissions: requestCases.map(x => ({ ...x, accepted: !x.bad, ns: 100 })),
});
test('complete success evidence is required', () => {
  validateWorker(valid(), 'js');
  for (const mutate of [x => x.rows.pop(), x => x.rows.push(x.rows[0]),
    x => x.rows[1] = x.rows[0], x => x.rows[0].hits--, x => x.guards = false,
    x => x.admissions[2].accepted = true, x => x.admissions.pop(),
    x => x.admissions[0].count++, x => x.runtime = 'native',
    x => delete x.peakRssKiB, x => x.peakRssKiB = 0]) {
    const value = valid(); mutate(value); assert.throws(() => validateWorker(value, 'js'));
  }
});
test('timings must be positive exact numeric observations', () => {
  for (const bad of [0, -1, NaN, Infinity, '10', 1.2, Number.MAX_SAFE_INTEGER + 1]) {
    const value = valid(); value.rows[0].ns = bad;
    assert.throws(() => validateWorker(value, 'js'));
  }
});
test('native output cannot hide failure or duplicate results', () => {
  assert.equal(parseNative('CROSS_NATIVE 1 1000 123\n', 1), 123);
  for (const bad of ['CROSS_NATIVE 0 1000 123', 'CROSS_NATIVE 1 999 123',
    'CROSS_NATIVE 1 1000 0', 'CROSS_NATIVE 1 1000 1\nextra']) {
    assert.throws(() => parseNative(bad, 1));
  }
});
test('WASM evidence requires the pin and all matching verdicts', () => {
  const value = { runtime: 'wasm', healthRequestNs: 10,
    identity: { leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b' },
    admissions: valid().admissions };
  validateWorker(value, 'wasm');
  value.identity.leanCommit = 'wrong';
  assert.throws(() => validateWorker(value, 'wasm'));
});
test('corpus retains exact big naturals and deliberate kernel rejection', () => {
  const good = JSON.parse(admissionRequest(128, false));
  assert.equal(good.admissions.length, 128);
  assert.equal(good.admissions[0].declaration.v.v, '9007199254740993');
  assert.equal(good.admissions[127].declaration.v.v, '9007199254741120');
  const bad = JSON.parse(admissionRequest(4, true));
  assert.equal(bad.admissions[2].declaration.v.k, 'nat');
  assert.equal(bad.admissions[3].declaration.v.k, 'sort');
  assert.throws(() => admissionRequest(1_000_000, false));
});
test('median and range preserve samples', () => {
  assert.deepEqual(stats([4, 1, 2]), { median: 2, min: 1, max: 4 });
  assert.deepEqual(stats([4, 2]), { median: 3, min: 2, max: 4 });
  assert.throws(() => stats([]));
});
