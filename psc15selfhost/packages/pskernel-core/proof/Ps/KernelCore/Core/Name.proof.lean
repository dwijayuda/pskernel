import Ps.KernelCore.Metatheory.BootstrapStringObligations
import Ps.KernelCore.Core.Name
import Ps.KernelCore.Metatheory.Comparator

theorem psKernelNameComponentAppend_eq_append
    (left right : List PsKernelNameComponent) :
    psKernelNameComponentAppend left right = List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelNameComponentAppend, ih]

theorem psKernelNameAppend_right_anonymous
    (base : PsKernelName) :
    psKernelNameAppend base PsKernelName.anonymous = base := by
  rfl

theorem psKernelNameAppend_left_anonymous
    (suffix : PsKernelName) :
    psKernelNameAppend PsKernelName.anonymous suffix = suffix := by
  induction suffix with
  | anonymous =>
      rfl
  | str parent value ih =>
      simp [psKernelNameAppend, ih]
  | num parent value ih =>
      simp [psKernelNameAppend, ih]

theorem psKernelNameAppend_assoc
    (a b c : PsKernelName) :
    psKernelNameAppend (psKernelNameAppend a b) c =
      psKernelNameAppend a (psKernelNameAppend b c) := by
  induction c with
  | anonymous =>
      rfl
  | str parent value ih =>
      simp [psKernelNameAppend, ih]
  | num parent value ih =>
      simp [psKernelNameAppend, ih]

theorem psKernelNameComponents_anonymous :
    psKernelNameComponents PsKernelName.anonymous = List.nil := by
  rfl

theorem psKernelNameListLength_eq_length
    (values : List PsKernelName) :
    psKernelNameListLength values = List.length values := by
  induction values with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelNameListLength, ih]



theorem psKernelNatBeq_symm
    (left right : Nat) :
    Nat.beq left right = Nat.beq right left :=
  psKernelNatBeq_symm_core left right

theorem psKernelStringEqFromWithFuel_symm
    (fuel : Nat)
    (left right : String)
    (leftPos rightPos : Nat) :
    psKernelStringEqFromWithFuel fuel left right leftPos rightPos =
      psKernelStringEqFromWithFuel fuel right left rightPos leftPos :=
  psKernelStringEqFromWithFuel_symm_core
    fuel left right leftPos rightPos

theorem psKernelStringEq_symm
    (left right : String) :
    psKernelStringEq left right =
      psKernelStringEq right left :=
  psKernelStringEq_symm_core left right

theorem psKernelNameEq_symm
    (left right : PsKernelName) :
    psKernelNameEq left right =
      psKernelNameEq right left :=
  psKernelNameEq_symm_core left right


theorem psKernelNameEq_true_iff_of_string_laws
    (hRefl : PsKernelStringEqReflexiveLaw)
    (hSound : PsKernelStringEqSoundLaw)
    (left right : PsKernelName) :
    psKernelNameEq left right = true ↔
      left = right := by
  constructor
  · intro h
    exact
      psKernelNameEq_sound_of_string_law
        hSound left right h
  · intro h
    subst right
    exact
      psKernelNameEq_refl_of_string_law
        hRefl
        left

#print axioms psKernelNatToString_injective
#print axioms psKernelSimpleFreshElimName_fresh_of_primitive_obligations
