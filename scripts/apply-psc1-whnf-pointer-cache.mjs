import { readFileSync, writeFileSync } from 'node:fs';

const path = 'psc1-kernel/PSC1Kernel/TypeChecker.lean';
let source = readFileSync(path, 'utf8');

const importNeedle = 'import PSC1Kernel.Instantiate\n';
const importReplacement =
  'import PSC1Kernel.Instantiate\nimport PSC1Kernel.CheckerWhnfPointerCache\n';
if (!source.includes('import PSC1Kernel.CheckerWhnfPointerCache')) {
  if (!source.includes(importNeedle)) throw new Error('missing TypeChecker import anchor');
  source = source.replace(importNeedle, importReplacement);
}

const defNeedle = `partial def whnfCore
    (ctx : CheckerContext)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String Expr := do
  let ctx ← ctx.enterKernelRecDepth
`;
const defReplacement = `partial def whnfCoreCompute
    (ctx : CheckerContext)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String Expr := do
  let ctx ← ctx.enterKernelRecDepth
`;
if (source.includes(defNeedle)) {
  source = source.replace(defNeedle, defReplacement);
} else if (!source.includes('partial def whnfCoreCompute')) {
  throw new Error('missing whnfCore definition anchor');
}

const reduceNativeAnchor = `partial def reduceNative
    (ctx : CheckerContext)
`;
const wrapper = `partial def whnfCore
    (ctx : CheckerContext)
    (e : Expr)
    (cheapRec cheapProj : Bool) : Except String Expr := do
  let cacheEnabled :=
    !cheapRec && !cheapProj &&
      ctx.maxRecDepth == 0 &&
      ctx.nativeEvaluator.isNone &&
      !ctx.eagerReduce
  if cacheEnabled then
    match checkerWhnfCoreLookup
        ctx.env ctx.lctx.decls ctx.lctx.nextIndex ctx.maxNatSize
        true e with
    | some cached => return cached
    | none => pure ()
  let result ← whnfCoreCompute ctx e cheapRec cheapProj
  return checkerWhnfCoreStore
    ctx.env ctx.lctx.decls ctx.lctx.nextIndex ctx.maxNatSize
    cacheEnabled e result

`;
if (!source.includes(wrapper)) {
  if (!source.includes(reduceNativeAnchor)) throw new Error('missing reduceNative anchor');
  source = source.replace(reduceNativeAnchor, wrapper + reduceNativeAnchor);
}

writeFileSync(path, source);
console.log('PSC1_WHNF_POINTER_CACHE_PATCH: PASS');
