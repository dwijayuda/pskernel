import Ps.KernelCore.Architecture.QualifiedLetInference

/-!
Phase E.4V — source-exact projection head inference and full checking.

Pinned Lean 4.35 kernel source type_checker.cpp::infer_proj is the primary
semantic reference: projections require a valid inductive structure, index
and parameter shape; they cannot simply be interpreted as tuple offsets.
The original C0 rule has been mechanically extracted into
Checker/Inference/Projection.lean and is shared by original source
inference and this direct head route.

The direct operation preserves the source cache lookup, fuel and recursion
guards and executes only the existing projection validator with the same
child inference and WHNF callbacks. Inference-only is not proof admission.
An exact source operation equation certifies every published successful
type and entire checker state, for any input context/state.
-/

/-- The exact original projection-head source operation, bypassing the
    surrounding recursive expression dispatcher. Error and resource
    outcomes remain from the source projection validator. -/
def psKernelC0ProjectionHeadWithFuel
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr)
    (inferOnly : Bool) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => .error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let expr : PsKernelExpr := .proj typeName index structValue
      let cache := if inferOnly then state.inferOnly else state.checkedInfer
      let cached :=
        if psKernelInferCacheEligible inferOnly expr then
          psKernelExprMapGetWithKnownHash cache expr none
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
              psKernelInferProjectionHead
                (psKernelInferCoreWithFuelUsingSourceFrames
                  remaining onCheckedApp)
                whnf defeq entered state
                typeName index structValue inferOnly

/-- Complete operational preservation of the source projection checker:
    identical checked/infer-only cache, result and error for all contexts,
    source callbacks, resource budgets and projection expressions. -/
theorem psKernelC0ProjectionHead_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr)
    (inferOnly : Bool) :
    psKernelC0ProjectionHeadWithFuel fuel onCheckedApp
      whnf defeq context state typeName index structValue inferOnly =
    psKernelInferCoreWithFuelUsing fuel onCheckedApp
      whnf defeq context state (.proj typeName index structValue) inferOnly := by
  cases fuel <;> rfl

/-- Full standalone projections are non-application roots and therefore
    retain the exact checked-app callback arrangement of the C0 checker. -/
theorem psKernelC0ProjectionFull_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr) :
    psKernelC0ProjectionHeadWithFuel fuel
      (some psKernelC0CheckAppRecursiveResummarized)
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      context state typeName index structValue false =
    psKernelCheckerCheck fuel context state
      (.proj typeName index structValue) := by
  rw [psKernelC0ProjectionHead_source]
  rfl

theorem psKernelC0ProjectionInferOnly_checkerInfer
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr) :
    psKernelC0ProjectionHeadWithFuel fuel none
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      context state typeName index structValue true =
    psKernelCheckerInfer fuel context state
      (.proj typeName index structValue) := by
  rw [psKernelC0ProjectionHead_source]
  rfl

/-- Source-checked standalone projection result with proof-carrying
    complete output/state. All other expressions retain the qualified
    let/app/binder/metadata/scalar source exactness chain. -/
def psKernelC0CertifiedWorkCheckProjectionOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .proj typeName index structValue =>
      match h : psKernelC0ProjectionHeadWithFuel fuel
          (some psKernelC0CheckAppRecursiveResummarized)
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          typeName index structValue false with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned work nextState).val),
            by
              have source : psKernelCheckerCheck fuel
                  work.raw.checker.context work.raw.checker.state
                  (.proj typeName index structValue) = .ok (ty, nextState) := by
                rw [← psKernelC0ProjectionFull_checkerCheck]
                exact h
              unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkCheckLetOwned fuel work other

/-- Separate infer-only projection type exposure. The result is never
    sufficient to admit a proof-bearing declaration without full checking. -/
def psKernelC0CertifiedWorkInferProjectionOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match expr with
  | .proj typeName index structValue =>
      match h : psKernelC0ProjectionHeadWithFuel fuel none
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          typeName index structValue true with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned work nextState).val),
            by
              have source : psKernelCheckerInfer fuel
                  work.raw.checker.context work.raw.checker.state
                  (.proj typeName index structValue) = .ok (ty, nextState) := by
                rw [← psKernelC0ProjectionInferOnly_checkerInfer]
                exact h
              unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkInferLetOwned fuel work other
