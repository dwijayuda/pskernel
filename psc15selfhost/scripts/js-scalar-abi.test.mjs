import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawnSync } from 'node:child_process';
import vm from 'node:vm';
import { artifactId, canonicalArtifact, canonicalBytes } from './artifact-evidence.mjs';
import { bindJsScalarImports, jsScalarAbiContract } from './js-scalar-abi.mjs';
import { jsAbiArtifactsFromVerifiedIr } from './js-abi-artifact.mjs';
import { artifactId as makeArtifactId } from './artifact-evidence.mjs';
import { irEncodingContract } from './ir-artifact.mjs';

const fixture = '.lake/build/bin/pscv_js_abi_tests' + (process.platform === 'win32' ? '.exe' : '');
function emitted(flag) {
  const result = spawnSync(fixture, [flag], { encoding: 'utf8', timeout: 30000, maxBuffer: 2 * 1024 * 1024 });
  assert.equal(result.status, 0, result.error?.message ?? result.stderr);
  return Buffer.from(result.stdout.trim());
}
const bytes = emitted('--plan'), value = JSON.parse(bytes);
const irBytes = emitted('--ir');
const verifiedIr = { bytes: irBytes, identity: makeArtifactId(irBytes, 'verified-ir', irEncodingContract) };

const plan = { bytes, identity: artifactId(bytes, 'abi-plan', jsScalarAbiContract) };
const providers = () => ({ host: Object.fromEntries(value.imports.map(entry => [entry.exportName, input => input])) });
function bind(overrides = {}) {
  return bindJsScalarImports({ plan, expectedPlanId: plan.identity, providers: providers(),
    grantedCapabilities: ['host-call'], ...overrides });
}


test('host-derived ABI plan matches portable planner for exact VerifiedIR and capability policy', () => {
  const derived = jsAbiArtifactsFromVerifiedIr(verifiedIr, {
    schemaVersion: 1,
    contract: 'psc-js-abi-host-policy/1',
    target: 'javascript',
    wordBits: 64,
    modules: [{ moduleId: 'host', capabilities: ['host-call'] }],
  });
  assert.deepEqual(Buffer.from(derived.plan.bytes), Buffer.from(bytes));
  assert.equal(derived.plan.identity.digest, plan.identity.digest);
  assert.throws(() => jsAbiArtifactsFromVerifiedIr(verifiedIr), /POLICY_MODULE_REQUIRED/);
  assert.throws(() => jsAbiArtifactsFromVerifiedIr(verifiedIr, {
    schemaVersion: 1, contract: 'psc-js-abi-host-policy/1', target: 'javascript', wordBits: 64,
    modules: [{ moduleId: 'host', capabilities: ['host-call'] }, { moduleId: 'unused', capabilities: [] }],
  }), /UNUSED_POLICY_MODULE/);
});

test('portable plan is canonical and adapters preserve every supported scalar representation', () => {
  assert.deepEqual(canonicalBytes(value), bytes);
  const bound = bind();
  assert.equal(Object.getPrototypeOf(bound), null);
  assert.equal(Object.isFrozen(bound), true);
  for (const [kind, samples] of Object.entries({
    nat: [0n, 2n ** 300n], int: [-(2n ** 300n), 0n], uint8: [0, 255], uint16: [0, 65535],
    uint32: [0, 4294967295], uint64: [0n, 2n ** 64n - 1n], usize: [0n, 2n ** 64n - 1n],
    int8: [-128, 127], int16: [-32768, 32767], int32: [-2147483648, 2147483647],
    int64: [-(2n ** 63n), 2n ** 63n - 1n], isize: [-(2n ** 63n), 2n ** 63n - 1n],
    float: [-0, NaN, Infinity, -Infinity, 0.1], float32: [-0, NaN, Infinity, Math.fround(0.1)],
    bool: [true, false], char: ['\0', 'A', '😀'], string: ['', 'A\0😀'], unit: [undefined],
  })) {
    for (const input of samples) assert.ok(Object.is(bound[kind](input), input), kind);
  }
  const bytes32 = emitted('--plan32'), plan32 = { bytes: bytes32, identity: artifactId(bytes32, 'abi-plan', jsScalarAbiContract) };
  const bound32 = bind({ plan: plan32, expectedPlanId: plan32.identity });
  assert.equal(bound32.usize(4294967295n), 4294967295n);
  assert.equal(bound32.isize(-2147483648n), -2147483648n);
  assert.throws(() => bound32.usize(4294967296n), /ARGUMENT/);
  assert.throws(() => bound32.isize(2147483648n), /ARGUMENT/);
});

test('invalid arguments never invoke a provider; invalid returns and promises reject', () => {
  let calls = 0;
  const selected = providers();
  for (const key of Object.keys(selected.host)) selected.host[key] = input => { calls++; return input; };
  const bound = bind({ providers: selected });
  for (const [kind, input] of [
    ['nat', -1n], ['int', 1], ['uint8', 256], ['uint16', -1], ['uint32', 3.5],
    ['uint32', -0], ['uint64', 2n ** 64n], ['int64', -(2n ** 63n) - 1n],
    ['bool', 1], ['float32', 0.1], ['float', '1'], ['char', 'ab'], ['char', '\ud800'],
    ['string', '\udfff'], ['unit', null],
  ]) assert.throws(() => bound[kind](input), /ARGUMENT/, kind);
  assert.throws(() => bound.uint32(), /ARITY/);
  assert.throws(() => bound.uint32(1, 2), /ARITY/);
  assert.equal(calls, 0);
  selected.host.uint32 = () => 1; // Existing binding snapshots the selected function.
  assert.equal(bound.uint32(9), 9);
  assert.equal(calls, 1);
  for (const result of [3.5, -1, '4', Promise.resolve(4)]) {
    assert.throws(() => bind({ providers: { ...providers(), host: { ...providers().host, uint32: () => result } } }).uint32(1), /RESULT/);
  }
  const failure = new Error('host failure');
  assert.throws(() => bind({ providers: { ...providers(), host: { ...providers().host, uint32: () => { throw failure; } } } }).uint32(1),
    error => error === failure);
});

test('consumer pin, capability policy, exact schema and data bindings fail closed', () => {
  const changed = canonicalArtifact({ ...value, wordBits: 32 }, 'abi-plan', jsScalarAbiContract);
  assert.throws(() => bind({ plan: changed }), /PLAN_ID/);
  assert.throws(() => bind({ plan: { ...plan, bytes: Buffer.from('bad') } }), /ARTIFACT_BYTES/);
  assert.throws(() => bind({ limits: { maxBytes: 1 } }), /PLAN_BYTES_LIMIT/);
  assert.throws(() => bind({ limits: { maxStringCodeUnits: 1 } }).string('ab'), /STRING_LIMIT/);
  assert.throws(() => bind({ limits: { maxIntegerBits: 4 } }).nat(16n), /INTEGER_LIMIT/);
  assert.throws(() => bind({ limits: { maxIntegerBits: -1 } }), /VALUE_LIMIT_POLICY/);
  let observed = 0;
  const hostile = { get host() { observed++; throw new Error('must not run'); } };
  assert.throws(() => bind({ providers: hostile, grantedCapabilities: [] }), /CAPABILITY_DENIED/);
  assert.throws(() => bind({ providers: hostile }), /BINDING/);
  assert.equal(observed, 0);
  assert.throws(() => bind({ providers: {} }), /BINDING/);
  assert.throws(() => bind({ grantedCapabilities: ['host-call', 'host-call'] }), /CAPABILITY_POLICY/);
  for (const candidate of [
    { ...value, unexpected: true },
    { ...value, imports: [...value.imports, value.imports[0]] },
    { ...value, imports: [{ ...value.imports[0], result: 'Array' }] },
    { ...value, imports: [{ ...value.imports[0], parameters: ['function'] }] },
  ]) {
    const altered = canonicalArtifact(candidate, 'abi-plan', jsScalarAbiContract);
    assert.throws(() => bind({ plan: altered, expectedPlanId: altered.identity }), /SCHEMA|IMPORT/);
  }
});

test('actual PSC JavaScript client calls the checked adapter and rejects bad host output', async () => {
  const source = emitted('--js').toString();
  let badResult = false;
  const bound = bind({ providers: { ...providers(), host: { ...providers().host,
    uint32: input => badResult ? 'wrong' : input + 1 } } });
  const context = vm.createContext(Object.create(null));
  const host = new vm.SyntheticModule(['uint32'], function () { this.setExport('uint32', bound.uint32); }, { context });
  const client = new vm.SourceTextModule(source, { context });
  await client.link(specifier => { assert.equal(specifier, 'host'); return host; });
  await client.evaluate();
  assert.equal(client.namespace.roundTrip(41), 42);
  assert.throws(() => client.namespace.roundTrip(-1), /ARGUMENT/);
  badResult = true;
  assert.throws(() => client.namespace.roundTrip(41), /RESULT/);
});
