import Ps.KernelCore.Architecture.QualifiedProjectionInference

/-!
Qualified recursive checked expression inference — native Lean 4.35.

One fuel-recursive, state-accounted accepting fragment now handles checked
application trees, transparent metadata and dependent Pi/lambda binders.
All successful results carry Lean-checked exact source-result and complete
checker-state refinement; unsupported conversion and other families retain
the independent original source checker as the authoritative fallback.
The earlier leaf-app implementation remains solely as a regression oracle.
-/

/-!
Phase E.4W — a checked application with independently typed children.

Lean 4.35 type_checker.cpp::infer_app checks a function's Pi type,
independently checks the argument and compares its inferred type with
the Pi domain before instantiating the codomain. This bounded fast path
performs BOTH child inference judgments through the previously proven
independent scalar/local/constant/metadata fragment. It only succeeds
when the function type is already a syntactic Pi and the argument type
is structurally equal to its domain. It never calls the source recursive
inference worker for these child judgments.

WHNF-dependent function types, DefEq-dependent argument conversions,
nested application heads and long checked-application hooks deliberately
decline and delegate to full source checking. A Lean theorem must establish
the exact complete source type and checker state before a result can reach
the audited provider. This is a bounded compositional refinement, not a
standalone soundness or consistency theorem.
-/

/-- Independently type the function and the argument of a short checked
    application. Success requires a syntactic dependent Pi and an exactly
    equal argument/domain type; no speculative result is an accepting
    verdict. An unsupported or invalid term returns none. -/
def psKernelC0CheckedAppLeafWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    Option (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ remaining =>
      if psKernelExprGetAppNumArgs (.app fn arg) >= 16 then none
      else
        match psKernelCheckerContextEnterRecDepth context with
        | .error _ => none
        | .ok entered =>
            match psKernelC0MetadataInferWithFuel
                remaining entered state fn false with
            | none => none
            | some (fnType, fnState) =>
                match fnType with
                | .forallE _ domain body _ =>
                    match psKernelC0MetadataInferWithFuel
                        remaining entered fnState arg false with
                    | none => none
                    | some (argType, argState) =>
                        if psKernelExprEq argType domain then
                          let result := psKernelExprInstantiate1 body arg
                          some (result,
                            psKernelCacheInferResult argState false
                              (.app fn arg) result)
                        else none
                | _ => none

/-- Every successful two-child independent evaluation produces EXACTLY
    the original fully checked application result AND source state for
    arbitrary source contexts, fuel, caches and WHNF/DefEq callbacks.
    The source recursive child checks are eliminated only on success;
    all rejected/declined cases retain the historical checker. -/
theorem psKernelC0CheckedAppLeaf_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0CheckedAppLeafWithFuel
      fuel context state fn arg = some result) :
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.app fn arg) false = .ok result := by
  cases fuel with
  | zero =>
      simp [psKernelC0CheckedAppLeafWithFuel] at h
  | succ remaining =>
      by_cases hlong : psKernelExprGetAppNumArgs (.app fn arg) >= 16
      · simp [psKernelC0CheckedAppLeafWithFuel, hlong] at h
      · cases depth : psKernelCheckerContextEnterRecDepth context with
        | error reason =>
            simp [psKernelC0CheckedAppLeafWithFuel,
              hlong, depth] at h
        | ok entered =>
            cases head : psKernelC0MetadataInferWithFuel
                remaining entered state fn false with
            | none =>
                simp [psKernelC0CheckedAppLeafWithFuel,
                  hlong, depth, head] at h
            | some headResult =>
                cases headResult with
                | mk fnType fnState =>
                    cases fnType with
                    | forallE name domain body binderInfo =>
                        cases argument : psKernelC0MetadataInferWithFuel
                            remaining entered fnState arg false with
                        | none =>
                            simp [psKernelC0CheckedAppLeafWithFuel,
                              hlong, depth, head, argument] at h
                        | some argumentResult =>
                            cases argumentResult with
                            | mk argType argState =>
                                by_cases same : psKernelExprEq argType domain = true
                                · let codomain := psKernelExprInstantiate1 body arg
                                  let nextState := psKernelCacheInferResult
                                    argState false (.app fn arg) codomain
                                  have hr : result = (codomain, nextState) := by
                                    have hx : some (codomain, nextState) =
                                        some result := by
                                      simpa [psKernelC0CheckedAppLeafWithFuel,
                                        hlong, depth, head, argument, same,
                                        codomain, nextState] using h
                                    exact (Option.some.inj hx).symm
                                  have checkedFn :
                                      psKernelInferCoreWithFuelUsingSourceFrames
                                        remaining onCheckedApp [] []
                                        whnf defeq entered state fn false =
                                        .ok (.forallE name domain body binderInfo, fnState) :=
                                    psKernelC0MetadataInfer_source remaining
                                      onCheckedApp whnf defeq entered state fn false
                                      (.forallE name domain body binderInfo, fnState) head
                                  have checkedArg :
                                      psKernelInferCoreWithFuelUsingSourceFrames
                                        remaining onCheckedApp [] []
                                        whnf defeq entered fnState arg false =
                                        .ok (argType, argState) :=
                                    psKernelC0MetadataInfer_source remaining
                                      onCheckedApp whnf defeq entered fnState arg false
                                      (argType, argState) argument
                                  rw [hr]
                                  change
                                    psKernelInferCoreWithFuelUsingSourceFrames
                                      (Nat.succ remaining) onCheckedApp [] []
                                      whnf defeq context state (.app fn arg) false =
                                        .ok (codomain, nextState)
                                  cases onCheckedApp with
                                  | none =>
                                      simp [psKernelInferCoreWithFuelUsingSourceFrames,
                                        psKernelInferCacheEligible,
                                        psKernelInferAppHead, psKernelEnsureForallWith,
                                        hlong, depth, checkedFn, checkedArg, same,
                                        codomain, nextState]
                                  | some callback =>
                                      simp [psKernelInferCoreWithFuelUsingSourceFrames,
                                        psKernelInferCacheEligible,
                                        psKernelInferAppHead, psKernelEnsureForallWith,
                                        hlong, depth, checkedFn, checkedArg, same,
                                        codomain, nextState]
                                · simp [psKernelC0CheckedAppLeafWithFuel,
                                    hlong, depth, head, argument, same] at h
                    | bvar _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | fvar _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | mvar _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | sort _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | const _ _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | app _ _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | lam _ _ _ _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | letE _ _ _ _ _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | lit _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | mdata _ _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h
                    | proj _ _ _ => simp [psKernelC0CheckedAppLeafWithFuel, hlong, depth, head] at h

theorem psKernelC0CheckedAppLeaf_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0CheckedAppLeafWithFuel fuel
      context state fn arg = some result) :
    psKernelCheckerCheck fuel context state (.app fn arg) =
      .ok result := by
  -- Unlike nested checked subterms, short ROOT applications use the
  -- historical callback-free infer worker in psKernelCheckWithFuel.
  -- This optimization deliberately declines the >=16-argument route.
  have hshort : ¬ psKernelExprGetAppNumArgs (.app fn arg) >= 16 := by
    cases fuel with
    | zero => simp [psKernelC0CheckedAppLeafWithFuel] at h
    | succ remaining =>
        intro hlong
        simp [psKernelC0CheckedAppLeafWithFuel, hlong] at h
  have exactSource := psKernelC0CheckedAppLeaf_source fuel
    none
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel)
    context state fn arg result h
  -- Reduce only the public checker entry point. In the short case its
  -- recursive worker is definitionally the callback-free source route.
  change
    (if psKernelExprGetAppNumArgs (.app fn arg) >= 16 then
      psKernelC0CheckAppRecursiveResummarized fuel
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)
        context state (.app fn arg)
    else
      psKernelInferCoreWithFuel fuel
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)
        context state (.app fn arg) false) = .ok result
  simp only [if_neg hshort]
  exact exactSource

/-!
Phase E.4X — independently execute a complete bounded APPLICATION TREE,
not just a top-level pair of already qualified child heads. The recursion
is on the original source fuel; both the function subtree and the argument
subtree are recursively typed with the same source-exact checked evaluator.
Any base head delegates only to the already independently qualified
scalar/local/constant/metadata fragment, NEVER to the old recursive
inference worker on a successful independent result. Non-syntactic Pi,
DefEq-dependent conversion, a long application spine and all insufficient
resource cases decline and preserve authoritative source checking.
-/

/-- Independent bounded recursive checked inference over application trees,
    with independently qualified metadata/scalar/local/constant terminals.
    Neither recursive child calls the original C0 inference worker. -/
def psKernelC0RecursiveCheckedWithFuel :
    Nat → PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → Option (PsKernelExpr × PsKernelCheckerState)
  | 0, _, _, _ => none
  | Nat.succ remaining, context, state, expr =>
      match expr with
      | .app fn arg =>
          if psKernelExprGetAppNumArgs (.app fn arg) >= 16 then none
          else
            match psKernelCheckerContextEnterRecDepth context with
            | .error _ => none
            | .ok entered =>
                match psKernelC0RecursiveCheckedWithFuel
                    remaining entered state fn with
                | none => none
                | some (fnType, fnState) =>
                    match fnType with
                    | .forallE _ domain body _ =>
                        match psKernelC0RecursiveCheckedWithFuel
                            remaining entered fnState arg with
                        | none => none
                        | some (argType, argState) =>
                            if psKernelExprEq argType domain then
                              let codomain := psKernelExprInstantiate1 body arg
                              some (codomain,
                                psKernelCacheInferResult argState false
                                  (.app fn arg) codomain)
                            else none
                    | _ => none
      | .lam name domain body binderInfo =>
          let term : PsKernelExpr := .lam name domain body binderInfo
          -- The original checked-app hook may precompute immutable
          -- summaries of long binder spines. Keep that source route
          -- authoritative, including its exact state/resource effects.
          if psKernelC0HasBinderPrefix 12 true term then none
          else
            match psKernelCheckerContextEnterRecDepth context with
            | .error _ => none
            | .ok entered =>
                match psKernelC0RecursiveCheckedWithFuel
                    remaining entered state domain with
                | some (.sort _, domainState) =>
                    let freshResult := psKernelCheckerStateFreshName
                      domainState name
                    let fresh := freshResult.fst
                    let state1 := freshResult.snd
                    let childLocal := psKernelLocalContextAddLocal
                      entered.localContext fresh name domain binderInfo
                    let child := psKernelCheckerContextWithLocalContext
                      entered childLocal
                    let openedBody := psKernelExprInstantiate1 body
                      (.fvar fresh)
                    match psKernelC0RecursiveCheckedWithFuel
                        remaining child state1 openedBody with
                    | some (bodyType, bodyState) =>
                        let reducedBody := psKernelExprCheapBetaReduce bodyType
                        let closedBody := psKernelExprAbstractFVars
                          reducedBody [fresh]
                        let ty : PsKernelExpr :=
                          .forallE name domain closedBody binderInfo
                        some (ty, psKernelCacheInferResult
                          (psKernelCheckerStateExitLocalScope state1 bodyState)
                          false term ty)
                    | none => none
                | _ => none
      | .forallE name domain body binderInfo =>
          let term : PsKernelExpr := .forallE name domain body binderInfo
          -- Pinned C0 source optimizes binder spines of length >=12
          -- when a checked-app hook is installed. Defer that family
          -- rather than guessing its source frame provenance.
          if psKernelC0HasBinderPrefix 12 false term then none
          else
            match psKernelCheckerContextEnterRecDepth context with
            | .error _ => none
            | .ok entered =>
                match psKernelC0RecursiveCheckedWithFuel
                    remaining entered state domain with
                | some (.sort domainLevel, domainState) =>
                    let freshResult := psKernelCheckerStateFreshName
                      domainState name
                    let fresh := freshResult.fst
                    let state1 := freshResult.snd
                    let childLocal := psKernelLocalContextAddLocal
                      entered.localContext fresh name domain binderInfo
                    let child := psKernelCheckerContextWithLocalContext
                      entered childLocal
                    let openedBody := psKernelExprInstantiate1 body
                      (.fvar fresh)
                    match psKernelC0RecursiveCheckedWithFuel
                        remaining child state1 openedBody with
                    | some (.sort bodyLevel, bodyState) =>
                        let ty : PsKernelExpr :=
                          .sort (psKernelLevelMkIMax domainLevel bodyLevel)
                        some (ty, psKernelCacheInferResult
                          (psKernelCheckerStateExitLocalScope state1 bodyState)
                          false term ty)
                    | _ => none
                | _ => none
      | .mdata md body =>
          let term : PsKernelExpr := .mdata md body
          match (if psKernelInferCacheEligible false term then
             psKernelExprMapGet state.checkedInfer term else Option.none) with
          | some ty =>
              match psKernelCheckerContextEnterRecDepth context with
              | .error _ => none
              | .ok _ => some (ty, state)
          | none =>
              match psKernelCheckerContextEnterRecDepth context with
              | .error _ => none
              | .ok entered =>
                  match psKernelC0RecursiveCheckedWithFuel
                      remaining entered state body with
                  | none => none
                  | some (ty, checkedState) =>
                      some (ty, psKernelCacheInferResult checkedState false
                        term ty)
      | other =>
          psKernelC0MetadataInferWithFuel
            (Nat.succ remaining) context state other false

/-- Full all-context source-result AND source-state refinement over
    arbitrarily nested independently executed short checked applications.
    This uses strong fuel induction for BOTH recursive child judgments.
    Successful base judgments use the previously proved metadata fragment;
    WHNF and DefEq remain source callbacks, not independent observations. -/
theorem psKernelC0RecursiveChecked_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0RecursiveCheckedWithFuel
      fuel context state expr = some result) :
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state expr false = .ok result := by
  induction fuel generalizing context state expr result with
  | zero =>
      simp [psKernelC0RecursiveCheckedWithFuel] at h
  | succ remaining ih =>
      cases expr with
      | app fn arg =>
          by_cases hlong : psKernelExprGetAppNumArgs (.app fn arg) >= 16
          · simp [psKernelC0RecursiveCheckedWithFuel, hlong] at h
          · cases depth : psKernelCheckerContextEnterRecDepth context with
            | error reason =>
                simp [psKernelC0RecursiveCheckedWithFuel,
                  hlong, depth] at h
            | ok entered =>
                cases head : psKernelC0RecursiveCheckedWithFuel
                    remaining entered state fn with
                | none =>
                    simp [psKernelC0RecursiveCheckedWithFuel,
                      hlong, depth, head] at h
                | some headResult =>
                    cases headResult with
                    | mk fnType fnState =>
                        cases fnType with
                        | forallE name domain body binderInfo =>
                            cases argument : psKernelC0RecursiveCheckedWithFuel
                                remaining entered fnState arg with
                            | none =>
                                simp [psKernelC0RecursiveCheckedWithFuel,
                                  hlong, depth, head, argument] at h
                            | some argumentResult =>
                                cases argumentResult with
                                | mk argType argState =>
                                    by_cases same :
                                        psKernelExprEq argType domain = true
                                    · let codomain := psKernelExprInstantiate1 body arg
                                      let nextState := psKernelCacheInferResult
                                        argState false (.app fn arg) codomain
                                      have hr : result = (codomain, nextState) := by
                                        have hx : some (codomain, nextState) =
                                            some result := by
                                          simpa [psKernelC0RecursiveCheckedWithFuel,
                                            hlong, depth, head, argument, same,
                                            codomain, nextState] using h
                                        exact (Option.some.inj hx).symm
                                      have checkedFn :
                                          psKernelInferCoreWithFuelUsingSourceFrames
                                            remaining onCheckedApp [] []
                                            whnf defeq entered state fn false =
                                            .ok (.forallE name domain body binderInfo,
                                              fnState) := by
                                        change psKernelInferCoreWithFuelUsing remaining
                                          onCheckedApp whnf defeq entered state fn false =
                                            .ok (.forallE name domain body binderInfo,
                                              fnState)
                                        exact ih entered state fn
                                          (.forallE name domain body binderInfo,
                                            fnState) head
                                      have checkedArg :
                                          psKernelInferCoreWithFuelUsingSourceFrames
                                            remaining onCheckedApp [] []
                                            whnf defeq entered fnState arg false =
                                            .ok (argType, argState) := by
                                        change psKernelInferCoreWithFuelUsing remaining
                                          onCheckedApp whnf defeq entered fnState arg false =
                                            .ok (argType, argState)
                                        exact ih entered fnState arg
                                          (argType, argState) argument
                                      rw [hr]
                                      change
                                        psKernelInferCoreWithFuelUsingSourceFrames
                                          (Nat.succ remaining) onCheckedApp [] []
                                          whnf defeq context state (.app fn arg) false =
                                            .ok (codomain, nextState)
                                      cases onCheckedApp with
                                      | none =>
                                          simp [psKernelInferCoreWithFuelUsingSourceFrames,
                                            psKernelInferCacheEligible,
                                            psKernelInferAppHead, psKernelEnsureForallWith,
                                            hlong, depth, checkedFn, checkedArg, same,
                                            codomain, nextState]
                                      | some callback =>
                                          simp [psKernelInferCoreWithFuelUsingSourceFrames,
                                            psKernelInferCacheEligible,
                                            psKernelInferAppHead, psKernelEnsureForallWith,
                                            hlong, depth, checkedFn, checkedArg, same,
                                            codomain, nextState]
                                    · simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, head, argument, same] at h
                        | bvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | fvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | mvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | sort _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | const _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | app _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | lam _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | letE _ _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | lit _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | mdata _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
                        | proj _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, head] at h
      | sort u =>
          exact psKernelC0MetadataInfer_source (Nat.succ remaining)
            onCheckedApp whnf defeq context state (.sort u) false result
            (by simpa only [psKernelC0RecursiveCheckedWithFuel] using h)
      | lit v =>
          exact psKernelC0MetadataInfer_source (Nat.succ remaining)
            onCheckedApp whnf defeq context state (.lit v) false result
            (by simpa only [psKernelC0RecursiveCheckedWithFuel] using h)
      | fvar name =>
          exact psKernelC0MetadataInfer_source (Nat.succ remaining)
            onCheckedApp whnf defeq context state (.fvar name) false result
            (by simpa only [psKernelC0RecursiveCheckedWithFuel] using h)
      | const name levels =>
          exact psKernelC0MetadataInfer_source (Nat.succ remaining)
            onCheckedApp whnf defeq context state (.const name levels) false result
            (by simpa only [psKernelC0RecursiveCheckedWithFuel] using h)
      | lam name domain body binderInfo =>
          let term : PsKernelExpr := .lam name domain body binderInfo
          by_cases hlong : psKernelC0HasBinderPrefix 12 true term = true
          · simp [psKernelC0RecursiveCheckedWithFuel,
              hlong, term] at h
          · cases depth : psKernelCheckerContextEnterRecDepth context with
            | error reason =>
                simp [psKernelC0RecursiveCheckedWithFuel,
                  hlong, depth, term] at h
            | ok entered =>
                cases hd : psKernelC0RecursiveCheckedWithFuel
                    remaining entered state domain with
                | none =>
                    simp [psKernelC0RecursiveCheckedWithFuel,
                      hlong, depth, hd, term] at h
                | some domainResult =>
                    cases domainResult with
                    | mk domainType domainState =>
                        cases domainType with
                        | sort domainLevel =>
                            let freshResult :=
                              psKernelCheckerStateFreshName domainState name
                            let fresh := freshResult.fst
                            let state1 := freshResult.snd
                            let childLocal := psKernelLocalContextAddLocal
                              entered.localContext fresh name domain binderInfo
                            let child := psKernelCheckerContextWithLocalContext
                              entered childLocal
                            let openedBody := psKernelExprInstantiate1 body
                              (.fvar fresh)
                            cases hb : psKernelC0RecursiveCheckedWithFuel
                                remaining child state1 openedBody with
                            | none =>
                                simp [psKernelC0RecursiveCheckedWithFuel,
                                  hlong, depth, hd, hb, term, child,
                                  openedBody, freshResult, fresh, state1,
                                  childLocal] at h
                            | some bodyResult =>
                                cases bodyResult with
                                | mk bodyType bodyState =>
                                    let reducedBody :=
                                      psKernelExprCheapBetaReduce bodyType
                                    let closedBody :=
                                      psKernelExprAbstractFVars reducedBody [fresh]
                                    let ty : PsKernelExpr :=
                                      .forallE name domain closedBody binderInfo
                                    let nextState :=
                                      psKernelCacheInferResult
                                          (psKernelCheckerStateExitLocalScope
                                            state1 bodyState) false term ty
                                    have hr : result = (ty, nextState) := by
                                      have hx : some (ty, nextState) =
                                          some result := by
                                        simpa [psKernelC0RecursiveCheckedWithFuel,
                                          hlong, depth, hd, hb, term, child,
                                          openedBody, freshResult, fresh,
                                          state1, childLocal, reducedBody,
                                          closedBody, ty, nextState] using h
                                      exact (Option.some.inj hx).symm
                                    have sourceDomain :
                                        psKernelInferCoreWithFuelUsingSourceFrames
                                          remaining onCheckedApp [] []
                                          whnf defeq entered state domain false =
                                          .ok (.sort domainLevel, domainState) := by
                                      change psKernelInferCoreWithFuelUsing
                                        remaining onCheckedApp whnf defeq
                                        entered state domain false =
                                          .ok (.sort domainLevel, domainState)
                                      exact ih entered state domain
                                        (.sort domainLevel, domainState) hd
                                    have sourceBody :
                                        psKernelInferCoreWithFuelUsingSourceFrames
                                          remaining onCheckedApp [] []
                                          whnf defeq child state1 openedBody false =
                                          .ok (bodyType, bodyState) := by
                                      change psKernelInferCoreWithFuelUsing
                                        remaining onCheckedApp whnf defeq
                                        child state1 openedBody false =
                                          .ok (bodyType, bodyState)
                                      exact ih child state1 openedBody
                                        (bodyType, bodyState) hb
                                    rw [hr]
                                    change
                                      psKernelInferCoreWithFuelUsingSourceFrames
                                        (Nat.succ remaining) onCheckedApp [] []
                                        whnf defeq context state term false =
                                          .ok (ty, nextState)
                                    cases onCheckedApp with
                                    | none =>
                                        simpa [psKernelInferCoreWithFuelUsingSourceFrames,
                                          psKernelInferCacheEligible,
                                          psKernelInferCurrentBinderRanges,
                                          psKernelInferLambdaHead,
                                          psKernelEnsureSortWith,
                                          hlong, depth, sourceDomain,
                                          sourceBody, term, child,
                                          openedBody, freshResult, fresh,
                                          state1, childLocal, reducedBody,
                                          closedBody, ty, nextState]
                                    | some hook =>
                                        simpa [psKernelInferCoreWithFuelUsingSourceFrames,
                                          psKernelInferCacheEligible,
                                          psKernelInferCurrentBinderRanges,
                                          psKernelInferLambdaHead,
                                          psKernelEnsureSortWith,
                                          hlong, depth, sourceDomain,
                                          sourceBody, term, child,
                                          openedBody, freshResult, fresh,
                                          state1, childLocal, reducedBody,
                                          closedBody, ty, nextState]
                        | bvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | fvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | mvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | const _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | app _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | lam _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | forallE _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | letE _ _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | lit _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | mdata _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | proj _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
      | forallE name domain body binderInfo =>
          let term : PsKernelExpr := .forallE name domain body binderInfo
          by_cases hlong : psKernelC0HasBinderPrefix 12 false term = true
          · simp [psKernelC0RecursiveCheckedWithFuel,
              hlong, term] at h
          · cases depth : psKernelCheckerContextEnterRecDepth context with
            | error reason =>
                simp [psKernelC0RecursiveCheckedWithFuel,
                  hlong, depth, term] at h
            | ok entered =>
                cases hd : psKernelC0RecursiveCheckedWithFuel
                    remaining entered state domain with
                | none =>
                    simp [psKernelC0RecursiveCheckedWithFuel,
                      hlong, depth, hd, term] at h
                | some domainResult =>
                    cases domainResult with
                    | mk domainType domainState =>
                        cases domainType with
                        | sort domainLevel =>
                            let freshResult :=
                              psKernelCheckerStateFreshName domainState name
                            let fresh := freshResult.fst
                            let state1 := freshResult.snd
                            let childLocal := psKernelLocalContextAddLocal
                              entered.localContext fresh name domain binderInfo
                            let child := psKernelCheckerContextWithLocalContext
                              entered childLocal
                            let openedBody := psKernelExprInstantiate1 body
                              (.fvar fresh)
                            cases hb : psKernelC0RecursiveCheckedWithFuel
                                remaining child state1 openedBody with
                            | none =>
                                simp [psKernelC0RecursiveCheckedWithFuel,
                                  hlong, depth, hd, hb, term, child,
                                  openedBody, freshResult, fresh, state1,
                                  childLocal] at h
                            | some bodyResult =>
                                cases bodyResult with
                                | mk bodyType bodyState =>
                                    cases bodyType with
                                    | sort bodyLevel =>
                                        let ty : PsKernelExpr :=
                                          .sort (psKernelLevelMkIMax
                                            domainLevel bodyLevel)
                                        let nextState :=
                                          psKernelCacheInferResult
                                          (psKernelCheckerStateExitLocalScope
                                            state1 bodyState) false term ty
                                        have hr : result = (ty, nextState) := by
                                          have hx : some (ty, nextState) =
                                              some result := by
                                            simpa [psKernelC0RecursiveCheckedWithFuel,
                                              hlong, depth, hd, hb, term, child,
                                              openedBody, freshResult, fresh,
                                              state1, childLocal, ty,
                                              nextState] using h
                                          exact (Option.some.inj hx).symm
                                        have sourceDomain :
                                            psKernelInferCoreWithFuelUsingSourceFrames
                                              remaining onCheckedApp [] []
                                              whnf defeq entered state domain false =
                                              .ok (.sort domainLevel, domainState) := by
                                          change psKernelInferCoreWithFuelUsing
                                            remaining onCheckedApp whnf defeq
                                            entered state domain false =
                                              .ok (.sort domainLevel, domainState)
                                          exact ih entered state domain
                                            (.sort domainLevel, domainState) hd
                                        have sourceBody :
                                            psKernelInferCoreWithFuelUsingSourceFrames
                                              remaining onCheckedApp [] []
                                              whnf defeq child state1 openedBody false =
                                              .ok (.sort bodyLevel, bodyState) := by
                                          change psKernelInferCoreWithFuelUsing
                                            remaining onCheckedApp whnf defeq
                                            child state1 openedBody false =
                                              .ok (.sort bodyLevel, bodyState)
                                          exact ih child state1 openedBody
                                            (.sort bodyLevel, bodyState) hb
                                        rw [hr]
                                        change
                                          psKernelInferCoreWithFuelUsingSourceFrames
                                            (Nat.succ remaining) onCheckedApp [] []
                                            whnf defeq context state term false =
                                              .ok (ty, nextState)
                                        cases onCheckedApp with
                                        | none =>
                                            simpa [psKernelInferCoreWithFuelUsingSourceFrames,
                                              psKernelInferCacheEligible,
                                              psKernelInferCurrentBinderRanges,
                                              psKernelInferForallHead,
                                              psKernelEnsureSortWith,
                                              hlong, depth, sourceDomain,
                                              sourceBody, term, child,
                                              openedBody, freshResult, fresh,
                                              state1, childLocal, ty, nextState]
                                        | some hook =>
                                            simpa [psKernelInferCoreWithFuelUsingSourceFrames,
                                              psKernelInferCacheEligible,
                                              psKernelInferCurrentBinderRanges,
                                              psKernelInferForallHead,
                                              psKernelEnsureSortWith,
                                              hlong, depth, sourceDomain,
                                              sourceBody, term, child,
                                              openedBody, freshResult, fresh,
                                              state1, childLocal, ty, nextState]
                                    | bvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | fvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | mvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | const _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | app _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | lam _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | forallE _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | letE _ _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | lit _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | mdata _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                                    | proj _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                                        hlong, depth, hd, hb, child, openedBody,
                                        freshResult, fresh, state1, childLocal,
                                        term] at h
                        | bvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | fvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | mvar _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | const _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | app _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | lam _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | forallE _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | letE _ _ _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | lit _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | mdata _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
                        | proj _ _ _ => simp [psKernelC0RecursiveCheckedWithFuel,
                            hlong, depth, hd, term] at h
      | mdata md body =>
          let term : PsKernelExpr := .mdata md body
          cases cached :
               (if psKernelInferCacheEligible false term then
                 psKernelExprMapGet state.checkedInfer term else Option.none) with
          | some ty =>
              cases depth : psKernelCheckerContextEnterRecDepth context with
              | error reason =>
                  simp [psKernelC0RecursiveCheckedWithFuel,
                    cached, depth, term] at h
              | ok entered =>
                  have hr : result = (ty, state) := by
                    have hx : some (ty, state) = some result := by
                      simpa [psKernelC0RecursiveCheckedWithFuel,
                        cached, depth, term] using h
                    exact (Option.some.inj hx).symm
                  rw [hr]
                  have hcache :
                       (if psKernelInferCacheEligible false term then
                         psKernelExprMapGetWithKnownHash state.checkedInfer
                           (.mdata md body) none else Option.none) = some ty := by
                     simpa [psKernelExprMapGet, term] using cached
                  have hcacheExact :
                      (if psKernelInferCacheEligible false (.mdata md body) then
                        psKernelExprMapGetWithKnownHash state.checkedInfer
                          (.mdata md body) none else Option.none) = some ty := by
                    simpa only [term] using hcache
                  simpa [psKernelInferCoreWithFuelUsing,
                    psKernelInferCoreWithFuelUsingSourceFrames,
                    hcacheExact, depth]
          | none =>
              cases depth : psKernelCheckerContextEnterRecDepth context with
              | error reason =>
                  simp [psKernelC0RecursiveCheckedWithFuel,
                    cached, depth, term] at h
              | ok entered =>
                  cases nested : psKernelC0RecursiveCheckedWithFuel
                      remaining entered state body with
                  | none =>
                      simp [psKernelC0RecursiveCheckedWithFuel,
                        cached, depth, nested, term] at h
                  | some nestedResult =>
                      cases nestedResult with
                      | mk ty checkedState =>
                          have hr : result =
                              (ty, psKernelCacheInferResult
                                checkedState false term ty) := by
                            have hx : some (ty, psKernelCacheInferResult
                                checkedState false term ty) = some result := by
                              simpa [psKernelC0RecursiveCheckedWithFuel,
                                cached, depth, nested, term] using h
                            exact (Option.some.inj hx).symm
                          rw [hr]
                          have sourceChild :
                              psKernelInferCoreWithFuelUsingSourceFrames
                                remaining onCheckedApp [] [] whnf defeq
                                entered state body false =
                                .ok (ty, checkedState) := by
                            change psKernelInferCoreWithFuelUsing remaining
                              onCheckedApp whnf defeq
                              entered state body false = .ok (ty, checkedState)
                            exact ih entered state body (ty, checkedState) nested
                          have hcache :
                               (if psKernelInferCacheEligible false term then
                                 psKernelExprMapGetWithKnownHash state.checkedInfer
                                   (.mdata md body) none else Option.none) = none := by
                             simpa [psKernelExprMapGet, term] using cached
                          have hcacheExact :
                              (if psKernelInferCacheEligible false (.mdata md body) then
                                psKernelExprMapGetWithKnownHash state.checkedInfer
                                  (.mdata md body) none else Option.none) = none := by
                            simpa only [term] using hcache
                          simpa [psKernelInferCoreWithFuelUsing,
                            psKernelInferCoreWithFuelUsingSourceFrames,
                            hcacheExact, depth,
                            sourceChild, term]
      | bvar n =>
          exact psKernelC0MetadataInfer_source (Nat.succ remaining)
            onCheckedApp whnf defeq context state (.bvar n) false result
            (by simpa only [psKernelC0RecursiveCheckedWithFuel] using h)
      | mvar name =>
          exact psKernelC0MetadataInfer_source (Nat.succ remaining)
            onCheckedApp whnf defeq context state (.mvar name) false result
            (by simpa only [psKernelC0RecursiveCheckedWithFuel] using h)
      | letE name ty value body nondep =>
          exact psKernelC0MetadataInfer_source (Nat.succ remaining)
            onCheckedApp whnf defeq context state
            (.letE name ty value body nondep) false result
            (by simpa only [psKernelC0RecursiveCheckedWithFuel] using h)
      | proj ty idx body =>
          exact psKernelC0MetadataInfer_source (Nat.succ remaining)
            onCheckedApp whnf defeq context state
            (.proj ty idx body) false result
            (by simpa only [psKernelC0RecursiveCheckedWithFuel] using h)

/-- The public checker uses a distinct hook-free entry for short root
    applications. All successful recursive short-app trees match that route
    exactly, including complete caches and resource-state results. -/
theorem psKernelC0RecursiveCheckedAppRoot_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0RecursiveCheckedWithFuel fuel
      context state (.app fn arg) = some result) :
    psKernelCheckerCheck fuel context state (.app fn arg) = .ok result := by
  have hshort : ¬ psKernelExprGetAppNumArgs (.app fn arg) >= 16 := by
    cases fuel with
    | zero => simp [psKernelC0RecursiveCheckedWithFuel] at h
    | succ remaining =>
        intro hlong
        simp [psKernelC0RecursiveCheckedWithFuel, hlong] at h
  have source := psKernelC0RecursiveChecked_source fuel
    none
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel)
    context state (.app fn arg) result h
  change
    (if psKernelExprGetAppNumArgs (.app fn arg) >= 16 then
      psKernelC0CheckAppRecursiveResummarized fuel
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)
        context state (.app fn arg)
    else
      psKernelInferCoreWithFuel fuel
        (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
        (psKernelIsDefEqWithFuel fuel)
        context state (.app fn arg) false) = .ok result
  simp only [if_neg hshort]
  exact source

/-- The whole verified checker uses the callback-free route at short
    root applications, and the checked-hook route for ALL other root
    constructors. The recursive independent engine refines the correct
    complete public checker in BOTH cases, including source cache states. -/
theorem psKernelC0RecursiveChecked_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0RecursiveCheckedWithFuel fuel
      context state expr = some result) :
    psKernelCheckerCheck fuel context state expr = .ok result := by
  have source := psKernelC0RecursiveChecked_source fuel
    (some psKernelC0CheckAppRecursiveResummarized)
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel)
    context state expr result h
  cases expr with
  | app fn arg =>
      exact psKernelC0RecursiveCheckedAppRoot_checkerCheck
        fuel context state fn arg result h
  | bvar _ => exact source
  | fvar _ => exact source
  | mvar _ => exact source
  | sort _ => exact source
  | const _ _ => exact source
  | lam _ _ _ _ => exact source
  | forallE _ _ _ _ => exact source
  | letE _ _ _ _ _ => exact source
  | lit _ => exact source
  | mdata _ _ => exact source
  | proj _ _ _ => exact source

/-- Public-source-equivalent checked-work operation. On an independently
    qualified success, the dependent receipt proves the full original
    checker equation. For every other term and every decline, run the
    existing projection/binder/application/let/metadata/source fallback. -/
def psKernelC0CertifiedWorkCheckRecursiveOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match h : psKernelC0RecursiveCheckedWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr with
  | none =>
      psKernelC0CertifiedWorkCheckProjectionOwned fuel work expr
  | some (ty, checkedState) =>
      .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
        work checkedState).val), by
          have source : psKernelCheckerCheck fuel
              work.raw.checker.context work.raw.checker.state expr =
                .ok (ty, checkedState) :=
            psKernelC0RecursiveChecked_checkerCheck fuel
              work.raw.checker.context work.raw.checker.state expr
              (ty, checkedState) h
          unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
          simp only [source]
          rfl⟩
