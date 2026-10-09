import Ps.KernelCore.Runtime.Acceleration.CachePolicy

theorem psKernelSemanticCacheEligible_fvar
    (name : PsKernelName) :
    psKernelSemanticCacheEligible
        (PsKernelExpr.fvar name) =
      false := by
  rfl

theorem psKernelSemanticCacheEligible_app_with_fvar_left
    (name : PsKernelName)
    (arg : PsKernelExpr) :
    psKernelSemanticCacheEligible
        (PsKernelExpr.app
          (PsKernelExpr.fvar name)
          arg) =
      false := by
  rfl

theorem psKernelSemanticCacheEligible_app_with_fvar_right
    (fn : PsKernelExpr)
    (name : PsKernelName) :
    psKernelSemanticCacheEligible
        (PsKernelExpr.app
          fn
          (PsKernelExpr.fvar name)) =
      false := by
  have hFVar : ∀ fuel : Nat,
      psKernelSemanticCacheRemaining (PsKernelExpr.fvar name) fuel = none := by
    intro fuel
    cases fuel <;> rfl
  cases hFn : psKernelSemanticCacheRemaining fn 255 with
  | none =>
      simp [psKernelSemanticCacheEligible, psKernelSemanticCacheNodeBudget,
        psKernelSemanticCacheRemaining, hFn, hFVar]
  | some remaining =>
      simp [psKernelSemanticCacheEligible, psKernelSemanticCacheNodeBudget,
        psKernelSemanticCacheRemaining, hFn, hFVar]

theorem psKernelSemanticPairCacheEligible_left_fvar
    (name : PsKernelName)
    (right : PsKernelExpr) :
    psKernelSemanticPairCacheEligible
        (PsKernelExpr.fvar name)
        right =
      false := by
  rfl

theorem psKernelSemanticPairCacheEligible_right_fvar
    (left : PsKernelExpr)
    (name : PsKernelName) :
    psKernelSemanticPairCacheEligible
        left
        (PsKernelExpr.fvar name) =
      false := by
  cases hLeft :
      psKernelSemanticCacheEligible left <;>
    simp [
      psKernelSemanticPairCacheEligible,
      hLeft,
      psKernelSemanticCacheEligible_fvar
    ]

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
      if
          psKernelSemanticCacheEligible
            (PsKernelExpr.app fn arg) then
        inferOnly
      else
        false := by
  cases inferOnly <;>
    cases h : psKernelSemanticCacheEligible (PsKernelExpr.app fn arg) <;>
    simp [psKernelInferCacheEligible, h]

theorem psKernelInferCacheEligible_lam
    (inferOnly : Bool)
    (name : PsKernelName)
    (type body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelInferCacheEligible
        inferOnly
        (PsKernelExpr.lam name type body binderInfo) =
      if
          psKernelSemanticCacheEligible
            (PsKernelExpr.lam
              name
              type
              body
              binderInfo) then
        inferOnly
      else
        false := by
  cases inferOnly <;>
    cases h : psKernelSemanticCacheEligible (PsKernelExpr.lam name type body binderInfo) <;>
    simp [psKernelInferCacheEligible, h]

theorem psKernelInferCacheEligible_bvar
    (inferOnly : Bool)
    (index : Nat) :
    psKernelInferCacheEligible
        inferOnly
        (PsKernelExpr.bvar index) =
      true := by
  rfl

theorem psKernelInferCacheEligible_fvar
    (inferOnly : Bool)
    (name : PsKernelName) :
    psKernelInferCacheEligible
        inferOnly
        (PsKernelExpr.fvar name) =
      false := by
  rfl

-- Reduction cache keys may mention locals, within the existing scope invariant.
theorem psKernelWhnfCacheEligible_fvar (name : PsKernelName) :
    psKernelWhnfCacheEligible (.fvar name) = true := by
  rfl

theorem psKernelWhnfCacheRemaining_zero (expr : PsKernelExpr) :
    psKernelWhnfCacheRemaining expr 0 = none := by
  cases expr <;> rfl

-- Mode refusal is independent of the expression's size and local variables.
theorem psKernelInferCacheEligible_checked_app
    (fn arg : PsKernelExpr) :
    psKernelInferCacheEligible false (.app fn arg) = false := by
  rfl

theorem psKernelInferCacheEligible_checked_forall
    (name : PsKernelName) (type body : PsKernelExpr)
    (bi : PsKernelBinderInfo) :
    psKernelInferCacheEligible false (.forallE name type body bi) = false := by
  rfl
