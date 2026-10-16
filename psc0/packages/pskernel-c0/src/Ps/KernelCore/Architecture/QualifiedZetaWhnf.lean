import Ps.KernelCore.Architecture.QualifiedWhnfTerminal

/-!
Phase E.4AG — source-refined cold one-step ζ normalization to stable WHNF heads.

Official Lean 4.35 WHNF performs structural ζ before Nat primitives
and δ unfolding. The C0 source semantics include a public fuel step,
a core fuel/depth step, a recursive body fuel/depth step, a WHNF-core
cache write and a public WHNF cache write. This module directly executes
that entire bounded operation for a let whose ONE substitution produces
an irreducible WHNF terminal; it never calls source WHNF on a successful path.

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
    accept only a stable WHNF terminal. No source normalization worker runs. -/
def psKernelC0ZetaStableWhnfWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | Nat.succ (Nat.succ (Nat.succ _)) =>
      match expr with
      | .letE _ _ value body _ =>
          -- Decline scoped syntax; the original source checker then owns
          -- all cache/environment effects for local FVar occurrences.
          if !psKernelSemanticCacheEligible expr then none
          else if psKernelC0HasLetPrefix 12 expr then none
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
                            let reduced := psKernelExprInstantiate1 body value
                            if psKernelC0StableWhnfTerminal reduced then
                              some (reduced,
                                psKernelC0ColdOneStepWhnfState
                                  state expr reduced)
                            else none
      | _ => none
  | _ => none

/-- Every independent ζ success is EXACTLY the C0 public WHNF outcome
    including both cache states, for arbitrary environment, recursor
    callback, cache, fuel and local-context/recursion policy. -/
theorem psKernelC0ZetaStableWhnf_source
    (fuel : Nat)
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ZetaStableWhnfWithFuel
      fuel context state expr = some result) :
    psKernelWhnfWithFuel fuel reduceRecursor context state expr =
      .ok result := by
  cases fuel with
  | zero => simp [psKernelC0ZetaStableWhnfWithFuel] at h
  | succ first =>
      cases first with
      | zero => simp [psKernelC0ZetaStableWhnfWithFuel] at h
      | succ second =>
          cases second with
          | zero => simp [psKernelC0ZetaStableWhnfWithFuel] at h
          | succ remaining =>
              cases expr with
              | letE name ty value body nondep =>
                  let term : PsKernelExpr := .letE name ty value body nondep
                  have eligible : psKernelSemanticCacheEligible term = true := by
                    by_cases he : psKernelSemanticCacheEligible term = true
                    · exact he
                    · simp [psKernelC0ZetaStableWhnfWithFuel,
                        he, term] at h
                  by_cases hlong : psKernelC0HasLetPrefix 12 term = true
                  · simp [psKernelC0ZetaStableWhnfWithFuel,
                      eligible, hlong, term] at h
                  · cases publicCache : psKernelExprMapGet state.whnf term with
                    | some cached =>
                        simp [psKernelC0ZetaStableWhnfWithFuel,
                          eligible, hlong, publicCache, term] at h
                    | none =>
                        cases depth :
                            psKernelCheckerContextEnterRecDepth context with
                        | error reason =>
                            simp [psKernelC0ZetaStableWhnfWithFuel,
                              eligible, hlong, publicCache, depth, term] at h
                        | ok entered =>
                            cases coreCache :
                                psKernelExprMapGet state.whnfCore term with
                            | some cached =>
                                simp [psKernelC0ZetaStableWhnfWithFuel,
                                  eligible, eligible, hlong, publicCache, depth, coreCache, term] at h
                            | none =>
                                cases childDepth :
                                    psKernelCheckerContextEnterRecDepth entered with
                                | error reason =>
                                    simp [psKernelC0ZetaStableWhnfWithFuel,
                                      eligible, hlong, publicCache, depth, coreCache,
                                      childDepth, term] at h
                                | ok child =>
                                    let normalized : PsKernelExpr :=
                                      psKernelExprInstantiate1 body value
                                    by_cases stable :
                                        psKernelC0StableWhnfTerminal normalized = true
                                    · let nextState :=
                                        psKernelC0ColdOneStepWhnfState
                                          state term normalized
                                      have hr : result = (normalized, nextState) := by
                                        have hx : some (normalized, nextState) =
                                            some result := by
                                          simpa [psKernelC0ZetaStableWhnfWithFuel,
                                            eligible, hlong, publicCache, depth, coreCache,
                                            childDepth, stable, normalized,
                                            term, nextState] using h
                                        exact (Option.some.inj hx).symm
                                      rw [hr]
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
                                              .ok (normalized, state) :=
                                        psKernelC0StableWhnfTerminal_core
                                          remaining whnfChild reduceRecursor
                                          entered state normalized child
                                          childDepth stable
                                      have letCore :
                                          psKernelWhnfCoreWithFuel
                                            (Nat.succ (Nat.succ remaining))
                                            whnfChild reduceRecursor context state
                                            term false false =
                                              .ok (normalized, coreState) := by
                                        change psKernelWhnfCoreWithFuelRanges
                                          (Nat.succ (Nat.succ remaining)) []
                                          whnfChild reduceRecursor context state
                                          term false false =
                                            .ok (normalized, coreState)
                                        rw [psKernelWhnfCoreWithFuelRanges]
                                        simp [depth, hlong, coreCache,
                                          bodyCore, psKernelWhnfCoreFinishWithKnownHash, eligible,
                                          psKernelExprMapInsert, term,
                                          coreState, normalized]
                                      have afterCore :
                                          psKernelWhnfAfterCore whnfChild
                                            context coreState term normalized =
                                              .ok (normalized, nextState) := by
                                        rw [psKernelC0StableWhnfTerminal_post
                                          whnfChild context coreState term
                                          normalized stable]
                                        simp [psKernelWhnfFinish,
                                          eligible, nextState,
                                          psKernelC0ColdOneStepWhnfState,
                                          coreState]
                                      change
                                        (match (if psKernelSemanticCacheEligible term then
                                            psKernelExprMapGet state.whnf term
                                          else Option.none) with
                                        | some cached => Except.ok (cached, state)
                                        | none =>
                                            match psKernelWhnfCoreWithFuel
                                                (Nat.succ (Nat.succ remaining))
                                                whnfChild reduceRecursor
                                                context state term false false with
                                            | .error reason => Except.error reason
                                            | .ok coreResult =>
                                                psKernelWhnfAfterCore
                                                  whnfChild context
                                                  coreResult.snd term
                                                  coreResult.fst) =
                                          Except.ok (normalized, nextState)
                                      simp only [eligible, ite_true,
                                        publicCache, letCore, afterCore]
                                    · simp [psKernelC0ZetaStableWhnfWithFuel,
                                        eligible, hlong, publicCache, depth, coreCache,
                                        childDepth, stable, normalized, term] at h
              | bvar _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | fvar _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | mvar _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | sort _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | const _ _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | app _ _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | lam _ _ _ _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | forallE _ _ _ _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | lit _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | mdata _ _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h
              | proj _ _ _ => simp [psKernelC0ZetaStableWhnfWithFuel] at h

/-- Carry successful source-equivalent ζ results through the same owned
    checked-work equation and immutable environmental lineage. -/
theorem psKernelC0ZetaStableWhnf_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0ZetaStableWhnfWithFuel fuel
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
    exact psKernelC0ZetaStableWhnf_source fuel
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
  match h : psKernelC0ZetaStableWhnfWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr with
  | none =>
      psKernelC0CertifiedWorkWhnfContextualOwned fuel work expr
  | some result =>
      .ok ⟨(result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val),
        psKernelC0ZetaStableWhnf_certified
          fuel work expr result h⟩
