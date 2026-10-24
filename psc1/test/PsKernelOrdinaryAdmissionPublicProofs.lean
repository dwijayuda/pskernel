import Ps.KernelCore.API.Dag

/- Native protocol proofs for the public ordinary-admission handoff.
   They assume the same validated internal owner correspondence as the command
   workers. The public boundary still establishes replay and original-input
   bounds; these equations do not certify arbitrary caller-built owners. -/
namespace PsKernelOrdinaryAdmissionPublicProofs

variable
  (admit : PsKernelDagGeneratedState ->
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult))
  (input : PsKernelExprV2Decoded)
  (execution : PsKernelDagExecutionState)
  (levelParams : List PsKernelName)
  (safety : PsKernelDefinitionSafety)
  (arena : PsKernelExprV2PagedArena)
  (built : PsKernelExprV2Decoded)
  (request : PsKernelDagDeclarationRequest)
  (declaration : PsKernelDeclarationRequest)

theorem preflight_error_precedes_private_worker
    (error : PsKernelError)
    (preflight : psKernelKernelSessionPreflight execution.session = Except.error error) :
    psKernelDagRunOrdinaryOwnedWith admit input execution levelParams safety
      arena built request declaration = Except.error error := by
  simp only [psKernelDagRunOrdinaryOwnedWith, preflight]

theorem decline_restarts_original_session_arena_input_and_request
    (preflight : psKernelKernelSessionPreflight execution.session = Except.ok ())
    (declined : admit (PsKernelDagGeneratedState.mk arena built execution.declarations) =
      Option.none) :
    psKernelDagRunOrdinaryOwnedWith admit input execution levelParams safety
      arena built request declaration =
      psKernelDagRunFallbackOwnedCommandWithSource input execution levelParams safety
        arena built (PsKernelDagCommand.admit request) := by
  simp only [psKernelDagRunOrdinaryOwnedWith, preflight, declined]

theorem private_error_returns_no_owner_or_environment
    (error : String)
    (preflight : psKernelKernelSessionPreflight execution.session = Except.ok ())
    (failed : admit (PsKernelDagGeneratedState.mk arena built execution.declarations) =
      Option.some (Except.error error)) :
    psKernelDagRunOrdinaryOwnedWith admit input execution levelParams safety
      arena built request declaration = Except.error (psKernelErrorFromMessage error) := by
  simp only [psKernelDagRunOrdinaryOwnedWith, preflight, failed]

theorem private_success_reaches_resource_gate_with_complete_result
    (checked : PsKernelExprV2OrdinaryAdmissionResult)
    (preflight : psKernelKernelSessionPreflight execution.session = Except.ok ())
    (accepted : admit (PsKernelDagGeneratedState.mk arena built execution.declarations) =
      Option.some (Except.ok checked)) :
    psKernelDagRunOrdinaryOwnedWith admit input execution levelParams safety
      arena built request declaration =
      psKernelDagFinishOwnedOrdinaryAdmission execution.session declaration checked := by
  simp only [psKernelDagRunOrdinaryOwnedWith, preflight, accepted]

theorem declaration_limit_returns_no_checked_owner
    (session : PsKernelKernelSession) (checked : PsKernelExprV2OrdinaryAdmissionResult)
    (denied : psKernelResourceAllowsSize session.resources
      (psKernelEnvironmentSize checked.environment) = false) :
    psKernelDagFinishOwnedOrdinaryAdmission session declaration checked =
      Except.error
        (PsKernelError.resourceExhausted PsKernelResourceError.declarationLimit
          "declaration limit exceeded") := by
  simp [psKernelDagFinishOwnedOrdinaryAdmission, denied]

theorem successful_publication_retains_exact_owner_and_clears_evaluator
    (session : PsKernelKernelSession) (checked : PsKernelExprV2OrdinaryAdmissionResult)
    (allowed : psKernelResourceAllowsSize session.resources
      (psKernelEnvironmentSize checked.environment) = true) :
    psKernelDagFinishOwnedOrdinaryAdmission session declaration checked =
      Except.ok
        (PsKernelDagOwnedCommandResult.mk
          (PsKernelDagReply.admitted
            (psKernelV1Receipt session
              (psKernelEnvironmentWithNativeEvaluator checked.environment Option.none)))
          (PsKernelDagExecutionState.mk
            (PsKernelKernelSession.mk
              (psKernelEnvironmentWithNativeEvaluator checked.environment Option.none)
              session.resources session.provider)
            checked.owner.declarations)
          checked.owner) := by
  simp [psKernelDagFinishOwnedOrdinaryAdmission, allowed]

theorem fallback_failure_precedes_generated_metadata_import
    (command : PsKernelDagCommand) (error : PsKernelError)
    (failed : psKernelDagRunCommandWithSource input execution levelParams safety
      arena built command = Except.error error) :
    psKernelDagRunFallbackOwnedCommandWithSource input execution levelParams safety
      arena built command = Except.error error := by
  simp only [psKernelDagRunFallbackOwnedCommandWithSource, failed]

theorem original_input_decode_failure_precedes_ordinary_admission
    (levels : List PsKernelName) (numParams : Nat)
    (value : PsKernelDagInductive) (isUnsafe : Bool) (error : String)
    (failed : psKernelDagDecodeDeclaration input
      (PsKernelDagDeclarationRequest.ordinaryInductive levels numParams value isUnsafe) =
        Except.error error) :
    psKernelDagRunOwnedCommandWithSource input execution levelParams safety arena built
      (PsKernelDagCommand.admit
        (PsKernelDagDeclarationRequest.ordinaryInductive levels numParams value isUnsafe)) =
      Except.error (PsKernelError.rejectedInvalid error) := by
  simp only [psKernelDagRunOwnedCommandWithSource, failed]

#print axioms preflight_error_precedes_private_worker
#print axioms decline_restarts_original_session_arena_input_and_request
#print axioms private_error_returns_no_owner_or_environment
#print axioms private_success_reaches_resource_gate_with_complete_result
#print axioms declaration_limit_returns_no_checked_owner
#print axioms successful_publication_retains_exact_owner_and_clears_evaluator
#print axioms fallback_failure_precedes_generated_metadata_import
#print axioms original_input_decode_failure_precedes_ordinary_admission

end PsKernelOrdinaryAdmissionPublicProofs
