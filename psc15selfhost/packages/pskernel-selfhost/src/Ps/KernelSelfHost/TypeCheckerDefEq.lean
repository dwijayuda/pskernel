import Ps.KernelSelfHost.TypeCheckerDefEqSupport

def psKernelDefEqReflectionWith
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  let mayReflect :=
    if psKernelExprHasFVar left then
      context.eagerReduce
    else
      true;
  if mayReflect then
    match right with
    | PsKernelExpr.const name levels =>
        match levels with
        | List.nil =>
            if psKernelNameEq name psKernelBoolTrueName then
              match whnf context state left with
              | Except.error error =>
                  Except.error error
              | Except.ok reducedResult =>
                  match Prod.fst reducedResult with
                  | PsKernelExpr.const reducedName reducedLevels =>
                      match reducedLevels with
                      | List.nil =>
                          if
                              psKernelNameEq
                                reducedName
                                psKernelBoolTrueName then
                            Except.ok
                              (Prod.mk
                                (Option.some true)
                                (Prod.snd reducedResult))
                          else
                            Except.ok
                              (Prod.mk
                                Option.none
                                (Prod.snd reducedResult))
                      | List.cons _ _ =>
                          Except.ok
                            (Prod.mk
                              Option.none
                              (Prod.snd reducedResult))
                  | _ =>
                      Except.ok
                        (Prod.mk
                          Option.none
                          (Prod.snd reducedResult))
            else
              Except.ok
                (Prod.mk Option.none state)
        | List.cons _ _ =>
            Except.ok
              (Prod.mk Option.none state)
    | _ =>
        Except.ok
          (Prod.mk Option.none state)
  else
    Except.ok
      (Prod.mk Option.none state)

def psKernelDefEqProjectionShortcut
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match left with
  | PsKernelExpr.const leftName leftLevels =>
      match right with
      | PsKernelExpr.const rightName rightLevels =>
          if
              if psKernelNameEq leftName rightName then
                psKernelLevelListsEquivalent
                  leftLevels
                  rightLevels
              else
                false then
            Except.ok
              (Prod.mk
                (Option.some true)
                state)
          else
            Except.ok
              (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.fvar leftName =>
      match right with
      | PsKernelExpr.fvar rightName =>
          if psKernelNameEq leftName rightName then
            Except.ok
              (Prod.mk
                (Option.some true)
                state)
          else
            Except.ok
              (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.proj leftName leftIndex leftExpr =>
      match right with
      | PsKernelExpr.proj rightName rightIndex rightExpr =>
          if
              if psKernelNameEq leftName rightName then
                Nat.beq leftIndex rightIndex
              else
                false then
            match
                psKernelDefEqLazyProjReductionWithFuel
                  (Nat.succ
                    (Nat.add
                      (psKernelExprNodeCount leftExpr)
                      (psKernelExprNodeCount rightExpr)))
                  defeq
                  (psKernelWhnfCoreWithRecursorFuel
                    (Nat.succ
                      (Nat.add
                        (psKernelExprNodeCount leftExpr)
                        (psKernelExprNodeCount rightExpr)))
                    defeq)
                  context
                  state
                  leftExpr
                  rightExpr
                  leftName
                  leftIndex with
            | Except.error error =>
                Except.error error
            | Except.ok result =>
                if Prod.fst result then
                  Except.ok
                    (Prod.mk
                      (Option.some true)
                      (Prod.snd result))
                else
                  Except.ok
                    (Prod.mk
                      Option.none
                      (Prod.snd result))
          else
            Except.ok
              (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | _ =>
      Except.ok
        (Prod.mk Option.none state)

def psKernelDefEqLambdaEtaLeftWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (lambdaValue : PsKernelExpr)
    (other : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match inferType context state other with
  | Except.error error =>
      Except.error error
  | Except.ok typeResult =>
      match
          whnf
            context
            (Prod.snd typeResult)
            (Prod.fst typeResult) with
      | Except.error error =>
          Except.error error
      | Except.ok reducedType =>
          match Prod.fst reducedType with
          | PsKernelExpr.forallE name domain _ binderInfo =>
              let eta :=
                PsKernelExpr.lam
                  name
                  domain
                  (PsKernelExpr.app
                    other
                    (PsKernelExpr.bvar 0))
                  binderInfo;
              match
                  defeq
                    context
                    (Prod.snd reducedType)
                    lambdaValue
                    eta with
              | Except.error error =>
                  Except.error error
              | Except.ok result =>
                  if Prod.fst result then
                    Except.ok
                      (Prod.mk
                        (Option.some true)
                        (Prod.snd result))
                  else
                    Except.ok
                      (Prod.mk
                        Option.none
                        (Prod.snd result))
          | _ =>
              Except.ok
                (Prod.mk
                  Option.none
                  (Prod.snd reducedType))

def psKernelDefEqLambdaEtaRightWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (other : PsKernelExpr)
    (lambdaValue : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match inferType context state other with
  | Except.error error =>
      Except.error error
  | Except.ok typeResult =>
      match
          whnf
            context
            (Prod.snd typeResult)
            (Prod.fst typeResult) with
      | Except.error error =>
          Except.error error
      | Except.ok reducedType =>
          match Prod.fst reducedType with
          | PsKernelExpr.forallE name domain _ binderInfo =>
              let eta :=
                PsKernelExpr.lam
                  name
                  domain
                  (PsKernelExpr.app
                    other
                    (PsKernelExpr.bvar 0))
                  binderInfo;
              match
                  defeq
                    context
                    (Prod.snd reducedType)
                    eta
                    lambdaValue with
              | Except.error error =>
                  Except.error error
              | Except.ok result =>
                  if Prod.fst result then
                    Except.ok
                      (Prod.mk
                        (Option.some true)
                        (Prod.snd result))
                  else
                    Except.ok
                      (Prod.mk
                        Option.none
                        (Prod.snd result))
          | _ =>
              Except.ok
                (Prod.mk
                  Option.none
                  (Prod.snd reducedType))

def psKernelDefEqFullShapeWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match left with
  | PsKernelExpr.sort leftLevel =>
      match right with
      | PsKernelExpr.sort rightLevel =>
          Except.ok
            (Prod.mk
              (Option.some
                (psKernelLevelEquivalent
                  leftLevel
                  rightLevel))
              state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.lit leftLiteral =>
      match right with
      | PsKernelExpr.lit rightLiteral =>
          Except.ok
            (Prod.mk
              (Option.some
                (psKernelLiteralEq
                  leftLiteral
                  rightLiteral))
              state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.app _ _ =>
      match right with
      | PsKernelExpr.app _ _ =>
          match
              psKernelDefEqApp
                defeq
                context
                state
                left
                right with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              if Prod.fst result then
                Except.ok
                  (Prod.mk
                    (Option.some true)
                    (Prod.snd result))
              else
                Except.ok
                  (Prod.mk
                    Option.none
                    (Prod.snd result))
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.forallE _ _ _ _ =>
      match right with
      | PsKernelExpr.forallE _ _ _ _ =>
          match
              psKernelDefEqForallSpine
                defeq
                context
                state
                left
                right with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              if Prod.fst result then
                Except.ok
                  (Prod.mk
                    (Option.some true)
                    (Prod.snd result))
              else
                Except.ok
                  (Prod.mk
                    Option.none
                    (Prod.snd result))
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | PsKernelExpr.lam _ _ _ _ =>
      match right with
      | PsKernelExpr.lam _ _ _ _ =>
          match
              psKernelDefEqLambdaSpine
                defeq
                context
                state
                left
                right with
          | Except.error error =>
              Except.error error
          | Except.ok result =>
              if Prod.fst result then
                Except.ok
                  (Prod.mk
                    (Option.some true)
                    (Prod.snd result))
              else
                Except.ok
                  (Prod.mk
                    Option.none
                    (Prod.snd result))
      | _ =>
          psKernelDefEqLambdaEtaLeftWith
            defeq
            inferType
            whnf
            context
            state
            left
            right
  | _ =>
      match right with
      | PsKernelExpr.lam _ _ _ _ =>
          psKernelDefEqLambdaEtaRightWith
            defeq
            inferType
            whnf
            context
            state
            left
            right
      | _ =>
          Except.ok
            (Prod.mk Option.none state)

def psKernelIsDefEqAfterFullShape
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (originalLeft : PsKernelExpr)
    (originalRight : PsKernelExpr)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match
      psKernelDefEqEtaStructWith
        defeq
        inferType
        context
        state
        left
        right with
  | Except.error error =>
      Except.error error
  | Except.ok etaResult =>
      if Prod.fst etaResult then
        Except.ok
          (psKernelDefEqFinish
            (Prod.snd etaResult)
            originalLeft
            originalRight
            true)
      else
        match
            psKernelDefEqStringLitExpansionWith
              defeq
              whnf
              context
              (Prod.snd etaResult)
              left
              right with
        | Except.error error =>
            Except.error error
        | Except.ok stringResult =>
            match Prod.fst stringResult with
            | Option.some value =>
                Except.ok
                  (psKernelDefEqFinish
                    (Prod.snd stringResult)
                    originalLeft
                    originalRight
                    value)
            | Option.none =>
                match
                    psKernelDefEqUnitLikeWith
                      defeq
                      inferType
                      whnf
                      context
                      (Prod.snd stringResult)
                      left
                      right with
                | Except.error error =>
                    Except.error error
                | Except.ok unitResult =>
                    Except.ok
                      (psKernelDefEqFinish
                        (Prod.snd unitResult)
                        originalLeft
                        originalRight
                        (Prod.fst unitResult))

def psKernelIsDefEqWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelExpr ->
    PsKernelExpr ->
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_left : PsKernelExpr)
        (_right : PsKernelExpr) =>
        Except.error
          "kernel definitional equality budget exhausted"
  | Nat.succ remaining =>
      let defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState) :=
        psKernelIsDefEqWithFuel remaining;
      fun
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (left : PsKernelExpr)
        (right : PsKernelExpr) =>
        match
            psKernelCheckerContextEnterRecDepth
              context with
        | Except.error error =>
            Except.error error
        | Except.ok nextContext =>
            if psKernelExprEq left right then
              Except.ok
                (psKernelDefEqFinish
                  state
                  left
                  right
                  true)
            else if
                psKernelExprPairSetContains
                  state.success
                  left
                  right then
              Except.ok
                (Prod.mk true state)
            else
              let whnf :=
                psKernelWhnfWithRecursorFuel
                  remaining
                  defeq;
              let coreWhnf :=
                psKernelWhnfCoreWithRecursorFuel
                  remaining
                  defeq;
              let inferType :=
                psKernelInferWithRecursorFuel
                  remaining
                  defeq;
              match
                  psKernelDefEqQuick
                    defeq
                    nextContext
                    state
                    left
                    right with
              | Except.error error =>
                  Except.error error
              | Except.ok quickResult =>
                  match Prod.fst quickResult with
                  | Option.some value =>
                      Except.ok
                        (psKernelDefEqFinish
                          (Prod.snd quickResult)
                          left
                          right
                          value)
                  | Option.none =>
                      match
                          psKernelDefEqReflectionWith
                            whnf
                            nextContext
                            (Prod.snd quickResult)
                            left
                            right with
                      | Except.error error =>
                          Except.error error
                      | Except.ok reflectionResult =>
                          match Prod.fst reflectionResult with
                          | Option.some value =>
                              Except.ok
                                (psKernelDefEqFinish
                                  (Prod.snd reflectionResult)
                                  left
                                  right
                                  value)
                          | Option.none =>
                              match
                                  coreWhnf
                                    nextContext
                                    (Prod.snd reflectionResult)
                                    left
                                    false
                                    true with
                              | Except.error error =>
                                  Except.error error
                              | Except.ok leftCoreResult =>
                                  match
                                      coreWhnf
                                        nextContext
                                        (Prod.snd leftCoreResult)
                                        right
                                        false
                                        true with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok rightCoreResult =>
                                      let leftCore :=
                                        Prod.fst leftCoreResult;
                                      let rightCore :=
                                        Prod.fst rightCoreResult;
                                      match
                                          psKernelDefEqQuick
                                            defeq
                                            nextContext
                                            (Prod.snd rightCoreResult)
                                            leftCore
                                            rightCore with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok coreQuick =>
                                          match Prod.fst coreQuick with
                                          | Option.some value =>
                                              Except.ok
                                                (psKernelDefEqFinish
                                                  (Prod.snd coreQuick)
                                                  left
                                                  right
                                                  value)
                                          | Option.none =>
                                              match
                                                  inferType
                                                    nextContext
                                                    (Prod.snd coreQuick)
                                                    leftCore with
                                              | Except.error error =>
                                                  Except.error error
                                              | Except.ok leftTypeResult =>
                                                  match
                                                      psKernelDefEqIsPropWith
                                                        inferType
                                                        whnf
                                                        nextContext
                                                        (Prod.snd leftTypeResult)
                                                        (Prod.fst leftTypeResult) with
                                                  | Except.error error =>
                                                      Except.error error
                                                  | Except.ok proofResult =>
                                                      if Prod.fst proofResult then
                                                        match
                                                            inferType
                                                              nextContext
                                                              (Prod.snd proofResult)
                                                              rightCore with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok rightTypeResult =>
                                                            match
                                                                defeq
                                                                  nextContext
                                                                  (Prod.snd rightTypeResult)
                                                                  (Prod.fst leftTypeResult)
                                                                  (Prod.fst rightTypeResult) with
                                                            | Except.error error =>
                                                                Except.error error
                                                            | Except.ok proofEqual =>
                                                                Except.ok
                                                                  (psKernelDefEqFinish
                                                                    (Prod.snd proofEqual)
                                                                    left
                                                                    right
                                                                    (Prod.fst proofEqual))
                                                      else
                                                        match
                                                            psKernelDefEqLazyReductionWithFuel
                                                              remaining
                                                              defeq
                                                              whnf
                                                              coreWhnf
                                                              nextContext
                                                              (Prod.snd proofResult)
                                                              leftCore
                                                              rightCore with
                                                        | Except.error error =>
                                                            Except.error error
                                                        | Except.ok deltaResult =>
                                                            match Prod.fst deltaResult with
                                                            | PsKernelDeltaResult.decided value =>
                                                                Except.ok
                                                                  (psKernelDefEqFinish
                                                                    (Prod.snd deltaResult)
                                                                    left
                                                                    right
                                                                    value)
                                                            | PsKernelDeltaResult.residual leftDelta rightDelta =>
                                                                match
                                                                    psKernelDefEqProjectionShortcut
                                                                      defeq
                                                                      nextContext
                                                                      (Prod.snd deltaResult)
                                                                      leftDelta
                                                                      rightDelta with
                                                                | Except.error error =>
                                                                    Except.error error
                                                                | Except.ok shortcutResult =>
                                                                    match Prod.fst shortcutResult with
                                                                    | Option.some value =>
                                                                        Except.ok
                                                                          (psKernelDefEqFinish
                                                                            (Prod.snd shortcutResult)
                                                                            left
                                                                            right
                                                                            value)
                                                                    | Option.none =>
                                                                        match
                                                                            coreWhnf
                                                                              nextContext
                                                                              (Prod.snd shortcutResult)
                                                                              leftDelta
                                                                              false
                                                                              false with
                                                                        | Except.error error =>
                                                                            Except.error error
                                                                        | Except.ok leftFullResult =>
                                                                            match
                                                                                coreWhnf
                                                                                  nextContext
                                                                                  (Prod.snd leftFullResult)
                                                                                  rightDelta
                                                                                  false
                                                                                  false with
                                                                            | Except.error error =>
                                                                                Except.error error
                                                                            | Except.ok rightFullResult =>
                                                                                let leftFull :=
                                                                                  Prod.fst leftFullResult;
                                                                                let rightFull :=
                                                                                  Prod.fst rightFullResult;
                                                                                let changed :=
                                                                                  if
                                                                                      psKernelExprEq
                                                                                        leftFull
                                                                                        leftDelta then
                                                                                    if
                                                                                        psKernelExprEq
                                                                                          rightFull
                                                                                          rightDelta then
                                                                                      false
                                                                                    else
                                                                                      true
                                                                                  else
                                                                                    true;
                                                                                if changed then
                                                                                  match
                                                                                      defeq
                                                                                        nextContext
                                                                                        (Prod.snd rightFullResult)
                                                                                        leftFull
                                                                                        rightFull with
                                                                                  | Except.error error =>
                                                                                      Except.error error
                                                                                  | Except.ok changedResult =>
                                                                                      Except.ok
                                                                                        (psKernelDefEqFinish
                                                                                          (Prod.snd changedResult)
                                                                                          left
                                                                                          right
                                                                                          (Prod.fst changedResult))
                                                                                else
                                                                                  match
                                                                                      psKernelDefEqFullShapeWith
                                                                                        defeq
                                                                                        inferType
                                                                                        whnf
                                                                                        nextContext
                                                                                        (Prod.snd rightFullResult)
                                                                                        leftFull
                                                                                        rightFull with
                                                                                  | Except.error error =>
                                                                                      Except.error error
                                                                                  | Except.ok shapeResult =>
                                                                                      match Prod.fst shapeResult with
                                                                                      | Option.some value =>
                                                                                          Except.ok
                                                                                            (psKernelDefEqFinish
                                                                                              (Prod.snd shapeResult)
                                                                                              left
                                                                                              right
                                                                                              value)
                                                                                      | Option.none =>
                                                                                          psKernelIsDefEqAfterFullShape
                                                                                            defeq
                                                                                            inferType
                                                                                            whnf
                                                                                            nextContext
                                                                                            (Prod.snd shapeResult)
                                                                                            left
                                                                                            right
                                                                                            leftFull
                                                                                            rightFull

def psKernelIsDefEq
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  psKernelIsDefEqWithFuel
    fuel
    context
    state
    left
    right
