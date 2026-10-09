import Ps.KernelCore.Runtime.Acceleration.CachePolicy

/- An independent Option-returning specification stays in CachePolicy.lean.
   Fast returns zero on failure, or succ of the unused budget on success.
   This theorem excludes new cache eligibility for every possible input. -/
private def psKernelEncodeRemaining : Option Nat → Nat
  | .none => 0
  | .some n => Nat.succ n

private theorem psKernelEncodeSequence
    (first : Option Nat)
    (next : Nat → Option Nat)
    (nextFast : Nat → Nat)
    (hNext : ∀ n, nextFast n = psKernelEncodeRemaining (next n)) :
    (if Nat.beq (psKernelEncodeRemaining first) 0 then 0
     else nextFast (Nat.pred (psKernelEncodeRemaining first))) =
       psKernelEncodeRemaining (first.bind next) := by
  cases first with
  | none => rfl
  | some n => simpa [psKernelEncodeRemaining] using hNext n

theorem psKernelSemanticCacheRemainingFast_refines
    (expr : PsKernelExpr) :
    ∀ budget : Nat,
      psKernelSemanticCacheRemainingFast expr budget =
        psKernelEncodeRemaining (psKernelSemanticCacheRemainingReference expr budget) := by
  induction expr with
  | bvar _ =>
      intro budget
      cases budget <;> rfl
  | fvar _ =>
      intro budget
      cases budget <;> rfl
  | mvar _ =>
      intro budget
      cases budget <;> rfl
  | sort _ =>
      intro budget
      cases budget <;> rfl
  | const _ _ =>
      intro budget
      cases budget <;> rfl
  | lit _ =>
      intro budget
      cases budget <;> rfl
  | app fn arg ihFn ihArg =>
      intro budget
      cases budget with
      | zero => rfl
      | succ n =>
          rw [ihFn n]
          exact psKernelEncodeSequence
            (psKernelSemanticCacheRemainingReference fn n)
            (fun rem => psKernelSemanticCacheRemainingReference arg rem)
            (fun rem => psKernelSemanticCacheRemainingFast arg rem)
            ihArg
  | lam _ type body _ ihType ihBody =>
      intro budget
      cases budget with
      | zero => rfl
      | succ n =>
          rw [ihType n]
          exact psKernelEncodeSequence
            (psKernelSemanticCacheRemainingReference type n)
            (fun rem => psKernelSemanticCacheRemainingReference body rem)
            (fun rem => psKernelSemanticCacheRemainingFast body rem)
            ihBody
  | forallE _ type body _ ihType ihBody =>
      intro budget
      cases budget with
      | zero => rfl
      | succ n =>
          rw [ihType n]
          exact psKernelEncodeSequence
            (psKernelSemanticCacheRemainingReference type n)
            (fun rem => psKernelSemanticCacheRemainingReference body rem)
            (fun rem => psKernelSemanticCacheRemainingFast body rem)
            ihBody
  | letE _ type value body _ ihType ihValue ihBody =>
      intro budget
      cases budget with
      | zero => rfl
      | succ n =>
          rw [ihType n]
          cases hType : psKernelSemanticCacheRemainingReference type n with
          | none =>
              simp [psKernelEncodeRemaining, hType]
          | some typeRest =>
              simpa [psKernelEncodeRemaining, hType, ihValue typeRest] using
                (psKernelEncodeSequence
                  (psKernelSemanticCacheRemainingReference value typeRest)
                  (fun valueRest => psKernelSemanticCacheRemainingReference body valueRest)
                  (fun valueRest => psKernelSemanticCacheRemainingFast body valueRest)
                  ihBody)
  | mdata _ body ihBody =>
      intro budget
      cases budget with
      | zero => rfl
      | succ n =>
          change
            psKernelSemanticCacheRemainingFast body n =
              psKernelEncodeRemaining (psKernelSemanticCacheRemainingReference body n)
          exact ihBody n
  | proj _ _ body ihBody =>
      intro budget
      cases budget with
      | zero => rfl
      | succ n =>
          change
            psKernelSemanticCacheRemainingFast body n =
              psKernelEncodeRemaining (psKernelSemanticCacheRemainingReference body n)
          exact ihBody n

theorem psKernelSemanticCacheRemaining_fast_equals_reference
    (expr : PsKernelExpr) (budget : Nat) :
    psKernelSemanticCacheRemaining expr budget =
      psKernelSemanticCacheRemainingReference expr budget := by
  simp only [psKernelSemanticCacheRemaining,
    psKernelSemanticCacheRemainingFast_refines expr budget]
  cases h : psKernelSemanticCacheRemainingReference expr budget with
  | none => rfl
  | some n => rfl


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
      psKernelSemanticCacheRemainingReference (PsKernelExpr.fvar name) fuel = none := by
    intro fuel
    cases fuel <;> rfl
  unfold psKernelSemanticCacheEligible
  rw [psKernelSemanticCacheRemaining_fast_equals_reference]
  cases hFn : psKernelSemanticCacheRemainingReference fn 255 with
  | none =>
      simp [psKernelSemanticCacheNodeBudget,
        psKernelSemanticCacheRemainingReference, hFn, hFVar]
  | some remaining =>
      simp [psKernelSemanticCacheNodeBudget,
        psKernelSemanticCacheRemainingReference, hFn, hFVar]

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
  rfl

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
  rfl

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
