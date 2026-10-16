import Ps.KernelCore.Architecture.QualifiedBetaWhnf

/-!
Phase E.4AH: a single recursively evaluated, source-refined beta/zeta
WHNF core, rather than one optimized wrapper per terminal reduction.

Pinned upstream Lean 4.35:
  src/kernel/type_checker.cpp::whnf_core / ::whnf
Pinned C0 source:
  Checker/Reduction/WhnfCore.lean::psKernelWhnfCoreWithFuelRanges

The independent core uses decreasing exact source fuel and records the
source recursion-depth and cache state on EACH completed reduction.
It supports terminal head forms, metadata, short lets, and beta across
whole function/application spines (including multi-binder and
intermediate beta/zeta terms). It may use the *source substitution and
cache insertion primitives*, not the original WHNF evaluator.

The only accepting public path requires the full result of core
evaluation to be a known stable WHNF terminal and the exact result and
whole-state source refinement theorem. Unsupported forms, long-let
optimized frames, cached cores, source exhaustion and context-dependent
redexes decline to the prior authoritative checker.
-/

/-- Insert only the source core cache entry, preserving all other state.
    Unlike public WHNF this MUST NOT touch the public WHNF cache. -/
def psKernelC0RecursiveWhnfCoreFinish
    (original : PsKernelExpr)
    (value : PsKernelExpr)
    (state : PsKernelCheckerState) : PsKernelCheckerState :=
  psKernelCheckerStateWithWhnfCore state
    (psKernelExprMapInsert state.whnfCore original value)

/-- A real, decreasing-fuel, multi-step independent core evaluator.
    Each recursive call runs with the *same* fuel and entered context as
    the corresponding source child, including exact state threading.
    Only successful fully qualified subtrees return Some. -/
def psKernelC0RecursiveBetaZetaCoreWithFuel :
    Nat → PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → Option (PsKernelExpr × PsKernelCheckerState)
  | 0, _, _, _ => none
  | Nat.succ remaining, context, state, expr =>
      match psKernelCheckerContextEnterRecDepth context with
      | .error _ => none
      | .ok entered =>
          match expr with
          | .bvar _ => some (expr, state)
          | .sort _ => some (expr, state)
          | .mvar _ => some (expr, state)
          | .forallE _ _ _ _ => some (expr, state)
          | .const _ _ => some (expr, state)
          | .lam _ _ _ _ => some (expr, state)
          | .lit _ => some (expr, state)
          | .mdata _ body =>
              psKernelC0RecursiveBetaZetaCoreWithFuel
                remaining entered state body
          | .letE _ _ value body _ =>
              if !psKernelSemanticCacheEligible expr then none
              else if psKernelC0HasLetPrefix 12 expr then none
              else
                match psKernelExprMapGet state.whnfCore expr with
                | some _ => none
                | none =>
                    match psKernelC0RecursiveBetaZetaCoreWithFuel remaining
                        entered state (psKernelExprInstantiate1 body value) with
                    | none => none
                    | some (reduced, nextState) =>
                        some (reduced,
                          psKernelC0RecursiveWhnfCoreFinish expr
                            reduced nextState)
          | .app _ _ =>
              if !psKernelSemanticCacheEligible expr then none
              else match psKernelExprMapGet state.whnfCore expr with
              | some _ => none
              | none =>
                  let fn0 := psKernelExprGetAppFn expr
                  match psKernelC0RecursiveBetaZetaCoreWithFuel remaining
                      entered state fn0 with
                  | none => none
                  | some (fn, fnState) =>
                      match fn with
                      | .lam _ _ _ _ =>
                          match psKernelC0BetaSpinePlan
                              fn (psKernelExprGetAppArgs expr) with
                          | none => none
                          | some plan =>
                              match psKernelC0RecursiveBetaZetaCoreWithFuel
                                  remaining entered fnState
                                  (psKernelC0BetaSpineApply plan) with
                              | none => none
                              | some (reduced, nextState) =>
                                  some (reduced,
                                    psKernelC0RecursiveWhnfCoreFinish
                                      expr reduced nextState)
                      | _ => none
          | _ => none

/-- Full source-core state/result refinement across arbitrary numbers of
    independently executed beta/zeta reductions and any source callbacks.
    Only successful trees qualify; declines never decide the source error. -/
theorem psKernelC0RecursiveBetaZetaCore_source
    (fuel : Nat)
    (publicWhnf :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Except String (PsKernelExpr × PsKernelCheckerState))
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0RecursiveBetaZetaCoreWithFuel
      fuel context state expr = some result) :
    psKernelWhnfCoreWithFuelRanges fuel []
      publicWhnf reduceRecursor context state expr false false =
        .ok result := by
  induction fuel generalizing context state expr result with
  | zero => simp [psKernelC0RecursiveBetaZetaCoreWithFuel] at h
  | succ remaining ih =>
      cases depth : psKernelCheckerContextEnterRecDepth context with
      | error reason =>
          simp [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] at h
      | ok entered =>
          cases expr with
          | bvar index =>
              have hr : result = (.bvar index, state) := by
                have heq : some ((.bvar index : PsKernelExpr), state) =
                    some result := by
                  simpa [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] using h
                exact (Option.some.inj heq).symm
              rw [hr]
              simp [psKernelWhnfCoreWithFuelRanges, depth]
          | sort level =>
              have hr : result = (.sort level, state) := by
                have heq : some ((.sort level : PsKernelExpr), state) =
                    some result := by
                  simpa [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] using h
                exact (Option.some.inj heq).symm
              rw [hr]
              simp [psKernelWhnfCoreWithFuelRanges, depth]
          | mvar name =>
              have hr : result = (.mvar name, state) := by
                have heq : some ((.mvar name : PsKernelExpr), state) =
                    some result := by
                  simpa [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] using h
                exact (Option.some.inj heq).symm
              rw [hr]
              simp [psKernelWhnfCoreWithFuelRanges, depth]
          | forallE name ty body binder =>
              have hr : result = (.forallE name ty body binder, state) := by
                have heq : some ((.forallE name ty body binder : PsKernelExpr),
                    state) = some result := by
                  simpa [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] using h
                exact (Option.some.inj heq).symm
              rw [hr]
              simp [psKernelWhnfCoreWithFuelRanges, depth]
          | const name levels =>
              have hr : result = (.const name levels, state) := by
                have heq : some ((.const name levels : PsKernelExpr), state) =
                    some result := by
                  simpa [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] using h
                exact (Option.some.inj heq).symm
              rw [hr]
              simp [psKernelWhnfCoreWithFuelRanges, depth]
          | lam name ty body binder =>
              have hr : result = (.lam name ty body binder, state) := by
                have heq : some ((.lam name ty body binder : PsKernelExpr),
                    state) = some result := by
                  simpa [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] using h
                exact (Option.some.inj heq).symm
              rw [hr]
              simp [psKernelWhnfCoreWithFuelRanges, depth]
          | lit literal =>
              have hr : result = (.lit literal, state) := by
                have heq : some ((.lit literal : PsKernelExpr), state) =
                    some result := by
                  simpa [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] using h
                exact (Option.some.inj heq).symm
              rw [hr]
              simp [psKernelWhnfCoreWithFuelRanges, depth]
          | mdata data body =>
              have hchild :
                  psKernelC0RecursiveBetaZetaCoreWithFuel
                    remaining entered state body = some result := by
                simpa only [psKernelC0RecursiveBetaZetaCoreWithFuel,
                  depth] using h
              rw [psKernelWhnfCoreWithFuelRanges]
              simpa only [depth] using
                (ih entered state body result hchild)
          | letE name ty value body nondep =>
              let term : PsKernelExpr := .letE name ty value body nondep
              have eligible : psKernelSemanticCacheEligible term = true := by
                by_cases he : psKernelSemanticCacheEligible term = true
                · exact he
                · simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                    depth, he, term] at h
              by_cases hlong : psKernelC0HasLetPrefix 12 term = true
              · simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                  eligible, depth, hlong, term] at h
              · cases cache : psKernelExprMapGet state.whnfCore term with
                | some old =>
                    simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                      eligible, depth, hlong, cache, term] at h
                | none =>
                    let opened := psKernelExprInstantiate1 body value
                    cases childCheck : psKernelC0RecursiveBetaZetaCoreWithFuel
                        remaining entered state opened with
                    | none =>
                        simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                          eligible, depth, hlong, cache, opened, childCheck, term] at h
                    | some childResult =>
                        let nextState :=
                          psKernelC0RecursiveWhnfCoreFinish
                            term childResult.fst childResult.snd
                        have hr : result = (childResult.fst, nextState) := by
                          have hx : some (childResult.fst, nextState) =
                              some result := by
                            simpa [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              eligible, depth, hlong, cache, opened, childCheck,
                              nextState, term] using h
                          exact (Option.some.inj hx).symm
                        have sourceChild :=
                          ih entered state opened childResult childCheck
                        rw [hr]
                        rw [psKernelWhnfCoreWithFuelRanges]
                        simp [eligible, depth, hlong, cache, sourceChild,
                          psKernelWhnfCoreFinishWithKnownHash,
                          psKernelExprMapInsert, term, opened,
                          psKernelC0RecursiveWhnfCoreFinish, nextState]
          | app fn arg =>
              let term : PsKernelExpr := .app fn arg
              have eligible : psKernelSemanticCacheEligible term = true := by
                by_cases he : psKernelSemanticCacheEligible term = true
                · exact he
                · simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                    depth, he, term] at h
              cases cache : psKernelExprMapGet state.whnfCore term with
              | some old =>
                  simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                    eligible, depth, cache, term] at h
              | none =>
                  let fn0 := psKernelExprGetAppFn term
                  cases fnCheck : psKernelC0RecursiveBetaZetaCoreWithFuel
                      remaining entered state fn0 with
                  | none =>
                      simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                        eligible, depth, cache, fn0, fnCheck, term] at h
                  | some fnResult =>
                      cases fnResult with
                      | mk fnValue fnState =>
                          cases fnValue with
                          | lam name ty body binder =>
                              let fnHead : PsKernelExpr := .lam name ty body binder
                              let args := psKernelExprGetAppArgs term
                              cases plan :
                                  psKernelC0BetaSpinePlan fnHead args with
                              | none =>
                                  simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                                    eligible, depth, cache, fn0, fnCheck,
                                    plan, fnHead, args, term] at h
                              | some selection =>
                                  let opened := psKernelC0BetaSpineApply selection
                                  cases childCheck :
                                      psKernelC0RecursiveBetaZetaCoreWithFuel
                                        remaining entered fnState opened with
                                  | none =>
                                      simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                                        eligible, depth, cache, fn0, fnCheck,
                                        plan, opened, childCheck,
                                        fnHead, args, term] at h
                                  | some childResult =>
                                      let nextState :=
                                        psKernelC0RecursiveWhnfCoreFinish
                                          term childResult.fst childResult.snd
                                      have hr : result =
                                          (childResult.fst, nextState) := by
                                        have hx : some
                                            (childResult.fst, nextState) =
                                              some result := by
                                          simpa [psKernelC0RecursiveBetaZetaCoreWithFuel,
                                            eligible, depth, cache, fn0, fnCheck,
                                            plan, opened, childCheck,
                                            fnHead, args, term, nextState] using h
                                        exact (Option.some.inj hx).symm
                                      have sourceFn :=
                                        ih entered state fn0
                                          (fnHead, fnState) fnCheck
                                      have sourceBody :=
                                        ih entered fnState opened
                                          childResult childCheck
                                      rw [hr]
                                      rw [psKernelWhnfCoreWithFuelRanges]
                                      simp [eligible, depth, cache, sourceFn, plan,
                                        sourceBody, fn0, fnHead, args,
                                        opened, term,
                                        psKernelWhnfCoreFinish,
                                        psKernelWhnfCoreFinishWithKnownHash,
                                        psKernelExprMapInsert,
                                        psKernelC0RecursiveWhnfCoreFinish,
                                        nextState]
                          | bvar _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              eligible, depth, cache, fn0, fnCheck, term] at h
                          | fvar _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | mvar _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | sort _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | const _ _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | app _ _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | forallE _ _ _ _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | letE _ _ _ _ _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | lit _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | mdata _ _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
                          | proj _ _ _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel,
                              depth, cache, fn0, fnCheck, term] at h
          | fvar _ => simp [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] at h
          | proj _ _ _ =>
              simp [psKernelC0RecursiveBetaZetaCoreWithFuel, depth] at h

/-- The public recursive normalizer is selected only for root applications
    and lets: their source pipeline executes a core reduction then a
    cache-writing public post-core step. A stable terminal rules out
    unresolved delta, Nat and recursor reductions. -/
def psKernelC0RecursiveBetaZetaWhnfWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ remaining =>
      match expr with
      | .app _ _ | .letE _ _ _ _ _ =>
          if !psKernelSemanticCacheEligible expr then none
          else match psKernelExprMapGet state.whnf expr with
          | some _ => none
          | none =>
              match psKernelC0RecursiveBetaZetaCoreWithFuel
                  remaining context state expr with
              | some (core, coreState) =>
                  if psKernelC0StableWhnfTerminal core then
                    some (core, psKernelCheckerStateWithWhnf coreState
                      (psKernelExprMapInsert coreState.whnf expr core))
                  else none
              | none => none
      | _ => none

/-- Exact public source WHNF, including the full *intermediate* core cache
    lineage and final public cache. Source WHNF and its callback never
    execute on an independently successful branch. -/
theorem psKernelC0RecursiveBetaZetaWhnf_source
    (fuel : Nat)
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0RecursiveBetaZetaWhnfWithFuel
      fuel context state expr = some result) :
    psKernelWhnfWithFuel fuel reduceRecursor context state expr =
      .ok result := by
  cases fuel with
  | zero => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
  | succ remaining =>
      cases expr with
      | app fn arg =>
          let term : PsKernelExpr := .app fn arg
          have eligible : psKernelSemanticCacheEligible term = true := by
            by_cases he : psKernelSemanticCacheEligible term = true
            · exact he
            · simp [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                he, term] at h
          cases cache : psKernelExprMapGet state.whnf term with
          | some old =>
              simp [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                eligible, cache, term] at h
          | none =>
              cases coreCheck : psKernelC0RecursiveBetaZetaCoreWithFuel
                  remaining context state term with
              | none =>
                  simp [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                    eligible, cache, coreCheck, term] at h
              | some coreResult =>
                  cases coreResult with
                  | mk value coreState =>
                      by_cases stable :
                          psKernelC0StableWhnfTerminal value = true
                      · have hr : result = (value,
                            psKernelCheckerStateWithWhnf coreState
                              (psKernelExprMapInsert coreState.whnf term value)) := by
                          have hx : some (value,
                              psKernelCheckerStateWithWhnf coreState
                                (psKernelExprMapInsert coreState.whnf term value)) =
                                  some result := by
                            simpa [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                              eligible, cache, coreCheck, stable, term] using h
                          exact (Option.some.inj hx).symm
                        have sourceCore :=
                          psKernelC0RecursiveBetaZetaCore_source remaining
                            (fun ctx st ex => psKernelWhnfWithFuel
                              remaining reduceRecursor ctx st ex)
                            reduceRecursor context state term
                            (value, coreState) coreCheck
                        have sourcePost :=
                          psKernelC0StableWhnfTerminal_post
                            (fun ctx st ex => psKernelWhnfWithFuel
                              remaining reduceRecursor ctx st ex)
                            context coreState term value stable
                        rw [hr]
                        change
                          (match (if psKernelSemanticCacheEligible term then
                                psKernelExprMapGet state.whnf term
                              else Option.none) with
                          | some cached => Except.ok (cached, state)
                          | none =>
                              match psKernelWhnfCoreWithFuel remaining
                                  (fun ctx st ex =>
                                    psKernelWhnfWithFuel remaining
                                      reduceRecursor ctx st ex)
                                  reduceRecursor context state term
                                  false false with
                              | .error error => Except.error error
                              | .ok coreResult =>
                                  psKernelWhnfAfterCore
                                    (fun ctx st ex =>
                                      psKernelWhnfWithFuel remaining
                                        reduceRecursor ctx st ex)
                                    context coreResult.snd term
                                    coreResult.fst) =
                            Except.ok (value,
                              psKernelCheckerStateWithWhnf coreState
                                (psKernelExprMapInsert coreState.whnf term value))
                        simp only [eligible, ite_true, cache, psKernelWhnfCoreWithFuel,
                          sourceCore, sourcePost]
                        rfl
                      · simp [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                          eligible, cache, coreCheck, stable, term] at h
      | letE name ty value body nondep =>
          let term : PsKernelExpr := .letE name ty value body nondep
          have eligible : psKernelSemanticCacheEligible term = true := by
            by_cases he : psKernelSemanticCacheEligible term = true
            · exact he
            · simp [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                he, term] at h
          cases cache : psKernelExprMapGet state.whnf term with
          | some old =>
              simp [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                eligible, cache, term] at h
          | none =>
              cases coreCheck : psKernelC0RecursiveBetaZetaCoreWithFuel
                  remaining context state term with
              | none =>
                  simp [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                    eligible, cache, coreCheck, term] at h
              | some coreResult =>
                  cases coreResult with
                  | mk reduced coreState =>
                      by_cases stable :
                          psKernelC0StableWhnfTerminal reduced = true
                      · have hr : result = (reduced,
                            psKernelCheckerStateWithWhnf coreState
                              (psKernelExprMapInsert coreState.whnf term reduced)) := by
                          have hx : some (reduced,
                              psKernelCheckerStateWithWhnf coreState
                                (psKernelExprMapInsert coreState.whnf term reduced)) =
                                  some result := by
                            simpa [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                              eligible, cache, coreCheck, stable, term] using h
                          exact (Option.some.inj hx).symm
                        have sourceCore :=
                          psKernelC0RecursiveBetaZetaCore_source remaining
                            (fun ctx st ex => psKernelWhnfWithFuel
                              remaining reduceRecursor ctx st ex)
                            reduceRecursor context state term
                            (reduced, coreState) coreCheck
                        have sourcePost :=
                          psKernelC0StableWhnfTerminal_post
                            (fun ctx st ex => psKernelWhnfWithFuel
                              remaining reduceRecursor ctx st ex)
                            context coreState term reduced stable
                        rw [hr]
                        change
                          (match (if psKernelSemanticCacheEligible term then
                                psKernelExprMapGet state.whnf term
                              else Option.none) with
                          | some cached => Except.ok (cached, state)
                          | none =>
                              match psKernelWhnfCoreWithFuel remaining
                                  (fun ctx st ex =>
                                    psKernelWhnfWithFuel remaining
                                      reduceRecursor ctx st ex)
                                  reduceRecursor context state term
                                  false false with
                              | .error error => Except.error error
                              | .ok coreResult =>
                                  psKernelWhnfAfterCore
                                    (fun ctx st ex =>
                                      psKernelWhnfWithFuel remaining
                                        reduceRecursor ctx st ex)
                                    context coreResult.snd term
                                    coreResult.fst) =
                            Except.ok (reduced,
                              psKernelCheckerStateWithWhnf coreState
                                (psKernelExprMapInsert coreState.whnf term reduced))
                        simp only [eligible, ite_true, cache, psKernelWhnfCoreWithFuel,
                          sourceCore, sourcePost]
                        rfl
                      · simp [psKernelC0RecursiveBetaZetaWhnfWithFuel,
                          eligible, cache, coreCheck, stable, term] at h
      | bvar _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | fvar _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | mvar _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | sort _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | const _ _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | lam _ _ _ _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | forallE _ _ _ _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | lit _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | mdata _ _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h
      | proj _ _ _ => simp [psKernelC0RecursiveBetaZetaWhnfWithFuel] at h

theorem psKernelC0RecursiveBetaZetaWhnf_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0RecursiveBetaZetaWhnfWithFuel fuel
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
    exact psKernelC0RecursiveBetaZetaWhnf_source fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr result h
  rcases result with ⟨value, nextState⟩
  unfold psKernelC0CertifiedWorkWhnf psKernelSessionWhnf
  simp only [source]
  rfl

/-- One recursive accepting route. Existing beta/zeta terminal fragments
    remain qualified fallback for declined resource/cache/syntax shapes.
    A successful branch cannot issue a proof verdict, only a receipt for
    the exact original public WHNF operation. -/
def psKernelC0CertifiedWorkWhnfRecursiveOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0SourceExactWhnfOutput fuel work expr) :=
  match h : psKernelC0RecursiveBetaZetaWhnfWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr with
  | none => psKernelC0CertifiedWorkWhnfBetaOwned fuel work expr
  | some result =>
      .ok ⟨(result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val),
        psKernelC0RecursiveBetaZetaWhnf_certified
          fuel work expr result h⟩
