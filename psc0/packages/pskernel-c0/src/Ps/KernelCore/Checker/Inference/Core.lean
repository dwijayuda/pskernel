import Ps.KernelCore.Checker.Inference.Let

/-
Syntax-directed core inference.

This module implements the Lean 4.34 inference cases for core expressions and
threads checker state through recursive calls. The public distinction between
"infer only" and fully checked inference is supplied as an explicit Boolean and
is cached separately.
-/

/-- Source-owned checked application route. A hook receives the original
    fuel and context and may only replace a checked application judgment.
    The default absent hook is the independent historical recursive worker.
    Infer-only judgments never call this hook. -/

def psKernelInferCoreWithFuelUsingSourceFrames
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook)
    (letFrames : List (Prod Nat Nat))
    (binderRanges : List Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_expr : PsKernelExpr)
        (_inferOnly : Bool) =>
        Except.error
          "kernel inference budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelInferCoreWithFuelUsingSourceFrames remaining onCheckedApp;
      fun
        (whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (expr : PsKernelExpr)
        (inferOnly : Bool) =>
        let cache :=
          if inferOnly then
            state.inferOnly
          else
            state.checkedInfer;
        -- Only checked inference with an installed callback may carry
        -- immutable source summaries through a consecutive let suffix.
        -- The hook-free historical oracle retains its original behavior.
        let currentFrames :=
          psKernelInferCurrentLetFrames expr onCheckedApp letFrames
        -- Exact syntactic binder ranges are already used by the DefEq
        -- spine worker. Fully checked inference can reuse those *read-only*
        -- ranges to avoid repeated no-op substitutions under closed bodies.
        -- The historical hook-free worker remains untouched.
        let currentBinderRanges :=
          psKernelInferCurrentBinderRanges expr onCheckedApp binderRanges
        let currentHash :=
          match currentFrames with
          | (_, hash) :: _ => some hash
          | [] => none;
        let cached :=
          if psKernelInferCacheEligible inferOnly expr then
            psKernelExprMapGetWithKnownHash cache expr currentHash
          else Option.none;
        match cached with
        | Option.some cached =>
            match
                psKernelCheckerContextEnterRecDepth
                  context with
            | Except.error error =>
                Except.error error
            | Except.ok _ =>
                Except.ok
                  (Prod.mk cached state)
        | Option.none =>
            match
                psKernelCheckerContextEnterRecDepth
                  context with
            | Except.error error =>
                Except.error error
            | Except.ok nextContext =>
                match expr with
                | PsKernelExpr.bvar _ =>
                    Except.error
                      "loose bound variable in type checker"
                | PsKernelExpr.mvar _ =>
                    Except.error
                      "kernel type checker does not support metavariables"
                | PsKernelExpr.fvar name =>
                    match
                        psKernelLocalContextFind
                          nextContext.localContext
                          name with
                    | Option.none =>
                        Except.error
                          "unknown free variable"
                    | Option.some declaration =>
                        let result :=
                          psKernelLocalDeclType
                            declaration;
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              state
                              inferOnly
                              expr
                              result))
                | PsKernelExpr.sort level =>
                    -- Lean 4.35 infer_type_core checks universe
                    -- parameter membership only on the fully checked
                    -- route. Infer-only intentionally does not reject
                    -- undeclared universe names.
                    if !inferOnly &&
                        (psKernelFindUndefLevelParam
                          level nextContext.levelParams).isSome then
                      Except.error
                        "invalid reference to undefined universe level parameter"
                    else
                      let result :=
                        PsKernelExpr.sort (PsKernelLevel.succ level)
                      Except.ok
                        (Prod.mk
                          result
                          (psKernelCacheInferResult
                            state inferOnly expr result))
                | PsKernelExpr.const name levels =>
                    psKernelInferConstantHead nextContext state
                      name levels inferOnly
                | PsKernelExpr.lit literal =>
                    match literal with
                    | PsKernelLiteral.nat value =>
                        match
                            psKernelCheckNatSize
                              nextContext.maxNatSize
                              value with
                        | Except.error error =>
                            Except.error error
                        | Except.ok _ =>
                            let result :=
                              PsKernelExpr.const
                                psKernelNatName
                                List.nil;
                            Except.ok
                              (Prod.mk
                                result
                                (psKernelCacheInferResult
                                  state
                                  inferOnly
                                  expr
                                  result))
                    | PsKernelLiteral.str _ =>
                        let result :=
                          PsKernelExpr.const
                            psKernelStringName
                            List.nil;
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              state
                              inferOnly
                              expr
                              result))
                | PsKernelExpr.mdata _ body =>
                    match
                        smaller [] []
                          whnf
                          defeq
                          nextContext
                          state
                          body
                          inferOnly with
                    | Except.error error =>
                        Except.error error
                    | Except.ok result =>
                        Except.ok
                          (Prod.mk
                            (Prod.fst result)
                            (psKernelCacheInferResult
                              (Prod.snd result)
                              inferOnly
                              expr
                              (Prod.fst result)))
                | PsKernelExpr.app fn arg =>
                    psKernelInferAppHead smaller onCheckedApp remaining
                      whnf defeq context nextContext state fn arg inferOnly
                | PsKernelExpr.lam name domain body binderInfo =>
                    psKernelInferLambdaHead smaller whnf defeq
                      nextContext state name domain body binderInfo
                      inferOnly currentBinderRanges
                | PsKernelExpr.forallE name domain body binderInfo =>
                    psKernelInferForallHead smaller whnf defeq
                      nextContext state name domain body binderInfo
                      inferOnly currentBinderRanges
                | PsKernelExpr.letE name type value body nondep =>
                    psKernelInferLetHead smaller whnf defeq
                      nextContext state name type value body nondep
                      inferOnly currentFrames currentHash
                | PsKernelExpr.proj typeName index structValue =>
                    let inferType :=
                      fun
                        (projectionContext : PsKernelCheckerContext)
                        (projectionState : PsKernelCheckerState)
                        (projectionExpr : PsKernelExpr) =>
                        smaller [] []
                          whnf
                          defeq
                          projectionContext
                          projectionState
                          projectionExpr
                          inferOnly;
                    match
                        psKernelInferProjectionWith
                          whnf
                          inferType
                          nextContext
                          state
                          typeName
                          index
                          structValue with
                    | Except.error error =>
                        Except.error error
                    | Except.ok projectionResult =>
                        let result :=
                          Prod.fst projectionResult;
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              (Prod.snd projectionResult)
                              inferOnly
                              expr
                              result))


/-- The same recursive typing rules, with optional operation-local exact
    let ranges and precomputed source cache hashes. -/
def psKernelInferCoreWithFuelUsing
    (fuel : Nat)
    (onCheckedApp : Option PsKernelC0CheckedAppHook) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelInferCoreWithFuelUsingSourceFrames fuel onCheckedApp [] []

/-- Historical independent inference semantics, retained for all callers
    without a checked-application hook and as the negative/fuel oracle. -/
def psKernelInferCoreWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  psKernelInferCoreWithFuelUsing fuel none
