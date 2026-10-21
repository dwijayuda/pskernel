import Ps.KernelCore.Checker.ExprV2.WhnfOwned
import Ps.KernelCore.Checker.ExprV2.Recursor
import Ps.KernelCore.Checker.ExprV2.CheckCore

/-
The DAG callback knot owns full checker state. It deliberately does not import
DefEq: its caller supplies the fixed DefEq callback belonging to that operation.

A bounded recursor at succ r creates public/core WHNF and infer-only callbacks
at r, and a nested recursor at r. The supplied DefEq callback is unchanged.
Structural WHNF recursion keeps these recursor/public callbacks fixed while
decreasing its own fuel. No recursion-depth guard is added at recursor entry.

The carrier migration retains the explicit unsupported K/structure branches
in Recursor.lean. Supplying the complete state does not promote those rules.
-/

def psKernelExprV2TryReduceRecursorOwnedWithFuel
    (fuel : Nat) :
    (PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    (PsKernelExprV2CheckContext -> PsKernelName -> Option Nat) ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Bool -> Bool ->
    Option (Except String (Prod PsKernelExprV2CheckState (Option Nat))) :=
  match fuel with
  | Nat.zero =>
      fun (_defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (_localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
          (_context : PsKernelExprV2CheckContext) (_state : PsKernelExprV2CheckState)
          (_root : Nat) (_cheapRec _cheapProj : Bool) =>
        Option.some (Except.error "kernel recursor budget exhausted")
  | Nat.succ remaining =>
      fun (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
          (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
          (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
          (root : Nat) (cheapRec cheapProj : Bool) =>
        let reducer :=
          fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
              (nextRoot : Nat) (nextCheapRec nextCheapProj : Bool) =>
            let recur := psKernelExprV2TryReduceRecursorOwnedWithFuel remaining;
            recur defeq localValue nextContext nextState nextRoot nextCheapRec nextCheapProj;
        let publicWhnf :=
          fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
              (nextRoot : Nat) =>
            let worker := psKernelExprV2TryWhnfOwnedWithReducerFuel remaining;
            worker reducer localValue nextContext nextState nextRoot;
        let coreWhnf :=
          fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
              (nextRoot : Nat) (nextCheapRec nextCheapProj : Bool) =>
            let worker := psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel remaining;
            worker nextCheapRec nextCheapProj localValue publicWhnf reducer
              nextContext nextState nextRoot;
        let inferType :=
          fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
              (nextRoot : Nat) =>
            let worker := psKernelExprV2TryInferCoreOwnedWithFuel remaining;
            worker publicWhnf defeq nextContext nextState nextRoot true;
        psKernelExprV2TryReduceRecursorOwnedWith
          publicWhnf coreWhnf inferType defeq context state root cheapRec cheapProj

def psKernelExprV2TryWhnfOwnedWithLocalValuesFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  let reducer :=
    fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
        (nextRoot : Nat) (nextCheapRec nextCheapProj : Bool) =>
      let worker := psKernelExprV2TryReduceRecursorOwnedWithFuel fuel;
      worker defeq localValue nextContext nextState nextRoot nextCheapRec nextCheapProj;
  let worker := psKernelExprV2TryWhnfOwnedWithReducerFuel fuel;
  worker reducer localValue context state root

def psKernelExprV2TryWhnfCoreOwnedWithLocalValuesFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (cheapRec cheapProj : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  let reducer :=
    fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
        (nextRoot : Nat) (nextCheapRec nextCheapProj : Bool) =>
      let worker := psKernelExprV2TryReduceRecursorOwnedWithFuel fuel;
      worker defeq localValue nextContext nextState nextRoot nextCheapRec nextCheapProj;
  let publicWhnf :=
    fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
        (nextRoot : Nat) =>
      psKernelExprV2TryWhnfOwnedWithLocalValuesFuel
        fuel defeq localValue nextContext nextState nextRoot;
  let worker := psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel fuel;
  worker cheapRec cheapProj localValue publicWhnf reducer context state root

def psKernelExprV2TryInferenceOwnedWithLocalValuesFuel
    (fuel : Nat)
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (localValue : PsKernelExprV2CheckContext -> PsKernelName -> Option Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (root : Nat) (inferOnly : Bool) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  let publicWhnf :=
    fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
        (nextRoot : Nat) =>
      psKernelExprV2TryWhnfOwnedWithLocalValuesFuel
        fuel defeq localValue nextContext nextState nextRoot;
  let worker := psKernelExprV2TryInferCoreOwnedWithFuel fuel;
  worker publicWhnf defeq context state root inferOnly
