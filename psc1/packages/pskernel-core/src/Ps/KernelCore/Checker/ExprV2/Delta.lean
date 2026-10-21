import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Checker.ExprV2.WhnfState
import Ps.KernelCore.Core.ExprV2.TransformSpine

/-
Delta reduction for definitions admitted from the owning input DAG. Admission
has already established correspondence between each stored ID and the actual
environment definition. This worker reads only declaration kind and universe
parameters from the original environment; it never imports a recursive body.

Outer none requests complete-checker fallback for a definition absent from
the same-batch index. An inner none is an ordinary stuck delta step. Existing
environment lookup, declaration kind, and level-arity ordering are preserved.
-/

def psKernelExprV2InstantiateDefinition
    (state : PsKernelExprV2WhnfState)
    (definition : PsKernelExprV2DefinitionRef)
    (levels : List PsKernelLevel) (args : List Nat) :
    Except String (Prod PsKernelExprV2WhnfState Nat) :=
  match psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.levels definition.levelParams levels)
      state.arena definition.value 0 with
  | Except.error error => Except.error error
  | Except.ok instantiated =>
      match psKernelExprV2TransformApplyArgsOnCanonical
          args (Prod.fst instantiated) (Prod.snd instantiated) with
      | Except.error error => Except.error error
      | Except.ok applied =>
          Except.ok
            (Prod.mk
              (psKernelExprV2WhnfStateWithArena state (Prod.fst applied))
              (Prod.snd applied))

def psKernelExprV2TryUnfoldDefinition
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState (Option Nat))) :=
  match psKernelExprV2TransformAppSpineOnCanonical state.arena root with
  | Except.error error => Option.some (Except.error error)
  | Except.ok spine =>
      match psKernelExprV2PagedRequire state.arena (Prod.fst spine) with
      | Except.error error => Option.some (Except.error error)
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const name levels =>
              match psKernelEnvironmentFind context.environment name with
              | Option.none => Option.some (Except.ok (Prod.mk state Option.none))
              | Option.some info =>
                  match info with
                  | PsKernelConstantInfo.defnInfo actual =>
                      if Nat.beq
                          (psKernelNameListLength actual.base.levelParams)
                          (psKernelLevelListLength levels) then
                        match psKernelExprV2DefinitionRefFind state.definitions name with
                        | Option.none => Option.none
                        | Option.some definition =>
                            if psKernelNameListsEq
                                definition.levelParams actual.base.levelParams then
                              match psKernelExprV2InstantiateDefinition
                                  state definition levels (Prod.snd spine) with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok result =>
                                  Option.some
                                    (Except.ok
                                      (Prod.mk (Prod.fst result)
                                        (Option.some (Prod.snd result))))
                            else Option.none
                      else Option.some (Except.ok (Prod.mk state Option.none))
                  | _ => Option.some (Except.ok (Prod.mk state Option.none))
          | _ => Option.some (Except.ok (Prod.mk state Option.none))
