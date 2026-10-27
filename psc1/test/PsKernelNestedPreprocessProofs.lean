import Lean
import Ps.KernelCore.API.DagNestedPreprocess

namespace PsKernelNestedPreprocessProofs
abbrev Check := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  Option (Except String (PsKernelExprV2CheckState × Nat))
variable (fuel : Nat) (environment : PsKernelEnvironment)
variable (header : PsKernelExprV2NestedHeader) (owner : PsKernelDagGeneratedState)

theorem synchronization_error_precedes_parameter_decode_and_queue
    (built : PsKernelExprV2Decoded) (error : String)
    (sync : psKernelExprV2OrdinarySynchronizeOwner header.parameters.state built = .error error) :
    psKernelExprV2NestedPreprocessAfterHeader fuel environment built header = .error error := by
  simp only [psKernelExprV2NestedPreprocessAfterHeader,sync]

theorem parameter_decode_error_precedes_discovery
    (error : String)
    (decode : psKernelExprV2OrdinaryDecodeBinders header.parameters.binders owner.built = .error error) :
    psKernelExprV2NestedProcessSynchronizedParameters fuel environment header owner = .error error := by
  simp only [psKernelExprV2NestedProcessSynchronizedParameters,decode]

theorem original_queue_error_keeps_exact_preprocessing_prefix
    (parameters : List PsKernelOpenBinder) (error : String)
    (queue : psKernelSimpleNestedProcessQueue fuel environment header.original.levelParams
      (psKernelSimpleMutualNames header.original.types) parameters header.original.numParams
      header.original.types [] (PsKernelSimpleNestedMapState.mk [] 1 []) = .error error) :
    psKernelExprV2NestedProcessDecodedParameters fuel environment header owner parameters =
      .error (String.Internal.append "nested preprocessing: " error) := by
  simp only [psKernelExprV2NestedProcessDecodedParameters,queue]

theorem original_queue_success_keeps_exact_metadata_and_owner
    (parameters : List PsKernelOpenBinder) (processed : PsKernelSimpleNestedProcessQueueResult)
    (queue : psKernelSimpleNestedProcessQueue fuel environment header.original.levelParams
      (psKernelSimpleMutualNames header.original.types) parameters header.original.numParams
      header.original.types [] (PsKernelSimpleNestedMapState.mk [] 1 []) = .ok processed) :
    psKernelExprV2NestedProcessDecodedParameters fuel environment header owner parameters =
      .ok (PsKernelExprV2NestedPreprocessed.mk header parameters processed owner) := by
  simp only [psKernelExprV2NestedProcessDecodedParameters,queue]

theorem empty_original_queue_keeps_original_syntax_state_at_zero_fuel
    (parameters : List PsKernelOpenBinder)
    (empty : header.original.types = []) :
    psKernelExprV2NestedProcessDecodedParameters 0 environment header owner parameters =
      .ok (PsKernelExprV2NestedPreprocessed.mk header parameters
        (PsKernelSimpleNestedProcessQueueResult.mk [] (PsKernelSimpleNestedMapState.mk [] 1 [])) owner) := by
  simp only [psKernelExprV2NestedProcessDecodedParameters,empty,
    psKernelSimpleNestedProcessQueue,psKernelSimpleNestedProcessQueueWithFuel]

theorem header_decline_precedes_suffix_decode_and_discovery
    (check whnf : Check) (depth maxNat : Nat) (input : PsKernelExprV2Decoded)
    (value : PsKernelDagInductiveGroup)
    (step : psKernelExprV2NestedAnalyzeHeaderWith check whnf fuel environment depth maxNat
      input owner.arena owner.declarations value = none) :
    psKernelExprV2NestedPreprocessWith check whnf fuel environment depth maxNat input owner value = none := by
  simp only [psKernelExprV2NestedPreprocessWith,step]

theorem header_error_precedes_suffix_decode_and_discovery
    (check whnf : Check) (depth maxNat : Nat) (input : PsKernelExprV2Decoded)
    (value : PsKernelDagInductiveGroup) (error : String)
    (step : psKernelExprV2NestedAnalyzeHeaderWith check whnf fuel environment depth maxNat
      input owner.arena owner.declarations value = some (.error error)) :
    psKernelExprV2NestedPreprocessWith check whnf fuel environment depth maxNat input owner value =
      some (.error error) := by
  simp only [psKernelExprV2NestedPreprocessWith,step]

theorem actual_wrapper_preserves_owned_check_public_whnf_and_entry_fuel
    (depth maxNat : Nat) (input : PsKernelExprV2Decoded) (value : PsKernelDagInductiveGroup) :
    psKernelExprV2NestedPreprocessWithFuel fuel environment depth maxNat input owner value =
      psKernelExprV2NestedPreprocessWith psKernelExprV2TryCheckStateWithFuel
        psKernelExprV2TryWhnfCheckStateWithFuel fuel environment depth maxNat input owner value := rfl

end PsKernelNestedPreprocessProofs

#print axioms PsKernelNestedPreprocessProofs.synchronization_error_precedes_parameter_decode_and_queue
#print axioms PsKernelNestedPreprocessProofs.parameter_decode_error_precedes_discovery
#print axioms PsKernelNestedPreprocessProofs.original_queue_error_keeps_exact_preprocessing_prefix
#print axioms PsKernelNestedPreprocessProofs.original_queue_success_keeps_exact_metadata_and_owner
#print axioms PsKernelNestedPreprocessProofs.empty_original_queue_keeps_original_syntax_state_at_zero_fuel
#print axioms PsKernelNestedPreprocessProofs.header_decline_precedes_suffix_decode_and_discovery
#print axioms PsKernelNestedPreprocessProofs.header_error_precedes_suffix_decode_and_discovery
#print axioms PsKernelNestedPreprocessProofs.actual_wrapper_preserves_owned_check_public_whnf_and_entry_fuel
