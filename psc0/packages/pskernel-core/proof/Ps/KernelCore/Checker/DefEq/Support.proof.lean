import Ps.KernelCore.Checker.DefEq.Support
import Ps.KernelCore.Metatheory.Comparator

theorem psKernelDefEqSupport_level_lists_nil :
    psKernelLevelListsEquivalent List.nil List.nil = true := by
  rfl


theorem psKernelLevelListsEquivalent_true_refines_normalized
    (hString : PsKernelStringEqSoundLaw)
    (left right : List PsKernelLevel)
    (hEq :
      psKernelLevelListsEquivalent left right =
        true) :
    List.map psKernelLevelNormalize left =
      List.map psKernelLevelNormalize right := by
  induction left generalizing right with
  | nil =>
      cases right with
      | nil =>
          rfl
      | cons head tail =>
          simp [psKernelLevelListsEquivalent] at hEq
  | cons leftHead leftTail ih =>
      cases right with
      | nil =>
          simp [psKernelLevelListsEquivalent] at hEq
      | cons rightHead rightTail =>
          cases hHead :
              psKernelLevelEquivalent
                leftHead
                rightHead with
          | false =>
              simp [
                psKernelLevelListsEquivalent,
                hHead
              ] at hEq
          | true =>
              have hTail :
                  psKernelLevelListsEquivalent
                      leftTail
                      rightTail =
                    true := by
                simpa [
                  psKernelLevelListsEquivalent,
                  hHead
                ] using hEq
              have hHeadEq :
                  psKernelLevelNormalize leftHead =
                    psKernelLevelNormalize rightHead :=
                psKernelLevelEquivalent_sound_of_string_law
                  hString
                  leftHead
                  rightHead
                  hHead
              have hTailEq :=
                ih rightTail hTail
              simp [hHeadEq, hTailEq]
