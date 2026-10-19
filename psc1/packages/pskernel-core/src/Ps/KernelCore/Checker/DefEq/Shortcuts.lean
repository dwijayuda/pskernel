import Ps.KernelCore.Checker.DefEq.FinalRules

/-
Lean 4.34 algorithmic-defeq shortcuts.

These rules are tried at precise points in the top-level equality algorithm:
- reflection against Bool.true;
- projection-specific lazy-delta comparison;
- function eta expansion, left and right.

The order is semantic because Lean's algorithmic definitional equality is
intentionally incomplete.
-/

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
