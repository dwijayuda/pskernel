import KernelCore.Bench.CrossRuntime
import KernelCore.Foundation.Core

def main (args : List String) : IO Unit := do
  let kind := (args.headD "0").toNat!
  if kind > 2 then throw (IO.userError "invalid workload")
  if !psKernelCrossGuards then throw (IO.userError "cross-runtime guards failed")
  for i in [0:27] do
    for j in [0:27] do
      if !(psKernelExprDifferentialPair (psKernelCrossEqualityEntry i).fst (psKernelCrossEqualityEntry j).fst) then
        throw (IO.userError "frozen-reference equality mismatch")
  let inputs := (List.range 16).toArray.map (psKernelCrossInput kind)
  let fallback := psKernelCrossInput kind 0
  let mut hits := 0
  -- Sequence calls in IO and vary inputs; keep fixture construction untimed.
  for i in [0:100] do
    if !(psKernelCrossRun kind (inputs.getD (i % 16) fallback)) then
      throw (IO.userError "warmup failed")
  let start ← IO.monoNanosNow
  for i in [0:1000] do
    if psKernelCrossRun kind (inputs.getD (i % 16) fallback) then hits := hits + 1
  let elapsed := (← IO.monoNanosNow) - start
  if hits != 1000 then throw (IO.userError "operation failed")
  IO.println s!"CROSS_NATIVE {kind} {hits} {elapsed}"
