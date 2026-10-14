import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedLetInference

/-!
Phase E.4U: source-exact independently dispatched dependent LET heads.

The original Lean 4.35-style let binder checks its annotated type and
value, opens a fresh local body, and closes the resulting type. The checked
head rule here is source shared, but all child judgments remain the
original recursive checker. Every positive result has an exact equation
to the entire authoritative source result and checker state.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "CheckedLet"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let valid : PsKernelExpr :=
    .letE name sort1 sort0 (.bvar 0) false
  let unused : PsKernelExpr :=
    .letE name sort1 sort0 sort0 true
  let wrong : PsKernelExpr :=
    .letE name sort0 sort0 (.bvar 0) false
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "source let work genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "source let canonical-work proof failed")

  for term in [valid, unused] do
    let checked ← match psKernelC0CertifiedWorkCheckLetOwned
        4096 work term with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("checked let head failed: " ++ e))
    let _sourceEq :
        psKernelC0CertifiedWorkCheck 4096 work term =
          .ok checked.val :=
      checked.property
    if !psKernelExprEqual checked.val.fst sort1 then
      throw (IO.userError "checked let returned wrong source type")
    let inferred ← match psKernelC0CertifiedWorkInferLetOwned
        4096 work term with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("let infer-only failed: " ++ e))
    let _inferEq :
        psKernelC0CertifiedWorkInfer 4096 work term =
          .ok inferred.val :=
      inferred.property
    if !psKernelExprEqual inferred.val.fst sort1 then
      throw (IO.userError "let infer-only changed source result")

  -- Type mismatch rejects only FULL checking. Infer-only is never itself
  -- a proof and may expose types of terms that fail the later check.
  match psKernelC0CertifiedWorkCheckLetOwned 4096 work wrong,
        psKernelC0CertifiedWorkCheck 4096 work wrong with
  | .error observed, .error sourceError =>
      if observed != sourceError then
        throw (IO.userError "checked let mismatch error changed")
  | _, _ =>
      throw (IO.userError "checked let type mismatch was accepted")
  let inferWrong ← match psKernelC0CertifiedWorkInferLetOwned
      4096 work wrong with
    | .ok receipt => pure receipt
    | .error e =>
        throw (IO.userError ("infer-only let unexpectedly rejected: " ++ e))
  let _inferWrongSource :
      psKernelC0CertifiedWorkInfer 4096 work wrong = .ok inferWrong.val :=
    inferWrong.property
  if !psKernelExprEqual inferWrong.val.fst sort0 then
    throw (IO.userError "infer-only let type changed")

  -- A long checked suffix exercises the source's optional immutable
  -- let-frame summaries. The exact theorem is independent of let depth.
  let mut deep : PsKernelExpr := sort0
  for _ in [:18] do
    deep := .letE name sort1 sort0 deep true
  let deepChecked ← match psKernelC0CertifiedWorkCheckLetOwned
      4096 work deep with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("deep checked let failed: " ++ e))
  let _deepEq :
      psKernelC0CertifiedWorkCheck 4096 work deep =
        .ok deepChecked.val :=
    deepChecked.property
  if !psKernelExprEqual deepChecked.val.fst sort1 then
    throw (IO.userError "let-frame checked source result changed")

  -- Exact failures must not produce checked work, even if syntactically
  -- wrapped source let expressions superficially look like safe binders.
  let invalid : PsKernelExpr :=
    .letE name sort1 sort0 (.mvar (.str .anonymous "untrusted")) false
  match psKernelC0CertifiedWorkCheckLetOwned 4096 work invalid with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "checked let accepted metavariable body")
  for term in [valid, deep] do
    match psKernelC0CertifiedWorkCheckLetOwned 0 work term,
          psKernelC0CertifiedWorkCheck 0 work term with
    | .error observed, .error sourceError =>
        if observed != sourceError then
          throw (IO.userError "let source fuel error category changed")
    | _, _ => throw (IO.userError "direct let bypassed source zero fuel")
  let blocked : PsKernelCheckerSession := {
    source with
    context := {
      source.context with
      maxRecDepth := 1
      recDepth := 1000000
    }
  }
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "blocked let source work failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "blocked let certified work failed")
  match psKernelC0CertifiedWorkCheckLetOwned 4096 blockedWork valid,
        psKernelC0CertifiedWorkCheck 4096 blockedWork valid with
  | .error observed, .error sourceError =>
      if observed != sourceError then
        throw (IO.userError "checked let recursion error changed")
  | _, _ => throw (IO.userError "direct let ignored source recursion depth")

  -- Actual verified source-checked sessions must accept valid lets and
  -- reject invalid ones before creating any atomic published root.
  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok provider => pure provider
    | .error _ => throw (IO.userError "checked let provider genesis failed")
  let (checkedType, _) ← match psKernelC0VerifiedProviderCheck genesis valid with
    | .ok result => pure result
    | .error e => throw (IO.userError ("verified let checking failed: " ++ toString e))
  if !psKernelExprEqual checkedType sort1 then
    throw (IO.userError "verified checked let type was altered")
  match psKernelC0VerifiedProviderCheck genesis wrong with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider accepted let value mismatch")
  let publication ← match psKernelC0VerifiedProviderPublishRoots
      genesis [valid, unused] with
    | .ok receipt => pure receipt
    | .error _ => throw (IO.userError "valid let publication was rejected")
  let _staged := psKernelC0VerifiedProviderPublicationStagingExact publication
  let _accepted := psKernelC0VerifiedProviderPublicationCheckExact publication
  if publication.checked.roots.length != 2 then
    throw (IO.userError "checked let batch publication lost roots")
  match psKernelC0VerifiedProviderPublishRoots genesis [valid, wrong] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "mixed valid/invalid let roots published")
  if !(psKernelC0HistoryAxiomSignatures
      publication.staged.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "source checked let inserted a trusted assumption")

  IO.println "C0_QUALIFIED_LET exact_checked_and_infer_only_source_equations=pass"
  IO.println "C0_QUALIFIED_LET deep_binder_error_and_resource_semantics=pass"
  IO.println "C0_QUALIFIED_LET audited_atomic_publication=pass"
