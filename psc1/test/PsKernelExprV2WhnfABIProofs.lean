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
      let ownedLocalValue := psKernelExprV2LiftLocalValue localValue;
      let reducer :=
        fun (nextContext : PsKernelExprV2CheckContext) (nextState : PsKernelExprV2CheckState)
            (nextRoot : Nat) (nextCheapRec nextCheapProj : Bool) =>
          let worker := psKernelExprV2TryReduceRecursorOwnedWithFuel fuel;
          worker psKernelExprV2NoOwnedDefEq ownedLocalValue
            nextContext nextState nextRoot nextCheapRec nextCheapProj;
      psKernelExprV2LowerWhnfAttempt
        (psKernelExprV2TryWhnfCoreOwnedModeWithReducerFuel fuel
          false cheapProj ownedLocalValue (psKernelExprV2LiftScalarWhnf publicWhnf)
          reducer (psKernelExprV2CheckContextEmpty context)
          (psKernelExprV2CheckStateFromWhnf state) root)) := by
  cases fuel <;> rfl

theorem public_wrapper_keeps_exact_operation (fuel : Nat) :
    psKernelExprV2TryWhnfStateWithLocalValuesFuel fuel =
    (fun (localValue : PsKernelName -> Option Nat)
        (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState) (root : Nat) =>
      psKernelExprV2LowerWhnfAttempt
        (psKernelExprV2TryWhnfOwnedWithLocalValuesFuel fuel
          psKernelExprV2NoOwnedDefEq (psKernelExprV2LiftLocalValue localValue)
          (psKernelExprV2CheckContextEmpty context)
          (psKernelExprV2CheckStateFromWhnf state) root)) := by
  cases fuel <;> rfl

end PsKernelExprV2WhnfABIProofs

#print axioms PsKernelExprV2WhnfABIProofs.core_wrapper_keeps_exact_operation
#print axioms PsKernelExprV2WhnfABIProofs.public_wrapper_keeps_exact_operation
