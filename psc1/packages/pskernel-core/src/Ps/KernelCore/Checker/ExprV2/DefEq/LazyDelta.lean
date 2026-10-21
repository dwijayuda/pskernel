import Ps.KernelCore.Checker.ExprV2.DefEq.LazyNat
import Ps.KernelCore.Checker.ExprV2.DefEq.DeltaStep

/- The lazy loop spends only its own predecessor when a single step continues.
The DefEq, public WHNF and core WHNF callbacks remain fixed for the owning
DefEq entry. A residual is passed to its explicit later-stage continuation.
Neither a residual nor a missing admitted body can become a negative result. -/
def psKernelExprV2DefEqLazyDeltaAfterStepOwnedWith
    (resume : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2DefEqLazyStepOwnedWith defeq coreWhnf context state left right with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok stepped =>
          let next := Prod.fst stepped;
          match Prod.snd stepped with
          | PsKernelExprV2DeltaStepResult.continue nextLeft nextRight =>
              resume context next nextLeft nextRight
          | PsKernelExprV2DeltaStepResult.unknown nextLeft nextRight =>
              continuation context next nextLeft nextRight
          | PsKernelExprV2DeltaStepResult.equal =>
              Option.some (Except.ok (Prod.mk next true))
          | PsKernelExprV2DeltaStepResult.different _ _ =>
              Option.some (Except.ok (Prod.mk next false))

def psKernelExprV2DefEqLazyDeltaContinueOwnedWithFuel
    (fuel : Nat)
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match fuel with
  | Nat.zero => Option.some (Except.error "kernel lazy-delta budget exhausted")
  | Nat.succ remaining =>
      let resume :=
        fun (nextContext : PsKernelExprV2CheckContext)
            (nextState : PsKernelExprV2CheckState) (nextLeft nextRight : Nat) =>
          psKernelExprV2DefEqLazyDeltaContinueOwnedWithFuel remaining
            continuation defeq whnf coreWhnf nextContext nextState nextLeft nextRight;
      let afterNat :=
        fun (nextContext : PsKernelExprV2CheckContext)
            (nextState : PsKernelExprV2CheckState) (nextLeft nextRight : Nat) =>
          psKernelExprV2DefEqLazyDeltaAfterStepOwnedWith resume continuation defeq coreWhnf
            nextContext nextState nextLeft nextRight;
      psKernelExprV2DefEqLazyNatContinueOwnedWithFuel (Nat.succ remaining)
        afterNat defeq whnf context state left right

def psKernelExprV2DefEqLazyDeltaOwnedWithFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyDeltaContinueOwnedWithFuel fuel psKernelExprV2DefEqLazyNatUnsupported
    defeq whnf coreWhnf context state left right

/- Original WHNF-only callback signatures remain compatibility wrappers.
   Each callback is lifted against the actual complete state at its call. -/

def psKernelExprV2DefEqLazyDeltaAfterStepWith
    (resume : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyDeltaAfterStepOwnedWith
    resume continuation defeq (psKernelExprV2LiftCheckCoreWhnf coreWhnf) context state left right

def psKernelExprV2DefEqLazyDeltaContinueWithFuel
    (fuel : Nat)
    (continuation : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyDeltaContinueOwnedWithFuel
    fuel continuation defeq (psKernelExprV2LiftCheckWhnf whnf) (psKernelExprV2LiftCheckCoreWhnf coreWhnf) context state left right

def psKernelExprV2DefEqLazyDeltaWithFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (coreWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2WhnfState -> Nat -> Bool ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  psKernelExprV2DefEqLazyDeltaOwnedWithFuel
    fuel defeq (psKernelExprV2LiftCheckWhnf whnf) (psKernelExprV2LiftCheckCoreWhnf coreWhnf) context state left right
