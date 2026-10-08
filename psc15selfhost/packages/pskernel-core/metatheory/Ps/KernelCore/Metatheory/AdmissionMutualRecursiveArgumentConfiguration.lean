import Ps.KernelCore.Metatheory.AdmissionRecursiveArgumentConfiguration
import Ps.KernelCore.Metatheory.AdmissionMutualOccurrenceConfiguration

/--
Fuel-free mutual recursive-argument positivity and exact recursive metadata.
Function domains are structurally nonrecursive; domain typing is supplied by
the separately checked whole constructor-field spine, not by infer-only.
The shape/name correspondence of the supplied family is a separate header
invariant required at full mutual transaction composition.
-/
inductive PsKernelMutualRecursiveArgumentSafe
    (environment : PsKernelEnvironment)
    (targets : List PsKernelName) (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (field : PsKernelOpenBinder) :
    PsKernelLocalContext -> PsKernelExpr -> List PsKernelOpenBinder ->
    PsKernelExpr -> Option PsKernelSimpleMutualRecursiveField -> Prop where
  | nonrecursive (localContext : PsKernelLocalContext)
      (domain reduced applied : PsKernelExpr) (revArgs : List PsKernelOpenBinder)
      (hReduction : PsKernelReductionClosure environment localContext domain reduced)
      (hOriginal : ∀ target : PsKernelName, List.Mem target targets ->
        PsKernelNoTargetConstantOccurrence target domain)
      (hReduced : ∀ target : PsKernelName, List.Mem target targets ->
        PsKernelNoTargetConstantOccurrence target reduced) :
      PsKernelMutualRecursiveArgumentSafe environment targets shapes levels params field
        localContext domain revArgs applied none
  | recursive (localContext : PsKernelLocalContext)
      (domain reduced applied : PsKernelExpr) (revArgs : List PsKernelOpenBinder)
      (info : PsKernelSimpleMutualAppInfo)
      (hReduction : PsKernelReductionClosure environment localContext domain reduced)
      (hApplication : PsKernelMutualConstructorApplicationValid targets shapes levels params reduced info) :
      PsKernelMutualRecursiveArgumentSafe environment targets shapes levels params field
        localContext domain revArgs applied
        (some (PsKernelSimpleMutualRecursiveField.mk field
          (psKernelReverseOpenBinders revArgs) info.target info.indices))
  | function (localContext : PsKernelLocalContext)
      (domain argDomain body applied : PsKernelExpr)
      (userName fresh : PsKernelName) (binderInfo : PsKernelBinderInfo)
      (revArgs : List PsKernelOpenBinder) (info : Option PsKernelSimpleMutualRecursiveField)
      (hReduction : PsKernelReductionClosure environment localContext domain
        (PsKernelExpr.forallE userName argDomain body binderInfo))
      (hDomain : ∀ target : PsKernelName, List.Mem target targets ->
        PsKernelNoTargetConstantOccurrence target argDomain)
      (hFresh : psKernelLocalContextFind localContext fresh = none)
      (hBody : PsKernelMutualRecursiveArgumentSafe environment targets shapes levels params field
        (psKernelLocalContextAddLocal localContext fresh userName
          (psKernelExprConsumeTypeAnnotations argDomain) binderInfo)
        (psKernelExprInstantiate1 body (PsKernelExpr.fvar fresh))
        (PsKernelOpenBinder.mk fresh userName
          (psKernelExprConsumeTypeAnnotations argDomain) binderInfo :: revArgs)
        (PsKernelExpr.app applied (PsKernelExpr.fvar fresh)) info) :
      PsKernelMutualRecursiveArgumentSafe environment targets shapes levels params field
        localContext domain revArgs applied info

theorem psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel_semantic_refines
    (fuel : Nat) (hNative : PsKernelNativeReductionSoundLaw)
    (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw) :
    ∀ (checkerFuel : Nat) (session : PsKernelCheckerSession)
      (targets : List PsKernelName) (shapes : List PsKernelSimpleMutualTypeShape)
      (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
      (field : PsKernelOpenBinder) (domain : PsKernelExpr)
      (revArgs : List PsKernelOpenBinder) (applied : PsKernelExpr)
      (result : PsKernelMutualRecursiveArgumentResult),
      PsKernelCheckerConfigurationSound session.context session.state ->
      psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel fuel checkerFuel
        session targets shapes levels params field domain revArgs applied = Except.ok result ->
      PsKernelMutualRecursiveArgumentSafe session.context.environment
        targets shapes levels params field session.context.localContext domain
        revArgs applied result.recursiveInfo := by
  induction fuel with
  | zero =>
      intro checkerFuel session targets shapes levels params field domain
        revArgs applied result hConfig hRun
      simp [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel] at hRun
  | succ remaining ih =>
      intro checkerFuel session targets shapes levels params field domain
        revArgs applied result hConfig hRun
      cases hDirect : psKernelSimpleMutualAppInfo targets shapes levels params domain with
      | some direct =>
          have hResult : PsKernelMutualRecursiveArgumentResult.mk session
              (some (PsKernelSimpleMutualRecursiveField.mk field
                (psKernelReverseOpenBinders revArgs) direct.target direct.indices)) = result := by
            simpa [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel, hDirect] using hRun
          cases hResult
          exact PsKernelMutualRecursiveArgumentSafe.recursive session.context.localContext
            domain domain applied revArgs direct (PsKernelReductionClosure.refl domain)
            (psKernelSimpleMutualAppInfo_semantic_shape hString hReflexive
              targets shapes levels params domain direct hDirect)
      | none =>
          cases hWhnf : psKernelSessionWhnf checkerFuel session domain with
          | error message =>
              simp [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                hDirect, hWhnf] at hRun
          | ok reduced =>
              have hReducedSound := psKernelSessionWhnf_concrete_refines_reduction
                checkerFuel hNative hString session reduced.2 domain reduced.1 hConfig hWhnf
              have hContext := psKernelSessionWhnf_success_preserves_context_core
                checkerFuel session reduced.2 domain reduced.1 hWhnf
              have hReducedConfig : PsKernelCheckerConfigurationSound
                  reduced.2.context reduced.2.state := by
                simpa [hContext] using hReducedSound.2
              cases hApp : psKernelSimpleMutualAppInfo targets shapes levels params reduced.1 with
              | some info =>
                  have hResult : PsKernelMutualRecursiveArgumentResult.mk reduced.2
                      (some (PsKernelSimpleMutualRecursiveField.mk field
                        (psKernelReverseOpenBinders revArgs) info.target info.indices)) = result := by
                    simpa [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                      hDirect, hWhnf, hApp] using hRun
                  cases hResult
                  exact PsKernelMutualRecursiveArgumentSafe.recursive session.context.localContext
                    domain reduced.1 applied revArgs info hReducedSound.1
                    (psKernelSimpleMutualAppInfo_semantic_shape hString hReflexive
                      targets shapes levels params reduced.1 info hApp)
              | none =>
                  simp only [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                    hDirect, hWhnf, hApp] at hRun
                  cases hShape : reduced.1 with
                  | forallE userName argDomain body binderInfo =>
                      cases hNegative : psKernelSimpleMutualContainsConst targets argDomain with
                      | true => simp [hShape, hNegative] at hRun
                      | false =>
                          let opened := psKernelSessionWithLocal reduced.2 userName
                            (psKernelExprConsumeTypeAnnotations argDomain) binderInfo
                          let arg := PsKernelOpenBinder.mk opened.1 userName
                            (psKernelExprConsumeTypeAnnotations argDomain) binderInfo
                          have hOpenedConfig :=
                            psKernelSessionWithLocal_preserves_configuration reduced.2 userName
                              (psKernelExprConsumeTypeAnnotations argDomain) binderInfo hString hReducedConfig
                          have hTail : psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
                              remaining checkerFuel opened.2 targets shapes levels params field
                              (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                              (arg :: revArgs) (PsKernelExpr.app applied (PsKernelExpr.fvar opened.1)) =
                                Except.ok result := by
                            simpa [hShape, hNegative, opened, arg] using hRun
                          have hBody := ih checkerFuel opened.2 targets shapes levels params field
                            (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                            (arg :: revArgs) (PsKernelExpr.app applied (PsKernelExpr.fvar opened.1))
                            result hOpenedConfig hTail
                          have hFresh := psKernelSessionWithLocal_fresh_absent reduced.2 userName
                            (psKernelExprConsumeTypeAnnotations argDomain) binderInfo hString hReducedConfig
                          refine PsKernelMutualRecursiveArgumentSafe.function
                            session.context.localContext domain argDomain body applied userName opened.1
                            binderInfo revArgs result.recursiveInfo ?_ ?_ ?_ ?_
                          · simpa [hShape] using hReducedSound.1
                          · intro target hMember
                            exact psKernelSimpleMutualContainsConst_false_refines_absence
                              hReflexive targets target hMember argDomain hNegative
                          · simpa [opened, hContext] using hFresh
                          · simpa [opened, arg, psKernelSessionWithLocal,
                              psKernelCheckerContextWithLocalContext, hContext] using hBody
                  | _ =>
                      cases hDomain : psKernelSimpleMutualContainsConst targets domain with
                      | true => simp [hShape, hDomain] at hRun
                      | false =>
                          cases hReduced : psKernelSimpleMutualContainsConst targets reduced.1 with
                          | true =>
                              simp only [hShape] at hReduced
                              simp [hShape, hDomain, hReduced] at hRun
                          | false =>
                              simp only [hShape] at hReduced
                              have hResult : PsKernelMutualRecursiveArgumentResult.mk reduced.2 none = result := by
                                simpa [hShape, hDomain, hReduced] using hRun
                              cases hResult
                              refine PsKernelMutualRecursiveArgumentSafe.nonrecursive
                                session.context.localContext domain _ applied revArgs hReducedSound.1 ?_ ?_
                              · intro target hMember
                                exact psKernelSimpleMutualContainsConst_false_refines_absence
                                  hReflexive targets target hMember domain hDomain
                              · intro target hMember
                                apply psKernelSimpleMutualContainsConst_false_refines_absence
                                  hReflexive targets target hMember
                                simpa [hShape] using hReduced
