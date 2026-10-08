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
