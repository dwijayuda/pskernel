import Ps.KernelCore.Checker.DefEq.Quick
import Ps.KernelCore.Checker.ExprV2.CheckState
import Ps.KernelCore.Checker.ExprV2.DefEq.BinderSpines

/-
The definitive quick rules of the complete checker on a canonical DAG.
Fuel and recursion-depth guards precede syntax and successful-pair lookup.
The operation-owned success set excludes pairs flagged with free variables and
is restored when a checking scope closes. Hashes never authorize a comparison.

Some (ok false) is a definitive original quick-rule result. None requests the
complete algorithm with its original fuel, context and state. No partial
state is returned for an unsupported descendant. The fresh public wrapper
shares these rules and discards its private cache on return.
-/
def psKernelExprV2DefEqFinishAttempt
    (left right : Nat)
    (attempt : Option (Except String (Prod PsKernelExprV2CheckState Bool))) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match attempt with
  | Option.none => Option.none
  | Option.some result =>
      match result with
      | Except.error error => Option.some (Except.error error)
      | Except.ok compared =>
          Option.some
            (psKernelExprV2CheckStateDefEqFinish
              (Prod.fst compared) left right (Prod.snd compared))

def psKernelExprV2TryDefEqStateWithFuel
    (fuel : Nat) :
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelExprV2CheckContext)
          (_state : PsKernelExprV2CheckState) (_left _right : Nat) =>
        Option.some (Except.error "kernel definitional equality budget exhausted")
  | Nat.succ remaining =>
      fun (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (left right : Nat) =>
        let smaller :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextLeft nextRight : Nat) =>
            let recur := psKernelExprV2TryDefEqStateWithFuel remaining;
            recur nextContext nextState nextLeft nextRight;
        match psKernelExprV2CheckContextEnterRecDepth context with
        | Except.error error => Option.some (Except.error error)
        | Except.ok nextContext =>
            match psKernelExprV2PagedEqOnCanonical state.whnf.arena left right with
            | Except.error error => Option.some (Except.error error)
            | Except.ok equal =>
                if equal then
                  Option.some (psKernelExprV2CheckStateDefEqFinish state left right true)
                else
                  match psKernelExprV2DefEqPairContains
                      state.whnf.arena state.success left right with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok cached =>
                      if cached then Option.some (Except.ok (Prod.mk state true))
                      else
                        match psKernelExprV2PagedRequire state.whnf.arena left with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok leftEntry =>
                            match psKernelExprV2PagedRequire state.whnf.arena right with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok rightEntry =>
                                match leftEntry.node with
                                | PsKernelExprV2Node.lam _ _ _ _ =>
                                    match rightEntry.node with
                                    | PsKernelExprV2Node.lam _ _ _ _ =>
                                        psKernelExprV2DefEqFinishAttempt left right
                                          (psKernelExprV2DefEqBinderSpine true
                                            smaller nextContext state left right)
                                    | _ => Option.none
                                | PsKernelExprV2Node.forallE _ _ _ _ =>
                                    match rightEntry.node with
                                    | PsKernelExprV2Node.forallE _ _ _ _ =>
                                        psKernelExprV2DefEqFinishAttempt left right
                                          (psKernelExprV2DefEqBinderSpine false
                                            smaller nextContext state left right)
                                    | _ => Option.none
                                | PsKernelExprV2Node.sort leftLevel =>
                                    match rightEntry.node with
                                    | PsKernelExprV2Node.sort rightLevel =>
                                        Option.some
                                          (psKernelExprV2CheckStateDefEqFinish state left right
                                            (psKernelLevelEquivalent leftLevel rightLevel))
                                    | _ => Option.none
                                | PsKernelExprV2Node.lit leftLiteral =>
                                    match rightEntry.node with
                                    | PsKernelExprV2Node.lit rightLiteral =>
                                        Option.some
                                          (psKernelExprV2CheckStateDefEqFinish state left right
                                            (psKernelLiteralEq leftLiteral rightLiteral))
                                    | _ => Option.none
                                | PsKernelExprV2Node.mdata _ leftBody =>
                                    match rightEntry.node with
                                    | PsKernelExprV2Node.mdata _ rightBody =>
                                        psKernelExprV2DefEqFinishAttempt left right
                                          (smaller nextContext state leftBody rightBody)
                                    | _ => Option.none
                                | _ => Option.none

def psKernelExprV2TryQuickDefEqWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2PagedArena -> Nat -> Nat ->
    Option (Except String Bool) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_arena : PsKernelExprV2PagedArena) (_left _right : Nat) =>
        Option.some (Except.error "kernel definitional equality budget exhausted")
  | Nat.succ remaining =>
      fun (context : PsKernelCheckerContext)
          (arena : PsKernelExprV2PagedArena) (left right : Nat) =>
        match psKernelExprV2TryDefEqStateWithFuel (Nat.succ remaining)
            (psKernelExprV2CheckContextEmpty context)
            (psKernelExprV2CheckStateEmpty arena) left right with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok result => Option.some (Except.ok (Prod.snd result))
