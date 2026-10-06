import Ps.KernelCore.Metatheory.EnvironmentIndexHash
import Lean.Elab.Tactic.Omega

/-
Routing refinement for the 16-level environment index trie.
-/

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
  | succ remaining ih =>
      have hSetBound' : setHash < Nat.pow 2 remaining * 2 := by
        simpa [Nat.pow_succ] using hSetBound
      have hFindBound' : findHash < Nat.pow 2 remaining * 2 := by
        simpa [Nat.pow_succ] using hFindBound
      by_cases hSetEven : Nat.mod setHash 2 = 0
      · by_cases hFindEven : Nat.mod findHash 2 = 0
        · have hSetDiv :
              Nat.div setHash 2 < Nat.pow 2 remaining := by
            omega
          have hFindDiv :
              Nat.div findHash 2 < Nat.pow 2 remaining := by
            omega
          have hDivDifferent :
              Nat.div setHash 2 ≠ Nat.div findHash 2 := by
            intro hDiv
            omega
          have hRec :=
            ih
              index
              (Nat.div setHash 2)
              (Nat.div findHash 2)
              hSetDiv
              hFindDiv
              hDivDifferent
          cases index <;>
            simp [
              psKernelEnvironmentIndexSetWorker,
              psKernelEnvironmentIndexFindWorker,
              hSetEven,
              hFindEven,
              hRec
            ]
        · cases index <;>
            simp [
              psKernelEnvironmentIndexSetWorker,
              psKernelEnvironmentIndexFindWorker,
              hSetEven,
              hFindEven
            ]
      · by_cases hFindEven : Nat.mod findHash 2 = 0
        · cases index <;>
            simp [
              psKernelEnvironmentIndexSetWorker,
              psKernelEnvironmentIndexFindWorker,
              hSetEven,
              hFindEven
            ]
        · have hSetDiv :
              Nat.div setHash 2 < Nat.pow 2 remaining := by
            omega
          have hFindDiv :
              Nat.div findHash 2 < Nat.pow 2 remaining := by
            omega
          have hDivDifferent :
              Nat.div setHash 2 ≠ Nat.div findHash 2 := by
            intro hDiv
            omega
          have hRec :=
            ih
              index
              (Nat.div setHash 2)
              (Nat.div findHash 2)
              hSetDiv
              hFindDiv
              hDivDifferent
          cases index <;>
            simp [
              psKernelEnvironmentIndexSetWorker,
              psKernelEnvironmentIndexFindWorker,
              hSetEven,
              hFindEven,
              hRec
            ]

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
