import Ps.KernelCore.Architecture.TrustedAdmission

/-!
Phase E source-admission provenance conformance.

Successful transitions carry Lean equality proofs that the exact source
admission function accepted the complete declaration under the original
context, resource policy and environment. The genesis never trusts an
externally assembled environment; an untrusted candidate never writes the
chain.
-/

def c0TrustName (s : String) : PsKernelName := .str .anonymous s

def c0TrustDefinition
    (name : PsKernelName)
    (value : PsKernelExpr) : PsKernelDefinitionInfo := {
  base := {
    name := name
    levelParams := []
    type := .sort (.succ .zero)
  }
  value := value
  hints := .abbrevHint
  safety := .safe
}

def main : IO Unit := do
  let some genesis := psKernelC0TrustedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault
    | throw (IO.userError "trusted empty genesis could not be certified")
  if psKernelEnvironmentSize genesis.certified.raw.checker.context.environment != 0 ||
      !psKernelC0ArchitectureWorkValid genesis.certified.raw then
    throw (IO.userError "trusted genesis was not the canonical empty environment")
  let _genesisProof :
      PsKernelC0SourceEnvironmentHistory
        genesis.certified.raw.checker.context.environment :=
    genesis.history
  let _genesisStoreWF :
      psKernelC0StoreWF genesis.certified.raw.scratch.working :=
    psKernelC0CertifiedWorkStoreWF genesis.certified

  -- The default trusted WHNF now uses the source-proved direct fragment.
  -- Unlike a checker judgment, normalization of a Sort proves no term.
  let (head, afterDirect) ← match psKernelC0TrustedSourceWhnf
      4096 genesis (.sort .zero) with
    | .ok result => pure result
    | .error error =>
        throw (IO.userError ("trusted direct WHNF failed: " ++ error))
  if !psKernelExprEqual head (.sort .zero) then
    throw (IO.userError "trusted direct WHNF changed irreducible source head")
  let _directHistory :
      PsKernelC0SourceEnvironmentHistory
        afterDirect.certified.raw.checker.context.environment :=
    afterDirect.history
  if psKernelEnvironmentSize afterDirect.certified.raw.checker.context.environment != 0 then
    throw (IO.userError "trusted direct WHNF changed source empty genesis")
  match psKernelC0TrustedSourceWhnf 0 genesis (.sort .zero) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "trusted direct WHNF bypassed source fuel exhaustion")

  let nameOne := c0TrustName "TrustedSourceOne"
  let nameTwo := c0TrustName "TrustedSourceTwo"
  let first : PsKernelC0ArchitectureDeclaration :=
    .definition (c0TrustDefinition nameOne (.sort .zero))
  let second : PsKernelC0ArchitectureDeclaration :=
    .definition (c0TrustDefinition nameTwo (.const nameOne []))
  let admittedOnce ← match psKernelC0TrustedSourceAdmit
      4096 genesis first with
    | .ok next => pure next
    | .error reason =>
        throw (IO.userError ("trusted first admission failed: " ++ reason))
  -- Source checking, inference, WHNF and DefEq may change checker
  -- caches, but none may replace the *checked environment history*.
  let (inferred, afterInfer) ← match psKernelC0TrustedSourceInfer
      4096 admittedOnce (.sort .zero) with
    | .ok result => pure result
    | .error reason =>
        throw (IO.userError ("trusted source inference failed: " ++ reason))
  if !psKernelExprEqual inferred (.sort (.succ .zero)) then
    throw (IO.userError "trusted inference changed source type")
  let (checked, afterCheck) ← match psKernelC0TrustedSourceCheck
      4096 afterInfer (.sort .zero) with
    | .ok result => pure result
    | .error reason =>
        throw (IO.userError ("trusted full source check failed: " ++ reason))
  if !psKernelExprEqual checked inferred then
    throw (IO.userError "trusted full check disagreed with inference")
  let (same, afterDefEq) ← match psKernelC0TrustedSourceDefEq
      4096 afterCheck (.const nameOne []) (.sort .zero) with
    | .ok result => pure result
    | .error reason =>
        throw (IO.userError ("trusted source DefEq failed: " ++ reason))
  if !same then
    throw (IO.userError "trusted DefEq lost checked definition unfolding")
  let (normalized, afterWhnf) ← match psKernelC0TrustedSourceWhnf
      4096 afterDefEq (.const nameOne []) with
    | .ok result => pure result
    | .error reason =>
        throw (IO.userError ("trusted source WHNF failed: " ++ reason))
  if !psKernelExprEqual normalized (.sort .zero) then
    throw (IO.userError "trusted WHNF changed original kernel semantics")
  let _historyAfterQueries :
      PsKernelC0SourceEnvironmentHistory
        afterWhnf.certified.raw.checker.context.environment :=
    afterWhnf.history
  if psKernelEnvironmentSize afterWhnf.certified.raw.checker.context.environment != 1 then
    throw (IO.userError "checked query changed admitted environment")
  match psKernelC0TrustedSourceCheck 4096 afterWhnf
      (.app (.sort .zero) (.sort .zero)) with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "trusted full checker authorized an invalid application")

  let admittedTwice ← match psKernelC0TrustedSourceAdmit
      4096 afterWhnf second with
    | .ok next => pure next
    | .error reason =>
        throw (IO.userError ("trusted second admission failed: " ++ reason))
  let _chain :
      PsKernelC0SourceEnvironmentHistory
        admittedTwice.certified.raw.checker.context.environment :=
    admittedTwice.history
  if psKernelEnvironmentSize admittedTwice.certified.raw.checker.context.environment != 2 then
    throw (IO.userError "trusted source history changed admitted environment size")
  if psKernelEnvironmentSize genesis.certified.raw.checker.context.environment != 0 then
    throw (IO.userError "source admission mutated original immutable genesis")
  let (value, _) ← match psKernelC0CertifiedWorkWhnf
      4096 admittedTwice.certified (.const nameTwo []) with
    | .ok data => pure data
    | .error reason =>
        throw (IO.userError ("trusted source WHNF failed: " ++ reason))
  if !psKernelExprEqual value (.sort .zero) then
    throw (IO.userError "trusted source declarations did not unfold")

  -- Syntax staging is not admission. Its dependent environment-equality
  -- witness carries the verified source history across a changed scratch
  -- graph, without reinterpreting a numeric handle as a checked term.
  let some staged := psKernelC0TrustedSourceStage
      admittedTwice (.sort .zero)
    | throw (IO.userError "trusted verified syntax stage declined")
  let _stageHistory :
      PsKernelC0SourceEnvironmentHistory
        staged.certified.raw.checker.context.environment :=
    staged.history
  let (published, receipts) ← match
      psKernelC0TrustedSourceCommitChecked 4096 staged with
    | .ok result => pure result
    | .error reason =>
        throw (IO.userError ("trusted checked publication failed: " ++ reason))
  if !psKernelC0ReplayValidateStore published.store then
    throw (IO.userError "trusted publication returned a noncanonical store")
  match receipts with
  | [receipt] =>
      let _exactCheck := psKernelC0SourceCheckedRootExact receipt
      if !psKernelExprEqual receipt.root.expression (.sort .zero) ||
          !psKernelExprEqual receipt.checkedType (.sort (.succ .zero)) then
        throw (IO.userError "trusted staged source check changed term/type")
  | _ => throw (IO.userError "trusted publication lost selected roots")
  let some invalidStage := psKernelC0TrustedSourceStage
      staged (.bvar 0)
    | throw (IO.userError "trusted syntax stage preemptively checked bvar")
  match psKernelC0TrustedSourceCommitChecked 4096 invalidStage with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "verified environment history approved unbound root")
  if psKernelEnvironmentSize
      invalidStage.certified.raw.checker.context.environment != 2 then
    throw (IO.userError "staging changed the checked environment history")
  if psKernelEnvironmentSize admittedTwice.certified.raw.checker.context.environment != 2 then
    throw (IO.userError "rejected trusted publication mutated accepted declarations")

  -- The evidence itself must be the source admission's exact output,
  -- not a candidate expression or a hash-only environment stamp.
  let step ← match psKernelC0SourceAdmitWithProof 4096 genesis.certified first with
    | .ok next => pure next
    | .error reason =>
        throw (IO.userError ("source evidence generation failed: " ++ reason))
  let _evidence :
      psKernelC0ArchitectureAdmit step.fuel genesis.certified.raw step.request =
        .ok step.result.raw :=
    psKernelC0SourceAdmissionExact step
  if psKernelEnvironmentSize step.result.raw.checker.context.environment != 1 then
    throw (IO.userError "checked transition evidence has wrong resulting environment")

  -- Failed duplicate and ill-typed declarations cannot extend an existing
  -- admitted environment or produce another checked history constructor.
  match psKernelC0TrustedSourceAdmit 4096 admittedTwice first with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "trusted history accepted a duplicate declaration")
  let wrong : PsKernelC0ArchitectureDeclaration :=
    .definition (c0TrustDefinition (c0TrustName "TrustedBad") (.sort (.succ .zero)))
  match psKernelC0TrustedSourceAdmit 4096 admittedTwice wrong with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "trusted history accepted invalid definition type")
  if psKernelEnvironmentSize admittedTwice.certified.raw.checker.context.environment != 2 then
    throw (IO.userError "failed trusted admission mutated accepted source prefix")
  IO.println "C0_TRUSTED checked_empty_genesis_provenance=pass"
  IO.println "C0_TRUSTED chained_source_admissions_exact_receipts=pass"
  IO.println "C0_TRUSTED history_preserved_across_source_judgments=pass"
  IO.println "C0_TRUSTED staged_checked_root_publication_with_history=pass"
  IO.println "C0_TRUSTED immutable_rejection_and_checked_environment=pass"
