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
  let ctx := GeneralPiContext.empty []
  let s0 : KExpr := .sort .zero
  let s1 : KExpr := .sort (.succ .zero)
  let count : Nat := 100000
  let betaAt : Nat → KExpr := fun i =>
    .app (.lam (.num .anonymous i) s1 (.bvar 0) .default) s0
  let letAt : Nat → KExpr := fun i =>
    .letE (.num .anonymous i) s1 s0 (.bvar 0) false
  let terms : Array KExpr := (List.range 127).toArray.map betaAt
  let lets : Array KExpr := (List.range 127).toArray.map letAt
  if terms.size == 0 || lets.size == 0 then
    throw (IO.userError "typed microbenchmark fixture array is empty")

  for i in [0:256] do
    let term := terms[i % terms.size]!
    unless (compareTypedHead ctx term s0 1).isEqual do
      throw (IO.userError "G4.4a warmup failed")

  let t0 ← IO.monoNanosNow
  let mut inferred : Nat := 0
  for i in [0:count] do
    let term := terms[i % terms.size]!
    match ctx.infer term with
    | some _ => inferred := inferred + 1
    | none => throw (IO.userError "typed inference baseline failed")
  let t1 ← IO.monoNanosNow

  let mut reflexive : Nat := 0
  for i in [0:count] do
    let term := terms[i % terms.size]!
    if (compareTypedHead ctx term term 1).isEqual then
      reflexive := reflexive + 1
    else
      throw (IO.userError "typed reflexivity benchmark declined")
  let t2 ← IO.monoNanosNow

  let mut betaCount : Nat := 0
  for i in [0:count] do
    let term := terms[i % terms.size]!
    if (compareTypedHead ctx term s0 1).isEqual then
      betaCount := betaCount + 1
    else
      throw (IO.userError "typed beta benchmark declined")
  let t3 ← IO.monoNanosNow

  let mut zetaCount : Nat := 0
  for i in [0:count] do
    let term := lets[i % lets.size]!
    if (compareTypedHead ctx term s0 1).isEqual then
      zetaCount := zetaCount + 1
    else
      throw (IO.userError "typed let benchmark declined")
  let t4 ← IO.monoNanosNow

  unless inferred == count && reflexive == count &&
      betaCount == count && zetaCount == count do
    throw (IO.userError "typed work counter unexpectedly short")

  let inferNs := t1-t0
  let reflNs := t2-t1
  let betaNs := t3-t2
  let letNs := t4-t3
  IO.println s!"PSKernel-Fast G4.4a typed microbench: {count} runtime-indexed terms per family; infer={inferNs}ns ({inferNs/count}ns/op), reflexive={reflNs}ns ({reflNs/count}ns/op), beta={betaNs}ns ({betaNs/count}ns/op), let={letNs}ns ({letNs/count}ns/op)"
  IO.println "Includes input-array lookup but excludes fixture construction and executable startup; no official kernel/RSS comparison"


end PSKernelFast.Core

def main : IO Unit :=
  PSKernelFast.Core.typedConversionBench
