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

/-- One explicit frame makes exactly the same result/error/state transition
    as one historical recursive application continuation. The proof does
    not assume a particular WHNF, DefEq or checker state. -/
theorem c0DeepFrameStepIsSource
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (frame : PsKernelC0CheckedAppFrame)
    (rest : List PsKernelC0CheckedAppFrame)
    (ranges : List Nat)
    (ty : PsKernelExpr)
    (state : PsKernelCheckerState) :
    psKernelC0CheckAppFrames whnf defeq context
        (frame :: rest) ranges ty state =
      (do
        let next ← psKernelC0DeepFrameStep whnf defeq context
          { current := ty, checker := state, bodyRanges := ranges } frame
        psKernelC0CheckAppFrames whnf defeq context rest
          next.bodyRanges next.current next.checker) := by
  simp [psKernelC0CheckAppFrames, psKernelC0DeepFrameStep, Except.bind, Except.map] <;> grind
