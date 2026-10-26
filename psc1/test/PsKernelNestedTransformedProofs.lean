import Lean
import Ps.KernelCore.API.DagNestedTransformed

namespace PsKernelNestedTransformedProofs

/- Private phase protocol only. Owning ordinary/mutual checking remains the
   source of judgments; transformed success still requires restoration and
   validation before any final nested environment can be published. -/

theorem empty_target_list_preserves_entire_owner
    (origins : List PsKernelDagInductive) (owner : PsKernelDagGeneratedState) :
    psKernelExprV2NestedImportTypeTargets [] origins owner = .ok (owner,[]) := rfl

theorem transformed_decline_is_not_restarted (hasAux : Bool) :
    psKernelExprV2NestedTransformedPrefix hasAux none = none := rfl

theorem transformed_success_retains_exact_checked_environment_and_owner
    (hasAux : Bool) (admitted : PsKernelExprV2OrdinaryAdmissionResult) :
    psKernelExprV2NestedTransformedPrefix hasAux (some (.ok admitted)) = some (.ok admitted) := rfl

theorem no_aux_error_has_no_transformed_prefix (error : String) :
    psKernelExprV2NestedTransformedPrefix false (some (.error error)) = some (.error error) := rfl

theorem auxiliary_error_keeps_exact_original_transformed_prefix (error : String) :
    psKernelExprV2NestedTransformedPrefix true (some (.error error)) =
      some (.error (String.Internal.append "nested transformed admission: " error)) := rfl

variable (ordinary : Nat -> PsKernelEnvironment -> Nat -> Nat -> PsKernelExprV2Decoded ->
      PsKernelDagGeneratedState -> List PsKernelName -> Nat -> PsKernelDagInductive -> Bool ->
      Option (Except String PsKernelExprV2OrdinaryAdmissionResult))
    (admitMutual : Nat -> PsKernelEnvironment -> Nat -> Nat -> PsKernelExprV2Decoded ->
      PsKernelDagGeneratedState -> PsKernelDagInductiveGroup ->
      Option (Except String PsKernelExprV2OrdinaryAdmissionResult))

theorem auxiliary_route_is_always_the_owning_mutual_callback
    (fuel : Nat) (environment : PsKernelEnvironment) (depth natLimit : Nat)
    (owner : PsKernelDagGeneratedState) (value : PsKernelDagInductiveGroup) :
    psKernelExprV2NestedAdmitModeWith ordinary admitMutual true fuel environment depth natLimit owner value =
      psKernelExprV2NestedTransformedPrefix true
        (admitMutual fuel environment depth natLimit owner.built owner value) := rfl

theorem no_aux_empty_group_keeps_original_error_before_callbacks
    (fuel : Nat) (environment : PsKernelEnvironment) (depth natLimit : Nat)
    (owner : PsKernelDagGeneratedState) (levels : List PsKernelName) (params : Nat) (unsafeFlag : Bool) :
    psKernelExprV2NestedAdmitModeWith ordinary admitMutual false fuel environment depth natLimit owner
      ⟨levels,params,[],unsafeFlag⟩ = some (.error "empty nested inductive declaration") := rfl

theorem no_aux_single_group_uses_exact_owning_ordinary_callback
    (fuel : Nat) (environment : PsKernelEnvironment) (depth natLimit : Nat)
    (owner : PsKernelDagGeneratedState) (levels : List PsKernelName) (params : Nat)
    (first : PsKernelDagInductive) (unsafeFlag : Bool) :
    psKernelExprV2NestedAdmitModeWith ordinary admitMutual false fuel environment depth natLimit owner
      ⟨levels,params,[first],unsafeFlag⟩ =
        ordinary fuel environment depth natLimit owner.built owner levels params first unsafeFlag := rfl

end PsKernelNestedTransformedProofs
#print axioms PsKernelNestedTransformedProofs.empty_target_list_preserves_entire_owner
#print axioms PsKernelNestedTransformedProofs.transformed_decline_is_not_restarted
#print axioms PsKernelNestedTransformedProofs.transformed_success_retains_exact_checked_environment_and_owner
#print axioms PsKernelNestedTransformedProofs.no_aux_error_has_no_transformed_prefix
#print axioms PsKernelNestedTransformedProofs.auxiliary_error_keeps_exact_original_transformed_prefix
#print axioms PsKernelNestedTransformedProofs.auxiliary_route_is_always_the_owning_mutual_callback
#print axioms PsKernelNestedTransformedProofs.no_aux_empty_group_keeps_original_error_before_callbacks
#print axioms PsKernelNestedTransformedProofs.no_aux_single_group_uses_exact_owning_ordinary_callback
