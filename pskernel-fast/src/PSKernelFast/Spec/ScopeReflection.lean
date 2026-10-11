import PSKernelFast.Spec.ContextScope

/-!
P1 independent scope-reflection bridge: successful G3 executable input
preflight is EQUIVALENT to declarative well-formedness for this exact
CoreSyntax. Its sound direction was previously proved in CoreSyntaxProofs.

Proving the opposite direction permits a future proof that the redundant
G4.3b OUTPUT structural check cannot reject an otherwise successful
fragment inference. It does NOT prove type preservation or model soundness.
-/

namespace PSKernelFast.Spec

open PSKernelFast.Core

theorem levelParams_complete (params : List KName) (level : ULevel)
    (h : ULevel.WellFormed params level) :
    level.validParams params = true := by
  induction level with
  | zero => rfl
  | succ inner ih =>
      exact ih h
  | max left right ihLeft ihRight =>
      simp only [ULevel.validParams, Bool.and_eq_true]
      exact ⟨ihLeft h.1, ihRight h.2⟩
  | imax left right ihLeft ihRight =>
      simp only [ULevel.validParams, Bool.and_eq_true]
      exact ⟨ihLeft h.1, ihRight h.2⟩
  | param name =>
      simpa [ULevel.validParams] using (decide_eq_true h)
  | mvar name =>
      exact False.elim h

/-- No malformed/free metavariable or escaped bvar passes by omission. -/
theorem validAt_complete (params : List KName) (depth : Nat)
    (expr : KExpr) (h : KExpr.StructurallyValid params depth expr) :
    expr.validAt params depth = true := by
  induction expr generalizing depth with
  | bvar index =>
      simpa [KExpr.validAt] using (decide_eq_true h)
  | fvar name => exact False.elim h
  | mvar name => exact False.elim h
  | sort level =>
      exact levelParams_complete params level h
  | const name levels =>
      change levels.all (ULevel.validParams params) = true
      apply List.all_eq_true.mpr
      intro level hMem
      exact levelParams_complete params level (h level hMem)
  | app fn arg ihFn ihArg =>
      simp only [KExpr.validAt, Bool.and_eq_true]
      exact ⟨ihFn depth h.1, ihArg depth h.2⟩
  | lam name domain body style ihDomain ihBody =>
      simp only [KExpr.validAt, Bool.and_eq_true]
      exact ⟨ihDomain depth h.1, ihBody (depth + 1) h.2⟩
  | forallE name domain body style ihDomain ihBody =>
      simp only [KExpr.validAt, Bool.and_eq_true]
      exact ⟨ihDomain depth h.1, ihBody (depth + 1) h.2⟩
  | letE name declared value body flag ihDecl ihValue ihBody =>
      simp only [KExpr.validAt, Bool.and_eq_true]
      exact ⟨⟨ihDecl depth h.1.1, ihValue depth h.1.2⟩,
        ihBody (depth + 1) h.2⟩
  | lit _ => rfl
  | mdata tag inner ih =>
      exact ih depth h
  | proj name index inner ih =>
      exact ih depth h

theorem closedInput_complete (params : List KName) (expr : KExpr)
    (h : KExpr.StructurallyValid params 0 expr) :
    expr.closedInput params = true := by
  exact validAt_complete params 0 expr h

theorem closedInput_iff (params : List KName) (expr : KExpr) :
    expr.closedInput params = true ↔
      KExpr.StructurallyValid params 0 expr := by
  constructor
  · exact KExpr.closedInput_sound params expr
  · exact closedInput_complete params expr

#print axioms closedInput_iff

end PSKernelFast.Spec
