import Ps.KernelCore.Checker.ExprV2.CheckState
import Ps.KernelCore.Checker.ExprV2.Whnf

/-
Checked inference resolves local let values in its owning canonical arena.
The external entry admits no legacy local context; the explicit guard also
prevents a value-free typed shadow from exposing a legacy local let value.
-/
def psKernelExprV2CheckWhnfWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2WhnfState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2WhnfState Nat)) :=
  match context.scalar.localContext.decls with
  | List.cons _ _ => Option.none
  | List.nil =>
      let localValue :=
        fun (name : PsKernelName) => psKernelExprV2CheckLocalValue context name;
      psKernelExprV2TryWhnfStateWithLocalValuesFuel fuel localValue
        context.scalar state root
