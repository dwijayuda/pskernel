import Ps.KernelCore.API.Dag

/- Native protocol equations for explicit Quot session-owner preparation.
   Internal workers require the validated original input/private-owner boundary.
   No arbitrary session record or returned receipt is a checking certificate. -/
namespace PsKernelQuotSessionOwnerProofs

variable
  (prepare : PsKernelEnvironment -> PsKernelDagGeneratedState ->
    Except String PsKernelDagGeneratedState)
  (admit : PsKernelEnvironment -> PsKernelExprV2PagedArena ->
    List PsKernelExprV2DeclarationRef -> Option (Except String PsKernelEnvironment))
  (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
  (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
  (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)

theorem preflight_error_precedes_prepare
    (error : PsKernelError)
    (failed : psKernelKernelSessionPreflight execution.session = Except.error error) :
    psKernelDagRunQuotOwnedWith prepare admit input execution levelParams safety arena built =
      Except.error error := by
  simp only [psKernelDagRunQuotOwnedWith, failed]

theorem prepare_error_publishes_no_owner
    (error : String)
    (preflight : psKernelKernelSessionPreflight execution.session = Except.ok ())
    (failed : prepare (psKernelKernelSessionEnvironment execution.session)
      (PsKernelDagGeneratedState.mk arena built execution.declarations) = Except.error error) :
    psKernelDagRunQuotOwnedWith prepare admit input execution levelParams safety arena built =
      Except.error (PsKernelError.internalError error) := by
  simp only [psKernelDagRunQuotOwnedWith, preflight, failed]

theorem decline_discards_prepared_owner_and_restarts_original
    (prepared : PsKernelDagGeneratedState)
    (preflight : psKernelKernelSessionPreflight execution.session = Except.ok ())
    (ready : prepare (psKernelKernelSessionEnvironment execution.session)
      (PsKernelDagGeneratedState.mk arena built execution.declarations) = Except.ok prepared)
    (declined : admit (psKernelKernelSessionEnvironment execution.session)
      prepared.arena prepared.declarations = Option.none) :
    psKernelDagRunQuotOwnedWith prepare admit input execution levelParams safety arena built =
      psKernelDagRunFallbackOwnedCommandWithSource input execution levelParams safety arena built
        (PsKernelDagCommand.admit PsKernelDagDeclarationRequest.quot) := by
  simp only [psKernelDagRunQuotOwnedWith, preflight, ready, declined]

theorem hard_rejection_never_invokes_original_admission
    (prepared : PsKernelDagGeneratedState) (error : String)
    (preflight : psKernelKernelSessionPreflight execution.session = Except.ok ())
    (ready : prepare (psKernelKernelSessionEnvironment execution.session)
      (PsKernelDagGeneratedState.mk arena built execution.declarations) = Except.ok prepared)
    (rejected : admit (psKernelKernelSessionEnvironment execution.session)
      prepared.arena prepared.declarations = Option.some (Except.error error)) :
    psKernelDagRunQuotOwnedWith prepare admit input execution levelParams safety arena built =
      Except.error (psKernelErrorFromMessage error) := by
  simp only [psKernelDagRunQuotOwnedWith, preflight, ready, rejected]

theorem success_keeps_exact_prepared_owner_for_atomic_publication
    (prepared : PsKernelDagGeneratedState) (environment : PsKernelEnvironment)
    (preflight : psKernelKernelSessionPreflight execution.session = Except.ok ())
    (ready : prepare (psKernelKernelSessionEnvironment execution.session)
      (PsKernelDagGeneratedState.mk arena built execution.declarations) = Except.ok prepared)
    (accepted : admit (psKernelKernelSessionEnvironment execution.session)
      prepared.arena prepared.declarations = Option.some (Except.ok environment)) :
    psKernelDagRunQuotOwnedWith prepare admit input execution levelParams safety arena built =
      psKernelDagFinishOwnedQuotAdmission execution.session environment prepared := by
  simp only [psKernelDagRunQuotOwnedWith, preflight, ready, accepted]

theorem declaration_limit_precedes_generated_header_import
    (session : PsKernelKernelSession) (environment : PsKernelEnvironment)
    (prepared : PsKernelDagGeneratedState)
    (limited : psKernelResourceAllowsSize session.resources
      (psKernelEnvironmentSize environment) = false) :
    psKernelDagFinishOwnedQuotAdmission session environment prepared =
      Except.error
        (PsKernelError.resourceExhausted PsKernelResourceError.declarationLimit
          "declaration limit exceeded") := by
  simp only [psKernelDagFinishOwnedQuotAdmission, limited, Bool.false_eq_true, ite_false]

theorem initialized_preparation_is_exact_identity
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (initialized : environment.quotInitialized = true) :
    psKernelDagGeneratedPrepareQuot environment state = Except.ok state := by
  simp only [psKernelDagGeneratedPrepareQuot, initialized, ite_true]

theorem missing_eq_preparation_is_exact_identity
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (uninitialized : environment.quotInitialized = false)
    (missing : psKernelEnvironmentFind environment psKernelEqName = none) :
    psKernelDagGeneratedPrepareQuot environment state = Except.ok state := by
  simp only [psKernelDagGeneratedPrepareQuot, uninitialized,
    Bool.false_eq_true, ite_false, missing]

theorem wrong_eq_kind_does_not_import
    (environment : PsKernelEnvironment) (state : PsKernelDagGeneratedState)
    (value : PsKernelAxiomInfo)
    (uninitialized : environment.quotInitialized = false)
    (wrong : psKernelEnvironmentFind environment psKernelEqName =
      some (PsKernelConstantInfo.axiomInfo value)) :
    psKernelDagGeneratedPrepareQuot environment state = Except.ok state := by
  simp only [psKernelDagGeneratedPrepareQuot, uninitialized,
    Bool.false_eq_true, ite_false, wrong]

theorem explicit_public_quot_routes_to_owned_worker :
    psKernelDagRunOwnedCommandWithSource input execution levelParams safety arena built
      (PsKernelDagCommand.admit PsKernelDagDeclarationRequest.quot) =
    psKernelDagRunQuotOwnedWith psKernelDagGeneratedPrepareQuot psKernelDagTryAdmitQuot
      input execution levelParams safety arena built := by
  rfl

end PsKernelQuotSessionOwnerProofs

#print axioms PsKernelQuotSessionOwnerProofs.preflight_error_precedes_prepare
#print axioms PsKernelQuotSessionOwnerProofs.prepare_error_publishes_no_owner
#print axioms PsKernelQuotSessionOwnerProofs.decline_discards_prepared_owner_and_restarts_original
#print axioms PsKernelQuotSessionOwnerProofs.hard_rejection_never_invokes_original_admission
#print axioms PsKernelQuotSessionOwnerProofs.success_keeps_exact_prepared_owner_for_atomic_publication
#print axioms PsKernelQuotSessionOwnerProofs.declaration_limit_precedes_generated_header_import
#print axioms PsKernelQuotSessionOwnerProofs.initialized_preparation_is_exact_identity
#print axioms PsKernelQuotSessionOwnerProofs.missing_eq_preparation_is_exact_identity
#print axioms PsKernelQuotSessionOwnerProofs.wrong_eq_kind_does_not_import
#print axioms PsKernelQuotSessionOwnerProofs.explicit_public_quot_routes_to_owned_worker
