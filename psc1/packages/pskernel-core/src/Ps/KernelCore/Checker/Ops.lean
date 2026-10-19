import Ps.KernelCore.Checker.Context

/- Internal callback contract. Implementations and fuel wiring belong to Checker/Knot. -/
-- PSC1 structure fields use one physical line, as in PsKernelNativeEvaluator.
structure PsKernelCheckerOps where
  infer : PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr -> Except String (Prod PsKernelExpr PsKernelCheckerState)
  check : PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr -> Except String (Prod PsKernelExpr PsKernelCheckerState)
  whnfCore : PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr -> Bool -> Bool -> Except String (Prod PsKernelExpr PsKernelCheckerState)
  whnf : PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr -> Except String (Prod PsKernelExpr PsKernelCheckerState)
  defeq : PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr -> PsKernelExpr -> Except String (Prod Bool PsKernelCheckerState)
  reduceRecursor : PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr -> Bool -> Bool -> Except String (Prod (Option PsKernelExpr) PsKernelCheckerState)
