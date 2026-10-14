import Ps.KernelCore.Architecture.CertifiedWork

/-!
Phase E.4J: fully source-exact scalar type inference and full checking.

Based on pinned Lean 4.35 src/kernel/type_checker.cpp, infer_type_core:
Sort produces Sort (succ u); Nat/String literals produce their primitive type.
Importantly, infer-only versus full checked inference use different caches,
and the source C0 worker enforces recursion and numeral-size limits.

The independent fragment is used ONLY after an exact Lean proof that the
returned expression AND complete source checker state match the original
source inference worker. Unsupported heads and declined resource budgets
run through the original source checker. This does not prove well-typedness
of arbitrary imported constants, closure values or externally forged caches.
-/

/-- Source-equivalent scalar type synthesis for one fully evaluated head.
    The result is an option instead of a verdict: exhausted source fuel,
    failed recursion and oversize Nat all delegate to the source checker for
    its exact diagnostic category and failure precedence. -/
def psKernelC0ScalarInferWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (inferOnly : Bool) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ _ =>
      match expr with
      | .sort level =>
          let cache := if inferOnly then state.inferOnly
            else state.checkedInfer
          match psKernelExprMapGet cache expr with
          | some type =>
              match psKernelCheckerContextEnterRecDepth context with
              | .ok _ => some (type, state)
              | .error _ => none
          | none =>
              match psKernelCheckerContextEnterRecDepth context with
              | .error _ => none
              | .ok _ =>
                  let ty : PsKernelExpr := .sort (.succ level)
                  some (ty, psKernelCacheInferResult state inferOnly expr ty)
      | .lit literal =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error _ => none
          | .ok nextContext =>
              match literal with
              | .nat value =>
                  match psKernelCheckNatSize nextContext.maxNatSize value with
                  | .error _ => none
                  | .ok _ =>
                      let ty : PsKernelExpr := .const psKernelNatName []
                      some (ty, psKernelCacheInferResult state inferOnly expr ty)
              | .str _ =>
                  let ty : PsKernelExpr := .const psKernelStringName []
                  some (ty, psKernelCacheInferResult state inferOnly expr ty)
      | _ => none

/-- Every successful scalar result preserves the whole original inference
    algorithm, independent of the WHNF/DefEq callbacks. Includes exact
    memo/state behavior even for a starting raw source cache: this is an
    operational refinement, NOT proof of the validity of forged raw caches. -/
theorem psKernelC0ScalarInfer_source
    (fuel : Nat)
    (whnf :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Except String (PsKernelExpr × PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext → PsKernelCheckerState →
        PsKernelExpr → PsKernelExpr →
        Except String (Bool × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (inferOnly : Bool)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ScalarInferWithFuel fuel context state expr inferOnly =
      some result) :
    psKernelInferCoreWithFuel fuel whnf defeq context state expr inferOnly =
      .ok result := by
  cases fuel with
  | zero =>
      simp [psKernelC0ScalarInferWithFuel] at h
  | succ remaining =>
      cases expr with
      | sort level =>
          let expr : PsKernelExpr := .sort level
          let cache := if inferOnly then state.inferOnly
            else state.checkedInfer
          cases cached : psKernelExprMapGet cache expr with
          | some ty =>
              cases depth : psKernelCheckerContextEnterRecDepth context with
              | error reason =>
                  simp [psKernelC0ScalarInferWithFuel, cached, depth] at h
              | ok nextContext =>
                  have hresult : result = (ty, state) := by
                    have hx : some (ty, state) = some result := by
                      simpa [psKernelC0ScalarInferWithFuel, cached, depth,
                        cache, expr] using h
                    exact (Option.some.inj hx).symm
                  rw [hresult]
                  simp [psKernelInferCoreWithFuel,
                    psKernelInferCoreWithFuelUsing,
                    psKernelInferCoreWithFuelUsingSourceFrames,
                    psKernelInferCacheEligible, psKernelExprMapGet,
                    psKernelExprMapGetWithKnownHash, cached, depth,
                    cache, expr]
          | none =>
              cases depth : psKernelCheckerContextEnterRecDepth context with
              | error reason =>
                  simp [psKernelC0ScalarInferWithFuel, cached, depth] at h
              | ok nextContext =>
                  let ty : PsKernelExpr := .sort (.succ level)
                  have hresult :
                      result = (ty, psKernelCacheInferResult state inferOnly
                        expr ty) := by
                    have hx : some (ty,
                        psKernelCacheInferResult state inferOnly expr ty) =
                          some result := by
                      simpa [psKernelC0ScalarInferWithFuel, cached, depth,
                        cache, expr, ty] using h
                    exact (Option.some.inj hx).symm
                  rw [hresult]
                  simp [psKernelInferCoreWithFuel,
                    psKernelInferCoreWithFuelUsing,
                    psKernelInferCoreWithFuelUsingSourceFrames,
                    psKernelInferCacheEligible, psKernelExprMapGet,
                    psKernelExprMapGetWithKnownHash, cached, depth,
                    cache, expr, ty]
      | lit literal =>
          cases depth : psKernelCheckerContextEnterRecDepth context with
          | error reason =>
              simp [psKernelC0ScalarInferWithFuel, depth] at h
          | ok nextContext =>
              cases literal with
              | nat value =>
                  cases size : psKernelCheckNatSize nextContext.maxNatSize
                      value with
                  | error reason =>
                      simp [psKernelC0ScalarInferWithFuel, depth, size] at h
                  | ok ignored =>
                      let expr : PsKernelExpr := .lit (.nat value)
                      let ty : PsKernelExpr := .const psKernelNatName []
                      have hresult :
                          result = (ty, psKernelCacheInferResult
                            state inferOnly expr ty) := by
                        have hx : some (ty,
                            psKernelCacheInferResult state inferOnly expr ty) =
                              some result := by
                          simpa [psKernelC0ScalarInferWithFuel, depth, size,
                            expr, ty] using h
                        exact (Option.some.inj hx).symm
                      rw [hresult]
                      simp [psKernelInferCoreWithFuel,
                        psKernelInferCoreWithFuelUsing,
                        psKernelInferCoreWithFuelUsingSourceFrames,
                        psKernelInferCacheEligible, depth, size, expr, ty]
              | str value =>
                  let expr : PsKernelExpr := .lit (.str value)
                  let ty : PsKernelExpr := .const psKernelStringName []
                  have hresult :
                      result = (ty, psKernelCacheInferResult
                        state inferOnly expr ty) := by
                    have hx : some (ty,
                        psKernelCacheInferResult state inferOnly expr ty) =
                          some result := by
                      simpa [psKernelC0ScalarInferWithFuel, depth, expr, ty]
                        using h
                    exact (Option.some.inj hx).symm
                  rw [hresult]
                  simp [psKernelInferCoreWithFuel,
                    psKernelInferCoreWithFuelUsing,
                    psKernelInferCoreWithFuelUsingSourceFrames,
                    psKernelInferCacheEligible, depth, expr, ty]
      | bvar _ => simp [psKernelC0ScalarInferWithFuel] at h
      | fvar _ => simp [psKernelC0ScalarInferWithFuel] at h
      | mvar _ => simp [psKernelC0ScalarInferWithFuel] at h
      | const _ _ => simp [psKernelC0ScalarInferWithFuel] at h
      | app _ _ => simp [psKernelC0ScalarInferWithFuel] at h
      | lam _ _ _ _ => simp [psKernelC0ScalarInferWithFuel] at h
      | forallE _ _ _ _ => simp [psKernelC0ScalarInferWithFuel] at h
      | letE _ _ _ _ _ => simp [psKernelC0ScalarInferWithFuel] at h
      | mdata _ _ => simp [psKernelC0ScalarInferWithFuel] at h
      | proj _ _ _ => simp [psKernelC0ScalarInferWithFuel] at h

/-- Convert the pure source-refinement theorem into a complete checked
    native inference-state equation. No new typing rule or axiom. -/
theorem psKernelC0ScalarInfer_checkerInfer
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState) (expr ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0ScalarInferWithFuel fuel context state expr true =
      some (ty, nextState)) :
    psKernelCheckerInfer fuel context state expr = .ok (ty, nextState) := by
  unfold psKernelCheckerInfer psKernelInferWithRecursorFuel
    psKernelInferWithFuel
  exact psKernelC0ScalarInfer_source fuel
    (psKernelWhnfWithRecursorFuel fuel
      (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel) context state expr true
    (ty, nextState) h

/-- Exact source full-check equation, not a mere infer-only type witness. -/
theorem psKernelC0ScalarInfer_checkerCheck
    (fuel : Nat) (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState) (expr ty : PsKernelExpr)
    (nextState : PsKernelCheckerState)
    (h : psKernelC0ScalarInferWithFuel fuel context state expr false =
      some (ty, nextState)) :
    psKernelCheckerCheck fuel context state expr = .ok (ty, nextState) := by
  unfold psKernelCheckerCheck psKernelCheckWithFuel
  -- Source fully checked application-specialization is irrelevant
  -- to Sort/Nat/String heads.
  cases expr with
  | app _ _ =>
      simp [psKernelC0ScalarInferWithFuel] at h
  | sort level =>
      simp only [reduceCtorEq, Bool.false_eq_true, dite_false, ite_false]
      exact psKernelC0ScalarInfer_source fuel
        (psKernelWhnfWithRecursorFuel fuel
          (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel) context state
        (.sort level) false (ty, nextState) h
  | lit literal =>
      simp only [reduceCtorEq, Bool.false_eq_true, dite_false, ite_false]
      exact psKernelC0ScalarInfer_source fuel
        (psKernelWhnfWithRecursorFuel fuel
          (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel) context state
        (.lit literal) false (ty, nextState) h
  | bvar _ => simp [psKernelC0ScalarInferWithFuel] at h
  | fvar _ => simp [psKernelC0ScalarInferWithFuel] at h
  | mvar _ => simp [psKernelC0ScalarInferWithFuel] at h
  | const _ _ => simp [psKernelC0ScalarInferWithFuel] at h
  | lam _ _ _ _ => simp [psKernelC0ScalarInferWithFuel] at h
  | forallE _ _ _ _ => simp [psKernelC0ScalarInferWithFuel] at h
  | letE _ _ _ _ _ => simp [psKernelC0ScalarInferWithFuel] at h
  | mdata _ _ => simp [psKernelC0ScalarInferWithFuel] at h
  | proj _ _ _ => simp [psKernelC0ScalarInferWithFuel] at h

/-- Source-equation-backed inference for the scalar fragment and all
    fallback terms. Even a successful inferred type is NOT a checked
    declaration/proof. -/
def psKernelC0CertifiedWorkInferQualifiedOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkInfer fuel work expr = .ok result } :=
  match h : psKernelC0ScalarInferWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr true with
  | none =>
      match source : psKernelC0CertifiedWorkInfer fuel work expr with
      | .error reason => .error reason
      | .ok result => .ok ⟨result, source⟩
  | some (ty, nextState) =>
      .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned work nextState).val),
        by
          have source :
              psKernelCheckerInfer fuel work.raw.checker.context
                work.raw.checker.state expr = .ok (ty, nextState) :=
            psKernelC0ScalarInfer_checkerInfer fuel
              work.raw.checker.context work.raw.checker.state
              expr ty nextState h
          unfold psKernelC0CertifiedWorkInfer psKernelSessionInfer
          simp only [source]
          rfl⟩

/-- Independently qualified FULL source checking for source-scalar terms.
    It preserves both the distinct checked-inference cache and exact
    original typing/error semantics for all unsupported expression heads. -/
def psKernelC0CertifiedWorkCheckQualifiedOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match h : psKernelC0ScalarInferWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr false with
  | none =>
      match source : psKernelC0CertifiedWorkCheck fuel work expr with
      | .error reason => .error reason
      | .ok result => .ok ⟨result, source⟩
  | some (ty, nextState) =>
      .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned work nextState).val),
        by
          have source :
              psKernelCheckerCheck fuel work.raw.checker.context
                work.raw.checker.state expr = .ok (ty, nextState) :=
            psKernelC0ScalarInfer_checkerCheck fuel
              work.raw.checker.context work.raw.checker.state
              expr ty nextState h
          unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
          simp only [source]
          rfl⟩
