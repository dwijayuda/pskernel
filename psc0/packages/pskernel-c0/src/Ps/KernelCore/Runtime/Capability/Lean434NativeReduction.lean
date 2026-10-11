import Ps.KernelCore.Runtime.Capability.Types

def psKernelNativeBoolExpr
    (trueName : PsKernelName)
    (falseName : PsKernelName)
    (value : Bool) :
    PsKernelExpr :=
  if value then
    PsKernelExpr.const
      trueName
      List.nil
  else
    PsKernelExpr.const
      falseName
      List.nil

def psKernelReduceNativeWith
    (provider : Option PsKernelNativeEvaluator)
    (reduceBoolName : PsKernelName)
    (reduceNatName : PsKernelName)
    (boolTrueName : PsKernelName)
    (boolFalseName : PsKernelName)
    (expr : PsKernelExpr) :
    Except String (Option PsKernelExpr) :=
  match provider with
  | Option.none =>
      Except.ok Option.none
  | Option.some evaluator =>
      match expr with
      | PsKernelExpr.app fn arg =>
          match fn with
          | PsKernelExpr.const marker levels =>
              match levels with
              | List.nil =>
                  match arg with
                  | PsKernelExpr.const target _ =>
                      if
                          psKernelNameEq
                            marker
                            reduceBoolName then
                        match evaluator.evalBool target with
                        | Except.error error =>
                            Except.error error
                        | Except.ok result =>
                            match result with
                            | Option.none =>
                                Except.ok Option.none
                            | Option.some value =>
                                Except.ok
                                  (Option.some
                                    (psKernelNativeBoolExpr
                                      boolTrueName
                                      boolFalseName
                                      value))
                      else if
                          psKernelNameEq
                            marker
                            reduceNatName then
                        match evaluator.evalNat target with
                        | Except.error error =>
                            Except.error error
                        | Except.ok result =>
                            match result with
                            | Option.none =>
                                Except.ok Option.none
                            | Option.some value =>
                                Except.ok
                                  (Option.some
                                    (PsKernelExpr.lit
                                      (PsKernelLiteral.nat value)))
                      else
                        Except.ok Option.none
                  | _ =>
                      Except.ok Option.none
              | List.cons _ _ =>
                  Except.ok Option.none
          | _ =>
              Except.ok Option.none
      | _ =>
          Except.ok Option.none
