import Ps.KernelCore.Checker.Inference.Helpers

/-
Syntax-directed core inference.

This module implements inference for the pinned Lean 4.35 core expressions and
threads checker state through recursive calls. The public distinction between
"infer only" and fully checked inference is supplied as an explicit Boolean and
is cached separately.
-/

def psKernelInferCoreWithFuel
    [cachePolicy : PsKernelSemanticCachePolicy]
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
        psKernelInferCoreWithFuel remaining;
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
        let cached :=
          if
              psKernelInferCacheEligible
                inferOnly
                expr then
            psKernelSemanticCacheGet
              cache
              expr
          else
            Option.none;
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
                    let result :=
                      PsKernelExpr.sort
                        (PsKernelLevel.succ level);
                    Except.ok
                      (Prod.mk
                        result
                        (psKernelCacheInferResult
                          state
                          inferOnly
                          expr
                          result))
                | PsKernelExpr.const name levels =>
                    match
                        psKernelEnvironmentFind
                          nextContext.environment
                          name with
                    | Option.none =>
                        Except.error
                          "unknown constant"
                    | Option.some info =>
                        let params :=
                          psKernelConstantInfoLevelParams
                            info;
                        if
                            Nat.beq
                              (psKernelNameListLength params)
                              (psKernelLevelListLength levels) then
                          if inferOnly then
                            let result :=
                              psKernelExprInstantiateLevelParams
                                (psKernelConstantInfoType info)
                                params
                                levels;
                            Except.ok
                              (Prod.mk
                                result
                                (psKernelCacheInferResult
                                  state
                                  inferOnly
                                  expr
                                  result))
                          else if
                              psKernelConstantInfoIsUnsafe info then
                            if
                                psKernelDefinitionSafetyIsUnsafe
                                  nextContext.safety then
                              let result :=
                                psKernelExprInstantiateLevelParams
                                  (psKernelConstantInfoType info)
                                  params
                                  levels;
                              Except.ok
                                (Prod.mk
                                  result
                                  (psKernelCacheInferResult
                                    state
                                    inferOnly
                                    expr
                                    result))
                            else
                              Except.error
                                "safe declaration uses unsafe constant"
                          else if
                              psKernelConstantInfoIsPartial info then
                            if
                                psKernelDefinitionSafetyIsSafe
                                  nextContext.safety then
                              Except.error
                                "safe declaration uses partial constant"
                            else
                              let result :=
                                psKernelExprInstantiateLevelParams
                                  (psKernelConstantInfoType info)
                                  params
                                  levels;
                              Except.ok
                                (Prod.mk
                                  result
                                  (psKernelCacheInferResult
                                    state
                                    inferOnly
                                    expr
                                    result))
                          else
                            let result :=
                              psKernelExprInstantiateLevelParams
                                (psKernelConstantInfoType info)
                                params
                                levels;
                            Except.ok
                              (Prod.mk
                                result
                                (psKernelCacheInferResult
                                  state
                                  inferOnly
                                  expr
                                  result))
                        else
                          Except.error
                            "incorrect number of universe levels"
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
                        smaller
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
                    if inferOnly then
                      let args :=
                        psKernelExprGetAppArgs expr;
                      match
                          smaller
                            whnf
                            defeq
                            nextContext
                            state
                            (psKernelExprGetAppFn expr)
                            true with
                      | Except.error error =>
                          Except.error error
                      | Except.ok fnResult =>
                          match
                              psKernelInferAppOnlyLoopWithFuel
                                (Nat.succ
                                  (psKernelExprListLength args))
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
                      match
                          smaller
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
                                  smaller
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
                | PsKernelExpr.lam name domain body binderInfo =>
                    let checkedDomain :=
                      if inferOnly then
                        Except.ok
                          (Prod.mk
                            domain
                            state)
                      else
                        match
                            smaller
                              whnf
                              defeq
                              nextContext
                              state
                              domain
                              false with
                        | Except.error error =>
                            Except.error error
                        | Except.ok domainResult =>
                            match
                                psKernelEnsureSortWith
                                  whnf
                                  nextContext
                                  (Prod.snd domainResult)
                                  (Prod.fst domainResult) with
                            | Except.error error =>
                                Except.error error
                            | Except.ok sortResult =>
                                Except.ok
                                  (Prod.mk
                                    domain
                                    (Prod.snd sortResult));
                    match checkedDomain with
                    | Except.error error =>
                        Except.error error
                    | Except.ok domainState =>
                        let freshResult :=
                          psKernelCheckerStateFreshName
                            (Prod.snd domainState)
                            name;
                        let fresh :=
                          Prod.fst freshResult;
                        let state1 :=
                          Prod.snd freshResult;
                        let childLocal :=
                          psKernelLocalContextAddLocal
                            nextContext.localContext
                            fresh
                            name
                            domain
                            binderInfo;
                        let child :=
                          psKernelCheckerContextWithLocalContext
                            nextContext
                            childLocal;
                        let openedBody :=
                          psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar fresh);
                        match
                            smaller
                              whnf
                              defeq
                              child
                              state1
                              openedBody
                              inferOnly with
                        | Except.error error =>
                            Except.error error
                        | Except.ok bodyResult =>
                            -- Checked lambda inference establishes its codomain
                            -- sort by a real infer-only visit and sort exposure.
                            -- Infer-only callers retain their validity precondition.
                            let codomainCheck : Except String PsKernelCheckerState :=
                              if inferOnly then
                                Except.ok (Prod.snd bodyResult)
                              else
                                match
                                    smaller whnf defeq child
                                      (Prod.snd bodyResult)
                                      (Prod.fst bodyResult) true with
                                | Except.error error =>
                                    Except.error (psKernelLambdaCodomainSortFailure error)
                                | Except.ok typeResult =>
                                    match
                                        psKernelEnsureSortWith whnf child
                                          (Prod.snd typeResult) (Prod.fst typeResult) with
                                    | Except.error error =>
                                        Except.error (psKernelLambdaCodomainSortFailure error)
                                    | Except.ok sortResult =>
                                        Except.ok (Prod.snd sortResult);
                            match codomainCheck with
                            | Except.error error => Except.error error
                            | Except.ok codomainState =>
                                -- Return the recursively inferred type unchanged. Closing
                                -- fresh names is semantic transport; opportunistic beta
                                -- reduction here would need an additional soundness proof.
                                let bodyType :=
                                  Prod.fst bodyResult;
                                let closedBody :=
                                  psKernelExprAbstractFVars
                                    bodyType
                                    (List.cons
                                      fresh
                                      List.nil);
                                let result :=
                                  PsKernelExpr.forallE
                                    name
                                    domain
                                    closedBody
                                    binderInfo;
                                let scopedState :=
                                  psKernelCheckerStateExitLocalScope
                                    state1
                                    codomainState;
                                Except.ok
                                  (Prod.mk
                                    result
                                    (psKernelCacheInferResult
                                      scopedState
                                      inferOnly
                                      expr
                                      result))
                | PsKernelExpr.forallE name domain body binderInfo =>
                    match
                        smaller
                          whnf
                          defeq
                          nextContext
                          state
                          domain
                          inferOnly with
                    | Except.error error =>
                        Except.error error
                    | Except.ok domainResult =>
                        match
                            psKernelEnsureSortWith
                              whnf
                              nextContext
                              (Prod.snd domainResult)
                              (Prod.fst domainResult) with
                        | Except.error error =>
                            Except.error error
                        | Except.ok domainSort =>
                            let freshResult :=
                              psKernelCheckerStateFreshName
                                (Prod.snd domainSort)
                                name;
                            let fresh :=
                              Prod.fst freshResult;
                            let state1 :=
                              Prod.snd freshResult;
                            let childLocal :=
                              psKernelLocalContextAddLocal
                                nextContext.localContext
                                fresh
                                name
                                domain
                                binderInfo;
                            let child :=
                              psKernelCheckerContextWithLocalContext
                                nextContext
                                childLocal;
                            let openedBody :=
                              psKernelExprInstantiate1
                                body
                                (PsKernelExpr.fvar fresh);
                            match
                                smaller
                                  whnf
                                  defeq
                                  child
                                  state1
                                  openedBody
                                  inferOnly with
                            | Except.error error =>
                                Except.error error
                            | Except.ok bodyResult =>
                                match
                                    psKernelEnsureSortWith
                                      whnf
                                      child
                                      (Prod.snd bodyResult)
                                      (Prod.fst bodyResult) with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok bodySort =>
                                    let result :=
                                      PsKernelExpr.sort
                                        (psKernelLevelMkIMax
                                          (Prod.fst domainSort)
                                          (Prod.fst bodySort));
                                    let scopedState :=
                                      psKernelCheckerStateExitLocalScope
                                        state1
                                        (Prod.snd bodySort);
                                    Except.ok
                                      (Prod.mk
                                        result
                                        (psKernelCacheInferResult
                                          scopedState
                                          inferOnly
                                          expr
                                          result))
                | PsKernelExpr.letE name type value body nondep =>
                    let checked :=
                      if inferOnly then
                        Except.ok
                          (Prod.mk
                            type
                            state)
                      else
                        match
                            smaller
                              whnf
                              defeq
                              nextContext
                              state
                              type
                              false with
                        | Except.error error =>
                            Except.error error
                        | Except.ok typeResult =>
                            match
                                psKernelEnsureSortWith
                                  whnf
                                  nextContext
                                  (Prod.snd typeResult)
                                  (Prod.fst typeResult) with
                            | Except.error error =>
                                Except.error error
                            | Except.ok typeSort =>
                                match
                                    smaller
                                      whnf
                                      defeq
                                      nextContext
                                      (Prod.snd typeSort)
                                      value
                                      false with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok valueResult =>
                                    match
                                        defeq
                                          nextContext
                                          (Prod.snd valueResult)
                                          (Prod.fst valueResult)
                                          type with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok eqResult =>
                                        if Prod.fst eqResult then
                                          Except.ok
                                            (Prod.mk
                                              type
                                              (Prod.snd eqResult))
                                        else
                                          Except.error
                                            "let value type mismatch";
                    match checked with
                    | Except.error error =>
                        Except.error error
                    | Except.ok checkedResult =>
                        let freshResult :=
                          psKernelCheckerStateFreshName
                            (Prod.snd checkedResult)
                            name;
                        let fresh :=
                          Prod.fst freshResult;
                        let state1 :=
                          Prod.snd freshResult;
                        let childLocal :=
                          psKernelLocalContextAddLet
                            nextContext.localContext
                            fresh
                            name
                            type
                            value;
                        let child :=
                          psKernelCheckerContextWithLocalContext
                            nextContext
                            childLocal;
                        let openedBody :=
                          psKernelExprInstantiate1
                            body
                            (PsKernelExpr.fvar fresh);
                        match
                            smaller
                              whnf
                              defeq
                              child
                              state1
                              openedBody
                              inferOnly with
                        | Except.error error =>
                            Except.error error
                        | Except.ok bodyResult =>
                            let bodyType :=
                              psKernelExprCheapBetaReduce
                                (Prod.fst bodyResult);
                            let closedBody :=
                              psKernelExprAbstractFVars
                                bodyType
                                (List.cons
                                  fresh
                                  List.nil);
                            let result :=
                              if
                                  psKernelExprHasLooseBVarAt
                                    closedBody
                                    0 then
                                PsKernelExpr.letE
                                  name
                                  type
                                  value
                                  closedBody
                                  nondep
                              else
                                bodyType;
                            let scopedState :=
                              psKernelCheckerStateExitLocalScope
                                state1
                                (Prod.snd bodyResult);
                            Except.ok
                              (Prod.mk
                                result
                                (psKernelCacheInferResult
                                  scopedState
                                  inferOnly
                                  expr
                                  result))
                | PsKernelExpr.proj typeName index structValue =>
                    let inferType :=
                      fun
                        (projectionContext : PsKernelCheckerContext)
                        (projectionState : PsKernelCheckerState)
                        (projectionExpr : PsKernelExpr) =>
                        smaller
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
