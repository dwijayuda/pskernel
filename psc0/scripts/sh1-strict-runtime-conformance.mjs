import assert from 'node:assert/strict';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
import { inspectOriginalIrCarrier } from './original-ir-carrier.mjs';
import { describeOriginalIrCheckReport, inventoryOriginalIr } from './original-ir-inventory.mjs';
import { compileTypeScript, sha256, unwrap, valueTag } from './sh1-capabilities.mjs';
import { compileStrictSources } from './sh1-strict-source.mjs';

export const strictRuntimeContractSha256 = '21a9272d9d9a68ca67041a705cc049f02d4ccdf8fc258666dc59cce8c428db89';
export const strictRuntimeReferenceSourceSha256 = '3a4ada94e66ce4bc8a18bf0417c2a9660c06e326b4de312c8ee83ba831bda008';
export const strictSourceEvaluationLeanSourceSha256 = 'aa068f731e363494a42127e33fc8fc292de66de62075593f5c29ffb2af45748e';
export const strictSourceEvaluationProofScriptSourceSha256 = '27d9877bdd05f2189735047edf33b509ae6adab028fb7ebb128509e96b6cab1e';
export const strictSourceEvaluationReferenceSourceSha256 = '75486abeb314702a573b84c473e8fc8c4659b29ae8793f0ee7f89539e4c4a131';
export const strictSourceEvaluationExpectedObservationsSha256 = '9aa5567a82c7789778037e145d35d20f310329632da36c7758c8be45431ecb6f';
export const strictSourceEvaluationExpectedHostProbesSha256 = '76dba00fb02adff5cc8bd76d52f178b95cd6b9886542e8b5cf5e0efc314aae91';
const contractRelativePath = 'docs/selfhost-language/strict/enabled-runtime-contract.json';
const referenceRelativePath = 'test/StrictRuntimeReference.lean';
const nativePrefix = 'PSC0_SH1_STRICT_NATIVE_REFERENCE: ';

async function inputs(root) {
  const [contractText, source] = await Promise.all([
    readFile(path.join(root, contractRelativePath), 'utf8'),
    readFile(path.join(root, referenceRelativePath), 'utf8'),
  ]);
  assert.equal(sha256(contractText), strictRuntimeContractSha256, 'PSC0_STRICT_CONTRACT_CHANGED');
  assert.equal(sha256(source), strictRuntimeReferenceSourceSha256, 'PSC0_STRICT_REFERENCE_CHANGED');
  const contract = JSON.parse(contractText);
  assert.equal(contract.operations.length, 45);
  assert.equal(contract.cases.length, 186);
  assert.equal(new Set(contract.operations.map((entry) => entry.id)).size, 45);
  assert.equal(new Set(contract.cases.map((entry) => entry.id)).size, 186);
  return { contract, contractText, source };
}

function validateReference(envelope, contract) {
  assert.equal(envelope.kind, 'psc0-native-strict-runtime-reference-execution');
  assert.equal(envelope.status, 'reference-produced');
  assert.equal(envelope.sourceSha256, strictRuntimeReferenceSourceSha256);
  assert.equal(envelope.contractSha256, strictRuntimeContractSha256);
  assert.equal(envelope.execution.exitCode, 0);
  assert.equal(envelope.versionExecution.exitCode, 0);
  assert.match(envelope.versionExecution.stdout, /Lean \(version 4\.34\.0(?:,|\))/u);
  const reference = envelope.reference;
  assert.equal(reference.kind, 'psc0-native-enabled-runtime-reference');
  assert.equal(reference.status, 'reference-produced');
  assert.equal(reference.contractSha256, strictRuntimeContractSha256);
  assert.equal(reference.leanVersion, '4.34.0');
  assert.equal(reference.leanGitHash, '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
  assert.equal(reference.operationCount, 45);
  assert.equal(reference.observationCount, contract.cases.length);
  assert.equal(reference.strictSh1Qualified, false);
  assert.equal(reference.sourceProofProvenanceReconstructed, false);
  assert.equal(reference.observations.length, contract.cases.length);
  for (let index = 0; index < contract.cases.length; index++) {
    const expected = contract.cases[index], observed = reference.observations[index];
    assert.deepEqual(Object.keys(observed).sort(), ['id', 'operation', 'resultType', 'value']);
    assert.equal(observed.id, expected.id);
    assert.equal(observed.operation, expected.operation);
    assert.equal(observed.resultType, expected.resultType);
  }
  assert.equal(envelope.observationsSha256, sha256(JSON.stringify(reference.observations)));
  return reference;
}

// Run once per qualification, independently of every generated PSC0 compiler.
// The actual Lean process calculates all expected values; the case data only
// supplies labels/input correspondence, not precomputed expected results.
export async function runNativeStrictRuntimeReference({ root, outDir }) {
  const before = await inputs(root);
  await mkdir(outDir, { recursive: true });
  const versionCommand = ['lake', 'env', 'lean', '--version'];
  const command = ['lake', 'env', 'lean', '--run', path.join(root, referenceRelativePath)];
  const invoke = (argv) => spawnSync(argv[0], argv.slice(1), {
    cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 16 * 1024 * 1024,
  });
  const version = invoke(versionCommand);
  await writeFile(path.join(outDir, 'lean-version.stdout.log'), version.stdout ?? '');
  await writeFile(path.join(outDir, 'lean-version.stderr.log'), version.stderr ?? '');
  if (version.error) throw version.error;
  assert.equal(version.status, 0, 'PSC0_STRICT_NATIVE_VERSION_EXIT');
  assert.match(version.stdout, /Lean \(version 4\.34\.0(?:,|\))/u);
  const execution = invoke(command);
  const stdout = execution.stdout ?? '', stderr = execution.stderr ?? '';
  await writeFile(path.join(outDir, 'native.stdout.log'), stdout);
  await writeFile(path.join(outDir, 'native.stderr.log'), stderr);
  if (execution.error) throw execution.error;
  assert.equal(execution.status, 0, 'PSC0_STRICT_NATIVE_REFERENCE_EXIT');
  const lines = stdout.split(/\r?\n/u).filter((line) => line.startsWith(nativePrefix));
  assert.equal(lines.length, 1, 'PSC0_STRICT_NATIVE_REFERENCE_MARKER');
  const reference = JSON.parse(lines[0].slice(nativePrefix.length));
  const after = await inputs(root);
  assert.equal(after.source, before.source);
  assert.equal(after.contractText, before.contractText);
  const sourceEvaluationReference = await runNativeSourceEvaluationReference({ root, outDir });
  const envelope = {
    schemaVersion: 1, kind: 'psc0-native-strict-runtime-reference-execution',
    status: 'reference-produced', sourcePath: referenceRelativePath,
    sourceSha256: strictRuntimeReferenceSourceSha256,
    contractPath: contractRelativePath, contractSha256: strictRuntimeContractSha256,
    execution: { command, exitCode: execution.status, stdoutSha256: sha256(stdout), stderrSha256: sha256(stderr) },
    versionExecution: { command: versionCommand, exitCode: version.status,
      stdout: version.stdout, stderr: version.stderr },
    reference, sourceEvaluationReference,
    observationsSha256: sha256(JSON.stringify(reference.observations)),
    strictSh1Qualified: false, provider: { status: 'not-attempted', kernelChecked: false },
  };
  validateReference(envelope, before.contract);
  await writeFile(path.join(outDir, 'reference.json'), JSON.stringify(envelope, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_STRICT_NATIVE: ' + JSON.stringify(envelope) + '\n');
  return envelope;
}

function fixtureModel(c, contract) {
  const list = (values) => values.reduceRight((tail, value) => c.List.cons(value, tail), c.List.nil());
  const T = c.PsVerifiedIrType, E = c.PsVerifiedIrExpr, L = c.PsVerifiedIrLiteral;
  const primitive = (name) => T.primitive(c.PsVerifiedIrPrimitiveType[name]);
  const arrayType = (element) => T.named('Array', list([primitive(element)]));
  const type = (name) => name === 'arrayNat' ? arrayType('nat') :
    name === 'arrayUnit' ? arrayType('unit') : primitive(name);
  const fnType = (parameters, result) => T.function(list(parameters), result);
  const parameters = (entries) => list(entries.map(([name, value]) => c.psIrCheckMakeParameter(name, value)));
  const intrinsic = (name, arguments_, typeArguments = []) =>
    E.intrinsic(c.PsVerifiedIrIntrinsic[name], list(typeArguments), list(arguments_));
  const natural = (value) => E.literal(L.natural(BigInt(value)));
  const variable = (name) => E.var(name);
  const invoke = (name) => E.call(variable(name), list([]), list([]));
  const lambda = (entries, result, body) => E.lambda(parameters(entries), result, body);
  const declaration = (name, result, body, entries = []) =>
    c.psIrCheckMakeDeclaration(name, list([]), parameters(entries), result, body);
  const module = (declarations) => c.psIrCheckMakeModule(list([]), list([]), list([]), list(declarations));
  const argument = (input) => {
    switch (input.kind) {
      case 'nat': return natural(input.value);
      case 'int': return E.literal(L.integer(BigInt(input.value)));
      case 'bool': return E.literal(L.bool(input.value));
      case 'string': return E.literal(L.string(input.value));
      case 'char': return intrinsic('charOfNat', [natural(input.value)]);
      case 'unit': return E.literal(L.unit);
      case 'array': return input.values.reduce((array, value) =>
        intrinsic('arrayPush', [array, argument(value)], [primitive(input.element)]),
      intrinsic('arrayEmptyWithCapacity', [natural(0)], [primitive(input.element)]));
      case 'callback':
        if (input.name === 'natAddTen') return lambda([['value', primitive('nat')]], primitive('nat'),
          intrinsic('natAdd', [variable('value'), natural(10)]));
        assert.equal(input.name, 'natDecimalFold');
        return lambda([['acc', primitive('nat')], ['value', primitive('nat')]], primitive('nat'),
          intrinsic('natAdd', [intrinsic('natMul', [variable('acc'), natural(10)]), variable('value')]));
      default: throw new Error('PSC0_STRICT_CASE_ARGUMENT: ' + input.kind);
    }
  };
  const typeArguments = (entry) => {
    if (!entry.operation.startsWith('array')) return [];
    if (entry.operation === 'arrayMap' || entry.operation === 'arrayFoldl') return [primitive('nat'), primitive('nat')];
    const element = entry.arguments.find((item) => item.kind === 'array')?.element ?? 'nat';
    return [primitive(element)];
  };
  const declarations = contract.cases.map((entry, index) => declaration(
    'strict_case_' + index, type(entry.resultType),
    intrinsic(entry.operation, entry.arguments.map(argument), typeArguments(entry))));
  const nat = primitive('nat'), natArray = arrayType('nat');
  const seed = { kind: 'array', element: 'nat', values: [1, 2, 3].map((n) => ({ kind: 'nat', value: String(n) })) };
  declarations.push(declaration('strictSeed', natArray, argument(seed)));
  declarations.push(declaration('strictEmptySeed', natArray,
    intrinsic('arrayEmptyWithCapacity', [natural(0)], [nat])));
  declarations.push(declaration('strictGet', nat,
    intrinsic('arrayGet', [variable('array'), variable('index')], [nat]),
    [['array', natArray], ['index', nat]]));
  declarations.push(declaration('strictSet', natArray,
    intrinsic('arraySet', [variable('array'), variable('index'), variable('value')], [nat]),
    [['array', natArray], ['index', nat], ['value', nat]]));
  declarations.push(declaration('strictGetProbe', nat,
    intrinsic('arrayGet', [invoke('makeArray'), invoke('makeIndex')], [nat]),
    [['makeArray', fnType([], natArray)], ['makeIndex', fnType([], nat)]]));
  declarations.push(declaration('strictSetProbe', natArray,
    intrinsic('arraySet', [invoke('makeArray'), invoke('makeIndex'), invoke('makeValue')], [nat]),
    [['makeArray', fnType([], natArray)], ['makeIndex', fnType([], nat)], ['makeValue', fnType([], nat)]]));
  const singleString = (value, name = 'x') =>
    module([declaration(name, primitive('string'), E.literal(L.string(value)))]);
  return { module: module(declarations), declarationCount: declarations.length, singleString };
}

function isWellFormed(value) {
  if (typeof value !== 'string') return false;
  for (const character of value) {
    const scalar = character.codePointAt(0);
    if (scalar >= 0xd800 && scalar <= 0xdfff) return false;
  }
  return true;
}

function observedValue(type, value) {
  if (type === 'nat' || type === 'int') {
    assert.equal(typeof value, 'bigint');
    if (type === 'nat') assert(value >= 0n);
    return value.toString();
  }
  if (type === 'bool') { assert.equal(typeof value, 'boolean'); return value; }
  if (type === 'unit') { assert.equal(value, undefined); return 'unit'; }
  if (type === 'string' || type === 'char') {
    assert(isWellFormed(value), 'PSC0_STRICT_RUNTIME_TEXT_CARRIER');
    if (type === 'string') return value;
    assert.equal(Array.from(value).length, 1, 'PSC0_STRICT_RUNTIME_CHAR_CARDINALITY');
    return String(value.codePointAt(0));
  }
  assert(type === 'arrayNat' || type === 'arrayUnit');
  assert(Array.isArray(value));
  const elementType = type === 'arrayNat' ? 'nat' : 'unit';
  return Array.from({ length: value.length }, (_, index) => {
    assert(Object.hasOwn(value, index), 'PSC0_STRICT_RUNTIME_ARRAY_HOLE');
    return observedValue(elementType, value[index]);
  });
}

function defensiveBounds(runtime) {
  const observations = [], seed = runtime.strictSeed, empty = runtime.strictEmptySeed;
  const before = [...seed];
  const refusal = (id, code, invoke) => {
    assert.throws(invoke, (error) => error !== null && typeof error === 'object' &&
      Object.keys(error).length === 1 && error.code === code, id);
    observations.push({ id, expectedCode: code, status: 'defensive-runtime-refusal' });
    assert.deepEqual(seed, before, 'PSC0_STRICT_BOUNDS_ORIGINAL_ARRAY_CHANGED');
    assert.equal(empty.length, 0);
  };
  for (const [label, array, index] of [
    ['empty', empty, 0n], ['at-size', seed, 3n], ['large', seed, 900719925474099312345678901234567890n],
    ['negative-host-input', seed, -1n],
  ]) {
    refusal('arrayGet.' + label, 'PSC0_ARRAY_GET_BOUNDS', () => runtime.strictGet(array, index));
    refusal('arraySet.' + label, 'PSC0_ARRAY_SET_BOUNDS', () => runtime.strictSet(array, index, 9n));
  }
  assert.equal(runtime.strictGet(seed, 2n), 3n);
  assert.deepEqual(runtime.strictSet(seed, 1n, 9n), [1n, 9n, 3n]);
  assert.deepEqual(seed, before);
  return observations;
}

function operandEvaluation(runtime) {
  const observations = [], marker = { code: 'PSC0_HOST_OPERAND_PROBE' };
  const run = (id, kind, options, expectedTrace, expectedFault) => {
    const trace = [];
    const makeArray = () => { trace.push('array'); if (options.arrayFault) throw marker; return runtime.strictSeed; };
    const makeIndex = () => { trace.push('index'); if (options.indexFault) throw marker; return options.index ?? 1n; };
    const makeValue = () => { trace.push('value'); if (options.valueFault) throw marker; return 9n; };
    const invoke = () => kind === 'get' ? runtime.strictGetProbe(makeArray, makeIndex) :
      runtime.strictSetProbe(makeArray, makeIndex, makeValue);
    if (expectedFault === 'host') assert.throws(invoke, (error) => error === marker, id);
    else if (expectedFault) assert.throws(invoke, (error) => error?.code === expectedFault, id);
    else {
      const result = invoke();
      assert.deepEqual(result, kind === 'get' ? 2n : [1n, 9n, 3n], id);
    }
    assert.deepEqual(trace, expectedTrace, id);
    assert.deepEqual(runtime.strictSeed, [1n, 2n, 3n], id);
    observations.push({ id, trace, expectedFault: expectedFault ?? null, status: 'pass' });
  };
  run('get.valid-order', 'get', {}, ['array', 'index']);
  run('get.bounds-order', 'get', { index: 3n }, ['array', 'index'], 'PSC0_ARRAY_GET_BOUNDS');
  run('get.array-fault', 'get', { arrayFault: true }, ['array'], 'host');
  run('get.index-fault', 'get', { indexFault: true }, ['array', 'index'], 'host');
  run('set.valid-order', 'set', {}, ['array', 'index', 'value']);
  run('set.bounds-order', 'set', { index: 3n }, ['array', 'index', 'value'], 'PSC0_ARRAY_SET_BOUNDS');
  run('set.value-fault-before-bounds', 'set', { index: 3n, valueFault: true },
    ['array', 'index', 'value'], 'host');
  run('set.index-fault', 'set', { indexFault: true }, ['array', 'index'], 'host');
  run('set.array-fault', 'set', { arrayFault: true }, ['array'], 'host');
  return observations;
}

function carrierCases(compiler, compilerSha256, fixture) {
  const rejected = [];
  for (const [id, value, name] of [
    ['lone-high', '\ud800'], ['lone-low', '\udfff'], ['high-then-ascii', '\ud800A'],
    ['reversed-pair', '\udfff\ud800'], ['invalid-name', 'valid', '\ud800'],
  ]) {
    const original = value;
    const ir = fixture.singleString(value, name);
    const report = inventoryOriginalIr(compiler, ir, { compilerSha256 });
    assert.equal(report.runtimeIrTypingAccepted, false, id);
    assert.equal(report.portableChecker.status, 'not-run-invalid-carrier', id);
    assert.equal(report.findingCounts['invalid-ir-scalar-carrier'], 1, id);
    assert.equal(ir.declarations.head.body.value.value, original, 'PSC0_STRICT_TEXT_REPAIRED');
    assert.equal(ir.declarations.head.name, name ?? 'x', 'PSC0_STRICT_NAME_REPAIRED');
    rejected.push({ id, findingCounts: report.findingCounts, portableChecker: report.portableChecker.status });
  }
  const valid = inspectOriginalIrCarrier(compiler, fixture.singleString('😀\u0000é'));
  assert.equal(valid.accepted, true, 'PSC0_STRICT_VALID_SURROGATE_PAIR');
  const exact = inspectOriginalIrCarrier(compiler, fixture.singleString('x'.repeat(32)), { maxNodes: 32 });
  const exceeded = inspectOriginalIrCarrier(compiler, fixture.singleString('x'.repeat(33)), { maxNodes: 32 });
  assert.equal(exact.accepted, true, 'PSC0_STRICT_STRING_BOUND_EXACT');
  assert.equal(exceeded.accepted, false, 'PSC0_STRICT_STRING_BOUND_EXCEEDED');
  assert.equal(exceeded.finding.code, 'ir-carrier-resource-limit');
  assert.match(exceeded.finding.detail, /UTF-16 units/u);
  return { rejected, canonicalPairAndNul: 'accepted', lengthBoundary: { limit: 32, exact, exceeded },
    repairOrNormalization: false };
}

function textPositions(compiler, contract) {
  const position = (value) => ({
    byteOffset: value.byteOffset.toString(), line: value.line.toString(), column: value.column.toString(),
  });
  const [cursorCase, lexerCase] = contract.textPositionCases;
  let cursor = compiler.psLexCursorFromString(cursorCase.source);
  assert.deepEqual(position(cursor.position), { byteOffset: '0', line: '1', column: '1' });
  const after = [];
  for (const expected of cursorCase.after) {
    const option = compiler.psLexCursorAdvance(cursor);
    assert.equal(valueTag(option), 'some');
    assert.equal(option.value.char, expected.char);
    cursor = option.value.cursor;
    const actual = position(cursor.position);
    assert.deepEqual(actual, { byteOffset: String(expected.byteOffset),
      line: String(expected.line), column: String(expected.column) });
    after.push({ char: expected.char, ...actual });
  }
  assert.equal(valueTag(compiler.psLexCursorAdvance(cursor)), 'none');
  let list = unwrap(compiler.psLexProofScript(lexerCase.source), 'STRICT_POSITION_LEX');
  const tokens = [];
  while (valueTag(list) === 'cons') {
    assert(tokens.length <= lexerCase.source.length, 'PSC0_STRICT_POSITION_TOKEN_BOUND');
    tokens.push(list.head); list = list.tail;
  }
  assert.equal(valueTag(list), 'nil');
  const origins = lexerCase.origins.map((expected) => {
    const token = tokens.filter((item) => item.text === expected.text)[expected.occurrence];
    assert(token, 'PSC0_STRICT_POSITION_TOKEN');
    const actual = position(token.span.start);
    assert.deepEqual(actual, { byteOffset: String(expected.byteOffset),
      line: String(expected.line), column: String(expected.column) });
    return { text: expected.text, occurrence: expected.occurrence, ...actual };
  });
  return [{ id: cursorCase.id, after }, { id: lexerCase.id, origins }];
}

// A source-level regression for the installed Nat.beq primitive. The other
// equality operations remain covered by the unchanged original-IR fixture.
// These independent fixed expectations do not use the emitted compiler as an oracle.
async function sourceEqualityRegression({ compiler, compilerSha256, root, outDir, tsc }) {
  const relativeDirectory = 'source-equality';
  const directory = path.join(outDir, relativeDirectory);
  await mkdir(directory, { recursive: true });
  const moduleName = ['Ps', 'Compiler', 'StrictRuntimeEquality'];
  const rawSources = {
    lean: [
      'def strictSourceNatEqEqual : Bool := Nat.beq 7 7',
      'def strictSourceNatEqDisjoint : Bool := Nat.beq 1 2',
      'def strictSourceNatEqReversed : Bool := Nat.beq 2 1',
      'def strictSourceNatEqZero : Bool := Nat.beq 0 0',
      'def strictSourceNatEqLarge : Bool := Nat.beq 900719925474099312345678901234567890 900719925474099312345678901234567891',
      'def strictSourceNatEqComputed : Bool := Nat.beq (Nat.add 2 3) 5',
    ].join('\n') + '\n',
    ps: [
      'def strictSourceNatEqEqual : Bool := Nat.beq(7, 7)',
      'def strictSourceNatEqDisjoint : Bool := Nat.beq(1, 2)',
      'def strictSourceNatEqReversed : Bool := Nat.beq(2, 1)',
      'def strictSourceNatEqZero : Bool := Nat.beq(0, 0)',
      'def strictSourceNatEqLarge : Bool := Nat.beq(900719925474099312345678901234567890, 900719925474099312345678901234567891)',
      'def strictSourceNatEqComputed : Bool := Nat.beq(Nat.add(2, 3), 5)',
    ].join('\n') + '\n',
  };
  const expected = [
    { id: 'equal', declaration: 'strictSourceNatEqEqual', expected: true },
    { id: 'disjoint', declaration: 'strictSourceNatEqDisjoint', expected: false },
    { id: 'reversed', declaration: 'strictSourceNatEqReversed', expected: false },
    { id: 'zero', declaration: 'strictSourceNatEqZero', expected: true },
    { id: 'large', declaration: 'strictSourceNatEqLarge', expected: false },
    { id: 'computed', declaration: 'strictSourceNatEqComputed', expected: true },
  ];
  const sources = [], compiled = {};
  for (const sourceKind of ['lean', 'ps']) {
    const source = rawSources[sourceKind];
    const sourcePath = relativeDirectory + '/source.' + sourceKind;
    await writeFile(path.join(outDir, sourcePath), source, 'utf8');
    const result = compileStrictSources(compiler, [{ moduleName, source }],
      { compilerSha256, sourceKind });
    assert.equal(result.evidence.sourcePolicy.moduleCount, 1);
    assert.equal(result.evidence.sourcePolicy.stats.declarationCount, expected.length);
    assert.equal(result.evidence.sourcePolicy.importCount, 0);
    const sourceSha256 = sha256(source), sourceBytes = Buffer.byteLength(source);
    assert.deepEqual(result.evidence.sourceInputs, [{ moduleName, sourceSha256, sourceBytes }]);
    assert.equal(result.evidence.preparationCount, 1);
    assert.equal(result.evidence.portableIrCheckCount, 1);
    const evidenceText = JSON.stringify(result.evidence, null, 2) + '\n';
    const evidencePath = relativeDirectory + '/' + sourceKind + '-source-receipt.json';
    await writeFile(path.join(outDir, evidencePath), evidenceText, 'utf8');
    sources.push({ sourceKind, path: sourcePath, sha256: sourceSha256, bytes: sourceBytes,
      evidencePath, evidenceSha256: sha256(evidenceText), evidence: result.evidence });
    compiled[sourceKind] = result;
  }
  assert.equal(compiled.lean.typeScript, compiled.ps.typeScript,
    'PSC0_STRICT_SOURCE_EQUALITY_TYPESCRIPT_BYTES');
  assert.equal(compiled.lean.admissions, compiled.ps.admissions,
    'PSC0_STRICT_SOURCE_EQUALITY_ADMISSIONS_BYTES');
  const typeScript = compiled.lean.typeScript, admissions = compiled.lean.admissions;
  const admissionsPath = relativeDirectory + '/admissions.jsonl';
  await writeFile(path.join(outDir, admissionsPath), admissions, 'utf8');
  // Compile this single shared module separately: concatenating complete emitted
  // modules would duplicate their private runtime helpers.
  const generated = await compileTypeScript(typeScript, path.join(directory, 'runtime'), tsc, root, '7.0.2');
  const javascript = await readFile(generated, 'utf8');
  const runtime = await import(pathToFileURL(generated).href + '?sha256=' + sha256(javascript));
  const observations = expected.map((entry) => {
    const value = runtime[entry.declaration];
    assert.equal(typeof value, 'boolean', 'PSC0_STRICT_SOURCE_EQUALITY_RESULT_TYPE: ' + entry.id);
    assert.equal(value, entry.expected, 'PSC0_STRICT_SOURCE_EQUALITY_RESULT: ' + entry.id);
    return { ...entry, value };
  });
  return {
    schemaVersion: 1, kind: 'psc0-source-nat-equality-conformance', status: 'pass',
    compilerSha256, sourceOperation: 'Nat.beq', irOperation: 'natEq',
    declarationCount: expected.length, sources,
    byteAgreement: { typescript: true, admissions: true },
    artifacts: {
      typescript: { path: relativeDirectory + '/runtime/index.ts', sha256: sha256(typeScript) },
      javascript: { path: relativeDirectory + '/runtime/index.js', sha256: sha256(javascript) },
      admissions: { path: admissionsPath, sha256: sha256(admissions) },
    },
    expectedValuesOrigin: 'independent-fixed-results',
    observations, observationsSha256: sha256(JSON.stringify(observations)),
    rawSourceCompilationCount: 2, portableIrCheckCount: 2, typescriptCompilationCount: 1,
    strictSh1Qualified: false, semanticContractQualified: false,
    formalPreservationProven: false, sourceProofProvenanceReconstructed: false,
    provider: { status: 'not-attempted', kernelChecked: false },
  };
}

// This next semantic slice covers computed Nat majors, text operand order,
// and computed Array capacity expressions in generator-backed calls.
function sourceEvaluationFixture() {
  const rawSources = {
    lean: [
      "def strictNatComputed (value : Nat) : Nat :=",
      "  match Nat.add value 0 with",
      "  | Nat.zero => 97",
      "  | Nat.succ predecessor => Nat.add predecessor 3",
      "",
      "def strictNatNested (value : Nat) : Nat :=",
      "  match Nat.add value 1 with",
      "  | Nat.zero => 101",
      "  | Nat.succ outer =>",
      "      match Nat.add outer 2 with",
      "      | Nat.zero => 103",
      "      | Nat.succ inner => Nat.add inner 7",
      "",
      "def strictNatCollision (_psNatMajor : Nat) : Nat :=",
      "  match Nat.add _psNatMajor 1 with",
      "  | Nat.zero => _psNatMajor",
      "  | Nat.succ _psNatMajor => Nat.add _psNatMajor 13",
      "",
      "def strictNatBranchBinder (value : Nat) : Nat :=",
      "  match Nat.add value 0 with",
      "  | Nat.zero => 23",
      "  | Nat.succ _psNatMajor => Nat.add _psNatMajor 31",
      "",
      "def strictNatProbe (major : Nat -> Nat) (start : Nat -> Nat)",
      "    (zero : Nat -> Nat) (successor : Nat -> Nat) (seed : Nat) : Nat :=",
      "  match major (start seed) with",
      "  | Nat.zero => zero 17",
      "  | Nat.succ predecessor => successor predecessor",
      "",
      "def sh1RuntimeAtEndCalls (getText : Unit -> String) (getPosition : Unit -> Nat) : Bool :=",
      "  String.Internal.atEnd (getText Unit.unit) (String.Pos.Raw.mk (getPosition Unit.unit))",
      "",
      "def sh1RuntimeEmptyCalls (getCapacity : Unit -> Nat) : Array Nat :=",
      "  Array.emptyWithCapacity (getCapacity Unit.unit)",
      "",
      "structure StrictPartialFn where",
      "  apply : Nat -> Nat -> Nat -> Nat",
      "",
      "def strictPartialCalls (_psAppFn : StrictPartialFn) (_psAppArg : Unit -> Nat)",
      "    (getSecond : Unit -> Nat) (after : Nat -> Nat) (seed : Nat) (useSaved : Bool) : Nat :=",
      "  let saved : Nat -> Nat := _psAppFn.apply (_psAppArg Unit.unit) (getSecond Unit.unit);",
      "  let next : Nat := after seed;",
      "  if useSaved then Nat.add (saved next) (saved next) else next",
      "",
      "def strictPartialNested (_psAppFn : StrictPartialFn) (_psAppArg : Unit -> Nat)",
      "    (getSecond : Unit -> Nat) (after : Nat -> Nat) (seed : Nat) : Nat :=",
      "  let first : Nat -> Nat -> Nat := _psAppFn.apply (_psAppArg Unit.unit);",
      "  let saved : Nat -> Nat := first (getSecond Unit.unit);",
      "  let next : Nat := after seed;",
      "  Nat.add (saved next) (saved next)",
      "",
      "def strictPartialKeep {p : Prop} (Alpha : Type) (h : p)",
      "    (chosen : Alpha) (ignored : Nat) : Alpha := chosen",
      "",
      "def strictPartialGeneric {p : Prop} (Alpha : Type) (h : p)",
      "    (make : Unit -> Alpha) (after : Nat -> Nat) (seed : Nat) : Alpha :=",
      "  let saved : Nat -> Alpha := strictPartialKeep Alpha h (make Unit.unit);",
      "  let next : Nat := after seed;",
      "  let prior : Alpha := saved next;",
      "  saved next"
    ].join('\n') + '\n',
    ps: [
      "def strictNatComputed(value : Nat) : Nat :=",
      "  match Nat.add(value, 0) with {",
      "  | Nat.zero => 97",
      "  | Nat.succ predecessor => Nat.add(predecessor, 3)",
      "  }",
      "",
      "def strictNatNested(value : Nat) : Nat :=",
      "  match Nat.add(value, 1) with {",
      "  | Nat.zero => 101",
      "  | Nat.succ outer =>",
      "      match Nat.add(outer, 2) with {",
      "      | Nat.zero => 103",
      "      | Nat.succ inner => Nat.add(inner, 7)",
      "      }",
      "  }",
      "",
      "def strictNatCollision(_psNatMajor : Nat) : Nat :=",
      "  match Nat.add(_psNatMajor, 1) with {",
      "  | Nat.zero => _psNatMajor",
      "  | Nat.succ _psNatMajor => Nat.add(_psNatMajor, 13)",
      "  }",
      "",
      "def strictNatBranchBinder(value : Nat) : Nat :=",
      "  match Nat.add(value, 0) with {",
      "  | Nat.zero => 23",
      "  | Nat.succ _psNatMajor => Nat.add(_psNatMajor, 31)",
      "  }",
      "",
      "def strictNatProbe(major : Nat -> Nat, start : Nat -> Nat,",
      "    zero : Nat -> Nat, successor : Nat -> Nat, seed : Nat) : Nat :=",
      "  match major(start(seed)) with {",
      "  | Nat.zero => zero(17)",
      "  | Nat.succ predecessor => successor(predecessor)",
      "  }",
      "",
      "def sh1RuntimeAtEndCalls(getText : Unit -> String, getPosition : Unit -> Nat) : Bool :=",
      "  String.Internal.atEnd(getText(Unit.unit), String.Pos.Raw.mk(getPosition(Unit.unit)))",
      "",
      "def sh1RuntimeEmptyCalls(getCapacity : Unit -> Nat) : Array(Nat) :=",
      "  Array.emptyWithCapacity(getCapacity(Unit.unit))",
      "",
      "structure StrictPartialFn where {",
      "  apply : Nat -> Nat -> Nat -> Nat",
      "}",
      "",
      "def strictPartialCalls(_psAppFn : StrictPartialFn, _psAppArg : Unit -> Nat,",
      "    getSecond : Unit -> Nat, after : Nat -> Nat, seed : Nat, useSaved : Bool) : Nat :=",
      "  let saved : Nat -> Nat := _psAppFn.apply(_psAppArg(Unit.unit), getSecond(Unit.unit))",
      "  let next : Nat := after(seed)",
      "  if (useSaved) { Nat.add(saved(next), saved(next)) } else { next }",
      "",
      "def strictPartialNested(_psAppFn : StrictPartialFn, _psAppArg : Unit -> Nat,",
      "    getSecond : Unit -> Nat, after : Nat -> Nat, seed : Nat) : Nat :=",
      "  let first : Nat -> Nat -> Nat := _psAppFn.apply(_psAppArg(Unit.unit))",
      "  let saved : Nat -> Nat := first(getSecond(Unit.unit))",
      "  let next : Nat := after(seed)",
      "  Nat.add(saved(next), saved(next))",
      "",
      "def strictPartialKeep {p : Prop}(Alpha : Type, h : p,",
      "    chosen : Alpha, ignored : Nat) : Alpha := chosen",
      "",
      "def strictPartialGeneric {p : Prop}(Alpha : Type, h : p,",
      "    make : Unit -> Alpha, after : Nat -> Nat, seed : Nat) : Alpha :=",
      "  let saved : Nat -> Alpha := strictPartialKeep(Alpha, h, make(Unit.unit))",
      "  let next : Nat := after(seed)",
      "  let prior : Alpha := saved(next)",
      "  saved(next)"
    ].join('\n') + '\n',
  };
  const valueCases = [
    {
      "id": "computed.zero",
      "group": "natDemand",
      "declaration": "strictNatComputed",
      "resultType": "nat",
      "input": "0",
      "expected": "97",
      "nativeExpression": "strictNatComputed (0 : Nat)"
    },
    {
      "id": "computed.successor",
      "group": "natDemand",
      "declaration": "strictNatComputed",
      "resultType": "nat",
      "input": "5",
      "expected": "7",
      "nativeExpression": "strictNatComputed (5 : Nat)"
    },
    {
      "id": "computed.large",
      "group": "natDemand",
      "declaration": "strictNatComputed",
      "resultType": "nat",
      "input": "900719925474099312345678901234567890",
      "expected": "900719925474099312345678901234567892",
      "nativeExpression": "strictNatComputed (900719925474099312345678901234567890 : Nat)"
    },
    {
      "id": "nested.zero-input",
      "group": "natDemand",
      "declaration": "strictNatNested",
      "resultType": "nat",
      "input": "0",
      "expected": "8",
      "nativeExpression": "strictNatNested (0 : Nat)"
    },
    {
      "id": "nested.successor-input",
      "group": "natDemand",
      "declaration": "strictNatNested",
      "resultType": "nat",
      "input": "5",
      "expected": "13",
      "nativeExpression": "strictNatNested (5 : Nat)"
    },
    {
      "id": "collision.zero-input",
      "group": "natDemand",
      "declaration": "strictNatCollision",
      "resultType": "nat",
      "input": "0",
      "expected": "13",
      "nativeExpression": "strictNatCollision (0 : Nat)"
    },
    {
      "id": "collision.successor-input",
      "group": "natDemand",
      "declaration": "strictNatCollision",
      "resultType": "nat",
      "input": "7",
      "expected": "20",
      "nativeExpression": "strictNatCollision (7 : Nat)"
    },
    {
      "id": "branch-name.zero",
      "group": "natDemand",
      "declaration": "strictNatBranchBinder",
      "resultType": "nat",
      "input": "0",
      "expected": "23",
      "nativeExpression": "strictNatBranchBinder (0 : Nat)"
    },
    {
      "id": "branch-name.successor",
      "group": "natDemand",
      "declaration": "strictNatBranchBinder",
      "resultType": "nat",
      "input": "7",
      "expected": "37",
      "nativeExpression": "strictNatBranchBinder (7 : Nat)"
    },
    {
      "id": "probe.zero",
      "group": "natDemand",
      "declaration": "strictNatProbe",
      "resultType": "nat",
      "input": "0",
      "callbackFixture": "identity-major-start-plus100-zero-plus200-successor",
      "expected": "117",
      "nativeExpression": "strictNatProbe (fun (value : Nat) => value) (fun (value : Nat) => value) (fun (value : Nat) => Nat.add value 100) (fun (value : Nat) => Nat.add value 200) (0 : Nat)"
    },
    {
      "id": "probe.successor",
      "group": "natDemand",
      "declaration": "strictNatProbe",
      "resultType": "nat",
      "input": "5",
      "callbackFixture": "identity-major-start-plus100-zero-plus200-successor",
      "expected": "204",
      "nativeExpression": "strictNatProbe (fun (value : Nat) => value) (fun (value : Nat) => value) (fun (value : Nat) => Nat.add value 100) (fun (value : Nat) => Nat.add value 200) (5 : Nat)"
    },
    {
      "id": "atEnd.start",
      "group": "stringAtEnd",
      "declaration": "sh1RuntimeAtEndCalls",
      "resultType": "bool",
      "input": "é😀",
      "position": "0",
      "callbackFixture": "constant-text-and-position",
      "expected": false,
      "nativeExpression": "sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"é😀\") (fun (_unit : Unit) => (0 : Nat))"
    },
    {
      "id": "atEnd.middle",
      "group": "stringAtEnd",
      "declaration": "sh1RuntimeAtEndCalls",
      "resultType": "bool",
      "input": "é😀",
      "position": "2",
      "callbackFixture": "constant-text-and-position",
      "expected": false,
      "nativeExpression": "sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"é😀\") (fun (_unit : Unit) => (2 : Nat))"
    },
    {
      "id": "atEnd.exact-end",
      "group": "stringAtEnd",
      "declaration": "sh1RuntimeAtEndCalls",
      "resultType": "bool",
      "input": "é😀",
      "position": "6",
      "callbackFixture": "constant-text-and-position",
      "expected": true,
      "nativeExpression": "sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"é😀\") (fun (_unit : Unit) => (6 : Nat))"
    },
    {
      "id": "atEnd.after-end",
      "group": "stringAtEnd",
      "declaration": "sh1RuntimeAtEndCalls",
      "resultType": "bool",
      "input": "é😀",
      "position": "7",
      "callbackFixture": "constant-text-and-position",
      "expected": true,
      "nativeExpression": "sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"é😀\") (fun (_unit : Unit) => (7 : Nat))"
    },
    {
      "id": "atEnd.empty",
      "group": "stringAtEnd",
      "declaration": "sh1RuntimeAtEndCalls",
      "resultType": "bool",
      "input": "",
      "position": "0",
      "callbackFixture": "constant-text-and-position",
      "expected": true,
      "nativeExpression": "sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"\") (fun (_unit : Unit) => (0 : Nat))"
    },
    {
      "id": "empty.capacity-0",
      "group": "arrayEmptyWithCapacity",
      "declaration": "sh1RuntimeEmptyCalls",
      "resultType": "arrayNat",
      "input": "0",
      "callbackFixture": "constant-capacity",
      "expected": [],
      "nativeExpression": "sh1RuntimeEmptyCalls (fun (_unit : Unit) => (0 : Nat))"
    },
    {
      "id": "empty.capacity-17",
      "group": "arrayEmptyWithCapacity",
      "declaration": "sh1RuntimeEmptyCalls",
      "resultType": "arrayNat",
      "input": "17",
      "callbackFixture": "constant-capacity",
      "expected": [],
      "nativeExpression": "sh1RuntimeEmptyCalls (fun (_unit : Unit) => (17 : Nat))"
    },
    {
      "id": "partial.used",
      "group": "partialApplication",
      "declaration": "strictPartialCalls",
      "resultType": "nat",
      "input": "3",
      "useSaved": true,
      "callbackFixture": "partial-weighted-record",
      "expected": "488",
      "nativeExpression": "strictPartialCalls (StrictPartialFn.mk (fun (first : Nat) (second : Nat) (third : Nat) => Nat.add (Nat.mul first 100) (Nat.add (Nat.mul second 10) third))) (fun (_unit : Unit) => (2 : Nat)) (fun (_unit : Unit) => (4 : Nat)) (fun (value : Nat) => Nat.add value 1) (3 : Nat) true"
    },
    {
      "id": "partial.unused",
      "group": "partialApplication",
      "declaration": "strictPartialCalls",
      "resultType": "nat",
      "input": "3",
      "useSaved": false,
      "callbackFixture": "partial-weighted-record",
      "expected": "4",
      "nativeExpression": "strictPartialCalls (StrictPartialFn.mk (fun (first : Nat) (second : Nat) (third : Nat) => Nat.add (Nat.mul first 100) (Nat.add (Nat.mul second 10) third))) (fun (_unit : Unit) => (2 : Nat)) (fun (_unit : Unit) => (4 : Nat)) (fun (value : Nat) => Nat.add value 1) (3 : Nat) false"
    },
    {
      "id": "partial.nested",
      "group": "partialApplication",
      "declaration": "strictPartialNested",
      "resultType": "nat",
      "input": "5",
      "callbackFixture": "partial-nested-weighted-record",
      "expected": "492",
      "nativeExpression": "strictPartialNested (StrictPartialFn.mk (fun (first : Nat) (second : Nat) (third : Nat) => Nat.add (Nat.mul first 100) (Nat.add (Nat.mul second 10) third))) (fun (_unit : Unit) => (2 : Nat)) (fun (_unit : Unit) => (4 : Nat)) (fun (value : Nat) => Nat.add value 1) (5 : Nat)"
    },
    {
      "id": "partial.generic-nat",
      "group": "partialApplication",
      "declaration": "strictPartialGeneric",
      "resultType": "nat",
      "input": "23",
      "callbackFixture": "partial-generic-and-proof",
      "expected": "23",
      "nativeExpression": "@strictPartialGeneric True Nat True.intro (fun (_unit : Unit) => (23 : Nat)) (fun (value : Nat) => Nat.add value 1) (3 : Nat)"
    },
    {
      "id": "partial.generic-bool",
      "group": "partialApplication",
      "declaration": "strictPartialGeneric",
      "resultType": "bool",
      "input": true,
      "callbackFixture": "partial-generic-and-proof",
      "expected": true,
      "nativeExpression": "@strictPartialGeneric True Bool True.intro (fun (_unit : Unit) => true) (fun (value : Nat) => Nat.add value 1) (3 : Nat)"
    },
    {
      "id": "partial.generic-string",
      "group": "partialApplication",
      "declaration": "strictPartialGeneric",
      "resultType": "string",
      "input": "é😀",
      "callbackFixture": "partial-generic-and-proof",
      "expected": "é😀",
      "nativeExpression": "@strictPartialGeneric True String True.intro (fun (_unit : Unit) => \"é😀\") (fun (value : Nat) => Nat.add value 1) (3 : Nat)"
    }
  ];
  const hostProbeCases = [
    {
      "id": "nat.successor-once-order",
      "group": "natDemand",
      "seed": "4",
      "startOffset": "1",
      "branch": "successor",
      "fault": null,
      "trace": [
        "start:4",
        "major:5",
        "successor:4"
      ],
      "resultType": "nat",
      "value": "204"
    },
    {
      "id": "nat.zero-once-order",
      "group": "natDemand",
      "seed": "0",
      "startOffset": "0",
      "branch": "zero",
      "fault": null,
      "trace": [
        "start:0",
        "major:0",
        "zero:17"
      ],
      "resultType": "nat",
      "value": "117"
    },
    {
      "id": "nat.start-first-fault",
      "group": "natDemand",
      "seed": "4",
      "startOffset": "1",
      "branch": "successor",
      "fault": "start",
      "trace": [
        "start:4"
      ],
      "resultType": "nat",
      "value": null
    },
    {
      "id": "nat.major-first-fault",
      "group": "natDemand",
      "seed": "4",
      "startOffset": "1",
      "branch": "successor",
      "fault": "major",
      "trace": [
        "start:4",
        "major:5"
      ],
      "resultType": "nat",
      "value": null
    },
    {
      "id": "nat.zero-first-fault",
      "group": "natDemand",
      "seed": "0",
      "startOffset": "0",
      "branch": "zero",
      "fault": "zero",
      "trace": [
        "start:0",
        "major:0",
        "zero:17"
      ],
      "resultType": "nat",
      "value": null
    },
    {
      "id": "nat.successor-first-fault",
      "group": "natDemand",
      "seed": "4",
      "startOffset": "1",
      "branch": "successor",
      "fault": "successor",
      "trace": [
        "start:4",
        "major:5",
        "successor:4"
      ],
      "resultType": "nat",
      "value": null
    },
    {
      "id": "atEnd.operand-order",
      "group": "stringAtEnd",
      "fault": null,
      "trace": [
        "text",
        "position"
      ],
      "resultType": "bool",
      "value": true
    },
    {
      "id": "atEnd.text-first-fault",
      "group": "stringAtEnd",
      "fault": "text",
      "trace": [
        "text"
      ],
      "resultType": "bool",
      "value": null
    },
    {
      "id": "atEnd.position-first-fault",
      "group": "stringAtEnd",
      "fault": "position",
      "trace": [
        "text",
        "position"
      ],
      "resultType": "bool",
      "value": null
    },
    {
      "id": "empty.capacity-once",
      "group": "arrayEmptyWithCapacity",
      "fault": null,
      "trace": [
        "capacity"
      ],
      "resultType": "arrayNat",
      "value": []
    },
    {
      "id": "empty.capacity-first-fault",
      "group": "arrayEmptyWithCapacity",
      "fault": "capacity",
      "trace": [
        "capacity"
      ],
      "resultType": "arrayNat",
      "value": null
    },
    {
      "id": "partial.formation-once-order",
      "group": "partialApplication",
      "mode": "direct",
      "useSaved": true,
      "fault": null,
      "trace": [
        "callee",
        "first",
        "second",
        "after"
      ],
      "resultType": "nat",
      "value": "488",
      "diagnosticDomain": "host-accessor-and-callbacks"
    },
    {
      "id": "partial.unused-closure-demand",
      "group": "partialApplication",
      "mode": "direct",
      "useSaved": false,
      "fault": null,
      "trace": [
        "callee",
        "first",
        "second",
        "after"
      ],
      "resultType": "nat",
      "value": "4",
      "diagnosticDomain": "host-accessor-and-callbacks"
    },
    {
      "id": "partial.callee-first-fault",
      "group": "partialApplication",
      "mode": "direct",
      "useSaved": true,
      "fault": "callee",
      "trace": [
        "callee"
      ],
      "resultType": "nat",
      "value": null,
      "diagnosticDomain": "host-accessor-and-callbacks"
    },
    {
      "id": "partial.first-argument-fault",
      "group": "partialApplication",
      "mode": "direct",
      "useSaved": true,
      "fault": "first",
      "trace": [
        "callee",
        "first"
      ],
      "resultType": "nat",
      "value": null,
      "diagnosticDomain": "host-accessor-and-callbacks"
    },
    {
      "id": "partial.second-argument-fault",
      "group": "partialApplication",
      "mode": "direct",
      "useSaved": true,
      "fault": "second",
      "trace": [
        "callee",
        "first",
        "second"
      ],
      "resultType": "nat",
      "value": null,
      "diagnosticDomain": "host-accessor-and-callbacks"
    },
    {
      "id": "partial.after-formation-fault",
      "group": "partialApplication",
      "mode": "direct",
      "useSaved": true,
      "fault": "after",
      "trace": [
        "callee",
        "first",
        "second",
        "after"
      ],
      "resultType": "nat",
      "value": null,
      "diagnosticDomain": "host-accessor-and-callbacks"
    },
    {
      "id": "partial.nested-formation-order",
      "group": "partialApplication",
      "mode": "nested",
      "useSaved": true,
      "fault": null,
      "trace": [
        "callee",
        "first",
        "second",
        "after"
      ],
      "resultType": "nat",
      "value": "488",
      "diagnosticDomain": "host-accessor-and-callbacks"
    },
    {
      "id": "partial.generic-proof-erased",
      "group": "partialApplication",
      "mode": "generic",
      "useSaved": true,
      "fault": null,
      "trace": [
        "first",
        "after"
      ],
      "resultType": "nat",
      "value": "23",
      "diagnosticDomain": "host-callbacks-only"
    },
    {
      "id": "partial.generic-first-fault",
      "group": "partialApplication",
      "mode": "generic",
      "useSaved": true,
      "fault": "first",
      "trace": [
        "first"
      ],
      "resultType": "nat",
      "value": null,
      "diagnosticDomain": "host-callbacks-only"
    },
    {
      "id": "partial.generic-after-fault",
      "group": "partialApplication",
      "mode": "generic",
      "useSaved": true,
      "fault": "after",
      "trace": [
        "first",
        "after"
      ],
      "resultType": "nat",
      "value": null,
      "diagnosticDomain": "host-callbacks-only"
    }
  ];
  const nativeReferenceSource = [
      "import Lean",
      "",
      "-- The eleven definitions and one structure below are the exact raw Lean fixture consumed by PSC0.",
      "-- Only this native value-reference wrapper imports Lean and uses IO/JSON.",
      "",
      "def strictNatComputed (value : Nat) : Nat :=",
      "  match Nat.add value 0 with",
      "  | Nat.zero => 97",
      "  | Nat.succ predecessor => Nat.add predecessor 3",
      "",
      "def strictNatNested (value : Nat) : Nat :=",
      "  match Nat.add value 1 with",
      "  | Nat.zero => 101",
      "  | Nat.succ outer =>",
      "      match Nat.add outer 2 with",
      "      | Nat.zero => 103",
      "      | Nat.succ inner => Nat.add inner 7",
      "",
      "def strictNatCollision (_psNatMajor : Nat) : Nat :=",
      "  match Nat.add _psNatMajor 1 with",
      "  | Nat.zero => _psNatMajor",
      "  | Nat.succ _psNatMajor => Nat.add _psNatMajor 13",
      "",
      "def strictNatBranchBinder (value : Nat) : Nat :=",
      "  match Nat.add value 0 with",
      "  | Nat.zero => 23",
      "  | Nat.succ _psNatMajor => Nat.add _psNatMajor 31",
      "",
      "def strictNatProbe (major : Nat -> Nat) (start : Nat -> Nat)",
      "    (zero : Nat -> Nat) (successor : Nat -> Nat) (seed : Nat) : Nat :=",
      "  match major (start seed) with",
      "  | Nat.zero => zero 17",
      "  | Nat.succ predecessor => successor predecessor",
      "",
      "def sh1RuntimeAtEndCalls (getText : Unit -> String) (getPosition : Unit -> Nat) : Bool :=",
      "  String.Internal.atEnd (getText Unit.unit) (String.Pos.Raw.mk (getPosition Unit.unit))",
      "",
      "def sh1RuntimeEmptyCalls (getCapacity : Unit -> Nat) : Array Nat :=",
      "  Array.emptyWithCapacity (getCapacity Unit.unit)",
      "",
      "structure StrictPartialFn where",
      "  apply : Nat -> Nat -> Nat -> Nat",
      "",
      "def strictPartialCalls (_psAppFn : StrictPartialFn) (_psAppArg : Unit -> Nat)",
      "    (getSecond : Unit -> Nat) (after : Nat -> Nat) (seed : Nat) (useSaved : Bool) : Nat :=",
      "  let saved : Nat -> Nat := _psAppFn.apply (_psAppArg Unit.unit) (getSecond Unit.unit);",
      "  let next : Nat := after seed;",
      "  if useSaved then Nat.add (saved next) (saved next) else next",
      "",
      "def strictPartialNested (_psAppFn : StrictPartialFn) (_psAppArg : Unit -> Nat)",
      "    (getSecond : Unit -> Nat) (after : Nat -> Nat) (seed : Nat) : Nat :=",
      "  let first : Nat -> Nat -> Nat := _psAppFn.apply (_psAppArg Unit.unit);",
      "  let saved : Nat -> Nat := first (getSecond Unit.unit);",
      "  let next : Nat := after seed;",
      "  Nat.add (saved next) (saved next)",
      "",
      "def strictPartialKeep {p : Prop} (Alpha : Type) (h : p)",
      "    (chosen : Alpha) (ignored : Nat) : Alpha := chosen",
      "",
      "def strictPartialGeneric {p : Prop} (Alpha : Type) (h : p)",
      "    (make : Unit -> Alpha) (after : Nat -> Nat) (seed : Nat) : Alpha :=",
      "  let saved : Nat -> Alpha := strictPartialKeep Alpha h (make Unit.unit);",
      "  let next : Nat := after seed;",
      "  let prior : Alpha := saved next;",
      "  saved next",
      "",
      "open Lean",
      "",
      "private def sourceEvaluationObservations : Array Json := #[",
      "  Json.mkObj [(\"id\", Json.str \"computed.zero\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatComputed (0 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"computed.successor\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatComputed (5 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"computed.large\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatComputed (900719925474099312345678901234567890 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"nested.zero-input\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatNested (0 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"nested.successor-input\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatNested (5 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"collision.zero-input\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatCollision (0 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"collision.successor-input\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatCollision (7 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"branch-name.zero\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatBranchBinder (0 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"branch-name.successor\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatBranchBinder (7 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"probe.zero\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatProbe (fun (value : Nat) => value) (fun (value : Nat) => value) (fun (value : Nat) => Nat.add value 100) (fun (value : Nat) => Nat.add value 200) (0 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"probe.successor\"), (\"group\", Json.str \"natDemand\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictNatProbe (fun (value : Nat) => value) (fun (value : Nat) => value) (fun (value : Nat) => Nat.add value 100) (fun (value : Nat) => Nat.add value 200) (5 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"atEnd.start\"), (\"group\", Json.str \"stringAtEnd\"),",
      "    (\"resultType\", Json.str \"bool\"), (\"value\", Json.bool (sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"é😀\") (fun (_unit : Unit) => (0 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"atEnd.middle\"), (\"group\", Json.str \"stringAtEnd\"),",
      "    (\"resultType\", Json.str \"bool\"), (\"value\", Json.bool (sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"é😀\") (fun (_unit : Unit) => (2 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"atEnd.exact-end\"), (\"group\", Json.str \"stringAtEnd\"),",
      "    (\"resultType\", Json.str \"bool\"), (\"value\", Json.bool (sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"é😀\") (fun (_unit : Unit) => (6 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"atEnd.after-end\"), (\"group\", Json.str \"stringAtEnd\"),",
      "    (\"resultType\", Json.str \"bool\"), (\"value\", Json.bool (sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"é😀\") (fun (_unit : Unit) => (7 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"atEnd.empty\"), (\"group\", Json.str \"stringAtEnd\"),",
      "    (\"resultType\", Json.str \"bool\"), (\"value\", Json.bool (sh1RuntimeAtEndCalls (fun (_unit : Unit) => \"\") (fun (_unit : Unit) => (0 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"empty.capacity-0\"), (\"group\", Json.str \"arrayEmptyWithCapacity\"),",
      "    (\"resultType\", Json.str \"arrayNat\"), (\"value\", Json.arr ((sh1RuntimeEmptyCalls (fun (_unit : Unit) => (0 : Nat))).map (fun (value : Nat) => Json.str (toString value))))],",
      "  Json.mkObj [(\"id\", Json.str \"empty.capacity-17\"), (\"group\", Json.str \"arrayEmptyWithCapacity\"),",
      "    (\"resultType\", Json.str \"arrayNat\"), (\"value\", Json.arr ((sh1RuntimeEmptyCalls (fun (_unit : Unit) => (17 : Nat))).map (fun (value : Nat) => Json.str (toString value))))],",
      "  Json.mkObj [(\"id\", Json.str \"partial.used\"), (\"group\", Json.str \"partialApplication\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictPartialCalls (StrictPartialFn.mk (fun (first : Nat) (second : Nat) (third : Nat) => Nat.add (Nat.mul first 100) (Nat.add (Nat.mul second 10) third))) (fun (_unit : Unit) => (2 : Nat)) (fun (_unit : Unit) => (4 : Nat)) (fun (value : Nat) => Nat.add value 1) (3 : Nat) true)))],",
      "  Json.mkObj [(\"id\", Json.str \"partial.unused\"), (\"group\", Json.str \"partialApplication\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictPartialCalls (StrictPartialFn.mk (fun (first : Nat) (second : Nat) (third : Nat) => Nat.add (Nat.mul first 100) (Nat.add (Nat.mul second 10) third))) (fun (_unit : Unit) => (2 : Nat)) (fun (_unit : Unit) => (4 : Nat)) (fun (value : Nat) => Nat.add value 1) (3 : Nat) false)))],",
      "  Json.mkObj [(\"id\", Json.str \"partial.nested\"), (\"group\", Json.str \"partialApplication\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (strictPartialNested (StrictPartialFn.mk (fun (first : Nat) (second : Nat) (third : Nat) => Nat.add (Nat.mul first 100) (Nat.add (Nat.mul second 10) third))) (fun (_unit : Unit) => (2 : Nat)) (fun (_unit : Unit) => (4 : Nat)) (fun (value : Nat) => Nat.add value 1) (5 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"partial.generic-nat\"), (\"group\", Json.str \"partialApplication\"),",
      "    (\"resultType\", Json.str \"nat\"), (\"value\", Json.str (toString (@strictPartialGeneric True Nat True.intro (fun (_unit : Unit) => (23 : Nat)) (fun (value : Nat) => Nat.add value 1) (3 : Nat))))],",
      "  Json.mkObj [(\"id\", Json.str \"partial.generic-bool\"), (\"group\", Json.str \"partialApplication\"),",
      "    (\"resultType\", Json.str \"bool\"), (\"value\", Json.bool (@strictPartialGeneric True Bool True.intro (fun (_unit : Unit) => true) (fun (value : Nat) => Nat.add value 1) (3 : Nat)))],",
      "  Json.mkObj [(\"id\", Json.str \"partial.generic-string\"), (\"group\", Json.str \"partialApplication\"),",
      "    (\"resultType\", Json.str \"string\"), (\"value\", Json.str (@strictPartialGeneric True String True.intro (fun (_unit : Unit) => \"é😀\") (fun (value : Nat) => Nat.add value 1) (3 : Nat)))]",
      "]",
      "",
      "def main : IO Unit := do",
      "  let receipt := Json.mkObj [",
      "    (\"schemaVersion\", toJson (1 : Nat)),",
      "    (\"kind\", Json.str \"psc0-native-source-evaluation-reference\"),",
      "    (\"status\", Json.str \"reference-produced\"),",
      "    (\"rawSourceSha256\", Json.str \"aa068f731e363494a42127e33fc8fc292de66de62075593f5c29ffb2af45748e\"),",
      "    (\"leanVersion\", Json.str Lean.versionStringCore),",
      "    (\"leanGitHash\", Json.str Lean.githash),",
      "    (\"observationCount\", toJson sourceEvaluationObservations.size),",
      "    (\"observations\", Json.arr sourceEvaluationObservations),",
      "    (\"strictSh1Qualified\", Json.bool false),",
      "    (\"semanticContractQualified\", Json.bool false),",
      "    (\"formalPreservationProven\", Json.bool false)",
      "  ]",
      "  IO.println (\"PSC0_SH1_NATIVE_SOURCE_EVALUATION: \" ++ receipt.compress)"
    ].join('\n') + '\n';
  return { moduleName: ['Ps', 'Compiler', 'StrictEvaluation'], rawSources,
    valueCases, hostProbeCases, nativeReferenceSource };
}
function sourceEvaluationExpected(fixture) {
  assert.equal(fixture.valueCases.length, 24);
  assert.equal(fixture.hostProbeCases.length, 21);
  assert.equal(sha256(fixture.rawSources.lean), strictSourceEvaluationLeanSourceSha256);
  assert.equal(sha256(fixture.rawSources.ps), strictSourceEvaluationProofScriptSourceSha256);
  assert.equal(sha256(fixture.nativeReferenceSource), strictSourceEvaluationReferenceSourceSha256);
  const expected = fixture.valueCases.map(({ id, group, resultType, expected: value }) =>
    ({ id, group, resultType, value }));
  assert.equal(sha256(JSON.stringify(expected)), strictSourceEvaluationExpectedObservationsSha256);
  return expected;
}

function validateSourceEvaluationReference(envelope, fixture) {
  assert(envelope && typeof envelope === 'object', 'PSC0_SOURCE_EVALUATION_NATIVE_REFERENCE_REQUIRED');
  const expected = sourceEvaluationExpected(fixture);
  assert.equal(envelope.schemaVersion, 1);
  assert.equal(envelope.kind, 'psc0-native-source-evaluation-reference-execution');
  assert.equal(envelope.status, 'reference-produced');
  assert.equal(envelope.source.path, 'native-source-evaluation/reference.lean');
  assert.equal(envelope.source.sha256, strictSourceEvaluationReferenceSourceSha256);
  assert.equal(envelope.source.bytes, Buffer.byteLength(fixture.nativeReferenceSource));
  assert.equal(envelope.rawSource.path, 'native-source-evaluation/fixture.lean');
  assert.equal(envelope.rawSource.sha256, strictSourceEvaluationLeanSourceSha256);
  assert.equal(envelope.rawSource.bytes, Buffer.byteLength(fixture.rawSources.lean));
  assert.equal(envelope.execution.exitCode, 0);
  assert.equal(envelope.nativeExecutionCount, 1);
  assert.equal(envelope.strictSh1Qualified, false);
  assert.equal(envelope.semanticContractQualified, false);
  assert.equal(envelope.formalPreservationProven, false);
  assert.equal(envelope.sourceEffectCapabilityAdded, false);
  assert.deepEqual(envelope.provider, { status: 'not-attempted', kernelChecked: false });
  const native = envelope.reference;
  assert.equal(native.schemaVersion, 1);
  assert.equal(native.kind, 'psc0-native-source-evaluation-reference');
  assert.equal(native.status, 'reference-produced');
  assert.equal(native.rawSourceSha256, strictSourceEvaluationLeanSourceSha256);
  assert.equal(native.leanVersion, '4.34.0');
  assert.equal(native.leanGitHash, '293d5d0c0c3f3dded4688b3ccd6a33939ac5102b');
  assert.equal(native.observationCount, 24);
  assert.equal(native.strictSh1Qualified, false);
  assert.equal(native.semanticContractQualified, false);
  assert.equal(native.formalPreservationProven, false);
  assert.deepEqual(native.observations, expected, 'PSC0_SOURCE_EVALUATION_NATIVE_FIXED_VALUES');
  assert.deepEqual(envelope.observations, expected);
  assert.equal(envelope.observationsSha256, strictSourceEvaluationExpectedObservationsSha256);
  assert.equal(sha256(JSON.stringify(envelope.observations)), envelope.observationsSha256);
  return envelope;
}

// A single additional native Lean value run for the whole qualification.
// The raw fixture is an exact prefix of the generated reference definitions.
// The existing 186-case source, contract and observation rows remain unchanged.
async function runNativeSourceEvaluationReference({ root, outDir }) {
  const fixture = sourceEvaluationFixture();
  sourceEvaluationExpected(fixture);
  const relativeDirectory = 'native-source-evaluation';
  const directory = path.join(outDir, relativeDirectory);
  await mkdir(directory, { recursive: true });
  const sourcePath = relativeDirectory + '/reference.lean';
  const rawSourcePath = relativeDirectory + '/fixture.lean';
  const stdoutPath = relativeDirectory + '/stdout.log';
  const stderrPath = relativeDirectory + '/stderr.log';
  const sourceFile = path.join(outDir, sourcePath);
  await writeFile(sourceFile, fixture.nativeReferenceSource, 'utf8');
  await writeFile(path.join(outDir, rawSourcePath), fixture.rawSources.lean, 'utf8');
  const command = ['lake', 'env', 'lean', '--run', sourceFile];
  const execution = spawnSync(command[0], command.slice(1), {
    cwd: root, encoding: 'utf8', timeout: 120000, maxBuffer: 4 * 1024 * 1024,
  });
  const stdout = execution.stdout ?? '', stderr = execution.stderr ?? '';
  await writeFile(path.join(outDir, stdoutPath), stdout, 'utf8');
  await writeFile(path.join(outDir, stderrPath), stderr, 'utf8');
  if (execution.error) throw execution.error;
  assert.equal(execution.status, 0, 'PSC0_SOURCE_EVALUATION_NATIVE_EXIT');
  assert.equal(await readFile(sourceFile, 'utf8'), fixture.nativeReferenceSource);
  assert.equal(await readFile(path.join(outDir, rawSourcePath), 'utf8'), fixture.rawSources.lean);
  const prefix = 'PSC0_SH1_NATIVE_SOURCE_EVALUATION: ';
  const lines = stdout.split(/\r?\n/u).filter((line) => line.startsWith(prefix));
  assert.equal(lines.length, 1, 'PSC0_SOURCE_EVALUATION_NATIVE_MARKER');
  const reference = JSON.parse(lines[0].slice(prefix.length));
  // Preserve the complete native receipt; explicitly order only these evidence
  // object keys so the observation digest does not depend on Json object order.
  const observations = reference.observations.map(({ id, group, resultType, value }) =>
    ({ id, group, resultType, value }));
  const envelope = {
    schemaVersion: 1, kind: 'psc0-native-source-evaluation-reference-execution',
    status: 'reference-produced',
    source: { path: sourcePath, sha256: strictSourceEvaluationReferenceSourceSha256,
      bytes: Buffer.byteLength(fixture.nativeReferenceSource) },
    rawSource: { path: rawSourcePath, sha256: strictSourceEvaluationLeanSourceSha256,
      bytes: Buffer.byteLength(fixture.rawSources.lean) },
    execution: { command, exitCode: execution.status,
      stdoutPath, stdoutSha256: sha256(stdout), stderrPath, stderrSha256: sha256(stderr) },
    reference, observations, observationsSha256: sha256(JSON.stringify(observations)),
    nativeExecutionCount: 1,
    strictSh1Qualified: false, semanticContractQualified: false, formalPreservationProven: false,
    sourceEffectCapabilityAdded: false, provider: { status: 'not-attempted', kernelChecked: false },
  };
  validateSourceEvaluationReference(envelope, fixture);
  const receiptText = JSON.stringify(envelope, null, 2) + '\n';
  const receiptPath = relativeDirectory + '/receipt.json';
  await writeFile(path.join(outDir, receiptPath), receiptText, 'utf8');
  return { ...envelope, receipt: { path: receiptPath, sha256: sha256(receiptText) } };
}

function sourceEvaluationHostProbes(runtime, fixture) {
  const observations = [];
  for (const entry of fixture.hostProbeCases) {
    const trace = [];
    const faults = Object.fromEntries(
      ['start', 'major', 'zero', 'successor', 'text', 'position', 'capacity', 'unselected',
        'callee', 'first', 'second', 'after']
        .map((phase) => [phase, { code: 'PSC0_SOURCE_EVALUATION_HOST_PROBE', phase }]));
    let invoke;
    if (entry.group === 'natDemand') {
      const start = (value) => {
        trace.push('start:' + value.toString());
        if (entry.fault === 'start') throw faults.start;
        return value + BigInt(entry.startOffset);
      };
      const major = (value) => {
        trace.push('major:' + value.toString());
        if (entry.fault === 'major') throw faults.major;
        return value;
      };
      const zero = (value) => {
        trace.push('zero:' + value.toString());
        if (entry.branch !== 'zero') throw faults.unselected;
        if (entry.fault === 'zero') throw faults.zero;
        return value + 100n;
      };
      const successor = (value) => {
        trace.push('successor:' + value.toString());
        if (entry.branch !== 'successor') throw faults.unselected;
        if (entry.fault === 'successor') throw faults.successor;
        return value + 200n;
      };
      invoke = () => runtime.strictNatProbe(major, start, zero, successor, BigInt(entry.seed));
    } else if (entry.group === 'stringAtEnd') {
      const getText = (unit) => {
        assert.equal(unit, undefined);
        trace.push('text');
        if (entry.fault === 'text') throw faults.text;
        return 'é😀';
      };
      const getPosition = (unit) => {
        assert.equal(unit, undefined);
        trace.push('position');
        // When both operands can fail, the text operand's failure must win.
        if (entry.fault === 'text' || entry.fault === 'position') throw faults.position;
        return 6n;
      };
      invoke = () => runtime.sh1RuntimeAtEndCalls(getText, getPosition);
    } else if (entry.group === 'partialApplication') {
      // These accessors and callbacks are diagnostic host values, outside the
      // immutable source-value contract. Pure reference cases use plain records.
      const phases = entry.mode === 'generic' ? ['first', 'after'] :
        ['callee', 'first', 'second', 'after'];
      const faultIndex = entry.fault === null ? -1 : phases.indexOf(entry.fault);
      assert(entry.fault === null || faultIndex >= 0);
      const visit = (phase) => {
        trace.push(phase);
        // Every later phase can also fail: the earliest demanded error must win.
        if (faultIndex >= 0 && phases.indexOf(phase) >= faultIndex) throw faults[phase];
      };
      const first = (unit) => {
        assert.equal(unit, undefined);
        visit('first');
        return entry.mode === 'generic' ? 23n : 2n;
      };
      const second = (unit) => {
        assert.equal(unit, undefined);
        visit('second');
        return 4n;
      };
      const after = (value) => {
        assert.equal(value, 3n);
        visit('after');
        return value + 1n;
      };
      if (entry.mode === 'generic') {
        assert.equal(entry.diagnosticDomain, 'host-callbacks-only');
        // Alpha and both proof parameters are erased; only these three values remain.
        invoke = () => runtime.strictPartialGeneric(first, after, 3n);
      } else {
        assert.equal(entry.diagnosticDomain, 'host-accessor-and-callbacks');
        const holder = Object.defineProperty({}, 'apply', {
          enumerable: true,
          get() {
            visit('callee');
            return (a, b, c) => 100n * a + 10n * b + c;
          },
        });
        if (entry.mode === 'nested')
          invoke = () => runtime.strictPartialNested(holder, first, second, after, 3n);
        else {
          assert.equal(entry.mode, 'direct');
          invoke = () => runtime.strictPartialCalls(holder, first, second, after, 3n, entry.useSaved);
        }
      }
    } else {
      assert.equal(entry.group, 'arrayEmptyWithCapacity');
      const getCapacity = (unit) => {
        assert.equal(unit, undefined);
        trace.push('capacity');
        if (entry.fault === 'capacity') throw faults.capacity;
        return 17n;
      };
      invoke = () => runtime.sh1RuntimeEmptyCalls(getCapacity);
    }
    let value = null;
    if (entry.fault) assert.throws(invoke, (error) => error === faults[entry.fault], entry.id);
    else {
      value = observedValue(entry.resultType, invoke());
      assert.deepEqual(value, entry.value, entry.id);
    }
    assert.deepEqual(trace, entry.trace, entry.id);
    const observation = { id: entry.id, group: entry.group, trace,
      expectedFault: entry.fault, value, status: 'pass' };
    if (entry.diagnosticDomain) observation.diagnosticDomain = entry.diagnosticDomain;
    observations.push(observation);
  }
  assert.equal(observations.length, 21);
  assert.equal(sha256(JSON.stringify(observations)), strictSourceEvaluationExpectedHostProbesSha256);
  return observations;
}

// These ordinary source function types do not admit host effects or FFI.
// Native pure-value correspondence and diagnostic host traces stay separate.
async function sourceEvaluationRegression({ compiler, compilerSha256, root, outDir, tsc, reference }) {
  const fixture = sourceEvaluationFixture();
  const native = validateSourceEvaluationReference(reference, fixture);
  assert.equal(native.receipt.path, 'native-source-evaluation/receipt.json');
  assert.match(native.receipt.sha256, /^[a-f0-9]{64}$/u);
  const expected = sourceEvaluationExpected(fixture);
  const relativeDirectory = 'source-evaluation';
  const directory = path.join(outDir, relativeDirectory);
  await mkdir(directory, { recursive: true });
  const sources = [], compiled = {};
  for (const sourceKind of ['lean', 'ps']) {
    const source = fixture.rawSources[sourceKind];
    const sourcePath = relativeDirectory + '/source.' + sourceKind;
    await writeFile(path.join(outDir, sourcePath), source, 'utf8');
    const result = compileStrictSources(compiler, [{ moduleName: fixture.moduleName, source }],
      { compilerSha256, sourceKind });
    assert.equal(result.evidence.sourcePolicy.moduleCount, 1);
    assert.equal(result.evidence.sourcePolicy.stats.declarationCount, 12);
    assert.equal(result.evidence.sourcePolicy.importCount, 0);
    const sourceSha256 = sha256(source), sourceBytes = Buffer.byteLength(source);
    assert.deepEqual(result.evidence.sourceInputs, [{
      moduleName: fixture.moduleName, sourceSha256, sourceBytes,
    }]);
    assert.equal(result.evidence.preparationCount, 1);
    assert.equal(result.evidence.portableIrCheckCount, 1);
    const evidenceText = JSON.stringify(result.evidence, null, 2) + '\n';
    const evidencePath = relativeDirectory + '/' + sourceKind + '-source-receipt.json';
    await writeFile(path.join(outDir, evidencePath), evidenceText, 'utf8');
    sources.push({ sourceKind, path: sourcePath, sha256: sourceSha256, bytes: sourceBytes,
      evidencePath, evidenceSha256: sha256(evidenceText), evidence: result.evidence });
    compiled[sourceKind] = result;
  }
  assert.equal(compiled.lean.typeScript, compiled.ps.typeScript,
    'PSC0_SOURCE_EVALUATION_TYPESCRIPT_BYTES');
  assert.equal(compiled.lean.admissions, compiled.ps.admissions,
    'PSC0_SOURCE_EVALUATION_ADMISSIONS_BYTES');
  const typeScript = compiled.lean.typeScript, admissions = compiled.lean.admissions;
  const admissionsPath = relativeDirectory + '/admissions.jsonl';
  await writeFile(path.join(outDir, admissionsPath), admissions, 'utf8');
  const generated = await compileTypeScript(typeScript, path.join(directory, 'runtime'), tsc, root, '7.0.2');
  const javascript = await readFile(generated, 'utf8');
  const runtime = await import(pathToFileURL(generated).href + '?sha256=' + sha256(javascript));
  const observations = fixture.valueCases.map((entry) => {
    let result;
    if (entry.callbackFixture === 'identity-major-start-plus100-zero-plus200-successor') {
      result = runtime[entry.declaration]((value) => value, (value) => value,
        (value) => value + 100n, (value) => value + 200n, BigInt(entry.input));
    } else if (entry.callbackFixture === 'constant-text-and-position') {
      result = runtime[entry.declaration](() => entry.input, () => BigInt(entry.position));
    } else if (entry.callbackFixture === 'constant-capacity') {
      result = runtime[entry.declaration](() => BigInt(entry.input));
    } else if (entry.callbackFixture === 'partial-weighted-record' ||
        entry.callbackFixture === 'partial-nested-weighted-record') {
      // Plain immutable host records with related pure fields, without accessors.
      const holder = { apply: (a, b, c) => 100n * a + 10n * b + c };
      const arguments_ = [holder, () => 2n, () => 4n, (value) => value + 1n, BigInt(entry.input)];
      if (entry.callbackFixture === 'partial-weighted-record') arguments_.push(entry.useSaved);
      result = runtime[entry.declaration](...arguments_);
    } else if (entry.callbackFixture === 'partial-generic-and-proof') {
      const value = entry.resultType === 'nat' ? BigInt(entry.input) : entry.input;
      result = runtime[entry.declaration](() => value, (input) => input + 1n, 3n);
    } else {
      assert.equal(entry.callbackFixture, undefined);
      result = runtime[entry.declaration](BigInt(entry.input));
    }
    return { id: entry.id, group: entry.group, resultType: entry.resultType,
      value: observedValue(entry.resultType, result) };
  });
  assert.deepEqual(observations, expected, 'PSC0_SOURCE_EVALUATION_FIXED_VALUES');
  assert.deepEqual(observations, native.observations, 'PSC0_SOURCE_EVALUATION_NATIVE_CORRESPONDENCE');
  assert.equal(sha256(JSON.stringify(observations)), strictSourceEvaluationExpectedObservationsSha256);
  const hostProbes = sourceEvaluationHostProbes(runtime, fixture);
  return {
    schemaVersion: 1, kind: 'psc0-source-evaluation-conformance', status: 'pass',
    compilerSha256, declarationCount: 12, definitionCount: 11, structureCount: 1, sources,
    byteAgreement: { typescript: true, admissions: true },
    artifacts: {
      typescript: { path: relativeDirectory + '/runtime/index.ts', sha256: sha256(typeScript) },
      javascript: { path: relativeDirectory + '/runtime/index.js', sha256: sha256(javascript) },
      admissions: { path: admissionsPath, sha256: sha256(admissions) },
    },
    nativeReference: { sourceSha256: native.source.sha256, rawSourceSha256: native.rawSource.sha256,
      receiptPath: native.receipt.path, receiptSha256: native.receipt.sha256,
      leanVersion: native.reference.leanVersion, leanGitHash: native.reference.leanGitHash,
      observationsSha256: native.observationsSha256, stdoutSha256: native.execution.stdoutSha256 },
    expectedValuesOrigin: 'independent-fixed-results-and-native-Lean-execution',
    observations, observationsSha256: sha256(JSON.stringify(observations)),
    hostProbes, hostProbesSha256: sha256(JSON.stringify(hostProbes)),
    observationCount: 24, hostProbeCount: 21,
    rawSourceCompilationCount: 2, portableIrCheckCount: 2, typescriptCompilationCount: 1,
    nativeReferenceReused: true, additionalNativeExecutions: 0,
    interpretation: {
      natMajor: 'Computed majors are observed once; nested and branch-name cases preserve pure values.',
      runtimeOperands: 'Text then position; computed capacity stays in the surrounding generator context.',
      partialApplication: 'Computed callee and supplied operands are captured before completion closures; repeated calls, unused closures, nested partial groups and erased generics/proofs are distinguished.',
      pureValues: 'The exact raw Lean definitions and structure run once natively; all compiler generations reuse 24 observations.',
      hostProbes: 'Twenty-one separate host traces/faults: fourteen callback-only and seven accessor/callback diagnostics, all outside the admitted source effects.',
      hostAccessors: 'Noncanonical host accessors distinguish callee projection demand only; pure source values remain immutable records.',
      allocation: 'Array capacity cases are bounded by 17 and observations assume allocation succeeds.',
    },
    strictSh1Qualified: false, semanticContractQualified: false, formalPreservationProven: false,
    sourceProofProvenanceReconstructed: false, sourceEffectCapabilityAdded: false,
    provider: { status: 'not-attempted', kernelChecked: false },
  };
}

// This proves finite executable correspondence and defensive refusals.
// It does not claim erased proof provenance, general totality, or strict SH/1.
export async function runStrictRuntimeConformance({
  compiler, compilerSha256, root, outDir, tsc, reference,
}) {
  assert.match(compilerSha256, /^[a-f0-9]{64}$/u);
  const { contract } = await inputs(root);
  const native = validateReference(reference, contract);
  const fixture = fixtureModel(compiler, contract);
  const options = compiler.psIrCheckDefaultOptions;
  const fixtureCarrier = inspectOriginalIrCarrier(compiler, fixture.module);
  assert.equal(fixtureCarrier.accepted, true, 'PSC0_STRICT_FIXTURE_CARRIER');
  const emission = unwrap(compiler.psTsEmitCheckedModuleWithReport(
    options, fixture.module), 'STRICT_CHECKED_EMIT');
  const checked = describeOriginalIrCheckReport(compiler, emission.report, {
    compilerSha256, carrier: fixtureCarrier,
    maxFindings: Number(options.maxFindings), maxSteps: Number(options.maxSteps),
    typeSteps: options.maxTypeSteps,
  });
  assert.equal(checked.runtimeIrTypingAccepted, true, 'PSC0_STRICT_FIXTURE_IR_TYPES');
  assert.equal(checked.traversalComplete, true);
  const typeScript = emission.typeScript;
  const generated = await compileTypeScript(typeScript, path.join(outDir, 'runtime'), tsc, root, '7.0.2');
  const javascript = await readFile(generated, 'utf8');
  const runtime = await import(pathToFileURL(generated).href + '?sha256=' + sha256(javascript));
  const observations = contract.cases.map((entry, index) => ({
    id: entry.id, operation: entry.operation, resultType: entry.resultType,
    value: observedValue(entry.resultType, runtime['strict_case_' + index]),
  }));
  assert.deepEqual(observations, native.observations, 'PSC0_STRICT_NATIVE_RUNTIME_CORRESPONDENCE');
  const operationCoverage = contract.operations.map((operation) => ({
    operation: operation.id, cases: observations.filter((entry) => entry.operation === operation.id).map((entry) => entry.id),
  }));
  assert(operationCoverage.every((entry) => entry.cases.length > 0));
  const bounds = defensiveBounds(runtime);
  const evaluation = operandEvaluation(runtime);
  const carrier = carrierCases(compiler, compilerSha256, fixture);
  const positions = textPositions(compiler, contract);
  const sourceEquality = await sourceEqualityRegression({ compiler, compilerSha256, root, outDir, tsc });
  const sourceEvaluation = await sourceEvaluationRegression({ compiler, compilerSha256, root, outDir, tsc,
    reference: reference.sourceEvaluationReference });
  const receipt = {
    schemaVersion: 1, kind: 'psc0-enabled-runtime-conformance', status: 'pass',
    compilerSha256, contractVersion: contract.version, contractSha256: strictRuntimeContractSha256,
    nativeReference: { sourceSha256: strictRuntimeReferenceSourceSha256,
      leanVersion: native.leanVersion, leanGitHash: native.leanGitHash,
      observationsSha256: reference.observationsSha256, stdoutSha256: reference.execution.stdoutSha256 },
    checkedOriginalIr: checked, portableIrCheckCount: 1, fixtureDeclarations: fixture.declarationCount,
    artifacts: { typescriptSha256: sha256(typeScript), javascriptSha256: sha256(javascript) },
    operationCoverage, observations, observationsSha256: sha256(JSON.stringify(observations)),
    defensiveBounds: bounds, operandEvaluation: evaluation, carrier, textPositions: positions,
    sourceEqualityRegression: sourceEquality,
    sourceEvaluationRegression: sourceEvaluation,
    interpretation: {
      correspondence: '186 fixed native Lean reference observations for all 45 enabled operations.',
      bounds: 'Defensive refusal outside proof-required source bounds; no reconstructed proof or totality claim.',
      operands: 'Host callback observations for exact once/in-order evaluation; no new admitted FFI capability.',
      unicode: 'Canonical String/Char values, no repair, raw byte positions keep pinned fallback semantics.',
      booleanDemand: 'Value truth tables only; general short-circuit lowering proof is a separate obligation.',
      sourceEquality: 'Six Nat.beq declarations in raw Lean and new-only PS share exact TS/admission bytes and independent fixed Bool results.',
      sourceEvaluation: 'Eleven raw definitions and one structure, 24 reused native pure values and 21 separate host diagnostic traces for four lowering classes.',
    },
    strictSh1Qualified: false, semanticContractQualified: false, formalPreservationProven: false,
    sourceProofProvenanceReconstructed: false, provider: { status: 'not-attempted', kernelChecked: false },
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_STRICT_RUNTIME: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
