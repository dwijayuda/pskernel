import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';

// F1 only: bounded fresh-name behavior in two already loaded generated modules.
// The caller supplies exact compiler identities and records the returned receipt.
// This file does not load modules, access the filesystem, or launch a compiler.
// Complete public-type/IR and compiled PSC partial-application checks are separate.
const sha256 = (value) => createHash('sha256').update(value).digest('hex');

// The TypeScript backend emits structures as interfaces plus private brands,
// not runtime Type.mk namespaces. Check every callable fixture dependency before
// allocating inputs, including when this F1 section is used on its own.
export const sh1FreshNameRequiredExports = Object.freeze([
  'List.cons', 'List.nil', 'PsName.str',
  'PsVerifiedIrType.primitive', 'PsVerifiedIrLiteral.natural',
  'PsVerifiedIrExpr.literal', 'PsVerifiedIrExpr.var', 'PsVerifiedIrExpr.record',
  'PsVerifiedIrExpr.lambda', 'PsVerifiedIrExpr.letE', 'PsVerifiedIrExpr.projection',
  'psIrCheckMakePair', 'psIrCheckMakeParameter',
  'psErasureLocalNameWithFuel', 'psErasureEtaNameWithFuel',
  'psTsFreshMatchTempWorker', 'psTsFreshInternalWorker',
  'psErasureScopeEmpty', 'psErasureLocalName', 'psErasureEtaParameters',
  'psTsFreshMatchTempLoop', 'psTsFreshInternalWithFuel',
]);

export function assertMigrationRequiredExports(compiler, names, label) {
  const missing = names.filter((name) => {
    const value = name.split('.').reduce((owner, key) => owner?.[key], compiler);
    return typeof value !== 'function';
  });
  assert.deepEqual(missing, [], 'PSC0_SH1_MIGRATION_REQUIRED_EXPORTS_' + label);
}

function tag(value) {
  if (value === null || typeof value !== 'object') return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    if (typeof value[symbol] === 'string') return value[symbol];
  }
  return undefined;
}

function list(runtime, values) {
  return values.reduceRight((tail, head) => runtime.List.cons(head, tail), runtime.List.nil());
}

function array(value) {
  const output = [];
  while (tag(value) === 'cons') {
    assert(output.length < 10000, 'PSC0_SH1_F1_LIST_BOUND');
    output.push(value.head);
    value = value.tail;
  }
  assert.equal(tag(value), 'nil', 'PSC0_SH1_F1_LIST_SHAPE');
  return output;
}

function natType(runtime) {
  return runtime.PsVerifiedIrType.primitive(runtime.PsVerifiedIrPrimitiveType.nat);
}

function parameter(runtime, name) {
  return runtime.psIrCheckMakeParameter(name, natType(runtime));
}

function scope(runtime, localNames, globalNames) {
  const declarations = list(runtime, globalNames.map((output, index) => runtime.psIrCheckMakePair(
    runtime.PsName.str(runtime.PsName.anonymous, 'declaration' + index), output)));
  const empty = runtime.psErasureScopeEmpty(declarations);
  // Spread retains this compiler's scope brand and every untouched field.
  return {
    ...empty,
    runtimeLocals: list(runtime, localNames.map((name, index) =>
      runtime.psIrCheckMakePair(BigInt(index), name))),
  };
}

function makeBodyFactory(runtime) {
  const expr = runtime.PsVerifiedIrExpr;
  const literal = () => expr.literal(runtime.PsVerifiedIrLiteral.natural(0n));
  const nil = list(runtime, []);
  // A chain is constructed once per module, with no shared tagged values across
  // modules. At 4095 projections the leaf is inspected; at 4096 the existing
  // conservative 4096-step name scan reaches zero before inspecting the leaf.
  const depth = [literal()];
  return (fixture) => {
    const [kind, value] = fixture;
    switch (kind) {
      case 'literal': return literal();
      case 'var': return expr.var(value);
      case 'values':
        return expr.record('Record', nil, list(runtime, value.map((name, index) =>
          runtime.psIrCheckMakePair('field' + index, expr.var(name)))));
      case 'field-label':
        return expr.record('Record', nil, list(runtime, [runtime.psIrCheckMakePair(value, literal())]));
      case 'lambda-binder':
        return expr.lambda(list(runtime, [parameter(runtime, value)]), natType(runtime), literal());
      case 'let-binder':
        return expr.letE(value, natType(runtime), literal(), literal());
      case 'depth':
        assert(Number.isSafeInteger(value) && value >= 0 && value <= 4096, 'PSC0_SH1_F1_DEPTH');
        while (depth.length <= value) {
          depth.push(expr.projection('Record', nil, depth.at(-1), 'field'));
        }
        return depth[value];
      default: throw new Error('PSC0_SH1_F1_UNKNOWN_BODY_FIXTURE: ' + kind);
    }
  };
}

// Entries contain explicit independent expectations, not calls to a second
// implementation of the worker. Nat inputs are decimal strings for stable JSON.
const localCases = [
  { name: 'local-zero-fresh', locals: [], globals: [], base: 'x', fuel: '0', index: '0', expected: 'x$0' },
  { name: 'local-zero-colliding', locals: ['x$7'], globals: ['x$7'], base: 'x', fuel: '0', index: '7', expected: 'x$7' },
  { name: 'local-first-free', locals: [], globals: [], base: 'x', fuel: '1', index: '7', expected: 'x$7' },
  { name: 'local-exhaustion-can-collide', locals: ['x$7'], globals: ['x$8'], base: 'x', fuel: '1', index: '7', expected: 'x$8' },
  { name: 'local-global-collision-chain', locals: ['x$7'], globals: ['x$8'], base: 'x', fuel: '3', index: '7', expected: 'x$9' },
  { name: 'local-global-only-collision', locals: [], globals: ['x$4'], base: 'x', fuel: '2', index: '4', expected: 'x$5' },
  { name: 'local-duplicates-consume-one-candidate', locals: ['x$4', 'x$4'], globals: ['x$4', 'x$5'], base: 'x', fuel: '3', index: '4', expected: 'x$6' },
  { name: 'local-future-collision-does-not-skip-free', locals: ['x$8'], globals: [], base: 'x', fuel: '3', index: '7', expected: 'x$7' },
  { name: 'local-arbitrary-base', locals: ['é_$2'], globals: [], base: 'é_', fuel: '2', index: '2', expected: 'é_$3' },
  { name: 'local-large-nat-index', locals: [], globals: [], base: 'x', fuel: '1', index: '9007199254740993', expected: 'x$9007199254740993' },
];

const etaCases = [
  { name: 'eta-zero', used: [], body: ['literal'], fuel: '0', index: '0', expected: ['error', 'fuelExhausted'] },
  { name: 'eta-first-free', used: [], body: ['literal'], fuel: '1', index: '4', expected: ['ok', '__ps_eta_4'] },
  { name: 'eta-used-exhausts', used: ['__ps_eta_4'], body: ['literal'], fuel: '1', index: '4', expected: ['error', 'fuelExhausted'] },
  { name: 'eta-used-collision', used: ['__ps_eta_4'], body: ['literal'], fuel: '2', index: '4', expected: ['ok', '__ps_eta_5'] },
  { name: 'eta-body-collision', used: [], body: ['var', '__ps_eta_4'], fuel: '2', index: '4', expected: ['ok', '__ps_eta_5'] },
  { name: 'eta-used-and-body-chain', used: ['__ps_eta_4', '__ps_eta_4'], body: ['var', '__ps_eta_5'], fuel: '3', index: '4', expected: ['ok', '__ps_eta_6'] },
  { name: 'eta-lambda-binder-counts', used: [], body: ['lambda-binder', '__ps_eta_4'], fuel: '2', index: '4', expected: ['ok', '__ps_eta_5'] },
  { name: 'eta-let-binder-counts', used: [], body: ['let-binder', '__ps_eta_4'], fuel: '2', index: '4', expected: ['ok', '__ps_eta_5'] },
  { name: 'eta-record-label-does-not-count', used: [], body: ['field-label', '__ps_eta_4'], fuel: '1', index: '4', expected: ['ok', '__ps_eta_4'] },
  { name: 'eta-last-inspected-depth', used: [], body: ['depth', 4095], fuel: '1', index: '4', expected: ['ok', '__ps_eta_4'] },
  { name: 'eta-conservative-depth-exhaustion', used: [], body: ['depth', 4096], fuel: '2', index: '4', expected: ['error', 'fuelExhausted'] },
  { name: 'eta-zero-with-deep-body', used: ['__ps_eta_4'], body: ['depth', 4096], fuel: '0', index: '4', expected: ['error', 'fuelExhausted'] },
  { name: 'eta-large-nat-index', used: [], body: ['literal'], fuel: '1', index: '9007199254740993', expected: ['ok', '__ps_eta_9007199254740993'] },
];

const matchCases = [
  { name: 'match-zero', body: ['literal'], attempts: '0', index: '7', expected: '__ps$match$overflow' },
  { name: 'match-zero-colliding-overflow', body: ['var', '__ps$match$overflow'], attempts: '0', index: '7', expected: '__ps$match$overflow' },
  { name: 'match-first-free', body: ['literal'], attempts: '1', index: '7', expected: '__ps$match$7' },
  { name: 'match-collision-exhausts', body: ['var', '__ps$match$7'], attempts: '1', index: '7', expected: '__ps$match$overflow' },
  { name: 'match-collision-chain', body: ['values', ['__ps$match$7', '__ps$match$8']], attempts: '3', index: '7', expected: '__ps$match$9' },
  { name: 'match-lambda-binder-counts', body: ['lambda-binder', '__ps$match$7'], attempts: '2', index: '7', expected: '__ps$match$8' },
  { name: 'match-record-label-does-not-count', body: ['field-label', '__ps$match$7'], attempts: '1', index: '7', expected: '__ps$match$7' },
  { name: 'match-last-inspected-depth', body: ['depth', 4095], attempts: '1', index: '7', expected: '__ps$match$7' },
  { name: 'match-conservative-depth-exhaustion', body: ['depth', 4096], attempts: '2', index: '7', expected: '__ps$match$overflow' },
  { name: 'match-large-nat-index', body: ['literal'], attempts: '1', index: '9007199254740993', expected: '__ps$match$9007199254740993' },
];

const internalCases = [
  { name: 'internal-zero', used: [], prefix: 'p', attempts: '0', index: '7', expected: ['poverflow', '8'] },
  { name: 'internal-zero-colliding-overflow', used: ['poverflow'], prefix: 'p', attempts: '0', index: '7', expected: ['poverflow', '8'] },
  { name: 'internal-first-free', used: [], prefix: 'p', attempts: '1', index: '7', expected: ['p7', '8'] },
  { name: 'internal-one-collision-exhausts', used: ['p7'], prefix: 'p', attempts: '1', index: '7', expected: ['poverflow', '9'] },
  { name: 'internal-all-collisions-exhaust', used: ['p7', 'p8', 'p9'], prefix: 'p', attempts: '3', index: '7', expected: ['poverflow', '11'] },
  { name: 'internal-first-free-after-chain', used: ['p7', 'p8'], prefix: 'p', attempts: '3', index: '7', expected: ['p9', '10'] },
  { name: 'internal-duplicate-used-names', used: ['p7', 'p7'], prefix: 'p', attempts: '2', index: '7', expected: ['p8', '9'] },
  { name: 'internal-future-collision-does-not-skip-free', used: ['p8'], prefix: 'p', attempts: '3', index: '7', expected: ['p7', '8'] },
  { name: 'internal-empty-prefix', used: ['0', '1'], prefix: '', attempts: '3', index: '0', expected: ['2', '3'] },
  { name: 'internal-arbitrary-prefix', used: ['é_$7'], prefix: 'é_$', attempts: '2', index: '7', expected: ['é_$8', '9'] },
  { name: 'internal-large-nat-index', used: [], prefix: 'p', attempts: '1', index: '9007199254740993', expected: ['p9007199254740993', '9007199254740994'] },
];

const localWrapperCases = [
  { name: 'wrapper-reserved-arguments', locals: [], globals: [], raw: 'arguments', fallback: 'decl', index: '3', expected: '_arguments' },
  { name: 'wrapper-reserved-eval-collision', locals: [], globals: ['_eval'], raw: 'eval', fallback: 'decl', index: '3', expected: '_eval$3' },
  { name: 'wrapper-underscore-fallback', locals: ['tmp$11'], globals: [], raw: '_', fallback: 'tmp', index: '11', expected: 'tmp$12' },
  { name: 'wrapper-sanitized-global-collision', locals: [], globals: ['x_y'], raw: 'x-y', fallback: 'decl', index: '3', expected: 'x_y$3' },
];

function freshResult(value) {
  assert.equal(typeof value.name, 'string', 'PSC0_SH1_F1_RESULT_NAME');
  assert.equal(typeof value.nextIndex, 'bigint', 'PSC0_SH1_F1_RESULT_INDEX');
  return [value.name, value.nextIndex.toString()];
}

function etaResult(value) {
  if (tag(value) === 'ok') {
    assert.equal(typeof value.value, 'string', 'PSC0_SH1_F1_ETA_VALUE');
    return ['ok', value.value];
  }
  assert.equal(tag(value), 'error', 'PSC0_SH1_F1_ETA_RESULT');
  return ['error', tag(value.error)];
}

function inspectRuntime(runtime, label) {
  assertMigrationRequiredExports(runtime, sh1FreshNameRequiredExports, 'F1_' + label);
  const body = makeBodyFactory(runtime);
  const observations = [];
  function observe(name, actual, expected) {
    assert.deepEqual(actual, expected, 'PSC0_SH1_F1_EXPECTATION_' + label + '_' + name);
    observations.push({ name, result: actual });
  }
  for (const test of localCases) {
    observe(test.name, runtime.psErasureLocalNameWithFuel(
      scope(runtime, test.locals, test.globals), test.base, BigInt(test.fuel), BigInt(test.index)),
    test.expected);
  }
  for (const test of etaCases) {
    observe(test.name, etaResult(runtime.psErasureEtaNameWithFuel(body(test.body),
      list(runtime, test.used.map((name) => parameter(runtime, name))),
      BigInt(test.fuel), BigInt(test.index))), test.expected);
  }
  for (const test of matchCases) {
    observe(test.name, runtime.psTsFreshMatchTempWorker(body(test.body),
      BigInt(test.attempts), BigInt(test.index)), test.expected);
  }
  for (const test of internalCases) {
    observe(test.name, freshResult(runtime.psTsFreshInternalWorker(
      list(runtime, test.used), test.prefix, BigInt(test.attempts), BigInt(test.index))),
    test.expected);
  }
  for (const test of localWrapperCases) {
    observe(test.name, runtime.psErasureLocalName(scope(runtime, test.locals, test.globals),
      test.raw, test.fallback, BigInt(test.index)), test.expected);
  }
  observe('wrapper-match-argument-order',
    runtime.psTsFreshMatchTempLoop(body(['var', '__ps$match$7']), 7n, 2n), '__ps$match$8');
  observe('wrapper-internal-argument-order',
    freshResult(runtime.psTsFreshInternalWithFuel(list(runtime, ['p7', 'p8']), 'p', 7n, 3n)),
    ['p9', '10']);
  const etaParameters = runtime.psErasureEtaParameters(body(['literal']),
    list(runtime, [natType(runtime), natType(runtime)]),
    list(runtime, [parameter(runtime, '__ps_eta_0')]), 0n);
  assert.equal(tag(etaParameters), 'ok', 'PSC0_SH1_F1_ETA_PARAMETER_WRAPPER_' + label);
  observe('wrapper-eta-parameter-order',
    array(etaParameters.value).map((value) => value.name), ['__ps_eta_1', '__ps_eta_2']);
  return observations;
}

// Single-runtime section for a shared F1/F2 migration gate. The returned
// observations contain primitives only, so the caller can compare independently
// constructed baseline/candidate observations without crossing module ownership.
export function runSh1FreshNameCases(compiler, label = 'compiler') {
  const observations = inspectRuntime(compiler, label);
  return {
    family: 'F1',
    workerCases: localCases.length + etaCases.length + matchCases.length + internalCases.length,
    wrapperCases: localWrapperCases.length + 3,
    observations,
    observationSha256: sha256(JSON.stringify(observations)),
  };
}

export function runSh1FreshNameConformance({
  before, after, beforeCompilerSha256, afterCompilerSha256,
}) {
  assert.notEqual(before, after, 'PSC0_SH1_F1_DISTINCT_MODULE_INSTANCES');
  assert.match(beforeCompilerSha256, /^[a-f0-9]{64}$/u, 'PSC0_SH1_F1_BEFORE_IDENTITY');
  assert.match(afterCompilerSha256, /^[a-f0-9]{64}$/u, 'PSC0_SH1_F1_AFTER_IDENTITY');
  const beforeObservations = inspectRuntime(before, 'before');
  const afterObservations = inspectRuntime(after, 'after');
  // Only strings, decimal indices and arrays of those cross this comparison.
  assert.deepEqual(afterObservations, beforeObservations, 'PSC0_SH1_F1_BEHAVIOR_CORRESPONDENCE');
  return {
    schemaVersion: 1,
    evidence: 'finite-fresh-name-generated-export-correspondence',
    family: 'F1',
    beforeCompilerSha256, afterCompilerSha256,
    corpusSha256: sha256(JSON.stringify({
      localCases, etaCases, matchCases, internalCases, localWrapperCases,
      wrappers: [
        ['match', '__ps$match$7', '7', '2', '__ps$match$8'],
        ['internal', ['p7', 'p8'], 'p', '7', '3', ['p9', '10']],
        ['etaParameters', ['Nat', 'Nat'], ['__ps_eta_0'], '0', ['__ps_eta_1', '__ps_eta_2']],
      ],
    })),
    workerCases: localCases.length + etaCases.length + matchCases.length + internalCases.length,
    wrapperCases: localWrapperCases.length + 3,
    observationsPerRuntime: beforeObservations.length,
    observationSha256: sha256(JSON.stringify(beforeObservations)),
    result: 'pass',
    scope: {
      eachRuntimeOwnsAllTaggedInputs: true,
      independentExplicitExpectations: true,
      preservedScanLimit: 4096,
      checkedScanDepths: [4095, 4096],
      saturatedExportCallsChecked: true,
      completePublicTypes: 'separate required comparison',
      compiledPscPartialApplications: 'separate required probes',
      performanceImprovementClaimed: false,
      exhaustiveForAllInputs: false,
      kernelChecked: false,
    },
  };
}
