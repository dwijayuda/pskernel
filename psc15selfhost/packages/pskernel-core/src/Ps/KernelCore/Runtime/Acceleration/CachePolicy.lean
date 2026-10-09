import Ps.KernelCore.Core.Expr

/-
Non-semantic checker cache policy.

This module decides whether an inference result is worth memoizing. It does not
read or mutate checker state and must not change the inferred type or
accept/reject judgment.

Checked application nodes are intentionally not memoized. A cold checked spine
visits each node once, while memoizing every growing application tree can force
expensive structural hashing/promotion in the portable cache. Checked lambda
and forall nodes are likewise commonly one-shot in generated declaration and
recursor-rule validation. Infer-only application, lambda and forall results
remain memoized because whole-expression inference results are commonly reused.
-/

/--
Maximum structural key size worth memoizing in the portable checker caches.

Cache entries are an acceleration only. Declining to memoize a larger closed
term cannot change kernel acceptance, while it prevents cache eligibility and
hashing from repeatedly traversing giant proof terms. The budget is consumed
across the whole expression tree, not independently per branch.
-/
def psKernelSemanticCacheNodeBudget : Nat :=
  256

def psKernelSemanticCacheRemainingReference :
    PsKernelExpr -> Nat -> Option Nat
  | _expr, Nat.zero =>
      Option.none
  | PsKernelExpr.fvar _, Nat.succ _ =>
      Option.none
  | PsKernelExpr.app fn arg, Nat.succ remaining =>
      match psKernelSemanticCacheRemainingReference fn remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelSemanticCacheRemainingReference arg next
  | PsKernelExpr.lam _ type body _, Nat.succ remaining =>
      match psKernelSemanticCacheRemainingReference type remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelSemanticCacheRemainingReference body next
  | PsKernelExpr.forallE _ type body _, Nat.succ remaining =>
      match psKernelSemanticCacheRemainingReference type remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelSemanticCacheRemainingReference body next
  | PsKernelExpr.letE _ type value body _, Nat.succ remaining =>
      match psKernelSemanticCacheRemainingReference type remaining with
      | Option.none => Option.none
      | Option.some afterType =>
          match psKernelSemanticCacheRemainingReference value afterType with
          | Option.none => Option.none
          | Option.some afterValue =>
              psKernelSemanticCacheRemainingReference body afterValue
  | PsKernelExpr.mdata _ body, Nat.succ remaining =>
      psKernelSemanticCacheRemainingReference body remaining
  | PsKernelExpr.proj _ _ body, Nat.succ remaining =>
      psKernelSemanticCacheRemainingReference body remaining
  | _expr, Nat.succ remaining =>
      Option.some remaining

/- Semantics-preserving no-per-node-Option acceleration.
   Encoding: 0 = failure, succ remaining = successful remaining budget.
   Reference above is retained as a specification for proof/differential tests. -/
def psKernelSemanticCacheRemainingFast :
    PsKernelExpr -> Nat -> Nat
  | _expr, Nat.zero =>
      0
  | PsKernelExpr.fvar _, Nat.succ _ =>
      0
  | PsKernelExpr.app fn arg, Nat.succ remaining =>
      let next := psKernelSemanticCacheRemainingFast fn remaining
      if Nat.beq next 0 then
        0
      else
        psKernelSemanticCacheRemainingFast arg (Nat.pred next)
  | PsKernelExpr.lam _ type body _, Nat.succ remaining =>
      let next := psKernelSemanticCacheRemainingFast type remaining
      if Nat.beq next 0 then
        0
      else
        psKernelSemanticCacheRemainingFast body (Nat.pred next)
  | PsKernelExpr.forallE _ type body _, Nat.succ remaining =>
      let next := psKernelSemanticCacheRemainingFast type remaining
      if Nat.beq next 0 then
        0
      else
        psKernelSemanticCacheRemainingFast body (Nat.pred next)
  | PsKernelExpr.letE _ type value body _, Nat.succ remaining =>
      let nextType := psKernelSemanticCacheRemainingFast type remaining
      if Nat.beq nextType 0 then
        0
      else
        let nextValue := psKernelSemanticCacheRemainingFast value (Nat.pred nextType)
        if Nat.beq nextValue 0 then
          0
        else
          psKernelSemanticCacheRemainingFast body (Nat.pred nextValue)
  | PsKernelExpr.mdata _ body, Nat.succ remaining =>
      psKernelSemanticCacheRemainingFast body remaining
  | PsKernelExpr.proj _ _ body, Nat.succ remaining =>
      psKernelSemanticCacheRemainingFast body remaining
  | _expr, Nat.succ remaining =>
      Nat.succ remaining

def psKernelSemanticCacheRemaining
    (expr : PsKernelExpr)
    (budget : Nat) : Option Nat :=
  let encoded := psKernelSemanticCacheRemainingFast expr budget
  if Nat.beq encoded 0 then
    Option.none
  else
    Option.some (Nat.pred encoded)

def psKernelSemanticCacheEligible
    (expr : PsKernelExpr) :
    Bool :=
  match
      psKernelSemanticCacheRemaining
        expr
        psKernelSemanticCacheNodeBudget with
  | Option.some _ => true
  | Option.none => false

def psKernelSemanticPairCacheEligible
    (left right : PsKernelExpr) :
    Bool :=
  if psKernelSemanticCacheEligible left then
    psKernelSemanticCacheEligible right
  else
    false

def psKernelInferCacheEligible
    (inferOnly : Bool)
    (expr : PsKernelExpr) :
    Bool :=
  if psKernelSemanticCacheEligible expr then
    match expr with
    | PsKernelExpr.lit _ =>
        false
    | PsKernelExpr.app _ _ =>
        inferOnly
    | PsKernelExpr.lam _ _ _ _ =>
        inferOnly
    | PsKernelExpr.forallE _ _ _ _ =>
        inferOnly
    | _ =>
        true
  else
    false

