import Ps.KernelCore.Metatheory.Judgments

theorem psKernelWhnfWithFuel_bvar_refines_reduction
    (remaining : Nat)
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (index : Nat) :
    psKernelWhnfWithFuel
        (Nat.succ remaining)
        reduceRecursor
        context
        state
        (PsKernelExpr.bvar index) =
      Except.ok
        (Prod.mk (PsKernelExpr.bvar index) state) ∧
    PsKernelReductionClosure
      context.environment
      context.localContext
      (PsKernelExpr.bvar index)
      (PsKernelExpr.bvar index) := by
  constructor
  · rfl
  · exact PsKernelReductionClosure.refl (PsKernelExpr.bvar index)

theorem psKernelWhnfWithFuel_sort_refines_reduction
    (remaining : Nat)
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (level : PsKernelLevel) :
    psKernelWhnfWithFuel
        (Nat.succ remaining)
        reduceRecursor
        context
        state
        (PsKernelExpr.sort level) =
      Except.ok
        (Prod.mk (PsKernelExpr.sort level) state) ∧
    PsKernelReductionClosure
      context.environment
      context.localContext
      (PsKernelExpr.sort level)
      (PsKernelExpr.sort level) := by
  constructor
  · rfl
  · exact PsKernelReductionClosure.refl (PsKernelExpr.sort level)

theorem psKernelWhnfWithFuel_mdata_refines_reduction
    (remaining : Nat)
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (metadata : Nat)
    (body result : PsKernelExpr)
    (hRun :
      psKernelWhnfWithFuel
          remaining
          reduceRecursor
          context
          state
          body =
        Except.ok (Prod.mk result nextState))
    (hSemantic :
      PsKernelReductionClosure
        context.environment
        context.localContext
        body
        result) :
    psKernelWhnfWithFuel
        (Nat.succ remaining)
        reduceRecursor
        context
        state
        (PsKernelExpr.mdata metadata body) =
      Except.ok (Prod.mk result nextState) ∧
    PsKernelReductionClosure
      context.environment
      context.localContext
      (PsKernelExpr.mdata metadata body)
      result := by
  constructor
  · simpa [psKernelWhnfWithFuel] using hRun
  · exact
      PsKernelReductionClosure.cons
        (PsKernelExpr.mdata metadata body)
        body
        result
        (PsKernelReductionStep.metadata metadata body)
        hSemantic

theorem psKernelWhnfCore_let_refines_zeta
    (remaining : Nat)
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (reduceRecursor :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod (Option PsKernelExpr) PsKernelCheckerState))
    (context nextContext : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (name : PsKernelName)
    (type value body result : PsKernelExpr)
    (nondep cheapRec cheapProj : Bool)
    (hDepth :
      psKernelCheckerContextEnterRecDepth context =
        Except.ok nextContext)
    (hCache :
      psKernelExprMapGet
          state.whnfCore
          (PsKernelExpr.letE name type value body nondep) =
        Option.none)
    (hRun :
      psKernelWhnfCoreWithFuel
          remaining
          publicWhnf
          reduceRecursor
          nextContext
          state
          (psKernelExprInstantiate1 body value)
          cheapRec
          cheapProj =
        Except.ok (Prod.mk result nextState))
    (hSemantic :
      PsKernelReductionClosure
        nextContext.environment
        nextContext.localContext
        (psKernelExprInstantiate1 body value)
        result) :
    psKernelWhnfCoreWithFuel
        (Nat.succ remaining)
        publicWhnf
        reduceRecursor
        context
        state
        (PsKernelExpr.letE name type value body nondep)
        cheapRec
        cheapProj =
      psKernelWhnfCoreFinish
        (PsKernelExpr.letE name type value body nondep)
        (Bool.or cheapRec cheapProj)
        result
        nextState ∧
    PsKernelReductionClosure
      nextContext.environment
      nextContext.localContext
      (PsKernelExpr.letE name type value body nondep)
      result := by
  constructor
  · simp [
      psKernelWhnfCoreWithFuel,
      hDepth,
      hCache,
      hRun
    ]
  · exact
      PsKernelReductionClosure.cons
        (PsKernelExpr.letE name type value body nondep)
        (psKernelExprInstantiate1 body value)
        result
        (PsKernelReductionStep.zeta name type value body nondep)
        hSemantic
