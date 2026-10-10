import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { compileStrictSources, strictSourceOptions } from './sh1-strict-source.mjs';

const sha256 = (value) => createHash('sha256').update(value).digest('hex');
const input = (source, tail = 'StrictCase') => ({
  moduleName: ['Ps', 'Compiler', tail], source,
});
const literal = 'def sh1Literal : Nat := 7\n';



export const sh1EmptySourceFixtures = Object.freeze({
  "lean": {
    "path": "test/fixtures/selfhost-sh1-empty.lean",
    "sha256": "243b2660309aba388df6009af8af033a51e9f3ca080dde502e096c4f29b6a7a5",
    "bytes": 345
  },
  "ps": {
    "path": "test/fixtures/selfhost-sh1-empty.ps",
    "sha256": "71f4e7e756816c301603ce1e6382c60cb6f0877ca8b88c4f166a358dab2e3390",
    "bytes": 369
  }
});

function emptyTag(value) {
  if (value === null || typeof value !== 'object') return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    if (typeof value[symbol] === 'string') return value[symbol];
  }
  return undefined;
}

function emptyItems(value) {
  const items = [], seen = new Set();
  while (emptyTag(value) === 'cons') {
    assert(!seen.has(value), 'PSC0_SH1_EMPTY_OWNED_LIST_CYCLE');
    seen.add(value); items.push(value.head); value = value.tail;
  }
  assert.equal(emptyTag(value), 'nil', 'PSC0_SH1_EMPTY_OWNED_LIST');
  return items;
}

function emptyResultType(type) {
  switch (emptyTag(type)) {
    case 'primitive': return { kind: 'primitive', name: emptyTag(type.name) };
    case 'typeParameter': return { kind: 'typeParameter', name: type.name };
    case 'function': return { kind: 'function',
      parameters: emptyItems(type.parameters).map(emptyResultType), result: emptyResultType(type.result) };
    default: throw new Error('PSC0_SH1_EMPTY_RESULT_TYPE: ' + emptyTag(type));
  }
}

function observeEmptySource(result, sourceKind, fixture) {
  const layout = emptyItems(result.originalIr.inductives).filter((item) => item.name === 'Sh1Empty');
  assert.equal(layout.length, 1);
  assert.equal(emptyItems(layout[0].constructors).length, 0);
  assert.deepEqual(emptyItems(layout[0].typeParameters).map((item) => item.name), ['T0']);
  const nat = { kind: 'primitive', name: 'nat' };
  const expected = [
    ['sh1EmptyNat', nat], ['sh1EmptyFunction', { kind: 'function', parameters: [nat], result: nat }],
    ['sh1EmptyGeneric', { kind: 'typeParameter', name: 'T0' }], ['sh1EmptyFresh', nat],
  ];
  const declarations = emptyItems(result.originalIr.declarations);
  const eliminations = expected.map(([name, type]) => {
    const matches = declarations.filter((item) => item.name === name);
    assert.equal(matches.length, 1, name);
    const declaration = matches[0], retained = [], pending = [declaration.body], seen = new Set();
    // Observe the compiler-owned, already checked graph after atomic emission.
    // Aliases are visited once; no new caller graph or compiler work is admitted.
    while (pending.length) {
      const value = pending.pop();
      if (value === null || typeof value !== 'object' || seen.has(value)) continue;
      seen.add(value);
      if (emptyTag(value) === 'letE' && emptyTag(value.value) === 'matchE' &&
          value.value.inductiveName === 'Sh1Empty') retained.push(value);
      pending.push(...Object.values(value));
    }
    assert.equal(retained.length, 1, name + ': typed empty result');
    const local = retained[0], matched = local.value;
    assert.deepEqual(emptyResultType(local.type), type, name + ': result annotation');
    assert.equal(emptyItems(matched.alternatives).length, 0);
    assert.equal(emptyItems(matched.typeArguments).length, 1);
    assert.equal(emptyTag(matched.scrutinee), 'var');
    assert.equal(matched.scrutinee.name, 'value');
    assert.equal(emptyTag(local.body), 'var');
    assert.equal(local.body.name, local.name);
    const runtimeParameters = emptyItems(declaration.parameters).map((item) => item.name);
    const declarationResultType = emptyResultType(declaration.resultType);
    assert.deepEqual(declarationResultType, type, name + ': declaration result type');
    assert.deepEqual(runtimeParameters, name === 'sh1EmptyFresh' ? ['value', 'emptyResult'] : ['value'],
      name + ': authored runtime parameter prefix');
    assert.equal(declaration.body, local, name + ': direct typed empty result');
    assert(!runtimeParameters.includes(local.name), name + ': fresh result binding');
    return { name, resultType: type, declarationResultType, resultName: local.name,
      runtimeParameters, bodyIsTypedEmptyResult: true,
      alternatives: 0, typeArgumentCount: 1, freshResultName: true };
  });
  const origin = result.evidence.sourceOrigins.modules[1];
  assert.deepEqual(origin.moduleName, ['Ps', 'Compiler', 'StrictEmpty']);
  assert.deepEqual(origin.batches.map((batch) => batch.sourceName), [
    ['Sh1Empty'], ...expected.map(([name]) => [name]),
  ]);
  assert.deepEqual(origin.batches.map((batch) => batch.members.map((member) => member.role)),
    [['inductiveType', 'recursor'], ...expected.map(() => ['sourceDeclaration'])]);
  assert(origin.batches.every((batch) => batch.normalization === null));
  assert.match(result.typeScript, /export type Sh1Empty<T0> = never;/u);
  assert.equal(result.typeScript.split('__ps$Computation<never>').length - 1, 4);
  return { sourceKind, ...sh1EmptySourceFixtures[sourceKind],
    sourceArtifact: 'empty.' + (sourceKind === 'lean' ? 'lean' : 'ps'),
    typeScriptArtifact: 'accepted-' + sourceKind + '.ts',
    typeScriptSha256: sha256(result.typeScript),
    atomicAcceptedId: sourceKind + '-raw-imports-and-ordinary-do-spellings',
    atomicSourceInputsSha256: result.evidence.sourceInputsSha256,
    moduleName: origin.moduleName, sourceDeclarationCount: 5, coreDeclarationCount: 6,
    originMemberCounts: origin.batches.map((batch) => batch.members.length),
    emptyLayoutCount: layout.length, emptyEliminationCount: eliminations.length,
    typedResultCount: eliminations.length, eliminations,
    capturedFixtureSha256: sha256(fixture) };
}


function observeZeroFieldRecord(result, sourceKind) {
  const layouts = emptyItems(result.originalIr.structures).filter((item) => item.name === 'Sh1EmptyRecord');
  assert.equal(layouts.length, 1);
  assert.equal(emptyItems(layouts[0].fields).length, 0);
  assert.equal(emptyItems(layouts[0].typeParameters).length, 0);
  const values = emptyItems(result.originalIr.declarations)
    .filter((item) => item.name === 'sh1EmptyRecordValue');
  assert.equal(values.length, 1);
  const value = values[0];
  assert.equal(emptyItems(value.parameters).length, 0);
  assert.equal(emptyItems(value.typeParameters).length, 0);
  assert.equal(emptyTag(value.resultType), 'named');
  assert.equal(value.resultType.name, 'Sh1EmptyRecord');
  assert.equal(emptyTag(value.body), 'record');
  assert.equal(value.body.structureName, 'Sh1EmptyRecord');
  assert.equal(emptyItems(value.body.typeArguments).length, 0);
  assert.equal(emptyItems(value.body.fields).length, 0);
  const origin = result.evidence.sourceOrigins.modules[0];
  const batches = origin.batches.filter((batch) =>
    batch.sourceName.length === 1 && ['Sh1EmptyRecord', 'sh1EmptyRecordValue'].includes(batch.sourceName[0]));
  assert.deepEqual(batches.map((batch) => batch.sourceName), [['Sh1EmptyRecord'], ['sh1EmptyRecordValue']]);
  assert.deepEqual(batches.map((batch) => batch.members.map((member) => member.role)),
    [['structureType', 'constructor', 'recursor'], ['sourceDeclaration']]);
  assert(batches.every((batch) => batch.normalization === null));
  return { sourceKind, structureName: layouts[0].name, valueName: value.name,
    moduleName: origin.moduleName, sourceDeclarationCount: 2, coreDeclarationCount: 4,
    constructorCount: 1, fieldCount: 0, recordFieldCount: 0,
    actualRecordValueRetained: true, inhabited: true,
    atomicAcceptedId: sourceKind + '-raw-imports-and-ordinary-do-spellings',
    atomicSourceInputsSha256: result.evidence.sourceInputsSha256,
    typeScriptArtifact: 'accepted-' + sourceKind + '.ts', typeScriptSha256: sha256(result.typeScript) };
}

function reservedRuntimeNameCases() {
  const definitions = [
  {
    "name": "Bool.and",
    "lean": "def Bool.and (left : Bool) (right : Bool) : Bool := true\n",
    "ps": "def Bool.and(left : Bool, right : Bool) : Bool := true\n"
  },
  {
    "name": "Bool.or",
    "lean": "def Bool.or (left : Bool) (right : Bool) : Bool := false\n",
    "ps": "def Bool.or(left : Bool, right : Bool) : Bool := false\n"
  },
  {
    "name": "Bool.not",
    "lean": "def Bool.not (value : Bool) : Bool := value\n",
    "ps": "def Bool.not(value : Bool) : Bool := value\n"
  },
  {
    "name": "Array.getInternal",
    "lean": "def Array.getInternal {alpha : Type} (values : Array alpha) (index : Nat) (fallback : alpha) : alpha := fallback\n",
    "ps": "def Array.getInternal {alpha : Type}(values : Array alpha, index : Nat, fallback : alpha) : alpha := fallback\n"
  },
  {
    "name": "Array.set",
    "lean": "def Array.set {alpha : Type} (values : Array alpha) (index : Nat) (value : alpha) (ignored : Nat) : Array alpha := values\n",
    "ps": "def Array.set {alpha : Type}(values : Array alpha, index : Nat, value : alpha, ignored : Nat) : Array alpha := values\n"
  },
  {
    "name": "String.Pos.Raw",
    "policyCode": "source-builtin-type-name-reserved",
    "lean": "inductive String.Pos.Raw where\n  | marker\n",
    "ps": "inductive String.Pos.Raw where {\n  | marker\n}\n"
  }
];
  return definitions.flatMap((definition) => ['lean', 'ps'].map((kind) => ({
    id: 'reserved-runtime-name-' + definition.name + '-' + kind, kind,
    inputs: [input(definition[kind])],
    code: kind === 'lean' ? definition.policyCode ?? 'source-intrinsic-name-reserved' : 'source-compiler',
    ...(kind === 'lean' ? { exactName: definition.name } : {}),
    boundary: kind === 'lean' ? 'portable-source-name-policy' : 'new-only-ps-declared-name-grammar',
  })));
}

// These cases must reach the structural elaborator. A parser/erasure refusal
// is not accepted as evidence for the intended root-IH/telescope boundary.
function structuralRecursionRefusalCases() {
  return [
  {
    "id": "nested-major-alias-lean",
    "kind": "lean",
    "boundary": "structural-recursion-provenance",
    "inputs": [
      {
        "moduleName": [
          "Ps",
          "Compiler",
          "StrictCase"
        ],
        "source": "def sh1NestedMajorAlias (n : Nat) : Nat :=\n  match n with\n  | Nat.zero => 0\n  | Nat.succ k =>\n      match n with\n      | Nat.zero => 100\n      | Nat.succ j => Nat.add (sh1NestedMajorAlias j) 1\n"
      }
    ],
    "code": "source-elaboration",
    "expectedOwner": "sh1NestedMajorAlias",
    "expectedDetail": "structuralRecursionNotDecreasing"
  },
  {
    "id": "nested-major-alias-ps",
    "kind": "ps",
    "boundary": "structural-recursion-provenance",
    "inputs": [
      {
        "moduleName": [
          "Ps",
          "Compiler",
          "StrictCase"
        ],
        "source": "def sh1NestedMajorAlias(n : Nat) : Nat :=\n  match n with {\n  | Nat.zero => 0\n  | Nat.succ k =>\n      match n with {\n      | Nat.zero => 100\n      | Nat.succ j => Nat.add(sh1NestedMajorAlias(j), 1)\n      }\n  }\n"
      }
    ],
    "code": "source-elaboration",
    "expectedOwner": "sh1NestedMajorAlias",
    "expectedDetail": "structuralRecursionNotDecreasing"
  },
  {
    "id": "nested-descendant-lean",
    "kind": "lean",
    "boundary": "structural-recursion-provenance",
    "inputs": [
      {
        "moduleName": [
          "Ps",
          "Compiler",
          "StrictCase"
        ],
        "source": "def sh1NestedDescendant (n : Nat) : Nat :=\n  match n with\n  | Nat.zero => 0\n  | Nat.succ k =>\n      match k with\n      | Nat.zero => 1\n      | Nat.succ j => Nat.add (sh1NestedDescendant j) 1\n"
      }
    ],
    "code": "source-elaboration",
    "expectedOwner": "sh1NestedDescendant",
    "expectedDetail": "structuralRecursionNotDecreasing"
  },
  {
    "id": "nested-descendant-ps",
    "kind": "ps",
    "boundary": "structural-recursion-provenance",
    "inputs": [
      {
        "moduleName": [
          "Ps",
          "Compiler",
          "StrictCase"
        ],
        "source": "def sh1NestedDescendant(n : Nat) : Nat :=\n  match n with {\n  | Nat.zero => 0\n  | Nat.succ k =>\n      match k with {\n      | Nat.zero => 1\n      | Nat.succ j => Nat.add(sh1NestedDescendant(j), 1)\n      }\n  }\n"
      }
    ],
    "code": "source-elaboration",
    "expectedOwner": "sh1NestedDescendant",
    "expectedDetail": "structuralRecursionNotDecreasing"
  },
  {
    "id": "implicit-major-dependent-proof",
    "kind": "lean",
    "boundary": "structural-recursion-original-telescope",
    "inputs": [
      {
        "moduleName": [
          "Ps",
          "Compiler",
          "StrictCase"
        ],
        "source": "def sh1ImplicitMajorProof {P : Nat -> Prop} (n : Nat) {h : P n} : Nat :=\n  match n with\n  | Nat.zero => 0\n  | Nat.succ k => sh1ImplicitMajorProof k\n"
      }
    ],
    "code": "source-elaboration",
    "expectedOwner": "sh1ImplicitMajorProof",
    "expectedDetail": "structuralRecursionDependentParameter"
  }
];
}

function sourceCases() {
  return [
    { id: 'empty-bundle', inputs: [], code: 'source-empty-bundle' },
    { id: 'duplicate-module', inputs: [input(literal), input(literal)], code: 'source-module-duplicate' },
    { id: 'forbidden-module', inputs: [{ moduleName: ['Ps', 'Kernel', 'StrictCase'], source: literal }],
      code: 'source-module-package' },
    { id: 'empty-module-segment', inputs: [{ moduleName: ['Ps', 'Compiler', ''], source: literal }],
      code: 'source-module-name' },
    { id: 'missing-import', inputs: [input('import Ps.Compiler.Missing\n' + literal)],
      code: 'source-import-unresolved' },
    { id: 'forward-import', inputs: [input('import Ps.Compiler.Later\n' + literal), input('', 'Later')],
      code: 'source-import-unresolved' },
    { id: 'self-import', inputs: [input('import Ps.Compiler.StrictCase\n' + literal)],
      code: 'source-import-unresolved' },
    { id: 'forbidden-import', inputs: [input('import Ps.Kernel.Forbidden\n' + literal)],
      code: 'source-import-package' },
    { id: 'non-package-import', inputs: [input('import Lean\n' + literal)],
      code: 'source-import-package' },
    { id: 'partial-definition',
      inputs: [input('partial def sh1Partial (value : Nat) : Nat := value\n')],
      code: 'source-partial-definition' },
    { id: 'do-expansion', inputs: [input('def sh1Do : Nat := do return 7\n')],
      code: 'source-do-unsupported', exactDoSpan: true },
    { id: 'missing-result-signature', inputs: [input('def sh1Missing (value : Nat) := value\n')],
      code: 'source-compiler' },
    { id: 'axiom-command', inputs: [input('axiom sh1Axiom : Nat\n')], code: 'source-compiler' },
    { id: 'opaque-command', inputs: [input('opaque sh1Opaque : Nat := 7\n')], code: 'source-compiler' },
    { id: 'old-ps-semicolon', kind: 'ps', inputs: [input('def sh1Old : Nat := 7;\n')],
      code: 'source-compiler' },
    { id: 'module-budget', inputs: [input(literal)], limits: { maxModules: 0 }, code: 'source-module-limit' },
    { id: 'input-byte-budget', inputs: [input(literal)], limits: { maxInputBytes: 25 },
      code: 'source-input-byte-limit' },
    { id: 'name-traversal-budget', inputs: [input(literal)], limits: { maxSyntaxSteps: 0 },
      code: 'source-name-limit' },
    { id: 'syntax-budget', inputs: [input(literal)], limits: { maxSyntaxSteps: 3 },
      code: 'source-syntax-limit' },
    { id: 'type-position-budget', inputs: [input(literal)], limits: { maxTypeSteps: 0 },
      code: 'source-type-limit' },
    { id: 'term-position-budget', inputs: [input(literal)], limits: { maxTermSteps: 0 },
      code: 'source-term-limit' },
    ...reservedRuntimeNameCases(),
    ...structuralRecursionRefusalCases(),
  ];
}

const sourceLimitKeys = ['maxModules', 'maxInputBytes', 'maxSyntaxSteps', 'maxTypeSteps', 'maxTermSteps'];
const irLimitKeys = ['maxSteps', 'maxTypeSteps', 'maxFindings'];

// These boundary probes intercept the atomic entry point and never delegate to
// it. The normal record/List factories do no source preparation or IR checking.
function probeIngressSnapshots(compiler, compilerSha256) {
  const aboveSafeInteger = BigInt(Number.MAX_SAFE_INTEGER) + 1n;
  const cases = [
    ...sourceLimitKeys.map((key) => ({ id: 'negative-source-' + key, group: 'source', key, value: -1n })),
    ...irLimitKeys.map((key) => ({ id: 'negative-ir-' + key, group: 'ir', key, value: -1n })),
    { id: 'number-source-maxModules', group: 'source', key: 'maxModules', value: 1 },
    { id: 'number-ir-maxTypeSteps', group: 'ir', key: 'maxTypeSteps', value: 1 },
    { id: 'missing-source-maxSyntaxSteps', group: 'source', key: 'maxSyntaxSteps', value: undefined },
    { id: 'missing-ir-maxSteps', group: 'ir', key: 'maxSteps', value: undefined },
    { id: 'unsafe-source-maxInputBytes', group: 'source', key: 'maxInputBytes', value: aboveSafeInteger },
    { id: 'unsafe-ir-maxFindings', group: 'ir', key: 'maxFindings', value: aboveSafeInteger },
  ];
  const malformedOptions = [];
  for (const test of cases) {
    let sourceGetterReads = 0;
    let atomicInterceptions = 0;
    const sourceOptions = Object.fromEntries(sourceLimitKeys.map((key) =>
      [key, compiler.psSh1DefaultSourceOptions[key]]));
    const irOptions = Object.fromEntries(irLimitKeys.map((key) =>
      [key, compiler.psIrCheckDefaultOptions[key]]));
    (test.group === 'source' ? sourceOptions : irOptions)[test.key] = test.value;
    const untouchedInput = {
      get moduleName() { sourceGetterReads++; throw new Error('PSC0_SH1_UNEXPECTED_SOURCE_READ'); },
      get source() { sourceGetterReads++; throw new Error('PSC0_SH1_UNEXPECTED_SOURCE_READ'); },
    };
    const spy = Object.create(compiler);
    Object.defineProperty(spy, 'psCompilerSh1TypeScriptSources', { value: () => {
      atomicInterceptions++;
      throw new Error('PSC0_SH1_UNEXPECTED_ATOMIC_CALL');
    } });
    const option = (test.group === 'source' ? 'sourceOptions.' : 'irOptions.') + test.key;
    const message = test.group === 'ir' && test.key === 'maxTypeSteps'
      ? 'PSC0_SH1_IR_OPTION: maxTypeSteps' : 'PSC0_SH1_SOURCE_REPORT_COUNT: ' + option;
    assert.throws(() => compileStrictSources(spy, [untouchedInput],
      { compilerSha256, sourceOptions, irOptions }), { message }, test.id);
    assert.equal(sourceGetterReads, 0, test.id);
    assert.equal(atomicInterceptions, 0, test.id);
    malformedOptions.push({ id: test.id, option, refused: true, sourceGetterReads, atomicInterceptions });
  }

  const optionGetterReads = {};
  const sourceValues = Object.fromEntries(sourceLimitKeys.map((key) => [key, 0n]));
  const irValues = { maxSteps: 0n, maxTypeSteps: aboveSafeInteger, maxFindings: 0n };
  const watchedOptions = (keys, values, prefix) => Object.fromEntries(keys.map((key) => {
    optionGetterReads[prefix + key] = 0;
    return [key, { enumerable: true, get() {
      optionGetterReads[prefix + key]++;
      return values[key];
    } }];
  }));
  const sourceOptions = Object.defineProperties({}, watchedOptions(sourceLimitKeys, sourceValues, 'source.'));
  const irOptions = Object.defineProperties({}, watchedOptions(irLimitKeys, irValues, 'ir.'));
  const inputReads = { length: 0, element: 0, moduleName: 0, moduleLength: 0, segments: [0, 0, 0], source: 0 };
  const originalName = ['Ps', 'Compiler', 'StrictSnapshot'];
  const callerName = [...originalName];
  const moduleName = new Proxy(callerName, { get(target, key, receiver) {
    if (key === 'length') inputReads.moduleLength++;
    if (key === '0' || key === '1' || key === '2') inputReads.segments[Number(key)]++;
    return Reflect.get(target, key, receiver);
  } });
  const switchedLiteral = 'def sh1Literal : Nat := 9\n';
  const callerInputs = [{
    get moduleName() { inputReads.moduleName++; return moduleName; },
    get source() {
      inputReads.source++;
      callerName[2] = 'ChangedAfterCapture';
      callerName.push('ExtraAfterCapture');
      callerInputs.length = 0;
      for (const key of sourceLimitKeys) sourceValues[key] = 1n;
      for (const key of irLimitKeys) irValues[key] = 1n;
      return inputReads.source === 1 ? literal : switchedLiteral;
    },
  }];
  const inputs = new Proxy(callerInputs, { get(target, key, receiver) {
    if (key === 'length') inputReads.length++;
    if (key === '0') inputReads.element++;
    return Reflect.get(target, key, receiver);
  } });
  const stop = new Error('PSC0_SH1_INGRESS_SNAPSHOT_PROBE_COMPLETE');
  let atomicInterceptions = 0;
  let portableInputSourceSha256;
  const spy = Object.create(compiler);
  Object.defineProperty(spy, 'psCompilerSh1TypeScriptSources', { value: (options, checkOptions, kind, ownedInputs) => {
    atomicInterceptions++;
    assert.notEqual(options, sourceOptions);
    assert.notEqual(checkOptions, irOptions);
    for (const key of sourceLimitKeys) assert.equal(options[key], 0n);
    assert.equal(checkOptions.maxSteps, 0n);
    assert.equal(checkOptions.maxFindings, 0n);
    assert.equal(checkOptions.maxTypeSteps, aboveSafeInteger);
    assert.equal(kind, compiler.PsCompilerSourceKind.lean);
    const expectedName = originalName.reduceRight((tail, head) => compiler.List.cons(head, tail), compiler.List.nil());
    assert.deepEqual(ownedInputs, compiler.List.cons(
      compiler.psSh1SourceInput(expectedName, literal), compiler.List.nil()));
    portableInputSourceSha256 = sha256(ownedInputs.head.source);
    assert.equal(portableInputSourceSha256, sha256(literal));
    assert.equal(callerInputs.length, 0);
    assert.deepEqual(callerName, ['Ps', 'Compiler', 'ChangedAfterCapture', 'ExtraAfterCapture']);
    assert.deepEqual(inputReads, { length: 1, element: 1, moduleName: 1, moduleLength: 1, segments: [1, 1, 1], source: 1 });
    for (const reads of Object.values(optionGetterReads)) assert.equal(reads, 1);
    throw stop;
  } });
  assert.throws(() => compileStrictSources(spy, inputs, { compilerSha256, sourceOptions, irOptions }),
    (error) => error === stop, 'PSC0_SH1_INGRESS_SNAPSHOT_PROBE');
  assert.equal(atomicInterceptions, 1);
  return {
    boundary: 'host-ingress-before-real-portable-call', malformedOptions,
    snapshotProbe: { optionGetterReads, inputReads, atomicInterceptions, portableInputSourceSha256,
      zeroBudgetCarriersRetained: true, irTypeBudget: aboveSafeInteger.toString(),
      realPortableCompilerCalls: 0, preparationCount: 0, portableIrCheckCount: 0 },
  };
}

// Reuse the two existing successful fixture calls to cover post-emission
// manifest/origin readback. Each source getter clears the caller name array
// after its segments have been captured; a second source read returns other text.
function watchedSourceInput(expected) {
  const source = expected.source;
  const expectedName = [...expected.moduleName];
  const reads = { moduleName: 0, source: 0, segments: expectedName.map(() => 0) };
  const callerName = [];
  expectedName.forEach((segment, index) => Object.defineProperty(callerName, index, {
    configurable: true, enumerable: true, get() { reads.segments[index]++; return segment; },
  }));
  const value = {
    get moduleName() { reads.moduleName++; return callerName; },
    get source() {
      reads.source++;
      callerName.length = 0;
      return reads.source === 1 ? source : 'def sh1UnexpectedReread : Nat := 9\n';
    },
  };
  return { value, reads, callerName,
    manifest: { moduleName: expectedName, sourceSha256: sha256(source), sourceBytes: Buffer.byteLength(source) } };
}

export async function runStrictSourceConformance({ compiler, compilerSha256, outDir }) {
  const ingressSnapshots = probeIngressSnapshots(compiler, compilerSha256);
  ingressSnapshots.emittedSourceCaptures = [];
  const accepted = [], emptyObservations = [], zeroFieldObservations = [], emittedBundles = [];
  const emptySources = {};
  for (const kind of ['lean', 'ps']) {
    const pin = sh1EmptySourceFixtures[kind];
    const source = await readFile(new URL('../' + pin.path, import.meta.url), 'utf8');
    assert.equal(sha256(source), pin.sha256, 'PSC0_SH1_EMPTY_FIXTURE_HASH: ' + kind);
    assert.equal(Buffer.byteLength(source), pin.bytes, 'PSC0_SH1_EMPTY_FIXTURE_BYTES: ' + kind);
    emptySources[kind] = source;
  }
  const libraries = {
    lean: 'structure Sh1DoField where\n  do : Nat\n' +
      'def sh1ExplicitHelpers (compilerPure : Nat -> Nat) (compilerBind : Nat -> Nat) (value : Nat) : Nat := compilerBind (compilerPure value)\n' +
      '-- do compilerPure compilerBind are comment text.\n' +
      'def sh1OriginWords : String := "do compilerPure compilerBind"\n' +
      'structure Sh1EmptyRecord where\n' +
      'def sh1EmptyRecordValue : Sh1EmptyRecord := {}\n',
    ps: 'structure Sh1DoField where {\n  do : Nat\n}\n' +
      'def sh1ExplicitHelpers(compilerPure : Nat -> Nat, compilerBind : Nat -> Nat, value : Nat) : Nat := compilerBind(compilerPure(value))\n' +
      '-- do compilerPure compilerBind are comment text.\n' +
      'def sh1OriginWords : String := "do compilerPure compilerBind"\n' +
      'structure Sh1EmptyRecord where {}\n' +
      'def sh1EmptyRecordValue : Sh1EmptyRecord := {}\n',
  };
  for (const kind of ['lean', 'ps']) {
    const library = input(libraries[kind], 'StrictLibrary');
    const entry = input('import Ps.Compiler.StrictLibrary\n' +
      (kind === 'lean' ? 'def sh1ReadDo (value : Sh1DoField) : Nat := value.do\n'
        : 'def sh1ReadDo(value : Sh1DoField) : Nat := value.do\n'), 'StrictEntry');
    const captures = [library, input(emptySources[kind], 'StrictEmpty'), entry].map(watchedSourceInput);
    const result = compileStrictSources(compiler, captures.map(({ value }) => value),
      { compilerSha256, sourceKind: kind });
    for (const capture of captures) {
      assert.deepEqual(capture.reads, { moduleName: 1, source: 1,
        segments: capture.manifest.moduleName.map(() => 1) });
      assert.equal(capture.callerName.length, 0);
    }
    const expectedManifest = captures.map(({ manifest }) => manifest);
    assert.deepEqual(result.evidence.sourceInputs, expectedManifest);
    assert.equal(result.evidence.sourceInputsSha256, sha256(JSON.stringify(expectedManifest)));
    ingressSnapshots.emittedSourceCaptures.push({ sourceKind: kind,
      inputReads: captures.map(({ reads }) => reads),
      sourceInputsSha256: result.evidence.sourceInputsSha256,
      manifestMatchesCapturedSources: true, additionalPreparations: 0 });
    assert.equal(result.evidence.sourcePolicy.importCount, 1);
    assert.equal(result.evidence.sourcePolicy.stats.declarationCount, 11);
    assert.equal(result.evidence.sourcePolicy.moduleCount, 3);
    assert.equal(result.evidence.sourceOrigins.sourceDeclarationCount, 11);
    assert.equal(result.evidence.sourceOrigins.coreDeclarationCount, 16);
    assert.equal(result.evidence.sourceOrigins.normalizationCount, 0);
    emptyObservations.push(observeEmptySource(result, kind, emptySources[kind]));
    zeroFieldObservations.push(observeZeroFieldRecord(result, kind));
    emittedBundles.push(result.typeScript);
    accepted.push({ id: kind + '-raw-imports-and-ordinary-do-spellings', ...result.evidence });
  }
  assert.equal(emittedBundles[0], emittedBundles[1], 'PSC0_SH1_EMPTY_LEAN_PS_EMISSION_PARITY');
  const emptyElimination = {
    feature: 'regular-empty-data-and-single-scrutinee-elimination',
    sourceEdition: 'ps-0.9-r3', sourceMode: 'new-only', observations: emptyObservations,
    emittedTypeScriptEqual: true, typeScriptSha256: sha256(emittedBundles[0]),
    additionalPreparations: 0, additionalPortableIrChecks: 0,
    nativeValueOracle: false, strictSh1Qualified: false,
    semanticContractQualified: false, providerChecked: false,
  };
  const zeroFieldRecords = {
    feature: 'inhabited-zero-field-structures', observations: zeroFieldObservations,
    emittedTypeScriptEqual: true, typeScriptSha256: sha256(emittedBundles[0]),
    observationBoundary: 'actual-original-ir-after-atomic-emission',
    additionalPreparations: 0, additionalPortableIrChecks: 0,
    strictSh1Qualified: false, semanticContractQualified: false, providerChecked: false,
  };
  const refused = [];
  for (const test of sourceCases()) {
    let failure;
    try {
      compileStrictSources(compiler, test.inputs, { compilerSha256, sourceKind: test.kind ?? 'lean',
        sourceOptions: strictSourceOptions(compiler, test.limits ?? {}) });
    } catch (error) {
      failure = error.strictFailure;
      if (!failure) throw error;
    }
    assert(failure, 'PSC0_SH1_SOURCE_REFUSAL_MISSING: ' + test.id);
    assert.equal(failure.code, test.code, 'PSC0_SH1_SOURCE_REFUSAL_CODE: ' + test.id);
    if (test.expectedDetail) {
      assert.equal(failure.compilerStage, 'elaboration', 'PSC0_SH1_RECURSION_REFUSAL_STAGE: ' + test.id);
      assert.equal(failure.detail, test.expectedDetail, 'PSC0_SH1_RECURSION_REFUSAL_DETAIL: ' + test.id);
      assert.equal(failure.owner, test.expectedOwner, 'PSC0_SH1_RECURSION_REFUSAL_OWNER: ' + test.id);
    }
    if (test.exactName) {
      const offset = test.inputs[0].source.indexOf(test.exactName);
      assert.equal(failure.owner, test.exactName);
      assert.equal(failure.span?.start?.byteOffset, offset);
      assert.equal(failure.span?.stop?.byteOffset, offset + test.exactName.length);
    }
    if (test.exactDoSpan) {
      const offset = test.inputs[0].source.indexOf('do return');
      assert.equal(failure.span?.start?.byteOffset, offset);
      assert.equal(failure.span?.stop?.byteOffset, offset + 2);
    }
    refused.push({ id: test.id, sourceKind: test.kind ?? 'lean',
      inputSha256: sha256(JSON.stringify(test.inputs)), limits: test.limits ?? {},
      ...(test.boundary ? { boundary: test.boundary } : {}), failure });
  }
  const badText = [String.fromCharCode(0xd800), String.fromCharCode(0xdc00)];
  const carrierRefusals = [];
  for (let index = 0; index < badText.length; index++) {
    assert.throws(() => compileStrictSources(compiler,
      [input('def sh1Text : String := "' + badText[index] + '"\n')], { compilerSha256 }),
    /PSC0_SH1_SOURCE_UNICODE/u);
    carrierRefusals.push({ id: index === 0 ? 'lone-high-surrogate' : 'lone-low-surrogate',
      boundary: 'host-source-carrier-before-portable-call', refused: true });
  }
  const receipt = {
    schemaVersion: 1, evidence: 'portable-source-boundary-conformance', compilerSha256,
    accepted, refused, carrierRefusals, ingressSnapshots, emptyElimination, zeroFieldRecords,
    sourcePolicyGenerations: 'This exact executing compiler only; full current closure has its separate generation receipt.',
    strictSh1Qualified: false, semanticContractQualified: false,
    provider: { status: 'not-attempted', kernelChecked: false },
  };
  await mkdir(outDir, { recursive: true });
  for (const [index, kind] of ['lean', 'ps'].entries()) {
    const observation = emptyObservations[index];
    await writeFile(path.join(outDir, observation.sourceArtifact), emptySources[kind]);
    await writeFile(path.join(outDir, observation.typeScriptArtifact), emittedBundles[index]);
  }
  await writeFile(path.join(outDir, 'source-cases.json'), JSON.stringify(sourceCases(), null, 2) + '\n');
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_STRICT_SOURCE: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
