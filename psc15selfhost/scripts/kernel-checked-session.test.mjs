import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  createKernelCheckedSession,
  kernelContractV1,
  leanCheckedIdentity,
} from './kernel-checked-session.mjs';

const tag = Symbol('Except');
const ok = value => ({ [tag]: 'ok', value });
const wire = admissions => JSON.stringify({
  admissions,
  format: 'proofscript-checked-admissions',
  version: 2,
});
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
      assert.equal(value, prepared); calls.push('encode'); return ok(wire(value.declarations));
    },
    psCompilerTypeScriptFromPrepared(value) {
      assert.equal(value, prepared); calls.push('emit'); return ok('export const answer = 42n;');
    },
  };
  const session = createKernelCheckedSession(compiler, admissions => {
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
  const { session, calls } = fixture(() => ({
    ...identity,
    accepted: false,
    errorKind: 'kernel-rejection',
  }));
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
  assert.equal(checked.kernelContract.id, 'proofscript-kernel-contract/1');
  assert.equal(checked.kernelContract.sha256, kernelContractV1.sha256);
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
  await assert.rejects(session.check('lean', '42'), /KERNEL_CONTRACT_RESULT_ACCEPTED/);
});
test('rejection without an error kind violates KernelContract-v1', async () => {
  const { session } = fixture(() => ({ ...identity, accepted: false }));
  await assert.rejects(session.check('lean', '42'), /KERNEL_CONTRACT_RESULT_REJECTION/);
});
test('mismatched kernel contract is rejected before preparation', () => {
  const { session: baseline } = fixture();
  assert.ok(baseline);
  const compiler = {
    psCompilerPrepareSource: () => ok({ declarations: [] }),
    psCompilerAdmissionsFromPrepared: () => ok(wire([])),
    psCompilerTypeScriptFromPrepared: () => ok(''),
  };
  assert.throws(
    () => createKernelCheckedSession(
      compiler,
      () => identity,
      leanCheckedIdentity,
      { ...kernelContractV1, id: 'proofscript-kernel-contract/2' },
    ),
    /KERNEL_CONTRACT_IDENTITY/,
  );
});
test('noncanonical admission envelope is rejected before provider invocation', async () => {
  let called = false;
  const compiler = {
    psCompilerPrepareSource: () => ok({ declarations: [] }),
    psCompilerAdmissionsFromPrepared: () => ok(JSON.stringify({
      admissions: [],
      format: 'wrong',
      version: 2,
    })),
    psCompilerTypeScriptFromPrepared: () => ok(''),
  };
  const session = createKernelCheckedSession(
    compiler,
    () => { called = true; return identity; },
  );
  await assert.rejects(session.check('lean', ''), /KERNEL_CONTRACT_ADMISSIONS_FORMAT/);
  assert.equal(called, false);
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
    psCompilerAdmissionsFromPrepared: () => ok(wire([{ generation: count++ }])),
    psCompilerTypeScriptFromPrepared: () => { calls.push('emit'); return ok('bad'); },
  };
  const session = createKernelCheckedSession(compiler, () => identity, leanCheckedIdentity);
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
  const session = createKernelCheckedSession(compiler, () => { called = true; return identity; });
  await assert.rejects(session.check('lean', ''), /RESULT_SHAPE/);
  assert.equal(called, false);
});
test('source text is a value, not a file read between check and emit', async () => {
  const { session, getPrepared } = fixture();
  let source = 'original'; const checked = await session.check('lean', source);
  source = 'changed'; session.emit(checked);
  assert.equal(getPrepared().declarations[0].value, 'original');
});

test('portable declaration requests require live JS authority, bounded inputs and exact frozen preparation', async () => {
  let calls = 0, prepared;
  const compiler = {
    psCompilerPrepareSource: () => { prepared = {}; return ok(prepared); },
    psCompilerAdmissionsFromPrepared: value => { assert.equal(value, prepared); return ok(wire([])); },
    psCompilerJavaScriptDeclarationsFromPrepared: (request, value) => {
      assert.equal(value, prepared); assert.equal(Object.isFrozen(value), true); calls++;
      assert.deepEqual(JSON.parse(request), ['psc-ts-declaration-request/1',
        'psc-direct-js-declarations-closed-structural/1', '512', []]);
      return ok('export {};\n');
    },
  };
  const session = createKernelCheckedSession(compiler, () => identity, leanCheckedIdentity,
    kernelContractV1, undefined, { targets: ['javascript'] });
  const handle = await session.check('lean', '');
  assert.equal(session.javaScriptDeclarations(handle, [], 512), 'export {};\n');
  assert.equal(calls, 1);
  assert.throws(() => session.javaScriptDeclarations({ ...handle }, [], 512), /UNCHECKED_MODULE/);
  assert.throws(() => session.javaScriptDeclarations(handle, [], 0), /REQUEST_RESOURCE/);
  assert.throws(() => session.javaScriptDeclarations(handle, Array(4097).fill({ sourceIndex: 0, exportName: 'x' }), 512), /REQUEST_RESOURCE/);
  assert.throws(() => session.javaScriptDeclarations(handle, [{ sourceIndex: 1000001, exportName: 'x' }], 512), /REQUEST_SHAPE/);
  assert.throws(() => session.javaScriptDeclarations(handle, [{ sourceIndex: 0, exportName: 'x'.repeat(512) }], 512), /REQUEST_RESOURCE/);
  assert.equal(calls, 1);
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = () => ok('x'.repeat(513));
  assert.throws(() => session.javaScriptDeclarations(handle, [], 512), /OUTPUT_RESOURCE/);
  compiler.psCompilerJavaScriptDeclarationsFromPrepared = () => { session.revoke(handle); return ok('export {};\n'); };
  assert.throws(() => session.javaScriptDeclarations(handle, [], 512), /UNCHECKED_MODULE/);
  const denied = fixture();
  const deniedHandle = await denied.session.check('lean', '');
  assert.throws(() => denied.session.javaScriptDeclarations(deniedHandle, [], 512), /TARGET_FORBIDDEN/);
});
