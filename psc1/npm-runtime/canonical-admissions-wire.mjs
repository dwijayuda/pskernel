// Canonical admissions wire decoder shared by the PSC1 developer provider and legacy adapter.
// This module only constructs untrusted declaration requests. It never creates
// an environment, changes kernel resources, or makes an admission decision.
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
export function createWireDecoder(kernel, { maxDepth = 4096 } = {}) {
  if (!Number.isSafeInteger(maxDepth) || maxDepth < 1 || maxDepth > 4096) fail('DEPTH_POLICY');
  const list = (values, convert) => {
    const xs = array(values);
    let result = typeof kernel.List.nil === 'function' ? kernel.List.nil() : kernel.List.nil;
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

