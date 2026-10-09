import Ps.KernelCore.Metatheory.CacheHash
import Ps.KernelCore.Metatheory.EnvironmentIndexRefinement
import Lean.Elab.Tactic.Omega

/-
Routing refinement for the 16-level expression-cache trie.
-/

theorem psKernelExprMapIndexBucket_empty
    (fuel hash : Nat) :
    psKernelExprMapIndexBucket
        fuel
        PsKernelExprMapIndex.empty
        hash =
      List.nil := by
  cases fuel <;> rfl

theorem psKernelExprHash_lt_modulus
    (expr : PsKernelExpr) :
    psKernelExprHash expr <
      psKernelCacheHashModulus := by
  cases expr <;>
    simp only [
      psKernelExprHash,
      psKernelCacheMix,
      psKernelCacheHashModulus
    ] <;>
    exact Nat.mod_lt _ (by decide)

theorem psKernelExprHash_lt_two_pow_16
    (expr : PsKernelExpr) :
    psKernelExprHash expr < Nat.pow 2 16 := by
  exact
    Nat.lt_trans
      (psKernelExprHash_lt_modulus expr)
      (by decide)

theorem psKernelExprMapIndexBucket_set_other_bounded
    (fuel : Nat)
    (index : PsKernelExprMapIndex)
    (setHash findHash : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (hSetBound : setHash < Nat.pow 2 fuel)
    (hFindBound : findHash < Nat.pow 2 fuel)
    (hDifferent : setHash ≠ findHash) :
    psKernelExprMapIndexBucket
        fuel
        (psKernelExprMapIndexSet
          fuel
          index
          setHash
          entries)
        findHash =
      psKernelExprMapIndexBucket
        fuel
        index
        findHash := by
  induction fuel generalizing index setHash findHash with
  | zero =>
      simp [Nat.pow_zero] at hSetBound hFindBound
      omega
  | succ remaining ih =>
      have hSetBound' :
          setHash < Nat.pow 2 remaining * 2 := by
        simpa [Nat.pow_succ] using hSetBound
      have hFindBound' :
          findHash < Nat.pow 2 remaining * 2 := by
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
                  PsKernelExprMapIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelExprMapIndexSet,
                psKernelExprMapIndexBucket,
                hSetEven,
                hFindEven,
                psKernelExprMapIndexBucket_empty
              ] using hRec
          | bucket values =>
              have hRec :=
                ih
                  PsKernelExprMapIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelExprMapIndexSet,
                psKernelExprMapIndexBucket,
                hSetEven,
                hFindEven,
                psKernelExprMapIndexBucket_empty
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
                psKernelExprMapIndexSet,
                psKernelExprMapIndexBucket,
                hSetEven,
                hFindEven
              ] using hRec
        · cases index <;>
            simp [
              psKernelExprMapIndexSet,
              psKernelExprMapIndexBucket,
              hSetEven,
              hFindEven,
              psKernelExprMapIndexBucket_empty
            ]
      · by_cases hFindEven : Nat.mod findHash 2 = 0
        · cases index <;>
            simp [
              psKernelExprMapIndexSet,
              psKernelExprMapIndexBucket,
              hSetEven,
              hFindEven,
              psKernelExprMapIndexBucket_empty
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
                  PsKernelExprMapIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelExprMapIndexSet,
                psKernelExprMapIndexBucket,
                hSetEven,
                hFindEven,
                psKernelExprMapIndexBucket_empty
              ] using hRec
          | bucket values =>
              have hRec :=
                ih
                  PsKernelExprMapIndex.empty
                  (Nat.div setHash 2)
                  (Nat.div findHash 2)
                  hSetDiv
                  hFindDiv
                  hDivDifferent
              simpa [
                psKernelExprMapIndexSet,
                psKernelExprMapIndexBucket,
                hSetEven,
                hFindEven,
                psKernelExprMapIndexBucket_empty
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
                psKernelExprMapIndexSet,
                psKernelExprMapIndexBucket,
                hSetEven,
                hFindEven
              ] using hRec

theorem psKernelExprMapIndexBucket_set_other_expr_hash
    (index : PsKernelExprMapIndex)
    (setExpr findExpr : PsKernelExpr)
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (hDifferent :
      psKernelExprHash setExpr ≠
        psKernelExprHash findExpr) :
    psKernelExprMapIndexBucket
        16
        (psKernelExprMapIndexSet
          16
          index
          (psKernelExprHash setExpr)
          entries)
        (psKernelExprHash findExpr) =
      psKernelExprMapIndexBucket
        16
        index
        (psKernelExprHash findExpr) := by
  exact
    psKernelExprMapIndexBucket_set_other_bounded
      16
      index
      (psKernelExprHash setExpr)
      (psKernelExprHash findExpr)
      entries
      (psKernelExprHash_lt_two_pow_16 setExpr)
      (psKernelExprHash_lt_two_pow_16 findExpr)
      hDifferent
