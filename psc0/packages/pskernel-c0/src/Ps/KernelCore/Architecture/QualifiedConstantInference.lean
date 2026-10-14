import Ps.KernelCore.Architecture.QualifiedLocalInference

/-!
Phase E.4M — exact checked constant inference cache-hit refinement.

Based on pinned Lean 4.35 src/kernel/type_checker.cpp::infer_type_core,
the kernel may reuse previously checked inference results within its owned
checker state. C0 keeps separate infer-only and full-check caches, with its
own source recursion/fuel guards. This independent fragment returns ONLY
already-cached constant results, preserving source cache state exactly.
Cold lookup (arity, safety, universes, type instantiation) and all errors
remain source authoritative.

An arbitrary caller-created cache can carry an invalid value: proving
operational equality to that raw source behavior does NOT make arbitrary
caches sound. The verified provider starts from checked empty genesis
and preserves its exact proven checker-state lineage.
-/

/-- Only source-owned constant inference cache hits are handled directly.
    No raw cache entry is validated by its presence alone: the verified API
    must establish a sound lineage before this operation is authoritative. -/
def psKernelC0ConstantCachedInferWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (inferOnly : Bool) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ _ =>
      let expr : PsKernelExpr := .const name levels
      let cache := if inferOnly then state.inferOnly else state.checkedInfer
      match psKernelExprMapGet cache expr with
      | none => none
      | some ty =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error _ => none
          | .ok _ => some (ty, state)

/-- Every successful direct cached constant is precisely the C0 source
    infer/check worker's result for ANY context, existing source cache,
    reduction callbacks and optional checked application-hook. -/
theorem psKernelC0ConstantCachedInfer_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → Except String (PsKernelExpr × PsKernelCheckerState))
    (defeq : PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → PsKernelExpr →
      Except String (Bool × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (inferOnly : Bool)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ConstantCachedInferWithFuel
      fuel context state name levels inferOnly = some result) :
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.const name levels) inferOnly = .ok result := by
  cases fuel with
  | zero => simp [psKernelC0ConstantCachedInferWithFuel] at h
  | succ remaining =>
      let expr : PsKernelExpr := .const name levels
      let cache := if inferOnly then state.inferOnly else state.checkedInfer
      cases cached : psKernelExprMapGet cache expr with
      | none =>
          simp [psKernelC0ConstantCachedInferWithFuel, cached,
            cache, expr] at h
      | some ty =>
          cases depth : psKernelCheckerContextEnterRecDepth context with
          | error reason =>
              simp [psKernelC0ConstantCachedInferWithFuel, cached,
                depth, cache, expr] at h
          | ok entered =>
              have hresult : result = (ty, state) := by
                have hx : some (ty, state) = some result := by
                  simpa [psKernelC0ConstantCachedInferWithFuel,
                    cached, depth, cache, expr] using h
                exact (Option.some.inj hx).symm
              rw [hresult]
              have hcache :
                  psKernelExprMapGetWithKnownHash
                    (if inferOnly then state.inferOnly else state.checkedInfer)
                    (.const name levels) none = some ty := by
                change psKernelExprMapGet cache expr = some ty
                exact cached
              simpa [psKernelInferCoreWithFuelUsing,
                psKernelInferCoreWithFuelUsingSourceFrames,
                psKernelInferCacheEligible, hcache, depth]

theorem psKernelC0ConstantCachedInfer_checkerInfer
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0ConstantCachedInferWithFuel
      fuel context state name levels true = some (ty, nextState)) :
    psKernelCheckerInfer fuel context state (.const name levels) =
      .ok (ty, nextState) := by
  unfold psKernelCheckerInfer psKernelInferWithRecursorFuel
    psKernelInferWithFuel psKernelInferCoreWithFuel
  exact psKernelC0ConstantCachedInfer_source fuel none
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state name levels true
    (ty, nextState) h

theorem psKernelC0ConstantCachedInfer_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0ConstantCachedInferWithFuel
      fuel context state name levels false = some (ty, nextState)) :
    psKernelCheckerCheck fuel context state (.const name levels) =
      .ok (ty, nextState) := by
  change psKernelInferCoreWithFuelUsing fuel
    (some psKernelC0CheckAppRecursiveResummarized)
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state
    (.const name levels) false = .ok (ty, nextState)
  exact psKernelC0ConstantCachedInfer_source fuel
    (some psKernelC0CheckAppRecursiveResummarized)
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state name levels false
    (ty, nextState) h

/-- The qualified constant cache-hit family feeds the same source-equation
    receipt used by local and scalar inference. Cold constants are still
    checked by the original independent reference source kernel. -/
def psKernelC0CertifiedWorkInferWithConstantsOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match expr with
  | .const name levels =>
      match h : psKernelC0ConstantCachedInferWithFuel fuel
          work.raw.checker.context work.raw.checker.state
          name levels true with
      | none =>
          psKernelC0CertifiedWorkInferWithLocalsOwned
            fuel work (.const name levels)
      | some (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
              work nextState).val), by
            have source : psKernelCheckerInfer fuel
                work.raw.checker.context work.raw.checker.state
                (.const name levels) = .ok (ty, nextState) :=
              psKernelC0ConstantCachedInfer_checkerInfer fuel
                work.raw.checker.context work.raw.checker.state
                name levels ty nextState h
            unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
            simp only [source]
            rfl⟩
  | other => psKernelC0CertifiedWorkInferWithLocalsOwned fuel work other

/-- The FULL checked constant cache is kept separate from infer-only and
    exact original check semantics. This does not approve any new constant
    admission and never imports arbitrary external source state. -/
def psKernelC0CertifiedWorkCheckWithConstantsOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .const name levels =>
      match h : psKernelC0ConstantCachedInferWithFuel fuel
          work.raw.checker.context work.raw.checker.state
          name levels false with
      | none =>
          psKernelC0CertifiedWorkCheckWithLocalsOwned
            fuel work (.const name levels)
      | some (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
              work nextState).val), by
            have source : psKernelCheckerCheck fuel
                work.raw.checker.context work.raw.checker.state
                (.const name levels) = .ok (ty, nextState) :=
              psKernelC0ConstantCachedInfer_checkerCheck fuel
                work.raw.checker.context work.raw.checker.state
                name levels ty nextState h
            unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
            simp only [source]
            rfl⟩
  | other => psKernelC0CertifiedWorkCheckWithLocalsOwned fuel work other


/-!
Phase E.4O — complete source-exact constant inference for cache hits AND
cold environment resolution, without invoking the source inference walker.

Unlike the older warm-only fragment, this one uses the single mechanically
extracted, Lean 4.35-compatible cold constant rule from
Checker/Inference/Constant.lean. There is one source-cache lookup and
one recursion-depth check; cold success runs the full source primitive
environment/safety/arity/universe/type instantiation logic. The returned
value is admitted ONLY with a source-result AND complete state equality
witness, never by unchecked candidate agreement.
-/

/-- Full constant-head source algorithm, independent of the enclosing
    syntax-directed inference worker. A declined branch must still call the
    original source worker for its exact failure/error/resource semantics.
    Inference-only and fully checked caches remain distinct. -/
def psKernelC0ConstantCompleteInferWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (inferOnly : Bool) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ _ =>
      let expr : PsKernelExpr := .const name levels
      let cache := if inferOnly then state.inferOnly else state.checkedInfer
      match psKernelExprMapGet cache expr with
      | some ty =>
          match psKernelCheckerContextEnterRecDepth context with
          | .ok _ => some (ty, state)
          | .error _ => none
      | none =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error _ => none
          | .ok nextContext =>
              match psKernelInferConstantHead
                  nextContext state name levels inferOnly with
              | .error _ => none
              | .ok value => some value

/-- On EVERY successful independent constant inference branch, the entire
    result (including warm/cold infer and checked cache state) equals the
    original C0 source checker under any environment, local context, checked
    application hook or WHNF/DefEq callbacks. Negative/cancelled resource
    paths retain the original checker as the source of exact diagnostics. -/
theorem psKernelC0ConstantCompleteInfer_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → Except String (PsKernelExpr × PsKernelCheckerState))
    (defeq : PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → PsKernelExpr →
      Except String (Bool × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (inferOnly : Bool)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ConstantCompleteInferWithFuel
      fuel context state name levels inferOnly = some result) :
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.const name levels) inferOnly = .ok result := by
  cases fuel with
  | zero => simp [psKernelC0ConstantCompleteInferWithFuel] at h
  | succ remaining =>
      let expr : PsKernelExpr := .const name levels
      let cache := if inferOnly then state.inferOnly else state.checkedInfer
      cases cached : psKernelExprMapGet cache expr with
      | some ty =>
          cases depth : psKernelCheckerContextEnterRecDepth context with
          | error reason =>
              simp [psKernelC0ConstantCompleteInferWithFuel, cached,
                depth, cache, expr] at h
          | ok entered =>
              have hresult : result = (ty, state) := by
                have hx : some (ty, state) = some result := by
                  simpa [psKernelC0ConstantCompleteInferWithFuel,
                    cached, depth, cache, expr] using h
                exact (Option.some.inj hx).symm
              rw [hresult]
              have hcache :
                  psKernelExprMapGetWithKnownHash
                    (if inferOnly then state.inferOnly else state.checkedInfer)
                    (.const name levels) none = some ty := by
                change psKernelExprMapGet cache expr = some ty
                exact cached
              simpa [psKernelInferCoreWithFuelUsing,
                psKernelInferCoreWithFuelUsingSourceFrames,
                psKernelInferCacheEligible, hcache, depth]
      | none =>
          cases depth : psKernelCheckerContextEnterRecDepth context with
          | error reason =>
              simp [psKernelC0ConstantCompleteInferWithFuel, cached,
                depth, cache, expr] at h
          | ok entered =>
              cases chosen : psKernelInferConstantHead
                  entered state name levels inferOnly with
              | error reason =>
                  simp [psKernelC0ConstantCompleteInferWithFuel,
                    cached, depth, chosen, cache, expr] at h
              | ok value =>
                  have hresult : result = value := by
                    have hx : some value = some result := by
                      simpa [psKernelC0ConstantCompleteInferWithFuel,
                        cached, depth, chosen, cache, expr] using h
                    exact (Option.some.inj hx).symm
                  rw [hresult]
                  have hcache :
                      psKernelExprMapGetWithKnownHash
                        (if inferOnly then state.inferOnly else state.checkedInfer)
                        (.const name levels) none = none := by
                    change psKernelExprMapGet cache expr = none
                    exact cached
                  simpa [psKernelInferCoreWithFuelUsing,
                    psKernelInferCoreWithFuelUsingSourceFrames,
                    psKernelInferCacheEligible, hcache, depth, chosen]
