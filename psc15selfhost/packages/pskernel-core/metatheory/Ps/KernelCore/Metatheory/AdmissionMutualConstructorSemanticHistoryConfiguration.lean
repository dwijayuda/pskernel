import Ps.KernelCore.Metatheory.AdmissionConstructorSemanticHistoryConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualConstructorConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualFieldConfiguration

/--
Independent mutual constructor history in progressive work environments.
The owner ordinal is checked against the actual family header shape.
-/
inductive PsKernelCheckedMutualConstructorHistory
    (targets : List PsKernelName) (typeShapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel) (typeShape : PsKernelSimpleMutualTypeShape)
    (owner : Nat) (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (headerLocal : PsKernelLocalContext) :
    PsKernelEnvironment -> Nat -> List PsKernelSimpleConstructorDecl ->
    List PsKernelSimpleMutualConstructorShape -> PsKernelEnvironment -> Prop where
  | done (work : PsKernelEnvironment) (index : Nat) :
      PsKernelCheckedMutualConstructorHistory targets typeShapes levels params resultLevel
        typeShape owner levelParams safety headerLocal work index [] [] work
  | step (work : PsKernelEnvironment) (index : Nat)
      (ctor : PsKernelSimpleConstructorDecl) (rest : List PsKernelSimpleConstructorDecl)
      (tailShapes : List PsKernelSimpleMutualConstructorShape)
      (finalEnvironment : PsKernelEnvironment)
      (inferredType : PsKernelExpr) (level : PsKernelLevel)
      (fields : List PsKernelOpenBinder)
      (recursiveFields : List PsKernelSimpleMutualRecursiveField)
      (indices : List PsKernelExpr)
      (hFresh : psKernelFindConstantInList ctor.name work.constants = none)
      (hTyped : PsKernelTypingJudgment work psKernelLocalContextEmpty ctor.type inferredType)
      (hSort : PsKernelReductionClosure work psKernelLocalContextEmpty inferredType (PsKernelExpr.sort level))
      (hOpen : PsKernelMutualConstructorOpenShapeValid work headerLocal targets typeShapes levels
        params resultLevel typeShape ctor.type fields recursiveFields indices)
      (hTail : PsKernelCheckedMutualConstructorHistory targets typeShapes levels params resultLevel
        typeShape owner levelParams safety headerLocal
        (psKernelEnvironmentAddUnchecked work (PsKernelConstantInfo.ctorInfo
          (PsKernelConstructorInfo.mk (PsKernelConstantBase.mk ctor.name levelParams ctor.type)
            typeShape.decl.name index (psKernelOpenBinderListLength params)
            (psKernelOpenBinderListLength fields) (psKernelDefinitionSafetyIsUnsafe safety))))
        (Nat.succ index) rest tailShapes finalEnvironment) :
      PsKernelCheckedMutualConstructorHistory targets typeShapes levels params resultLevel
        typeShape owner levelParams safety headerLocal work index (ctor :: rest)
        (PsKernelSimpleMutualConstructorShape.mk owner ctor fields recursiveFields indices :: tailShapes)
        finalEnvironment

theorem psKernelAddSimpleMutualConstructorsForTypeWorker_semantic_history
    (ctors : List PsKernelSimpleConstructorDecl) :
    ∀ (fuel : Nat)
      (safety : PsKernelDefinitionSafety)
      (resultLevel : PsKernelLevel)
      (levels : List PsKernelLevel)
      (params : List PsKernelOpenBinder)
      (typeNames : List PsKernelName)
      (typeShapes : List PsKernelSimpleMutualTypeShape)
      (typeShape : PsKernelSimpleMutualTypeShape)
      (owner : Nat)
      (headerSession : PsKernelCheckerSession)
      (work : PsKernelEnvironment)
      (ctorIndex : Nat)
      (result : PsKernelAddMutualConstructorsResult),
      PsKernelEnvironmentIndexRefines work ->
      PsKernelCheckerConfigurationSound headerSession.context headerSession.state ->
      PsKernelEnvironmentSemanticExtends headerSession.context.environment work ->
      PsKernelInductiveNamesAbsent work (psKernelSimpleCtorNames ctors) ->
      psKernelNameHasDuplicates (psKernelSimpleCtorNames ctors) = false ->
      psKernelMutualTypeShapeListGet typeShapes owner = some typeShape ->
      PsKernelStringEqReflexiveLaw ->
      PsKernelNativeReductionSoundLaw ->
      PsKernelStringEqSoundLaw ->
      psKernelAddSimpleMutualConstructorsForTypeWorker
          ctors fuel safety resultLevel levels params
          typeNames typeShapes typeShape owner
          headerSession work ctorIndex =
        Except.ok result ->
      PsKernelCheckedMutualConstructorHistory typeNames typeShapes levels params
        resultLevel typeShape owner headerSession.context.levelParams safety
        headerSession.context.localContext work ctorIndex ctors result.shapes result.environment ∧
      PsKernelEnvironmentSemanticExtends work result.environment ∧
      PsKernelEnvironmentIndexRefines result.environment := by
  induction ctors with
  | nil =>
      intro fuel safety resultLevel levels params typeNames
        typeShapes typeShape owner headerSession work ctorIndex
        result hIndex hHeaderConfig hEnvExt hNames hUnique hOwnerShape hReflexive hNative hString hRun
      simp [psKernelAddSimpleMutualConstructorsForTypeWorker] at hRun
      cases hRun
      exact ⟨PsKernelCheckedMutualConstructorHistory.done work ctorIndex,
        PsKernelEnvironmentSemanticExtends.refl work, hIndex⟩
  | cons ctor rest ih =>
      intro fuel safety resultLevel levels params typeNames
        typeShapes typeShape owner headerSession work ctorIndex
        result hIndex hHeaderConfig hEnvExt hNames hUnique hOwnerShape hReflexive hNative hString hRun
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
      simp only [psKernelAddSimpleMutualConstructorsForTypeWorker] at hRun
      cases hClosed :
          psKernelCheckNoMVarNoFVar ctor.type with
      | error error =>
          simp only [hClosed] at hRun
          cases hRun
      | ok closed =>
          simp only [hClosed] at hRun
          cases hLevels :
              psKernelCheckLevelParams
                ctor.type headerSession.context.levelParams with
          | error error =>
              simp only [hLevels] at hRun
              cases hRun
          | ok levelsChecked =>
              simp only [hLevels] at hRun
              cases hType :
                  psKernelSessionCheck
                    fuel
                    (psKernelMkCheckerSession
                      work
                      headerSession.context.levelParams
                      safety
                      headerSession.context.maxRecDepth
                      headerSession.context.maxNatSize)
                    ctor.type with
              | error error =>
                  simp only [hType] at hRun
                  cases hRun
              | ok ctorType =>
                  simp only [hType] at hRun
                  cases hSort :
                      psKernelSessionEnsureSort
                        fuel (Prod.snd ctorType) (Prod.fst ctorType) with
                  | error error =>
                      simp only [hSort] at hRun
                      cases hRun
                  | ok sortResult =>
                      simp only [hSort] at hRun
                      cases hParams :
                          psKernelOpenSimpleConstructorParams
                            fuel
                            (psKernelSessionWithEnvironment
                              headerSession work)
                            params ctor.type with
                      | error error =>
                          simp only [hParams] at hRun
                          cases hRun
                      | ok afterParams =>
                          simp only [hParams] at hRun
                          cases hFields :
                              psKernelOpenSimpleMutualConstructorFields
                                fuel afterParams.session typeNames
                                typeShapes levels params resultLevel
                                afterParams.result with
                          | error error =>
                              simp only [hFields] at hRun
                              cases hRun
                          | ok fieldsResult =>
                              simp only [hFields] at hRun
                              cases hApp :
                                  psKernelSimpleMutualAppInfo
                                    typeNames typeShapes levels params
                                    fieldsResult.result with
                              | none =>
                                  simp only [hApp] at hRun
                                  cases hRun
                              | some appInfo =>
                                  simp only [hApp] at hRun
                                  cases hOwner :
                                      Nat.beq appInfo.target owner with
                                  | false =>
                                      simp only [hOwner] at hRun
                                      cases hRun
                                  | true =>
                                      simp only [hOwner] at hRun
                                      have hShape := psKernelOpenSimpleMutualConstructor_shape_refines
                                        fuel hNative hString hReflexive
                                        (psKernelSessionWithEnvironment headerSession work)
                                        typeNames typeShapes levels params resultLevel typeShape owner ctor.type
                                        afterParams fieldsResult appInfo hCtorConfig hOwnerShape
                                        hParams hFields hApp hOwner
                                      have hOpen : PsKernelMutualConstructorOpenShapeValid
                                          work headerSession.context.localContext typeNames typeShapes
                                          levels params resultLevel typeShape ctor.type fieldsResult.fields
                                          fieldsResult.recursiveFields appInfo.indices := by
                                        simpa [psKernelSessionWithEnvironment,
                                          psKernelCheckerContextWithEnvironment] using hShape.1
                                      let initial := psKernelMkCheckerSession work
                                        headerSession.context.levelParams safety
                                        headerSession.context.maxRecDepth headerSession.context.maxNatSize
                                      have hInitial := psKernelMkCheckerSession_configuration_sound work
                                        headerSession.context.levelParams safety
                                        headerSession.context.maxRecDepth headerSession.context.maxNatSize hIndex
                                      have hTyped := psKernelSessionCheck_concrete_refines_typing
                                        fuel hNative hString initial ctorType.2 ctor.type ctorType.1 hInitial hType
                                      have hCheckedContext := psKernelSessionCheck_success_preserves_context_core
                                        fuel initial ctorType.2 ctor.type ctorType.1 hType
                                      have hCheckedConfig : PsKernelCheckerConfigurationSound
                                          ctorType.2.context ctorType.2.state := by
                                        simpa [hCheckedContext] using hTyped.2
                                      have hSorted := psKernelSessionEnsureSort_concrete_refines_reduction
                                        fuel hNative hString ctorType.2 sortResult.2 ctorType.1
                                        sortResult.1 hCheckedConfig hSort
                                      let ctorInfo :=
                                        PsKernelConstructorInfo.mk
                                          (PsKernelConstantBase.mk
                                            ctor.name
                                            headerSession.context.levelParams
                                            ctor.type)
                                          typeShape.decl.name
                                          ctorIndex
                                          (psKernelOpenBinderListLength params)
                                          (psKernelOpenBinderListLength
                                            fieldsResult.fields)
                                          (psKernelDefinitionSafetyIsUnsafe
                                            safety)
                                      let nextWork :=
                                        psKernelEnvironmentAddUnchecked
                                          work
                                          (PsKernelConstantInfo.ctorInfo
                                            ctorInfo)
                                      have hNext :
                                          PsKernelEnvironmentIndexRefines
                                            nextWork :=
                                        psKernelEnvironmentAddUnchecked_index_refines
                                          work
                                          (PsKernelConstantInfo.ctorInfo
                                            ctorInfo)
                                          hIndex
                                      have hStepExt : PsKernelEnvironmentSemanticExtends work nextWork :=
                                        psKernelEnvironmentAddUnchecked_fresh_semantic_extends
                                          work (PsKernelConstantInfo.ctorInfo ctorInfo) hString
                                          (by simpa [ctorInfo, psKernelConstantInfoName,
                                            psKernelConstantInfoBase] using hFresh.1)
                                      have hNextNames : PsKernelInductiveNamesAbsent nextWork
                                          (psKernelSimpleCtorNames rest) :=
                                        psKernelInductiveNamesAbsent_add_disjoint work
                                          (PsKernelConstantInfo.ctorInfo ctorInfo)
                                          (psKernelSimpleCtorNames rest) hFresh.2
                                          (by simpa [ctorInfo, psKernelConstantInfoName,
                                            psKernelConstantInfoBase] using hUniqueTail.1)
                                      cases hTail :
                                          psKernelAddSimpleMutualConstructorsForTypeWorker
                                            rest fuel safety resultLevel
                                            levels params typeNames typeShapes
                                            typeShape owner headerSession
                                            (psKernelEnvironmentAddUnchecked
                                              work
                                              (PsKernelConstantInfo.ctorInfo
                                                (PsKernelConstructorInfo.mk
                                                  (PsKernelConstantBase.mk
                                                    ctor.name
                                                    headerSession.context.levelParams
                                                    ctor.type)
                                                  typeShape.decl.name
                                                  ctorIndex
                                                  (psKernelOpenBinderListLength
                                                    params)
                                                  (psKernelOpenBinderListLength
                                                    fieldsResult.fields)
                                                  (psKernelDefinitionSafetyIsUnsafe
                                                    safety))))
                                            (Nat.succ ctorIndex) with
                                      | error error =>
                                          simp only [hTail] at hRun
                                          cases hRun
                                      | ok tailResult =>
                                          simp only [hTail] at hRun
                                          obtain ⟨hTailHistory, hTailExt, hFinalIndex⟩ :=
                                            ih fuel safety resultLevel levels params typeNames typeShapes
                                              typeShape owner headerSession nextWork (Nat.succ ctorIndex)
                                              tailResult hNext hHeaderConfig
                                              (PsKernelEnvironmentSemanticExtends.trans
                                                headerSession.context.environment work nextWork hEnvExt hStepExt)
                                              hNextNames hUniqueTail.2 hOwnerShape hReflexive hNative hString hTail
                                          cases hRun
                                          refine ⟨?_, PsKernelEnvironmentSemanticExtends.trans
                                            work nextWork tailResult.environment hStepExt hTailExt, hFinalIndex⟩
                                          apply PsKernelCheckedMutualConstructorHistory.step work ctorIndex ctor rest
                                            tailResult.shapes tailResult.environment ctorType.1 sortResult.1
                                            fieldsResult.fields fieldsResult.recursiveFields appInfo.indices
                                            hFresh.1 _ _ hOpen hTailHistory
                                          · simpa [initial, psKernelMkCheckerSession,
                                              psKernelCheckerContextEmpty] using hTyped.1
                                          · simpa [hCheckedContext, initial, psKernelMkCheckerSession,
                                              psKernelCheckerContextEmpty] using hSorted.1
