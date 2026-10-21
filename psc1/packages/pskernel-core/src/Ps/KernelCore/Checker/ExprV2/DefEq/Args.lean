import Ps.KernelCore.Checker.ExprV2.CheckState
import Ps.KernelCore.Core.ExprV2.Transform

/- Same-definition shortcuts compare the outermost (rightmost) argument first.
The traversal budget is separate from the fixed injected DefEq callback.
An arity mismatch is observed only when the original traversal reaches it. -/
def psKernelExprV2DefEqArgsWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match fuel with
  | Nat.zero =>
      fun (_defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
          (_left _right : Nat) =>
        Option.some (Except.error "kernel defeq argument budget exhausted")
  | Nat.succ remaining =>
      fun (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
          (left right : Nat) =>
        match psKernelExprV2PagedRequire state.whnf.arena left with
        | Except.error error => Option.some (Except.error error)
        | Except.ok leftEntry =>
            match psKernelExprV2PagedRequire state.whnf.arena right with
            | Except.error error => Option.some (Except.error error)
            | Except.ok rightEntry =>
                match leftEntry.node with
                | PsKernelExprV2Node.app leftFn leftArg =>
                    match rightEntry.node with
                    | PsKernelExprV2Node.app rightFn rightArg =>
                        match defeq context state leftArg rightArg with
                        | Option.none => Option.none
                        | Option.some attempted =>
                            match attempted with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok compared =>
                                if Prod.snd compared then
                                  let recur := psKernelExprV2DefEqArgsWithFuel remaining;
                                  recur defeq context (Prod.fst compared) leftFn rightFn
                                else Option.some (Except.ok compared)
                    | _ => Option.some (Except.ok (Prod.mk state false))
                | _ =>
                    match rightEntry.node with
                    | PsKernelExprV2Node.app _ _ =>
                        Option.some (Except.ok (Prod.mk state false))
                    | _ => Option.some (Except.ok (Prod.mk state true))

def psKernelExprV2DefEqArgs
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2TransformCountOnCanonical state.whnf.arena left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftCount =>
      match psKernelExprV2TransformCountOnCanonical state.whnf.arena right with
      | Except.error error => Option.some (Except.error error)
      | Except.ok rightCount =>
          psKernelExprV2DefEqArgsWithFuel (Nat.succ (Nat.add leftCount rightCount))
            defeq context state left right
