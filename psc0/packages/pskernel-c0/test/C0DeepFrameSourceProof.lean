import Ps.KernelCore.Architecture.DeepInferenceFrames

/-!
These are the source properties genuinely discharged by the current
experimental code. Whole-machine step/fold equivalence and fuel-independent
logical soundness remain OPEN and are not asserted via sorry or an axiom.
-/

/-- Any receipt contains a proof of complete source successful checking,
    including the exact original full checker state and frame fuel. -/
theorem c0DeepSourceReceipt_sound
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (frame : PsKernelC0CheckedAppFrame)
    (ty : PsKernelExpr)
    (state : PsKernelCheckerState)
    (receipt : PsKernelC0DeepSourceReceipt
      whnf defeq context frame ty state) :
    psKernelC0CheckAppFrames whnf defeq context
      [frame] [] ty state = .ok receipt.result :=
  receipt.source

/-- The empty continuation is precisely the historical source case. -/
theorem c0DeepFrameEmpty_source
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context : PsKernelCheckerContext)
    (ranges : List Nat)
    (ty : PsKernelExpr)
    (state : PsKernelCheckerState) :
    psKernelC0DeepFrameFold whnf defeq context [] ranges ty state =
      psKernelC0CheckAppFrames whnf defeq context [] ranges ty state := by
  rfl

#check psKernelC0DeepSourceCheckOne
#check c0DeepSourceReceipt_sound
#check c0DeepFrameEmpty_source
