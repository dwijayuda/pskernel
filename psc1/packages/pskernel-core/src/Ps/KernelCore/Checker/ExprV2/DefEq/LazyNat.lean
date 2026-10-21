import Ps.KernelCore.Checker.ExprV2.CheckState
import Ps.KernelCore.Checker.ExprV2.Nat

/- Ordered Nat prefix of the original lazy-delta stage. The owning DefEq
entry supplies fixed predecessor-fuel callbacks. This helper has the separate
lazy-delta entry guard but consumes no extra recursion for zero/predecessor
or one-sided Nat reduction. A continuation receives only the state after both
Nat attempts. The compatibility entry retains its explicit unsupported boundary.

Only validated, canonical arena metadata supplies the free-variable decision.
Nat predecessors preserve exact syntax: one Nat.succ application or a positive
literal. No WHNF, numeral-size check or semantic cache is added to that rule. -/
def psKernelExprV2DefEqNatIsZero
    (arena : PsKernelExprV2PagedArena) (root : Nat) : Except String Bool :=
  match psKernelExprV2NatLiteralValue arena root with
  | Except.error error => Except.error error
  | Except.ok value =>
      match value with
      | Option.none => Except.ok false
      | Option.some number => Except.ok (Nat.beq number 0)

def psKernelExprV2DefEqNatPred
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Except String (Prod PsKernelExprV2CheckState (Option Nat)) :=
  match psKernelExprV2PagedRequire state.whnf.arena root with
  | Except.error error => Except.error error
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.lit literal =>
          match literal with
          | PsKernelLiteral.str _ => Except.ok (Prod.mk state Option.none)
          | PsKernelLiteral.nat number =>
              match number with
              | Nat.zero => Except.ok (Prod.mk state Option.none)
              | Nat.succ predecessor =>
                  match psKernelExprV2PagedMkLit state.whnf.arena
                      (PsKernelLiteral.nat predecessor) with
                  | Except.error error => Except.error error
                  | Except.ok built =>
                      Except.ok (Prod.mk
                        (psKernelExprV2CheckStateWithArena state (Prod.fst built))
                        (Option.some (Prod.snd built)))
      | PsKernelExprV2Node.app fn argument =>
          match psKernelExprV2PagedRequire state.whnf.arena fn with
          | Except.error error => Except.error error
          | Except.ok fnEntry =>
              match fnEntry.node with
              | PsKernelExprV2Node.const name levels =>
                  match levels with
                  | List.nil =>
                      if psKernelNameEq name psKernelNatSuccName then
                        Except.ok (Prod.mk state (Option.some argument))
                      else Except.ok (Prod.mk state Option.none)
                  | List.cons _ _ => Except.ok (Prod.mk state Option.none)
              | _ => Except.ok (Prod.mk state Option.none)
      | _ => Except.ok (Prod.mk state Option.none)

def psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2PagedRequire state.whnf.arena left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftEntry =>
      match psKernelExprV2PagedRequire state.whnf.arena right with
      | Except.error error => Option.some (Except.error error)
      | Except.ok rightEntry =>
          let eager :=
            if context.scalar.eagerReduce then true
            else if leftEntry.hasFVar then false
            else if rightEntry.hasFVar then false
            else true;
          if eager then
            match psKernelExprV2TryReduceNatOwnedWith whnf context
                state left with
            | Option.none => Option.none
            | Option.some attemptedLeft =>
                match attemptedLeft with
                | Except.error error => Option.some (Except.error error)
                | Except.ok leftResult =>
                    let afterLeft :=
                      Prod.fst leftResult;
                    match Prod.snd leftResult with
                    | Option.some value => defeq context afterLeft value right
                    | Option.none =>
                        match psKernelExprV2TryReduceNatOwnedWith whnf context
                            afterLeft right with
                        | Option.none => Option.none
                        | Option.some attemptedRight =>
                            match attemptedRight with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok rightResult =>
                                let afterRight :=
                                  Prod.fst rightResult;
                                match Prod.snd rightResult with
                                | Option.some value => defeq context afterRight left value
                                | Option.none => continuation context afterRight left right
          else continuation context state left right

/- A candidate literal predecessor is retained only when both sides have one.
Otherwise the original owner resumes; NatPred cannot publish semantic state. -/
def psKernelExprV2DefEqLazyNatPredContinueOwnedWith
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqNatPred state left with
  | Except.error error => Option.some (Except.error error)
  | Except.ok leftResult =>
      match Prod.snd leftResult with
      | Option.none =>
          psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith continuation defeq whnf
            context state left right
      | Option.some leftPred =>
          match psKernelExprV2DefEqNatPred (Prod.fst leftResult) right with
          | Except.error error => Option.some (Except.error error)
          | Except.ok rightResult =>
              match Prod.snd rightResult with
              | Option.some rightPred =>
                  defeq context (Prod.fst rightResult) leftPred rightPred
              | Option.none =>
                  psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith continuation defeq whnf
                    context state left right

def psKernelExprV2DefEqLazyNatContinueOwnedWithFuel
    (fuel : Nat)
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match fuel with
  | Nat.zero => Option.some (Except.error "kernel lazy-delta budget exhausted")
  | Nat.succ _ =>
      match psKernelExprV2DefEqNatIsZero state.whnf.arena left with
      | Except.error error => Option.some (Except.error error)
      | Except.ok leftZero =>
          if leftZero then
            match psKernelExprV2DefEqNatIsZero state.whnf.arena right with
            | Except.error error => Option.some (Except.error error)
            | Except.ok rightZero =>
                if rightZero then Option.some (Except.ok (Prod.mk state true))
                else psKernelExprV2DefEqLazyNatPredContinueOwnedWith continuation defeq whnf context state left right
          else psKernelExprV2DefEqLazyNatPredContinueOwnedWith continuation defeq whnf context state left right

/- Stable standalone Nat APIs retain the original unsupported result. -/
def psKernelExprV2DefEqLazyNatUnsupported
    (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
    (_left _right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  Option.none

def psKernelExprV2DefEqLazyNatAfterPredOwnedWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith psKernelExprV2DefEqLazyNatUnsupported
    defeq whnf context state left right

def psKernelExprV2DefEqLazyNatPredOwnedWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatPredContinueOwnedWith psKernelExprV2DefEqLazyNatUnsupported
    defeq whnf context state left right

def psKernelExprV2DefEqLazyNatOwnedWithFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatContinueOwnedWithFuel fuel psKernelExprV2DefEqLazyNatUnsupported
    defeq whnf context state left right

/- Original WHNF-only callback signatures remain compatibility wrappers.
   Each callback is lifted against the actual complete state at its call. -/

def psKernelExprV2DefEqLazyNatAfterPredContinueWith
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatAfterPredContinueOwnedWith
    continuation defeq (psKernelExprV2LiftCheckWhnf whnf) context state left right

def psKernelExprV2DefEqLazyNatPredContinueWith
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatPredContinueOwnedWith
    continuation defeq (psKernelExprV2LiftCheckWhnf whnf) context state left right

def psKernelExprV2DefEqLazyNatContinueWithFuel
    (fuel : Nat)
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatContinueOwnedWithFuel
    fuel continuation defeq (psKernelExprV2LiftCheckWhnf whnf) context state left right

def psKernelExprV2DefEqLazyNatAfterPredWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatAfterPredOwnedWith
    defeq (psKernelExprV2LiftCheckWhnf whnf) context state left right

def psKernelExprV2DefEqLazyNatPredWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatPredOwnedWith
    defeq (psKernelExprV2LiftCheckWhnf whnf) context state left right

def psKernelExprV2DefEqLazyNatWithFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyNatOwnedWithFuel
    fuel defeq (psKernelExprV2LiftCheckWhnf whnf) context state left right
