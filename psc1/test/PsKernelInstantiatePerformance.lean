import Ps.KernelCore.SelfHost

/-
PSC1/C0 single-substitution benchmark.  Both paths operate in the same native
process on source expressions, with parity checked before timing.
The original bounded generic substitution is retained as the oracle.
Measurements are informational, not acceptance proof or blanket speedup.
-/
private def inst1Prior (e r : PsKernelExpr) : PsKernelExpr :=
  if psKernelExprHasLooseBVar e then
    psKernelExprInstantiate e (List.cons r List.nil)
  else e

private def inst1AppSpine (depth : Nat) : PsKernelExpr :=
  match depth with
  | Nat.zero => PsKernelExpr.bvar 0
  | Nat.succ n =>
      PsKernelExpr.app (inst1AppSpine n) (PsKernelExpr.bvar 2)

private def inst1Repeat (optimized : Bool)
    (times : Nat) (e : PsKernelExpr) : IO Nat := do
  let mut checksum := 0
  for index in [:times] do
    let replacement := PsKernelExpr.bvar index
    let actual := if optimized
      then psKernelExprInstantiate1 e replacement
      else inst1Prior e replacement
    checksum := checksum + psKernelExprNodeCount actual
  pure checksum

private def inst1Benchmark
    (depth times : Nat) : IO Unit := do
  let term := inst1AppSpine depth
  let rep := PsKernelExpr.bvar 3
  unless psKernelExprEq (inst1Prior term rep)
      (psKernelExprInstantiate1 term rep) do
    throw (IO.userError "PSC1_C0_INST1_BENCH_PARITY_FAILED")
  let beforeStart ← IO.monoMsNow
  let baselineSum ← inst1Repeat false times term
  let beforeEnd ← IO.monoMsNow
  let afterStart ← IO.monoMsNow
  let candidateSum ← inst1Repeat true times term
  let afterEnd ← IO.monoMsNow
  unless baselineSum == candidateSum do
    throw (IO.userError "PSC1_C0_INST1_BENCH_CHECKSUM_FAILED")
  IO.println s!"PSC1_C0_INST1_BENCH depth={depth} calls={times} prior_ms={beforeEnd-beforeStart} c0_ms={afterEnd-afterStart} checksum={candidateSum}"

def main : IO Unit := do
  inst1Benchmark 12 25000
  inst1Benchmark 32 25000
  IO.println "PSC1_C0_INST1_BENCH: COMPLETE"
