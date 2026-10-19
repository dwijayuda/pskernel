import Ps.KernelCore.Architecture.CertifiedInstantiateMemo
import Lean

/-!
A structural *no-substitution* certificate, deliberately separate from native
cache implementation. It allows stopping before hash-trie recursion only when
the immutable bound proves all bound-variable indices are below this offset.
-/

/-! Source proof is now compiled as part of CertifiedInstantiateMemo.lean;
the standalone regression uses that production theorem without redefinition. -/

def c0NoSubstShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, e => e
  | n+1, e => let t := c0NoSubstShared n e; .app t t

def main : IO Unit := do
  let a : PsKernelName := .str .anonymous "closed"
  let closed := c0NoSubstShared 4000 (.const a [])
  if closed.psKernelC0LooseBVarBound != 0 then
    throw (IO.userError "closed shared DAG has unexpected free BVar bound")
  let xs : List PsKernelExpr := [
    .bvar 0, .bvar 1, .app (.bvar 0) (.sort .zero),
    .lam a (.sort .zero) (.bvar 0) .default,
    .forallE a (.sort .zero) (.bvar 0) .default,
    .letE a (.sort .zero) (.sort .zero) (.bvar 0) false,
    .mdata 0 (.sort .zero), .proj a 0 (.sort .zero)
  ]
  for expr in xs do
    for offset in [0,1,2,4] do
      if expr.psKernelC0LooseBVarBound ≤ offset then
        let src := psKernelC0ExprInstantiateOneChanged expr (.bvar 5) offset
        if src != (expr,false) then
          throw (IO.userError "source closed-substitution proof mismatch")
  IO.println "C0_NO_SUBST_FROM_BOUND source=Lean_proved all_offsets=true 4000_shared_DAG=proof only no_admission=true"
