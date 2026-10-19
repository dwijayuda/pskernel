import Ps.KernelCore.Architecture.DeepBinderFrames

/-! Complete checked lambda stage-refinement test.
All callbacks/starting states, binder offsets and failure branches are
quantified; no axiom, sorry or special Arena term case is allowed. -/

/-- Source-level operation equality including error and final full checker
state. A success does not override the old 4096-fuel resource semantics. -/
theorem c0DeepLambdaSplit_source
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (ctx : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo)
    (ranges : List Nat) :
    psKernelC0DeepLambdaSplit smaller whnf defeq
      ctx state name domain body info ranges =
    psKernelInferLambdaHead smaller whnf defeq
      ctx state name domain body info false ranges := by
  rfl

example
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (ctx : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo)
    (ranges : List Nat)
    (receipt : PsKernelC0DeepLambdaReceipt
      smaller whnf defeq ctx state name domain body info ranges) :
    psKernelInferLambdaHead smaller whnf defeq
      ctx state name domain body info false ranges = .ok receipt.result :=
  receipt.source

#check c0DeepLambdaSplit_source
#check psKernelC0DeepLambdaPrepare
#check psKernelC0DeepLambdaClose
