import Ps.KernelCore.Checker.Inference.Helpers

/-
Syntax-directed core inference.

This module implements the Lean 4.34 inference cases for core expressions and
threads checker state through recursive calls. The public distinction between
"infer only" and fully checked inference is supplied as an explicit Boolean and
is cached separately.
-/

def psKernelInferenceFoldIMax
    (levels : List PsKernelLevel)
    (result : PsKernelLevel) : PsKernelLevel :=
  match levels with
  | List.nil => result
  | List.cons level rest =>
      psKernelLevelMkIMax
        level
        (psKernelInferenceFoldIMax rest result)

def psKernelInferLambdaSpineWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    List PsKernelExpr ->
    List PsKernelCheckerCloseBinder ->
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun _ _ _ _ _ _ _ _ =>
        Except.error "kernel inference lambda-spine budget exhausted"
  | Nat.succ remaining =>
      let smaller := psKernelInferLambdaSpineWithFuel remaining
      fun inferCore whnf context state current inferOnly fvars binders =>
        match current with
        | PsKernelExpr.lam name domain body binderInfo =>
            let openedDomain :=
              psKernelExprInstantiateRev domain fvars
            let checkedState :
                Except String PsKernelCheckerState :=
              if inferOnly then
                Except.ok state
              else
                match
                    inferCore
                      context
                      state
                      openedDomain
                      false with
                | Except.error error =>
                    Except.error error
                | Except.ok domainResult =>
                    match
                        psKernelEnsureSortWith
                          whnf
                          context
                          (Prod.snd domainResult)
                          (Prod.fst domainResult) with
                    | Except.error error =>
                        Except.error error
                    | Except.ok sortResult =>
                        Except.ok (Prod.snd sortResult)
            match checkedState with
            | Except.error error =>
                Except.error error
            | Except.ok state1 =>
                let freshResult :=
                  psKernelCheckerStateFreshName state1 name
                let fresh := Prod.fst freshResult
                let state2 := Prod.snd freshResult
                let childLocal :=
                  psKernelLocalContextAddLocal
                    context.localContext
                    fresh
                    name
                    openedDomain
                    binderInfo
                let child :=
                  psKernelCheckerContextWithLocalContext
                    context
                    childLocal
                let binder : PsKernelCheckerCloseBinder := {
                  internalName := fresh
                  userName := name
                  type := openedDomain
                  binderInfo := binderInfo
                  value := Option.none
                  nondep := false
                }
                match
                    smaller
                      inferCore
                      whnf
                      child
                      state2
                      body
                      inferOnly
                      (List.append
                        fvars
                        (List.cons
                          (PsKernelExpr.fvar fresh)
                          List.nil))
                      (List.append
                        binders
                        (List.cons binder List.nil)) with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.mk
                        (Prod.fst result)
                        (psKernelCheckerStateExitLocalScope
                          state2
                          (Prod.snd result)))
        | tail =>
            let openedTail :=
              psKernelExprInstantiateRev tail fvars
            match
                inferCore
                  context
                  state
                  openedTail
                  inferOnly with
            | Except.error error =>
                Except.error error
            | Except.ok tailResult =>
                let result :=
                  psKernelCloseCheckerBinders
                    binders
                    (psKernelExprCheapBetaReduce
                      (Prod.fst tailResult))
                    false
                Except.ok
                  (Prod.mk result (Prod.snd tailResult))

def psKernelInferForallSpineWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    List PsKernelExpr ->
    List PsKernelLevel ->
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun _ _ _ _ _ _ _ _ =>
        Except.error "kernel inference forall-spine budget exhausted"
  | Nat.succ remaining =>
      let smaller := psKernelInferForallSpineWithFuel remaining
      fun inferCore whnf context state current inferOnly fvars levels =>
        match current with
        | PsKernelExpr.forallE name domain body binderInfo =>
            let openedDomain :=
              psKernelExprInstantiateRev domain fvars
            match
                inferCore
                  context
                  state
                  openedDomain
                  inferOnly with
            | Except.error error =>
                Except.error error
            | Except.ok domainResult =>
                match
                    psKernelEnsureSortWith
                      whnf
                      context
                      (Prod.snd domainResult)
                      (Prod.fst domainResult) with
                | Except.error error =>
                    Except.error error
                | Except.ok domainSort =>
                    let freshResult :=
                      psKernelCheckerStateFreshName
                        (Prod.snd domainSort)
                        name
                    let fresh := Prod.fst freshResult
                    let state1 := Prod.snd freshResult
                    let childLocal :=
                      psKernelLocalContextAddLocal
                        context.localContext
                        fresh
                        name
                        openedDomain
                        binderInfo
                    let child :=
                      psKernelCheckerContextWithLocalContext
                        context
                        childLocal
                    match
                        smaller
                          inferCore
                          whnf
                          child
                          state1
                          body
                          inferOnly
                          (List.append
                            fvars
                            (List.cons
                              (PsKernelExpr.fvar fresh)
                              List.nil))
                          (List.append
                            levels
                            (List.cons
                              (Prod.fst domainSort)
                              List.nil)) with
                    | Except.error error =>
                        Except.error error
                    | Except.ok result =>
                        Except.ok
                          (Prod.mk
                            (Prod.fst result)
                            (psKernelCheckerStateExitLocalScope
                              state1
                              (Prod.snd result)))
        | tail =>
            let openedTail :=
              psKernelExprInstantiateRev tail fvars
            match
                inferCore
                  context
                  state
                  openedTail
                  inferOnly with
            | Except.error error =>
                Except.error error
            | Except.ok tailResult =>
                match
                    psKernelEnsureSortWith
                      whnf
                      context
                      (Prod.snd tailResult)
                      (Prod.fst tailResult) with
                | Except.error error =>
                    Except.error error
                | Except.ok resultSort =>
                    Except.ok
                      (Prod.mk
                        (PsKernelExpr.sort
                          (psKernelInferenceFoldIMax
                            levels
                            (Prod.fst resultSort)))
                        (Prod.snd resultSort))

def psKernelInferLetSpineWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    Bool ->
    List PsKernelExpr ->
    List PsKernelCheckerCloseBinder ->
    Except String (Prod PsKernelExpr PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun _ _ _ _ _ _ _ _ _ =>
        Except.error "kernel inference let-spine budget exhausted"
  | Nat.succ remaining =>
      let smaller := psKernelInferLetSpineWithFuel remaining
      fun inferCore whnf defeq context state current inferOnly fvars binders =>
        match current with
        | PsKernelExpr.letE name type value body nondep =>
            let openedType :=
              psKernelExprInstantiateRev type fvars
            let openedValue :=
              psKernelExprInstantiateRev value fvars
            let checkedState :
                Except String PsKernelCheckerState :=
              if inferOnly then
                Except.ok state
              else
                match
                    inferCore
                      context
                      state
                      openedType
                      false with
                | Except.error error =>
                    Except.error error
                | Except.ok typeResult =>
                    match
                        psKernelEnsureSortWith
                          whnf
                          context
                          (Prod.snd typeResult)
                          (Prod.fst typeResult) with
                    | Except.error error =>
                        Except.error error
                    | Except.ok typeSort =>
                        match
                            inferCore
                              context
                              (Prod.snd typeSort)
                              openedValue
                              false with
                        | Except.error error =>
                            Except.error error
                        | Except.ok valueResult =>
                            match
                                defeq
                                  context
                                  (Prod.snd valueResult)
                                  (Prod.fst valueResult)
                                  openedType with
                            | Except.error error =>
                                Except.error error
                            | Except.ok equal =>
                                if Prod.fst equal then
                                  Except.ok (Prod.snd equal)
                                else
                                  Except.error
                                    "let value type mismatch"
            match checkedState with
            | Except.error error =>
                Except.error error
            | Except.ok state1 =>
                let freshResult :=
                  psKernelCheckerStateFreshName state1 name
                let fresh := Prod.fst freshResult
                let state2 := Prod.snd freshResult
                let childLocal :=
                  psKernelLocalContextAddLet
                    context.localContext
                    fresh
                    name
                    openedType
                    openedValue
                let child :=
                  psKernelCheckerContextWithLocalContext
                    context
                    childLocal
                let binder : PsKernelCheckerCloseBinder := {
                  internalName := fresh
                  userName := name
                  type := openedType
                  binderInfo := PsKernelBinderInfo.default
                  value := Option.some openedValue
                  nondep := nondep
                }
                match
                    smaller
                      inferCore
                      whnf
                      defeq
                      child
                      state2
                      body
                      inferOnly
                      (List.append
                        fvars
                        (List.cons
                          (PsKernelExpr.fvar fresh)
                          List.nil))
                      (List.append
                        binders
                        (List.cons binder List.nil)) with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.mk
                        (Prod.fst result)
                        (psKernelCheckerStateExitLocalScope
                          state2
                          (Prod.snd result)))
        | tail =>
            let openedTail :=
              psKernelExprInstantiateRev tail fvars
            match
                inferCore
                  context
                  state
                  openedTail
                  inferOnly with
            | Except.error error =>
                Except.error error
            | Except.ok tailResult =>
                let result :=
                  psKernelCloseCheckerBinders
                    binders
                    (psKernelExprCheapBetaReduce
                      (Prod.fst tailResult))
                    true
                Except.ok
                  (Prod.mk result (Prod.snd tailResult))

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
            psKernelExprMapGet
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
                                          match
                                              whnf
                                                eqContext
                                                (Prod.snd eqResult)
                                                view.domain with
                                          | Except.error _ =>
                                              Except.error
                                                ("application type mismatch; fn=" ++
                                                  psKernelInferenceDebugExprHead fn ++
                                                  "; arg=" ++
                                                  psKernelInferenceDebugExprHead arg ++
                                                  "; expected=" ++
                                                  psKernelInferenceDebugExprHead view.domain ++
                                                  "; actual=" ++
                                                  psKernelInferenceDebugExprHead argType ++
                                                  "; diff=" ++
                                                  psKernelInferenceDebugExprDiff
                                                    view.domain
                                                    argType)
                                          | Except.ok expectedWhnf =>
                                              match
                                                  whnf
                                                    eqContext
                                                    (Prod.snd expectedWhnf)
                                                    argType with
                                              | Except.error _ =>
                                                  Except.error
                                                    ("application type mismatch; fn=" ++
                                                      psKernelInferenceDebugExprHead fn ++
                                                      "; arg=" ++
                                                      psKernelInferenceDebugExprHead arg ++
                                                      "; expected=" ++
                                                      psKernelInferenceDebugExprHead view.domain ++
                                                      "; actual=" ++
                                                      psKernelInferenceDebugExprHead argType ++
                                                      "; diff=" ++
                                                      psKernelInferenceDebugExprDiff
                                                        view.domain
                                                        argType)
                                              | Except.ok actualWhnf =>
                                                  Except.error
                                                    ("application type mismatch; fn=" ++
                                                      psKernelInferenceDebugExprHead fn ++
                                                      "; arg=" ++
                                                      psKernelInferenceDebugExprHead arg ++
                                                      "; expected=" ++
                                                      psKernelInferenceDebugExprHead view.domain ++
                                                      "; actual=" ++
                                                      psKernelInferenceDebugExprHead argType ++
                                                      "; diff=" ++
                                                      psKernelInferenceDebugExprDiff
                                                        view.domain
                                                        argType ++
                                                      "; whnf-expected=" ++
                                                      psKernelInferenceDebugExprHead
                                                        (Prod.fst expectedWhnf) ++
                                                      "; whnf-actual=" ++
                                                      psKernelInferenceDebugExprHead
                                                        (Prod.fst actualWhnf) ++
                                                      "; whnf-diff=" ++
                                                      psKernelInferenceDebugExprDiff
                                                        (Prod.fst expectedWhnf)
                                                        (Prod.fst actualWhnf))
                | PsKernelExpr.lam name domain body binderInfo =>
                    match
                        psKernelInferLambdaSpineWithFuel
                          (Nat.succ
                            (psKernelExprNodeCount expr))
                          (smaller whnf defeq)
                          whnf
                          nextContext
                          state
                          expr
                          inferOnly
                          List.nil
                          List.nil with
                    | Except.error error =>
                        Except.error error
                    | Except.ok spineResult =>
                        let result :=
                          Prod.fst spineResult
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              (Prod.snd spineResult)
                              inferOnly
                              expr
                              result))
                | PsKernelExpr.forallE name domain body binderInfo =>
                    match
                        psKernelInferForallSpineWithFuel
                          (Nat.succ
                            (psKernelExprNodeCount expr))
                          (smaller whnf defeq)
                          whnf
                          nextContext
                          state
                          expr
                          inferOnly
                          List.nil
                          List.nil with
                    | Except.error error =>
                        Except.error error
                    | Except.ok spineResult =>
                        let result :=
                          Prod.fst spineResult
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              (Prod.snd spineResult)
                              inferOnly
                              expr
                              result))
                | PsKernelExpr.letE name type value body nondep =>
                    match
                        psKernelInferLetSpineWithFuel
                          (Nat.succ
                            (psKernelExprNodeCount expr))
                          (smaller whnf defeq)
                          whnf
                          defeq
                          nextContext
                          state
                          expr
                          inferOnly
                          List.nil
                          List.nil with
                    | Except.error error =>
                        Except.error error
                    | Except.ok spineResult =>
                        let result :=
                          Prod.fst spineResult
                        Except.ok
                          (Prod.mk
                            result
                            (psKernelCacheInferResult
                              (Prod.snd spineResult)
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
