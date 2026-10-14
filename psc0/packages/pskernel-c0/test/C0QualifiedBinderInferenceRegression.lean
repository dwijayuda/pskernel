import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedBinderInference

/-!
Native Phase E.4Q: directly executed checked Pi/lambda binder HEADS,
with all-context source equations and exact checker-state publication.

Recursive dependent child operations still delegate to the historical source
worker; no unchecked binder, ill-typed domain, loose de Bruijn variable, or
mere inference-only observation can enter source checked publication.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "QualifiedBinder"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let pi : PsKernelExpr := .forallE name sort0 sort0 .default
  let dependent : PsKernelExpr := .forallE name sort0 (.bvar 0) .default
  let lambda : PsKernelExpr := .lam name sort0 (.bvar 0) .default
  let session := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin session
    | throw (IO.userError "source binder work genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "source binder work certificate failed")
  let terms := [pi, dependent, lambda]
  for expr in terms do
    let checked ← match psKernelC0CertifiedWorkCheckBinderOwned
        4096 work expr with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("qualified binder failed: " ++ e))
    let _sourceEquation :
        psKernelC0CertifiedWorkCheck 4096 work expr =
          .ok checked.val :=
      checked.property
    let (sourceType, _) ← match psKernelSessionCheck 4096 session expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("source binder failed: " ++ e))
    if !psKernelExprEqual checked.val.fst sourceType then
      throw (IO.userError "direct binder returned wrong source type")
  let (lambdaType, _) ← match psKernelSessionCheck 4096 session lambda with
    | .ok result => pure result
    | .error e => throw (IO.userError ("full lambda typing failed: " ++ e))
  if !psKernelExprEqual lambdaType pi then
    throw (IO.userError "qualified identity lambda type changed")

  -- Nontrivial dependent Π uses a local variable when checking its body,
  -- with correct source imax and all scoped fresh-name/cache transitions.
  let depChecked ← match psKernelC0CertifiedWorkCheckBinderOwned
      4096 work dependent with
    | .ok result => pure result
    | .error e => throw (IO.userError ("dependent Π direct check failed: " ++ e))
  let expectedDep : PsKernelExpr :=
    .sort (psKernelLevelMkIMax (.succ .zero) .zero)
  if !psKernelExprEqual depChecked.val.fst expectedDep then
    throw (IO.userError "direct dependent Π universe imax changed")

  -- Depth 18 exercises source binder-range acceleration rather than
  -- only the single binder shortcut; the entire result remains source exact.
  let mut deepPi : PsKernelExpr := sort0
  for _ in [:18] do
    deepPi := .forallE name sort0 deepPi .default
  let deep ← match psKernelC0CertifiedWorkCheckBinderOwned
      4096 work deepPi with
    | .ok proof => pure proof
    | .error e => throw (IO.userError ("direct deep Pi failed: " ++ e))
  let _deepSource :
      psKernelC0CertifiedWorkCheck 4096 work deepPi =
        .ok deep.val :=
    deep.property
  let mut deepLambda : PsKernelExpr := .bvar 0
  for _ in [:18] do
    deepLambda := .lam name sort0 deepLambda .default
  let deepLam ← match psKernelC0CertifiedWorkCheckBinderOwned
      4096 work deepLambda with
    | .ok proof => pure proof
    | .error e => throw (IO.userError ("direct deep lambda failed: " ++ e))
  let _deepLambdaSource :
      psKernelC0CertifiedWorkCheck 4096 work deepLambda =
        .ok deepLam.val :=
    deepLam.property

  -- Every bad source judgment has the exact same failure result, not a
  -- candidate disagreement or an invented alternate error category.
  let badDomain : PsKernelExpr :=
    .mvar (.str .anonymous "UnresolvedDomain")
  let invalidPi : PsKernelExpr :=
    .forallE name badDomain sort0 .default
  let invalidLambda : PsKernelExpr :=
    .lam name badDomain (.bvar 0) .default
  for bad in [invalidPi, invalidLambda] do
    let actual := psKernelC0CertifiedWorkCheckBinderOwned 4096 work bad
    let source := psKernelC0CertifiedWorkCheck 4096 work bad
    match actual, source with
    | .error left, .error right =>
        if left != right then
          throw (IO.userError "source binder error precedence changed")
    | _, _ =>
        throw (IO.userError "unqualified binder was accepted or error changed")
  for bad in [pi, lambda] do
    match psKernelC0CertifiedWorkCheckBinderOwned 0 work bad,
          psKernelC0CertifiedWorkCheck 0 work bad with
    | .error left, .error right =>
        if left != right then
          throw (IO.userError "binder zero-fuel error diverged from source")
    | _, _ => throw (IO.userError "binder bypassed source zero-fuel guard")
  let limited : PsKernelCheckerSession := {
    session with
    context := {
      session.context with maxRecDepth := 1
      recDepth := 1000000
    }
  }
  let some limitedRaw := psKernelC0ArchitectureBegin limited
    | throw (IO.userError "limited binder work genesis failed")
  let some limitedWork := psKernelC0ArchitectureCertifyWork limitedRaw
    | throw (IO.userError "limited binder work certification failed")
  match psKernelC0CertifiedWorkCheckBinderOwned 4096 limitedWork lambda,
        psKernelC0CertifiedWorkCheck 4096 limitedWork lambda with
  | .error left, .error right =>
      if left != right then
        throw (IO.userError "binder recursion guard changed source error")
  | _, _ => throw (IO.userError "direct lambda bypassed source recursion guard")

  -- All public verified proofs still come from the signed audited
  -- checked session with actual source types and atomic whole-root checking.
  let policy : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin policy
      psKernelProviderDefault with
    | .ok result => pure result
    | .error _ => throw (IO.userError "direct binder provider genesis failed")
  let published ← match psKernelC0VerifiedProviderPublishRoots
      genesis [pi, lambda, dependent] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "source-qualified binders not published")
  let _sourceRootProof :=
    psKernelC0VerifiedProviderPublicationCheckExact published
  if published.checked.roots.length != 3 then
    throw (IO.userError "dependent binder publication omitted selected roots")
  match psKernelC0VerifiedProviderPublishRoots
      genesis [pi, invalidLambda] with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "invalid lambda partially published valid binder")
  if !(psKernelC0HistoryAxiomSignatures
      published.staged.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "direct binder checking introduced a trusted assumption")

  IO.println "C0_BINDER_QUALIFIED dependent_Pi_lambda_exact_source_state=pass"
  IO.println "C0_BINDER_QUALIFIED deep_spines_and_failed_resource_equations=pass"
  IO.println "C0_BINDER_QUALIFIED verified_atomic_closed_root_publication=pass"
