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

/-- The substitution result of a bound variable at depth zero is exact. -/
theorem bound_zero_substitution_preserves_type
    (params : List KName) (ctx : List KExpr)
    (domain value : KExpr)
    (valueTyped : GeneralPiRule params ctx value domain) :
    GeneralPiRule params ctx
      ((KExpr.bvar 0).instantiateBVar value 0)
      ((domain.liftBVars 1 0).instantiateBVar value 0) := by
  simpa [KExpr.instantiateBVar,
    liftBVars_one_instantiate_cancel] using valueTyped

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
  · simpa [KExpr.instantiateBVar] using valueTyped

#print axioms liftBVars_one_instantiate_cancel
#print axioms bound_zero_substitution_preserves_type
#print axioms dependent_identity_beta_preserves_type

end PSKernelFast.Proof
