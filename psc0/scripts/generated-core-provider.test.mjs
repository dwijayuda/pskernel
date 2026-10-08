import assert from 'node:assert/strict';
import test from 'node:test';
import { createWireDecoder, parseCanonicalAdmissions,
  checkGeneratedAdmissionsWithPrelude } from './generated-core-provider.mjs';

const tag = Symbol('LeanAdt');
const ok = value => ({ [tag]: 'ok', value });
function mockKernel() {
  const obj = (kind, value) => Object.freeze({ kind, ...value });
  const K = {
    List: { nil: () => [], cons: (a, b) => [a, ...b] },
    PsKernelName: {
      anonymous: { kind: 'anon' },
      str: (p, v) => obj('str', { p, v }),
      num: (p, v) => obj('num', { p, v }),
    },
    PsKernelLevel: {
      zero: { kind: 'zero' },
      succ: o => obj('succ', { o }),
      max: (l, r) => obj('max', { l, r }),
      imax: (l, r) => obj('imax', { l, r }),
      param: n => obj('param', { n }),
    },
    PsKernelLiteral: {
      nat: v => obj('nat', { v }),
      str: v => obj('str', { v }),
    },
    PsKernelBinderInfo: {
      default: 'default', implicit: 'implicit',
      strictImplicit: 'strictImplicit', instImplicit: 'instImplicit',
    },
    PsKernelExpr: Object.fromEntries(
      ['bvar', 'sort', 'const', 'app', 'lam', 'forallE', 'letE', 'lit', 'proj']
        .map(k => [k, (...args) => ({ kind: k, args })]),
    ),
    PsKernelReducibilityHints: { regular: h => ({ height: h }) },
    PsKernelDefinitionSafety: { safe: 'safe' },
    PsKernelDeclarationRequest: Object.fromEntries(
      ['axiomDecl', 'definitionDecl', 'theoremDecl', 'opaqueDecl',
        'nestedInductive', 'ordinaryInductive'].map(k => [k, value => obj(k, { value })]),
    ),
    psKernelResourcePolicyDefault: { fuel: 4096n, maxRecDepth: 0n },
    psKernelProviderDefault: { name: 'mock' },
    psKernelKernelSessionEmpty: (resources) => ok({ resources, environment: [] }),
    psKernelV1AdmitDeclaration: (session, request) =>
      ok({ session: { ...session, environment: [...session.environment, request] } }),
  };
  return K;
}
const name = v => ({ k: 's', p: { k: 'a' }, v });
const nat = { k: 'const', n: name('Nat'), ls: [] };
const env = [{
  kind: 'axiom', name: 'Nat', nameWire: name('Nat'),
  levelParameterWires: [], type: { k: 'sort', l: { k: 's', o: { k: 'z' } } },
  value: null, metadata: null,
}];
const envelope = admissions => JSON.stringify({
  format: 'proofscript-checked-admissions', version: 2, admissions,
});

test('canonical decoder retains large Nat precision and structured names', () => {
  const K = mockKernel();
  const d = createWireDecoder(K);
  assert.equal(d.name({ k: 'n', p: name('Foo'), v: '9007199254740993' }).v, 9007199254740993n);
  assert.equal(d.expr({ k: 'nat', v: '9007199254740993' }).args[0].v, 9007199254740993n);
  assert.equal(d.expr({ k: 'let', n: name('x'), t: nat, v: { k: 'nat', v: '3' },
    b: { k: 'b', i: 0 } }).args[4], false);
  assert.equal(d.expr({ k: 'forall', n: name('x'), t: nat,
    b: nat, bi: 'instImplicit' }).args[3], 'instImplicit');
});

test('fail closed on unknown wire forms and invalid natural text', () => {
  const d = createWireDecoder(mockKernel());
  for (const invalid of [{ k: 'mvar' }, { k: 'nat', v: '01' }, { k: 'nat', v: '-5' }]) {
    assert.throws(() => d.expr(invalid), /PSC0_GENERATED_CORE_/u);
  }
  assert.throws(() => d.name({ k: 'n', p: { k: 'a' }, v: '-1' }), /INVALID_NATURAL/u);
  assert.throws(() => parseCanonicalAdmissions(envelope([]).replace('"version":2', '"version":1')),
    /ADMISSIONS_VERSION/u);
});

test('generated-JS checker candidate replays the prelude and checks canonical admissions', () => {
  const K = mockKernel();
  const decl = { kind: 'constant', declaration: {
    k: 'definition', n: name('Foo'), lp: [], t: nat,
    v: { k: 'nat', v: '42' }, h: { k: 'regular', h: '0' }, s: 'safe',
  } };
  const result = checkGeneratedAdmissionsWithPrelude(K, envelope([decl]), env);
  assert.equal(result.accepted, true);
  assert.equal(result.declarationCount, 1);
});

test('mock generated checker cannot accept arbitrary input and rejects unsafe definitions', () => {
  const K = mockKernel();
  const bad = { kind: 'constant', declaration: {
    k: 'definition', n: name('Bar'), lp: [], t: nat, v: { k: 'nat', v: '1' },
    h: { k: 'regular', h: '0' }, s: 'unsafe',
  } };
  assert.throws(() => checkGeneratedAdmissionsWithPrelude(K, envelope([bad]), env),
    /UNSUPPORTED_DEFINITION/u);
  assert.throws(() => checkGeneratedAdmissionsWithPrelude(K, '{"format":"bad","version":2,"admissions":[]}', env),
    /ADMISSIONS_VERSION/u);
  assert.throws(() => checkGeneratedAdmissionsWithPrelude(K, envelope([]), []), /PRELUDE_SHAPE/u);
});
