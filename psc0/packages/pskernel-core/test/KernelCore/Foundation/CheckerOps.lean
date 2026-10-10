import Ps.KernelCore.Checker.Session

def psKernelCheckerOpsFailed {α : Type} (result : Except String α) : Bool :=
  match result with
  | Except.error _ => true
  | Except.ok _ => false

def psKernelCheckerOpsExprResult
    (expected : PsKernelExpr)
    (result : Except String (Prod PsKernelExpr PsKernelCheckerState)) : Bool :=
  match result with
  | Except.error _ => false
  | Except.ok value => psKernelExprEq expected value.fst

-- Every public operation must reject exhaustion, even reflexive defeq.
def psKernelCheckerOpsExhaustionTests : Bool :=
  let ops := psKernelCheckerOpsWithFuel 0
  let context := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let state := psKernelCheckerStateEmpty
  let expr := PsKernelExpr.sort PsKernelLevel.zero
  psKernelCheckerOpsFailed (ops.infer context state expr) &&
    psKernelCheckerOpsFailed (ops.check context state expr) &&
    psKernelCheckerOpsFailed (ops.whnf context state expr) &&
    psKernelCheckerOpsFailed (ops.whnfCore context state expr false false) &&
    psKernelCheckerOpsFailed (ops.defeq context state expr expr) &&
    psKernelCheckerOpsFailed (ops.reduceRecursor context state expr false false)

def psKernelCheckerOpsSuccessTests : Bool :=
  let ops := psKernelCheckerOpsWithFuel 64
  let context := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let state := psKernelCheckerStateEmpty
  let expr := PsKernelExpr.sort PsKernelLevel.zero
  let type := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
  psKernelCheckerOpsExprResult type (ops.infer context state expr) &&
    psKernelCheckerOpsExprResult type (ops.check context state expr) &&
    psKernelCheckerOpsExprResult expr (ops.whnf context state expr) &&
    psKernelCheckerOpsExprResult expr (ops.whnfCore context state expr false false) &&
    (match ops.defeq context state expr expr with
     | Except.ok result => result.fst
     | Except.error _ => false) &&
    (match ops.reduceRecursor context state expr false false with
     | Except.ok (Option.none, _) => true
     | _ => false)

-- Infer-only may compute this application's result type without validating its
-- argument. Full checking must still reject it, including after that result has
-- populated the session's infer-only cache.
def psKernelCheckerSessionCheckedPathTests : Bool :=
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    PsKernelDefinitionSafety.safe 0 psKernelLeanNatMaxSizeDefault
  let prop := PsKernelExpr.sort PsKernelLevel.zero
  let malformed := PsKernelExpr.app
    (PsKernelExpr.lam PsKernelName.anonymous prop (PsKernelExpr.bvar 0)
      PsKernelBinderInfo.default)
    prop
  match psKernelSessionInfer 128 session malformed with
  | Except.error _ => false
  | Except.ok inferred =>
      psKernelExprEq prop inferred.fst &&
        psKernelCheckerOpsFailed (psKernelSessionCheck 128 session malformed) &&
        psKernelCheckerOpsFailed (psKernelSessionCheck 128 inferred.snd malformed)

def psKernelCheckerOpsTests : Bool :=
  psKernelCheckerOpsExhaustionTests && psKernelCheckerOpsSuccessTests &&
    psKernelCheckerSessionCheckedPathTests
