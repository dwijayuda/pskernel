import RegularValidation
import RegularNames
import BinderLowering
import Ps.MinKernel.Check
import Ps.MinKernel.Tests.RegularVectors

namespace Ps.MinKernel.RegularSource
open Ps.MinKernel.RegularModel Ps.MinKernel.RegularProofs

def sourceSignature : SignatureModel [psMinRegTySpec] [PsMinTy] := by
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
  · intro fuel slot universe parameters indices motives minors result type h
    cases slot with
    | succ slot => simp [psMinRegRecursorTypeAt] at h
    | zero =>
      by_cases allowed : psMinRegRecursorAllowed fuel 1 psMinRegTySpec universe parameters indices motives minors result = true
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

def checkedValue (major : PsMinTy) : Bool :=
  inferModel 128 [psMinRegTySpec] [PsMinTy] [] [PsMinRegTy.data 0] psMinRegTyInstance PsMinRegTy.boolean
    sourceSignature (emptyModel [PsMinTy]) (consModel [PsMinTy] major (emptyModel [PsMinTy])) source_instance_checked

def actualRecursorValue (major : PsMinTy) : Bool :=
  PsMinTy.rec (motive := fun _ => Bool) false false true (fun _ _ _ _ => false) major

theorem checked_source_semantics (major : PsMinTy) : checkedValue major = actualRecursorValue major := by
  cases major <;> rfl

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

#print axioms source_instance_checked
#print axioms checked_source_semantics
#print axioms source_iota
#print axioms source_motive_instantiation

end Ps.MinKernel.RegularSource
