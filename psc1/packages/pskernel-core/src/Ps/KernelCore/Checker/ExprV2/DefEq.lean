import Ps.KernelCore.Checker.ExprV2.DefEq.Prefix
import Ps.KernelCore.Checker.ExprV2.CheckWhnf
import Ps.KernelCore.Checker.ExprV2.CheckCore
import Ps.KernelCore.Checker.ExprV2.DefEq.ProofIrrelevance
import Ps.KernelCore.Checker.ExprV2.DefEq.LazyDelta
import Ps.KernelCore.Checker.ExprV2.DefEq.FullShape

/- Single recursive DefEq owner. The ordered prefix and proof irrelevance
share inference-only/WHNF/DefEq callbacks at the exact predecessor fuel.
The complete ordered lazy-delta stage uses that same owner and admitted body
IDs. Residual full-WHNF and full-shape rules retain the same callback owner.
Matching projection and structure/string/unit terminal rules remain explicit
unsupported paths; no partial state escapes into the reference fallback. -/
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
        let coreWhnfMode :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) (cheapProj : Bool) =>
            psKernelExprV2CheckWhnfCoreWithFuel remaining nextContext nextState nextRoot cheapProj;
        let coreWhnf :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2WhnfState) (nextRoot : Nat) =>
            coreWhnfMode nextContext nextState nextRoot true;
        let inferType :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
            let worker := psKernelExprV2TryInferCoreWithFuel remaining;
            worker whnf smaller nextContext nextState nextRoot true;
        let afterLazy :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextLeft nextRight : Nat) =>
            psKernelExprV2DefEqResidualWith smaller inferType whnf coreWhnfMode
              nextContext nextState nextLeft nextRight;
        let afterProof :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextLeft nextRight : Nat) =>
            psKernelExprV2DefEqLazyDeltaContinueWithFuel remaining afterLazy smaller whnf coreWhnfMode
              nextContext nextState nextLeft nextRight;
        let afterCore :=
          fun (nextContext : PsKernelExprV2CheckContext)
              (nextState : PsKernelExprV2CheckState) (nextLeft nextRight : Nat) =>
            psKernelExprV2DefEqProofIrrelevanceContinueWith afterProof smaller inferType whnf
              nextContext nextState nextLeft nextRight;
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
                      else psKernelExprV2DefEqPrefixContinueWith afterCore smaller whnf coreWhnf
                        nextContext state left right

/- Public helper retains the same owning declaration index as inference/WHNF.
It starts fresh semantic caches; references must come from this validated batch. -/
def psKernelExprV2TryDefEqWithDeclarationsFuel
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) (left right : Nat) :
    Option (Except String Bool) :=
  match context.localContext.decls with
  | List.cons _ _ => Option.none
  | List.nil =>
      let initial :=
        psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
          (psKernelExprV2WhnfStateForDeclarations arena declarations);
      match psKernelExprV2TryDefEqStateWithFuel fuel
          (psKernelExprV2CheckContextEmpty context) initial left right with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok result => Option.some (Except.ok (Prod.snd result))

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
        match psKernelCheckerContextEnterRecDepth context with
        | Except.error error => Option.some (Except.error error)
        | Except.ok _ =>
            psKernelExprV2TryDefEqWithDeclarationsFuel (Nat.succ remaining)
              context arena List.nil left right
