import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import {
  runSh1FreshNameCases, sh1FreshNameRequiredExports, assertMigrationRequiredExports,
} from './sh1-fresh-name-conformance.mjs';

// These gates accept already loaded compiler instances and already prepared
// products. They do not load code, read files, spawn processes, or select seeds.
const sha256 = (value) => createHash('sha256').update(value).digest('hex');

// One finite preflight covers F1 and F2 before either section constructs inputs.
// Every name is an existing generated export; no structure namespace is assumed.
const migrationRequiredExports = Object.freeze([...new Set([
  ...sh1FreshNameRequiredExports,
  'Option.some',
  'PsDeclaration.axiomDecl', 'PsDeclaration.definitionDecl',
  'PsDeclaration.theoremDecl', 'PsDeclaration.partialDecl',
  'PsDeclaration.opaqueDecl', 'PsDeclaration.inductiveDecl',
  'PsExpr.constE', 'PsExpr.lit', 'PsExpr.app', 'PsExpr.proj', 'PsExpr.fvar',
  'PsLiteral.natural', 'PsVerifiedIrType.named',
  'psNameAppendStr', 'psNameToString', 'psDeclarationName',
  'psEnvironmentAdd', 'psEnvironmentFind',
  'psCompilerParseSource', 'psCompilerElaborateSource',
  'psCompilerPreparationStart', 'psCompilerPreparationStepParsed',
  'psCompilerPreparationSourcesWorker', 'psAddDeclarationListWorker',
  'psElabDeclarationsWorker', 'psBuildErasureDeclarationNamesWorker',
  'psEraseDefinitionsLoopWorker', 'psPrepareRuntimeStructures',
  'psPrepareRuntimeInductives', 'psTsBuildSymbolMap',
  'psLocalPushBinding', 'psErasureLookupStructure',
  'psErasureLookupConstructor', 'psErasureLookupRecursor',
  'psPrepareRuntimeStructure', 'psPrepareRuntimeInductive',
  'psTsBuildBrandMap', 'psTsBuildTagMap',
  'psIrCheckMakeDeclaration', 'psIrCheckMakeStructureField',
  'psIrCheckMakeStructure', 'psIrCheckMakeConstructorField',
  'psIrCheckMakeConstructor', 'psIrCheckMakeInductive', 'psIrCheckMakeModule',
])]);

const f2CaseNames = [
  'preparation-empty-state', 'preparation-ordered-dependencies',
  'preparation-first-parse-error', 'preparation-middle-elaboration-error',
  'preparation-parsed-step-correspondence',
  'add-empty-environment', 'add-ordered-declarations', 'add-duplicate-initial',
  'add-duplicate-earlier-input', 'add-owned-bootstrap-replacement',
  'elab-empty-reverse-accumulator', 'elab-ordered-batches',
  'elab-first-failure', 'elab-duplicate-before-tail-failure',
  'names-empty-state', 'names-kind-whitelist',
  'names-sanitizing-collisions', 'names-prefix-and-fallback',
  'erase-empty-reverse-accumulator', 'erase-definition-and-partial',
  'erase-proof-omission', 'erase-skipped-variants', 'erase-first-refusal',
  'structures-empty-reverse-accumulator', 'structures-mixed-stream',
  'structures-threaded-scope', 'structures-first-refusal',
  'inductives-empty-reverse-accumulator', 'inductives-mixed-stream',
  'inductives-threaded-scope', 'inductives-first-refusal',
  'symbols-empty-state', 'symbols-collision-and-index',
  'symbols-duplicate-source-names', 'symbols-brand-wrapper', 'symbols-tag-wrapper',
];

const metadataSource = [
  'structure F2RecordA where',
  '  value : Nat',
  'structure F2RecordB where',
  '  prior : F2RecordA',
  'inductive F2ChoiceA where',
  '  | first',
  '  | second',
  'inductive F2ChoiceB where',
  '  | wrap (prior : F2ChoiceA)',
  'def f2Proof (p : Prop) (h : p) : p := h',
  '',
].join('\n');

function ownedApi(compiler, valueTag) {
  const fail = (label) => 'PSC0_SH1_F2_' + label;
  const list = (values) => values.reduceRight(
    (tail, head) => compiler.List.cons(head, tail), compiler.List.nil());
  const array = (value) => {
    const result = [];
    while (valueTag(value) === 'cons') {
      assert(result.length < 20000, fail('LIST_BOUND'));
      result.push(value.head);
      value = value.tail;
    }
    assert.equal(valueTag(value), 'nil', fail('LIST_SHAPE'));
    return result;
  };
  const plain = (value, depth = 0) => {
    assert(depth < 128, fail('OBSERVATION_DEPTH'));
    if (typeof value === 'bigint') return value.toString();
    if (value === null || typeof value === 'string' || typeof value === 'boolean') return value;
    if (typeof value === 'number') {
      assert(Number.isFinite(value), fail('OBSERVATION_NUMBER'));
      return value;
    }
    if (Array.isArray(value)) return value.map((item) => plain(item, depth + 1));
    assert(value !== null && typeof value === 'object', fail('OBSERVATION_VALUE'));
    const tag = valueTag(value);
    if (tag === 'cons' || tag === 'nil') return array(value).map((item) => plain(item, depth + 1));
    const result = tag === undefined ? {} : { tag };
    for (const key of Object.keys(value).sort()) result[key] = plain(value[key], depth + 1);
    return result;
  };
  const ok = (value, label) => {
    if (valueTag(value) !== 'ok') {
      assert.fail(fail(label + '_OK') + ': ' + JSON.stringify(plain(value)));
    }
    return value.value;
  };
  const some = (value, label) => {
    assert.equal(valueTag(value), 'some', fail(label + '_SOME'));
    return value.value;
  };
  const error = (value, tag, label) => {
    assert.equal(valueTag(value), 'error', fail(label + '_ERROR'));
    assert.equal(valueTag(value.error), tag, fail(label + '_DIAGNOSTIC'));
    return value.error;
  };
  const name = (text) => text.split('.').reduce(
    (parent, part) => compiler.psNameAppendStr(parent, part), compiler.PsName.anonymous);
  const nameText = (value) => compiler.psNameToString(value);
  const declName = (value) => nameText(compiler.psDeclarationName(value));
  const expr = compiler.PsExpr;
  const nil = list([]);
  const nat = expr.constE(name('Nat'), nil);
  const literal = (value) => expr.lit(compiler.PsLiteral.natural(BigInt(value)));
  const definition = (text, value) => compiler.PsDeclaration.definitionDecl(
    name(text), nil, nat, typeof value === 'string' ? expr.constE(name(value), nil) : literal(value));
  const axiom = (text) => compiler.PsDeclaration.axiomDecl(name(text), nil, nat);
  const add = (environment, declarations) => {
    let result = environment;
    for (const declaration of declarations) {
      result = some(compiler.psEnvironmentAdd(result, declaration), 'FIXTURE_ENVIRONMENT');
    }
    return result;
  };
  const parse = (source, label) => ok(compiler.psCompilerParseSource(
    compiler.PsCompilerSourceKind.lean, source), label + '_PARSE');
  const find = (environment, text) => some(
    compiler.psEnvironmentFind(environment, name(text)), 'LOOKUP_' + text);
  const same = (actual, expected, label) => assert.deepEqual(plain(actual), plain(expected), fail(label));
  const expectEnvironment = (actual, newestFirst, base, label) => {
    const values = array(actual.declarations);
    same(values, [...newestFirst, ...array(base.declarations)], label + '_DECLARATION_ORDER');
    for (const declaration of newestFirst) {
      same(find(actual, declName(declaration)), declaration, label + '_LOOKUP_' + declName(declaration));
    }
    return {
      declarationCount: values.length,
      addedNewestFirst: newestFirst.map(declName),
      declarations: plain(newestFirst),
    };
  };
  const namedError = (result, tag, expectedName, label) => {
    const diagnostic = error(result, tag, label);
    assert.equal(nameText(diagnostic.name), expectedName, fail(label + '_NAME'));
    return plain(diagnostic);
  };
  const natIr = compiler.PsVerifiedIrType.primitive(compiler.PsVerifiedIrPrimitiveType.nat);
  const irLiteral = (value) => compiler.PsVerifiedIrExpr.literal(
    compiler.PsVerifiedIrLiteral.natural(BigInt(value)));
  const irDefinition = (text, value) => compiler.psIrCheckMakeDeclaration(
    text, nil, nil, natIr, irLiteral(value));
  return {
    compiler, valueTag, fail, list, array, plain, ok, some, error, name, nameText, declName,
    expr, nil, nat, literal, definition, axiom, add, parse, find, same,
    expectEnvironment, namedError, natIr, irLiteral, irDefinition,
  };
}

function runF2Cases(compiler, valueTag) {
  const api = ownedApi(compiler, valueTag);
  const {
    fail, list, array, plain, ok, some, error, name, nameText, declName,
    expr, nil, nat, literal, definition, axiom, add, parse, find, same,
    expectEnvironment, namedError, natIr, irLiteral, irDefinition,
  } = api;
  for (const exportName of [
    'psCompilerPreparationSourcesWorker', 'psAddDeclarationListWorker',
    'psElabDeclarationsWorker', 'psBuildErasureDeclarationNamesWorker',
    'psEraseDefinitionsLoopWorker', 'psPrepareRuntimeStructures',
    'psPrepareRuntimeInductives', 'psTsBuildSymbolMap',
  ]) assert.equal(typeof compiler[exportName], 'function', fail('EXPORT_' + exportName));

  const observations = [];
  const observe = (caseName, run) => {
    assert(!observations.some((item) => item.name === caseName), fail('DUPLICATE_CASE'));
    observations.push({ name: caseName, result: run() });
  };
  const prelude = compiler.psSelfHostProdPreludeEnvironment;
  const prefix = definition('f2Prefix', 11);
  const first = definition('f2First', 17);
  const second = definition('f2Second', 23);
  const prefixEnvironment = add(prelude, [prefix]);
  const sourceKind = compiler.PsCompilerSourceKind.lean;
  const prefixState = {
    ...compiler.psCompilerPreparationStart(sourceKind),
    environment: prefixEnvironment,
    declarationsRev: list([prefix]),
  };
  const sources = [
    'def f2Base : Nat := 17\n',
    'def f2Next : Nat := f2Base\n',
    'def f2Last : Nat := f2Next\n',
  ];
  const base = definition('f2Base', 17);
  const next = definition('f2Next', 'f2Base');
  const last = definition('f2Last', 'f2Next');
  const sourceDeclarationsRev = [last, next, base, prefix];
  const preparationSnapshot = (state, expected, label) => {
    assert.equal(valueTag(state.sourceKind), 'lean', fail(label + '_SOURCE_KIND'));
    same(state.declarationsRev, list(expected), label + '_ACCUMULATOR');
    return {
      sourceKind: 'lean',
      declarationsRev: plain(state.declarationsRev),
      environment: expectEnvironment(state.environment, expected, prelude, label),
    };
  };
  observe('preparation-empty-state', () => {
    const state = ok(compiler.psCompilerPreparationSourcesWorker(nil, prefixState), 'PREPARATION_EMPTY');
    return preparationSnapshot(state, [prefix], 'PREPARATION_EMPTY');
  });
  observe('preparation-ordered-dependencies', () => {
    const state = ok(compiler.psCompilerPreparationSourcesWorker(
      list(sources), prefixState), 'PREPARATION_ORDERED');
    return preparationSnapshot(state, sourceDeclarationsRev, 'PREPARATION_ORDERED');
  });
  observe('preparation-first-parse-error', () => {
    const result = compiler.psCompilerPreparationSourcesWorker(list([
      'def f2Broken : Nat :=\n',
      'def f2Tail : Nat := f2MissingTail\n',
    ]), prefixState);
    return plain(error(result, 'leanFrontend', 'PREPARATION_PARSE_FIRST'));
  });
  observe('preparation-middle-elaboration-error', () => {
    const result = compiler.psCompilerPreparationSourcesWorker(list([
      sources[0],
      'def f2Broken : Nat := f2MissingSecond\n',
      'def f2Tail : Nat := f2MissingThird\n',
    ]), prefixState);
    const diagnostic = error(result, 'elaboration', 'PREPARATION_ELAB_FIRST');
    assert.equal(valueTag(diagnostic.error), 'unknownName', fail('PREPARATION_ELAB_KIND'));
    assert.equal(nameText(diagnostic.error.name), 'f2MissingSecond', fail('PREPARATION_ELAB_NAME'));
    return plain(diagnostic);
  });
  observe('preparation-parsed-step-correspondence', () => {
    let state = prefixState;
    for (const source of sources) {
      state = ok(compiler.psCompilerPreparationStepParsed(
        state, parse(source, 'PARSED_STEP')), 'PARSED_STEP');
    }
    const expected = preparationSnapshot(state, sourceDeclarationsRev, 'PARSED_STEPS');
    const direct = ok(compiler.psCompilerPreparationSourcesWorker(
      list(sources), prefixState), 'PREPARATION_CORRESPONDENCE');
    assert.deepEqual(preparationSnapshot(direct, sourceDeclarationsRev,
      'PREPARATION_CORRESPONDENCE'), expected, fail('PARSED_STEP_CORRESPONDENCE'));
    return expected;
  });

  observe('add-empty-environment', () => {
    const result = ok(compiler.psAddDeclarationListWorker(nil, prefixEnvironment), 'ADD_EMPTY');
    return expectEnvironment(result, [prefix], prelude, 'ADD_EMPTY');
  });
  observe('add-ordered-declarations', () => {
    const result = ok(compiler.psAddDeclarationListWorker(
      list([first, second]), prefixEnvironment), 'ADD_ORDERED');
    return expectEnvironment(result, [second, first, prefix], prelude, 'ADD_ORDERED');
  });
  observe('add-duplicate-initial', () => namedError(compiler.psAddDeclarationListWorker(
    list([definition('f2Prefix', 99), first]), prefixEnvironment),
  'duplicateDeclaration', 'f2Prefix', 'ADD_DUPLICATE_INITIAL'));
  observe('add-duplicate-earlier-input', () => namedError(compiler.psAddDeclarationListWorker(
    list([first, definition('f2First', 99), definition('f2Prefix', 88)]), prefixEnvironment),
  'duplicateDeclaration', 'f2First', 'ADD_DUPLICATE_INPUT'));
  observe('add-owned-bootstrap-replacement', () => {
    const results = [];
    // Deliberate helper-only environments: insertion is under test, not the
    // admission of a declaration with a builtin name and this placeholder type.
    for (const text of ['Prod', 'List', 'Option']) {
      const placeholder = axiom(text);
      const replacement = definition(text, 7);
      const initial = add(compiler.psEnvironmentEmpty, [placeholder]);
      const result = ok(compiler.psAddDeclarationListWorker(
        list([replacement]), initial), 'BOOTSTRAP_REPLACE_' + text);
      const environment = expectEnvironment(result, [replacement],
        compiler.psEnvironmentEmpty, 'BOOTSTRAP_REPLACE_' + text);
      const rejection = namedError(compiler.psAddDeclarationListWorker(
        list([definition(text, 8)]), result),
      'duplicateDeclaration', text, 'BOOTSTRAP_REPEAT_' + text);
      results.push({ name: text, environment, rejection });
    }
    return results;
  });

  observe('elab-empty-reverse-accumulator', () => {
    const environment = add(prefixEnvironment, [first, second]);
    const result = ok(compiler.psElabDeclarationsWorker(
      nil, environment, list([second, first, prefix])), 'ELAB_EMPTY');
    same(result.declarations, list([prefix, first, second]), 'ELAB_EMPTY_REVERSE');
    return {
      declarations: plain(result.declarations),
      environment: expectEnvironment(result.environment, [second, first, prefix], prelude, 'ELAB_EMPTY'),
    };
  });
  observe('elab-ordered-batches', () => {
    const source = [
      'structure F2Cell where',
      '  value : Nat',
      'def f2Cell : F2Cell := F2Cell.mk 31',
      'def f2Read : Nat := f2Cell.value',
      '',
    ].join('\n');
    const parsed = parse(source, 'ELAB_BATCHES');
    const result = ok(compiler.psElabDeclarationsWorker(
      parsed.declarations, prefixEnvironment, list([prefix])), 'ELAB_BATCHES');
    const declarations = array(result.declarations);
    assert.deepEqual(declarations.map(declName),
      ['f2Prefix', 'F2Cell', 'F2Cell.mk', 'F2Cell.rec', 'f2Cell', 'f2Read'],
    fail('ELAB_BATCH_ORDER'));
    assert.equal(valueTag(declarations[1]), 'inductiveDecl', fail('ELAB_BATCH_INDUCTIVE'));
    assert.equal(declarations[1].info.isStructure, true, fail('ELAB_BATCH_STRUCTURE'));
    assert.equal(valueTag(declarations[2]), 'constructorDecl', fail('ELAB_BATCH_CONSTRUCTOR'));
    assert.equal(valueTag(declarations[3]), 'recursorDecl', fail('ELAB_BATCH_RECURSOR'));
    same(find(result.environment, 'f2Cell').value,
      expr.app(expr.constE(name('F2Cell.mk'), nil), literal(31)), 'ELAB_BATCH_CONSTRUCTOR_USE');
    same(find(result.environment, 'f2Read').value,
      expr.proj(name('F2Cell'), 0n, expr.constE(name('f2Cell'), nil)), 'ELAB_BATCH_FIELD_USE');
    return {
      declarations: plain(declarations),
      environment: expectEnvironment(result.environment, [...declarations].reverse(), prelude, 'ELAB_BATCHES'),
    };
  });
  observe('elab-first-failure', () => {
    const parsed = parse([
      'def f2Broken : Nat := f2MissingFirst',
      'def f2Tail : Nat := f2MissingSecond',
      '',
    ].join('\n'), 'ELAB_FIRST_ERROR');
    return namedError(compiler.psElabDeclarationsWorker(
      parsed.declarations, prefixEnvironment, list([prefix])),
    'unknownName', 'f2MissingFirst', 'ELAB_FIRST_ERROR');
  });
  observe('elab-duplicate-before-tail-failure', () => {
    const parsed = parse([
      'def f2Prefix : Nat := 99',
      'def f2Tail : Nat := f2MissingTail',
      '',
    ].join('\n'), 'ELAB_DUPLICATE_FIRST');
    return namedError(compiler.psElabDeclarationsWorker(
      parsed.declarations, prefixEnvironment, list([prefix])),
    'duplicateDeclaration', 'f2Prefix', 'ELAB_DUPLICATE_FIRST');
  });

  const metadata = ok(compiler.psCompilerElaborateSource(
    sourceKind, metadataSource), 'METADATA');
  const metadataDeclarations = array(metadata.declarations);
  assert.deepEqual(metadataDeclarations.map(declName), [
    'F2RecordA', 'F2RecordA.mk', 'F2RecordA.rec',
    'F2RecordB', 'F2RecordB.mk', 'F2RecordB.rec',
    'F2ChoiceA', 'F2ChoiceA.first', 'F2ChoiceA.second', 'F2ChoiceA.rec',
    'F2ChoiceB', 'F2ChoiceB.wrap', 'F2ChoiceB.rec', 'f2Proof',
  ], fail('METADATA_DECLARATIONS'));
  const recordA = find(metadata.environment, 'F2RecordA');
  const recordB = find(metadata.environment, 'F2RecordB');
  const choiceA = find(metadata.environment, 'F2ChoiceA');
  const choiceB = find(metadata.environment, 'F2ChoiceB');
  const recordConstructor = find(metadata.environment, 'F2RecordA.mk');
  const choiceRecursor = find(metadata.environment, 'F2ChoiceA.rec');
  const proofDeclaration = find(metadata.environment, 'f2Proof');
  const naturalPartial = compiler.PsDeclaration.partialDecl(name('f2Partial'), nil, nat, literal(29));
  const proofTheorem = compiler.PsDeclaration.theoremDecl(name('f2Theorem'),
    proofDeclaration.levelParams, proofDeclaration.type, proofDeclaration.value);
  const naturalOpaque = compiler.PsDeclaration.opaqueDecl(name('f2Opaque'), nil, nat, literal(41));
  // These two worker-state types have no neutral exported constructor. Their
  // worker paths only project fields, so use explicit unbranded host structural
  // fixtures with this compiler's List/Prod/Name children. They are not claimed
  // to be compiler-created records or submitted to original-IR carrier checking.
  const nameState = (used, entries) => ({
    used: list(used),
    entriesRev: list(entries.map(([text, output]) =>
      compiler.psIrCheckMakePair(name(text), output))),
  });
  const nameStateView = (state) => ({
    used: array(state.used),
    entriesRev: array(state.entriesRev).map((entry) => [nameText(entry.fst), entry.snd]),
  });
  observe('names-empty-state', () => {
    const state = nameState(['usedBefore'], [['before', 'before_output']]);
    const result = compiler.psBuildErasureDeclarationNamesWorker(nil, state);
    const view = nameStateView(result);
    assert.deepEqual(view, {
      used: ['usedBefore'], entriesRev: [['before', 'before_output']],
    }, fail('NAMES_EMPTY'));
    return view;
  });
  observe('names-kind-whitelist', () => {
    const values = [
      first, naturalPartial, proofTheorem, choiceA,
      axiom('f2Axiom'), naturalOpaque, recordConstructor, choiceRecursor,
    ];
    const result = compiler.psBuildErasureDeclarationNamesWorker(list(values),
      nameState(['usedBefore'], [['before', 'before_output']]));
    const view = nameStateView(result);
    assert.deepEqual(view, {
      used: ['F2ChoiceA', 'f2Theorem', 'f2Partial', 'f2First', 'usedBefore'],
      entriesRev: [
        ['F2ChoiceA', 'F2ChoiceA'], ['f2Theorem', 'f2Theorem'],
        ['f2Partial', 'f2Partial'], ['f2First', 'f2First'],
        ['before', 'before_output'],
      ],
    }, fail('NAMES_WHITELIST'));
    return view;
  });
  observe('names-sanitizing-collisions', () => {
    const result = compiler.psBuildErasureDeclarationNamesWorker(list([
      definition('a.b', 1), definition('a_b', 2), definition('a.b', 3),
    ]), nameState(['a_b', 'a_b_'], [['before', 'before_output']]));
    const view = nameStateView(result);
    assert.deepEqual(view, {
      used: ['a_b____', 'a_b___', 'a_b__', 'a_b', 'a_b_'],
      entriesRev: [
        ['a.b', 'a_b____'], ['a_b', 'a_b___'], ['a.b', 'a_b__'],
        ['before', 'before_output'],
      ],
    }, fail('NAMES_COLLISIONS'));
    return view;
  });
  observe('names-prefix-and-fallback', () => {
    // The empty rendered name is a focused name-helper input, not a parsed declaration.
    const result = compiler.psBuildErasureDeclarationNamesWorker(
      list([definition('1name', 1), definition('', 2)]), nameState([], []));
    const view = nameStateView(result);
    assert.deepEqual(view, {
      used: ['decl', '_1name'], entriesRev: [['', 'decl'], ['1name', '_1name']],
    }, fail('NAMES_FALLBACK'));
    return view;
  });

  const eraseScope = compiler.psErasureScopeEmpty(list([
    compiler.psIrCheckMakePair(name('f2First'), 'runtime_first'),
    compiler.psIrCheckMakePair(name('f2Partial'), 'runtime_partial'),
    compiler.psIrCheckMakePair(name('f2Proof'), 'runtime_proof'),
  ]));
  const irFirst = irDefinition('runtime_first', 17);
  const irPartial = irDefinition('runtime_partial', 29);
  const irSecond = irDefinition('f2Second', 23);
  const keptA = irDefinition('keptA', 5);
  const keptB = irDefinition('keptB', 6);
  const erase = (declarations, accumulator, label) => ok(compiler.psEraseDefinitionsLoopWorker(
    metadata.environment, eraseScope, list(declarations), list(accumulator)), label);
  observe('erase-empty-reverse-accumulator', () => {
    const result = erase([], [keptB, keptA], 'ERASE_EMPTY');
    same(result, list([keptA, keptB]), 'ERASE_EMPTY_REVERSE');
    return plain(result);
  });
  observe('erase-definition-and-partial', () => {
    const result = erase([first, naturalPartial], [keptA], 'ERASE_BOTH');
    same(result, list([keptA, irFirst, irPartial]), 'ERASE_BOTH_ORDER_AND_VALUE');
    return plain(result);
  });
  observe('erase-proof-omission', () => {
    const result = erase([first, proofDeclaration, second], [], 'ERASE_PROOF');
    same(result, list([irFirst, irSecond]), 'ERASE_PROOF_OMITTED');
    return plain(result);
  });
  observe('erase-skipped-variants', () => {
    const result = erase([
      proofTheorem, axiom('f2Axiom'), naturalOpaque,
      recordA, recordConstructor, choiceRecursor, first,
    ], [], 'ERASE_SKIPPED');
    same(result, list([irFirst]), 'ERASE_SKIPPED_VARIANTS');
    return plain(result);
  });
  observe('erase-first-refusal', () => {
    const badFirst = compiler.PsDeclaration.definitionDecl(
      name('f2BadFirst'), nil, nat, expr.fvar(701n));
    const badSecond = compiler.PsDeclaration.partialDecl(
      name('f2BadSecond'), nil, nat, expr.fvar(702n));
    const result = compiler.psEraseDefinitionsLoopWorker(
      metadata.environment, eraseScope, list([badFirst, badSecond]), list([keptA]));
    const diagnostic = error(result, 'unknownLocal', 'ERASE_FIRST_REFUSAL');
    assert.equal(diagnostic.id, 701n, fail('ERASE_FIRST_REFUSAL_ID'));
    return plain(diagnostic);
  });

  const scopeNames = list([
    compiler.psIrCheckMakePair(name('F2RecordA'), 'record_A'),
    compiler.psIrCheckMakePair(name('F2RecordB'), 'record_B'),
    compiler.psIrCheckMakePair(name('F2ChoiceA'), 'choice_A'),
    compiler.psIrCheckMakePair(name('F2ChoiceB'), 'choice_B'),
  ]);
  const emptyScope = compiler.psErasureScopeEmpty(scopeNames);
  const pushed = compiler.psLocalPushBinding(
    emptyScope.localContext, name('keptLocal'), nat, compiler.PsBinderInfo.explicit);
  const seededScope = {
    ...emptyScope,
    localContext: pushed.context,
    runtimeLocals: list([compiler.psIrCheckMakePair(pushed.id, 'keptRuntime')]),
    runtimeExpressions: list([
      compiler.psIrCheckMakePair(pushed.id, compiler.PsVerifiedIrExpr.var('keptRuntime')),
    ]),
    // A third explicit host structural fixture: preparation resets this marker
    // to none without reading its fields or brand. Preserve that reset case.
    currentDefinition: compiler.Option.some({
      name: 'keptDefinition', typeArgumentsRev: nil, runtimeParameters: list(['keptRuntime']),
    }),
  };
  const namedIr = (text) => compiler.PsVerifiedIrType.named(text, nil);
  const irRecordA = compiler.psIrCheckMakeStructure('record_A', nil,
    list([compiler.psIrCheckMakeStructureField('value', natIr)]));
  const irRecordB = compiler.psIrCheckMakeStructure('record_B', nil,
    list([compiler.psIrCheckMakeStructureField('prior', namedIr('record_A'))]));
  const irChoiceA = compiler.psIrCheckMakeInductive('choice_A', nil, list([
    compiler.psIrCheckMakeConstructor('first', nil),
    compiler.psIrCheckMakeConstructor('second', nil),
  ]));
  const irChoiceB = compiler.psIrCheckMakeInductive('choice_B', nil,
    list([compiler.psIrCheckMakeConstructor('wrap',
      list([compiler.psIrCheckMakeConstructorField('prior', namedIr('choice_A'))]))]));
  const keptRecordA = compiler.psIrCheckMakeStructure('keptRecordA', nil, nil);
  const keptRecordB = compiler.psIrCheckMakeStructure('keptRecordB', nil, nil);
  const keptChoiceA = compiler.psIrCheckMakeInductive('keptChoiceA', nil, nil);
  const keptChoiceB = compiler.psIrCheckMakeInductive('keptChoiceB', nil, nil);
  const completeDeclarations = metadata.declarations;
  const badInfo = (declaration, missing) => {
    const info = declaration.info;
    return compiler.PsDeclaration.inductiveDecl({
      ...info,
      constructors: list([name(missing)]),
    });
  };
  const commonScopeFields = [
    'localContext', 'runtimeLocals', 'typeLocals', 'erasedLocals', 'declarationNames',
  ];
  const scopeFields = (value, keys) => Object.fromEntries(
    keys.map((key) => [key, plain(value[key])]));
  const expectScopeBase = (value, before, extraKeys, label) => {
    const keys = [...commonScopeFields, ...extraKeys];
    assert.deepEqual(scopeFields(value, keys), scopeFields(before, keys),
      fail(label + '_PRESERVED_SCOPE'));
    same(value.runtimeExpressions, nil, label + '_EXPRESSION_RESET');
    assert.equal(valueTag(value.currentDefinition), 'none', fail(label + '_DEFINITION_RESET'));
  };
  const runtimeStructureView = (scopeValue, text, constructor) => {
    const typeEntry = some(compiler.psErasureLookupStructure(
      scopeValue.runtimeStructures, name(text)), 'STRUCTURE_' + text);
    const constructorEntry = some(compiler.psErasureLookupStructure(
      scopeValue.runtimeStructureConstructors, name(constructor)), 'STRUCTURE_CONSTRUCTOR_' + text);
    same(typeEntry, constructorEntry, 'STRUCTURE_INDEX_AGREEMENT_' + text);
    return plain(typeEntry);
  };
  // Expected metadata is compared as plain observations, never passed as input
  // to a compiler operation. Do not assume runtime structure constructors.
  const expectedRuntimeRecord = (text, core, constructor, field, type) => ({
    name: text, coreName: name(core), constructorName: name(constructor), numParams: 0n,
    typeParameters: nil,
    fields: list([{ sourceIndex: 0n, projectionIndex: 0n, name: field, type }]),
  });
  const runtimeRecordA = expectedRuntimeRecord(
    'record_A', 'F2RecordA', 'F2RecordA.mk', 'value', natIr);
  const runtimeRecordB = expectedRuntimeRecord(
    'record_B', 'F2RecordB', 'F2RecordB.mk', 'prior', namedIr('record_A'));
  const structuresView = (value) => {
    const records = [
      runtimeStructureView(value, 'F2RecordA', 'F2RecordA.mk'),
      runtimeStructureView(value, 'F2RecordB', 'F2RecordB.mk'),
    ];
    assert.deepEqual(records, [plain(runtimeRecordA), plain(runtimeRecordB)], fail('STRUCTURE_SCOPE_ENTRIES'));
    return records;
  };
  observe('structures-empty-reverse-accumulator', () => {
    const result = ok(compiler.psPrepareRuntimeStructures(
      metadata.environment, completeDeclarations, nil, seededScope,
      list([keptRecordB, keptRecordA])), 'STRUCTURES_EMPTY');
    same(result.scope, seededScope, 'STRUCTURES_EMPTY_SCOPE');
    same(result.ir, list([keptRecordA, keptRecordB]), 'STRUCTURES_EMPTY_REVERSE');
    return { ir: plain(result.ir), scope: plain(result.scope) };
  });
  observe('structures-mixed-stream', () => {
    const result = ok(compiler.psPrepareRuntimeStructures(
      metadata.environment, completeDeclarations,
      list([choiceA, recordA, recordConstructor, proofDeclaration, recordB, choiceB, choiceRecursor]),
      seededScope, list([keptRecordA])), 'STRUCTURES_MIXED');
    same(result.ir, list([keptRecordA, irRecordA, irRecordB]), 'STRUCTURES_MIXED_ORDER');
    expectScopeBase(result.scope, seededScope,
      ['runtimeConstructors', 'runtimeRecursors'], 'STRUCTURES_MIXED');
    return { ir: plain(result.ir), runtimeStructures: structuresView(result.scope) };
  });
  observe('structures-threaded-scope', () => {
    const prepared = ok(compiler.psPrepareRuntimeStructure(
      metadata.environment, completeDeclarations, seededScope, recordA.info), 'STRUCTURE_PREFIX');
    const result = ok(compiler.psPrepareRuntimeStructures(
      metadata.environment, completeDeclarations, list([recordB]), prepared.scope,
      list([keptRecordB, keptRecordA])), 'STRUCTURES_THREADED');
    same(result.ir, list([keptRecordA, keptRecordB, irRecordB]), 'STRUCTURES_THREADED_ORDER');
    expectScopeBase(result.scope, prepared.scope,
      ['runtimeConstructors', 'runtimeRecursors'], 'STRUCTURES_THREADED');
    return { ir: plain(result.ir), runtimeStructures: structuresView(result.scope) };
  });
  observe('structures-first-refusal', () => namedError(compiler.psPrepareRuntimeStructures(
    metadata.environment, completeDeclarations, list([
      choiceA,
      badInfo(recordA, 'F2RecordA.missingFirst'),
      badInfo(recordB, 'F2RecordB.missingSecond'),
    ]), seededScope, list([keptRecordA])),
  'unknownConstant', 'F2RecordA.missingFirst', 'STRUCTURES_FIRST_REFUSAL'));

  const firstConstructor = {
    inductiveName: 'choice_A', name: 'first', coreName: name('F2ChoiceA.first'),
    numParams: 0n, fields: nil,
  };
  const secondConstructor = {
    inductiveName: 'choice_A', name: 'second', coreName: name('F2ChoiceA.second'),
    numParams: 0n, fields: nil,
  };
  const wrapConstructor = {
    inductiveName: 'choice_B', name: 'wrap', coreName: name('F2ChoiceB.wrap'),
    numParams: 0n,
    fields: list([{ sourceIndex: 0n, name: 'prior', type: namedIr('choice_A'), recursive: false }]),
  };
  const runtimeChoiceA = {
    name: 'choice_A', coreName: name('F2ChoiceA'), recursorName: name('F2ChoiceA.rec'),
    numParams: 0n, typeParameters: nil, constructors: list([firstConstructor, secondConstructor]),
  };
  const runtimeChoiceB = {
    name: 'choice_B', coreName: name('F2ChoiceB'), recursorName: name('F2ChoiceB.rec'),
    numParams: 0n, typeParameters: nil, constructors: list([wrapConstructor]),
  };
  const inductivesView = (value) => {
    const recursors = ['F2ChoiceA.rec', 'F2ChoiceB.rec'].map((text) =>
      plain(some(compiler.psErasureLookupRecursor(value.runtimeRecursors, name(text)),
        'RECURSOR_' + text)));
    assert.deepEqual(recursors, [plain(runtimeChoiceA), plain(runtimeChoiceB)],
      fail('INDUCTIVE_RECURSOR_ENTRIES'));
    const constructors = ['F2ChoiceA.first', 'F2ChoiceA.second', 'F2ChoiceB.wrap'].map((text) =>
      plain(some(compiler.psErasureLookupConstructor(value.runtimeConstructors, name(text)),
        'CONSTRUCTOR_' + text)));
    assert.deepEqual(constructors,
      [plain(firstConstructor), plain(secondConstructor), plain(wrapConstructor)],
    fail('INDUCTIVE_CONSTRUCTOR_ENTRIES'));
    same(compiler.psErasureLookupRecursor(value.runtimeRecursors, name('Nat.rec')),
      compiler.psErasureLookupRecursor(seededScope.runtimeRecursors, name('Nat.rec')),
      'INDUCTIVE_EXISTING_NAT_RECURSOR');
    return { recursors, constructors };
  };
  observe('inductives-empty-reverse-accumulator', () => {
    const result = ok(compiler.psPrepareRuntimeInductives(
      metadata.environment, completeDeclarations, nil, seededScope,
      list([keptChoiceB, keptChoiceA])), 'INDUCTIVES_EMPTY');
    same(result.scope, seededScope, 'INDUCTIVES_EMPTY_SCOPE');
    same(result.ir, list([keptChoiceA, keptChoiceB]), 'INDUCTIVES_EMPTY_REVERSE');
    return { ir: plain(result.ir), scope: plain(result.scope) };
  });
  observe('inductives-mixed-stream', () => {
    const result = ok(compiler.psPrepareRuntimeInductives(
      metadata.environment, completeDeclarations,
      list([recordA, choiceA, recordConstructor, proofDeclaration, choiceB, recordB, choiceRecursor]),
      seededScope, list([keptChoiceA])), 'INDUCTIVES_MIXED');
    same(result.ir, list([keptChoiceA, irChoiceA, irChoiceB]), 'INDUCTIVES_MIXED_ORDER');
    expectScopeBase(result.scope, seededScope,
      ['runtimeStructures', 'runtimeStructureConstructors'], 'INDUCTIVES_MIXED');
    return { ir: plain(result.ir), runtime: inductivesView(result.scope) };
  });
  observe('inductives-threaded-scope', () => {
    const prepared = ok(compiler.psPrepareRuntimeInductive(
      metadata.environment, completeDeclarations, seededScope, choiceA.info), 'INDUCTIVE_PREFIX');
    const result = ok(compiler.psPrepareRuntimeInductives(
      metadata.environment, completeDeclarations, list([choiceB]), prepared.scope,
      list([keptChoiceB, keptChoiceA])), 'INDUCTIVES_THREADED');
    same(result.ir, list([keptChoiceA, keptChoiceB, irChoiceB]), 'INDUCTIVES_THREADED_ORDER');
    expectScopeBase(result.scope, prepared.scope,
      ['runtimeStructures', 'runtimeStructureConstructors'], 'INDUCTIVES_THREADED');
    return { ir: plain(result.ir), runtime: inductivesView(result.scope) };
  });
  observe('inductives-first-refusal', () => namedError(compiler.psPrepareRuntimeInductives(
    metadata.environment, completeDeclarations, list([
      recordA,
      badInfo(choiceA, 'F2ChoiceA.missingFirst'),
      badInfo(choiceB, 'F2ChoiceB.missingSecond'),
    ]), seededScope, list([keptChoiceA])),
  'unknownConstant', 'F2ChoiceA.missingFirst', 'INDUCTIVES_FIRST_REFUSAL'));

  const symbolState = (used, index, entries) => ({
    used: list(used),
    nextIndex: BigInt(index),
    entriesRev: list(entries.map(([key, value]) => compiler.psIrCheckMakePair(key, value))),
  });
  const pairStrings = (value) => array(value).map((entry) => [entry.fst, entry.snd]);
  const symbolStateView = (state) => ({
    used: array(state.used),
    nextIndex: state.nextIndex.toString(),
    entriesRev: pairStrings(state.entriesRev),
  });
  observe('symbols-empty-state', () => {
    const result = compiler.psTsBuildSymbolMap('p', nil,
      symbolState(['usedBefore'], 3, [['before', 'usedBefore']]));
    const view = symbolStateView(result);
    assert.deepEqual(view, {
      used: ['usedBefore'], nextIndex: '3', entriesRev: [['before', 'usedBefore']],
    }, fail('SYMBOLS_EMPTY'));
    return view;
  });
  observe('symbols-collision-and-index', () => {
    const result = compiler.psTsBuildSymbolMap('p', list(['alpha', 'beta']),
      symbolState(['p3', 'p5'], 3, [['prior', 'p3']]));
    const view = symbolStateView(result);
    assert.deepEqual(view, {
      used: ['p6', 'p4', 'p3', 'p5'], nextIndex: '7',
      entriesRev: [['beta', 'p6'], ['alpha', 'p4'], ['prior', 'p3']],
    }, fail('SYMBOLS_COLLISION'));
    return view;
  });
  observe('symbols-duplicate-source-names', () => {
    const result = compiler.psTsBuildSymbolMap('p', list(['duplicate', 'duplicate']),
      symbolState([], 0, []));
    const view = symbolStateView(result);
    assert.deepEqual(view, {
      used: ['p1', 'p0'], nextIndex: '2',
      entriesRev: [['duplicate', 'p1'], ['duplicate', 'p0']],
    }, fail('SYMBOLS_DUPLICATE'));
    return view;
  });
  observe('symbols-brand-wrapper', () => {
    const module = compiler.psIrCheckMakeModule(
      nil, list([keptRecordA, keptRecordB]), nil,
      list([irDefinition('__ps$brand$0', 0)]));
    const result = pairStrings(compiler.psTsBuildBrandMap(module));
    assert.deepEqual(result, [
      ['keptRecordA', '__ps$brand$1'], ['keptRecordB', '__ps$brand$2'],
    ], fail('SYMBOLS_BRAND_WRAPPER'));
    return result;
  });
  observe('symbols-tag-wrapper', () => {
    const module = compiler.psIrCheckMakeModule(
      nil, nil, list([keptChoiceA, keptChoiceB]),
      list([irDefinition('__ps$tag$0', 0)]));
    const result = pairStrings(compiler.psTsBuildTagMap(module));
    assert.deepEqual(result, [
      ['keptChoiceA', '__ps$tag$1'], ['keptChoiceB', '__ps$tag$2'],
    ], fail('SYMBOLS_TAG_WRAPPER'));
    return result;
  });

  assert.deepEqual(observations.map((item) => item.name), f2CaseNames, fail('CASE_COVERAGE'));
  assert.equal(observations.length, 36, fail('CASE_COUNT'));
  return {
    family: 'F2', cases: observations.length, observations,
    observationSha256: sha256(JSON.stringify(observations)),
  };
}

// The single-runtime entry point is suitable for an existing qualification pass.
// The separate ABI gate receives its already prepared declarations and exact IR.
export function runMigrationWorkerConformance(compiler, valueTag) {
  assert.equal(typeof valueTag, 'function', 'PSC0_SH1_MIGRATION_TAG_READER');
  assertMigrationRequiredExports(compiler, migrationRequiredExports, 'F1_F2');
  const f1 = runSh1FreshNameCases(compiler);
  const f2 = runF2Cases(compiler, valueTag);
  assert.equal(f1.workerCases, 44, 'PSC0_SH1_MIGRATION_F1_WORKER_COUNT');
  assert.equal(f1.wrapperCases, 7, 'PSC0_SH1_MIGRATION_F1_WRAPPER_COUNT');
  assert.equal(f1.observations.length + f2.observations.length, 87,
    'PSC0_SH1_MIGRATION_CASE_COUNT');
  const observations = { F1: f1.observations, F2: f2.observations };
  return {
    schemaVersion: 1,
    evidence: 'finite-migration-worker-generated-export-conformance',
    cases: 87,
    families: [f1, f2],
    observationSha256: sha256(JSON.stringify(observations)),
    scope: {
      eachCompilerOwnsAllTaggedInputs: true,
      irRecordsUseExistingCompilerFactories: true,
      copiedRecordsRetainOwningCompilerBrands: true,
      hostStructuralFixtureRecords: [
        'PsErasureNameState', 'PsTsSymbolMapState', 'PsErasureCurrentDefinition',
      ],
      hostStructuralFixtureBoundary:
        'Explicit unbranded non-IR host records with owning-compiler tagged children; ' +
        'their exercised paths project fields or reset the marker, and do not inspect brands. ' +
        'They are not compiler-created branded records and never enter original-IR carrier checking.',
      independentExplicitExpectations: true,
      saturatedPublicArgumentOrderChecked: true,
      completePublicTypes: 'separate migration ABI gate',
      pscPartialApplications: 'separate typed migration ABI probes',
      performanceImprovementClaimed: false,
      exhaustiveForAllInputs: false,
      kernelChecked: false,
    },
  };
}

// Compare the legacy erasure-scope observations across the T1 record extension.
// Raw reports stay unchanged. Only these two named fixture paths may lose the
// newly added empty namespace in the comparison view; every other field remains.
export function compareMigrationWorkerReportObservations(reference, current,
  label = 'PSC0_SH1_MIGRATION_BEHAVIOR_CORRESPONDENCE') {
  const scopeCases = [
    'structures-empty-reverse-accumulator',
    'inductives-empty-reverse-accumulator',
  ];
  const view = (report, requireRuntimePrefix) => {
    assert.equal(report.schemaVersion, 1, label + '_REPORT_SCHEMA');
    assert.equal(report.evidence, 'finite-migration-worker-generated-export-conformance',
      label + '_REPORT_KIND');
    assert.equal(report.cases, 87, label + '_CASE_COUNT');
    assert.deepEqual(report.families.map((family) => family.family), ['F1', 'F2'],
      label + '_FAMILIES');
    const [f1, f2] = report.families;
    assert.equal(f1.workerCases, 44, label + '_F1_WORKERS');
    assert.equal(f1.wrapperCases, 7, label + '_F1_WRAPPERS');
    assert.equal(f1.observations.length, 51, label + '_F1_CASES');
    assert.equal(f2.cases, 36, label + '_F2_CASES');
    assert.deepEqual(f2.observations.map((item) => item.name), f2CaseNames,
      label + '_F2_COVERAGE');
    for (const family of report.families) {
      assert.equal(family.observationSha256, sha256(JSON.stringify(family.observations)),
        label + '_RAW_FAMILY_HASH');
    }
    assert.equal(report.observationSha256,
      sha256(JSON.stringify({ F1: f1.observations, F2: f2.observations })),
      label + '_RAW_REPORT_HASH');
    const prefixPresence = [];
    const observations = f2.observations.map((item) => {
      if (!scopeCases.includes(item.name)) return item;
      const scope = item.result.scope;
      const names = scope.declarationNames;
      const hasPrefix = Object.hasOwn(names, 'runtimePrefix');
      prefixPresence.push(hasPrefix);
      if (requireRuntimePrefix) assert(hasPrefix, label + '_CURRENT_RUNTIME_PREFIX_MISSING');
      if (hasPrefix) assert.equal(names.runtimePrefix, '', label + '_NONEMPTY_RUNTIME_PREFIX');
      assert.deepEqual(Object.keys(names).sort(),
        hasPrefix ? ['byCore', 'byOutput', 'count', 'runtimePrefix'] : ['byCore', 'byOutput', 'count'],
        label + '_DECLARATION_NAMES_FIELDS');
      const declarationNames = { ...names };
      delete declarationNames.runtimePrefix;
      return { ...item, result: { ...item.result, scope: { ...scope, declarationNames } } };
    });
    assert.equal(prefixPresence.length, scopeCases.length, label + '_SCOPE_CASES');
    assert.equal(prefixPresence[0], prefixPresence[1], label + '_REFERENCE_RECORD_SHAPE');
    const families = [
      f1, { ...f2, observations, observationSha256: sha256(JSON.stringify(observations)) },
    ];
    return {
      report: { ...report, families,
        observationSha256: sha256(JSON.stringify({ F1: f1.observations, F2: observations })) },
      runtimePrefixPresent: prefixPresence[0],
    };
  };
  const before = view(reference, false);
  const after = view(current, true);
  assert.deepEqual(after.report, before.report, label);
  return {
    profile: 'empty-legacy-erasure-namespace/1',
    cases: 87,
    projectedPaths: scopeCases.map((name) =>
      'F2/' + name + '/result/scope/declarationNames/runtimePrefix'),
    runtimePrefix: '',
    referenceRuntimePrefixPresent: before.runtimePrefixPresent,
    referenceObservationSha256: reference.observationSha256,
    currentObservationSha256: current.observationSha256,
    comparisonObservationSha256: after.report.observationSha256,
  };
}

// R and F must already be authenticated and loaded by the caller. The reports
// compared here contain no values owned by either generated compiler.
export function compareMigrationWorkerConformance({
  before, after, beforeCompilerSha256, afterCompilerSha256, valueTag,
}) {
  assert.notEqual(before, after, 'PSC0_SH1_MIGRATION_DISTINCT_COMPILERS');
  for (const [label, hash] of Object.entries({ beforeCompilerSha256, afterCompilerSha256 })) {
    assert.match(hash, /^[a-f0-9]{64}$/u, 'PSC0_SH1_MIGRATION_' + label);
  }
  const beforeReport = runMigrationWorkerConformance(before, valueTag);
  const afterReport = runMigrationWorkerConformance(after, valueTag);
  assert.deepEqual(afterReport, beforeReport, 'PSC0_SH1_MIGRATION_BEHAVIOR_CORRESPONDENCE');
  return {
    schemaVersion: 1,
    evidence: 'finite-migration-worker-R-F-correspondence',
    beforeCompilerSha256, afterCompilerSha256,
    casesPerCompiler: beforeReport.cases,
    observationSha256: beforeReport.observationSha256,
    report: beforeReport,
    passed: true,
  };
}
