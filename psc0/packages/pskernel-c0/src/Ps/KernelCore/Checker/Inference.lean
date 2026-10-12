import Ps.KernelCore.Checker.Inference.Core

/-
Public inference/check entry points.

`psKernelInferWithFuel` performs inference-only checking.
`psKernelCheckWithFuel` performs the fully checked path.
Both delegate to the same syntax-directed core so the semantic difference is
explicit and small.
-/

def psKernelInferWithFuel
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
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
  psKernelInferCoreWithFuel
    fuel
    whnf
    defeq
    context
    state
    expr
    true

/-
Experimental complete checked-application spine with explicit frames.

Every application node is assigned the exact decreasing inference fuel and
recursion-depth context of the original recursive walk. The head and each
argument still go through ordinary, fully checked core inference; Pi exposure,
DefEq, eagerReduce and single-binder substitution retain their original
order. This path must be differentially qualified before production promotion.

Unlike infer-only inference, a fully checked application cannot skip any
argument checks or use the infer-only cache. The existing cache policy never
caches checked application nodes, so flattening these frames cannot bypass
a valid cached application judgment.
-/
structure PsKernelC0CheckedAppFrame where
  argument : PsKernelExpr
  context : PsKernelCheckerContext
  fuel : Nat

structure PsKernelC0CheckedAppPath where
  head : PsKernelExpr
  context : PsKernelCheckerContext
  fuel : Nat
  frames : List PsKernelC0CheckedAppFrame

def psKernelC0CollectCheckedAppPath
    (expr : PsKernelExpr)
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (frames : List PsKernelC0CheckedAppFrame) :
    Except String PsKernelC0CheckedAppPath :=
  match expr with
  | .app fn arg =>
      match fuel with
      | 0 => Except.error "kernel inference budget exhausted"
      | Nat.succ remaining =>
          match psKernelCheckerContextEnterRecDepth context with
          | Except.error error => Except.error error
          | Except.ok nextContext =>
              psKernelC0CollectCheckedAppPath
                fn remaining nextContext
                ({ argument := arg
                   context := nextContext
                   fuel := remaining } :: frames)
  | _ =>
      Except.ok {
        head := expr
        context := context
        fuel := fuel
        frames := frames
      }

def psKernelC0CheckAppFrames
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (frames : List PsKernelC0CheckedAppFrame)
    (current : PsKernelExpr)
    (state : PsKernelCheckerState) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match frames with
  | [] => Except.ok (current, state)
  | frame :: tail => do
      let (view, state1) ←
        psKernelEnsureForallWith whnf frame.context state current
      let (argType, state2) ←
        psKernelInferCoreWithFuel frame.fuel whnf defeq
          frame.context state1 frame.argument false
      let state3 ←
        if psKernelExprEq argType view.domain then
          Except.ok state2
        else
          let eqContext :=
            if psKernelExprIsEagerReduce frame.argument then
              psKernelCheckerContextWithEagerReduce frame.context true
            else frame.context
          match defeq eqContext state2 argType view.domain with
          | Except.error error => Except.error error
          | Except.ok (true, nextState) => Except.ok nextState
          | Except.ok (false, _) =>
              Except.error "application type mismatch"
      psKernelC0CheckAppFrames whnf defeq tail
        (psKernelExprInstantiate1 view.body frame.argument) state3

/-- Candidate exact checked spine, not yet used by production checking. -/
def psKernelC0CheckAppSpineWithFuel
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) := do
  let path ← psKernelC0CollectCheckedAppPath expr fuel context []
  let (headType, headState) ←
    psKernelInferCoreWithFuel path.fuel whnf defeq
      path.context state path.head false
  psKernelC0CheckAppFrames whnf defeq path.frames headType headState

def psKernelCheckWithFuel
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
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
  psKernelInferCoreWithFuel
    fuel
    whnf
    defeq
    context
    state
    expr
    false
