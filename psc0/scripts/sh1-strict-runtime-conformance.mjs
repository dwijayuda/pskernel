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
  const envelope = {
    schemaVersion: 1, kind: 'psc0-native-strict-runtime-reference-execution',
    status: 'reference-produced', sourcePath: referenceRelativePath,
    sourceSha256: strictRuntimeReferenceSourceSha256,
    contractPath: contractRelativePath, contractSha256: strictRuntimeContractSha256,
    execution: { command, exitCode: execution.status, stdoutSha256: sha256(stdout), stderrSha256: sha256(stderr) },
    versionExecution: { command: versionCommand, exitCode: version.status,
      stdout: version.stdout, stderr: version.stderr },
    reference, observationsSha256: sha256(JSON.stringify(reference.observations)),
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
    interpretation: {
      correspondence: '186 fixed native Lean reference observations for all 45 enabled operations.',
      bounds: 'Defensive refusal outside proof-required source bounds; no reconstructed proof or totality claim.',
      operands: 'Host callback observations for exact once/in-order evaluation; no new admitted FFI capability.',
      unicode: 'Canonical String/Char values, no repair, raw byte positions keep pinned fallback semantics.',
      booleanDemand: 'Value truth tables only; general short-circuit lowering proof is a separate obligation.',
      sourceEquality: 'Six Nat.beq declarations in raw Lean and new-only PS share exact TS/admission bytes and independent fixed Bool results.',
    },
    strictSh1Qualified: false, semanticContractQualified: false, formalPreservationProven: false,
    sourceProofProvenanceReconstructed: false, provider: { status: 'not-attempted', kernelChecked: false },
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_STRICT_RUNTIME: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
