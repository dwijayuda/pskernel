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
              key
              (psKernelExprMapIndexBucket
                16
                index
                (psKernelExprHash key))
              (by
                rw [
                  ← psKernelExprEq_symm_core
                    key
                    query
                ]
                exact hMatch)

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
