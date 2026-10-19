import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { compileTypeScript, runCommand, sha256, unwrap, valueTag } from './sh1-capabilities.mjs';

const cases = [
  { name: 'sh1GenericCopy', types: ['T0'], parameters: ['values'] },
  { name: 'sh1GenericMap', types: ['T0', 'T1'], parameters: ['convert', 'values'] },
  { name: 'sh1GenericTriple', types: ['T0', 'T1', 'T2'], parameters: ['first', 'second', 'third', 'fuel'] },
  { name: 'sh1GenericMono', types: [], parameters: ['fuel', 'value'] },
];

function list(value, label) {
  const result = [];
  while (valueTag(value) === 'cons') {
    assert(result.length < 1024, 'PSC0_SH1_GENERIC_LIST_BOUND: ' + label);
    result.push(value.head);
    value = value.tail;
  }
  assert.equal(valueTag(value), 'nil', 'PSC0_SH1_GENERIC_LIST_SHAPE: ' + label);
  return result;
}

function recursiveCalls(body, owner) {
  const result = [];
  const pending = [{ value: body, at: 'declaration:' + owner + '/body' }];
  const seen = new Set();
  while (pending.length) {
    const { value, at } = pending.pop();
    if (value === null || typeof value !== 'object' || seen.has(value)) continue;
    seen.add(value);
    assert(seen.size <= 10000, 'PSC0_SH1_GENERIC_IR_BOUND: ' + owner);
    if (valueTag(value) === 'call' && valueTag(value.fn) === 'var' && value.fn.name === owner) {
      result.push({ expression: value, at });
    }
    for (const [key, child] of Object.entries(value)) {
      pending.push({ value: child, at: at + '/' + key });
    }
  }
  return result;
}

// Expectations come from each fixture's declared telescope, independently of
// the context record used by the implementation. Preserve the observed IR paths.
function checkOriginalIr(ir) {
  const declarations = new Map(list(ir.declarations, 'declarations').map((item) => [item.name, item]));
  return cases.map((expected) => {
    const declaration = declarations.get(expected.name);
    assert(declaration, 'PSC0_SH1_GENERIC_DECLARATION_MISSING: ' + expected.name);
    assert.deepEqual(list(declaration.typeParameters, expected.name).map((item) => item.name),
      expected.types, 'PSC0_SH1_GENERIC_DECLARATION_TYPES: ' + expected.name);
    assert.deepEqual(list(declaration.parameters, expected.name).map((item) => item.name),
      expected.parameters, 'PSC0_SH1_GENERIC_RUNTIME_PARAMETERS: ' + expected.name);
    const calls = recursiveCalls(declaration.body, expected.name);
    assert.equal(calls.length, 1, 'PSC0_SH1_GENERIC_RECURSIVE_CALL_COUNT: ' + expected.name);
    return {
      declaration: expected.name,
      declarationTypeParameters: expected.types,
      runtimeParameters: expected.parameters,
      calls: calls.map(({ expression, at }) => {
        const arguments_ = list(expression.typeArguments, at);
        const names = arguments_.map((argument) => {
          assert.equal(valueTag(argument), 'typeParameter', 'PSC0_SH1_GENERIC_ARGUMENT_FORM: ' + at);
          return argument.name;
        });
        assert.deepEqual(names, expected.types, 'PSC0_SH1_GENERIC_ARGUMENT_ORDER: ' + at);
        const runtimeArity = list(expression.arguments, at).length;
        assert.equal(runtimeArity, expected.parameters.length, 'PSC0_SH1_GENERIC_RUNTIME_ARITY: ' + at);
        return { at, typeArguments: names, runtimeArity };
      }),
    };
  });
}

function checkBehavior(runtime, label) {
  const from = (values) => values.reduceRight((tail, head) => runtime.List.cons(head, tail), runtime.List.nil());
  let observations = 0;
  for (const values of [[], [7n], [2n, 5n, 11n], ['first', 'second']]) {
    assert.deepEqual(list(runtime.sh1GenericCopy(from(values)), label), values);
    observations++;
  }
  for (const values of [[], [7n], [2n, 5n, 11n]]) {
    const convert = (value) => 'n=' + value.toString();
    assert.deepEqual(list(runtime.sh1GenericMap(convert, from(values)), label), values.map(convert));
    observations++;
  }
  for (const fuel of [0n, 1n, 7n, 31n]) {
    for (const [first, second, third] of [[7n, 'word', true], ['left', 19n, false]]) {
      const actual = runtime.sh1GenericTriple(first, second, third, fuel);
      assert.deepEqual([actual.fst, actual.snd.fst, actual.snd.snd], [first, second, third],
        label + ': erased proof and interleaved type/runtime binders');
      observations++;
    }
    assert.equal(runtime.sh1GenericMono(fuel, 53n), 53n, label + ': monomorphic recursion');
    observations++;
  }
  return { observations, status: 'pass', exhaustiveForAllInputs: false };
}


// Assertions come from the unchanged source types and the new fixture's raw
// declaration prefixes, not from erasure's entry cache or its inferred names.
function checkFunctionValueIr(compiler, ir) {
  const report = compiler.psCheckVerifiedIrModule(compiler.psIrCheckDefaultOptions, ir);
  assert.equal(report.accepted, true, 'PSC0_SH1_GROUP_ORIGINAL_IR_ACCEPTED');
  assert.equal(report.traversalComplete, true, 'PSC0_SH1_GROUP_ORIGINAL_IR_COMPLETE');
  assert.equal(report.findingCount, 0n, 'PSC0_SH1_GROUP_ORIGINAL_IR_FINDINGS');
  const declarations = new Map(list(ir.declarations, 'group declarations').map((item) => [item.name, item]));
  const sourceEntries = [
    ['sh1GroupIdentity', 1], ['sh1GroupDirect', 1], ['sh1GroupLet', 1],
    ['sh1GroupApply', 2], ['sh1GroupHigher', 1], ['sh1GroupWeighted', 2],
    ['sh1GroupKnown', 0], ['sh1GroupRecordUse', 1], ['sh1GroupBoxUse', 1],
    ['sh1GroupArrayUse', 1], ['sh1GroupArrayMap', 1], ['sh1GroupArrayFold', 0],
    ['sh1GroupComputed', 2],
    ['sh1GroupTypeOnlyUse', 1], ['sh1GroupTypeOnlyHigher', 1],
    ['sh1GroupTypeProofOnlyUse', 1],
    ['sh1GroupLambda', 1], ['sh1GroupProjection', 1],
  ];
  const entries = sourceEntries.map(([name, arity]) => {
    const declaration = declarations.get(name);
    assert(declaration, 'PSC0_SH1_GROUP_DECLARATION: ' + name);
    assert.equal(list(declaration.parameters, name).length, arity,
      'PSC0_SH1_GROUP_ENTRY_ARITY: ' + name);
    return { name, runtimeArity: arity };
  });
  const typeActivationEntries = ['sh1GroupTypeOnly', 'sh1GroupTypeProofOnly'].map((name) => {
    const declaration = declarations.get(name);
    assert(declaration, 'PSC0_SH1_GROUP_TYPE_ACTIVATION_DECLARATION: ' + name);
    const parameters = list(declaration.parameters, name);
    assert.equal(parameters.length, 1, 'PSC0_SH1_GROUP_TYPE_ACTIVATION_PHYSICAL_ARITY: ' + name);
    assert.equal(valueTag(parameters[0].type), 'primitive');
    assert.equal(valueTag(parameters[0].type.name), 'unit');
    assert.equal(list(declaration.typeParameters, name).length, 1,
      'PSC0_SH1_GROUP_TYPE_ACTIVATION_GENERIC_ARITY: ' + name);
    return { name, sourceRuntimeArity: 0, physicalRuntimeArity: 1,
      internalActivation: 'fresh-ignored-unit', typeArity: 1 };
  });
  for (const [owner, target] of [
    ['sh1GroupTypeOnlyUse', 'sh1GroupTypeOnly'],
    ['sh1GroupTypeOnlyHigher', 'sh1GroupTypeOnly'],
    ['sh1GroupTypeProofOnlyUse', 'sh1GroupTypeProofOnly'],
  ]) {
    const calls = recursiveCalls(declarations.get(owner).body, target);
    assert.equal(calls.length, 1, 'PSC0_SH1_GROUP_TYPE_ACTIVATION_CALL: ' + owner);
    const arguments_ = list(calls[0].expression.arguments, owner);
    assert.equal(arguments_.length, 1, 'PSC0_SH1_GROUP_TYPE_ACTIVATION_ARGUMENTS: ' + owner);
    assert.equal(valueTag(arguments_[0]), 'literal');
    assert.equal(valueTag(arguments_[0].value), 'unit');
    assert.equal(list(calls[0].expression.typeArguments, owner).length, 1,
      'PSC0_SH1_GROUP_TYPE_ACTIVATION_TYPE_ARGUMENT: ' + owner);
  }
  const pending = [];
  for (const declaration of declarations.values()) {
    pending.push(declaration.resultType);
    for (const parameter of list(declaration.parameters, declaration.name)) pending.push(parameter.type);
  }
  for (const layout of list(ir.structures, 'structures'))
    for (const field of list(layout.fields, layout.name)) pending.push(field.type);
  for (const layout of list(ir.inductives, 'inductives'))
    for (const constructor of list(layout.constructors, layout.name))
      for (const field of list(constructor.fields, constructor.name)) pending.push(field.type);
  let typeNodes = 0, unaryFunctionNodes = 0;
  const seen = new Set();
  while (pending.length) {
    const type = pending.pop();
    if (seen.has(type)) continue;
    seen.add(type);
    assert(++typeNodes <= 10000, 'PSC0_SH1_GROUP_TYPE_BOUND');
    const tag = valueTag(type);
    if (tag === 'function') {
      const parameters = list(type.parameters, 'canonical function');
      assert.equal(parameters.length, 1, 'PSC0_SH1_GROUP_CANONICAL_UNARY_VALUE_TYPE');
      pending.push(parameters[0], type.result);
      unaryFunctionNodes++;
    } else if (tag === 'named') pending.push(...list(type.arguments, type.name));
    else assert(tag === 'primitive' || tag === 'typeParameter',
      'PSC0_SH1_GROUP_VALUE_TYPE_FORM: ' + String(tag));
  }
  assert(unaryFunctionNodes > 0, 'PSC0_SH1_GROUP_FUNCTION_TYPES_PRESENT');
  for (const owner of ['sh1GroupDirect', 'sh1GroupLet', 'sh1GroupKnown']) {
    const calls = recursiveCalls(declarations.get(owner).body, 'sh1GroupIdentity');
    assert.equal(calls.length, 1, 'PSC0_SH1_GROUP_IDENTITY_CALL: ' + owner);
    assert.equal(list(calls[0].expression.arguments, owner).length, 1,
      'PSC0_SH1_GROUP_IDENTITY_SATURATION: ' + owner);
    assert.equal(list(calls[0].expression.typeArguments, owner).length, 1,
      'PSC0_SH1_GROUP_IDENTITY_TYPE_ARGUMENT: ' + owner);
  }
  return {
    policy: 'canonical-unary-values-flat-aligned-entries/1',
    sourceEntries: entries, typeActivationEntries, typeNodes, unaryFunctionNodes,
    originalIr: {
      accepted: report.accepted, traversalComplete: report.traversalComplete,
      findingCount: report.findingCount.toString(),
      expressionCount: report.expressionCount.toString(),
      visitedSteps: report.visitedSteps.toString(),
      checkedObjectIsEmittedObject: true,
    },
    additionalPreparations: 0, additionalTypeScriptCompilations: 0,
    additionalNativeExecutions: 0,
  };
}

function checkFunctionValueBehavior(runtime, label) {
  const observations = [];
  const unary = (value) => value + 100n;
  const binary = (first) => (second) => 10n * first + second;
  const values = [
    ['generic-return-direct', () => runtime.sh1GroupDirect(unary), 107n],
    ['generic-return-let', () => runtime.sh1GroupLet(unary), 107n],
    ['generic-higher-order-parameter', () => runtime.sh1GroupHigher(binary), 37n],
    ['known-flat-entry-as-value', () => runtime.sh1GroupKnown, 37n],
    ['generic-record-field', () => runtime.sh1GroupRecordUse(binary), 37n],
    ['generic-inductive-field', () => runtime.sh1GroupBoxUse(binary), 37n],
    ['array-of-function-values', () => runtime.sh1GroupArrayUse(binary), 37n],
    ['array-map-function-result', () => runtime.sh1GroupArrayMap(unary), 37n],
    ['array-fold-binary-bridge', () => runtime.sh1GroupArrayFold, 15n],
    ['type-only-computed-value', () => runtime.sh1GroupTypeOnlyUse(29n), 29n],
    ['type-only-function-instantiation', () => runtime.sh1GroupTypeOnlyHigher(unary), 107n],
    ['type-and-proof-only-activation', () => runtime.sh1GroupTypeProofOnlyUse(53n), 53n],
    ['generic-lambda-body-result', () => runtime.sh1GroupLambda(unary), 107n],
    ['generic-projection-computed-head', () => runtime.sh1GroupProjection(binary), 37n],
  ];
  for (const [id, invoke, expected] of values) {
    const actual = invoke();
    assert.equal(actual, expected, label + ': ' + id);
    observations.push({ id, value: actual.toString(), status: 'pass' });
  }

  // Host traces/faults diagnose the mechanism; they do not add effects or FFI
  // to the source language. The original source callback type remains Unit->Nat.
  assert.equal(runtime.sh1GroupComputed.length, 2, label + ': computed closure entry');
  const trace = [];
  const make = (unit) => {
    assert.equal(unit, undefined);
    trace.push('make');
    return 23n;
  };
  const saved = runtime.sh1GroupComputed(make, 5n);
  assert.equal(typeof saved, 'function');
  assert.deepEqual(trace, ['make'], label + ': body demanded before closure return');
  for (const [id, input, expected] of [
    ['computed-closure-first', 7n, 35n],
    ['computed-closure-second', 15n, 43n],
    ['computed-closure-reuse', 7n, 35n],
  ]) {
    const actual = saved(input);
    assert.equal(actual, expected, label + ': ' + id);
    assert.deepEqual(trace, ['make'], label + ': captured value not recomputed');
    observations.push({ id, value: actual.toString(), status: 'pass',
      diagnosticDomain: 'host-callback-demand' });
  }
  const discarded = runtime.sh1GroupComputed(make, 11n);
  assert.equal(typeof discarded, 'function');
  assert.deepEqual(trace, ['make', 'make'], label + ': discarded closure body demanded');
  observations.push({ id: 'computed-closure-discarded', trace: [...trace], status: 'pass',
    diagnosticDomain: 'host-callback-demand' });
  const fault = { code: 'PSC0_SH1_GROUP_COMPUTED_FAULT' };
  assert.throws(() => runtime.sh1GroupComputed((unit) => {
    assert.equal(unit, undefined);
    trace.push('make-failure');
    throw fault;
  }, 5n), (error) => error === fault, label + ': original body fault before closure');
  assert.deepEqual(trace, ['make', 'make', 'make-failure']);
  observations.push({ id: 'computed-closure-original-fault', trace: [...trace], status: 'pass',
    diagnosticDomain: 'host-callback-demand' });
  assert.equal(observations.length, 19, 'PSC0_SH1_GROUP_BEHAVIOR_COUNT');
  return {
    observations, observationCount: observations.length, status: 'pass',
    pureValueCases: 14, callbackDemandDiagnostics: 5,
    exhaustiveForAllInputs: false, sourceEffectCapabilityAdded: false,
  };
}


const recursionCases = [
  { id: 'major-capture-two', declaration: 'sh1CoreMajorCapture', input: 2n, expected: 3n },
  { id: 'major-capture-three', declaration: 'sh1CoreMajorCapture', input: 3n, expected: 6n },
  { id: 'nested-outer-two', declaration: 'sh1CoreNestedOuter', input: 2n, expected: 3n },
  { id: 'nested-outer-three', declaration: 'sh1CoreNestedOuter', input: 3n, expected: 6n },
];

// This is a finite independent value reference for these two Nat declarations,
// not a compiler evaluator or a general source/Core demand semantics. It reads
// the exact prepared objects later passed to erasure, including the actual minor
// closures and their captured environments. Only constant-Nat motives are used.
function checkPreparedCoreRecursion(prepared, sourceSha256) {
  const prefix = 'PSC0_SH1_RECURSION_CORE_';
  const natural = (value, label) => {
    assert(typeof value === 'bigint' && value >= 0n, prefix + 'NAT: ' + label);
    return value;
  };
  const name = (value) => {
    const segments = [];
    while (valueTag(value) !== 'anonymous') {
      assert(segments.length < 32, prefix + 'NAME_BOUND');
      const tag = valueTag(value);
      if (tag === 'str') {
        assert.equal(typeof value.value, 'string', prefix + 'NAME_STRING');
        segments.push(['str', value.value]);
      } else {
        assert.equal(tag, 'num', prefix + 'NAME_FORM');
        segments.push(['num', natural(value.value, 'name').toString()]);
      }
      value = value.parent;
    }
    return segments.reverse();
  };
  const nameKey = (value) => JSON.stringify(name(value));
  const namedKey = (text) => JSON.stringify(text.split('.').map((part) => ['str', part]));
  const wanted = [...new Set(recursionCases.map((item) => item.declaration))];
  const wantedKeys = new Map(wanted.map((item) => [namedKey(item), item]));
  const definitions = new Map();
  for (const declaration of list(prepared.declarations, 'prepared Core declarations')) {
    if (valueTag(declaration) !== 'definitionDecl') continue;
    const label = wantedKeys.get(nameKey(declaration.name));
    if (label === undefined) continue;
    assert(!definitions.has(label), prefix + 'DUPLICATE: ' + label);
    definitions.set(label, declaration);
  }
  assert.equal(definitions.size, 2, prefix + 'DECLARATION_COUNT');
  const natKey = namedKey('Nat');
  const natType = (expression, label) => {
    assert.equal(valueTag(expression), 'constE', prefix + 'NAT_TYPE: ' + label);
    assert.equal(nameKey(expression.name), natKey, prefix + 'NAT_TYPE_NAME: ' + label);
    assert.equal(list(expression.levels, label).length, 0, prefix + 'NAT_TYPE_LEVELS');
  };
  const binder = (value) => {
    const tag = valueTag(value);
    assert(['explicit', 'implicit', 'strictImplicit', 'instanceImplicit'].includes(tag),
      prefix + 'BINDER_FORM');
    return tag;
  };
  let snapshotNodes = 0;
  const snapshotStep = (depth) => {
    assert(depth <= 128, prefix + 'SNAPSHOT_DEPTH');
    assert(++snapshotNodes <= 8192, prefix + 'SNAPSHOT_BOUND');
  };
  const levelSnapshot = (level, depth) => {
    snapshotStep(depth);
    const tag = valueTag(level);
    if (tag === 'zero') return { tag };
    if (tag === 'succ') return { tag, of: levelSnapshot(level.of, depth + 1) };
    if (tag === 'max' || tag === 'imax') return {
      tag, left: levelSnapshot(level.left, depth + 1),
      right: levelSnapshot(level.right, depth + 1),
    };
    assert.fail(prefix + 'CLOSED_LEVEL_FORM: ' + String(tag));
  };
  const snapshot = (expression, depth = 0) => {
    snapshotStep(depth);
    const tag = valueTag(expression);
    if (tag === 'bvar') return { tag, index: natural(expression.index, 'bvar').toString() };
    if (tag === 'sortE') return { tag, level: levelSnapshot(expression.level, depth + 1) };
    if (tag === 'constE') return {
      tag, name: name(expression.name),
      levels: list(expression.levels, 'constant levels').map((level) => levelSnapshot(level, depth + 1)),
    };
    if (tag === 'app') return {
      tag, fn: snapshot(expression.fn, depth + 1), arg: snapshot(expression.arg, depth + 1),
    };
    if (tag === 'lam' || tag === 'forallE') return {
      tag, name: name(expression.name), type: snapshot(expression.type, depth + 1),
      body: snapshot(expression.body, depth + 1), binder: binder(expression.binder),
    };
    if (tag === 'letE') return {
      tag, name: name(expression.name), type: snapshot(expression.type, depth + 1),
      value: snapshot(expression.value, depth + 1), body: snapshot(expression.body, depth + 1),
    };
    if (tag === 'lit') {
      assert.equal(valueTag(expression.value), 'natural', prefix + 'LITERAL_FORM');
      return { tag, value: { tag: 'natural', value: natural(expression.value.value, 'literal').toString() } };
    }
    assert.fail(prefix + 'SNAPSHOT_FORM: ' + String(tag));
  };
  const declarationSnapshots = wanted.map((label) => {
    const declaration = definitions.get(label);
    assert(declaration, prefix + 'DECLARATION: ' + label);
    assert.equal(list(declaration.levelParams, label).length, 0, prefix + 'LEVEL_PARAMETERS');
    assert.equal(valueTag(declaration.type), 'forallE', prefix + 'TYPE_TELESCOPE: ' + label);
    assert.equal(binder(declaration.type.binder), 'explicit', prefix + 'TYPE_BINDER: ' + label);
    natType(declaration.type.type, label + ' parameter');
    natType(declaration.type.body, label + ' result');
    assert.equal(valueTag(declaration.value), 'lam', prefix + 'VALUE_PREFIX: ' + label);
    assert.equal(binder(declaration.value.binder), 'explicit', prefix + 'VALUE_BINDER: ' + label);
    natType(declaration.value.type, label + ' lambda parameter');
    return { name: label, type: snapshot(declaration.type), value: snapshot(declaration.value) };
  });

  const budget = { limit: 20000, used: 0, remaining: 20000 };
  let recursorApplications = 0;
  const tick = () => {
    assert(budget.remaining > 0, prefix + 'EVALUATION_BUDGET');
    budget.remaining--;
    budget.used++;
  };
  const builtins = new Map([
    [namedKey('Nat.succ'), { name: 'Nat.succ', arity: 1 }],
    [namedKey('Nat.add'), { name: 'Nat.add', arity: 2 }],
    [namedKey('Nat.rec'), { name: 'Nat.rec', arity: 4 }],
  ]);
  const evaluate = (expression, environment) => {
    tick();
    const tag = valueTag(expression);
    if (tag === 'bvar') {
      const index = natural(expression.index, 'bvar');
      assert(index < BigInt(environment.length) && index < 128n, prefix + 'BVAR_SCOPE');
      return environment[Number(index)];
    }
    if (tag === 'lam') return { kind: 'closure', node: expression, environment };
    if (tag === 'app') {
      const fn = evaluate(expression.fn, environment);
      const argument = evaluate(expression.arg, environment);
      return apply(fn, argument);
    }
    if (tag === 'letE') {
      const value = evaluate(expression.value, environment);
      assert(environment.length < 128, prefix + 'ENVIRONMENT_BOUND');
      return evaluate(expression.body, [value, ...environment]);
    }
    if (tag === 'lit') {
      assert.equal(valueTag(expression.value), 'natural', prefix + 'RUNTIME_LITERAL_FORM');
      return natural(expression.value.value, 'runtime literal');
    }
    if (tag === 'constE') {
      const key = nameKey(expression.name);
      if (key === namedKey('Nat.zero')) return 0n;
      const builtin = builtins.get(key);
      if (builtin) return { kind: 'builtin', ...builtin, arguments: [] };
      const label = wantedKeys.get(key);
      if (label !== undefined) return evaluate(definitions.get(label).value, []);
      assert.fail(prefix + 'RUNTIME_CONSTANT: ' + key);
    }
    assert.fail(prefix + 'RUNTIME_FORM: ' + String(tag));
  };
  const apply = (fn, argument) => {
    tick();
    assert(fn !== null && typeof fn === 'object', prefix + 'FUNCTION_VALUE');
    if (fn.kind === 'closure') {
      assert(fn.environment.length < 128, prefix + 'ENVIRONMENT_BOUND');
      return evaluate(fn.node.body, [argument, ...fn.environment]);
    }
    assert.equal(fn.kind, 'builtin', prefix + 'FUNCTION_FORM');
    const arguments_ = [...fn.arguments, argument];
    assert(arguments_.length <= fn.arity, prefix + 'BUILTIN_ARITY');
    if (arguments_.length < fn.arity) return { ...fn, arguments: arguments_ };
    if (fn.name === 'Nat.succ') return natural(arguments_[0], 'succ') + 1n;
    if (fn.name === 'Nat.add') return natural(arguments_[0], 'add left') + natural(arguments_[1], 'add right');
    assert.equal(fn.name, 'Nat.rec', prefix + 'BUILTIN_NAME');
    const [motive, zero, step, major] = arguments_;
    assert.equal(motive.kind, 'closure', prefix + 'MOTIVE_CLOSURE');
    natType(motive.node.type, 'motive parameter');
    natType(motive.node.body, 'constant motive result');
    assert.equal(step.kind, 'closure', prefix + 'STEP_CLOSURE');
    let result = natural(zero, 'recursor zero minor');
    const count = natural(major, 'recursor major');
    assert(count <= 64n, prefix + 'RECURSOR_MAJOR_BOUND');
    recursorApplications++;
    for (let predecessor = 0n; predecessor < count; predecessor++) {
      tick();
      result = natural(apply(apply(step, predecessor), result), 'recursor step result');
    }
    return result;
  };
  const observations = recursionCases.map(({ id, declaration, input, expected }) => {
    const stepsBefore = budget.used;
    const recursorsBefore = recursorApplications;
    const actual = natural(apply(evaluate(definitions.get(declaration).value, []), input), id);
    assert.equal(actual, expected, prefix + 'EQUATION: ' + id);
    const usedRecursors = recursorApplications - recursorsBefore;
    assert(usedRecursors > 0, prefix + 'ACTUAL_RECURSOR: ' + id);
    return { id, declaration, input: input.toString(), value: actual.toString(),
      steps: budget.used - stepsBefore, recursorApplications: usedRecursors, status: 'pass' };
  });
  const artifact = {
    schemaVersion: 1, evidence: 'actual-prepared-core-nat-recursion',
    sourceSha256, declarations: declarationSnapshots,
  };
  const artifactText = JSON.stringify(artifact, null, 2) + '\n';
  const receipt = {
    policy: 'prepared-core-nat-reference/1',
    preparedObject: 'same PsCompilerAdmissionReadyModule used for original IR',
    artifact: { path: 'recursion-core.json', sha256: sha256(artifactText), bytes: Buffer.byteLength(artifactText) },
    declarations: declarationSnapshots.map((declaration) => ({
      name: declaration.name, sourceRuntimeArity: 1, coreSha256: sha256(JSON.stringify(declaration)),
    })),
    observations, observationCount: observations.length,
    budget: { ...budget, scope: 'shared across all four reference observations' },
    snapshot: { nodes: snapshotNodes, nodeLimit: 8192, depthLimit: 128 },
    supportedExecutableForms: ['bvar', 'lam', 'app', 'letE', 'lit.natural', 'constE'],
    runtimeConstants: ['Nat.zero', 'Nat.succ', 'Nat.add', 'Nat.rec', ...wanted],
    suppliedNatRecMinorClosures: true,
    additionalPreparations: 0, additionalTypeScriptCompilations: 0, additionalNativeExecutions: 0,
    status: 'pass', exhaustiveForAllInputs: false, generalRecursorDemandAdequacy: false,
  };
  return { receipt, artifactText };
}

function checkRecursionBehavior(runtime, label) {
  const observations = recursionCases.map(({ id, declaration, input, expected }) => {
    assert.equal(typeof runtime[declaration], 'function', label + ': recursion declaration');
    assert.equal(runtime[declaration].length, 1, label + ': recursion entry arity');
    const actual = runtime[declaration](input);
    assert.equal(actual, expected, label + ': recursion equation ' + id);
    return { id, declaration, input: input.toString(), value: actual.toString(), status: 'pass' };
  });
  return { observations, observationCount: observations.length, status: 'pass',
    exhaustiveForAllInputs: false };
}


// These accepted declarations have no finite canonical record inhabitant.
// Inspect their actual original IR; never fabricate a record or call them.
function checkRecursiveStructureIr(ir, originalIr) {
  assert.equal(originalIr.accepted, true);
  assert.equal(originalIr.traversalComplete, true);
  assert.equal(originalIr.findingCount, '0');
  assert.equal(originalIr.checkedObjectIsEmittedObject, true);
  const typeView = (type, depth = 0) => {
    assert(depth < 16, 'PSC0_SH1_RECURSIVE_STRUCTURE_TYPE_BOUND');
    const kind = valueTag(type);
    if (kind === 'primitive') return { kind, name: valueTag(type.name) };
    if (kind === 'typeParameter') return { kind, name: type.name };
    assert.equal(kind, 'named', 'PSC0_SH1_RECURSIVE_STRUCTURE_TYPE_FORM');
    return { kind, name: type.name,
      arguments: list(type.arguments, type.name).map((item) => typeView(item, depth + 1)) };
  };
  const parameterType = { kind: 'typeParameter', name: 'T0' };
  const naturalType = { kind: 'primitive', name: 'nat' };
  const namedType = (name, parameters) => ({
    kind: 'named', name,
    arguments: parameters.map((parameter) => ({ kind: 'typeParameter', name: parameter })),
  });
  const expectedLayouts = [
    { name: 'Sh1RecursiveRecord', typeParameters: [], recursiveFieldIndex: 0,
      fields: [{ name: 'next', type: namedType('Sh1RecursiveRecord', []) }] },
    { name: 'Sh1RecursiveGenericRecord', typeParameters: ['T0'], recursiveFieldIndex: 1,
      fields: [{ name: 'item', type: parameterType },
        { name: 'next', type: namedType('Sh1RecursiveGenericRecord', ['T0']) }] },
  ];
  const structures = list(ir.structures, 'recursive structures');
  const inductives = list(ir.inductives, 'recursive structure inductives');
  const declarations = list(ir.declarations, 'recursive structure declarations');
  const globals = new Set([...structures, ...inductives, ...declarations].map((item) => item.name));
  const layouts = expectedLayouts.map((expected) => {
    const matches = structures.filter((item) => item.name === expected.name);
    assert.equal(matches.length, 1, 'PSC0_SH1_RECURSIVE_STRUCTURE_LAYOUT: ' + expected.name);
    assert.equal(inductives.filter((item) => item.name === expected.name).length, 0,
      'PSC0_SH1_RECURSIVE_STRUCTURE_REPRESENTATION: ' + expected.name);
    const layout = matches[0];
    const observed = {
      name: layout.name,
      typeParameters: list(layout.typeParameters, layout.name).map((item) => item.name),
      recursiveFieldIndex: expected.recursiveFieldIndex,
      fields: list(layout.fields, layout.name).map((field) => ({
        name: field.name, type: typeView(field.type),
      })),
    };
    assert.deepEqual(observed, expected, 'PSC0_SH1_RECURSIVE_STRUCTURE_LAYOUT_FIELDS');
    return observed;
  });
  const specs = [
    { name: 'sh1RecursiveRecordObserve', layout: 0, result: naturalType, outcome: 'zero' },
    { name: 'sh1RecursiveRecordStep', layout: 0, result: naturalType, outcome: 'recursive-call' },
    { name: 'sh1RecursiveGenericObserve', layout: 1, result: parameterType, outcome: 'item' },
    { name: 'sh1RecursiveGenericStep', layout: 1, result: parameterType, outcome: 'recursive-call' },
  ];
  const observedDeclarations = specs.map((expected) => {
    const layout = layouts[expected.layout];
    const matches = declarations.filter((item) => item.name === expected.name);
    assert.equal(matches.length, 1, 'PSC0_SH1_RECURSIVE_STRUCTURE_DECLARATION: ' + expected.name);
    const declaration = matches[0];
    const typeParameters = list(declaration.typeParameters, expected.name).map((item) => item.name);
    assert.deepEqual(typeParameters, layout.typeParameters,
      'PSC0_SH1_RECURSIVE_STRUCTURE_DECLARATION_TYPES: ' + expected.name);
    const parameters = list(declaration.parameters, expected.name);
    assert.equal(parameters.length, 1, 'PSC0_SH1_RECURSIVE_STRUCTURE_ENTRY_ARITY');
    const parameter = parameters[0];
    const inputType = namedType(layout.name, typeParameters);
    assert.deepEqual(typeView(parameter.type), inputType);
    assert.deepEqual(typeView(declaration.resultType), expected.result);
    const major = declaration.body;
    assert.equal(valueTag(major), 'letE', 'PSC0_SH1_RECURSIVE_STRUCTURE_MAJOR_LET');
    assert.deepEqual(typeView(major.type), inputType);
    assert.equal(valueTag(major.value), 'var', 'PSC0_SH1_RECURSIVE_STRUCTURE_MAJOR_VALUE');
    assert.equal(major.value.name, parameter.name);
    const localNames = new Set([parameter.name]);
    const fresh = (name) => {
      assert.equal(typeof name, 'string');
      assert(name.length > 0 && !localNames.has(name) && !globals.has(name),
        'PSC0_SH1_RECURSIVE_STRUCTURE_FRESH_BINDER: ' + expected.name);
      localNames.add(name);
    };
    fresh(major.name);
    let cursor = major.body;
    const projections = layout.fields.map((field, index) => {
      assert.equal(valueTag(cursor), 'letE', 'PSC0_SH1_RECURSIVE_STRUCTURE_FIELD_LET');
      assert.deepEqual(typeView(cursor.type), field.type);
      fresh(cursor.name);
      const projection = cursor.value;
      assert.equal(valueTag(projection), 'projection', 'PSC0_SH1_RECURSIVE_STRUCTURE_FIELD_PROJECTION');
      assert.equal(projection.structureName, layout.name);
      assert.deepEqual(list(projection.typeArguments, expected.name).map((type) => typeView(type)),
        inputType.arguments);
      assert.equal(projection.field, field.name, 'PSC0_SH1_RECURSIVE_STRUCTURE_FIELD_ORDER');
      assert.equal(valueTag(projection.target), 'var');
      assert.equal(projection.target.name, major.name, 'PSC0_SH1_RECURSIVE_STRUCTURE_SHARED_MAJOR');
      const observed = { index, field: projection.field, binding: cursor.name,
        type: typeView(cursor.type), target: projection.target.name };
      cursor = cursor.body;
      return observed;
    });
    let body;
    if (expected.outcome === 'recursive-call') {
      assert.equal(valueTag(cursor), 'call', 'PSC0_SH1_RECURSIVE_STRUCTURE_USED_IH');
      assert.equal(valueTag(cursor.fn), 'var');
      assert.equal(cursor.fn.name, declaration.name);
      const typeArguments = list(cursor.typeArguments, expected.name).map((type) => typeView(type));
      assert.deepEqual(typeArguments, inputType.arguments);
      const arguments_ = list(cursor.arguments, expected.name);
      assert.equal(arguments_.length, 1);
      assert.equal(valueTag(arguments_[0]), 'var');
      assert.equal(arguments_[0].name, projections[layout.recursiveFieldIndex].binding,
        'PSC0_SH1_RECURSIVE_STRUCTURE_RECURSIVE_FIELD_ARGUMENT');
      body = { kind: 'recursive-call', declaration: cursor.fn.name,
        typeArguments, arguments: [arguments_[0].name], runtimeArity: arguments_.length };
    } else if (expected.outcome === 'zero') {
      assert.equal(valueTag(cursor), 'literal', 'PSC0_SH1_RECURSIVE_STRUCTURE_UNUSED_IH');
      assert.equal(valueTag(cursor.value), 'natural');
      assert.equal(cursor.value.value, 0n);
      body = { kind: 'natural', value: cursor.value.value.toString() };
    } else {
      assert.equal(valueTag(cursor), 'var', 'PSC0_SH1_RECURSIVE_STRUCTURE_GENERIC_FIELD_RESULT');
      assert.equal(cursor.name, projections[0].binding);
      body = { kind: 'field', field: 'item', binding: cursor.name };
    }
    return {
      name: declaration.name, structure: layout.name, typeParameters,
      parameters: [{ name: parameter.name, type: typeView(parameter.type) }],
      resultType: typeView(declaration.resultType),
      major: { name: major.name, sourceParameter: major.value.name, type: typeView(major.type),
        evaluations: 1, fresh: true },
      projections, recursiveFieldIndex: layout.recursiveFieldIndex, body,
      freshNamesDistinct: true, remainingHypothesisLambdas: 0,
    };
  });
  return {
    policy: 'recursive-structure-fields-and-root-hypotheses/1',
    compileOnly: true, layouts, declarations: observedDeclarations,
    structureCount: layouts.length, declarationCount: observedDeclarations.length,
    projectionCount: observedDeclarations.reduce((count, item) => count + item.projections.length, 0),
    usedHypothesisCount: observedDeclarations.filter((item) => item.body.kind === 'recursive-call').length,
    unusedHypothesisCount: observedDeclarations.filter((item) => item.body.kind !== 'recursive-call').length,
    originalIr: { ...originalIr, reusedExistingCheck: true },
    runtimeInvocations: 0, constructedRuntimeRecords: 0,
    additionalPreparations: 0, additionalIrChecks: 0,
    additionalTypeScriptCompilations: 0, additionalNativeExecutions: 0,
    generalRecursorDemandAdequacyProven: false, semanticPreservationProven: false,
  };
}

export async function runGenericErasureConformance({
  compiler, compilerSha256, root, outDir, tsc, nativeCompiler,
}) {
  const fixture = path.join(root, 'test/fixtures/selfhost-sh1-generic-erasure.lean');
  const source = await readFile(fixture, 'utf8');
  const prepared = unwrap(compiler.psCompilerPrepareSource(compiler.PsCompilerSourceKind.lean, source),
    'GENERIC_ERASURE_PREPARE');
  const recursionReference = checkPreparedCoreRecursion(prepared, sha256(source));
  const ir = unwrap(compiler.psCompilerVerifiedIrFromPrepared(prepared), 'GENERIC_ERASURE_ORIGINAL_IR');
  const observations = checkOriginalIr(ir);
  const functionValueIr = checkFunctionValueIr(compiler, ir);
  const recursiveStructures = checkRecursiveStructureIr(ir, functionValueIr.originalIr);
  const admissions = unwrap(compiler.psCompilerAdmissionsFromPrepared(prepared), 'GENERIC_ERASURE_ADMISSIONS');
  const typeScript = unwrap(compiler.psTsEmitModule(ir), 'GENERIC_ERASURE_EMIT');
  const outputJs = await compileTypeScript(typeScript, path.join(outDir, 'generated'), tsc, root);
  const runtime = await import(pathToFileURL(outputJs).href);
  const behavior = checkBehavior(runtime, 'generated PSC');
  const functionValueBehavior = checkFunctionValueBehavior(runtime, 'generated PSC');
  const recursionBehavior = checkRecursionBehavior(runtime, 'generated PSC');
  const receipt = {
    schemaVersion: 1,
    evidence: 'scoped-recursive-generic-erasure',
    compilerSha256,
    sourceKind: 'raw-authoritative-lean',
    sourceSha256: sha256(source),
    originalIr: {
      checks: [
        'one, two, and three declaration generics in exact declaration order',
        'interleaved type, erased proposition/proof, and runtime binders',
        'recursive calls retain the complete runtime argument count',
        'monomorphic recursive calls retain zero type arguments',
      ],
      observations,
      emittedIr: 'The exact original IR inspected above is passed to psTsEmitModule.',
      strictSh1Qualified: false,
    },
    artifacts: {
      admissionsSha256: sha256(admissions),
      typescriptSha256: sha256(typeScript),
      javascriptSha256: sha256(await readFile(outputJs)),
    },
    behavior,
    functionValues: { ir: functionValueIr, behavior: functionValueBehavior },
    recursion: { reference: recursionReference.receipt, behavior: recursionBehavior },
    recursiveStructures,
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  if (nativeCompiler) {
    const native = runCommand(nativeCompiler, ['typescript', fixture], {
      cwd: root, encoding: 'utf8', stdio: 'pipe', timeout: 120000,
      maxBuffer: 16 * 1024 * 1024,
    });
    assert.equal(native.stdout, typeScript, 'PSC0_SH1_GENERIC_NATIVE_TYPESCRIPT_PARITY');
    const nativeJs = await compileTypeScript(native.stdout, path.join(outDir, 'native'), tsc, root);
    const nativeRuntime = await import(pathToFileURL(nativeJs).href);
    receipt.native = {
      typescriptSha256: sha256(native.stdout),
      javascriptSha256: sha256(await readFile(nativeJs)),
      behavior: checkBehavior(nativeRuntime, 'native PSC'),
      functionValueBehavior: checkFunctionValueBehavior(nativeRuntime, 'native PSC'),
      recursionBehavior: checkRecursionBehavior(nativeRuntime, 'native PSC'),
    };
  }
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'admissions.json'), admissions);
  await writeFile(path.join(outDir, 'recursion-core.json'), recursionReference.artifactText);
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_GENERIC_ERASURE: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
