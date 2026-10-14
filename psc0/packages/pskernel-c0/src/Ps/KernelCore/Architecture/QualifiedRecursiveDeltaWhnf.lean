import Ps.KernelCore.Architecture.QualifiedRecursiveWhnf

/-!
E.4AI — one compositional, independently executing public WHNF evaluator
that incorporates delta unfolding into E.4AH's independently proved
beta/zeta core, retaining exactly the source fuel, callback, context,
and intermediate cache/state transitions.

Official Lean 4.35 reference: src/kernel/type_checker.cpp::whnf,
src/kernel/type_checker.cpp::unfold_definition; C0 pinned source:
Checker/Reduction/Whnf.lean::psKernelWhnfWithFuel and
Checker/Context.lean::psKernelUnfoldDefinition.

A successful path does NOT call the original source public WHNF,
core WHNF or source recursor reducer. The expression substitution,
environment-definition lookup and cache insertion remain the existing
audited deterministic C0 semantic primitives, now composed by an
independent recursive controller. This does not claim complete WHNF:
native Nat, contextual FVars, projections, recursors, Quot and
unqualified core calls still decline to the authoritative source.
-/

/-- Only the five unconditional source-public WHNF terminal constructors
    avoid a core call and all cache writes. Lambda and constant do NOT:
    they require public cache lookup and core depth/resource checks. -/
def psKernelC0DeltaPublicImmediate : PsKernelExpr → Bool
  | .bvar _ => true
  | .sort _ => true
  | .mvar _ => true
  | .forallE _ _ _ _ => true
  | .lit _ => true
  | _ => false

def psKernelC0DeltaIsMetadata : PsKernelExpr → Bool
  | .mdata _ _ => true
  | _ => false

/-- Forms for which the existing E.4AH core is independently qualified.
    A delta-expanded application headed by an unknown constant is NOT
    accepted: recursor/Quot/Nat callbacks can affect its source state. -/
def psKernelC0DeltaCoreEligible : PsKernelExpr → Bool
  | .const _ _ => true
  | .lam _ _ _ _ => true
  | .app _ _ => true
  | .letE _ _ _ _ _ => true
  | _ => false

/-- The same whole checker state as original public WHNF completion.
    An unfolded child may have inserted intermediate core and public
    entries; insert only the final ORIGINAL root's public entry here. -/
def psKernelC0RecursiveDeltaWhnfFinish
    (expr value : PsKernelExpr)
    (state : PsKernelCheckerState) : PsKernelCheckerState :=
  psKernelCheckerStateWithWhnf state
    (psKernelExprMapInsert state.whnf expr value)

/-- Recursively normalize delta-expanded expressions with the source's
    remaining PUBLIC fuel. This worker handles multiple δ steps, β/ζ
    between δ steps, metadata prefixes and source-stable terminals.
    A failed partial evaluation is never a kernel rejection. -/
def psKernelC0RecursiveDeltaWhnfWithFuel :
    Nat → PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → Option (PsKernelExpr × PsKernelCheckerState)
  | 0, _, _, _ => none
  | Nat.succ remaining, context, state, expr =>
      if psKernelC0DeltaPublicImmediate expr then
        some (expr, state)
      else if psKernelC0DeltaIsMetadata expr then
        match expr with
        | .mdata _ body =>
            psKernelC0RecursiveDeltaWhnfWithFuel
              remaining context state body
        | _ => none
      else if psKernelC0DeltaCoreEligible expr then
        match psKernelExprMapGet state.whnf expr with
        | some _ => none
        | none =>
            match psKernelC0RecursiveBetaZetaCoreWithFuel
                remaining context state expr with
            | none => none
            | some (core, coreState) =>
                if psKernelC0StableWhnfTerminal core then
                  some (core,
                    psKernelC0RecursiveDeltaWhnfFinish expr core coreState)
                else
                  match core with
                  | .const _ _ =>
                      match psKernelUnfoldDefinition context core with
                      | none =>
                          some (core,
                            psKernelC0RecursiveDeltaWhnfFinish expr core coreState)
                      | some opened =>
                          match psKernelC0RecursiveDeltaWhnfWithFuel
                              remaining context coreState opened with
                          | none => none
                          | some (value, valueState) =>
                              some (value,
                                psKernelC0RecursiveDeltaWhnfFinish
                                  expr value valueState)
                  | _ => none
      else none

/-- The source's Nat reduction is a no-op on a constant; independently
    exercising the deterministic environment delta lookup is therefore
    exactly the public post-core decision for that constructor. -/
theorem psKernelC0ConstPostDelta_source
    (callback :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Except String (PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (original : PsKernelExpr)
    (name : PsKernelName)
    (levels : List PsKernelLevel)
    (next : Option PsKernelExpr)
    (hdelta :
      psKernelUnfoldDefinition context (.const name levels) = next) :
    psKernelWhnfAfterCore callback context state original
        (.const name levels) =
      match next with
      | none =>
          psKernelWhnfFinish original (.const name levels) state
      | some unfolded =>
          match callback context state unfolded with
          | .error reason => .error reason
          | .ok (result, after) =>
              psKernelWhnfFinish original result after := by
  simp [psKernelWhnfAfterCore, psKernelReduceNatWith, hdelta]

/-- Full source-refinement of the NEW compositional public WHNF
    controller. All successful direct and nested delta/beta/zeta paths
    have the identical source result and complete checker/cache state.
    In particular, success does NOT merely mean the same normalized
    expression: its intermediate delta-expanded public and core writes
    are exactly preserved. -/
theorem psKernelC0RecursiveDeltaWhnf_source
    (fuel : Nat)
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0RecursiveDeltaWhnfWithFuel
        fuel context state expr = some result) :
    psKernelWhnfWithFuel fuel reduceRecursor context state expr =
      .ok result := by
  induction fuel generalizing context state expr result with
  | zero =>
      simp [psKernelC0RecursiveDeltaWhnfWithFuel] at h
  | succ remaining ih =>
      by_cases direct : psKernelC0DeltaPublicImmediate expr = true
      · have hr : result = (expr, state) := by
          have hx : some (expr, state) = some result := by
            simpa [psKernelC0RecursiveDeltaWhnfWithFuel,
              direct] using h
          exact (Option.some.inj hx).symm
        rw [hr]
        cases expr <;>
          simp [psKernelC0DeltaPublicImmediate] at direct <;>
          simp [psKernelWhnfWithFuel]
      · by_cases metadata : psKernelC0DeltaIsMetadata expr = true
        · cases expr with
          | mdata tag body =>
              have child :
                  psKernelC0RecursiveDeltaWhnfWithFuel
                    remaining context state body = some result := by
                simpa [psKernelC0RecursiveDeltaWhnfWithFuel,
                  direct, metadata] using h
              change psKernelWhnfWithFuel remaining reduceRecursor
                context state body = .ok result
              exact ih context state body result child
          | bvar _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | fvar _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | mvar _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | sort _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | const _ _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | app _ _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | lam _ _ _ _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | forallE _ _ _ _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | letE _ _ _ _ _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | lit _ => simp [psKernelC0DeltaIsMetadata] at metadata
          | proj _ _ _ => simp [psKernelC0DeltaIsMetadata] at metadata
        · by_cases eligible : psKernelC0DeltaCoreEligible expr = true
          · have sourceOuter :
                psKernelWhnfWithFuel (Nat.succ remaining)
                  reduceRecursor context state expr =
                  match psKernelExprMapGet state.whnf expr with
                  | some cached => .ok (cached, state)
                  | none =>
                      match psKernelWhnfCoreWithFuel remaining
                          (fun ctx st ex =>
                            psKernelWhnfWithFuel remaining
                              reduceRecursor ctx st ex)
                          reduceRecursor context state expr false false with
                      | .error error => .error error
                      | .ok (core, coreState) =>
                          psKernelWhnfAfterCore
                            (fun ctx st ex =>
                              psKernelWhnfWithFuel remaining
                                reduceRecursor ctx st ex)
                            context coreState expr core := by
                cases expr <;>
                  simp [psKernelC0DeltaCoreEligible] at eligible <;>
                  simp [psKernelWhnfWithFuel]
            rw [sourceOuter]
            cases cache : psKernelExprMapGet state.whnf expr with
            | some cached =>
                simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                  direct, metadata, eligible, cache] at h
            | none =>
                cases coreCheck : psKernelC0RecursiveBetaZetaCoreWithFuel
                    remaining context state expr with
                | none =>
                    simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                      direct, metadata, eligible, cache, coreCheck] at h
                | some coreResult =>
                    rcases coreResult with ⟨core, coreState⟩
                    let callback :=
                      fun (ctx : PsKernelCheckerContext)
                        (st : PsKernelCheckerState)
                        (ex : PsKernelExpr) =>
                          psKernelWhnfWithFuel remaining
                            reduceRecursor ctx st ex
                    have sourceCore :
                        psKernelWhnfCoreWithFuel remaining callback
                          reduceRecursor context state expr false false =
                            .ok (core, coreState) := by
                      exact psKernelC0RecursiveBetaZetaCore_source
                        remaining callback reduceRecursor context state
                        expr (core, coreState) coreCheck
                    by_cases stable : psKernelC0StableWhnfTerminal core = true
                    · let afterState :=
                        psKernelC0RecursiveDeltaWhnfFinish
                          expr core coreState
                      have hr : result = (core, afterState) := by
                        have hx : some (core, afterState) = some result := by
                          simpa [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache, coreCheck,
                            stable, afterState] using h
                        exact (Option.some.inj hx).symm
                      have sourcePost :
                          psKernelWhnfAfterCore callback context coreState
                            expr core = psKernelWhnfFinish expr core coreState :=
                        psKernelC0StableWhnfTerminal_post
                          callback context coreState expr core stable
                      rw [hr]
                      simp only [cache, sourceCore, sourcePost]
                      rfl
                    · cases core with
                      | const name levels =>
                          let constTerm : PsKernelExpr := .const name levels
                          cases unfolding :
                              psKernelUnfoldDefinition context constTerm with
                          | none =>
                              let afterState :=
                                psKernelC0RecursiveDeltaWhnfFinish
                                  expr constTerm coreState
                              have hr : result = (constTerm, afterState) := by
                                have hx : some (constTerm, afterState) =
                                    some result := by
                                  simpa [psKernelC0RecursiveDeltaWhnfWithFuel,
                                    direct, metadata, eligible, cache,
                                    coreCheck, stable, unfolding,
                                    constTerm, afterState] using h
                                exact (Option.some.inj hx).symm
                              have sourcePost :=
                                psKernelC0ConstPostDelta_source
                                  callback context coreState expr name levels
                                  none unfolding
                              rw [hr]
                              simp only [cache, sourceCore, sourcePost]
                              rfl
                          | some opened =>
                              cases child : psKernelC0RecursiveDeltaWhnfWithFuel
                                  remaining context coreState opened with
                              | none =>
                                  simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                                    direct, metadata, eligible, cache,
                                    coreCheck, stable, unfolding,
                                    child, constTerm] at h
                              | some childResult =>
                                  rcases childResult with ⟨value, childState⟩
                                  let afterState :=
                                    psKernelC0RecursiveDeltaWhnfFinish
                                      expr value childState
                                  have hr : result = (value, afterState) := by
                                    have hx : some (value, afterState) =
                                        some result := by
                                      simpa [psKernelC0RecursiveDeltaWhnfWithFuel,
                                        direct, metadata, eligible, cache,
                                        coreCheck, stable, unfolding,
                                        child, constTerm, afterState] using h
                                    exact (Option.some.inj hx).symm
                                  have sourceChild :=
                                    ih context coreState opened
                                      (value, childState) child
                                  have sourcePost :=
                                    psKernelC0ConstPostDelta_source
                                      callback context coreState expr
                                      name levels (some opened) unfolding
                                  rw [hr]
                                  simp only [cache, sourceCore, sourcePost,
                                    sourceChild]
                                  rfl
                      | bvar _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | fvar _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | mvar _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | sort _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | app _ _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | lam _ _ _ _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | forallE _ _ _ _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | letE _ _ _ _ _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | lit _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | mdata _ _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
                      | proj _ _ _ =>
                          simp [psKernelC0RecursiveDeltaWhnfWithFuel,
                            direct, metadata, eligible, cache,
                            coreCheck, stable] at h
          · simp [psKernelC0RecursiveDeltaWhnfWithFuel,
              direct, metadata, eligible] at h

/-- A returned success is bound to the exact original trusted checker
    operation, including its cache, recursive fuel and source environment. -/
theorem psKernelC0RecursiveDeltaWhnf_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr)
    (result : PsKernelExpr × PsKernelCheckerState)
    (h : psKernelC0RecursiveDeltaWhnfWithFuel fuel
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
    exact psKernelC0RecursiveDeltaWhnf_source fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr result h
  rcases result with ⟨value, nextState⟩
  unfold psKernelC0CertifiedWorkWhnf psKernelSessionWhnf
  simp only [source]
  rfl

/-- One accepting WHNF path: first try compositional beta/zeta/delta with
    exact source proof. All unsupported and resource-limited cases
    preserve the previously qualified recursive beta/zeta+source route.
    WHNF is never a proof/admission verdict. -/
def psKernelC0CertifiedWorkWhnfDeltaOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0SourceExactWhnfOutput fuel work expr) :=
  match h : psKernelC0RecursiveDeltaWhnfWithFuel fuel
      work.raw.checker.context work.raw.checker.state expr with
  | none => psKernelC0CertifiedWorkWhnfRecursiveOwned fuel work expr
  | some result =>
      .ok ⟨(result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val),
        psKernelC0RecursiveDeltaWhnf_certified fuel work expr result h⟩
