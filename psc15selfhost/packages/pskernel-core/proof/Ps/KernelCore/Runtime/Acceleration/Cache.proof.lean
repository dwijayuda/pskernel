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
