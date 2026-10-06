import Ps.KernelCore.Admission.Declaration.Validation
import Ps.KernelCore.Metatheory.Admission
import Ps.KernelCore.Metatheory.SessionRefinement

theorem psKernelNameListsEq_nil :
    psKernelNameListsEq List.nil List.nil = true := by
  rfl

theorem psKernelNameMember_nil
    (name : PsKernelName) :
    psKernelNameMember name List.nil = false := by
  rfl

theorem psKernelLevelsHaveMVar_nil :
    psKernelLevelsHaveMVar List.nil = false := by
  rfl

theorem psKernelExprHasMVar_bvar
    (index : Nat) :
    psKernelExprHasMVar (PsKernelExpr.bvar index) = false := by
  rfl


theorem psKernelCheckNoMVarNoFVar_rejects_mvar
    (expr : PsKernelExpr)
    (h : psKernelExprHasMVar expr = true) :
    psKernelCheckNoMVarNoFVar expr =
      Except.error "declaration has metavariables" := by
  simp [psKernelCheckNoMVarNoFVar, h]

theorem psKernelCheckNoMVarNoFVar_rejects_fvar
    (expr : PsKernelExpr)
    (hMVar : psKernelExprHasMVar expr = false)
    (hFVar : psKernelExprHasFVar expr = true) :
    psKernelCheckNoMVarNoFVar expr =
      Except.error "declaration has free variables" := by
  simp [psKernelCheckNoMVarNoFVar, hMVar, hFVar]

theorem psKernelCheckNoMVarNoFVar_accepts_closed
    (expr : PsKernelExpr)
    (hMVar : psKernelExprHasMVar expr = false)
    (hFVar : psKernelExprHasFVar expr = false) :
    psKernelCheckNoMVarNoFVar expr =
      Except.ok Unit.unit := by
  simp [psKernelCheckNoMVarNoFVar, hMVar, hFVar]

theorem psKernelCheckLevelParams_rejects_undefined
    (expr : PsKernelExpr)
    (allowed : List PsKernelName)
    (name : PsKernelName)
    (h :
      psKernelFindUndefExprLevelParam expr allowed =
        Option.some name) :
    psKernelCheckLevelParams expr allowed =
      Except.error
        "invalid reference to undefined universe level parameter" := by
  simp [psKernelCheckLevelParams, h]

theorem psKernelCheckLevelParams_accepts_defined
    (expr : PsKernelExpr)
    (allowed : List PsKernelName)
    (h :
      psKernelFindUndefExprLevelParam expr allowed =
        Option.none) :
    psKernelCheckLevelParams expr allowed =
      Except.ok Unit.unit := by
  simp [psKernelCheckLevelParams, h]


theorem psKernelCheckDefinitionBody_rejects_shape_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo)
    (error : String)
    (h :
      psKernelCheckNoMVarNoFVar value.value =
        Except.error error) :
    psKernelCheckDefinitionBodyWithSession fuel session value =
      Except.error error := by
  simp [psKernelCheckDefinitionBodyWithSession, h]

theorem psKernelCheckDefinitionBody_rejects_level_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo)
    (error : String)
    (hClosed :
      psKernelCheckNoMVarNoFVar value.value =
        Except.ok Unit.unit)
    (hLevels :
      psKernelCheckLevelParams
          value.value
          value.base.levelParams =
        Except.error error) :
    psKernelCheckDefinitionBodyWithSession fuel session value =
      Except.error error := by
  simp [
    psKernelCheckDefinitionBodyWithSession,
    hClosed,
    hLevels
  ]

theorem psKernelCheckDefinitionBody_propagates_check_error
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo)
    (error : String)
    (hClosed :
      psKernelCheckNoMVarNoFVar value.value =
        Except.ok Unit.unit)
    (hLevels :
      psKernelCheckLevelParams
          value.value
          value.base.levelParams =
        Except.ok Unit.unit)
    (hCheck :
      psKernelSessionCheck fuel session value.value =
        Except.error error) :
    psKernelCheckDefinitionBodyWithSession fuel session value =
      Except.error error := by
  simp [
    psKernelCheckDefinitionBodyWithSession,
    hClosed,
    hLevels,
    hCheck
  ]

theorem psKernelCheckDefinitionBody_rejects_type_mismatch
    (fuel : Nat)
    (session checkedSession nextSession : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo)
    (inferredType : PsKernelExpr)
    (hClosed :
      psKernelCheckNoMVarNoFVar value.value =
        Except.ok Unit.unit)
    (hLevels :
      psKernelCheckLevelParams
          value.value
          value.base.levelParams =
        Except.ok Unit.unit)
    (hCheck :
      psKernelSessionCheck fuel session value.value =
        Except.ok (Prod.mk inferredType checkedSession))
    (hDefEq :
      psKernelSessionIsDefEq
          fuel
          checkedSession
          inferredType
          value.base.type =
        Except.ok (Prod.mk false nextSession)) :
    psKernelCheckDefinitionBodyWithSession fuel session value =
      Except.error "definition type mismatch" := by
  simp [
    psKernelCheckDefinitionBodyWithSession,
    hClosed,
    hLevels,
    hCheck,
    hDefEq
  ]

theorem psKernelCheckDefinitionBody_accepts_defeq
    (fuel : Nat)
    (session checkedSession nextSession : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo)
    (inferredType : PsKernelExpr)
    (hClosed :
      psKernelCheckNoMVarNoFVar value.value =
        Except.ok Unit.unit)
    (hLevels :
      psKernelCheckLevelParams
          value.value
          value.base.levelParams =
        Except.ok Unit.unit)
    (hCheck :
      psKernelSessionCheck fuel session value.value =
        Except.ok (Prod.mk inferredType checkedSession))
    (hDefEq :
      psKernelSessionIsDefEq
          fuel
          checkedSession
          inferredType
          value.base.type =
        Except.ok (Prod.mk true nextSession)) :
    psKernelCheckDefinitionBodyWithSession fuel session value =
      Except.ok nextSession := by
  simp [
    psKernelCheckDefinitionBodyWithSession,
    hClosed,
    hLevels,
    hCheck,
    hDefEq
  ]


theorem psKernelCheckNoMVarNoFVar_success_flags
    (expr : PsKernelExpr)
    (hSuccess :
      psKernelCheckNoMVarNoFVar expr =
        Except.ok Unit.unit) :
    psKernelExprHasMVar expr = false ∧
    psKernelExprHasFVar expr = false := by
  cases hMVar : psKernelExprHasMVar expr with
  | true =>
      simp [
        psKernelCheckNoMVarNoFVar,
        hMVar
      ] at hSuccess
  | false =>
      cases hFVar : psKernelExprHasFVar expr with
      | true =>
          simp [
            psKernelCheckNoMVarNoFVar,
            hMVar,
            hFVar
          ] at hSuccess
      | false =>
          constructor <;> rfl

theorem psKernelCheckLevelParams_success_none
    (expr : PsKernelExpr)
    (allowed : List PsKernelName)
    (hSuccess :
      psKernelCheckLevelParams expr allowed =
        Except.ok Unit.unit) :
    psKernelFindUndefExprLevelParam expr allowed =
      Option.none := by
  cases hFind :
      psKernelFindUndefExprLevelParam expr allowed with
  | none =>
      rfl
  | some name =>
      simp [
        psKernelCheckLevelParams,
        hFind
      ] at hSuccess

theorem psKernelCheckDefinitionBody_success_refines_semantics
    (fuel : Nat)
    (session nextSession : PsKernelCheckerSession)
    (value : PsKernelDefinitionInfo)
    (hCheckSound :
      PsKernelInferenceSound
        (psKernelCheckerCheck fuel))
    (hDefEqSound :
      PsKernelDefEqSound
        (psKernelIsDefEq fuel))
    (hSuccess :
      psKernelCheckDefinitionBodyWithSession
          fuel session value =
        Except.ok nextSession) :
    PsKernelDefinitionBodyValid
      session
      value := by
  cases hClosed :
      psKernelCheckNoMVarNoFVar value.value with
  | error error =>
      simp [
        psKernelCheckDefinitionBodyWithSession,
        hClosed
      ] at hSuccess
  | ok closedUnit =>
      cases closedUnit
      cases hLevels :
          psKernelCheckLevelParams
            value.value
            value.base.levelParams with
      | error error =>
          simp [
            psKernelCheckDefinitionBodyWithSession,
            hClosed,
            hLevels
          ] at hSuccess
      | ok levelsUnit =>
          cases levelsUnit
          cases hCheck :
              psKernelSessionCheck
                fuel
                session
                value.value with
          | error error =>
              simp [
                psKernelCheckDefinitionBodyWithSession,
                hClosed,
                hLevels,
                hCheck
              ] at hSuccess
          | ok checkResult =>
              cases checkResult with
              | mk inferredType checkedSession =>
                  cases hDefEq :
                      psKernelSessionIsDefEq
                        fuel
                        checkedSession
                        inferredType
                        value.base.type with
                  | error error =>
                      simp [
                        psKernelCheckDefinitionBodyWithSession,
                        hClosed,
                        hLevels,
                        hCheck,
                        hDefEq
                      ] at hSuccess
                  | ok defeqResult =>
                      cases defeqResult with
                      | mk equal finalSession =>
                          cases equal with
                          | false =>
                              simp [
                                psKernelCheckDefinitionBodyWithSession,
                                hClosed,
                                hLevels,
                                hCheck,
                                hDefEq
                              ] at hSuccess
                          | true =>
                              have hFlags :=
                                psKernelCheckNoMVarNoFVar_success_flags
                                  value.value
                                  hClosed
                              have hLevelNone :=
                                psKernelCheckLevelParams_success_none
                                  value.value
                                  value.base.levelParams
                                  hLevels
                              have hTyping :
                                  PsKernelTypingJudgment
                                    session.context.environment
                                    session.context.localContext
                                    value.value
                                    inferredType :=
                                psKernelSessionCheck_refines_typing_core
                                  fuel
                                  session
                                  checkedSession
                                  value.value
                                  inferredType
                                  hCheckSound
                                  hCheck
                              have hCheckedContext :
                                  checkedSession.context =
                                    session.context :=
                                psKernelSessionCheck_success_preserves_context_core
                                  fuel
                                  session
                                  checkedSession
                                  value.value
                                  inferredType
                                  hCheck
                              have hDefEqSemantic :
                                  PsKernelDefEqJudgment
                                    checkedSession.context.environment
                                    checkedSession.context.localContext
                                    inferredType
                                    value.base.type :=
                                psKernelSessionIsDefEq_refines_defeq_core
                                  fuel
                                  checkedSession
                                  finalSession
                                  inferredType
                                  value.base.type
                                  hDefEqSound
                                  hDefEq
                              unfold PsKernelDefinitionBodyValid
                              refine ⟨
                                hFlags.1,
                                hFlags.2,
                                hLevelNone,
                                inferredType,
                                hTyping,
                                ?_
                              ⟩
                              simpa [hCheckedContext] using
                                hDefEqSemantic
