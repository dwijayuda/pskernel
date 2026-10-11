import PSKernelFast.Reduction

namespace PSKernelFast

/--
  Controlled but exploratory wall-clock microbenchmark. It is not a Lean
  kernel benchmark: only four RawExpr constructors and beta WHNF are supported.
  Inputs are allocated before the timed runs and identical across strategies.
-/
def reductionBenchmark : IO Unit := do
  let terms : Array RawExpr :=
    (List.range 28).toArray.map (fun i => identityChain (35 + i % 13) (.sort (i % 31)))
  let mut inputRoots : Array RawExpr := #[]
  for t in terms do
    match encodeClosed 2000 t with
    | .error err => throw <| IO.userError s!"benchmark encode: {repr err}"
    | .ok (id, store) =>
      match decodeForEvaluation store id (store.nodes.size + 5) with
      | .error err => throw <| IO.userError s!"benchmark decode: {repr err}"
      | .ok decoded => inputRoots := inputRoots.push decoded

  let iterations : Nat := 25
  let beforeEager ← IO.monoMsNow
  let mut eagerDigest : Nat := 0
  for _ in [:iterations] do
    for term in inputRoots do
      match eagerWHNF 200 term with
      | .ok result => eagerDigest := eagerDigest + rawSize result
      | .error err => throw <| IO.userError s!"benchmark eager: {repr err}"
  let afterEager ← IO.monoMsNow

  let beforeLazy ← IO.monoMsNow
  let mut lazyDigest : Nat := 0
  for _ in [:iterations] do
    for term in inputRoots do
      match lazyWHNF 600 100 term with
      | .ok result => lazyDigest := lazyDigest + rawSize result
      | .error err => throw <| IO.userError s!"benchmark lazy: {repr err}"
  let afterLazy ← IO.monoMsNow

  if eagerDigest != lazyDigest then
    throw <| IO.userError "eager/lazy benchmark result digests disagree"

  IO.println s!"G2 beta WHNF comparison: samples={inputRoots.size * iterations}, eager_ms={afterEager - beforeEager}, lazy_with_readback_ms={afterLazy - beforeLazy}, digest={eagerDigest}"
  IO.println "BENCHMARK LIMIT: exploratory one-run wall time, not Lean kernel throughput or proof soundness"
end PSKernelFast

def main : IO Unit := PSKernelFast.reductionBenchmark
