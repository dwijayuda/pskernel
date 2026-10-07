import Ps.KernelCore.Checker.DefEq.LazyDelta
import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.ProjectionReduction

/-
Independent refinement of the terminal projection comparison used by
lazy-delta.  The concrete worker compares the computed fields only when
*both* projections reduce.  If either field is unavailable it compares the
original major premises and applies projection congruence instead.

No general transitivity of algorithmic DefEq is used.
-/

theorem psKernelDefEqLazyProjFinish_configuration_sound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hDefEq : PsKernelDefEqConfigurationSound defeq)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (typeName : PsKernelName)
    (index : Nat)
    (value : Bool)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hSuccess :
      psKernelDefEqLazyProjFinish
          defeq context state left right typeName index =
        Except.ok (Prod.mk value nextState)) :
    PsKernelCheckerConfigurationSound context nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          (PsKernelExpr.proj typeName index left)
          (PsKernelExpr.proj typeName index right)) := by
  unfold psKernelDefEqLazyProjFinish at hSuccess
  cases hLeft :
      psKernelReduceProjCore context typeName index left with
  | none =>
      simp only [hLeft] at hSuccess
      have hEq :=
        hDefEq
          context state nextState left right value
          hConfig hSuccess
      refine ⟨hEq.1, ?_⟩
      intro hTrue
      exact
        PsKernelDefEqJudgment.projection
          typeName index left right
          (hEq.2 hTrue)
  | some leftValue =>
      cases hRight :
          psKernelReduceProjCore context typeName index right with
      | none =>
          simp only [hLeft, hRight] at hSuccess
          have hEq :=
            hDefEq
              context state nextState left right value
              hConfig hSuccess
          refine ⟨hEq.1, ?_⟩
          intro hTrue
          exact
            PsKernelDefEqJudgment.projection
              typeName index left right
              (hEq.2 hTrue)
      | some rightValue =>
          simp only [hLeft, hRight] at hSuccess
          have hEq :=
            hDefEq
              context state nextState
              leftValue rightValue value
              hConfig hSuccess
          refine ⟨hEq.1, ?_⟩
          intro hTrue
          exact
            PsKernelDefEqJudgment.reduceCompare
              (PsKernelExpr.proj typeName index left)
              (PsKernelExpr.proj typeName index right)
              leftValue
              rightValue
              (psKernelReduceProjCore_some_refines_closure
                context typeName index left leftValue
                hConfig.1 hLeft)
              (psKernelReduceProjCore_some_refines_closure
                context typeName index right rightValue
                hConfig.1 hRight)
              (hEq.2 hTrue)
