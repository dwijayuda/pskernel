import Ps.KernelCore.Checker.DefEq.FinalRules
import Ps.KernelCore.Metatheory.CheckerContracts

/-
Configuration preservation for the proposition classifier used by DefEq.

This theorem intentionally makes no semantic proof-irrelevance claim yet.
The executable helper infers the input expression's type and WHNF-reduces that
inferred type to a Sort; later proof-irrelevance refinement must model that
exact relationship rather than claiming the proposition expression itself
reduces to Sort 0.
-/

theorem psKernelDefEqIsPropWith_configuration_preserves
    (inferType whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hInfer :
      PsKernelInferOnlyConfigurationPreserves inferType)
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (answer : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqIsPropWith
          inferType
          whnf
          context
          state
          expr =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  cases hInferRun :
      inferType context state expr with
  | error error =>
      simp [
        psKernelDefEqIsPropWith,
        hInferRun
      ] at hSuccess
  | ok inferRun =>
      rcases inferRun with ⟨inferredType, inferredState⟩
      have hInferredConfig :=
        hInfer
          context
          state
          inferredState
          expr
          inferredType
          hConfig
          hInferRun
      cases hWhnfRun :
          whnf
            context
            inferredState
            inferredType with
      | error error =>
          simp [
            psKernelDefEqIsPropWith,
            hInferRun,
            hWhnfRun
          ] at hSuccess
      | ok whnfRun =>
          rcases whnfRun with ⟨reducedType, reducedState⟩
          have hReduced :=
            hWhnf
              context
              inferredState
              reducedState
              inferredType
              reducedType
              hInferredConfig
              hWhnfRun
          cases reducedType with
          | sort level =>
              simp [
                psKernelDefEqIsPropWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hReduced.2
          | _ =>
              simp [
                psKernelDefEqIsPropWith,
                hInferRun,
                hWhnfRun
              ] at hSuccess


theorem psKernelDefEqEtaStructFieldsWithFuel_configuration_preserves
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (induct : PsKernelName)
    (term : PsKernelExpr)
    (args : List PsKernelExpr)
    (numParams index : Nat)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructFieldsWithFuel
          fuel defeq context state
          induct term args numParams index =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  induction fuel generalizing state nextState index value with
  | zero =>
      simp [psKernelDefEqEtaStructFieldsWithFuel] at hSuccess
  | succ remaining ih =>
      let fieldCount :=
        Nat.sub (psKernelExprListLength args) numParams
      cases hMore : psKernelNatLt index fieldCount with
      | false =>
          simp [
            psKernelDefEqEtaStructFieldsWithFuel,
            fieldCount,
            hMore
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
      | true =>
          cases hArg :
              psKernelExprListGet args (Nat.add numParams index) with
          | none =>
              simp [
                psKernelDefEqEtaStructFieldsWithFuel,
                fieldCount,
                hMore,
                hArg
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | some arg =>
              cases hRun :
                  defeq context state
                    (PsKernelExpr.proj induct index term)
                    arg with
              | error error =>
                  simp [
                    psKernelDefEqEtaStructFieldsWithFuel,
                    fieldCount,
                    hMore,
                    hArg,
                    hRun
                  ] at hSuccess
              | ok run =>
                  rcases run with ⟨eqValue, eqState⟩
                  have hEq :=
                    hDefEq
                      context state eqState
                      (PsKernelExpr.proj induct index term)
                      arg eqValue
                      hConfig hRun
                  cases eqValue with
                  | false =>
                      simp [
                        psKernelDefEqEtaStructFieldsWithFuel,
                        fieldCount,
                        hMore,
                        hArg,
                        hRun
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact hEq.1
                  | true =>
                      apply
                        ih
                          eqState
                          nextState
                          (Nat.succ index)
                          value
                          hEq.1
                      simpa [
                        psKernelDefEqEtaStructFieldsWithFuel,
                        fieldCount,
                        hMore,
                        hArg,
                        hRun
                      ] using hSuccess
