import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createCheckedPreparedSession, leanCheckedIdentity } from './checked-prepared-session.mjs';

const tag = Symbol('Except');
const ok = value => ({ [tag]: 'ok', value });
const identity = { protocol: 'pskernel-lean/1', provider: 'lean4-cpp',
  leanVersion: '4.34.0', leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  profile: 'lean4.34-core', accepted: true };
function fixture(provider = () => identity) {
  const calls = []; let prepared;
  const compiler = {
    List: { nil: () => null, cons: (head, tail) => ({ head, tail }) },
    psCompilerPrepareSources(kind, sources) {
      calls.push('prepare-modules');
      const values = [];
      for (let cursor = sources; cursor !== null; cursor = cursor.tail) values.push(cursor.head);
      prepared = { declarations: values.map((value, index) => ({ name: `module${index}`, value })), kind };
      return ok(prepared);
    },
    psCompilerPrepareSource(kind, source) {
      calls.push('prepare'); prepared = { declarations: [{ name: 'answer', value: source }], kind };
      return ok(prepared);
    },
    psCompilerAdmissionsFromPrepared(value) {
      assert.equal(value, prepared); calls.push('encode'); return ok(JSON.stringify(value.declarations));
    },
    psCompilerTypeScriptFromPrepared(value) {
      assert.equal(value, prepared); calls.push('emit'); return ok('export const answer = 42n;');
    },
  };
  const session = createCheckedPreparedSession(compiler, admissions => {
    calls.push('kernel'); return provider(admissions, prepared);
  }, leanCheckedIdentity);
  return { session, calls, getPrepared: () => prepared };
}

test('module preparation preserves order and checks one combined immutable payload', async () => {
  const { session, calls, getPrepared } = fixture();
  const sources = ['def first : Nat := 1', 'def second : Nat := first'];
  const pending = session.checkSources('lean', sources);
  sources[0] = 'mutated';
  const handle = await pending;
  assert.deepEqual(getPrepared().declarations.map(item => item.value),
    ['def first : Nat := 1', 'def second : Nat := first']);
  assert.equal(session.emit(handle), 'export const answer = 42n;');
  assert.deepEqual(calls, ['prepare-modules', 'encode', 'kernel', 'encode', 'emit']);
});

test('module preparation cannot bypass kernel rejection or use a fallback', async () => {
  const { session, calls } = fixture(() => ({ ...identity, accepted: false }));
  await assert.rejects(session.checkSources('lean', ['first', 'second']), /KERNEL_REJECTED/);
  assert.deepEqual(calls, ['prepare-modules', 'encode', 'kernel']);
});

test('module preparation rejects nontext inputs before preparing', async () => {
  const { session, calls } = fixture();
  await assert.rejects(session.checkSources('lean', ['first', 42]), /immutable source texts/);
  assert.deepEqual(calls, []);
});
test('one preparation; exact checked object reaches emission', async () => {
  const { session, calls } = fixture();
  const checked = await session.check('lean', '42');
  assert.equal(session.emit(checked), 'export const answer = 42n;');
  assert.deepEqual(calls, ['prepare', 'encode', 'kernel', 'encode', 'emit']);
  assert.match(checked.canonicalAdmissionsSha256, /^[0-9a-f]{64}$/);
  assert.equal(checked.provider.profile, 'lean4.34-core');
});
test('no emission after kernel rejection', async () => {
  const { session, calls } = fixture(() => ({ ...identity, accepted: false, errorKind: 'kernel-rejection' }));
  await assert.rejects(session.check('lean', '42'), /KERNEL_REJECTED/);
  assert.ok(!calls.includes('emit'));
});
test('provider failure does not fall back', async () => {
  const { session, calls } = fixture(() => { throw new Error('provider unavailable'); });
  await assert.rejects(session.check('lean', '42'), /provider unavailable/);
  assert.equal(calls.filter(x => x === 'kernel').length, 1);
  assert.ok(!calls.includes('emit'));
});
for (const field of ['protocol', 'provider', 'leanVersion', 'leanCommit', 'profile']) {
  test(`reject mismatched ${field}`, async () => {
    const { session } = fixture(() => ({ ...identity, [field]: 'wrong' }));
    await assert.rejects(session.check('lean', '42'), /PROVIDER_IDENTITY/);
  });
}
test('nonboolean accepted is not acceptance', async () => {
  const { session } = fixture(() => ({ ...identity, accepted: 'true' }));
  await assert.rejects(session.check('lean', '42'), /PROVIDER_RESULT/);
});
test('ordinary callers cannot forge or clone a checked handle', async () => {
  const { session } = fixture();
  assert.throws(() => session.emit({ accepted: true }), /UNCHECKED_MODULE/);
  const checked = await session.check('lean', '42');
  assert.throws(() => session.emit({ ...checked }), /UNCHECKED_MODULE/);
  assert.throws(() => fixture().session.emit(checked), /UNCHECKED_MODULE/);
});
test('semantic graph is frozen before checker is called', async () => {
  const { session, getPrepared } = fixture((_admissions, prepared) => {
    assert.throws(() => { prepared.declarations[0].value = 'changed'; }, TypeError);
    return identity;
  });
  const checked = await session.check('lean', '42');
  assert.throws(() => getPrepared().declarations.push({}), TypeError);
  assert.throws(() => { checked.provider.profile = 'changed'; }, TypeError);
  session.emit(checked);
});
test('changed canonical output is rejected before emission', async () => {
  let count = 0; const calls = [];
  const compiler = {
    psCompilerPrepareSource: () => ok({ declarations: [] }),
    psCompilerAdmissionsFromPrepared: () => ok(String(count++)),
    psCompilerTypeScriptFromPrepared: () => { calls.push('emit'); return ok('bad'); },
  };
  const session = createCheckedPreparedSession(compiler, () => identity, leanCheckedIdentity);
  const checked = await session.check('lean', '42');
  assert.throws(() => session.emit(checked), /CHECKED_PAYLOAD_CHANGED/);
  assert.deepEqual(calls, []);
});
test('malformed frontend result fails before checker', async () => {
  let called = false;
  const compiler = {
    psCompilerPrepareSource: () => ({ value: {} }),
    psCompilerAdmissionsFromPrepared: () => ok(''),
    psCompilerTypeScriptFromPrepared: () => ok(''),
  };
  const session = createCheckedPreparedSession(compiler, () => { called = true; return identity; });
  await assert.rejects(session.check('lean', ''), /RESULT_SHAPE/);
  assert.equal(called, false);
});
test('source text is a value, not a file read between check and emit', async () => {
  const { session, getPrepared } = fixture();
  let source = 'original'; const checked = await session.check('lean', source);
  source = 'changed'; session.emit(checked);
  assert.equal(getPrepared().declarations[0].value, 'original');
});
