import Ps.KernelCore.Checker.Recursor.Reduction
import Ps.KernelCore.Metatheory.CheckerContracts
import Ps.KernelCore.Metatheory.QuotReduction

/-
Configuration-aware semantics for recursor computation.

K conversion and structure conversion are explicit proof obligations because
they are semantic conversions, not ordinary WHNF callbacks.  The top-level
recursor reducer itself is then just Quot reduction followed by ordinary
inductive recursor reduction.
-/

def PsKernelRecursorKConversionConfigurationSound
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (major result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    psKernelToConstructorWhenK
        publicWhnf
        inferType
        defeq
        context
        state
        recursor
        major =
      Except.ok (Prod.mk result nextState) ->
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelReductionClosure
        context.environment
        context.localContext
        major
        result


def PsKernelRecursorStructureConversionConfigurationSound
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (recursor : PsKernelRecursorInfo)
    (major result : PsKernelExpr),
    PsKernelCheckerConfigurationSound context state ->
    psKernelToConstructorWhenStructure
        publicWhnf
        inferType
        context
        state
        recursor
        major =
      Except.ok (Prod.mk result nextState) ->
    PsKernelCheckerConfigurationSound context nextState ∧
      PsKernelReductionClosure
        context.environment
        context.localContext
        major
        result


theorem psKernelReduceRecursorWith_configuration_sound_of_inductive
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState))
    (hWhnf :
      PsKernelWhnfConfigurationSound publicWhnf)
    (hInductive :
      PsKernelRecursorReductionConfigurationSound
        (psKernelReduceInductiveRecWith
          publicWhnf
          coreWhnf
          inferType
          defeq)) :
    PsKernelRecursorReductionConfigurationSound
      (psKernelReduceRecursorWith
        publicWhnf
        coreWhnf
        inferType
        defeq) := by
  intro
    context state nextState expr cheapRec cheapProj answer
    hConfig hSuccess
  have hQuotSound :=
    psKernelReduceQuotWith_configuration_sound
      publicWhnf
      hWhnf
  cases hQuot :
      psKernelReduceQuotWith
        publicWhnf
        context
        state
        expr with
  | error error =>
      simp [
        psKernelReduceRecursorWith,
        hQuot
      ] at hSuccess
  | ok quotient =>
      rcases quotient with
        ⟨quotientAnswer, quotientState⟩
      have hQuotSemantic :=
        hQuotSound
          context
          state
          quotientState
          expr
          quotientAnswer
          hConfig
          hQuot
      cases quotientAnswer with
      | some value =>
          simp [
            psKernelReduceRecursorWith,
            hQuot
          ] at hSuccess
          rcases hSuccess with ⟨rfl, rfl⟩
          exact hQuotSemantic
      | none =>
          have hInductiveRun :
              psKernelReduceInductiveRecWith
                  publicWhnf
                  coreWhnf
                  inferType
                  defeq
                  context
                  quotientState
                  expr
                  cheapRec
                  cheapProj =
                Except.ok
                  (Prod.mk answer nextState) := by
            simpa [
              psKernelReduceRecursorWith,
              hQuot
            ] using hSuccess
          exact
            hInductive
              context
              quotientState
              nextState
              expr
              cheapRec
              cheapProj
              answer
              hQuotSemantic.1
              hInductiveRun
