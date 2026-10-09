import Ps.KernelCore.Metatheory.EnvironmentIndexHash
import Lean.Elab.Tactic.Omega

/-
Routing refinement for the 16-level environment index trie.
-/

theorem psKernelNat_eq_of_div_two_eq_and_mod_two_eq
    (left right : Nat)
    (hDiv : Nat.div left 2 = Nat.div right 2)
    (hMod : Nat.mod left 2 = Nat.mod right 2) :
    left = right := by
  calc
    left =
        Nat.mod left 2 +
          2 * Nat.div left 2 := (Nat.mod_add_div left 2).symm
    _ =
        Nat.mod right 2 +
          2 * Nat.div right 2 := by
            rw [hMod, hDiv]
    _ = right := Nat.mod_add_div right 2

theorem psKernelEnvironmentIndexFindWorker_empty
    (fuel hash : Nat) :
    psKernelEnvironmentIndexFindWorker
        fuel
        PsKernelEnvironmentIndex.empty
        hash =
      List.nil := by
  cases fuel <;> rfl

theorem psKernelEnvironmentIndexFindWorker_setWorker_other_bounded
    (fuel : Nat)
    (index : PsKernelEnvironmentIndex)
    (setHash findHash : Nat)
    (constants : List PsKernelConstantInfo)
    (hSetBound : setHash < Nat.pow 2 fuel)
    (hFindBound : findHash < Nat.pow 2 fuel)
    (hDifferent : setHash ≠ findHash) :
    psKernelEnvironmentIndexFindWorker
        fuel
        (psKernelEnvironmentIndexSetWorker
          fuel index setHash constants)
        findHash =
      psKernelEnvironmentIndexFindWorker
        fuel
        index
        findHash := by
  induction fuel generalizing index setHash findHash with
  | zero =>
      simp [Nat.pow_zero] at hSetBound hFindBound
      omega
  | succ remaining ih =>
      have hSetBound' : setHash < Nat.pow 2 remaining * 2 := by
        simpa [Nat.pow_succ] using hSetBound
      have hFindBound' : findHash < Nat.pow 2 remaining * 2 := by
        simpa [Nat.pow_succ] using hFindBound
      by_cases hSetEven : Nat.mod setHash 2 = 0
      · by_cases hFindEven : Nat.mod findHash 2 = 0
        · have hSetDiv :
              Nat.div setHash 2 < Nat.pow 2 remaining :=
            (Nat.div_lt_iff_lt_mul Nat.zero_lt_two).2 hSetBound'
          have hFindDiv :
              Nat.div findHash 2 < Nat.pow 2 remaining :=
            (Nat.div_lt_iff_lt_mul Nat.zero_lt_two).2 hFindBound'
          have hMod :
              Nat.mod setHash 2 = Nat.mod findHash 2 := by
            rw [hSetEven, hFindEven]
          have hDivDifferent :
              Nat.div setHash 2 ≠ Nat.div findHash 2 := by
            intro hDiv
            apply hDifferent
            exact
              psKernelNat_eq_of_div_two_eq_and_mod_two_eq
                setHash findHash hDiv hMod
          cases index with
          | empty =>
              have hRec :=
                ih
                  PsKernelEnvironmentIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelEnvironmentIndexSetWorker,
                psKernelEnvironmentIndexFindWorker,
                hSetEven,
                hFindEven,
                psKernelEnvironmentIndexFindWorker_empty
              ] using hRec
          | small values =>
              have hRec :=
                ih
                  PsKernelEnvironmentIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelEnvironmentIndexSetWorker,
                psKernelEnvironmentIndexFindWorker,
                hSetEven,
                hFindEven,
                psKernelEnvironmentIndexFindWorker_empty
              ] using hRec
          | bucket values =>
              have hRec :=
                ih
                  PsKernelEnvironmentIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelEnvironmentIndexSetWorker,
                psKernelEnvironmentIndexFindWorker,
                hSetEven,
                hFindEven,
                psKernelEnvironmentIndexFindWorker_empty
              ] using hRec
          | branch left right =>
              have hRec :=
                ih
                  left
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelEnvironmentIndexSetWorker,
                psKernelEnvironmentIndexFindWorker,
                hSetEven,
                hFindEven
              ] using hRec
        · cases index <;>
            simp [
              psKernelEnvironmentIndexSetWorker,
              psKernelEnvironmentIndexFindWorker,
              hSetEven,
              hFindEven,
              psKernelEnvironmentIndexFindWorker_empty
            ]
      · by_cases hFindEven : Nat.mod findHash 2 = 0
        · cases index <;>
            simp [
              psKernelEnvironmentIndexSetWorker,
              psKernelEnvironmentIndexFindWorker,
              hSetEven,
              hFindEven,
              psKernelEnvironmentIndexFindWorker_empty
            ]
        · have hSetDiv :
              Nat.div setHash 2 < Nat.pow 2 remaining :=
            (Nat.div_lt_iff_lt_mul Nat.zero_lt_two).2 hSetBound'
          have hFindDiv :
              Nat.div findHash 2 < Nat.pow 2 remaining :=
            (Nat.div_lt_iff_lt_mul Nat.zero_lt_two).2 hFindBound'
          have hSetModOne : Nat.mod setHash 2 = 1 := by
            rcases Nat.mod_two_eq_zero_or_one setHash with hZero | hOne
            · exact False.elim (hSetEven hZero)
            · exact hOne
          have hFindModOne : Nat.mod findHash 2 = 1 := by
            rcases Nat.mod_two_eq_zero_or_one findHash with hZero | hOne
            · exact False.elim (hFindEven hZero)
            · exact hOne
          have hMod :
              Nat.mod setHash 2 = Nat.mod findHash 2 := by
            rw [hSetModOne, hFindModOne]
          have hDivDifferent :
              Nat.div setHash 2 ≠ Nat.div findHash 2 := by
            intro hDiv
            apply hDifferent
            exact
              psKernelNat_eq_of_div_two_eq_and_mod_two_eq
                setHash findHash hDiv hMod
          cases index with
          | empty =>
              have hRec :=
                ih
                  PsKernelEnvironmentIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelEnvironmentIndexSetWorker,
                psKernelEnvironmentIndexFindWorker,
                hSetEven,
                hFindEven,
                psKernelEnvironmentIndexFindWorker_empty
              ] using hRec
          | small values =>
              have hRec :=
                ih
                  PsKernelEnvironmentIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelEnvironmentIndexSetWorker,
                psKernelEnvironmentIndexFindWorker,
                hSetEven,
                hFindEven,
                psKernelEnvironmentIndexFindWorker_empty
              ] using hRec
          | bucket values =>
              have hRec :=
                ih
                  PsKernelEnvironmentIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelEnvironmentIndexSetWorker,
                psKernelEnvironmentIndexFindWorker,
                hSetEven,
                hFindEven,
                psKernelEnvironmentIndexFindWorker_empty
              ] using hRec
          | branch left right =>
              have hRec :=
                ih
                  right
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelEnvironmentIndexSetWorker,
                psKernelEnvironmentIndexFindWorker,
                hSetEven,
                hFindEven
              ] using hRec

theorem psKernelEnvironmentIndexFindWorker_setWorker_other_name_hash
    (index : PsKernelEnvironmentIndex)
    (setName findName : PsKernelName)
    (constants : List PsKernelConstantInfo)
    (hDifferent :
      psKernelEnvironmentNameHash setName ≠
        psKernelEnvironmentNameHash findName) :
    psKernelEnvironmentIndexFindWorker
        16
        (psKernelEnvironmentIndexSetWorker
          16
          index
          (psKernelEnvironmentNameHash setName)
          constants)
        (psKernelEnvironmentNameHash findName) =
      psKernelEnvironmentIndexFindWorker
        16
        index
        (psKernelEnvironmentNameHash findName) := by
  exact
    psKernelEnvironmentIndexFindWorker_setWorker_other_bounded
      16
      index
      (psKernelEnvironmentNameHash setName)
      (psKernelEnvironmentNameHash findName)
      constants
      (psKernelEnvironmentNameHash_lt_two_pow_16 setName)
      (psKernelEnvironmentNameHash_lt_two_pow_16 findName)
      hDifferent
