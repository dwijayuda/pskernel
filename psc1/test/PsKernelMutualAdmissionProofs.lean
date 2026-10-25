import Ps.KernelCore.API.DagMutualAdmission
import Lean

/- Algebraic private transaction/owner protocols, not global checker
   soundness or authentication of forged internal decoded tables. The public
   boundary retains resource/capability checks and atomic publication. -/
namespace PsKernelMutualAdmissionProofs
abbrev Check := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  Option (Except String (PsKernelExprV2CheckState × Nat))
abbrev DefEq := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
  Option (Except String (PsKernelExprV2CheckState × Bool))
variable (check whnf : Check) (defeq : DefEq) (fuel : Nat)
  (input built : PsKernelExprV2Decoded) (value : PsKernelDagInductiveGroup)
  (decl : PsKernelSimpleMutualInductiveDecl) (header : PsKernelExprV2MutualHeaderAnalysis)
  (prepared : PsKernelExprV2MutualPreparedAdmission)
  (constructors : PsKernelExprV2MutualConstructorsResult)

theorem empty_type_reference_prefix_preserves_original_owners
    (levels : List PsKernelName) (references : List PsKernelExprV2DeclarationRef) :
    psKernelExprV2MutualPrependTypeReferences [] levels references = references := rfl

theorem type_reference_keeps_original_closed_root_kind_and_order
    (first : PsKernelDagInductive) (rest : List PsKernelDagInductive)
    (levels : List PsKernelName) (references : List PsKernelExprV2DeclarationRef) :
    psKernelExprV2MutualPrependTypeReferences (first :: rest) levels references =
      psKernelExprV2MutualPrependTypeReferences rest levels
        (PsKernelExprV2DeclarationRef.mk first.name levels first.type none .inductiveDecl :: references) := rfl

theorem header_decode_suffix_error_precedes_provisional_metadata
    (error : String)
    (failed : psKernelExprV2OrdinaryExtendDecoded header.arena built = .error error) :
    psKernelExprV2MutualPrepareAdmissionAfterHeader input built decl value header = .error error := by
  simp only [psKernelExprV2MutualPrepareAdmissionAfterHeader, failed]

theorem header_metadata_read_error_precedes_environment_extension
    (decoded : PsKernelExprV2Decoded) (error : String)
    (a : psKernelExprV2OrdinaryExtendDecoded header.arena built = .ok decoded)
    (b : psKernelExprV2MutualDecodeTypeHeaders header.types input decoded = .error error) :
    psKernelExprV2MutualPrepareAdmissionAfterHeader input built decl value header = .error error := by
  simp only [psKernelExprV2MutualPrepareAdmissionAfterHeader, a, b]

theorem preparation_retains_first_parameter_scope_caches_and_freshness
    (decoded : PsKernelExprV2Decoded) (types : List PsKernelSimpleMutualTypeShape)
    (a : psKernelExprV2OrdinaryExtendDecoded header.arena built = .ok decoded)
    (b : psKernelExprV2MutualDecodeTypeHeaders header.types input decoded = .ok types) :
    psKernelExprV2MutualPrepareAdmissionAfterHeader input built decl value header =
      let infos := psKernelMakeSimpleMutualBaseInfos (psKernelSimpleMutualNames decl.types) decl types;
      let parentContext := header.parameters.context;
      let parentState := header.parameters.state;
      let work := psKernelAddMutualInductiveInfos infos parentContext.scalar.environment;
      .ok (PsKernelExprV2MutualPreparedAdmission.mk infos
        (PsKernelExprV2CheckContext.mk (psKernelCheckerContextWithEnvironment parentContext.scalar work) parentContext.locals)
        (psKernelExprV2CheckStateWithWhnf parentState
          (PsKernelExprV2WhnfState.mk header.arena parentState.whnf.coreCache parentState.whnf.publicCache
            (psKernelExprV2MutualPrependTypeReferences value.types value.levelParams parentState.whnf.declarations)))
        decoded) := by
  simp only [psKernelExprV2MutualPrepareAdmissionAfterHeader, a, b]

theorem constructor_owner_sync_error_precedes_data_flags_and_recursors
    (error : String)
    (failed : psKernelExprV2OrdinarySynchronizeOwner constructors.state prepared.built = .error error) :
    psKernelExprV2MutualAfterConstructorsWith check whnf defeq fuel input value header prepared constructors = some (.error error) := by
  simp only [psKernelExprV2MutualAfterConstructorsWith, failed]

theorem constructor_data_error_precedes_final_flags_and_recursors
    (owner : PsKernelDagGeneratedState) (error : String)
    (a : psKernelExprV2OrdinarySynchronizeOwner constructors.state prepared.built = .ok owner)
    (b : psKernelExprV2MutualDecodeRecursorData input owner.built header constructors.shapes = .error error) :
    psKernelExprV2MutualAfterConstructorsWith check whnf defeq fuel input value header prepared constructors = some (.error error) := by
  simp only [psKernelExprV2MutualAfterConstructorsWith, a, b]

theorem recursor_plan_error_returns_no_private_admission
    (owner : PsKernelDagGeneratedState) (data : PsKernelExprV2MutualRecursorData) (error : String)
    (a : psKernelExprV2OrdinarySynchronizeOwner constructors.state prepared.built = .ok owner)
    (b : psKernelExprV2MutualDecodeRecursorData input owner.built header constructors.shapes = .ok data)
    (c : psKernelExprV2MutualMakeRecursorPlan value.levelParams header.resultLevel value.isUnsafe data = .error error) :
    psKernelExprV2MutualAfterConstructorsWith check whnf defeq fuel input value header prepared constructors = some (.error error) := by
  simp only [psKernelExprV2MutualAfterConstructorsWith, a, b, c]

theorem plan_success_requires_all_generated_type_and_rule_checks
    (owner : PsKernelDagGeneratedState) (data : PsKernelExprV2MutualRecursorData)
    (plan : PsKernelExprV2MutualRecursorPlan)
    (a : psKernelExprV2OrdinarySynchronizeOwner constructors.state prepared.built = .ok owner)
    (b : psKernelExprV2MutualDecodeRecursorData input owner.built header constructors.shapes = .ok data)
    (c : psKernelExprV2MutualMakeRecursorPlan value.levelParams header.resultLevel value.isUnsafe data = .ok plan) :
    psKernelExprV2MutualAfterConstructorsWith check whnf defeq fuel input value header prepared constructors = psKernelExprV2MutualCheckRecursorsWith check whnf defeq fuel
      (psKernelReplaceMutualInductiveInfos prepared.baseInfos
        (psKernelSimpleMutualHasRecursiveFields data.constructors)
        (psKernelSimpleMutualHasReflexiveFields data.constructors) constructors.context.scalar.environment)
      prepared.context.scalar.maxRecDepth prepared.context.scalar.maxNatSize value.isUnsafe owner plan := by
  simp only [psKernelExprV2MutualAfterConstructorsWith, a, b, c]

theorem prepare_failure_precedes_constructor_checking
    (error : String)
    (failed : psKernelExprV2MutualPrepareAdmissionAfterHeader input built decl value header = .error error) :
    psKernelExprV2MutualAfterHeaderWith check whnf defeq fuel input built decl value header = some (.error error) := by
  simp only [psKernelExprV2MutualAfterHeaderWith, failed]

theorem constructor_decline_is_an_atomic_private_transaction_step
    
    (ready : psKernelExprV2MutualPrepareAdmissionAfterHeader input built decl value header = .ok prepared)
    (stepped : psKernelExprV2MutualAddTypesWorker header.types
      (fun phaseFuel context state owner ctor => psKernelExprV2MutualAnalyzeConstructorWith
        check whnf defeq phaseFuel context state (psKernelExprV2MutualTypeNames value.types)
        header.types owner (psKernelLevelParamsToLevels value.levelParams) header.parameters.binders header.resultLevel ctor)
      fuel input (psKernelExprV2OrdinaryOpenBinderCount header.parameters.binders) prepared.context prepared.state 0 = none) :
    psKernelExprV2MutualAfterHeaderWith check whnf defeq fuel input built decl value header = none := by
  simp only [psKernelExprV2MutualAfterHeaderWith, ready, stepped]

theorem constructor_error_is_an_atomic_private_transaction_step
    (error : String)
    (ready : psKernelExprV2MutualPrepareAdmissionAfterHeader input built decl value header = .ok prepared)
    (stepped : psKernelExprV2MutualAddTypesWorker header.types
      (fun phaseFuel context state owner ctor => psKernelExprV2MutualAnalyzeConstructorWith
        check whnf defeq phaseFuel context state (psKernelExprV2MutualTypeNames value.types)
        header.types owner (psKernelLevelParamsToLevels value.levelParams) header.parameters.binders header.resultLevel ctor)
      fuel input (psKernelExprV2OrdinaryOpenBinderCount header.parameters.binders) prepared.context prepared.state 0 = some (.error error)) :
    psKernelExprV2MutualAfterHeaderWith check whnf defeq fuel input built decl value header = some (.error error) := by
  simp only [psKernelExprV2MutualAfterHeaderWith, ready, stepped]

theorem constructor_success_is_an_atomic_private_transaction_step
    
    (ready : psKernelExprV2MutualPrepareAdmissionAfterHeader input built decl value header = .ok prepared)
    (stepped : psKernelExprV2MutualAddTypesWorker header.types
      (fun phaseFuel context state owner ctor => psKernelExprV2MutualAnalyzeConstructorWith
        check whnf defeq phaseFuel context state (psKernelExprV2MutualTypeNames value.types)
        header.types owner (psKernelLevelParamsToLevels value.levelParams) header.parameters.binders header.resultLevel ctor)
      fuel input (psKernelExprV2OrdinaryOpenBinderCount header.parameters.binders) prepared.context prepared.state 0 = some (.ok constructors)) :
    psKernelExprV2MutualAfterHeaderWith check whnf defeq fuel input built decl value header = psKernelExprV2MutualAfterConstructorsWith check whnf defeq fuel input value header prepared constructors := by
  simp only [psKernelExprV2MutualAfterHeaderWith, ready, stepped]

variable (environment : PsKernelEnvironment) (depth maxNat : Nat)
  (owner : PsKernelDagGeneratedState)

theorem unsynchronized_owner_rejected_before_decode_and_all_callbacks
    (bad : Nat.beq owner.built.size owner.arena.size = false) :
    psKernelExprV2MutualAdmitWith check whnf defeq fuel environment depth maxNat input owner value = some (.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH") := by
  simp only [psKernelExprV2MutualAdmitWith, bad] <;> rfl

theorem missing_original_prefix_rejected_before_decode_and_all_callbacks
    (synchronized : Nat.beq owner.built.size owner.arena.size = true)
    (bad : Nat.ble input.size owner.built.size = false) :
    psKernelExprV2MutualAdmitWith check whnf defeq fuel environment depth maxNat input owner value = some (.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH") := by
  simp only [psKernelExprV2MutualAdmitWith, synchronized, bad] <;> rfl

theorem boundary_group_decode_error_precedes_header_attempt
    (synchronized : Nat.beq owner.built.size owner.arena.size = true)
    (prefix : Nat.ble input.size owner.built.size = true)
    (error : String) (bad : psKernelDagDecodeGroup input value = .error error) :
    psKernelExprV2MutualAdmitWith check whnf defeq fuel environment depth maxNat input owner value = some (.error error) := by
  simp only [psKernelExprV2MutualAdmitWith, synchronized, prefix, bad] <;> rfl

theorem header_decline_preserves_original_transaction_order
    (synchronized : Nat.beq owner.built.size owner.arena.size = true)
    (prefix : Nat.ble input.size owner.built.size = true)
    
    (decoded : psKernelDagDecodeGroup input value = .ok decl)
    (checked : psKernelExprV2MutualAnalyzeHeaderWith check whnf defeq fuel environment depth maxNat
      owner.arena owner.declarations value = none) :
    psKernelExprV2MutualAdmitWith check whnf defeq fuel environment depth maxNat input owner value = none := by
  simp only [psKernelExprV2MutualAdmitWith, synchronized, prefix, decoded, checked] <;> rfl

theorem header_error_preserves_original_transaction_order
    (synchronized : Nat.beq owner.built.size owner.arena.size = true)
    (prefix : Nat.ble input.size owner.built.size = true)
    (error : String)
    (decoded : psKernelDagDecodeGroup input value = .ok decl)
    (checked : psKernelExprV2MutualAnalyzeHeaderWith check whnf defeq fuel environment depth maxNat
      owner.arena owner.declarations value = some (.error error)) :
    psKernelExprV2MutualAdmitWith check whnf defeq fuel environment depth maxNat input owner value = some (.error error) := by
  simp only [psKernelExprV2MutualAdmitWith, synchronized, prefix, decoded, checked] <;> rfl

theorem header_success_preserves_original_transaction_order
    (synchronized : Nat.beq owner.built.size owner.arena.size = true)
    (prefix : Nat.ble input.size owner.built.size = true)
    
    (decoded : psKernelDagDecodeGroup input value = .ok decl)
    (checked : psKernelExprV2MutualAnalyzeHeaderWith check whnf defeq fuel environment depth maxNat
      owner.arena owner.declarations value = some (.ok header)) :
    psKernelExprV2MutualAdmitWith check whnf defeq fuel environment depth maxNat input owner value = psKernelExprV2MutualAfterHeaderWith check whnf defeq fuel input owner.built decl value header := by
  simp only [psKernelExprV2MutualAdmitWith, synchronized, prefix, decoded, checked] <;> rfl

theorem actual_wrapper_uses_owned_callbacks_at_unchanged_entry_fuel
    : psKernelExprV2MutualAdmitWithFuel fuel environment depth maxNat input owner value =
      psKernelExprV2MutualAdmitWith psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
        psKernelExprV2TryDefEqStateWithFuel fuel environment depth maxNat input owner value := rfl

#print axioms empty_type_reference_prefix_preserves_original_owners
#print axioms type_reference_keeps_original_closed_root_kind_and_order
#print axioms header_decode_suffix_error_precedes_provisional_metadata
#print axioms header_metadata_read_error_precedes_environment_extension
#print axioms preparation_retains_first_parameter_scope_caches_and_freshness
#print axioms constructor_owner_sync_error_precedes_data_flags_and_recursors
#print axioms constructor_data_error_precedes_final_flags_and_recursors
#print axioms recursor_plan_error_returns_no_private_admission
#print axioms plan_success_requires_all_generated_type_and_rule_checks
#print axioms prepare_failure_precedes_constructor_checking
#print axioms constructor_decline_is_an_atomic_private_transaction_step
#print axioms constructor_error_is_an_atomic_private_transaction_step
#print axioms constructor_success_is_an_atomic_private_transaction_step
#print axioms unsynchronized_owner_rejected_before_decode_and_all_callbacks
#print axioms missing_original_prefix_rejected_before_decode_and_all_callbacks
#print axioms boundary_group_decode_error_precedes_header_attempt
#print axioms header_decline_preserves_original_transaction_order
#print axioms header_error_preserves_original_transaction_order
#print axioms header_success_preserves_original_transaction_order
#print axioms actual_wrapper_uses_owned_callbacks_at_unchanged_entry_fuel
end PsKernelMutualAdmissionProofs
