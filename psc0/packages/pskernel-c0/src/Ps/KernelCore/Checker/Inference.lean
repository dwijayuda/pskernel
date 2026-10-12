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

/-
Alternative checked-application execution substrate.

This worker carries exact Pi suffix metadata alongside a recursive, fuel-indexed
application walk. It avoids allocating a separate frame list and reconstructing
the spine context. Every node enters the original recursion context, checks the
head before its argument, preserves the same decreased fuel for both, uses the
same WHNF, checked inference, DefEq, eager-reduction, and substitution rules.

Only a syntactically unchanged Pi body with exact loose range zero may bypass
the old substitution worker. Dependent substitutions and exposed/non-Pi heads
discard the suffix metadata and fall back. Routing requires whole checked-operation performance and independent
positive/negative/resource equivalence before deployment.
-/
/-- A bounded syntactic shape probe before a potentially useful
    re-analysis. Nothing in this predicate determines typing or conversion. -/
def psKernelC0HasPiPrefix : Nat -> PsKernelExpr -> Bool
  | 0, _ => true
  | n + 1, .forallE _ _ body _ =>
      psKernelC0HasPiPrefix n body
  | _ + 1, _ => false

structure PsKernelC0CheckedAppSummary where
  type : PsKernelExpr
  state : PsKernelCheckerState
  bodyRanges : List Nat

def psKernelC0CheckAppRecursiveWithFuelMode
    (fuel : Nat)
    (rangeFuel : Nat)
    (rebuildRanges : Bool) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Except String PsKernelC0CheckedAppSummary :=
  match fuel with
  | 0 =>
      fun _ _ _ _ _ => Except.error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelC0CheckAppRecursiveWithFuelMode
          remaining rangeFuel rebuildRanges
      fun whnf defeq context state expr =>
        match expr with
        | .app fn arg => do
            let nextContext ← psKernelCheckerContextEnterRecDepth context
            let inferredFn ← smaller whnf defeq nextContext state fn
            let (view, state1) ←
              psKernelEnsureForallWith whnf nextContext
                inferredFn.state inferredFn.type
            let (argType, state2) ←
              -- A checked wide application used as another application's
              -- argument retains the exact remaining fuel and context.
              -- Only the syntactic application family uses this structural
              -- callback; all other argument expressions keep the original
              -- checked worker and its acceptance/cache behavior.
              match arg with
              | .app _ _ =>
                  if psKernelExprGetAppNumArgs arg >= 16 then
                    let nested ← smaller whnf defeq nextContext state1 arg
                    Except.ok (nested.type, nested.state)
                  else
                    psKernelInferCoreWithFuel remaining whnf defeq
                      nextContext state1 arg false
              | _ =>
                  psKernelInferCoreWithFuel remaining whnf defeq
                    nextContext state1 arg false
            let nextState ←
              if psKernelExprEq argType view.domain then
                Except.ok state2
              else
                let eqContext :=
                  if psKernelExprIsEagerReduce arg then
                    psKernelCheckerContextWithEagerReduce nextContext true
                  else nextContext
                match defeq eqContext state2 argType view.domain with
                | Except.error error => Except.error error
                | Except.ok (true, approvedState) =>
                    Except.ok approvedState
                | Except.ok (false, _) =>
                    Except.error "application type mismatch"
            let (resultType, inheritedRanges, changedBySubst) :=
              match inferredFn.type, inferredFn.bodyRanges with
              | .forallE _ _ _ _, range :: suffix =>
                  if range == 0 then
                    (view.body, suffix, false)
                  else
                    (psKernelExprInstantiate1 view.body arg, [], true)
              | _, _ =>
                  (psKernelExprInstantiate1 view.body arg, [], false)
            -- A dependent substitution invalidates the old suffix summary,
            -- but it can expose a long newly closed Pi tail. Recompute an
            -- exact bounded syntax summary at most once at this boundary.
            -- Short tails, unknown shapes or metadata-budget exhaustion
            -- keep the historical substitution behavior unchanged.
            let nextRanges :=
              if rebuildRanges && changedBySubst &&
                  psKernelC0HasPiPrefix 12 resultType then
                match psKernelC0PiBodyRangesWithFuel rangeFuel resultType with
                | some (_, suffix) => suffix
                | none => inheritedRanges
              else
                inheritedRanges
            pure {
              type := resultType
              state := nextState
              bodyRanges := nextRanges
            }
        | _ => do
            let (inferred, nextState) ←
              psKernelInferCoreWithFuel (Nat.succ remaining)
                whnf defeq context state expr false
            let ranges :=
              match psKernelC0PiBodyRangesWithFuel rangeFuel inferred with
              | some (_, suffix) => suffix
              | none => []
            pure {
              type := inferred
              state := nextState
              bodyRanges := ranges
            }

/-- Historical metadata-invalidation mode, retained as the exact
    accepting-path performance comparison. -/
def psKernelC0CheckAppRecursiveWithFuel
    (fuel : Nat) (rangeFuel : Nat) :=
  psKernelC0CheckAppRecursiveWithFuelMode fuel rangeFuel false

/-- Source-native, fuel-indexed checked application execution; production
    for selected root spines, with independent recursive and frame oracles. -/
def psKernelC0CheckAppRecursive
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
  let result ← psKernelC0CheckAppRecursiveWithFuelMode fuel
    (Nat.min 1024 fuel) false whnf defeq context state expr
  pure (result.type, result.state)

/-- Qualified exact suffix-reanalysis route for accepting checked
    applications. Independent old C0 metadata invalidation, recursive
    inference and explicit-frame workers remain separately callable. -/
def psKernelC0CheckAppRecursiveResummarized
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
  let result ← psKernelC0CheckAppRecursiveWithFuelMode fuel
    (Nat.min 1024 fuel) true whnf defeq context state expr
  pure (result.type, result.state)

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
  -- Selected root application spines use one exact fuel-indexed checked walk
  -- that can rebuild syntactic Pi ranges after dependent substitution.
  -- Only sufficiently long remaining Pi tails pay for a rescan. Unchanged
  -- original inference and the old C0 mode stay independent test oracles.
  match expr with
  | .app _ _ =>
      if psKernelExprGetAppNumArgs expr >= 16 then
        psKernelC0CheckAppRecursiveResummarized
          fuel whnf defeq context state expr
      else
        psKernelInferCoreWithFuel
          fuel whnf defeq context state expr false
  | _ =>
      -- Non-application roots preserve their existing syntax-directed rules.
      -- The optional callback reaches checked application subterms inside
      -- lambda/forall/let/metadata/projection inference without duplicating
      -- those rules or changing infer-only judgments.
      psKernelInferCoreWithFuelUsing
        fuel (some psKernelC0CheckAppRecursiveResummarized)
        whnf defeq context state expr false
