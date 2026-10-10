import Ps.KernelCore.Metatheory.ProjectionConfiguration
import Ps.KernelCore.Metatheory.ProjectionSemantics

/-
Configuration-aware projection semantics.  These theorems avoid the older
result-only checker contracts: every executable subcall consumes a sound
configuration and returns both the semantic result and a sound next state.
-/

theorem psKernelProjectionApplyParamsWithFuel_configuration_refines_semantics
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (args : List PsKernelExpr)
    (index numParams : Nat)
    (current result : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelProjectionApplyParamsWithFuel
          fuel whnf context state args index numParams current =
        Except.ok (Prod.mk result nextState)) :
    PsKernelProjectionApplyParamsJudgment
        context.environment
        context.localContext
        args
        index
        numParams
        current
        result ∧
      PsKernelCheckerConfigurationSound context nextState := by
  induction fuel generalizing state nextState index current result with
  | zero =>
      simp [psKernelProjectionApplyParamsWithFuel] at hSuccess
  | succ remaining ih =>
      cases hMore : psKernelNatLt index numParams with
      | false =>
          simp [psKernelProjectionApplyParamsWithFuel, hMore] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨
              PsKernelProjectionApplyParamsJudgment.done
                index numParams current hMore,
              hConfig
            ⟩
      | true =>
          cases hRun : whnf context state current with
          | error error =>
              simp [
                psKernelProjectionApplyParamsWithFuel,
                hMore,
                hRun
              ] at hSuccess
          | ok run =>
              rcases run with ⟨reduced, reducedState⟩
              have hWhnfSemantic :=
                hWhnf
                  context
                  state
                  reducedState
                  current
                  reduced
                  hConfig
                  hRun
              cases reduced with
              | forallE name domain body binderInfo =>
                  cases hArg : psKernelExprListGet args index with
                  | none =>
                      simp [
                        psKernelProjectionApplyParamsWithFuel,
                        hMore,
                        hRun,
                        hArg
                      ] at hSuccess
                  | some argument =>
                      have hRec :
                          psKernelProjectionApplyParamsWithFuel
                              remaining
                              whnf
                              context
                              reducedState
                              args
                              (Nat.succ index)
                              numParams
                              (psKernelExprInstantiate1 body argument) =
                            Except.ok (Prod.mk result nextState) := by
                        simpa [
                          psKernelProjectionApplyParamsWithFuel,
                          hMore,
                          hRun,
                          hArg
                        ] using hSuccess
                      have hRest :=
                        ih
                          reducedState
                          nextState
                          (Nat.succ index)
                          (psKernelExprInstantiate1 body argument)
                          result
                          hWhnfSemantic.2
                          hRec
                      exact
                        ⟨
                          PsKernelProjectionApplyParamsJudgment.step
                            index
                            numParams
                            current
                            domain
                            body
                            result
                            argument
                            name
                            binderInfo
                            hMore
                            hWhnfSemantic.1
                            hArg
                            hRest.1,
                          hRest.2
                        ⟩
              | _ =>
                  simp [
                    psKernelProjectionApplyParamsWithFuel,
                    hMore,
                    hRun
                  ] at hSuccess


theorem psKernelProjectionSkipFieldsWithFuel_configuration_refines_semantics
    (fuel : Nat)
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (hInfer : PsKernelCheckedInferenceConfigurationSound inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (inductName : PsKernelName)
    (structValue : PsKernelExpr)
    (propType : Bool)
    (targetIndex index : Nat)
    (current result : PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelProjectionSkipFieldsWithFuel
          fuel
          whnf
          inferType
          context
          state
          inductName
          structValue
          propType
          targetIndex
          index
          current =
        Except.ok (Prod.mk result nextState)) :
    PsKernelProjectionSkipFieldsJudgment
        context.environment
        context.localContext
        inductName
        structValue
        targetIndex
        index
        current
        result ∧
      PsKernelCheckerConfigurationSound context nextState := by
  have hInferPreserves :
      PsKernelInferOnlyConfigurationPreserves inferType :=
    psKernelInferenceConfigurationSound_preserves inferType hInfer
  induction fuel generalizing state nextState index current result with
  | zero =>
      simp [psKernelProjectionSkipFieldsWithFuel] at hSuccess
  | succ remaining ih =>
      cases hMore : psKernelNatLt index targetIndex with
      | false =>
          simp [psKernelProjectionSkipFieldsWithFuel, hMore] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            ⟨
              PsKernelProjectionSkipFieldsJudgment.done
                index current hMore,
              hConfig
            ⟩
      | true =>
          cases hRun : whnf context state current with
          | error error =>
              simp [
                psKernelProjectionSkipFieldsWithFuel,
                hMore,
                hRun
              ] at hSuccess
          | ok run =>
              rcases run with ⟨reduced, reducedState⟩
              have hWhnfSemantic :=
                hWhnf
                  context
                  state
                  reducedState
                  current
                  reduced
                  hConfig
                  hRun
              cases reduced with
              | forallE name domain body binderInfo =>
                  cases hLoose : psKernelExprHasLooseBVar body with
                  | false =>
                      have hRec :
                          psKernelProjectionSkipFieldsWithFuel
                              remaining
                              whnf
                              inferType
                              context
                              reducedState
                              inductName
                              structValue
                              propType
                              targetIndex
                              (Nat.succ index)
                              body =
                            Except.ok (Prod.mk result nextState) := by
                        simpa [
                          psKernelProjectionSkipFieldsWithFuel,
                          hMore,
                          hRun,
                          hLoose
                        ] using hSuccess
                      have hRest :=
                        ih
                          reducedState
                          nextState
                          (Nat.succ index)
                          body
                          result
                          hWhnfSemantic.2
                          hRec
                      exact
                        ⟨
                          PsKernelProjectionSkipFieldsJudgment.stepClosed
                            index
                            current
                            domain
                            body
                            result
                            name
                            binderInfo
                            hMore
                            hWhnfSemantic.1
                            hLoose
                            hRest.1,
                          hRest.2
                        ⟩
                  | true =>
                      let nextExpr :=
                        psKernelExprInstantiate1
                          body
                          (PsKernelExpr.proj
                            inductName index structValue)
                      cases propType with
                      | false =>
                          have hRec :
                              psKernelProjectionSkipFieldsWithFuel
                                  remaining
                                  whnf
                                  inferType
                                  context
                                  reducedState
                                  inductName
                                  structValue
                                  false
                                  targetIndex
                                  (Nat.succ index)
                                  nextExpr =
                                Except.ok (Prod.mk result nextState) := by
                            simpa [
                              psKernelProjectionSkipFieldsWithFuel,
                              hMore,
                              hRun,
                              hLoose,
                              nextExpr
                            ] using hSuccess
                          have hRest :=
                            ih
                              reducedState
                              nextState
                              (Nat.succ index)
                              nextExpr
                              result
                              hWhnfSemantic.2
                              hRec
                          exact
                            ⟨
                              PsKernelProjectionSkipFieldsJudgment.stepDependent
                                index
                                current
                                domain
                                body
                                result
                                name
                                binderInfo
                                hMore
                                hWhnfSemantic.1
                                hLoose
                                hRest.1,
                              hRest.2
                            ⟩
                      | true =>
                          cases hProp :
                              psKernelInferIsPropWith
                                whnf
                                inferType
                                context
                                reducedState
                                domain with
                          | error error =>
                              simp [
                                psKernelProjectionSkipFieldsWithFuel,
                                hMore,
                                hRun,
                                hLoose,
                                hProp,
                                nextExpr
                              ] at hSuccess
                          | ok propRun =>
                              rcases propRun with ⟨isProp, propState⟩
                              have hPropConfig :
                                  PsKernelCheckerConfigurationSound
                                    context
                                    propState :=
                                psKernelInferIsPropWith_preserves_configuration_of_infer_preserves
                                  whnf
                                  inferType
                                  hWhnf
                                  hInferPreserves
                                  context
                                  reducedState
                                  propState
                                  domain
                                  isProp
                                  hWhnfSemantic.2
                                  hProp
                              cases isProp with
                              | false =>
                                  simp [
                                    psKernelProjectionSkipFieldsWithFuel,
                                    hMore,
                                    hRun,
                                    hLoose,
                                    hProp,
                                    nextExpr
                                  ] at hSuccess
                              | true =>
                                  have hRec :
                                      psKernelProjectionSkipFieldsWithFuel
                                          remaining
                                          whnf
                                          inferType
                                          context
                                          propState
                                          inductName
                                          structValue
                                          true
                                          targetIndex
                                          (Nat.succ index)
                                          nextExpr =
                                        Except.ok
                                          (Prod.mk result nextState) := by
                                    simpa [
                                      psKernelProjectionSkipFieldsWithFuel,
                                      hMore,
                                      hRun,
                                      hLoose,
                                      hProp,
                                      nextExpr
                                    ] using hSuccess
                                  have hRest :=
                                    ih
                                      propState
                                      nextState
                                      (Nat.succ index)
                                      nextExpr
                                      result
                                      hPropConfig
                                      hRec
                                  exact
                                    ⟨
                                      PsKernelProjectionSkipFieldsJudgment.stepDependent
                                        index
                                        current
                                        domain
                                        body
                                        result
                                        name
                                        binderInfo
                                        hMore
                                        hWhnfSemantic.1
                                        hLoose
                                        hRest.1,
                                      hRest.2
                                    ⟩
              | _ =>
                  simp [
                    psKernelProjectionSkipFieldsWithFuel,
                    hMore,
                    hRun
                  ] at hSuccess


theorem psKernelInferProjectionWith_configuration_sound
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (hInfer : PsKernelCheckedInferenceConfigurationSound inferType) :
    PsKernelProjectionConfigurationSound
      whnf
      inferType := by
  intro
    context
    state
    nextState
    typeName
    index
    structValue
    result
    hConfig
    hSuccess
  have hInferPreserves :
      PsKernelInferOnlyConfigurationPreserves inferType :=
    psKernelInferenceConfigurationSound_preserves inferType hInfer
  cases hInferRun :
      inferType context state structValue with
  | error error =>
      simp [psKernelInferProjectionWith, hInferRun] at hSuccess
  | ok inferRun =>
      rcases inferRun with ⟨structType, state0⟩
      have hInferSemantic :=
        hInfer
          context
          state
          state0
          structValue
          structType
          hConfig
          hInferRun
      cases hTypeWhnf :
          whnf context state0 structType with
      | error error =>
          simp [
            psKernelInferProjectionWith,
            hInferRun,
            hTypeWhnf
          ] at hSuccess
      | ok typeRun =>
          rcases typeRun with ⟨typeWhnf, state1⟩
          have hTypeSemantic :=
            hWhnf
              context
              state0
              state1
              structType
              typeWhnf
              hInferSemantic.2
              hTypeWhnf
          cases hIndexBound :
              psKernelNatGt index psKernelLeanUInt32Max with
          | true =>
              simp [
                psKernelInferProjectionWith,
                hInferRun,
                hTypeWhnf,
                hIndexBound
              ] at hSuccess
          | false =>
              cases hFn :
                  psKernelExprGetAppFn typeWhnf with
              | const inductName inductLevels =>
                  cases hTypeName :
                      psKernelNameEq inductName typeName with
                  | false =>
                      simp [
                        psKernelInferProjectionWith,
                        hInferRun,
                        hTypeWhnf,
                        hIndexBound,
                        hFn,
                        hTypeName
                      ] at hSuccess
                  | true =>
                      cases hInductFind :
                          psKernelEnvironmentFind
                            context.environment
                            inductName with
                      | none =>
                          simp [
                            psKernelInferProjectionWith,
                            hInferRun,
                            hTypeWhnf,
                            hIndexBound,
                            hFn,
                            hTypeName,
                            hInductFind
                          ] at hSuccess
                      | some inductEntry =>
                          cases inductEntry <;>
                            try
                              simp [
                                psKernelInferProjectionWith,
                                hInferRun,
                                hTypeWhnf,
                                hIndexBound,
                                hFn,
                                hTypeName,
                                hInductFind
                              ] at hSuccess
                          case inductInfo inductInfo =>
                              cases hCtors : inductInfo.ctors with
                              | nil =>
                                  simp [
                                    psKernelInferProjectionWith,
                                    hInferRun,
                                    hTypeWhnf,
                                    hIndexBound,
                                    hFn,
                                    hTypeName,
                                    hInductFind,
                                    hCtors
                                  ] at hSuccess
                              | cons ctorName ctorRest =>
                                  cases hCtorRest : ctorRest with
                                  | cons nextCtor restCtors =>
                                      simp [
                                        psKernelInferProjectionWith,
                                        hInferRun,
                                        hTypeWhnf,
                                        hIndexBound,
                                        hFn,
                                        hTypeName,
                                        hInductFind,
                                        hCtors,
                                        hCtorRest
                                      ] at hSuccess
                                  | nil =>
                                      let args :=
                                        psKernelExprGetAppArgs typeWhnf
                                      cases hArgsLengthBool :
                                          Nat.beq
                                            (psKernelExprListLength args)
                                            (Nat.add
                                              inductInfo.numParams
                                              inductInfo.numIndices) with
                                      | false =>
                                          have hArgsLengthNeRaw :
                                              psKernelExprListLength
                                                  (psKernelExprGetAppArgs
                                                    typeWhnf) ≠
                                                Nat.add
                                                  inductInfo.numParams
                                                  inductInfo.numIndices := by
                                            intro hEq
                                            have hTrue :
                                                Nat.beq
                                                    (psKernelExprListLength
                                                      (psKernelExprGetAppArgs
                                                        typeWhnf))
                                                    (Nat.add
                                                      inductInfo.numParams
                                                      inductInfo.numIndices) =
                                                  true := by
                                              simpa [hEq]
                                            have hFalse :
                                                Nat.beq
                                                    (psKernelExprListLength
                                                      (psKernelExprGetAppArgs
                                                        typeWhnf))
                                                    (Nat.add
                                                      inductInfo.numParams
                                                      inductInfo.numIndices) =
                                                  false := by
                                              simpa [args] using
                                                hArgsLengthBool
                                            rw [hFalse] at hTrue
                                            cases hTrue
                                          simp only [hCtors, hCtorRest] at hSuccess
                                          split at hSuccess
                                          next hEq =>
                                            exact (hArgsLengthNeRaw hEq).elim
                                          next hNe =>
                                            cases hSuccess
                                      | true =>
                                          have hArgsLength :
                                              psKernelExprListLength args =
                                                Nat.add
                                                  inductInfo.numParams
                                                  inductInfo.numIndices := by
                                            simpa using hArgsLengthBool
                                          cases hCtorFind :
                                              psKernelEnvironmentFind
                                                context.environment
                                                ctorName with
                                          | none =>
                                              simp [
                                                psKernelInferProjectionWith,
                                                hInferRun,
                                                hTypeWhnf,
                                                hIndexBound,
                                                hFn,
                                                hTypeName,
                                                hInductFind,
                                                hCtors,
                                                hCtorRest,
                                                args,
                                                hArgsLength,
                                                hCtorFind
                                              ] at hSuccess
                                          | some ctorEntry =>
                                              cases ctorEntry <;>
                                                try
                                                  simp [
                                                    psKernelInferProjectionWith,
                                                    hInferRun,
                                                    hTypeWhnf,
                                                    hIndexBound,
                                                    hFn,
                                                    hTypeName,
                                                    hInductFind,
                                                    hCtors,
                                                    hCtorRest,
                                                    args,
                                                    hArgsLength,
                                                    hCtorFind
                                                  ] at hSuccess
                                              case ctorInfo ctorInfo =>
                                                  let initial :=
                                                    psKernelExprInstantiateLevelParams
                                                      ctorInfo.base.type
                                                      ctorInfo.base.levelParams
                                                      inductLevels
                                                  cases hParams :
                                                      psKernelProjectionApplyParamsWithFuel
                                                        (Nat.succ
                                                          inductInfo.numParams)
                                                        whnf
                                                        context
                                                        state1
                                                        args
                                                        0
                                                        inductInfo.numParams
                                                        initial with
                                                  | error error =>
                                                      simp [
                                                        psKernelInferProjectionWith,
                                                        hInferRun,
                                                        hTypeWhnf,
                                                        hIndexBound,
                                                        hFn,
                                                        hTypeName,
                                                        hInductFind,
                                                        hCtors,
                                                        hCtorRest,
                                                        args,
                                                        hArgsLength,
                                                        hCtorFind,
                                                        initial,
                                                        hParams
                                                      ] at hSuccess
                                                  | ok paramRun =>
                                                      rcases paramRun with
                                                        ⟨afterParams, state2⟩
                                                      have hParamsSemantic :=
                                                        psKernelProjectionApplyParamsWithFuel_configuration_refines_semantics
                                                          (Nat.succ
                                                            inductInfo.numParams)
                                                          whnf
                                                          hWhnf
                                                          context
                                                          state1
                                                          state2
                                                          args
                                                          0
                                                          inductInfo.numParams
                                                          initial
                                                          afterParams
                                                          hTypeSemantic.2
                                                          hParams
                                                      cases hProp :
                                                          psKernelInferIsPropWith
                                                            whnf
                                                            inferType
                                                            context
                                                            state2
                                                            typeWhnf with
                                                      | error error =>
                                                          simp [
                                                            psKernelInferProjectionWith,
                                                            hInferRun,
                                                            hTypeWhnf,
                                                            hIndexBound,
                                                            hFn,
                                                            hTypeName,
                                                            hInductFind,
                                                            hCtors,
                                                            hCtorRest,
                                                            args,
                                                            hArgsLength,
                                                            hCtorFind,
                                                            initial,
                                                            hParams,
                                                            hProp
                                                          ] at hSuccess
                                                      | ok propRun =>
                                                          rcases propRun with
                                                            ⟨propType, state3⟩
                                                          have hPropConfig :
                                                              PsKernelCheckerConfigurationSound
                                                                context
                                                                state3 :=
                                                            psKernelInferIsPropWith_preserves_configuration_of_infer_preserves
                                                              whnf
                                                              inferType
                                                              hWhnf
                                                              hInferPreserves
                                                              context
                                                              state2
                                                              state3
                                                              typeWhnf
                                                              propType
                                                              hParamsSemantic.2
                                                              hProp
                                                          cases hFields :
                                                              psKernelProjectionSkipFieldsWithFuel
                                                                (Nat.succ index)
                                                                whnf
                                                                inferType
                                                                context
                                                                state3
                                                                inductName
                                                                structValue
                                                                propType
                                                                index
                                                                0
                                                                afterParams with
                                                          | error error =>
                                                              simp [
                                                                psKernelInferProjectionWith,
                                                                hInferRun,
                                                                hTypeWhnf,
                                                                hIndexBound,
                                                                hFn,
                                                                hTypeName,
                                                                hInductFind,
                                                                hCtors,
                                                                hCtorRest,
                                                                args,
                                                                hArgsLength,
                                                                hCtorFind,
                                                                initial,
                                                                hParams,
                                                                hProp,
                                                                hFields
                                                              ] at hSuccess
                                                          | ok fieldRun =>
                                                              rcases fieldRun with
                                                                ⟨afterFields, state4⟩
                                                              have hFieldsSemantic :=
                                                                psKernelProjectionSkipFieldsWithFuel_configuration_refines_semantics
                                                                  (Nat.succ index)
                                                                  whnf
                                                                  inferType
                                                                  hWhnf
                                                                  hInfer
                                                                  context
                                                                  state3
                                                                  state4
                                                                  inductName
                                                                  structValue
                                                                  propType
                                                                  index
                                                                  0
                                                                  afterParams
                                                                  afterFields
                                                                  hPropConfig
                                                                  hFields
                                                              cases hFinal :
                                                                  whnf
                                                                    context
                                                                    state4
                                                                    afterFields with
                                                              | error error =>
                                                                  simp [
                                                                    psKernelInferProjectionWith,
                                                                    hInferRun,
                                                                    hTypeWhnf,
                                                                    hIndexBound,
                                                                    hFn,
                                                                    hTypeName,
                                                                    hInductFind,
                                                                    hCtors,
                                                                    hCtorRest,
                                                                    args,
                                                                    hArgsLength,
                                                                    hCtorFind,
                                                                    initial,
                                                                    hParams,
                                                                    hProp,
                                                                    hFields,
                                                                    hFinal
                                                                  ] at hSuccess
                                                              | ok finalRun =>
                                                                  rcases finalRun with
                                                                    ⟨finalExpr,
                                                                      finalState⟩
                                                                  have hFinalSemantic :=
                                                                    hWhnf
                                                                      context
                                                                      state4
                                                                      finalState
                                                                      afterFields
                                                                      finalExpr
                                                                      hFieldsSemantic.2
                                                                      hFinal
                                                                  cases finalExpr with
                                                                  | forallE fieldName domain
                                                                      fieldBody
                                                                      fieldBinderInfo =>
                                                                      have hInductAuth :
                                                                          psKernelFindConstantInList
                                                                              inductName
                                                                              context.environment.constants =
                                                                            Option.some
                                                                              (PsKernelConstantInfo.inductInfo
                                                                                inductInfo) := by
                                                                        unfold psKernelEnvironmentFind
                                                                          at hInductFind
                                                                        rw [← hConfig.1 inductName]
                                                                        exact hInductFind
                                                                      have hCtorAuth :
                                                                          psKernelFindConstantInList
                                                                              ctorName
                                                                              context.environment.constants =
                                                                            Option.some
                                                                              (PsKernelConstantInfo.ctorInfo
                                                                                ctorInfo) := by
                                                                        unfold psKernelEnvironmentFind
                                                                          at hCtorFind
                                                                        rw [← hConfig.1 ctorName]
                                                                        exact hCtorFind
                                                                      have hProjection :
                                                                          PsKernelProjectionResultJudgment
                                                                            context.environment
                                                                            context.localContext
                                                                            typeName
                                                                            index
                                                                            structValue
                                                                            structType
                                                                            domain := by
                                                                        exact
                                                                          PsKernelProjectionResultJudgment.intro
                                                                            typeName
                                                                            inductName
                                                                            ctorName
                                                                            fieldName
                                                                            index
                                                                            structValue
                                                                            structType
                                                                            typeWhnf
                                                                            inductLevels
                                                                            args
                                                                            inductInfo
                                                                            ctorInfo
                                                                            initial
                                                                            afterParams
                                                                            afterFields
                                                                            fieldBody
                                                                            domain
                                                                            fieldBinderInfo
                                                                            hTypeSemantic.1
                                                                            hFn
                                                                            rfl
                                                                            hIndexBound
                                                                            hTypeName
                                                                            hInductAuth
                                                                            (by
                                                                              simpa [hCtorRest]
                                                                                using hCtors)
                                                                            hArgsLength
                                                                            hCtorAuth
                                                                            rfl
                                                                            hParamsSemantic.1
                                                                            hFieldsSemantic.1
                                                                            hFinalSemantic.1
                                                                      have hTyping :
                                                                          PsKernelTypingJudgment
                                                                            context.environment
                                                                            context.localContext
                                                                            (PsKernelExpr.proj
                                                                              typeName
                                                                              index
                                                                              structValue)
                                                                            domain :=
                                                                        PsKernelTypingJudgment.proj
                                                                          typeName
                                                                          index
                                                                          structValue
                                                                          structType
                                                                          domain
                                                                          hInferSemantic.1
                                                                          hProjection
                                                                      cases propType with
                                                                      | false =>
                                                                          simp [
                                                                            psKernelInferProjectionWith,
                                                                            hInferRun,
                                                                            hTypeWhnf,
                                                                            hIndexBound,
                                                                            hFn,
                                                                            hTypeName,
                                                                            hInductFind,
                                                                            hCtors,
                                                                            hCtorRest,
                                                                            args,
                                                                            hArgsLength,
                                                                            hCtorFind,
                                                                            initial,
                                                                            hParams,
                                                                            hProp,
                                                                            hFields,
                                                                            hFinal
                                                                          ] at hSuccess
                                                                          rcases hSuccess with
                                                                            ⟨rfl, rfl⟩
                                                                          exact
                                                                            ⟨
                                                                              hTyping,
                                                                              hFinalSemantic.2
                                                                            ⟩
                                                                      | true =>
                                                                          cases hDomainProp :
                                                                              psKernelInferIsPropWith
                                                                                whnf
                                                                                inferType
                                                                                context
                                                                                finalState
                                                                                domain with
                                                                          | error error =>
                                                                              simp [
                                                                                psKernelInferProjectionWith,
                                                                                hInferRun,
                                                                                hTypeWhnf,
                                                                                hIndexBound,
                                                                                hFn,
                                                                                hTypeName,
                                                                                hInductFind,
                                                                                hCtors,
                                                                                hCtorRest,
                                                                                args,
                                                                                hArgsLength,
                                                                                hCtorFind,
                                                                                initial,
                                                                                hParams,
                                                                                hProp,
                                                                                hFields,
                                                                                hFinal,
                                                                                hDomainProp
                                                                              ] at hSuccess
                                                                          | ok domainPropRun =>
                                                                              rcases domainPropRun with
                                                                                ⟨domainIsProp,
                                                                                  domainPropState⟩
                                                                              have hDomainPropConfig :
                                                                                  PsKernelCheckerConfigurationSound
                                                                                    context
                                                                                    domainPropState :=
                                                                                psKernelInferIsPropWith_preserves_configuration_of_infer_preserves
                                                                                  whnf
                                                                                  inferType
                                                                                  hWhnf
                                                                                  hInferPreserves
                                                                                  context
                                                                                  finalState
                                                                                  domainPropState
                                                                                  domain
                                                                                  domainIsProp
                                                                                  hFinalSemantic.2
                                                                                  hDomainProp
                                                                              cases domainIsProp with
                                                                              | false =>
                                                                                  simp [
                                                                                    psKernelInferProjectionWith,
                                                                                    hInferRun,
                                                                                    hTypeWhnf,
                                                                                    hIndexBound,
                                                                                    hFn,
                                                                                    hTypeName,
                                                                                    hInductFind,
                                                                                    hCtors,
                                                                                    hCtorRest,
                                                                                    args,
                                                                                    hArgsLength,
                                                                                    hCtorFind,
                                                                                    initial,
                                                                                    hParams,
                                                                                    hProp,
                                                                                    hFields,
                                                                                    hFinal,
                                                                                    hDomainProp
                                                                                  ] at hSuccess
                                                                              | true =>
                                                                                  simp [
                                                                                    psKernelInferProjectionWith,
                                                                                    hInferRun,
                                                                                    hTypeWhnf,
                                                                                    hIndexBound,
                                                                                    hFn,
                                                                                    hTypeName,
                                                                                    hInductFind,
                                                                                    hCtors,
                                                                                    hCtorRest,
                                                                                    args,
                                                                                    hArgsLength,
                                                                                    hCtorFind,
                                                                                    initial,
                                                                                    hParams,
                                                                                    hProp,
                                                                                    hFields,
                                                                                    hFinal,
                                                                                    hDomainProp
                                                                                  ] at hSuccess
                                                                                  rcases hSuccess with
                                                                                    ⟨rfl, rfl⟩
                                                                                  exact
                                                                                    ⟨
                                                                                      hTyping,
                                                                                      hDomainPropConfig
                                                                                    ⟩
                                                                  | _ =>
                                                                      simp [
                                                                        psKernelInferProjectionWith,
                                                                        hInferRun,
                                                                        hTypeWhnf,
                                                                        hIndexBound,
                                                                        hFn,
                                                                        hTypeName,
                                                                        hInductFind,
                                                                        hCtors,
                                                                        hCtorRest,
                                                                        args,
                                                                        hArgsLength,
                                                                        hCtorFind,
                                                                        initial,
                                                                        hParams,
                                                                        hProp,
                                                                        hFields,
                                                                        hFinal
                                                                      ] at hSuccess
              | _ =>
                  simp [
                    psKernelInferProjectionWith,
                    hInferRun,
                    hTypeWhnf,
                    hIndexBound,
                    hFn
                  ] at hSuccess
