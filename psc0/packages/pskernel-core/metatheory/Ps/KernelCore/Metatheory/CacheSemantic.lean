import Ps.KernelCore.Metatheory.Judgments
import Ps.KernelCore.Metatheory.ExprEq
import Ps.KernelCore.Metatheory.Comparator
import Ps.KernelCore.Metatheory.CacheHash
import Ps.KernelCore.Metatheory.CacheIndexRefinement

/-
Semantic refinement for the expression caches.

The cache comparator intentionally quotients binder presentation.  The
Assurance Plane therefore transports semantic judgments across
PsKernelStructuralExprEq instead of pretending cache keys are Lean-equal.
-/

theorem psKernelExprMapIndexBucket_set_same_core
    (fuel : Nat)
    (index : PsKernelExprMapIndex)
    (hash : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprMapIndexBucket
        fuel
        (psKernelExprMapIndexSet
          fuel
          index
          hash
          entries)
        hash =
      entries := by
  induction fuel generalizing index hash with
  | zero =>
      rfl
  | succ remaining ih =>
      cases index <;>
        by_cases hEven : Nat.mod hash 2 = 0 <;>
        simp [
          psKernelExprMapIndexSet,
          psKernelExprMapIndexBucket,
          hEven,
          ih
        ]

theorem psKernelExprMapGetIn_insertIn_other_core
    (key value query : PsKernelExpr)
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (hDifferent : psKernelExprEq key query = false) :
    psKernelExprMapGetIn
        query
        (psKernelExprMapInsertIn
          key
          value
          entries) =
      psKernelExprMapGetIn query entries := by
  induction entries with
  | nil =>
      simp [
        psKernelExprMapInsertIn,
        psKernelExprMapGetIn,
        hDifferent
      ]
  | cons entry rest ih =>
      cases hExisting :
          psKernelExprEq
            (Prod.fst entry)
            key with
      | false =>
          simp [
            psKernelExprMapInsertIn,
            psKernelExprMapGetIn,
            hExisting,
            ih
          ]
      | true =>
          have hEntryQuery :
              psKernelExprEq
                  (Prod.fst entry)
                  query =
                false := by
            cases hQuery :
                psKernelExprEq
                  (Prod.fst entry)
                  query with
            | false =>
                rfl
            | true =>
                have hKeyEntry :
                    psKernelExprEq
                        key
                        (Prod.fst entry) =
                      true := by
                  rw [
                    ← psKernelExprEq_symm_core
                      (Prod.fst entry)
                      key
                  ]
                  exact hExisting
                have hTrans :
                    psKernelExprEq key query = true :=
                  psKernelExprEq_trans_core
                    key
                    (Prod.fst entry)
                    query
                    hKeyEntry
                    hQuery
                rw [hDifferent] at hTrans
                cases hTrans
          simp [
            psKernelExprMapInsertIn,
            psKernelExprMapGetIn,
            hExisting,
            hDifferent,
            hEntryQuery
          ]

theorem psKernelExprMapGetIn_insertIn_match_core
    (key value query : PsKernelExpr)
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (hMatch : psKernelExprEq key query = true) :
    psKernelExprMapGetIn
        query
        (psKernelExprMapInsertIn
          key
          value
          entries) =
      Option.some value := by
  induction entries with
  | nil =>
      simp [
        psKernelExprMapInsertIn,
        psKernelExprMapGetIn,
        hMatch
      ]
  | cons entry rest ih =>
      cases hExisting :
          psKernelExprEq
            (Prod.fst entry)
            key with
      | true =>
          simp [
            psKernelExprMapInsertIn,
            psKernelExprMapGetIn,
            hExisting,
            hMatch
          ]
      | false =>
          have hEntryQuery :
              psKernelExprEq
                  (Prod.fst entry)
                  query =
                false := by
            cases hQuery :
                psKernelExprEq
                  (Prod.fst entry)
                  query with
            | false =>
                rfl
            | true =>
                have hQueryKey :
                    psKernelExprEq query key = true := by
                  rw [
                    ← psKernelExprEq_symm_core
                      key
                      query
                  ]
                  exact hMatch
                have hTrans :
                    psKernelExprEq
                        (Prod.fst entry)
                        key =
                      true :=
                  psKernelExprEq_trans_core
                    (Prod.fst entry)
                    query
                    key
                    hQuery
                    hQueryKey
                rw [hExisting] at hTrans
                cases hTrans
          simp [
            psKernelExprMapInsertIn,
            psKernelExprMapGetIn,
            hExisting,
            hEntryQuery,
            ih
          ]

theorem psKernelExprMapBuildIndex_refines_get_core
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (query : PsKernelExpr) :
    psKernelExprMapGetIn
        query
        (psKernelExprMapIndexBucket
          16
          (psKernelExprMapBuildIndex entries)
          (psKernelExprHash query)) =
      psKernelExprMapGetIn query entries := by
  induction entries generalizing query with
  | nil =>
      rfl
  | cons entry rest ih =>
      let key := Prod.fst entry
      let value := Prod.snd entry
      let oldIndex :=
        psKernelExprMapBuildIndex rest
      let oldBucket :=
        psKernelExprMapIndexBucket
          16
          oldIndex
          (psKernelExprHash key)
      let newBucket :=
        psKernelExprMapInsertIn
          key
          value
          oldBucket
      change
        psKernelExprMapGetIn
            query
            (psKernelExprMapIndexBucket
              16
              (psKernelExprMapIndexSet
                16
                oldIndex
                (psKernelExprHash key)
                newBucket)
              (psKernelExprHash query)) =
          psKernelExprMapGetIn
            query
            (List.cons entry rest)
      cases hSame :
          psKernelExprEq key query with
      | true =>
          have hHash :
              psKernelExprHash key =
                psKernelExprHash query :=
            psKernelExprHash_of_exprEq_true
              key query hSame
          have hBucket :
              psKernelExprMapIndexBucket
                  16
                  (psKernelExprMapIndexSet
                    16
                    oldIndex
                    (psKernelExprHash key)
                    newBucket)
                  (psKernelExprHash query) =
                newBucket := by
            rw [← hHash]
            exact
              psKernelExprMapIndexBucket_set_same_core
                16
                oldIndex
                (psKernelExprHash key)
                newBucket
          rw [hBucket]
          have hLeft :
              psKernelExprMapGetIn query newBucket =
                Option.some value := by
            exact
              psKernelExprMapGetIn_insertIn_match_core
                key value query oldBucket hSame
          rw [hLeft]
          have hSameRaw :
              psKernelExprEq
                  (Prod.fst entry)
                  query =
                true := by
            simpa [key] using hSame
          simp [
            psKernelExprMapGetIn,
            value,
            hSameRaw
          ]
      | false =>
          have hRight :
              psKernelExprMapGetIn
                  query
                  (List.cons entry rest) =
                psKernelExprMapGetIn query rest := by
            have hSameRaw :
                psKernelExprEq
                    (Prod.fst entry)
                    query =
                  false := by
              simpa [key] using hSame
            simp [
              psKernelExprMapGetIn,
              hSameRaw
            ]
          rw [hRight]
          by_cases hHash :
              psKernelExprHash key =
                psKernelExprHash query
          · have hBucket :
                psKernelExprMapIndexBucket
                    16
                    (psKernelExprMapIndexSet
                      16
                      oldIndex
                      (psKernelExprHash key)
                      newBucket)
                    (psKernelExprHash query) =
                  newBucket := by
              rw [← hHash]
              exact
                psKernelExprMapIndexBucket_set_same_core
                  16
                  oldIndex
                  (psKernelExprHash key)
                  newBucket
            rw [hBucket]
            rw [
              psKernelExprMapGetIn_insertIn_other_core
                key value query oldBucket hSame
            ]
            unfold oldBucket
            rw [hHash]
            exact ih query
          · rw [
              psKernelExprMapIndexBucket_set_other_expr_hash
                oldIndex
                key
                query
                newBucket
                hHash
            ]
            exact ih query

theorem psKernelExprMapGet_insert_match_core
    (cache : PsKernelExprMap)
    (key value query : PsKernelExpr)
    (hMatch : psKernelExprEq key query = true) :
    psKernelExprMapGet
        (psKernelExprMapInsert cache key value)
        query =
      Option.some value := by
  cases cache with
  | mk small index =>
      cases index with
      | none =>
          cases hFits :
              Nat.ble
                (psKernelCacheEntryListLength
                  (psKernelExprMapInsertIn key value small))
                psKernelCacheSmallLimit with
          | true =>
              simp [
                psKernelExprMapInsert,
                hFits,
                psKernelExprMapGet
              ]
              exact
                psKernelExprMapGetIn_insertIn_match_core
                  key value query small hMatch
          | false =>
              simp [
                psKernelExprMapInsert,
                hFits,
                psKernelExprMapGet
              ]
              rw [
                psKernelExprMapBuildIndex_refines_get_core
                  (psKernelExprMapInsertIn key value small)
                  query
              ]
              exact
                psKernelExprMapGetIn_insertIn_match_core
                  key value query small hMatch
      | some index =>
          have hHash :
              psKernelExprHash key =
                psKernelExprHash query :=
            psKernelExprHash_of_exprEq_true
              key query hMatch
          simp only [
            psKernelExprMapInsert,
            psKernelExprMapGet
          ]
          rw [← hHash]
          rw [
            psKernelExprMapIndexBucket_set_same_core
              16
              index
              (psKernelExprHash key)
              (psKernelExprMapInsertIn
                key
                value
                (psKernelExprMapIndexBucket
                  16
                  index
                  (psKernelExprHash key)))
          ]
          exact
            psKernelExprMapGetIn_insertIn_match_core
              key
              value
              query
              (psKernelExprMapIndexBucket
                16
                index
                (psKernelExprHash key))
              hMatch

theorem psKernelExprMapGet_insert_other_core
    (cache : PsKernelExprMap)
    (key value query : PsKernelExpr)
    (hDifferent : psKernelExprEq key query = false) :
    psKernelExprMapGet
        (psKernelExprMapInsert cache key value)
        query =
      psKernelExprMapGet cache query := by
  cases cache with
  | mk small index =>
      cases index with
      | none =>
          cases hFits :
              Nat.ble
                (psKernelCacheEntryListLength
                  (psKernelExprMapInsertIn key value small))
                psKernelCacheSmallLimit with
          | true =>
              simp [
                psKernelExprMapInsert,
                hFits,
                psKernelExprMapGet
              ]
              exact
                psKernelExprMapGetIn_insertIn_other_core
                  key value query small hDifferent
          | false =>
              simp [
                psKernelExprMapInsert,
                hFits,
                psKernelExprMapGet
              ]
              rw [
                psKernelExprMapBuildIndex_refines_get_core
                  (psKernelExprMapInsertIn key value small)
                  query
              ]
              exact
                psKernelExprMapGetIn_insertIn_other_core
                  key value query small hDifferent
      | some index =>
          simp only [
            psKernelExprMapInsert,
            psKernelExprMapGet
          ]
          by_cases hHash :
              psKernelExprHash key =
                psKernelExprHash query
          · rw [← hHash]
            rw [
              psKernelExprMapIndexBucket_set_same_core
                16
                index
                (psKernelExprHash key)
                (psKernelExprMapInsertIn
                  key
                  value
                  (psKernelExprMapIndexBucket
                    16
                    index
                    (psKernelExprHash key)))
            ]
            exact
              psKernelExprMapGetIn_insertIn_other_core
                key
                value
                query
                (psKernelExprMapIndexBucket
                  16
                  index
                  (psKernelExprHash key))
                hDifferent
          · rw [
              psKernelExprMapIndexBucket_set_other_expr_hash
                index
                key
                query
                (psKernelExprMapInsertIn
                  key
                  value
                  (psKernelExprMapIndexBucket
                    16
                    index
                    (psKernelExprHash key)))
                hHash
            ]

theorem psKernelInferenceCacheInsertLaw_all :
    PsKernelInferenceCacheInsertLaw := by
  intro environment localContext cache expr result hCache hTyping
  intro query cached hGet
  cases hMatch : psKernelExprEq expr query with
  | true =>
      have hLookup :=
        psKernelExprMapGet_insert_match_core
          cache expr result query hMatch
      rw [hLookup] at hGet
      simp at hGet
      subst cached
      exact
        PsKernelTypingJudgment.presentation
          expr
          query
          result
          (psKernelExprEq_true_refines_structural
            expr
            query
            hMatch)
          hTyping
  | false =>
      have hLookup :=
        psKernelExprMapGet_insert_other_core
          cache expr result query hMatch
      rw [hLookup] at hGet
      exact hCache query cached hGet

theorem psKernelReductionCacheInsertLaw_all :
    PsKernelReductionCacheInsertLaw := by
  intro environment localContext cache expr result hCache hReduction
  intro query cached hGet
  cases hMatch : psKernelExprEq expr query with
  | true =>
      have hLookup :=
        psKernelExprMapGet_insert_match_core
          cache expr result query hMatch
      rw [hLookup] at hGet
      simp at hGet
      subst cached
      exact
        PsKernelReductionClosure.presentationSource
          expr
          query
          result
          (psKernelExprEq_true_refines_structural
            expr
            query
            hMatch)
          hReduction
  | false =>
      have hLookup :=
        psKernelExprMapGet_insert_other_core
          cache expr result query hMatch
      rw [hLookup] at hGet
      exact hCache query cached hGet


/- Unordered DefEq pair-cache routing. -/

def psKernelExprPairSetIndexAsMapIndex
    (index : PsKernelExprPairSetIndex) :
    PsKernelExprMapIndex :=
  match index with
  | PsKernelExprPairSetIndex.empty =>
      PsKernelExprMapIndex.empty
  | PsKernelExprPairSetIndex.bucket entries =>
      PsKernelExprMapIndex.bucket entries
  | PsKernelExprPairSetIndex.branch left right =>
      PsKernelExprMapIndex.branch
        (psKernelExprPairSetIndexAsMapIndex left)
        (psKernelExprPairSetIndexAsMapIndex right)
termination_by index

theorem psKernelExprPairSetIndexBucket_as_map_core
    (fuel : Nat)
    (index : PsKernelExprPairSetIndex)
    (hash : Nat) :
    psKernelExprMapIndexBucket
        fuel
        (psKernelExprPairSetIndexAsMapIndex index)
        hash =
      psKernelExprPairSetIndexBucket
        fuel
        index
        hash := by
  induction fuel generalizing index hash with
  | zero =>
      cases index <;>
        simp [
          psKernelExprPairSetIndexAsMapIndex,
          psKernelExprMapIndexBucket,
          psKernelExprPairSetIndexBucket
        ]
  | succ remaining ih =>
      cases index with
      | empty =>
          simp [
            psKernelExprPairSetIndexAsMapIndex,
            psKernelExprMapIndexBucket,
            psKernelExprPairSetIndexBucket
          ]
      | bucket entries =>
          simp [
            psKernelExprPairSetIndexAsMapIndex,
            psKernelExprMapIndexBucket,
            psKernelExprPairSetIndexBucket
          ]
      | branch left right =>
          by_cases hEven :
              Nat.mod hash 2 = 0 <;>
            simp [
              psKernelExprPairSetIndexAsMapIndex,
              psKernelExprMapIndexBucket,
              psKernelExprPairSetIndexBucket,
              hEven,
              ih
            ]

theorem psKernelExprPairSetIndexSet_as_map_core
    (fuel : Nat)
    (index : PsKernelExprPairSetIndex)
    (hash : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprPairSetIndexAsMapIndex
        (psKernelExprPairSetIndexSet
          fuel
          index
          hash
          entries) =
      psKernelExprMapIndexSet
        fuel
        (psKernelExprPairSetIndexAsMapIndex index)
        hash
        entries := by
  induction fuel generalizing index hash with
  | zero =>
      cases index <;>
        simp [
          psKernelExprPairSetIndexAsMapIndex,
          psKernelExprPairSetIndexSet,
          psKernelExprMapIndexSet
        ]
  | succ remaining ih =>
      cases index <;>
        by_cases hEven : Nat.mod hash 2 = 0 <;>
        simp [
          psKernelExprPairSetIndexAsMapIndex,
          psKernelExprPairSetIndexSet,
          psKernelExprMapIndexSet,
          hEven,
          ih
        ]

theorem psKernelExprPairSetIndexBucket_set_same_core
    (fuel : Nat)
    (index : PsKernelExprPairSetIndex)
    (hash : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprPairSetIndexBucket
        fuel
        (psKernelExprPairSetIndexSet
          fuel
          index
          hash
          entries)
        hash =
      entries := by
  calc
    psKernelExprPairSetIndexBucket
        fuel
        (psKernelExprPairSetIndexSet
          fuel
          index
          hash
          entries)
        hash =
      psKernelExprMapIndexBucket
        fuel
        (psKernelExprPairSetIndexAsMapIndex
          (psKernelExprPairSetIndexSet
            fuel
            index
            hash
            entries))
        hash := by
          symm
          exact
            psKernelExprPairSetIndexBucket_as_map_core
              fuel
              (psKernelExprPairSetIndexSet
                fuel index hash entries)
              hash
    _ =
      psKernelExprMapIndexBucket
        fuel
        (psKernelExprMapIndexSet
          fuel
          (psKernelExprPairSetIndexAsMapIndex index)
          hash
          entries)
        hash := by
          rw [
            psKernelExprPairSetIndexSet_as_map_core
              fuel index hash entries
          ]
    _ = entries :=
      psKernelExprMapIndexBucket_set_same_core
        fuel
        (psKernelExprPairSetIndexAsMapIndex index)
        hash
        entries

theorem psKernelExprPairHash_lt_modulus_core
    (left right : PsKernelExpr) :
    psKernelExprPairHash left right <
      psKernelCacheHashModulus := by
  unfold psKernelExprPairHash
  exact Nat.mod_lt _ (by decide)

theorem psKernelExprPairHash_lt_two_pow_16_core
    (left right : PsKernelExpr) :
    psKernelExprPairHash left right <
      Nat.pow 2 16 := by
  exact
    Nat.lt_trans
      (psKernelExprPairHash_lt_modulus_core left right)
      (by decide)

theorem psKernelExprPairSetIndexBucket_set_other_hash_core
    (index : PsKernelExprPairSetIndex)
    (setHash findHash : Nat)
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (hSetBound : setHash < Nat.pow 2 16)
    (hFindBound : findHash < Nat.pow 2 16)
    (hDifferent : setHash ≠ findHash) :
    psKernelExprPairSetIndexBucket
        16
        (psKernelExprPairSetIndexSet
          16
          index
          setHash
          entries)
        findHash =
      psKernelExprPairSetIndexBucket
        16
        index
        findHash := by
  calc
    psKernelExprPairSetIndexBucket
        16
        (psKernelExprPairSetIndexSet
          16
          index
          setHash
          entries)
        findHash =
      psKernelExprMapIndexBucket
        16
        (psKernelExprPairSetIndexAsMapIndex
          (psKernelExprPairSetIndexSet
            16 index setHash entries))
        findHash := by
          symm
          exact
            psKernelExprPairSetIndexBucket_as_map_core
              16
              (psKernelExprPairSetIndexSet
                16 index setHash entries)
              findHash
    _ =
      psKernelExprMapIndexBucket
        16
        (psKernelExprMapIndexSet
          16
          (psKernelExprPairSetIndexAsMapIndex index)
          setHash
          entries)
        findHash := by
          rw [
            psKernelExprPairSetIndexSet_as_map_core
              16 index setHash entries
          ]
    _ =
      psKernelExprMapIndexBucket
        16
        (psKernelExprPairSetIndexAsMapIndex index)
        findHash :=
      psKernelExprMapIndexBucket_set_other_bounded
        16
        (psKernelExprPairSetIndexAsMapIndex index)
        setHash
        findHash
        entries
        hSetBound
        hFindBound
        hDifferent
    _ =
      psKernelExprPairSetIndexBucket
        16
        index
        findHash :=
      psKernelExprPairSetIndexBucket_as_map_core
        16 index findHash

theorem psKernelExprPairEq_true_cases_core
    (queryLeft queryRight storedLeft storedRight : PsKernelExpr)
    (h :
      psKernelExprPairEq
          queryLeft
          queryRight
          (Prod.mk storedLeft storedRight) =
        true) :
    (psKernelExprEq storedLeft queryLeft = true ∧
      psKernelExprEq storedRight queryRight = true) ∨
    (psKernelExprEq storedLeft queryRight = true ∧
      psKernelExprEq storedRight queryLeft = true) := by
  cases hFirst :
      psKernelExprEq storedLeft queryLeft with
  | true =>
      left
      have hSecond :
          psKernelExprEq storedRight queryRight = true := by
        simpa [
          psKernelExprPairEq,
          hFirst
        ] using h
      exact ⟨rfl, hSecond⟩
  | false =>
      cases hSwap :
          psKernelExprEq storedLeft queryRight with
      | false =>
          simp [
            psKernelExprPairEq,
            hFirst,
            hSwap
          ] at h
      | true =>
          right
          have hSecond :
              psKernelExprEq storedRight queryLeft = true := by
            simpa [
              psKernelExprPairEq,
              hFirst,
              hSwap
            ] using h
          exact ⟨rfl, hSecond⟩

theorem psKernelExprPairEq_true_refines_presentation_core
    (queryLeft queryRight storedLeft storedRight : PsKernelExpr)
    (h :
      psKernelExprPairEq
          queryLeft
          queryRight
          (Prod.mk storedLeft storedRight) =
        true) :
    (PsKernelStructuralExprEq storedLeft queryLeft ∧
      PsKernelStructuralExprEq storedRight queryRight) ∨
    (PsKernelStructuralExprEq storedLeft queryRight ∧
      PsKernelStructuralExprEq storedRight queryLeft) := by
  rcases
      psKernelExprPairEq_true_cases_core
        queryLeft queryRight storedLeft storedRight h with
    hDirect | hSwapped
  · left
    exact
      ⟨
        psKernelExprEq_true_refines_structural
          storedLeft queryLeft hDirect.1,
        psKernelExprEq_true_refines_structural
          storedRight queryRight hDirect.2
      ⟩
  · right
    exact
      ⟨
        psKernelExprEq_true_refines_structural
          storedLeft queryRight hSwapped.1,
        psKernelExprEq_true_refines_structural
          storedRight queryLeft hSwapped.2
      ⟩

theorem psKernelExprPairHash_of_pairEq_true_core
    (queryLeft queryRight storedLeft storedRight : PsKernelExpr)
    (h :
      psKernelExprPairEq
          queryLeft
          queryRight
          (Prod.mk storedLeft storedRight) =
        true) :
    psKernelExprPairHash storedLeft storedRight =
      psKernelExprPairHash queryLeft queryRight := by
  rcases
      psKernelExprPairEq_true_cases_core
        queryLeft queryRight storedLeft storedRight h with
    hDirect | hSwapped
  · have hLeft :=
      psKernelExprHash_of_exprEq_true
        storedLeft queryLeft hDirect.1
    have hRight :=
      psKernelExprHash_of_exprEq_true
        storedRight queryRight hDirect.2
    simp [
      psKernelExprPairHash,
      hLeft,
      hRight
    ]
  · have hLeft :=
      psKernelExprHash_of_exprEq_true
        storedLeft queryRight hSwapped.1
    have hRight :=
      psKernelExprHash_of_exprEq_true
        storedRight queryLeft hSwapped.2
    simp [
      psKernelExprPairHash,
      hLeft,
      hRight,
      Nat.add_comm
    ]

theorem psKernelExprPairSetContainsIn_cons_true_cases_core
    (queryLeft queryRight : PsKernelExpr)
    (entry : Prod PsKernelExpr PsKernelExpr)
    (rest : List (Prod PsKernelExpr PsKernelExpr))
    (h :
      psKernelExprPairSetContainsIn
          queryLeft
          queryRight
          (List.cons entry rest) =
        true) :
    psKernelExprPairEq queryLeft queryRight entry = true ∨
      psKernelExprPairSetContainsIn
          queryLeft
          queryRight
          rest =
        true := by
  cases hHead :
      psKernelExprPairEq queryLeft queryRight entry with
  | true =>
      exact Or.inl rfl
  | false =>
      right
      simpa [
        psKernelExprPairSetContainsIn,
        hHead
      ] using h


theorem psKernelExprPairSetBuildIndex_contains_sound_core
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (queryLeft queryRight : PsKernelExpr)
    (h :
      psKernelExprPairSetContainsIn
          queryLeft
          queryRight
          (psKernelExprPairSetIndexBucket
            16
            (psKernelExprPairSetBuildIndex entries)
            (psKernelExprPairHash queryLeft queryRight)) =
        true) :
    psKernelExprPairSetContainsIn
        queryLeft
        queryRight
        entries =
      true := by
  induction entries generalizing queryLeft queryRight with
  | nil =>
      simp [
        psKernelExprPairSetBuildIndex,
        psKernelExprPairSetIndexBucket,
        psKernelExprPairSetContainsIn
      ] at h
  | cons entry rest ih =>
      let storedLeft := Prod.fst entry
      let storedRight := Prod.snd entry
      let oldIndex :=
        psKernelExprPairSetBuildIndex rest
      let storedHash :=
        psKernelExprPairHash storedLeft storedRight
      let oldBucket :=
        psKernelExprPairSetIndexBucket
          16
          oldIndex
          storedHash
      cases hExisting :
          psKernelExprPairSetContainsIn
            storedLeft
            storedRight
            oldBucket with
      | true =>
          have hBuild :
              psKernelExprPairSetBuildIndex
                  (List.cons entry rest) =
                oldIndex := by
            simp [
              psKernelExprPairSetBuildIndex,
              storedLeft,
              storedRight,
              oldIndex,
              storedHash,
              oldBucket,
              hExisting
            ]
          rw [hBuild] at h
          have hRest :=
            ih queryLeft queryRight h
          cases hHead :
              psKernelExprPairEq
                queryLeft
                queryRight
                entry with
          | true =>
              simp [
                psKernelExprPairSetContainsIn,
                hHead
              ]
          | false =>
              simpa [
                psKernelExprPairSetContainsIn,
                hHead
              ] using hRest
      | false =>
          have hBuild :
              psKernelExprPairSetBuildIndex
                  (List.cons entry rest) =
                psKernelExprPairSetIndexSet
                  16
                  oldIndex
                  storedHash
                  (List.cons entry oldBucket) := by
            simp [
              psKernelExprPairSetBuildIndex,
              storedLeft,
              storedRight,
              oldIndex,
              storedHash,
              oldBucket,
              hExisting
            ]
          rw [hBuild] at h
          by_cases hHash :
              storedHash =
                psKernelExprPairHash queryLeft queryRight
          · have hBucket :
                psKernelExprPairSetIndexBucket
                    16
                    (psKernelExprPairSetIndexSet
                      16
                      oldIndex
                      storedHash
                      (List.cons entry oldBucket))
                    (psKernelExprPairHash queryLeft queryRight) =
                  List.cons entry oldBucket := by
              rw [← hHash]
              exact
                psKernelExprPairSetIndexBucket_set_same_core
                  16
                  oldIndex
                  storedHash
                  (List.cons entry oldBucket)
            rw [hBucket] at h
            rcases
                psKernelExprPairSetContainsIn_cons_true_cases_core
                  queryLeft
                  queryRight
                  entry
                  oldBucket
                  h with
              hHead | hOld
            · simp [
                psKernelExprPairSetContainsIn,
                hHead
              ]
            · have hOldIndex :
                  psKernelExprPairSetContainsIn
                      queryLeft
                      queryRight
                      (psKernelExprPairSetIndexBucket
                        16
                        oldIndex
                        (psKernelExprPairHash
                          queryLeft
                          queryRight)) =
                    true := by
                unfold oldBucket at hOld
                rw [hHash] at hOld
                exact hOld
              have hRest :=
                ih queryLeft queryRight hOldIndex
              cases hHead :
                  psKernelExprPairEq
                    queryLeft
                    queryRight
                    entry with
              | true =>
                  simp [
                    psKernelExprPairSetContainsIn,
                    hHead
                  ]
              | false =>
                  simpa [
                    psKernelExprPairSetContainsIn,
                    hHead
                  ] using hRest
          · have hRouted :
                psKernelExprPairSetContainsIn
                    queryLeft
                    queryRight
                    (psKernelExprPairSetIndexBucket
                      16
                      oldIndex
                      (psKernelExprPairHash
                        queryLeft
                        queryRight)) =
                  true := by
              rw [
                psKernelExprPairSetIndexBucket_set_other_hash_core
                  oldIndex
                  storedHash
                  (psKernelExprPairHash queryLeft queryRight)
                  (List.cons entry oldBucket)
                  (psKernelExprPairHash_lt_two_pow_16_core
                    storedLeft storedRight)
                  (psKernelExprPairHash_lt_two_pow_16_core
                    queryLeft queryRight)
                  hHash
              ] at h
              exact h
            have hRest :=
              ih queryLeft queryRight hRouted
            cases hHead :
                psKernelExprPairEq
                  queryLeft
                  queryRight
                  entry with
            | true =>
                simp [
                  psKernelExprPairSetContainsIn,
                  hHead
                ]
            | false =>
                simpa [
                  psKernelExprPairSetContainsIn,
                  hHead
                ] using hRest


theorem psKernelExprPairSetContains_insert_sound_core
    (set : PsKernelExprPairSet)
    (left right queryLeft queryRight : PsKernelExpr)
    (hContains :
      psKernelExprPairSetContains
          (psKernelExprPairSetInsert set left right)
          queryLeft
          queryRight =
        true) :
    psKernelExprPairEq
        queryLeft
        queryRight
        (Prod.mk left right) =
      true ∨
    psKernelExprPairSetContains
        set
        queryLeft
        queryRight =
      true := by
  cases set with
  | mk small index =>
      cases index with
      | none =>
          cases hExisting :
              psKernelExprPairSetContainsIn
                left
                right
                small with
          | true =>
              right
              simpa [
                psKernelExprPairSetInsert,
                hExisting,
                psKernelExprPairSetContains
              ] using hContains
          | false =>
              let next :=
                List.cons
                  (Prod.mk left right)
                  small
              cases hFits :
                  Nat.ble
                    (psKernelCacheEntryListLength next)
                    psKernelCacheSmallLimit with
              | true =>
                  have hNext :
                      psKernelExprPairSetContainsIn
                          queryLeft
                          queryRight
                          next =
                        true := by
                    simpa [
                      psKernelExprPairSetInsert,
                      hExisting,
                      next,
                      hFits,
                      psKernelExprPairSetContains
                    ] using hContains
                  exact
                    psKernelExprPairSetContainsIn_cons_true_cases_core
                      queryLeft
                      queryRight
                      (Prod.mk left right)
                      small
                      hNext
              | false =>
                  have hIndexed :
                      psKernelExprPairSetContainsIn
                          queryLeft
                          queryRight
                          (psKernelExprPairSetIndexBucket
                            16
                            (psKernelExprPairSetBuildIndex next)
                            (psKernelExprPairHash
                              queryLeft
                              queryRight)) =
                        true := by
                    simpa [
                      psKernelExprPairSetInsert,
                      hExisting,
                      next,
                      hFits,
                      psKernelExprPairSetContains
                    ] using hContains
                  have hList :
                      psKernelExprPairSetContainsIn
                          queryLeft
                          queryRight
                          next =
                        true :=
                    psKernelExprPairSetBuildIndex_contains_sound_core
                      next
                      queryLeft
                      queryRight
                      hIndexed
                  exact
                    psKernelExprPairSetContainsIn_cons_true_cases_core
                      queryLeft
                      queryRight
                      (Prod.mk left right)
                      small
                      hList
      | some index =>
          let hash :=
            psKernelExprPairHash left right
          let bucket :=
            psKernelExprPairSetIndexBucket
              16
              index
              hash
          cases hExisting :
              psKernelExprPairSetContainsIn
                left
                right
                bucket with
          | true =>
              right
              simpa [
                psKernelExprPairSetInsert,
                hash,
                bucket,
                hExisting,
                psKernelExprPairSetContains
              ] using hContains
          | false =>
              by_cases hHash :
                  hash =
                    psKernelExprPairHash queryLeft queryRight
              · have hBucket :
                    psKernelExprPairSetIndexBucket
                        16
                        (psKernelExprPairSetIndexSet
                          16
                          index
                          hash
                          (List.cons
                            (Prod.mk left right)
                            bucket))
                        (psKernelExprPairHash queryLeft queryRight) =
                      List.cons
                        (Prod.mk left right)
                        bucket := by
                  rw [← hHash]
                  exact
                    psKernelExprPairSetIndexBucket_set_same_core
                      16
                      index
                      hash
                      (List.cons
                        (Prod.mk left right)
                        bucket)
                have hNew :
                    psKernelExprPairSetContainsIn
                        queryLeft
                        queryRight
                        (List.cons
                          (Prod.mk left right)
                          bucket) =
                      true := by
                  simpa [
                    psKernelExprPairSetInsert,
                    hash,
                    bucket,
                    hExisting,
                    psKernelExprPairSetContains,
                    hBucket
                  ] using hContains
                rcases
                    psKernelExprPairSetContainsIn_cons_true_cases_core
                      queryLeft
                      queryRight
                      (Prod.mk left right)
                      bucket
                      hNew with
                  hHead | hRest
                · exact Or.inl hHead
                · right
                  change
                    psKernelExprPairSetContainsIn
                        queryLeft
                        queryRight
                        (psKernelExprPairSetIndexBucket
                          16
                          index
                          (psKernelExprPairHash
                            queryLeft
                            queryRight)) =
                      true
                  rw [← hHash]
                  exact hRest
              · right
                have hRouted :
                    psKernelExprPairSetIndexBucket
                        16
                        (psKernelExprPairSetIndexSet
                          16
                          index
                          hash
                          (List.cons
                            (Prod.mk left right)
                            bucket))
                        (psKernelExprPairHash queryLeft queryRight) =
                      psKernelExprPairSetIndexBucket
                        16
                        index
                        (psKernelExprPairHash queryLeft queryRight) :=
                  psKernelExprPairSetIndexBucket_set_other_hash_core
                    index
                    hash
                    (psKernelExprPairHash queryLeft queryRight)
                    (List.cons
                      (Prod.mk left right)
                      bucket)
                    (psKernelExprPairHash_lt_two_pow_16_core
                      left right)
                    (psKernelExprPairHash_lt_two_pow_16_core
                      queryLeft queryRight)
                    hHash
                simpa [
                  psKernelExprPairSetInsert,
                  hash,
                  bucket,
                  hExisting,
                  psKernelExprPairSetContains,
                  hRouted
                ] using hContains

theorem psKernelDefEqCacheInsertLaw_all :
    PsKernelDefEqCacheInsertLaw := by
  intro environment localContext cache left right hCache hDefEq
  intro queryLeft queryRight hContains
  rcases
      psKernelExprPairSetContains_insert_sound_core
        cache
        left
        right
        queryLeft
        queryRight
        hContains with
    hInserted | hOld
  · rcases
        psKernelExprPairEq_true_refines_presentation_core
          queryLeft
          queryRight
          left
          right
          hInserted with
      hDirect | hSwapped
    · exact
        PsKernelDefEqJudgment.presentation
          left
          right
          queryLeft
          queryRight
          hDirect.1
          hDefEq
          hDirect.2
    · exact
        PsKernelDefEqJudgment.presentation
          right
          left
          queryLeft
          queryRight
          hSwapped.2
          (PsKernelDefEqJudgment.symm
            left
            right
            hDefEq)
          hSwapped.1
  · exact
      hCache
        queryLeft
        queryRight
        hOld
