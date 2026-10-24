import Ps.KernelCore.API.DagOrdinaryHeaderTypes
import Ps.KernelCore.Core.ExprV2.Transform
import Ps.KernelCore.Checker.ExprV2.DefEq

/-
Private constructor-parameter alignment in the existing header context.
The arena is canonical and every parameter type belongs to the current owner.
This worker inspects the syntactic constructor telescope, just like V1: there
is no preliminary WHNF, type-annotation consumption or new local allocation.
DefEq returns the complete next owner; only its arena is extended to reuse the
already allocated header parameter name in the constructor body.
-/
def psKernelExprV2OrdinaryOpenConstructorParamsWorker
    (fuel : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    List PsKernelExprV2OrdinaryOpenBinder -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match fuel with
  | Nat.zero =>
      fun
        (_defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
        (_parameters : List PsKernelExprV2OrdinaryOpenBinder) (_type : Nat) =>
        Option.some
          (Except.error "simple inductive constructor parameter budget exhausted")
  | Nat.succ remaining =>
      let smaller := psKernelExprV2OrdinaryOpenConstructorParamsWorker remaining;
      fun
        (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
        (parameters : List PsKernelExprV2OrdinaryOpenBinder) (type : Nat) =>
        match parameters with
        | List.nil => Option.some (Except.ok (Prod.mk state type))
        | List.cons parameter rest =>
            match psKernelExprV2PagedRequire state.whnf.arena type with
            | Except.error error => Option.some (Except.error error)
            | Except.ok entry =>
                match entry.node with
                | PsKernelExprV2Node.forallE _ domain body _ =>
                    match defeq remaining context state domain parameter.type with
                    | Option.none => Option.none
                    | Option.some attempted =>
                        match attempted with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok equal =>
                            if Prod.snd equal then
                              let next := Prod.fst equal;
                              match psKernelExprV2PagedMkFVar
                                  next.whnf.arena parameter.internalName with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok fvarBuilt =>
                                  match psKernelExprV2TransformOnCanonical
                                      (PsKernelExprV2Transform.instantiate 0
                                        (List.cons (Prod.snd fvarBuilt) List.nil))
                                      (Prod.fst fvarBuilt) body 0 with
                                  | Except.error error => Option.some (Except.error error)
                                  | Except.ok instantiated =>
                                      smaller defeq context
                                        (psKernelExprV2CheckStateWithArena
                                          next (Prod.fst instantiated))
                                        rest (Prod.snd instantiated)
                            else
                              Option.some
                                (Except.error
                                  "simple inductive constructor parameter does not match the datatype parameter")
                | _ =>
                    Option.some
                      (Except.error
                        "simple inductive constructor has fewer parameters than the datatype")

def psKernelExprV2OrdinaryOpenConstructorParamsWith
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (type : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2OrdinaryOpenConstructorParamsWorker (Nat.succ fuel)
    defeq context state parameters type

def psKernelExprV2OrdinaryOpenConstructorParamsWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (type : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2OrdinaryOpenConstructorParamsWith
    psKernelExprV2TryDefEqStateWithFuel fuel context state parameters type
