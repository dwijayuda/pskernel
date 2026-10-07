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
            rw [hArg] at hSuccess
            simp at hSuccess
            rcases hSuccess with ⟨rfl, rfl⟩
            exact hConfig
        | some arg =>
            rw [hArg] at hSuccess
            cases hRun :
                defeq
                  context
                  state
                  (PsKernelExpr.proj induct index term)
                  arg with
            | error error =>
                rw [hRun] at hSuccess
                simp at hSuccess
            | ok run =>
                rcases run with ⟨eqValue, eqState⟩
                rw [hRun] at hSuccess
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
  let fn := psKernelExprGetAppFn structureValue
  let args := psKernelExprGetAppArgs structureValue
  cases hFn : fn with
  | const ctorName levels =>
      cases hFind :
          psKernelEnvironmentFind context.environment ctorName with
      | none =>
          simp [
            psKernelDefEqEtaStructCoreWith,
            fn,
            args,
            hFn,
            hFind
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
      | some info =>
          cases info with
          | ctorInfo ctor =>
              cases hArity :
                  Nat.beq
                    (psKernelExprListLength args)
                    (Nat.add ctor.numParams ctor.numFields) with
              | false =>
                  simp [
                    psKernelDefEqEtaStructCoreWith,
                    fn,
                    args,
                    hFn,
                    hFind,
                    hArity
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hConfig
              | true =>
                  cases hStructure :
                      psKernelEnvironmentIsNonRecStructure
                        context.environment
                        ctor.induct with
                  | false =>
                      simp [
                        psKernelDefEqEtaStructCoreWith,
                        fn,
                        args,
                        hFn,
                        hFind,
                        hArity,
                        hStructure
                      ] at hSuccess
                      rcases hSuccess with ⟨rfl, rfl⟩
                      exact hConfig
                  | true =>
                      cases hTerm :
                          inferType context state term with
                      | error error =>
                          simp [
                            psKernelDefEqEtaStructCoreWith,
                            fn,
                            args,
                            hFn,
                            hFind,
                            hArity,
                            hStructure,
                            hTerm
                          ] at hSuccess
                      | ok termRun =>
                          rcases termRun with ⟨termType, termState⟩
                          have hTermConfig :=
                            hInfer
                              context state termState
                              term termType
                              hConfig hTerm
                          cases hStructType :
                              inferType
                                context
                                termState
                                structureValue with
                          | error error =>
                              simp [
                                psKernelDefEqEtaStructCoreWith,
                                fn,
                                args,
                                hFn,
                                hFind,
                                hArity,
                                hStructure,
                                hTerm,
                                hStructType
                              ] at hSuccess
                          | ok structRun =>
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
                                  simp [
                                    psKernelDefEqEtaStructCoreWith,
                                    fn,
                                    args,
                                    hFn,
                                    hFind,
                                    hArity,
                                    hStructure,
                                    hTerm,
                                    hStructType,
                                    hTypes
                                  ] at hSuccess
                              | ok typeRun =>
                                  rcases typeRun with
                                    ⟨typesEqual, typeState⟩
                                  have hTypeConfig :=
                                    (hDefEq
                                      context
                                      structureState
                                      typeState
                                      termType
                                      structureType
                                      typesEqual
                                      hStructureConfig
                                      hTypes).1
                                  cases typesEqual with
                                  | false =>
                                      simp [
                                        psKernelDefEqEtaStructCoreWith,
                                        fn,
                                        args,
                                        hFn,
                                        hFind,
                                        hArity,
                                        hStructure,
                                        hTerm,
                                        hStructType,
                                        hTypes
                                      ] at hSuccess
                                      rcases hSuccess with ⟨rfl, rfl⟩
                                      exact hTypeConfig
                                  | true =>
                                      apply
                                        psKernelDefEqEtaStructFieldsWithFuel_configuration_preserves
                                          (Nat.succ ctor.numFields)
                                          defeq
                                          hDefEq
                                          context
                                          typeState
                                          nextState
                                          ctor.induct
                                          term
                                          args
                                          ctor.numParams
                                          0
                                          value
                                          hTypeConfig
                                      simpa [
                                        psKernelDefEqEtaStructCoreWith,
                                        fn,
                                        args,
                                        hFn,
                                        hFind,
                                        hArity,
                                        hStructure,
                                        hTerm,
                                        hStructType,
                                        hTypes
                                      ] using hSuccess
          | axiomInfo infoValue =>
              simp [psKernelDefEqEtaStructCoreWith, fn, args, hFn, hFind] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | defnInfo infoValue =>
              simp [psKernelDefEqEtaStructCoreWith, fn, args, hFn, hFind] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | thmInfo infoValue =>
              simp [psKernelDefEqEtaStructCoreWith, fn, args, hFn, hFind] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | opaqueInfo infoValue =>
              simp [psKernelDefEqEtaStructCoreWith, fn, args, hFn, hFind] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | inductInfo infoValue =>
              simp [psKernelDefEqEtaStructCoreWith, fn, args, hFn, hFind] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | recInfo infoValue =>
              simp [psKernelDefEqEtaStructCoreWith, fn, args, hFn, hFind] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
          | quotInfo infoValue =>
              simp [psKernelDefEqEtaStructCoreWith, fn, args, hFn, hFind] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
  | _ =>
      simp [
        psKernelDefEqEtaStructCoreWith,
        fn,
        args,
        hFn
      ] at hSuccess
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
  cases hFirst :
      psKernelDefEqEtaStructCoreWith
        defeq inferType context state left right with
  | error error =>
      simp [psKernelDefEqEtaStructWith, hFirst] at hSuccess
  | ok firstRun =>
      rcases firstRun with ⟨firstValue, firstState⟩
      have hFirstConfig :=
        psKernelDefEqEtaStructCoreWith_configuration_preserves
          defeq inferType
          hDefEq hInfer
          context state firstState
          left right firstValue
          hConfig hFirst
      cases firstValue with
      | true =>
          simp [psKernelDefEqEtaStructWith, hFirst] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hFirstConfig
      | false =>
          cases hSecond :
              psKernelDefEqEtaStructCoreWith
                defeq inferType
                context firstState right left with
          | error error =>
              simp [
                psKernelDefEqEtaStructWith,
                hFirst,
                hSecond
              ] at hSuccess
          | ok secondRun =>
              rcases secondRun with ⟨secondValue, secondState⟩
              have hSecondConfig :=
                psKernelDefEqEtaStructCoreWith_configuration_preserves
                  defeq inferType
                  hDefEq hInfer
                  context firstState secondState
                  right left secondValue
                  hFirstConfig hSecond
              simp [
                psKernelDefEqEtaStructWith,
                hFirst,
                hSecond
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hSecondConfig
