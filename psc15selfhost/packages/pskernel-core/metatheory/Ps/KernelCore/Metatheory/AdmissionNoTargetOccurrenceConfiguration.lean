import Ps.KernelCore.Metatheory.Comparator
import Ps.KernelCore.Admission.Inductive.Common.Occurrence

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
      trivial
  | fvar name =>
      intro _
      trivial
  | mvar name =>
      intro _
      trivial
  | sort level =>
      intro _
      trivial
  | const name levels =>
      intro hAbsent
      have hName :
          psKernelNameEq name target = false := by
        simpa [psKernelExprContainsConst] using hAbsent
      exact
        psKernelNameEq_false_ne_of_string_reflexive
          hString name target hName
  | app fn arg ihFn ihArg =>
      intro hAbsent
      cases hFn : psKernelExprContainsConst target fn with
      | true =>
          simp [psKernelExprContainsConst, hFn] at hAbsent
      | false =>
          have hArg :
              psKernelExprContainsConst target arg = false := by
            simpa [psKernelExprContainsConst, hFn] using hAbsent
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
              exact ⟨ihType hType, ihValue hValue, ihBody hBody⟩
  | lit literal =>
      intro _
      trivial
  | mdata metadata body ihBody =>
      intro hAbsent
      exact
        ihBody
          (by simpa [psKernelExprContainsConst] using hAbsent)
  | proj typeName index body ihBody =>
      intro hAbsent
      cases hName : psKernelNameEq typeName target with
      | true =>
          simp [psKernelExprContainsConst, hName] at hAbsent
      | false =>
          have hBody :
              psKernelExprContainsConst target body = false := by
            simpa [psKernelExprContainsConst, hName] using hAbsent
          exact
            ⟨psKernelNameEq_false_ne_of_string_reflexive
              hString typeName target hName,
             ihBody hBody⟩
