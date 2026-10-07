import Ps.KernelCore.Checker.DefEq.Shortcuts
import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.Comparator

/-
Configuration-aware refinement for the Bool.true reflection shortcut.

The positive case does not add a new equality axiom: public WHNF must reduce
the left expression to exactly the Bool.true constant that appears on the
right, so ordinary reduction closure is sufficient.
-/

theorem psKernelDefEqReflectionWith_configuration_preserves
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : Option Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqReflectionWith
          whnf context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelCheckerConfigurationSound context nextState := by
  cases hMay :
      (if psKernelExprHasFVar left then
         context.eagerReduce
       else
         true) with
  | false =>
      simp [
        psKernelDefEqReflectionWith,
        hMay
      ] at hSuccess
      rcases hSuccess with ⟨rfl, rfl⟩
      exact hConfig
  | true =>
      cases right with
      | const name levels =>
          cases levels with
          | nil =>
              cases hName :
                  psKernelNameEq
                    name
                    psKernelBoolTrueName with
              | false =>
                  simp [
                    psKernelDefEqReflectionWith,
                    hMay,
                    hName
                  ] at hSuccess
                  rcases hSuccess with ⟨rfl, rfl⟩
                  exact hConfig
              | true =>
                  cases hRun :
                      whnf context state left with
                  | error error =>
                      simp [
                        psKernelDefEqReflectionWith,
                        hMay,
                        hName,
                        hRun
                      ] at hSuccess
                  | ok run =>
                      rcases run with ⟨reduced, reducedState⟩
                      have hReduced :=
                        hWhnf
                          context
                          state
                          reducedState
                          left
                          reduced
                          hConfig
                          hRun
                      cases reduced with
                      | const reducedName reducedLevels =>
                          cases reducedLevels with
                          | nil =>
                              cases hReducedName :
                                  psKernelNameEq
                                    reducedName
                                    psKernelBoolTrueName with
                              | false =>
                                  simp [
                                    psKernelDefEqReflectionWith,
                                    hMay,
                                    hName,
                                    hRun,
                                    hReducedName
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact hReduced.2
                              | true =>
                                  simp [
                                    psKernelDefEqReflectionWith,
                                    hMay,
                                    hName,
                                    hRun,
                                    hReducedName
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  exact hReduced.2
                          | cons level rest =>
                              simp [
                                psKernelDefEqReflectionWith,
                                hMay,
                                hName,
                                hRun
                              ] at hSuccess
                              rcases hSuccess with ⟨rfl, rfl⟩
                              exact hReduced.2
                      | _ =>
                          simp [
                            psKernelDefEqReflectionWith,
                            hMay,
                            hName,
                            hRun
                          ] at hSuccess
                          rcases hSuccess with ⟨rfl, rfl⟩
                          exact hReduced.2
          | cons level rest =>
              simp [
                psKernelDefEqReflectionWith,
                hMay
              ] at hSuccess
              rcases hSuccess with ⟨rfl, rfl⟩
              exact hConfig
      | _ =>
          simp [
            psKernelDefEqReflectionWith,
            hMay
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hConfig


theorem psKernelDefEqReflectionWith_true_refines
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (hString :
      PsKernelStringEqSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqReflectionWith
          whnf context state left right =
        Except.ok
          (Prod.mk (Option.some true) nextState)) :
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right := by
  cases hMay :
      (if psKernelExprHasFVar left then
         context.eagerReduce
       else
         true) with
  | false =>
      simp [
        psKernelDefEqReflectionWith,
        hMay
      ] at hSuccess
  | true =>
      cases right with
      | const name levels =>
          cases levels with
          | nil =>
              cases hName :
                  psKernelNameEq
                    name
                    psKernelBoolTrueName with
              | false =>
                  simp [
                    psKernelDefEqReflectionWith,
                    hMay,
                    hName
                  ] at hSuccess
              | true =>
                  have hNameEq :
                      name = psKernelBoolTrueName :=
                    psKernelNameEq_sound_of_string_law
                      hString
                      name
                      psKernelBoolTrueName
                      hName
                  cases hRun :
                      whnf context state left with
                  | error error =>
                      simp [
                        psKernelDefEqReflectionWith,
                        hMay,
                        hName,
                        hRun
                      ] at hSuccess
                  | ok run =>
                      rcases run with ⟨reduced, reducedState⟩
                      have hReduced :=
                        hWhnf
                          context
                          state
                          reducedState
                          left
                          reduced
                          hConfig
                          hRun
                      cases reduced with
                      | const reducedName reducedLevels =>
                          cases reducedLevels with
                          | nil =>
                              cases hReducedName :
                                  psKernelNameEq
                                    reducedName
                                    psKernelBoolTrueName with
                              | false =>
                                  simp [
                                    psKernelDefEqReflectionWith,
                                    hMay,
                                    hName,
                                    hRun,
                                    hReducedName
                                  ] at hSuccess
                              | true =>
                                  have hReducedNameEq :
                                      reducedName =
                                        psKernelBoolTrueName :=
                                    psKernelNameEq_sound_of_string_law
                                      hString
                                      reducedName
                                      psKernelBoolTrueName
                                      hReducedName
                                  simp [
                                    psKernelDefEqReflectionWith,
                                    hMay,
                                    hName,
                                    hRun,
                                    hReducedName
                                  ] at hSuccess
                                  rcases hSuccess with ⟨rfl, rfl⟩
                                  subst name
                                  subst reducedName
                                  exact
                                    PsKernelDefEqJudgment.reductionClosure
                                      left
                                      (PsKernelExpr.const
                                        psKernelBoolTrueName
                                        List.nil)
                                      hReduced.1
                          | cons level rest =>
                              simp [
                                psKernelDefEqReflectionWith,
                                hMay,
                                hName,
                                hRun
                              ] at hSuccess
                      | _ =>
                          simp [
                            psKernelDefEqReflectionWith,
                            hMay,
                            hName,
                            hRun
                          ] at hSuccess
          | cons level rest =>
              simp [
                psKernelDefEqReflectionWith,
                hMay
              ] at hSuccess
      | _ =>
          simp [
            psKernelDefEqReflectionWith,
            hMay
          ] at hSuccess


theorem psKernelDefEqReflectionWith_optional_configuration_sound
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound whnf)
    (hString :
      PsKernelStringEqSoundLaw)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (answer : Option Bool)
    (hConfig :
      PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqReflectionWith
          whnf context state left right =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalDefEqPostcondition
      context nextState left right answer := by
  refine
    ⟨
      psKernelDefEqReflectionWith_configuration_preserves
        whnf hWhnf
        context state nextState
        left right answer
        hConfig hSuccess,
      ?_
    ⟩
  cases answer with
  | none =>
      trivial
  | some value =>
      cases value with
      | false =>
          trivial
      | true =>
          exact
            psKernelDefEqReflectionWith_true_refines
              whnf hWhnf hString
              context state nextState
              left right
              hConfig hSuccess
