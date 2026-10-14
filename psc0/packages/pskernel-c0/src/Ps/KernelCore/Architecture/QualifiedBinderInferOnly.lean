import Ps.KernelCore.Architecture.QualifiedBinderInference

/-!
Phase E.4R — independently execute lambda/Pi INFER-ONLY heads as well.

The checked binder execution is qualified separately. The inference-only
source distinguishes its own result cache and deliberately skips certain
domain full-check obligations; it must NEVER be mistaken for proof admission.
The source exactness below includes warm/cold infer-only cache behavior,
recursion/fuel, name generation and recursive dependent child inference.

Recursive body/domain judgments retain the source worker. These equations
establish complete top-level binder HEAD operational refinement, not a
standalone independently verified higher-order/dependent type checker.
-/

/-- Exact source infer-only lambda head: cached results return the source
    checked state unchanged; cold heads reuse the exact binder rule under
    the original source recursion budget and without a checked-app hook. -/
def psKernelC0LambdaInferOnlyWithFuel
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => .error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let expr : PsKernelExpr := .lam name domain body binderInfo
      match psKernelExprMapGetWithKnownHash state.inferOnly expr none with
      | some type =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error error => .error error
          | .ok _ => .ok (type, state)
      | none =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error error => .error error
          | .ok entered =>
              psKernelInferLambdaHead
                (psKernelInferCoreWithFuelUsingSourceFrames remaining none)
                whnf defeq entered state name domain body binderInfo true
                (psKernelInferCurrentBinderRanges expr
                  (none : Option PsKernelC0CheckedAppHook) [])

/-- Exact source infer-only dependent Π head, with distinct inference-only
    cache lookup, child source judgments, and imax universe calculation. -/
def psKernelC0PiInferOnlyWithFuel
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => .error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let expr : PsKernelExpr := .forallE name domain body binderInfo
      match psKernelExprMapGetWithKnownHash state.inferOnly expr none with
      | some type =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error error => .error error
          | .ok _ => .ok (type, state)
      | none =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error error => .error error
          | .ok entered =>
              psKernelInferForallHead
                (psKernelInferCoreWithFuelUsingSourceFrames remaining none)
                whnf defeq entered state name domain body binderInfo true
                (psKernelInferCurrentBinderRanges expr
                  (none : Option PsKernelC0CheckedAppHook) [])

/-- An exact source-result equation for the full infer-only lambda
    operation, including cache hits, successful state, and source errors. -/
theorem psKernelC0LambdaInferOnly_source
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelC0LambdaInferOnlyWithFuel fuel whnf defeq
      context state name domain body binderInfo =
    psKernelInferCoreWithFuelUsing fuel none whnf defeq
      context state (.lam name domain body binderInfo) true := by
  cases fuel <;> rfl

/-- Exact source-result/state/cache equality for infer-only dependent Π. -/
theorem psKernelC0PiInferOnly_source
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelC0PiInferOnlyWithFuel fuel whnf defeq
      context state name domain body binderInfo =
    psKernelInferCoreWithFuelUsing fuel none whnf defeq
      context state (.forallE name domain body binderInfo) true := by
  cases fuel <;> rfl

theorem psKernelC0LambdaInferOnly_checkerInfer
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelC0LambdaInferOnlyWithFuel fuel
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      context state name domain body binderInfo =
    psKernelCheckerInfer fuel context state
      (.lam name domain body binderInfo) := by
  rw [psKernelC0LambdaInferOnly_source]
  rfl

theorem psKernelC0PiInferOnly_checkerInfer
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelC0PiInferOnlyWithFuel fuel
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      context state name domain body binderInfo =
    psKernelCheckerInfer fuel context state
      (.forallE name domain body binderInfo) := by
  rw [psKernelC0PiInferOnly_source]
  rfl

/-- The actual source-owned inference session now selects the independent
    lambda/Π head implementation with an exact complete source equation.
    Infer-only type synthesis remains separate from full checked proof
    judgment; all other expressions keep qualified metadata/source fallback. -/
def psKernelC0CertifiedWorkInferBinderOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match expr with
  | .lam name domain body binderInfo =>
      match h : psKernelC0LambdaInferOnlyWithFuel fuel
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          name domain body binderInfo with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work nextState).val), by
              have source :
                  psKernelCheckerInfer fuel
                    work.raw.checker.context work.raw.checker.state
                    (.lam name domain body binderInfo) =
                      .ok (ty, nextState) := by
                rw [← psKernelC0LambdaInferOnly_checkerInfer]
                exact h
              unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
              simp only [source]
              rfl⟩
  | .forallE name domain body binderInfo =>
      match h : psKernelC0PiInferOnlyWithFuel fuel
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          name domain body binderInfo with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work nextState).val), by
              have source :
                  psKernelCheckerInfer fuel
                    work.raw.checker.context work.raw.checker.state
                    (.forallE name domain body binderInfo) =
                      .ok (ty, nextState) := by
                rw [← psKernelC0PiInferOnly_checkerInfer]
                exact h
              unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkInferMetadataOwned fuel work other
