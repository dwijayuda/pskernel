import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
E.4AE: independently execute one cold ζ WHNF when the substituted
binder body becomes Sort. Check exact state/cache, source fuel, local
recursion-depth and audited permission preservation. Unsupported terms
must decline and use the existing original checker.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "IndependentZetaBinder"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let substituted : PsKernelExpr :=
    .letE name sort1 sort0 (.bvar 0) false
  let unused : PsKernelExpr :=
    .letE name sort1 sort0 sort0 true
  let unsupported : PsKernelExpr :=
    .letE name sort1 sort0 (.app (.lam name sort1 (.bvar 0) .default) (.bvar 0)) false
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "independent ζ genesis unavailable")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "independent ζ certified work unavailable")
  for expr in [substituted, unused] do
    let some (reduced, nextState) := psKernelC0ZetaSortWhnfWithFuel
        4096 source.context source.state expr
      | throw (IO.userError "independent ζ declined simple substitution")
    if !psKernelExprEqual reduced sort0 ||
        (psKernelExprMapGet nextState.whnf expr).isNone ||
        (psKernelExprMapGet nextState.whnfCore expr).isNone then
      throw (IO.userError "ζ result or two caches changed")
    let proof ← match psKernelC0CertifiedWorkWhnfZetaOwned
        4096 work expr with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("qualified ζ failed: " ++ e))
    let _exact : psKernelC0CertifiedWorkWhnf 4096 work expr =
        .ok proof.val := proof.property
    if !psKernelExprEqual proof.val.fst sort0 then
      throw (IO.userError "ζ changed source WHNF")
    if (psKernelC0ZetaSortWhnfWithFuel
        2 source.context source.state expr).isSome then
      throw (IO.userError "ζ skipped source core/body fuel")
    if (psKernelC0ZetaSortWhnfWithFuel
        0 source.context source.state expr).isSome then
      throw (IO.userError "ζ skipped zero fuel")
    let (reference, _) ← match psKernelCheckerWhnf 4096
        source.context source.state expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("source ζ failed: " ++ e))
    if !psKernelExprEqual reference reduced then
      throw (IO.userError "ζ source-result differential mismatch")
  if (psKernelC0ZetaSortWhnfWithFuel
      4096 source.context source.state unsupported).isSome then
    throw (IO.userError "unsupported ζ descendant was independently authorized")
  match psKernelC0CertifiedWorkWhnfZetaOwned
      0 work substituted, psKernelC0CertifiedWorkWhnf 0 work substituted with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "ζ zero-fuel error changed")
  | _, _ => throw (IO.userError "ζ escaped zero fuel")
  let blocked : PsKernelCheckerSession := {
    source with
    context := { source.context with recDepth := 1000000, maxRecDepth := 1 }
  }
  if (psKernelC0ZetaSortWhnfWithFuel
      4096 blocked.context blocked.state substituted).isSome then
    throw (IO.userError "ζ bypassed source recursion depth")
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "blocked ζ work unavailable")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "blocked ζ work certification failed")
  match psKernelC0CertifiedWorkWhnfZetaOwned
      4096 blockedWork substituted,
    psKernelC0CertifiedWorkWhnf 4096 blockedWork substituted with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "ζ recursion error category changed")
  | _, _ => throw (IO.userError "qualified ζ bypassed depth limit")
  let some genesis := psKernelC0AuditedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "audited ζ genesis failed")
  let (value, after) ← match psKernelC0AuditedSourceWhnf
      4096 genesis substituted with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited ζ failed: " ++ e))
  if !psKernelExprEqual value sort0 ||
      !(psKernelC0HistoryAxiomSignatures
        after.trusted.history).isEmpty ||
      !(psKernelC0HistoryTrustCapabilities
        after.trusted.history).isEmpty then
    throw (IO.userError "audited ζ mutated assumption history")
  let _axioms := psKernelC0AuditedSourceAxiomsApproved after
  let _capabilities := psKernelC0AuditedSourceCapabilitiesApproved after
  IO.println "C0_SOURCE_REFINED_ZETA independent_substitution_and_both_caches=pass"
  IO.println "C0_SOURCE_REFINED_ZETA exact_fuel_depth_and_source_errors=pass"
  IO.println "C0_SOURCE_REFINED_ZETA audited_permission_history=pass"
