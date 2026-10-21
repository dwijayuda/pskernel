import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Core.ExprV2.TransformSpine

/-
Read only environment decisions for the owning canonical DAG. Constructor
projection selects an existing argument ID using admitted scalar metadata;
no declaration body or type is imported from the original representation.
The reduction guard mirrors the inert branches of the original Quot/recursor
callbacks.
-/

def psKernelExprV2ReduceProjOnCanonical
    (context : PsKernelCheckerContext) (arena : PsKernelExprV2PagedArena)
    (typeName : PsKernelName) (index structValue : Nat) :
    Except String (Option Nat) :=
  if psKernelNatGt index psKernelLeanUInt32Max then Except.ok Option.none
  else
    match psKernelExprV2TransformAppSpineOnCanonical arena structValue with
    | Except.error error => Except.error error
    | Except.ok spine =>
        match psKernelExprV2PagedRequire arena (Prod.fst spine) with
        | Except.error error => Except.error error
        | Except.ok head =>
            match head.node with
            | PsKernelExprV2Node.const ctorName _ =>
                match psKernelEnvironmentFind context.environment ctorName with
                | Option.none => Except.ok Option.none
                | Option.some info =>
                    match info with
                    | PsKernelConstantInfo.ctorInfo ctor =>
                        if psKernelNameEq ctor.induct typeName then
                          Except.ok
                            (psKernelExprV2TransformNatGet
                              (Prod.snd spine) (Nat.add ctor.numParams index))
                        else Except.ok Option.none
                    | _ => Except.ok Option.none
            | _ => Except.ok Option.none

def psKernelExprV2WhnfRecursorInert
    (context : PsKernelCheckerContext) (head : PsKernelExprV2Node) : Bool :=
  match head with
  | PsKernelExprV2Node.const name _ =>
      let quotientInert :=
        if context.environment.quotInitialized then
          if psKernelNameEq name psKernelQuotLiftName then false
          else if psKernelNameEq name psKernelQuotIndName then false
          else true
        else true;
      if quotientInert then
        match psKernelEnvironmentFind context.environment name with
        | Option.none => true
        | Option.some info =>
            match info with
            | PsKernelConstantInfo.recInfo _ => false
            | _ => true
      else false
  | _ => true

