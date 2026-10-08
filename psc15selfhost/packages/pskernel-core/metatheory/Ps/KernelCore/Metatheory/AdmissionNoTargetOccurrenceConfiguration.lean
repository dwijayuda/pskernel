import Ps.KernelCore.Metatheory.Comparator
import Ps.KernelCore.Admission.Inductive.Common.Occurrence
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor

/-
Independent, fuel-free structural absence of a named recursive datatype.

An admissible negative-occurrence check must guarantee that the target name
does not occur anywhere that psKernelExprContainsConst traverses, including
projection type names. The proof needs reflexivity/completeness of name
comparison, not merely the one-direction StringEq soundness law used to justify
*positive* equality. This additional premise is explicit and remains a
discharge obligation for final inductive-admission soundness.

This predicate does not by itself prove full strict positivity: positivity
also depends on the field and recursive-argument checking phases.
-/
def PsKernelNoTargetConstantOccurrence
    (target : PsKernelName)
    (expr : PsKernelExpr) : Prop :=
  match expr with
  | PsKernelExpr.const name _ =>
      name ≠ target
  | PsKernelExpr.app fn arg =>
      PsKernelNoTargetConstantOccurrence target fn ∧
        PsKernelNoTargetConstantOccurrence target arg
  | PsKernelExpr.lam _ type body _ =>
      PsKernelNoTargetConstantOccurrence target type ∧
        PsKernelNoTargetConstantOccurrence target body
  | PsKernelExpr.forallE _ type body _ =>
      PsKernelNoTargetConstantOccurrence target type ∧
        PsKernelNoTargetConstantOccurrence target body
  | PsKernelExpr.letE _ type value body _ =>
      PsKernelNoTargetConstantOccurrence target type ∧
        PsKernelNoTargetConstantOccurrence target value ∧
        PsKernelNoTargetConstantOccurrence target body
  | PsKernelExpr.mdata _ body =>
      PsKernelNoTargetConstantOccurrence target body
  | PsKernelExpr.proj typeName _ body =>
      typeName ≠ target ∧
        PsKernelNoTargetConstantOccurrence target body
  | _ => True
termination_by expr

theorem psKernelNameEq_false_ne_of_string_reflexive
    (hString : PsKernelStringEqReflexiveLaw)
    (left right : PsKernelName)
    (hFalse : psKernelNameEq left right = false) :
    left ≠ right := by
  intro hEqual
  subst left
  have hRefl :=
    psKernelNameEq_refl_of_string_law hString right
  rw [hRefl] at hFalse
  cases hFalse

theorem psKernelExprContainsConst_false_refines_absence
    (hString : PsKernelStringEqReflexiveLaw)
    (target : PsKernelName) :
    ∀ expr : PsKernelExpr,
      psKernelExprContainsConst target expr = false ->
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
        simpa [psKernelExprContainsConst] using hAbsent
      simpa only [PsKernelNoTargetConstantOccurrence] using
        (psKernelNameEq_false_ne_of_string_reflexive
          hString name target hName)
  | app fn arg ihFn ihArg =>
      intro hAbsent
      cases hFn : psKernelExprContainsConst target fn with
      | true =>
          simp [psKernelExprContainsConst, hFn] at hAbsent
      | false =>
          have hArg :
              psKernelExprContainsConst target arg = false := by
            simpa [psKernelExprContainsConst, hFn] using hAbsent
          simp only [PsKernelNoTargetConstantOccurrence]
          exact ⟨ihFn hFn, ihArg hArg⟩
  | lam name type body binderInfo ihType ihBody =>
      intro hAbsent
      cases hType : psKernelExprContainsConst target type with
      | true =>
          simp [psKernelExprContainsConst, hType] at hAbsent
      | false =>
          have hBody :
              psKernelExprContainsConst target body = false := by
            simpa [psKernelExprContainsConst, hType] using hAbsent
          simp only [PsKernelNoTargetConstantOccurrence]
          exact ⟨ihType hType, ihBody hBody⟩
  | forallE name type body binderInfo ihType ihBody =>
      intro hAbsent
      cases hType : psKernelExprContainsConst target type with
      | true =>
          simp [psKernelExprContainsConst, hType] at hAbsent
      | false =>
          have hBody :
              psKernelExprContainsConst target body = false := by
            simpa [psKernelExprContainsConst, hType] using hAbsent
          simp only [PsKernelNoTargetConstantOccurrence]
          exact ⟨ihType hType, ihBody hBody⟩
  | letE name type value body nondep ihType ihValue ihBody =>
      intro hAbsent
      cases hType : psKernelExprContainsConst target type with
      | true =>
          simp [psKernelExprContainsConst, hType] at hAbsent
      | false =>
          cases hValue :
              psKernelExprContainsConst target value with
          | true =>
              simp [psKernelExprContainsConst, hType, hValue] at hAbsent
          | false =>
              have hBody :
                  psKernelExprContainsConst target body = false := by
                simpa [
                  psKernelExprContainsConst, hType, hValue
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
          (by simpa [psKernelExprContainsConst] using hAbsent))
  | proj typeName index body ihBody =>
      intro hAbsent
      cases hName : psKernelNameEq typeName target with
      | true =>
          simp [psKernelExprContainsConst, hName] at hAbsent
      | false =>
          have hBody :
              psKernelExprContainsConst target body = false := by
            simpa [psKernelExprContainsConst, hName] using hAbsent
          simp only [PsKernelNoTargetConstantOccurrence]
          exact
            ⟨psKernelNameEq_false_ne_of_string_reflexive
              hString typeName target hName,
             ihBody hBody⟩


/-
A successful result-index occurrence check excludes the recursive target
from every returned index. This requires comparator reflexivity for the
negative branch; positive-comparison soundness alone is insufficient.
-/
theorem psKernelSimpleIndicesContainTarget_false_refines_absence
    (hString : PsKernelStringEqReflexiveLaw)
    (target : PsKernelName) :
    ∀ (indices : List PsKernelExpr),
      psKernelSimpleIndicesContainTarget target indices = false ->
      ∀ (expr : PsKernelExpr),
        List.Mem expr indices ->
          PsKernelNoTargetConstantOccurrence target expr := by
  intro indices
  induction indices with
  | nil =>
      intro _ expr hMember
      cases hMember
  | cons head tail ih =>
      intro hAbsent expr hMember
      cases hHead :
          psKernelExprContainsConst target head with
      | true =>
          simp [
            psKernelSimpleIndicesContainTarget, hHead
          ] at hAbsent
      | false =>
          have hTail :
              psKernelSimpleIndicesContainTarget target tail = false := by
            simpa [
              psKernelSimpleIndicesContainTarget, hHead
            ] using hAbsent
          cases hMember with
          | head =>
              exact
                psKernelExprContainsConst_false_refines_absence
                  hString target head hHead
          | tail =>
              exact ih hTail expr (by assumption)


theorem psKernelValidateSimpleConstructorResult_success_indices_absent
    (hString : PsKernelStringEqReflexiveLaw)
    (target : PsKernelName)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (numIndices : Nat)
    (result : PsKernelExpr)
    (indices : List PsKernelExpr)
    (hSuccess :
      psKernelValidateSimpleConstructorResult
          target levels params numIndices result =
        Except.ok indices) :
    ∀ expr : PsKernelExpr,
      List.Mem expr indices ->
        PsKernelNoTargetConstantOccurrence target expr := by
  cases hIndices :
      psKernelSimpleInductiveAppIndices
        target levels params numIndices result with
  | none =>
      simp [
        psKernelValidateSimpleConstructorResult, hIndices
      ] at hSuccess
  | some actualIndices =>
      cases hContains :
          psKernelSimpleIndicesContainTarget target actualIndices with
      | true =>
          simp [
            psKernelValidateSimpleConstructorResult,
            hIndices, hContains
          ] at hSuccess
      | false =>
          have hIndicesEq : actualIndices = indices := by
            simpa [
              psKernelValidateSimpleConstructorResult,
              hIndices, hContains
            ] using hSuccess
          subst indices
          exact
            psKernelSimpleIndicesContainTarget_false_refines_absence
              hString target actualIndices hContains
