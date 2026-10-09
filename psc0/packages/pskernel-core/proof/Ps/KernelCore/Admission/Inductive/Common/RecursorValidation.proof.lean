import Ps.KernelCore.Admission.Inductive.Common.RecursorValidation
import Ps.KernelCore.Metatheory.Inductive

theorem psKernelValidateSimpleRecursorRulesWorker_empty
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel) :
    psKernelValidateSimpleRecursorRulesWorker
        List.nil fuel session params ruleBinders motive levels List.nil =
      Except.ok Unit.unit := by
  rfl


theorem psKernelValidateSimpleRecursorRulesWorker_success_refines
    (shapes : List PsKernelSimpleConstructorShape)
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel)
    (rules : List PsKernelRecursorRule)
    (hCheckSound : PsKernelSessionCheckSoundAtFuel fuel)
    (hDefEqSound : PsKernelSessionDefEqSoundAtFuel fuel)
    (hSuccess :
      psKernelValidateSimpleRecursorRulesWorker
          shapes
          fuel
          session
          params
          ruleBinders
          motive
          levels
          rules =
        Except.ok Unit.unit) :
    PsKernelSimpleRecursorRulesValid
      fuel
      params
      ruleBinders
      motive
      levels
      session
      shapes
      rules := by
  induction shapes generalizing session rules with
  | nil =>
      cases rules with
      | nil =>
          exact
            PsKernelSimpleRecursorRulesValid.nil
              session
      | cons rule rest =>
          simp [
            psKernelValidateSimpleRecursorRulesWorker
          ] at hSuccess
  | cons shape shapeRest ih =>
      cases rules with
      | nil =>
          simp [
            psKernelValidateSimpleRecursorRulesWorker
          ] at hSuccess
      | cons rule ruleRest =>
          cases hCheck :
              psKernelSessionCheck
                fuel
                session
                rule.rhs with
          | error error =>
              simp [
                psKernelValidateSimpleRecursorRulesWorker,
                hCheck
              ] at hSuccess
          | ok checkRun =>
              cases checkRun with
              | mk gotType checkedSession =>
                  let expectedType :=
                    psKernelCloseOpenBinders
                      (psKernelOpenBinderListAppend
                        ruleBinders
                        shape.fields)
                      (psKernelSimpleMotiveApp
                        motive
                        shape.resultIndices
                        (psKernelSimpleCtorApp
                          levels
                          params
                          shape))
                  cases hEq :
                      psKernelSessionIsDefEq
                        fuel
                        checkedSession
                        gotType
                        expectedType with
                  | error error =>
                      simp [
                        psKernelValidateSimpleRecursorRulesWorker,
                        hCheck,
                        expectedType,
                        hEq
                      ] at hSuccess
                  | ok eqRun =>
                      cases eqRun with
                      | mk equal equalSession =>
                          cases equal with
                          | false =>
                              simp [
                                psKernelValidateSimpleRecursorRulesWorker,
                                hCheck,
                                expectedType,
                                hEq
                              ] at hSuccess
                          | true =>
                              have hTyping :
                                  PsKernelTypingJudgment
                                    session.context.environment
                                    session.context.localContext
                                    rule.rhs
                                    gotType :=
                                hCheckSound
                                  session
                                  checkedSession
                                  rule.rhs
                                  gotType
                                  hCheck
                              have hDefEq :
                                  PsKernelDefEqJudgment
                                    checkedSession.context.environment
                                    checkedSession.context.localContext
                                    gotType
                                    expectedType :=
                                hDefEqSound
                                  checkedSession
                                  equalSession
                                  gotType
                                  expectedType
                                  hEq
                              have hRest :
                                  PsKernelSimpleRecursorRulesValid
                                    fuel
                                    params
                                    ruleBinders
                                    motive
                                    levels
                                    equalSession
                                    shapeRest
                                    ruleRest := by
                                apply
                                  ih
                                    (session := equalSession)
                                    (rules := ruleRest)
                                simpa [
                                  psKernelValidateSimpleRecursorRulesWorker,
                                  hCheck,
                                  expectedType,
                                  hEq
                                ] using hSuccess
                              exact
                                PsKernelSimpleRecursorRulesValid.cons
                                  session
                                  checkedSession
                                  equalSession
                                  shape
                                  shapeRest
                                  rule
                                  ruleRest
                                  gotType
                                  hCheck
                                  hTyping
                                  (by simpa [expectedType] using hEq)
                                  (by simpa [expectedType] using hDefEq)
                                  hRest

theorem psKernelValidateSimpleRecursorRules_success_refines
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel)
    (shapes : List PsKernelSimpleConstructorShape)
    (rules : List PsKernelRecursorRule)
    (hCheckSound : PsKernelSessionCheckSoundAtFuel fuel)
    (hDefEqSound : PsKernelSessionDefEqSoundAtFuel fuel)
    (hSuccess :
      psKernelValidateSimpleRecursorRules
          fuel
          session
          params
          ruleBinders
          motive
          levels
          shapes
          rules =
        Except.ok Unit.unit) :
    PsKernelSimpleRecursorRulesValid
      fuel
      params
      ruleBinders
      motive
      levels
      session
      shapes
      rules := by
  exact
    psKernelValidateSimpleRecursorRulesWorker_success_refines
      shapes
      fuel
      session
      params
      ruleBinders
      motive
      levels
      rules
      hCheckSound
      hDefEqSound
      hSuccess
