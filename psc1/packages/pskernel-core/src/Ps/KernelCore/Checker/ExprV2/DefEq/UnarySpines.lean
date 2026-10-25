import Ps.KernelCore.Checker.ExprV2.CheckState

/- Read-only cancellation of unary applications with the same fvar node ID.
   Structural traversal has its own finite bound. The supplied semantic
   callback and its predecessor fuel are retained without reset.
   Only a positive residual comparison may bypass the original full rule. -/
structure PsKernelExprV2UnarySpinePlan where
  left : Nat
  right : Nat
  skipped : Nat

def psKernelExprV2UnarySpineView
    (arena : PsKernelExprV2PagedArena) (left right : Nat) : Option (Prod Nat Nat) :=
  match psKernelExprV2PagedFind arena left with
  | Option.none => Option.none
  | Option.some leftEntry =>
      match psKernelExprV2PagedFind arena right with
      | Option.none => Option.none
      | Option.some rightEntry =>
          match leftEntry.node with
          | PsKernelExprV2Node.app leftFn leftArg =>
              match rightEntry.node with
              | PsKernelExprV2Node.app rightFn rightArg =>
                  if Nat.beq leftFn rightFn then
                    match psKernelExprV2PagedFind arena leftFn with
                    | Option.none => Option.none
                    | Option.some head =>
                        match head.node with
                        | PsKernelExprV2Node.fvar _ =>
                            Option.some (Prod.mk leftArg rightArg)
                        | _ => Option.none
                  else Option.none
              | _ => Option.none
          | _ => Option.none

def psKernelExprV2UnarySpinePlanWithFuel
    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat) :
    Option PsKernelExprV2UnarySpinePlan :=
  match fuel with
  | Nat.zero => Option.none
  | Nat.succ remaining =>
      match psKernelExprV2UnarySpineView arena left right with
      | Option.none =>
          Option.some (PsKernelExprV2UnarySpinePlan.mk left right 0)
      | Option.some pair =>
          match psKernelExprV2UnarySpinePlanWithFuel remaining arena
              (Prod.fst pair) (Prod.snd pair) with
          | Option.none => Option.none
          | Option.some plan =>
              Option.some (PsKernelExprV2UnarySpinePlan.mk
                plan.left plan.right (Nat.succ plan.skipped))

def psKernelExprV2UnarySpineContext
    (count : Nat) (context : PsKernelExprV2CheckContext) :
    Except String PsKernelExprV2CheckContext :=
  match count with
  | Nat.zero => Except.ok context
  | Nat.succ remaining =>
      match psKernelExprV2CheckContextEnterRecDepth context with
      | Except.error error => Except.error error
      | Except.ok next => psKernelExprV2UnarySpineContext remaining next

def psKernelExprV2TryUnarySpineWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2PagedFind state.whnf.arena left with
  | Option.none => Option.none
  | Option.some leftEntry =>
      match psKernelExprV2PagedFind state.whnf.arena right with
      | Option.none => Option.none
      | Option.some rightEntry =>
          match psKernelExprV2UnarySpinePlanWithFuel
              (Nat.succ (Nat.add leftEntry.depth rightEntry.depth))
              state.whnf.arena left right with
          | Option.none => Option.none
          | Option.some plan =>
              if Nat.ble 2 plan.skipped then
                match psKernelExprV2UnarySpineContext (Nat.sub plan.skipped 1) context with
                | Except.error _ => Option.none
                | Except.ok next => defeq next state plan.left plan.right
              else Option.none
