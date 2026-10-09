import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { inventoryOriginalIr } from './original-ir-inventory.mjs';
import { loadGeneratedCompiler, stripBootstrapImports } from './sh1-source-snapshot.mjs';
import { compileTypeScript, sha256, unwrap, valueTag } from './sh1-capabilities.mjs';

function fixtureModel(c) {
  const list = (values) => values.reduceRight((tail, head) => c.List.cons(head, tail), c.List.nil());
  const pair = (first, second) => c.psIrCheckMakePair(first, second);
  const T = c.PsVerifiedIrType, E = c.PsVerifiedIrExpr, L = c.PsVerifiedIrLiteral;
  const primitive = (name) => T.primitive(c.PsVerifiedIrPrimitiveType[name]);
  const nat = primitive('nat'), int = primitive('int'), bool = primitive('bool');
  const string = primitive('string'), char = primitive('char'), unit = primitive('unit');
  const named = (name, types = []) => T.named(name, list(types));
  const functionType = (parameters, result) => T.function(list(parameters), result);
  const fnNat = functionType([nat], nat);
  const variable = (name) => E.var(name);
  const natural = (value) => E.literal(L.natural(BigInt(value)));
  const text = (value) => E.literal(L.string(value));
  const truth = (value) => E.literal(L.bool(value));
  const intrinsic = (name, arguments_, types = []) => E.intrinsic(c.PsVerifiedIrIntrinsic[name], list(types), list(arguments_));
  const call = (fn, arguments_, types = []) => E.call(typeof fn === 'string' ? variable(fn) : fn, list(types), list(arguments_));
  const parameter = (name, type) => c.psIrCheckMakeParameter(name, type);
  const parameters = (values) => list(values.map(([name, type]) => parameter(name, type)));
  const typeParameters = (names) => list(names.map((name) => c.psIrCheckMakeTypeParameter(name)));
  const lambda = (params, result, body) => E.lambda(parameters(params), result, body);
  const fields = (values) => list(values.map(([name, body]) => pair(name, body)));
  const record = (name, values, types = []) => E.record(name, list(types), fields(values));
  const constructor = (name, ctor, values, types = []) => E.constructor(name, ctor, list(types), fields(values));
  const projection = (name, target, field, types = []) => E.projection(name, list(types), target, field);
  const binding = (field, name, type) => c.psIrCheckMakeMatchBinding(field, name, type);
  const alternative = (name, bindings, body) => pair(name, pair(list(bindings), body));
  const declaration = (name, result, body, params = [], types = []) =>
    c.psIrCheckMakeDeclaration(name, typeParameters(types), parameters(params), result, body);
  const structure = (name, members, types = []) => c.psIrCheckMakeStructure(name, typeParameters(types),
    list(members.map(([field, type]) => c.psIrCheckMakeStructureField(field, type))));
  const inductive = (name, ctors, types = []) => c.psIrCheckMakeInductive(name, typeParameters(types),
    list(ctors.map(([ctor, members]) => c.psIrCheckMakeConstructor(ctor,
      list(members.map(([field, type]) => c.psIrCheckMakeConstructorField(field, type)))))));
  const layouts = [
    structure('Holder', [['apply', fnNat]]),
    structure('Box', [['value', T.typeParameter('T0')]], ['T0']),
  ];
  const choices = [
    inductive('Choice', [['first', [['apply', fnNat]]], ['second', [['apply', fnNat]]]]),
    inductive('TwoFields', [['pair', [['left', nat], ['right', nat]]]]),
  ];
  const module = (declarations, structures = layouts, inductives = choices, imports = []) =>
    c.psIrCheckMakeModule(list(imports), list(structures), list(inductives), list(declarations));
  const plusOne = lambda([['x', nat]], nat, intrinsic('natAdd', [variable('x'), natural(1)]));
  const nested = lambda([['first', nat]], fnNat,
    lambda([['second', nat]], nat, intrinsic('natAdd', [variable('first'), variable('second')])));
  const T0 = T.typeParameter('T0'), T1 = T.typeParameter('T1');
  const base = [
    declaration('functionValue', fnNat, plusOne),
    declaration('numberValue', nat, natural(7)),
    declaration('returnFunction', fnNat,
      lambda([['right', nat]], nat, intrinsic('natAdd', [variable('left'), variable('right')])),
      [['left', nat]]),
    declaration('nestedFunction', functionType([nat], fnNat), nested),
    declaration('chooseSecond', T1, variable('second'), [['first', T0], ['second', T1]], ['T0', 'T1']),
    declaration('swapCaller', T0,
      call('chooseSecond', [variable('second'), variable('first')], [T1, T0]),
      [['first', T0], ['second', T1]], ['T0', 'T1']),
    declaration('mapBox', named('Box', [T1]),
      record('Box', [['value', call(variable('convert'),
        [projection('Box', variable('box'), 'value', [T0])])]], [T1]),
      [['convert', functionType([T0], T1)], ['box', named('Box', [T0])]], ['T0', 'T1']),
  ];
  const choiceValue = constructor('Choice', 'first', [['apply', variable('functionValue')]]);
  const alternatives = [
    alternative('first', [binding('apply', 'selected', fnNat)], variable('selected')),
    alternative('second', [binding('apply', 'selected', fnNat)], variable('selected')),
  ];
  const match = (alts = alternatives) => E.matchE('Choice', list([]), choiceValue, list(alts));
  const array = intrinsic('arrayPush', [
    intrinsic('arrayEmptyWithCapacity', [natural(1)], [nat]), natural(7),
  ], [nat]);
  const positive = module([...base,
    declaration('fromLet', nat, call(E.letE('callee', fnNat, plusOne, variable('callee')), [natural(5)])),
    declaration('fromIf', nat, call(E.ifE(truth(true), variable('functionValue'), plusOne), [natural(5)])),
    declaration('fromMatch', nat, call(match(), [natural(5)])),
    declaration('fromProjection', nat,
      call(projection('Holder', record('Holder', [['apply', plusOne]]), 'apply'), [natural(5)])),
    declaration('fromReturnedCall', nat, call(call('returnFunction', [natural(4)]), [natural(5)])),
    declaration('fromGlobalFunction', nat, call('functionValue', [natural(5)])),
    declaration('fromGlobalLiteral', nat, variable('numberValue')),
    declaration('fromZeroLambda', nat, call(lambda([], nat, natural(42)), [])),
    declaration('shadowOldScope', nat, E.letE('value', nat,
      intrinsic('natAdd', [variable('value'), natural(1)]), variable('value')), [['value', nat]]),
    declaration('fromSwap', nat, call('swapCaller', [natural(42), text('swap')], [nat, string])),
    declaration('fromNestedGeneric', string, projection('Box',
      call('mapBox', [lambda([['value', nat]], string, text('mapped')),
        record('Box', [['value', natural(7)]], [nat])], [nat, string]), 'value', [string])),
    declaration('mutualEven', bool, E.ifE(intrinsic('natEq', [variable('fuel'), natural(0)]),
      truth(true), call('mutualOdd', [intrinsic('natSub', [variable('fuel'), natural(1)])])), [['fuel', nat]]),
    declaration('mutualOdd', bool, E.ifE(intrinsic('natEq', [variable('fuel'), natural(0)]),
      truth(false), call('mutualEven', [intrinsic('natSub', [variable('fuel'), natural(1)])])), [['fuel', nat]]),
    declaration('fromArray', nat, intrinsic('arrayGetD', [array, natural(0), natural(99)], [nat])),
    declaration('fromArrayFold', nat, intrinsic('arrayFoldl', [
      lambda([['accumulator', nat], ['element', nat]], nat,
        intrinsic('natAdd', [variable('accumulator'), variable('element')])),
      natural(0), array, natural(0), natural(1),
    ], [nat, nat])),
    declaration('fromInteger', int, intrinsic('intAdd', [
      E.literal(L.integer(-2n)), intrinsic('intOfNat', [natural(7)]),
    ])),
    declaration('fromCharacter', string, intrinsic('stringPush', [
      text('x'), intrinsic('charOfNat', [natural(65)]),
    ])),
  ]);
  const single = (body, result = nat, params = [], types = []) =>
    module([...base, declaration('rejectedResult', result, body, params, types)]);
  const negative = [
    ['false-let-annotation', single(E.letE('value', nat, truth(true), variable('value'))), 'type-mismatch'],
    ['false-lambda-result', single(call(lambda([['x', nat]], nat, truth(true)), [natural(1)])), 'type-mismatch'],
    ['false-declaration-result', single(text('wrong')), 'type-mismatch'],
    ['incompatible-if-branches', single(E.ifE(truth(true), natural(1), truth(false))), 'type-mismatch'],
    ['non-boolean-condition', single(E.ifE(natural(1), natural(1), natural(2))), 'type-mismatch'],
    ['flattened-function-grouping', single(call(variable('nestedFunction'), [natural(1), natural(2)])), 'call-runtime-arity'],
    ['false-function-group-annotation', single(E.letE('value', functionType([nat, nat], nat),
      nested, natural(0))), 'type-mismatch'],
    ['global-literal-is-not-zero-argument-function', single(call('numberValue', [])), 'non-function-callee'],
    ['generic-arguments-missing', single(call('chooseSecond', [natural(1), natural(2)])), 'call-type-arity'],
    ['monomorphic-value-with-type-arguments', single(call('functionValue', [natural(1)], [nat])), 'call-type-arity'],
    ['generic-scheme-escape', single(variable('chooseSecond'), functionType([nat, nat], nat)), 'generic-value-reference'],
    ['zero-runtime-generic-value', single(lambda([['value', T0]], T0, variable('value')),
      functionType([T0], T0), [], ['T0']), 'generic-value-unsupported'],
    ['unknown-runtime-type', single(natural(1), T.unknown), 'unknown-type'],
    ['unscoped-type-parameter', single(natural(1), T.typeParameter('Missing')), 'unbound-type-parameter'],
    ['named-type-arity', single(natural(1), nat, [['unused', named('Box')]]), 'named-type-arity'],
    ['unresolved-variable', single(variable('missing')), 'unresolved-value-name'],
    ['duplicate-runtime-binder', single(variable('x'), nat, [['x', nat], ['x', nat]]), 'duplicate-binder'],
    ['duplicate-type-binder', single(variable('x'), T0, [['x', T0]], ['T0', 'T0']), 'duplicate-type-parameter'],
    ['duplicate-global-name', module([...base, declaration('numberValue', nat, natural(2))]), 'duplicate-value-name'],
    ['Nat-and-Int-are-distinct', single(intrinsic('natAdd', [E.literal(L.integer(1n)), natural(2)])), 'type-mismatch'],
    ['Char-and-String-are-distinct', single(intrinsic('stringPush', [text('x'), text('y')]), string), 'type-mismatch'],
    ['intrinsic-type-arity', single(intrinsic('natAdd', [natural(1), natural(2)], [nat])), 'intrinsic-type-arity'],
    ['constructor-positional-field-order', single(constructor('TwoFields', 'pair',
      [['right', natural(1)], ['left', natural(2)]]), named('TwoFields')), 'constructor-field-order'],
    ['record-missing-field', single(record('Holder', []), named('Holder')), 'missing-field'],
    ['record-duplicate-field', single(record('Holder', [['apply', plusOne], ['apply', plusOne]]), named('Holder')), 'duplicate-field'],
    ['record-extra-field', single(record('Holder', [['apply', plusOne], ['extra', natural(1)]]), named('Holder')), 'unexpected-field'],
    ['projection-owner-mismatch', single(projection('Holder',
      record('Box', [['value', natural(1)]], [nat]), 'apply'), fnNat), 'type-mismatch'],
    ['projection-instantiation-mismatch', single(projection('Box',
      record('Box', [['value', text('wrong')]], [string]), 'value', [nat])), 'type-mismatch'],
    ['match-binding-type-mismatch', single(call(match([
      alternative('first', [binding('apply', 'selected', nat)], variable('selected')),
      alternatives[1],
    ]), [natural(1)])), 'type-mismatch'],
    ['match-missing-alternative', single(call(match([alternatives[0]]), [natural(1)])), 'match-coverage'],
    ['match-duplicate-alternative', single(call(match([...alternatives, alternatives[0]]), [natural(1)])), 'duplicate-match-alternative'],
    ['optional-scalar-capability', single(variable('value'), primitive('uint32'),
      [['value', primitive('uint32')]]), 'scalar-capability-unqualified'],
    ['external-import-ABI', module([declaration('importedUse', nat, variable('external'))], [], [],
      [c.psIrCheckMakeExternalImport('external', 'unqualified-module', 'external', nat)]), 'external-import-abi-unqualified'],
    ['empty-layout', module([], [], [inductive('Empty', [])]), 'empty-layout-unsupported'],
    ['empty-match', module([declaration('eliminate', nat,
      E.matchE('Empty', list([]), variable('empty'), list([])), [['empty', named('Empty')]])],
      [], [inductive('Empty', [])]), 'empty-match-unsupported'],
    ['runtime-layout-name-collision', module([], [structure('Array', [])], []), 'duplicate-layout-name'],
  ];
  return { positive, negative, single, natural, E, L, nat, list, module, declaration };
}

function assertBehavior(runtime) {
  let observations = 0;
  for (const name of ['fromLet', 'fromIf', 'fromMatch', 'fromProjection', 'fromGlobalFunction']) {
    assert.equal(runtime[name], 6n, 'PSC0_SH1_IR_RUNTIME: ' + name); observations++;
  }
  for (const [name, expected] of [
    ['fromReturnedCall', 9n], ['fromGlobalLiteral', 7n], ['fromZeroLambda', 42n],
    ['fromSwap', 42n], ['fromNestedGeneric', 'mapped'], ['fromArray', 7n],
    ['fromArrayFold', 7n], ['fromInteger', 5n], ['fromCharacter', 'xA'],
  ]) { assert.equal(runtime[name], expected, 'PSC0_SH1_IR_RUNTIME: ' + name); observations++; }
  for (let input = 0n; input < 8n; input++) {
    assert.equal(runtime.shadowOldScope(input), input + 1n, 'PSC0_SH1_IR_SHADOW_SCOPE');
    assert.equal(runtime.mutualEven(input), input % 2n === 0n, 'PSC0_SH1_IR_MUTUAL_EVEN');
    assert.equal(runtime.mutualOdd(input), input % 2n === 1n, 'PSC0_SH1_IR_MUTUAL_ODD');
    observations += 3;
  }
  return { status: 'pass', observations, exhaustiveForAllInputs: false };
}

function assertRejected(report, label, code) {
  assert.equal(report.runtimeIrTypingAccepted, false, 'PSC0_SH1_IR_REJECT: ' + label);
  assert(report.findingCount > 0, 'PSC0_SH1_IR_REJECT_FINDING: ' + label);
  if (code) assert(Object.hasOwn(report.findingCounts, code),
    'PSC0_SH1_IR_REJECT_CODE: ' + label + ': ' + JSON.stringify(report.findingCounts));
}

export async function runIrCheckerConformance({
  compiler, compilerSha256, compilerPath, root, outDir, tsc,
}) {
  for (const name of ['psCheckVerifiedIrModule', 'psIrCheckOptionsWithLimits',
    'psIrCheckMakeModule', 'psIrCheckMakePair', 'psTsEmitCheckedModule',
    'psCompilerCheckedTypeScriptFromPrepared']) {
    assert.equal(typeof compiler[name], 'function', 'PSC0_SH1_IR_EXPORT: ' + name);
  }
  const fixture = fixtureModel(compiler);
  const positive = inventoryOriginalIr(compiler, fixture.positive, { compilerSha256 });
  assert.equal(positive.runtimeIrTypingAccepted, true,
    'PSC0_SH1_IR_POSITIVE: ' + JSON.stringify(positive.findings));
  assert.equal(positive.traversalComplete, true, 'PSC0_SH1_IR_POSITIVE_COMPLETE');
  const typeScript = unwrap(compiler.psTsEmitCheckedModule(compiler.psIrCheckDefaultOptions, fixture.positive),
    'IR_CHECKED_EMIT');
  assert.equal(typeScript, unwrap(compiler.psTsEmitModule(fixture.positive), 'IR_RAW_EMIT_PARITY'));
  const generated = await compileTypeScript(typeScript, path.join(outDir, 'accepted'), tsc, root);
  const behavior = assertBehavior(await import(pathToFileURL(generated).href));
  const rejected = [];
  for (const [name, ir, code] of fixture.negative) {
    const report = inventoryOriginalIr(compiler, ir, { compilerSha256 });
    assertRejected(report, name, code);
    const emission = compiler.psTsEmitCheckedModule(compiler.psIrCheckDefaultOptions, ir);
    assert.equal(valueTag(emission), 'error', 'PSC0_SH1_IR_REJECTED_EMISSION: ' + name);
    assert.equal(valueTag(emission.error), 'check', 'PSC0_SH1_IR_REJECTED_BEFORE_EMITTER: ' + name);
    assert.equal(emission.error.report.accepted, false, 'PSC0_SH1_IR_EMITTER_REJECTION_REPORT');
    rejected.push({ name, expectedCode: code, findingCount: report.findingCount,
      findingCounts: report.findingCounts, traversalComplete: report.traversalComplete,
      checkedEmitter: 'rejected-before-emission' });
  }
  const exhausted = [];
  for (const [name, limits, code] of [
    ['input-preflight-budget', { maxSteps: 0 }, 'checker-input-resource-limit'],
    ['type-work-budget', { maxTypeSteps: 0 }, 'type-resource-limit'],
  ]) {
    const report = inventoryOriginalIr(compiler, fixture.positive, { compilerSha256, ...limits });
    assertRejected(report, name, code);
    assert.equal(report.traversalComplete, false, 'PSC0_SH1_IR_EXHAUSTED_TRAVERSAL');
    exhausted.push({ name, findingCounts: report.findingCounts, traversalComplete: false });
  }
  const firstType = compiler.PsVerifiedIrType.typeParameter('T0');
  const secondType = compiler.PsVerifiedIrType.typeParameter('T1');
  const substitutions = fixture.list([
    compiler.psIrCheckMakePair('T0', secondType), compiler.psIrCheckMakePair('T1', firstType),
  ]);
  const substitutionInput = compiler.PsVerifiedIrType.function(fixture.list([firstType]),
    compiler.PsVerifiedIrType.named('Box', fixture.list([secondType])));
  const substituted = unwrap(compiler.psIrCheckSubstitute(
    compiler.psIrCheckDefaultOptions.maxTypeSteps, substitutions, substitutionInput), 'IR_SIMULTANEOUS_SUBSTITUTION');
  assert.equal(valueTag(substituted), 'function');
  assert.equal(substituted.parameters.head.name, 'T1');
  assert.equal(valueTag(substituted.result), 'named');
  assert.equal(substituted.result.name, 'Box');
  assert.equal(substituted.result.arguments.head.name, 'T0');
  const directTypeOperations = [{ name: 'simultaneous-nested-generic-swap', status: 'pass' }];
  for (const [name, result] of [
    ['substitution', compiler.psIrCheckSubstitute(0n, substitutions, substitutionInput)],
    ['equality', compiler.psIrCheckTypeEqual(0n, fixture.nat, fixture.nat)],
  ]) {
    assert.equal(valueTag(result), 'error', 'PSC0_SH1_IR_DIRECT_TYPE_EXHAUSTION: ' + name);
    assert.equal(result.error.code, 'type-resource-limit');
    assert.equal(result.error.detail, name);
    directTypeOperations.push({ name: name + '-budget', code: result.error.code, detail: result.error.detail });
  }
  const capped = inventoryOriginalIr(compiler, fixture.negative[0][1], { compilerSha256, maxFindings: 0 });
  assertRejected(capped, 'diagnostic-detail-cap');
  assert.equal(capped.findings.length, 0);
  assert.equal(capped.omittedFindingDetails, capped.findingCount);
  const malformed = [
    ['negative-natural-carrier', fixture.single(fixture.E.literal(fixture.L.natural(-1n))), 'invalid-ir-scalar-carrier'],
    ['number-natural-carrier', fixture.single(fixture.E.literal(fixture.L.natural(1))), 'invalid-ir-scalar-carrier'],
    ['string-boolean-carrier', fixture.single(fixture.E.literal(fixture.L.bool('true'))), 'invalid-ir-scalar-carrier'],
  ];
  const cyclic = compiler.List.cons(fixture.natural(1), compiler.List.nil());
  cyclic.tail = cyclic;
  malformed.push(['cyclic-list-carrier', fixture.single(
    fixture.E.call(fixture.E.var('functionValue'), compiler.List.nil(), cyclic)), 'cyclic-ir-carrier']);
  const foreign = await loadGeneratedCompiler(compilerPath, { expectedSha256: compilerSha256 });
  malformed.push(['foreign-compiler-brand', foreign.compiler.psVerifiedIrModuleEmpty, 'malformed-or-foreign-constructor']);
  const carrierRejections = malformed.map(([name, ir, code]) => {
    const report = inventoryOriginalIr(compiler, ir, { compilerSha256 });
    assertRejected(report, name, code);
    assert.equal(report.portableChecker.status, 'not-run-invalid-carrier');
    return { name, findingCounts: report.findingCounts, portableChecker: 'not-run-invalid-carrier' };
  });
  const source = 'def irCheckedPrepared : Nat := 17\n';
  const prepared = unwrap(compiler.psCompilerPrepareSource(compiler.PsCompilerSourceKind.lean, source),
    'IR_CHECKED_PREPARE');
  const preparedOutput = unwrap(compiler.psCompilerCheckedTypeScriptFromPrepared(
    compiler.psIrCheckDefaultOptions, prepared), 'IR_CHECKED_PREPARED_EMIT');
  assert.equal(preparedOutput, unwrap(compiler.psCompilerTypeScriptFromPrepared(prepared), 'IR_PREPARED_PARITY'));
  const receipt = {
    schemaVersion: 1, evidence: 'portable-original-ir-checker-conformance',
    compilerSha256, acceptedFixture: positive,
    artifacts: { typescriptSha256: sha256(typeScript), javascriptSha256: sha256(await readFile(generated)) },
    behavior, rejected, exhausted, directTypeOperations, carrierRejections,
    diagnosticsCap: { limit: 0, findingCount: capped.findingCount, omittedFindingDetails: capped.omittedFindingDetails },
    checkedPreparedEntry: { sourceSha256: sha256(source), typescriptSha256: sha256(preparedOutput), status: 'pass' },
    instanceOwnership: 'All IR constructors and neutral record factories belong to the checked compiler namespace.',
    strictSh1Qualified: false, provider: { status: 'not-attempted', kernelChecked: false },
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_IR_CHECKER: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}

export async function runNativeIrCheckerConformance({
  nativeChecker, closure, nativeTypeScript, root, outDir,
}) {
  await mkdir(outDir, { recursive: true });
  const source = closure.ordered.map(({ source }) => stripBootstrapImports(source)).join('\n\n') + '\n';
  const sourcePath = path.join(outDir, 'current-source.lean');
  const checkedOutput = path.join(outDir, 'checked-current-source.ts');
  await writeFile(sourcePath, source);
  const binarySha256 = sha256(await readFile(nativeChecker));
  const command = [nativeChecker, sourcePath, checkedOutput];
  await writeFile(path.join(outDir, 'execution-inputs.json'), JSON.stringify({
    nativeCheckerSha256: binarySha256, sourceClosureSha256: closure.sha256,
    sourceAggregateSha256: sha256(source), command,
  }, null, 2) + '\n');
  const execution = spawnSync(nativeChecker, command.slice(1), {
    cwd: root, encoding: 'utf8', stdio: 'pipe', timeout: 180000,
    maxBuffer: 16 * 1024 * 1024,
  });
  // Retain the complete bounded diagnostics before checking the exit status.
  // The shared command helper truncates failures, which would lose root causes.
  const stdout = execution.stdout ?? '';
  const stderr = execution.stderr ?? '';
  await writeFile(path.join(outDir, 'native.stdout.log'), stdout);
  await writeFile(path.join(outDir, 'native.stderr.log'), stderr);
  process.stdout.write(stdout);
  process.stderr.write(stderr);
  assert.equal(sha256(await readFile(nativeChecker)), binarySha256, 'PSC0_SH1_IR_NATIVE_BINARY_CHANGED');
  if (execution.error) throw new Error('PSC0_SH1_IR_NATIVE_EXECUTION: ' + execution.error.message);
  assert.equal(execution.status, 0, 'PSC0_SH1_IR_NATIVE_EXECUTION_FAILED: ' + (execution.signal ?? 'exit'));
  const readReceipt = (marker) => {
    const lines = execution.stdout.split(/\r?\n/u).filter((line) => line.startsWith(marker + ': '));
    assert.equal(lines.length, 1, 'PSC0_SH1_IR_NATIVE_RECEIPT: ' + marker);
    return JSON.parse(lines[0].slice(marker.length + 2));
  };
  const fixtures = readReceipt('PSC0_SH1_IR_NATIVE');
  const full = readReceipt('PSC0_SH1_IR_NATIVE_FULL');
  assert.equal(fixtures.status, 'pass');
  assert.equal(full.accepted, true);
  assert.equal(full.traversalComplete, true);
  assert.equal(full.findingCount, 0);
  const checkedTs = await readFile(checkedOutput, 'utf8');
  assert.equal(checkedTs, await readFile(nativeTypeScript, 'utf8'), 'PSC0_SH1_IR_NATIVE_FULL_TYPESCRIPT_PARITY');
  const receipt = {
    schemaVersion: 1, evidence: 'native-portable-checker-current-source',
    nativeCheckerSha256: binarySha256, sourceClosureSha256: closure.sha256,
    sourceAggregateSha256: sha256(source), moduleCount: closure.moduleCount,
    recipe: 'Ordered raw closure with imports stripped, aggregate native preparation, original IR check, same-IR emission.',
    fixtures, fullCompilerIr: full,
    typescriptSha256: sha256(checkedTs),
    parity: 'Checked native emission equals the native-generated N1 compiler TypeScript byte for byte.',
    strictSh1Qualified: false, provider: { status: 'not-attempted', kernelChecked: false },
  };
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_IR_NATIVE_EVIDENCE: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
