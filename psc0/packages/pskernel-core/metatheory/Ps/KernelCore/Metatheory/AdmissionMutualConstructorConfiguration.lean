import Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops
import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration

/-
Mutual constructor admission has two structural loops: constructors inside
one inductive type, then types inside the mutual family.  This file
composes the authoritative environment-index invariant across both, using
only successfully checked branches and the already proved general insertion
law.  No assumption is made about hash buckets or the shape of the index.

This is a necessary transaction invariant; positivity, recursor generation,
and final semantic admission are separately verified obligations.
-/

theorem psKernelAddSimpleMutualConstructorsForTypeWorker_index_refines
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
      psKernelAddSimpleMutualConstructorsForTypeWorker
          ctors fuel safety resultLevel levels params
          typeNames typeShapes typeShape owner
          headerSession work ctorIndex =
        Except.ok result ->
      PsKernelEnvironmentIndexRefines result.environment := by
  induction ctors with
  | nil =>
      intro fuel safety resultLevel levels params typeNames
        typeShapes typeShape owner headerSession work ctorIndex
        result hIndex hRun
      simp [psKernelAddSimpleMutualConstructorsForTypeWorker] at hRun
      cases hRun
      exact hIndex
  | cons ctor rest ih =>
      intro fuel safety resultLevel levels params typeNames
        typeShapes typeShape owner headerSession work ctorIndex
        result hIndex hRun
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
                                          have hTailIndex :=
                                            ih fuel safety resultLevel levels
                                              params typeNames typeShapes
                                              typeShape owner headerSession
                                              nextWork (Nat.succ ctorIndex)
                                              tailResult hNext hTail
                                          cases hRun
                                          exact hTailIndex


theorem psKernelAddSimpleMutualTypesWorker_index_refines
    (types : List PsKernelSimpleMutualTypeShape) :
    ∀ (fuel : Nat)
      (safety : PsKernelDefinitionSafety)
      (resultLevel : PsKernelLevel)
      (levels : List PsKernelLevel)
      (params : List PsKernelOpenBinder)
      (typeNames : List PsKernelName)
      (allShapes : List PsKernelSimpleMutualTypeShape)
      (headerSession : PsKernelCheckerSession)
      (work : PsKernelEnvironment)
      (owner : Nat)
      (result : PsKernelAddMutualConstructorsResult),
      PsKernelEnvironmentIndexRefines work ->
      psKernelAddSimpleMutualTypesWorker
          types fuel safety resultLevel levels params
          typeNames allShapes headerSession work owner =
        Except.ok result ->
      PsKernelEnvironmentIndexRefines result.environment := by
  induction types with
  | nil =>
      intro fuel safety resultLevel levels params typeNames
        allShapes headerSession work owner result hIndex hRun
      simp [psKernelAddSimpleMutualTypesWorker] at hRun
      cases hRun
      exact hIndex
  | cons typeShape rest ih =>
      intro fuel safety resultLevel levels params typeNames
        allShapes headerSession work owner result hIndex hRun
      simp only [psKernelAddSimpleMutualTypesWorker] at hRun
      cases hOwn :
          psKernelAddSimpleMutualConstructorsForTypeWorker
            typeShape.decl.ctors fuel safety resultLevel
            levels params typeNames allShapes typeShape owner
            headerSession work 0 with
      | error error =>
          simp only [hOwn] at hRun
          cases hRun
      | ok ownResult =>
          simp only [hOwn] at hRun
          have hOwnIndex :=
            psKernelAddSimpleMutualConstructorsForTypeWorker_index_refines
              typeShape.decl.ctors fuel safety resultLevel levels
              params typeNames allShapes typeShape owner
              headerSession work 0 ownResult hIndex hOwn
          cases hRest :
              psKernelAddSimpleMutualTypesWorker rest
                fuel safety resultLevel levels params typeNames
                allShapes headerSession ownResult.environment
                (Nat.succ owner) with
          | error error =>
              simp only [hRest] at hRun
              cases hRun
          | ok tailResult =>
              simp only [hRest] at hRun
              have hTailIndex :=
                ih fuel safety resultLevel levels params typeNames
                  allShapes headerSession ownResult.environment
                  (Nat.succ owner) tailResult hOwnIndex hRest
              cases hRun
              exact hTailIndex
