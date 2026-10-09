import Ps.KernelCore.Checker.Projection
import Ps.KernelCore.Metatheory.CheckerContracts

/-
Importable configuration-preservation layer for dependent projection.
Promoted from the standalone proof tree so inference soundness can compose it.
-/

theorem psKernelProjectionEnsureSortWith_preserves_configuration
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (type : PsKernelExpr)
    (level : PsKernelLevel)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelProjectionEnsureSortWith
          whnf context state type =
        Except.ok (Prod.mk level nextState)) :
    PsKernelCheckerConfigurationSound
      context
      nextState := by
  unfold psKernelProjectionEnsureSortWith at hSuccess
  cases hRun : whnf context state type with
  | error error =>
      simp [hRun] at hSuccess
  | ok result =>
      rcases result with ⟨reduced, reducedState⟩
      rw [hRun] at hSuccess
      cases reduced <;> simp at hSuccess
      case sort found =>
        rcases hSuccess with ⟨rfl, rfl⟩
        exact
          (hWhnf
            context
            state
            reducedState
            type
            (PsKernelExpr.sort found)
            hConfig
            hRun).2

theorem psKernelInferIsPropWith_preserves_configuration_of_infer_preserves
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (hInfer :
      PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (value : Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelInferIsPropWith
          whnf inferType context state expr =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound
      context
      nextState := by
  unfold psKernelInferIsPropWith at hSuccess
  cases hInferRun : inferType context state expr with
  | error error =>
      simp [hInferRun] at hSuccess
  | ok inferResult =>
      rcases inferResult with ⟨inferredType, inferState⟩
      rw [hInferRun] at hSuccess
      simp only at hSuccess
      have hInferConfig :
          PsKernelCheckerConfigurationSound
            context
            inferState :=
        hInfer
          context
          state
          inferState
          expr
          inferredType
          hConfig
          hInferRun
      cases hSort :
          psKernelProjectionEnsureSortWith
            whnf
            context
            inferState
            inferredType with
      | error error =>
          simp [hSort] at hSuccess
      | ok sortResult =>
          rcases sortResult with ⟨level, sortState⟩
          rw [hSort] at hSuccess
          simp at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            psKernelProjectionEnsureSortWith_preserves_configuration
              whnf
              hWhnf
              context
              inferState
              sortState
              inferredType
              level
              hInferConfig
              hSort

theorem psKernelProjectionApplyParamsWithFuel_preserves_configuration
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (args : List PsKernelExpr)
    (index numParams : Nat)
    (current result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelProjectionApplyParamsWithFuel
          fuel
          whnf
          context
          state
          args
          index
          numParams
          current =
        Except.ok (Prod.mk result nextState)) :
    PsKernelCheckerConfigurationSound
      context
      nextState := by
  induction fuel generalizing
      state nextState index current result with
  | zero =>
      simp [psKernelProjectionApplyParamsWithFuel] at hSuccess
  | succ remaining ih =>
      cases hMore : psKernelNatLt index numParams with
      | false =>
          simp [
            psKernelProjectionApplyParamsWithFuel,
            hMore
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
      | true =>
          cases hRun : whnf context state current with
          | error error =>
              simp [
                psKernelProjectionApplyParamsWithFuel,
                hMore,
                hRun
              ] at hSuccess
          | ok reducedResult =>
              rcases reducedResult with
                ⟨reduced, reducedState⟩
              have hReducedConfig :
                  PsKernelCheckerConfigurationSound
                    context
                    reducedState :=
                (hWhnf
                  context
                  state
                  reducedState
                  current
                  reduced
                  hConfig
                  hRun).2
              cases reduced with
              | forallE name domain body binderInfo =>
                  cases hArg :
                      psKernelExprListGet
                        args
                        index with
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
                              (psKernelExprInstantiate1
                                body
                                argument) =
                            Except.ok
                              (Prod.mk result nextState) := by
                        simpa [
                          psKernelProjectionApplyParamsWithFuel,
                          hMore,
                          hRun,
                          hArg
                        ] using hSuccess
                      exact
                        ih
                          reducedState
                          nextState
                          (Nat.succ index)
                          (psKernelExprInstantiate1
                            body
                            argument)
                          result
                          hReducedConfig
                          hRec
              | _ =>
                  simp [
                    psKernelProjectionApplyParamsWithFuel,
                    hMore,
                    hRun
                  ] at hSuccess

theorem psKernelProjectionSkipFieldsWithFuel_preserves_configuration_of_infer_preserves
    (fuel : Nat)
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (hInfer :
      PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (inductName : PsKernelName)
    (structValue : PsKernelExpr)
    (propType : Bool)
    (targetIndex index : Nat)
    (current result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
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
    PsKernelCheckerConfigurationSound
      context
      nextState := by
  induction fuel generalizing
      state nextState index current result with
  | zero =>
      simp [psKernelProjectionSkipFieldsWithFuel] at hSuccess
  | succ remaining ih =>
      cases hMore : psKernelNatLt index targetIndex with
      | false =>
          simp [
            psKernelProjectionSkipFieldsWithFuel,
            hMore
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig
      | true =>
          cases hRun : whnf context state current with
          | error error =>
              simp [
                psKernelProjectionSkipFieldsWithFuel,
                hMore,
                hRun
              ] at hSuccess
          | ok reducedResult =>
              rcases reducedResult with
                ⟨reduced, reducedState⟩
              have hReducedConfig :
                  PsKernelCheckerConfigurationSound
                    context
                    reducedState :=
                (hWhnf
                  context
                  state
                  reducedState
                  current
                  reduced
                  hConfig
                  hRun).2
              cases reduced with
              | forallE name domain body binderInfo =>
                  cases hLoose :
                      psKernelExprHasLooseBVar body with
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
                            Except.ok
                              (Prod.mk result nextState) := by
                        simpa [
                          psKernelProjectionSkipFieldsWithFuel,
                          hMore,
                          hRun,
                          hLoose
                        ] using hSuccess
                      exact
                        ih
                          reducedState
                          nextState
                          (Nat.succ index)
                          body
                          result
                          hReducedConfig
                          hRec
                  | true =>
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
                                  (psKernelExprInstantiate1
                                    body
                                    (PsKernelExpr.proj
                                      inductName
                                      index
                                      structValue)) =
                                Except.ok
                                  (Prod.mk result nextState) := by
                            simpa [
                              psKernelProjectionSkipFieldsWithFuel,
                              hMore,
                              hRun,
                              hLoose
                            ] using hSuccess
                          exact
                            ih
                              reducedState
                              nextState
                              (Nat.succ index)
                              (psKernelExprInstantiate1
                                body
                                (PsKernelExpr.proj
                                  inductName
                                  index
                                  structValue))
                              result
                              hReducedConfig
                              hRec
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
                                hProp
                              ] at hSuccess
                          | ok propResult =>
                              rcases propResult with
                                ⟨isProp, propState⟩
                              have hPropConfig :
                                  PsKernelCheckerConfigurationSound
                                    context
                                    propState :=
                                psKernelInferIsPropWith_preserves_configuration_of_infer_preserves
                                  whnf
                                  inferType
                                  hWhnf
                                  hInfer
                                  context
                                  reducedState
                                  propState
                                  domain
                                  isProp
                                  hReducedConfig
                                  hProp
                              cases isProp with
                              | false =>
                                  simp [
                                    psKernelProjectionSkipFieldsWithFuel,
                                    hMore,
                                    hRun,
                                    hLoose,
                                    hProp
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
                                          (psKernelExprInstantiate1
                                            body
                                            (PsKernelExpr.proj
                                              inductName
                                              index
                                              structValue)) =
                                        Except.ok
                                          (Prod.mk result nextState) := by
                                    simpa [
                                      psKernelProjectionSkipFieldsWithFuel,
                                      hMore,
                                      hRun,
                                      hLoose,
                                      hProp
                                    ] using hSuccess
                                  exact
                                    ih
                                      propState
                                      nextState
                                      (Nat.succ index)
                                      (psKernelExprInstantiate1
                                        body
                                        (PsKernelExpr.proj
                                          inductName
                                          index
                                          structValue))
                                      result
                                      hPropConfig
                                      hRec
              | _ =>
                  simp [
                    psKernelProjectionSkipFieldsWithFuel,
                    hMore,
                    hRun
                  ] at hSuccess


theorem psKernelInferProjectionWith_preserves_configuration_of_infer_preserves
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (hInfer :
      PsKernelInferOnlyConfigurationPreserves inferType)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue result : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelInferProjectionWith
          whnf inferType context state typeName index structValue =
        Except.ok (Prod.mk result nextState)) :
    PsKernelCheckerConfigurationSound
      context
      nextState := by
  cases hInferRun : inferType context state structValue with
  | error error =>
      simp [psKernelInferProjectionWith, hInferRun] at hSuccess
  | ok inferRun =>
      cases inferRun with
      | mk structType state0 =>
          have hState0 :
              PsKernelCheckerConfigurationSound context state0 :=
            hInfer
              context
              state
              state0
              structValue
              structType
              hConfig
              hInferRun
          cases hTypeWhnf : whnf context state0 structType with
          | error error =>
              simp [
                psKernelInferProjectionWith,
                hInferRun,
                hTypeWhnf
              ] at hSuccess
          | ok typeRun =>
              cases typeRun with
              | mk typeWhnf state1 =>
                  have hState1 :
                      PsKernelCheckerConfigurationSound context state1 :=
                    (hWhnf
                      context
                      state0
                      state1
                      structType
                      typeWhnf
                      hState0
                      hTypeWhnf).2
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
                          psKernelExprGetAppFn typeWhnf <;>
                        try
                          simp [
                            psKernelInferProjectionWith,
                            hInferRun,
                            hTypeWhnf,
                            hIndexBound,
                            hFn
                          ] at hSuccess
                      case const inductName inductLevels =>
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
                                                      (psKernelExprGetAppArgs typeWhnf) ≠
                                                    Nat.add
                                                      inductInfo.numParams
                                                      inductInfo.numIndices := by
                                                intro hEq
                                                have hBeqTrue :
                                                    Nat.beq
                                                        (psKernelExprListLength
                                                          (psKernelExprGetAppArgs typeWhnf))
                                                        (Nat.add
                                                          inductInfo.numParams
                                                          inductInfo.numIndices) =
                                                      true := by
                                                  simpa [hEq]
                                                have hBeqFalse :
                                                    Nat.beq
                                                        (psKernelExprListLength
                                                          (psKernelExprGetAppArgs typeWhnf))
                                                        (Nat.add
                                                          inductInfo.numParams
                                                          inductInfo.numIndices) =
                                                      false := by
                                                  simpa [args] using
                                                    hArgsLengthBool
                                                rw [hBeqFalse] at hBeqTrue
                                                cases hBeqTrue
                                              simp only [
                                                hCtors,
                                                hCtorRest
                                              ] at hSuccess
                                              split at hSuccess
                                              next hEq =>
                                                exact (hArgsLengthNeRaw hEq).elim
                                              next hNe =>
                                                simp at hSuccess
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
                                                          (Nat.succ inductInfo.numParams)
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
                                                        cases paramRun with
                                                        | mk afterParams state2 =>
                                                            have hState2 :
                                                                PsKernelCheckerConfigurationSound
                                                                  context
                                                                  state2 :=
                                                              psKernelProjectionApplyParamsWithFuel_preserves_configuration
                                                                (Nat.succ inductInfo.numParams)
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
                                                                hState1
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
                                                                cases propRun with
                                                                | mk propType state3 =>
                                                                    have hState3 :
                                                                        PsKernelCheckerConfigurationSound
                                                                          context
                                                                          state3 :=
                                                                      psKernelInferIsPropWith_preserves_configuration_of_infer_preserves
                                                                        whnf
                                                                        inferType
                                                                        hWhnf
                                                                        hInfer
                                                                        context
                                                                        state2
                                                                        state3
                                                                        typeWhnf
                                                                        propType
                                                                        hState2
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
                                                                        cases fieldRun with
                                                                        | mk afterFields state4 =>
                                                                            have hState4 :
                                                                                PsKernelCheckerConfigurationSound
                                                                                  context
                                                                                  state4 :=
                                                                              psKernelProjectionSkipFieldsWithFuel_preserves_configuration_of_infer_preserves
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
                                                                                hState3
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
                                                                                cases finalRun with
                                                                                | mk finalExpr state5 =>
                                                                                    have hState5 :
                                                                                        PsKernelCheckerConfigurationSound
                                                                                          context
                                                                                          state5 :=
                                                                                      (hWhnf
                                                                                        context
                                                                                        state4
                                                                                        state5
                                                                                        afterFields
                                                                                        finalExpr
                                                                                        hState4
                                                                                        hFinal).2
                                                                                    cases finalExpr <;>
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
                                                                                          hCtorFind,
                                                                                          initial,
                                                                                          hParams,
                                                                                          hProp,
                                                                                          hFields,
                                                                                          hFinal
                                                                                        ] at hSuccess
                                                                                    case forallE fieldName domain fieldBody fieldBinderInfo =>
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
                                                                                          exact hState5
                                                                                      | true =>
                                                                                          cases hDomainProp :
                                                                                              psKernelInferIsPropWith
                                                                                                whnf
                                                                                                inferType
                                                                                                context
                                                                                                state5
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
                                                                                              cases domainPropRun with
                                                                                              | mk domainIsProp state6 =>
                                                                                                  have hState6 :
                                                                                                      PsKernelCheckerConfigurationSound
                                                                                                        context
                                                                                                        state6 :=
                                                                                                    psKernelInferIsPropWith_preserves_configuration_of_infer_preserves
                                                                                                      whnf
                                                                                                      inferType
                                                                                                      hWhnf
                                                                                                      hInfer
                                                                                                      context
                                                                                                      state5
                                                                                                      state6
                                                                                                      domain
                                                                                                      domainIsProp
                                                                                                      hState5
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
                                                                                                      exact hState6


