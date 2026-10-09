import Ps.KernelCore.Metatheory.AdmissionRecursorSemanticConfiguration
import Ps.KernelCore.Metatheory.CheckerInitialConfiguration
import Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops

/--
Independent typing of exactly the rules belonging to one mutual owner.
Other owners consume no rule. Motive selection is explicit; the judgment has
no checker fuel, successful-check equation, or infer-only typing premise.
-/
inductive PsKernelMutualRecursorRulesTyped
    (environment : PsKernelEnvironment) (localContext : PsKernelLocalContext)
    (levels : List PsKernelLevel) (params motives ruleBinders : List PsKernelOpenBinder)
    (owner : Nat) :
    List PsKernelSimpleMutualConstructorShape -> List PsKernelRecursorRule -> Prop where
  | nil : PsKernelMutualRecursorRulesTyped environment localContext levels params
      motives ruleBinders owner [] []
  | skip (shape : PsKernelSimpleMutualConstructorShape)
      (rest : List PsKernelSimpleMutualConstructorShape) (rules : List PsKernelRecursorRule)
      (hOther : shape.owner ≠ owner)
      (hTail : PsKernelMutualRecursorRulesTyped environment localContext levels params
        motives ruleBinders owner rest rules) :
      PsKernelMutualRecursorRulesTyped environment localContext levels params
        motives ruleBinders owner (shape :: rest) rules
  | cons (shape : PsKernelSimpleMutualConstructorShape)
      (rest : List PsKernelSimpleMutualConstructorShape)
      (rule : PsKernelRecursorRule) (rules : List PsKernelRecursorRule)
      (motive : PsKernelOpenBinder) (hOwner : shape.owner = owner)
      (hMotive : psKernelMutualOpenBinderListGet motives owner = some motive)
      (hTyping : PsKernelTypingJudgment environment localContext rule.rhs
        (psKernelCloseOpenBinders (psKernelOpenBinderListAppend ruleBinders shape.fields)
          (psKernelSimpleMotiveApp (PsKernelExpr.fvar motive.internalName)
            shape.resultIndices (psKernelSimpleMutualCtorApp levels params shape))))
      (hTail : PsKernelMutualRecursorRulesTyped environment localContext levels params
        motives ruleBinders owner rest rules) :
      PsKernelMutualRecursorRulesTyped environment localContext levels params
        motives ruleBinders owner (shape :: rest) (rule :: rules)

theorem psKernelValidateSimpleMutualRulesWorker_independent_typing
    (shapes : List PsKernelSimpleMutualConstructorShape)
    (fuel : Nat) (session finalSession : PsKernelCheckerSession)
    (levels : List PsKernelLevel) (params motives minors ruleBinders : List PsKernelOpenBinder)
    (owner : Nat) (rules : List PsKernelRecursorRule)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state)
    (hNative : PsKernelNativeReductionSoundLaw) (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelValidateSimpleMutualRulesWorker shapes fuel session levels params
      motives minors ruleBinders owner rules = Except.ok finalSession) :
    PsKernelMutualRecursorRulesTyped session.context.environment session.context.localContext
      levels params motives ruleBinders owner shapes rules ∧
    finalSession.context = session.context ∧
    PsKernelCheckerConfigurationSound finalSession.context finalSession.state := by
  induction shapes generalizing session rules with
  | nil =>
      cases rules with
      | nil =>
          simp [psKernelValidateSimpleMutualRulesWorker] at hRun
          cases hRun
          exact ⟨PsKernelMutualRecursorRulesTyped.nil, rfl, hConfig⟩
      | cons rule rest => simp [psKernelValidateSimpleMutualRulesWorker] at hRun
  | cons shape rest ih =>
      cases hOwner : Nat.beq shape.owner owner with
      | false =>
          have hTailRun : psKernelValidateSimpleMutualRulesWorker rest fuel session levels
              params motives minors ruleBinders owner rules = Except.ok finalSession := by
            simpa [psKernelValidateSimpleMutualRulesWorker, hOwner] using hRun
          obtain ⟨hTail, hContext, hFinal⟩ := ih session rules hConfig hTailRun
          exact ⟨PsKernelMutualRecursorRulesTyped.skip shape rest rules
            (by simpa using hOwner) hTail, hContext, hFinal⟩
      | true =>
          cases rules with
          | nil => simp [psKernelValidateSimpleMutualRulesWorker, hOwner] at hRun
          | cons rule tail =>
              cases hCheck : psKernelSessionCheck fuel session rule.rhs with
              | error message =>
                  simp [psKernelValidateSimpleMutualRulesWorker, hOwner, hCheck] at hRun
              | ok checked =>
                  rcases checked with ⟨gotType, checkedSession⟩
                  cases hMotive : psKernelMutualOpenBinderListGet motives owner with
                  | none =>
                      simp [psKernelValidateSimpleMutualRulesWorker, hOwner, hCheck,
                        psKernelSimpleMutualMotiveApp, hMotive] at hRun
                  | some motive =>
                      let expectedType := psKernelCloseOpenBinders
                        (psKernelOpenBinderListAppend ruleBinders shape.fields)
                        (psKernelSimpleMotiveApp (PsKernelExpr.fvar motive.internalName)
                          shape.resultIndices (psKernelSimpleMutualCtorApp levels params shape))
                      cases hCompare : psKernelSessionIsDefEq fuel checkedSession gotType expectedType with
                      | error message =>
                          simp [psKernelValidateSimpleMutualRulesWorker, hOwner, hCheck,
                            psKernelSimpleMutualMotiveApp, hMotive, expectedType, hCompare] at hRun
                      | ok compared =>
                          rcases compared with ⟨equal, equalSession⟩
                          cases equal with
                          | false =>
                              simp [psKernelValidateSimpleMutualRulesWorker, hOwner, hCheck,
                                psKernelSimpleMutualMotiveApp, hMotive, expectedType, hCompare] at hRun
                          | true =>
                              have hTyped := psKernelSessionCheck_concrete_refines_typing
                                fuel hNative hString session checkedSession rule.rhs gotType hConfig hCheck
                              have hCheckedContext := psKernelSessionCheck_success_preserves_context_core
                                fuel session checkedSession rule.rhs gotType hCheck
                              have hCheckedConfig : PsKernelCheckerConfigurationSound
                                  checkedSession.context checkedSession.state := by
                                simpa [hCheckedContext] using hTyped.2
                              have hEqual := psKernelSessionIsDefEq_concrete_refines_defeq
                                fuel hNative hString checkedSession equalSession gotType expectedType
                                hCheckedConfig hCompare
                              have hEqualContext := psKernelSessionIsDefEq_success_preserves_context_core
                                fuel checkedSession equalSession gotType expectedType true hCompare
                              have hEqualConfig : PsKernelCheckerConfigurationSound
                                  equalSession.context equalSession.state := by
                                simpa [hEqualContext] using hEqual.2
                              have hTailRun : psKernelValidateSimpleMutualRulesWorker rest fuel equalSession
                                  levels params motives minors ruleBinders owner tail = Except.ok finalSession := by
                                simpa [psKernelValidateSimpleMutualRulesWorker, hOwner, hCheck,
                                  psKernelSimpleMutualMotiveApp, hMotive, expectedType, hCompare] using hRun
                              obtain ⟨hTail, hFinalContext, hFinalConfig⟩ :=
                                ih equalSession tail hEqualConfig hTailRun
                              refine ⟨PsKernelMutualRecursorRulesTyped.cons shape rest rule tail
                                motive (by simpa using hOwner) hMotive ?_ ?_, ?_, hFinalConfig⟩
                              · apply PsKernelTypingJudgment.convert rule.rhs gotType expectedType hTyped.1
                                simpa [hCheckedContext] using hEqual.1
                              · simpa [hEqualContext, hCheckedContext] using hTail
                              · exact hFinalContext.trans (hEqualContext.trans hCheckedContext)

theorem psKernelValidateSimpleMutualRules_independent_typing
    (fuel : Nat) (session finalSession : PsKernelCheckerSession)
    (levels : List PsKernelLevel) (params motives minors ruleBinders : List PsKernelOpenBinder)
    (owner : Nat) (shapes : List PsKernelSimpleMutualConstructorShape)
    (rules : List PsKernelRecursorRule)
    (hConfig : PsKernelCheckerConfigurationSound session.context session.state)
    (hNative : PsKernelNativeReductionSoundLaw) (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelValidateSimpleMutualRules fuel session levels params motives minors
      ruleBinders owner shapes rules = Except.ok finalSession) :
    PsKernelMutualRecursorRulesTyped session.context.environment session.context.localContext
      levels params motives ruleBinders owner shapes rules ∧
    finalSession.context = session.context ∧
    PsKernelCheckerConfigurationSound finalSession.context finalSession.state :=
  psKernelValidateSimpleMutualRulesWorker_independent_typing shapes fuel session finalSession
    levels params motives minors ruleBinders owner rules hConfig hNative hString hRun

/-- Every recursor in publication order has a Sort-typed header and typed owner rules. -/
inductive PsKernelMutualRecursorInfosTyped
    (environment : PsKernelEnvironment) (levels : List PsKernelLevel)
    (params motives ruleBinders : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    Nat -> List PsKernelRecursorInfo -> Prop where
  | nil (owner : Nat) :
      PsKernelMutualRecursorInfosTyped environment levels params motives ruleBinders shapes owner []
  | cons (owner : Nat) (info : PsKernelRecursorInfo) (rest : List PsKernelRecursorInfo)
      (level : PsKernelLevel)
      (hHeader : PsKernelTypingJudgment environment psKernelLocalContextEmpty
        info.base.type (PsKernelExpr.sort level))
      (hRules : PsKernelMutualRecursorRulesTyped environment psKernelLocalContextEmpty
        levels params motives ruleBinders owner shapes info.rules)
      (hTail : PsKernelMutualRecursorInfosTyped environment levels params motives
        ruleBinders shapes (Nat.succ owner) rest) :
      PsKernelMutualRecursorInfosTyped environment levels params motives ruleBinders shapes
        owner (info :: rest)

theorem psKernelValidateMutualRecursorInfosWorker_independent_typing
    (infos : List PsKernelRecursorInfo)
    (fuel : Nat) (environment : PsKernelEnvironment) (recLevelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (maxRecDepth maxNatSize : Nat)
    (levels : List PsKernelLevel) (params motives minors ruleBinders : List PsKernelOpenBinder)
    (shapes : List PsKernelSimpleMutualConstructorShape) (owner : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw) (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelValidateMutualRecursorInfosWorker infos fuel environment recLevelParams safety
      maxRecDepth maxNatSize levels params motives minors ruleBinders shapes owner = Except.ok ()) :
    PsKernelMutualRecursorInfosTyped environment levels params motives ruleBinders shapes owner infos := by
  induction infos generalizing owner with
  | nil => exact PsKernelMutualRecursorInfosTyped.nil owner
  | cons info rest ih =>
      let session := psKernelMkCheckerSession environment recLevelParams safety maxRecDepth maxNatSize
      have hConfig := psKernelMkCheckerSession_configuration_sound environment recLevelParams
        safety maxRecDepth maxNatSize hIndex
      simp only [psKernelValidateMutualRecursorInfosWorker] at hRun
      cases hCheck : psKernelSessionCheck fuel session info.base.type with
      | error message =>
          simp only [session] at hCheck
          simp only [hCheck] at hRun
          cases hRun
      | ok checked =>
          have hTyped := psKernelSessionCheck_concrete_refines_typing fuel hNative hString
            session checked.2 info.base.type checked.1 hConfig hCheck
          have hContext := psKernelSessionCheck_success_preserves_context_core
            fuel session checked.2 info.base.type checked.1 hCheck
          have hCheckedConfig : PsKernelCheckerConfigurationSound checked.2.context checked.2.state := by
            simpa [hContext] using hTyped.2
          simp only [session] at hCheck
          simp only [hCheck] at hRun
          cases hSort : psKernelSessionEnsureSort fuel checked.2 checked.1 with
          | error message => simp only [hSort] at hRun; cases hRun
          | ok sorted =>
              have hReduced := psKernelSessionEnsureSort_concrete_refines_reduction
                fuel hNative hString checked.2 sorted.2 checked.1 sorted.1 hCheckedConfig hSort
              have hSortContext := psKernelSessionEnsureSort_success_preserves_context_core
                fuel checked.2 sorted.2 checked.1 sorted.1 hSort
              have hSortedConfig : PsKernelCheckerConfigurationSound sorted.2.context sorted.2.state := by
                simpa [hSortContext] using hReduced.2
              simp only [hSort] at hRun
              cases hRules : psKernelValidateSimpleMutualRules fuel sorted.2 levels params
                  motives minors ruleBinders owner shapes info.rules with
              | error message => simp only [hRules] at hRun; cases hRun
              | ok finalSession =>
                  simp only [hRules] at hRun
                  have hRuleTyped := psKernelValidateSimpleMutualRules_independent_typing
                    fuel sorted.2 finalSession levels params motives minors ruleBinders owner shapes
                    info.rules hSortedConfig hNative hString hRules
                  refine PsKernelMutualRecursorInfosTyped.cons owner info rest sorted.1 ?_ ?_
                    (ih (Nat.succ owner) hRun)
                  · apply PsKernelTypingJudgment.convert info.base.type checked.1 (PsKernelExpr.sort sorted.1)
                    · simpa [session, psKernelMkCheckerSession, psKernelCheckerContextEmpty] using hTyped.1
                    · apply PsKernelDefEqJudgment.reductionClosure
                      simpa [hContext, session, psKernelMkCheckerSession,
                        psKernelCheckerContextEmpty] using hReduced.1
                  · simpa [hSortContext, hContext, session, psKernelMkCheckerSession,
                      psKernelCheckerContextEmpty] using hRuleTyped.1
