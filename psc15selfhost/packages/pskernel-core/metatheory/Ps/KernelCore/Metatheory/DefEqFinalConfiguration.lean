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
      simp only [psKernelDefEqEtaStructFieldsWithFuel] at hSuccess
      by_cases hMore :
          psKernelNatLt
              index
              (Nat.sub
                (psKernelExprListLength args)
                numParams) =
            true
      · rw [if_pos hMore] at hSuccess
        cases hArg :
            psKernelExprListGet
              args
              (Nat.add numParams index) with
        | none =>
            simp only [hArg] at hSuccess
            simp at hSuccess
            rcases hSuccess with ⟨rfl, rfl⟩
            exact hConfig
        | some arg =>
            simp only [hArg] at hSuccess
            cases hRun :
                defeq
                  context
                  state
                  (PsKernelExpr.proj induct index term)
                  arg with
            | error error =>
                simp only [hRun] at hSuccess
                simp at hSuccess
            | ok run =>
                rcases run with ⟨eqValue, eqState⟩
                simp only [hRun] at hSuccess
                have hEq :=
                  hDefEq
                    context
                    state
                    eqState
                    (PsKernelExpr.proj induct index term)
                    arg
                    eqValue
                    hConfig
                    hRun
                by_cases hEqValue : eqValue = true
                · rw [if_pos hEqValue] at hSuccess
                  exact
                    ih
                      eqState
                      nextState
                      (Nat.succ index)
                      value
                      hEq.1
                      (by simpa [Nat.succ_eq_add_one] using hSuccess)
                · rw [if_neg hEqValue] at hSuccess
                  simp at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hEq.1
      · rw [if_neg hMore] at hSuccess
        simp at hSuccess
        rcases hSuccess with ⟨rfl, rfl⟩
        exact hConfig

theorem psKernelDefEqEtaStructCoreWith_configuration_preserves
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (term structureValue : PsKernelExpr)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructCoreWith
          defeq inferType context state term structureValue =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  simp only [psKernelDefEqEtaStructCoreWith] at hSuccess
  cases hFn : psKernelExprGetAppFn structureValue with
  | const ctorName levels =>
      simp only [hFn] at hSuccess
      cases hFind :
          psKernelEnvironmentFind
            context.environment
            ctorName with
      | none =>
          simp only [hFind] at hSuccess
          simp at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
      | some info =>
          simp only [hFind] at hSuccess
          cases info with
          | ctorInfo ctor =>
              by_cases hArity :
                  Nat.beq
                      (psKernelExprListLength
                        (psKernelExprGetAppArgs structureValue))
                      (Nat.add ctor.numParams ctor.numFields) =
                    true
              · rw [if_pos hArity] at hSuccess
                by_cases hStructure :
                    psKernelEnvironmentIsNonRecStructure
                        context.environment
                        ctor.induct =
                      true
                · rw [if_pos hStructure] at hSuccess
                  cases hTerm :
                      inferType context state term with
                  | error error =>
                      simp only [hTerm] at hSuccess
                      simp at hSuccess
                  | ok termRun =>
                      simp only [hTerm] at hSuccess
                      rcases termRun with ⟨termType, termState⟩
                      have hTermConfig :=
                        hInfer
                          context
                          state
                          termState
                          term
                          termType
                          hConfig
                          hTerm
                      cases hStructType :
                          inferType
                            context
                            termState
                            structureValue with
                      | error error =>
                          simp only [hStructType] at hSuccess
                          simp at hSuccess
                      | ok structRun =>
                          simp only [hStructType] at hSuccess
                          rcases structRun with
                            ⟨structureType, structureState⟩
                          have hStructureConfig :=
                            hInfer
                              context
                              termState
                              structureState
                              structureValue
                              structureType
                              hTermConfig
                              hStructType
                          cases hTypes :
                              defeq
                                context
                                structureState
                                termType
                                structureType with
                          | error error =>
                              simp only [hTypes] at hSuccess
                              simp at hSuccess
                          | ok typeRun =>
                              simp only [hTypes] at hSuccess
                              rcases typeRun with
                                ⟨typesEqual, typeState⟩
                              have hTypeSemantic :=
                                hDefEq
                                  context
                                  structureState
                                  typeState
                                  termType
                                  structureType
                                  typesEqual
                                  hStructureConfig
                                  hTypes
                              by_cases hTypesEqual :
                                  typesEqual = true
                              · rw [if_pos hTypesEqual] at hSuccess
                                exact
                                  psKernelDefEqEtaStructFieldsWithFuel_configuration_preserves
                                    (Nat.succ ctor.numFields)
                                    defeq
                                    hDefEq
                                    context
                                    typeState
                                    nextState
                                    ctor.induct
                                    term
                                    (psKernelExprGetAppArgs structureValue)
                                    ctor.numParams
                                    0
                                    value
                                    hTypeSemantic.1
                                    hSuccess
                              · rw [if_neg hTypesEqual] at hSuccess
                                simp at hSuccess
                                rcases hSuccess with ⟨rfl, rfl⟩
                                exact hTypeSemantic.1
                · rw [if_neg hStructure] at hSuccess
                  simp at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hConfig
              · rw [if_neg hArity] at hSuccess
                simp at hSuccess
                rcases hSuccess with ⟨rfl, rfl⟩
                exact hConfig
          | axiomInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | defnInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | thmInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | opaqueInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | inductInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | recInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | quotInfo infoValue =>
              simp at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
  | bvar index =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | fvar name =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | mvar name =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | sort level =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | app fn arg =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | lam name type body binderInfo =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | forallE name type body binderInfo =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | letE name type value body nondep =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | lit literal =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | mdata metadata body =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | proj typeName index body =>
      simp only [hFn] at hSuccess
      simp at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig

theorem psKernelDefEqEtaStructWith_configuration_preserves
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (hInfer : PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqEtaStructWith
          defeq inferType context state left right =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  simp only [psKernelDefEqEtaStructWith] at hSuccess
  cases hFirst :
      psKernelDefEqEtaStructCoreWith
        defeq inferType context state left right with
  | error error =>
      simp only [hFirst] at hSuccess
      simp at hSuccess
  | ok firstRun =>
      simp only [hFirst] at hSuccess
      rcases firstRun with ⟨firstValue, firstState⟩
      have hFirstConfig :=
        psKernelDefEqEtaStructCoreWith_configuration_preserves
          defeq
          inferType
          hDefEq
          hInfer
          context
          state
          firstState
          left
          right
          firstValue
          hConfig
          hFirst
      by_cases hFirstTrue : firstValue = true
      · rw [if_pos hFirstTrue] at hSuccess
        simp at hSuccess
        rcases hSuccess with ⟨rfl, rfl⟩
        exact hFirstConfig
      · rw [if_neg hFirstTrue] at hSuccess
        cases hSecond :
            psKernelDefEqEtaStructCoreWith
              defeq inferType
              context firstState right left with
        | error error =>
            simp only [hSecond] at hSuccess
            simp at hSuccess
        | ok secondRun =>
            simp only [hSecond] at hSuccess
            rcases secondRun with ⟨secondValue, secondState⟩
            have hSecondConfig :=
              psKernelDefEqEtaStructCoreWith_configuration_preserves
                defeq
                inferType
                hDefEq
                hInfer
                context
                firstState
                secondState
                right
                left
                secondValue
                hFirstConfig
                hSecond
            simp at hSuccess
            rcases hSuccess with ⟨rfl, rfl⟩
            exact hSecondConfig
