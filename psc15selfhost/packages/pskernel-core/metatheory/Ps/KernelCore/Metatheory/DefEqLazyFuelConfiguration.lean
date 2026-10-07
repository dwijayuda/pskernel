import Ps.KernelCore.Metatheory.DefEqLazyContinuation
import Ps.KernelCore.Metatheory.PrimitiveNatReduction

/-
Reusable fuel-driven LazyDelta proof infrastructure.

The executable fast Nat-reduction stage is intentionally optional:
an eager comparison invokes the independently proved primitive reducer,
whereas a non-eager comparison returns an unchanged configuration and an
undecided reduction. Both branches refine the same semantic postcondition.
-/

theorem psKernelLazyOptionalNat_configuration_sound
    (eager : Bool)
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState))
    (hWhnf : PsKernelWhnfConfigurationSound whnf)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (answer : Option PsKernelExpr)
    (hConfig : PsKernelCheckerConfigurationSound context state)
    (hRun :
      (if eager then
         psKernelReduceNatWith whnf context state expr
       else
         Except.ok (Prod.mk Option.none state)) =
        Except.ok (Prod.mk answer nextState)) :
    PsKernelOptionalReductionPostcondition
      context nextState expr answer := by
  cases eager with
  | false =>
      simp at hRun
      rcases hRun with ⟨rfl, rfl⟩
      exact ⟨hConfig, trivial⟩
  | true =>
      exact
        psKernelReduceNatWith_configuration_sound
          whnf hWhnf
          context state nextState expr answer
          hConfig
          (by simpa using hRun)
