import Ps.KernelCore.Architecture.DeepBinderFrames

/-!
Research-only mixed checked application/lambda worklist.

A single small-step evaluator separates three distinct operations:
  * descent into a checked expression;
  * resumption after a checked child returns its type and full state;
  * completion of a checked binder scope.

Application and lambda continuations are represented as data rather than
retaining nested host-language calls. All remaining source checking, WHNF,
DefEq, eager-reduction, binder preparation/close and capture-avoiding force
are delegated to the original C0 operations. The original per-child `fuel`
and source recursion depth are kept exactly on descent.

IMPORTANT: the bounded historical 4096-fuel source checker already
exhausts on dag_app_binder. This worklist is NOT a proof of fuel-independent
typing soundness, and it is NEVER routed into production admission.
-/

/-- The exact suspended source checked-application and scoped checked-lambda
    stages. The function type and Pi view are never fabricated: the latter
    comes solely from the original psKernelEnsureForallWith check. -/
inductive PsKernelC0DeepMixedFrame where
  | appFunction
      (original argument : PsKernelExpr)
      (childContext : PsKernelCheckerContext)
      (childFuel : Nat)
  | appArgument
      (original argument : PsKernelExpr)
      (view : PsKernelForallView)
      (childContext : PsKernelCheckerContext)
  | lambdaDomain
      (name : PsKernelName)
      (domain body : PsKernelExpr)
      (info : PsKernelBinderInfo)
      (ranges : List Nat)
      (childContext : PsKernelCheckerContext)
      (childFuel : Nat)
  | lambdaBody (frame : PsKernelC0DeepDeferredLambdaFrame)

/-- A source inference focus, a checked child result, or completed output.
    A source checker failure remains an Except error, never a completed
    judgment. -/
inductive PsKernelC0DeepMixedFocus where
  | check
      (fuel : Nat)
      (context : PsKernelCheckerContext)
      (state : PsKernelCheckerState)
      (expr : PsKernelExpr)
  | returned
      (type : PsKernelExpr)
      (state : PsKernelCheckerState)
  | finished
      (type : PsKernelExpr)
      (state : PsKernelCheckerState)

structure PsKernelC0DeepMixedMachine where
  focus : PsKernelC0DeepMixedFocus
  pending : List PsKernelC0DeepMixedFrame

def psKernelC0DeepMixedStart
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) : PsKernelC0DeepMixedMachine :=
  ⟨.check fuel context state expr, []⟩

/-- One small-step transition. Context-sensitive checked results cannot be
    shared across frames. In particular a cached checked judgment is still
    delegated to the original source checker rather than assumed valid. -/
def psKernelC0DeepMixedStep
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (machine : PsKernelC0DeepMixedMachine) :
    Except String PsKernelC0DeepMixedMachine := do
  match machine.focus with
  | .finished ty state =>
      pure ⟨.finished ty state, machine.pending⟩
  | .check fuel ctx state expr =>
      match fuel with
      | 0 => .error "kernel inference budget exhausted"
      | remaining + 1 =>
          -- Match the source's checked cache lookup before entering depth.
          let cached :=
            if psKernelInferCacheEligible false expr then
              psKernelExprMapGetWithKnownHash state.checkedInfer expr none
            else
              none
          match cached with
          | some _ =>
              let (ty, state1) ←
                psKernelInferCoreWithFuel fuel whnf defeq ctx state expr false
              pure ⟨.returned ty state1, machine.pending⟩
          | none =>
              let child ← psKernelCheckerContextEnterRecDepth ctx
              match expr with
              | .app fn arg =>
                  pure ⟨.check remaining child state fn,
                    .appFunction expr arg child remaining :: machine.pending⟩
              | .lam name domain body info =>
                  pure ⟨.check remaining child state domain,
                    .lambdaDomain name domain body info [] child remaining ::
                      machine.pending⟩
              | _ =>
                  -- All other constructors remain checked by original C0.
                  -- This is not an infer-only shortcut.
                  let (ty, state1) ←
                    psKernelInferCoreWithFuel fuel whnf defeq ctx state expr false
                  pure ⟨.returned ty state1, machine.pending⟩
  | .returned ty state =>
      match machine.pending with
      | [] =>
          pure ⟨.finished ty state, []⟩
      | frame :: rest =>
          match frame with
          | .appFunction original arg child remaining =>
              let (view, state1) ←
                psKernelEnsureForallWith whnf child state ty
              pure ⟨.check remaining child state1 arg,
                .appArgument original arg view child :: rest⟩
          | .appArgument original arg view child =>
              let state1 ←
                if psKernelExprEq ty view.domain then
                  Except.ok state
                else
                  let eqContext :=
                    if psKernelExprIsEagerReduce arg then
                      psKernelCheckerContextWithEagerReduce child true
                    else
                      child
                  match defeq eqContext state ty view.domain with
                  | .error error => .error error
                  | .ok (true, resultState) => .ok resultState
                  | .ok (false, _) => .error "application type mismatch"
              let resultType := psKernelExprInstantiate1 view.body arg
              pure ⟨.returned resultType
                (psKernelCacheInferResult state1 false original resultType),
                rest⟩
          | .lambdaDomain name domain body info ranges child remaining =>
              let frame ← psKernelC0DeepLambdaResumeCheckedDomain whnf child
                (ty, state) name domain body info ranges
              pure ⟨.check remaining frame.scopedContext
                  frame.sourceFreshState
                  (psKernelC0DeepSubstForce frame.delayedOpening),
                .lambdaBody frame :: rest⟩
          | .lambdaBody frame =>
              let sourceFrame := psKernelC0DeepLambdaForceFrame frame
              let (resultType, resultState) :=
                psKernelC0DeepLambdaClose sourceFrame ty state
              pure ⟨.returned resultType resultState, rest⟩

/-- This diagnostic *step cap* is NOT the C0 source recursion fuel.
    It only bounds the number of evaluator transitions in a research run;
    failure cannot be interpreted as a kernel rejection or acceptance. -/
def psKernelC0DeepMixedRunDiagnostic
    (steps : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (machine : PsKernelC0DeepMixedMachine) :
    Except String PsKernelC0DeepMixedMachine :=
  match steps with
  | 0 => .error "experimental mixed inference step cap exhausted"
  | n + 1 =>
      match machine.focus with
      | .finished _ _ => .ok machine
      | _ =>
          match psKernelC0DeepMixedStep whnf defeq machine with
          | .error e => .error e
          | .ok next => psKernelC0DeepMixedRunDiagnostic n whnf defeq next

/-- No transition may publish a proof from a finished machine: it is
    a purely diagnostic state with no declaration-admission constructor. -/
theorem psKernelC0DeepMixedFinishedStable
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (ty : PsKernelExpr)
    (state : PsKernelCheckerState)
    (pending : List PsKernelC0DeepMixedFrame) :
    psKernelC0DeepMixedStep whnf defeq
      ⟨.finished ty state, pending⟩ =
      .ok ⟨.finished ty state, pending⟩ := by
  rfl
