import Ps.KernelCore.Core.Level
import Ps.KernelCore.Metatheory.Comparator

theorem psKernelLevelAddOffset_zero
    (level : PsKernelLevel) :
    psKernelLevelAddOffset level 0 = level := by
  rfl

theorem psKernelLevelAddOffset_succ
    (level : PsKernelLevel)
    (amount : Nat) :
    psKernelLevelAddOffset level (Nat.succ amount) =
      PsKernelLevel.succ (psKernelLevelAddOffset level amount) := by
  rfl

theorem psKernelLevelToOffset_roundtrip
    (level : PsKernelLevel) :
    psKernelLevelAddOffset
        (Prod.fst (psKernelLevelToOffset level))
        (Prod.snd (psKernelLevelToOffset level)) =
      level := by
  induction level with
  | zero =>
      rfl
  | succ inner ih =>
      simp [psKernelLevelToOffset, psKernelLevelAddOffset, ih]
  | max left right =>
      rfl
  | imax left right =>
      rfl
  | param name =>
      rfl
  | mvar name =>
      rfl

theorem psKernelLevelListAppend_eq_append
    (left right : List PsKernelLevel) :
    psKernelLevelListAppend left right = List.append left right := by
  induction left with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelLevelListAppend, ih]

theorem psKernelLevelListReverseWorker_eq
    (values acc : List PsKernelLevel) :
    psKernelLevelListReverseWorker values acc =
      List.append (List.reverse values) acc := by
  induction values generalizing acc with
  | nil =>
      simp [psKernelLevelListReverseWorker]
  | cons head tail ih =>
      simp [psKernelLevelListReverseWorker, ih, List.append_assoc]

theorem psKernelLevelListReverse_eq_reverse
    (values : List PsKernelLevel) :
    psKernelLevelListReverse values = List.reverse values := by
  simp [psKernelLevelListReverse, psKernelLevelListReverseWorker_eq]


theorem psKernelLevelEq_symm
    (left right : PsKernelLevel) :
    psKernelLevelEq left right =
      psKernelLevelEq right left :=
  psKernelLevelEq_symm_core left right

theorem psKernelLevelListEq_symm
    (left right : List PsKernelLevel) :
    psKernelLevelListEq left right =
      psKernelLevelListEq right left :=
  psKernelLevelListEq_symm_core left right


theorem psKernelLevelEq_true_implies_equivalent
    (left right : PsKernelLevel)
    (hEq : psKernelLevelEq left right = true) :
    psKernelLevelEquivalent left right = true := by
  simp [psKernelLevelEquivalent, hEq]


theorem psKernelLevelEq_true_iff_of_string_laws
    (hRefl : PsKernelStringEqReflexiveLaw)
    (hSound : PsKernelStringEqSoundLaw)
    (left right : PsKernelLevel) :
    psKernelLevelEq left right = true ↔
      left = right := by
  constructor
  · intro h
    exact
      psKernelLevelEq_sound_of_string_law
        hSound left right h
  · intro h
    subst right
    exact
      psKernelLevelEq_refl_of_string_law
        hRefl
        left

theorem psKernelLevelEquivalent_true_refines_normalized_eq
    (hSound : PsKernelStringEqSoundLaw)
    (left right : PsKernelLevel)
    (hEq : psKernelLevelEquivalent left right = true) :
    psKernelLevelNormalize left =
      psKernelLevelNormalize right := by
  unfold psKernelLevelEquivalent at hEq
  cases hRaw : psKernelLevelEq left right with
  | true =>
      have hSame :
          left = right :=
        psKernelLevelEq_sound_of_string_law
          hSound
          left
          right
          hRaw
      rw [hSame]
  | false =>
      have hNormalized :
          psKernelLevelEq
              (psKernelLevelNormalize left)
              (psKernelLevelNormalize right) =
            true := by
        simpa [hRaw] using hEq
      exact
        psKernelLevelEq_sound_of_string_law
          hSound
          (psKernelLevelNormalize left)
          (psKernelLevelNormalize right)
          hNormalized
