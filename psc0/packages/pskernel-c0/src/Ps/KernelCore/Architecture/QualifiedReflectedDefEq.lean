import Ps.KernelCore.Architecture.QualifiedRecursiveMetadataDefEq

/-!
E.4AK — independent, source-refined Bool.true reflection using E.4AI's
independently computed recursive beta/zeta/delta public WHNF.

Pinned Lean 4.35 reference:
  src/kernel/type_checker.cpp::is_def_eq_core (reflection)
Pinned source checker:
  Checker/Knot.lean::psKernelIsDefEqWithFuel
  Checker/DefEq/Shortcuts.lean::psKernelDefEqReflectionWith.

This is a genuine integration between TWO independently evaluated
kernel operations. The source reflection shortcut, after an ordinary
quick comparison miss, calls *public* WHNF on the left; if it reduces
to Bool.true, the original algorithm caches DefEq success. A selected
result here independently evaluates that WHNF through the E.4AI proof,
then computes the source-positive cache update with no source DefEq
or WHNF evaluator call. The theorem proves the full source result and
checker state, not just the Boolean. The closed-app syntactic domain
is intentionally narrow; reduction-dependent proof irrelevance, eta,
lazy-delta and untyped source validation remain separate obligations.

This is a conversion *observation* only. Actual verified-root admission
and checked provider APIs must independently type-check both terms.
-/

/-- Exact one-side closed Bool.true reflection candidate, with the
    source's DefEq fuel, recursion-depth, prior-success-cache and
    source-public WHNF fuel and checker-state accounting. -/
def psKernelC0ReflectedAppBoolTrueWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr)
    (rightName : PsKernelName) :
    Option (Bool × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ remaining =>
      if psKernelNameEq rightName psKernelBoolTrueName then
        match psKernelCheckerContextEnterRecDepth context with
        | .error _ => none
        | .ok entered =>
            let left : PsKernelExpr := .app fn arg
            let right : PsKernelExpr := .const rightName []
            if psKernelExprPairSetContains state.success left right then none
            else if psKernelExprHasFVar left then none
            else
              match psKernelC0RecursiveDeltaWhnfWithFuel
                  remaining entered state left with
              | some (.const reducedName [], checkedState) =>
                  if psKernelNameEq reducedName psKernelBoolTrueName then
                    some (psKernelDefEqFinish
                      checkedState left right true)
                  else none
              | _ => none
      else none

/-- Source-proved reflection for an application and a Bool.true name.
    Every successful candidate computes the identical COMPLETE original
    DefEq result, including the public/core WHNF cache state and final
    positive conversion-pair cache. -/
theorem psKernelC0ReflectedAppBoolTrue_source
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr)
    (rightName : PsKernelName)
    (result : Bool × PsKernelCheckerState)
    (h : psKernelC0ReflectedAppBoolTrueWithFuel
      fuel context state fn arg rightName = some result) :
    psKernelIsDefEq fuel context state
      (.app fn arg) (.const rightName []) = .ok result := by
  cases fuel with
  | zero =>
      simp [psKernelC0ReflectedAppBoolTrueWithFuel] at h
  | succ remaining =>
      let left : PsKernelExpr := .app fn arg
      let right : PsKernelExpr := .const rightName []
      by_cases rightTrue :
          psKernelNameEq rightName psKernelBoolTrueName = true
      · cases depth : psKernelCheckerContextEnterRecDepth context with
        | error reason =>
            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
              rightTrue, depth, left, right] at h
        | ok entered =>
            cases cached :
                psKernelExprPairSetContains state.success
                  left right with
            | true =>
                simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                  rightTrue, depth, cached, left, right] at h
            | false =>
                cases closed : psKernelExprHasFVar left with
                | true =>
                    simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                      rightTrue, depth, cached, closed,
                      left, right] at h
                | false =>
                    cases whnf :
                        psKernelC0RecursiveDeltaWhnfWithFuel
                          remaining entered state left with
                    | none =>
                        simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                          rightTrue, depth, cached, closed,
                          whnf, left, right] at h
                    | some pair =>
                        rcases pair with ⟨reduced, checkedState⟩
                        cases reduced with
                        | const reducedName levels =>
                            cases levels with
                            | nil =>
                                by_cases reducedTrue :
                                    psKernelNameEq reducedName
                                      psKernelBoolTrueName = true
                                · let finalized :=
                                    psKernelDefEqFinish checkedState
                                      left right true
                                  have hr : result = finalized := by
                                    have hx : some finalized = some result := by
                                      simpa [psKernelC0ReflectedAppBoolTrueWithFuel,
                                        rightTrue, depth, cached, closed,
                                        whnf, reducedTrue, left, right,
                                        finalized] using h
                                    exact (Option.some.inj hx).symm
                                  have sourceWhnf :
                                      psKernelWhnfWithRecursorFuel remaining
                                        (psKernelIsDefEqWithFuel remaining)
                                        entered state left =
                                        .ok (.const reducedName [], checkedState) := by
                                    change psKernelWhnfWithFuel remaining
                                      (psKernelReduceRecursorBoundedWithFuel
                                        remaining (psKernelIsDefEqWithFuel remaining))
                                      entered state left =
                                        .ok (.const reducedName [], checkedState)
                                    exact psKernelC0RecursiveDeltaWhnf_source
                                      remaining
                                      (psKernelReduceRecursorBoundedWithFuel
                                        remaining (psKernelIsDefEqWithFuel remaining))
                                      entered state left
                                      (.const reducedName [], checkedState) whnf
                                  have sourceQuick :
                                      psKernelDefEqQuickAfterCommon
                                        (psKernelIsDefEqWithFuel remaining)
                                        entered state left right =
                                        .ok (none, state) := by
                                    rfl
                                  have sourceReflection :
                                      psKernelDefEqReflectionWith
                                        (psKernelWhnfWithRecursorFuel remaining
                                          (psKernelIsDefEqWithFuel remaining))
                                        entered state left right =
                                        .ok (some true, checkedState) := by
                                    simp [psKernelDefEqReflectionWith,
                                      sourceWhnf, closed, rightTrue,
                                      reducedTrue, left, right]
                                  rw [hr]
                                  change psKernelIsDefEqWithFuel
                                    (Nat.succ remaining) context state
                                    left right = .ok finalized
                                  rw [psKernelIsDefEqWithFuel]
                                  simp [psKernelDefEqSourceStepWithFuel,
                                    depth, psKernelExprEq, cached,
                                    sourceQuick, sourceReflection,
                                    finalized, left, right]
                                · simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                                    rightTrue, depth, cached, closed,
                                    whnf, reducedTrue, left, right] at h
                            | cons level rest =>
                                simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                                  rightTrue, depth, cached, closed,
                                  whnf, left, right] at h
                        | bvar _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | fvar _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | mvar _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | sort _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | app _ _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | lam _ _ _ _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | forallE _ _ _ _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | letE _ _ _ _ _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | lit _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | mdata _ _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
                        | proj _ _ _ =>
                            simp [psKernelC0ReflectedAppBoolTrueWithFuel,
                              rightTrue, depth, cached, closed,
                              whnf, left, right] at h
      · simp [psKernelC0ReflectedAppBoolTrueWithFuel,
          rightTrue, left, right] at h

/-- Preserve the original expression identity for dependent receipts
    without destructuring the result index in the provider selector. -/
def psKernelC0ReflectedBoolTrueDefEqWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    Option (Bool × PsKernelCheckerState) :=
  match left, right with
  | .app fn arg, .const rightName [] =>
      psKernelC0ReflectedAppBoolTrueWithFuel
        fuel context state fn arg rightName
  | _, _ => none

theorem psKernelC0ReflectedBoolTrueDefEq_source
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (result : Bool × PsKernelCheckerState)
    (h : psKernelC0ReflectedBoolTrueDefEqWithFuel fuel
      context state left right = some result) :
    psKernelIsDefEq fuel context state left right = .ok result := by
  cases left with
  | app fn arg =>
      cases right with
      | const name levels =>
          cases levels with
          | nil =>
              exact psKernelC0ReflectedAppBoolTrue_source
                fuel context state fn arg name result
                (by simpa only [psKernelC0ReflectedBoolTrueDefEqWithFuel]
                  using h)
          | cons _ _ =>
              simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | bvar _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | fvar _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | mvar _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | sort _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | app _ _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | lam _ _ _ _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | forallE _ _ _ _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | letE _ _ _ _ _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | lit _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | mdata _ _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
      | proj _ _ _ => simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | bvar _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | fvar _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | mvar _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | sort _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | const _ _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | lam _ _ _ _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | forallE _ _ _ _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | letE _ _ _ _ _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | lit _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | mdata _ _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h
  | proj _ _ _ => cases right <;>
      simp [psKernelC0ReflectedBoolTrueDefEqWithFuel] at h

theorem psKernelC0ReflectedBoolTrueDefEq_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (left right : PsKernelExpr)
    (result : Bool × PsKernelCheckerState)
    (h : psKernelC0ReflectedBoolTrueDefEqWithFuel fuel
      work.raw.checker.context work.raw.checker.state
      left right = some result) :
    psKernelC0CertifiedWorkDefEq fuel work left right =
      .ok (result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val) := by
  have source :
      psKernelIsDefEq fuel work.raw.checker.context
        work.raw.checker.state left right = .ok result :=
    psKernelC0ReflectedBoolTrueDefEq_source
      fuel work.raw.checker.context work.raw.checker.state
      left right result h
  rcases result with ⟨equal, nextState⟩
  unfold psKernelC0CertifiedWorkDefEq psKernelSessionIsDefEq
  simp only [source]
  rfl

/-- Unified dependent DefEq dispatch: first the independently proved
    recursive WHNF-based reflection, then independently proved
    metadata/Sort/literal/reflexive DefEq; unsupported cases finally
    use the unchanged original source algorithm with exact errors. -/
def psKernelC0CertifiedWorkDefEqReflectedOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (left right : PsKernelExpr) :
    Except String
      { result : Bool × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkDefEq fuel work left right = .ok result } :=
  match h : psKernelC0ReflectedBoolTrueDefEqWithFuel fuel
      work.raw.checker.context work.raw.checker.state
      left right with
  | none => psKernelC0CertifiedWorkDefEqRecursiveMetadataOwned
      fuel work left right
  | some result =>
      .ok ⟨(result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val),
        psKernelC0ReflectedBoolTrueDefEq_certified
          fuel work left right result h⟩
