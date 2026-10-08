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
