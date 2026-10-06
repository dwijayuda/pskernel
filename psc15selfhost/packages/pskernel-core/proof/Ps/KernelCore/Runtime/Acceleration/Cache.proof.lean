import Ps.KernelCore.Runtime.Acceleration.Cache
import Ps.KernelCore.Metatheory.CacheIndexRefinement

theorem psKernelExprMapGetIn_nil
    (expr : PsKernelExpr) :
    psKernelExprMapGetIn expr List.nil = Option.none := by
  rfl

theorem psKernelExprMapGet_empty
    (expr : PsKernelExpr) :
    psKernelExprMapGet psKernelExprMapEmpty expr = Option.none := by
  rfl

theorem psKernelExprPairSetContainsIn_nil
    (left right : PsKernelExpr) :
    psKernelExprPairSetContainsIn
        left right List.nil =
      false := by
  rfl

theorem psKernelExprPairSetContains_empty
    (left right : PsKernelExpr) :
    psKernelExprPairSetContains
        psKernelExprPairSetEmpty
        left right =
      false := by
  rfl

theorem psKernelCacheEntryListLength_eq_length
    (entries : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelCacheEntryListLength entries =
      List.length entries := by
  induction entries with
  | nil =>
      rfl
  | cons head tail ih =>
      simp [psKernelCacheEntryListLength, ih]


theorem psKernelExprMapGetIn_insertIn_self
    (expr value : PsKernelExpr)
    (entries : List (Prod PsKernelExpr PsKernelExpr))
    (hRefl : psKernelExprEq expr expr = true) :
    psKernelExprMapGetIn
        expr
        (psKernelExprMapInsertIn
          expr
          value
          entries) =
      Option.some value := by
  induction entries with
  | nil =>
      simp [
        psKernelExprMapInsertIn,
        psKernelExprMapGetIn,
        hRefl
      ]
  | cons entry rest ih =>
      cases hHead :
          psKernelExprEq
            (Prod.fst entry)
            expr <;>
        simp [
          psKernelExprMapInsertIn,
          psKernelExprMapGetIn,
          hHead,
          hRefl,
          ih
        ]

theorem psKernelExprMapIndexBucket_set_same
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
        by_cases hParity : Nat.mod hash 2 = 0 <;>
        simp [
          psKernelExprMapIndexSet,
          psKernelExprMapIndexBucket,
          hParity,
          ih
        ]


theorem psKernelExprPairEq_self
    (left right : PsKernelExpr)
    (hLeft : psKernelExprEq left left = true)
    (hRight : psKernelExprEq right right = true) :
    psKernelExprPairEq
        left
        right
        (Prod.mk left right) =
      true := by
  simp [
    psKernelExprPairEq,
    hLeft,
    hRight
  ]

theorem psKernelExprPairSetContainsIn_cons_self
    (left right : PsKernelExpr)
    (rest : List (Prod PsKernelExpr PsKernelExpr))
    (hLeft : psKernelExprEq left left = true)
    (hRight : psKernelExprEq right right = true) :
    psKernelExprPairSetContainsIn
        left
        right
        (List.cons
          (Prod.mk left right)
          rest) =
      true := by
  simp [
    psKernelExprPairSetContainsIn,
    psKernelExprPairEq_self,
    hLeft,
    hRight
  ]

theorem psKernelExprPairSetIndexBucket_set_same
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
  induction fuel generalizing index hash with
  | zero =>
      rfl
  | succ remaining ih =>
      cases index <;>
        by_cases hParity : Nat.mod hash 2 = 0 <;>
        simp [
          psKernelExprPairSetIndexSet,
          psKernelExprPairSetIndexBucket,
          hParity,
          ih
        ]


theorem psKernelExprMapIndexBucket_build_cons
    (entry : Prod PsKernelExpr PsKernelExpr)
    (rest : List (Prod PsKernelExpr PsKernelExpr)) :
    psKernelExprMapIndexBucket
        16
        (psKernelExprMapBuildIndex
          (List.cons entry rest))
        (psKernelExprHash (Prod.fst entry)) =
      psKernelExprMapInsertIn
        (Prod.fst entry)
        (Prod.snd entry)
        (psKernelExprMapIndexBucket
          16
          (psKernelExprMapBuildIndex rest)
          (psKernelExprHash (Prod.fst entry))) := by
  change
    psKernelExprMapIndexBucket
        16
        (psKernelExprMapIndexSet
          16
          (psKernelExprMapBuildIndex rest)
          (psKernelExprHash (Prod.fst entry))
          (psKernelExprMapInsertIn
            (Prod.fst entry)
            (Prod.snd entry)
            (psKernelExprMapIndexBucket
              16
              (psKernelExprMapBuildIndex rest)
              (psKernelExprHash (Prod.fst entry)))))
        (psKernelExprHash (Prod.fst entry)) =
      psKernelExprMapInsertIn
        (Prod.fst entry)
        (Prod.snd entry)
        (psKernelExprMapIndexBucket
          16
          (psKernelExprMapBuildIndex rest)
          (psKernelExprHash (Prod.fst entry)))
  exact
    psKernelExprMapIndexBucket_set_same
      16
      (psKernelExprMapBuildIndex rest)
      (psKernelExprHash (Prod.fst entry))
      (psKernelExprMapInsertIn
        (Prod.fst entry)
        (Prod.snd entry)
        (psKernelExprMapIndexBucket
          16
          (psKernelExprMapBuildIndex rest)
          (psKernelExprHash (Prod.fst entry))))

theorem psKernelExprMapGet_build_cons_self
    (expr value : PsKernelExpr)
    (rest : List (Prod PsKernelExpr PsKernelExpr))
    (hRefl : psKernelExprEq expr expr = true) :
    psKernelExprMapGet
        {
          small := List.nil
          index :=
            Option.some
              (psKernelExprMapBuildIndex
                (List.cons
                  (Prod.mk expr value)
                  rest))
        }
        expr =
      Option.some value := by
  change
    psKernelExprMapGetIn
        expr
        (psKernelExprMapIndexBucket
          16
          (psKernelExprMapBuildIndex
            (List.cons
              (Prod.mk expr value)
              rest))
          (psKernelExprHash expr)) =
      Option.some value
  have hBucket :
      psKernelExprMapIndexBucket
          16
          (psKernelExprMapBuildIndex
            (List.cons
              (Prod.mk expr value)
              rest))
          (psKernelExprHash expr) =
        psKernelExprMapInsertIn
          expr
          value
          (psKernelExprMapIndexBucket
            16
            (psKernelExprMapBuildIndex rest)
            (psKernelExprHash expr)) := by
    simpa using
      psKernelExprMapIndexBucket_build_cons
        (Prod.mk expr value)
        rest
  rw [hBucket]
  exact
    psKernelExprMapGetIn_insertIn_self
      expr
      value
      (psKernelExprMapIndexBucket
        16
        (psKernelExprMapBuildIndex rest)
        (psKernelExprHash expr))
      hRefl

theorem psKernelExprMapGet_insert_small_self
    (small : List (Prod PsKernelExpr PsKernelExpr))
    (expr value : PsKernelExpr)
    (hRefl : psKernelExprEq expr expr = true)
    (hFits :
      Nat.ble
          (psKernelCacheEntryListLength
            (psKernelExprMapInsertIn expr value small))
          psKernelCacheSmallLimit =
        true) :
    psKernelExprMapGet
        (psKernelExprMapInsert
          {
            small := small
            index := Option.none
          }
          expr
          value)
        expr =
      Option.some value := by
  simp [
    psKernelExprMapInsert,
    hFits,
    psKernelExprMapGet,
    psKernelExprMapGetIn_insertIn_self,
    hRefl
  ]

theorem psKernelExprMapGet_insert_indexed_self
    (small : List (Prod PsKernelExpr PsKernelExpr))
    (index : PsKernelExprMapIndex)
    (expr value : PsKernelExpr)
    (hRefl : psKernelExprEq expr expr = true) :
    psKernelExprMapGet
        (psKernelExprMapInsert
          {
            small := small
            index := Option.some index
          }
          expr
          value)
        expr =
      Option.some value := by
  simp [
    psKernelExprMapInsert,
    psKernelExprMapGet,
    psKernelExprMapIndexBucket_set_same,
    psKernelExprMapGetIn_insertIn_self,
    hRefl
  ]


theorem psKernelExprMapGetIn_insertIn_other
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

theorem psKernelExprMapGetIn_insertIn_match
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

theorem psKernelExprMapBuildIndex_refines_get
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
              psKernelExprMapIndexBucket_set_same
                16
                oldIndex
                (psKernelExprHash key)
                newBucket
          rw [hBucket]
          have hLeft :
              psKernelExprMapGetIn query newBucket =
                Option.some value := by
            exact
              psKernelExprMapGetIn_insertIn_match
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
                psKernelExprMapIndexBucket_set_same
                  16
                  oldIndex
                  (psKernelExprHash key)
                  newBucket
            rw [hBucket]
            rw [
              psKernelExprMapGetIn_insertIn_other
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

theorem psKernelExprMapGet_insert_self
    (cache : PsKernelExprMap)
    (expr value : PsKernelExpr)
    (hRefl : psKernelExprEq expr expr = true) :
    psKernelExprMapGet
        (psKernelExprMapInsert cache expr value)
        expr =
      Option.some value := by
  cases cache with
  | mk small index =>
      cases index with
      | none =>
          cases hFits :
              Nat.ble
                (psKernelCacheEntryListLength
                  (psKernelExprMapInsertIn
                    expr
                    value
                    small))
                psKernelCacheSmallLimit with
          | true =>
              exact
                psKernelExprMapGet_insert_small_self
                  small expr value hRefl hFits
          | false =>
              simp [
                psKernelExprMapInsert,
                hFits,
                psKernelExprMapGet
              ]
              rw [
                psKernelExprMapBuildIndex_refines_get
                  (psKernelExprMapInsertIn
                    expr
                    value
                    small)
                  expr
              ]
              exact
                psKernelExprMapGetIn_insertIn_match
                  expr value expr small hRefl
      | some index =>
          exact
            psKernelExprMapGet_insert_indexed_self
              small index expr value hRefl


theorem psKernelExprPairSetBuildIndex_contains_cons_self
    (left right : PsKernelExpr)
    (rest : List (Prod PsKernelExpr PsKernelExpr))
    (hLeft : psKernelExprEq left left = true)
    (hRight : psKernelExprEq right right = true) :
    psKernelExprPairSetContainsIn
        left
        right
        (psKernelExprPairSetIndexBucket
          16
          (psKernelExprPairSetBuildIndex
            (List.cons
              (Prod.mk left right)
              rest))
          (psKernelExprPairHash left right)) =
      true := by
  let oldIndex :=
    psKernelExprPairSetBuildIndex rest
  let oldBucket :=
    psKernelExprPairSetIndexBucket
      16
      oldIndex
      (psKernelExprPairHash left right)
  cases hExisting :
      psKernelExprPairSetContainsIn
        left
        right
        oldBucket with
  | true =>
      simpa [
        psKernelExprPairSetBuildIndex,
        oldIndex,
        oldBucket,
        hExisting
      ] using hExisting
  | false =>
      have hBuild :
          psKernelExprPairSetBuildIndex
              (List.cons
                (Prod.mk left right)
                rest) =
            psKernelExprPairSetIndexSet
              16
              oldIndex
              (psKernelExprPairHash left right)
              (List.cons
                (Prod.mk left right)
                oldBucket) := by
        simp [
          psKernelExprPairSetBuildIndex,
          oldIndex,
          oldBucket,
          hExisting
        ]
      rw [hBuild]
      rw [
        psKernelExprPairSetIndexBucket_set_same
          16
          oldIndex
          (psKernelExprPairHash left right)
          (List.cons
            (Prod.mk left right)
            oldBucket)
      ]
      exact
        psKernelExprPairSetContainsIn_cons_self
          left
          right
          oldBucket
          hLeft
          hRight

theorem psKernelExprPairSetContains_insert_self
    (set : PsKernelExprPairSet)
    (left right : PsKernelExpr)
    (hLeft : psKernelExprEq left left = true)
    (hRight : psKernelExprEq right right = true) :
    psKernelExprPairSetContains
        (psKernelExprPairSetInsert set left right)
        left
        right =
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
              simp [
                psKernelExprPairSetInsert,
                hExisting,
                psKernelExprPairSetContains
              ]
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
                  simp [
                    psKernelExprPairSetInsert,
                    hExisting,
                    next,
                    hFits,
                    psKernelExprPairSetContains,
                    psKernelExprPairSetContainsIn_cons_self,
                    hLeft,
                    hRight
                  ]
              | false =>
                  simp [
                    psKernelExprPairSetInsert,
                    hExisting,
                    next,
                    hFits,
                    psKernelExprPairSetContains
                  ]
                  exact
                    psKernelExprPairSetBuildIndex_contains_cons_self
                      left
                      right
                      small
                      hLeft
                      hRight
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
              simp [
                psKernelExprPairSetInsert,
                hash,
                bucket,
                hExisting,
                psKernelExprPairSetContains
              ]
          | false =>
              simp [
                psKernelExprPairSetInsert,
                hash,
                bucket,
                hExisting,
                psKernelExprPairSetContains
              ]
              rw [
                psKernelExprPairSetIndexBucket_set_same
                  16
                  index
                  hash
                  (List.cons
                    (Prod.mk left right)
                    bucket)
              ]
              exact
                psKernelExprPairSetContainsIn_cons_self
                  left
                  right
                  bucket
                  hLeft
                  hRight
