import Ps.KernelCore.Architecture.QualifiedApplicationInference

/-!
Phase E.4U — exact dependent-let head inference/checking.

Pinned Lean 4.35 type_checker.cpp::infer_let is the primary reference.
The complete existing source C0 let decision was mechanically extracted
into Checker/Inference/Let.lean with its unchanged recursive child checker,
name generation, local context, type/DefEq obligations and frame-based
source cache hints. This direct accepting-head path executes that shared
rule while bypassing the top-level recursive inference dispatcher ONLY.

Source equality is proved over the complete result/state/error operation.
Recursive type/value/body checking remains source authoritative, so this
is a real LET-head operational refinement, not a full independently
verified dependent term checker or permission for unchecked admission.
-/

/-- Execute the same source let head at the original fuel, source cache,
    recursion policy and source range/hash hints. Inference-only uses the
    historical callback-free worker; full checking may use the already
    qualified nested application callback exactly as original C0. -/
def psKernelC0LetHeadWithFuel
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (type value body : PsKernelExpr)
    (nondep inferOnly : Bool) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => .error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let expr : PsKernelExpr := .letE name type value body nondep
      let frames := psKernelInferCurrentLetFrames expr onCheckedApp []
      let currentHash :=
        match frames with
        | (_, hash) :: _ => some hash
        | [] => none
      let cache := if inferOnly then state.inferOnly else state.checkedInfer
      let cached :=
        if psKernelInferCacheEligible inferOnly expr then
          psKernelExprMapGetWithKnownHash cache expr currentHash
        else none
      match cached with
      | some ty =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error reason => .error reason
          | .ok _ => .ok (ty, state)
      | none =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error reason => .error reason
          | .ok entered =>
              psKernelInferLetHead
                (psKernelInferCoreWithFuelUsingSourceFrames
                  remaining onCheckedApp)
                whnf defeq entered state name type value body nondep
                inferOnly frames currentHash

/-- This is an equality of TOTAL source operations (not just the values
    of a handful of positive examples): every source exception, context,
    fuel, memo/hash state and optional application callback is preserved. -/
theorem psKernelC0LetHead_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (type value body : PsKernelExpr)
    (nondep inferOnly : Bool) :
    psKernelC0LetHeadWithFuel fuel onCheckedApp whnf defeq
      context state name type value body nondep inferOnly =
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.letE name type value body nondep) inferOnly := by
  cases fuel <;> rfl

/-- The original standalone checked let root uses the same checked-app
    callback as every other non-application head. -/
theorem psKernelC0LetFull_checkerCheck
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName) (type value body : PsKernelExpr)
    (nondep : Bool) :
    psKernelC0LetHeadWithFuel fuel
      (some psKernelC0CheckAppRecursiveResummarized)
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      context state name type value body nondep false =
    psKernelCheckerCheck fuel context state
      (.letE name type value body nondep) := by
  rw [psKernelC0LetHead_source]
  rfl

/-- Infer-only let exposure is not a type-correctness judgment. Its source
    result and complete state nevertheless must equal C0's infer-only path. -/
theorem psKernelC0LetInferOnly_checkerInfer
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName) (type value body : PsKernelExpr)
    (nondep : Bool) :
    psKernelC0LetHeadWithFuel fuel none
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      context state name type value body nondep true =
    psKernelCheckerInfer fuel context state
      (.letE name type value body nondep) := by
  rw [psKernelC0LetHead_source]
  rfl

/-- Exact source-checked let head. Every successful result includes a
    kernel-checked propositional equality to the original source checker,
    including its full cache and local state. All other terms still use
    the previously qualified checked application or source fallback. -/
def psKernelC0CertifiedWorkCheckLetOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .letE name type value body nondep =>
      match h : psKernelC0LetHeadWithFuel fuel
          (some psKernelC0CheckAppRecursiveResummarized)
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          name type value body nondep false with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned work nextState).val),
            by
              have source : psKernelCheckerCheck fuel
                  work.raw.checker.context work.raw.checker.state
                  (.letE name type value body nondep) = .ok (ty, nextState) := by
                rw [← psKernelC0LetFull_checkerCheck]
                exact h
              unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkCheckAppOwned fuel work other

/-- Source-equivalent infer-only let-head exposure, without gaining
    verified proof authority or bypassing checked declaration admission. -/
def psKernelC0CertifiedWorkInferLetOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match expr with
  | .letE name type value body nondep =>
      match h : psKernelC0LetHeadWithFuel fuel none
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          name type value body nondep true with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned work nextState).val),
            by
              have source : psKernelCheckerInfer fuel
                  work.raw.checker.context work.raw.checker.state
                  (.letE name type value body nondep) = .ok (ty, nextState) := by
                rw [← psKernelC0LetInferOnly_checkerInfer]
                exact h
              unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkInferAppOwned fuel work other
