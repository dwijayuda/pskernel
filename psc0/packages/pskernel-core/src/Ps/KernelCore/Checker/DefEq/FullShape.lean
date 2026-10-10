import Ps.KernelCore.Checker.DefEq.Shortcuts

/-
Lean 4.34 full-shape and terminal definitional-equality rules.

After lazy delta and full projection WHNF stop making progress, this module:
- compares Sort/literal/application/binder shapes;
- performs function eta when only one side is a lambda;
- then applies structure eta, string-literal expansion, and unit-like
  structure equality.

This module does not choose when to run these rules; Checker/Knot.lean
remains the readable top-level orchestration.
-/

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
          | _ =>
              Except.ok
                (Prod.mk Option.none state)

def psKernelIsDefEqAfterFullShape
    [cachePolicy : PsKernelSemanticCachePolicy]
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
