import Ps.KernelCore.Admission.Inductive.Ordinary.ConstructorAdmission
import Ps.KernelCore.Metatheory.AdmissionIndexConfiguration

/-
End-to-end authoritative index preservation for the ordinary constructor
admission loop.  Only a successful checked constructor transaction is
considered.  Every constructor is installed through the common unchecked
insert primitive, for which the index-refinement theorem is independent of
the underlying index representation (including root buckets and collisions).

This theorem deliberately proves only the environment-index invariant:
successful constructor checking is not conflated with a complete typing or
positivity/admission soundness theorem.
-/

theorem psKernelAddSimpleConstructorsWithFuel_index_refines
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
      psKernelAddSimpleConstructorsWithFuel
          fuel decl safety resultLevel levels params numIndices
          headerSession work index ctors =
        Except.ok result ->
      PsKernelEnvironmentIndexRefines result.environment := by
  induction fuel with
  | zero =>
      intro decl safety resultLevel levels params numIndices
        headerSession work index ctors result hIndex hRun
      simp [psKernelAddSimpleConstructorsWithFuel] at hRun
  | succ remaining ih =>
      intro decl safety resultLevel levels params numIndices
        headerSession work index ctors result hIndex hRun
      cases ctors with
      | nil =>
          simp [psKernelAddSimpleConstructorsWithFuel] at hRun
          cases hRun
          exact hIndex
      | cons ctor rest =>
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
                  let closedSession :=
                    psKernelMkCheckerSession
                      work decl.levelParams safety
                      headerSession.context.maxRecDepth
                      headerSession.context.maxNatSize
                  cases hType :
                      psKernelSessionCheck
                        remaining closedSession ctor.type with
                  | error error =>
                      simp only [hType] at hRun
                      cases hRun
                  | ok ctorType =>
                      simp only [hType] at hRun
                      cases hSort :
                          psKernelSessionEnsureSort
                            remaining
                            (Prod.snd ctorType)
                            (Prod.fst ctorType) with
                      | error error =>
                          simp only [hSort] at hRun
                          cases hRun
                      | ok sortValue =>
                          simp only [hSort] at hRun
                          let ctorSession :=
                            psKernelSessionWithEnvironment headerSession work
                          cases hParams :
                              psKernelOpenSimpleConstructorParams
                                remaining ctorSession params ctor.type with
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
                                      let ctorInfo :=
                                        PsKernelConstructorInfo.mk
                                          (PsKernelConstantBase.mk
                                            ctor.name decl.levelParams ctor.type)
                                          decl.name
                                          index
                                          decl.numParams
                                          (psKernelOpenBinderListLength
                                            fieldsResult.fields)
                                          decl.isUnsafe
                                      let nextWork :=
                                        psKernelEnvironmentAddUnchecked work
                                          (PsKernelConstantInfo.ctorInfo ctorInfo)
                                      have hNext :
                                          PsKernelEnvironmentIndexRefines nextWork :=
                                        psKernelEnvironmentAddUnchecked_index_refines
                                          work
                                          (PsKernelConstantInfo.ctorInfo ctorInfo)
                                          hIndex
                                      cases hTail :
                                          psKernelAddSimpleConstructorsWithFuel
                                            remaining decl safety resultLevel
                                            levels params numIndices headerSession
                                            nextWork (Nat.succ index) rest with
                                      | error error =>
                                          simp only [hTail] at hRun
                                          cases hRun
                                      | ok tailResult =>
                                          simp only [hTail] at hRun
                                          have hTailIndex :=
                                            ih decl safety resultLevel
                                              levels params numIndices
                                              headerSession nextWork
                                              (Nat.succ index) rest tailResult
                                              hNext hTail
                                          cases hRun
                                          exact hTailIndex
