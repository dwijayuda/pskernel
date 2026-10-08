import Ps.KernelCore.Metatheory.AdmissionConstructorTypingConfiguration
import Ps.KernelCore.Metatheory.AdmissionInductiveConstructorConfiguration

/-
Independent, fuel-free checked-header history for an ordinary constructor
bundle. Each admitted constructor is checked in its precise work environment,
then its metadata is appended to that environment before the next constructor
is checked. The history uses authoritative declaration insertion, not a
fictional simultaneous check in the initial environment.

This is *not* yet a positivity or full-inductive-admission theorem: field
analysis, result-index validation and recursor acceptance still require
independent semantic refinement.
-/
inductive PsKernelCheckedConstructorHeaderHistory
    (decl : PsKernelSimpleInductiveDecl) :
    PsKernelEnvironment ->
    Nat ->
    List PsKernelSimpleConstructorDecl ->
    PsKernelEnvironment -> Prop
  | done
      (work : PsKernelEnvironment)
      (index : Nat) :
      PsKernelCheckedConstructorHeaderHistory
        decl work index List.nil work
  | step
      (work : PsKernelEnvironment)
      (index : Nat)
      (ctor : PsKernelSimpleConstructorDecl)
      (rest : List PsKernelSimpleConstructorDecl)
      (finalEnvironment : PsKernelEnvironment)
      (inferredType : PsKernelExpr)
      (level : PsKernelLevel)
      (fields : List PsKernelOpenBinder)
      (hTyped :
        PsKernelTypingJudgment
          work psKernelLocalContextEmpty
          ctor.type inferredType)
      (hSort :
        PsKernelReductionClosure
          work psKernelLocalContextEmpty
          inferredType (PsKernelExpr.sort level))
      (hTail :
        PsKernelCheckedConstructorHeaderHistory
          decl
          (psKernelEnvironmentAddUnchecked
            work
            (PsKernelConstantInfo.ctorInfo
              (PsKernelConstructorInfo.mk
                (PsKernelConstantBase.mk
                  ctor.name decl.levelParams ctor.type)
                decl.name index decl.numParams
                (psKernelOpenBinderListLength fields)
                decl.isUnsafe)))
          (Nat.succ index)
          rest
          finalEnvironment) :
      PsKernelCheckedConstructorHeaderHistory
        decl work index (List.cons ctor rest) finalEnvironment

/-
The executable fuel recursion and the semantic constructor-history spine
agree on successful transactions. Soundness hypotheses flow through each
freshly initialized checked session. Inductive insertion preserves the
authoritative environment-index invariant between stages.
-/
theorem psKernelAddSimpleConstructorsWithFuel_checked_header_history
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
      PsKernelNativeReductionSoundLaw ->
      PsKernelStringEqSoundLaw ->
      psKernelAddSimpleConstructorsWithFuel
          fuel decl safety resultLevel levels params numIndices
          headerSession work index ctors =
        Except.ok result ->
      PsKernelCheckedConstructorHeaderHistory
        decl work index ctors result.environment := by
  induction fuel with
  | zero =>
      intro decl safety resultLevel levels params numIndices
        headerSession work index ctors result hIndex hNative hString hRun
      simp [psKernelAddSimpleConstructorsWithFuel] at hRun
  | succ remaining ih =>
      intro decl safety resultLevel levels params numIndices
        headerSession work index ctors result hIndex hNative hString hRun
      cases ctors with
      | nil =>
          simp [psKernelAddSimpleConstructorsWithFuel] at hRun
          cases hRun
          exact PsKernelCheckedConstructorHeaderHistory.done work index
      | cons ctor rest =>
          obtain ⟨inferredType, level, hTyped, hSort⟩ :=
            psKernelAddSimpleConstructorsWithFuel_success_head_checked
              remaining decl safety resultLevel levels params numIndices
              headerSession work index ctor rest result
              hIndex hNative hString hRun
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
                                          have hRest :
                                              PsKernelCheckedConstructorHeaderHistory
                                                decl nextWork (Nat.succ index)
                                                rest tailResult.environment :=
                                            ih decl safety resultLevel
                                              levels params numIndices
                                              headerSession nextWork
                                              (Nat.succ index) rest tailResult
                                              hNextIndex hNative hString hTail
                                          cases hRun
                                          exact
                                            PsKernelCheckedConstructorHeaderHistory.step
                                              work index ctor rest
                                              tailResult.environment
                                              inferredType level
                                              fieldsResult.fields
                                              hTyped hSort hRest
