import Ps.KernelCore.API.DagOrdinaryAdmission

/- Exact private admission equations. The owning canonical arena and decoded
   prefix must correspond; size guards alone do not establish that invariant.
   Constructor shapes and rule metadata come from the internal generator.
   Injected-callback equations specify ordering and complete owner transfer,
   not the soundness of arbitrary callbacks or caller-constructed metadata.
   No environment/owner pair is returned before final suffix synchronization. -/
namespace PsKernelOrdinaryAdmissionProofs

abbrev Check :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
  Option (Except String (Prod PsKernelExprV2CheckState Nat))
abbrev DefEq :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
  Option (Except String (Prod PsKernelExprV2CheckState Bool))
abbrev Expected :=
  PsKernelSimpleConstructorShape -> PsKernelExprV2CheckState -> PsKernelExprV2Decoded ->
  Except String PsKernelExprV2OrdinaryImported

variable (check whnf : Check) (defeq : DefEq) (expected : Expected)
  (fuel : Nat) (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
  (built : PsKernelExprV2Decoded)

theorem rules_empty_identity_at_any_fuel :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker []
      check defeq expected fuel context state built [] =
    some (.ok (PsKernelExprV2OrdinaryRuleState.mk state built)) := by
  rfl

theorem rules_excess_precedes_callbacks (rule : PsKernelExprV2RecursorRuleRef)
    (rest : List PsKernelExprV2RecursorRuleRef) :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker []
      check defeq expected fuel context state built (rule :: rest) =
    some (.error "generated simple recursor rule count mismatch") := by
  rfl

variable (shape : PsKernelSimpleConstructorShape) (shapes : List PsKernelSimpleConstructorShape)
  (rule : PsKernelExprV2RecursorRuleRef) (rules : List PsKernelExprV2RecursorRuleRef)

theorem rules_missing_precedes_callbacks :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker (shape :: shapes)
      check defeq expected fuel context state built [] =
    some (.error "generated simple recursor rule count mismatch") := by
  rfl

theorem rule_check_decline_precedes_import
    (h : check fuel context state rule.rhs = none) :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker (shape :: shapes)
      check defeq expected fuel context state built (rule :: rules) = none := by
  simp only [psKernelExprV2OrdinaryValidateRecursorRulesWorker, h]

theorem rule_check_error_precedes_import (message : String)
    (h : check fuel context state rule.rhs = some (.error message)) :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker (shape :: shapes)
      check defeq expected fuel context state built (rule :: rules) = some (.error message) := by
  simp only [psKernelExprV2OrdinaryValidateRecursorRulesWorker, h]

variable (checkedOwner : PsKernelExprV2CheckState) (checkedType : Nat)
  (imported : PsKernelExprV2OrdinaryImported)

theorem expected_import_error_uses_complete_checked_owner (message : String)
    (hc : check fuel context state rule.rhs = some (.ok (checkedOwner,checkedType)))
    (hi : expected shape checkedOwner built = .error message) :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker (shape :: shapes)
      check defeq expected fuel context state built (rule :: rules) = some (.error message) := by
  simp only [psKernelExprV2OrdinaryValidateRecursorRulesWorker, hc, hi]

theorem rule_defeq_decline_uses_complete_imported_owner
    (hc : check fuel context state rule.rhs = some (.ok (checkedOwner,checkedType)))
    (hi : expected shape checkedOwner built = .ok imported)
    (he : defeq fuel context imported.state checkedType imported.root = none) :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker (shape :: shapes)
      check defeq expected fuel context state built (rule :: rules) = none := by
  simp only [psKernelExprV2OrdinaryValidateRecursorRulesWorker, hc, hi, he]

theorem rule_defeq_error_uses_complete_imported_owner (message : String)
    (hc : check fuel context state rule.rhs = some (.ok (checkedOwner,checkedType)))
    (hi : expected shape checkedOwner built = .ok imported)
    (he : defeq fuel context imported.state checkedType imported.root = some (.error message)) :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker (shape :: shapes)
      check defeq expected fuel context state built (rule :: rules) = some (.error message) := by
  simp only [psKernelExprV2OrdinaryValidateRecursorRulesWorker, hc, hi, he]

variable (comparedOwner : PsKernelExprV2CheckState)

theorem rule_defeq_false_prevents_tail_and_publication
    (hc : check fuel context state rule.rhs = some (.ok (checkedOwner,checkedType)))
    (hi : expected shape checkedOwner built = .ok imported)
    (he : defeq fuel context imported.state checkedType imported.root =
      some (.ok (comparedOwner,false))) :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker (shape :: shapes)
      check defeq expected fuel context state built (rule :: rules) =
    some (.error "generated simple recursor rule is not type preserving") := by
  simp [psKernelExprV2OrdinaryValidateRecursorRulesWorker, hc, hi, he]

theorem rule_success_returns_tail_with_same_fuel_and_full_owner
    (hc : check fuel context state rule.rhs = some (.ok (checkedOwner,checkedType)))
    (hi : expected shape checkedOwner built = .ok imported)
    (he : defeq fuel context imported.state checkedType imported.root =
      some (.ok (comparedOwner,true))) :
    psKernelExprV2OrdinaryValidateRecursorRulesWorker (shape :: shapes)
      check defeq expected fuel context state built (rule :: rules) =
    psKernelExprV2OrdinaryValidateRecursorRulesWorker shapes
      check defeq expected fuel context comparedOwner imported.built rules := by
  simp [psKernelExprV2OrdinaryValidateRecursorRulesWorker, hc, hi, he]

theorem synchronize_returns_current_arena_and_references (decoded : PsKernelExprV2Decoded)
    (h : psKernelExprV2OrdinaryExtendDecoded state.whnf.arena built = .ok decoded) :
    psKernelExprV2OrdinarySynchronizeOwner state built =
    .ok (PsKernelDagGeneratedState.mk state.whnf.arena decoded state.whnf.declarations) := by
  simp only [psKernelExprV2OrdinarySynchronizeOwner, h]

theorem generated_import_preserves_complete_semantic_owner
    (source : PsKernelExpr) (owner next : PsKernelDagGeneratedState) (root : Nat)
    (hs : psKernelExprV2OrdinarySynchronizeOwner state built = .ok owner)
    (hi : psKernelDagGeneratedImport source owner = .ok (next,root)) :
    psKernelExprV2OrdinaryImportGenerated source state built =
    .ok (PsKernelExprV2OrdinaryImported.mk
      (psKernelExprV2CheckStateWithArena state next.arena) next.built root) := by
  simp only [psKernelExprV2OrdinaryImportGenerated, hs, hi]

variable (environment : PsKernelEnvironment) (declarations : List PsKernelExprV2DeclarationRef)
  (plan : PsKernelExprV2OrdinaryRecursorPlan) (typeRoot : Nat)

theorem recursor_staging_ignores_type_phase_semantic_and_reference_mutations
    (first second : PsKernelExprV2CheckState)
    (arena : first.whnf.arena = second.whnf.arena) :
    psKernelExprV2OrdinaryStageRecursor environment declarations plan typeRoot first built =
    psKernelExprV2OrdinaryStageRecursor environment declarations plan typeRoot second built := by
  simp only [psKernelExprV2OrdinaryStageRecursor, arena]

theorem recursor_staging_uses_parent_owner_and_adds_generated_reference
    (sorted : PsKernelExprV2CheckState) (decoded : PsKernelExprV2Decoded)
    (next : PsKernelDagGeneratedState) (generatedRules : List PsKernelExprV2RecursorRuleRef)
    (hd : psKernelExprV2OrdinaryExtendDecoded sorted.whnf.arena built = .ok decoded)
    (hi : psKernelDagGeneratedImportRules plan.info.rules
      (PsKernelDagGeneratedState.mk sorted.whnf.arena decoded declarations) =
        .ok (next,generatedRules)) :
    psKernelExprV2OrdinaryStageRecursor environment declarations plan typeRoot sorted built =
    .ok (PsKernelExprV2OrdinaryStagedRecursor.mk
      (psKernelEnvironmentAddUnchecked environment (.recInfo plan.info))
      (PsKernelDagGeneratedState.mk next.arena next.built
        (PsKernelExprV2DeclarationRef.mk plan.info.base.name plan.info.base.levelParams
          typeRoot none (.recursorDecl generatedRules) :: next.declarations)) generatedRules) := by
  simp only [psKernelExprV2OrdinaryStageRecursor, hd, hi]

variable (maxRecDepth maxNatSize : Nat) (isUnsafe : Bool)
  (staged : PsKernelExprV2OrdinaryStagedRecursor)

theorem fresh_rule_phase_decline_prevents_publication
    (h : psKernelExprV2OrdinaryValidateRecursorRulesWith check defeq fuel
      (psKernelExprV2OrdinaryFreshContext staged.environment plan.info.base.levelParams
        isUnsafe maxRecDepth maxNatSize)
      (psKernelExprV2OrdinaryFreshState staged.owner) staged.owner.built plan staged.rules = none) :
    psKernelExprV2OrdinaryValidateStagedRecursorWith check defeq fuel maxRecDepth maxNatSize
      isUnsafe plan staged = none := by
  simp only [psKernelExprV2OrdinaryValidateStagedRecursorWith, h]

theorem fresh_rule_phase_error_prevents_publication (message : String)
    (h : psKernelExprV2OrdinaryValidateRecursorRulesWith check defeq fuel
      (psKernelExprV2OrdinaryFreshContext staged.environment plan.info.base.levelParams
        isUnsafe maxRecDepth maxNatSize)
      (psKernelExprV2OrdinaryFreshState staged.owner) staged.owner.built plan staged.rules =
        some (.error message)) :
    psKernelExprV2OrdinaryValidateStagedRecursorWith check defeq fuel maxRecDepth maxNatSize
      isUnsafe plan staged = some (.error message) := by
  simp only [psKernelExprV2OrdinaryValidateStagedRecursorWith, h]

theorem fresh_rule_phase_success_still_requires_final_synchronization
    (checked : PsKernelExprV2OrdinaryRuleState)
    (h : psKernelExprV2OrdinaryValidateRecursorRulesWith check defeq fuel
      (psKernelExprV2OrdinaryFreshContext staged.environment plan.info.base.levelParams
        isUnsafe maxRecDepth maxNatSize)
      (psKernelExprV2OrdinaryFreshState staged.owner) staged.owner.built plan staged.rules =
        some (.ok checked)) :
    psKernelExprV2OrdinaryValidateStagedRecursorWith check defeq fuel maxRecDepth maxNatSize
      isUnsafe plan staged =
    some (psKernelExprV2OrdinaryFinishAdmission staged.environment checked) := by
  simp only [psKernelExprV2OrdinaryValidateStagedRecursorWith, h]

theorem final_synchronization_error_prevents_success
    (checked : PsKernelExprV2OrdinaryRuleState) (message : String)
    (h : psKernelExprV2OrdinarySynchronizeOwner checked.state checked.built = .error message) :
    psKernelExprV2OrdinaryFinishAdmission environment checked = .error message := by
  simp only [psKernelExprV2OrdinaryFinishAdmission, h]

theorem final_success_contains_only_synchronized_owner
    (checked : PsKernelExprV2OrdinaryRuleState) (owner : PsKernelDagGeneratedState)
    (h : psKernelExprV2OrdinarySynchronizeOwner checked.state checked.built = .ok owner) :
    psKernelExprV2OrdinaryFinishAdmission environment checked =
    .ok (PsKernelExprV2OrdinaryAdmissionResult.mk environment owner) := by
  simp only [psKernelExprV2OrdinaryFinishAdmission, h]

variable (owner : PsKernelDagGeneratedState)

theorem fresh_rule_state_resets_every_semantic_collection :
    psKernelExprV2OrdinaryFreshState owner =
    PsKernelExprV2CheckState.mk
      (PsKernelExprV2WhnfState.mk owner.arena [] [] owner.declarations)
      0 [] [] [] [] [] := by
  rfl

theorem recursor_type_check_decline_precedes_sort
    (hi : psKernelExprV2OrdinaryImportGenerated plan.info.base.type
      (psKernelExprV2OrdinaryFreshState owner) owner.built = .ok imported)
    (hc : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
      isUnsafe maxRecDepth maxNatSize) imported.state imported.root = none) :
    psKernelExprV2OrdinaryCheckRecursorWith check whnf defeq fuel environment
      maxRecDepth maxNatSize isUnsafe owner plan = none := by
  simp only [psKernelExprV2OrdinaryCheckRecursorWith, hi, hc]

theorem recursor_type_check_error_precedes_sort (message : String)
    (hi : psKernelExprV2OrdinaryImportGenerated plan.info.base.type
      (psKernelExprV2OrdinaryFreshState owner) owner.built = .ok imported)
    (hc : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
      isUnsafe maxRecDepth maxNatSize) imported.state imported.root = some (.error message)) :
    psKernelExprV2OrdinaryCheckRecursorWith check whnf defeq fuel environment
      maxRecDepth maxNatSize isUnsafe owner plan = some (.error message) := by
  simp only [psKernelExprV2OrdinaryCheckRecursorWith, hi, hc]

theorem recursor_type_sort_decline_uses_complete_checked_owner
    (hi : psKernelExprV2OrdinaryImportGenerated plan.info.base.type
      (psKernelExprV2OrdinaryFreshState owner) owner.built = .ok imported)
    (hc : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
      isUnsafe maxRecDepth maxNatSize) imported.state imported.root =
        some (.ok (checkedOwner,checkedType)))
    (hs : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel)
      (psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
        isUnsafe maxRecDepth maxNatSize) checkedOwner checkedType = none) :
    psKernelExprV2OrdinaryCheckRecursorWith check whnf defeq fuel environment
      maxRecDepth maxNatSize isUnsafe owner plan = none := by
  simp only [psKernelExprV2OrdinaryCheckRecursorWith, hi, hc, hs]

theorem recursor_type_sort_error_uses_complete_checked_owner (message : String)
    (hi : psKernelExprV2OrdinaryImportGenerated plan.info.base.type
      (psKernelExprV2OrdinaryFreshState owner) owner.built = .ok imported)
    (hc : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
      isUnsafe maxRecDepth maxNatSize) imported.state imported.root =
        some (.ok (checkedOwner,checkedType)))
    (hs : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel)
      (psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
        isUnsafe maxRecDepth maxNatSize) checkedOwner checkedType = some (.error message)) :
    psKernelExprV2OrdinaryCheckRecursorWith check whnf defeq fuel environment
      maxRecDepth maxNatSize isUnsafe owner plan = some (.error message) := by
  simp only [psKernelExprV2OrdinaryCheckRecursorWith, hi, hc, hs]

theorem recursor_type_success_hands_off_only_after_sort_and_staging
    (sorted : PsKernelExprV2CheckState) (level : PsKernelLevel)
    (hi : psKernelExprV2OrdinaryImportGenerated plan.info.base.type
      (psKernelExprV2OrdinaryFreshState owner) owner.built = .ok imported)
    (hc : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
      isUnsafe maxRecDepth maxNatSize) imported.state imported.root =
        some (.ok (checkedOwner,checkedType)))
    (hs : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel)
      (psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
        isUnsafe maxRecDepth maxNatSize) checkedOwner checkedType = some (.ok (sorted,level)))
    (hp : psKernelExprV2OrdinaryStageRecursor environment owner.declarations plan
      imported.root sorted imported.built = .ok staged) :
    psKernelExprV2OrdinaryCheckRecursorWith check whnf defeq fuel environment
      maxRecDepth maxNatSize isUnsafe owner plan =
    psKernelExprV2OrdinaryValidateStagedRecursorWith check defeq fuel maxRecDepth maxNatSize
      isUnsafe plan staged := by
  simp only [psKernelExprV2OrdinaryCheckRecursorWith, hi, hc, hs, hp]

variable (input : PsKernelExprV2Decoded) (levelParams : List PsKernelName)
  (numParams : Nat) (value : PsKernelDagInductive)

theorem unsynchronized_input_owner_rejects_before_decoding
    (h : Nat.beq owner.built.size owner.arena.size = false) :
    psKernelExprV2OrdinaryAdmitWith check whnf defeq fuel environment maxRecDepth maxNatSize
      input owner levelParams numParams value isUnsafe =
    some (.error "PSKERNEL_V2_ORDINARY_INPUT_OWNER_SIZE") := by
  simp [psKernelExprV2OrdinaryAdmitWith, h]

theorem original_namespace_error_precedes_header_check (message : String)
    (hs : Nat.beq owner.built.size owner.arena.size = true)
    (hb : Nat.ble input.size owner.built.size = true)
    (hd : psKernelDagDecodeInductive input value = .error message) :
    psKernelExprV2OrdinaryAdmitWith check whnf defeq fuel environment maxRecDepth maxNatSize
      input owner levelParams numParams value isUnsafe = some (.error message) := by
  simp [psKernelExprV2OrdinaryAdmitWith, hs, hb, hd]

end PsKernelOrdinaryAdmissionProofs

#print axioms PsKernelOrdinaryAdmissionProofs.rules_empty_identity_at_any_fuel
#print axioms PsKernelOrdinaryAdmissionProofs.rules_excess_precedes_callbacks
#print axioms PsKernelOrdinaryAdmissionProofs.rules_missing_precedes_callbacks
#print axioms PsKernelOrdinaryAdmissionProofs.rule_check_decline_precedes_import
#print axioms PsKernelOrdinaryAdmissionProofs.rule_check_error_precedes_import
#print axioms PsKernelOrdinaryAdmissionProofs.expected_import_error_uses_complete_checked_owner
#print axioms PsKernelOrdinaryAdmissionProofs.rule_defeq_decline_uses_complete_imported_owner
#print axioms PsKernelOrdinaryAdmissionProofs.rule_defeq_error_uses_complete_imported_owner
#print axioms PsKernelOrdinaryAdmissionProofs.rule_defeq_false_prevents_tail_and_publication
#print axioms PsKernelOrdinaryAdmissionProofs.rule_success_returns_tail_with_same_fuel_and_full_owner
#print axioms PsKernelOrdinaryAdmissionProofs.synchronize_returns_current_arena_and_references
#print axioms PsKernelOrdinaryAdmissionProofs.generated_import_preserves_complete_semantic_owner
#print axioms PsKernelOrdinaryAdmissionProofs.recursor_staging_ignores_type_phase_semantic_and_reference_mutations
#print axioms PsKernelOrdinaryAdmissionProofs.recursor_staging_uses_parent_owner_and_adds_generated_reference
#print axioms PsKernelOrdinaryAdmissionProofs.fresh_rule_phase_decline_prevents_publication
#print axioms PsKernelOrdinaryAdmissionProofs.fresh_rule_phase_error_prevents_publication
#print axioms PsKernelOrdinaryAdmissionProofs.fresh_rule_phase_success_still_requires_final_synchronization
#print axioms PsKernelOrdinaryAdmissionProofs.final_synchronization_error_prevents_success
#print axioms PsKernelOrdinaryAdmissionProofs.final_success_contains_only_synchronized_owner
#print axioms PsKernelOrdinaryAdmissionProofs.fresh_rule_state_resets_every_semantic_collection
#print axioms PsKernelOrdinaryAdmissionProofs.recursor_type_check_decline_precedes_sort
#print axioms PsKernelOrdinaryAdmissionProofs.recursor_type_check_error_precedes_sort
#print axioms PsKernelOrdinaryAdmissionProofs.recursor_type_sort_decline_uses_complete_checked_owner
#print axioms PsKernelOrdinaryAdmissionProofs.recursor_type_sort_error_uses_complete_checked_owner
#print axioms PsKernelOrdinaryAdmissionProofs.recursor_type_success_hands_off_only_after_sort_and_staging
#print axioms PsKernelOrdinaryAdmissionProofs.unsynchronized_input_owner_rejects_before_decoding
#print axioms PsKernelOrdinaryAdmissionProofs.original_namespace_error_precedes_header_check
