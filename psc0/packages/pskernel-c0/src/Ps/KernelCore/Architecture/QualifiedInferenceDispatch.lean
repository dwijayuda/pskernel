import Ps.KernelCore.Architecture.QualifiedConstantInference

/-!
Phase E.4N — one proof-qualified direct-head inference dispatcher.

Three preceding native-qualified fragments handle Sort/Nat/String scalars,
FVar local lookup, and warm and cold constant inference. The previous
incremental wrappers tested each layer and then fell back through another
layer, incurring redundant source-cache probes for cold or unsupported terms.

This single, closed-form direct-head selector dispatches exactly once on
the source term constructor, returning a source-exact witness for every
successful direct case. Unsupported heads or declined resource/lookup
cases go STRAIGHT to the original source checker, retaining its exact
exception categories, complete state and separate checked/infer caches.

This is still an operational refinement relative to C0 source semantics.
A forged raw source cache is not a proof certificate; public verified
sessions remain rooted in audited checked genesis and lineage.
-/

/-- Direct source-equivalent inference for exactly the qualified families.
    The declaration/safety/cold-constant rules are not invented or guessed:
    a cold cache executes the mechanically extracted, source-exact
    constant inference decision with complete checker-state proof. -/
def psKernelC0QualifiedInferHeadWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (inferOnly : Bool) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match expr with
  | .sort level =>
      psKernelC0ScalarInferWithFuel fuel context state (.sort level) inferOnly
  | .lit literal =>
      psKernelC0ScalarInferWithFuel fuel context state (.lit literal) inferOnly
  | .fvar name =>
      psKernelC0FVarInferWithFuel fuel context state name inferOnly
  | .const name levels =>
      psKernelC0ConstantCompleteInferWithFuel
        fuel context state name levels inferOnly
  | _ => none

/-- ONE source-preservation theorem for the entire implemented selector,
    covering both optional checked application hooks and arbitrary
    supplied WHNF/DefEq callbacks. Each constructor reuses its
    independently native-checked per-family refinement theorem. -/
theorem psKernelC0QualifiedInferHead_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → Except String (PsKernelExpr × PsKernelCheckerState))
    (defeq : PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → PsKernelExpr →
      Except String (Bool × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (inferOnly : Bool)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0QualifiedInferHeadWithFuel
      fuel context state expr inferOnly = some result) :
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state expr inferOnly = .ok result := by
  cases expr with
  | sort level =>
      exact psKernelC0ScalarInfer_source fuel onCheckedApp whnf defeq
        context state (.sort level) inferOnly result
        (by simpa only [psKernelC0QualifiedInferHeadWithFuel] using h)
  | lit literal =>
      exact psKernelC0ScalarInfer_source fuel onCheckedApp whnf defeq
        context state (.lit literal) inferOnly result
        (by simpa only [psKernelC0QualifiedInferHeadWithFuel] using h)
  | fvar name =>
      exact psKernelC0FVarInfer_source fuel onCheckedApp whnf defeq
        context state name inferOnly result
        (by simpa only [psKernelC0QualifiedInferHeadWithFuel] using h)
  | const name levels =>
      exact psKernelC0ConstantCompleteInfer_source fuel onCheckedApp
        whnf defeq context state name levels inferOnly result
        (by simpa only [psKernelC0QualifiedInferHeadWithFuel] using h)
  | bvar _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | mvar _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | app _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | lam _ _ _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | forallE _ _ _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | letE _ _ _ _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | mdata _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | proj _ _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h

/-- Source exactness of the unified independent/direct inference selector,
    including the complete checked cache state and recursion/fuel effects. -/
theorem psKernelC0QualifiedInferHead_checkerInfer
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0QualifiedInferHeadWithFuel
      fuel context state expr true = some (ty, nextState)) :
    psKernelCheckerInfer fuel context state expr = .ok (ty, nextState) := by
  unfold psKernelCheckerInfer psKernelInferWithRecursorFuel
    psKernelInferWithFuel psKernelInferCoreWithFuel
  exact psKernelC0QualifiedInferHead_source fuel none
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state expr true
    (ty, nextState) h

/-- Full check uses the original C0 checked application hook for every
    term. None of the qualified direct heads is an App, so all successful
    direct cases are provably the identical original complete checker call. -/
theorem psKernelC0QualifiedInferHead_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0QualifiedInferHeadWithFuel
      fuel context state expr false = some (ty, nextState)) :
    psKernelCheckerCheck fuel context state expr = .ok (ty, nextState) := by
  cases expr with
  | sort level =>
      change psKernelInferCoreWithFuelUsing fuel
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)
        context state (.sort level) false = .ok (ty, nextState)
      exact psKernelC0QualifiedInferHead_source fuel
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel) context state
        (.sort level) false (ty, nextState) h
  | lit literal =>
      change psKernelInferCoreWithFuelUsing fuel
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)
        context state (.lit literal) false = .ok (ty, nextState)
      exact psKernelC0QualifiedInferHead_source fuel
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel) context state
        (.lit literal) false (ty, nextState) h
  | fvar name =>
      change psKernelInferCoreWithFuelUsing fuel
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)
        context state (.fvar name) false = .ok (ty, nextState)
      exact psKernelC0QualifiedInferHead_source fuel
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel) context state
        (.fvar name) false (ty, nextState) h
  | const name levels =>
      change psKernelInferCoreWithFuelUsing fuel
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)
        context state (.const name levels) false = .ok (ty, nextState)
      exact psKernelC0QualifiedInferHead_source fuel
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel) context state
        (.const name levels) false (ty, nextState) h
  | bvar _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | mvar _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | app _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | lam _ _ _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | forallE _ _ _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | letE _ _ _ _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | mdata _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h
  | proj _ _ _ => simp [psKernelC0QualifiedInferHeadWithFuel] at h

/-- Unified one-step qualified inference. Unsupported terms and declines
    fall back ONCE to the original source checker; there is no chain of
    cache/lookups from the scalar/FVar/constant wrapper layers. -/
def psKernelC0CertifiedWorkInferDirectOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match h : psKernelC0QualifiedInferHeadWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr true with
  | none =>
      match source : psKernelC0CertifiedWorkInfer fuel work expr with
      | .error reason => .error reason
      | .ok result => .ok ⟨result, rfl⟩
  | some (ty, nextState) =>
      .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned work nextState).val),
        by
          have source : psKernelCheckerInfer fuel
              work.raw.checker.context work.raw.checker.state expr =
                .ok (ty, nextState) :=
            psKernelC0QualifiedInferHead_checkerInfer fuel
              work.raw.checker.context work.raw.checker.state
              expr ty nextState h
          unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
          simp only [source]
          rfl⟩

/-- Unified source-exact FULL checking, with checked-inference cache
    kept distinct, and every unqualified input routed exactly once to
    the original source checker. There is no candidate proof/admission. -/
def psKernelC0CertifiedWorkCheckDirectOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match h : psKernelC0QualifiedInferHeadWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr false with
  | none =>
      match source : psKernelC0CertifiedWorkCheck fuel work expr with
      | .error reason => .error reason
      | .ok result => .ok ⟨result, rfl⟩
  | some (ty, nextState) =>
      .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned work nextState).val),
        by
          have source : psKernelCheckerCheck fuel
              work.raw.checker.context work.raw.checker.state expr =
                .ok (ty, nextState) :=
            psKernelC0QualifiedInferHead_checkerCheck fuel
              work.raw.checker.context work.raw.checker.state
              expr ty nextState h
          unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
          simp only [source]
          rfl⟩
