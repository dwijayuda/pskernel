import PSKernelFast.CoreSyntaxProofs

/-!
G4.3 research-only DEPENDENT Sort/Pi formation fragment.

Unlike the old closed syntactic-Pi fragment, this independently specified
judgment supports variables and genuinely dependent Pi codomains under a
restricted verified context whose binder domains are literally `Sort u`.

The output is a source-matched certificate of THIS precise rule fragment,
not general Lean type inference, DefEq, a verified environment, executable
proof admission or a model-theoretic soundness theorem.
-/

namespace PSKernelFast.Core

/-- A universe with a proof of allowed parameters and no level metavariables. -/
abbrev VerifiedSortLevel (params : List KName) :=
  {level : ULevel // ULevel.WellFormed params level}

/--
A separate, intentionally narrow declarative relation for expressions
whose inferred type is `Sort level`. Context entries are actual validated
universe levels, representing syntactically Sort-shaped binder domains.
-/
inductive DependentSortRule (params : List KName) :
    List (VerifiedSortLevel params) → KExpr → ULevel → Prop where
  | sort (ctx : List (VerifiedSortLevel params))
      (u : VerifiedSortLevel params) :
      DependentSortRule params ctx (.sort u.val) (.succ u.val)
  | boundVar (ctx : List (VerifiedSortLevel params))
      (index : Nat) (domain : VerifiedSortLevel params)
      (found : ctx[index]? = some domain) :
      DependentSortRule params ctx (.bvar index) domain.val
  | pi (ctx : List (VerifiedSortLevel params))
      (name : KName) (domain : VerifiedSortLevel params)
      (body : KExpr) (style : BinderStyle) (bodyLevel : ULevel)
      (bodyTyped :
        DependentSortRule params (domain :: ctx) body bodyLevel) :
      DependentSortRule params ctx
        (.forallE name (.sort domain.val) body style)
        (.imax (.succ domain.val) bodyLevel)

/--
Exact executable inference for the tiny dependent rule fragment.
Certificates are built by this recursion from checked parameters and
context entries; no untrusted catalog or unchecked type annotation is read.
-/
def inferDependentSort {params : List KName}
    (ctx : List (VerifiedSortLevel params)) :
    (expr : KExpr) →
      Option {level : ULevel // DependentSortRule params ctx expr level}
  | .sort u =>
      if h : u.validParams params = true then
        let checked : VerifiedSortLevel params :=
          ⟨u, ULevel.validParams_sound params u h⟩
        some ⟨.succ u, .sort ctx checked⟩
      else
        none
  | .bvar index =>
      match h : ctx[index]? with
      | some checked =>
          some ⟨checked.val, .boundVar ctx index checked h⟩
      | none => none
  | .forallE name (.sort u) body style =>
      if h : u.validParams params = true then
        let checked : VerifiedSortLevel params :=
          ⟨u, ULevel.validParams_sound params u h⟩
        match inferDependentSort (checked :: ctx) body with
        | some witness =>
            some ⟨.imax (.succ u) witness.val,
              .pi ctx name checked body style witness.val witness.property⟩
        | none => none
      else
        none
  | _ => none

inductive DependentSortError where
  | malformed
  | unsupported
  deriving Inhabited, Repr, BEq

/--
Only closed source inputs can enter this prototype. Unsupported forms are
NOT accepted by guessing a type; malformed inputs retain their category.
-/
def inferClosedDependentSort (params : List KName) (expr : KExpr) :
    Except DependentSortError ULevel :=
  if h : expr.closedInput params = true then
    match inferDependentSort ([] : List (VerifiedSortLevel params)) expr with
    | some witness => .ok witness.val
    | none => .error .unsupported
  else
    .error .malformed

/--
A successful ACTUAL executable call provides both a G3 structural
validity proof and the independent, narrow dependent formation judgment.
This result may not be promoted into a general FullyChecked term witness.
-/
theorem inferClosedDependentSort_sound (params : List KName)
    (expr : KExpr) (level : ULevel)
    (h : inferClosedDependentSort params expr = .ok level) :
    KExpr.StructurallyValid params 0 expr ∧
      DependentSortRule params [] expr level := by
  by_cases hv : expr.closedInput params = true
  · cases hi : inferDependentSort
      ([] : List (VerifiedSortLevel params)) expr with
    | none =>
        simp [inferClosedDependentSort, hv, hi] at h
    | some witness =>
        have hLevel : witness.val = level := by
          simpa [inferClosedDependentSort, hv, hi] using h
        subst level
        exact ⟨KExpr.closedInput_sound params expr hv, witness.property⟩
  · simp [inferClosedDependentSort, hv] at h

end PSKernelFast.Core
