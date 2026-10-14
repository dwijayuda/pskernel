import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedMetadataInference

/-!
Phase E.4P: independent recursive, exact source metadata type checking.

Native Lean 4.35 requires metadata-transparent inference with the same
fuel and recursion-depth charges at every wrapper, while C0 maintains
separate infer-only and checked caches for complete wrapped expressions.
Every successful checked-work result carries an exact source equation.
-/

def main : IO Unit := do
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "metadata checked source genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "metadata checked source work certification failed")
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)

  -- Exact at every depth, including the minimum source fuel for each
  -- wrapped scalar head; source WHNF and typing callbacks are independent.
  for depth in [:25] do
    let mut wrapped : PsKernelExpr := sort0
    for i in [:depth] do
      wrapped := .mdata (100 + i) wrapped
    let exactFuel := depth + 1
    match psKernelC0MetadataInferWithFuel
        exactFuel source.context source.state wrapped false with
    | some (ty, nextState) =>
        if !psKernelExprEqual ty sort1 then
          throw (IO.userError "nested metadata changed checked source type")
        if (psKernelExprMapGet nextState.checkedInfer wrapped).isNone then
          throw (IO.userError "metadata source cache was not populated")
    | none =>
        throw (IO.userError "qualified metadata declined an exact-fuel root")
    let checked ← match psKernelC0CertifiedWorkCheckMetadataOwned
        exactFuel work wrapped with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("metadata full check failed: " ++ e))
    let _exactChecked :
        psKernelC0CertifiedWorkCheck exactFuel work wrapped = .ok checked.val :=
      checked.property
    if !psKernelExprEqual checked.val.fst sort1 then
      throw (IO.userError "metadata source certificate wrong type")
    let inferred ← match psKernelC0CertifiedWorkInferMetadataOwned
        exactFuel work wrapped with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("metadata inference failed: " ++ e))
    let _exactInfer :
        psKernelC0CertifiedWorkInfer exactFuel work wrapped = .ok inferred.val :=
      inferred.property
    if !psKernelExprEqual inferred.val.fst sort1 then
      throw (IO.userError "metadata infer-only certificate wrong type")
    if depth > 0 then
      if (psKernelC0MetadataInferWithFuel
          depth source.context source.state wrapped false).isSome then
        throw (IO.userError "metadata bypassed per-layer source fuel budget")
      match psKernelC0CertifiedWorkCheckMetadataOwned depth work wrapped with
      | .error _ => pure ()
      | .ok _ =>
          throw (IO.userError "metadata source fuel exhaustion became checked")

  let nested : PsKernelExpr := .mdata 300 (.mdata 301 sort0)
  let (type, afterSource) ← match psKernelSessionCheck 4096 source nested with
    | .ok result => pure result
    | .error e => throw (IO.userError ("metadata source warmup failed: " ++ e))
  if !psKernelExprEqual type sort1 then
    throw (IO.userError "metadata source warmup changed result")
  match psKernelC0MetadataInferWithFuel
      4096 afterSource.context afterSource.state nested false with
  | some (type, nextState) =>
      if !psKernelExprEqual type sort1 ||
          (psKernelExprMapGet nextState.checkedInfer nested).isNone then
        throw (IO.userError "nested metadata cache hit changed source state")
  | none => throw (IO.userError "metadata source warm-cache hit declined")

  -- A root enclosing an unqualified expression is NOT admitted just
  -- because the metadata layer is syntactically transparent.
  let loose : PsKernelExpr := .mdata 4 (.mdata 5 (.bvar 0))
  let unknown : PsKernelExpr :=
    .mdata 6 (.const (.str .anonymous "NotDeclared") [])
  let metavar : PsKernelExpr :=
    .mdata 7 (.mvar (.str .anonymous "UnknownMeta"))
  for bad in [loose, unknown, metavar] do
    if (psKernelC0MetadataInferWithFuel 4096
        source.context source.state bad false).isSome then
      throw (IO.userError "independent metadata admitted invalid terminal")
    match psKernelC0CertifiedWorkCheckMetadataOwned 4096 work bad with
    | .error _ => pure ()
    | .ok _ =>
        throw (IO.userError "metadata ignored source terminal rejection")

  let blockedContext : PsKernelCheckerContext := {
    source.context with
    maxRecDepth := 1
    recDepth := 1000000
  }
  if (psKernelC0MetadataInferWithFuel
      4096 blockedContext source.state nested false).isSome then
    throw (IO.userError "metadata bypassed original recursion guard")
  if (psKernelC0MetadataInferWithFuel 0
      source.context source.state nested false).isSome then
    throw (IO.userError "metadata bypassed zero-fuel source error")

  -- A checked source definition under metadata remains source checked
  -- and can be atomically published ONLY through the verified provider.
  let name : PsKernelName := .str .anonymous "MetadataCheckedDefinition"
  let info : PsKernelDefinitionInfo := {
    base := {
      name := name
      levelParams := []
      type := sort1
    }
    value := sort0
    hints := .abbrevHint
    safety := .safe
  }
  let policy : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 16
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      policy psKernelProviderDefault with
    | .ok value => pure value
    | .error _ => throw (IO.userError "metadata verified provider genesis failed")
  let admitted ← match psKernelC0VerifiedProviderAdmit
      genesis (.definitionDecl info) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "metadata verified admission failed")
  let metadataConstant : PsKernelExpr :=
    .mdata 10 (.mdata 11 (.const name []))
  let (checkedType, next) ← match psKernelC0VerifiedProviderCheck
      admitted metadataConstant with
    | .ok result => pure result
    | .error _ => throw (IO.userError "metadata verified checked constant failed")
  if !psKernelExprEqual checkedType sort1 ||
      !(psKernelC0HistoryAxiomSignatures
        next.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "metadata source checking corrupted source foundation")
  let receipt ← match psKernelC0VerifiedProviderPublishRoots
      admitted [metadataConstant] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "metadata verified atomic publication failed")
  let _exactStaging := psKernelC0VerifiedProviderPublicationStagingExact receipt
  let _exactCommit := psKernelC0VerifiedProviderPublicationCheckExact receipt
  match receipt.checked.roots with
  | [root] =>
      if !psKernelExprEqual root.checkedType sort1 then
        throw (IO.userError "metadata publication changed source root type")
  | _ => throw (IO.userError "metadata publication lost the checked root")

  IO.println "C0_METADATA_TYPING recursive_depth_fuel_and_cache_source_proofs=pass"
  IO.println "C0_METADATA_TYPING fail_closed_unqualified_term_and_resource=pass"
  IO.println "C0_METADATA_TYPING verified_publication_source_equivalence=pass"
