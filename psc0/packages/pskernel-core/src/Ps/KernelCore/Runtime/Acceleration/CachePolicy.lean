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

def psKernelSemanticCacheRemaining :
    PsKernelExpr -> Nat -> Option Nat
  | _expr, Nat.zero =>
      Option.none
  | PsKernelExpr.fvar _, Nat.succ _ =>
      Option.none
  | PsKernelExpr.app fn arg, Nat.succ remaining =>
      match psKernelSemanticCacheRemaining fn remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelSemanticCacheRemaining arg next
  | PsKernelExpr.lam _ type body _, Nat.succ remaining =>
      match psKernelSemanticCacheRemaining type remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelSemanticCacheRemaining body next
  | PsKernelExpr.forallE _ type body _, Nat.succ remaining =>
      match psKernelSemanticCacheRemaining type remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelSemanticCacheRemaining body next
  | PsKernelExpr.letE _ type value body _, Nat.succ remaining =>
      match psKernelSemanticCacheRemaining type remaining with
      | Option.none => Option.none
      | Option.some afterType =>
          match psKernelSemanticCacheRemaining value afterType with
          | Option.none => Option.none
          | Option.some afterValue =>
              psKernelSemanticCacheRemaining body afterValue
  | PsKernelExpr.mdata _ body, Nat.succ remaining =>
      psKernelSemanticCacheRemaining body remaining
  | PsKernelExpr.proj _ _ body, Nat.succ remaining =>
      psKernelSemanticCacheRemaining body remaining
  | _expr, Nat.succ remaining =>
      Option.some remaining

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
  match expr with
  | PsKernelExpr.lit _ =>
      false
  | PsKernelExpr.app _ _ =>
      if inferOnly then psKernelSemanticCacheEligible expr else false
  | PsKernelExpr.lam _ _ _ _ =>
      if inferOnly then psKernelSemanticCacheEligible expr else false
  | PsKernelExpr.forallE _ _ _ _ =>
      if inferOnly then psKernelSemanticCacheEligible expr else false
  | _ =>
      psKernelSemanticCacheEligible expr

/--
Reduction caches live in a checker local scope. Unlike persistent closed-key
inference/equality caches, they must also memoize bounded open expressions:
repeated normalization of symbolic arithmetic can otherwise be exponential.
The 256-node key bound still prevents hashing giant expanded expression trees.

A caller must maintain the configuration invariant (the cache and local context
belong together). Binder exit restores all parent caches with
psKernelCheckerStateExitLocalScope; fresh declaration sessions start empty.
-/
def psKernelWhnfCacheRemaining :
    PsKernelExpr -> Nat -> Option Nat
  | _expr, Nat.zero =>
      Option.none
  | PsKernelExpr.app fn arg, Nat.succ remaining =>
      match psKernelWhnfCacheRemaining fn remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelWhnfCacheRemaining arg next
  | PsKernelExpr.lam _ type body _, Nat.succ remaining =>
      match psKernelWhnfCacheRemaining type remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelWhnfCacheRemaining body next
  | PsKernelExpr.forallE _ type body _, Nat.succ remaining =>
      match psKernelWhnfCacheRemaining type remaining with
      | Option.none => Option.none
      | Option.some next =>
          psKernelWhnfCacheRemaining body next
  | PsKernelExpr.letE _ type value body _, Nat.succ remaining =>
      match psKernelWhnfCacheRemaining type remaining with
      | Option.none => Option.none
      | Option.some afterType =>
          match psKernelWhnfCacheRemaining value afterType with
          | Option.none => Option.none
          | Option.some afterValue =>
              psKernelWhnfCacheRemaining body afterValue
  | PsKernelExpr.mdata _ body, Nat.succ remaining =>
      psKernelWhnfCacheRemaining body remaining
  | PsKernelExpr.proj _ _ body, Nat.succ remaining =>
      psKernelWhnfCacheRemaining body remaining
  | _expr, Nat.succ remaining =>
      Option.some remaining

def psKernelWhnfCacheEligible
    (expr : PsKernelExpr) :
    Bool :=
  match
      psKernelWhnfCacheRemaining
        expr
        psKernelSemanticCacheNodeBudget with
  | Option.some _ => true
  | Option.none => false

