import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
Axiom scope is explicit even when each underlying source admission is valid.
An allowance of an ordinary axiom is not a proof of its proposition; it is
a separately authorized assumption recorded in a checked history.
-/

def c0AuditedName (s : String) : PsKernelName := .str .anonymous s

def c0AuditedAxiom (name : PsKernelName) : PsKernelAxiomInfo := {
  base := {
    name := name
    levelParams := []
    type := .sort .zero
  }
  isUnsafe := false
}

def main : IO Unit := do
  let some genesis := psKernelC0AuditedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "audited empty source genesis declined")
  if !(psKernelC0HistoryOrdinaryAxioms genesis.trusted.history).isEmpty then
    throw (IO.userError "empty checked genesis unexpectedly assumed an axiom")
  -- These are real propositional no-assumption theorems over the entire
  -- checked source-admission history, not a claim of kernel consistency.
  if hA : genesis.allowedAxioms = [] then
    let _zeroAxioms :=
      psKernelC0AuditedNoOrdinaryAxioms genesis hA
    pure ()
  else
    throw (IO.userError "empty audited genesis changed signature allowance")
  if hC : genesis.allowedCapabilities = [] then
    let _zeroCapabilities :=
      psKernelC0AuditedNoTrustCapabilities genesis hC
    pure ()
  else
    throw (IO.userError "empty audited genesis changed capability allowance")
  let firstName := c0AuditedName "ReviewedAxiom"
  let secondName := c0AuditedName "UnapprovedAxiom"
  let firstRequest : PsKernelC0ArchitectureDeclaration :=
    .axiomDecl (c0AuditedAxiom firstName)
  let secondRequest : PsKernelC0ArchitectureDeclaration :=
    .axiomDecl (c0AuditedAxiom secondName)
  match psKernelC0AuditedSourceAdmit 4096 genesis firstRequest with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "audited genesis admitted an unapproved assumption")
  if psKernelEnvironmentSize genesis.trusted.certified.raw.checker.context.environment != 0 then
    throw (IO.userError "failed axiom authorization mutated the genesis")

  let some allowed := psKernelC0AuditTrustedSource
      genesis.trusted [c0AuditedAxiom firstName]
    | throw (IO.userError "explicit one-axiom policy could not be certified")
  let _emptyApproved := psKernelC0AuditedSourceAxiomsApproved allowed
  let reviewed ← match psKernelC0AuditedSourceAdmit
      4096 allowed firstRequest with
    | .ok accepted => pure accepted
    | .error e =>
        throw (IO.userError ("approved axiom source checking failed: " ++ e))
  let _reviewedProof :
      psKernelC0HistoryAxiomsApproved reviewed.trusted.history
        reviewed.allowedAxioms :=
    psKernelC0AuditedSourceAxiomsApproved reviewed
  -- An approved AXIOM NAME must not authorize a different proposition,
  -- universe signature, or safety classification at the same name.
  let approvedSignature := c0AuditedAxiom firstName
  let wrongProposition : PsKernelAxiomInfo := {
    approvedSignature with
    base := { approvedSignature.base with type := .sort (.succ .zero) }
  }
  let wrongUniverse : PsKernelAxiomInfo := {
    approvedSignature with
    base := {
      approvedSignature.base with
      levelParams := [c0AuditedName "differentUniverse"]
    }
  }
  let wrongSafety : PsKernelAxiomInfo := {
    approvedSignature with isUnsafe := true
  }
  for modified in [wrongProposition, wrongUniverse, wrongSafety] do
    if psKernelC0OrdinaryAxiomRequestApproved
        (.axiomDecl modified) [approvedSignature] then
      throw (IO.userError "name-only match authorized altered axiom signature")
    match psKernelC0AuditedSourceAdmit 4096 allowed
        (.axiomDecl modified) with
    | .error _ => pure ()
    | .ok _ =>
        throw (IO.userError "audited source admitted altered axiom signature")
    if (psKernelC0AuditTrustedSource reviewed.trusted [modified]).isSome then
      throw (IO.userError "accepted axiom history was re-audited under wrong type")
  if member : approvedSignature ∈
      psKernelC0HistoryAxiomSignatures reviewed.trusted.history then
    let _fullyTypedAuthorization :
        approvedSignature ∈ reviewed.allowedAxioms :=
      psKernelC0AuditedAxiomSignatureAllowed
        reviewed approvedSignature member
    pure ()
  else
    throw (IO.userError "reviewed full axiom signature had no history membership")
  match psKernelC0HistoryAxiomSignatures reviewed.trusted.history with
  | [actual] =>
      if !decide (actual = approvedSignature) then
        throw (IO.userError "exact checked axiom declaration provenance lost")
  | _ => throw (IO.userError "typed history lost reviewed axiom signature")
  match psKernelC0HistoryOrdinaryAxioms reviewed.trusted.history with
  | [actual] =>
      if !psKernelNameEq actual firstName then
        throw (IO.userError "audited history recorded wrong ordinary axiom")
  | _ => throw (IO.userError "audited history lost source axiom provenance")
  -- Authorization proves actual structural name membership, even for
  -- non-ASCII source identifiers and nested numeric name components.
  let nestedAxiomName : PsKernelName :=
    .num (.str .anonymous "Reviewed🧪") 17
  let nestedRequest : PsKernelC0ArchitectureDeclaration :=
    .axiomDecl (c0AuditedAxiom nestedAxiomName)
  match psKernelC0AuditedSourceAdmit 4096 reviewed nestedRequest with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "unlisted composite axiom name was authorized")
  if psKernelEnvironmentSize reviewed.trusted.certified.raw.checker.context.environment != 1 then
    throw (IO.userError "reviewed source axiom not admitted")

  match psKernelC0AuditedSourceAdmit 4096 reviewed secondRequest with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "audited history accepted a second unapproved axiom")
  match psKernelC0AuditedSourceAdmit 4096 reviewed firstRequest with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "source checker admitted a duplicate reviewed axiom")
  let some reopened := psKernelC0AuditTrustedSource
      reviewed.trusted [c0AuditedAxiom firstName, c0AuditedAxiom secondName]
    | throw (IO.userError "explicitly expanded axiom policy was not certifiable")
  let expanded ← match psKernelC0AuditedSourceAdmit
      4096 reopened secondRequest with
    | .ok accepted => pure accepted
    | .error e =>
        throw (IO.userError ("expanded reviewed source admission failed: " ++ e))
  if (psKernelC0HistoryOrdinaryAxioms expanded.trusted.history).length != 2 then
    throw (IO.userError "expanded checked axiom history lost assumptions")
  if (psKernelC0AuditTrustedSource
      expanded.trusted [c0AuditedAxiom firstName]).isSome then
    throw (IO.userError "history was downgraded to narrower false axiom policy")

  -- The policy affects assumption admission only: a source-checked
  -- definition with no new axioms remains permitted under the same list.
  let defName := c0AuditedName "ReviewedDefinition"
  let definition : PsKernelDefinitionInfo := {
    base := {
      name := defName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := .sort .zero
    hints := .abbrevHint
    safety := .safe
  }
  let next ← match psKernelC0AuditedSourceAdmit 4096 reviewed
      (.definition definition) with
    | .ok accepted => pure accepted
    | .error e =>
        throw (IO.userError ("source definition under approved policy failed: " ++ e))
  if (psKernelC0HistoryOrdinaryAxioms next.trusted.history).length != 1 then
    throw (IO.userError "ordinary definition changed assumptions ledger")
  -- Checked judgments and syntax staging must retain the same approved
  -- history. Even an approved axiom does not turn ill-typed syntax into a
  -- closed checked publication.
  let (checkedType, afterCheck) ← match psKernelC0AuditedSourceCheck
      4096 next (.sort .zero) with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited source check failed: " ++ e))
  if !psKernelExprEqual checkedType (.sort (.succ .zero)) then
    throw (IO.userError "audited check changed source Sort typing")
  let (unfolded, afterWhnf) ← match psKernelC0AuditedSourceWhnf
      4096 afterCheck (.const defName []) with
    | .ok result => pure result
    | .error e => throw (IO.userError ("audited source WHNF failed: " ++ e))
  if !psKernelExprEqual unfolded (.sort .zero) then
    throw (IO.userError "audited checked definition did not unfold")
  let _stillApproved := psKernelC0AuditedSourceAxiomsApproved afterWhnf
  let some staged := psKernelC0AuditedSourceStage
      afterWhnf (.sort .zero)
    | throw (IO.userError "audited staging declined closed source syntax")
  let (_, receipts) ← match psKernelC0AuditedSourceCommitChecked
      4096 staged with
    | .ok result => pure result
    | .error e =>
        throw (IO.userError ("audited checked publication failed: " ++ e))
  match receipts with
  | [receipt] =>
      let _sourceProof := psKernelC0SourceCheckedRootExact receipt
      if !psKernelExprEqual receipt.checkedType (.sort (.succ .zero)) then
        throw (IO.userError "audited publication returned wrong source type")
  | _ => throw (IO.userError "audited publication dropped a closed root")
  let some malformed := psKernelC0AuditedSourceStage staged (.bvar 0)
    | throw (IO.userError "audited syntax-only stage refused unbound bvar")
  match psKernelC0AuditedSourceCommitChecked 4096 malformed with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "approved assumption bypassed full root checking")
  let _malformedStillApproved :=
    psKernelC0AuditedSourceAxiomsApproved malformed
  -- Quot, unsafe/partial definitions, unsafe opaques, and unsafe
  -- inductive families are distinct trust capabilities. The ordinary
  -- axiom-name allowlist must NOT authorize any of them implicitly.
  let unsafeName := c0AuditedName "ReviewedUnsafeDefinition"
  let unsafeDefinition : PsKernelDefinitionInfo := {
    base := {
      name := unsafeName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := .sort .zero
    hints := .abbrevHint
    safety := .unsafeDef
  }
  let partialDefinition : PsKernelDefinitionInfo := {
    unsafeDefinition with safety := .partialDef
  }
  let unsafeRequest : PsKernelC0ArchitectureDeclaration :=
    .definition unsafeDefinition
  let partialRequest : PsKernelC0ArchitectureDeclaration :=
    .definition partialDefinition
  if psKernelC0RequestCapabilitiesApproved unsafeRequest [] ||
      psKernelC0RequestCapabilitiesApproved partialRequest [] ||
      psKernelC0RequestCapabilitiesApproved .quotient [] then
    throw (IO.userError "trust-bearing declaration was implicitly authorized")
  let preciseAllowance : List PsKernelC0TrustCapability :=
    [.unsafeDefinition unsafeName]
  if !psKernelC0RequestCapabilitiesApproved unsafeRequest preciseAllowance ||
      psKernelC0RequestCapabilitiesApproved partialRequest preciseAllowance then
    throw (IO.userError "unsafe/partial declaration capabilities were conflated")
  let unsafeAxiomName := c0AuditedName "UnsafeReviewedAxiom"
  let unsafeAxiomRequest : PsKernelC0ArchitectureDeclaration :=
    .axiomDecl {
      base := {
        name := unsafeAxiomName
        levelParams := []
        type := .sort .zero
      }
      isUnsafe := true
    }
  let some nameApprovedUnsafe := psKernelC0AuditTrustedSourceWithCapabilities
      genesis.trusted [{ (c0AuditedAxiom unsafeAxiomName) with isUnsafe := true }] []
    | throw (IO.userError "unsafe axiom name allowlist was not certifiable")
  match psKernelC0AuditedSourceAdmit 4096
      nameApprovedUnsafe unsafeAxiomRequest with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "ordinary axiom name approved unsafe capability implicitly")
  if !psKernelC0RequestCapabilitiesApproved unsafeAxiomRequest
      [.unsafeAxiom unsafeAxiomName] ||
      psKernelC0RequestCapabilitiesApproved unsafeAxiomRequest [] then
    throw (IO.userError "unsafe axiom did not require separate capability")

  match psKernelC0AuditedSourceAdmit 4096 reviewed unsafeRequest with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "audited profile admitted unapproved unsafe definition")
  let opaqueRequest : PsKernelC0ArchitectureDeclaration :=
    .opaqueDecl {
      base := {
        name := c0AuditedName "UnreviewedOpaque"
        levelParams := []
        type := .sort (.succ .zero)
      }
      value := .sort .zero
      isUnsafe := true
    }
  if psKernelC0RequestCapabilitiesApproved opaqueRequest [] then
    throw (IO.userError "unsafe opaque escaped capability audit")
  let unsafeInductive : PsKernelSimpleInductiveDecl := {
    levelParams := []
    name := c0AuditedName "UnreviewedInductive"
    type := .sort .zero
    ctors := []
    isUnsafe := true
    numParams := 0
  }
  if psKernelC0RequestCapabilitiesApproved
      (.ordinaryInductive unsafeInductive) [] then
    throw (IO.userError "unsafe ordinary inductive escaped capability audit")
  let unsafeMutual : PsKernelSimpleMutualInductiveDecl := {
    levelParams := []
    numParams := 0
    types := [{
      name := c0AuditedName "UnreviewedMutual"
      type := .sort .zero
      ctors := []
    }]
    isUnsafe := true
  }
  if psKernelC0RequestCapabilitiesApproved
      (.mutualInductive unsafeMutual) [] ||
      psKernelC0RequestCapabilitiesApproved
        (.nestedInductive unsafeMutual) [] then
    throw (IO.userError "unsafe mutual/nested declaration escaped capability audit")

  -- A real Eq followed by real quotient initialization requires an
  -- explicit quotient capability *even with a fully valid source Eq*.
  let univ := c0AuditedName "u"
  let eqDecl : PsKernelSimpleInductiveDecl := {
    levelParams := [univ]
    name := psKernelEqName
    type := psKernelExpectedEqType univ
    ctors := [{
      name := .str psKernelEqName "refl"
      type := psKernelExpectedEqReflType univ
    }]
    isUnsafe := false
    numParams := 2
  }
  let eqWork ← match psKernelC0AuditedSourceAdmit 32768 genesis
      (.ordinaryInductive eqDecl) with
    | .ok checked => pure checked
    | .error e =>
        throw (IO.userError ("checked Eq under audited genesis failed: " ++ e))
  match psKernelC0AuditedSourceAdmit 32768 eqWork .quotient with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "valid Eq implicitly authorized Quot foundation")
  let some allowedQuot := psKernelC0AuditTrustedSourceWithCapabilities
      eqWork.trusted [] [.quotientBootstrap]
    | throw (IO.userError "explicit quotient review could not be certified")
  let quotWork ← match psKernelC0AuditedSourceAdmit
      32768 allowedQuot .quotient with
    | .ok checked => pure checked
    | .error e =>
        throw (IO.userError ("explicit checked Quot admission failed: " ++ e))
  if !quotWork.trusted.certified.raw.checker.context.environment.quotInitialized then
    throw (IO.userError "approved source quotient was not initialized")
  match psKernelC0HistoryTrustCapabilities quotWork.trusted.history with
  | [.quotientBootstrap] => pure ()
  | _ => throw (IO.userError "checked history lost quotient trust event")
  if (psKernelC0AuditTrustedSource quotWork.trusted []).isSome then
    throw (IO.userError "approved Quot history was downgraded to no-capability audit")
  if member : PsKernelC0TrustCapability.quotientBootstrap ∈
      psKernelC0HistoryTrustCapabilities quotWork.trusted.history then
    let _formalAuthorization :
        PsKernelC0TrustCapability.quotientBootstrap ∈
          quotWork.allowedCapabilities :=
      psKernelC0AuditedCapabilityAllowed
        quotWork .quotientBootstrap member
    pure ()
  else
    throw (IO.userError "approved Quot capability missing from checked history")
  let _quotApproved := psKernelC0AuditedSourceCapabilitiesApproved quotWork
  let (quotChecked, afterQuotCheck) ← match psKernelC0AuditedSourceCheck
      32768 quotWork (.sort .zero) with
    | .ok checked => pure checked
    | .error e => throw (IO.userError ("source check lost quotient history: " ++ e))
  if !psKernelExprEqual quotChecked (.sort (.succ .zero)) then
    throw (IO.userError "checked source Sort changed after quotient authorization")
  let _quotStillApproved :=
    psKernelC0AuditedSourceCapabilitiesApproved afterQuotCheck
  let some stagedQuot := psKernelC0AuditedSourceStage
      afterQuotCheck (.sort .zero)
    | throw (IO.userError "quotient audited stage lost environment proof")
  let _stagedQuotApproved :=
    psKernelC0AuditedSourceCapabilitiesApproved stagedQuot
  let (_, quotReceipts) ← match psKernelC0AuditedSourceCommitChecked
      32768 stagedQuot with
    | .ok completed => pure completed
    | .error e =>
        throw (IO.userError ("approved Quot checked publication failed: " ++ e))
  match quotReceipts with
  | [receipt] =>
      let _checkedResult := psKernelC0SourceCheckedRootExact receipt
      if !psKernelExprEqual receipt.checkedType (.sort (.succ .zero)) then
        throw (IO.userError "approved Quot publication changed checked type")
  | _ =>
      throw (IO.userError "approved Quot publication lost checked root")

  -- Steady-state audited admission must extend the existing proof from
  -- each source-checked request, not re-traverse the entire history on
  -- every accepted definition. Re-audit once at the end to independently
  -- compare the incremental ledger with full-history reconstruction.
  let mut incremental := stagedQuot
  for i in [:24] do
    let name : PsKernelName :=
      .num (c0AuditedName "IncrementalSafeDefinition") i
    let info : PsKernelDefinitionInfo := {
      base := {
        name := name
        levelParams := []
        type := .sort (.succ .zero)
      }
      value := .sort .zero
      hints := .abbrevHint
      safety := .safe
    }
    incremental ← match psKernelC0AuditedSourceAdmit
        8192 incremental (.definition info) with
      | .ok accepted => pure accepted
      | .error e =>
          throw (IO.userError ("incremental audited admission failed: " ++ e))
  let rebuilt := psKernelC0AuditTrustedSourceWithCapabilities
    incremental.trusted [] [.quotientBootstrap]
  if rebuilt.isNone ||
      (psKernelC0HistoryOrdinaryAxioms
        incremental.trusted.history).length != 0 ||
      (psKernelC0HistoryTrustCapabilities
        incremental.trusted.history).length != 1 then
    throw (IO.userError "incremental audit disagreed with complete history replay")
  let _incrementalAxioms := psKernelC0AuditedSourceAxiomsApproved incremental
  let _incrementalCapabilities :=
    psKernelC0AuditedSourceCapabilitiesApproved incremental

  IO.println "C0_AUDITED unapproved_axiom_blocked_atomically=pass"
  IO.println "C0_AUDITED authorized_source_assumptions_and_history=pass"
  IO.println "C0_AUDITED narrowed_policy_rejected_and_definitions_preserved=pass"
  IO.println "C0_AUDITED source_judgments_and_closed_publication=pass"
  IO.println "C0_AUDITED quotient_and_unsafe_capability_history=pass"
  IO.println "C0_AUDITED incremental_history_proof_matches_full_replay=pass"
  IO.println "C0_AUDITED exact_axiom_type_universe_safety_manifest=pass"
  IO.println "C0_AUDITED empty_foundation_has_no_source_admission_assumptions=pass"
