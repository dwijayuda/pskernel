import PSKernelFast.TypedConversion

/-!
G4.4a execution-to-reference-contract bridge.

A yes result can only be produced with TWO independently actual
G4.3b checked source typing judgments at the SAME syntactic type, and
a refl/beta/zeta head conversion witness. This is an operational
positive-soundness theorem, NOT arbitrary Lean definitional equality
or full set-denotation preservation.
-/

namespace PSKernelFast.Proof

open PSKernelFast.Core

theorem typedHead_positive_certificate
    {params : List KName} {ctx : List KExpr} {lhs rhs : KExpr}
    (decision : TypedHeadDecision params ctx lhs rhs)
    (h : decision.isEqual = true) :
    ∃ ty : KExpr,
      GeneralPiRule params ctx lhs ty ∧
      GeneralPiRule params ctx rhs ty ∧
      HeadConversion lhs rhs := by
  cases decision with
  | equal cert =>
      exact ⟨cert.ty, cert.lhsTyped, cert.rhsTyped, cert.headStep⟩
  | unresolved => cases h
  | malformed => cases h
  | resourceExhausted => cases h

theorem compareTypedHead_positive_sound
    {params : List KName}
    (ctx : GeneralPiContext params)
    (lhs rhs : KExpr) (budget : Nat)
    (h : (compareTypedHead ctx lhs rhs budget).isEqual = true) :
    ∃ ty : KExpr,
      GeneralPiRule params ctx.entries lhs ty ∧
      GeneralPiRule params ctx.entries rhs ty ∧
      HeadConversion lhs rhs :=
  typedHead_positive_certificate
    (compareTypedHead ctx lhs rhs budget) h

#print axioms typedHead_positive_certificate
#print axioms compareTypedHead_positive_sound

end PSKernelFast.Proof
