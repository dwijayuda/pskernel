import assert from 'node:assert/strict';
import test from 'node:test';
import { assertProviderParity, checkAdmissionsWithDual } from './checked-kernel-dual.mjs';
import { checkCoreAdmissions } from './checked-kernel-core.mjs';

const yes = { accepted: true };
const no = { accepted: false, errorKind: 'kernel-rejection', declarationIndex: 0, message: 'type mismatch' };

test('dual checking requires matching semantic outcomes and the same rejection index', () => {
  assert.equal(assertProviderParity(yes, yes, 0), 'accepted');
  assert.equal(assertProviderParity(no, no, 1), 'rejected:0');
  assert.throws(() => assertProviderParity(yes, no, 1), /DISAGREEMENT/);
  assert.throws(() => assertProviderParity(no, yes, 1), /DISAGREEMENT/);
  assert.throws(() => assertProviderParity(no, { ...no, declarationIndex: 1 }, 2), /DISAGREEMENT/);
});

test('timeouts, exhaustion, unsupported forms and host failures never establish parity', () => {
  const failures = [
    ...['resource-exhausted', 'provider-internal-error', 'unsupported-core-form',
      'prelude-mismatch', 'malformed-request', 'protocol-version'].map(errorKind => ({ ...no, errorKind })),
    ...['deterministic-timeout', 'excessive-memory', 'deep-recursion', 'interrupted',
      'other:unknown failure', 'kernel inference budget exhausted'].map(message => ({ ...no, message })),
    { ...no, declarationIndex: undefined }, { ...no, declarationIndex: -1 },
    { ...no, declarationIndex: 1 }, { ...no, message: undefined }, {},
    { accepted: true, errorKind: 'resource-exhausted' },
  ];
  for (const failure of failures) {
    assert.throws(() => assertProviderParity(failure, failure, 1), /INCONCLUSIVE/);
    assert.throws(() => assertProviderParity(yes, failure, 1), /INCONCLUSIVE/);
  }
});

test('dual mode cannot compare a provider with itself or substitute an archived kernel', async () => {
  for (const pair of [['pskernel-core', 'pskernel-core'], ['lean434', 'lean434-wasm'],
    ['pskernel-core.old3', 'lean434-wasm']]) {
    await assert.rejects(checkAdmissionsWithDual('{}', ...pair), /DUAL_CHECK_PAIR/);
  }
});

test('missing core binary and invalid time budget fail without fallback', () => {
  assert.throws(() => checkCoreAdmissions('{}', { binaryPath: '/missing/m4-provider' }), /PROVIDER_MISSING/);
  for (const timeoutMs of [0, -1, Infinity, NaN, 60001]) {
    assert.throws(() => checkCoreAdmissions('{}', { timeoutMs }), /TIMEOUT_BUDGET/);
  }
});
