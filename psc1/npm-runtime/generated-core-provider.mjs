// Generated-JavaScript PSKernel Core admission adapter.
// This is an independent EXECUTION candidate, not a promoted trusted kernel.
// Promotion requires independent differential and full-corpus
// conformance gates independently pass. No fallback or unchecked insertion.
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const allowedTags = new Set(['z', 's', 'max', 'imax', 'p']);

function fail(code) { throw new Error('PSC0_GENERATED_CORE_' + code); }
function obj(value) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) fail('EXPECTED_OBJECT');
  return value;
}
function array(value) {
  if (!Array.isArray(value)) fail('EXPECTED_ARRAY');
  return value;
}
function string(value) {
  if (typeof value !== 'string') fail('EXPECTED_STRING');
  return value;
}
function nat(value) {
  const text = typeof value === 'number' && Number.isSafeInteger(value) && value >= 0
    ? String(value) : value;
  if (typeof text !== 'string' || !/^(0|[1-9][0-9]*)$/u.test(text)) fail('INVALID_NATURAL');
  return BigInt(text);
}
function sumTag(value) {
  if (!value || typeof value !== 'object') fail('INVALID_SUM');
  const tags = Object.getOwnPropertySymbols(value).map(k => value[k]);
  if (tags.length !== 1 || typeof tags[0] !== 'string') fail('INVALID_SUM_TAG');
  return tags[0];
}
function attempt(result) {
  const tag = sumTag(result);
  if (tag === 'ok') return { ok: true, value: result.value };
  if (tag !== 'error') fail('INVALID_EXCEPT_TAG');
  return { ok: false, error: result.error };
}
function errorDetails(value) {
  let kind, message;
  try { kind = sumTag(value); } catch { kind = 'internalError'; }
  if (typeof value?.message === 'string') message = value.message;
  else if (typeof value?.value === 'string') message = value.value;
  else if (typeof value?.[0] === 'string') message = value[0];
  else message = 'unrecognized generated core error';
  return { kind, message };
}
function kernelError(value) {
  const { kind, message } = errorDetails(value);
  if (kind === 'rejectedInvalid') return { errorKind: 'kernel-rejection', message };
  if (kind === 'declinedUnsupported') return { errorKind: 'unsupported-core-form', message };
  if (kind === 'resourceExhausted') return { errorKind: 'resource-exhausted', message };
  return { errorKind: 'provider-internal-error', message };
}

export function createWireDecoder(kernel, { maxDepth = 4096 } = {}) {
  if (!Number.isSafeInteger(maxDepth) || maxDepth < 1 || maxDepth > 4096) fail('DEPTH_POLICY');
  const list = (values, convert) => {
    const xs = array(values);
    let result = kernel.List.nil();
    for (let i = xs.length - 1; i >= 0; i--) {
      result = kernel.List.cons(convert(xs[i]), result);
    }
    return result;
  };
  function name(value, depth = 0) {
    if (depth >= maxDepth) fail('NAME_DEPTH');
    const v = obj(value);
    if (v.k === 'a') return kernel.PsKernelName.anonymous;
    if (v.k === 's') return kernel.PsKernelName.str(name(v.p, depth + 1), string(v.v));
    if (v.k === 'n') return kernel.PsKernelName.num(name(v.p, depth + 1), nat(v.v));
    fail('NAME_TAG');
  }
  function level(value, depth = 0) {
    if (depth >= maxDepth) fail('LEVEL_DEPTH');
    const v = obj(value);
    if (!allowedTags.has(v.k)) fail('LEVEL_TAG');
    if (v.k === 'z') return kernel.PsKernelLevel.zero;
    if (v.k === 's') return kernel.PsKernelLevel.succ(level(v.o, depth + 1));
    if (v.k === 'max' || v.k === 'imax') {
      return kernel.PsKernelLevel[v.k](level(v.l, depth + 1), level(v.r, depth + 1));
    }
    return kernel.PsKernelLevel.param(name(v.n, depth + 1));
  }
  function expr(value, depth = 0) {
    if (depth >= maxDepth) fail('EXPR_DEPTH');
    const v = obj(value), d = depth + 1;
    switch (v.k) {
      case 'b': return kernel.PsKernelExpr.bvar(nat(v.i));
      case 'sort': return kernel.PsKernelExpr.sort(level(v.l, d));
      case 'const': return kernel.PsKernelExpr.const(name(v.n, d), list(v.ls, x => level(x, d)));
      case 'app': return kernel.PsKernelExpr.app(expr(v.f, d), expr(v.a, d));
      case 'lam':
      case 'forall': {
        const binder = {
          default: 'default', implicit: 'implicit', strictImplicit: 'strictImplicit',
          instImplicit: 'instImplicit',
        }[string(v.bi)];
        if (!binder) fail('BINDER_TAG');
        const fn = v.k === 'lam' ? 'lam' : 'forallE';
        return kernel.PsKernelExpr[fn](
          name(v.n, d), expr(v.t, d), expr(v.b, d), kernel.PsKernelBinderInfo[binder]);
      }
      case 'let': return kernel.PsKernelExpr.letE(
        name(v.n, d), expr(v.t, d), expr(v.v, d), expr(v.b, d), false);
      case 'nat': return kernel.PsKernelExpr.lit(kernel.PsKernelLiteral.nat(nat(v.v)));
      case 'str': return kernel.PsKernelExpr.lit(kernel.PsKernelLiteral.str(string(v.v)));
      case 'proj': return kernel.PsKernelExpr.proj(name(v.n, d), nat(v.i), expr(v.e, d));
      default: fail('EXPR_TAG');
    }
  }
  const base = ({ n, lp, t }) => ({
    name: name(n), levelParams: list(lp, name), type: expr(t),
  });
  function request(admission) {
    const a = obj(admission), d = obj(a.declaration);
    if (a.kind === 'constant') {
      if (d.k === 'definition') {
        if (d.s !== 'safe' || obj(d.h).k !== 'regular') fail('UNSUPPORTED_DEFINITION');
        const height = nat(d.h.h);
        if (height > 0xffffffffn) fail('DEFINITION_HEIGHT_OVERFLOW');
        return kernel.PsKernelDeclarationRequest.definitionDecl({
          base: base(d), value: expr(d.v),
          hints: kernel.PsKernelReducibilityHints.regular(height),
          safety: kernel.PsKernelDefinitionSafety.safe,
        });
      }
      if (d.k === 'theorem') {
        return kernel.PsKernelDeclarationRequest.theoremDecl({
          base: base(d), value: expr(d.v),
        });
      }
      fail('CONSTANT_KIND');
    }
    if (a.kind === 'inductive') {
      const types = array(d.ts);
      if (types.length < 1) fail('EMPTY_INDUCTIVE');
      const info = {
        levelParams: list(d.lp, name), numParams: nat(d.np),
        types: list(types, t => ({
          name: name(obj(t).n), type: expr(t.t),
          ctors: list(t.cs, c => ({ name: name(obj(c).n), type: expr(c.t) })),
        })),
        isUnsafe: false,
      };
      return kernel.PsKernelDeclarationRequest.nestedInductive(info);
    }
    fail('ADMISSION_KIND');
  }
  return Object.freeze({ name, level, expr, list, base, request });
}

export function parseCanonicalAdmissions(source) {
  const wire = obj(JSON.parse(string(source)));
  if (wire.format !== 'proofscript-checked-admissions' || wire.version !== 2) {
    fail('ADMISSIONS_VERSION');
  }
  return array(wire.admissions);
}

function parsePreludeDeclaration(value, all, decoder, kernel) {
  const v = obj(value);
  const base = {
    name: decoder.name(v.nameWire),
    levelParams: decoder.list(v.levelParameterWires, decoder.name),
    type: decoder.expr(v.type),
  };
  if (v.kind === 'axiom') return kernel.PsKernelDeclarationRequest.axiomDecl({
    base, isUnsafe: false,
  });
  if (v.kind === 'definition') return kernel.PsKernelDeclarationRequest.definitionDecl({
    base, value: decoder.expr(v.value),
    hints: kernel.PsKernelReducibilityHints.regular(0n),
    safety: kernel.PsKernelDefinitionSafety.safe,
  });
  if (v.kind === 'theorem') return kernel.PsKernelDeclarationRequest.theoremDecl({
    base, value: decoder.expr(v.value),
  });
  if (v.kind === 'opaque') return kernel.PsKernelDeclarationRequest.opaqueDecl({
    base, value: decoder.expr(v.value), isUnsafe: false,
  });
  if (v.kind === 'partial') fail('PARTIAL_PRELUDE_FORBIDDEN');
  if (v.kind === 'inductive') {
    const constructorWires = array(obj(v.metadata).constructorWires);
    const ctors = constructorWires.map(n => {
      const key = JSON.stringify(n);
      const matched = all.find(x => x.kind === 'constructor' && JSON.stringify(x.nameWire) === key);
      if (!matched || JSON.stringify(matched.metadata?.familyWire) !== JSON.stringify(v.nameWire)) {
        fail('PRELUDE_CONSTRUCTOR_METADATA');
      }
      return { name: decoder.name(matched.nameWire), type: decoder.expr(matched.type) };
    });
    return kernel.PsKernelDeclarationRequest.ordinaryInductive({
      levelParams: decoder.list(v.levelParameterWires, decoder.name),
      numParams: nat(v.metadata.parameters),
      name: base.name, type: base.type,
      ctors: decoder.list(ctors, x => x), isUnsafe: false,
    });
  }
  if (v.kind === 'constructor' || v.kind === 'recursor') return null;
  fail('PRELUDE_KIND');
}

export function checkGeneratedAdmissionsWithPrelude(
  kernel, source, prelude, { maxDeclarations = 20000 } = {}) {
  if (!Number.isSafeInteger(maxDeclarations) || maxDeclarations < 1) fail('DECLARATION_POLICY');
  const admissions = parseCanonicalAdmissions(source);
  if (admissions.length > maxDeclarations) fail('ADMISSION_LIMIT');
  if (!Array.isArray(prelude) || prelude.length === 0 || prelude.length > 4096) fail('PRELUDE_SHAPE');
  const decoder = createWireDecoder(kernel);
  const initial = attempt(kernel.psKernelKernelSessionEmpty(
    kernel.psKernelResourcePolicyDefault, kernel.psKernelProviderDefault));
  if (!initial.ok) fail('EMPTY_SESSION_REJECTED');
  let session = initial.value;
  let pending = [...prelude].reverse();
  // Mirror the native adapter's fresh checked prelude and defer ONLY unknown
  // constant dependencies. All other diagnostics fail without a fallback.
  for (let round = 0; pending.length; round++) {
    if (round > prelude.length) fail('PRELUDE_DEPENDENCY_LIMIT');
    const deferred = [];
    let progressed = false;
    for (const declaration of pending) {
      const request = parsePreludeDeclaration(declaration, prelude, decoder, kernel);
      if (request === null) { progressed = true; continue; }
      const outcome = attempt(kernel.psKernelV1AdmitDeclaration(session, request));
      if (outcome.ok) {
        session = outcome.value.session;
        progressed = true;
      } else {
        const error = errorDetails(outcome.error);
        if (error.kind === 'rejectedInvalid' && error.message === 'unknown constant') {
          deferred.push(declaration);
        } else {
          return { accepted: false, errorKind: 'prelude-mismatch',
            message: declaration.name + ': ' + error.message };
        }
      }
    }
    if (!deferred.length) break;
    if (!progressed) fail('PRELUDE_UNRESOLVED_DEPENDENCY');
    pending = deferred;
  }
  // Native host expands fuel after the prelude was checked.
  session = { ...session,
    resources: { ...session.resources, fuel: 131072n } };
  for (let i = 0; i < admissions.length; i++) {
    const request = decoder.request(admissions[i]);
    const result = attempt(kernel.psKernelV1AdmitDeclaration(session, request));
    if (!result.ok) return { accepted: false, declarationIndex: i, ...kernelError(result.error) };
    session = result.value.session;
  }
  return { accepted: true, declarationCount: admissions.length };
}

// A subprocess should invoke this for untrusted canonical streams so the
// host can impose independent wall-time and memory budgets. Run as the default only after independent cloud acceptance and negative-conformance qualification.
export async function checkGeneratedKernelFile(kernelPath, admissions, preludePath) {
  const [prelude] = await Promise.all([readFile(preludePath, 'utf8')]);
  const kernel = await import(pathToFileURL(path.resolve(kernelPath)).href);
  return checkGeneratedAdmissionsWithPrelude(kernel, admissions, JSON.parse(prelude));
}
