import Ps.KernelCore.Metatheory.AdmissionMutualHeaderConfiguration
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

/--
Source family names are the ordinary map of checked datatype declaration
names. This identity is reused by all provisional constructor/recursor
publication certificates.
-/
theorem psKernelSimpleMutualNames_map
    (types : List PsKernelSimpleMutualTypeDecl) :
    psKernelSimpleMutualNames types =
      types.map (fun typeDecl : PsKernelSimpleMutualTypeDecl => typeDecl.name) := by
  induction types with
  | nil => rfl
  | cons typeDecl rest ih =>
      simpa [psKernelSimpleMutualNames] using congrArg (List.cons typeDecl.name) ih

/-- Name provenance transfers from source declarations to their checked shapes. -/
theorem psKernelMutualShapes_source_name_provenance
    (shapes : List PsKernelSimpleMutualTypeShape)
    (types : List PsKernelSimpleMutualTypeDecl)
    (hDecl : shapes.map PsKernelSimpleMutualTypeShape.decl = types) :
    shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name) =
      psKernelSimpleMutualNames types := by
  calc
    shapes.map (fun shape : PsKernelSimpleMutualTypeShape => shape.decl.name) =
        (shapes.map PsKernelSimpleMutualTypeShape.decl).map
          (fun typeDecl : PsKernelSimpleMutualTypeDecl => typeDecl.name) := by
            simp [List.map_map]
    _ = types.map (fun typeDecl : PsKernelSimpleMutualTypeDecl => typeDecl.name) :=
      congrArg (fun decls : List PsKernelSimpleMutualTypeDecl =>
        decls.map (fun typeDecl : PsKernelSimpleMutualTypeDecl => typeDecl.name)) hDecl
    _ = psKernelSimpleMutualNames types := (psKernelSimpleMutualNames_map types).symm

/-- Generated recursor-name order is determined solely by source type shapes. -/
theorem psKernelMutualShapeRecursorNames_source
    (shapes : List PsKernelSimpleMutualTypeShape) :
    shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
      psKernelSimpleRecName shape.decl.name) =
      psKernelSimpleMutualRecNames (shapes.map PsKernelSimpleMutualTypeShape.decl) := by
  induction shapes with
  | nil => rfl
  | cons shape rest ih =>
      simpa [psKernelSimpleMutualRecNames] using
        congrArg (List.cons (psKernelSimpleRecName shape.decl.name)) ih

/-- Generated constructor-name order is determined solely by source type shapes. -/
theorem psKernelMutualShapeConstructorNames_source
    (shapes : List PsKernelSimpleMutualTypeShape) :
    psKernelMutualShapeConstructorNames shapes =
      psKernelSimpleMutualCtorNames (shapes.map PsKernelSimpleMutualTypeShape.decl) := by
  induction shapes with
  | nil => rfl
  | cons shape rest ih =>
      simpa [psKernelMutualShapeConstructorNames, psKernelSimpleMutualCtorNames,
        psKernelMutualNameListAppend_eq_append] using
        congrArg (fun names : List PsKernelName =>
          psKernelSimpleCtorNames shape.decl.ctors ++ names) ih

/--
Independent joint certificate for the source's provisional mutual-header
transaction, immediately before its checked constructor worker.

Every premise needed to transfer canonical semantics, authoritative indexes,
and source-family constructor/recursor reservations is derived from actual
successful admission. The final conjunct retains independent checked Sort
typing for every source type rather than a mere inference assertion.
-/
def PsKernelPreparedMutualConstructorInputsValid
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape) : Prop :=
  let work0 := psKernelAddMutualInductiveInfos
    (psKernelMakeSimpleMutualBaseInfos
      (psKernelSimpleMutualNames decl.types) decl shapes) environment
  shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types ∧
  PsKernelEnvironmentSemanticExtends environment work0 ∧
  PsKernelEnvironmentIndexRefines work0 ∧
  PsKernelInductiveNamesAbsent work0 (psKernelMutualShapeConstructorNames shapes) ∧
  psKernelNameHasDuplicates (psKernelMutualShapeConstructorNames shapes) = false ∧
  PsKernelInductiveNamesAbsent work0 (shapes.map
    (fun shape : PsKernelSimpleMutualTypeShape => psKernelSimpleRecName shape.decl.name)) ∧
  psKernelNameHasDuplicates (shapes.map
    (fun shape : PsKernelSimpleMutualTypeShape => psKernelSimpleRecName shape.decl.name)) = false ∧
  (∀ typeDecl : PsKernelSimpleMutualTypeDecl, List.Mem typeDecl decl.types ->
    ∃ level : PsKernelLevel,
      PsKernelTypingJudgment environment psKernelLocalContextEmpty
        typeDecl.type (PsKernelExpr.sort level))

/--
The actual global admission preflight derives the complete provisional
constructor-input certificate for *any* checked shape list that preserves
source declaration order. This makes source-name invariants independent of
index-opening implementation details and allows the later executable pipeline
to reuse its exact (not merely existential) shape witnesses.
-/
theorem psKernelPreparedMutualConstructorInputs_for_source_shapes
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (hShapeDecls : shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualInductive fuel environment decl
      maxRecDepth maxNatSize = Except.ok result) :
    PsKernelPreparedMutualConstructorInputsValid environment decl shapes := by
  obtain ⟨hTypesAbsent, _, _, hTypesUnique, hRecUnique, hCtorUnique,
    hTypesDisjoint, _⟩ :=
    psKernelAddSimpleMutualInductive_success_partitioned_name_guards
      fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  have hShapeNames :=
    psKernelMutualShapes_source_name_provenance shapes decl.types hShapeDecls
  have hPrepared := psKernelPreparedMutualHeaders_semantic_refines
    (psKernelSimpleMutualNames decl.types) decl shapes environment hIndex hString
    (by simpa only [hShapeNames] using hTypesAbsent)
    (by simpa only [hShapeNames] using hTypesUnique)
  have hRecNames : shapes.map
      (fun shape : PsKernelSimpleMutualTypeShape => psKernelSimpleRecName shape.decl.name) =
      psKernelSimpleMutualRecNames decl.types := by
    rw [psKernelMutualShapeRecursorNames_source, hShapeDecls]
  have hCtorNames : psKernelMutualShapeConstructorNames shapes =
      psKernelSimpleMutualCtorNames decl.types := by
    rw [psKernelMutualShapeConstructorNames_source, hShapeDecls]
  obtain ⟨_, _, _, hAllAbsent⟩ :=
    psKernelAddSimpleMutualInductive_success_name_guards
      fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  have hOriginalReserved : PsKernelInductiveNamesAbsent environment
      (psKernelSimpleMutualRecNames decl.types ++
        psKernelSimpleMutualCtorNames decl.types) := by
    have hAll : PsKernelInductiveNamesAbsent environment
        (psKernelSimpleMutualNames decl.types ++
          (psKernelSimpleMutualRecNames decl.types ++
            psKernelSimpleMutualCtorNames decl.types)) := by
      simpa only [psKernelMutualNameListAppend_eq_append] using hAllAbsent
    exact (PsKernelInductiveNamesAbsent.append_split environment
      (psKernelSimpleMutualNames decl.types)
      (psKernelSimpleMutualRecNames decl.types ++
        psKernelSimpleMutualCtorNames decl.types) hAll).2
  let work0 := psKernelAddMutualInductiveInfos
    (psKernelMakeSimpleMutualBaseInfos
      (psKernelSimpleMutualNames decl.types) decl shapes) environment
  have hReserved := psKernelPreparedMutualHeaders_preserves_reserved_names
    (psKernelSimpleMutualNames decl.types) decl shapes environment
    (psKernelSimpleMutualRecNames decl.types ++
      psKernelSimpleMutualCtorNames decl.types)
    hOriginalReserved (by
      intro name hMember
      apply hTypesDisjoint name
      simpa only [hShapeNames] using hMember)
  have hSplit := PsKernelInductiveNamesAbsent.append_split work0
    (psKernelSimpleMutualRecNames decl.types)
    (psKernelSimpleMutualCtorNames decl.types) hReserved
  have hTyped :=
    psKernelAddSimpleMutualInductive_success_all_headers_sort_typed
      fuel environment result decl maxRecDepth maxNatSize hIndex hNative hString hRun
  dsimp only [PsKernelPreparedMutualConstructorInputsValid]
  refine ⟨hShapeDecls, hPrepared.1, hPrepared.2.1, ?_, ?_, ?_, ?_, hTyped⟩
  · simpa only [hCtorNames] using hSplit.2
  · simpa only [hCtorNames] using hCtorUnique
  · simpa only [hRecNames] using hSplit.1
  · simpa only [hRecNames] using hRecUnique

theorem psKernelAddSimpleMutualInductive_success_prepared_constructor_inputs
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualInductive
      fuel environment decl maxRecDepth maxNatSize = Except.ok result) :
    ∃ shapes : List PsKernelSimpleMutualTypeShape,
      PsKernelPreparedMutualConstructorInputsValid environment decl shapes := by
  obtain ⟨first, remaining, paramResult, indexResult, headerLevel, resultLevel,
    tailShapes, hTypes, hFirstTyping, hParamConfig, hIndexConfig, hParamEnv,
    hIndexEnv, hHistory⟩ :=
    psKernelAddSimpleMutualInductive_success_header_semantics
      fuel environment result decl maxRecDepth maxNatSize
      hIndex hNative hString hRun
  let shapes : List PsKernelSimpleMutualTypeShape :=
    PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes
  have hShapeDecls : shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types := by
    rw [hTypes]
    simpa [shapes] using congrArg (List.cons first) hHistory.shape_provenance
  exact ⟨shapes, psKernelPreparedMutualConstructorInputs_for_source_shapes
    fuel environment result decl maxRecDepth maxNatSize shapes hShapeDecls
    hIndex hNative hString hRun⟩


/--
Composition boundary for the executable mutual-constructor family worker.

The prepared input certificate supplies authoritative indexes, canonical
semantic preservation, source-name freshness and uniqueness. The independently
sound session and the actual successful worker supply checked constructor
history, exact insertion provenance, and a sound work environment.

The cross-family disjointness requirement is explicit at this boundary; it
must be discharged from the *same actual admission* global naming guard.
No infer-only typing, unproved comparator reflexivity, or replacement
well-formedness is inferred.
-/
theorem psKernelMutualConstructorWorker_prepared_refines
    (fuel : Nat) (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (headerSession : PsKernelCheckerSession)
    (resultLevel : PsKernelLevel) (params : List PsKernelOpenBinder)
    (result : PsKernelAddMutualConstructorsResult)
    (hPrepared : PsKernelPreparedMutualConstructorInputsValid environment decl shapes)
    (hHeaderConfig : PsKernelCheckerConfigurationSound
      headerSession.context headerSession.state)
    (hHeaderEnvironment : headerSession.context.environment = environment)
    (hCross : ∀ name : PsKernelName, List.Mem name
        (psKernelMutualShapeConstructorNames shapes) ->
      psKernelNameListContains name
        (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
          psKernelSimpleRecName shape.decl.name)) = false)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualTypesWorker shapes fuel
      (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
        else PsKernelDefinitionSafety.safe)
      resultLevel (psKernelLevelParamsToLevels decl.levelParams)
      params (psKernelSimpleMutualNames decl.types) shapes headerSession
      (psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes) environment) 0 =
        Except.ok result) :
    let work0 := psKernelAddMutualInductiveInfos
      (psKernelMakeSimpleMutualBaseInfos
        (psKernelSimpleMutualNames decl.types) decl shapes) environment
    ∃ added : List PsKernelConstantInfo,
      PsKernelCheckedMutualFamilyConstructorHistory
        (psKernelSimpleMutualNames decl.types) shapes
        (psKernelLevelParamsToLevels decl.levelParams) params resultLevel
        headerSession.context.levelParams
        (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
          else PsKernelDefinitionSafety.safe)
        headerSession.context.localContext
        work0 0 shapes result.shapes result.environment ∧
      PsKernelEnvironmentSemanticExtends environment result.environment ∧
      PsKernelEnvironmentIndexRefines result.environment ∧
      PsKernelInductiveNamesAbsent result.environment
        (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
          psKernelSimpleRecName shape.decl.name)) ∧
      PsKernelEnvironmentExtendsBy work0 result.environment added.reverse ∧
      result.environment.quotInitialized = work0.quotInitialized ∧
      added.map psKernelConstantInfoName =
        psKernelMutualShapeConstructorNames shapes := by
  let work0 := psKernelAddMutualInductiveInfos
    (psKernelMakeSimpleMutualBaseInfos
      (psKernelSimpleMutualNames decl.types) decl shapes) environment
  obtain ⟨hShapeDecls, hEnvExt, hIndex, hCtorAbsent, hCtorUnique,
    hRecAbsent, hRecUnique, hHeadersTyped⟩ := hPrepared
  have hSessionExt :
      PsKernelEnvironmentSemanticExtends headerSession.context.environment work0 := by
    rw [hHeaderEnvironment]
    exact hEnvExt
  obtain ⟨hHistory, hCtorExt, hFinalIndex⟩ :=
    psKernelAddSimpleMutualTypesWorker_concrete_semantic_history
      shapes fuel
      (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
        else PsKernelDefinitionSafety.safe)
      resultLevel (psKernelLevelParamsToLevels decl.levelParams) params
      (psKernelSimpleMutualNames decl.types) shapes
      headerSession work0 0 result
      hIndex hHeaderConfig hSessionExt hCtorAbsent hCtorUnique
      (PsKernelMutualTypeShapeSuffix.root shapes) hNative hString hRun
  have hRecAbsentFinal :=
    hHistory.preserves_absent_names
      (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
        psKernelSimpleRecName shape.decl.name))
      hRecAbsent hCross
  obtain ⟨added, hAdded, hQuot, hNames⟩ := hHistory.exact_extension
  exact ⟨added, hHistory,
    PsKernelEnvironmentSemanticExtends.trans environment work0
      result.environment hEnvExt hCtorExt,
    hFinalIndex, hRecAbsentFinal, hAdded, hQuot, hNames⟩

/--
The actual global source-level name guards discharge the cross-name condition
needed by the checked constructor-history worker. The proof transports the
executable disjointness through independently established shape provenance.
No additional cross-family uniqueness premise is imposed on successful input.
-/
theorem psKernelAddSimpleMutualInductive_success_shape_ctor_rec_disjoint
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (hShapeDecls : shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hRun : psKernelAddSimpleMutualInductive
      fuel environment decl maxRecDepth maxNatSize = Except.ok result) :
    ∀ name : PsKernelName, List.Mem name
      (psKernelMutualShapeConstructorNames shapes) ->
      psKernelNameListContains name
        (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
          psKernelSimpleRecName shape.decl.name)) = false := by
  have hCross :=
    psKernelAddSimpleMutualInductive_success_constructor_recursor_disjoint
      fuel environment result decl maxRecDepth maxNatSize hIndex hRun
  have hCtorNames : psKernelMutualShapeConstructorNames shapes =
      psKernelSimpleMutualCtorNames decl.types := by
    rw [psKernelMutualShapeConstructorNames_source, hShapeDecls]
  have hRecNames : shapes.map
      (fun shape : PsKernelSimpleMutualTypeShape => psKernelSimpleRecName shape.decl.name) =
      psKernelSimpleMutualRecNames decl.types := by
    rw [psKernelMutualShapeRecursorNames_source, hShapeDecls]
  simpa only [hCtorNames, hRecNames] using hCross

/--
Actual successful mutual admission yields independently checked complete
constructor-family history with canonical and publication guarantees.

Unlike the reusable constructor worker theorem, this theorem obtains the
successful worker call, its exact checked source shape witnesses, the sound
parameter-open checker session, and all name/freshness preconditions from the
real top-level successful executable path. Full recursor and final metadata
replacement transactions remain separate obligations.
-/
theorem psKernelAddSimpleMutualInductive_success_constructor_stage_refines
    (fuel : Nat) (environment result : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) (maxRecDepth maxNatSize : Nat)
    (hIndex : PsKernelEnvironmentIndexRefines environment)
    (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hRun : psKernelAddSimpleMutualInductive
      fuel environment decl maxRecDepth maxNatSize = Except.ok result) :
    ∃ (shapes : List PsKernelSimpleMutualTypeShape)
      (headerSession : PsKernelCheckerSession)
      (params : List PsKernelOpenBinder) (resultLevel : PsKernelLevel)
      (ctorResult : PsKernelAddMutualConstructorsResult)
      (added : List PsKernelConstantInfo),
      let work0 := psKernelAddMutualInductiveInfos
        (psKernelMakeSimpleMutualBaseInfos
          (psKernelSimpleMutualNames decl.types) decl shapes) environment
      shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types ∧
      PsKernelCheckerConfigurationSound headerSession.context headerSession.state ∧
      headerSession.context.environment = environment ∧
      PsKernelPreparedMutualConstructorInputsValid environment decl shapes ∧
      psKernelAddSimpleMutualTypesWorker shapes fuel
        (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
          else PsKernelDefinitionSafety.safe)
        resultLevel (psKernelLevelParamsToLevels decl.levelParams)
        params (psKernelSimpleMutualNames decl.types) shapes
        headerSession work0 0 = Except.ok ctorResult ∧
      PsKernelCheckedMutualFamilyConstructorHistory
        (psKernelSimpleMutualNames decl.types) shapes
        (psKernelLevelParamsToLevels decl.levelParams) params resultLevel
        headerSession.context.levelParams
        (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
          else PsKernelDefinitionSafety.safe)
        headerSession.context.localContext work0 0 shapes ctorResult.shapes
        ctorResult.environment ∧
      PsKernelEnvironmentSemanticExtends environment ctorResult.environment ∧
      PsKernelEnvironmentIndexRefines ctorResult.environment ∧
      PsKernelInductiveNamesAbsent ctorResult.environment
        (shapes.map (fun shape : PsKernelSimpleMutualTypeShape =>
          psKernelSimpleRecName shape.decl.name)) ∧
      PsKernelEnvironmentExtendsBy work0 ctorResult.environment added.reverse ∧
      ctorResult.environment.quotInitialized = work0.quotInitialized ∧
      added.map psKernelConstantInfoName = psKernelMutualShapeConstructorNames shapes := by
  obtain ⟨first, remaining, checked, sorted, paramResult, indexResult, resultLevel,
    tailShapes, ctorResult, hTypes, hCheck, hSort, hParams, hIndices,
    hResult, hTail, hCtor⟩ :=
    psKernelAddSimpleMutualInductive_success_constructor_pipeline
      fuel environment result decl maxRecDepth maxNatSize hRun
  let initial := psKernelMkCheckerSession environment decl.levelParams
    (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
      else PsKernelDefinitionSafety.safe) maxRecDepth maxNatSize
  have hInitial := psKernelMkCheckerSession_configuration_sound
    environment decl.levelParams
      (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
        else PsKernelDefinitionSafety.safe) maxRecDepth maxNatSize hIndex
  have hCheckSound := psKernelSessionCheck_concrete_refines_typing
    fuel hNative hString initial checked.2 first.type checked.1 hInitial hCheck
  have hCheckedContext := psKernelSessionCheck_success_preserves_context_core
    fuel initial checked.2 first.type checked.1 hCheck
  have hCheckedConfig : PsKernelCheckerConfigurationSound
      checked.2.context checked.2.state := by
    simpa [hCheckedContext] using hCheckSound.2
  have hSortSound := psKernelSessionEnsureSort_concrete_refines_reduction
    fuel hNative hString checked.2 sorted.2 checked.1 sorted.1 hCheckedConfig hSort
  have hSortedContext := psKernelSessionEnsureSort_success_preserves_context_core
    fuel checked.2 sorted.2 checked.1 sorted.1 hSort
  have hSortedEnv : sorted.2.context.environment = environment := by
    rw [hSortedContext, hCheckedContext]
    simp [initial, psKernelMkCheckerSession, psKernelCheckerContextEmpty]
  have hSortedConfig : PsKernelCheckerConfigurationSound
      sorted.2.context sorted.2.state := by
    simpa [hSortedContext] using hSortSound.2
  have hParamsConfig := psKernelOpenSimpleHeaderParams_configuration_refines
    fuel decl.numParams hNative hString sorted.2 first.type paramResult
    hSortedConfig hParams
  have hParamEnv : paramResult.session.context.environment = environment :=
    hParamsConfig.2.1.trans hSortedEnv
  have hRemainingHistory := psKernelOpenSimpleMutualRemainingTypesWorker_header_history
    remaining fuel environment decl.levelParams
      (if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef
       else PsKernelDefinitionSafety.safe)
      maxRecDepth maxNatSize paramResult.session paramResult.binders
      resultLevel tailShapes hIndex hParamsConfig.1 hParamEnv
      hNative hString hTail
  let shapes : List PsKernelSimpleMutualTypeShape :=
    PsKernelSimpleMutualTypeShape.mk first indexResult.binders :: tailShapes
  have hShapeDecls : shapes.map PsKernelSimpleMutualTypeShape.decl = decl.types := by
    rw [hTypes]
    simpa [shapes] using congrArg (List.cons first) hRemainingHistory.shape_provenance
  have hPrepared := psKernelPreparedMutualConstructorInputs_for_source_shapes
    fuel environment result decl maxRecDepth maxNatSize shapes
    hShapeDecls hIndex hNative hString hRun
  have hCross := psKernelAddSimpleMutualInductive_success_shape_ctor_rec_disjoint
    fuel environment result decl maxRecDepth maxNatSize
    shapes hShapeDecls hIndex hRun
  obtain ⟨added, hHistory, hExt, hFinalIndex, hReserved, hAdded, hQuot, hNames⟩ :=
    psKernelMutualConstructorWorker_prepared_refines
      fuel environment decl shapes paramResult.session resultLevel paramResult.binders
      ctorResult hPrepared hParamsConfig.1 hParamEnv hCross
      hNative hString hCtor
  exact ⟨shapes, paramResult.session, paramResult.binders, resultLevel,
    ctorResult, added, hShapeDecls, hParamsConfig.1, hParamEnv,
    hPrepared, hCtor, hHistory, hExt, hFinalIndex,
    hReserved, hAdded, hQuot, hNames⟩

/--
Every actual independently checked constructor insertion extends authoritative
lookup semantics from the previous work environment. This proof uses the
stored canonical fresh-name witness at each history step and the pre-existing
positive StringEq soundness law; no new type inference is performed.
-/
theorem PsKernelCheckedMutualConstructorHistory.semantic_extension
    (hString : PsKernelStringEqSoundLaw)
    {targets : List PsKernelName} {typeShapes : List PsKernelSimpleMutualTypeShape}
    {levels : List PsKernelLevel} {params : List PsKernelOpenBinder}
    {resultLevel : PsKernelLevel} {typeShape : PsKernelSimpleMutualTypeShape}
    {owner : Nat} {levelParams : List PsKernelName}
    {safety : PsKernelDefinitionSafety} {headerLocal : PsKernelLocalContext}
    {work finalEnvironment : PsKernelEnvironment}
    {index : Nat} {ctors : List PsKernelSimpleConstructorDecl}
    {shapes : List PsKernelSimpleMutualConstructorShape}
    (hHistory : PsKernelCheckedMutualConstructorHistory
      targets typeShapes levels params resultLevel typeShape owner
      levelParams safety headerLocal work index ctors shapes finalEnvironment) :
    PsKernelEnvironmentSemanticExtends work finalEnvironment := by
  induction hHistory with
  | done work index =>
      exact PsKernelEnvironmentSemanticExtends.refl work
  | step work index ctor rest tailShapes finalEnvironment inferredType level
      fields recursiveFields indices hFresh hTyped hSort hOpen hTail ih =>
      let added := PsKernelConstantInfo.ctorInfo
        (PsKernelConstructorInfo.mk
          (PsKernelConstantBase.mk ctor.name levelParams ctor.type)
          typeShape.decl.name index (psKernelOpenBinderListLength params)
          (psKernelOpenBinderListLength fields)
          (psKernelDefinitionSafetyIsUnsafe safety))
      have hStep := psKernelEnvironmentAddUnchecked_fresh_semantic_extends
        work added hString (by
          simpa [added, psKernelConstantInfoName, psKernelConstantInfoBase] using hFresh)
      exact PsKernelEnvironmentSemanticExtends.trans work
        (psKernelEnvironmentAddUnchecked work added)
        finalEnvironment hStep ih

/--
A checked family constructor history semantically extends its starting
environment through every owner and constructor. The result provides the
provisional metadata lookup transport required before replacing inductive
flags; the source environment itself is not reinterpreted.
-/
theorem PsKernelCheckedMutualFamilyConstructorHistory.semantic_extension
    (hString : PsKernelStringEqSoundLaw)
    {targets : List PsKernelName} {allShapes : List PsKernelSimpleMutualTypeShape}
    {levels : List PsKernelLevel} {params : List PsKernelOpenBinder}
    {resultLevel : PsKernelLevel} {levelParams : List PsKernelName}
    {safety : PsKernelDefinitionSafety} {headerLocal : PsKernelLocalContext}
    {work finalEnvironment : PsKernelEnvironment} {owner : Nat}
    {types : List PsKernelSimpleMutualTypeShape}
    {shapes : List PsKernelSimpleMutualConstructorShape}
    (hHistory : PsKernelCheckedMutualFamilyConstructorHistory targets allShapes
      levels params resultLevel levelParams safety headerLocal
      work owner types shapes finalEnvironment) :
    PsKernelEnvironmentSemanticExtends work finalEnvironment := by
  induction hHistory with
  | done work owner =>
      exact PsKernelEnvironmentSemanticExtends.refl work
  | step work ownEnvironment finalEnvironment owner shape rest ownShapes tailShapes
      hOwner hOwn hTail ih =>
      exact PsKernelEnvironmentSemanticExtends.trans work ownEnvironment
        finalEnvironment (hOwn.semantic_extension hString) ih
