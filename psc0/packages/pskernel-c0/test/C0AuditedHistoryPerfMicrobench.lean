import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
Matched native Lean benchmark: approved-source queries with exact
environment-equality proof transport vs identical source queries followed
by explicit whole-history permission re-audit.

Both lanes use the same source WHNF operation, declaration history, input
and policy. The timings are informational, not acceptance thresholds or a
claim of full-kernel competitive performance.
-/

def c0AuditPerfName (i : Nat) : PsKernelName :=
  .num (.str .anonymous "AuditPerfSafeDefinition") i

def main : IO Unit := do
  let some start := psKernelC0AuditedSourceBegin
      8192 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "matched audit benchmark could not start empty history")
  let mut admitted := start
  for i in [:96] do
    let info : PsKernelDefinitionInfo := {
      base := {
        name := c0AuditPerfName i
        levelParams := []
        type := .sort (.succ .zero)
      }
      value := .sort .zero
      hints := .abbrevHint
      safety := .safe
    }
    admitted ← match psKernelC0AuditedSourceAdmit
        8192 admitted (.definition info) with
      | .ok newWork => pure newWork
      | .error e =>
          throw (IO.userError ("matched audit seed admission failed: " ++ e))
  if (psKernelC0HistoryAxiomSignatures admitted.trusted.history).length != 0 ||
      (psKernelC0HistoryTrustCapabilities admitted.trusted.history).length != 0 then
    throw (IO.userError "benchmark seed acquired unexpected trusted assumptions")

  let trials := 112
  let mut incremental := admitted
  let fastStart ← IO.monoMsNow
  for _ in [:trials] do
    let (result, next) ← match psKernelC0AuditedSourceWhnf
        8192 incremental (.sort .zero) with
      | .ok value => pure value
      | .error e =>
          throw (IO.userError ("incremental audited source WHNF failed: " ++ e))
    if !psKernelExprEqual result (.sort .zero) then
      throw (IO.userError "incremental audited WHNF changed source value")
    incremental := next
  let fastEnd ← IO.monoMsNow

  let mut replayed := admitted
  let replayStart ← IO.monoMsNow
  for _ in [:trials] do
    let (result, nextTrusted) ← match psKernelC0TrustedSourceWhnf
        8192 replayed.trusted (.sort .zero) with
      | .ok value => pure value
      | .error e =>
          throw (IO.userError ("full-replay audited source WHNF failed: " ++ e))
    if !psKernelExprEqual result (.sort .zero) then
      throw (IO.userError "full-replay audited WHNF changed source value")
    let some next := psKernelC0AuditTrustedSourceWithCapabilities
        nextTrusted replayed.allowedAxioms replayed.allowedCapabilities
      | throw (IO.userError "full-history re-audit rejected matching source")
    replayed := next
  let replayEnd ← IO.monoMsNow
  if (psKernelC0HistoryAxiomSignatures incremental.trusted.history).length !=
      (psKernelC0HistoryAxiomSignatures replayed.trusted.history).length ||
      (psKernelC0HistoryTrustCapabilities incremental.trusted.history).length !=
        (psKernelC0HistoryTrustCapabilities replayed.trusted.history).length then
    throw (IO.userError "matched audit alternatives changed assumption history")
  IO.println s!"C0_AUDIT_PERF checked_declarations=96 operations={trials} incremental_ms={fastEnd - fastStart} replay_per_query_ms={replayEnd - replayStart}"
  IO.println "C0_AUDIT_PERF exact_source_queries_and_permissions_agree=pass"
