import Ps.BackendTs.Saturate

/- Local equations for the bounded recognizer and its refusal/signature rules.
   These are not a global compiler-preservation or kernel-soundness theorem. -/
namespace PsBackendTsSaturateProofs

theorem purity_zero (expression : PsVerifiedIrExpr) :
    psTsSatPureWithFuel 0 expression = false := rfl

theorem purity_variable (remaining : Nat) (name : String) :
    psTsSatPureWithFuel (Nat.succ remaining) (.var name) = true := rfl

theorem purity_call_refused (remaining : Nat) (target : PsVerifiedIrExpr)
    (types : List PsVerifiedIrType) (arguments : List PsVerifiedIrExpr) :
    psTsSatPureWithFuel (Nat.succ remaining) (.call target types arguments) = false := rfl

theorem purity_projection_refused (remaining : Nat) (name field : String)
    (types : List PsVerifiedIrType) (target : PsVerifiedIrExpr) :
    psTsSatPureWithFuel (Nat.succ remaining) (.projection name types target field) = false := rfl

theorem purity_array_refused (remaining : Nat)
    (types : List PsVerifiedIrType) (arguments : List PsVerifiedIrExpr) :
    psTsSatPureWithFuel (Nat.succ remaining) (.intrinsic .arrayGetD types arguments) = false := by
  cases types <;> rfl

theorem apply_zero (parameter : PsVerifiedIrParameter)
    (result : PsVerifiedIrType) (expression : PsVerifiedIrExpr) :
    psTsSatApplyOne 0 parameter result expression = none := rfl

theorem apply_exact_lambda
    (remaining : Nat) (parameter bound : PsVerifiedIrParameter)
    (result expected : PsVerifiedIrType) (body : PsVerifiedIrExpr)
    (parameterType : psTsSatTypeEqual bound.type parameter.type = true)
    (resultType : psTsSatTypeEqual result expected = true) :
    psTsSatApplyOne (Nat.succ remaining) parameter expected (.lambda [bound] result body) =
      some (.letE bound.name bound.type (.var parameter.name) body) := by
  simp only [psTsSatApplyOne, psListIsEmpty, parameterType, resultType, ite_true]

theorem apply_effectful_interval_refused
    (remaining : Nat) (parameter : PsVerifiedIrParameter)
    (expected type : PsVerifiedIrType) (name : String) (target : PsVerifiedIrExpr)
    (arguments : List PsVerifiedIrExpr) (body : PsVerifiedIrExpr) :
    psTsSatApplyOne (Nat.succ remaining) parameter expected
      (.letE name type (.call target [] arguments) body) = none := rfl

theorem no_stages (result : PsVerifiedIrType) (expression : PsVerifiedIrExpr) :
    psTsSatApplyStages [] result expression = some expression := rfl

theorem fresh_zero (reserved : List String) (declaration : PsVerifiedIrDeclaration)
    (prefixText : String) (index : Nat) :
    psTsSatFresh 0 reserved declaration prefixText index = none := rfl

theorem rewrite_zero (candidates : PsErasureNameIndex PsTsSatCandidate)
    (locals : List String) (expression : PsVerifiedIrExpr) :
    psTsSatRewrite 0 candidates locals expression = none := rfl

theorem empty_state_arguments :
    psTsSatStateArguments 0 [] = some [] := rfl

theorem excess_state_arguments_refused
    (first : List PsVerifiedIrExpr) (rest : List (List PsVerifiedIrExpr)) :
    psTsSatStateArguments 0 (first :: rest) = none := rfl

theorem constant_entry_refused (reserved : List String)
    (name : String) (type : PsVerifiedIrType) (body : PsVerifiedIrExpr) (index : Nat) :
    psTsSatMakeCandidate reserved (.mk name [] [] type body) index = none := rfl

theorem generic_entry_refused (reserved : List String) (name : String)
    (first : PsVerifiedIrTypeParameter) (rest : List PsVerifiedIrTypeParameter)
    (parameters : List PsVerifiedIrParameter) (type : PsVerifiedIrType)
    (body : PsVerifiedIrExpr) (index : Nat) :
    psTsSatMakeCandidate reserved (.mk name (first :: rest) parameters type body) index = none := rfl

theorem declaration_signature_preserved
    (candidates : PsErasureNameIndex PsTsSatCandidate) (declaration : PsVerifiedIrDeclaration)
    (result : PsTsSatExprResult)
    (rewritten : psTsSatRewrite 4096 candidates
      (psTsSatParameterNames declaration.parameters) declaration.body = some result) :
    psTsSatRewriteDeclaration candidates declaration =
      some ((PsVerifiedIrDeclaration.mk declaration.name declaration.typeParameters
        declaration.parameters declaration.resultType result.expr),result.calls) := by
  simp only [psTsSatRewriteDeclaration, rewritten]

end PsBackendTsSaturateProofs

#print axioms PsBackendTsSaturateProofs.purity_zero
#print axioms PsBackendTsSaturateProofs.purity_variable
#print axioms PsBackendTsSaturateProofs.purity_call_refused
#print axioms PsBackendTsSaturateProofs.purity_projection_refused
#print axioms PsBackendTsSaturateProofs.purity_array_refused
#print axioms PsBackendTsSaturateProofs.apply_zero
#print axioms PsBackendTsSaturateProofs.apply_exact_lambda
#print axioms PsBackendTsSaturateProofs.apply_effectful_interval_refused
#print axioms PsBackendTsSaturateProofs.no_stages
#print axioms PsBackendTsSaturateProofs.fresh_zero
#print axioms PsBackendTsSaturateProofs.rewrite_zero
#print axioms PsBackendTsSaturateProofs.empty_state_arguments
#print axioms PsBackendTsSaturateProofs.excess_state_arguments_refused
#print axioms PsBackendTsSaturateProofs.constant_entry_refused
#print axioms PsBackendTsSaturateProofs.generic_entry_refused
#print axioms PsBackendTsSaturateProofs.declaration_signature_preserved
