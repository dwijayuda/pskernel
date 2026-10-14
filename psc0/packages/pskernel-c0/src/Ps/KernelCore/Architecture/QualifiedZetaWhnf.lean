import Ps.KernelCore.Architecture.QualifiedContextualWhnf

/-!
Phase E.4AE — fully source-refined cold one-step ζ normalization.

Official Lean 4.35 WHNF performs structural ζ before Nat primitives
and δ unfolding. The C0 source semantics include a public fuel step,
a core fuel/depth step, a recursive body fuel/depth step, a WHNF-core
cache write and a public WHNF cache write. This module directly executes
that entire bounded operation for a let whose ONE substitution produces
a Sort; it never calls the original WHNF evaluator on a successful path.

The source's low-cost consecutive-let range accelerator is excluded
rather than approximated. Existing cache hits, exhausted fuel/depth and
all other syntax fall back to the authoritative checker. This proves an
independently executed ζ fragment, not general WHNF/DefEq/soundness.
-/

/-- Exact source core-then-public cache updates after a completed cold
    public normalization. The original cache keys and insertion functions
    are reused, NOT externally authored handle/cache assertions. -/
def psKernelC0ColdOneStepWhnfState
    (state : PsKernelCheckerState)
    (expr value : PsKernelExpr) : PsKernelCheckerState :=
  let coreState := psKernelCheckerStateWithWhnfCore state
    (psKernelExprMapInsert state.whnfCore expr value)
  psKernelCheckerStateWithWhnf coreState
    (psKernelExprMapInsert coreState.whnf expr value)

/-- Pure successful ζ: check the same source-fuel/depth and existing cache
    misses as the original C0 public WHNF, substitute the one binder, and
    accept ONLY a resulting Sort. No source normalization worker runs. -/
def psKernelC0ZetaSortWhnfWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | Nat.succ (Nat.succ (Nat.succ _)) =>
      match expr with
      | .letE _ _ value body _ =>
          if psKernelC0HasLetPrefix 12 expr then none
          else
            match psKernelExprMapGet state.whnf expr with
            | some _ => none
            | none =>
                match psKernelCheckerContextEnterRecDepth context with
                | .error _ => none
                | .ok entered =>
                    match psKernelExprMapGet state.whnfCore expr with
                    | some _ => none
                    | none =>
                        match psKernelCheckerContextEnterRecDepth entered with
                        | .error _ => none
                        | .ok _ =>
                            match psKernelExprInstantiate1 body value with
                            | .sort level =>
                                let reduced : PsKernelExpr := .sort level
                                some (reduced,
                                  psKernelC0ColdOneStepWhnfState
                                    state expr reduced)
                            | _ => none
      | _ => none
  | _ => none

/-- Every independent ζ success is EXACTLY the C0 public WHNF outcome
    including both cache states, for arbitrary environment, recursor
    callback, cache, fuel and local-context/recursion policy. -/
theorem psKernelC0ZetaSortWhnf_source
    (fuel : Nat)
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ZetaSortWhnfWithFuel
      fuel context state expr = some result) :
    psKernelWhnfWithFuel fuel reduceRecursor context state expr =
      .ok result := by
  cases fuel with
  | zero =>
      simp [psKernelC0ZetaSortWhnfWithFuel] at h
  | succ first =>
      cases first with
      | zero =>
          simp [psKernelC0ZetaSortWhnfWithFuel] at h
      | succ second =>
          cases second with
          | zero =>
              simp [psKernelC0ZetaSortWhnfWithFuel] at h
          | succ remaining =>
              cases expr with
              | letE name ty value body nondep =>
                  let term : PsKernelExpr :=
                    .letE name ty value body nondep
                  by_cases hlong : psKernelC0HasLetPrefix 12 term = true
                  · simp [psKernelC0ZetaSortWhnfWithFuel,
                      hlong, term] at h
                  · cases publicCache :
                      psKernelExprMapGet state.whnf term with
                    | some cached =>
                        simp [psKernelC0ZetaSortWhnfWithFuel,
                          hlong, publicCache, term] at h
                    | none =>
                        cases depth :
                            psKernelCheckerContextEnterRecDepth context with
                        | error reason =>
                            simp [psKernelC0ZetaSortWhnfWithFuel,
                              hlong, publicCache, depth, term] at h
                        | ok entered =>
                            cases coreCache :
                                psKernelExprMapGet state.whnfCore term with
                            | some cached =>
                                simp [psKernelC0ZetaSortWhnfWithFuel,
                                  hlong, publicCache, depth, coreCache,
                                  term] at h
                            | none =>
                                cases childDepth :
                                    psKernelCheckerContextEnterRecDepth entered with
                                | error reason =>
                                    simp [psKernelC0ZetaSortWhnfWithFuel,
                                      hlong, publicCache, depth, coreCache,
                                      childDepth, term] at h
                                | ok child =>
                                    cases opened :
                                        psKernelExprInstantiate1 body value with
                                    | sort u =>
                                        let normalized : PsKernelExpr := .sort u
                                        let nextState :=
                                          psKernelC0ColdOneStepWhnfState
                                            state term normalized
                                        have hr : result = (normalized, nextState) := by
                                          have hx :
                                              some (normalized, nextState) =
                                                some result := by
                                            simpa [psKernelC0ZetaSortWhnfWithFuel,
                                              hlong, publicCache, depth, coreCache,
                                              childDepth, opened, term,
                                              normalized, nextState] using h
                                          exact (Option.some.inj hx).symm
                                        rw [hr]
                                        -- Qualify each source stage in isolation.
                                        -- Expanding public/core/Nat/delta at
                                        -- once creates exponential simplifier
                                        -- work and obscures fuel/cache effects.
                                        let whnfChild :=
                                          fun (ctx : PsKernelCheckerContext)
                                            (st : PsKernelCheckerState)
                                            (ex : PsKernelExpr) =>
                                              psKernelWhnfWithFuel
                                                (Nat.succ (Nat.succ remaining))
                                                reduceRecursor ctx st ex
                                        let coreState := psKernelCheckerStateWithWhnfCore
                                          state (psKernelExprMapInsert
                                            state.whnfCore term normalized)
                                        have bodyCore :
                                            psKernelWhnfCoreWithFuelRanges
                                              (Nat.succ remaining) []
                                              whnfChild reduceRecursor
                                              entered state normalized false false =
                                                .ok (normalized, state) := by
                                          simpa [psKernelWhnfCoreWithFuelRanges,
                                            childDepth, normalized, whnfChild]
                                        have letCore :
                                            psKernelWhnfCoreWithFuel
                                              (Nat.succ (Nat.succ remaining))
                                              whnfChild reduceRecursor context state
                                              term false false =
                                                .ok (normalized, coreState) := by
                                          simpa [psKernelWhnfCoreWithFuel,
                                            psKernelWhnfCoreWithFuelRanges,
                                            psKernelWhnfCoreFinishWithKnownHash,
                                            hlong, depth, coreCache, opened,
                                            bodyCore, term, normalized, coreState]
                                        have natSort :
                                            psKernelReduceNatWith whnfChild
                                              context coreState normalized =
                                                .ok (none, coreState) := by
                                          rfl
                                        have noDelta :
                                            psKernelUnfoldDefinition
                                              context normalized = none := by
                                          rfl
                                        have afterCore :
                                            psKernelWhnfAfterCore whnfChild
                                              context coreState term normalized =
                                                .ok (normalized, nextState) := by
                                          simpa [psKernelWhnfAfterCore,
                                            natSort, noDelta, psKernelWhnfFinish,
                                            psKernelC0ColdOneStepWhnfState,
                                            nextState, normalized, coreState]
                                        simpa [psKernelWhnfWithFuel,
                                          publicCache, letCore, afterCore,
                                          whnfChild]
                                    | bvar _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | fvar _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | mvar _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | const _ _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | app _ _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | lam _ _ _ _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | forallE _ _ _ _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | letE _ _ _ _ _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | lit _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | mdata _ _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
                                    | proj _ _ _ => simp [psKernelC0ZetaSortWhnfWithFuel,
                                        hlong, publicCache, depth, coreCache,
                                        childDepth, opened, term] at h
              | bvar _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | fvar _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | mvar _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | sort _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | const _ _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | app _ _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | lam _ _ _ _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | forallE _ _ _ _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | lit _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | mdata _ _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h
              | proj _ _ _ => simp [psKernelC0ZetaSortWhnfWithFuel] at h

/-- Carry successful source-equivalent ζ results through the same owned
    checked-work equation and immutable environmental lineage. -/
theorem psKernelC0ZetaSortWhnf_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ZetaSortWhnfWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr = some result) :
    psKernelC0CertifiedWorkWhnf fuel work expr =
      .ok (result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val) := by
  have source :
      psKernelCheckerWhnf fuel work.raw.checker.context
        work.raw.checker.state expr = .ok result := by
    change psKernelWhnfWithFuel fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr = .ok result
    exact psKernelC0ZetaSortWhnf_source fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr result h
  rcases result with ⟨value, nextState⟩
  unfold psKernelC0CertifiedWorkWhnf psKernelSessionWhnf
  simp only [source]
  rfl

/-- First select the directly computed one-step ζ result, then E.4AD
    contextual heads and the qualified E.2 irreducible/metadata checker;
    everything else remains on the exact original WHNF path. -/
def psKernelC0CertifiedWorkWhnfZetaOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0SourceExactWhnfOutput fuel work expr) :=
  match h : psKernelC0ZetaSortWhnfWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr with
  | none =>
      psKernelC0CertifiedWorkWhnfContextualOwned fuel work expr
  | some result =>
      .ok ⟨(result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val),
        psKernelC0ZetaSortWhnf_certified
          fuel work expr result h⟩
