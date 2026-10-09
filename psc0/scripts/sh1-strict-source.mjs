import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { inspectOriginalIrCarrier } from './original-ir-carrier.mjs';
import { describeOriginalIrCheckReport } from './original-ir-inventory.mjs';
import { sh1GrammarProfile } from './sh1-grammar-conformance.mjs';

const digest = (value) => createHash('sha256').update(value).digest('hex');
const sourceOptionKeys = ['maxModules', 'maxInputBytes', 'maxSyntaxSteps', 'maxTypeSteps', 'maxTermSteps'];

function count(value, name) {
  assert(typeof value === 'bigint' && value >= 0n && value <= BigInt(Number.MAX_SAFE_INTEGER),
    'PSC0_SH1_SOURCE_REPORT_COUNT: ' + name);
  return Number(value);
}

function tag(value) {
  if (value === null || typeof value !== 'object') return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    const result = value[symbol];
    if (typeof result === 'string') return result;
  }
  return undefined;
}

function list(compiler, values) {
  return values.reduceRight((tail, head) => compiler.List.cons(head, tail), compiler.List.nil());
}

function readOwnedList(compiler, value, limit, label) {
  const nil = compiler.List.nil();
  const symbol = Object.getOwnPropertySymbols(nil).find((key) => nil[key] === 'nil');
  assert(symbol, 'PSC0_SH1_SOURCE_LIST_NAMESPACE');
  const seen = new Set();
  const result = [];
  for (;;) {
    assert(value !== null && typeof value === 'object' && Object.hasOwn(value, symbol),
      'PSC0_SH1_SOURCE_LIST_SHAPE: ' + label);
    if (value[symbol] === 'nil') return result;
    assert(value[symbol] === 'cons' && !seen.has(value) && result.length < limit,
      'PSC0_SH1_SOURCE_LIST_LIMIT: ' + label);
    seen.add(value);
    result.push(value.head);
    value = value.tail;
  }
}

// This is host carrier validation, not a second source parser or capability checker.
// The portable API validates the actual imports, AST, typing and target policy.
function requireText(value, maxUnits, label) {
  assert(typeof value === 'string', 'PSC0_SH1_SOURCE_TEXT: ' + label);
  assert(value.length <= maxUnits, 'PSC0_SH1_SOURCE_TEXT_LIMIT: ' + label);
  for (let index = 0; index < value.length; index++) {
    const unit = value.charCodeAt(index);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      const next = value.charCodeAt(index + 1);
      assert(next >= 0xdc00 && next <= 0xdfff, 'PSC0_SH1_SOURCE_UNICODE: ' + label);
      index++;
    } else assert(unit < 0xdc00 || unit > 0xdfff, 'PSC0_SH1_SOURCE_UNICODE: ' + label);
  }
}

export function requireStrictSourceApi(compiler) {
  for (const name of ['psCompilerSh1TypeScriptSources', 'psSh1SourceInput',
    'psSh1DefaultSourceOptions', 'psSh1SourceOptionsWithLimits',
    'psIrCheckDefaultOptions', 'psIrCheckOptionsWithLimits', 'PsCompilerSourceKind',
    'List', 'Except', 'psSh1CheckTarget']) {
    assert(name in compiler, 'PSC0_SH1_STRICT_API_REQUIRED: ' + name);
  }
}

export function strictSourceOptions(compiler, overrides = {}) {
  requireStrictSourceApi(compiler);
  for (const key of Object.keys(overrides)) assert(sourceOptionKeys.includes(key),
    'PSC0_SH1_SOURCE_OPTION: ' + key);
  const values = sourceOptionKeys.map((key) => {
    const value = overrides[key] ?? compiler.psSh1DefaultSourceOptions[key];
    if (typeof value === 'number') {
      assert(Number.isSafeInteger(value) && value >= 0, 'PSC0_SH1_SOURCE_OPTION: ' + key);
      return BigInt(value);
    }
    count(value, key);
    return value;
  });
  return compiler.psSh1SourceOptionsWithLimits(...values);
}

export function strictSourceFailure(error) {
  const stage = tag(error);
  if (stage === 'source') {
    const source = error.error;
    if (tag(source) === 'policy') {
      const finding = source.finding;
      const span = tag(finding.span) === 'some' ? finding.span.value : null;
      const position = (value) => value ? Object.fromEntries(
        Object.entries(value).map(([key, item]) => [key, typeof item === 'bigint' ? count(item, key) : item])) : null;
      return { stage, code: finding.code, detail: finding.detail,
        moduleName: finding.moduleName, owner: finding.owner,
        span: span ? { start: position(span.start), stop: position(span.stop) } : null };
    }
    return { stage, code: 'source-compiler', moduleName: source.moduleName ?? null,
      compilerStage: tag(source.error), detail: 'The owned frontend or existing preparation refused the source.' };
  }
  if (stage === 'target') {
    const finding = error.error;
    return { stage, code: finding.code, detail: finding.detail,
      owner: finding.owner, path: finding.path, visitedSteps: count(finding.visitedSteps, 'visitedSteps') };
  }
  if (stage === 'checkedEmit') return { stage, code: 'checked-emission-refused',
    detail: tag(error.error) ?? 'unknown-check-error' };
  return { stage: stage ?? 'unknown', code: 'strict-source-compilation-refused',
    compilerStage: tag(error.error), detail: 'Atomic source compilation did not produce an artifact.' };
}

function ownExcept(compiler, result) {
  const sample = compiler.Except.ok(undefined);
  const symbol = Object.getOwnPropertySymbols(sample).find((key) => sample[key] === 'ok');
  assert(symbol && result && typeof result === 'object' && Object.hasOwn(result, symbol),
    'PSC0_SH1_STRICT_RESULT_NAMESPACE');
  if (result[symbol] === 'error') {
    const failure = strictSourceFailure(result.error);
    const error = new Error('PSC0_SH1_STRICT_SOURCE_REJECTED: ' + JSON.stringify(failure));
    error.strictFailure = failure;
    throw error;
  }
  assert.equal(result[symbol], 'ok', 'PSC0_SH1_STRICT_RESULT');
  return result.value;
}

export function strictSourceInputsFromClosure(closure) {
  return closure.ordered.map(({ path: sourcePath, source }) => {
    const match = /^packages\/[a-z0-9-]+\/src\/(Ps\/[^.]+(?:\/[^.]+)*)\.(lean|ps)$/u.exec(sourcePath);
    assert(match, 'PSC0_SH1_SOURCE_MODULE_PATH: ' + sourcePath);
    return { moduleName: match[1].split('/'), source, path: sourcePath };
  });
}

// Only this function invokes the source-owned atomic API. No caller-supplied
// prepared object, original IR, report or accepted flag is an input.
export function compileStrictSources(compiler, inputs, {
  compilerSha256, sourceKind = 'lean', sourceOptions, irOptions,
} = {}) {
  requireStrictSourceApi(compiler);
  assert(/^[a-f0-9]{64}$/u.test(compilerSha256 ?? ''), 'PSC0_SH1_SOURCE_COMPILER_IDENTITY');
  assert(['lean', 'ps'].includes(sourceKind), 'PSC0_SH1_SOURCE_KIND');
  const options = sourceOptions ?? compiler.psSh1DefaultSourceOptions;
  const checkOptions = irOptions ?? compiler.psIrCheckDefaultOptions;
  // Independent host ingress ceilings protect JS carrier traversal itself.
  // Portable option exhaustion retains its own source-policy diagnostics.
  assert(Array.isArray(inputs) && inputs.length <= 16384, 'PSC0_SH1_SOURCE_INPUT_CARRIER');
  let bytes = 0;
  const manifest = inputs.map((input, index) => {
    assert(input && Array.isArray(input.moduleName) && input.moduleName.length <= 1024,
      'PSC0_SH1_SOURCE_MODULE_CARRIER: ' + index);
    requireText(input.source, 67108864, 'source:' + index);
    for (const segment of input.moduleName) requireText(segment, 1048576, 'module:' + index);
    bytes += Buffer.byteLength(input.source) +
      input.moduleName.reduce((sum, segment) => sum + Buffer.byteLength(segment), 0);
    assert(bytes <= 67108864, 'PSC0_SH1_SOURCE_INPUT_CARRIER_BYTES');
    return { moduleName: [...input.moduleName], sourceSha256: digest(input.source),
      sourceBytes: Buffer.byteLength(input.source) };
  });
  const ownedInputs = list(compiler, inputs.map(({ moduleName, source }) =>
    compiler.psSh1SourceInput(list(compiler, moduleName), source)));
  const kind = sourceKind === 'lean' ? compiler.PsCompilerSourceKind.lean
    : compiler.PsCompilerSourceKind.proofScript;
  const atomic = ownExcept(compiler,
    compiler.psCompilerSh1TypeScriptSources(options, checkOptions, kind, ownedInputs));
  assert.equal(atomic.strictSh1Qualified, false, 'PSC0_SH1_UNEARNED_STRICT_CLAIM');
  assert.equal(atomic.semanticContractQualified, false, 'PSC0_SH1_UNEARNED_SEMANTIC_CLAIM');
  assert.equal(atomic.providerChecked, false, 'PSC0_SH1_UNEARNED_PROVIDER_CLAIM');
  assert.equal(typeof atomic.typeScript, 'string');
  assert.equal(typeof atomic.admissions, 'string');
  const policy = atomic.sourcePolicy;
  assert.equal(policy.profile, 'PSC0-SH/1');
  assert.equal(policy.enforcementVersion, 1n);
  assert.equal(policy.accepted, true);
  assert.equal(policy.traversalComplete, true);
  assert.equal(policy.strictSh1Qualified, false);
  assert.equal(tag(policy.sourceKind), tag(kind));
  assert.equal(count(policy.moduleCount, 'moduleCount'), inputs.length);
  assert.equal(count(policy.inputBytes, 'inputBytes'), bytes);
  const actualOptions = Object.fromEntries(sourceOptionKeys.map((key) => [key, count(policy.options[key], key)]));
  assert.deepEqual(actualOptions, Object.fromEntries(sourceOptionKeys.map((key) => [key, count(options[key], key)])));
  const parsedModules = readOwnedList(compiler, atomic.parsedModules, inputs.length, 'parsed modules');
  assert.equal(parsedModules.length, inputs.length);
  parsedModules.forEach((parsed, index) => assert.deepEqual(
    readOwnedList(compiler, parsed.moduleName, 1024, 'parsed module name'), inputs[index].moduleName,
    'PSC0_SH1_PARSED_MODULE_ORDER'));
  const target = atomic.targetPolicy;
  assert.equal(target.policy, 'psc0-sh1-ts-target/1');
  assert.equal(target.accepted, true);
  assert.equal(target.traversalComplete, true);
  // The IR is produced inside the portable call, never supplied by this host.
  // This readback is after atomic emission and is recorded as such.
  const carrier = inspectOriginalIrCarrier(compiler, atomic.originalIr);
  assert.equal(carrier.accepted, true, 'PSC0_SH1_OWNED_IR_CARRIER_READBACK');
  const irInventory = describeOriginalIrCheckReport(compiler, atomic.checkReport, {
    compilerSha256, carrier, maxSteps: count(checkOptions.maxSteps, 'maxSteps'),
    typeSteps: checkOptions.maxTypeSteps, maxFindings: count(checkOptions.maxFindings, 'maxFindings'),
    carrierObservation: 'after-atomic-source-emission',
  });
  assert.equal(irInventory.runtimeIrTypingAccepted, true);
  assert.equal(irInventory.traversalComplete, true);
  const evidence = {
    schemaVersion: 1, evidence: 'portable-atomic-source-and-target-enforcement',
    compilerSha256, sourceKind, sourceInputs: manifest,
    sourceInputsSha256: digest(JSON.stringify(manifest)),
    sourceGrammar: sh1GrammarProfile,
    sourcePolicy: { profile: policy.profile, enforcementVersion: count(policy.enforcementVersion, 'enforcementVersion'),
      sourceKind, options: actualOptions, moduleCount: inputs.length,
      sourceBytes: count(policy.sourceBytes, 'sourceBytes'), inputBytes: bytes,
      importCount: count(policy.importCount, 'importCount'),
      stats: Object.fromEntries(['visitedSteps', 'typeSteps', 'termSteps', 'declarationCount', 'theoremCount']
        .map((key) => [key, count(policy.stats[key], key)])),
      accepted: true, traversalComplete: true, strictSh1Qualified: false },
    targetPolicy: { policy: target.policy, accepted: true, traversalComplete: true,
      visitedSteps: count(target.visitedSteps, 'visitedSteps') },
    originalIr: { accepted: true, traversalComplete: true, findingCount: irInventory.findingCount,
      expressions: irInventory.counts.expressions, visitedSteps: irInventory.visitedNodes,
      sameOriginalIrCheckedBeforeEmission: true, carrierObservation: irInventory.carrierObservation },
    sourceOrigins: { actualParsedModulesRetained: parsedModules.length,
      semanticCorrespondenceDischarged: false },
    artifacts: { typescriptSha256: digest(atomic.typeScript), admissionsSha256: digest(atomic.admissions) },
    preparationCount: 1, portableIrCheckCount: 1,
    strictSh1Qualified: false, semanticContractQualified: false, providerChecked: false,
  };
  return { ...atomic, irInventory, evidence };
}
