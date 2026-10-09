import Ps.KernelCore.Checker.Reduction.Primitives

/-
Kernel-recognized weak-head reduction helpers.

This module contains the Quot and optimized Nat reduction hooks used by WHNF.
Each helper is callback-driven so recursive normalization remains controlled by
the public WHNF pipeline rather than hidden inside primitive reduction code.
-/


def psKernelNoRecursorReduction
    (_context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (_expr : PsKernelExpr)
    (_cheapRec : Bool)
    (_cheapProj : Bool) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  Except.ok
    (Prod.mk
      Option.none
      state)

def psKernelReduceQuotWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  if context.environment.quotInitialized then
    let fn :=
      psKernelExprGetAppFn expr;
    match fn with
    | PsKernelExpr.const fnName _ =>
        let isLift :=
          psKernelNameEq
            fnName
            psKernelQuotLiftName;
        let isInd :=
          psKernelNameEq
            fnName
            psKernelQuotIndName;
        if isLift then
          let mkPos := 5;
          let argPos := 3;
          let args :=
            psKernelExprGetAppArgs expr;
          if
              Nat.ble
                (psKernelExprListLength args)
                mkPos then
            Except.ok
              (Prod.mk Option.none state)
          else
            match psKernelExprListGet args mkPos with
            | Option.none =>
                Except.ok
                  (Prod.mk Option.none state)
            | Option.some major =>
                match publicWhnf context state major with
                | Except.error error =>
                    Except.error error
                | Except.ok majorResult =>
                    let majorReduced :=
                      Prod.fst majorResult;
                    let state1 :=
                      Prod.snd majorResult;
                    match
                        psKernelExprGetAppFn
                          majorReduced with
                    | PsKernelExpr.const mkName _ =>
                        if
                            psKernelNameEq
                              mkName
                              psKernelQuotMkName then
                          if
                              Nat.beq
                                (psKernelExprGetAppNumArgs
                                  majorReduced)
                                3 then
                            let mkArgs :=
                              psKernelExprGetAppArgs
                                majorReduced;
                            match
                                psKernelExprListGet
                                  mkArgs
                                  2 with
                            | Option.none =>
                                Except.ok
                                  (Prod.mk
                                    Option.none
                                    state1)
                            | Option.some representative =>
                                match
                                    psKernelExprListGet
                                      args
                                      argPos with
                                | Option.none =>
                                    Except.ok
                                      (Prod.mk
                                        Option.none
                                        state1)
                                | Option.some fnValue =>
                                    let base :=
                                      PsKernelExpr.app
                                        fnValue
                                        representative;
                                    let remaining :=
                                      psKernelExprListDrop
                                        (Nat.succ mkPos)
                                        args;
                                    Except.ok
                                      (Prod.mk
                                        (Option.some
                                          (psKernelApplyArgs
                                            base
                                            remaining))
                                        state1)
                          else
                            Except.ok
                              (Prod.mk Option.none state1)
                        else
                          Except.ok
                            (Prod.mk Option.none state1)
                    | _ =>
                        Except.ok
                          (Prod.mk Option.none state1)
        else if isInd then
          let mkPos := 4;
          let argPos := 3;
          let args :=
            psKernelExprGetAppArgs expr;
          if
              Nat.ble
                (psKernelExprListLength args)
                mkPos then
            Except.ok
              (Prod.mk Option.none state)
          else
            match psKernelExprListGet args mkPos with
            | Option.none =>
                Except.ok
                  (Prod.mk Option.none state)
            | Option.some major =>
                match publicWhnf context state major with
                | Except.error error =>
                    Except.error error
                | Except.ok majorResult =>
                    let majorReduced :=
                      Prod.fst majorResult;
                    let state1 :=
                      Prod.snd majorResult;
                    match
                        psKernelExprGetAppFn
                          majorReduced with
                    | PsKernelExpr.const mkName _ =>
                        if
                            psKernelNameEq
                              mkName
                              psKernelQuotMkName then
                          if
                              Nat.beq
                                (psKernelExprGetAppNumArgs
                                  majorReduced)
                                3 then
                            let mkArgs :=
                              psKernelExprGetAppArgs
                                majorReduced;
                            match
                                psKernelExprListGet
                                  mkArgs
                                  2 with
                            | Option.none =>
                                Except.ok
                                  (Prod.mk
                                    Option.none
                                    state1)
                            | Option.some representative =>
                                match
                                    psKernelExprListGet
                                      args
                                      argPos with
                                | Option.none =>
                                    Except.ok
                                      (Prod.mk
                                        Option.none
                                        state1)
                                | Option.some fnValue =>
                                    let base :=
                                      PsKernelExpr.app
                                        fnValue
                                        representative;
                                    let remaining :=
                                      psKernelExprListDrop
                                        (Nat.succ mkPos)
                                        args;
                                    Except.ok
                                      (Prod.mk
                                        (Option.some
                                          (psKernelApplyArgs
                                            base
                                            remaining))
                                        state1)
                          else
                            Except.ok
                              (Prod.mk Option.none state1)
                        else
                          Except.ok
                            (Prod.mk Option.none state1)
                    | _ =>
                        Except.ok
                          (Prod.mk Option.none state1)
        else
          Except.ok
            (Prod.mk Option.none state)
    | _ =>
        Except.ok
          (Prod.mk Option.none state)
  else
    Except.ok
      (Prod.mk Option.none state)

def psKernelReduceNatWith
    (publicWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod
        (Option PsKernelExpr)
        PsKernelCheckerState) :=
  match expr with
  | PsKernelExpr.app fn right =>
      match fn with
      | PsKernelExpr.const name levels =>
          match levels with
          | List.nil =>
              if
                  psKernelNameEq
                    name
                    psKernelNatSuccName then
                match
                    publicWhnf
                      context
                      state
                      right with
                | Except.error error =>
                    Except.error error
                | Except.ok reducedResult =>
                    let reduced :=
                      Prod.fst reducedResult;
                    let next :=
                      Prod.snd reducedResult;
                    match
                        psKernelExprNatLiteralValue
                          reduced with
                    | Option.none =>
                        Except.ok
                          (Prod.mk Option.none next)
                    | Option.some value =>
                        let result :=
                          Nat.succ value;
                        match
                            psKernelCheckNatSize
                              context.maxNatSize
                              result with
                        | Except.error error =>
                            Except.error error
                        | Except.ok _ =>
                            Except.ok
                              (Prod.mk
                                (Option.some
                                  (PsKernelExpr.lit
                                    (PsKernelLiteral.nat
                                      result)))
                                next)
              else
                Except.ok
                  (Prod.mk Option.none state)
          | List.cons _ _ =>
              Except.ok
                (Prod.mk Option.none state)
      | PsKernelExpr.app binaryHead left =>
          match binaryHead with
          | PsKernelExpr.const name levels =>
              match levels with
              | List.nil =>
                  if psKernelNatBinarySupported name then
                    match publicWhnf context state left with
                    | Except.error error => Except.error error
                    | Except.ok leftResult =>
                        let leftReduced := Prod.fst leftResult;
                        let state1 := Prod.snd leftResult;
                        match psKernelExprNatLiteralValue leftReduced with
                        | Option.none =>
                            Except.ok (Prod.mk Option.none state1)
                        | Option.some leftValue =>
                            match publicWhnf context state1 right with
                            | Except.error error => Except.error error
                            | Except.ok rightResult =>
                                let rightReduced := Prod.fst rightResult;
                                let state2 := Prod.snd rightResult;
                                match psKernelExprNatLiteralValue rightReduced with
                                | Option.none =>
                                    Except.ok (Prod.mk Option.none state2)
                                | Option.some rightValue =>
                                    match psKernelReduceNatBinary
                                        context.maxNatSize name leftValue rightValue with
                                    | Except.error error => Except.error error
                                    | Except.ok result =>
                                        Except.ok (Prod.mk result state2)
                  else
                    Except.ok (Prod.mk Option.none state)
              | List.cons _ _ =>
                  Except.ok (Prod.mk Option.none state)
          | _ =>
              Except.ok (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | _ =>
      Except.ok
        (Prod.mk Option.none state)
