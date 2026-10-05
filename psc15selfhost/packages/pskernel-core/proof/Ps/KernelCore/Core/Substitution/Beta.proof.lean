import Ps.KernelCore.Core.Substitution.Beta

theorem psKernelExprApplyArgsCheap_nil
    (fn : PsKernelExpr) :
    psKernelExprApplyArgsCheap fn List.nil = fn := by
  rfl

theorem psKernelExprApplyArgsCheap_cons
    (fn arg : PsKernelExpr)
    (rest : List PsKernelExpr) :
    psKernelExprApplyArgsCheap fn (List.cons arg rest) =
      psKernelExprApplyArgsCheap (PsKernelExpr.app fn arg) rest := by
  rfl

theorem psKernelExprConsumeLambdaSpineWithFuel_zero
    (fn : PsKernelExpr)
    (args : List PsKernelExpr)
    (count : Nat) :
    psKernelExprConsumeLambdaSpineWithFuel 0 fn args count =
      Prod.mk fn count := by
  rfl

theorem psKernelExprCheapBetaReduce_bvar
    (index : Nat) :
    psKernelExprCheapBetaReduce (PsKernelExpr.bvar index) =
      PsKernelExpr.bvar index := by
  rfl

theorem psKernelExprCheapBetaReduce_const
    (name : PsKernelName)
    (levels : List PsKernelLevel) :
    psKernelExprCheapBetaReduce (PsKernelExpr.const name levels) =
      PsKernelExpr.const name levels := by
  rfl
