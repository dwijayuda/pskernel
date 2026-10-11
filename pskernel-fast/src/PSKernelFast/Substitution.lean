import PSKernelFast.ScopedContext

/-!
G4.3 capture-avoiding, binder-aware reference substitution over the ACTUAL
G3 KExpr syntax. All cases are handled; malformed/free/metavariable inputs
must still be rejected by structural preflight before kernel checking.

This module certifies structural *scope* preservation, not type preservation,
WHNF, DefEq, checked inference, proof validity, or declaration admission.
-/

namespace PSKernelFast.Core

/--
Instantiate the variable at de Bruijn depth and remove its enclosing binder.
Inner bound indices are preserved; the replacement is lifted while traversing
new local binders; outer indices decrement after the removed binder.
-/
def KExpr.instantiateBVar (expr replacement : KExpr) (depth : Nat) : KExpr :=
  match expr with
  | .bvar index =>
      if index < depth then .bvar index
      else if index = depth then replacement.liftBVars depth 0
      else .bvar (index - 1)
  | .app fn arg =>
      .app (fn.instantiateBVar replacement depth)
        (arg.instantiateBVar replacement depth)
  | .lam name domain body style =>
      .lam name (domain.instantiateBVar replacement depth)
        (body.instantiateBVar replacement (depth + 1)) style
  | .forallE name domain body style =>
      .forallE name (domain.instantiateBVar replacement depth)
        (body.instantiateBVar replacement (depth + 1)) style
  | .letE name ty value body nondep =>
      .letE name (ty.instantiateBVar replacement depth)
        (value.instantiateBVar replacement depth)
        (body.instantiateBVar replacement (depth + 1)) nondep
  | .mdata tag inner =>
      .mdata tag (inner.instantiateBVar replacement depth)
  | .proj name index inner =>
      .proj name index (inner.instantiateBVar replacement depth)
  | atom => atom

/--
The ACTUAL substitution routine preserves structural well-scopedness.
For a replacement scoped in Γ and a body scoped under an additional binder,
instantiation produces an expression scoped in Γ (with nested binders
accounted for by the depth parameter). This is not a typing theorem.
-/
theorem KExpr.instantiateBVar_structurallyValid
    (params : List KName) (outerDepth : Nat) (replacement : KExpr)
    (hReplacement : KExpr.StructurallyValid params outerDepth replacement)
    (expr : KExpr) (depth : Nat)
    (hExpr :
      KExpr.StructurallyValid params (outerDepth + depth + 1) expr) :
    KExpr.StructurallyValid params (outerDepth + depth)
      (expr.instantiateBVar replacement depth) := by
  induction expr generalizing depth with
  | bvar index =>
      change index < outerDepth + depth + 1 at hExpr
      by_cases hLocal : index < depth
      · have hBound : index < outerDepth + depth := by omega
        simpa [KExpr.instantiateBVar, hLocal, KExpr.StructurallyValid]
          using hBound
      · by_cases hTarget : index = depth
        · have hLift :
              KExpr.StructurallyValid params (outerDepth + depth)
                (replacement.liftBVars depth 0) :=
            KExpr.liftBVars_structurallyValid params depth 0
              outerDepth replacement (by omega) hReplacement
          simpa [KExpr.instantiateBVar, hLocal, hTarget,
            KExpr.StructurallyValid] using hLift
        · have hBound : index - 1 < outerDepth + depth := by omega
          simpa [KExpr.instantiateBVar, hLocal, hTarget,
            KExpr.StructurallyValid] using hBound
  | fvar _ => exact False.elim hExpr
  | mvar _ => exact False.elim hExpr
  | sort _ => exact hExpr
  | const _ _ => exact hExpr
  | app fn arg ihFn ihArg =>
      exact ⟨ihFn depth hExpr.1, ihArg depth hExpr.2⟩
  | lam name domain body style ihDomain ihBody =>
      have hBody :
          KExpr.StructurallyValid params (outerDepth + (depth + 1) + 1)
            body := by
        simpa only [Nat.add_assoc] using hExpr.2
      have hNext := ihBody (depth + 1) hBody
      exact ⟨ihDomain depth hExpr.1,
        (by simpa only [Nat.add_assoc] using hNext)⟩
  | forallE name domain body style ihDomain ihBody =>
      have hBody :
          KExpr.StructurallyValid params (outerDepth + (depth + 1) + 1)
            body := by
        simpa only [Nat.add_assoc] using hExpr.2
      have hNext := ihBody (depth + 1) hBody
      exact ⟨ihDomain depth hExpr.1,
        (by simpa only [Nat.add_assoc] using hNext)⟩
  | letE name ty value body nondep ihTy ihValue ihBody =>
      have hBody :
          KExpr.StructurallyValid params (outerDepth + (depth + 1) + 1)
            body := by
        simpa only [Nat.add_assoc] using hExpr.2
      have hNext := ihBody (depth + 1) hBody
      exact ⟨⟨ihTy depth hExpr.1.1, ihValue depth hExpr.1.2⟩,
        (by simpa only [Nat.add_assoc] using hNext)⟩
  | lit _ => trivial
  | mdata tag inner ih => exact ih depth hExpr
  | proj name index inner ih => exact ih depth hExpr

/-- The ordinary one-binder beta/let use case, specialized to depth zero. -/
theorem KExpr.instantiateBVar_top_scoped
    (params : List KName) (outerDepth : Nat)
    (replacement body : KExpr)
    (hReplacement : KExpr.StructurallyValid params outerDepth replacement)
    (hBody : KExpr.StructurallyValid params (outerDepth + 1) body) :
    KExpr.StructurallyValid params outerDepth
      (body.instantiateBVar replacement 0) := by
  simpa using
    (KExpr.instantiateBVar_structurallyValid params outerDepth
      replacement hReplacement body 0 (by simpa using hBody))

/-- Structural preflight failures for this binder operation, not kernel errors. -/
inductive SubstitutionScopeError where
  | malformedBody
  | malformedReplacement
  deriving Inhabited, Repr, BEq

/--
Fail-closed runtime entry point for substitution in a known context:
validate BOTH inputs, run the real reference substitution, and return
a scope certificate for the EXACT executable result.

This does not validate a term's TYPE and does not enable theorem admission.
-/
def KExpr.instantiateTopScoped (params : List KName) (outerDepth : Nat)
    (body replacement : KExpr) :
    Except SubstitutionScopeError
      { result : KExpr // KExpr.StructurallyValid params outerDepth result } :=
  if hBody : body.validAt params (outerDepth + 1) = true then
    if hReplacement : replacement.validAt params outerDepth = true then
      .ok ⟨body.instantiateBVar replacement 0,
        KExpr.instantiateBVar_top_scoped params outerDepth replacement body
          (KExpr.validAt_sound params outerDepth replacement hReplacement)
          (KExpr.validAt_sound params (outerDepth + 1) body hBody)⟩
    else
      .error .malformedReplacement
  else
    .error .malformedBody


end PSKernelFast.Core
