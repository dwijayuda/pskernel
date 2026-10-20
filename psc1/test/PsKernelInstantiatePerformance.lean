import Ps.KernelCore.SelfHost

/-
PSC1/C0 experimental single-substitution benchmark. Both paths operate in
the same native process with parity checked before timing. The previous
bounded source is now also the production implementation; the C0 worker is
retained only for research. These are informational helper timings, not a
whole-checker performance claim.
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
      then Prod.fst (psKernelC0ExprInstantiateOneChanged e replacement 0)
      else inst1Prior e replacement
    checksum := checksum + psKernelExprNodeCount actual
  pure checksum

private def inst1Benchmark
    (depth times : Nat) : IO Unit := do
  let term := inst1AppSpine depth
  let rep := PsKernelExpr.bvar 3
  unless psKernelExprEq (inst1Prior term rep)
      (Prod.fst (psKernelC0ExprInstantiateOneChanged term rep 0)) &&
      psKernelExprEq (inst1Prior term rep)
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
