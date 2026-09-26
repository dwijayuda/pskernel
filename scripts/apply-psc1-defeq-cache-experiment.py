#!/usr/bin/env python3
from pathlib import Path

TYPECHECKER = Path("psc1-kernel/PSC1Kernel/TypeChecker.lean")
SESSION = Path("psc1-kernel/PSC1Kernel/CheckerSession.lean")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count == 0:
        if new in text:
            return text
        raise SystemExit(f"{label}: anchor not found")
    if count != 1:
        raise SystemExit(f"{label}: expected one anchor, found {count}")
    return text.replace(old, new, 1)


def patch_typechecker() -> None:
    text = TYPECHECKER.read_text()

    text = replace_once(
        text,
        "import PSC1Kernel.Instantiate\n",
        "import PSC1Kernel.Instantiate\nimport PSC1Kernel.CheckerRuntimeCache\n",
        "TypeChecker import",
    )

    text = replace_once(
        text,
        "  eagerReduce : Bool\n  nativeEvaluator : Option NativeEvaluator\n  /-- User-facing Lean maxRecDepth value. 0 means unlimited. -/\n",
        "  eagerReduce : Bool\n  nativeEvaluator : Option NativeEvaluator\n  /-- Declaration-scoped runtime memo state; pure checker semantics ignore it. -/\n  runtimeCache : Option CheckerRuntimeCache := none\n  /-- User-facing Lean maxRecDepth value. 0 means unlimited. -/\n",
        "CheckerContext runtime cache field",
    )

    text = replace_once(
        text,
        "    eagerReduce := false\n    nativeEvaluator := none\n    maxRecDepth := 0\n",
        "    eagerReduce := false\n    nativeEvaluator := none\n    runtimeCache := some (CheckerRuntimeCache.freshFor env)\n    maxRecDepth := 0\n",
        "CheckerContext.empty runtime cache",
    )

    old = """partial def isDefEq (ctx : CheckerContext) (a b : Expr) : Except String Bool := do
  -- Final Lean 4.34 enters scope_rec_depth in is_def_eq_core before even the
  -- structural/success-cache quick path. Keep that resource boundary here.
  let ctx ← ctx.enterKernelRecDepth
  match ← quickDefEq ctx a b with
"""
    new = """partial def isDefEq (ctx : CheckerContext) (a b : Expr) : Except String Bool := do
  -- Final Lean 4.34 enters scope_rec_depth before the success-cache quick path.
  -- Keep the same resource boundary even when a runtime memo entry hits.
  let ctx ← ctx.enterKernelRecDepth
  match ctx.runtimeCache with
  | some cache =>
      CheckerRuntimeCache.withClosedSuccess cache a b (fun _ =>
        isDefEqCore ctx a b)
  | none =>
      isDefEqCore ctx a b

partial def isDefEqCore (ctx : CheckerContext) (a b : Expr) : Except String Bool := do
  match ← quickDefEq ctx a b with
"""
    text = replace_once(text, old, new, "isDefEq cache wrapper")

    TYPECHECKER.write_text(text)


def patch_session() -> None:
    text = SESSION.read_text()
    text = replace_once(
        text,
        "      eagerReduce := false\n      nativeEvaluator := nativeEvaluator\n      maxRecDepth := maxRecDepth\n",
        "      eagerReduce := false\n      nativeEvaluator := nativeEvaluator\n      runtimeCache := some (CheckerRuntimeCache.freshFor env)\n      maxRecDepth := maxRecDepth\n",
        "CheckerSession runtime cache",
    )
    SESSION.write_text(text)


patch_typechecker()
patch_session()
print("PSC1 defeq cache experiment patch: APPLIED")
