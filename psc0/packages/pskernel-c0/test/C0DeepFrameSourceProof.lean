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
  let ctx : PsKernelCheckerContext :=
    { context with recDepth := frame.recDepth }
  cases hview : psKernelEnsureForallWith whnf ctx state ty with
  | error message =>
      simp [psKernelC0CheckAppFrames, psKernelC0DeepFrameStep, ctx, hview]
  | ok pair =>
      obtain ⟨view, state1⟩ := pair
      cases harg : psKernelInferCoreWithFuel frame.fuel whnf defeq
          ctx state1 frame.argument false with
      | error message =>
          simp [psKernelC0CheckAppFrames, psKernelC0DeepFrameStep,
            ctx, hview, harg]
      | ok pair =>
          obtain ⟨argType, state2⟩ := pair
          by_cases heq : psKernelExprEq argType view.domain = true
          · simp [psKernelC0CheckAppFrames, psKernelC0DeepFrameStep,
              ctx, hview, harg, heq]
          · let eqCtx : PsKernelCheckerContext :=
              if psKernelExprIsEagerReduce frame.argument then
                psKernelCheckerContextWithEagerReduce ctx true
              else ctx
            cases hdefeq : defeq eqCtx state2 argType view.domain with
            | error message =>
                simp [psKernelC0CheckAppFrames, psKernelC0DeepFrameStep,
                  ctx, eqCtx, hview, harg, heq, hdefeq]
            | ok pair =>
                obtain ⟨answer, state3⟩ := pair
                cases answer with
                | true =>
                    simp [psKernelC0CheckAppFrames, psKernelC0DeepFrameStep,
                      ctx, eqCtx, hview, harg, heq, hdefeq]
                | false =>
                    simp [psKernelC0CheckAppFrames, psKernelC0DeepFrameStep,
                      ctx, eqCtx, hview, harg, heq, hdefeq]
