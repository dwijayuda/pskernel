import fs from 'node:fs';

const path = 'psc1-kernel/PSC1Kernel/TypeChecker.lean';
let source = fs.readFileSync(path, 'utf8');

function replaceOnce(label, from, to) {
  const first = source.indexOf(from);
  if (first < 0) throw new Error(`${label}: source anchor not found`);
  if (source.indexOf(from, first + from.length) >= 0) {
    throw new Error(`${label}: source anchor is not unique`);
  }
  source = source.slice(0, first) + to + source.slice(first + from.length);
}

replaceOnce(
  'runtime import',
  'import PSC1Kernel.Instantiate\n',
  'import PSC1Kernel.Instantiate\nimport PSC1Kernel.CheckerCacheRuntime\n',
);

replaceOnce(
  'positive cache quick path',
  `  if Expr.eq left right then\n    return some true\n`,
  `  let cacheEnabled := ctx.nativeEvaluator.isNone\n  if Expr.eq left right ||\n      checkerDefEqSuccessCached ctx.env ctx.lctx ctx.maxRecDepth ctx.maxNatSize\n        cacheEnabled left right then\n    return some true\n`,
);

replaceOnce(
  'lazy-delta negative cache',
  `            if sameDeltaDefinition da db &&\n                da.hints.isRegular &&\n                appHeadLevelsEquivalent left right then\n              if ← isDefEqArgs ctx left right then\n                return .equal\n`,
  `            if sameDeltaDefinition da db &&\n                da.hints.isRegular &&\n                appHeadLevelsEquivalent left right then\n              let cacheEnabled := ctx.nativeEvaluator.isNone\n              if !checkerDefEqFailureCached\n                  ctx.env ctx.lctx ctx.maxRecDepth ctx.maxNatSize\n                  cacheEnabled left right then\n                let argsEq ← isDefEqArgs ctx left right\n                let argsEq := checkerDefEqCacheFailureResult\n                  ctx.env ctx.lctx ctx.maxRecDepth ctx.maxNatSize\n                  cacheEnabled left right argsEq\n                if argsEq then\n                  return .equal\n`,
);

replaceOnce(
  'defeq core rename',
  `partial def isDefEq (ctx : CheckerContext) (a b : Expr) : Except String Bool := do\n`,
  `partial def isDefEqCore (ctx : CheckerContext) (a b : Expr) : Except String Bool := do\n`,
);

replaceOnce(
  'success cache wrapper',
  `  if ← isDefEqUnitLike ctx aFull bFull then return true\n  return false\n\npartial def tryEtaStructCore\n`,
  `  if ← isDefEqUnitLike ctx aFull bFull then return true\n  return false\n\n/--\nLean 4.34 public is_def_eq wrapper: cache only successful original pairs.\nThe pure cache hook is identity/no-op, so reference semantics are unchanged.\n-/\npartial def isDefEq (ctx : CheckerContext) (a b : Expr) : Except String Bool := do\n  let result ← isDefEqCore ctx a b\n  let cacheEnabled := ctx.nativeEvaluator.isNone\n  return checkerDefEqCacheSuccessResult\n    ctx.env ctx.lctx ctx.maxRecDepth ctx.maxNatSize\n    cacheEnabled a b result\n\npartial def tryEtaStructCore\n`,
);

fs.writeFileSync(path, source);
console.log('PSC1_DEFEQ_CACHE_PATCH: PASS');
