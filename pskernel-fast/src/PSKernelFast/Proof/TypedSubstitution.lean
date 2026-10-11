import PSKernelFast.Proof.GeneralPiScope

/-!
P1 typed-substitution vertical slice (not yet the full theorem).

We first prove that the ACTUAL executing de Bruijn operations cancel
a binder lift under any number of intervening binders. From this, the
actual G4.3b typing relation proves subject reduction for a dependent
identity beta-redex, under an explicitly checked domain and argument.

This IS a genuine nontrivial typing-preservation case for beta, unlike
the earlier structural-scope-only result. It does NOT establish a
general substitution theorem for arbitrary dependent body expressions,
nor denotational model soundness or kernel proof admission.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core

/--
A freshly lifted loose-variable index always survives instantiation
of the immediately enclosing binder, independent of the replacement.
The actual general liftBVars and instantiateBVar implementations are used.
-/
theorem liftBVars_one_instantiate_cancel
    (expr replacement : KExpr) (depth : Nat) :
    (expr.liftBVars 1 depth).instantiateBVar replacement depth = expr := by
  induction expr generalizing depth with
  | bvar index =>
      by_cases hLocal : index < depth
      · simp [KExpr.liftBVars, KExpr.instantiateBVar, hLocal]
      · have hOut : ¬ index + 1 < depth := by omega
        have hOther : index + 1 ≠ depth := by omega
        simp [KExpr.liftBVars, KExpr.instantiateBVar, hLocal,
          hOut, hOther]
  | fvar _ => rfl
  | mvar _ => rfl
  | sort _ => rfl
  | const _ _ => rfl
  | app fn arg ihFn ihArg =>
      simp [KExpr.liftBVars, KExpr.instantiateBVar,
        ihFn depth, ihArg depth]
  | lam name domain body style ihDomain ihBody =>
      simp [KExpr.liftBVars, KExpr.instantiateBVar,
        ihDomain depth, ihBody (depth + 1)]
  | forallE name domain body style ihDomain ihBody =>
      simp [KExpr.liftBVars, KExpr.instantiateBVar,
        ihDomain depth, ihBody (depth + 1)]
  | letE name ty val body flag ihTy ihVal ihBody =>
      simp [KExpr.liftBVars, KExpr.instantiateBVar,
        ihTy depth, ihVal depth, ihBody (depth + 1)]
  | lit _ => rfl
  | mdata tag inner ih =>
      simp [KExpr.liftBVars, KExpr.instantiateBVar, ih depth]
  | proj name index inner ih =>
      simp [KExpr.liftBVars, KExpr.instantiateBVar, ih depth]

/--
Lifting any term by ZERO positions changes nothing, for every binder cutoff.
This is an equality of the *actual* implementation, not a heuristic.
-/
theorem liftBVars_zero (expr : KExpr) (cutoff : Nat) :
    expr.liftBVars 0 cutoff = expr := by
  induction expr generalizing cutoff with
  | bvar index =>
      by_cases h : index < cutoff
      · simp [KExpr.liftBVars, h]
      · simp [KExpr.liftBVars, h]
  | fvar _ => rfl
  | mvar _ => rfl
  | sort _ => rfl
  | const _ _ => rfl
  | app fn arg ihFn ihArg =>
      simp [KExpr.liftBVars, ihFn cutoff, ihArg cutoff]
  | lam name domain body style ihDomain ihBody =>
      simp [KExpr.liftBVars, ihDomain cutoff, ihBody (cutoff + 1)]
  | forallE name domain body style ihDomain ihBody =>
      simp [KExpr.liftBVars, ihDomain cutoff, ihBody (cutoff + 1)]
  | letE name ty val body flag ihTy ihVal ihBody =>
      simp [KExpr.liftBVars, ihTy cutoff, ihVal cutoff,
        ihBody (cutoff + 1)]
  | lit _ => rfl
  | mdata tag inner ih =>
      simp [KExpr.liftBVars, ih cutoff]
  | proj name index inner ih =>
      simp [KExpr.liftBVars, ih cutoff]

/--
Two shifts at the same binder cutoff compose by adding their amounts.
This is a pure equation about actual CoreSyntax operations and works
under arbitrarily nested Pi, lambda and let binders.
-/
theorem liftBVars_add (expr : KExpr) (first second cutoff : Nat) :
    (expr.liftBVars first cutoff).liftBVars second cutoff =
      expr.liftBVars (first + second) cutoff := by
  induction expr generalizing cutoff with
  | bvar index =>
      by_cases hLocal : index < cutoff
      · simp [KExpr.liftBVars, hLocal]
      · have hOuter : ¬ index + first < cutoff := by omega
        simp [KExpr.liftBVars, hLocal, hOuter, Nat.add_assoc]
  | fvar _ => rfl
  | mvar _ => rfl
  | sort _ => rfl
  | const _ _ => rfl
  | app fn arg ihFn ihArg =>
      simp [KExpr.liftBVars, ihFn cutoff, ihArg cutoff]
  | lam name domain body style ihDomain ihBody =>
      simp [KExpr.liftBVars, ihDomain cutoff, ihBody (cutoff + 1)]
  | forallE name domain body style ihDomain ihBody =>
      simp [KExpr.liftBVars, ihDomain cutoff, ihBody (cutoff + 1)]
  | letE name ty val body flag ihTy ihVal ihBody =>
      simp [KExpr.liftBVars, ihTy cutoff, ihVal cutoff,
        ihBody (cutoff + 1)]
  | lit _ => rfl
  | mdata tag inner ih =>
      simp [KExpr.liftBVars, ih cutoff]
  | proj name index inner ih =>
      simp [KExpr.liftBVars, ih cutoff]

/-- Two positive binder shifts at the same cutoff commute. -/
theorem liftBVars_comm (expr : KExpr) (first second cutoff : Nat) :
    (expr.liftBVars first cutoff).liftBVars second cutoff =
      (expr.liftBVars second cutoff).liftBVars first cutoff := by
  calc
    (expr.liftBVars first cutoff).liftBVars second cutoff =
        expr.liftBVars (first + second) cutoff :=
          liftBVars_add expr first second cutoff
    _ = expr.liftBVars (second + first) cutoff := by rw [Nat.add_comm]
    _ = (expr.liftBVars second cutoff).liftBVars first cutoff :=
      (liftBVars_add expr second first cutoff).symm

/-- The substitution result of a bound variable at depth zero is exact. -/
theorem bound_zero_substitution_preserves_type
    (params : List KName) (ctx : List KExpr)
    (domain value : KExpr)
    (valueTyped : GeneralPiRule params ctx value domain) :
    GeneralPiRule params ctx
      ((KExpr.bvar 0).instantiateBVar value 0)
      ((domain.liftBVars 1 0).instantiateBVar value 0) := by
  simpa [KExpr.instantiateBVar,
    liftBVars_one_instantiate_cancel, liftBVars_zero] using valueTyped

/--
A typing derivation for the application of a dependent identity
is constructed from the actual six rules, then its beta-reduced
term is *independently* shown to retain the exact inferred type.
There is no invocation of general DefEq or an unchecked theorem body.
-/
theorem dependent_identity_beta_preserves_type
    (params : List KName) (ctx : List KExpr)
    (contextWF : GeneralPiContextWF params ctx)
    (name : KName) (style : BinderStyle)
    (domain value : KExpr) (level : ULevel)
    (domainTyped : GeneralPiRule params ctx domain (.sort level))
    (valueTyped : GeneralPiRule params ctx value domain) :
    GeneralPiRule params ctx
      (.app (.lam name domain (.bvar 0) style) value) domain ∧
    GeneralPiRule params ctx
      ((KExpr.bvar 0).instantiateBVar value 0) domain := by
  have hBound : GeneralPiRule params (domain :: ctx)
      (.bvar 0) (domain.liftBVars 1 0) :=
    .bound (domain :: ctx) 0 domain rfl
  have hLam : GeneralPiRule params ctx
      (.lam name domain (.bvar 0) style)
      (.forallE name domain (domain.liftBVars 1 0) style) :=
    .lam ctx name domain (.bvar 0) style level
      (domain.liftBVars 1 0) domainTyped hBound
  have hApp : GeneralPiRule params ctx
      (.app (.lam name domain (.bvar 0) style) value)
      ((domain.liftBVars 1 0).instantiateBVar value 0) :=
    .app ctx (.lam name domain (.bvar 0) style) value
      name domain (domain.liftBVars 1 0) style hLam valueTyped
  constructor
  · simpa [liftBVars_one_instantiate_cancel] using hApp
  · simpa [KExpr.instantiateBVar, liftBVars_zero] using valueTyped


/--
Checked zeta reduction of the newest, potentially dependent binder.
The exact executing `letE` rule, rather than a second invented let rule,
inferred the original term's type from the body `bvar 0`. Replacing that
binder with its well-typed value preserves the same type.

This is a second bounded subject-reduction case, NOT arbitrary typed
substitution for all possible binder bodies.
-/
theorem dependent_let_variable_zeta_preserves_type
    (params : List KName) (ctx : List KExpr)
    (contextWF : GeneralPiContextWF params ctx)
    (name : KName) (domain value : KExpr) (level : ULevel)
    (domainTyped : GeneralPiRule params ctx domain (.sort level))
    (valueTyped : GeneralPiRule params ctx value domain) :
    GeneralPiRule params ctx
      (.letE name domain value (.bvar 0) false) domain ∧
    GeneralPiRule params ctx
      ((KExpr.bvar 0).instantiateBVar value 0) domain := by
  have hBound : GeneralPiRule params (domain :: ctx)
      (.bvar 0) (domain.liftBVars 1 0) :=
    .bound (domain :: ctx) 0 domain rfl
  have hLet : GeneralPiRule params ctx
      (.letE name domain value (.bvar 0) false)
      ((domain.liftBVars 1 0).instantiateBVar value 0) :=
    .letE ctx name domain value (.bvar 0) false rfl level
      (domain.liftBVars 1 0) domainTyped valueTyped hBound
  constructor
  · simpa [liftBVars_one_instantiate_cancel] using hLet
  · simpa [KExpr.instantiateBVar, liftBVars_zero] using valueTyped

#print axioms liftBVars_one_instantiate_cancel
#print axioms liftBVars_add
#print axioms liftBVars_comm
#print axioms liftBVars_zero
#print axioms bound_zero_substitution_preserves_type
#print axioms dependent_identity_beta_preserves_type
#print axioms dependent_let_variable_zeta_preserves_type

end PSKernelFast.Proof
