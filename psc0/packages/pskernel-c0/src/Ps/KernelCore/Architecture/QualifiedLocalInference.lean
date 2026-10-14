import Ps.KernelCore.Architecture.QualifiedInference

/-!
Phase E.4L — source-exact independent local-variable type synthesis and check.

Lean 4.35 src/kernel/type_checker.cpp::infer_fvar resolves the local context's
unique name to its declaration type, while inference-only and fully checked
cache entries remain separate. C0's source InferCore performs the same
lookup after the original cache and recursion guard.

This small independent accepting fragment preserves successful source result,
all state/cache updates, and original source resource/unknown-local failures.
It is an *operational refinement*, not a claim that externally forged local
declarations or cache entries become trusted proof objects. The verified
provider still starts with an empty checked local context and does not import
caller-created local contexts.
-/

/-- Independent FVar head inference; no call into the source inference
    worker. A declined context/fuel/name delegates to that worker to retain
    its exact failure category. The untrusted raw-cache behavior is kept
    intentionally identical for the source-equivalence theorem. -/
def psKernelC0FVarInferWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (inferOnly : Bool) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ _ =>
      let expr : PsKernelExpr := .fvar name
      let cache := if inferOnly then state.inferOnly else state.checkedInfer
      match psKernelExprMapGet cache expr with
      | some ty =>
          match psKernelCheckerContextEnterRecDepth context with
          | .ok _ => some (ty, state)
          | .error _ => none
      | none =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error _ => none
          | .ok entered =>
              match psKernelLocalContextFind entered.localContext name with
              | none => none
              | some decl =>
                  let ty := psKernelLocalDeclType decl
                  some (ty, psKernelCacheInferResult state inferOnly expr ty)

/-- A successful independent local-variable result is exactly the original
    inference worker's complete result, for ANY source state, context,
    cache, optional checked-application hook or WHNF/DefEq callbacks. -/
theorem psKernelC0FVarInfer_source
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
    (inferOnly : Bool)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0FVarInferWithFuel fuel context state name inferOnly =
      some result) :
    psKernelInferCoreWithFuelUsing fuel onCheckedApp
      whnf defeq context state (.fvar name) inferOnly = .ok result := by
  cases fuel with
  | zero => simp [psKernelC0FVarInferWithFuel] at h
  | succ remaining =>
      let expr : PsKernelExpr := .fvar name
      let cache := if inferOnly then state.inferOnly
        else state.checkedInfer
      cases cached : psKernelExprMapGet cache expr with
      | some ty =>
          cases depth : psKernelCheckerContextEnterRecDepth context with
          | error reason =>
              simp only [psKernelC0FVarInferWithFuel, depth] at h
              split at h <;> cases h
          | ok entered =>
              have hresult : result = (ty, state) := by
                have hx : some (ty, state) = some result := by
                  simpa [psKernelC0FVarInferWithFuel, cached, depth,
                    cache, expr] using h
                exact (Option.some.inj hx).symm
              rw [hresult]
              have hcache :
                  psKernelExprMapGetWithKnownHash
                    (if inferOnly then state.inferOnly else state.checkedInfer)
                    (.fvar name) none = some ty := by
                change psKernelExprMapGet cache expr = some ty
                exact cached
              simpa [psKernelInferCoreWithFuelUsing,
                psKernelInferCoreWithFuelUsingSourceFrames,
                psKernelInferCacheEligible, hcache, depth]
      | none =>
          cases depth : psKernelCheckerContextEnterRecDepth context with
          | error reason =>
              simp only [psKernelC0FVarInferWithFuel, depth] at h
              split at h <;> cases h
          | ok entered =>
              cases found : psKernelLocalContextFind
                  entered.localContext name with
              | none =>
                  simp [psKernelC0FVarInferWithFuel,
                    cached, depth, found] at h
              | some decl =>
                  let ty : PsKernelExpr := psKernelLocalDeclType decl
                  have hresult :
                      result = (ty, psKernelCacheInferResult
                        state inferOnly expr ty) := by
                    have hx : some (ty,
                        psKernelCacheInferResult state inferOnly expr ty) =
                          some result := by
                      simpa [psKernelC0FVarInferWithFuel, cached,
                        depth, found, cache, expr, ty] using h
                    exact (Option.some.inj hx).symm
                  rw [hresult]
                  have hcache :
                      psKernelExprMapGetWithKnownHash
                        (if inferOnly then state.inferOnly
                          else state.checkedInfer)
                        (.fvar name) none = none := by
                    change psKernelExprMapGet cache expr = none
                    exact cached
                  simpa [psKernelInferCoreWithFuelUsing,
                    psKernelInferCoreWithFuelUsingSourceFrames,
                    psKernelInferCacheEligible, hcache, depth, found,
                    ty, expr]

/-- Source infer-only FVar checking uses precisely the previously defined
    infer-only cache and local context. -/
theorem psKernelC0FVarInfer_checkerInfer
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0FVarInferWithFuel
      fuel context state name true = some (ty, nextState)) :
    psKernelCheckerInfer fuel context state (.fvar name) =
      .ok (ty, nextState) := by
  unfold psKernelCheckerInfer psKernelInferWithRecursorFuel
    psKernelInferWithFuel psKernelInferCoreWithFuel
  exact psKernelC0FVarInfer_source fuel none
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state name true
    (ty, nextState) h

/-- A full source FVar check has the same result and distinct checked-infer
    cache effects, including the fully checked application hook configuration
    for other term forms. -/
theorem psKernelC0FVarInfer_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0FVarInferWithFuel fuel context state name false =
      some (ty, nextState)) :
    psKernelCheckerCheck fuel context state (.fvar name) =
      .ok (ty, nextState) := by
  change psKernelInferCoreWithFuelUsing fuel
    (some psKernelC0CheckAppRecursiveResummarized)
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state (.fvar name) false =
      .ok (ty, nextState)
  exact psKernelC0FVarInfer_source fuel
    (some psKernelC0CheckAppRecursiveResummarized)
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state name false
    (ty, nextState) h

/-- Refined local-variable inference with the same proof receipt shape used
    by the scalar source-exact selector. All other terms and failed direct
    local lookups remain on the already-qualified scalar/source path. -/
def psKernelC0CertifiedWorkInferWithLocalsOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match expr with
  | .fvar name =>
      match h : psKernelC0FVarInferWithFuel fuel
          work.raw.checker.context work.raw.checker.state name true with
      | none => psKernelC0CertifiedWorkInferQualifiedOwned fuel work expr
      | some (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
              work nextState).val), by
            have source : psKernelCheckerInfer fuel
                work.raw.checker.context work.raw.checker.state
                (.fvar name) = .ok (ty, nextState) :=
              psKernelC0FVarInfer_checkerInfer fuel
                work.raw.checker.context work.raw.checker.state
                name ty nextState h
            unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
            simp only [source]
            rfl⟩
  | _ => psKernelC0CertifiedWorkInferQualifiedOwned fuel work expr

/-- Source-equivalent FULL checked local-variable typing, with source-proof
    equality for the original checker result. A loose/unknown local context
    is not promoted to a new verified public session by this function. -/
def psKernelC0CertifiedWorkCheckWithLocalsOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .fvar name =>
      match h : psKernelC0FVarInferWithFuel fuel
          work.raw.checker.context work.raw.checker.state name false with
      | none => psKernelC0CertifiedWorkCheckQualifiedOwned fuel work expr
      | some (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
              work nextState).val), by
            have source : psKernelCheckerCheck fuel
                work.raw.checker.context work.raw.checker.state
                (.fvar name) = .ok (ty, nextState) :=
              psKernelC0FVarInfer_checkerCheck fuel
                work.raw.checker.context work.raw.checker.state
                name ty nextState h
            unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
            simp only [source]
            rfl⟩
  | _ => psKernelC0CertifiedWorkCheckQualifiedOwned fuel work expr
