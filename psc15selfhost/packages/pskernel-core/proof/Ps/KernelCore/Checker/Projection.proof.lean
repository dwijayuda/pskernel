import Ps.KernelCore.Checker.Projection
import Ps.KernelCore.Metatheory.Judgments

theorem psKernelProjectionApplyParamsWithFuel_zero
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (args : List PsKernelExpr)
    (index numParams : Nat)
    (current : PsKernelExpr) :
    psKernelProjectionApplyParamsWithFuel
        0 whnf context state args index numParams current =
      Except.error "kernel projection parameter budget exhausted" := by
  rfl

theorem psKernelProjectionSkipFieldsWithFuel_zero
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (inductName : PsKernelName)
    (structValue : PsKernelExpr)
    (propType : Bool)
    (targetIndex index : Nat)
    (current : PsKernelExpr) :
    psKernelProjectionSkipFieldsWithFuel
        0 whnf inferType context state inductName structValue
        propType targetIndex index current =
      Except.error "kernel projection field budget exhausted" := by
  rfl

theorem psKernelProjectionEnsureSortWith_error
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (type : PsKernelExpr)
    (error : String)
    (h : whnf context state type = Except.error error) :
    psKernelProjectionEnsureSortWith whnf context state type =
      Except.error error := by
  simp [psKernelProjectionEnsureSortWith, h]


theorem psKernelProjectionApplyParamsWithFuel_refines_semantics
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (args : List PsKernelExpr)
    (index numParams : Nat)
    (current result : PsKernelExpr)
    (hWhnfSound : PsKernelWhnfSound whnf)
    (hSuccess :
      psKernelProjectionApplyParamsWithFuel
          fuel whnf context state args index numParams current =
        Except.ok (Prod.mk result nextState)) :
    PsKernelProjectionApplyParamsJudgment
      context.environment context.localContext args
      index numParams current result := by
  induction fuel generalizing state index current result nextState with
  | zero =>
      simp [psKernelProjectionApplyParamsWithFuel] at hSuccess
  | succ remaining ih =>
      cases hMore : psKernelNatLt index numParams with
      | false =>
          simp [psKernelProjectionApplyParamsWithFuel, hMore] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            PsKernelProjectionApplyParamsJudgment.done
              index numParams current hMore
      | true =>
          cases hRun : whnf context state current with
          | error error =>
              simp [
                psKernelProjectionApplyParamsWithFuel,
                hMore,
                hRun
              ] at hSuccess
          | ok run =>
              cases run with
              | mk reduced state1 =>
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
                          have hClosure :
                              PsKernelReductionClosure
                                context.environment
                                context.localContext
                                current
                                (PsKernelExpr.forallE
                                  name domain body binderInfo) :=
                            hWhnfSound
                              context state state1 current
                              (PsKernelExpr.forallE
                                name domain body binderInfo)
                              hRun
                          have hRest :
                              PsKernelProjectionApplyParamsJudgment
                                context.environment
                                context.localContext
                                args
                                (Nat.succ index)
                                numParams
                                (psKernelExprInstantiate1 body argument)
                                result := by
                            apply
                              ih
                                (state := state1)
                                (index := Nat.succ index)
                                (current :=
                                  psKernelExprInstantiate1 body argument)
                                (result := result)
                                (nextState := nextState)
                            simpa [
                              psKernelProjectionApplyParamsWithFuel,
                              hMore,
                              hRun,
                              hArg
                            ] using hSuccess
                          exact
                            PsKernelProjectionApplyParamsJudgment.step
                              index numParams current domain body result
                              argument name binderInfo hMore hClosure hArg hRest
                  | bvar value =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | fvar value =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | mvar value =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | sort value =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | const name levels =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | app fn arg =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | lam name type body binderInfo =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | letE name type value body nondep =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | lit value =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | mdata metadata body =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess
                  | proj typeName projIndex body =>
                      simp [psKernelProjectionApplyParamsWithFuel, hMore, hRun] at hSuccess

theorem psKernelProjectionSkipFieldsWithFuel_refines_semantics
    (fuel : Nat)
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (inductName : PsKernelName)
    (structValue : PsKernelExpr)
    (propType : Bool)
    (targetIndex index : Nat)
    (current result : PsKernelExpr)
    (hWhnfSound : PsKernelWhnfSound whnf)
    (hSuccess :
      psKernelProjectionSkipFieldsWithFuel
          fuel whnf inferType context state
          inductName structValue propType targetIndex index current =
        Except.ok (Prod.mk result nextState)) :
    PsKernelProjectionSkipFieldsJudgment
      context.environment context.localContext
      inductName structValue targetIndex index current result := by
  induction fuel generalizing state index current result nextState with
  | zero =>
      simp [psKernelProjectionSkipFieldsWithFuel] at hSuccess
  | succ remaining ih =>
      cases hMore : psKernelNatLt index targetIndex with
      | false =>
          simp [psKernelProjectionSkipFieldsWithFuel, hMore] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact
            PsKernelProjectionSkipFieldsJudgment.done
              index current hMore
      | true =>
          cases hRun : whnf context state current with
          | error error =>
              simp [
                psKernelProjectionSkipFieldsWithFuel,
                hMore,
                hRun
              ] at hSuccess
          | ok run =>
              cases run with
              | mk reduced state1 =>
                  cases reduced with
                  | forallE name domain body binderInfo =>
                      have hClosure :
                          PsKernelReductionClosure
                            context.environment
                            context.localContext
                            current
                            (PsKernelExpr.forallE
                              name domain body binderInfo) :=
                        hWhnfSound
                          context state state1 current
                          (PsKernelExpr.forallE
                            name domain body binderInfo)
                          hRun
                      cases hLoose : psKernelExprHasLooseBVar body with
                      | false =>
                          have hRest :
                              PsKernelProjectionSkipFieldsJudgment
                                context.environment
                                context.localContext
                                inductName structValue targetIndex
                                (Nat.succ index) body result := by
                            apply
                              ih
                                (state := state1)
                                (index := Nat.succ index)
                                (current := body)
                                (result := result)
                                (nextState := nextState)
                            simpa [
                              psKernelProjectionSkipFieldsWithFuel,
                              hMore,
                              hRun,
                              hLoose
                            ] using hSuccess
                          exact
                            PsKernelProjectionSkipFieldsJudgment.stepClosed
                              index current domain body result name binderInfo
                              hMore hClosure hLoose hRest
                      | true =>
                          let nextExpr :=
                            psKernelExprInstantiate1
                              body
                              (PsKernelExpr.proj
                                inductName index structValue)
                          cases propType with
                          | false =>
                              have hRest :
                                  PsKernelProjectionSkipFieldsJudgment
                                    context.environment
                                    context.localContext
                                    inductName structValue targetIndex
                                    (Nat.succ index) nextExpr result := by
                                apply
                                  ih
                                    (state := state1)
                                    (index := Nat.succ index)
                                    (current := nextExpr)
                                    (result := result)
                                    (nextState := nextState)
                                simpa [
                                  psKernelProjectionSkipFieldsWithFuel,
                                  hMore,
                                  hRun,
                                  hLoose,
                                  nextExpr
                                ] using hSuccess
                              exact
                                PsKernelProjectionSkipFieldsJudgment.stepDependent
                                  index current domain body result name binderInfo
                                  hMore hClosure hLoose hRest
                          | true =>
                              cases hProp :
                                  psKernelInferIsPropWith
                                    whnf inferType context state1 domain with
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
                                  cases propRun with
                                  | mk isProp state2 =>
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
                                          have hRest :
                                              PsKernelProjectionSkipFieldsJudgment
                                                context.environment
                                                context.localContext
                                                inductName structValue targetIndex
                                                (Nat.succ index)
                                                nextExpr result := by
                                            apply
                                              ih
                                                (state := state2)
                                                (index := Nat.succ index)
                                                (current := nextExpr)
                                                (result := result)
                                                (nextState := nextState)
                                            simpa [
                                              psKernelProjectionSkipFieldsWithFuel,
                                              hMore,
                                              hRun,
                                              hLoose,
                                              hProp,
                                              nextExpr
                                            ] using hSuccess
                                          exact
                                            PsKernelProjectionSkipFieldsJudgment.stepDependent
                                              index current domain body result
                                              name binderInfo
                                              hMore hClosure hLoose hRest
                  | bvar value =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | fvar value =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | mvar value =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | sort value =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | const name levels =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | app fn arg =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | lam name type body binderInfo =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | letE name type value body nondep =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | lit value =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | mdata metadata body =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
                  | proj typeName projIndex body =>
                      simp [psKernelProjectionSkipFieldsWithFuel, hMore, hRun] at hSuccess
