import Ps.KernelCore.Architecture.QualifiedProjectionInference

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
        by_contra hlong
        simp [psKernelC0CheckedAppLeafWithFuel, hlong] at h
  have exactSource := psKernelC0CheckedAppLeaf_source fuel
    none
    (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
    (psKernelIsDefEqWithFuel fuel)
    context state fn arg result h
  simpa [psKernelCheckerCheck, psKernelCheckWithFuel, hshort,
    psKernelInferCoreWithFuel, psKernelInferCoreWithFuelUsing] using exactSource

/-- Public-source-equivalent checked-work operation. On an independently
    qualified success, the dependent receipt proves the full original
    checker equation. For every other term and every decline, run the
    existing projection/binder/application/let/metadata/source fallback. -/
def psKernelC0CertifiedWorkCheckIndependentAppOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .app fn arg =>
      match h : psKernelC0CheckedAppLeafWithFuel fuel
          work.raw.checker.context work.raw.checker.state fn arg with
      | none =>
          psKernelC0CertifiedWorkCheckProjectionOwned fuel work (.app fn arg)
      | some (ty, checkedState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work checkedState).val), by
              have source : psKernelCheckerCheck fuel
                  work.raw.checker.context work.raw.checker.state
                  (.app fn arg) = .ok (ty, checkedState) :=
                psKernelC0CheckedAppLeaf_checkerCheck fuel
                  work.raw.checker.context work.raw.checker.state fn arg
                  (ty, checkedState) h
              unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkCheckProjectionOwned fuel work other
