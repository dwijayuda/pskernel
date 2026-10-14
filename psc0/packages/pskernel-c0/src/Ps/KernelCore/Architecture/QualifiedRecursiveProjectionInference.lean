import Ps.KernelCore.Architecture.QualifiedRecursiveLetInference

/-!
Phase E.4AC — checked projections over independently checked major terms.

The Lean 4.35 infer_proj rule must recover the major term's inductive
type, validate a one-constructor structure, exact field index, parameters,
dependent fields and proof elimination. The unchanged original C0 source
validator still performs those checks and WHNF/DefEq operations.

Only the eligible checked MAJOR-TERM recursive inference is replaced by
the previously source-proved independent checked expression engine. The
replacement callback is extensionally identical to the original source
worker for ALL checker contexts, caches, budgets and callbacks. Unsupported
major terms and infer-only work use source exactly. This is not a new
independent projection validator or an independent soundness theorem.
-/

/-- Retain source projection caching, fuel, error order and recursion
    depth while substituting proved-independent checked major inference
    whenever the source frames permit it. -/
def psKernelC0QualifiedProjectionHeadWithFuel
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
                (psKernelC0RefinedCheckedSmallerWithFuel
                  remaining onCheckedApp)
                whnf defeq entered state
                typeName index structValue inferOnly

/-- Equality of the entire original projection source operation, including
    positive/negative verdict, error, cache and resource effects. -/
theorem psKernelC0QualifiedProjectionHead_source
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
    psKernelC0QualifiedProjectionHeadWithFuel fuel onCheckedApp
      whnf defeq context state typeName index structValue inferOnly =
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.proj typeName index structValue) inferOnly := by
  rw [show psKernelC0QualifiedProjectionHeadWithFuel fuel onCheckedApp
        whnf defeq context state typeName index structValue inferOnly =
      psKernelC0ProjectionHeadWithFuel fuel onCheckedApp
        whnf defeq context state typeName index structValue inferOnly from
      (by
        cases fuel with
        | zero => rfl
        | succ remaining =>
            simp only [psKernelC0QualifiedProjectionHeadWithFuel,
              psKernelC0ProjectionHeadWithFuel,
              psKernelC0RefinedCheckedSmaller_source]
            rfl)]
  exact psKernelC0ProjectionHead_source fuel onCheckedApp
    whnf defeq context state typeName index structValue inferOnly

/-- Exact refinement of the real checked projection route. -/
theorem psKernelC0QualifiedProjection_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr) :
    psKernelC0QualifiedProjectionHeadWithFuel fuel
      (some psKernelC0CheckAppRecursiveResummarized)
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      context state typeName index structValue false =
    psKernelCheckerCheck fuel context state
      (.proj typeName index structValue) := by
  rw [psKernelC0QualifiedProjectionHead_source]
  rfl

/-- Proof-qualified checked projection provider operation. All remaining
    roots continue through the already source-refined recursive let,
    binder, application and fallback paths. -/
def psKernelC0CertifiedWorkCheckRecursiveProjectionOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .proj typeName index structValue =>
      match h : psKernelC0QualifiedProjectionHeadWithFuel fuel
          (some psKernelC0CheckAppRecursiveResummarized)
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          typeName index structValue false with
      | .error reason => .error reason
      | .ok (ty, checkedState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work checkedState).val), by
              have source : psKernelCheckerCheck fuel
                  work.raw.checker.context work.raw.checker.state
                  (.proj typeName index structValue) =
                    .ok (ty, checkedState) := by
                rw [← psKernelC0QualifiedProjection_checkerCheck]
                exact h
              unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
              simp only [source]
              rfl⟩
  | other =>
      psKernelC0CertifiedWorkCheckRecursiveLetOwned fuel work other
