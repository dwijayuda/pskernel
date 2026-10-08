import test from 'node:test';
import assert from 'node:assert/strict';
import { classifyPortablePackageTrees, baseline } from './selfhost-baseline.mjs';

test('unchanged baseline permits the cheap fixed-point preflight', () => {
  const result = classifyPortablePackageTrees({ ...baseline.portablePackageTrees });
  assert.equal(result.unchanged, true);
  assert.deepEqual(result.changed, []);
});

test('any portable package tree change disables fast mode', () => {
  for (const name of Object.keys(baseline.portablePackageTrees)) {
    const actual = { ...baseline.portablePackageTrees, [name]: '0000000000000000000000000000000000000000' };
    const result = classifyPortablePackageTrees(actual);
    assert.equal(result.unchanged, false);
    assert.deepEqual(result.changed, [name]);
  }
});

test('unrecognized paths cannot weaken the 12-package baseline', () => {
  const actual = { ...baseline.portablePackageTrees, 'pskernel-core': 'different' };
  assert.equal(classifyPortablePackageTrees(actual).unchanged, true);
  assert.equal(Object.keys(baseline.portablePackageTrees).length, 12);
  assert.equal(baseline.sourceCount, 55);
});
