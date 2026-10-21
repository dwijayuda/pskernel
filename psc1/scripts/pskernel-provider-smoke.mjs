import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { mkdtempSync, mkdirSync, copyFileSync, chmodSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';

const [mode, executable] = process.argv.slice(2);
if (!['native', 'js'].includes(mode) || !executable)
  throw Error('usage: node pskernel-provider-smoke.mjs native|js executable-or-kernel.js');
const target = path.resolve(executable);
const detached = mkdtempSync(path.join(tmpdir(), 'pskernel-provider-'));
let command, baseArgs;
if (mode === 'native') {
  command = path.join(detached, 'psc1_kernel_provider');
  copyFileSync(target, command);
  chmodSync(command, 0o755);
  baseArgs = [];
} else {
  mkdirSync(path.join(detached, 'scripts'));
  mkdirSync(path.join(detached, 'npm-runtime'));
  const provider = path.join(detached, 'scripts', 'pskernel-canonical-provider.mjs');
  copyFileSync(fileURLToPath(new URL('./pskernel-canonical-provider.mjs', import.meta.url)), provider);
  copyFileSync(fileURLToPath(new URL('../npm-runtime/canonical-admissions-wire.mjs', import.meta.url)),
    path.join(detached, 'npm-runtime', 'canonical-admissions-wire.mjs'));
  const kernel = path.join(detached, 'kernel.mjs');
  copyFileSync(target, kernel);
  writeFileSync(path.join(detached, 'package.json'), '{"type":"module"}\n');
  command = process.execPath;
  baseArgs = [provider, kernel];
}
try {
const anonymous = { k: 'a' };
const name = value => ({ k: 's', p: anonymous, v: value });
const z = { k: 'z' };
const sort = level => ({ k: 'sort', l: level });
const s0 = sort(z), s1 = sort({ k: 's', o: z });
const b = i => ({ k: 'b', i });
const constant = n => ({ k: 'const', n: name(n), ls: [] });
const definition = (n, type, value) => ({ kind: 'constant',
  declaration: { k: 'definition', n: name(n), lp: [], t: type, v: value,
    s: 'safe', h: { k: 'regular', h: '0' } } });
const binder = (k, n, t, body) => ({ k, n: name(n), t, b: body, bi: 'default' });
const identityType = binder('forall', 'P', s0, binder('forall', 'h', b(0), b(1)));
const identityProof = binder('lam', 'P', s0, binder('lam', 'h', b(0), b(0)));
const theorem = { kind: 'constant', declaration: {
  k: 'theorem', n: name('identityProof'), lp: [], t: identityType, v: identityProof } };
const first = definition('SortAlias', s1, s0);
const dependent = definition('AliasAgain', s1, constant('SortAlias'));
const enumName = name('UnitExample');
const enumType = { k: 'const', n: enumName, ls: [] };
const inductive = { kind: 'inductive', declaration: { lp: [], np: 0,
  ts: [{ n: enumName, t: s1,
    cs: [{ n: { k: 's', p: enumName, v: 'mk' }, t: enumType }] }] } };
const batch = admissions => JSON.stringify({
  format: 'proofscript-checked-admissions', version: 2, admissions,
});
function invoke(input, fuel) {
  const args = [...baseArgs];
  if (fuel !== undefined) args.push('--fuel', String(fuel));
  const result = spawnSync(command, args, {
    cwd: detached,
    input, encoding: 'utf8', timeout: 60000, killSignal: 'SIGKILL', maxBuffer: 4 * 1024 * 1024,
    env: { ...process.env, PATH: '' },
  });
  assert.ifError(result.error);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.signal, null);
  const value = JSON.parse(result.stdout);
  assert.equal(value.protocol, 'pskernel-canonical-provider/1');
  assert.equal(value.provider, 'pskernel-core-v1');
  assert.equal(value.leanVersion, '4.35.0');
  assert.equal(value.leanCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(value.scope, 'canonical-v2-empty-environment');
  assert.equal(value.fuel, String(fuel ?? 4096));
  return value;
}
const fixtures = [
  ['valid-batch', batch([first, dependent, theorem, inductive]), 'accepted', 'complete'],
  ['wrong-definition-type', batch([definition('Bad', s0, s0)]), 'rejectedInvalid', 'kernel'],
  ['invalid-proof', batch([{ ...theorem, declaration: { ...theorem.declaration, v: s0 } }]), 'rejectedInvalid', 'kernel'],
  ['late-duplicate', batch([first, first]), 'rejectedInvalid', 'kernel'],
  ['unknown-dependency', batch([dependent]), 'rejectedInvalid', 'kernel'],
  ['unsupported-axiom', batch([{ kind: 'constant', declaration: { k: 'axiom' } }]), 'declinedUnsupported', 'transport'],
  ['extra-unsafe-flag', batch([{ ...inductive, declaration: { ...inductive.declaration, isUnsafe: true } }]), 'declinedUnsupported', 'transport'],
  ['extra-recursor-metadata', batch([{ ...inductive, declaration: { ...inductive.declaration, recursors: [] } }]), 'declinedUnsupported', 'transport'],
  ['missing-required-safety', batch([{ kind: 'constant', declaration: Object.fromEntries(
    Object.entries(first.declaration).filter(([key]) => key !== 's')) }]), 'malformedInput', 'transport'],
  ['malformed-json', '{', 'malformedInput', 'transport'],
  ['malformed-natural', batch([definition('BadIndex', s1, b(-1))]), 'malformedInput', 'transport'],
  ['unsupported-version', JSON.stringify({ format: 'proofscript-checked-admissions', version: 99, admissions: [] }), 'declinedUnsupported', 'transport'],
];
for (const [label, input, outcome, stage] of fixtures) {
  const value = invoke(input);
  assert.equal(value.outcome, outcome, label + ' ' + JSON.stringify(value));
  assert.equal(value.stage, stage, label);
  assert.equal(value.accepted, outcome === 'accepted', label);
  if (value.accepted) {
    assert.equal(value.declarationCount, 4);
    assert.ok(value.environmentSize >= 6);
    assert.ok(!('message' in value) && !('declarationIndex' in value));
  } else {
    assert.equal(typeof value.message, 'string');
    assert.ok(!('session' in value) && !('environment' in value));
  }
  if (label === 'late-duplicate') assert.equal(value.declarationIndex, 1);
  console.log('PSC1_PROVIDER_CASE ' + JSON.stringify({ mode, label, ...value }));
}
for (const input of [batch([first]), batch([])]) {
  const value = invoke(input, 0);
  assert.equal(value.accepted, false);
  assert.equal(value.outcome, 'resourceExhausted');
  assert.equal(value.resource, 'fuel');
  assert.equal(value.stage, 'kernel');
  console.log('PSC1_PROVIDER_ZERO_FUEL ' + JSON.stringify({ mode, ...value }));
}
// Failed earlier processes never publish sessions; a fresh process accepts
// the same name, while a fresh process cannot see any former declaration.
assert.equal(invoke(batch([first])).accepted, true);
assert.equal(invoke(batch([dependent])).outcome, 'rejectedInvalid');
console.log('PSC1_CANONICAL_PROVIDER: PASS mode=' + mode + ' cases=16 PATH=empty cwd=detached');
} finally {
  rmSync(detached, { recursive: true, force: true });
}
