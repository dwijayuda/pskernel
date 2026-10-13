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
      genesis.trusted [firstName]
    | throw (IO.userError "explicit one-axiom policy could not be certified")
  let _emptyApproved := psKernelC0AuditedSourceAxiomsApproved allowed
  let reviewed ← match psKernelC0AuditedSourceAdmit
      4096 allowed firstRequest with
    | .ok accepted => pure accepted
    | .error e =>
        throw (IO.userError ("approved axiom source checking failed: " ++ e))
  let _reviewedProof :
      psKernelC0HistoryAxiomsApproved reviewed.trusted.history
        reviewed.allowedAxioms = true :=
    psKernelC0AuditedSourceAxiomsApproved reviewed
  match psKernelC0HistoryOrdinaryAxioms reviewed.trusted.history with
  | [actual] =>
      if !psKernelNameEq actual firstName then
        throw (IO.userError "audited history recorded wrong ordinary axiom")
  | _ => throw (IO.userError "audited history lost source axiom provenance")
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
      reviewed.trusted [firstName, secondName]
    | throw (IO.userError "explicitly expanded axiom policy was not certifiable")
  let expanded ← match psKernelC0AuditedSourceAdmit
      4096 reopened secondRequest with
    | .ok accepted => pure accepted
    | .error e =>
        throw (IO.userError ("expanded reviewed source admission failed: " ++ e))
  if (psKernelC0HistoryOrdinaryAxioms expanded.trusted.history).length != 2 then
    throw (IO.userError "expanded checked axiom history lost assumptions")
  if (psKernelC0AuditTrustedSource
      expanded.trusted [firstName]).isSome then
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
  IO.println "C0_AUDITED unapproved_axiom_blocked_atomically=pass"
  IO.println "C0_AUDITED authorized_source_assumptions_and_history=pass"
  IO.println "C0_AUDITED narrowed_policy_rejected_and_definitions_preserved=pass"
  IO.println "C0_AUDITED source_judgments_and_closed_publication=pass"
