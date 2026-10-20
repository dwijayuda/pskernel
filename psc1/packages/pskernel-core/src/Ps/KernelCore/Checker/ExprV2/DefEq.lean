import Ps.KernelCore.Checker.ExprV2.Whnf
import Ps.KernelCore.Core.ExprV2.Equality

/-
Syntactic success shortcut for a single validated arena. The caller has fully
checked both terms. DefEq's original entry guards run before syntax equality.
A false syntax result is only a request for the complete DefEq algorithm.
No expression judgment, context-sensitive cache or cross-arena memo survives.
-/
def psKernelExprV2TrySyntacticDefEq
    (fuel : Nat) (context : PsKernelCheckerContext)
    (arena : PsKernelExprV2PagedArena) (left right : Nat) :
    Except String Bool :=
  match psKernelExprV2CheckedIdentity fuel context with
  | Except.error error => Except.error error
  | Except.ok _ => psKernelExprV2PagedEqOnCanonical arena left right
