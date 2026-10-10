import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { createCheckedPreparedSession, leanCheckedIdentity } from './checked-prepared-session.mjs';
import { coreCheckedIdentity } from './checked-kernel-identity.mjs';

const tag = Symbol('Except');
const ok = value => ({ [tag]: 'ok', value });
const identity = { protocol: 'pskernel-lean/1', provider: 'lean4-cpp',
  leanVersion: '4.34.0', leanCommit: '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b',
  profile: 'lean4.34-core', accepted: true };
const defaultIrOptions = Object.freeze({
  maxSteps: 5000000n, maxTypeSteps: 65536n, maxFindings: 1000n,
});
const makeIrOptions = (maxSteps, maxTypeSteps, maxFindings) =>
  ({ maxSteps, maxTypeSteps, maxFindings });
const checkedOptionsApi = {
  psIrCheckDefaultOptions: defaultIrOptions,
  psIrCheckOptionsWithLimits: makeIrOptions,
};
function fixture(provider = () => identity, configure = () => {}) {
  const calls = []; const optionCalls = []; let prepared; let constructedOptions;
  const compiler = {
    ...checkedOptionsApi,
    psIrCheckOptionsWithLimits(...limits) {
      optionCalls.push(limits);
      constructedOptions = makeIrOptions(...limits);
      return constructedOptions;
    },
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
    psCompilerCheckedTypeScriptFromPrepared(options, value) {
      assert.equal(options, constructedOptions);
      assert.ok(Object.isFrozen(options));
      assert.equal(value, prepared);
      calls.push('checked-emit');
      return ok('export const answer = 42n;');
    },
    psCompilerTypeScriptFromPrepared() {
      calls.push('raw-emit');
      throw new Error('raw emission must never be used');
    },
  };
  configure(compiler);
  const session = createCheckedPreparedSession(compiler, admissions => {
    calls.push('kernel'); return provider(admissions, prepared);
  }, leanCheckedIdentity);
  return { session, calls, compiler, optionCalls, getPrepared: () => prepared };
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
  assert.deepEqual(calls, ['prepare-modules', 'encode', 'kernel', 'encode', 'checked-emit']);
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
  assert.deepEqual(calls, ['prepare', 'encode', 'kernel', 'encode', 'checked-emit']);
  assert.match(checked.canonicalAdmissionsSha256, /^[0-9a-f]{64}$/);
  assert.equal(checked.provider.profile, 'lean4.34-core');
});
test('no emission after kernel rejection', async () => {
  const { session, calls } = fixture(() => ({ ...identity, accepted: false, errorKind: 'kernel-rejection' }));
  await assert.rejects(session.check('lean', '42'), /KERNEL_REJECTED/);
  assert.ok(!calls.includes('checked-emit'));
});
test('provider failure does not fall back', async () => {
  const { session, calls } = fixture(() => { throw new Error('provider unavailable'); });
  await assert.rejects(session.check('lean', '42'), /provider unavailable/);
  assert.equal(calls.filter(x => x === 'kernel').length, 1);
  assert.ok(!calls.includes('checked-emit'));
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
    ...checkedOptionsApi,
    psCompilerPrepareSource: () => ok({ declarations: [] }),
    psCompilerAdmissionsFromPrepared: () => ok(String(count++)),
    psCompilerCheckedTypeScriptFromPrepared: () => { calls.push('checked-emit'); return ok('bad'); },
  };
  const session = createCheckedPreparedSession(compiler, () => identity, leanCheckedIdentity);
  const checked = await session.check('lean', '42');
  assert.throws(() => session.emit(checked), /CHECKED_PAYLOAD_CHANGED/);
  assert.deepEqual(calls, []);
});
test('malformed frontend result fails before checker', async () => {
  let called = false;
  const compiler = {
    ...checkedOptionsApi,
    psCompilerPrepareSource: () => ({ value: {} }),
    psCompilerAdmissionsFromPrepared: () => ok(''),
    psCompilerCheckedTypeScriptFromPrepared: () => ok(''),
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

test('checked emission constructs own-compiler options and returns exact scoped evidence', async () => {
  const { session, calls, optionCalls } = fixture();
  const handle = await session.check('lean', '42');
  const result = session.emitChecked(handle);
  assert.deepEqual(optionCalls, [[5000000n, 65536n, 1000n]]);
  assert.deepEqual(calls, ['prepare', 'encode', 'kernel', 'encode', 'checked-emit']);
  assert.equal(result.typeScript, 'export const answer = 42n;');
  assert.equal(result.validation.kind, 'psc0-runtime-ir-checked-emission');
  assert.equal(result.validation.emitter, 'psCompilerCheckedTypeScriptFromPrepared');
  assert.equal(result.validation.sourceSha256, handle.sourceSha256);
  assert.equal(result.validation.canonicalAdmissionsSha256, handle.canonicalAdmissionsSha256);
  assert.equal(result.validation.typeScriptSha256,
    createHash('sha256').update(result.typeScript, 'utf8').digest('hex'));
  assert.equal(result.validation.runtimeIrTypingAccepted, true);
  assert.equal(result.validation.traversalComplete, true);
  assert.equal(result.validation.sameOriginalIrCheckedBeforeEmission, true);
  assert.equal(result.validation.strictSh1Qualified, false);
  assert.equal(result.validation.semanticContractQualified, false);
  assert.deepEqual(result.validation.options, {
    maxSteps: 5000000, maxTypeSteps: 65536, maxFindings: 1000,
  });
  assert.doesNotThrow(() => JSON.stringify(result.validation));
  assert.ok(Object.isFrozen(result));
  assert.ok(Object.isFrozen(result.validation));
  assert.ok(Object.isFrozen(result.validation.options));
  assert.throws(() => { result.typeScript = 'changed'; }, TypeError);
  assert.throws(() => { result.validation.runtimeIrTypingAccepted = false; }, TypeError);
  assert.throws(() => { result.validation.options.maxSteps = 1; }, TypeError);
  assert.throws(() => session.emitChecked(result.validation), /UNCHECKED_MODULE/);
});

test('missing checked emitter cannot fall back to the raw compiler API', () => {
  assert.throws(() => fixture(undefined, compiler => {
    delete compiler.psCompilerCheckedTypeScriptFromPrepared;
  }), /CHECKED_API_MISSING: psCompilerCheckedTypeScriptFromPrepared/);
});

test('checked options must use the compiler factory', () => {
  assert.throws(() => fixture(undefined, compiler => {
    delete compiler.psIrCheckOptionsWithLimits;
  }), /CHECKED_API_MISSING: psIrCheckOptionsWithLimits/);
});

for (const [label, defaults] of [
  ['missing record', undefined],
  ['null record', null],
  ['number carrier', { ...defaultIrOptions, maxSteps: 1 }],
  ['negative limit', { ...defaultIrOptions, maxTypeSteps: -1n }],
  ['unsafe evidence count', { ...defaultIrOptions, maxFindings: BigInt(Number.MAX_SAFE_INTEGER) + 1n }],
]) {
  test('malformed default IR limits refuse before preparation: ' + label, () => {
    assert.throws(() => fixture(undefined, compiler => {
      compiler.psIrCheckDefaultOptions = defaults;
    }), /CHECKED_IR_OPTIONS_DEFAULTS/);
  });
}

test('an options factory cannot silently change the recorded checking limits', () => {
  assert.throws(() => fixture(undefined, compiler => {
    compiler.psIrCheckOptionsWithLimits = (...limits) => ({
      ...makeIrOptions(...limits), maxSteps: 1n,
    });
  }), /CHECKED_IR_OPTIONS_RESULT: maxSteps/);
});

test('checked emitter rejection produces neither output nor validation and has no fallback', async () => {
  let attempted = 0;
  const { session, calls } = fixture(undefined, compiler => {
    compiler.psCompilerCheckedTypeScriptFromPrepared = () => {
      attempted++;
      return { [tag]: 'error', error: { reason: 'runtime IR rejected' } };
    };
  });
  const handle = await session.check('lean', '42');
  assert.throws(() => session.emitChecked(handle), /CHECKED_EMIT_FAILED/);
  assert.throws(() => session.emit(handle), /CHECKED_EMIT_FAILED/);
  assert.equal(attempted, 2);
  assert.ok(!calls.includes('raw-emit'));
});

test('an accepted flag or malformed result cannot substitute for checked output', async () => {
  const { session, calls } = fixture(undefined, compiler => {
    compiler.psCompilerCheckedTypeScriptFromPrepared = () =>
      ok({ accepted: true, traversalComplete: true, typeScript: 'unchecked' });
  });
  const handle = await session.check('lean', '42');
  assert.throws(() => session.emitChecked(handle), /CHECKED_EMIT_RESULT_SHAPE/);
  assert.ok(!calls.includes('raw-emit'));
});

test('validation-returning emission retains private handle and admission readback checks', async () => {
  const { session, compiler, calls } = fixture();
  const handle = await session.check('lean', '42');
  assert.throws(() => session.emitChecked({ ...handle }), /UNCHECKED_MODULE/);
  assert.throws(() => fixture().session.emitChecked(handle), /UNCHECKED_MODULE/);
  compiler.psCompilerAdmissionsFromPrepared = () => ok('changed');
  assert.throws(() => session.emitChecked(handle), /CHECKED_PAYLOAD_CHANGED/);
  assert.ok(!calls.includes('checked-emit'));
});

test('the default prepared session requires the active PSKernel Core identity', async () => {
  const { compiler } = fixture();
  const session = createCheckedPreparedSession(compiler, () => ({
    ...coreCheckedIdentity, accepted: true,
  }));
  const handle = await session.check('lean', '42');
  assert.deepEqual(handle.provider, coreCheckedIdentity);
  assert.equal(handle.provider.protocol, 'pskernel-core/1');
  assert.equal(handle.provider.provider, 'pskernel-core-native');
  assert.equal(handle.provider.profile, 'lean4.34-core');
  assert.equal(session.emitChecked(handle).validation.runtimeIrTypingAccepted, true);
});

test('the default prepared session cannot accept the legacy owned provider', async () => {
  const { compiler } = fixture();
  const session = createCheckedPreparedSession(compiler, () => ({
    ...coreCheckedIdentity, provider: 'psc-generated-owned', accepted: true,
  }));
  await assert.rejects(session.check('lean', '42'), /PROVIDER_IDENTITY: provider/);
});


function projectFixture(provider) {
  return fixture(provider, compiler => {
    compiler.psCompilerMakeProjectSource = (sourceId, source, exports) => ({ sourceId, source, exports });
    compiler.psCompilerPrepareProject = (kind, inputs) => {
      const units = [];
      for (let cursor = inputs; cursor !== null; cursor = cursor.tail) {
        const unit = cursor.head, names = [];
        for (let list = unit.exports; list !== null; list = list.tail) names.push(list.head);
        units.push({ sourceId: unit.sourceId, source: unit.source, exports: names });
      }
      let sources = null;
      for (const unit of [...units].reverse()) sources = compiler.List.cons(unit.source, sources);
      const prepared = compiler.psCompilerPrepareSources(kind, sources).value;
      return ok({ prepared, units });
    };
    compiler.psCompilerProjectAdmissionsFromPrepared = project =>
      compiler.psCompilerAdmissionsFromPrepared(project.prepared);
    compiler.psCompilerCheckedTypeScriptProjectFromPrepared = (options, project) => {
      const bundle = compiler.psCompilerCheckedTypeScriptFromPrepared(options, project.prepared).value;
      return ok(JSON.stringify({ profile: 'psc-ts-library/1', bundle,
        modules: project.units.filter(unit => unit.exports.length).map(unit => ({
          sourceId: unit.sourceId,
          exports: unit.exports.map(name => ({ name, kind: 'value', binding: 'answer' })),
        })) }));
    };
  });
}
test('project sessions capture ownership selection and retain the same mandatory admission boundary', async () => {
  const { session, calls } = projectFixture();
  const units = [{ sourceId: 'Main.ps', source: '42', exports: ['answer'] }];
  const pending = session.checkProject('ps', units);
  units[0].exports[0] = 'changed';
  const handle = await pending;
  assert.throws(() => session.emitChecked(handle), /LIBRARY_EMISSION_MODE/);
  assert.throws(() => session.emitProjectChecked({ ...handle }), /UNCHECKED_MODULE/);
  const result = session.emitProjectChecked(handle);
  assert.deepEqual(result.library.modules[0].exports, [{ name: 'answer', kind: 'value', binding: 'answer' }]);
  assert.equal(result.validation.publicInterfaceSha256, result.library.publicInterfaceSha256);
  assert.equal(result.validation.emitter, 'psCompilerCheckedTypeScriptProjectFromPrepared');
  assert.deepEqual(calls, ['prepare-modules', 'encode', 'kernel', 'encode', 'checked-emit']);
});
test('project preparation cannot turn kernel refusal into a public library', async () => {
  const { session, calls } = projectFixture(() => ({ ...identity, accepted: false }));
  await assert.rejects(session.checkProject('ps', [{ sourceId: 'Main.ps', source: '42', exports: ['answer'] }]),
    /KERNEL_REJECTED/);
  assert.deepEqual(calls, ['prepare-modules', 'encode', 'kernel']);
});
