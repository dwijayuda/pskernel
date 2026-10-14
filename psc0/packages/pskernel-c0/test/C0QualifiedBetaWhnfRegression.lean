import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
E.4AF: independently checked one-beta Sort WHNF. The source checker
must match both caches, exact result and fuel/depth behavior. Unsupported
spines and bodies do not gain acceptance or error authority.
-/
def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "IndependentBetaBinder"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let id : PsKernelExpr := .lam name sort1 (.bvar 0) .default
  let constant : PsKernelExpr := .lam name sort1 sort0 .default
  let substituted : PsKernelExpr := .app id sort0
  let constantApp : PsKernelExpr := .app constant sort1
  let nested : PsKernelExpr :=
    .app (.app (.lam name sort1 (.lam name sort1 (.bvar 1) .default)
      .default) sort0) sort1
  let nonterminal : PsKernelExpr :=
    .app (.lam name sort1 (.const (.str .anonymous "NotTerminal") [])
      .default) sort0
  let stableHeads : List PsKernelExpr := [
    .lit (.nat 37),
    .lit (.str "λ世界"),
    .bvar 0,
    .mvar (.str .anonymous "WhnfMeta"),
    .forallE name sort1 (.bvar 0) .default,
    .lam name sort1 (.bvar 0) .default
  ]
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "independent beta work genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "independent beta work certification failed")
  for expr in [substituted, constantApp] do
    let some (normalized, nextState) := psKernelC0BetaStableWhnfWithFuel
        4096 source.context source.state expr
      | throw (IO.userError "simple independent beta was declined")
    if !psKernelExprEqual normalized sort0 ||
        (psKernelExprMapGet nextState.whnf expr).isNone ||
        (psKernelExprMapGet nextState.whnfCore expr).isNone then
      throw (IO.userError "independent beta changed result or two caches")
    let receipt ← match psKernelC0CertifiedWorkWhnfBetaOwned
        4096 work expr with
      | .ok proof => pure proof
      | .error e => throw (IO.userError ("beta checked work failed: " ++ e))
    let _exact : psKernelC0CertifiedWorkWhnf 4096 work expr =
        .ok receipt.val := receipt.property
    if !psKernelExprEqual receipt.val.fst normalized then
      throw (IO.userError "beta source receipt changed value")
    let (original, _) ← match psKernelCheckerWhnf 4096
        source.context source.state expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("original beta failed: " ++ e))
    if !psKernelExprEqual original normalized then
      throw (IO.userError "beta source-differential mismatch")
    if (psKernelC0BetaStableWhnfWithFuel
        2 source.context source.state expr).isSome then
      throw (IO.userError "beta skipped source/core body fuel")
    if (psKernelC0BetaStableWhnfWithFuel
        0 source.context source.state expr).isSome then
      throw (IO.userError "beta skipped zero fuel")
    let warmSource ← match psKernelCheckerWhnf
        4096 source.context source.state expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("beta cache warm failed: " ++ e))
    if (psKernelC0BetaStableWhnfWithFuel
        4096 source.context warmSource.snd expr).isSome then
      throw (IO.userError "beta bypassed source-warm cache")
  for target in stableHeads do
    let expr : PsKernelExpr := .app id target
    let some (direct, cacheState) := psKernelC0BetaStableWhnfWithFuel
        4096 source.context source.state expr
      | throw (IO.userError "non-Sort beta terminal declined")
    if !psKernelExprEqual direct target ||
        (psKernelExprMapGet cacheState.whnf expr).isNone ||
        (psKernelExprMapGet cacheState.whnfCore expr).isNone then
      throw (IO.userError "non-Sort beta source cache/state changed")
    let receipt ← match psKernelC0CertifiedWorkWhnfBetaOwned
        4096 work expr with
      | .ok value => pure value
      | .error e => throw (IO.userError ("qualified stable beta failed: " ++ e))
    let _source : psKernelC0CertifiedWorkWhnf 4096 work expr =
        .ok receipt.val := receipt.property
    if !psKernelExprEqual receipt.val.fst target then
      throw (IO.userError "non-Sort beta source-refinement value changed")
  for expr in [nonterminal, nested] do
    if (psKernelC0BetaStableWhnfWithFuel
        4096 source.context source.state expr).isSome then
      throw (IO.userError "unsupported beta was independently accepted")
  match psKernelC0CertifiedWorkWhnfBetaOwned
      0 work substituted, psKernelC0CertifiedWorkWhnf 0 work substituted with
  | .error observed, .error original =>
      if observed != original then
        throw (IO.userError "beta zero-fuel error changed")
  | _, _ => throw (IO.userError "beta bypassed original zero-fuel guard")
  let blocked : PsKernelCheckerSession := {
    source with
    context := { source.context with recDepth := 1000000, maxRecDepth := 1 }
  }
  if (psKernelC0BetaStableWhnfWithFuel
      4096 blocked.context blocked.state substituted).isSome then
    throw (IO.userError "beta ignored source depth limit")
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "blocked beta work genesis failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "blocked beta certified work failed")
  match psKernelC0CertifiedWorkWhnfBetaOwned
      4096 blockedWork substituted,
    psKernelC0CertifiedWorkWhnf 4096 blockedWork substituted with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "beta recursion diagnostic changed")
  | _, _ => throw (IO.userError "beta bypassed source recursion policy")
  let some genesis := psKernelC0AuditedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "audited beta genesis failed")
  let (value, after) ← match psKernelC0AuditedSourceWhnf
      4096 genesis substituted with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited beta failed: " ++ e))
  if !psKernelExprEqual value sort0 ||
      !(psKernelC0HistoryAxiomSignatures after.trusted.history).isEmpty ||
      !(psKernelC0HistoryTrustCapabilities after.trusted.history).isEmpty then
    throw (IO.userError "independent beta changed audited foundation")
  let _axioms := psKernelC0AuditedSourceAxiomsApproved after
  let _capabilities := psKernelC0AuditedSourceCapabilitiesApproved after
  IO.println "C0_BETA_SOURCE_REFINEMENT independently_checked_beta_to_stable_heads=pass"
  IO.println "C0_BETA_SOURCE_REFINEMENT complete_source_cache_and_fuel=pass"
  IO.println "C0_BETA_SOURCE_REFINEMENT fallback_and_audited_history=pass"
