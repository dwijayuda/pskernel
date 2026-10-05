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
