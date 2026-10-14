import Ps.KernelCore.API.VerifiedProvider

/-!
End-to-end checked-root publishing from the *provider* interface.

A source-checked publication must carry both the exact selected-root staging
receipt and the exact audited source root-checking equation. Invalid, open,
resource-declined, and unauthorized inputs may never emit a partial artifact.
The source kernel remains the sole checking authority.
-/

def main : IO Unit := do
  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let provider := psKernelProviderDefault
  let genesis ← match psKernelC0VerifiedProviderBegin resources provider with
    | .ok result => pure result
    | .error _ => throw (IO.userError "provider publication genesis failed")
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let sort2 : PsKernelExpr := .sort (.succ (.succ .zero))
  let (inferred, inferredSession) ← match
      psKernelC0VerifiedProviderInfer genesis sort0 with
    | .ok result => pure result
    | .error _ => throw (IO.userError "source inference was not exposed")
  if !psKernelExprEqual inferred sort1 then
    throw (IO.userError "verified provider source inference changed Sort type")
  let (fullyChecked, _) ← match psKernelC0VerifiedProviderCheck genesis sort0 with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified provider full check failed")
  if !psKernelExprEqual inferred fullyChecked then
    throw (IO.userError "source provider inference and full check diverged")
  if psKernelEnvironmentSize
      inferredSession.verified.sealed.audited.trusted.certified.raw.checker.context.environment != 0 then
    throw (IO.userError "inference mutated checked source environment")
  let staged ← match psKernelC0VerifiedProviderStage genesis sort0 with
    | .ok result => pure result
    | .error _ => throw (IO.userError "checked syntax staging failed")
  let sourcePublished ← match psKernelC0VerifiedProviderCommitChecked staged with
    | .ok receipt => pure receipt
    | .error _ => throw (IO.userError "single-root source checking failed")
  let _singleSourceProof :=
    psKernelC0SealedAuditedPublicationExact sourcePublished
  match sourcePublished.roots with
  | [receipt] =>
      let _checkedRootProof := psKernelC0SourceCheckedRootExact receipt
      if !psKernelExprEqual receipt.checkedType sort1 then
        throw (IO.userError "provider published wrong checked source type")
  | _ => throw (IO.userError "source publication lost selected singleton")

  -- One immutable two-root transaction, with typed evidence of both the
  -- exact staging operation and the ALL-root source checking decision.
  let selected : List PsKernelExpr := [sort0, sort1]
  let batch ← match psKernelC0VerifiedProviderPublishRoots genesis selected with
    | .ok receipt => pure receipt
    | .error _ => throw (IO.userError "whole checked batch publication failed")
  let _stageEq := psKernelC0VerifiedProviderPublicationStagingExact batch
  let _checkEq := psKernelC0VerifiedProviderPublicationCheckExact batch
  match batch.checked.roots with
  | [first, second] =>
      if !psKernelExprEqual first.checkedType sort1 ||
          !psKernelExprEqual second.checkedType sort2 then
        throw (IO.userError "provider checked-root order/types changed")
  | _ => throw (IO.userError "provider batch publication lost checked roots")

  -- A valid prefix MUST NOT be published when a later selected source
  -- expression contains an invalid loose binder or undeclared universe.
  match psKernelC0VerifiedProviderPublishRoots genesis [sort0, .bvar 0] with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "mixed valid/invalid batch was not rejected")
  match psKernelC0VerifiedProviderPublishRoots genesis
      [sort0, .mvar (.str .anonymous "untrusted")] with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "metavariable batch published a checked root")
  match psKernelC0VerifiedProviderPublishRoots genesis
      [sort0, .sort (.param (.str .anonymous "undeclaredU"))] with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "unknown level param reached publication")

  -- Staging alone confers no proof authority. A separately staged invalid
  -- root also prevents publication of a valid staged prefix.
  let mixedStaged ← match psKernelC0VerifiedProviderStageRoots
      genesis [sort0, .bvar 0] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "syntax stage rejected an untyped bvar")
  match psKernelC0VerifiedProviderCommitChecked mixedStaged with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "provider published an untyped staged root")
  -- Immutable prior inputs still produce an independently checked result.
  match psKernelC0VerifiedProviderCommitChecked staged with
  | .ok receipt =>
      if receipt.roots.length != 1 then
        throw (IO.userError "failed publication mutated prior staged roots")
  | .error _ =>
      throw (IO.userError "failed transaction damaged immutable prior work")

  -- All public checked operations share the provider's typed preflight.
  let cancelledResources : PsKernelResourcePolicy :=
    { resources with cancelled := true }
  let cancelled := { genesis with resources := cancelledResources }
  match psKernelC0VerifiedProviderPublishRoots cancelled [sort0] with
  | .error (.resourceExhausted .cancelled _) => pure ()
  | _ => throw (IO.userError "cancelled publishing bypassed resource policy")
  match psKernelC0VerifiedProviderInfer cancelled sort0 with
  | .error (.resourceExhausted .cancelled _) => pure ()
  | _ => throw (IO.userError "provider inference bypassed cancellation")

  -- Trust approval is explicit, AND the source checker must actually
  -- admit the signed request before its constant can be checked/published.
  let signedName : PsKernelName := .str .anonymous "ProviderPublishedAssumption"
  let signed : PsKernelAxiomInfo := {
    base := {
      name := signedName
      levelParams := []
      type := sort0
    }
    isUnsafe := false
  }
  match psKernelC0VerifiedProviderAdmit genesis (.axiomDecl signed) with
  | .error (.declinedUnsupported _) => pure ()
  | _ => throw (IO.userError "unsigned assumption was admitted")
  let permitted ← match psKernelC0VerifiedProviderChangePolicy
      genesis [signed] [] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "explicit axiom policy review declined")
  let approved ← match psKernelC0VerifiedProviderAdmit
      permitted (.axiomDecl signed) with
    | .ok result => pure result
    | .error _ => throw (IO.userError "source checker rejected reviewed axiom")
  match psKernelC0VerifiedProviderChangePolicy approved [] [] with
  | .error (.declinedUnsupported _) => pure ()
  | _ => throw (IO.userError "provider silently downgraded assumption history")
  let axiomPublished ← match psKernelC0VerifiedProviderPublishRoots
      approved [.const signedName []] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "approved checked axiom root was rejected")
  let _axiomSourceCheck :=
    psKernelC0VerifiedProviderPublicationCheckExact axiomPublished
  match axiomPublished.checked.roots with
  | [receipt] =>
      if !psKernelExprEqual receipt.checkedType sort0 then
        throw (IO.userError "approved axiom publication changed source type")
  | _ => throw (IO.userError "approved axiom publication lost checked root")
  if (psKernelC0HistoryAxiomSignatures
      axiomPublished.staged.verified.sealed.audited.trusted.history).length != 1 then
    throw (IO.userError "publication lost exact authorized assumption history")
  if psKernelEnvironmentSize
      genesis.verified.sealed.audited.trusted.certified.raw.checker.context.environment != 0 then
    throw (IO.userError "published axiom changed immutable genesis")

  IO.println "C0_PROVIDER_PUBLISH source_infer_and_checked_root_types=pass"
  IO.println "C0_PROVIDER_PUBLISH exact_staging_and_source_publication_receipts=pass"
  IO.println "C0_PROVIDER_PUBLISH mixed_invalid_open_universe_atomic_rejection=pass"
  IO.println "C0_PROVIDER_PUBLISH resource_and_assumption_policy_boundaries=pass"
