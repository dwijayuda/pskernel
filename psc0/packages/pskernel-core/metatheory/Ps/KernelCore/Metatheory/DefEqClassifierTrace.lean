import Ps.KernelCore.Checker.DefEq.FinalRules

/-
Exact operational evidence for proposition classification.

This retains the connection that the legacy abstract judgment discards:
the expression was passed to this inference operation, its returned type
was passed to this WHNF operation, and that result was a zero-level sort.
The states are threaded exactly as in the implementation.

A trace is not a semantic typing theorem. Infer-only soundness on valid
inputs and a model-preservation theorem remain separate obligations.
-/

def PsKernelPropClassificationTrace
    (inferType whnf :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
      Except String (PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr) : Prop :=
  ∃ (inferredType : PsKernelExpr)
    (inferredState : PsKernelCheckerState)
    (level : PsKernelLevel),
    inferType context state expr = Except.ok (inferredType, inferredState) ∧
    whnf context inferredState inferredType =
      Except.ok (PsKernelExpr.sort level, nextState) ∧
    psKernelLevelNormalizesToZero level = true

/-- Positive classification is equivalent to its complete operational trace. -/
theorem psKernelDefEqIsPropWith_true_iff_trace
    (inferType whnf :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
      Except String (PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelDefEqIsPropWith inferType whnf context state expr =
        Except.ok (true, nextState) ↔
      PsKernelPropClassificationTrace inferType whnf context state nextState expr := by
  constructor
  · intro hSuccess
    cases hInferRun : inferType context state expr with
    | error error =>
        simp [psKernelDefEqIsPropWith, hInferRun] at hSuccess
    | ok inferRun =>
        rcases inferRun with ⟨inferredType, inferredState⟩
        cases hWhnfRun : whnf context inferredState inferredType with
        | error error =>
            simp [psKernelDefEqIsPropWith, hInferRun, hWhnfRun] at hSuccess
        | ok whnfRun =>
            rcases whnfRun with ⟨reducedType, reducedState⟩
            cases reducedType with
            | sort level =>
                simp [psKernelDefEqIsPropWith, hInferRun, hWhnfRun] at hSuccess
                rcases hSuccess with ⟨hZero, rfl⟩
                exact ⟨inferredType, inferredState, level, hInferRun, hWhnfRun, hZero⟩
            | _ =>
                simp [psKernelDefEqIsPropWith, hInferRun, hWhnfRun] at hSuccess
  · rintro ⟨inferredType, inferredState, level, hInferRun, hWhnfRun, hZero⟩
    simp [psKernelDefEqIsPropWith, hInferRun, hWhnfRun, hZero]

#print axioms psKernelDefEqIsPropWith_true_iff_trace
