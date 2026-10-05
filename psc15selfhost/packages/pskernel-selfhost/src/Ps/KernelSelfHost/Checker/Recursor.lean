import Ps.KernelSelfHost.Checker.Recursor.Reduction

/-
Bounded recursor integration with WHNF and inference.

The public layer ties the recursor reducer back into WHNF/core-WHNF/inference
using one decreasing fuel parameter. Exhaustion rejects; it never manufactures
an accepted reduction result.
-/

def psKernelReduceRecursorBoundedWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    Bool ->
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_expr : PsKernelExpr)
        (_cheapRec : Bool)
        (_cheapProj : Bool) =>
        Except.error
          "kernel recursor budget exhausted"
  | Nat.succ remaining =>
      let nextReducer :=
        psKernelReduceRecursorBoundedWithFuel remaining;
      fun
        (defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (expr : PsKernelExpr)
        (cheapRec : Bool)
        (cheapProj : Bool) =>
        let reducer :=
          fun
            (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelCheckerState)
            (nextExpr : PsKernelExpr)
            (nextCheapRec : Bool)
            (nextCheapProj : Bool) =>
            nextReducer
              defeq
              nextContext
              nextState
              nextExpr
              nextCheapRec
              nextCheapProj;
        let publicWhnf :=
          fun
            (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelCheckerState)
            (nextExpr : PsKernelExpr) =>
            psKernelWhnfWithFuel
              remaining
              reducer
              nextContext
              nextState
              nextExpr;
        let coreWhnf :=
          fun
            (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelCheckerState)
            (nextExpr : PsKernelExpr)
            (nextCheapRec : Bool)
            (nextCheapProj : Bool) =>
            psKernelWhnfCoreWithFuel
              remaining
              publicWhnf
              reducer
              nextContext
              nextState
              nextExpr
              nextCheapRec
              nextCheapProj;
        let inferType :=
          fun
            (nextContext : PsKernelCheckerContext)
            (nextState : PsKernelCheckerState)
            (nextExpr : PsKernelExpr) =>
            psKernelInferWithFuel
              remaining
              publicWhnf
              defeq
              nextContext
              nextState
              nextExpr;
        psKernelReduceRecursorWith
          publicWhnf
          coreWhnf
          inferType
          defeq
          context
          state
          expr
          cheapRec
          cheapProj

def psKernelWhnfWithRecursorFuel
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelWhnfWithFuel
    fuel
    (psKernelReduceRecursorBoundedWithFuel
      fuel
      defeq)
    context
    state
    expr

def psKernelWhnfCoreWithRecursorFuel
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (cheapRec : Bool)
    (cheapProj : Bool) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  let reducer :=
    psKernelReduceRecursorBoundedWithFuel
      fuel
      defeq;
  psKernelWhnfCoreWithFuel
    fuel
    (psKernelWhnfWithRecursorFuel
      fuel
      defeq)
    reducer
    context
    state
    expr
    cheapRec
    cheapProj

def psKernelInferWithRecursorFuel
    (fuel : Nat)
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelInferWithFuel
    fuel
    (psKernelWhnfWithRecursorFuel
      fuel
      defeq)
    defeq
    context
    state
    expr
