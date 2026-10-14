import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedBinderInferOnly

/-!
Phase E.4R: complete source-exact infer-only lambda and dependent Pi heads.

Infer-only cache results cannot certify that a binder domain or body was
fully checked. The separate source-exact FULL checker must be called before
proof-bearing publication. These tests keep the entire source state and
resource/error semantics unchanged in both modes.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "InferredBinder"
  let sort0 : PsKernelExpr := .sort .zero
  let pi : PsKernelExpr := .forallE name sort0 sort0 .default
  let dependent : PsKernelExpr := .forallE name sort0 (.bvar 0) .default
  let identity : PsKernelExpr := .lam name sort0 (.bvar 0) .default
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "inferred binder genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "inferred binder source work failed")
  for expr in [pi, dependent, identity] do
    let inferred ← match psKernelC0CertifiedWorkInferBinderOwned
        4096 work expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("direct binder inference failed: " ++ e))
    let _sourceEquation :
        psKernelC0CertifiedWorkInfer 4096 work expr =
          .ok inferred.val :=
      inferred.property
    let (sourceType, _) ← match psKernelSessionInfer 4096 source expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("source binder inference failed: " ++ e))
    if !psKernelExprEqual inferred.val.fst sourceType then
      throw (IO.userError "infer-only Pi/lambda type differs from source")
    if (psKernelExprMapGet
        inferred.val.snd.raw.checker.state.inferOnly expr).isNone then
      throw (IO.userError "infer-only binder result was not cached")

  let (sourceType, warmed) ← match psKernelSessionInfer 4096
      source identity with
    | .ok result => pure result
    | .error e => throw (IO.userError ("warm inferred lambda failed: " ++ e))
  let warm ← match psKernelC0LambdaInferOnlyWithFuel 4096
      (psKernelWhnfWithRecursorFuel 4096 (psKernelIsDefEqWithFuel 4096))
      (psKernelIsDefEqWithFuel 4096)
      warmed.context warmed.state name sort0 (.bvar 0) .default with
    | .ok result => pure result
    | .error e => throw (IO.userError ("warm direct lambda failed: " ++ e))
  if !psKernelExprEqual warm.fst sourceType ||
      (psKernelExprMapGet warm.snd.inferOnly identity).isNone then
    throw (IO.userError "warm binder cache changed source behavior")

  let mut deep : PsKernelExpr := sort0
  for _ in [:18] do
    deep := .forallE name sort0 deep .default
  let deepResult ← match psKernelC0CertifiedWorkInferBinderOwned 4096 work deep with
    | .ok result => pure result
    | .error e => throw (IO.userError ("deep inferred Pi failed: " ++ e))
  let _deepSourceEquation :
      psKernelC0CertifiedWorkInfer 4096 work deep = .ok deepResult.val :=
    deepResult.property

  -- Infer-only is NOT full checking, and no arbitrary source cache or
  -- unknown binder can authorize proof publication.
  let invalidDomain : PsKernelExpr :=
    .mvar (.str .anonymous "unknownBinderDomain")
  let dubiousLambda : PsKernelExpr :=
    .lam name invalidDomain (.bvar 0) .default
  match psKernelC0CertifiedWorkCheckBinderOwned
      4096 work dubiousLambda with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "unchecked lambda domain acquired proof")
  let sourceInfer := psKernelC0CertifiedWorkInfer 4096 work dubiousLambda
  let qualifiedInfer := psKernelC0CertifiedWorkInferBinderOwned
    4096 work dubiousLambda
  match sourceInfer, qualifiedInfer with
  | .error left, .error right =>
      if left != right then
        throw (IO.userError "infer-only binder errors diverged from source")
  | .ok original, .ok receipt =>
      if !psKernelExprEqual original.fst receipt.val.fst then
        throw (IO.userError "source infer-only binder result diverged")
  | _, _ => throw (IO.userError "qualified infer-only binder changed acceptance")
  for expr in [pi, identity] do
    match psKernelC0CertifiedWorkInferBinderOwned 0 work expr,
          psKernelC0CertifiedWorkInfer 0 work expr with
    | .error left, .error right =>
        if left != right then
          throw (IO.userError "infer-only binder zero-fuel mismatch")
    | _, _ => throw (IO.userError "source infer-only binder bypassed fuel")
  let blocked : PsKernelCheckerSession := {
    source with
    context := {
      source.context with
      maxRecDepth := 1
      recDepth := 1000000
    }
  }
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "limited infer-only source work failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "limited infer-only work certification failed")
  match psKernelC0CertifiedWorkInferBinderOwned 4096 blockedWork identity,
        psKernelC0CertifiedWorkInfer 4096 blockedWork identity with
  | .error left, .error right =>
      if left != right then
        throw (IO.userError "infer-only binder recursion error changed")
  | _, _ => throw (IO.userError "infer-only binder bypassed source depth")

  -- A verified provider can expose an infer-only type but cannot publish
  -- the type without independently applying full checked source semantics.
  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok result => pure result
    | .error _ => throw (IO.userError "inferred binder provider genesis failed")
  let (inferred, _) ← match psKernelC0VerifiedProviderInfer genesis identity with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified binder inference failed")
  let (checked, _) ← match psKernelC0VerifiedProviderCheck genesis identity with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified checked binder failed")
  if !psKernelExprEqual inferred checked ||
      !psKernelExprEqual inferred pi then
    throw (IO.userError "verified infer/check binder source parity changed")
  match psKernelC0VerifiedProviderPublishRoots
      genesis [pi, dubiousLambda] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "infer-only binder reached checked publication")

  IO.println "C0_BINDER_INFER source_exact_infer_only_and_distinct_cache=pass"
  IO.println "C0_BINDER_INFER dependent_Pi_deep_binder_and_resource_errors=pass"
  IO.println "C0_BINDER_INFER verified_source_full_check_boundary=pass"
