import Lean
import Ps.KernelCore.API.Dag

/-
Matched complete public checking. DAG timing includes replay validation and
one-time decoding on every operation. No prevalidated private worker is timed.
The original checker remains the oracle; this is a partial migration benchmark.
Construction, checking and process memory are reported separately.
-/

private def s0 := PsKernelExpr.sort PsKernelLevel.zero
private def s1 := PsKernelExpr.sort (.succ .zero)
private def officialS0 := Lean.Expr.sort Lean.Level.zero
private def officialS1 := Lean.Expr.sort (.succ .zero)

private def expect {α : Type} (value : Except String α) : IO α := do
  match value with
  | .ok result => return result
  | .error message => throw (IO.userError message)

private def mkTerms (metadata : Bool) (depth tag : Nat) :
    IO (PsKernelExpr × Lean.Expr × PsKernelExprV2PagedArena × Nat) := do
  let (a0, r0) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
  let (a1, r1) ← expect (psKernelExprV2PagedMkSort a0 (.succ .zero))
  let (a2, b0) ← expect (psKernelExprV2PagedMkBVar a1 0)
  let mut arena := a2
  let mut root := r0
  let mut original := s0
  let mut official := officialS0
  for i in [:depth] do
    if metadata then
      let (next, id) ← expect (psKernelExprV2PagedMkMData arena (tag + i) root)
      arena := next
      root := id
      original := .mdata (tag + i) original
      official := .mdata {} official
    else
      let (next, id) ← expect
        (psKernelExprV2PagedMkLet arena .anonymous r1 root b0 false)
      arena := next
      root := id
      original := .letE .anonymous s1 original (.bvar 0) false
      official := .letE .anonymous officialS1 official (.bvar 0) false
  return (original, official, arena, root)

private def cacheMarker (shape : String) (tag i : Nat) : Nat :=
  tag * 4096 +
    (if shape == "fn-unique" then i
     else if shape == "fn-collision" then 65521 * i
     else 0)

private def mkFunctionTerms (variant shape : String) (depth tag : Nat) :
    IO (PsKernelExpr × Lean.Expr × PsKernelExprV2PagedArena × Nat) := do
  if variant == "legacy" then
    let functionType := PsKernelExpr.forallE .anonymous s1 s1 .default
    let head : Nat → PsKernelExpr := fun i =>
      let name := PsKernelName.str .anonymous s!"cache-{tag}-{i}"
      let info := if shape == "fn-alpha" && i % 2 == 1
        then PsKernelBinderInfo.implicit else PsKernelBinderInfo.default
      .letE name functionType
        (.mdata (cacheMarker shape tag i) (.lam name s1 (.bvar 0) info))
        (.bvar 0) false
    let shared := if shape == "fn-shared" then head 0 else s0
    let mut term := s0
    for i in [:depth] do
      term := .app (if shape == "fn-shared" then shared else head i) term
    return (term, officialS0, psKernelExprV2PagedEmpty, 0)
  else if variant == "lean" then
    let functionType := Lean.Expr.forallE .anonymous officialS1 officialS1 .default
    let head : Nat → Lean.Expr := fun i =>
      let name := Lean.Name.str .anonymous s!"cache-{tag}-{i}"
      let info := if shape == "fn-alpha" && i % 2 == 1
        then Lean.BinderInfo.implicit else Lean.BinderInfo.default
      let marker := Lean.KVMap.setNat {} (.str .anonymous "pskernel-bench-tag")
        (cacheMarker shape tag i)
      .letE name functionType
        (.mdata marker (.lam name officialS1 (.bvar 0) info))
        (.bvar 0) false
    let shared := if shape == "fn-shared" then head 0 else officialS0
    let mut term := officialS0
    for i in [:depth] do
      term := .app (if shape == "fn-shared" then shared else head i) term
    return (s0, term, psKernelExprV2PagedEmpty, 0)
  else
    let (a0, r0) ← expect (psKernelExprV2PagedMkSort psKernelExprV2PagedEmpty .zero)
    let (a1, r1) ← expect (psKernelExprV2PagedMkSort a0 (.succ .zero))
    let (a2, b0) ← expect (psKernelExprV2PagedMkBVar a1 0)
    let (a3, functionType) ← expect
      (psKernelExprV2PagedMkForall a2 .anonymous r1 r1 .default)
    let head := fun (current : PsKernelExprV2PagedArena) (i : Nat) => do
      let name := PsKernelName.str .anonymous s!"cache-{tag}-{i}"
      let info := if shape == "fn-alpha" && i % 2 == 1
        then PsKernelBinderInfo.implicit else PsKernelBinderInfo.default
      let (next, identity) ← expect
        (psKernelExprV2PagedMkLam current name r1 b0 info)
      let (next, marked) ← expect
        (psKernelExprV2PagedMkMData next (cacheMarker shape tag i) identity)
      expect (psKernelExprV2PagedMkLet next name functionType marked b0 false)
    let mut arena := a3
    let mut root := r0
    let mut shared := r0
    if shape == "fn-shared" then
      let (next, id) ← head arena 0
      arena := next
      shared := id
    for i in [:depth] do
      let mut fn := shared
      if shape != "fn-shared" then
        let (next, id) ← head arena i
        arena := next
        fn := id
      let (next, id) ← expect (psKernelExprV2PagedMkApp arena fn root)
      arena := next
      root := id
    return (s0, officialS0, arena, root)

private def checkOne (env : Lean.Environment) (session : PsKernelKernelSession)
    (variant : String) (term : PsKernelExpr) (official : Lean.Expr)
    (arena : PsKernelExprV2PagedArena) (root : Nat) : IO Nat := do
  if variant == "lean" then
    match Lean.Kernel.check env {} official with
    | .ok type =>
        unless Lean.Expr.equal type officialS1 do
          throw (IO.userError "DAG_PERF_OFFICIAL_WRONG_TYPE")
    | .error _ => throw (IO.userError "DAG_PERF_OFFICIAL_REJECTED")
  else if variant == "legacy" then
    match psKernelV1CheckExpression session [] .safe term with
    | .ok value =>
        unless psKernelExprEqual value.type s1 do
          throw (IO.userError "DAG_PERF_LEGACY_WRONG_TYPE")
    | .error _ => throw (IO.userError "DAG_PERF_LEGACY_REJECTED")
  else
    match psKernelV1RunDag session [] .safe arena [.check root] with
    | .ok result =>
        match result.replies with
        | [.checked value] =>
            unless psKernelExprEqual value.type s1 do
              throw (IO.userError "DAG_PERF_DAG_WRONG_TYPE")
        | _ => throw (IO.userError "DAG_PERF_DAG_WRONG_REPLY")
    | .error _ => throw (IO.userError "DAG_PERF_DAG_REJECTED")
  return 1

private def measureDagPublicChecks (env : Lean.Environment) (session : PsKernelKernelSession)
    (variant shape : String) (depth calls : Nat)
    (fixtures : Array (PsKernelExpr × Lean.Expr × PsKernelExprV2PagedArena × Nat)) :
    IO Unit := do
  let mut correct := 0
  let start ← IO.monoMsNow
  for i in [:calls] do
    match fixtures[i % fixtures.size]? with
    | none => throw (IO.userError "DAG_PERF_FIXTURE_MISSING")
    | some (term, official, arena, root) =>
        correct := correct + (← checkOne env session variant term official arena root)
  let stop ← IO.monoMsNow
  unless correct == calls do throw (IO.userError "DAG_PERF_INCOMPLETE")
  IO.println s!"PSC1_DAG_NATIVE_SAMPLE variant={variant} shape={shape} depth={depth} calls={calls} ms={stop-start} all_correct=true"

private def measureDagPublicWhnf (env : Lean.Environment) (session : PsKernelKernelSession)
    (variant shape : String) (depth calls : Nat)
    (fixtures : Array (PsKernelExpr × Lean.Expr × PsKernelExprV2PagedArena × Nat)) :
    IO Unit := do
  unless session.resources.fuel == 4096 do
    throw (IO.userError "DAG_PERF_CHANGED_RESOURCE_FUEL")
  let run : Nat → IO Nat := fun i => do
    match fixtures[i % fixtures.size]? with
    | none => throw (IO.userError "DAG_PERF_WHNF_FIXTURE_MISSING")
    | some (term, official, arena, root) =>
        if variant == "lean" then
          let _ ← checkOne env session "lean" term official arena root
          match Lean.Kernel.whnf env {} official with
          | .ok value =>
              unless Lean.Expr.equal value officialS0 do
                throw (IO.userError "DAG_PERF_OFFICIAL_WRONG_WHNF")
          | .error _ => throw (IO.userError "DAG_PERF_OFFICIAL_WHNF_REJECTED")
        else
          let value ← if variant == "legacy" then
            match psKernelV1Whnf session [] .safe term with
            | .ok value => pure value
            | .error _ => throw (IO.userError "DAG_PERF_LEGACY_WHNF_REJECTED")
          else
            match psKernelV1RunDag session [] .safe arena [.whnf root] with
            | .ok result =>
                match result.replies with
                | [.normalized value] => pure value
                | _ => throw (IO.userError "DAG_PERF_DAG_WHNF_REPLY")
            | .error _ => throw (IO.userError "DAG_PERF_DAG_WHNF_REJECTED")
          unless psKernelExprEqual value s0 do
            throw (IO.userError "DAG_PERF_WRONG_WHNF")
        return 1
  let coldStart ← IO.monoNanosNow
  let coldCorrect ← run 0
  let coldStop ← IO.monoNanosNow
  unless coldCorrect == 1 do throw (IO.userError "DAG_PERF_COLD_WHNF_INCOMPLETE")
  for i in [:fixtures.size] do
    discard (run i)
  let mut correct := 0
  let start ← IO.monoNanosNow
  for i in [:calls] do
    correct := correct + (← run i)
  let stop ← IO.monoNanosNow
  unless correct == calls do throw (IO.userError "DAG_PERF_WHNF_INCOMPLETE")
  IO.println s!"PSC1_DAG_NATIVE_WHNF_SAMPLE variant={variant} shape={shape} depth={depth} calls={calls} ms={(stop-start)/1000000} warm_ns={stop-start} cold_ns={coldStop-coldStart} input_pool={fixtures.size} fuel={session.resources.fuel} fuel_scope=pskernel_only official_budget=kernel_internal all_correct=true semantic_cache=fresh_per_public_operation"

private def runDagCacheWorker (variant shape : String) (depth calls : Nat) : IO Unit := do
  unless (["lean", "legacy", "dag"] : List String).contains variant do
    throw (IO.userError "DAG_PERF_UNKNOWN_VARIANT")
  unless (["fn-shared", "fn-alpha", "fn-unique", "fn-collision"] : List String).contains shape do
    throw (IO.userError "DAG_PERF_UNKNOWN_CACHE_SHAPE")
  if depth == 0 || calls == 0 then
    throw (IO.userError "DAG_PERF_EMPTY_CACHE_WORKLOAD")
  let env ← Lean.mkEmptyEnvironment
  let session ← match psKernelKernelSessionEmpty
      psKernelResourcePolicyDefault psKernelProviderDefault with
    | .ok value => pure value
    | .error _ => throw (IO.userError "DAG_PERF_SESSION_FAILED")
  let setupStart ← IO.monoNanosNow
  let mut fixtures := #[]
  for tag in [:5] do
    fixtures := fixtures.push (← mkFunctionTerms variant shape depth tag)
  let setupStop ← IO.monoNanosNow
  IO.println s!"PSC1_DAG_NATIVE_CONSTRUCTION variant={variant} shape={shape} depth={depth} pool=5 input_ns={setupStop-setupStart} representation=measured_variant_only"
  measureDagPublicWhnf env session variant shape depth calls fixtures

private def runDagCacheComparisons : IO Unit := do
  let executable ← IO.appPath
  for shape in ["fn-shared", "fn-alpha", "fn-unique", "fn-collision"] do
    for (depth, calls) in [(8, 100), (32, 40), (128, 10)] do
      for variant in ["lean", "legacy", "dag", "dag", "legacy", "lean"] do
        let measured ← IO.Process.output {
          cmd := "/usr/bin/time"
          args := #["-f",
            s!"PSC1_DAG_NATIVE_PROCESS_MEMORY variant={variant} shape={shape} depth={depth} peak_rss_kib=%M scope=isolated_worker",
            executable.toString, "cache-worker", variant, shape,
            toString depth, toString calls]
        }
        unless measured.exitCode == 0 do
          throw (IO.userError s!"DAG_PERF_CACHE_WORKER_FAILED {variant} {shape} {depth}\n{measured.stdout}\n{measured.stderr}")
        IO.print measured.stdout
        IO.print measured.stderr

private def runDagBenchmarks : IO Unit := do
  let env ← Lean.mkEmptyEnvironment
  let session ← match psKernelKernelSessionEmpty
      psKernelResourcePolicyDefault psKernelProviderDefault with
    | .ok value => pure value
    | .error _ => throw (IO.userError "DAG_PERF_SESSION_FAILED")
  for (metadata, depth, calls) in [
      (true, 32, 1200), (true, 96, 600), (true, 192, 300),
      (false, 32, 100), (false, 96, 50), (false, 192, 20)] do
    let shape := if metadata then "metadata" else "zeta"
    let start ← IO.monoMsNow
    let mut fixtures := #[]
    for tag in [:5] do
      fixtures := fixtures.push (← mkTerms metadata depth (tag * 1000))
    let stop ← IO.monoMsNow
    IO.println s!"PSC1_DAG_NATIVE_CONSTRUCTION shape={shape} depth={depth} pool=5 combined_inputs_ms={stop-start}"
    for variant in ["lean", "legacy", "dag", "dag", "legacy", "lean"] do
      measureDagPublicChecks env session variant shape depth calls fixtures
  for (metadata, depth, calls) in [
      (true, 96, 300), (false, 32, 100), (false, 96, 50), (false, 192, 20)] do
    let shape := if metadata then "metadata" else "zeta"
    let mut fixtures := #[]
    for tag in [:5] do
      fixtures := fixtures.push (← mkTerms metadata depth (tag * 1000))
    for variant in ["lean", "legacy", "dag", "dag", "legacy", "lean"] do
      measureDagPublicWhnf env session variant shape depth calls fixtures
  runDagCacheComparisons
  IO.println "PSC1_V2_DAG_NATIVE_BENCH: PASS"

def main (args : List String) : IO Unit := do
  match args with
  | [] => runDagBenchmarks
  | ["cache-worker", variant, shape, depthText, callsText] =>
      let some depth := depthText.toNat?
        | throw (IO.userError "DAG_PERF_INVALID_DEPTH")
      let some calls := callsText.toNat?
        | throw (IO.userError "DAG_PERF_INVALID_CALLS")
      runDagCacheWorker variant shape depth calls
  | _ => throw (IO.userError "DAG_PERF_INVALID_ARGUMENTS")
