import RegularValidation
import Ps.MinKernel.Profile.OperationalProfile

namespace Ps.MinKernel.OperationalFoundation
open Ps.MinKernel.RegularModel

noncomputable def primitiveValue (data : List Type) (primitive : PsMinOpPrimitive) :
    Denote data (psMinOpPrimitiveSignature primitive) :=
  match primitive with
  | .natSucc => Nat.succ
  | .natPred => Nat.pred
  | .natAdd => Nat.add
  | .natSub => Nat.sub
  | .natBeq => Nat.beq
  | .natBlt => Nat.blt
  | .boolNot => Bool.not
  | .boolBeq => fun (left right : Bool) => left == right
  | .natRec result => fun zero step major =>
    Nat.rec (motive := fun _ => Denote data result) zero step major
  | .listNil _ => []
  | .listCons _ => List.cons
  | .listRec element result => fun nil cons major =>
    List.rec (motive := fun _ => Denote data result) nil cons major
  | .optionNone _ => none
  | .optionSome _ => some
  | .optionRec _ _ => fun none some major =>
    match major with | .none => none | .some value => some value
  | .boolEqIte result => fun left right yes no =>
    @ite (Denote data result) (left = right) (Bool.decEq left right) yes no

theorem primitiveType_signature (fuel bound : Nat) (primitive : PsMinOpPrimitive)
    (level parameters indices motives minors : Nat) (type : PsMinRegTy)
    (h : psMinOpPrimitiveType fuel bound primitive level parameters indices motives minors = some type) :
    type = psMinOpPrimitiveSignature primitive := by
  unfold psMinOpPrimitiveType at h
  repeat' split at h
  all_goals simp_all

theorem primitiveType_guards (fuel bound : Nat) (primitive : PsMinOpPrimitive)
    (level parameters indices motives minors : Nat) (type : PsMinRegTy)
    (h : psMinOpPrimitiveType fuel bound primitive level parameters indices motives minors = some type) :
    level = psMinOpPrimitiveLevel primitive ∧ parameters = psMinOpPrimitiveParameters primitive ∧
    indices = 0 ∧ motives = psMinOpPrimitiveMotives primitive ∧
    minors = psMinOpPrimitiveMinors primitive ∧ psMinOpPrimitiveCodesValid fuel bound primitive = true := by
  unfold psMinOpPrimitiveType at h
  repeat' split at h
  all_goals simp_all [Nat.beq_eq]

noncomputable def primitiveModel (data : List Type) (fuel bound : Nat) (primitive : PsMinOpPrimitive)
    (level parameters indices motives minors : Nat) (type : PsMinRegTy)
    (h : psMinOpPrimitiveType fuel bound primitive level parameters indices motives minors = some type) :
    Denote data type :=
  cast (congrArg (Denote data) (primitiveType_signature _ _ _ _ _ _ _ _ _ h)).symm
    (primitiveValue data primitive)

theorem nat_iota_zero (data : List Type) (result : PsMinRegTy) (zero : Denote data result)
    (step : Nat → Denote data result → Denote data result) :
    primitiveValue data (.natRec result) zero step (0 : Nat) = zero := rfl

theorem nat_iota_succ (data : List Type) (result : PsMinRegTy) (zero : Denote data result)
    (step : Nat → Denote data result → Denote data result) (major : Nat) :
    primitiveValue data (.natRec result) zero step (Nat.succ major) =
      step major (primitiveValue data (.natRec result) zero step major) := rfl

theorem list_iota_nil (data : List Type) (element result : PsMinRegTy) (nil : Denote data result)
    (cons : Denote data element → List (Denote data element) → Denote data result → Denote data result) :
    primitiveValue data (.listRec element result) nil cons [] = nil := rfl

theorem list_iota_cons (data : List Type) (element result : PsMinRegTy) (nil : Denote data result)
    (cons : Denote data element → List (Denote data element) → Denote data result → Denote data result)
    (head : Denote data element) (tail : List (Denote data element)) :
    primitiveValue data (.listRec element result) nil cons (head :: tail) =
      cons head tail (primitiveValue data (.listRec element result) nil cons tail) := rfl

theorem option_iota_none (data : List Type) (element result : PsMinRegTy) (none : Denote data result)
    (some : Denote data element → Denote data result) :
    primitiveValue data (.optionRec element result) none some Option.none = none := rfl

theorem option_iota_some (data : List Type) (element result : PsMinRegTy) (none : Denote data result)
    (some : Denote data element → Denote data result) (value : Denote data element) :
    primitiveValue data (.optionRec element result) none some (Option.some value) = some value := rfl

-- This schema fixes BOTH proposition and decision to the same Bool pair.
-- There is no arbitrary erased proof/decision argument in its normalized API.
theorem boolEqIte_exact (data : List Type) (result : PsMinRegTy) (left right : Bool)
    (yes no : Denote data result) :
    primitiveValue data (.boolEqIte result) left right yes no =
      @ite (Denote data result) (Eq left right) (Bool.decEq left right) yes no := rfl

theorem boolEqIte_true (data : List Type) (result : PsMinRegTy) (value : Bool)
    (yes no : Denote data result) :
    primitiveValue data (.boolEqIte result) value value yes no = yes := by
  cases value <;> rfl

theorem boolEqIte_false (data : List Type) (result : PsMinRegTy) (left right : Bool)
    (h : left ≠ right) (yes no : Denote data result) :
    primitiveValue data (.boolEqIte result) left right yes no = no := by
  cases left <;> cases right <;> first | exact False.elim (h rfl) | rfl

#print axioms primitiveType_guards
#print axioms primitiveModel
#print axioms nat_iota_succ
#print axioms list_iota_cons
#print axioms option_iota_some
#print axioms boolEqIte_exact
#print axioms boolEqIte_true
#print axioms boolEqIte_false
end Ps.MinKernel.OperationalFoundation
