import Ps.KernelCore.Checker.Inference.Binder

/-!
Complete Lean-4.35-compatible source application inference rules.

This branch was extracted mechanically from the C0 inference source.
It retains the original infer-only argument-spine exposure algorithm,
checked argument/domain/full DefEq and eagerReduce behavior, error
precedence, source fuel/recursion, and long checked-application hook.
The source worker and any future qualified accepting app-head executor
must call this exact same implementation; neither can treat an
infer-only exposed type as a checked proof.
-/

abbrev PsKernelC0CheckedAppHook :=
  Nat ->
  (PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr ->
    Except String (Prod PsKernelExpr PsKernelCheckerState)) ->
  (PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr ->
    PsKernelExpr -> Except String (Prod Bool PsKernelCheckerState)) ->
  PsKernelCheckerContext -> PsKernelCheckerState -> PsKernelExpr ->
  Except String (Prod PsKernelExpr PsKernelCheckerState)

/-- The exact original source app-head inference and checking decision.
    The recursive smaller callback is source owned. Long checked spines
    may use the already-qualified source checked-app hook; short checked
    applications and infer-only app spines preserve their original workers.
    This operation does NOT admit declarations or unchecked proof terms. -/
def psKernelInferAppHead
    (smaller : PsKernelC0BinderSmaller)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (remaining : Nat)
    (whnf : PsKernelC0BinderWhnf)
    (defeq : PsKernelC0BinderDefEq)
    (context nextContext : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (fn arg : PsKernelExpr)
    (inferOnly : Bool) :
    Except String (PsKernelExpr × PsKernelCheckerState) :=
  let expr : PsKernelExpr := .app fn arg
  if inferOnly then
    -- Collect the canonical head and ordered arguments in
    -- one spine traversal; the length is used by both the
    -- budget and the infer-only exposure worker.
    let spine :=
      psKernelExprGetAppFnArgs expr;
    let args := spine.snd;
    let argCount := psKernelExprListLength args;
    match
        smaller [] []
          whnf
          defeq
          nextContext
          state
          spine.fst
          true with
    | Except.error error =>
        Except.error error
    | Except.ok fnResult =>
        match
            psKernelInferAppOnlyLoopWithFuelCount
              (Nat.succ argCount)
              argCount
              whnf
              nextContext
              (Prod.snd fnResult)
              args
              0
              0
              (Prod.fst fnResult) with
        | Except.error error =>
            Except.error error
        | Except.ok appResult =>
            Except.ok
              (Prod.mk
                (Prod.fst appResult)
                (psKernelCacheInferResult
                  (Prod.snd appResult)
                  true
                  expr
                  (Prod.fst appResult)))
  else
    -- Preserve the original checked branch as a suspended
    -- pure computation; never evaluate it before invoking
    -- the optimized route. This is the independent fallback
    -- for shorter checked applications and hook-free calls.
    let originalChecked : Unit -> Except String
        (Prod PsKernelExpr PsKernelCheckerState) :=
      fun _ =>
        match
            smaller [] []
              whnf
              defeq
              nextContext
              state
              fn
              false with
        | Except.error error =>
            Except.error error
        | Except.ok fnResult =>
            match
                psKernelEnsureForallWith
                  whnf
                  nextContext
                  (Prod.snd fnResult)
                  (Prod.fst fnResult) with
            | Except.error error =>
                Except.error error
            | Except.ok forallResult =>
                let view :=
                  Prod.fst forallResult;
                let state2 :=
                  Prod.snd forallResult;
                match
                    smaller [] []
                      whnf
                      defeq
                      nextContext
                      state2
                      arg
                      false with
                | Except.error error =>
                    Except.error error
                | Except.ok argResult =>
                    let argType :=
                      Prod.fst argResult;
                    if
                        psKernelExprEq
                          argType
                          view.domain then
                      let result :=
                        psKernelExprInstantiate1
                          view.body
                          arg;
                      Except.ok
                        (Prod.mk
                          result
                          (psKernelCacheInferResult
                            (Prod.snd argResult)
                            false
                            expr
                            result))
                    else
                      let eqContext :=
                        if
                            psKernelExprIsEagerReduce
                              arg then
                          psKernelCheckerContextWithEagerReduce
                            nextContext
                            true
                        else
                          nextContext;
                      match
                          defeq
                            eqContext
                            (Prod.snd argResult)
                            argType
                            view.domain with
                      | Except.error error =>
                          Except.error error
                      | Except.ok eqResult =>
                          if Prod.fst eqResult then
                            let result :=
                              psKernelExprInstantiate1
                                view.body
                                arg;
                            Except.ok
                              (Prod.mk
                                result
                                (psKernelCacheInferResult
                                  (Prod.snd eqResult)
                                  false
                                  expr
                                  result))
                          else
                            Except.error
                              "application type mismatch"
    match onCheckedApp with
    | none => originalChecked ()
    | some checkedApp =>
        if psKernelExprGetAppNumArgs expr >= 16 then
          checkedApp (Nat.succ remaining)
            whnf defeq context state expr
        else
          originalChecked ()
