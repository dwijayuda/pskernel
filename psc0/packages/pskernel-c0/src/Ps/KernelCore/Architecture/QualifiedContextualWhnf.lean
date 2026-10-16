import Ps.KernelCore.Architecture.CertifiedWork

/-!
Phase E.4AD — independently executed, source-refined contextual WHNF heads.

Lean 4.35 src/kernel/type_checker.cpp::whnf and ::whnf_core distinguish
rigid local variables, reducible local lets, lambda values and immutable
WHNF-cache hits. Unlike the five older source-free irreducible heads,
a lambda goes through the public cache and (when cold) the core reduction
budget/depth check. A bound fvar with a value can only be fast-pathed on
the EXACT source cache hit; uncached let-bound variables delegate.

This finite fuel-recursive engine handles metadata around these heads,
preserving their original public-WHNF fuel and complete checker state.
Beta/zeta/delta, recursors, Nat arithmetic and general conversion are
NOT independently decided by this module. All declines run the source
checker, never authorize negative verdicts or proof admission.
-/

/-- Independently reproduce the exact source WHNF of rigid free variables
    and lambda heads, including warm cache and cold lambda publication.
    Metadata recursion charges one source fuel step per wrapper. -/
def psKernelC0ContextualHeadWhnfWithFuel :
    Nat → PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → Option (PsKernelExpr × PsKernelCheckerState)
  | 0, _, _, _ => none
  | Nat.succ remaining, context, state, expr =>
      match expr with
      | .mdata _ body =>
          psKernelC0ContextualHeadWhnfWithFuel remaining context state body
      | .fvar name =>
          match psKernelLocalContextFind context.localContext name with
          | none => some (expr, state)
          | some declaration =>
              match psKernelLocalDeclValue declaration with
              | none => some (expr, state)
              | some _ =>
                  -- A reducible local variable depends on this exact
                  -- scope. Never reuse its source-cache data by name.
                  none
      | .lam _ _ _ _ =>
          if psKernelSemanticCacheEligible expr then
            match psKernelExprMapGet state.whnf expr with
            | some cached => some (cached, state)
            | none =>
                match remaining with
                | 0 => none
                | Nat.succ _ =>
                    match psKernelCheckerContextEnterRecDepth context with
                    | .error _ => none
                    | .ok _ =>
                        some (expr,
                          psKernelCheckerStateWithWhnf state
                            (psKernelExprMapInsert state.whnf expr expr))
          else none
      | _ => none

/-- Every independently computed success equals the WHOLE original
    public source WHNF result, including all cache/state changes and
    for all source recursor callbacks, contexts, resource policies, and
    starting cache contents. An unsuccessful partial evaluation is never
    interpreted as a kernel rejection. -/
theorem psKernelC0ContextualHeadWhnf_source
    (fuel : Nat)
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ContextualHeadWhnfWithFuel
      fuel context state expr = some result) :
    psKernelWhnfWithFuel fuel reduceRecursor context state expr =
      .ok result := by
  induction fuel generalizing expr result with
  | zero =>
      simp [psKernelC0ContextualHeadWhnfWithFuel] at h
  | succ remaining ih =>
      cases expr with
      | mdata md body =>
          have nested :
              psKernelC0ContextualHeadWhnfWithFuel
                remaining context state body = some result := by
            simpa only [psKernelC0ContextualHeadWhnfWithFuel] using h
          change psKernelWhnfWithFuel remaining reduceRecursor
            context state body = .ok result
          exact ih body result nested
      | fvar name =>
          let term : PsKernelExpr := .fvar name
          cases lookup : psKernelLocalContextFind context.localContext name with
          | none =>
              have hr : result = (term, state) := by
                have hx : some (term, state) = some result := by
                  simpa [psKernelC0ContextualHeadWhnfWithFuel,
                    lookup, term] using h
                exact (Option.some.inj hx).symm
              rw [hr]
              simp [psKernelWhnfWithFuel, lookup, term]
          | some decl =>
              cases localValue : psKernelLocalDeclValue decl with
              | none =>
                  have hr : result = (term, state) := by
                    have hx : some (term, state) = some result := by
                      simpa [psKernelC0ContextualHeadWhnfWithFuel,
                        lookup, localValue, term] using h
                    exact (Option.some.inj hx).symm
                  rw [hr]
                  simp [psKernelWhnfWithFuel, lookup, localValue, term]
              | some value =>
                  simp [psKernelC0ContextualHeadWhnfWithFuel,
                    lookup, localValue, term] at h
      | lam name domain body binderInfo =>
          let term : PsKernelExpr := .lam name domain body binderInfo
          cases eligible : psKernelSemanticCacheEligible term with
          | false =>
              simp [psKernelC0ContextualHeadWhnfWithFuel,
                term, eligible] at h
          | true =>
            cases cache : psKernelExprMapGet state.whnf term with
            | some cached =>
                have hr : result = (cached, state) := by
                  have hx : some (cached, state) = some result := by
                    simpa [psKernelC0ContextualHeadWhnfWithFuel,
                      cache, eligible, term] using h
                  exact (Option.some.inj hx).symm
                rw [hr]
                simp [psKernelWhnfWithFuel, cache, eligible, term]
            | none =>
                cases remaining with
                | zero =>
                    simp [psKernelC0ContextualHeadWhnfWithFuel,
                      cache, eligible, term] at h
                | succ previous =>
                    cases depth : psKernelCheckerContextEnterRecDepth context with
                    | error reason =>
                        simp [psKernelC0ContextualHeadWhnfWithFuel,
                          cache, eligible, depth, term] at h
                    | ok entered =>
                        let nextState := psKernelCheckerStateWithWhnf state
                          (psKernelExprMapInsert state.whnf term term)
                        have hr : result = (term, nextState) := by
                          have hx : some (term, nextState) = some result := by
                            simpa [psKernelC0ContextualHeadWhnfWithFuel,
                              cache, eligible, depth, term, nextState] using h
                          exact (Option.some.inj hx).symm
                        rw [hr]
                        simp [psKernelWhnfWithFuel,
                          psKernelWhnfCoreWithFuel,
                          psKernelWhnfCoreWithFuelRanges,
                          psKernelWhnfAfterCore, psKernelReduceNatWith,
                          psKernelUnfoldDefinition, psKernelExprGetAppFn,
                          psKernelWhnfFinish, cache, eligible, depth, term, nextState]
      | bvar _ => simp [psKernelC0ContextualHeadWhnfWithFuel] at h
      | sort _ => simp [psKernelC0ContextualHeadWhnfWithFuel] at h
      | mvar _ => simp [psKernelC0ContextualHeadWhnfWithFuel] at h
      | forallE _ _ _ _ =>
          simp [psKernelC0ContextualHeadWhnfWithFuel] at h
      | const _ _ => simp [psKernelC0ContextualHeadWhnfWithFuel] at h
      | app _ _ => simp [psKernelC0ContextualHeadWhnfWithFuel] at h
      | letE _ _ _ _ _ =>
          simp [psKernelC0ContextualHeadWhnfWithFuel] at h
      | lit _ => simp [psKernelC0ContextualHeadWhnfWithFuel] at h
      | proj _ _ _ =>
          simp [psKernelC0ContextualHeadWhnfWithFuel] at h

/-- Every successful contextual WHNF head carries the exact source
    certified-work equation, not merely expression equality. -/
theorem psKernelC0ContextualHeadWhnf_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ContextualHeadWhnfWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr = some result) :
    psKernelC0CertifiedWorkWhnf fuel work expr =
      .ok (result.fst, (psKernelC0CertifiedWorkWithStateOwned
        work result.snd).val) := by
  have exactSource :
      psKernelCheckerWhnf fuel work.raw.checker.context
        work.raw.checker.state expr = .ok result := by
    change psKernelWhnfWithFuel fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr =
        .ok result
    exact psKernelC0ContextualHeadWhnf_source fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr result h
  rcases result with ⟨value, nextState⟩
  unfold psKernelC0CertifiedWorkWhnf psKernelSessionWhnf
  simp only [exactSource]
  rfl

/-- Default certified WHNF selector: direct contextual lambda/FVar where
    source-proof eligible, then the earlier direct irreducible/metadata
    fragment, and finally the unmodified source checker on every decline.
    All successes return a dependent source-operation witness. -/
def psKernelC0CertifiedWorkWhnfContextualOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0SourceExactWhnfOutput fuel work expr) :=
  match h : psKernelC0ContextualHeadWhnfWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr with
  | none =>
      psKernelC0CertifiedWorkWhnfCanonicalFastOwned fuel work expr
  | some result =>
      .ok ⟨(result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val),
        psKernelC0ContextualHeadWhnf_certified
          fuel work expr result h⟩
