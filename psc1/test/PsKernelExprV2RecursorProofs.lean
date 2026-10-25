import Ps.KernelCore.API.Dag

/- Local source obligations for the explicit generated-owner bridge.
   These prove namespace refusal and exact stage guard/order equations.
   They do not prove complete inductive admission, global iota equivalence,
   or soundness of arbitrary caller-forged internal owner records. -/

namespace PsKernelExprV2RecursorProofs

abbrev PublicWhnf := PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
  Option (Except String (Prod PsKernelExprV2WhnfState Nat))

theorem check_uses_input_namespace
    (input work : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (root : Nat) (error : String)
    (invalid : psKernelExprV2DecodedRequire input root = Except.error error) :
    psKernelDagRunCommandWithSource input execution params safety arena work
      (PsKernelDagCommand.check root) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp [psKernelDagRunCommandWithSource, psKernelDagRequire, invalid]

theorem whnf_uses_input_namespace
    (input work : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (root : Nat) (error : String)
    (invalid : psKernelExprV2DecodedRequire input root = Except.error error) :
    psKernelDagRunCommandWithSource input execution params safety arena work
      (PsKernelDagCommand.whnf root) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp [psKernelDagRunCommandWithSource, psKernelDagRequire, invalid]

theorem defeq_left_uses_input_namespace_first
    (input work : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (left right : Nat) (error : String)
    (invalid : psKernelExprV2DecodedRequire input left = Except.error error) :
    psKernelDagRunCommandWithSource input execution params safety arena work
      (PsKernelDagCommand.isDefEq left right) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp [psKernelDagRunCommandWithSource, psKernelDagRequire, invalid]

theorem admission_uses_input_namespace
    (input work : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (request : PsKernelDagDeclarationRequest)
    (error : String)
    (invalid : psKernelDagDecodeDeclaration input request = Except.error error) :
    psKernelDagRunCommandWithSource input execution params safety arena work
      (PsKernelDagCommand.admit request) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp [psKernelDagRunCommandWithSource, invalid]

theorem generated_finish_synchronizes_append
    (source : PsKernelExpr) (state : PsKernelDagGeneratedState)
    (arena : PsKernelExprV2PagedArena) (root : Nat)
    (atEnd : root = state.built.size)
    (oneNew : arena.size = Nat.succ state.built.size) :
    psKernelDagGeneratedFinish source state (Except.ok (Prod.mk arena root)) =
      Except.ok (Prod.mk
        (PsKernelDagGeneratedState.mk arena
          (psKernelExprV2DecodedPush state.built source) state.declarations) root) := by
  simp [psKernelDagGeneratedFinish, atEnd, oneNew]

theorem generated_finish_refuses_wrong_root
    (source : PsKernelExpr) (state : PsKernelDagGeneratedState)
    (arena : PsKernelExprV2PagedArena) (root : Nat)
    (wrong : Nat.beq root state.built.size = false) :
    psKernelDagGeneratedFinish source state (Except.ok (Prod.mk arena root)) =
      Except.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH" := by
  simp [psKernelDagGeneratedFinish, wrong]

theorem no_owner_from_empty_batch
    (recursor : PsKernelRecursorInfo) (rule : PsKernelRecursorRule) :
    psKernelExprV2RecursorRuleOwner [] recursor rule = none := rfl

theorem insufficient_fields_precede_owner
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args fields : List Nat) (majorIndex : Nat)
    (rule : PsKernelRecursorRule)
    (short : psKernelNatGt rule.nFields (psKernelExprV2TransformNatLength fields) = true) :
    psKernelExprV2RecursorApplyRule state recursor levels args fields majorIndex rule =
      some (.ok (state,none)) := by
  simp [psKernelExprV2RecursorApplyRule, short]

theorem wrong_universe_arity_precedes_owner
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args fields : List Nat) (majorIndex : Nat)
    (rule : PsKernelRecursorRule)
    (enough : psKernelNatGt rule.nFields (psKernelExprV2TransformNatLength fields) = false)
    (wrong : Nat.beq (psKernelLevelListLength levels)
      (psKernelNameListLength recursor.base.levelParams) = false) :
    psKernelExprV2RecursorApplyRule state recursor levels args fields majorIndex rule =
      some (.ok (state,none)) := by
  simp [psKernelExprV2RecursorApplyRule, enough, wrong]

theorem missing_owner_never_claims_reduction
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args fields : List Nat) (majorIndex : Nat)
    (rule : PsKernelRecursorRule)
    (enough : psKernelNatGt rule.nFields (psKernelExprV2TransformNatLength fields) = false)
    (arity : Nat.beq (psKernelLevelListLength levels)
      (psKernelNameListLength recursor.base.levelParams) = true)
    (missing : psKernelExprV2RecursorRuleOwner state.declarations recursor rule = none) :
    psKernelExprV2RecursorApplyRule state recursor levels args fields majorIndex rule = none := by
  simp [psKernelExprV2RecursorApplyRule, enough, arity, missing]

theorem K_refuses_before_callbacks
    (whnf : PublicWhnf) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args : List Nat) (majorIndex major : Nat)
    (isK : recursor.k = true) :
    psKernelExprV2TryReduceNonKRecursorWith whnf context state recursor
      levels args majorIndex major = none := by
  simp [psKernelExprV2TryReduceNonKRecursorWith,
    psKernelExprV2TryReduceNonKRecursorOwnedWith,
    psKernelExprV2TryReduceNonKRecursorUsingOwnedWith,
    psKernelExprV2TryReduceRecursorMajorOwnedWith,
    psKernelExprV2LowerOptionalWhnfAttempt, isK]

theorem constructor_skips_major_callback
    (whnf : PublicWhnf) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2WhnfState) (recursor : PsKernelRecursorInfo)
    (levels : List PsKernelLevel) (args : List Nat) (majorIndex major : Nat)
    (notK : recursor.k = false)
    (isConstructorResult : psKernelExprV2RecursorIsConstructorApp context state.arena major = .ok true) :
    psKernelExprV2TryReduceNonKRecursorWith whnf context state recursor levels args majorIndex major =
      psKernelExprV2RecursorSelectRule state recursor levels args majorIndex major := by
  cases selected : psKernelExprV2RecursorSelectRule
      state recursor levels args majorIndex major with
  | none =>
      simp [psKernelExprV2TryReduceNonKRecursorWith,
        psKernelExprV2TryReduceNonKRecursorOwnedWith,
    psKernelExprV2TryReduceNonKRecursorUsingOwnedWith,
    psKernelExprV2TryReduceRecursorMajorOwnedWith,
        psKernelExprV2CheckContextEmpty, psKernelExprV2CheckStateFromWhnf,
        psKernelExprV2CheckStateEmpty, psKernelExprV2CheckStateWithWhnf,
        psKernelExprV2LiftOptionalWhnfAttempt, psKernelExprV2LowerOptionalWhnfAttempt,
        notK, isConstructorResult, selected]
  | some result =>
      cases result <;>
        simp [psKernelExprV2TryReduceNonKRecursorWith,
          psKernelExprV2TryReduceNonKRecursorOwnedWith,
    psKernelExprV2TryReduceNonKRecursorUsingOwnedWith,
    psKernelExprV2TryReduceRecursorMajorOwnedWith,
          psKernelExprV2CheckContextEmpty, psKernelExprV2CheckStateFromWhnf,
          psKernelExprV2CheckStateEmpty, psKernelExprV2CheckStateWithWhnf,
          psKernelExprV2LiftOptionalWhnfAttempt, psKernelExprV2LowerOptionalWhnfAttempt,
          notK, isConstructorResult, selected]

theorem nonconstructor_callback_error_precedes_normalization
    (context : PsKernelCheckerContext) (state : PsKernelExprV2WhnfState)
    (recursor : PsKernelRecursorInfo) (levels : List PsKernelLevel)
    (args : List Nat) (majorIndex major : Nat) (error : String)
    (notK : recursor.k = false)
    (notConstructor : psKernelExprV2RecursorIsConstructorApp context state.arena major = .ok false) :
    psKernelExprV2TryReduceNonKRecursorWith
      (fun _ _ _ => some (.error error)) context state recursor levels args majorIndex major =
      some (.error error) := by
  simp [psKernelExprV2TryReduceNonKRecursorWith,
    psKernelExprV2TryReduceNonKRecursorOwnedWith,
    psKernelExprV2TryReduceNonKRecursorUsingOwnedWith,
    psKernelExprV2TryReduceRecursorMajorOwnedWith,
    psKernelExprV2CheckContextEmpty, psKernelExprV2CheckStateFromWhnf,
    psKernelExprV2CheckStateEmpty, psKernelExprV2CheckStateWithWhnf,
    psKernelExprV2LiftScalarWhnf, psKernelExprV2LiftWhnfAttempt,
    psKernelExprV2LowerOptionalWhnfAttempt, notK, notConstructor]

theorem recursor_zero_before_syntax
    (localValue : PsKernelName -> Option Nat) (context : PsKernelCheckerContext)
    (state : PsKernelExprV2WhnfState) (root : Nat) (cheapProj : Bool) :
    psKernelExprV2TryReduceRecursorWithLocalValuesFuel 0 localValue context state root cheapProj =
      some (.error "kernel recursor budget exhausted") := rfl


/- T03a ownership equations. The old environment tail is arbitrary. -/
theorem generated_type_reuses_current_command_ref
    (info : PsKernelConstantInfo) (base : PsKernelConstantBase)
    (kind : PsKernelExprV2DeclarationRefKind)
    (inputRefs : List PsKernelExprV2DeclarationRef)
    (state : PsKernelDagGeneratedState) (owner : PsKernelExprV2DeclarationRef)
    (found : psKernelExprV2DeclarationRefFind inputRefs base.name = some owner)
    (compatible : psKernelExprV2DeclarationRefMatches owner info = true) :
    psKernelDagGeneratedInstallType info base kind inputRefs state = Except.ok state := by
  simp [psKernelDagGeneratedInstallType, found, compatible]

theorem generated_prefix_empty
    (previous : PsKernelEnvironment)
    (inputRefs : List PsKernelExprV2DeclarationRef)
    (state : PsKernelDagGeneratedState) :
    psKernelDagGeneratedInstallNewPrefix [] previous inputRefs state =
      Except.ok state := rfl

theorem generated_prefix_stops_at_old_name
    (info : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (previous : PsKernelEnvironment)
    (inputRefs : List PsKernelExprV2DeclarationRef)
    (state : PsKernelDagGeneratedState)
    (old : psKernelEnvironmentContains previous (psKernelConstantInfoName info) = true) :
    psKernelDagGeneratedInstallNewPrefix (info :: rest) previous inputRefs state =
      Except.ok state := by
  simp [psKernelDagGeneratedInstallNewPrefix, old]

theorem generated_prefix_first_import_error
    (info : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (previous : PsKernelEnvironment)
    (inputRefs : List PsKernelExprV2DeclarationRef)
    (state : PsKernelDagGeneratedState) (error : String)
    (fresh : psKernelEnvironmentContains previous (psKernelConstantInfoName info) = false)
    (failed : psKernelDagGeneratedInstallNewInfo info inputRefs state = Except.error error) :
    psKernelDagGeneratedInstallNewPrefix (info :: rest) previous inputRefs state =
      Except.error error := by
  simp [psKernelDagGeneratedInstallNewPrefix, fresh, failed]

theorem generated_prefix_threads_complete_state
    (info : PsKernelConstantInfo) (rest : List PsKernelConstantInfo)
    (previous : PsKernelEnvironment)
    (inputRefs : List PsKernelExprV2DeclarationRef)
    (state next : PsKernelDagGeneratedState)
    (fresh : psKernelEnvironmentContains previous (psKernelConstantInfoName info) = false)
    (installed : psKernelDagGeneratedInstallNewInfo info inputRefs state = Except.ok next) :
    psKernelDagGeneratedInstallNewPrefix (info :: rest) previous inputRefs state =
      psKernelDagGeneratedInstallNewPrefix rest previous inputRefs next := by
  rw [psKernelDagGeneratedInstallNewPrefix]
  simp [fresh, installed]

/- Batch dispatch now returns the exact checked work owner. Demand imports
   and continuation failures use that owner. Generated-prefix installation is
   retained explicitly at the fallback boundary, before any owned result. -/
theorem generated_import_error_prevents_batch_publication
    (command : PsKernelDagCommand) (rest : List PsKernelDagCommand)
    (input built : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (result : PsKernelDagOwnedCommandResult) (error : String)
    (admitted : psKernelDagRunOwnedCommandWithSource input execution
      params safety arena built command = Except.ok result)
    (failed : psKernelDagGeneratedDemandRange
      result.execution.session.environment built.size result.owner = Except.error error) :
    psKernelDagRunCommandsWithSource (command :: rest) input execution
      params safety arena built = Except.error (PsKernelError.internalError error) := by
  rw [psKernelDagRunCommandsWithSource]
  simp only [admitted, failed]

theorem generated_late_command_error_prevents_batch_publication
    (command : PsKernelDagCommand) (rest : List PsKernelDagCommand)
    (input built : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (result : PsKernelDagOwnedCommandResult)
    (ready : PsKernelDagGeneratedState) (error : PsKernelError)
    (admitted : psKernelDagRunOwnedCommandWithSource input execution
      params safety arena built command = Except.ok result)
    (completed : psKernelDagGeneratedDemandRange
      result.execution.session.environment built.size result.owner = Except.ok ready)
    (failed : psKernelDagRunCommandsWithSource rest input
      (PsKernelDagExecutionState.mk result.execution.session ready.declarations)
      params safety ready.arena ready.built = Except.error error) :
    psKernelDagRunCommandsWithSource (command :: rest) input execution
      params safety arena built = Except.error error := by
  rw [psKernelDagRunCommandsWithSource]
  simp only [admitted, completed, failed]

theorem generated_fallback_import_error_returns_no_owner
    (command : PsKernelDagCommand)
    (input built : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (result : Prod PsKernelDagReply PsKernelDagExecutionState)
    (error : String)
    (admitted : psKernelDagRunCommandWithSource input execution
      params safety arena built command = Except.ok result)
    (failed : psKernelDagGeneratedAfterCommandWithPrevious command
      execution.session.environment (Prod.snd result).session.environment
      (PsKernelDagGeneratedState.mk arena built (Prod.snd result).declarations) =
      Except.error error) :
    psKernelDagRunFallbackOwnedCommandWithSource input execution
      params safety arena built command = Except.error (PsKernelError.internalError error) := by
  simp only [psKernelDagRunFallbackOwnedCommandWithSource, admitted, failed]

theorem owned_command_error_prevents_batch_publication
    (command : PsKernelDagCommand) (rest : List PsKernelDagCommand)
    (input built : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (params : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (error : PsKernelError)
    (failed : psKernelDagRunOwnedCommandWithSource input execution
      params safety arena built command = Except.error error) :
    psKernelDagRunCommandsWithSource (command :: rest) input execution
      params safety arena built = Except.error error := by
  rw [psKernelDagRunCommandsWithSource]
  simp only [failed]

#print axioms generated_type_reuses_current_command_ref
#print axioms generated_prefix_empty
#print axioms generated_prefix_stops_at_old_name
#print axioms generated_prefix_first_import_error
#print axioms generated_prefix_threads_complete_state
#print axioms generated_import_error_prevents_batch_publication
#print axioms generated_late_command_error_prevents_batch_publication

#print axioms check_uses_input_namespace
#print axioms whnf_uses_input_namespace
#print axioms defeq_left_uses_input_namespace_first
#print axioms admission_uses_input_namespace
#print axioms generated_finish_synchronizes_append
#print axioms generated_finish_refuses_wrong_root
#print axioms no_owner_from_empty_batch
#print axioms insufficient_fields_precede_owner
#print axioms wrong_universe_arity_precedes_owner
#print axioms missing_owner_never_claims_reduction
#print axioms K_refuses_before_callbacks
#print axioms constructor_skips_major_callback
#print axioms nonconstructor_callback_error_precedes_normalization
#print axioms recursor_zero_before_syntax
#print axioms generated_fallback_import_error_returns_no_owner
#print axioms owned_command_error_prevents_batch_publication

end PsKernelExprV2RecursorProofs
