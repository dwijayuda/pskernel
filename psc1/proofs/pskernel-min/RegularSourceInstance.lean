import RegularValidation
import RegularNames
import BinderLowering
import Ps.MinKernel.Check
import Ps.MinKernel.Tests.RegularVectors

namespace Ps.MinKernel.RegularSource
open Ps.MinKernel.RegularModel Ps.MinKernel.RegularProofs

noncomputable def sourceSignature : SignatureModel [psMinRegTySpec] [PsMinTy] := by
  constructor
  · intro slot index type h
    cases slot with
    | succ slot => simp [psMinRegCtorTypeAt] at h
    | zero =>
      cases index with
      | zero =>
        have ht : PsMinRegTy.data 0 = type := by simpa [psMinRegCtorTypeAt, psMinRegTySpec, psMinRegMakeSpec, psMinRegCtorAt, psMinRegFieldArrow] using h
        cases ht
        exact PsMinTy.empty
      | succ index =>
        cases index with
        | zero =>
          have ht : PsMinRegTy.data 0 = type := by simpa [psMinRegCtorTypeAt, psMinRegTySpec, psMinRegMakeSpec, psMinRegCtorAt, psMinRegFieldArrow] using h
          cases ht
          exact PsMinTy.unit
        | succ index =>
          cases index with
          | zero =>
            have ht : PsMinRegTy.data 0 = type := by simpa [psMinRegCtorTypeAt, psMinRegTySpec, psMinRegMakeSpec, psMinRegCtorAt, psMinRegFieldArrow] using h
            cases ht
            exact PsMinTy.nat
          | succ index =>
            cases index with
            | zero =>
              have ht : PsMinRegTy.arr (PsMinRegTy.data 0) (PsMinRegTy.arr (PsMinRegTy.data 0) (PsMinRegTy.data 0)) = type := by
                simpa [psMinRegCtorTypeAt, psMinRegTySpec, psMinRegMakeSpec, psMinRegCtorAt, psMinRegFieldArrow] using h
              cases ht
              exact PsMinTy.arr
            | succ index => simp [psMinRegCtorTypeAt, psMinRegTySpec, psMinRegMakeSpec, psMinRegCtorAt] at h
  · intro fuel slot sortLevel parameters indices motives minors result type h
    cases slot with
    | succ slot => simp [psMinRegRecursorTypeAt] at h
    | zero =>
      by_cases allowed : psMinRegRecursorAllowed fuel 1 psMinRegTySpec sortLevel parameters indices motives minors result = true
      · have ht : psMinRegRecursorTy result psMinRegTySpec.constructors = type := by
          simpa [psMinRegRecursorTypeAt, psMinRegSpecCount, allowed] using h
        cases ht
        change Denote [PsMinTy] result → Denote [PsMinTy] result → Denote [PsMinTy] result →
          (PsMinTy → PsMinTy → Denote [PsMinTy] result → Denote [PsMinTy] result → Denote [PsMinTy] result) →
          PsMinTy → Denote [PsMinTy] result
        exact fun empty unit nat arr major => PsMinTy.rec (motive := fun _ => Denote [PsMinTy] result)
          empty unit nat arr major
      · simp [psMinRegRecursorTypeAt, psMinRegSpecCount, allowed] at h

theorem source_instance_checked :
    psMinRegInfer 128 [psMinRegTySpec] [] [PsMinRegTy.data 0] psMinRegTyInstance = some PsMinRegTy.boolean := by
  rfl

noncomputable def checkedValue (major : PsMinTy) : Bool :=
  inferModel 128 [psMinRegTySpec] [PsMinTy] [] [PsMinRegTy.data 0] psMinRegTyInstance PsMinRegTy.boolean
    sourceSignature (emptyModel [PsMinTy]) (consModel [PsMinTy] major (emptyModel [PsMinTy])) source_instance_checked

noncomputable def actualRecursorValue (major : PsMinTy) : Bool :=
  PsMinTy.rec (motive := fun _ => Bool) false false true (fun _ _ _ _ => false) major

theorem checked_source_semantics (major : PsMinTy) : checkedValue major = actualRecursorValue major := by
  cases major <;> simp only [checkedValue, inferModel, sourceSignature] <;> rfl

theorem source_iota (major : PsMinTy) : actualRecursorValue major =
    (match major with | .nat => true | _ => false) := by
  cases major <;> rfl

private def root (text : String) : PsName := PsName.str PsName.anonymous text
private def sourceType : PsExpr := PsExpr.constE (root "PsMinTy") []
def sourceBool : PsExpr := PsExpr.constE (root "Bool") []
private def boolValue (value : Bool) : PsExpr :=
  PsExpr.constE (PsName.str (root "Bool") (if value then "true" else "false")) []

def sourceMotive : PsExpr := PsExpr.lam (root "_match") sourceType sourceBool PsBinderInfo.explicit

def sourceArrMinor : PsExpr :=
  PsExpr.lam (root "_wild0") sourceType
    (PsExpr.lam (root "_wild1") sourceType
      (PsExpr.lam (PsName.num (root "_ih") 0) sourceBool
        (PsExpr.lam (PsName.num (root "_ih") 1) sourceBool (boolValue false) PsBinderInfo.explicit)
        PsBinderInfo.explicit) PsBinderInfo.explicit) PsBinderInfo.explicit

-- Exact observed Core shape. CI checks occurrence in current source admissions;
-- this witness is never consulted by the runtime checker to grant acceptance.
def sourceCoreInstance : PsExpr :=
  PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app (PsExpr.app
    (PsExpr.constE (PsName.str (root "PsMinTy") "rec") [PsLevel.succ PsLevel.zero])
    sourceMotive) (boolValue false)) (boolValue false)) (boolValue true)) sourceArrMinor) (PsExpr.bvar 0)

theorem source_motive_lowered : psMinLowerUnusedBinder 0 sourceBool = some sourceBool := by rfl

theorem source_motive_instantiation (major : PsExpr) : psExprInstantiate1 sourceBool major = sourceBool :=
  Ps.MinKernel.BinderLowering.lower_motive_body sourceBool sourceBool major source_motive_lowered


-- A small typed model for the exact source-image fragment used by this witness.
-- This is not a decoder for arbitrary canonical input or source environments.
inductive SourceAnnotation : PsMinRegTy → PsExpr → Prop where
  | data : SourceAnnotation (PsMinRegTy.data 0) sourceType
  | boolean : SourceAnnotation PsMinRegTy.boolean sourceBool

def sourcePartialRecursor : PsExpr :=
  PsExpr.app (PsExpr.constE (PsName.str (root "PsMinTy") "rec") [PsLevel.succ PsLevel.zero]) sourceMotive

noncomputable def sourceRecursorFunction : Denote [PsMinTy] (psMinRegRecursorTy PsMinRegTy.boolean psMinRegTySpec.constructors) :=
  fun empty unit nat arr major => PsMinTy.rec (motive := fun _ => Bool) empty unit nat arr major

inductive CoreEval : (locals : List PsMinRegTy) → Model [PsMinTy] locals →
    PsExpr → (type : PsMinRegTy) → Denote [PsMinTy] type → Prop where
  | var {locals : List PsMinRegTy} (model : Model [PsMinTy] locals) (index : Nat) (type : PsMinRegTy)
      (h : psMinRegLookup locals index = some type) :
      CoreEval locals model (PsExpr.bvar index) type (model index type h)
  | boolean {locals : List PsMinRegTy} (model : Model [PsMinTy] locals) (value : Bool) :
      CoreEval locals model (boolValue value) PsMinRegTy.boolean value
  | recursor {locals : List PsMinRegTy} (model : Model [PsMinTy] locals)
      (motiveLaw : (major : PsExpr) → psExprInstantiate1 sourceBool major = sourceBool) :
      CoreEval locals model sourcePartialRecursor
        (psMinRegRecursorTy PsMinRegTy.boolean psMinRegTySpec.constructors) sourceRecursorFunction
  | lam {locals : List PsMinRegTy} {model : Model [PsMinTy] locals}
      {domain result : PsMinRegTy} {annotation body : PsExpr} {name : PsName}
      {fn : Denote [PsMinTy] domain → Denote [PsMinTy] result}
      (annotationLaw : SourceAnnotation domain annotation)
      (bodyLaw : (value : Denote [PsMinTy] domain) →
        CoreEval (domain :: locals) (consModel [PsMinTy] value model) body result (fn value)) :
      CoreEval locals model (PsExpr.lam name annotation body PsBinderInfo.explicit)
        (PsMinRegTy.arr domain result) fn
  | app {locals : List PsMinRegTy} {model : Model [PsMinTy] locals}
      {domain result : PsMinRegTy} {fn argument : PsExpr}
      {fnValue : Denote [PsMinTy] domain → Denote [PsMinTy] result}
      {argumentValue : Denote [PsMinTy] domain}
      (fnLaw : CoreEval locals model fn (PsMinRegTy.arr domain result) fnValue)
      (argumentLaw : CoreEval locals model argument domain argumentValue) :
      CoreEval locals model (PsExpr.app fn argument) result (fnValue argumentValue)

theorem actual_core_instance_model (major : PsMinTy) :
    CoreEval [PsMinRegTy.data 0] (consModel [PsMinTy] major (emptyModel [PsMinTy]))
      sourceCoreInstance PsMinRegTy.boolean (actualRecursorValue major) := by
  let model : Model [PsMinTy] [PsMinRegTy.data 0] :=
    consModel [PsMinTy] (type := PsMinRegTy.data 0) major (emptyModel [PsMinTy])
  have arr : CoreEval [PsMinRegTy.data 0] model sourceArrMinor
      (psMinRegMinorTy PsMinRegTy.boolean [PsMinRegField.recursive, PsMinRegField.recursive])
      (fun (_ _ : PsMinTy) (_ _ : Bool) => false) := by
    apply CoreEval.lam SourceAnnotation.data
    intro left
    apply CoreEval.lam SourceAnnotation.data
    intro right
    apply CoreEval.lam SourceAnnotation.boolean
    intro leftIH
    apply CoreEval.lam SourceAnnotation.boolean
    intro rightIH
    exact CoreEval.boolean _ false
  have majorLaw : CoreEval [PsMinRegTy.data 0] model (PsExpr.bvar 0) (PsMinRegTy.data 0) major :=
    CoreEval.var model 0 (PsMinRegTy.data 0) rfl
  exact CoreEval.app
    (CoreEval.app
      (CoreEval.app
        (CoreEval.app
          (CoreEval.app (CoreEval.recursor model source_motive_instantiation) (CoreEval.boolean model false))
          (CoreEval.boolean model false))
        (CoreEval.boolean model true)) arr) majorLaw

theorem checked_instance_core_model (major : PsMinTy) :
    CoreEval [PsMinRegTy.data 0] (consModel [PsMinTy] major (emptyModel [PsMinTy]))
      sourceCoreInstance PsMinRegTy.boolean (checkedValue major) := by
  rw [checked_source_semantics]
  exact actual_core_instance_model major

#print axioms source_instance_checked
#print axioms checked_source_semantics
#print axioms source_iota
#print axioms source_motive_instantiation
#print axioms actual_core_instance_model
#print axioms checked_instance_core_model

end Ps.MinKernel.RegularSource
