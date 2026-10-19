import Ps.KernelCore.Architecture.DeepInferenceFrames

/-! Small native compile-time acceptance guards for the non-admitting
    application continuation machine. Real checker equivalence/throughput
    remains a separate required external-oracle gate. -/

example
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (ty : PsKernelExpr)
    (state : PsKernelCheckerState) :
    psKernelC0DeepFrameFold whnf defeq context [] [] ty state =
      .ok (ty, state) := by
  rfl

example
    (fn arg : PsKernelExpr)
    (context : PsKernelCheckerContext) :
    psKernelC0CollectCheckedAppPath (.app fn arg) 0 context [] =
      .error "kernel inference budget exhausted" :=
  psKernelC0DeepZeroFuel fn arg context

example
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr) :
    psKernelC0DeepAppSpineWithFuel 0 whnf defeq context state (.app fn arg) =
      .error "kernel inference budget exhausted" := by
  rfl

#check psKernelC0DeepFrameStep
#check psKernelC0DeepFrameFold
#check psKernelC0DeepAppSpineWithFuel
