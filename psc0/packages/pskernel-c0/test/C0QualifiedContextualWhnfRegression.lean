import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
E.4AD: exact source-state/caching qualification for checked lambda
and rigid local WHNF, including arbitrary metadata prefixes, warm
cache, zero-fuel, recursion and source fallbacks. No proof admission
from mere WHNF results.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "ContextualWhnfLocal"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let identity : PsKernelExpr := .lam name sort1 (.bvar 0) .default
  let wrapped : PsKernelExpr := .mdata 7 (.mdata 8 identity)
  let rigid : PsKernelExpr := .fvar name
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let rigidLocalContext := psKernelLocalContextAddLocal source.context.localContext
    name name sort1 .default
  let rigidSession : PsKernelCheckerSession := {
    source with
    context := psKernelCheckerContextWithLocalContext source.context rigidLocalContext
  }
  let letLocal := psKernelLocalContextAddLet source.context.localContext
    name name sort1 sort0
  let letSession : PsKernelCheckerSession := {
    source with
    context := psKernelCheckerContextWithLocalContext source.context letLocal
  }

  for session in [source, rigidSession, letSession] do
    let some raw := psKernelC0ArchitectureBegin session
      | throw (IO.userError "contextual WHNF work genesis unavailable")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "contextual WHNF work invalid")
    for expr in [identity, wrapped, rigid] do
      let proof ← match psKernelC0CertifiedWorkWhnfContextualOwned
          4096 work expr with
        | .ok receipt => pure receipt
        | .error e => throw (IO.userError ("contextual WHNF failed: " ++ e))
      let _sourceEquation :
          psKernelC0CertifiedWorkWhnf 4096 work expr = .ok proof.val :=
        proof.property
      let sourceResult ← match psKernelC0CertifiedWorkWhnf
          4096 work expr with
        | .ok result => pure result
        | .error e => throw (IO.userError ("source WHNF failed: " ++ e))
      if !psKernelExprEqual sourceResult.fst proof.val.fst then
        throw (IO.userError "independent WHNF diverged from source")
      if psKernelExprEqual expr identity || psKernelExprEqual expr wrapped then
        if !psKernelExprEqual proof.val.fst identity then
          throw (IO.userError "source lambda/mdata WHNF changed")
    let some (coldLambda, warmState) :=
        psKernelC0ContextualHeadWhnfWithFuel
          4096 session.context session.state identity
      | throw (IO.userError "cold lambda was not independently evaluated")
    if !psKernelExprEqual coldLambda identity ||
        (psKernelExprMapGet warmState.whnf identity).isNone then
      throw (IO.userError "lambda WHNF did not publish exact source cache")
    let some (warmLambda, _) := psKernelC0ContextualHeadWhnfWithFuel
        1 session.context warmState identity
      | throw (IO.userError "warm lambda cache bypassed source fuel policy")
    if !psKernelExprEqual warmLambda identity then
      throw (IO.userError "warm lambda cache result changed")
    if (psKernelC0ContextualHeadWhnfWithFuel
        0 session.context session.state identity).isSome then
      throw (IO.userError "lambda WHNF bypassed zero fuel")
    if (psKernelC0ContextualHeadWhnfWithFuel
        1 session.context session.state identity).isSome then
      throw (IO.userError "cold lambda ignored inner WHNF fuel")
    if (psKernelC0ContextualHeadWhnfWithFuel
        2 session.context session.state wrapped).isSome then
      throw (IO.userError "metadata lambda bypassed recursive fuel")
    match psKernelC0CertifiedWorkWhnfContextualOwned
        0 work identity, psKernelC0CertifiedWorkWhnf 0 work identity with
    | .error observed, .error expected =>
        if observed != expected then
          throw (IO.userError "zero-fuel error changed")
    | _, _ => throw (IO.userError "zero-fuel lambda was accepted")

  -- A rigid local has no definition and can be normalized directly.
  let some (rigidValue, rigidState) :=
      psKernelC0ContextualHeadWhnfWithFuel
        1 rigidSession.context rigidSession.state rigid
    | throw (IO.userError "rigid fvar declined direct WHNF")
  if !psKernelExprEqual rigidValue rigid ||
      (psKernelExprMapGet rigidState.whnf rigid).isSome then
    throw (IO.userError "rigid fvar unexpectedly changed cache")
  -- A let-bound fvar with no warm source cache must *decline* independent
  -- evaluation; its zeta-reduction belongs to the source checker.
  if (psKernelC0ContextualHeadWhnfWithFuel
      4096 letSession.context letSession.state rigid).isSome then
    throw (IO.userError "uncached let-fvar was independently accepted")

  -- A let-bound FVar is context-sensitive. Even after successful source
  -- zeta, it must never enter a reusable expression-only WHNF cache.
  let (letValue, warmedLetState) ← match psKernelCheckerWhnf 4096
      letSession.context letSession.state rigid with
    | .ok result => pure result
    | .error e => throw (IO.userError ("source let-fvar failed: " ++ e))
  if !psKernelExprEqual letValue sort0 ||
      (psKernelExprMapGet warmedLetState.whnf rigid).isSome then
    throw (IO.userError "source let-fvar zeta or scoped cache policy changed")
  if (psKernelC0ContextualHeadWhnfWithFuel
      1 letSession.context warmedLetState rigid).isSome then
    throw (IO.userError "contextual WHNF reused scoped let-fvar cache")
  let (again, _) ← match psKernelCheckerWhnf 4096
      letSession.context warmedLetState rigid with
    | .ok result => pure result
    | .error e => throw (IO.userError ("repeated source let-fvar failed: " ++ e))
  if !psKernelExprEqual again sort0 then
    throw (IO.userError "repeated source let-fvar normalization changed")
  if (psKernelC0ContextualHeadWhnfWithFuel
      0 letSession.context warmedLetState rigid).isSome then
    throw (IO.userError "let-fvar bypassed zero public fuel")

  let blocked : PsKernelCheckerSession := {
    source with
    context := { source.context with recDepth := 1000000, maxRecDepth := 1 }
  }
  if (psKernelC0ContextualHeadWhnfWithFuel
      4096 blocked.context blocked.state identity).isSome then
    throw (IO.userError "cold lambda bypassed recDepth bound")
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "blocked WHNF work genesis failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "blocked WHNF work certification failed")
  match psKernelC0CertifiedWorkWhnfContextualOwned
      4096 blockedWork identity,
    psKernelC0CertifiedWorkWhnf 4096 blockedWork identity with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "source depth diagnostic changed")
  | _, _ => throw (IO.userError "cold lambda bypassed original recursion budget")

  -- Actual audited source work selects the new independently proved
  -- normalization without introducing assumptions or importing raw
  -- checker state.
  let some genesis := psKernelC0AuditedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "audited WHNF genesis failed")
  let (value, after) ← match psKernelC0AuditedSourceWhnf 4096
      genesis wrapped with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited lambda WHNF failed: " ++ e))
  if !psKernelExprEqual value identity ||
      !(psKernelC0HistoryAxiomSignatures
        after.trusted.history).isEmpty ||
      !(psKernelC0HistoryTrustCapabilities
        after.trusted.history).isEmpty then
    throw (IO.userError "qualified audited WHNF changed trusted assumptions")
  let _axioms := psKernelC0AuditedSourceAxiomsApproved after
  let _capabilities := psKernelC0AuditedSourceCapabilitiesApproved after

  IO.println "C0_CONTEXTUAL_WHNF independently_checked_lambda_cache_state=pass"
  IO.println "C0_CONTEXTUAL_WHNF rigid_fvar_and_source_let_fallback=pass"
  IO.println "C0_CONTEXTUAL_WHNF metadata_fuel_depth_and_source_errors=pass"
  IO.println "C0_CONTEXTUAL_WHNF audited_source_foundation_unchanged=pass"
