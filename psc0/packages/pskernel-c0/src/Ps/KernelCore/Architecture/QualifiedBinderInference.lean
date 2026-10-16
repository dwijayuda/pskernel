import Ps.KernelCore.Architecture.QualifiedMetadataInference

/-!
Phase E.4Q — independently execute complete checked lambda/Pi binder
HEADS with exact source-result and source-state equivalence.

The official Lean 4.35 kernel type_checker.cpp::infer_lambda/infer_pi
maintains fresh local declarations, checks dependent domain/body terms,
opens binders, and closes inferred result types. The equivalent C0
binder algorithms are extracted in Checker/Inference/Binder.lean,
where source and qualified checked inference use the SAME precise rule.

A checked binder is not memoized in the source's checked-inference cache;
only infer-only binders are. Thus the direct checked path reproduces the
original source recursion-depth/fuel guard and runs the source-exact binder
rule immediately, without re-running the top-level recursive InferCore
dispatcher. The DOMAIN/BODY recursive subjudgments still call the original
source recursive worker — this is a full binder-head operational refinement,
NOT complete independent recursive type inference for arbitrary subterms.

No source checker result is accepted without an equation proving the
entire result and checker state exactly equal to C0 source checking.
Unknown binders, resource exhaustion and failures preserve source errors.
-/

/-- Complete source-exact checked lambda-head execution. All recursively
    checked domain and body judgments keep the original source evaluator. -/
def psKernelC0LambdaFullWithFuel
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => .error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      match psKernelCheckerContextEnterRecDepth context with
      | .error error => .error error
      | .ok entered =>
          psKernelInferLambdaHead
            (psKernelInferCoreWithFuelUsingSourceFrames remaining onCheckedApp)
            whnf defeq entered state name domain body binderInfo false
            (psKernelInferCurrentBinderRanges
              (.lam name domain body binderInfo) onCheckedApp [])

/-- Complete source-exact dependent Π-head formation. Universes, opening,
    fresh local declarations and source body checks match Lean 4.35's
    dependent Π algorithm exactly as implemented by C0. -/
def psKernelC0PiFullWithFuel
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  match fuel with
  | 0 => .error "kernel inference budget exhausted"
  | Nat.succ remaining =>
      match psKernelCheckerContextEnterRecDepth context with
      | .error error => .error error
      | .ok entered =>
          psKernelInferForallHead
            (psKernelInferCoreWithFuelUsingSourceFrames remaining onCheckedApp)
            whnf defeq entered state name domain body binderInfo false
            (psKernelInferCurrentBinderRanges
              (.forallE name domain body binderInfo) onCheckedApp [])

/-- Source equality of the entire checked lambda operation, including
    every error and full checker cache/state result. The theorem is
    definitional: both source and qualified binder heads share EXACT
    helper functions, without an extra trusted assumption. -/
theorem psKernelC0LambdaFull_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelC0LambdaFullWithFuel fuel onCheckedApp whnf defeq
      context state name domain body binderInfo =
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.lam name domain body binderInfo) false := by
  cases fuel with
  | zero => rfl
  | succ remaining =>
      simp [psKernelC0LambdaFullWithFuel,
        psKernelInferCoreWithFuelUsing,
        psKernelInferCoreWithFuelUsingSourceFrames,
        psKernelInferCacheEligible] <;> rfl

/-- Source equality of the entire dependent Π checked operation for
    every starting source context/state, fuel, safety level and callback.
    This includes source recursion failure and all dependent child checks. -/
theorem psKernelC0PiFull_source
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelC0PiFullWithFuel fuel onCheckedApp whnf defeq
      context state name domain body binderInfo =
    psKernelInferCoreWithFuelUsing fuel onCheckedApp whnf defeq
      context state (.forallE name domain body binderInfo) false := by
  cases fuel with
  | zero => rfl
  | succ remaining =>
      simp [psKernelC0PiFullWithFuel,
        psKernelInferCoreWithFuelUsing,
        psKernelInferCoreWithFuelUsingSourceFrames,
        psKernelInferCacheEligible] <;> rfl

/-- Match the real source full-check specialization. It is essential
    that any recursively checked applications inside the binder continue
    to use the source checked-app callback and resource policy. -/
theorem psKernelC0LambdaFull_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelC0LambdaFullWithFuel fuel
      (some psKernelC0CheckAppRecursiveResummarized)
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel) context state
      name domain body binderInfo =
    psKernelCheckerCheck fuel context state
      (.lam name domain body binderInfo) := by
  rw [psKernelC0LambdaFull_source]
  rfl

theorem psKernelC0PiFull_checkerCheck
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (binderInfo : PsKernelBinderInfo) :
    psKernelC0PiFullWithFuel fuel
      (some psKernelC0CheckAppRecursiveResummarized)
      (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
      (psKernelIsDefEqWithFuel fuel) context state
      name domain body binderInfo =
    psKernelCheckerCheck fuel context state
      (.forallE name domain body binderInfo) := by
  rw [psKernelC0PiFull_source]
  rfl

/-- Source-verified independent checked binder heads. Every returned
    success carries its complete source operation equation. The other
    supported heads still use prior qualified metadata/scalar/FVar/cold
    constant rules; all unsupported cases retain source checking. -/
def psKernelC0CertifiedWorkCheckBinderOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      { result : PsKernelExpr × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkCheck fuel work expr = .ok result } :=
  match expr with
  | .lam name domain body binderInfo =>
      match h : psKernelC0LambdaFullWithFuel fuel
          (some psKernelC0CheckAppRecursiveResummarized)
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          name domain body binderInfo with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work nextState).val), by
              have source :
                  psKernelCheckerCheck fuel
                    work.raw.checker.context work.raw.checker.state
                    (.lam name domain body binderInfo) =
                      .ok (ty, nextState) := by
                rw [← psKernelC0LambdaFull_checkerCheck]
                exact h
              unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
              simp only [source]
              rfl⟩
  | .forallE name domain body binderInfo =>
      match h : psKernelC0PiFullWithFuel fuel
          (some psKernelC0CheckAppRecursiveResummarized)
          (psKernelWhnfWithRecursorFuel fuel (psKernelIsDefEqWithFuel fuel))
          (psKernelIsDefEqWithFuel fuel)
          work.raw.checker.context work.raw.checker.state
          name domain body binderInfo with
      | .error reason => .error reason
      | .ok (ty, nextState) =>
          .ok ⟨(ty, (psKernelC0CertifiedWorkWithStateOwned
            work nextState).val), by
              have source :
                  psKernelCheckerCheck fuel
                    work.raw.checker.context work.raw.checker.state
                    (.forallE name domain body binderInfo) =
                      .ok (ty, nextState) := by
                rw [← psKernelC0PiFull_checkerCheck]
                exact h
              unfold psKernelC0CertifiedWorkCheck psKernelSessionCheck
              simp only [source]
              rfl⟩
  | other => psKernelC0CertifiedWorkCheckMetadataOwned fuel work other
