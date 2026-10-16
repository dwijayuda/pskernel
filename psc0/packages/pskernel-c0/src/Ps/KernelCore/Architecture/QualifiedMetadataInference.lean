import Ps.KernelCore.Architecture.QualifiedInferenceDispatch

/-!
Phase E.4P — source-exact recursive metadata typing.

Pinned Lean 4.35 src/kernel/type_checker.cpp::infer_type_core treats MData
as a transparent type wrapper and separately caches its inferred result.
C0's source inference does the same, but it also charges the original
fuel/recursion depth at EACH metadata layer.

This independent fragment evaluates arbitrary nested metadata terminating
in an already proved scalar/FVar/cold-or-warm-constant typing head, without
calling the source inference worker. Cache hits retain original source
state; cache misses recurse at exactly the historical smaller fuel and
context. Any declined head/resource/error falls back to the ORIGINAL
source checker, never to an unchecked type.
-/

/-- One metadata-aware, fuel-recursive source-exact inference fragment.
    The only terminal judgments are the previously proved qualified
    heads; each metadata step preserves the original cache mode. -/
def psKernelC0MetadataInferWithFuel :
    Nat → PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → Bool →
      Option (PsKernelExpr × PsKernelCheckerState)
  | 0, _, _, _, _ => none
  | Nat.succ remaining, context, state, expr, inferOnly =>
      match expr with
      | .mdata _ body =>
          let cache := if inferOnly then state.inferOnly
            else state.checkedInfer
          match (if psKernelInferCacheEligible inferOnly expr then
            psKernelExprMapGet cache expr else Option.none) with
          | some ty =>
              match psKernelCheckerContextEnterRecDepth context with
              | .ok _ => some (ty, state)
              | .error _ => none
          | none =>
              match psKernelCheckerContextEnterRecDepth context with
              | .error _ => none
              | .ok entered =>
                  match psKernelC0MetadataInferWithFuel
                      remaining entered state body inferOnly with
                  | none => none
                  | some (ty, checkedState) =>
                      some (ty,
                        psKernelCacheInferResult checkedState inferOnly
                          expr ty)
      | other =>
          psKernelC0QualifiedInferHeadWithFuel
            (Nat.succ remaining) context state other inferOnly

/-- For ANY source checking context/state and callbacks, every successful
    independent metadata result agrees with the entire original source
    inference result and cache state at the SAME fuel and recursion depth.
    The only induction step is the source's exact mdata recursion. -/
theorem psKernelC0MetadataInfer_source
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
    (h : psKernelC0MetadataInferWithFuel
      fuel context state expr inferOnly = some result) :
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state expr inferOnly = .ok result := by
  induction fuel generalizing context state expr inferOnly result with
  | zero => simp [psKernelC0MetadataInferWithFuel] at h
  | succ remaining ih =>
      cases expr with
      | mdata md body =>
          let term : PsKernelExpr := .mdata md body
          let cache := if inferOnly then state.inferOnly
            else state.checkedInfer
          cases cached :
              (if psKernelInferCacheEligible inferOnly term then
                psKernelExprMapGet cache term else Option.none) with
          | some ty =>
              cases depth : psKernelCheckerContextEnterRecDepth context with
              | error reason =>
                  simp [psKernelC0MetadataInferWithFuel, cached,
                    depth, cache, term] at h
              | ok entered =>
                  have hresult : result = (ty, state) := by
                    have hx : some (ty, state) = some result := by
                      simpa [psKernelC0MetadataInferWithFuel,
                        cached, depth, cache, term] using h
                    exact (Option.some.inj hx).symm
                  rw [hresult]
                  have hcache :
                      (if psKernelSemanticCacheEligible term then
                        psKernelExprMapGetWithKnownHash
                          (if inferOnly then state.inferOnly else state.checkedInfer)
                          (.mdata md body) none
                       else Option.none) = some ty := by
                    simpa [psKernelExprMapGet, psKernelInferCacheEligible, cache, term] using cached
                  have hcacheExact :
                      (if psKernelSemanticCacheEligible (.mdata md body) then
                        psKernelExprMapGetWithKnownHash
                          (if inferOnly then state.inferOnly else state.checkedInfer)
                          (.mdata md body) none
                       else Option.none) = some ty := by
                    simpa only [term] using hcache
                  simp [psKernelInferCoreWithFuelUsing,
                    psKernelInferCoreWithFuelUsingSourceFrames,
                    psKernelInferCacheEligible, hcacheExact, depth, term]
          | none =>
              cases depth : psKernelCheckerContextEnterRecDepth context with
              | error reason =>
                  simp [psKernelC0MetadataInferWithFuel, cached,
                    depth, cache, term] at h
              | ok entered =>
                  cases nested : psKernelC0MetadataInferWithFuel
                      remaining entered state body inferOnly with
                  | none =>
                      simp [psKernelC0MetadataInferWithFuel,
                        cached, depth, nested, cache, term] at h
                  | some nestedResult =>
                      cases nestedResult with
                      | mk ty checkedState =>
                          have hresult : result =
                              (ty, psKernelCacheInferResult
                                checkedState inferOnly term ty) := by
                            have hx : some (ty,
                                psKernelCacheInferResult
                                  checkedState inferOnly term ty) =
                                  some result := by
                              simpa [psKernelC0MetadataInferWithFuel,
                                cached, depth, nested, cache, term] using h
                            exact (Option.some.inj hx).symm
                          rw [hresult]
                          have hinner :
                              psKernelInferCoreWithFuelUsing remaining
                                onCheckedApp whnf defeq
                                entered state body inferOnly =
                                  .ok (ty, checkedState) := by
                            apply ih
                            exact nested
                          have hcache :
                              (if psKernelSemanticCacheEligible term then
                                psKernelExprMapGetWithKnownHash
                                  (if inferOnly then state.inferOnly
                                   else state.checkedInfer)
                                  (.mdata md body) none
                               else Option.none) = none := by
                            simpa [psKernelExprMapGet, psKernelInferCacheEligible, cache, term] using cached
                          change psKernelInferCoreWithFuelUsingSourceFrames
                            remaining onCheckedApp [] [] whnf defeq
                            entered state body inferOnly =
                              .ok (ty, checkedState) at hinner
                          simpa [psKernelInferCoreWithFuelUsing,
                            psKernelInferCoreWithFuelUsingSourceFrames,
                            psKernelInferCacheEligible, hcache, depth,
                            hinner, term]
      | sort level =>
          exact psKernelC0QualifiedInferHead_source
            (Nat.succ remaining) onCheckedApp whnf defeq
            context state (.sort level) inferOnly result
            (by simpa only [psKernelC0MetadataInferWithFuel] using h)
      | lit literal =>
          exact psKernelC0QualifiedInferHead_source
            (Nat.succ remaining) onCheckedApp whnf defeq
            context state (.lit literal) inferOnly result
            (by simpa only [psKernelC0MetadataInferWithFuel] using h)
      | fvar name =>
          exact psKernelC0QualifiedInferHead_source
            (Nat.succ remaining) onCheckedApp whnf defeq
            context state (.fvar name) inferOnly result
            (by simpa only [psKernelC0MetadataInferWithFuel] using h)
      | const name levels =>
          exact psKernelC0QualifiedInferHead_source
            (Nat.succ remaining) onCheckedApp whnf defeq
            context state (.const name levels) inferOnly result
            (by simpa only [psKernelC0MetadataInferWithFuel] using h)
      | bvar _ => simp [psKernelC0MetadataInferWithFuel,
          psKernelC0QualifiedInferHeadWithFuel] at h
      | mvar _ => simp [psKernelC0MetadataInferWithFuel,
          psKernelC0QualifiedInferHeadWithFuel] at h
      | app _ _ => simp [psKernelC0MetadataInferWithFuel,
          psKernelC0QualifiedInferHeadWithFuel] at h
      | lam _ _ _ _ => simp [psKernelC0MetadataInferWithFuel,
          psKernelC0QualifiedInferHeadWithFuel] at h
      | forallE _ _ _ _ => simp [psKernelC0MetadataInferWithFuel,
          psKernelC0QualifiedInferHeadWithFuel] at h
      | letE _ _ _ _ _ => simp [psKernelC0MetadataInferWithFuel,
          psKernelC0QualifiedInferHeadWithFuel] at h
      | proj _ _ _ => simp [psKernelC0MetadataInferWithFuel,
          psKernelC0QualifiedInferHeadWithFuel] at h

/-- The native inference API's callback arrangement is fixed, but the
    all-context metadata refinement above already covers that arrangement. -/
theorem psKernelC0MetadataInfer_checkerInfer
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState) (expr ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0MetadataInferWithFuel fuel context state expr true =
      some (ty, nextState)) :
    psKernelCheckerInfer fuel context state expr = .ok (ty, nextState) := by
  unfold psKernelCheckerInfer psKernelInferWithRecursorFuel
    psKernelInferWithFuel psKernelInferCoreWithFuel
  exact psKernelC0MetadataInfer_source fuel none
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state expr true
    (ty, nextState) h

/-- Metadata cannot select the checked-application specialization, so
    its full checking is the same hook-based inference core. -/
theorem psKernelC0MetadataInfer_checkerCheck
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (md : Nat) (body ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0MetadataInferWithFuel fuel
      context state (.mdata md body) false = some (ty, nextState)) :
    psKernelCheckerCheck fuel context state (.mdata md body) =
      .ok (ty, nextState) := by
  change psKernelInferCoreWithFuelUsing fuel
    (some psKernelC0CheckAppRecursiveResummarized)
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel)
    context state (.mdata md body) false = .ok (ty, nextState)
  exact psKernelC0MetadataInfer_source fuel
    (some psKernelC0CheckAppRecursiveResummarized)
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state (.mdata md body) false
    (ty, nextState) h

/-- Metadata-aware source-exact inference, with one fallback for other
    terms and declined/malformed metadata. Only successful typed exact
    source equations can leave this API. -/
def psKernelC0CertifiedWorkInferMetadataOwned
    (fuel : Nat) (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match expr with
  | .mdata md body =>
      match h : psKernelC0MetadataInferWithFuel fuel
          work.raw.checker.context work.raw.checker.state
          (.mdata md body) true with
      | none =>
          psKernelC0CertifiedWorkInferDirectOwned fuel work (.mdata md body)
      | some (ty, checkedState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work checkedState).val), by
            have source : psKernelCheckerInfer fuel
                work.raw.checker.context work.raw.checker.state
                (.mdata md body) = .ok (ty, checkedState) :=
              psKernelC0MetadataInfer_checkerInfer fuel
                work.raw.checker.context work.raw.checker.state
                (.mdata md body) ty checkedState h
            unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
            simp only [source]
            rfl⟩
  | other => psKernelC0CertifiedWorkInferDirectOwned fuel work other

/-- Source-exact FULL metadata checking, including checked-mode cache
    separation and exact successful result/complete source state witnesses. -/
def psKernelC0CertifiedWorkCheckMetadataOwned
    (fuel : Nat) (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .mdata md body =>
      match h : psKernelC0MetadataInferWithFuel fuel
          work.raw.checker.context work.raw.checker.state
          (.mdata md body) false with
      | none =>
          psKernelC0CertifiedWorkCheckDirectOwned fuel work (.mdata md body)
      | some (ty, checkedState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work checkedState).val), by
            have source : psKernelCheckerCheck fuel
                work.raw.checker.context work.raw.checker.state
                (.mdata md body) = .ok (ty, checkedState) :=
              psKernelC0MetadataInfer_checkerCheck fuel
                work.raw.checker.context work.raw.checker.state
                md body ty checkedState h
            unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
            simp only [source]
            rfl⟩
  | other => psKernelC0CertifiedWorkCheckDirectOwned fuel work other
