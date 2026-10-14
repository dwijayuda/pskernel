import Ps.KernelCore.Architecture.QualifiedRecursiveInference

/-!
Phase E.4AB: checked let children may use the independently typed,
source-refined recursive checker. Lean 4.35 type_checker.cpp::infer_let
checks annotation and value before opening a fresh local body.

The original source let rule remains the single owner of its cache,
WHNF/DefEq, binder opening, cheap-beta, and result reconstruction. This
module substitutes a source-equivalent child callback: on a proven
independent checked result it does not rerun source recursive inference;
unsupported, infer-only and nonempty source-frame judgments delegate
unchanged. This is a qualified checked-let-child extension, NOT an
independent WHNF/DefEq or entire let implementation.
-/

/-- Select an independently source-proved checked child when possible,
    otherwise use the original recursive checker with exactly empty
    operation-local frames. -/
def psKernelC0RefinedCheckedChildWithFuel
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match psKernelC0RecursiveCheckedWithFuel fuel context state expr with
  | some result => .ok result
  | none =>
      psKernelInferCoreWithFuelUsingSourceFrames
        fuel onCheckedApp [] [] whnf defeq
        context state expr false

/-- The entire returned type, state, cache, error and budget behavior of
    the child callback is the original source operation, not merely
    an equality of inferred types. -/
theorem psKernelC0RefinedCheckedChild_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelC0RefinedCheckedChildWithFuel fuel onCheckedApp
      whnf defeq context state expr =
    psKernelInferCoreWithFuelUsingSourceFrames
      fuel onCheckedApp [] [] whnf defeq context state expr false := by
  cases h : psKernelC0RecursiveCheckedWithFuel fuel context state expr with
  | none =>
      simp [psKernelC0RefinedCheckedChildWithFuel, h]
  | some result =>
      have source :
          psKernelInferCoreWithFuelUsingSourceFrames
            fuel onCheckedApp [] [] whnf defeq context state expr false =
              .ok result :=
        psKernelC0RecursiveChecked_source fuel onCheckedApp
          whnf defeq context state expr result h
      simpa [psKernelC0RefinedCheckedChildWithFuel, h] using source.symm

/-- Never replace infer-only evaluation with checked evaluation. Never
    discard a source let/binder frame: source hash and range semantics
    retain authority until the independent engine models them. -/
def psKernelC0RefinedCheckedSmallerWithFuel
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook) :
    PsKernelC0BinderSmaller :=
  fun letFrames binderRanges whnf defeq context state expr inferOnly =>
    match letFrames, binderRanges, inferOnly with
    | [], [], false =>
        psKernelC0RefinedCheckedChildWithFuel fuel onCheckedApp
          whnf defeq context state expr
    | _, _, _ =>
        psKernelInferCoreWithFuelUsingSourceFrames
          fuel onCheckedApp letFrames binderRanges
          whnf defeq context state expr inferOnly

/-- Extensional source equivalence of the entire recursive callback.
    This includes unsupported descendants, infer-only behavior, source
    frame provenance, and all arbitrary checker states and callbacks. -/
theorem psKernelC0RefinedCheckedSmaller_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook) :
    psKernelC0RefinedCheckedSmallerWithFuel fuel onCheckedApp =
      psKernelInferCoreWithFuelUsingSourceFrames fuel onCheckedApp := by
  funext letFrames binderRanges whnf defeq context state expr inferOnly
  cases letFrames <;> cases binderRanges <;> cases inferOnly <;>
    simp [psKernelC0RefinedCheckedSmallerWithFuel,
      psKernelC0RefinedCheckedChild_source]

/-- Qualify the checked let head through independently checked recursive
    children. Preserve the precise source cache lookup, recursion-depth
    guard, optional immutable let frames and all resulting diagnostics. -/
def psKernelC0QualifiedLetHeadWithFuel
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
                (psKernelC0RefinedCheckedSmallerWithFuel
                  remaining onCheckedApp)
                whnf defeq entered state name type value body nondep
                inferOnly frames currentHash

/-- Source-operation equality comes from the proved callback equality;
    no unchecked successful child can create a different source verdict. -/
theorem psKernelC0QualifiedLetHead_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (type value body : PsKernelExpr)
    (nondep inferOnly : Bool) :
    psKernelC0QualifiedLetHeadWithFuel fuel onCheckedApp
      whnf defeq context state name type value body nondep inferOnly =
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.letE name type value body nondep) inferOnly := by
  rw [show psKernelC0QualifiedLetHeadWithFuel fuel onCheckedApp
        whnf defeq context state name type value body nondep inferOnly =
      psKernelC0LetHeadWithFuel fuel onCheckedApp
        whnf defeq context state name type value body nondep inferOnly from
      (by
        cases fuel with
        | zero => rfl
        | succ remaining =>
            simp only [psKernelC0QualifiedLetHeadWithFuel,
              psKernelC0LetHeadWithFuel,
              psKernelC0RefinedCheckedSmaller_source]
            rfl)]
  exact psKernelC0LetHead_source fuel onCheckedApp
    whnf defeq context state name type value body nondep inferOnly

/-- This proof is against the actual full checked C0 root operation,
    including its callback and resource policy. -/
theorem psKernelC0QualifiedLet_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (type value body : PsKernelExpr)
    (nondep : Bool) :
    psKernelC0QualifiedLetHeadWithFuel fuel
      (some psKernelC0CheckAppRecursiveResummarized)
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel)
      context state name type value body nondep false =
    psKernelCheckerCheck fuel context state
      (.letE name type value body nondep) := by
  rw [psKernelC0QualifiedLetHead_source]
  rfl

/-- The real checked-provider path uses the refined recursive children for
    let roots; every successful result carries the complete C0 source
    equation. Other constructors retain the qualified recursive engine. -/
def psKernelC0CertifiedWorkCheckRecursiveLetOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .letE name type value body nondep =>
      match h : psKernelC0QualifiedLetHeadWithFuel fuel
          (some psKernelC0CheckAppRecursiveResummarized)
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          name type value body nondep false with
      | .error reason => .error reason
      | .ok (ty, checkedState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work checkedState).val), by
              have source : psKernelCheckerCheck fuel
                  work.raw.checker.context work.raw.checker.state
                  (.letE name type value body nondep) =
                    .ok (ty, checkedState) := by
                rw [← psKernelC0QualifiedLet_checkerCheck]
                exact h
              unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkCheckRecursiveOwned fuel work other
