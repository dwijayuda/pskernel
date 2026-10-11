import PSKernelFast.CoreSyntaxProofs

/-!
G4.2 **tiny certified formation fragment**, NOT a complete Lean kernel.

Accepted rules:
  Sort u : Sort (succ u)
  (x : Sort u) -> Sort v : Sort (imax (succ u) (succ v))

The Pi rule is restricted to syntactically Sort-typed domain and codomain.
It has no local-context inference, DefEq, constants, theorem admission,
inductive recursor, or proof irrelevance. All other structurally valid
expressions are UNSUPPORTED rather than rejected as mathematically ill-typed.

A successful fragment inference comes from a dependent proof witness
produced by the same implementation, so the result cannot be a guessed sort.
-/

namespace PSKernelFast.Core

/-- An independent limited formation judgment mirroring two official rules. -/
inductive SortFragmentRule : KExpr → ULevel → Prop where
  | sort (u : ULevel) :
      SortFragmentRule (.sort u) (.succ u)
  | piOfSorts (binderName : KName) (u v : ULevel)
      (style : BinderStyle) :
      SortFragmentRule
        (.forallE binderName (.sort u) (.sort v) style)
        (.imax (.succ u) (.succ v))

/-- Executable soundness witness, erased from the runtime success value. -/
def inferSortShape :
    (expr : KExpr) →
    Option { level : ULevel // SortFragmentRule expr level }
  | .sort level =>
      some ⟨.succ level, .sort level⟩
  | .forallE name (.sort domain) (.sort codomain) style =>
      some ⟨.imax (.succ domain) (.succ codomain),
        .piOfSorts name domain codomain style⟩
  | _ => none

inductive FormationError where
  | malformed
  | unsupported
  deriving Repr, BEq, Inhabited

/--
Preflight and then infer only the explicitly supported formation fragment.
No arbitrary theorem declaration is checked or admitted.
-/
def inferClosedSortFragment (params : List KName) (expr : KExpr) :
    Except FormationError ULevel :=
  if h : expr.closedInput params = true then
    match inferSortShape expr with
    | some result => .ok result.val
    | none => .error .unsupported
  else
    .error .malformed

/--
Soundness of the actual executable fragment: success establishes BOTH
independent structural input validity and the explicit formation judgment.
-/
theorem inferClosedSortFragment_sound (params : List KName)
    (expr : KExpr) (level : ULevel)
    (h : inferClosedSortFragment params expr = .ok level) :
    KExpr.StructurallyValid params 0 expr ∧
      SortFragmentRule expr level := by
  by_cases hv : expr.closedInput params = true
  · cases hc : inferSortShape expr with
    | none =>
        simp [inferClosedSortFragment, hv, hc] at h
    | some witness =>
        have hLevel : witness.val = level := by
          simpa [inferClosedSortFragment, hv, hc] using h
        subst level
        exact ⟨KExpr.closedInput_sound params expr hv, witness.property⟩
  · simp [inferClosedSortFragment, hv] at h

/-- The result is always a Sort expression; no proof term is manufactured. -/
def inferClosedSortType (params : List KName) (expr : KExpr) :
    Except FormationError KExpr :=
  match inferClosedSortFragment params expr with
  | .ok level => .ok (.sort level)
  | .error issue => .error issue

end PSKernelFast.Core
