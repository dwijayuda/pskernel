import Ps.KernelCore.API.Dag

/- Local source equations for the initial-session bridge. These establish
   lookup authority, transport, failure propagation and ingress ordering only.
   They do not certify arbitrary low-level sessions or prove global soundness. -/
namespace PsKernelExprV2InitialOwnerProofs

theorem empty_entries (environment : PsKernelEnvironment)
    (state : PsKernelDagGeneratedState) :
    psKernelDagInitialInstallEntries [] environment state = .ok state := rfl

theorem empty_environment (state : PsKernelDagGeneratedState) :
    psKernelDagInitialInstall psKernelEnvironmentEmpty state = .ok state := rfl

theorem missing_live_lookup
    (historical : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (missing : psKernelEnvironmentFind environment (psKernelConstantInfoName historical) = none) :
    psKernelDagInitialInstallEntries (historical :: rest) environment state =
      psKernelDagInitialInstallEntries rest environment state := by
  simp only [psKernelDagInitialInstallEntries, missing]

theorem live_import_error
    (historical live : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState) (error : String)
    (found : psKernelEnvironmentFind environment (psKernelConstantInfoName historical) = some live)
    (failed : psKernelDagInitialInstallInfo live state = .error error) :
    psKernelDagInitialInstallEntries (historical :: rest) environment state = .error error := by
  simp only [psKernelDagInitialInstallEntries, found, failed]

theorem live_import_success
    (historical live : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (environment : PsKernelEnvironment) (state next : PsKernelDagGeneratedState)
    (found : psKernelEnvironmentFind environment (psKernelConstantInfoName historical) = some live)
    (installed : psKernelDagInitialInstallInfo live state = .ok next) :
    psKernelDagInitialInstallEntries (historical :: rest) environment state =
      psKernelDagInitialInstallEntries rest environment next := by
  simp only [psKernelDagInitialInstallEntries, found, installed]

theorem historical_payload_irrelevant
    (left right : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (sameName : psKernelConstantInfoName left = psKernelConstantInfoName right) :
    psKernelDagInitialInstallEntries (left :: rest) environment state =
      psKernelDagInitialInstallEntries (right :: rest) environment state := by
  simp only [psKernelDagInitialInstallEntries, sameName]

theorem live_lookup_extensional
    (entries : List PsKernelConstantInfo) (left right : PsKernelEnvironment)
    (sameLookup : ∀ name, psKernelEnvironmentFind left name = psKernelEnvironmentFind right name)
    (state : PsKernelDagGeneratedState) :
    psKernelDagInitialInstallEntries entries left state =
      psKernelDagInitialInstallEntries entries right state := by
  induction entries generalizing state with
  | nil => rfl
  | cons first rest ih =>
      simp only [psKernelDagInitialInstallEntries]
      rw [sameLookup (psKernelConstantInfoName first)]
      cases found : psKernelEnvironmentFind right (psKernelConstantInfoName first) with
      | none =>
          simp only [found]
          exact ih state
      | some live =>
          simp only [found]
          cases installed : psKernelDagInitialInstallInfo live state with
          | error error => rfl
          | ok next => exact ih next

theorem shared_index_same_lookup
    (left right : PsKernelEnvironment) (name : PsKernelName)
    (sameIndex : left.index = right.index) :
    psKernelEnvironmentFind left name = psKernelEnvironmentFind right name := by
  simp only [psKernelEnvironmentFind, sameIndex]

theorem shared_index_same_entries
    (entries : List PsKernelConstantInfo) (left right : PsKernelEnvironment)
    (sameIndex : left.index = right.index) (state : PsKernelDagGeneratedState) :
    psKernelDagInitialInstallEntries entries left state =
      psKernelDagInitialInstallEntries entries right state := by
  apply live_lookup_extensional
  intro name
  exact shared_index_same_lookup left right name sameIndex

theorem theorem_proof_is_not_imported
    (base : PsKernelConstantBase) (left right : PsKernelExpr)
    (state : PsKernelDagGeneratedState) :
    psKernelDagInitialInstallInfo (.thmInfo (PsKernelTheoremInfo.mk base left)) state =
      psKernelDagInitialInstallInfo (.thmInfo (PsKernelTheoremInfo.mk base right)) state := rfl

theorem opaque_value_is_not_imported
    (base : PsKernelConstantBase) (left right : PsKernelExpr) (isUnsafe : Bool)
    (state : PsKernelDagGeneratedState) :
    psKernelDagInitialInstallInfo (.opaqueInfo (PsKernelOpaqueInfo.mk base left isUnsafe)) state =
      psKernelDagInitialInstallInfo (.opaqueInfo (PsKernelOpaqueInfo.mk base right isUnsafe)) state := rfl

theorem quotient_has_no_owner
    (value : PsKernelQuotInfo) (state : PsKernelDagGeneratedState) :
    psKernelDagInitialInstallInfo (.quotInfo value) state = .ok state := rfl

theorem definition_type_failure_precedes_value
    (value : PsKernelDefinitionInfo) (state : PsKernelDagGeneratedState) (error : String)
    (failed : psKernelDagGeneratedImport value.base.type state = .error error) :
    psKernelDagInitialInstallDefinition value state = .error error := by
  simp only [psKernelDagInitialInstallDefinition, failed]

theorem definition_value_failure_propagates
    (value : PsKernelDefinitionInfo) (state typed : PsKernelDagGeneratedState)
    (typeId : Nat) (error : String)
    (typeResult : psKernelDagGeneratedImport value.base.type state = .ok (typed,typeId))
    (bodyResult : psKernelDagGeneratedImport value.value typed = .error error) :
    psKernelDagInitialInstallDefinition value state = .error error := by
  simp only [psKernelDagInitialInstallDefinition, typeResult, bodyResult]

theorem definition_owner_uses_returned_state
    (value : PsKernelDefinitionInfo) (state typed finalState : PsKernelDagGeneratedState)
    (typeId bodyId : Nat)
    (typeResult : psKernelDagGeneratedImport value.base.type state = .ok (typed,typeId))
    (bodyResult : psKernelDagGeneratedImport value.value typed = .ok (finalState,bodyId)) :
    psKernelDagInitialInstallDefinition value state =
      .ok (PsKernelDagGeneratedState.mk finalState.arena finalState.built
        (PsKernelExprV2DeclarationRef.mk value.base.name value.base.levelParams typeId
          (some bodyId) .definitionDecl :: finalState.declarations)) := by
  simp only [psKernelDagInitialInstallDefinition, typeResult, bodyResult]

theorem public_preflight_precedes_import
    (session : PsKernelKernelSession) (levels : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (source : PsKernelExprV2PagedArena)
    (commands : List PsKernelDagCommand) (error : PsKernelError)
    (failed : psKernelKernelSessionPreflight session = .error error) :
    psKernelV1RunDag session levels safety source commands = .error error := by
  simp only [psKernelV1RunDag, failed]

theorem public_validation_precedes_import
    (session : PsKernelKernelSession) (levels : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (source : PsKernelExprV2PagedArena)
    (commands : List PsKernelDagCommand) (error : String)
    (preflight : psKernelKernelSessionPreflight session = .ok ())
    (failed : psKernelExprV2PagedValidate source = .error error) :
    psKernelV1RunDag session levels safety source commands = .error (.rejectedInvalid error) := by
  simp only [psKernelV1RunDag, preflight, failed]

theorem public_empty_batch_does_not_import
    (session : PsKernelKernelSession) (levels : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (source canonical : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (preflight : psKernelKernelSessionPreflight session = .ok ())
    (validated : psKernelExprV2PagedValidate source = .ok canonical)
    (decoded : psKernelExprV2DecodeCanonicalFuel
      (Nat.succ canonical.size) canonical psKernelExprV2DecodedEmpty 0 = .ok built) :
    psKernelV1RunDag session levels safety source [] =
      .ok (PsKernelDagBatchResult.mk session []) := by
  simp only [psKernelV1RunDag, preflight, validated, decoded]

theorem public_import_failure_is_atomic
    (session : PsKernelKernelSession) (levels : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (source canonical : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded) (command : PsKernelDagCommand)
    (rest : List PsKernelDagCommand) (error : String)
    (preflight : psKernelKernelSessionPreflight session = .ok ())
    (validated : psKernelExprV2PagedValidate source = .ok canonical)
    (decoded : psKernelExprV2DecodeCanonicalFuel
      (Nat.succ canonical.size) canonical psKernelExprV2DecodedEmpty 0 = .ok built)
    (failed : psKernelDagInitialInstall (psKernelKernelSessionEnvironment session)
      (PsKernelDagGeneratedState.mk canonical built []) = .error error) :
    psKernelV1RunDag session levels safety source (command :: rest) =
      .error (.internalError error) := by
  simp only [psKernelV1RunDag, preflight, validated, decoded, failed]

theorem public_installed_owner_keeps_original_input
    (session : PsKernelKernelSession) (levels : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (source canonical : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded) (command : PsKernelDagCommand)
    (rest : List PsKernelDagCommand) (installed : PsKernelDagGeneratedState)
    (preflight : psKernelKernelSessionPreflight session = .ok ())
    (validated : psKernelExprV2PagedValidate source = .ok canonical)
    (decoded : psKernelExprV2DecodeCanonicalFuel
      (Nat.succ canonical.size) canonical psKernelExprV2DecodedEmpty 0 = .ok built)
    (ready : psKernelDagInitialInstall (psKernelKernelSessionEnvironment session)
      (PsKernelDagGeneratedState.mk canonical built []) = .ok installed) :
    psKernelV1RunDag session levels safety source (command :: rest) =
      psKernelDagRunCommandsWithSource (command :: rest) built
        (PsKernelDagExecutionState.mk session installed.declarations)
        levels safety installed.arena installed.built := by
  simp only [psKernelV1RunDag, preflight, validated, decoded, ready]

end PsKernelExprV2InitialOwnerProofs

#print axioms PsKernelExprV2InitialOwnerProofs.empty_entries
#print axioms PsKernelExprV2InitialOwnerProofs.empty_environment
#print axioms PsKernelExprV2InitialOwnerProofs.missing_live_lookup
#print axioms PsKernelExprV2InitialOwnerProofs.live_import_error
#print axioms PsKernelExprV2InitialOwnerProofs.live_import_success
#print axioms PsKernelExprV2InitialOwnerProofs.historical_payload_irrelevant
#print axioms PsKernelExprV2InitialOwnerProofs.live_lookup_extensional
#print axioms PsKernelExprV2InitialOwnerProofs.shared_index_same_lookup
#print axioms PsKernelExprV2InitialOwnerProofs.shared_index_same_entries
#print axioms PsKernelExprV2InitialOwnerProofs.theorem_proof_is_not_imported
#print axioms PsKernelExprV2InitialOwnerProofs.opaque_value_is_not_imported
#print axioms PsKernelExprV2InitialOwnerProofs.quotient_has_no_owner
#print axioms PsKernelExprV2InitialOwnerProofs.definition_type_failure_precedes_value
#print axioms PsKernelExprV2InitialOwnerProofs.definition_value_failure_propagates
#print axioms PsKernelExprV2InitialOwnerProofs.definition_owner_uses_returned_state
#print axioms PsKernelExprV2InitialOwnerProofs.public_preflight_precedes_import
#print axioms PsKernelExprV2InitialOwnerProofs.public_validation_precedes_import
#print axioms PsKernelExprV2InitialOwnerProofs.public_empty_batch_does_not_import
#print axioms PsKernelExprV2InitialOwnerProofs.public_import_failure_is_atomic
#print axioms PsKernelExprV2InitialOwnerProofs.public_installed_owner_keeps_original_input
