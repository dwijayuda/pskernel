import Ps.KernelCore.Architecture.DeepMixedWorklist

/-!
The mixed evaluator is research-only. These executable Lean source guards
make no claim that the evaluator can admit a theorem or reset a source fuel
budget. Its complete logical preservation proof remains mandatory before
any production routing.
-/

/-- An incoming source fuel of zero fails before any transition or cached
    result can be used to create a checked judgment. -/
theorem c0DeepMixedZeroFuel
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (ctx : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    psKernelC0DeepMixedStep whnf defeq
      (psKernelC0DeepMixedStart 0 ctx state expr) =
      .error "kernel inference budget exhausted" := by
  rfl

/-- Merely having a completed diagnostic state adds no new checking step. -/
example
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (ty : PsKernelExpr)
    (state : PsKernelCheckerState)
    (pending : List PsKernelC0DeepMixedFrame) :
    psKernelC0DeepMixedStep whnf defeq
      ⟨.finished ty state, pending⟩ =
      .ok ⟨.finished ty state, pending⟩ :=
  psKernelC0DeepMixedFinishedStable whnf defeq ty state pending

#check psKernelC0DeepLambdaResumeCheckedDomain
#check psKernelC0DeepLambdaPrepareDeferred
#check psKernelC0DeepSubstForcePush
#check psKernelC0DeepDeferBinderOpening_source
#check psKernelC0DeepMixedStep
#check psKernelC0DeepMixedRunDiagnostic

/-- No substituted body is needed for source lambda closing. This is the
    exact source equality for every body type and complete checker state. -/
example
    (frame : PsKernelC0DeepDeferredLambdaFrame)
    (bodyType : PsKernelExpr)
    (bodyState : PsKernelCheckerState) :
    psKernelC0DeepLambdaCloseDeferred frame bodyType bodyState =
      psKernelC0DeepLambdaClose
        (psKernelC0DeepLambdaForceFrame frame) bodyType bodyState :=
  psKernelC0DeepLambdaCloseDeferred_source frame bodyType bodyState
