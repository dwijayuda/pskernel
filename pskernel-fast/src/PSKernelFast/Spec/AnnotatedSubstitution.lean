import PSKernelFast.Spec.TaggedDependentPi

/-!
P1n: full six-constructor PROOF-SIDE term interpretation and substitution.

Only Pi/lambda carry a codomain-sort valuation. Those annotations are
preserved by lifting and instantiation; erasure forgets them. This syntax
is NOT an accepting checker. Correctness of annotations for arbitrary
source typing derivations is a separate obligation. In particular, an
erasure equation cannot certify a Prop/Type regime.

The interpretation reuses the existing tagged-Prop/graph-Type algebra.
No new model operation or axiom is postulated. Substitution is proved at
ARBITRARY depth, through Pi, lambda and let binders, under arbitrary model
environments. The source connection reuses Proof.Erasure separately.
All set-model claims remain conditional on supplied SetTheoryBasis V.
-/

namespace PSKernelFast.Spec

universe u

inductive AnnotatedModelTerm where
  | bvar (index : Nat)
  | sort (level : Nat)
  | app (fn arg : AnnotatedModelTerm)
  | lam (codomainRank : Nat) (domain body : AnnotatedModelTerm)
  | pi (codomainRank : Nat) (domain body : AnnotatedModelTerm)
  | letE (type value body : AnnotatedModelTerm)
  deriving Repr, Inhabited, BEq, DecidableEq

def AnnotatedModelTerm.forget : AnnotatedModelTerm → ErasedExpr
  | .bvar i => .bvar i
  | .sort n => .sort n
  | .app f a => .app f.forget a.forget
  | .lam _ a b => .lam a.forget b.forget
  | .pi _ a b => .pi a.forget b.forget
  | .letE a v b => .letE a.forget v.forget b.forget

def AnnotatedModelTerm.lift (amount cutoff : Nat) :
    AnnotatedModelTerm → AnnotatedModelTerm
  | .bvar i => if i < cutoff then .bvar i else .bvar (i + amount)
  | .sort n => .sort n
  | .app f a => .app (f.lift amount cutoff) (a.lift amount cutoff)
  | .lam n a b => .lam n (a.lift amount cutoff) (b.lift amount (cutoff + 1))
  | .pi n a b => .pi n (a.lift amount cutoff) (b.lift amount (cutoff + 1))
  | .letE a v b => .letE (a.lift amount cutoff) (v.lift amount cutoff)
      (b.lift amount (cutoff + 1))

def AnnotatedModelTerm.instantiate (term replacement : AnnotatedModelTerm)
    (depth : Nat) : AnnotatedModelTerm :=
  match term with
  | .bvar i =>
      if i < depth then .bvar i
      else if i = depth then replacement.lift depth 0
      else .bvar (i - 1)
  | .sort n => .sort n
  | .app f a => .app (f.instantiate replacement depth) (a.instantiate replacement depth)
  | .lam n a b => .lam n (a.instantiate replacement depth)
      (b.instantiate replacement (depth + 1))
  | .pi n a b => .pi n (a.instantiate replacement depth)
      (b.instantiate replacement (depth + 1))
  | .letE a v b => .letE (a.instantiate replacement depth)
      (v.instantiate replacement depth) (b.instantiate replacement (depth + 1))

/-- Concrete commutation with the ALREADY source-matched erased operations. -/
theorem AnnotatedModelTerm.forget_lift (term : AnnotatedModelTerm)
    (amount cutoff : Nat) :
    (term.lift amount cutoff).forget = term.forget.lift amount cutoff := by
  induction term generalizing cutoff with
  | bvar i =>
      by_cases h : i < cutoff <;> simp [lift, forget, ErasedExpr.lift, h]
  | sort n => rfl
  | app f a ihf iha => simp only [lift, forget, ErasedExpr.lift, ihf, iha]
  | lam n a b iha ihb => simp only [lift, forget, ErasedExpr.lift, iha, ihb]
  | pi n a b iha ihb => simp only [lift, forget, ErasedExpr.lift, iha, ihb]
  | letE a v b iha ihv ihb => simp only [lift, forget, ErasedExpr.lift, iha, ihv, ihb]

theorem AnnotatedModelTerm.forget_instantiate (term replacement : AnnotatedModelTerm)
    (depth : Nat) :
    (term.instantiate replacement depth).forget =
      term.forget.instantiate replacement.forget depth := by
  induction term generalizing depth with
  | bvar i =>
      by_cases h : i < depth
      · simp [instantiate, forget, ErasedExpr.instantiate, h]
      · by_cases he : i = depth <;>
          simp [instantiate, forget, ErasedExpr.instantiate, h, he, forget_lift]
  | sort n => rfl
  | app f a ihf iha => simp only [instantiate, forget, ErasedExpr.instantiate, ihf, iha]
  | lam n a b iha ihb => simp only [instantiate, forget, ErasedExpr.instantiate, iha, ihb]
  | pi n a b iha ihb => simp only [instantiate, forget, ErasedExpr.instantiate, iha, ihb]
  | letE a v b iha ihv ihb =>
      simp only [instantiate, forget, ErasedExpr.instantiate, iha, ihv, ihb]

/-- Total mathematical interpretation; no claim that arbitrary terms are typed. -/
noncomputable def interpAnnotated (V : Type u) [SetTheoryBasis V]
    (env : Nat → V) : AnnotatedModelTerm → V
  | .bvar i => env i
  | .sort n => taggedSortSet V n
  | .app f a => modelApp V (interpAnnotated V env f) (interpAnnotated V env a)
  | .lam n a b => modelLam V n (interpAnnotated V env a)
      (fun x => interpAnnotated V (extendSetEnv x env) b)
  | .pi n a b => modelPi V n (interpAnnotated V env a)
      (fun x => interpAnnotated V (extendSetEnv x env) b)
  | .letE _ v b => interpAnnotated V (extendSetEnv (interpAnnotated V env v) env) b

/-- Pull an environment back through the exact de Bruijn lifting map. -/
def pullLiftEnv {V : Type u} (amount cutoff : Nat) (env : Nat → V) : Nat → V :=
  fun i => env (if i < cutoff then i else i + amount)

def dropModelEnv {V : Type u} (depth : Nat) (env : Nat → V) : Nat → V :=
  fun i => env (i + depth)

/-- Insert a semantic value at the removed source binder's exact depth. -/
def insertModelEnv {V : Type u} (depth : Nat) (value : V) (env : Nat → V) : Nat → V :=
  fun i => if i < depth then env i else if i = depth then value else env (i - 1)

private theorem pullLiftEnv_cons {V : Type u}
    (amount cutoff : Nat) (x : V) (env : Nat → V) :
    pullLiftEnv amount (cutoff + 1) (extendSetEnv x env) =
      extendSetEnv x (pullLiftEnv amount cutoff env) := by
  funext i
  cases i with
  | zero => simp [pullLiftEnv, extendSetEnv]
  | succ i =>
      by_cases h : i < cutoff
      · have hs : i + 1 < cutoff + 1 := by omega
        simp [pullLiftEnv, extendSetEnv, h, hs]
      · have hs : ¬ i + 1 < cutoff + 1 := by omega
        simp [pullLiftEnv, extendSetEnv, h, hs, Nat.succ_add]

private theorem pullLiftEnv_zero {V : Type u} (amount : Nat) (env : Nat → V) :
    pullLiftEnv amount 0 env = dropModelEnv amount env := by
  funext i
  simp [pullLiftEnv, dropModelEnv]

private theorem dropModelEnv_cons {V : Type u} (depth : Nat) (x : V) (env : Nat → V) :
    dropModelEnv (depth + 1) (extendSetEnv x env) = dropModelEnv depth env := by
  funext i
  simp [dropModelEnv, Nat.add_succ, extendSetEnv]

private theorem insertModelEnv_cons {V : Type u}
    (depth : Nat) (value x : V) (env : Nat → V) :
    insertModelEnv (depth + 1) value (extendSetEnv x env) =
      extendSetEnv x (insertModelEnv depth value env) := by
  funext i
  cases i with
  | zero => simp [insertModelEnv, extendSetEnv]
  | succ i =>
      by_cases h : i < depth
      · have hs : i + 1 < depth + 1 := by omega
        simp [insertModelEnv, extendSetEnv, h, hs]
      · by_cases he : i = depth
        · subst i
          simp [insertModelEnv, extendSetEnv]
        · have hs : ¬ i + 1 < depth + 1 := by omega
          have hes : i + 1 ≠ depth + 1 := by omega
          have hpos : 0 < i := by omega
          cases i with
          | zero => omega
          | succ j => simp [insertModelEnv, extendSetEnv, h, he, hs, hes]

private theorem insertModelEnv_zero {V : Type u} (x : V) (env : Nat → V) :
    insertModelEnv 0 x env = extendSetEnv x env := by
  funext i
  cases i <;> simp [insertModelEnv, extendSetEnv]

/-- Semantic weakening for ALL annotated terms, at any cutoff. -/
theorem interpAnnotated_lift (V : Type u) [SetTheoryBasis V]
    (term : AnnotatedModelTerm) (amount cutoff : Nat) (env : Nat → V) :
    interpAnnotated V env (term.lift amount cutoff) =
      interpAnnotated V (pullLiftEnv amount cutoff env) term := by
  induction term generalizing cutoff env with
  | bvar i =>
      by_cases h : i < cutoff <;>
        simp [AnnotatedModelTerm.lift, interpAnnotated, pullLiftEnv, h]
  | sort n => rfl
  | app f a ihf iha => simp only [AnnotatedModelTerm.lift, interpAnnotated, ihf, iha]
  | lam n a b iha ihb =>
      simp only [AnnotatedModelTerm.lift, interpAnnotated, iha, ihb, pullLiftEnv_cons]
  | pi n a b iha ihb =>
      simp only [AnnotatedModelTerm.lift, interpAnnotated, iha, ihb, pullLiftEnv_cons]
  | letE a v b iha ihv ihb =>
      simp only [AnnotatedModelTerm.lift, interpAnnotated, ihv, ihb, pullLiftEnv_cons]

/--
General substitution lemma, not a beta example. Replacement is interpreted
outside the depth local binders; the exact inserted environment restores it.
No typing/fibre validity or intended semantic substitution law is assumed.
-/
theorem interpAnnotated_instantiate (V : Type u) [SetTheoryBasis V]
    (term replacement : AnnotatedModelTerm) (depth : Nat) (env : Nat → V) :
    interpAnnotated V env (term.instantiate replacement depth) =
      interpAnnotated V
        (insertModelEnv depth (interpAnnotated V (dropModelEnv depth env) replacement) env)
        term := by
  induction term generalizing depth env with
  | bvar i =>
      by_cases h : i < depth
      · simp [AnnotatedModelTerm.instantiate, interpAnnotated, insertModelEnv, h]
      · by_cases he : i = depth
        · subst i
          simp [AnnotatedModelTerm.instantiate, interpAnnotated, insertModelEnv,
            interpAnnotated_lift, pullLiftEnv_zero]
        · simp [AnnotatedModelTerm.instantiate, interpAnnotated, insertModelEnv, h, he]
  | sort n => rfl
  | app f a ihf iha =>
      simp only [AnnotatedModelTerm.instantiate, interpAnnotated, ihf, iha]
  | lam n a b iha ihb =>
      simp only [AnnotatedModelTerm.instantiate, interpAnnotated, iha, ihb,
        dropModelEnv_cons, insertModelEnv_cons]
  | pi n a b iha ihb =>
      simp only [AnnotatedModelTerm.instantiate, interpAnnotated, iha, ihb,
        dropModelEnv_cons, insertModelEnv_cons]
  | letE a v b iha ihv ihb =>
      simp only [AnnotatedModelTerm.instantiate, interpAnnotated, ihv, ihb,
        dropModelEnv_cons, insertModelEnv_cons]

/-- The exact head-substitution equation used by source beta and zeta. -/
theorem interpAnnotated_instantiate_zero (V : Type u) [SetTheoryBasis V]
    (body arg : AnnotatedModelTerm) (env : Nat → V) :
    interpAnnotated V env (body.instantiate arg 0) =
      interpAnnotated V (extendSetEnv (interpAnnotated V env arg) env) body := by
  have hDrop : dropModelEnv 0 env = env := rfl
  have h := interpAnnotated_instantiate V body arg 0 env
  rw [hDrop, insertModelEnv_zero] at h
  exact h

#print axioms AnnotatedModelTerm.forget_lift
#print axioms AnnotatedModelTerm.forget_instantiate
#print axioms interpAnnotated_lift
#print axioms interpAnnotated_instantiate
#print axioms interpAnnotated_instantiate_zero

end PSKernelFast.Spec
