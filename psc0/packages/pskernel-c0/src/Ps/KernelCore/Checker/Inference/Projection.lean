import Ps.KernelCore.Checker.Inference.Let

/-!
Exact Lean-4.35-compatible source projection inference.

The projection rule is mechanically extracted from C0's original
syntax-directed source inference worker. It calls the existing checked
projection validator with the original recursive child inference callback,
WHNF, source context, and infer-only/full-check mode. The selected result
is cached exactly as before. Mere projection syntax is not a checked
proof, and invalid projection indices/type shapes must remain rejected.

Pinned upstream reference: Lean 4.35 src/kernel/type_checker.cpp::infer_proj.
-/

/-- One existing source projection inference step. All recursive judgments
    remain owned by the historical source worker supplied as smaller. -/
def psKernelInferProjectionHead
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr)
    (inferOnly : Bool) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  let expr : PsKernelExpr := .proj typeName index structValue
  let inferType :=
    fun
      (projectionContext : PsKernelCheckerContext)
      (projectionState : PsKernelCheckerState)
      (projectionExpr : PsKernelExpr) =>
      smaller [] []
        whnf
        defeq
        projectionContext
        projectionState
        projectionExpr
        inferOnly;
  match
      psKernelInferProjectionWith
        whnf
        inferType
        nextContext
        state
        typeName
        index
        structValue with
  | Except.error error =>
      Except.error error
  | Except.ok projectionResult =>
      let result :=
        Prod.fst projectionResult;
      Except.ok
        (Prod.mk
          result
          (psKernelCacheInferResult
            (Prod.snd projectionResult)
            inferOnly
            expr
            result))
