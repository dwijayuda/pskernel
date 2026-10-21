import Ps.KernelCore.Checker.ExprV2.Whnf

/-
Typed WHNF carries the complete state owned by the checker. The local-value
getter reads the context supplied at each callback, including newly opened
typed binders. Mixed legacy local contexts still request fallback before WHNF;
a value-free typed shadow must not reveal a legacy local let.

The original WhnfState signatures remain standalone compatibility wrappers.
-/
def psKernelExprV2CheckWhnfOwnedWithFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match context.scalar.localContext.decls with
  | List.cons _ _ => Option.none
  | List.nil =>
      psKernelExprV2TryWhnfOwnedWithLocalValuesFuel
        fuel defeq psKernelExprV2CheckLocalValue context state root

def psKernelExprV2CheckWhnfCoreOwnedWithFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match context.scalar.localContext.decls with
  | List.cons _ _ => Option.none
  | List.nil =>
      psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel
        fuel defeq psKernelExprV2CheckLocalValue context state root false cheapProj

def psKernelExprV2CheckWhnfWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2WhnfState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2LowerWhnfAttempt
    (psKernelExprV2CheckWhnfOwnedWithFuel fuel psKernelExprV2NoOwnedDefEq
      context (psKernelExprV2CheckStateFromWhnf state) root)

def psKernelExprV2CheckWhnfCoreWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2WhnfState) (root : Nat) (cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  psKernelExprV2LowerWhnfAttempt
    (psKernelExprV2CheckWhnfCoreOwnedWithFuel fuel psKernelExprV2NoOwnedDefEq
      context (psKernelExprV2CheckStateFromWhnf state) root cheapProj)
