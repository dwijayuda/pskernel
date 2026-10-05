import Ps.KernelCore.Runtime.Acceleration.Cache

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
  unfold psKernelExprMapGet
  rw [psKernelExprMapIndexBucket_build_cons]
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
