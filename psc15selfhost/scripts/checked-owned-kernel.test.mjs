import assert from 'node:assert/strict';
import { test } from 'node:test';
import { checkAdmissionsWithKernel } from './checked-kernel-provider.mjs';
import { checkOwnedAdmissions } from './checked-owned-kernel.mjs';
import { createKernelCheckedSession } from './kernel-checked-session.mjs';
import { ownedCheckedIdentity, leanCheckedIdentity } from './checked-kernel-identity.mjs';

const name = v => ({ k: 's', p: { k: 'a' }, v });
const Z = { k: 'z' }, U = n => ({ k: 'sort', l: n ? { k: 's', o: Z } : Z });
const C = v => ({ k: 'const', n: name(v), ls: [] });
const B = i => ({ k: 'b', i });
const binder = (k, n, t, b) => ({ k, n: name(n), t, b, bi: 'default' });
const definition = (n, t, v) => ({ kind: 'constant', declaration: {
  k: 'definition', n: name(n), lp: [], t, v, s: 'safe', h: { k: 'regular', h: '1' },
} });
const wire = admissions => JSON.stringify({ format: 'proofscript-checked-admissions', version: 2, admissions });
const alias = () => definition('Alias', U(1), U(0));
const identityType = binder('forall', 'P', U(0), binder('forall', 'p', B(0), B(1)));
const identity = binder('lam', 'P', U(0), binder('lam', 'p', B(0), B(0)));

test('explicit owned kernel runs generated semantics for empty, dependent and sequential modules', async () => {
  for (const ds of [[], [alias()], [definition('Id', identityType, identity), definition('Use', identityType, C('Id'))]]) {
    const { result, descriptor } = await checkAdmissionsWithKernel(wire(ds), 'pskernel-core.old3');
    assert.equal(descriptor.selector, 'pskernel-core.old3');
    assert.equal(result.provider, 'psc-generated-owned');
    assert.equal(result.accepted, true, JSON.stringify(result));
    assert.equal(result.admissionCount, ds.length);
    assert.equal(result.generatedKernelSha256, ownedCheckedIdentity.generatedKernelSha256);
  }
});
for (const [label, ds, errorKind] of [
  ['type mismatch', [definition('Bad', U(0), U(0))], 'typeMismatch'],
  ['duplicate', [alias(), alias()], 'duplicateName'],
  ['self reference', [definition('A', U(1), C('A'))], 'unknownConstant'],
  ['forward reference', [definition('A', U(1), C('B')), definition('B', U(1), U(0))], 'unknownConstant'],
  ['unbound variable', [definition('A', U(1), B(0))], 'invalidScope'],
]) test(`owned admission rejects ${label}`, async () => {
  const result = await checkOwnedAdmissions(wire(ds));
  assert.equal(result.accepted, false);
  assert.equal(result.errorKind, errorKind);
  assert.equal(result.environment, undefined);
});
test('each check begins with only its checked prelude after a previous accepted check', async () => {
  assert.equal((await checkOwnedAdmissions(wire([alias()]))).accepted, true);
  assert.equal((await checkOwnedAdmissions(wire([definition('Use', U(1), C('Alias'))]))).errorKind, 'unknownConstant');
});
for (const [label, change] of [
  ['inductive', a => { a.kind = 'inductive'; }],
  ['axiom', a => { a.declaration.k = 'axiom'; }],
  ['opaque', a => { a.declaration.k = 'opaque'; }],
  ['unsafe', a => { a.declaration.s = 'unsafe'; }],
  ['duplicate universe parameters', a => { a.declaration.lp = [name('u'), name('u')]; }],
  ['universe parameter', a => { a.declaration.t.l = { k: 'p', n: name('u') }; }],
  ['literal at the wrong type', a => { a.declaration.v = { k: 'nat', v: '0' }; }],
  ['unknown field', a => { a.accepted = true; }],
  ['malformed height', a => { a.declaration.h.h = '-1'; }],
  ['lossy numeric name', a => { a.declaration.n = { k: 'n', p: { k: 'a' }, v: 1e30 }; }],
  ['invalid Unicode', a => { a.declaration.n.v = '\ud800'; }],
  ['prototype binder', a => { a.declaration.v = { ...identity, bi: '__proto__' }; }],
]) test(`unsupported or malformed ${label} cannot be accepted or fall back`, async () => {
  const a = alias(); change(a);
  const { result, descriptor } = await checkAdmissionsWithKernel(wire([a]), 'pskernel-core.old3');
  assert.equal(result.accepted, false, JSON.stringify(result));
  assert.equal(descriptor.selector, 'pskernel-core.old3');
  assert.equal(result.admissionIndex, 0);
});
test('structured names do not collide with dotted root names', async () => {
  const a = alias(), b = alias();
  a.declaration.n = name('A.B');
  b.declaration.n = { k: 's', p: name('A'), v: 'B' };
  assert.equal((await checkOwnedAdmissions(wire([a, b]))).accepted, true);
});

const param = n => ({ k: 'p', n: name(n) });
const polyType = l => binder('forall', 'A', { k: 'sort', l }, binder('forall', 'a', B(0), B(1)));
const polyValue = l => binder('lam', 'A', { k: 'sort', l }, binder('lam', 'a', B(0), B(0)));
const poly = () => {
  const d = definition('Poly', polyType(param('u')), polyValue(param('u')));
  d.declaration.lp = [name('u')];
  return d;
};
test('explicit owned kernel admits a polymorphic identity and checks distinct universe instantiations', async () => {
  for (const l of [Z, { k: 's', o: Z }, { k: 'max', l: Z, r: { k: 's', o: Z } }]) {
    const use = definition('Use', polyType(l), { ...C('Poly'), ls: [l] });
    const { result, descriptor } = await checkAdmissionsWithKernel(wire([poly(), use]), 'pskernel-core.old3');
    assert.equal(result.accepted, true, JSON.stringify(result));
    assert.equal(result.profile, 'owned-uniform-algebraic/11');
    assert.equal(descriptor.selector, 'pskernel-core.old3');
  }
});
for (const [label, levels, typeLevel, errorKind] of [
  ['missing', [], Z, 'invalidUniverse'],
  ['extra', [Z, Z], Z, 'invalidUniverse'],
  ['undeclared', [param('missing')], Z, 'invalidUniverse'],
  ['wrong type', [Z], { k: 's', o: Z }, 'typeMismatch'],
]) test(`explicit owned kernel rejects ${label} polymorphic instantiation without fallback`, async () => {
  const use = definition('Use', polyType(typeLevel), { ...C('Poly'), ls: levels });
  const { result, descriptor } = await checkAdmissionsWithKernel(wire([poly(), use]), 'pskernel-core.old3');
  assert.equal(descriptor.selector, 'pskernel-core.old3');
  assert.equal(result.accepted, false);
  assert.equal(result.errorKind, errorKind);
  assert.equal(result.admissionIndex, 1);
  assert.equal(result.environment, undefined);
});
test('polymorphic checking shares exhaustion bounds with ordinary admission', async () => {
  for (const maxSteps of [0, 1, 32]) {
    const result = await checkOwnedAdmissions(wire([poly()]), { maxSteps });
    assert.equal(result.accepted, false);
    assert.equal(result.errorKind, 'outOfFuel');
  }
});
test('exhaustion, timeout, malformed input and invalid limits cannot accept', async () => {
  for (const maxSteps of [0, 1, 2]) {
    assert.equal((await checkOwnedAdmissions(wire([alias()]), { maxSteps })).errorKind, 'outOfFuel');
  }
  assert.equal((await checkOwnedAdmissions(wire([alias()]), { timeoutMs: 1 })).accepted, false);
  assert.equal((await checkOwnedAdmissions('{')).accepted, false);
  for (const maxSteps of [-1, 0.5, Infinity, 100000001]) {
    await assert.rejects(checkOwnedAdmissions(wire([]), { maxSteps }), /resource limit/);
  }
});
test('owned checked module emits the exact frozen preparation and rejects transferable or foreign handles', async () => {
  const sym = Symbol('result'), ok = value => ({ [sym]: 'ok', value });
  let prepared, emitted = 0;
  const compiler = {
    psCompilerPrepareSource: () => ok(prepared = { value: 'original' }),
    psCompilerAdmissionsFromPrepared: item => { assert.equal(item, prepared); return ok(wire([alias()])); },
    psCompilerTypeScriptFromPrepared: item => {
      assert.equal(item, prepared); assert.equal(Object.isFrozen(item), true); emitted++;
      return ok('export const checked = true;');
    },
  };
  const session = createKernelCheckedSession(compiler, checkOwnedAdmissions, ownedCheckedIdentity);
  const handle = await session.check('lean', 'source');
  assert.equal(session.emit(handle), 'export const checked = true;');
  assert.equal(emitted, 1);
  assert.throws(() => session.emit({ ...handle }), /UNCHECKED_MODULE/);
  const wrong = createKernelCheckedSession(compiler, () => ({ ...leanCheckedIdentity, accepted: true }), ownedCheckedIdentity);
  await assert.rejects(wrong.check('lean', 'source'), /PROVIDER_IDENTITY/);
  assert.equal(emitted, 1);
});
