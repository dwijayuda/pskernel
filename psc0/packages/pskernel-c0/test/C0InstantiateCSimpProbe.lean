import Ps.KernelCore.Architecture.CertifiedInstantiateMemo

/-!
Native-code regression specifically calls the ORIGINAL source symbol
psKernelExprInstantiate1. The Lean-checked @[csimp] function equality
must replace it in generated code, not weaken the logical checker.

The term shares 2^28 application leaves; naive substitution would expand
the entire tree. The source proof separately establishes exact semantics.
-/
def main : IO Unit := do
  let replacement : PsKernelExpr := .fvar (.str .anonymous "compiled")
  let depth := 28
  let term := (List.range depth).foldl
    (fun e (_ : Nat) => .app e e) (PsKernelExpr.bvar 0)
  let began ← IO.monoNanosNow
  let result := psKernelExprInstantiate1 term replacement
  let elapsed ← IO.monoNanosNow
  if psKernelExprGetAppNumArgs result != depth ||
      !psKernelExprEqual (psKernelExprGetAppFn result) replacement then
    throw (IO.userError "native csimp instantiation gave incorrect spine or leaf")
  IO.println s!"C0_INSTANTIATE_CSIMP_NATIVE shared_depth={depth} exact_source=Lean_proved elapsed_ms={(elapsed-began)/1000000}"
