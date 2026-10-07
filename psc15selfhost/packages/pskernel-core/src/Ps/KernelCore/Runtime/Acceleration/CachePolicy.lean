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

def psKernelSemanticCacheRemaining
    (fuel : Nat) :
    PsKernelExpr -> Option Nat :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsKernelExpr) =>
        Option.none
  | Nat.succ remaining =>
      let smaller : Nat -> PsKernelExpr -> Option Nat :=
        psKernelSemanticCacheRemaining;
      fun (expr : PsKernelExpr) =>
        match expr with
        | PsKernelExpr.fvar _ =>
            Option.none
        | PsKernelExpr.app fn arg =>
            match smaller remaining fn with
            | Option.none => Option.none
            | Option.some next => smaller next arg
        | PsKernelExpr.lam _ type body _ =>
            match smaller remaining type with
            | Option.none => Option.none
            | Option.some next => smaller next body
        | PsKernelExpr.forallE _ type body _ =>
            match smaller remaining type with
            | Option.none => Option.none
            | Option.some next => smaller next body
        | PsKernelExpr.letE _ type value body _ =>
            match smaller remaining type with
            | Option.none => Option.none
            | Option.some afterType =>
                match smaller afterType value with
                | Option.none => Option.none
                | Option.some afterValue =>
                    smaller afterValue body
        | PsKernelExpr.mdata _ body =>
            smaller remaining body
        | PsKernelExpr.proj _ _ body =>
            smaller remaining body
        | _ =>
            Option.some remaining

def psKernelSemanticCacheEligible
    (expr : PsKernelExpr) :
    Bool :=
  match
      psKernelSemanticCacheRemaining
        psKernelSemanticCacheNodeBudget
        expr with
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

