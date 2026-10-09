import Ps.KernelCore.Checker.DefEq.Quick

theorem psKernelDefEqQuick_expr_equal
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (h : psKernelExprEq left right = true) :
    psKernelDefEqQuick
        defeq context state left right =
      Except.ok
        (Prod.mk (Option.some true) state) := by
  simp [psKernelDefEqQuick, h]

theorem psKernelDefEqQuick_success_cache
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (hEq : psKernelExprEq left right = false)
    (hEligible :
      psKernelSemanticPairCacheEligible left right =
        true)
    (hCache :
      psKernelExprPairSetContains
        state.success left right =
      true) :
    psKernelDefEqQuick
        defeq context state left right =
      Except.ok
        (Prod.mk (Option.some true) state) := by
  simp [
    psKernelDefEqQuick,
    hEq,
    hEligible,
    hCache
  ]

theorem psKernelLevelListsEquivalent_nil_nil :
    psKernelLevelListsEquivalent
        List.nil List.nil =
      true := by
  rfl

theorem psKernelLevelListsEquivalent_nil_cons
    (head : PsKernelLevel)
    (tail : List PsKernelLevel) :
    psKernelLevelListsEquivalent
        List.nil
        (List.cons head tail) =
      false := by
  rfl


theorem psKernelDefEqQuick_fvar_ignores_success_cache
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (right : PsKernelExpr)
    (hEq :
      psKernelExprEq
          (PsKernelExpr.fvar name)
          right =
        false) :
    psKernelDefEqQuick
        defeq
        context
        state
        (PsKernelExpr.fvar name)
        right =
      Except.ok (Prod.mk Option.none state) := by
  simp [
    psKernelDefEqQuick,
    hEq,
    psKernelSemanticPairCacheEligible,
    psKernelSemanticCacheEligible,
    psKernelExprHasFVar
  ]
