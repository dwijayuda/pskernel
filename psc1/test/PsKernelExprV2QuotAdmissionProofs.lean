import Ps.KernelCore.API.Dag

/- Local equations for guard order, complete owner threading and atomic
   publication. These are not a global soundness or builder-equivalence proof.
   The fixed header builder is additionally compared with all four original
   builders by the native and detached generated regression suites. -/
namespace PsKernelExprV2QuotAdmissionProofs

theorem initialized_preserves_owner
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (initialized : environment.quotInitialized = true) :
    psKernelDagTryAddQuotOwned environment state =
      some (Except.ok (environment,state)) := by
  simp [psKernelDagTryAddQuotOwned, initialized]

theorem missing_Eq_precedes_owners
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (missing : psKernelEnvironmentFind environment psKernelEqName = none) :
    psKernelDagQuotCheckEqOwned environment state =
      some (Except.error "failed to initialize quot module, environment does not have Eq type") := by
  simp [psKernelDagQuotCheckEqOwned, missing]

theorem wrong_Eq_kind_precedes_owners
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (info : PsKernelAxiomInfo)
    (found : psKernelEnvironmentFind environment psKernelEqName = some (.axiomInfo info)) :
    psKernelDagQuotCheckEqOwned environment state =
      some (Except.error "failed to initialize quot module, environment does not have Eq type") := by
  simp [psKernelDagQuotCheckEqOwned, found]

theorem Eq_universe_guard_precedes_constructor_guard
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (info : PsKernelInductiveInfo)
    (found : psKernelEnvironmentFind environment psKernelEqName = some (.inductInfo info))
    (levels : info.base.levelParams = []) :
    psKernelDagQuotCheckEqOwned environment state =
      some (Except.error "failed to initialize quot module, unexpected number of universe params at Eq type") := by
  simp [psKernelDagQuotCheckEqOwned, found, levels]

theorem Eq_constructor_guard_precedes_owned_type
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (info : PsKernelInductiveInfo) (u : PsKernelName)
    (found : psKernelEnvironmentFind environment psKernelEqName = some (.inductInfo info))
    (levels : info.base.levelParams = [u]) (ctors : info.ctors = []) :
    psKernelDagQuotCheckEqOwned environment state =
      some (Except.error "failed to initialize quot module, unexpected number of constructors for Eq type") := by
  simp [psKernelDagQuotCheckEqOwned, found, levels, ctors]

theorem missing_owned_Eq_type_declines
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (info : PsKernelInductiveInfo) (u ctor : PsKernelName)
    (found : psKernelEnvironmentFind environment psKernelEqName = some (.inductInfo info))
    (levels : info.base.levelParams = [u]) (ctors : info.ctors = [ctor])
    (missing : psKernelDagQuotOwnedType (.inductInfo info) state = none) :
    psKernelDagQuotCheckEqOwned environment state = none := by
  simp [psKernelDagQuotCheckEqOwned, found, levels, ctors, missing]

theorem Eq_syntax_failure_precedes_refl_lookup
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (info : PsKernelInductiveInfo) (u ctor : PsKernelName) (root : Nat)
    (found : psKernelEnvironmentFind environment psKernelEqName = some (.inductInfo info))
    (levels : info.base.levelParams = [u]) (ctors : info.ctors = [ctor])
    (owned : psKernelDagQuotOwnedType (.inductInfo info) state = some root)
    (invalid : psKernelDagQuotCheckEqType state.arena root u = some false) :
    psKernelDagQuotCheckEqOwned environment state =
      some (Except.error "failed to initialize quot module, Eq has an unexpected type") := by
  simp [psKernelDagQuotCheckEqOwned, found, levels, ctors, owned, invalid]

theorem missing_refl_precedes_owned_type
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (name : PsKernelName)
    (missing : psKernelEnvironmentFind environment name = none) :
    psKernelDagQuotCheckReflOwned environment state name =
      some (Except.error "failed to initialize quot module, missing Eq constructor") := by
  simp [psKernelDagQuotCheckReflOwned, missing]

theorem refl_universe_guard_precedes_owned_type
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (name : PsKernelName) (info : PsKernelConstantInfo)
    (found : psKernelEnvironmentFind environment name = some info)
    (levels : psKernelConstantInfoLevelParams info = []) :
    psKernelDagQuotCheckReflOwned environment state name =
      some (Except.error "failed to initialize quot module, unexpected universe params at Eq constructor") := by
  simp [psKernelDagQuotCheckReflOwned, found, levels]

theorem refl_type_success_does_not_add_a_kind_guard
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (name u : PsKernelName) (info : PsKernelConstantInfo) (root : Nat)
    (found : psKernelEnvironmentFind environment name = some info)
    (levels : psKernelConstantInfoLevelParams info = [u])
    (owned : psKernelDagQuotOwnedType info state = some root)
    (valid : psKernelDagQuotCheckReflType state.arena root u = some true) :
    psKernelDagQuotCheckReflOwned environment state name = some (Except.ok ()) := by
  simp [psKernelDagQuotCheckReflOwned, found, levels, owned, valid]

theorem refl_syntax_failure_retains_original_error
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (name u : PsKernelName) (info : PsKernelConstantInfo) (root : Nat)
    (found : psKernelEnvironmentFind environment name = some info)
    (levels : psKernelConstantInfoLevelParams info = [u])
    (owned : psKernelDagQuotOwnedType info state = some root)
    (invalid : psKernelDagQuotCheckReflType state.arena root u = some false) :
    psKernelDagQuotCheckReflOwned environment state name =
      some (Except.error "failed to initialize quot module, unexpected type for Eq constructor") := by
  simp [psKernelDagQuotCheckReflOwned, found, levels, owned, invalid]

theorem Eq_failure_precedes_reserved_names
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (error : String) (initializing : environment.quotInitialized = false)
    (failed : psKernelDagQuotCheckEqOwned environment state = some (Except.error error)) :
    psKernelDagTryAddQuotOwned environment state = some (Except.error error) := by
  simp [psKernelDagTryAddQuotOwned, initializing, failed]

theorem reserved_names_precede_construction
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (error : String) (initializing : environment.quotInitialized = false)
    (checked : psKernelDagQuotCheckEqOwned environment state = some (Except.ok ()))
    (failed : psKernelCheckQuotReservedNames environment
      [psKernelQuotName,psKernelQuotMkName,psKernelQuotLiftName,psKernelQuotIndName] =
      Except.error error) :
    psKernelDagTryAddQuotOwned environment state = some (Except.error error) := by
  simp [psKernelDagTryAddQuotOwned, initializing, checked, failed]

theorem incoherent_owner_table_declines_after_guards
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (initializing : environment.quotInitialized = false)
    (checked : psKernelDagQuotCheckEqOwned environment state = some (Except.ok ()))
    (reserved : psKernelCheckQuotReservedNames environment
      [psKernelQuotName,psKernelQuotMkName,psKernelQuotLiftName,psKernelQuotIndName] =
      Except.ok ())
    (mismatch : Nat.beq state.arena.size state.built.size = false) :
    psKernelDagTryAddQuotOwned environment state = none := by
  simp [psKernelDagTryAddQuotOwned, initializing, checked, reserved, mismatch]

theorem empty_header_program_preserves_arena (arena : PsKernelExprV2PagedArena) :
    psKernelDagQuotAppendHeaderNodes [] arena = Except.ok arena := rfl

theorem fixed_header_program_has_55_nodes
    (base : Nat) (u v : PsKernelName) :
    (psKernelDagQuotHeaderNodes base u v).length = 55 := rfl

theorem missing_publication_type_returns_before_environment_extension
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (headers : PsKernelDagQuotHeaders) (built : PsKernelExprV2Decoded)
    (u v : PsKernelName) (error : String)
    (missing : psKernelExprV2DecodedRequire built headers.quotType = Except.error error) :
    psKernelDagQuotPublishTypes environment state headers built u v = Except.error error := by
  simp [psKernelDagQuotPublishTypes, missing]

theorem owned_admission_preflight_precedes_attempt
    (session : PsKernelKernelSession) (arena : PsKernelExprV2PagedArena)
    (refs : List PsKernelExprV2DeclarationRef) (source : PsKernelDagDeclarationRequest)
    (declaration : PsKernelDeclarationRequest) (owner : Option PsKernelDagGeneratedState)
    (error : PsKernelError)
    (failed : psKernelKernelSessionPreflight session = Except.error error) :
    psKernelDagAdmitDeclarationWithOwner session arena refs source declaration owner =
      Except.error error := by
  simp [psKernelDagAdmitDeclarationWithOwner, failed]

theorem declaration_limit_returns_no_completed_admission
    (session : PsKernelKernelSession) (declaration : PsKernelDeclarationRequest)
    (environment : PsKernelEnvironment)
    (blocked : psKernelResourceAllowsSize session.resources
      (psKernelEnvironmentSize environment) = false) :
    psKernelDagFinishAdmission session declaration environment =
      Except.error (.resourceExhausted .declarationLimit "declaration limit exceeded") := by
  simp [psKernelDagFinishAdmission, blocked]

theorem owned_command_keeps_original_input_namespace
    (input built : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (request : PsKernelDagDeclarationRequest)
    (error : String)
    (failed : psKernelDagDecodeDeclaration input request = Except.error error) :
    psKernelDagRunCommandOwnedWithSource input execution params safety arena built (.admit request) =
      Except.error (.rejectedInvalid error) := by
  simp [psKernelDagRunCommandOwnedWithSource, psKernelDagRunCommandWithOwner, failed]

private theorem owned_batch_is_shared_loop
    (commands : List PsKernelDagCommand) (input built : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState) (params : List PsKernelName)
    (safety : PsKernelDefinitionSafety) (arena : PsKernelExprV2PagedArena) :
    psKernelDagRunCommandsOwnedWithSource commands input execution params safety arena built =
      psKernelDagRunCommandsUsing commands psKernelDagRunCommandOwnedWithSource
        input execution params safety arena built := by
  cases commands <;> rfl

theorem owned_batch_first_error_prevents_publication
    (command : PsKernelDagCommand) (rest : List PsKernelDagCommand)
    (input built : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (error : PsKernelError)
    (failed : psKernelDagRunCommandOwnedWithSource input execution params safety arena built command =
      Except.error error) :
    psKernelDagRunCommandsOwnedWithSource (command :: rest) input execution params safety arena built =
      Except.error error := by
  rw [owned_batch_is_shared_loop, psKernelDagRunCommandsUsing]
  simp [failed]

theorem owned_batch_import_error_prevents_publication
    (command : PsKernelDagCommand) (rest : List PsKernelDagCommand)
    (input built : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (result : PsKernelDagCommandWithOwnerResult)
    (owner : PsKernelDagGeneratedState) (error : String)
    (admitted : psKernelDagRunCommandOwnedWithSource input execution params safety arena built command =
      Except.ok result)
    (retained : result.owner = some owner)
    (failed : psKernelDagGeneratedAfterCommandWithPrevious command
      execution.session.environment result.execution.session.environment owner = Except.error error) :
    psKernelDagRunCommandsOwnedWithSource (command :: rest) input execution params safety arena built =
      Except.error (.internalError error) := by
  rw [owned_batch_is_shared_loop, psKernelDagRunCommandsUsing]
  simp [admitted, retained, failed]

theorem owned_batch_late_error_preserves_complete_owner_until_failure
    (command : PsKernelDagCommand) (rest : List PsKernelDagCommand)
    (input built : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (result : PsKernelDagCommandWithOwnerResult)
    (owner installed : PsKernelDagGeneratedState) (error : PsKernelError)
    (admitted : psKernelDagRunCommandOwnedWithSource input execution params safety arena built command =
      Except.ok result)
    (retained : result.owner = some owner)
    (imported : psKernelDagGeneratedAfterCommandWithPrevious command
      execution.session.environment result.execution.session.environment owner = Except.ok installed)
    (failed : psKernelDagRunCommandsOwnedWithSource rest input
      (.mk result.execution.session installed.declarations) params safety installed.arena installed.built =
      Except.error error) :
    psKernelDagRunCommandsOwnedWithSource (command :: rest) input execution params safety arena built =
      Except.error error := by
  have failedShared :
      psKernelDagRunCommandsUsing rest psKernelDagRunCommandOwnedWithSource input
        (.mk result.execution.session installed.declarations) params safety installed.arena installed.built =
        Except.error error := by
    simpa only [owned_batch_is_shared_loop] using failed
  rw [owned_batch_is_shared_loop, psKernelDagRunCommandsUsing]
  simp [admitted, retained, imported, failedShared]

theorem production_batch_selects_owned_command
    (commands : List PsKernelDagCommand) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (input : PsKernelExprV2Decoded) :
    psKernelDagRunCommands commands execution params safety arena input =
      psKernelDagRunCommandsOwnedWithSource commands input execution params safety arena input := rfl

#print axioms initialized_preserves_owner
#print axioms missing_Eq_precedes_owners
#print axioms wrong_Eq_kind_precedes_owners
#print axioms Eq_universe_guard_precedes_constructor_guard
#print axioms Eq_constructor_guard_precedes_owned_type
#print axioms missing_owned_Eq_type_declines
#print axioms Eq_syntax_failure_precedes_refl_lookup
#print axioms missing_refl_precedes_owned_type
#print axioms refl_universe_guard_precedes_owned_type
#print axioms refl_type_success_does_not_add_a_kind_guard
#print axioms refl_syntax_failure_retains_original_error
#print axioms Eq_failure_precedes_reserved_names
#print axioms reserved_names_precede_construction
#print axioms incoherent_owner_table_declines_after_guards
#print axioms empty_header_program_preserves_arena
#print axioms fixed_header_program_has_55_nodes
#print axioms missing_publication_type_returns_before_environment_extension
#print axioms owned_admission_preflight_precedes_attempt
#print axioms declaration_limit_returns_no_completed_admission
#print axioms owned_command_keeps_original_input_namespace
#print axioms owned_batch_first_error_prevents_publication
#print axioms owned_batch_import_error_prevents_publication
#print axioms owned_batch_late_error_preserves_complete_owner_until_failure
#print axioms production_batch_selects_owned_command

end PsKernelExprV2QuotAdmissionProofs
