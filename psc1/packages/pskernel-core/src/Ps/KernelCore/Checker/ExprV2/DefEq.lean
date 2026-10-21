import Ps.KernelCore.Checker.ExprV2.DefEq.Prefix
import Ps.KernelCore.Checker.ExprV2.CheckWhnf

/- Single recursive DefEq owner. The supported ordered prefix stops before
proof irrelevance and lazy delta; unsupported work exports no partial state. -/
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
        let whnf :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
            psKernelExprV2CheckWhnfWithFuel remaining nextContext nextState nextRoot;
        let coreWhnf :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
            psKernelExprV2CheckWhnfCoreWithFuel remaining nextContext nextState nextRoot true;
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
                      else psKernelExprV2DefEqPrefixWith smaller whnf coreWhnf
                        nextContext state left right

/- Compatibility name and staged ABI share the one recursive owner. -/
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
