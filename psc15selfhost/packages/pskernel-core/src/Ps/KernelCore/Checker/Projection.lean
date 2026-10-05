import Ps.KernelCore.Checker.Reduction.Whnf

def psKernelProjectionEnsureSortWith
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (type : PsKernelExpr) :
    Except String
      (Prod PsKernelLevel PsKernelCheckerState) :=
  match whnf context state type with
  | Except.error error =>
      Except.error error
  | Except.ok result =>
      match Prod.fst result with
      | PsKernelExpr.sort level =>
          Except.ok
            (Prod.mk
              level
              (Prod.snd result))
      | _ =>
          Except.error "expected sort"

def psKernelInferIsPropWith
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match inferType context state expr with
  | Except.error error =>
      Except.error error
  | Except.ok inferResult =>
      match
          psKernelProjectionEnsureSortWith
            whnf
            context
            (Prod.snd inferResult)
            (Prod.fst inferResult) with
      | Except.error error =>
          Except.error error
      | Except.ok sortResult =>
          Except.ok
            (Prod.mk
              (psKernelLevelNormalizesToZero
                (Prod.fst sortResult))
              (Prod.snd sortResult))

def psKernelProjectionApplyParamsWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    List PsKernelExpr ->
    Nat ->
    Nat ->
    PsKernelExpr ->
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
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_args : List PsKernelExpr)
        (_index : Nat)
        (_numParams : Nat)
        (_current : PsKernelExpr) =>
        Except.error
          "kernel projection parameter budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelProjectionApplyParamsWithFuel remaining;
      fun
        (whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (args : List PsKernelExpr)
        (index : Nat)
        (numParams : Nat)
        (current : PsKernelExpr) =>
        if psKernelNatLt index numParams then
          match whnf context state current with
          | Except.error error =>
              Except.error error
          | Except.ok reducedResult =>
              match Prod.fst reducedResult with
              | PsKernelExpr.forallE _ _ body _ =>
                  match
                      psKernelExprListGet
                        args
                        index with
                  | Option.none =>
                      Except.error
                        "invalid projection: missing structure parameter"
                  | Option.some argument =>
                      smaller
                        whnf
                        context
                        (Prod.snd reducedResult)
                        args
                        (Nat.succ index)
                        numParams
                        (psKernelExprInstantiate1
                          body
                          argument)
              | _ =>
                  Except.error
                    "invalid projection: constructor parameter is not a forall"
        else
          Except.ok
            (Prod.mk
              current
              state)

def psKernelProjectionSkipFieldsWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelName ->
    PsKernelExpr ->
    Bool ->
    Nat ->
    Nat ->
    PsKernelExpr ->
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
        (_inferType :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_inductName : PsKernelName)
        (_structValue : PsKernelExpr)
        (_propType : Bool)
        (_targetIndex : Nat)
        (_index : Nat)
        (_current : PsKernelExpr) =>
        Except.error
          "kernel projection field budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelProjectionSkipFieldsWithFuel remaining;
      fun
        (whnf :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (inferType :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          Except String
            (Prod PsKernelExpr PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (inductName : PsKernelName)
        (structValue : PsKernelExpr)
        (propType : Bool)
        (targetIndex : Nat)
        (index : Nat)
        (current : PsKernelExpr) =>
        if psKernelNatLt index targetIndex then
          match whnf context state current with
          | Except.error error =>
              Except.error error
          | Except.ok reducedResult =>
              match Prod.fst reducedResult with
              | PsKernelExpr.forallE _ domain body _ =>
                  let nextState :=
                    Prod.snd reducedResult;
                  if
                      psKernelExprHasLooseBVar
                        body then
                    if propType then
                      match
                          psKernelInferIsPropWith
                            whnf
                            inferType
                            context
                            nextState
                            domain with
                      | Except.error error =>
                          Except.error error
                      | Except.ok propResult =>
                          if Prod.fst propResult then
                            smaller
                              whnf
                              inferType
                              context
                              (Prod.snd propResult)
                              inductName
                              structValue
                              propType
                              targetIndex
                              (Nat.succ index)
                              (psKernelExprInstantiate1
                                body
                                (PsKernelExpr.proj
                                  inductName
                                  index
                                  structValue))
                          else
                            Except.error
                              "invalid projection: proof structure depends on data field"
                    else
                      smaller
                        whnf
                        inferType
                        context
                        nextState
                        inductName
                        structValue
                        propType
                        targetIndex
                        (Nat.succ index)
                        (psKernelExprInstantiate1
                          body
                          (PsKernelExpr.proj
                            inductName
                            index
                            structValue))
                  else
                    smaller
                      whnf
                      inferType
                      context
                      nextState
                      inductName
                      structValue
                      propType
                      targetIndex
                      (Nat.succ index)
                      body
              | _ =>
                  Except.error
                    "invalid projection index"
        else
          Except.ok
            (Prod.mk
              current
              state)

def psKernelInferProjectionWith
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr) :
    Except String
      (Prod PsKernelExpr PsKernelCheckerState) :=
  match
      inferType
        context
        state
        structValue with
  | Except.error error =>
      Except.error error
  | Except.ok inferResult =>
      match
          whnf
            context
            (Prod.snd inferResult)
            (Prod.fst inferResult) with
      | Except.error error =>
          Except.error error
      | Except.ok typeResult =>
          let type :=
            Prod.fst typeResult;
          let state1 :=
            Prod.snd typeResult;
          if
              psKernelNatGt
                index
                psKernelLeanUInt32Max then
            Except.error
              "invalid projection index"
          else
            let fn :=
              psKernelExprGetAppFn type;
            let args :=
              psKernelExprGetAppArgs type;
            match fn with
            | PsKernelExpr.const inductName inductLevels =>
                if
                    psKernelNameEq
                      inductName
                      typeName then
                  match
                      psKernelEnvironmentFind
                        context.environment
                        inductName with
                  | Option.none =>
                      Except.error
                        "invalid projection: structure name is not inductive"
                  | Option.some info =>
                      match info with
                      | PsKernelConstantInfo.inductInfo inductInfo =>
                          match inductInfo.ctors with
                          | List.nil =>
                              Except.error
                                "invalid projection: inductive must have exactly one constructor"
                          | List.cons ctorName ctorRest =>
                              match ctorRest with
                              | List.cons _ _ =>
                                  Except.error
                                    "invalid projection: inductive must have exactly one constructor"
                              | List.nil =>
                                  if
                                      Nat.beq
                                        (psKernelExprListLength args)
                                        (Nat.add
                                          inductInfo.numParams
                                          inductInfo.numIndices) then
                                    match
                                        psKernelEnvironmentFind
                                          context.environment
                                          ctorName with
                                    | Option.none =>
                                        Except.error
                                          "invalid projection: constructor metadata missing"
                                    | Option.some ctorEntry =>
                                        match ctorEntry with
                                        | PsKernelConstantInfo.ctorInfo ctorInfo =>
                                            let ctorBase :=
                                              ctorInfo.base;
                                            let initial :=
                                              psKernelExprInstantiateLevelParams
                                                ctorBase.type
                                                ctorBase.levelParams
                                                inductLevels;
                                            match
                                                psKernelProjectionApplyParamsWithFuel
                                                  (Nat.succ
                                                    inductInfo.numParams)
                                                  whnf
                                                  context
                                                  state1
                                                  args
                                                  0
                                                  inductInfo.numParams
                                                  initial with
                                            | Except.error error =>
                                                Except.error error
                                            | Except.ok paramResult =>
                                                match
                                                    psKernelInferIsPropWith
                                                      whnf
                                                      inferType
                                                      context
                                                      (Prod.snd paramResult)
                                                      type with
                                                | Except.error error =>
                                                    Except.error error
                                                | Except.ok propResult =>
                                                    match
                                                        psKernelProjectionSkipFieldsWithFuel
                                                          (Nat.succ index)
                                                          whnf
                                                          inferType
                                                          context
                                                          (Prod.snd propResult)
                                                          inductName
                                                          structValue
                                                          (Prod.fst propResult)
                                                          index
                                                          0
                                                          (Prod.fst paramResult) with
                                                    | Except.error error =>
                                                        Except.error error
                                                    | Except.ok fieldResult =>
                                                        match
                                                            whnf
                                                              context
                                                              (Prod.snd fieldResult)
                                                              (Prod.fst fieldResult) with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok finalResult =>
                                                            match
                                                                Prod.fst finalResult with
                                                            | PsKernelExpr.forallE _ domain _ _ =>
                                                                if Prod.fst propResult then
                                                                  match
                                                                      psKernelInferIsPropWith
                                                                        whnf
                                                                        inferType
                                                                        context
                                                                        (Prod.snd finalResult)
                                                                        domain with
                                                                  | Except.error error =>
                                                                      Except.error error
                                                                  | Except.ok domainProp =>
                                                                      if Prod.fst domainProp then
                                                                        Except.ok
                                                                          (Prod.mk
                                                                            domain
                                                                            (Prod.snd domainProp))
                                                                      else
                                                                        Except.error
                                                                          "invalid projection: proof structure field is not a proposition"
                                                                else
                                                                  Except.ok
                                                                    (Prod.mk
                                                                      domain
                                                                      (Prod.snd finalResult))
                                                            | _ =>
                                                                Except.error
                                                                  "invalid projection index"
                                        | _ =>
                                            Except.error
                                              "invalid projection: constructor metadata missing"
                                  else
                                    Except.error
                                      "invalid projection: inductive type is not fully applied"
                      | _ =>
                          Except.error
                            "invalid projection: structure name is not inductive"
                else
                  Except.error
                    "invalid projection: structure type mismatch"
            | _ =>
                Except.error
                  "invalid projection: projected expression type is not an inductive application"
