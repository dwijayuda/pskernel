import PSKernelFast.DagReduction

namespace PSKernelFast

/-!
Three-strategy exploratory beta-WHNF comparison. Same validated input terms,
prepared outside timing. This is NOT the full Lean proof kernel.
-/

private structure Trial where
  raw : RawExpr
  store : Store
  root : Nat

private def benchEager (inputs : Array Trial) (iterations : Nat) :
    IO (Nat × Nat) := do
  let start ← IO.monoMsNow
  let mut digest : Nat := 0
  for _ in [:iterations] do
    for input in inputs do
      match eagerWHNF 200 input.raw with
      | .ok result => digest := digest + rawSize result
      | .error err => throw <| IO.userError s!"eager benchmark: {repr err}"
  return ((← IO.monoMsNow) - start, digest)

private def benchLazy (inputs : Array Trial) (iterations : Nat) :
    IO (Nat × Nat) := do
  let start ← IO.monoMsNow
  let mut digest : Nat := 0
  for _ in [:iterations] do
    for input in inputs do
      match lazyWHNF 600 100 input.raw with
      | .ok result => digest := digest + rawSize result
      | .error err => throw <| IO.userError s!"lazy benchmark: {repr err}"
  return ((← IO.monoMsNow) - start, digest)

private def benchDag (inputs : Array Trial) (iterations : Nat) :
    IO (Nat × Nat) := do
  let start ← IO.monoMsNow
  let mut digest : Nat := 0
  for _ in [:iterations] do
    for input in inputs do
      -- Only benchmark on encoded and explicitly validated source roots.
      match dagWHNFOnValidatedGraph input.store input.root 600 100 with
      | .ok result => digest := digest + rawSize result
      | .error err => throw <| IO.userError s!"DAG benchmark: {repr err}"
  return ((← IO.monoMsNow) - start, digest)

private def median (xs : Array Nat) : Nat :=
  (xs.toList.mergeSort (fun a b => a <= b)).getD (xs.size / 2) 0

def reductionBenchmark : IO Unit := do
  let rawTerms : Array RawExpr := (List.range 28).toArray.map
    (fun i => identityChain (35 + i % 13) (.sort (i % 31)))
  let mut inputs : Array Trial := #[]
  for raw in rawTerms do
    let (root, store) ←
      match encodeClosed 2000 raw with
      | .ok answer => pure answer
      | .error err => throw <| IO.userError s!"benchmark encode: {repr err}"
    let decoded ←
      match decodeForEvaluation store root (store.nodes.size + 5) with
      | .ok answer => pure answer
      | .error err => throw <| IO.userError s!"benchmark decode: {repr err}"
    inputs := inputs.push { raw := decoded, store := store, root := root }

  let iterations := 180
  discard <| benchEager inputs 2
  discard <| benchLazy inputs 2
  discard <| benchDag inputs 2
  let mut timesA : Array Nat := #[]
  let mut timesB : Array Nat := #[]
  let mut timesC : Array Nat := #[]
  for sample in [:5] do
    let mut digests : Array Nat := #[]
    for offset in [:3] do
      let choice := (sample + offset) % 3
      if choice == 0 then
        let (elapsed, digest) ← benchEager inputs iterations
        timesA := timesA.push elapsed
        digests := digests.push digest
      else if choice == 1 then
        let (elapsed, digest) ← benchLazy inputs iterations
        timesB := timesB.push elapsed
        digests := digests.push digest
      else
        let (elapsed, digest) ← benchDag inputs iterations
        timesC := timesC.push elapsed
        digests := digests.push digest
    if digests.size != 3 || digests[0]! != digests[1]! ||
        digests[0]! != digests[2]! then
      throw <| IO.userError "benchmark result digests disagree"

  IO.println s!"G2 3-engine beta-only WHNF: samples_each={inputs.size * iterations} per repetition, repetitions=5"
  IO.println s!"eager_ms={timesA.toList}, lazy_tree_ms={timesB.toList}, lazy_dag_ms={timesC.toList}"
  IO.println s!"median_eager_ms={median timesA}, median_lazy_tree_ms={median timesB}, median_lazy_dag_ms={median timesC}"
  IO.println "LIMIT: exploratory small untyped lambda calculus, prepared inputs; no Lean kernel or memory speedup claim"
end PSKernelFast

def main : IO Unit := PSKernelFast.reductionBenchmark
