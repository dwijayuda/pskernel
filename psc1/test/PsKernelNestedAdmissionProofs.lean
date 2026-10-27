import Lean
import Ps.KernelCore.API.DagNestedAdmission
namespace PsKernelNestedAdmissionProofs
/- Private transaction protocols; independent checking remains mandatory. -/
theorem late_decline_never_returns_partial_environment (restored : PsKernelExprV2NestedRestored) :
    psKernelExprV2NestedFinishValidated restored none = none := rfl

theorem late_error_never_returns_partial_environment (restored : PsKernelExprV2NestedRestored) (error : String) :
    psKernelExprV2NestedFinishValidated restored (some (.error error)) = some (.error error) := rfl

theorem success_retains_exact_restored_environment_and_checked_owner
    (restored : PsKernelExprV2NestedRestored) (owner : PsKernelDagGeneratedState) :
    psKernelExprV2NestedFinishValidated restored (some (.ok owner)) =
      some (.ok (PsKernelExprV2OrdinaryAdmissionResult.mk restored.environment owner)) := rfl

theorem validation_decline_is_not_restarted :
    psKernelExprV2NestedValidationPrefix none = none := rfl

theorem validation_error_has_exact_original_prefix (error : String) :
    psKernelExprV2NestedValidationPrefix (some (.error error)) =
      some (.error (String.Internal.append "nested restored validation: " error)) := rfl

theorem validation_success_retains_entire_checked_owner (owner : PsKernelDagGeneratedState) :
    psKernelExprV2NestedValidationPrefix (some (.ok owner)) = some (.ok owner) := rfl
end PsKernelNestedAdmissionProofs
#print axioms PsKernelNestedAdmissionProofs.late_decline_never_returns_partial_environment
#print axioms PsKernelNestedAdmissionProofs.late_error_never_returns_partial_environment
#print axioms PsKernelNestedAdmissionProofs.success_retains_exact_restored_environment_and_checked_owner
#print axioms PsKernelNestedAdmissionProofs.validation_decline_is_not_restarted
#print axioms PsKernelNestedAdmissionProofs.validation_error_has_exact_original_prefix
#print axioms PsKernelNestedAdmissionProofs.validation_success_retains_entire_checked_owner
