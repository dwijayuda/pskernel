import Ps.KernelCore.Metatheory.AdmissionNoTargetOccurrenceConfiguration
import Ps.KernelCore.Admission.Inductive.Mutual.Analysis

/-- Negative name membership excludes every actual list element. -/
theorem psKernelNameMember_false_of_mem
    (needle : PsKernelName) (names : List PsKernelName)
    (hAbsent : psKernelNameMember needle names = false) :
    ∀ target : PsKernelName, List.Mem target names ->
      psKernelNameEq needle target = false := by
  revert hAbsent
  induction names with
  | nil =>
      intro hAbsent target hMember
      cases hMember
  | cons head tail ih =>
      intro hAbsent target hMember
      cases hHead : psKernelNameEq needle head with
      | true => simp [psKernelNameMember, hHead] at hAbsent
      | false =>
          have hTail : psKernelNameMember needle tail = false := by
            simpa [psKernelNameMember, hHead] using hAbsent
          cases hMember with
          | head => exact hHead
          | tail => exact ih hTail target (by assumption)

/--
Mutual negative occurrence checking establishes independent structural absence
for every family member, including projection type names. As in the ordinary
case, comparator reflexivity remains a named unresolved conditional premise.
-/
theorem psKernelSimpleMutualContainsConstWorker_false_refines_absence
    (hString : PsKernelStringEqReflexiveLaw)
    (targets : List PsKernelName)
    (target : PsKernelName)
    (hMember : List.Mem target targets) :
    ∀ expr : PsKernelExpr,
      psKernelSimpleMutualContainsConstWorker expr targets = false ->
        PsKernelNoTargetConstantOccurrence target expr := by
  intro expr
  induction expr with
  | bvar index =>
      intro _
      simp [PsKernelNoTargetConstantOccurrence]
  | fvar name =>
      intro _
      simp [PsKernelNoTargetConstantOccurrence]
  | mvar name =>
      intro _
      simp [PsKernelNoTargetConstantOccurrence]
  | sort level =>
      intro _
      simp [PsKernelNoTargetConstantOccurrence]
  | const name levels =>
      intro hAbsent
      have hName :
          psKernelNameEq name target = false := by
        exact psKernelNameMember_false_of_mem name targets hAbsent target hMember
      simpa only [PsKernelNoTargetConstantOccurrence] using
        (psKernelNameEq_false_ne_of_string_reflexive
          hString name target hName)
  | app fn arg ihFn ihArg =>
      intro hAbsent
      cases hFn : psKernelSimpleMutualContainsConstWorker fn targets with
      | true =>
          simp [psKernelSimpleMutualContainsConstWorker, hFn] at hAbsent
      | false =>
          have hArg :
              psKernelSimpleMutualContainsConstWorker arg targets = false := by
            simpa [psKernelSimpleMutualContainsConstWorker, hFn] using hAbsent
          simp only [PsKernelNoTargetConstantOccurrence]
          exact ⟨ihFn hFn, ihArg hArg⟩
  | lam name type body binderInfo ihType ihBody =>
      intro hAbsent
      cases hType : psKernelSimpleMutualContainsConstWorker type targets with
      | true =>
          simp [psKernelSimpleMutualContainsConstWorker, hType] at hAbsent
      | false =>
          have hBody :
              psKernelSimpleMutualContainsConstWorker body targets = false := by
            simpa [psKernelSimpleMutualContainsConstWorker, hType] using hAbsent
          simp only [PsKernelNoTargetConstantOccurrence]
          exact ⟨ihType hType, ihBody hBody⟩
  | forallE name type body binderInfo ihType ihBody =>
      intro hAbsent
      cases hType : psKernelSimpleMutualContainsConstWorker type targets with
      | true =>
          simp [psKernelSimpleMutualContainsConstWorker, hType] at hAbsent
      | false =>
          have hBody :
              psKernelSimpleMutualContainsConstWorker body targets = false := by
            simpa [psKernelSimpleMutualContainsConstWorker, hType] using hAbsent
          simp only [PsKernelNoTargetConstantOccurrence]
          exact ⟨ihType hType, ihBody hBody⟩
  | letE name type value body nondep ihType ihValue ihBody =>
      intro hAbsent
      cases hType : psKernelSimpleMutualContainsConstWorker type targets with
      | true =>
          simp [psKernelSimpleMutualContainsConstWorker, hType] at hAbsent
      | false =>
          cases hValue :
              psKernelSimpleMutualContainsConstWorker value targets with
          | true =>
              simp [psKernelSimpleMutualContainsConstWorker, hType, hValue] at hAbsent
          | false =>
              have hBody :
                  psKernelSimpleMutualContainsConstWorker body targets = false := by
                simpa [
                  psKernelSimpleMutualContainsConstWorker, hType, hValue
                ] using hAbsent
              simp only [PsKernelNoTargetConstantOccurrence]
              exact ⟨ihType hType, ihValue hValue, ihBody hBody⟩
  | lit literal =>
      intro _
      simp [PsKernelNoTargetConstantOccurrence]
  | mdata metadata body ihBody =>
      intro hAbsent
      simpa only [PsKernelNoTargetConstantOccurrence] using
        (ihBody
          (by simpa [psKernelSimpleMutualContainsConstWorker] using hAbsent))
  | proj typeName index body ihBody =>
      intro hAbsent
      cases hName : psKernelNameMember typeName targets with
      | true =>
          simp [psKernelSimpleMutualContainsConstWorker, hName] at hAbsent
      | false =>
          have hBody :
              psKernelSimpleMutualContainsConstWorker body targets = false := by
            simpa [psKernelSimpleMutualContainsConstWorker, hName] using hAbsent
          simp only [PsKernelNoTargetConstantOccurrence]
          exact
            ⟨psKernelNameEq_false_ne_of_string_reflexive
              hString typeName target
                (psKernelNameMember_false_of_mem typeName targets hName target hMember),
             ihBody hBody⟩

theorem psKernelSimpleMutualContainsConst_false_refines_absence
    (hReflexive : PsKernelStringEqReflexiveLaw)
    (targets : List PsKernelName) (target : PsKernelName)
    (hMember : List.Mem target targets) (expr : PsKernelExpr)
    (hAbsent : psKernelSimpleMutualContainsConst targets expr = false) :
    PsKernelNoTargetConstantOccurrence target expr :=
  psKernelSimpleMutualContainsConstWorker_false_refines_absence
    hReflexive targets target hMember expr hAbsent

theorem psKernelSimpleMutualIndicesContainTarget_false_refines_absence
    (hReflexive : PsKernelStringEqReflexiveLaw)
    (targets : List PsKernelName) (target : PsKernelName)
    (hMember : List.Mem target targets)
    (indices : List PsKernelExpr)
    (hAbsent : psKernelSimpleMutualIndicesContainTarget targets indices = false) :
    ∀ expr : PsKernelExpr, List.Mem expr indices ->
      PsKernelNoTargetConstantOccurrence target expr := by
  revert hAbsent
  induction indices with
  | nil =>
      intro hAbsent expr hExpr
      cases hExpr
  | cons head tail ih =>
      intro hAbsent expr hExpr
      cases hHead : psKernelSimpleMutualContainsConst targets head with
      | true =>
          simp [psKernelSimpleMutualIndicesContainTarget, hHead] at hAbsent
      | false =>
          have hTail : psKernelSimpleMutualIndicesContainTarget targets tail = false := by
            simpa [psKernelSimpleMutualIndicesContainTarget, hHead] using hAbsent
          cases hExpr with
          | head =>
              exact psKernelSimpleMutualContainsConst_false_refines_absence
                hReflexive targets target hMember head hHead
          | tail =>
              exact ih hTail expr (by assumption)


/-- The selected mutual family ordinal denotes an actual, canonically named shape. -/
theorem psKernelSimpleMutualTargetIndexWorker_refines
    (hString : PsKernelStringEqSoundLaw)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    ∀ (name : PsKernelName) (start target : Nat),
      psKernelSimpleMutualTargetIndexWorker name shapes start = some target ->
      ∃ (offset : Nat) (shape : PsKernelSimpleMutualTypeShape),
        target = start + offset ∧
        psKernelMutualTypeShapeListGet shapes offset = some shape ∧
        name = shape.decl.name := by
  induction shapes with
  | nil =>
      intro name start target hRun
      simp [psKernelSimpleMutualTargetIndexWorker] at hRun
  | cons head tail ih =>
      intro name start target hRun
      cases hName : psKernelNameEq name head.decl.name with
      | true =>
          simp [psKernelSimpleMutualTargetIndexWorker, hName] at hRun
          cases hRun
          exact ⟨0, head, by simp, rfl,
            psKernelNameEq_sound_of_string_law hString name head.decl.name hName⟩
      | false =>
          have hTail : psKernelSimpleMutualTargetIndexWorker name tail
              (Nat.succ start) = some target := by
            simpa [psKernelSimpleMutualTargetIndexWorker, hName] using hRun
          obtain ⟨offset, shape, hTarget, hShape, hCanonical⟩ :=
            ih name (Nat.succ start) target hTail
          refine ⟨Nat.succ offset, shape, ?_, ?_, hCanonical⟩
          · omega
          · simpa [psKernelMutualTypeShapeListGet] using hShape

theorem psKernelSimpleMutualTargetIndex_refines
    (hString : PsKernelStringEqSoundLaw)
    (name : PsKernelName) (shapes : List PsKernelSimpleMutualTypeShape)
    (target : Nat)
    (hRun : psKernelSimpleMutualTargetIndex name shapes = some target) :
    ∃ shape : PsKernelSimpleMutualTypeShape,
      psKernelMutualTypeShapeListGet shapes target = some shape ∧
      name = shape.decl.name := by
  obtain ⟨offset, shape, hTarget, hShape, hCanonical⟩ :=
    psKernelSimpleMutualTargetIndexWorker_refines hString shapes name 0 target hRun
  have hOffset : target = offset := by simpa using hTarget
  exact ⟨shape, by simpa [hOffset] using hShape, hCanonical⟩

/-- Independent canonical mutual application shape with family-wide index exclusion. -/
def PsKernelMutualConstructorApplicationValid
    (targets : List PsKernelName) (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (expr : PsKernelExpr) (info : PsKernelSimpleMutualAppInfo) : Prop :=
  ∃ shape : PsKernelSimpleMutualTypeShape,
    psKernelMutualTypeShapeListGet shapes info.target = some shape ∧
    psKernelExprGetAppFn expr = PsKernelExpr.const shape.decl.name levels ∧
    PsKernelConstructorResultParamPrefix params (psKernelExprGetAppArgs expr) info.indices ∧
    psKernelExprListLength info.indices = psKernelOpenBinderListLength shape.indices ∧
    (∀ target : PsKernelName, List.Mem target targets ->
      ∀ index : PsKernelExpr, List.Mem index info.indices ->
        PsKernelNoTargetConstantOccurrence target index)


theorem psKernelSimpleMutualAppInfo_semantic_shape
    (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw)
    (targets : List PsKernelName) (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
    (expr : PsKernelExpr) (info : PsKernelSimpleMutualAppInfo)
    (hRun : psKernelSimpleMutualAppInfo targets shapes levels params expr = some info) :
    PsKernelMutualConstructorApplicationValid targets shapes levels params expr info := by
  cases hFn : psKernelExprGetAppFn expr with
  | const name foundLevels =>
      cases hLevels : psKernelLevelListEq foundLevels levels with
      | false =>
          simp [psKernelSimpleMutualAppInfo, hFn, hLevels] at hRun
      | true =>
          cases hTarget : psKernelSimpleMutualTargetIndex name shapes with
          | none =>
              simp [psKernelSimpleMutualAppInfo, hFn, hLevels, hTarget] at hRun
          | some target =>
              cases hShape : psKernelMutualTypeShapeListGet shapes target with
              | none =>
                  simp [psKernelSimpleMutualAppInfo, hFn, hLevels, hTarget, hShape] at hRun
              | some shape =>
                  cases hParams : psKernelConsumeSimpleResultParams params
                      (psKernelExprGetAppArgs expr) with
                  | none =>
                      simp [psKernelSimpleMutualAppInfo, hFn, hLevels, hTarget,
                        hShape, hParams] at hRun
                  | some indices =>
                      cases hLength : Nat.beq (psKernelExprListLength indices)
                          (psKernelOpenBinderListLength shape.indices) with
                      | false =>
                          simp [psKernelSimpleMutualAppInfo, hFn, hLevels, hTarget,
                            hShape, hParams, hLength] at hRun
                      | true =>
                          cases hExcluded : psKernelSimpleMutualIndicesContainTarget
                              targets indices with
                          | true =>
                              simp [psKernelSimpleMutualAppInfo, hFn, hLevels, hTarget,
                                hShape, hParams, hLength, hExcluded] at hRun
                          | false =>
                              have hInfo : PsKernelSimpleMutualAppInfo.mk target indices = info := by
                                simpa [psKernelSimpleMutualAppInfo, hFn, hLevels, hTarget,
                                  hShape, hParams, hLength, hExcluded] using hRun
                              cases hInfo
                              obtain ⟨selected, hSelected, hCanonical⟩ :=
                                psKernelSimpleMutualTargetIndex_refines hString name shapes target hTarget
                              have hShapeEq : selected = shape := Option.some.inj
                                (Eq.trans hSelected.symm hShape)
                              subst selected
                              have hLevelsEq := psKernelLevelListEq_sound_of_string_law
                                hString foundLevels levels hLevels
                              refine ⟨shape, hShape, ?_,
                                psKernelConsumeSimpleResultParams_success_refines_prefix
                                  params (psKernelExprGetAppArgs expr) indices hParams,
                                by simpa using hLength, ?_⟩
                              · simpa [hCanonical, hLevelsEq] using hFn
                              · intro member hMember index hIndex
                                exact psKernelSimpleMutualIndicesContainTarget_false_refines_absence
                                  hReflexive targets member hMember indices hExcluded index hIndex
  | _ =>
      simp [psKernelSimpleMutualAppInfo, hFn] at hRun


/--
Every returned recursive-field target is a real family shape and every
returned result index structurally excludes all family names. Traversal fuel
and checker fuel remain independent, as in the executable analyzer.
-/
theorem psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel_indices_refines
    (fuel : Nat) (hString : PsKernelStringEqSoundLaw)
    (hReflexive : PsKernelStringEqReflexiveLaw) :
    ∀ (checkerFuel : Nat) (session : PsKernelCheckerSession)
      (targets : List PsKernelName) (shapes : List PsKernelSimpleMutualTypeShape)
      (levels : List PsKernelLevel) (params : List PsKernelOpenBinder)
      (field : PsKernelOpenBinder) (domain : PsKernelExpr)
      (revArgs : List PsKernelOpenBinder) (applied : PsKernelExpr)
      (result : PsKernelMutualRecursiveArgumentResult)
      (recursive : PsKernelSimpleMutualRecursiveField),
      psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel fuel checkerFuel
        session targets shapes levels params field domain revArgs applied = Except.ok result ->
      result.recursiveInfo = some recursive ->
      recursive.field = field ∧
      ∃ shape : PsKernelSimpleMutualTypeShape,
        psKernelMutualTypeShapeListGet shapes recursive.target = some shape ∧
        psKernelExprListLength recursive.indices = psKernelOpenBinderListLength shape.indices ∧
        (∀ target : PsKernelName, List.Mem target targets ->
          ∀ index : PsKernelExpr, List.Mem index recursive.indices ->
            PsKernelNoTargetConstantOccurrence target index) := by
  induction fuel with
  | zero =>
      intro checkerFuel session targets shapes levels params field domain
        revArgs applied result recursive hRun hInfo
      simp [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel] at hRun
  | succ remaining ih =>
      intro checkerFuel session targets shapes levels params field domain
        revArgs applied result recursive hRun hInfo
      cases hDirect : psKernelSimpleMutualAppInfo targets shapes levels params domain with
      | some direct =>
          have hResult : PsKernelMutualRecursiveArgumentResult.mk session
              (some (PsKernelSimpleMutualRecursiveField.mk field
                (psKernelReverseOpenBinders revArgs) direct.target direct.indices)) = result := by
            simpa [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel, hDirect] using hRun
          cases hResult
          have hRecursive := Option.some.inj hInfo
          cases hRecursive
          obtain ⟨shape, hShape, hHead, hPrefix, hLength, hExcluded⟩ :=
            psKernelSimpleMutualAppInfo_semantic_shape hString hReflexive
              targets shapes levels params domain direct hDirect
          exact ⟨rfl, shape, hShape, hLength, hExcluded⟩
      | none =>
          cases hWhnf : psKernelSessionWhnf checkerFuel session domain with
          | error message =>
              simp [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                hDirect, hWhnf] at hRun
          | ok reduced =>
              cases hApp : psKernelSimpleMutualAppInfo targets shapes levels params reduced.1 with
              | some info =>
                  have hResult : PsKernelMutualRecursiveArgumentResult.mk reduced.2
                      (some (PsKernelSimpleMutualRecursiveField.mk field
                        (psKernelReverseOpenBinders revArgs) info.target info.indices)) = result := by
                    simpa [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                      hDirect, hWhnf, hApp] using hRun
                  cases hResult
                  have hRecursive := Option.some.inj hInfo
                  cases hRecursive
                  obtain ⟨shape, hShape, hHead, hPrefix, hLength, hExcluded⟩ :=
                    psKernelSimpleMutualAppInfo_semantic_shape hString hReflexive
                      targets shapes levels params reduced.1 info hApp
                  exact ⟨rfl, shape, hShape, hLength, hExcluded⟩
              | none =>
                  simp only [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                    hDirect, hWhnf, hApp] at hRun
                  cases hShape : reduced.1 with
                  | forallE userName argDomain body binderInfo =>
                      cases hNegative : psKernelSimpleMutualContainsConst targets argDomain with
                      | true =>
                          simp [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                            hDirect, hWhnf, hApp, hShape, hNegative] at hRun
                      | false =>
                          let opened := psKernelSessionWithLocal reduced.2 userName
                            (psKernelExprConsumeTypeAnnotations argDomain) binderInfo
                          let arg := PsKernelOpenBinder.mk opened.1 userName
                            (psKernelExprConsumeTypeAnnotations argDomain) binderInfo
                          have hTail : psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
                              remaining checkerFuel opened.2 targets shapes levels params field
                              (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                              (arg :: revArgs) (PsKernelExpr.app applied (PsKernelExpr.fvar opened.1)) =
                                Except.ok result := by
                            simpa [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                              hDirect, hWhnf, hApp, hShape, hNegative, opened, arg] using hRun
                          exact ih checkerFuel opened.2 targets shapes levels params field
                            (psKernelExprInstantiate1 body (PsKernelExpr.fvar opened.1))
                            (arg :: revArgs) (PsKernelExpr.app applied (PsKernelExpr.fvar opened.1))
                            result recursive hTail hInfo
                  | _ =>
                      cases hDomain : psKernelSimpleMutualContainsConst targets domain with
                      | true =>
                          simp [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                            hDirect, hWhnf, hApp, hShape, hDomain] at hRun
                      | false =>
                          cases hReduced : psKernelSimpleMutualContainsConst targets reduced.1 with
                          | true =>
                              simp [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                                hDirect, hWhnf, hApp, hShape, hDomain, hReduced] at hRun
                          | false =>
                              have hResult : PsKernelMutualRecursiveArgumentResult.mk reduced.2 none = result := by
                                simpa [psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel,
                                  hDirect, hWhnf, hApp, hShape, hDomain, hReduced] using hRun
                              cases hResult
                              cases hInfo
