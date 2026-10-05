import Ps.KernelCore.Runtime.Acceleration.CachePolicy

theorem psKernelInferCacheEligible_literal
    (inferOnly : Bool)
    (literal : PsKernelLiteral) :
    psKernelInferCacheEligible
        inferOnly
        (PsKernelExpr.lit literal) =
      false := by
  rfl

theorem psKernelInferCacheEligible_app
    (inferOnly : Bool)
    (fn arg : PsKernelExpr) :
    psKernelInferCacheEligible
        inferOnly
        (PsKernelExpr.app fn arg) =
      inferOnly := by
  rfl

theorem psKernelInferCacheEligible_lam
    (inferOnly : Bool)
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelInferCacheEligible
        inferOnly
        (PsKernelExpr.lam name type body binderInfo) =
      inferOnly := by
  rfl

theorem psKernelInferCacheEligible_bvar
    (inferOnly : Bool)
    (index : Nat) :
    psKernelInferCacheEligible
        inferOnly
        (PsKernelExpr.bvar index) =
      true := by
  rfl
