import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
E.4AH — fully source-refined multi-step, state-threaded β/ζ WHNF.
Nested core reductions must write each core cache, but only the root
writes the public WHNF cache. No trusted term admission is inferred.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "RecursiveWhnfBinder"
  let type : PsKernelExpr := .sort (.succ .zero)
  let value : PsKernelExpr := .sort .zero
  let id : PsKernelExpr := .lam name type (.bvar 0) .default
  let curried : PsKernelExpr :=
    .lam name type (.lam name type (.bvar 1) .default) .default
  let inner : PsKernelExpr := .app id value
  let nested : PsKernelExpr := .app id inner
  let nested3 : PsKernelExpr := .app id nested
  let multibinder : PsKernelExpr := .app (.app curried value) type
  let letBeta : PsKernelExpr :=
    .letE name type id (.app (.bvar 0) value) false
  let zetaChain : PsKernelExpr :=
    .letE name type value
      (.letE name type (.bvar 0)
        (.app id (.bvar 0)) false) false
  let metadataChain : PsKernelExpr :=
    .letE name type value (.mdata 17 (.app id (.bvar 0))) false
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "recursive WHNF genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "recursive WHNF certified store failed")
  for term in [nested, nested3, multibinder, letBeta,
      zetaChain, metadataChain] do
    let some (reduced, nextState) :=
        psKernelC0RecursiveBetaZetaWhnfWithFuel
          4096 source.context source.state term
      | throw (IO.userError "recursive beta/zeta declined supported chain")
    if !psKernelExprEqual reduced value ||
        (psKernelExprMapGet nextState.whnf term).isNone ||
        (psKernelExprMapGet nextState.whnfCore term).isNone then
      throw (IO.userError "recursive beta/zeta result or cache invalid")
    let receipt ← match psKernelC0CertifiedWorkWhnfRecursiveOwned
        4096 work term with
      | .ok proof => pure proof
      | .error e => throw (IO.userError ("source-refined recursion failed: " ++ e))
    let _exact : psKernelC0CertifiedWorkWhnf 4096 work term =
        .ok receipt.val := receipt.property
    if !psKernelExprEqual receipt.val.fst reduced then
      throw (IO.userError "recursive WHNF source-proof value mismatch")
    let (reference, _) ← match psKernelCheckerWhnf 4096
        source.context source.state term with
      | .ok v => pure v
      | .error e => throw (IO.userError ("original recursive WHNF failed: " ++ e))
    if !psKernelExprEqual reference reduced then
      throw (IO.userError "recursive source differential mismatch")

  let some (_, innerCacheState) := psKernelC0RecursiveBetaZetaWhnfWithFuel
      4096 source.context source.state nested3
    | throw (IO.userError "nested beta did not normalize")
  if (psKernelExprMapGet innerCacheState.whnfCore inner).isNone ||
      (psKernelExprMapGet innerCacheState.whnfCore nested).isNone ||
      (psKernelExprMapGet innerCacheState.whnfCore nested3).isNone then
    throw (IO.userError "intermediate beta core cache state lost")
  if (psKernelExprMapGet innerCacheState.whnf nested).isSome ||
      (psKernelExprMapGet innerCacheState.whnf inner).isSome then
    throw (IO.userError "inner core incorrectly published public cache")

  let unknown : PsKernelExpr :=
    .app (.const (.str .anonymous "UnknownDelta") []) value
  if (psKernelC0RecursiveBetaZetaWhnfWithFuel
      4096 source.context source.state unknown).isSome then
    throw (IO.userError "unsupported delta head gained WHNF authority")
  if (psKernelC0RecursiveBetaZetaWhnfWithFuel
      0 source.context source.state nested).isSome ||
      (psKernelC0RecursiveBetaZetaWhnfWithFuel
      2 source.context source.state nested).isSome then
    throw (IO.userError "recursive normalization escaped source fuel")
  match psKernelC0CertifiedWorkWhnfRecursiveOwned 0 work nested,
      psKernelC0CertifiedWorkWhnf 0 work nested with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "source zero-fuel diagnostic changed")
  | _, _ => throw (IO.userError "zero fuel allowed independently checked WHNF")

  let blocked : PsKernelCheckerSession := {
    source with context :=
      { source.context with recDepth := 1000000, maxRecDepth := 1 }
  }
  if (psKernelC0RecursiveBetaZetaWhnfWithFuel
      4096 blocked.context blocked.state nested).isSome then
    throw (IO.userError "recursive evaluator bypassed maxRecDepth")
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "recursive WHNF blocked genesis failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "recursive WHNF blocked work certification failed")
  match psKernelC0CertifiedWorkWhnfRecursiveOwned
      4096 blockedWork nested,
      psKernelC0CertifiedWorkWhnf 4096 blockedWork nested with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "recursive WHNF depth error changed")
  | _, _ => throw (IO.userError "recursive WHNF bypassed source depth")

  let some genesis := psKernelC0AuditedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "recursive audited genesis failed")
  let (v, next) ← match psKernelC0AuditedSourceWhnf 4096
      genesis nested3 with
    | .ok output => pure output
    | .error e => throw (IO.userError ("recursive audited WHNF failed: " ++ e))
  if !psKernelExprEqual v value ||
      !(psKernelC0HistoryAxiomSignatures next.trusted.history).isEmpty ||
      !(psKernelC0HistoryTrustCapabilities next.trusted.history).isEmpty then
    throw (IO.userError "recursive WHNF introduced unreviewed assumptions")
  let _axiomProof := psKernelC0AuditedSourceAxiomsApproved next
  let _capabilityProof := psKernelC0AuditedSourceCapabilitiesApproved next
  IO.println "C0_RECURSIVE_WHNF beta_zeta_multistep_spines_source_equivalent=pass"
  IO.println "C0_RECURSIVE_WHNF exact_intermediate_core_cache_and_public_boundary=pass"
  IO.println "C0_RECURSIVE_WHNF resource_policy_negative_and_audit=pass"
