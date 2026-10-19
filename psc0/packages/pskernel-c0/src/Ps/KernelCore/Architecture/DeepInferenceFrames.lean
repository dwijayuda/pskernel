import Ps.KernelCore.Checker.Inference

/-!
Experimental, non-admitting checked application frame machine.

The existing C0 recursive application evaluator remains the production checker.
This module evaluates the same *already recorded* application frames using a
fold over an explicit machine state rather than recursively retaining the
pending application call stack. It preserves frame-local inference fuel and
recursion depth; WHNF, checked argument inference, DefEq, eager-reduction,
source capture-avoiding substitution, and all state threading remain the
existing checker operations.

The bounded Pi-body-range summary is only a non-authoritative no-op
substitution hint. If a binder may be dependent, or a Pi is revealed by WHNF,
the source psKernelExprInstantiate1 path is mandatory. This experimental
machine is NOT a trusted admission path; promotion requires source
equivalence, resource-error parity, negative tests, real Arena acceptance,
and bounded memory at exactly the existing fuel policy.
-/

/-- Each continuation stores only the current type, checker state, and
    optional exact syntax-derived Pi-body ranges. No global cache or hidden
    context-sensitive type judgment is stored in the continuation. -/
structure PsKernelC0DeepFrameState where
  current : PsKernelExpr
  checker : PsKernelCheckerState
  bodyRanges : List Nat

/-- One checked application continuation: WHNF before argument inference,
    then original argument/domain equality and DefEq, then original
    capture-avoiding substitution. The recursion depth/fuel come from the
    source-collected frame, not from the fold index. -/
def psKernelC0DeepFrameStep
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (baseContext : PsKernelCheckerContext)
    (acc : PsKernelC0DeepFrameState)
    (frame : PsKernelC0CheckedAppFrame) :
    Except String PsKernelC0DeepFrameState := do
  let frameContext := { baseContext with recDepth := frame.recDepth }
  let (view, state1) ←
    psKernelEnsureForallWith whnf frameContext acc.checker acc.current
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
      | .error error => .error error
      | .ok (true, nextState) => .ok nextState
      | .ok (false, _) => .error "application type mismatch"
  -- A zero syntactic range comes only from the same immutable Pi body
  -- already analyzed by C0's source frame walker. No hint can approve
  -- a type, proof, DefEq result or a new environment declaration.
  let (nextType, nextRanges) :=
    match acc.current, acc.bodyRanges with
    | .forallE _ _ _ _, range :: suffix =>
        if range == 0 then
          (view.body, suffix)
        else
          (psKernelExprInstantiate1 view.body frame.argument, [])
    | _, _ =>
        (psKernelExprInstantiate1 view.body frame.argument, [])
  pure {
    current := nextType
    checker := state3
    bodyRanges := nextRanges
  }

/-- Stack-independent continuation traversal. List.foldlM owns the ordered
    pending frames, while the original checker owns every semantic step. -/
def psKernelC0DeepFrameFold
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (baseContext : PsKernelCheckerContext)
    (frames : List PsKernelC0CheckedAppFrame)
    (ranges : List Nat)
    (initialType : PsKernelExpr)
    (initialState : PsKernelCheckerState) :
    Except String (PsKernelExpr × PsKernelCheckerState) := do
  let final ← frames.foldlM
    (psKernelC0DeepFrameStep whnf defeq baseContext)
    { current := initialType, checker := initialState, bodyRanges := ranges }
  pure (final.current, final.checker)

/-- Research-only complete spine runner. The historical source frame
    collector performs the exact per-node fuel/depth checks before any
    inference. The head is checked at the original residual fuel/depth.
    This function never installs a checker hook or publishes an axiom. -/
def psKernelC0DeepAppSpineWithFuel
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelCheckerState) := do
  let path ← psKernelC0CollectCheckedAppPath expr fuel context []
  let (headType, headState) ←
    psKernelInferCoreWithFuel path.fuel whnf defeq
      { context with recDepth := path.headRecDepth }
      state path.head false
  let ranges :=
    if path.frames.length < 32 then []
    else
      match psKernelC0PiBodyRangesWithFuel (Nat.min 1024 fuel) headType with
      | some (_, suffixes) => suffixes
      | none => []
  psKernelC0DeepFrameFold whnf defeq context path.frames ranges
    headType headState

/-- Published fuel zero still refuses even a single application frame.
    This checks the guard at the *collector* boundary, before the machine
    could perform any stateful checked inference. -/
theorem psKernelC0DeepZeroFuel
    (fn arg : PsKernelExpr) (context : PsKernelCheckerContext) :
    psKernelC0CollectCheckedAppPath (.app fn arg) 0 context [] =
      .error "kernel inference budget exhausted" := by
  rfl
