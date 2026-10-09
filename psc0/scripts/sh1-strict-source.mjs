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

// Snapshot caller option primitives before inspecting any source. The ordinary
// constructor functions only build owned records; they do not parse or compile.
// Preserve the existing count contracts and valid zero limits. The IR type-work
// budget is any nonnegative bigint, without a new safe-integer ceiling.
function snapshotStrictOptions(compiler, sourceOptions, irOptions) {
  const source = sourceOptions ?? compiler.psSh1DefaultSourceOptions;
  const ir = irOptions ?? compiler.psIrCheckDefaultOptions;
  const sourceValues = sourceOptionKeys.map((key) => {
    const value = source[key];
    count(value, 'sourceOptions.' + key);
    return value;
  });
  const maxSteps = ir.maxSteps;
  const maxTypeSteps = ir.maxTypeSteps;
  const maxFindings = ir.maxFindings;
  count(maxSteps, 'irOptions.maxSteps');
  count(maxFindings, 'irOptions.maxFindings');
  assert(typeof maxTypeSteps === 'bigint' && maxTypeSteps >= 0n,
    'PSC0_SH1_IR_OPTION: maxTypeSteps');
  return {
    source: compiler.psSh1SourceOptionsWithLimits(...sourceValues),
    ir: compiler.psIrCheckOptionsWithLimits(maxSteps, maxTypeSteps, maxFindings),
  };
}

// Capture caller-owned arrays and getters once, before constructing evidence or
// portable input. Fixed carrier lengths bound these reads. All later source and
// identity observations use only the captured strings and private plain records;
// a caller getter cannot substitute different bytes between hashing and emission.
function snapshotStrictInputs(inputs) {
  assert(Array.isArray(inputs), 'PSC0_SH1_SOURCE_INPUT_CARRIER');
  const inputCount = inputs.length;
  assert(Number.isSafeInteger(inputCount) && inputCount >= 0 && inputCount <= 16384,
    'PSC0_SH1_SOURCE_INPUT_CARRIER');
  const captured = [];
  let bytes = 0;
  for (let index = 0; index < inputCount; index++) {
    const input = inputs[index];
    assert(input, 'PSC0_SH1_SOURCE_MODULE_CARRIER: ' + index);
    const callerModuleName = input.moduleName;
    assert(Array.isArray(callerModuleName), 'PSC0_SH1_SOURCE_MODULE_CARRIER: ' + index);
    const segmentCount = callerModuleName.length;
    assert(Number.isSafeInteger(segmentCount) && segmentCount >= 0 && segmentCount <= 1024,
      'PSC0_SH1_SOURCE_MODULE_CARRIER: ' + index);
    const moduleName = [];
    let moduleBytes = 0;
    for (let segmentIndex = 0; segmentIndex < segmentCount; segmentIndex++) {
      const segment = callerModuleName[segmentIndex];
      requireText(segment, 1048576, 'module:' + index);
      moduleName.push(segment);
      moduleBytes += Buffer.byteLength(segment);
    }
    const source = input.source;
    requireText(source, 67108864, 'source:' + index);
    bytes += moduleBytes + Buffer.byteLength(source);
    assert(bytes <= 67108864, 'PSC0_SH1_SOURCE_INPUT_CARRIER_BYTES');
    captured.push({ moduleName, source });
  }
  return { inputs: captured, bytes };
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
    if (tag(source) === 'origin') {
      const failure = source.error;
      const segments = [];
      let names = failure.sourceName.segments;
      const seen = new Set();
      while (tag(names) === 'cons') {
        assert(!seen.has(names), 'PSC0_SH1_ORIGIN_ERROR_NAME_CYCLE');
        seen.add(names);
        segments.push(names.head); names = names.tail;
      }
      assert.equal(tag(names), 'nil', 'PSC0_SH1_ORIGIN_ERROR_NAME');
      return { stage, code: 'source-elaboration', moduleName: source.moduleName,
        compilerStage: 'elaboration', detail: tag(failure.error) ?? 'elaboration-refused',
        owner: segments.join('.'), sourceIndex: count(failure.sourceIndex, 'sourceIndex'),
        phase: tag(failure.phase), span: originSpan(failure.span, Number.MAX_SAFE_INTEGER, 'elaboration error') };
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


function originPosition(value, label) {
  return Object.fromEntries(['byteOffset', 'line', 'column']
    .map((key) => [key, count(value[key], label + '.' + key)]));
}

function originSpan(value, sourceBytes, label) {
  const result = { start: originPosition(value.start, label + '.start'),
    stop: originPosition(value.stop, label + '.stop') };
  assert(result.start.byteOffset <= result.stop.byteOffset &&
    result.stop.byteOffset <= sourceBytes, 'PSC0_SH1_ORIGIN_SPAN: ' + label);
  assert(result.start.line > 0 && result.stop.line > 0 &&
    result.start.column > 0 && result.stop.column > 0,
  'PSC0_SH1_ORIGIN_POSITION: ' + label);
  return result;
}

// Preserve string versus numeric name components; display strings alone cannot
// establish the identity of a generated normalization worker. These names come
// from the finite source-owned result; cycle detection prevents revisiting it
// without adding a declaration-name limit to the source language.
function originCoreName(value) {
  const parts = [];
  const seen = new Set();
  for (;;) {
    assert(value && typeof value === 'object' && !seen.has(value),
      'PSC0_SH1_ORIGIN_CORE_NAME');
    seen.add(value);
    const kind = tag(value);
    if (kind === 'anonymous') return parts.reverse();
    assert(kind === 'str' || kind === 'num', 'PSC0_SH1_ORIGIN_CORE_NAME_TAG');
    if (kind === 'num') assert(typeof value.value === 'bigint' && value.value >= 0n,
      'PSC0_SH1_ORIGIN_CORE_NAME_NUMBER');
    const component = kind === 'str' ? value.value : value.value.toString();
    assert.equal(typeof component, 'string');
    parts.push([kind, component]);
    value = value.parent;
  }
}

// Post-emission observation of a finite graph already built by this compiler.
// The visited set handles shared nodes and cycles; this is not admission of an
// arbitrary caller graph or a global wall-clock/heap bound.
function originSyntaxSpans(roots, sourceBytes) {
  const pending = [...roots];
  const seen = new Set();
  while (pending.length > 0) {
    const value = pending.pop();
    if (value === null || typeof value !== 'object' || seen.has(value)) continue;
    seen.add(value);
    if (Object.hasOwn(value, 'span')) originSpan(value.span, sourceBytes, 'worker syntax');
    for (const child of Object.values(value)) {
      if (child !== null && typeof child === 'object') pending.push(child);
    }
  }
}

function originStableRole(declaration) {
  switch (tag(declaration)) {
    case 'inductiveDecl': return declaration.info.isStructure ? 'structureType' : 'inductiveType';
    case 'constructorDecl': return 'constructor';
    case 'recursorDecl': return 'recursor';
    default: return 'sourceDeclaration';
  }
}

// Readback of actual data from this synchronous source-owned call. This verifies
// declaration association and spans, not Core/IR semantic preservation. It does
// not invoke parsing, elaboration, erasure or a second IR checker.
function observeStrictOrigins(compiler, atomic, inputs, parsedModules) {
  const modules = readOwnedList(compiler, atomic.origins, inputs.length, 'origin modules');
  assert.equal(modules.length, inputs.length, 'PSC0_SH1_ORIGIN_MODULE_COUNT');
  const sourceDeclarationCount = count(atomic.sourcePolicy.stats.declarationCount, 'source declarations');
  const syntaxSteps = count(atomic.sourcePolicy.stats.visitedSteps, 'source syntax steps');
  // A value declaration contributes at most a worker/public pair. A data
  // declaration adds its explicitly visited constructors plus type/recursor.
  // Derive a broad bound from the actual traversal, not default source limits.
  const coreLimit = Math.min(Number.MAX_SAFE_INTEGER, syntaxSteps + 2 * sourceDeclarationCount);
  const declarations = readOwnedList(compiler, atomic.prepared.declarations,
    coreLimit, 'prepared declarations for origins');
  let coreIndex = 0;
  let sourceCount = 0;
  let normalizationCount = 0;
  const records = modules.map((module, moduleIndex) => {
    const sourceBytes = Buffer.byteLength(inputs[moduleIndex].source);
    const moduleName = readOwnedList(compiler, module.moduleName, 1024, 'origin module name');
    assert.deepEqual(moduleName, inputs[moduleIndex].moduleName, 'PSC0_SH1_ORIGIN_MODULE_ORDER');
    const coreStart = count(module.coreStart, 'origin coreStart');
    assert.equal(coreStart, coreIndex, 'PSC0_SH1_ORIGIN_CORE_START');
    const sources = readOwnedList(compiler, parsedModules[moduleIndex].sourceModule.declarations,
      sourceDeclarationCount, 'parsed declarations for origins');
    const batches = readOwnedList(compiler, module.batches, sources.length, 'origin batches');
    assert.equal(batches.length, sources.length, 'PSC0_SH1_ORIGIN_SOURCE_COUNT');
    const batchRecords = batches.map((batch, sourceIndex) => {
      const source = sources[sourceIndex];
      assert.equal(count(batch.sourceIndex, 'sourceIndex'), sourceIndex, 'PSC0_SH1_ORIGIN_SOURCE_ORDER');
      const sourceName = readOwnedList(compiler, batch.sourceName.segments, Infinity, 'origin source name');
      assert.deepEqual(sourceName, readOwnedList(compiler, source.name.segments, Infinity, 'parsed source name'));
      assert.deepEqual(originSpan(batch.sourceName.span, sourceBytes, 'origin name'),
        originSpan(source.name.span, sourceBytes, 'parsed name'), 'PSC0_SH1_ORIGIN_NAME_SPAN');
      const span = originSpan(batch.span, sourceBytes, 'origin declaration');
      assert.deepEqual(span, originSpan(source.span, sourceBytes, 'parsed declaration'),
        'PSC0_SH1_ORIGIN_DECLARATION_SPAN');
      const members = readOwnedList(compiler, batch.members, declarations.length, 'origin members');
      assert(members.length > 0, 'PSC0_SH1_ORIGIN_EMPTY_BATCH');
      const normalKind = tag(batch.normalization);
      assert(normalKind === 'none' || normalKind === 'some', 'PSC0_SH1_ORIGIN_NORMALIZATION_OPTION');
      const normalized = normalKind === 'some';
      const firstCore = coreIndex;
      const memberRecords = members.map((member, memberIndex) => {
        assert.equal(count(member.index, 'member index'), memberIndex, 'PSC0_SH1_ORIGIN_MEMBER_ORDER');
        assert(coreIndex < declarations.length, 'PSC0_SH1_ORIGIN_EXTRA_CORE_MEMBER');
        const declaration = declarations[coreIndex++];
        const name = originCoreName(member.name);
        assert.deepEqual(name, originCoreName(declaration.name ?? declaration.info.name),
          'PSC0_SH1_ORIGIN_MEMBER_IDENTITY');
        const role = tag(member.role);
        const expectedRole = normalized ? (memberIndex === 0 ? 'normalizedWorker' : 'publicWrapper')
          : originStableRole(declaration);
        assert.equal(role, expectedRole, 'PSC0_SH1_ORIGIN_MEMBER_ROLE');
        if (normalized) assert.equal(tag(declaration), 'definitionDecl', 'PSC0_SH1_ORIGIN_NORMALIZED_CORE_KIND');
        return { index: memberIndex, name, role };
      });
      let normalization = null;
      if (normalized) {
        normalizationCount++;
        assert.equal(members.length, 2, 'PSC0_SH1_ORIGIN_NORMALIZED_BATCH');
        const origin = batch.normalization.value;
        assert.deepEqual(originSpan(origin.span, sourceBytes, 'normalization'), span);
        const plan = origin.plan;
        const ids = (values, label) => readOwnedList(compiler, values, syntaxSteps, label)
          .map((id) => String(count(id, label)));
        const functionName = originCoreName(plan.functionName);
        const workerName = originCoreName(origin.workerName);
        assert.deepEqual(functionName, memberRecords[1].name, 'PSC0_SH1_ORIGIN_PUBLIC_IDENTITY');
        assert.deepEqual(functionName, sourceName.map((value) => ['str', value]),
          'PSC0_SH1_ORIGIN_SOURCE_IDENTITY');
        assert.deepEqual(workerName, memberRecords[0].name, 'PSC0_SH1_ORIGIN_WORKER_IDENTITY');
        const parameterIds = ids(plan.parameterIds, 'parameter ids');
        const explicitIds = ids(plan.explicitIds, 'explicit ids');
        const majorId = String(count(plan.majorId, 'major id'));
        const generalizedIds = ids(plan.generalizedIds, 'generalized ids');
        const parameterSet = new Set(parameterIds);
        const explicitSet = new Set(explicitIds);
        assert.equal(parameterSet.size, parameterIds.length);
        assert(explicitIds.every((id) => parameterSet.has(id)) && explicitSet.has(majorId));
        // The scanner collects changed explicit arguments and can encounter the
        // same parameter in several branches. Preserve that actual list.
        assert(generalizedIds.length > 0 &&
          generalizedIds.every((id) => explicitSet.has(id) && id !== majorId));
        const workerBinders = readOwnedList(compiler, origin.workerBinders, parameterIds.length, 'worker binders');
        assert.equal(tag(origin.workerType), 'forallE', 'PSC0_SH1_ORIGIN_WORKER_TYPE_SYNTAX');
        assert.equal(tag(origin.workerValue), 'matchE', 'PSC0_SH1_ORIGIN_WORKER_VALUE_SYNTAX');
        originSyntaxSpans([origin.workerBinders, origin.workerType, origin.workerValue], sourceBytes);
        normalization = { functionName, workerName, parameterIds, explicitIds, majorId, generalizedIds,
          workerBinderCount: workerBinders.length, workerTypeKind: 'forallE', workerValueKind: 'matchE',
          actualWorkerSyntaxRetained: true };
      }
      sourceCount++;
      return { sourceIndex, sourceName, span, coreStart: firstCore, members: memberRecords, normalization };
    });
    return { moduleName, coreStart, batches: batchRecords };
  });
  assert.equal(coreIndex, declarations.length, 'PSC0_SH1_ORIGIN_UNASSOCIATED_CORE_MEMBER');
  assert.equal(sourceCount, sourceDeclarationCount);
  const observations = { policy: 'psc0-declaration-origins/1',
    actualParsedModulesRetained: parsedModules.length, moduleCount: records.length,
    sourceDeclarationCount: sourceCount, coreDeclarationCount: coreIndex, normalizationCount,
    modules: records, semanticCorrespondenceDischarged: false };
  return { ...observations, observationsSha256: digest(JSON.stringify(observations)),
    observationBoundary: 'after-atomic-source-emission' };
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
  const capturedOptions = snapshotStrictOptions(compiler, sourceOptions, irOptions);
  const options = capturedOptions.source;
  const checkOptions = capturedOptions.ir;
  // Independent host ingress ceilings protect JS carrier traversal itself.
  // Portable option exhaustion retains its own source-policy diagnostics.
  const { inputs: capturedInputs, bytes } = snapshotStrictInputs(inputs);
  const manifest = capturedInputs.map(({ moduleName, source }) => ({
    moduleName: [...moduleName], sourceSha256: digest(source),
    sourceBytes: Buffer.byteLength(source),
  }));
  const ownedInputs = list(compiler, capturedInputs.map(({ moduleName, source }) =>
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
  assert.equal(count(policy.moduleCount, 'moduleCount'), capturedInputs.length);
  assert.equal(count(policy.inputBytes, 'inputBytes'), bytes);
  const actualOptions = Object.fromEntries(sourceOptionKeys.map((key) => [key, count(policy.options[key], key)]));
  assert.deepEqual(actualOptions, Object.fromEntries(sourceOptionKeys.map((key) => [key, count(options[key], key)])));
  const parsedModules = readOwnedList(compiler, atomic.parsedModules, capturedInputs.length, 'parsed modules');
  assert.equal(parsedModules.length, capturedInputs.length);
  parsedModules.forEach((parsed, index) => assert.deepEqual(
    readOwnedList(compiler, parsed.moduleName, 1024, 'parsed module name'), capturedInputs[index].moduleName,
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
      sourceKind, options: actualOptions, moduleCount: capturedInputs.length,
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
    sourceOrigins: observeStrictOrigins(compiler, atomic, capturedInputs, parsedModules),
    artifacts: { typescriptSha256: digest(atomic.typeScript), admissionsSha256: digest(atomic.admissions) },
    preparationCount: 1, canonicalAdmissionEncodingCount: 1,
    environmentReconstructionCount: 0, portableIrCheckCount: 1,
    strictSh1Qualified: false, semanticContractQualified: false, providerChecked: false,
  };
  return { ...atomic, irInventory, evidence };
}
