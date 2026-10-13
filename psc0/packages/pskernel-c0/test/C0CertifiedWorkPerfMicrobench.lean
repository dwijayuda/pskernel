import Ps.KernelCore.Architecture.CertifiedWork

/-!
Matched native Lean performance probe for representation validation reuse.

Both lanes call exactly the SAME source checked WHNF and DefEq functions on
the SAME checker session and canonical indexed store. The raw lane performs
whole-store replay on each operation; the proof-carrying lane retains the
immutable validation certificate. This is a local overhead measurement, not
a whole-checker competitive benchmark or acceptance rule.
-/

def main : IO Unit := do
  let seed : PsKernelExpr := .sort .zero
  let some (initial, firstId) :=
      psKernelC0EncodeExpr psKernelC0StoreEmpty seed
    | throw (IO.userError "certified benchmark could not encode seed")
  let mut stored := initial
  let mut last := firstId
  for _ in [:100] do
    match psKernelC0Intern stored (.app last last) with
    | none => throw (IO.userError "certified benchmark DAG insertion failed")
    | some (next, root) =>
        stored := next
        last := root
  if !psKernelC0ReplayValidateStore stored then
    throw (IO.userError "certified benchmark canonical DAG is malformed")

  let checker := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin checker stored
    | throw (IO.userError "certified benchmark raw begin failed")
  let some certified := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "certified benchmark certificate failed")

  let iterations := 18
  let mut ordinary := raw
  let rawStart ← IO.monoMsNow
  for _ in [:iterations] do
    let (value, next) ← match
        psKernelC0ArchitectureWhnfWork 4096 ordinary seed with
      | .ok result => pure result
      | .error reason =>
          throw (IO.userError ("raw benchmark WHNF failed: " ++ reason))
    if !psKernelExprEqual value seed then
      throw (IO.userError "raw benchmark WHNF changed source semantics")
    ordinary := next
    let (same, next) ← match
        psKernelC0ArchitectureDefEqWork 4096 ordinary
          seed seed with
      | .ok result => pure result
      | .error reason =>
          throw (IO.userError ("raw benchmark DefEq failed: " ++ reason))
    if !same then
      throw (IO.userError "raw benchmark lost definitional equality")
    ordinary := next
  let rawDone ← IO.monoMsNow

  let mut validated := certified
  let certStart ← IO.monoMsNow
  for _ in [:iterations] do
    let (value, next) ← match
        psKernelC0CertifiedWorkWhnf 4096 validated seed with
      | .ok result => pure result
      | .error reason =>
          throw (IO.userError ("certified benchmark WHNF failed: " ++ reason))
    if !psKernelExprEqual value seed then
      throw (IO.userError "certified benchmark WHNF disagreed with source")
    validated := next
    let (same, next) ← match
        psKernelC0CertifiedWorkDefEq 4096 validated seed seed with
      | .ok result => pure result
      | .error reason =>
          throw (IO.userError ("certified benchmark DefEq failed: " ++ reason))
    if !same then
      throw (IO.userError "certified benchmark lost source DefEq")
    validated := next
  let certDone ← IO.monoMsNow
  if !psKernelC0ArchitectureWorkValid validated.raw ||
      !psKernelC0ArchitectureWorkValid ordinary then
    throw (IO.userError "benchmarked source operations invalidated the store")

  IO.println s!"C0_CERTIFIED_PERF store_nodes={stored.nodes.size} operations={iterations * 2} raw_ms={rawDone - rawStart} certified_ms={certDone - certStart}"
  IO.println "C0_CERTIFIED_PERF matched_source_whnf_defeq=pass"
