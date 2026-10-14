import Ps.KernelCore.Architecture.QualifiedZetaWhnf

/-!
Phase E.4AF: independently executed one-argument beta WHNF to a Sort.

Pinned semantics: Lean 4.35.0 src/kernel/type_checker.cpp::whnf_core,
and C0 Checker/Reduction/WhnfCore.lean. A cold application of a lambda
head consumes public WHNF fuel, one parent core WHNF fuel/depth,
one head core WHNF fuel/depth, and one independently evaluated reduced
body core WHNF fuel/depth. The latter two use the SAME entered parent
context and have no state effects when their heads are lambda and Sort.
The parent application receives the source core and public cache writes.

This implementation does not invoke source WHNF when successful. It
uses the existing source single-binder instantiation primitive, but
neither the historical recursive WHNF evaluator nor candidate output
can authorize proof admission. All unsupported cases, warm-cache hits,
short fuel, unavailable depth and non-Sort beta outcomes decline and
retain prior qualified source behavior.
-/

/-- A source-exact one-step beta result with its two cache publications.
    The original source WHNF has no additional child cache writes when
    the head is a lambda and the beta-opened body is a Sort. -/
def psKernelC0BetaSortWhnfWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | Nat.succ (Nat.succ (Nat.succ _)) =>
      match expr with
      | .app (.lam _ _ body _) argument =>
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
                          match psKernelExprInstantiate1 body argument with
                          | .sort level =>
                              let normalized : PsKernelExpr := .sort level
                              some (normalized,
                                psKernelC0ColdOneStepWhnfState
                                  state expr normalized)
                          | _ => none
      | _ => none
  | _ => none

/-- One cold beta-to-Sort success matches the FULL source public WHNF
    result and state, for arbitrary contexts, starting caches, bounded
    resources, and recursor callbacks. The proof intentionally separates
    the head, reduced-body, application-core and post-core steps. -/
theorem psKernelC0BetaSortWhnf_source
    (fuel : Nat)
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0BetaSortWhnfWithFuel
      fuel context state expr = some result) :
    psKernelWhnfWithFuel fuel reduceRecursor context state expr =
      .ok result := by
  cases fuel with
  | zero => simp [psKernelC0BetaSortWhnfWithFuel] at h
  | succ first =>
      cases first with
      | zero => simp [psKernelC0BetaSortWhnfWithFuel] at h
      | succ second =>
          cases second with
          | zero => simp [psKernelC0BetaSortWhnfWithFuel] at h
          | succ remaining =>
              cases expr with
              | app fn argument =>
                  cases fn with
                  | lam name domain body binderInfo =>
                      let head : PsKernelExpr :=
                        .lam name domain body binderInfo
                      let term : PsKernelExpr := .app head argument
                      cases publicCache : psKernelExprMapGet state.whnf term with
                      | some cached =>
                          simp [psKernelC0BetaSortWhnfWithFuel,
                            publicCache, head, term] at h
                      | none =>
                          cases depth :
                              psKernelCheckerContextEnterRecDepth context with
                          | error reason =>
                              simp [psKernelC0BetaSortWhnfWithFuel,
                                publicCache, depth, head, term] at h
                          | ok entered =>
                              cases coreCache :
                                  psKernelExprMapGet state.whnfCore term with
                              | some cached =>
                                  simp [psKernelC0BetaSortWhnfWithFuel,
                                    publicCache, depth, coreCache,
                                    head, term] at h
                              | none =>
                                  cases childDepth :
                                      psKernelCheckerContextEnterRecDepth entered with
                                  | error reason =>
                                      simp [psKernelC0BetaSortWhnfWithFuel,
                                        publicCache, depth, coreCache,
                                        childDepth, head, term] at h
                                  | ok child =>
                                      cases opened :
                                          psKernelExprInstantiate1 body argument with
                                      | sort level =>
                                          let normalized : PsKernelExpr := .sort level
                                          let nextState := psKernelC0ColdOneStepWhnfState
                                            state term normalized
                                          have hr : result = (normalized, nextState) := by
                                            have hx : some (normalized, nextState) =
                                                some result := by
                                              simpa [psKernelC0BetaSortWhnfWithFuel,
                                                publicCache, depth, coreCache,
                                                childDepth, opened, head,
                                                term, normalized, nextState] using h
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
                                          have headCore :
                                              psKernelWhnfCoreWithFuelRanges
                                                (Nat.succ remaining) []
                                                whnfChild reduceRecursor
                                                entered state head false false =
                                                  .ok (head, state) := by
                                            simpa [psKernelWhnfCoreWithFuelRanges,
                                              childDepth, head]
                                          have bodyCore :
                                              psKernelWhnfCoreWithFuelRanges
                                                (Nat.succ remaining) []
                                                whnfChild reduceRecursor
                                                entered state normalized false false =
                                                  .ok (normalized, state) := by
                                            simpa [psKernelWhnfCoreWithFuelRanges,
                                              childDepth, normalized]
                                          have betaBody :
                                              psKernelC0BetaSpineApply
                                                (body, ([argument], [])) =
                                                  normalized := by
                                            simpa [psKernelC0BetaSpineApply,
                                              psKernelExprApplyArgsCheap,
                                              psKernelExprApplyArgsCheapWorker,
                                              opened, normalized]
                                          have appCore :
                                              psKernelWhnfCoreWithFuel
                                                (Nat.succ (Nat.succ remaining))
                                                whnfChild reduceRecursor
                                                context state term false false =
                                                  .ok (normalized, coreState) := by
                                            simpa [psKernelWhnfCoreWithFuel,
                                              psKernelWhnfCoreWithFuelRanges,
                                              psKernelExprGetAppFn,
                                              psKernelExprGetAppArgs,
                                              psKernelExprGetAppArgsWorker,
                                              psKernelC0BetaSpinePlan,
                                              psKernelC0BetaSpineWorker,
                                              psKernelWhnfCoreFinishWithKnownHash,
                                              psKernelExprMapInsert,
                                              depth, coreCache, childDepth,
                                              headCore, betaBody, bodyCore,
                                              head, term, normalized, coreState]
                                          have natSort :
                                              psKernelReduceNatWith whnfChild
                                                context coreState normalized =
                                                  .ok (none, coreState) := by
                                            rfl
                                          have noDelta :
                                              psKernelUnfoldDefinition context
                                                normalized = none := by
                                            rfl
                                          have afterCore :
                                              psKernelWhnfAfterCore whnfChild
                                                context coreState term normalized =
                                                  .ok (normalized, nextState) := by
                                            simpa [psKernelWhnfAfterCore, natSort,
                                              noDelta, psKernelWhnfFinish,
                                              psKernelC0ColdOneStepWhnfState,
                                              nextState, normalized, coreState]
                                          change
                                            (match psKernelExprMapGet state.whnf term with
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
                                                      coreResult.snd term coreResult.fst) =
                                              Except.ok (normalized, nextState)
                                          simp only [publicCache, appCore, afterCore]
                                      | bvar _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | fvar _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | mvar _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | const _ _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | app _ _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | lam _ _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | forallE _ _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | letE _ _ _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | lit _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | mdata _ _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                                      | proj _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel,
                                          publicCache, depth, coreCache,
                                          childDepth, opened, head, term] at h
                  | bvar _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | fvar _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | mvar _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | sort _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | const _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | app _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | forallE _ _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | letE _ _ _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | lit _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | mdata _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
                  | proj _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | bvar _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | fvar _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | mvar _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | sort _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | const _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | lam _ _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | forallE _ _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | letE _ _ _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | lit _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | mdata _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h
              | proj _ _ _ => simp [psKernelC0BetaSortWhnfWithFuel] at h

/-- Lift the exact source evaluator equation into certified immutable work. -/
theorem psKernelC0BetaSortWhnf_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0BetaSortWhnfWithFuel fuel
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
    exact psKernelC0BetaSortWhnf_source fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr result h
  rcases result with ⟨value, nextState⟩
  unfold psKernelC0CertifiedWorkWhnf psKernelSessionWhnf
  simp only [source]
  rfl

/-- Select the independently executed beta fragment only with a Lean
    theorem proving the source's full result and state. On all declines
    defer to E.4AE one-step ζ, E.4AD, and the original source checker. -/
def psKernelC0CertifiedWorkWhnfBetaOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0SourceExactWhnfOutput fuel work expr) :=
  match h : psKernelC0BetaSortWhnfWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr with
  | none => psKernelC0CertifiedWorkWhnfZetaOwned fuel work expr
  | some result =>
      .ok ⟨(result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val),
        psKernelC0BetaSortWhnf_certified
          fuel work expr result h⟩
