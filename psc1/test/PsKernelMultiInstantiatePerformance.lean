import Ps.KernelCore.SelfHost

/-
PSC1 native matched multi-substitution comparison. Original withFuel worker
uses exact expression node-count fuel, with identical inputs for the C0 worker.
Semantic parity and output checksums are required; wall time is advisory.
-/
private def multiAppSpine (depth : Nat) : PsKernelExpr :=
  match depth with
  | Nat.zero => PsKernelExpr.bvar 0
  | Nat.succ remaining =>
      PsKernelExpr.app (multiAppSpine remaining) (PsKernelExpr.bvar 3)

private def multiReference (expr : PsKernelExpr)
    (subst : List PsKernelExpr) : PsKernelExpr :=
  Prod.fst (psKernelExprInstantiateAtChangedWithFuel
    (Nat.succ (psKernelExprNodeCount expr)) expr 0 subst 0)

private def multiCandidate (expr : PsKernelExpr)
    (subst : List PsKernelExpr) : PsKernelExpr :=
  Prod.fst (psKernelExprInstantiateAtChanged expr 0 subst 0)

private def multiLoop (optimized : Bool)
    (times : Nat) (expr : PsKernelExpr) : IO Nat := do
  let mut checksum := 0
  for index in [:times] do
    let subst := [PsKernelExpr.bvar index, PsKernelExpr.sort PsKernelLevel.zero]
    let result := if optimized
      then multiCandidate expr subst else multiReference expr subst
    checksum := checksum + psKernelExprNodeCount result
  pure checksum

private def multiBenchmark (depth times : Nat) : IO Unit := do
  let term := multiAppSpine depth
  let sample := [PsKernelExpr.bvar 2, PsKernelExpr.sort PsKernelLevel.zero]
  unless psKernelExprEq (multiReference term sample) (multiCandidate term sample) do
    throw (IO.userError "PSC1_C0_MULTI_BENCH_PARITY_FAILED")
  let oldStart ← IO.monoMsNow
  let oldSum ← multiLoop false times term
  let oldStop ← IO.monoMsNow
  let newStart ← IO.monoMsNow
  let newSum ← multiLoop true times term
  let newStop ← IO.monoMsNow
  unless oldSum == newSum do
    throw (IO.userError "PSC1_C0_MULTI_BENCH_CHECKSUM_FAILED")
  IO.println s!"PSC1_C0_MULTI_BENCH depth={depth} calls={times} prior_ms={oldStop-oldStart} c0_ms={newStop-newStart} checksum={newSum}"

def main : IO Unit := do
  multiBenchmark 12 25000
  multiBenchmark 32 25000
  IO.println "PSC1_C0_MULTI_BENCH: COMPLETE"
