import Ps.KernelCore.Core.Expr

/-
Non-semantic checker cache policy.

This module decides whether an inference result is worth memoizing.
Open keys are valid only in their checker configuration. Binder exit restores
parent caches and new declaration sessions start empty; cache state must never
be transplanted into a different local context. It does not
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

Cache entries are an acceleration only. Declining to memoize a larger
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
Checker caches live in a fixed environment and local scope. They memoize
bounded open expressions:
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



namespace PsKernelCacheScan

/-- Zero encodes budget exhaustion; succ n encodes exactly n unused nodes.
The recursive worker uses scalar Nat values instead of allocating Option at
every expression node. The public specification remains Option Nat. -/
def decode : Nat → Option Nat
  | 0 => none
  | n + 1 => some n

@[simp] theorem decode_zero : decode 0 = none := rfl
@[simp] theorem decode_succ (n : Nat) : decode (n + 1) = some n := rfl

@[inline] def bind (code : Nat) (next : Nat → Nat) : Nat :=
  match code with
  | 0 => 0
  | n + 1 => next n

theorem decode_bind (code : Nat) (next : Nat → Nat) :
    decode (bind code next) =
      (match decode code with
       | none => none
       | some n => decode (next n)) := by
  cases code <;> rfl

def remaining (expr : PsKernelExpr) (fuel : Nat) : Nat :=
  match fuel with
  | 0 => 0
  | n + 1 =>
    match expr with
    | .app f x => bind (remaining f n) (fun left => remaining x left)
    | .lam _ t b _ | .forallE _ t b _ =>
        bind (remaining t n) (fun left => remaining b left)
    | .letE _ t v b _ =>
        bind (remaining t n) (fun left =>
          bind (remaining v left) (fun rest => remaining b rest))
    | .mdata _ b | .proj _ _ b => remaining b n
    | _ => n + 1
termination_by structural expr

theorem remaining_eq (expr : PsKernelExpr) (fuel : Nat) :
    decode (remaining expr fuel) = psKernelSemanticCacheRemaining expr fuel := by
  induction expr generalizing fuel <;> cases fuel <;>
    simp_all [remaining, decode_bind, psKernelSemanticCacheRemaining,
      Option.bind]

theorem semantic_whnf_eq (expr : PsKernelExpr) (fuel : Nat) :
    psKernelSemanticCacheRemaining expr fuel = psKernelWhnfCacheRemaining expr fuel := by
  induction expr generalizing fuel <;> cases fuel <;>
    simp_all [psKernelSemanticCacheRemaining, psKernelWhnfCacheRemaining]

end PsKernelCacheScan

def psKernelSemanticCacheRemainingScalar (expr : PsKernelExpr) (fuel : Nat) : Option Nat :=
  PsKernelCacheScan.decode (PsKernelCacheScan.remaining expr fuel)

@[csimp] theorem psKernelSemanticCacheRemaining_scalar_eq :
    psKernelSemanticCacheRemaining = psKernelSemanticCacheRemainingScalar := by
  funext expr fuel
  exact (PsKernelCacheScan.remaining_eq expr fuel).symm

@[csimp] theorem psKernelWhnfCacheRemaining_scalar_eq :
    psKernelWhnfCacheRemaining = psKernelSemanticCacheRemainingScalar := by
  funext expr fuel
  exact (PsKernelCacheScan.semantic_whnf_eq expr fuel).symm.trans
    (PsKernelCacheScan.remaining_eq expr fuel).symm

def psKernelSemanticCacheEligibleScalar (expr : PsKernelExpr) : Bool :=
  match PsKernelCacheScan.remaining expr psKernelSemanticCacheNodeBudget with
  | 0 => false
  | _ + 1 => true

@[csimp] theorem psKernelSemanticCacheEligible_scalar_eq :
    psKernelSemanticCacheEligible = psKernelSemanticCacheEligibleScalar := by
  funext expr
  unfold psKernelSemanticCacheEligible psKernelSemanticCacheEligibleScalar
  rw [← PsKernelCacheScan.remaining_eq]
  cases PsKernelCacheScan.remaining expr psKernelSemanticCacheNodeBudget <;> rfl

@[csimp] theorem psKernelWhnfCacheEligible_scalar_eq :
    psKernelWhnfCacheEligible = psKernelSemanticCacheEligibleScalar := by
  funext expr
  unfold psKernelWhnfCacheEligible psKernelSemanticCacheEligibleScalar
  rw [← PsKernelCacheScan.semantic_whnf_eq, ← PsKernelCacheScan.remaining_eq]
  cases PsKernelCacheScan.remaining expr psKernelSemanticCacheNodeBudget <;> rfl

/-- These wrappers propagate the proved scalar scan into callers that were
compiled before its compiler-simplification theorem was registered. -/
def psKernelSemanticPairCacheEligibleScalar (left right : PsKernelExpr) : Bool :=
  if psKernelSemanticCacheEligibleScalar left then
    psKernelSemanticCacheEligibleScalar right else false

@[csimp] theorem psKernelSemanticPairCacheEligible_scalar_eq :
    psKernelSemanticPairCacheEligible = psKernelSemanticPairCacheEligibleScalar := by
  funext left right
  simp only [psKernelSemanticPairCacheEligible, psKernelSemanticPairCacheEligibleScalar,
    ← psKernelSemanticCacheEligible_scalar_eq]

def psKernelInferCacheEligibleScalar (inferOnly : Bool) (expr : PsKernelExpr) : Bool :=
  match expr with
  | .lit _ => false
  | .app .. | .lam .. | .forallE .. =>
      if inferOnly then psKernelSemanticCacheEligibleScalar expr else false
  | _ => psKernelSemanticCacheEligibleScalar expr

@[csimp] theorem psKernelInferCacheEligible_scalar_eq :
    psKernelInferCacheEligible = psKernelInferCacheEligibleScalar := by
  funext inferOnly expr
  cases expr <;>
    simp only [psKernelInferCacheEligible, psKernelInferCacheEligibleScalar,
      ← psKernelSemanticCacheEligible_scalar_eq]
