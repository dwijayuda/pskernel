import Ps.KernelCore.Architecture.SealedAuditedState

def main : IO Unit := do
  let some genesis := psKernelC0SealedAuditedBegin
      4096 psKernelLeanNatMaxSizeDefault [] []
    | throw (IO.userError "sealed audited source genesis failed")
  let _genesisHistory := psKernelC0SealedAuditedHasLineage genesis
  let _axiomProof := psKernelC0SealedAuditedAxiomsApproved genesis
  let _capsProof := psKernelC0SealedAuditedCapabilitiesApproved genesis
  let sort0 : PsKernelExpr := .sort .zero
  let (normalized, afterWhnf) ← match psKernelC0SealedAuditedWhnf
      4096 genesis (.mdata 1 (.mdata 2 sort0)) with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited lineage WHNF failed: " ++ e))
  if !psKernelExprEqual normalized sort0 then
    throw (IO.userError "audited lineage WHNF disagreed with source")
  let (inferred, afterInfer) ← match psKernelC0SealedAuditedInfer
      4096 afterWhnf sort0 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited lineage infer failed: " ++ e))
  if !psKernelExprEqual inferred (.sort (.succ .zero)) then
    throw (IO.userError "audited lineage inferred wrong sort")
  let (checked, afterCheck) ← match psKernelC0SealedAuditedCheck
      4096 afterInfer sort0 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited lineage check failed: " ++ e))
  if !psKernelExprEqual checked inferred then
    throw (IO.userError "audited lineage checked wrong sort")
  let (same, afterDefEq) ← match psKernelC0SealedAuditedDefEq
      4096 afterCheck sort0 sort0 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited lineage DefEq failed: " ++ e))
  if !same then throw (IO.userError "audited lineage denied identical sort")
  match psKernelC0SealedAuditedCheck 4096 afterDefEq (.bvar 0) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "audited lineage checked loose bound variable")
  let some staged := psKernelC0SealedAuditedStage afterDefEq sort0
    | throw (IO.userError "audited lineage staging failed")
  let _stageProof := psKernelC0SealedAuditedHasLineage staged

  -- Only an exact, whole-source-check success can publish staged
  -- syntax as a checked root. The proof binds the complete audited work.
  let publication ← match psKernelC0SealedAuditedCommitChecked 4096 staged with
    | .ok result => pure result
    | .error e => throw (IO.userError ("sealed checked publication failed: " ++ e))
  let _sourceReceipt := psKernelC0SealedAuditedPublicationExact publication
  match publication.roots with
  | [receipt] =>
      let _rootProof := psKernelC0SourceCheckedRootExact receipt
      if !psKernelExprEqual receipt.checkedType (.sort (.succ .zero)) then
        throw (IO.userError "audited checked publication changed closed root type")
  | _ => throw (IO.userError "sealed audited publication lost selected root")
  let some invalidStaged := psKernelC0SealedAuditedStage genesis (.bvar 0)
    | throw (IO.userError "negative untyped staging failed unexpectedly")
  match psKernelC0SealedAuditedCommitChecked 4096 invalidStaged with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "sealed audited publication accepted loose bound root")

  -- Publication must be atomic even when an earlier selected root
  -- checks successfully and a later staged root is malformed.
  let some firstMixed := psKernelC0SealedAuditedStage genesis sort0
    | throw (IO.userError "sealed mixed-publication first stage failed")
  let some mixed := psKernelC0SealedAuditedStage firstMixed (.bvar 0)
    | throw (IO.userError "sealed mixed-publication second stage failed")
  match psKernelC0SealedAuditedCommitChecked 4096 mixed with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "sealed audited publication partially accepted roots")
  if psKernelEnvironmentSize
      genesis.audited.trusted.certified.raw.checker.context.environment != 0 then
    throw (IO.userError "failed mixed publication mutated checked genesis")

  -- Approving a signature only permits source admission; it never
  -- substitutes for the original checker or an exact lineage step.
  let signedName : PsKernelName := .str .anonymous "ExplicitSealedAxiom"
  let info : PsKernelAxiomInfo := {
    base := {
      name := signedName
      levelParams := []
      type := .sort .zero
    }
    isUnsafe := false
  }
  match psKernelC0SealedAuditedAdmit 4096 staged (.axiomDecl info) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "sealed audited state admitted unapproved axiom")
  let some permitted := psKernelC0SealedAuditedChangePolicy staged [info] []
    | throw (IO.userError "explicit sealed audit widening failed")
  let admitted ← match psKernelC0SealedAuditedAdmit
      4096 permitted (.axiomDecl info) with
    | .ok value => pure value
    | .error e => throw (IO.userError ("approved sealed axiom rejected: " ++ e))
  let _admittedLineage := psKernelC0SealedAuditedHasLineage admitted
  let _admittedApproval := psKernelC0SealedAuditedAxiomsApproved admitted
  let _admittedCaps := psKernelC0SealedAuditedCapabilitiesApproved admitted
  if (psKernelC0SealedAuditedChangePolicy admitted [] []).isSome then
    throw (IO.userError "sealed history silently discarded admitted axiom")
  if (psKernelC0HistoryAxiomSignatures admitted.audited.trusted.history).length != 1 then
    throw (IO.userError "sealed audited lineage lost exact admitted axiom")
  match psKernelC0SealedAuditedWhnf 0 admitted sort0 with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "audited lineage bypassed zero source fuel")
  IO.println "C0_SEALED_AUDITED exact_state_genesis_and_checked_steps=pass"
  IO.println "C0_SEALED_AUDITED exact_axiom_signature_permission_proofs=pass"
  IO.println "C0_SEALED_AUDITED failed_admission_and_policy_narrowing_atomic=pass"
