import PSKernelFast.Reduction

namespace PSKernelFast

/-!
Repeated exploratory timing ONLY for untyped beta WHNF on closed RawExpr.
Both engines receive the same decoded inputs. No checking, conversion,
inductive admission, proof soundness, Lean reference parity or binary-size
claims follow from this benchmark.
-/

private def benchEager (inputs : Array RawExpr) (iterations : Nat) :
    IO (Nat × Nat) := do
  let start ← IO.monoMsNow
  let mut digest : Nat := 0
  for _ in [:iterations] do
    for term in inputs do
      match eagerWHNF 200 term with
      | .ok result => digest := digest + rawSize result
      | .error err => throw <| IO.userError s!"eager benchmark failure: {repr err}"
  let elapsed := (← IO.monoMsNow) - start
  return (elapsed, digest)

private def benchLazy (inputs : Array RawExpr) (iterations : Nat) :
    IO (Nat × Nat) := do
  let start ← IO.monoMsNow
  let mut digest : Nat := 0
  for _ in [:iterations] do
    for term in inputs do
      match lazyWHNF 600 100 term with
      | .ok result => digest := digest + rawSize result
      | .error err => throw <| IO.userError s!"lazy benchmark failure: {repr err}"
  let elapsed := (← IO.monoMsNow) - start
  return (elapsed, digest)

private def median (measurements : Array Nat) : Nat :=
  (measurements.toList.mergeSort (fun a b => a <= b)).getD (measurements.size / 2) 0

def reductionBenchmark : IO Unit := do
  let terms : Array RawExpr :=
    (List.range 28).toArray.map (fun i =>
      identityChain (35 + i % 13) (.sort (i % 31)))
  let mut inputs : Array RawExpr := #[]
  for t in terms do
    match encodeClosed 2000 t with
    | .error err => throw <| IO.userError s!"benchmark encode: {repr err}"
    | .ok (root, store) =>
        match decodeForEvaluation store root (store.nodes.size + 5) with
        | .error err => throw <| IO.userError s!"benchmark decode: {repr err}"
        | .ok decoded => inputs := inputs.push decoded

  let iterations := 180
  -- Warm both runtimes before measuring. Alternate order to reduce bias.
  discard <| benchEager inputs 2
  discard <| benchLazy inputs 2
  let mut eagerTimes : Array Nat := #[]
  let mut lazyTimes : Array Nat := #[]
  for sample in [:5] do
    if sample % 2 == 0 then
      let (eagerMs, eagerDigest) ← benchEager inputs iterations
      let (lazyMs, lazyDigest) ← benchLazy inputs iterations
      if eagerDigest != lazyDigest then
        throw <| IO.userError "benchmark digest mismatch"
      eagerTimes := eagerTimes.push eagerMs
      lazyTimes := lazyTimes.push lazyMs
    else
      let (lazyMs, lazyDigest) ← benchLazy inputs iterations
      let (eagerMs, eagerDigest) ← benchEager inputs iterations
      if eagerDigest != lazyDigest then
        throw <| IO.userError "benchmark digest mismatch"
      eagerTimes := eagerTimes.push eagerMs
      lazyTimes := lazyTimes.push lazyMs

  IO.println s!"G2 paired beta-only WHNF: samples_each={inputs.size * iterations} per repetition, repetitions=5"
  IO.println s!"eager_ms={eagerTimes.toList}, lazy_readback_ms={lazyTimes.toList}"
  IO.println s!"median_eager_ms={median eagerTimes}, median_lazy_readback_ms={median lazyTimes}"
  IO.println "LIMIT: tiny closed untyped beta calculus; no Lean kernel speedup claim, no memory benchmark"
end PSKernelFast

def main : IO Unit := PSKernelFast.reductionBenchmark
