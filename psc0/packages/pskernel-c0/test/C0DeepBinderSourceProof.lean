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
  unfold psKernelC0DeepLambdaSplit psKernelC0DeepLambdaPrepare
  unfold psKernelInferLambdaHead
  cases hdom : smaller [] [] whnf defeq ctx state domain false with
  | error reason =>
      simp [hdom, Except.bind, Except.map]
  | ok domainResult =>
      cases domainResult with
      | mk domainType domainState =>
          cases hsort : psKernelEnsureSortWith whnf ctx domainState domainType with
          | error reason =>
              simp [hdom, hsort, Except.bind, Except.map]
          | ok sortResult =>
              cases sortResult with
              | mk sortLevel sortState =>
                  cases ranges with
                  | nil =>
                      simp [hdom, hsort, psKernelC0DeepLambdaClose,
                        Except.bind, Except.map]
                  | cons range tail =>
                      by_cases hr : range = 0
                      · simp [hdom, hsort, hr, psKernelC0DeepLambdaClose,
                          Except.bind, Except.map]
                      · simp [hdom, hsort, hr, psKernelC0DeepLambdaClose,
                          Except.bind, Except.map]

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


/-- Fully checked, scoped deferred preparation is observationally the
    original eager checked preparation after forcing its body once.
    This equality includes error strings, fresh-name state, local context,
    captured binder information and remaining binder-range metadata. -/
theorem c0DeepDeferredLambdaPrepare_source
    (smaller : PsKernelC0BinderSmaller)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (ctx : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (name : PsKernelName)
    (domain body : PsKernelExpr)
    (info : PsKernelBinderInfo)
    (ranges : List Nat) :
    (psKernelC0DeepLambdaPrepareDeferred smaller whnf defeq
      ctx state name domain body info ranges).map
        psKernelC0DeepLambdaForceFrame =
    psKernelC0DeepLambdaPrepare smaller whnf defeq
      ctx state name domain body info ranges := by
  unfold psKernelC0DeepLambdaPrepareDeferred psKernelC0DeepLambdaPrepare
  cases hdom : smaller [] [] whnf defeq ctx state domain false with
  | error reason =>
      simp [hdom, Except.map, Except.bind]
  | ok dom =>
      cases hsort : psKernelEnsureSortWith whnf ctx dom.2 dom.1 with
      | error reason =>
          simp [hdom, hsort, Except.map, Except.bind]
      | ok sortResult =>
          cases ranges with
          | nil =>
              simp [hdom, hsort, Except.map, Except.bind,
                psKernelC0DeepLambdaResumeCheckedDomain,
                psKernelC0DeepLambdaForceFrame,
                psKernelC0DeepSubstForceOneSource]
          | cons range tail =>
              by_cases hr : range = 0
              · simp [hdom, hsort, hr, Except.map, Except.bind,
                  psKernelC0DeepLambdaResumeCheckedDomain,
                  psKernelC0DeepLambdaForceFrame,
                  psKernelC0DeepSubstForcePure]
              · simp [hdom, hsort, hr, Except.map, Except.bind,
                  psKernelC0DeepLambdaResumeCheckedDomain,
                  psKernelC0DeepLambdaForceFrame,
                  psKernelC0DeepSubstForceOneSource]
