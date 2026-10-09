import Ps.KernelCore.Metatheory.BootstrapStringObligations
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

theorem PsKernelCheckedMutualConstructorHistory.preserves_absent_names
    {targets : List PsKernelName} {typeShapes : List PsKernelSimpleMutualTypeShape}
    {levels : List PsKernelLevel} {params : List PsKernelOpenBinder}
    {resultLevel : PsKernelLevel} {typeShape : PsKernelSimpleMutualTypeShape}
    {owner : Nat} {levelParams : List PsKernelName} {safety : PsKernelDefinitionSafety}
    {headerLocal : PsKernelLocalContext} {work finalEnvironment : PsKernelEnvironment}
    {index : Nat} {ctors : List PsKernelSimpleConstructorDecl}
    {shapes : List PsKernelSimpleMutualConstructorShape}
    (hHistory : PsKernelCheckedMutualConstructorHistory targets typeShapes levels params
      resultLevel typeShape owner levelParams safety headerLocal work index ctors shapes finalEnvironment) :
    ∀ names : List PsKernelName,
      PsKernelInductiveNamesAbsent work names ->
      (∀ name : PsKernelName, List.Mem name (psKernelSimpleCtorNames ctors) ->
        psKernelNameListContains name names = false) ->
      PsKernelInductiveNamesAbsent finalEnvironment names := by
  induction hHistory with
  | done => intro names hAbsent hDisjoint; exact hAbsent
  | step work index ctor rest tailShapes finalEnvironment inferredType level
      fields recursiveFields indices hFresh hTyped hSort hOpen hTail ih =>
      intro names hAbsent hDisjoint
      apply ih names
      · apply psKernelInductiveNamesAbsent_add_disjoint _ _ names hAbsent
        exact hDisjoint ctor.name (by
          simpa [psKernelSimpleCtorNames] using (List.Mem.head (psKernelSimpleCtorNames rest)))
      · intro name hMem
        apply hDisjoint name
        simpa [psKernelSimpleCtorNames] using (List.Mem.tail ctor.name hMem)

/-- The remaining type traversal denotes the corresponding family suffix. -/
def PsKernelMutualTypeShapeSuffix
    (allShapes : List PsKernelSimpleMutualTypeShape) (owner : Nat)
    (remaining : List PsKernelSimpleMutualTypeShape) : Prop :=
  ∀ offset : Nat, ∀ shape : PsKernelSimpleMutualTypeShape,
    psKernelMutualTypeShapeListGet remaining offset = some shape ->
      psKernelMutualTypeShapeListGet allShapes (owner + offset) = some shape

theorem PsKernelMutualTypeShapeSuffix.root
    (shapes : List PsKernelSimpleMutualTypeShape) :
    PsKernelMutualTypeShapeSuffix shapes 0 shapes := by
  intro offset shape hGet
  simpa using hGet

theorem PsKernelMutualTypeShapeSuffix.head
    {allShapes : List PsKernelSimpleMutualTypeShape} {owner : Nat}
    {shape : PsKernelSimpleMutualTypeShape} {rest : List PsKernelSimpleMutualTypeShape}
    (hSuffix : PsKernelMutualTypeShapeSuffix allShapes owner (shape :: rest)) :
    psKernelMutualTypeShapeListGet allShapes owner = some shape := by
  simpa using hSuffix 0 shape rfl

theorem PsKernelMutualTypeShapeSuffix.tail
    {allShapes : List PsKernelSimpleMutualTypeShape} {owner : Nat}
    {shape : PsKernelSimpleMutualTypeShape} {rest : List PsKernelSimpleMutualTypeShape}
    (hSuffix : PsKernelMutualTypeShapeSuffix allShapes owner (shape :: rest)) :
    PsKernelMutualTypeShapeSuffix allShapes (Nat.succ owner) rest := by
  intro offset selected hGet
  have hSelected := hSuffix (Nat.succ offset) selected
    (by simpa [psKernelMutualTypeShapeListGet] using hGet)
  have hIndex : owner + Nat.succ offset = Nat.succ owner + offset := by omega
  simpa [hIndex] using hSelected

def psKernelMutualShapeConstructorNames
    (types : List PsKernelSimpleMutualTypeShape) : List PsKernelName :=
  match types with
  | [] => []
  | shape :: rest => psKernelSimpleCtorNames shape.decl.ctors ++
      psKernelMutualShapeConstructorNames rest

/-- Full ordered constructor publication across all mutual owners. -/
inductive PsKernelCheckedMutualFamilyConstructorHistory
    (targets : List PsKernelName) (allShapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel) (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (headerLocal : PsKernelLocalContext) :
    PsKernelEnvironment -> Nat -> List PsKernelSimpleMutualTypeShape ->
    List PsKernelSimpleMutualConstructorShape -> PsKernelEnvironment -> Prop where
  | done (work : PsKernelEnvironment) (owner : Nat) :
      PsKernelCheckedMutualFamilyConstructorHistory targets allShapes levels params
        resultLevel levelParams safety headerLocal work owner [] [] work
  | step (work ownEnvironment finalEnvironment : PsKernelEnvironment) (owner : Nat)
      (shape : PsKernelSimpleMutualTypeShape) (rest : List PsKernelSimpleMutualTypeShape)
      (ownShapes tailShapes : List PsKernelSimpleMutualConstructorShape)
      (hOwner : psKernelMutualTypeShapeListGet allShapes owner = some shape)
      (hOwn : PsKernelCheckedMutualConstructorHistory targets allShapes levels params
        resultLevel shape owner levelParams safety headerLocal work 0 shape.decl.ctors ownShapes ownEnvironment)
      (hTail : PsKernelCheckedMutualFamilyConstructorHistory targets allShapes levels params
        resultLevel levelParams safety headerLocal ownEnvironment (Nat.succ owner) rest tailShapes finalEnvironment) :
      PsKernelCheckedMutualFamilyConstructorHistory targets allShapes levels params
        resultLevel levelParams safety headerLocal work owner (shape :: rest)
        (psKernelMutualConstructorShapeListAppend ownShapes tailShapes) finalEnvironment

theorem psKernelAddSimpleMutualTypesWorker_semantic_history
    (types : List PsKernelSimpleMutualTypeShape) :
    ∀ (fuel : Nat) (safety : PsKernelDefinitionSafety) (resultLevel : PsKernelLevel)
      (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
      (typeNames : List PsKernelName) (allShapes : List PsKernelSimpleMutualTypeShape)
      (headerSession : PsKernelCheckerSession) (work : PsKernelEnvironment)
      (owner : Nat) (result : PsKernelAddMutualConstructorsResult),
      PsKernelEnvironmentIndexRefines work ->
      PsKernelCheckerConfigurationSound headerSession.context headerSession.state ->
      PsKernelEnvironmentSemanticExtends headerSession.context.environment work ->
      PsKernelInductiveNamesAbsent work (psKernelMutualShapeConstructorNames types) ->
      psKernelNameHasDuplicates (psKernelMutualShapeConstructorNames types) = false ->
      PsKernelMutualTypeShapeSuffix allShapes owner types ->
      PsKernelStringEqReflexiveLaw -> PsKernelNativeReductionSoundLaw -> PsKernelStringEqSoundLaw ->
      psKernelAddSimpleMutualTypesWorker types fuel safety resultLevel levels params
        typeNames allShapes headerSession work owner = Except.ok result ->
      PsKernelCheckedMutualFamilyConstructorHistory typeNames allShapes levels params resultLevel
        headerSession.context.levelParams safety headerSession.context.localContext
        work owner types result.shapes result.environment ∧
      PsKernelEnvironmentSemanticExtends work result.environment ∧
      PsKernelEnvironmentIndexRefines result.environment := by
  induction types with
  | nil =>
      intro fuel safety resultLevel levels params typeNames allShapes headerSession work owner
        result hIndex hHeaderConfig hEnvExt hNames hUnique hSuffix hReflexive hNative hString hRun
      simp [psKernelAddSimpleMutualTypesWorker] at hRun
      cases hRun
      exact ⟨PsKernelCheckedMutualFamilyConstructorHistory.done work owner,
        PsKernelEnvironmentSemanticExtends.refl work, hIndex⟩
  | cons typeShape rest ih =>
      intro fuel safety resultLevel levels params typeNames allShapes headerSession work owner
        result hIndex hHeaderConfig hEnvExt hNames hUnique hSuffix hReflexive hNative hString hRun
      have hNamesSplit := PsKernelInductiveNamesAbsent.append_split work
        (psKernelSimpleCtorNames typeShape.decl.ctors) (psKernelMutualShapeConstructorNames rest) hNames
      have hUniqueSplit := psKernelNameHasDuplicates_append_false_refines
        (psKernelSimpleCtorNames typeShape.decl.ctors) (psKernelMutualShapeConstructorNames rest) hUnique
      simp only [psKernelAddSimpleMutualTypesWorker] at hRun
      cases hOwn : psKernelAddSimpleMutualConstructorsForTypeWorker
          typeShape.decl.ctors fuel safety resultLevel levels params typeNames allShapes
          typeShape owner headerSession work 0 with
      | error message => simp only [hOwn] at hRun; cases hRun
      | ok ownResult =>
          simp only [hOwn] at hRun
          obtain ⟨hOwnHistory, hOwnExt, hOwnIndex⟩ :=
            psKernelAddSimpleMutualConstructorsForTypeWorker_semantic_history
              typeShape.decl.ctors fuel safety resultLevel levels params typeNames allShapes
              typeShape owner headerSession work 0 ownResult hIndex hHeaderConfig hEnvExt
              hNamesSplit.1 hUniqueSplit.1 hSuffix.head hReflexive hNative hString hOwn
          have hRemainingNames := hOwnHistory.preserves_absent_names
            (psKernelMutualShapeConstructorNames rest) hNamesSplit.2 hUniqueSplit.2.2
          cases hRest : psKernelAddSimpleMutualTypesWorker rest fuel safety resultLevel
              levels params typeNames allShapes headerSession ownResult.environment (Nat.succ owner) with
          | error message => simp only [hRest] at hRun; cases hRun
          | ok tailResult =>
              simp only [hRest] at hRun
              obtain ⟨hTailHistory, hTailExt, hFinalIndex⟩ :=
                ih fuel safety resultLevel levels params typeNames allShapes headerSession
                  ownResult.environment (Nat.succ owner) tailResult hOwnIndex hHeaderConfig
                  (PsKernelEnvironmentSemanticExtends.trans headerSession.context.environment
                    work ownResult.environment hEnvExt hOwnExt)
                  hRemainingNames hUniqueSplit.2.1 hSuffix.tail hReflexive hNative hString hRest
              cases hRun
              exact ⟨PsKernelCheckedMutualFamilyConstructorHistory.step work
                ownResult.environment tailResult.environment owner typeShape rest
                ownResult.shapes tailResult.shapes hSuffix.head hOwnHistory hTailHistory,
                PsKernelEnvironmentSemanticExtends.trans work ownResult.environment
                  tailResult.environment hOwnExt hTailExt, hFinalIndex⟩

/-- Exact constructor declarations in source order for one mutual owner. -/
def psKernelMutualConstructorHistoryInfos
    (typeShape : PsKernelSimpleMutualTypeShape) (levelParams : List PsKernelName)
    (params : List PsKernelOpenBinder) (safety : PsKernelDefinitionSafety)
    (index : Nat) (shapes : List PsKernelSimpleMutualConstructorShape) :
    List PsKernelConstantInfo :=
  match shapes with
  | [] => []
  | shape :: rest =>
      PsKernelConstantInfo.ctorInfo
        (PsKernelConstructorInfo.mk
          (PsKernelConstantBase.mk shape.ctor.name levelParams shape.ctor.type)
          typeShape.decl.name index (psKernelOpenBinderListLength params)
          (psKernelOpenBinderListLength shape.fields) (psKernelDefinitionSafetyIsUnsafe safety)) ::
      psKernelMutualConstructorHistoryInfos typeShape levelParams params safety
        (Nat.succ index) rest

/-- Source-order provenance, exact publication, and runtime/Quot preservation. -/
theorem PsKernelCheckedMutualConstructorHistory.exact_extension
    {targets : List PsKernelName} {typeShapes : List PsKernelSimpleMutualTypeShape}
    {levels : List PsKernelLevel} {params : List PsKernelOpenBinder}
    {resultLevel : PsKernelLevel} {typeShape : PsKernelSimpleMutualTypeShape}
    {owner : Nat} {levelParams : List PsKernelName} {safety : PsKernelDefinitionSafety}
    {headerLocal : PsKernelLocalContext} {work finalEnvironment : PsKernelEnvironment}
    {index : Nat} {ctors : List PsKernelSimpleConstructorDecl}
    {shapes : List PsKernelSimpleMutualConstructorShape}
    (hHistory : PsKernelCheckedMutualConstructorHistory targets typeShapes levels params
      resultLevel typeShape owner levelParams safety headerLocal work index ctors shapes finalEnvironment) :
    PsKernelEnvironmentExtendsBy work finalEnvironment
      (psKernelMutualConstructorHistoryInfos typeShape levelParams params safety index shapes).reverse ∧
    finalEnvironment.quotInitialized = work.quotInitialized ∧
    (psKernelMutualConstructorHistoryInfos typeShape levelParams params safety index shapes).map
      psKernelConstantInfoName = psKernelSimpleCtorNames ctors := by
  induction hHistory with
  | done => exact ⟨psKernelEnvironmentExtendsBy_refl _, rfl, rfl⟩
  | step work index ctor rest tailShapes finalEnvironment inferredType level
      fields recursiveFields indices hFresh hTyped hSort hOpen hTail ih =>
      refine ⟨?_, ih.2.1, ?_⟩
      · simpa [PsKernelEnvironmentExtendsBy, psKernelMutualConstructorHistoryInfos,
          psKernelEnvironmentAddUnchecked, List.reverse_cons, List.append_assoc] using ih.1
      · simpa [psKernelMutualConstructorHistoryInfos, psKernelConstantInfoName,
          psKernelConstantInfoBase, psKernelSimpleCtorNames] using congrArg (List.cons ctor.name) ih.2.2

/-- Reserved recursor names survive the complete family constructor history. -/
theorem PsKernelCheckedMutualFamilyConstructorHistory.preserves_absent_names
    {targets : List PsKernelName} {allShapes : List PsKernelSimpleMutualTypeShape}
    {levels : List PsKernelLevel} {params : List PsKernelOpenBinder}
    {resultLevel : PsKernelLevel} {levelParams : List PsKernelName}
    {safety : PsKernelDefinitionSafety} {headerLocal : PsKernelLocalContext}
    {work finalEnvironment : PsKernelEnvironment} {owner : Nat}
    {types : List PsKernelSimpleMutualTypeShape}
    {shapes : List PsKernelSimpleMutualConstructorShape}
    (hHistory : PsKernelCheckedMutualFamilyConstructorHistory targets allShapes levels params
      resultLevel levelParams safety headerLocal work owner types shapes finalEnvironment) :
    ∀ names : List PsKernelName,
      PsKernelInductiveNamesAbsent work names ->
      (∀ name : PsKernelName, name ∈ psKernelMutualShapeConstructorNames types ->
        psKernelNameListContains name names = false) ->
      PsKernelInductiveNamesAbsent finalEnvironment names := by
  induction hHistory with
  | done => intro names hAbsent _; exact hAbsent
  | step work ownEnvironment finalEnvironment owner shape rest ownShapes tailShapes
      hOwner hOwn hTail ih =>
      intro names hAbsent hDisjoint
      apply ih names
      · apply hOwn.preserves_absent_names names hAbsent
        intro name hMember
        apply hDisjoint name
        exact List.mem_append_left _ hMember
      · intro name hMember
        apply hDisjoint name
        exact List.mem_append_right _ hMember

/-- The full family publishes exactly the source constructors, in reverse insertion order. -/
theorem PsKernelCheckedMutualFamilyConstructorHistory.exact_extension
    {targets : List PsKernelName} {allShapes : List PsKernelSimpleMutualTypeShape}
    {levels : List PsKernelLevel} {params : List PsKernelOpenBinder}
    {resultLevel : PsKernelLevel} {levelParams : List PsKernelName}
    {safety : PsKernelDefinitionSafety} {headerLocal : PsKernelLocalContext}
    {work finalEnvironment : PsKernelEnvironment} {owner : Nat}
    {types : List PsKernelSimpleMutualTypeShape}
    {shapes : List PsKernelSimpleMutualConstructorShape}
    (hHistory : PsKernelCheckedMutualFamilyConstructorHistory targets allShapes levels params
      resultLevel levelParams safety headerLocal work owner types shapes finalEnvironment) :
    ∃ added : List PsKernelConstantInfo,
      PsKernelEnvironmentExtendsBy work finalEnvironment added.reverse ∧
      finalEnvironment.quotInitialized = work.quotInitialized ∧
      added.map psKernelConstantInfoName = psKernelMutualShapeConstructorNames types := by
  induction hHistory with
  | done work owner => exact ⟨[], psKernelEnvironmentExtendsBy_refl work, rfl, rfl⟩
  | step work ownEnvironment finalEnvironment owner shape rest ownShapes tailShapes
      hOwner hOwn hTail ih =>
      obtain ⟨tailInfos, hTailExt, hTailQuot, hTailNames⟩ := ih
      let ownInfos := psKernelMutualConstructorHistoryInfos shape levelParams params safety 0 ownShapes
      have hOwnExt := hOwn.exact_extension
      refine ⟨ownInfos ++ tailInfos, ?_, hTailQuot.trans hOwnExt.2.1, ?_⟩
      · constructor
        · change finalEnvironment.constants = (ownInfos ++ tailInfos).reverse ++ work.constants
          rw [hTailExt.1, hOwnExt.1.1]
          simp [ownInfos, List.reverse_append, List.append_assoc]
        · exact hTailExt.2.trans hOwnExt.1.2
      · change (ownInfos ++ tailInfos).map psKernelConstantInfoName =
          psKernelSimpleCtorNames shape.decl.ctors ++ psKernelMutualShapeConstructorNames rest
        rw [List.map_append, hTailNames]
        exact congrArg (fun names => names ++ psKernelMutualShapeConstructorNames rest) hOwnExt.2.2

/--
Actual-source mutual-family constructor refinement. The nested worker theorem
retains an explicit comparator interface for reuse, but the executable source
discharges that interface from the checked specified cursor operations.
No reflexivity assumption, new axiom, or independent typing shortcut enters
the family-level constructor certificate.
-/
theorem psKernelAddSimpleMutualTypesWorker_concrete_semantic_history
    (types : List PsKernelSimpleMutualTypeShape)
    (fuel : Nat) (safety : PsKernelDefinitionSafety) (resultLevel : PsKernelLevel)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (typeNames : List PsKernelName) (allShapes : List PsKernelSimpleMutualTypeShape)
    (headerSession : PsKernelCheckerSession) (work : PsKernelEnvironment)
    (owner : Nat) (result : PsKernelAddMutualConstructorsResult)
    (hIndex : PsKernelEnvironmentIndexRefines work)
    (hHeaderConfig : PsKernelCheckerConfigurationSound headerSession.context headerSession.state)
    (hEnvExt : PsKernelEnvironmentSemanticExtends headerSession.context.environment work)
    (hNames : PsKernelInductiveNamesAbsent work (psKernelMutualShapeConstructorNames types))
    (hUnique : psKernelNameHasDuplicates (psKernelMutualShapeConstructorNames types) = false)
    (hSuffix : PsKernelMutualTypeShapeSuffix allShapes owner types)
    (hNative : PsKernelNativeReductionSoundLaw) (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualTypesWorker types fuel safety resultLevel levels params
      typeNames allShapes headerSession work owner = Except.ok result) :
    PsKernelCheckedMutualFamilyConstructorHistory typeNames allShapes levels params resultLevel
      headerSession.context.levelParams safety headerSession.context.localContext
      work owner types result.shapes result.environment ∧
    PsKernelEnvironmentSemanticExtends work result.environment ∧
    PsKernelEnvironmentIndexRefines result.environment :=
  psKernelAddSimpleMutualTypesWorker_semantic_history types fuel safety resultLevel
    levels params typeNames allShapes headerSession work owner result
    hIndex hHeaderConfig hEnvExt hNames hUnique hSuffix
    psKernelStringEq_reflexive hNative hString hRun
