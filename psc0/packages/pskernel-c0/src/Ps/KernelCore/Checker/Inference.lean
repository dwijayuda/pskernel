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
recursion depth of the original recursive walk. Application frames share the
immutable operation context instead of retaining full context snapshots.
The head and each argument still go through ordinary checked inference; Pi exposure,
DefEq, eagerReduce and single-binder substitution retain their original
order. This path must be differentially qualified before production promotion.

Unlike infer-only inference, a fully checked application cannot skip any
argument checks or use the infer-only cache. The existing cache policy never
caches checked application nodes, so flattening these frames cannot bypass
a valid cached application judgment.
-/
/-- A frame retains only its argument, checked-inference fuel and the exact
    recursion depth of the historical application walk. All other context
    fields are shared immutable data belonging to one checking operation. -/
structure PsKernelC0CheckedAppFrame where
  argument : PsKernelExpr
  fuel : Nat
  recDepth : Nat

structure PsKernelC0CheckedAppPath where
  head : PsKernelExpr
  headRecDepth : Nat
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
                   fuel := remaining
                   recDepth := nextContext.recDepth } :: frames)
  | _ =>
      Except.ok {
        head := expr
        headRecDepth := context.recDepth
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
    (baseContext : PsKernelCheckerContext)
    (frames : List PsKernelC0CheckedAppFrame)
    (bodyRanges : List Nat)
    (current : PsKernelExpr)
    (state : PsKernelCheckerState) :
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match frames with
  | [] => Except.ok (current, state)
  | frame :: tail => do
      -- Restore only the historical recursion depth on demand. The stored
      -- base context retains environment, locals, safety and native evaluator.
      let frameContext := { baseContext with recDepth := frame.recDepth }
      let (view, state1) ←
        psKernelEnsureForallWith whnf frameContext state current
      let (argType, state2) ←
        psKernelInferCoreWithFuel frame.fuel whnf defeq
          frameContext state1 frame.argument false
      let state3 ←
        if psKernelExprEq argType view.domain then
          Except.ok state2
        else
          let eqContext :=
            if psKernelExprIsEagerReduce frame.argument then
              psKernelCheckerContextWithEagerReduce frameContext true
            else frameContext
          match defeq eqContext state2 argType view.domain with
          | Except.error error => Except.error error
          | Except.ok (true, nextState) => Except.ok nextState
          | Except.ok (false, _) =>
              Except.error "application type mismatch"
      -- A range of zero means this *exact* Pi body has no loose
      -- de Bruijn variable. Instantiation would return it unchanged.
      -- Non-Pi exposure or any dependent instantiation invalidates all
      -- precomputed suffix metadata and uses the original worker.
      let (nextType, nextRanges) :=
        match current, bodyRanges with
        | .forallE _ _ _ _, range :: suffixes =>
            if range == 0 then
              (view.body, suffixes)
            else
              (psKernelExprInstantiate1 view.body frame.argument, [])
        | _, _ =>
            (psKernelExprInstantiate1 view.body frame.argument, [])
      psKernelC0CheckAppFrames whnf defeq baseContext tail nextRanges
        nextType state3

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
      { context with recDepth := path.headRecDepth }
      state path.head false
  -- Only large spines amortize a bounded full-suffix analysis. Short
  -- or unsupported spines keep exact historical substitution behavior.
  let ranges :=
    if path.frames.length < 32 then
      []
    else
      match psKernelC0PiBodyRangesWithFuel (Nat.min 1024 fuel) headType with
      | some (_, suffixes) => suffixes
      | none => []
  psKernelC0CheckAppFrames whnf defeq context path.frames ranges
    headType headState

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
  -- Use the exact-frame/Pi-range checked route for medium and large
  -- application spines. Smaller applications retain historical recursive
  -- checking to avoid frame allocation overhead. The 32-argument boundary
  -- is checked by independent recursive differential and same-run original
  -- kernel whole-checker benchmarks; this is a routing heuristic only.
  match expr with
  | .app _ _ =>
      if psKernelExprGetAppNumArgs expr >= 32 then
        psKernelC0CheckAppSpineWithFuel
          fuel whnf defeq context state expr
      else
        psKernelInferCoreWithFuel
          fuel whnf defeq context state expr false
  | _ =>
      psKernelInferCoreWithFuel
        fuel whnf defeq context state expr false
