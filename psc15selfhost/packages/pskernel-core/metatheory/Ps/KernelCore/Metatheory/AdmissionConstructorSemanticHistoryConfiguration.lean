import Ps.KernelCore.Metatheory.AdmissionConstructorHistoryConfiguration
import Ps.KernelCore.Metatheory.AdmissionInductiveNamesConfiguration
import Ps.KernelCore.Metatheory.AdmissionHeaderSpineConfiguration
import Ps.KernelCore.Metatheory.EnvironmentSemanticTransport

/--
Independent ordinary constructor publication history. Each constructor has
checked closed header typing, fresh canonical provenance, and the independently
validated parameter/field/positivity/recursive-metadata/result shape in its
actual progressive work environment. This is separate from recursor generation
and full inductive well-formedness. Comparator reflexivity remains conditional.
-/
inductive PsKernelCheckedOrdinaryConstructorHistory
    (decl : PsKernelSimpleInductiveDecl)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (numIndices : Nat) (resultLevel : PsKernelLevel)
    (headerLocal : PsKernelLocalContext) :
    PsKernelEnvironment -> Nat -> List PsKernelSimpleConstructorDecl ->
    List PsKernelSimpleConstructorShape -> PsKernelEnvironment -> Prop where
  | done (work : PsKernelEnvironment) (index : Nat) :
      PsKernelCheckedOrdinaryConstructorHistory decl levels params numIndices
        resultLevel headerLocal work index [] [] work
  | step (work : PsKernelEnvironment) (index : Nat)
      (ctor : PsKernelSimpleConstructorDecl) (rest : List PsKernelSimpleConstructorDecl)
      (tailShapes : List PsKernelSimpleConstructorShape) (finalEnvironment : PsKernelEnvironment)
      (inferredType : PsKernelExpr) (level : PsKernelLevel)
      (fields : List PsKernelOpenBinder) (recursiveFields : List PsKernelSimpleRecursiveField)
      (indices : List PsKernelExpr)
      (hFresh : psKernelFindConstantInList ctor.name work.constants = none)
      (hTyped : PsKernelTypingJudgment work psKernelLocalContextEmpty ctor.type inferredType)
      (hSort : PsKernelReductionClosure work psKernelLocalContextEmpty inferredType
        (PsKernelExpr.sort level))
      (hOpen : PsKernelOrdinaryConstructorOpenShapeValid work headerLocal decl.name
        levels params numIndices resultLevel ctor.type fields recursiveFields indices)
      (hTail : PsKernelCheckedOrdinaryConstructorHistory decl levels params numIndices
        resultLevel headerLocal
        (psKernelEnvironmentAddUnchecked work (PsKernelConstantInfo.ctorInfo
          (PsKernelConstructorInfo.mk (PsKernelConstantBase.mk ctor.name decl.levelParams ctor.type)
            decl.name index decl.numParams (psKernelOpenBinderListLength fields) decl.isUnsafe)))
        (Nat.succ index) rest tailShapes finalEnvironment) :
      PsKernelCheckedOrdinaryConstructorHistory decl levels params numIndices
        resultLevel headerLocal work index (ctor :: rest)
        (PsKernelSimpleConstructorShape.mk ctor fields recursiveFields indices :: tailShapes)
        finalEnvironment

theorem psKernelAddSimpleConstructorsWithFuel_checked_semantic_history
    (fuel : Nat) :
    ∀ (decl : PsKernelSimpleInductiveDecl)
      (safety : PsKernelDefinitionSafety)
      (resultLevel : PsKernelLevel)
      (levels : List PsKernelLevel)
      (params : List PsKernelOpenBinder)
      (numIndices : Nat)
      (headerSession : PsKernelCheckerSession)
      (work : PsKernelEnvironment)
      (index : Nat)
      (ctors : List PsKernelSimpleConstructorDecl)
      (result : PsKernelAddConstructorsResult),
      PsKernelEnvironmentIndexRefines work ->
      PsKernelCheckerConfigurationSound headerSession.context headerSession.state ->
      PsKernelEnvironmentSemanticExtends headerSession.context.environment work ->
      PsKernelInductiveNamesAbsent work (psKernelSimpleCtorNames ctors) ->
      psKernelNameHasDuplicates (psKernelSimpleCtorNames ctors) = false ->
      PsKernelStringEqReflexiveLaw ->
      PsKernelNativeReductionSoundLaw ->
      PsKernelStringEqSoundLaw ->
      psKernelAddSimpleConstructorsWithFuel
          fuel decl safety resultLevel levels params numIndices
          headerSession work index ctors =
        Except.ok result ->
      PsKernelCheckedOrdinaryConstructorHistory decl levels params numIndices
        resultLevel headerSession.context.localContext work index ctors
        result.shapes result.environment ∧
      PsKernelEnvironmentSemanticExtends work result.environment ∧
      PsKernelEnvironmentIndexRefines result.environment := by
  induction fuel with
  | zero =>
      intro decl safety resultLevel levels params numIndices
        headerSession work index ctors result hIndex hHeaderConfig hEnvExt hNames hUnique hReflexive hNative hString hRun
      simp [psKernelAddSimpleConstructorsWithFuel] at hRun
  | succ remaining ih =>
      intro decl safety resultLevel levels params numIndices
        headerSession work index ctors result hIndex hHeaderConfig hEnvExt hNames hUnique hReflexive hNative hString hRun
      cases ctors with
      | nil =>
          simp [psKernelAddSimpleConstructorsWithFuel] at hRun
          cases hRun
          exact ⟨PsKernelCheckedOrdinaryConstructorHistory.done work index,
            PsKernelEnvironmentSemanticExtends.refl work, hIndex⟩
      | cons ctor rest =>
          obtain ⟨inferredType, level, hTyped, hSort⟩ :=
            psKernelAddSimpleConstructorsWithFuel_success_head_checked
              remaining decl safety resultLevel levels params numIndices
              headerSession work index ctor rest result
              hIndex hNative hString hRun
          have hNamesCons : PsKernelInductiveNamesAbsent work
              (ctor.name :: psKernelSimpleCtorNames rest) := by
            simpa [psKernelSimpleCtorNames] using hNames
          have hFresh : psKernelFindConstantInList ctor.name work.constants = none ∧
              PsKernelInductiveNamesAbsent work (psKernelSimpleCtorNames rest) := by
            cases hNamesCons with
            | cons _ _ hHead hTail => exact ⟨hHead, hTail⟩
          have hUniqueTail := psKernelNameHasDuplicates_cons_false_refines
            ctor.name (psKernelSimpleCtorNames rest)
            (by simpa [psKernelSimpleCtorNames] using hUnique)
          have hCtorConfig := psKernelSessionWithEnvironment_configuration_preserves
            headerSession work hIndex hEnvExt hHeaderConfig
          simp only [psKernelAddSimpleConstructorsWithFuel] at hRun
          cases hClosed :
              psKernelCheckNoMVarNoFVar ctor.type with
          | error error =>
              simp only [hClosed] at hRun
              cases hRun
          | ok closed =>
              simp only [hClosed] at hRun
              cases hLevels :
                  psKernelCheckLevelParams
                    ctor.type decl.levelParams with
              | error error =>
                  simp only [hLevels] at hRun
                  cases hRun
              | ok checkedLevels =>
                  simp only [hLevels] at hRun
                  cases hType :
                      psKernelSessionCheck
                        remaining
                        (psKernelMkCheckerSession
                          work decl.levelParams safety
                          headerSession.context.maxRecDepth
                          headerSession.context.maxNatSize)
                        ctor.type with
                  | error error =>
                      simp only [hType] at hRun
                      cases hRun
                  | ok ctorType =>
                      simp only [hType] at hRun
                      cases hSortRun :
                          psKernelSessionEnsureSort
                            remaining
                            (Prod.snd ctorType)
                            (Prod.fst ctorType) with
                      | error error =>
                          simp only [hSortRun] at hRun
                          cases hRun
                      | ok sorted =>
                          simp only [hSortRun] at hRun
                          cases hParams :
                              psKernelOpenSimpleConstructorParams
                                remaining
                                (psKernelSessionWithEnvironment
                                  headerSession work)
                                params ctor.type with
                          | error error =>
                              simp only [hParams] at hRun
                              cases hRun
                          | ok afterParams =>
                              simp only [hParams] at hRun
                              cases hFields :
                                  psKernelOpenSimpleConstructorFields
                                    remaining
                                    afterParams.session
                                    decl.name levels params numIndices
                                    resultLevel afterParams.result with
                              | error error =>
                                  simp only [hFields] at hRun
                                  cases hRun
                              | ok fieldsResult =>
                                  simp only [hFields] at hRun
                                  cases hResult :
                                      psKernelValidateSimpleConstructorResult
                                        decl.name levels params numIndices
                                        fieldsResult.result with
                                  | error error =>
                                      simp only [hResult] at hRun
                                      cases hRun
                                  | ok resultIndices =>
                                      simp only [hResult] at hRun
                                      have hShape := psKernelOpenSimpleConstructor_shape_refines
                                        remaining hNative hString hReflexive
                                        (psKernelSessionWithEnvironment headerSession work)
                                        decl.name levels params numIndices resultLevel ctor.type
                                        afterParams fieldsResult resultIndices
                                        hCtorConfig hParams hFields hResult
                                      have hOpen : PsKernelOrdinaryConstructorOpenShapeValid
                                          work headerSession.context.localContext decl.name levels
                                          params numIndices resultLevel ctor.type fieldsResult.fields
                                          fieldsResult.recursiveFields resultIndices := by
                                        simpa [psKernelSessionWithEnvironment,
                                          psKernelCheckerContextWithEnvironment] using hShape.1
                                      let ctorInfo :=
                                        PsKernelConstructorInfo.mk
                                          (PsKernelConstantBase.mk
                                            ctor.name decl.levelParams ctor.type)
                                          decl.name index decl.numParams
                                          (psKernelOpenBinderListLength
                                            fieldsResult.fields)
                                          decl.isUnsafe
                                      let nextWork :=
                                        psKernelEnvironmentAddUnchecked
                                          work
                                          (PsKernelConstantInfo.ctorInfo ctorInfo)
                                      have hNextIndex :
                                          PsKernelEnvironmentIndexRefines nextWork :=
                                        psKernelEnvironmentAddUnchecked_index_refines
                                          work
                                          (PsKernelConstantInfo.ctorInfo ctorInfo)
                                          hIndex
                                      have hStepExt : PsKernelEnvironmentSemanticExtends work nextWork :=
                                        psKernelEnvironmentAddUnchecked_fresh_semantic_extends
                                          work (PsKernelConstantInfo.ctorInfo ctorInfo) hString
                                          (by simpa [ctorInfo, psKernelConstantInfoName, psKernelConstantInfoBase] using hFresh.1)
                                      have hNextNames : PsKernelInductiveNamesAbsent nextWork
                                          (psKernelSimpleCtorNames rest) :=
                                        psKernelInductiveNamesAbsent_add_disjoint
                                          work (PsKernelConstantInfo.ctorInfo ctorInfo)
                                          (psKernelSimpleCtorNames rest) hFresh.2
                                          (by simpa [ctorInfo, psKernelConstantInfoName, psKernelConstantInfoBase] using hUniqueTail.1)
                                      cases hTail :
                                          psKernelAddSimpleConstructorsWithFuel
                                            remaining decl safety resultLevel
                                            levels params numIndices headerSession
                                            nextWork (Nat.succ index) rest with
                                      | error error =>
                                          simp only [nextWork, ctorInfo] at hTail
                                          simp only [hTail] at hRun
                                          cases hRun
                                      | ok tailResult =>
                                          simp only [nextWork, ctorInfo] at hTail
                                          simp only [hTail] at hRun
                                          obtain ⟨hRest, hTailExt, hFinalIndex⟩ :=
                                            ih decl safety resultLevel levels params numIndices
                                              headerSession nextWork (Nat.succ index) rest tailResult
                                              hNextIndex hHeaderConfig
                                              (PsKernelEnvironmentSemanticExtends.trans
                                                headerSession.context.environment work nextWork hEnvExt hStepExt)
                                              hNextNames hUniqueTail.2 hReflexive hNative hString hTail
                                          cases hRun
                                          exact ⟨PsKernelCheckedOrdinaryConstructorHistory.step
                                            work index ctor rest tailResult.shapes tailResult.environment
                                            inferredType level fieldsResult.fields fieldsResult.recursiveFields
                                            resultIndices hFresh.1 hTyped hSort hOpen hRest,
                                            PsKernelEnvironmentSemanticExtends.trans
                                              work nextWork tailResult.environment hStepExt hTailExt,
                                            hFinalIndex⟩

/-- Exact provisional metadata used by ordinary admission, kept in metatheory. -/
def psKernelOrdinaryInitialInductiveInfo
    (decl : PsKernelSimpleInductiveDecl)
    (indices : List PsKernelOpenBinder) : PsKernelInductiveInfo :=
  PsKernelInductiveInfo.mk
    (PsKernelConstantBase.mk decl.name decl.levelParams decl.type)
    decl.numParams (psKernelOpenBinderListLength indices)
    [decl.name] (psKernelSimpleCtorNames decl.ctors) 0 false false decl.isUnsafe

/--
Compose the actual checked header-opening and constructor pipeline. Naming
premises are the already established top-level guards, not independent
per-constructor freshness or per-work-environment cache assumptions.
This certificate ends before final metadata and recursor publication.
-/
theorem psKernelOrdinaryHeaderConstructorPipeline_configuration_refines
    (fuel : Nat) (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw)
    (decl : PsKernelSimpleInductiveDecl)
    (safety : PsKernelDefinitionSafety)
    (sortedHeader : PsKernelCheckerSession)
    (paramResult indexResult : PsKernelOpenBindersResult)
    (resultLevel : PsKernelLevel)
    (ctorResult : PsKernelAddConstructorsResult)
    (hConfig : PsKernelCheckerConfigurationSound sortedHeader.context sortedHeader.state)
    (hNames : PsKernelInductiveNamesAbsent sortedHeader.context.environment
      (decl.name :: psKernelSimpleRecName decl.name :: psKernelSimpleCtorNames decl.ctors))
    (hUnique : psKernelNameHasDuplicates
      (decl.name :: psKernelSimpleRecName decl.name :: psKernelSimpleCtorNames decl.ctors) = false)
    (hParams : psKernelOpenSimpleHeaderParams fuel sortedHeader decl.type decl.numParams =
      Except.ok paramResult)
    (hIndices : psKernelOpenSimpleHeaderIndices fuel paramResult.session paramResult.result =
      Except.ok indexResult)
    (hResult : indexResult.result = PsKernelExpr.sort resultLevel)
    (hCtors : psKernelAddSimpleConstructorsWithFuel (Nat.succ fuel) decl safety
      resultLevel (psKernelLevelParamsToLevels decl.levelParams) paramResult.binders
      (psKernelOpenBinderListLength indexResult.binders) paramResult.session
      (psKernelEnvironmentAddUnchecked sortedHeader.context.environment
        (PsKernelConstantInfo.inductInfo
          (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)))
      0 decl.ctors = Except.ok ctorResult) :
    PsKernelCheckedHeaderBinderSpine sortedHeader.context.environment
      sortedHeader.context.localContext decl.type paramResult.binders
      paramResult.session.context.localContext paramResult.result ∧
    PsKernelCheckedHeaderBinderSpine sortedHeader.context.environment
      paramResult.session.context.localContext paramResult.result indexResult.binders
      indexResult.session.context.localContext (PsKernelExpr.sort resultLevel) ∧
    PsKernelCheckedOrdinaryConstructorHistory decl
      (psKernelLevelParamsToLevels decl.levelParams) paramResult.binders
      (psKernelOpenBinderListLength indexResult.binders) resultLevel
      paramResult.session.context.localContext
      (psKernelEnvironmentAddUnchecked sortedHeader.context.environment
        (PsKernelConstantInfo.inductInfo
          (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)))
      0 decl.ctors ctorResult.shapes ctorResult.environment ∧
    PsKernelEnvironmentSemanticExtends sortedHeader.context.environment ctorResult.environment ∧
    PsKernelEnvironmentIndexRefines ctorResult.environment := by
  have hParamSound := psKernelOpenSimpleHeaderParams_configuration_refines
    fuel decl.numParams hNative hString sortedHeader decl.type paramResult hConfig hParams
  have hIndexSound := psKernelOpenSimpleHeaderIndices_configuration_refines
    fuel hNative hString paramResult.session paramResult.result indexResult
    hParamSound.1 hIndices
  have hFresh : psKernelFindConstantInList decl.name
      sortedHeader.context.environment.constants = none ∧
      PsKernelInductiveNamesAbsent sortedHeader.context.environment
        (psKernelSimpleCtorNames decl.ctors) := by
    cases hNames with
    | cons _ _ hHead hTail =>
        cases hTail with
        | cons _ _ _ hCtorsAbsent => exact ⟨hHead, hCtorsAbsent⟩
  have hUniqueTail := psKernelNameHasDuplicates_cons_false_refines decl.name
    (psKernelSimpleRecName decl.name :: psKernelSimpleCtorNames decl.ctors) hUnique
  have hCtorUnique := psKernelNameHasDuplicates_cons_false_refines
    (psKernelSimpleRecName decl.name) (psKernelSimpleCtorNames decl.ctors) hUniqueTail.2
  have hDisjoint : psKernelNameListContains decl.name
      (psKernelSimpleCtorNames decl.ctors) = false := by
    cases hEqual : psKernelNameEq decl.name (psKernelSimpleRecName decl.name) with
    | true => simp [psKernelNameListContains, hEqual] at hUniqueTail
    | false => simpa [psKernelNameListContains, hEqual] using hUniqueTail.1
  let initial := PsKernelConstantInfo.inductInfo
    (psKernelOrdinaryInitialInductiveInfo decl indexResult.binders)
  let work := psKernelEnvironmentAddUnchecked sortedHeader.context.environment initial
  have hInitialName : psKernelConstantInfoName initial = decl.name := rfl
  have hWorkIndex : PsKernelEnvironmentIndexRefines work :=
    psKernelEnvironmentAddUnchecked_index_refines
      sortedHeader.context.environment initial hConfig.1
  have hWorkExt : PsKernelEnvironmentSemanticExtends
      sortedHeader.context.environment work :=
    psKernelEnvironmentAddUnchecked_fresh_semantic_extends
      sortedHeader.context.environment initial hString
      (by simpa [hInitialName] using hFresh.1)
  have hWorkNames : PsKernelInductiveNamesAbsent work
      (psKernelSimpleCtorNames decl.ctors) :=
    psKernelInductiveNamesAbsent_add_disjoint
      sortedHeader.context.environment initial (psKernelSimpleCtorNames decl.ctors)
      hFresh.2 (by simpa [hInitialName] using hDisjoint)
  have hParamExt : PsKernelEnvironmentSemanticExtends
      paramResult.session.context.environment work := by
    simpa [hParamSound.2.1] using hWorkExt
  obtain ⟨hHistory, hCtorExt, hFinalIndex⟩ :=
    psKernelAddSimpleConstructorsWithFuel_checked_semantic_history
      (Nat.succ fuel) decl safety resultLevel
      (psKernelLevelParamsToLevels decl.levelParams) paramResult.binders
      (psKernelOpenBinderListLength indexResult.binders) paramResult.session work
      0 decl.ctors ctorResult hWorkIndex hParamSound.1 hParamExt
      hWorkNames hCtorUnique.2 hReflexive hNative hString hCtors
  refine ⟨hParamSound.2.2, ?_, hHistory, ?_, hFinalIndex⟩
  · simpa [hParamSound.2.1, hResult] using hIndexSound.2.2
  · exact PsKernelEnvironmentSemanticExtends.trans
      sortedHeader.context.environment work ctorResult.environment hWorkExt hCtorExt

/--
Constructor publication cannot consume a reserved disjoint name. The proof
uses the independent publication history, not an empirical environment check.
Comparator reflexivity remains an explicit premise for negative membership.
-/
theorem PsKernelCheckedOrdinaryConstructorHistory.preserves_reserved_name
    (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw)
    {decl : PsKernelSimpleInductiveDecl} {levels : List PsKernelLevel}
    {params : List PsKernelOpenBinder} {numIndices : Nat}
    {resultLevel : PsKernelLevel} {headerLocal : PsKernelLocalContext}
    {work finalEnvironment : PsKernelEnvironment} {index : Nat}
    {ctors : List PsKernelSimpleConstructorDecl}
    {shapes : List PsKernelSimpleConstructorShape}
    (hHistory : PsKernelCheckedOrdinaryConstructorHistory decl levels params
      numIndices resultLevel headerLocal work index ctors shapes finalEnvironment) :
    ∀ reserved : PsKernelName,
      psKernelFindConstantInList reserved work.constants = none ->
      psKernelNameListContains reserved (psKernelSimpleCtorNames ctors) = false ->
      psKernelFindConstantInList reserved finalEnvironment.constants = none := by
  induction hHistory with
  | done work index =>
      intro reserved hAbsent hGuard
      exact hAbsent
  | step work index ctor rest tailShapes finalEnvironment inferredType level
      fields recursiveFields indices hFresh hTyped hSort hOpen hTail ih =>
      intro reserved hAbsent hGuard
      have hNamesGuard : psKernelNameListContains reserved
          (ctor.name :: psKernelSimpleCtorNames rest) = false := by
        simpa [psKernelSimpleCtorNames] using hGuard
      have hDifferent := psKernelNameListContains_false_excludes_equal
        hReflexive reserved (ctor.name :: psKernelSimpleCtorNames rest)
        hNamesGuard ctor.name (List.Mem.head _)
      have hInsertEqual : psKernelNameEq ctor.name reserved = false := by
        cases hEq : psKernelNameEq ctor.name reserved with
        | false => rfl
        | true =>
            exact False.elim (hDifferent
              (psKernelNameEq_sound_of_string_law hString ctor.name reserved hEq))
      have hTailGuard : psKernelNameListContains reserved
          (psKernelSimpleCtorNames rest) = false := by
        cases hEq : psKernelNameEq reserved ctor.name with
        | true => simp [psKernelNameListContains, hEq] at hNamesGuard
        | false => simpa [psKernelNameListContains, hEq] using hNamesGuard
      apply ih reserved _ hTailGuard
      simpa [psKernelEnvironmentAddUnchecked, psKernelFindConstantInList,
        psKernelConstantInfoName, psKernelConstantInfoBase, hInsertEqual] using hAbsent

theorem PsKernelCheckedOrdinaryConstructorHistory.shape_provenance
    {decl : PsKernelSimpleInductiveDecl} {levels : List PsKernelLevel}
    {params : List PsKernelOpenBinder} {numIndices : Nat}
    {resultLevel : PsKernelLevel} {headerLocal : PsKernelLocalContext}
    {work finalEnvironment : PsKernelEnvironment} {index : Nat}
    {ctors : List PsKernelSimpleConstructorDecl}
    {shapes : List PsKernelSimpleConstructorShape}
    (hHistory : PsKernelCheckedOrdinaryConstructorHistory decl levels params
      numIndices resultLevel headerLocal work index ctors shapes finalEnvironment) :
    shapes.map PsKernelSimpleConstructorShape.ctor = ctors := by
  induction hHistory with
  | done => rfl
  | step work index ctor rest tailShapes finalEnvironment inferredType level
      fields recursiveFields indices hFresh hTyped hSort hOpen hTail ih =>
      simpa using congrArg (List.cons _) ih
