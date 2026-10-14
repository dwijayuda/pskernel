import Ps.KernelCore.Architecture.QualifiedBinderInferOnly

/-!
Phase E.4T — source-equivalent direct CHECKED and INFER-ONLY application
head execution, with exact source error, type and checker-state equality.

Lean 4.35 type_checker.cpp::infer_app is the upstream reference. The C0
source checked/infer-only application rules were extracted verbatim into
Checker/Inference/App.lean. Qualified application heads bypass ONLY the
top-level recursive C0 inference dispatcher and call that exact source
operation with its unchanged recursive child checker, WHNF/DefEq callbacks,
eagerReduce/type-mismatch policy and long checked-app hook.

This does NOT replace recursive child inference or claim complete independent
semantic preservation for all dependent calculus forms. All successful
results carry the original full C0 source equation, including cache state;
failures preserve exactly the same error and resource precedence.
-/

/-- Independently select a full checked application head, retaining the
    source recursion budget and optional checked application-spine hook. -/
def psKernelC0AppFullWithFuel
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => .error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      match psKernelCheckerContextEnterRecDepth context with
      | .error error => .error error
      | .ok entered =>
          psKernelInferAppHead
            (psKernelInferCoreWithFuelUsingSourceFrames remaining onCheckedApp)
            onCheckedApp remaining whnf defeq
            context entered state fn arg false

/-- Infer-only application requires its own source cache read and its
    separate argument-spine exposure worker. A checked-app hook must NEVER
    be invoked during infer-only type synthesis. -/
def psKernelC0AppInferOnlyWithFuel
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => .error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let expr : PsKernelExpr := .app fn arg
      match psKernelExprMapGetWithKnownHash state.inferOnly expr none with
      | some ty =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error error => .error error
          | .ok _ => .ok (ty, state)
      | none =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error error => .error error
          | .ok entered =>
              psKernelInferAppHead
                (psKernelInferCoreWithFuelUsingSourceFrames remaining none)
                none remaining whnf defeq
                context entered state fn arg true

/-- Complete checked app operational refinement for ALL source contexts,
    starting states, source callbacks, fuel and syntactic application spines,
    including the ≥16-argument checked-app callback policy. -/
theorem psKernelC0AppFull_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    psKernelC0AppFullWithFuel fuel onCheckedApp whnf defeq
      context state fn arg =
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.app fn arg) false := by
  cases fuel <;> rfl

/-- Infer-only app operational refinement, including both source cache
    states, the app argument-spine budget, and all source failures. -/
theorem psKernelC0AppInferOnly_source
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    psKernelC0AppInferOnlyWithFuel fuel whnf defeq
      context state fn arg =
    psKernelInferCoreWithFuelUsing fuel none whnf defeq
      context state (.app fn arg) true := by
  cases fuel <;> rfl

/-- A root checked application is NOT the same operation as a recursive
    checked subapplication: the original source checker selects the
    independent suffix-resummarization worker at 16 or more arguments.
    Short roots use the historical hook-free inference worker. This exact
    decision belongs here, not in the accepting proof or test fixture. -/
def psKernelC0AppCheckedRootWithFuel
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  let expr : PsKernelExpr := .app fn arg
  if psKernelExprGetAppNumArgs expr >= 16 then
    psKernelC0CheckAppRecursiveResummarized
      fuel whnf defeq context state expr
  else
    psKernelC0AppFullWithFuel fuel none
      whnf defeq context state fn arg

/-- The complete root checked application operation is literally the
    original C0 source checking choice. The older generic app-head theorem
    remains valid for child inference with a chosen optional callback,
    but is NOT sufficient to characterize the public checked root. -/
theorem psKernelC0AppCheckedRoot_source
    (fuel : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    psKernelC0AppCheckedRootWithFuel fuel whnf defeq
      context state fn arg =
    psKernelCheckWithFuel fuel whnf defeq
      context state (.app fn arg) := by
  change
    (if psKernelExprGetAppNumArgs (.app fn arg) >= 16 then
      psKernelC0CheckAppRecursiveResummarized fuel whnf defeq
        context state (.app fn arg)
    else
      psKernelC0AppFullWithFuel fuel none
        whnf defeq context state fn arg) =
    (if psKernelExprGetAppNumArgs (.app fn arg) >= 16 then
      psKernelC0CheckAppRecursiveResummarized fuel whnf defeq
        context state (.app fn arg)
    else
      psKernelInferCoreWithFuel fuel whnf defeq
        context state (.app fn arg) false)
  by_cases h : psKernelExprGetAppNumArgs (.app fn arg) >= 16
  · simp only [if_pos h]
  · simp only [if_neg h]
    exact psKernelC0AppFull_source fuel none
      whnf defeq context state fn arg

/-- Exact source checking equation: successful short and long root
    applications retain their original complete state/error semantics.
    Full checking still requires an externally qualified checked session. -/
theorem psKernelC0AppFull_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    psKernelC0AppCheckedRootWithFuel fuel
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel) context state fn arg =
    psKernelCheckerCheck fuel context state (.app fn arg) := by
  rw [psKernelC0AppCheckedRoot_source]
  rfl

theorem psKernelC0AppInferOnly_checkerInfer
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    psKernelC0AppInferOnlyWithFuel fuel
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel) context state fn arg =
    psKernelCheckerInfer fuel context state (.app fn arg) := by
  rw [psKernelC0AppInferOnly_source]
  rfl

/-- Source-proved accepting full app heads; recursive children retain the
    official C0 source checking algorithm. All unsupported terms follow the
    fully qualified checked-binder/metadata inference chain. -/
def psKernelC0CertifiedWorkCheckAppOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .app fn arg =>
      match h : psKernelC0AppCheckedRootWithFuel fuel
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state fn arg with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work nextState).val), by
              have source : psKernelCheckerCheck fuel
                  work.raw.checker.context work.raw.checker.state
                  (.app fn arg) = .ok (ty, nextState) := by
                rw [← psKernelC0AppFull_checkerCheck]
                exact h
              unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkCheckBinderOwned fuel work other

/-- Source-proved infer-only app heads, carrying exact complete C0
    source-operation equality. Successful type exposure is not itself
    permission to emit a compiled/program proof artifact. -/
def psKernelC0CertifiedWorkInferAppOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match expr with
  | .app fn arg =>
      match h : psKernelC0AppInferOnlyWithFuel fuel
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state fn arg with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work nextState).val), by
              have source : psKernelCheckerInfer fuel
                  work.raw.checker.context work.raw.checker.state
                  (.app fn arg) = .ok (ty, nextState) := by
                rw [← psKernelC0AppInferOnly_checkerInfer]
                exact h
              unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkInferBinderOwned fuel work other
