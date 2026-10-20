import Ps.KernelCore.Checker.Context
import Ps.KernelCore.Core.ExprV2.Builder

/-
DAG terminal WHNF, with exactly the public/core entry budget distinction.
Public metadata recursion does not enter the recursion-depth guard. Lambda
WHNF enters core with the predecessor budget and then checks recursion depth.

The caller must first fully check the expression in a fresh public-operation
context. No reusable checker state is returned. Composite reductions request
the complete kernel by returning none; none never authorizes a verdict.
-/
def psKernelExprV2TryWhnfTerminalWithFuel
    (fuel : Nat) :
    PsKernelCheckerContext -> PsKernelExprV2PagedArena -> Nat ->
    Option (Except String Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsKernelCheckerContext)
          (_arena : PsKernelExprV2PagedArena) (_root : Nat) =>
        Option.some (Except.error "kernel reduction budget exhausted")
  | Nat.succ remaining =>
      let smaller := psKernelExprV2TryWhnfTerminalWithFuel remaining;
      fun (context : PsKernelCheckerContext)
          (arena : PsKernelExprV2PagedArena) (root : Nat) =>
        match psKernelExprV2PagedRequire arena root with
        | Except.error error => Option.some (Except.error error)
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.bvar _ => Option.some (Except.ok root)
            | PsKernelExprV2Node.mvar _ => Option.some (Except.ok root)
            | PsKernelExprV2Node.sort _ => Option.some (Except.ok root)
            | PsKernelExprV2Node.forallE _ _ _ _ => Option.some (Except.ok root)
            | PsKernelExprV2Node.lit _ => Option.some (Except.ok root)
            | PsKernelExprV2Node.mdata _ body => smaller context arena body
            | PsKernelExprV2Node.lam _ _ _ _ =>
                if Nat.beq remaining 0 then
                  Option.some (Except.error "kernel reduction budget exhausted")
                else
                  match psKernelCheckerContextEnterRecDepth context with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok _ => Option.some (Except.ok root)
            | _ => Option.none

/-
The same-arena identity shortcut runs only after both full public checks.
It retains IsDefEqWithFuel's entry fuel and recursion-depth checks. Its
discarded fresh cache state cannot authorize a different operation.
-/
def psKernelExprV2CheckedIdentity
    (fuel : Nat) (context : PsKernelCheckerContext) :
    Except String Bool :=
  if Nat.beq fuel 0 then
    Except.error "kernel definitional equality budget exhausted"
  else
    match psKernelCheckerContextEnterRecDepth context with
    | Except.error error => Except.error error
    | Except.ok _ => Except.ok true
