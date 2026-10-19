import Ps.KernelCore.Architecture.DeepInferenceFrames

/-! Research-only source equation for one explicit checked application frame.
Unlike input-specific test fixtures, this quantifies over arbitrary checker
contexts, states, WHNF and DefEq callbacks and source frame fuel/depth.
The published checker is unchanged until this proof and its fold induction
and genuine non-acceptance safety boundaries are qualified. -/

theorem c0DeepStep_source
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (frame : PsKernelC0CheckedAppFrame)
    (tail : List PsKernelC0CheckedAppFrame)
    (ranges : List Nat)
    (ty : PsKernelExpr)
    (state : PsKernelCheckerState) :
    psKernelC0CheckAppFrames whnf defeq context
        (frame :: tail) ranges ty state =
      (do
        let next ← psKernelC0DeepFrameStep whnf defeq context
          { current := ty, checker := state, bodyRanges := ranges } frame
        psKernelC0CheckAppFrames whnf defeq context tail
          next.bodyRanges next.current next.checker) := by
  simp only [psKernelC0CheckAppFrames, psKernelC0DeepFrameStep]
  split <;> simp_all [Except.bind, Except.map, bind_assoc]
