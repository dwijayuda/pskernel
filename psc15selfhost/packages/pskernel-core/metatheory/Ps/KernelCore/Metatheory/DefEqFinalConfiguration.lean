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
