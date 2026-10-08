// Bounded, independently specified canonical admissions; no checker implementation.
export const name = text => text.split('.').reduce((p, v) => ({ k: 's', p, v }), { k: 'a' });
const c = (text, ls = []) => ({ k: 'const', n: name(text), ls });
const sort = l => ({ k: 'sort', l });
const z = { k: 'z' }, one = { k: 's', o: z };
const type = sort(one), nat = c('Nat');
const b = i => ({ k: 'b', i });
const lit = v => ({ k: 'nat', v: String(v) });
const app = (f, a) => ({ k: 'app', f, a });
const forall = (n, t, body) => ({ k: 'forall', n: name(n), t, b: body, bi: 'default' });
const lam = (n, t, body) => ({ k: 'lam', n: name(n), t, b: body, bi: 'default' });
const def = (n, t, v, lp = []) => ({ kind: 'constant', declaration: {
  k: 'definition', n: name(n), lp, s: 'safe', h: { k: 'regular', h: '1' }, t, v,
} });
const thm = (n, t, v) => ({ kind: 'constant', declaration: { k: 'theorem', n: name(n), lp: [], t, v } });
const ctor = (n, t) => ({ n: name(n), t });
const family = (n, t, cs) => ({ n: name(n), t, cs });
const ind = (...ts) => ({ kind: 'inductive', declaration: { lp: [], np: 0, ts } });
export const envelope = admissions => JSON.stringify({ format: 'proofscript-checked-admissions', version: 2, admissions });
const flag = ind(family('M4Flag', type, [ctor('M4Flag.off', c('M4Flag')), ctor('M4Flag.on', c('M4Flag'))]));
const record = ind(family('M4Record', type, [ctor('M4Record.mk', forall('x', nat, c('M4Record')))]));
const valid = (id, admissions) => ({ id, admissions, expected: 'accepted' });
const invalid = (id, admissions, index = 0) => ({ id, admissions, expected: `rejected:${index}` });

export const providerCorpus = [
  valid('empty-prelude', []),
  valid('large-natural', [def('M4Big', nat, lit(9007199254740993n))]),
  valid('polymorphic-identity', [def('M4Id', forall('A', type, forall('x', b(0), b(1))),
    lam('A', type, lam('x', b(0), b(0))))]),
  valid('universe-parameter', [def('M4Sort', sort({ k: 's', o: { k: 'p', n: name('u') } }),
    sort({ k: 'p', n: name('u') }), [name('u')])]),
  valid('beta-reduction', [def('M4Beta', nat, app(lam('x', nat, b(0)), lit(7)))]),
  valid('let-reduction', [def('M4Let', nat, { k: 'let', n: name('x'), t: nat, v: lit(8), b: b(0) })]),
  valid('theorem', [ind(family('M4Prop', sort(z), [ctor('M4Prop.intro', c('M4Prop'))])),
    thm('M4True', c('M4Prop'), c('M4Prop.intro'))]),
  valid('ordinary-inductive-and-use', [flag, def('M4On', c('M4Flag'), c('M4Flag.on'))]),
  valid('record-projection', [record, def('M4Proj', nat, {
    k: 'proj', n: name('M4Record'), i: 0, e: app(c('M4Record.mk'), lit(9)),
  })]),
  valid('indexed-inductive', [ind(family('M4Ix', forall('n', nat, type), [
    ctor('M4Ix.zero', app(c('M4Ix'), c('Nat.zero'))),
    ctor('M4Ix.step', forall('n', nat, forall('x', app(c('M4Ix'), b(0)),
      app(c('M4Ix'), app(c('Nat.succ'), b(1)))))),
  ]))]),
  valid('mutual-inductive', [ind(
    family('M4Even', type, [ctor('M4Even.zero', c('M4Even')), ctor('M4Even.next', forall('x', c('M4Odd'), c('M4Even')))]),
    family('M4Odd', type, [ctor('M4Odd.next', forall('x', c('M4Even'), c('M4Odd')))]),
  )]),
  valid('nested-inductive', [ind(family('M4Tree', type, [ctor('M4Tree.leaf', c('M4Tree')),
    ctor('M4Tree.branch', forall('xs', app(c('List'), c('M4Tree')), c('M4Tree')))]))]),
  invalid('wrong-definition-type', [def('M4Bad', nat, sort(z))]),
  invalid('unknown-constant', [def('M4Missing', nat, c('DefinitelyMissing'))]),
  invalid('loose-bound-variable', [def('M4Loose', nat, b(0))]),
  invalid('theorem-not-prop', [thm('M4NotProp', nat, lit(1))]),
  invalid('duplicate-declaration', [def('M4Dup', nat, lit(1)), def('M4Dup', nat, lit(2))], 1),
  invalid('prelude-name-collision', [def('Nat', type, nat)]),
  invalid('undeclared-universe', [def('M4Univ', sort({ k: 's', o: { k: 'p', n: name('u') } }), sort(z))]),
  invalid('bad-application', [def('M4App', nat, app(lit(1), lit(2)))]),
  invalid('late-rejection', [def('M4Good', nat, lit(1)), def('M4Later', nat, sort(z))], 1),
];

// Declared by prelude-extension-contract.json after the bundled WASM snapshot.
// Keep this visible as a capability difference, never as a parity success.
export const preludeExtensionFixture = valid('current-prelude-UInt8.ofNat', [
  def('M4Byte', c('UInt8'), app(c('UInt8.ofNat'), lit(42))),
]);
