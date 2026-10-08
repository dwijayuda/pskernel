import Ps.KernelCore.Checker.Recursor.Analysis

/-
Recursor computation.

This module performs Quot and ordinary inductive recursor reduction once the
major has been analyzed/normalized. It selects the constructor rule,
instantiates universe parameters and fixed/minor arguments, and applies
remaining recursor arguments in Lean 4.34 order.
-/

def psKernelReduceInductiveRecWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
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
    (cheapRec : Bool)
    (cheapProj : Bool) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  let recSpine :=
    psKernelExprGetAppFnArgs expr;
  match Prod.fst recSpine with
  | PsKernelExpr.const recName recLevels =>
      match
          psKernelEnvironmentFind
            context.environment
            recName with
      | Option.some info =>
          match info with
          | PsKernelConstantInfo.recInfo recursor =>
              let recArgs :=
                Prod.snd recSpine;
              let majorIndex :=
                Nat.add
                  recursor.numParams
                  (Nat.add
                    recursor.numMotives
                    (Nat.add
                      recursor.numMinors
                      recursor.numIndices));
              if
                  psKernelNatGe
                    majorIndex
                    (psKernelExprListLength recArgs) then
                Except.ok
                  (Prod.mk
                    Option.none
                    state)
              else
                match
                    psKernelExprListGet
                      recArgs
                      majorIndex with
                | Option.none =>
                    Except.ok
                      (Prod.mk
                        Option.none
                        state)
                | Option.some major0 =>
                    let majorKResult :
                        Except String
                          (Prod PsKernelExpr PsKernelCheckerState) :=
                      if recursor.k then
                        psKernelToConstructorWhenK
                          publicWhnf
                          inferType
                          defeq
                          context
                          state
                          recursor
                          major0
                      else
                        Except.ok
                          (Prod.mk major0 state);
                    match majorKResult with
                    | Except.error error =>
                        Except.error error
                    | Except.ok majorK =>
                        let reducedResult :
                            Except String
                              (Prod PsKernelExpr PsKernelCheckerState) :=
                          if
                              psKernelIsConstructorApp
                                context.environment
                                (Prod.fst majorK) then
                            Except.ok majorK
                          else if cheapRec then
                            coreWhnf
                              context
                              (Prod.snd majorK)
                              (Prod.fst majorK)
                              cheapRec
                              cheapProj
                          else
                            publicWhnf
                              context
                              (Prod.snd majorK)
                              (Prod.fst majorK);
                        match reducedResult with
                        | Except.error error =>
                            Except.error error
                        | Except.ok reduced =>
                            let majorReduced :=
                              Prod.fst reduced;
                            let normalizeResult :
                                Except String
                                  (Prod PsKernelExpr PsKernelCheckerState) :=
                              match majorReduced with
                              | PsKernelExpr.lit literal =>
                                  match literal with
                                  | PsKernelLiteral.nat value =>
                                      match value with
                                      | Nat.zero =>
                                          Except.ok
                                            (Prod.mk
                                              (PsKernelExpr.const
                                                psKernelNatZeroName
                                                List.nil)
                                              (Prod.snd reduced))
                                      | Nat.succ predecessor =>
                                          Except.ok
                                            (Prod.mk
                                              (PsKernelExpr.app
                                                (PsKernelExpr.const
                                                  psKernelNatSuccName
                                                  List.nil)
                                                (PsKernelExpr.lit
                                                  (PsKernelLiteral.nat
                                                    predecessor)))
                                              (Prod.snd reduced))
                                  | PsKernelLiteral.str value =>
                                      publicWhnf
                                        context
                                        (Prod.snd reduced)
                                        (psKernelStringLitToConstructor value)
                              | _ =>
                                  psKernelToConstructorWhenStructure
                                    publicWhnf
                                    inferType
                                    context
                                    (Prod.snd reduced)
                                    recursor
                                    majorReduced;
                            match normalizeResult with
                            | Except.error error =>
                                Except.error error
                            | Except.ok normalized =>
                                let major :=
                                  Prod.fst normalized;
                                let majorSpine :=
                                  psKernelExprGetAppFnArgs major;
                                match Prod.fst majorSpine with
                                | PsKernelExpr.const ctorName _ =>
                                    match
                                        psKernelFindRecursorRule
                                          ctorName
                                          recursor.rules with
                                    | Option.none =>
                                        Except.ok
                                          (Prod.mk
                                            Option.none
                                            (Prod.snd normalized))
                                    | Option.some rule =>
                                        let majorArgs :=
                                          Prod.snd majorSpine;
                                        if
                                            psKernelNatGt
                                              rule.nFields
                                              (psKernelExprListLength majorArgs) then
                                          Except.ok
                                            (Prod.mk
                                              Option.none
                                              (Prod.snd normalized))
                                        else if
                                            Nat.beq
                                              (psKernelLevelListLength recLevels)
                                              (psKernelNameListLength
                                                recursor.base.levelParams) then
                                          let rhs0 :=
                                            psKernelExprInstantiateLevelParams
                                              rule.rhs
                                              recursor.base.levelParams
                                              recLevels;
                                          let fixedCount :=
                                            Nat.add
                                              recursor.numParams
                                              (Nat.add
                                                recursor.numMotives
                                                recursor.numMinors);
                                          let rhs1 :=
                                            psKernelApplyArgs
                                              rhs0
                                              (psKernelExprListTake
                                                fixedCount
                                                recArgs);
                                          let ctorParamCount :=
                                            Nat.sub
                                              (psKernelExprListLength majorArgs)
                                              rule.nFields;
                                          let rhs2 :=
                                            psKernelApplyArgs
                                              rhs1
                                              (psKernelExprListTake
                                                rule.nFields
                                                (psKernelExprListDrop
                                                  ctorParamCount
                                                  majorArgs));
                                          Except.ok
                                            (Prod.mk
                                              (Option.some
                                                (psKernelApplyArgs
                                                  rhs2
                                                  (psKernelExprListDrop
                                                    (Nat.succ majorIndex)
                                                    recArgs)))
                                              (Prod.snd normalized))
                                        else
                                          Except.ok
                                            (Prod.mk
                                              Option.none
                                              (Prod.snd normalized))
                                | _ =>
                                    Except.ok
                                      (Prod.mk
                                        Option.none
                                        (Prod.snd normalized))
          | _ =>
              Except.ok
                (Prod.mk Option.none state)
      | Option.none =>
          Except.ok
            (Prod.mk Option.none state)
  | _ =>
      Except.ok
        (Prod.mk Option.none state)

def psKernelReduceRecursorWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (inferType :
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
    (cheapRec : Bool)
    (cheapProj : Bool) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  match
      psKernelReduceQuotWith
        publicWhnf
        context
        state
        expr with
  | Except.error error =>
      Except.error error
  | Except.ok quotient =>
      match Prod.fst quotient with
      | Option.some value =>
          Except.ok
            (Prod.mk
              (Option.some value)
              (Prod.snd quotient))
      | Option.none =>
          psKernelReduceInductiveRecWith
            publicWhnf
            coreWhnf
            inferType
            defeq
            context
            (Prod.snd quotient)
            expr
            cheapRec
            cheapProj
