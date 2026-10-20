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

def main : IO Unit := do
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
  IO.println "PSC1_V2_DAG_NATIVE_BENCH: PASS"
