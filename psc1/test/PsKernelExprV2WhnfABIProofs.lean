import Ps.KernelCore.Checker.ExprV2.Whnf

/- Local equality of the staged compatibility wrappers to their pre-repair
   bodies. PSC1's external arity is separately exercised by real generated
   calls at fuel zero and successor; these are not compiler correctness proofs. -/
namespace PsKernelExprV2WhnfABIProofs

theorem core_wrapper_keeps_exact_operation (fuel : Nat) :
    psKernelExprV2TryWhnfCoreModeWithLocalValuesFuel fuel =
    (fun (cheapProj : Bool) (localValue : PsKernelName -> Option Nat)
        (publicWhnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
          Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
        (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState) (root : Nat) =>
      let reducer :=
        fun (nextContext : PsKernelCheckerContext) (nextState : PsKernelExprV2WhnfState)
            (nextRoot : Nat) (nextCheapProj : Bool) =>
          let worker := psKernelExprV2TryReduceRecursorWithLocalValuesFuel fuel;
          worker localValue nextContext nextState nextRoot nextCheapProj;
      psKernelExprV2TryWhnfCoreModeWithReducerFuel fuel
        cheapProj localValue publicWhnf reducer context state root) := by
  cases fuel <;> rfl

theorem public_wrapper_keeps_exact_operation (fuel : Nat) :
    psKernelExprV2TryWhnfStateWithLocalValuesFuel fuel =
    (fun (localValue : PsKernelName -> Option Nat)
        (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState) (root : Nat) =>
      let reducer :=
        fun (nextContext : PsKernelCheckerContext) (nextState : PsKernelExprV2WhnfState)
            (nextRoot : Nat) (nextCheapProj : Bool) =>
          let worker := psKernelExprV2TryReduceRecursorWithLocalValuesFuel fuel;
          worker localValue nextContext nextState nextRoot nextCheapProj;
      psKernelExprV2TryWhnfStateWithReducerFuel fuel reducer localValue context state root) := by
  cases fuel <;> rfl

end PsKernelExprV2WhnfABIProofs

#print axioms PsKernelExprV2WhnfABIProofs.core_wrapper_keeps_exact_operation
#print axioms PsKernelExprV2WhnfABIProofs.public_wrapper_keeps_exact_operation
