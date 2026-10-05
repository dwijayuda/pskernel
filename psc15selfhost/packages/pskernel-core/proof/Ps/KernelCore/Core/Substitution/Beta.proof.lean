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

theorem psKernelExprCheapBetaReduce_identity_lambda
    (name : PsKernelName)
    (level : PsKernelLevel)
    (binderInfo : PsKernelBinderInfo)
    (arg : PsKernelExpr) :
    psKernelExprCheapBetaReduce
        (PsKernelExpr.app
          (PsKernelExpr.lam
            name
            (PsKernelExpr.sort level)
            (PsKernelExpr.bvar 0)
            binderInfo)
          arg) =
      arg := by
  rfl

theorem psKernelExprCheapBetaReduce_closed_const_body
    (name constName : PsKernelName)
    (level : PsKernelLevel)
    (levels : List PsKernelLevel)
    (binderInfo : PsKernelBinderInfo)
    (arg : PsKernelExpr) :
    psKernelExprCheapBetaReduce
        (PsKernelExpr.app
          (PsKernelExpr.lam
            name
            (PsKernelExpr.sort level)
            (PsKernelExpr.const constName levels)
            binderInfo)
          arg) =
      PsKernelExpr.const constName levels := by
  rfl
