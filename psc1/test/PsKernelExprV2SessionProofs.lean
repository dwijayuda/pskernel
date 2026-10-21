import Ps.KernelCore.API.Dag

/- Local source obligations for the demand-scoped session-owner adapter.
   These establish selection, bounded import, error propagation and namespace
   equations. They do not prove global checker soundness, complete dependency
   coverage, or authenticity of arbitrary caller-forged internal records. -/

namespace PsKernelExprV2SessionProofs

theorem collect_zero_preserves_pending
    (built : PsKernelExprV2Decoded) (index : Nat)
    (pending : List PsKernelName) :
    psKernelDagGeneratedCollectDemands 0 built index pending =
      Except.ok pending := rfl

theorem collect_invalid_node_stops
    (remaining : Nat) (built : PsKernelExprV2Decoded) (index : Nat)
    (pending : List PsKernelName) (error : String)
    (invalid : psKernelExprV2DecodedRequire built index = Except.error error) :
    psKernelDagGeneratedCollectDemands
      (Nat.succ remaining) built index pending = Except.error error := by
  rw [psKernelDagGeneratedCollectDemands]
  simp only [invalid]

theorem next_demand_skips_owned_name
    (name : PsKernelName) (rest : List PsKernelName)
    (environment : PsKernelEnvironment)
    (declarations : List PsKernelExprV2DeclarationRef)
    (owner : PsKernelExprV2DeclarationRef)
    (owned : psKernelExprV2DeclarationRefFind declarations name = some owner) :
    psKernelDagGeneratedNextDemand (name :: rest) environment declarations =
      psKernelDagGeneratedNextDemand rest environment declarations := by
  rw [psKernelDagGeneratedNextDemand]
  simp only [owned]

theorem next_demand_skips_missing_name
    (name : PsKernelName) (rest : List PsKernelName)
    (environment : PsKernelEnvironment)
    (declarations : List PsKernelExprV2DeclarationRef)
    (unowned : psKernelExprV2DeclarationRefFind declarations name = none)
    (missing : psKernelEnvironmentFind environment name = none) :
    psKernelDagGeneratedNextDemand (name :: rest) environment declarations =
      psKernelDagGeneratedNextDemand rest environment declarations := by
  rw [psKernelDagGeneratedNextDemand]
  simp only [unowned, missing]

theorem next_demand_returns_exact_live_info
    (name : PsKernelName) (rest : List PsKernelName)
    (environment : PsKernelEnvironment)
    (declarations : List PsKernelExprV2DeclarationRef)
    (info : PsKernelConstantInfo)
    (unowned : psKernelExprV2DeclarationRefFind declarations name = none)
    (found : psKernelEnvironmentFind environment name = some info) :
    psKernelDagGeneratedNextDemand (name :: rest) environment declarations =
      some (Prod.mk info rest) := by
  rw [psKernelDagGeneratedNextDemand]
  simp only [unowned, found]

theorem complete_no_demand_preserves_state
    (remaining : List PsKernelConstantInfo)
    (environment : PsKernelEnvironment) (pending : List PsKernelName)
    (state : PsKernelDagGeneratedState)
    (exhausted :
      psKernelDagGeneratedNextDemand pending environment state.declarations = none) :
    psKernelDagGeneratedCompleteDemands remaining environment pending state =
      Except.ok state := by
  cases remaining <;>
    simp only [psKernelDagGeneratedCompleteDemands, exhausted]

theorem complete_zero_bound_refuses_needed_import
    (environment : PsKernelEnvironment)
    (pending rest : List PsKernelName)
    (state : PsKernelDagGeneratedState) (info : PsKernelConstantInfo)
    (selected :
      psKernelDagGeneratedNextDemand pending environment state.declarations =
        some (Prod.mk info rest)) :
    psKernelDagGeneratedCompleteDemands [] environment pending state =
      Except.error "PSKERNEL_V2_SESSION_OWNER_BOUND" := by
  rw [psKernelDagGeneratedCompleteDemands]
  simp only [selected]

theorem complete_import_error_returns_no_state
    (authority : PsKernelConstantInfo) (remaining : List PsKernelConstantInfo)
    (environment : PsKernelEnvironment)
    (pending rest : List PsKernelName)
    (state : PsKernelDagGeneratedState) (info : PsKernelConstantInfo)
    (error : String)
    (selected :
      psKernelDagGeneratedNextDemand pending environment state.declarations =
        some (Prod.mk info rest))
    (failed :
      psKernelDagGeneratedInstallSessionInfo info state = Except.error error) :
    psKernelDagGeneratedCompleteDemands
      (authority :: remaining) environment pending state = Except.error error := by
  rw [psKernelDagGeneratedCompleteDemands]
  simp only [selected, failed]

theorem complete_success_consumes_one_authority_cons
    (authority : PsKernelConstantInfo) (remaining : List PsKernelConstantInfo)
    (environment : PsKernelEnvironment)
    (pending rest demands : List PsKernelName)
    (state next : PsKernelDagGeneratedState) (info : PsKernelConstantInfo)
    (selected :
      psKernelDagGeneratedNextDemand pending environment state.declarations =
        some (Prod.mk info rest))
    (installed :
      psKernelDagGeneratedInstallSessionInfo info state = Except.ok next)
    (collected :
      psKernelDagGeneratedCollectDemands
        (Nat.sub next.built.size state.built.size)
        next.built state.built.size
        (psKernelDagGeneratedInfoDemands info rest) = Except.ok demands) :
    psKernelDagGeneratedCompleteDemands
      (authority :: remaining) environment pending state =
      psKernelDagGeneratedCompleteDemands remaining environment demands next := by
  rw [psKernelDagGeneratedCompleteDemands]
  simp only [selected, installed, collected]

theorem from_session_starts_with_private_empty_owners
    (session : PsKernelKernelSession)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded) :
    psKernelDagGeneratedFromSession session arena built =
      psKernelDagGeneratedDemandRange session.environment 0
        (PsKernelDagGeneratedState.mk arena built []) := rfl

theorem session_import_error_prevents_command_publication
    (session : PsKernelKernelSession)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (commands : List PsKernelDagCommand) (error : String)
    (failed :
      psKernelDagGeneratedFromSession session arena built = Except.error error) :
    psKernelDagRunSessionCommands session params safety arena built commands =
      Except.error (PsKernelError.internalError error) := by
  simp only [psKernelDagRunSessionCommands, failed]

theorem session_import_preserves_original_input_namespace
    (session : PsKernelKernelSession)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (commands : List PsKernelDagCommand)
    (installed : PsKernelDagGeneratedState)
    (imported :
      psKernelDagGeneratedFromSession session arena built = Except.ok installed) :
    psKernelDagRunSessionCommands session params safety arena built commands =
      psKernelDagRunCommandsWithSource commands built
        (PsKernelDagExecutionState.mk session installed.declarations)
        params safety installed.arena installed.built := by
  simp only [psKernelDagRunSessionCommands, imported]

theorem post_command_import_error_prevents_publication
    (command : PsKernelDagCommand) (rest : List PsKernelDagCommand)
    (input built : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (result : Prod PsKernelDagReply PsKernelDagExecutionState)
    (installed : PsKernelDagGeneratedState) (error : String)
    (admitted : psKernelDagRunCommandWithSource input execution
      params safety arena built command = Except.ok result)
    (imported : psKernelDagGeneratedAfterCommandWithPrevious command
      execution.session.environment (Prod.snd result).session.environment
      (PsKernelDagGeneratedState.mk arena built (Prod.snd result).declarations) =
      Except.ok installed)
    (failed : psKernelDagGeneratedDemandRange
      (Prod.snd result).session.environment built.size installed = Except.error error) :
    psKernelDagRunCommandsWithSource (command :: rest) input execution
      params safety arena built = Except.error (PsKernelError.internalError error) := by
  rw [psKernelDagRunCommandsWithSource]
  simp only [admitted, imported, failed]

theorem append_demands_preserves_order
    (names pending : List PsKernelName) :
    psKernelDagGeneratedAppendDemands names pending = names ++ pending := by
  induction names with
  | nil => rfl
  | cons name rest ih =>
      change name :: psKernelDagGeneratedAppendDemands rest pending =
        name :: (rest ++ pending)
      rw [ih]

end PsKernelExprV2SessionProofs

#print axioms PsKernelExprV2SessionProofs.collect_zero_preserves_pending
#print axioms PsKernelExprV2SessionProofs.collect_invalid_node_stops
#print axioms PsKernelExprV2SessionProofs.next_demand_skips_owned_name
#print axioms PsKernelExprV2SessionProofs.next_demand_skips_missing_name
#print axioms PsKernelExprV2SessionProofs.next_demand_returns_exact_live_info
#print axioms PsKernelExprV2SessionProofs.complete_no_demand_preserves_state
#print axioms PsKernelExprV2SessionProofs.complete_zero_bound_refuses_needed_import
#print axioms PsKernelExprV2SessionProofs.complete_import_error_returns_no_state
#print axioms PsKernelExprV2SessionProofs.complete_success_consumes_one_authority_cons
#print axioms PsKernelExprV2SessionProofs.from_session_starts_with_private_empty_owners
#print axioms PsKernelExprV2SessionProofs.session_import_error_prevents_command_publication
#print axioms PsKernelExprV2SessionProofs.session_import_preserves_original_input_namespace

#print axioms PsKernelExprV2SessionProofs.post_command_import_error_prevents_publication

#print axioms PsKernelExprV2SessionProofs.append_demands_preserves_order
