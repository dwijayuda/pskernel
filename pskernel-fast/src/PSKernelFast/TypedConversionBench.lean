import PSKernelFast.TypedConversion

/-!
Microbenchmark of the ACTUAL bounded G4.3b/G4.4a type-checker and typed
head-conversion paths, after executable startup. Not a matched Lean kernel
or Mathlib benchmark and NOT evidence that the storage representation is
faster than official Lean, con-ron, or another kernel implementation.
No declarations are admitted. Report active loop work and timings only.
-/

namespace PSKernelFast.Core

def typedConversionBench : IO Unit := do
  let x : KName := .str .anonymous "x"
  let ctx := GeneralPiContext.empty []
  let s0 : KExpr := .sort .zero
  let s1 : KExpr := .sort (.succ .zero)
  let beta : KExpr := .app (.lam x s1 (.bvar 0) .default) s0
  let zeta : KExpr := .letE x s1 s0 (.bvar 0) false
  let count : Nat := 20000

  for _ in [0:256] do
    unless (compareTypedHead ctx beta s0 1).isEqual do
      throw (IO.userError "G4.4a warmup failed")

  let t0 ← IO.monoMsNow
  let mut inferred : Nat := 0
  for _ in [0:count] do
    match ctx.infer beta with
    | some _ => inferred := inferred + 1
    | none => throw (IO.userError "typed inference baseline failed")
  let t1 ← IO.monoMsNow

  let mut reflexive : Nat := 0
  for _ in [0:count] do
    if (compareTypedHead ctx s0 s0 1).isEqual then
      reflexive := reflexive + 1
    else
      throw (IO.userError "typed reflexivity benchmark declined")
  let t2 ← IO.monoMsNow

  let mut betaCount : Nat := 0
  for _ in [0:count] do
    if (compareTypedHead ctx beta s0 1).isEqual then
      betaCount := betaCount + 1
    else
      throw (IO.userError "typed beta benchmark declined")
  let t3 ← IO.monoMsNow

  let mut zetaCount : Nat := 0
  for _ in [0:count] do
    if (compareTypedHead ctx zeta s0 1).isEqual then
      zetaCount := zetaCount + 1
    else
      throw (IO.userError "typed let benchmark declined")
  let t4 ← IO.monoMsNow

  unless inferred == count && reflexive == count &&
      betaCount == count && zetaCount == count do
    throw (IO.userError "typed work counter unexpectedly short")

  IO.println s!"PSKernel-Fast G4.4a microbench: {count} iterations each; infer={t1-t0}ms, reflexive={t2-t1}ms, beta={t3-t2}ms, let={t4-t3}ms"
  IO.println "G4.4a benchmark is only a bounded typed-conversion baseline; no official Lean kernel throughput or RSS comparison"

end PSKernelFast.Core

def main : IO Unit :=
  PSKernelFast.Core.typedConversionBench
