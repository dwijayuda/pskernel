import { inspectOriginalIrCarrier } from './original-ir-carrier.mjs';

// Serialize portable checker evidence. This host layer supplies no typing rules.
function checkedCount(value, name) {
  if (typeof value !== 'bigint' || value < 0n || value > BigInt(Number.MAX_SAFE_INTEGER)) {
    throw new Error('PSC0_IR_CHECK_REPORT_COUNT: ' + name);
  }
  return Number(value);
}

function reportList(compiler, value, limit, label) {
  const symbol = symbolFrom(compiler.List.nil(), 'nil');
  const values = [];
  const seen = new Set();
  for (;;) {
    if (value === null || typeof value !== 'object' || !Object.hasOwn(value, symbol)) {
      throw new Error('PSC0_IR_CHECK_REPORT_LIST: ' + label);
    }
    if (value[symbol] === 'nil') return values;
    if (value[symbol] !== 'cons' || values.length >= limit || seen.has(value)) {
      throw new Error('PSC0_IR_CHECK_REPORT_LIST_BOUND: ' + label);
    }
    seen.add(value);
    values.push(value.head);
    value = value.tail;
  }
}

function reportTypeList(compiler, value, limit) {
  const symbol = symbolFrom(compiler.List.nil(), 'nil');
  const values = [];
  const seen = new Set();
  for (;;) {
    if (value === null || typeof value !== 'object' || !Object.hasOwn(value, symbol)) {
      throw new Error('PSC0_IR_CHECK_REPORT_TYPE_LIST');
    }
    if (value[symbol] === 'nil') return { values, truncated: false };
    if (value[symbol] !== 'cons' || seen.has(value)) throw new Error('PSC0_IR_CHECK_REPORT_TYPE_LIST_SHAPE');
    if (values.length >= limit) return { values, truncated: true };
    seen.add(value);
    values.push(value.head);
    value = value.tail;
  }
}

function reportFindings(compiler, report, maxFindings) {
  const typeSymbol = symbolFrom(compiler.PsVerifiedIrType.unknown, 'unknown');
  const primitiveSymbol = symbolFrom(compiler.PsVerifiedIrPrimitiveType.nat, 'nat');
  const optionSymbol = symbolFrom(compiler.Option.none(), 'none');
  let detailNodes = 0;
  const encodeType = (root) => {
    const result = { value: null };
    const work = [{ value: root, parent: result, key: 'value' }];
    while (work.length) {
      const { value, parent, key } = work.pop();
      if (++detailNodes > 100000) {
        parent[key] = { detailOmitted: 'diagnostic-type-node-limit' };
        continue;
      }
      const tag = value?.[typeSymbol];
      if (tag === 'unknown') parent[key] = { kind: tag };
      else if (tag === 'typeParameter') parent[key] = { kind: tag, name: value.name };
      else if (tag === 'primitive') parent[key] = { kind: tag, name: value.name?.[primitiveSymbol] };
      else if (tag === 'function' || tag === 'named') {
        const field = tag === 'function' ? 'parameters' : 'arguments';
        const children = reportTypeList(compiler, value[field],
          Math.max(0, 100000 - detailNodes - work.length - (tag === 'function' ? 1 : 0)));
        const output = tag === 'function' ? { kind: tag, parameters: [], result: null } :
          { kind: tag, name: value.name, arguments: [] };
        parent[key] = output;
        if (tag === 'function') {
          if (detailNodes + work.length < 100000) work.push({ value: value.result, parent: output, key: 'result' });
          else output.result = { detailOmitted: 'diagnostic-type-node-limit' };
        }
        children.values.forEach((child, index) => work.push({ value: child, parent: output[field], key: index }));
        if (children.truncated) output[field][children.values.length] = { detailOmitted: 'diagnostic-type-node-limit' };
      } else throw new Error('PSC0_IR_CHECK_REPORT_TYPE');
    }
    return result.value;
  };
  const optionalType = (value) => {
    if (value?.[optionSymbol] === 'none') return null;
    if (value?.[optionSymbol] === 'some') return encodeType(value.value);
    throw new Error('PSC0_IR_CHECK_REPORT_OPTION');
  };
  return reportList(compiler, report.findings, maxFindings, 'findings').map((finding) => {
    for (const key of ['code', 'detail', 'owner', 'path']) {
      if (typeof finding[key] !== 'string') throw new Error('PSC0_IR_CHECK_REPORT_FIELD: ' + key);
    }
    return { code: finding.code, detail: finding.detail, owner: finding.owner, path: finding.path,
      at: finding.owner + '/' + finding.path,
      expected: optionalType(finding.expected), actual: optionalType(finding.actual) };
  });
}

export function inventoryOriginalIr(compiler, module, {
  compilerSha256, maxFindings = 1000, maxNodes = 5000000,
  maxSteps = maxNodes, maxTypeSteps, legacyBoundary,
} = {}) {
  if (!/^[a-f0-9]{64}$/u.test(compilerSha256 ?? '')) throw new Error('PSC0_IR_INVENTORY_COMPILER_IDENTITY');
  if (!Number.isSafeInteger(maxFindings) || maxFindings < 0 ||
      !Number.isSafeInteger(maxNodes) || maxNodes < 1 ||
      !Number.isSafeInteger(maxSteps) || maxSteps < 0 ||
      (maxTypeSteps !== undefined && (!Number.isSafeInteger(maxTypeSteps) || maxTypeSteps < 0))) {
    throw new Error('PSC0_IR_INVENTORY_LIMIT');
  }
  if (typeof compiler.psCheckVerifiedIrModule !== 'function') {
    if (!legacyBoundary || !['immutable-seed-recovery', 'selected-authoring-seed'].includes(legacyBoundary.kind) ||
        legacyBoundary.executingCompilerSha256 !== compilerSha256 ||
        !/^[a-f0-9]{40}$/u.test(legacyBoundary.executingSourceRef ?? '') ||
        typeof legacyBoundary.reason !== 'string' || legacyBoundary.reason.length === 0) {
      throw new Error('PSC0_IR_PORTABLE_CHECKER_REQUIRED');
    }
    const legacy = inventoryLegacyOriginalIr(compiler, module, {
      compilerSha256, maxFindings: Math.max(1, maxFindings), maxNodes,
    });
    return { ...legacy, runtimeIrTypingAccepted: false,
      portableChecker: { status: 'unavailable-at-explicit-seed-boundary', boundary: legacyBoundary },
      notes: [...legacy.notes, 'The pinned pre-checker seed is an explicit bootstrap boundary; this is not a portable pass.'] };
  }
  const carrier = inspectOriginalIrCarrier(compiler, module, { maxNodes });
  if (!carrier.accepted) {
    const finding = { ...carrier.finding, owner: 'module', path: carrier.finding.at, expected: null, actual: null };
    return {
      schemaVersion: 2, kind: 'psc0-original-ir-inventory', compilerSha256,
      status: 'rejected', strictSh1Qualified: false, runtimeIrTypingAccepted: false,
      traversalComplete: false, visitedNodes: carrier.visitedNodes, carrier,
      counts: { expressions: 0 }, findingCount: 1,
      findingCounts: { [finding.code]: 1 }, findingCountsCoverage: 'all-findings',
      findings: maxFindings === 0 ? [] : [finding], omittedFindingDetails: maxFindings === 0 ? 1 : 0,
      portableChecker: { status: 'not-run-invalid-carrier' },
      unqualifiedObligations: ['Portable checking did not run because the host IR carrier is invalid.'],
    };
  }
  const typeSteps = maxTypeSteps === undefined ? compiler.psIrCheckDefaultOptions.maxTypeSteps : BigInt(maxTypeSteps);
  const options = compiler.psIrCheckOptionsWithLimits(BigInt(maxSteps), typeSteps, BigInt(maxFindings));
  const report = compiler.psCheckVerifiedIrModule(options, module);
  return describeOriginalIrCheckReport(compiler, report, {
    compilerSha256, carrier, maxFindings, maxSteps, typeSteps,
  });
}

// Diagnostic serialization only. This function does not check IR, authorize
// emission, or establish source/IR provenance. The atomic strict source API
// returns the report for its own checked IR; callers may describe that result
// without running a second type check or preparing the compiler again.
export function describeOriginalIrCheckReport(compiler, report, {
  compilerSha256, carrier, maxFindings, maxSteps, typeSteps,
  carrierObservation = 'before-portable-check',
}) {
  if (!/^[a-f0-9]{64}$/u.test(compilerSha256 ?? '') ||
      !carrier || carrier.accepted !== true ||
      !Number.isSafeInteger(maxFindings) || maxFindings < 0 ||
      !Number.isSafeInteger(maxSteps) || maxSteps < 0 ||
      typeof typeSteps !== 'bigint' || typeSteps < 0n) {
    throw new Error('PSC0_IR_CHECK_REPORT_CONTEXT');
  }
  if (typeof report?.accepted !== 'boolean' || typeof report?.traversalComplete !== 'boolean') {
    throw new Error('PSC0_IR_CHECK_REPORT_SHAPE');
  }
  const findingCount = checkedCount(report.findingCount, 'findingCount');
  const findings = reportFindings(compiler, report, maxFindings);
  if (findings.length > findingCount || (report.accepted && (!report.traversalComplete || findingCount !== 0))) {
    throw new Error('PSC0_IR_CHECK_REPORT_INVARIANT');
  }
  const findingCounts = {};
  for (const { code } of findings) findingCounts[code] = (findingCounts[code] ?? 0) + 1;
  return {
    schemaVersion: 2, kind: 'psc0-original-ir-inventory', compilerSha256,
    status: report.accepted ? 'runtime-ir-types-accepted' : 'rejected',
    strictSh1Qualified: false, runtimeIrTypingAccepted: report.accepted,
    traversalComplete: report.traversalComplete,
    visitedNodes: checkedCount(report.visitedSteps, 'visitedSteps'), carrier, carrierObservation,
    counts: { expressions: checkedCount(report.expressionCount, 'expressionCount') },
    findingCount, findingCounts,
    findingCountsCoverage: findingCount === findings.length ? 'all-findings' : 'retained-details-only',
    findings, omittedFindingDetails: findingCount - findings.length,
    portableChecker: {
      status: report.accepted ? 'accepted' : 'rejected',
      implementation: 'Ps.CompilerIr.Check.psCheckVerifiedIrModule',
      options: { maxSteps, maxTypeSteps: checkedCount(typeSteps, 'maxTypeSteps'), maxFindings },
    },
    coverage: [
      carrierObservation === 'before-portable-check'
        ? 'Canonical own-namespace JS carriers before portable code'
        : 'Host carrier readback of IR created and checked inside the atomic portable source API',
      'Portable module signatures, scoped type substitution and compositional expression typing',
      'The host report serializes portable diagnostics without a second semantic checker',
    ],
    unqualifiedObligations: [
      'Enabled primitive laws, text positions and bounds semantics beyond runtime typing',
      'Erasure preservation, evaluation order and backend semantic correspondence',
      'Import ABI qualification for unsupported external imports',
      'Strict SH/1 profile activation and provider decisions remain separate',
    ],
    notes: [
      'A capped diagnostics list does not cap the portable finding count.',
      'Findings count failed checking obligations; a type operation reports its first failure, not every malformed descendant.',
      'visitedNodes combines portable input preflight and dispatcher steps, each with its own maxSteps allowance.',
      'Structural IR paths identify owners and expressions; they are not original source line numbers.',
      'Runtime IR typing acceptance does not establish Core provider acceptance or strict SH/1.',
    ],
  };
}

// The historical diagnostic inventory is kept only for explicit immutable
// bootstrap boundaries. Current consumers require the portable checker above.
// Inventory the original PSC0 PsVerifiedIrModule. This is deliberately a host
// report, not a validated-IR wrapper or strict SH/1 acceptance gate.
// Model authority: packages/compiler-ir/src/Ps/CompilerIr/Model.lean.
// Intrinsic arities: Erasure/Expr.lean and BackendTs/Expr.lean on the PSC0 lane.

const INTRINSIC_ARITIES = Object.freeze({
  machineIntBinary: [0, 2], machineIntCompare: [0, 2],
  floatBinary: [0, 2], floatCompare: [0, 2],
  natAdd: [0, 2], natSub: [0, 2], natMul: [0, 2], natDiv: [0, 2],
  natMod: [0, 2], natEq: [0, 2], natNe: [0, 2], natLe: [0, 2], natLt: [0, 2],
  intOfNat: [0, 1], intRepr: [0, 1], intNegSucc: [0, 1], intNeg: [0, 1],
  intAdd: [0, 2], intSub: [0, 2], intMul: [0, 2], intEq: [0, 2],
  intLe: [0, 2], intLt: [0, 2],
  boolNot: [0, 1], boolAnd: [0, 2], boolOr: [0, 2], boolEq: [0, 2], boolNe: [0, 2],
  charOfNat: [0, 1], charToNat: [0, 1],
  stringPush: [0, 2], stringSingleton: [0, 1], stringLength: [0, 1],
  stringAppend: [0, 2], stringUtf8ByteSize: [0, 1], stringNext: [0, 2],
  stringGet: [0, 2], stringAtEnd: [0, 2], stringExtract: [0, 3], stringEq: [0, 2],
  arrayEmptyWithCapacity: [1, 1], arraySize: [1, 1], arrayPush: [1, 2],
  arrayGet: [1, 2], arrayGetD: [1, 3], arraySet: [1, 3],
  arraySetIfInBounds: [1, 3], arrayMap: [2, 2], arrayFoldl: [2, 5],
});

const PRIMITIVES = new Set([
  "nat", "int", "uint8", "uint16", "uint32", "uint64", "usize",
  "int8", "int16", "int32", "int64", "isize", "float", "float32",
  "bool", "char", "string", "unit",
]);

function symbolFrom(value, constructor) {
  if (value === null || typeof value !== "object") {
    throw new Error("PSC0_IR_INVENTORY_CONSTRUCTOR_SAMPLE: " + constructor);
  }
  const symbols = Object.getOwnPropertySymbols(value)
    .filter((symbol) => value[symbol] === constructor);
  if (symbols.length !== 1) {
    throw new Error("PSC0_IR_INVENTORY_CONSTRUCTOR_IDENTITY: " + constructor);
  }
  return symbols[0];
}

/**
 * Inspect live IR made by this exact compiler instance. Constructor identities
 * come from its exported model, not arbitrary string tags from another module.
 * Finding locations name the owning declaration/layout and deterministic IR
 * positions; this model has no source-origin field to report original lines.
 */
export function inventoryLegacyOriginalIr(
  compiler,
  module,
  { compilerSha256, maxFindings = 1000, maxNodes = 5000000 } = {},
) {
  if (!/^[a-f0-9]{64}$/u.test(compilerSha256 ?? "")) {
    throw new Error("PSC0_IR_INVENTORY_COMPILER_IDENTITY");
  }
  if (!Number.isSafeInteger(maxFindings) || maxFindings < 1 ||
      !Number.isSafeInteger(maxNodes) || maxNodes < 1) {
    throw new Error("PSC0_IR_INVENTORY_LIMIT");
  }
  const symbols = {
    list: symbolFrom(compiler.List.nil(), "nil"),
    type: symbolFrom(compiler.PsVerifiedIrType.unknown, "unknown"),
    primitive: symbolFrom(compiler.PsVerifiedIrPrimitiveType.nat, "nat"),
    expr: symbolFrom(compiler.PsVerifiedIrExpr.var("__inventory"), "var"),
    literal: symbolFrom(compiler.PsVerifiedIrLiteral.unit, "unit"),
    intrinsic: symbolFrom(compiler.PsVerifiedIrIntrinsic.natAdd, "natAdd"),
    machine: symbolFrom(compiler.PsVerifiedIrMachineIntegerType.uint8, "uint8"),
  };
  const findings = [];
  const findingCounts = {};
  const typeForms = {};
  const primitives = {};
  const expressionForms = {};
  const literalForms = {};
  const intrinsicUses = {};
  const counts = {
    imports: 0, structures: 0, inductives: 0, declarations: 0,
    constructors: 0, layoutFields: 0, typeParameters: 0, typePositions: 0,
    expressions: 0, listCells: 0, valueReferences: 0,
    callArityChecked: 0, callArityUnresolved: 0, shadowedBindings: 0,
  };
  let visitedNodes = 0;
  let complete = true;
  const limit = new Error("PSC0_IR_INVENTORY_NODE_LIMIT");
  const increment = (table, key) => { table[key] = (table[key] ?? 0) + 1; };
  function finding(code, at, detail) {
    increment(findingCounts, code);
    if (findings.length < maxFindings) findings.push({ code, at, detail });
  }
  function charge() {
    visitedNodes += 1;
    if (visitedNodes > maxNodes) throw limit;
  }
  function tag(value, kind, at) {
    if (value === null || typeof value !== "object" ||
        !Object.hasOwn(value, symbols[kind]) || typeof value[symbols[kind]] !== "string") {
      complete = false;
      finding("malformed-or-foreign-constructor", at, { expected: kind });
      return undefined;
    }
    return value[symbols[kind]];
  }
  function list(value, at) {
    const out = [];
    const seen = new WeakSet();
    let cursor = value;
    for (;;) {
      charge();
      const constructor = tag(cursor, "list", at);
      if (constructor === "nil") return out;
      if (constructor !== "cons" || seen.has(cursor)) {
        complete = false;
        if (constructor !== undefined) finding("malformed-or-cyclic-list", at, { constructor });
        return out;
      }
      seen.add(cursor);
      counts.listCells += 1;
      out.push(cursor.head);
      cursor = cursor.tail;
    }
  }
  function uniqueNames(items, nameOf, at, code) {
    const result = new Set();
    for (const item of items) {
      const name = nameOf(item);
      if (typeof name !== "string" || !name) {
        finding("malformed-name", at, { name: String(name) });
      } else if (result.has(name)) {
        finding(code, at, { name });
      }
      result.add(name);
    }
    return result;
  }
  const layouts = new Map();
  const globals = new Map();
  function typeParameters(value, at) {
    const items = list(value, at + "/typeParameters");
    counts.typeParameters += items.length;
    return uniqueNames(items, (item) => item.name, at, "duplicate-type-parameter");
  }
  function checkArity(actual, expected, at, kind) {
    if (actual !== expected) finding(kind, at, { expected, actual });
  }
  function checkType(root, scope, owner) {
    const pending = [{ type: root, at: owner }];
    while (pending.length) {
      charge();
      const { type, at } = pending.pop();
      counts.typePositions += 1;
      const constructor = tag(type, "type", at);
      increment(typeForms, constructor ?? "<malformed>");
      if (constructor === "unknown") {
        finding("unresolved-runtime-type", at, {});
      } else if (constructor === "typeParameter") {
        if (!scope.has(type.name)) finding("unscoped-type-parameter", at, { name: type.name });
      } else if (constructor === "primitive") {
        const primitive = tag(type.name, "primitive", at);
        increment(primitives, primitive ?? "<malformed>");
        if (!PRIMITIVES.has(primitive)) finding("unknown-primitive", at, { primitive });
      } else if (constructor === "function") {
        const parameters = list(type.parameters, at + "/parameters");
        pending.push({ type: type.result, at: at + "/result" });
        parameters.forEach((parameter, index) =>
          pending.push({ type: parameter, at: at + "/parameter[" + index + "]" }));
      } else if (constructor === "named") {
        const arguments_ = list(type.arguments, at + "/arguments");
        const layout = layouts.get(type.name);
        if (!layout) {
          // No implicit target-library allowance, including Array. An external
          // runtime type ledger would have to state and qualify that allowance.
          finding("named-type-without-module-layout", at, { name: type.name });
        } else {
          checkArity(arguments_.length, layout.typeParameters.size, at, "named-type-arity");
        }
        arguments_.forEach((argument, index) =>
          pending.push({ type: argument, at: at + "/argument[" + index + "]" }));
      } else if (constructor !== undefined) {
        complete = false;
        finding("unrecognized-type-form", at, { constructor });
      }
    }
  }
  function lookup(scope, name) {
    for (let cursor = scope; cursor; cursor = cursor.parent) {
      if (cursor.bindings.has(name)) return cursor.bindings.get(name);
    }
    return globals.get(name);
  }
  function extend(scope, parameters, at) {
    uniqueNames(parameters, (parameter) => parameter.name, at, "duplicate-local-binder");
    const bindings = new Map();
    for (const parameter of parameters) {
      if (lookup(scope, parameter.name)) counts.shadowedBindings += 1;
      bindings.set(parameter.name, { type: parameter.type, genericArity: 0, local: true });
    }
    return { parent: scope, bindings };
  }
  function checkTypeArguments(value, scope, at) {
    const arguments_ = list(value, at + "/typeArguments");
    arguments_.forEach((argument, index) => checkType(argument, scope, at + "/typeArgument[" + index + "]"));
    return arguments_;
  }
  function layoutFor(name, expectedKind, typeArguments, at) {
    const layout = layouts.get(name);
    if (!layout || layout.kind !== expectedKind) {
      finding("unresolved-layout-owner", at, { name, expectedKind });
      return undefined;
    }
    checkArity(typeArguments.length, layout.typeParameters.size, at, "layout-type-arity");
    return layout;
  }
  function fields(value, expected, at, positional) {
    const actual = list(value, at + "/fields");
    const names = uniqueNames(actual, (pair) => pair.fst, at, "duplicate-field");
    if (expected) {
      const wanted = expected.map((field) => field.name);
      for (const name of wanted) if (!names.has(name)) finding("missing-field", at, { name });
      for (const name of names) if (!wanted.includes(name)) finding("unexpected-field", at, { name });
      // TS constructor emission passes values positionally, unlike records.
      if (positional && (actual.length !== wanted.length ||
          actual.some((pair, index) => pair.fst !== wanted[index]))) {
        finding("constructor-field-order", at, { expected: wanted, actual: actual.map((pair) => pair.fst) });
      }
    }
    return actual;
  }
  function knownCall(expression, scope, at) {
    const constructor = tag(expression, "expr", at);
    if (constructor === "var") {
      const entry = lookup(scope, expression.name);
      if (!entry) return undefined;
      if (entry.parameters) return { arity: entry.parameters.length, genericArity: entry.genericArity };
      if (tag(entry.type, "type", at + "/calleeType") === "function") {
        return { arity: list(entry.type.parameters, at + "/calleeParameters").length, genericArity: entry.genericArity };
      }
    } else if (constructor === "lambda") {
      return { arity: list(expression.parameters, at + "/lambdaParameters").length, genericArity: 0 };
    }
    return undefined;
  }
  function checkExpression(root, initialScope, typeScope, owner) {
    const pending = [{ expression: root, scope: initialScope, directCallee: false }];
    while (pending.length) {
      charge();
      const { expression, scope, directCallee } = pending.pop();
      const at = owner + "/expression[" + (++counts.expressions) + "]";
      const constructor = tag(expression, "expr", at);
      increment(expressionForms, constructor ?? "<malformed>");
      const child = (value, childScope = scope, callee = false) =>
        pending.push({ expression: value, scope: childScope, directCallee: callee });
      if (constructor === "literal") {
        const literal = tag(expression.value, "literal", at);
        increment(literalForms, literal ?? "<malformed>");
        if (literal === "natural" && (typeof expression.value.value !== "bigint" || expression.value.value < 0n)) {
          finding("noncanonical-natural-literal", at, {});
        } else if (literal === "integer" && typeof expression.value.value !== "bigint") {
          finding("noncanonical-integer-literal", at, {});
        } else if (literal === "machineInteger") {
          const machine = tag(expression.value.type, "machine", at);
          finding("machine-literal-ledger-unqualified", at, { machine });
        } else if (literal === "string" && typeof expression.value.value !== "string") {
          finding("malformed-string-literal", at, {});
        } else if (literal === "bool" && typeof expression.value.value !== "boolean") {
          finding("malformed-boolean-literal", at, {});
        } else if (!["natural", "integer", "machineInteger", "string", "bool", "unit"].includes(literal)) {
          complete = false;
          finding("unrecognized-literal-form", at, { literal });
        }
      } else if (constructor === "var") {
        counts.valueReferences += 1;
        const entry = lookup(scope, expression.name);
        if (!entry) finding("unresolved-value-name", at, { name: expression.name });
        else if (entry.genericArity > 0 && !directCallee) {
          finding("generic-value-reference-needs-typing", at, { name: expression.name });
        }
      } else if (constructor === "lambda") {
        const parameters = list(expression.parameters, at + "/parameters");
        parameters.forEach((parameter) => checkType(parameter.type, typeScope, at + "/parameter:" + parameter.name));
        checkType(expression.resultType, typeScope, at + "/resultType");
        child(expression.body, extend(scope, parameters, at));
      } else if (constructor === "call") {
        const types = checkTypeArguments(expression.typeArguments, typeScope, at);
        const arguments_ = list(expression.arguments, at + "/arguments");
        const signature = knownCall(expression.fn, scope, at);
        if (signature) {
          counts.callArityChecked += 1;
          checkArity(arguments_.length, signature.arity, at, "call-runtime-arity");
          checkArity(types.length, signature.genericArity, at, "call-type-arity");
        } else {
          counts.callArityUnresolved += 1;
          finding("call-arity-needs-expression-typing", at, {});
        }
        child(expression.fn, scope, true);
        arguments_.forEach((argument) => child(argument));
      } else if (constructor === "letE") {
        checkType(expression.type, typeScope, at + "/letType");
        child(expression.value);
        child(expression.body, extend(scope, [{ name: expression.name, type: expression.type }], at));
      } else if (constructor === "ifE") {
        child(expression.condition); child(expression.thenBranch); child(expression.elseBranch);
      } else if (constructor === "intrinsic") {
        const types = checkTypeArguments(expression.typeArguments, typeScope, at);
        const arguments_ = list(expression.arguments, at + "/arguments");
        const operation = tag(expression.operation, "intrinsic", at);
        increment(intrinsicUses, operation ?? "<malformed>");
        const signature = INTRINSIC_ARITIES[operation];
        if (!signature) finding("unlisted-intrinsic", at, { operation });
        else {
          checkArity(types.length, signature[0], at, "intrinsic-type-arity");
          checkArity(arguments_.length, signature[1], at, "intrinsic-runtime-arity");
        }
        arguments_.forEach((argument) => child(argument));
      } else if (constructor === "record" || constructor === "constructor") {
        const types = checkTypeArguments(expression.typeArguments, typeScope, at);
        const isRecord = constructor === "record";
        const layout = layoutFor(isRecord ? expression.structureName : expression.inductiveName,
          isRecord ? "structure" : "inductive", types, at);
        const ctor = !isRecord && layout?.constructors.get(expression.constructorName);
        if (!isRecord && layout && !ctor) {
          finding("unresolved-constructor", at, { name: expression.constructorName });
        }
        const actual = fields(expression.fields, isRecord ? layout?.fields : ctor?.fields, at, !isRecord);
        actual.forEach((pair) => child(pair.snd));
      } else if (constructor === "projection") {
        const types = checkTypeArguments(expression.typeArguments, typeScope, at);
        const layout = layoutFor(expression.structureName, "structure", types, at);
        if (layout && !layout.fields.some((field) => field.name === expression.field)) {
          finding("unresolved-projection-field", at, { field: expression.field });
        }
        child(expression.target);
      } else if (constructor === "matchE") {
        const types = checkTypeArguments(expression.typeArguments, typeScope, at);
        const layout = layoutFor(expression.inductiveName, "inductive", types, at);
        const alternatives = list(expression.alternatives, at + "/alternatives");
        const names = uniqueNames(alternatives, (alternative) => alternative.fst, at, "duplicate-match-alternative");
        if (layout) {
          for (const name of layout.constructors.keys()) {
            if (!names.has(name)) finding("missing-match-alternative", at, { name });
          }
          for (const name of names) {
            if (!layout.constructors.has(name)) finding("unexpected-match-alternative", at, { name });
          }
        }
        child(expression.scrutinee);
        for (const alternative of alternatives) {
          const bindings = list(alternative.snd.fst, at + "/bindings:" + alternative.fst);
          const ctor = layout?.constructors.get(alternative.fst);
          uniqueNames(bindings, (binding) => binding.field, at, "duplicate-match-field");
          for (const binding of bindings) {
            checkType(binding.type, typeScope, at + "/binding:" + binding.name);
            if (ctor && !ctor.fields.some((field) => field.name === binding.field)) {
              finding("unresolved-match-field", at, { field: binding.field, constructor: alternative.fst });
            }
          }
          child(alternative.snd.snd, extend(scope, bindings, at));
        }
      } else if (constructor !== undefined) {
        complete = false;
        finding("unrecognized-expression-form", at, { constructor });
      }
    }
  }

  try {
    const imports = list(module.imports, "imports");
    const structures = list(module.structures, "structures");
    const inductives = list(module.inductives, "inductives");
    const declarations = list(module.declarations, "declarations");
    Object.assign(counts, { imports: imports.length, structures: structures.length,
      inductives: inductives.length, declarations: declarations.length });
    uniqueNames([...structures, ...inductives], (item) => item.name, "layouts", "duplicate-layout-name");
    uniqueNames([...declarations.map((item) => ({ name: item.name })),
      ...imports.map((item) => ({ name: item.localName }))], (item) => item.name, "values", "duplicate-value-name");
    for (const [kind, items] of [["structure", structures], ["inductive", inductives]]) {
      for (const item of items) {
        const at = kind + ":" + item.name;
        const parameters = typeParameters(item.typeParameters, at);
        const layout = { kind, typeParameters: parameters };
        if (kind === "structure") {
          layout.fields = list(item.fields, at + "/fields");
          uniqueNames(layout.fields, (field) => field.name, at, "duplicate-layout-field");
        } else {
          const constructors = list(item.constructors, at + "/constructors");
          uniqueNames(constructors, (ctor) => ctor.name, at, "duplicate-constructor-name");
          counts.constructors += constructors.length;
          layout.constructors = new Map(constructors.map((ctor) => {
            const fields_ = list(ctor.fields, at + "/constructor:" + ctor.name);
            uniqueNames(fields_, (field) => field.name, at, "duplicate-layout-field");
            return [ctor.name, { fields: fields_ }];
          }));
        }
        layouts.set(item.name, layout);
      }
    }
    for (const [name, layout] of layouts) {
      const allFields = layout.kind === "structure" ? layout.fields :
        [...layout.constructors.values()].flatMap((ctor) => ctor.fields);
      counts.layoutFields += allFields.length;
      allFields.forEach((field) => checkType(field.type, layout.typeParameters, "layout:" + name + "/field:" + field.name));
    }
    for (const item of imports) {
      checkType(item.type, new Set(), "import:" + item.localName);
      globals.set(item.localName, { type: item.type, genericArity: 0 });
      finding("external-import-abi-unqualified", "import:" + item.localName,
        { source: item.source, importedName: item.importedName });
    }
    const preparedDeclarations = declarations.map((item) => {
      const at = "declaration:" + item.name;
      const parameters = list(item.parameters, at + "/parameters");
      const genericScope = typeParameters(item.typeParameters, at);
      globals.set(item.name, { parameters, genericArity: genericScope.size, resultType: item.resultType });
      return { item, at, parameters, genericScope };
    });
    for (const { item, at, parameters, genericScope } of preparedDeclarations) {
      parameters.forEach((parameter) => checkType(parameter.type, genericScope, at + "/parameter:" + parameter.name));
      checkType(item.resultType, genericScope, at + "/resultType");
      checkExpression(item.body, extend(undefined, parameters, at), genericScope, at);
    }
  } catch (error) {
    if (error !== limit) throw error;
    complete = false;
    finding("inventory-resource-limit", "module", { maxNodes });
  }

  return {
    schemaVersion: 1,
    kind: "psc0-original-ir-inventory",
    compilerSha256,
    status: "report-only",
    strictSh1Qualified: false,
    traversalComplete: complete,
    visitedNodes,
    counts, typeForms, primitives, expressionForms, literalForms, intrinsicUses,
    findingCounts,
    findings,
    omittedFindingDetails: Object.values(findingCounts).reduce((sum, count) => sum + count, 0) - findings.length,
    coverage: [
      "Every annotated runtime type position; layout and declaration generic scope",
      "Lexical/global value names, duplicate declarations/binders and shadowing",
      "Module-owned named type arity; record field sets; positional constructor layouts",
      "Projection owner/field existence; unique exhaustive flat match alternatives",
      "Direct/global, local function-annotation and lambda call arity",
      "All original intrinsic constructor runtime/type argument counts",
    ],
    unqualifiedObligations: [
      "Full expression argument/result type compatibility and generic substitution",
      "Indirect callee typing, instantiated generic function values and partial applications",
      "Projection target types and match scrutinee/binding/branch result compatibility",
      "Intrinsic operand/result signatures and scalar/effect semantics beyond arity",
      "Machine literal ranges/canonicalization, target word width, float and Unicode laws",
      "External runtime named-type ledger and import ABI closure",
      "Erasure preservation, evaluation order and backend semantic correspondence",
      "Portable checker self-hosting and strict SH/1 enforcement",
    ],
    notes: [
      "Scoped type parameters are supported parametric types, not unknown runtime types.",
      "Unknown means an explicit original-IR unknown annotation, never proof erasure.",
      "Nat recursors are lowered to if/let/intrinsics before this original-IR report.",
      "The inventory never grants acceptance from zero findings or a complete traversal.",
    ],
  };
}
