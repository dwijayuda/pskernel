import Ps.KernelCore.API.DagMutualRecursorValidation
import Lean

/- Local generated-recursor checking and ownership protocols. Arbitrary
   callback results are component premises, not checking certificates.
   No global soundness, backend proof or public publication is claimed. -/
namespace PsKernelMutualRecursorValidationProofs
abbrev Check := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  Option (Except String (PsKernelExprV2CheckState × Nat))
abbrev DefEq := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
  Option (Except String (PsKernelExprV2CheckState × Bool))
variable (check whnf : Check) (defeq : DefEq) (fuel : Nat)
  (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
  (built : PsKernelExprV2Decoded) (plan : PsKernelExprV2MutualRecursorPlan) (owner : Nat)
  (shape : PsKernelSimpleMutualConstructorShape) (rest : List PsKernelSimpleMutualConstructorShape)
  (rule : PsKernelExprV2RecursorRuleRef) (pending : List PsKernelExprV2RecursorRuleRef)

theorem empty_shapes_and_rules_keep_exact_owner_even_at_zero
    : psKernelExprV2MutualValidateRulesWorker [] check defeq 0 context state built plan owner [] =
      some (.ok (PsKernelExprV2OrdinaryRuleState.mk state built)) := rfl

theorem extra_pending_rule_is_original_count_error
    : psKernelExprV2MutualValidateRulesWorker [] check defeq fuel context state built plan owner (rule :: pending) =
      some (.error "mutual recursor rule count mismatch") := rfl

theorem nonowner_shape_skips_callbacks_and_preserves_pending_and_fuel
    (other : Nat.beq shape.owner owner = false) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner (rule :: pending) = psKernelExprV2MutualValidateRulesWorker rest check defeq fuel context state built plan owner (rule :: pending) := by
  simp only [psKernelExprV2MutualValidateRulesWorker, other] <;> rfl

theorem matching_shape_requires_rule_before_check
    (sameOwner : Nat.beq shape.owner owner = true) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner [] =
      some (.error "mutual recursor rule count mismatch") := by
  simp only [psKernelExprV2MutualValidateRulesWorker, sameOwner] <;> rfl

theorem rule_check_decline_precedes_expected_syntax
    
    (sameOwner : Nat.beq shape.owner owner = true)
    (attempted : check fuel context state rule.rhs = none) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner (rule :: pending) = none := by
  simp only [psKernelExprV2MutualValidateRulesWorker, sameOwner, attempted] <;> rfl

theorem rule_check_error_precedes_expected_syntax
    (error : String)
    (sameOwner : Nat.beq shape.owner owner = true)
    (attempted : check fuel context state rule.rhs = some (.error error)) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner (rule :: pending) = some (.error error) := by
  simp only [psKernelExprV2MutualValidateRulesWorker, sameOwner, attempted] <;> rfl

theorem expected_syntax_error_uses_checked_owner_before_defeq
    (next : PsKernelExprV2CheckState) (type : Nat) (error : String)
    (sameOwner : Nat.beq shape.owner owner = true)
    (attempted : check fuel context state rule.rhs = some (.ok (next,type)))
    (expected : psKernelExprV2MutualPrepareExpectedRuleType plan owner shape next built = .error error) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner (rule :: pending) = some (.error error) := by
  simp only [psKernelExprV2MutualValidateRulesWorker, sameOwner, attempted, expected] <;> rfl

theorem rule_defeq_decline_preserves_original_result
    (next : PsKernelExprV2CheckState) (type : Nat)
    (imported : PsKernelExprV2OrdinaryImported) 
    (sameOwner : Nat.beq shape.owner owner = true)
    (attempted : check fuel context state rule.rhs = some (.ok (next,type)))
    (expected : psKernelExprV2MutualPrepareExpectedRuleType plan owner shape next built = .ok imported)
    (equal : defeq fuel context imported.state type imported.root = none) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner (rule :: pending) = none := by
  simp only [psKernelExprV2MutualValidateRulesWorker, sameOwner, attempted, expected, equal] <;> rfl

theorem rule_defeq_error_preserves_original_result
    (next : PsKernelExprV2CheckState) (type : Nat)
    (imported : PsKernelExprV2OrdinaryImported) (error : String)
    (sameOwner : Nat.beq shape.owner owner = true)
    (attempted : check fuel context state rule.rhs = some (.ok (next,type)))
    (expected : psKernelExprV2MutualPrepareExpectedRuleType plan owner shape next built = .ok imported)
    (equal : defeq fuel context imported.state type imported.root = some (.error error)) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner (rule :: pending) = some (.error error) := by
  simp only [psKernelExprV2MutualValidateRulesWorker, sameOwner, attempted, expected, equal] <;> rfl

theorem rule_defeq_false_preserves_original_result
    (next : PsKernelExprV2CheckState) (type : Nat)
    (imported : PsKernelExprV2OrdinaryImported) (finalState : PsKernelExprV2CheckState)
    (sameOwner : Nat.beq shape.owner owner = true)
    (attempted : check fuel context state rule.rhs = some (.ok (next,type)))
    (expected : psKernelExprV2MutualPrepareExpectedRuleType plan owner shape next built = .ok imported)
    (equal : defeq fuel context imported.state type imported.root = some (.ok (finalState,false))) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner (rule :: pending) = some (.error "generated mutual recursor rule is not type preserving") := by
  simp only [psKernelExprV2MutualValidateRulesWorker, sameOwner, attempted, expected, equal] <;> rfl

theorem rule_success_threads_whole_owner_and_known_decoded_prefix_at_fixed_fuel
    (next finalState : PsKernelExprV2CheckState) (type : Nat)
    (imported : PsKernelExprV2OrdinaryImported)
    (sameOwner : Nat.beq shape.owner owner = true)
    (attempted : check fuel context state rule.rhs = some (.ok (next,type)))
    (expected : psKernelExprV2MutualPrepareExpectedRuleType plan owner shape next built = .ok imported)
    (equal : defeq fuel context imported.state type imported.root = some (.ok (finalState,true))) :
    psKernelExprV2MutualValidateRulesWorker (shape :: rest) check defeq fuel context state built plan owner (rule :: pending) = psKernelExprV2MutualValidateRulesWorker rest check defeq fuel context finalState imported.built plan owner pending := by
  simp only [psKernelExprV2MutualValidateRulesWorker, sameOwner, attempted, expected, equal] <;> rfl

theorem empty_staging_keeps_exact_private_environment_and_owner
    (environment : PsKernelEnvironment) (parent : PsKernelDagGeneratedState) :
    psKernelExprV2MutualStageRecursorsWorker [] environment parent =
      .ok (PsKernelExprV2MutualStagedRecursors.mk environment parent []) := rfl

theorem staging_type_import_error_precedes_rule_import_and_metadata
    (environment : PsKernelEnvironment) (parent : PsKernelDagGeneratedState)
    (info : PsKernelRecursorInfo) (error : String)
    (failed : psKernelDagGeneratedImport info.base.type parent = .error error) :
    psKernelExprV2MutualStageRecursor environment parent info = .error error := by
  simp only [psKernelExprV2MutualStageRecursor, failed]

theorem staging_rule_import_error_precedes_metadata
    (environment : PsKernelEnvironment) (parent imported : PsKernelDagGeneratedState)
    (info : PsKernelRecursorInfo) (root : Nat) (error : String)
    (typeImported : psKernelDagGeneratedImport info.base.type parent = .ok (imported,root))
    (rulesFailed : psKernelDagGeneratedImportRules info.rules imported = .error error) :
    psKernelExprV2MutualStageRecursor environment parent info = .error error := by
  simp only [psKernelExprV2MutualStageRecursor, typeImported, rulesFailed]

theorem staging_success_binds_exact_live_metadata_type_root_and_rule_refs
    (environment : PsKernelEnvironment) (parent imported finalOwner : PsKernelDagGeneratedState)
    (info : PsKernelRecursorInfo) (root : Nat) (rules : List PsKernelExprV2RecursorRuleRef)
    (typeImported : psKernelDagGeneratedImport info.base.type parent = .ok (imported,root))
    (rulesImported : psKernelDagGeneratedImportRules info.rules imported = .ok (finalOwner,rules)) :
    psKernelExprV2MutualStageRecursor environment parent info = .ok
      (PsKernelExprV2MutualStagedRecursors.mk
        (psKernelEnvironmentAddUnchecked environment (.recInfo info))
        (PsKernelDagGeneratedState.mk finalOwner.arena finalOwner.built
          (PsKernelExprV2DeclarationRef.mk info.base.name info.base.levelParams root none
            (.recursorDecl rules) :: finalOwner.declarations))
        [PsKernelExprV2MutualRecursorTask.mk info root rules]) := by
  simp only [psKernelExprV2MutualStageRecursor, typeImported, rulesImported]

theorem staging_tail_error_returns_no_partial_environment
    (environment : PsKernelEnvironment) (parent : PsKernelDagGeneratedState)
    (info : PsKernelRecursorInfo) (later : List PsKernelRecursorInfo)
    (first : PsKernelExprV2MutualStagedRecursors) (error : String)
    (a : psKernelExprV2MutualStageRecursor environment parent info = .ok first)
    (b : psKernelExprV2MutualStageRecursorsWorker later first.environment first.owner = .error error) :
    psKernelExprV2MutualStageRecursorsWorker (info :: later) environment parent = .error error := by
  simp only [psKernelExprV2MutualStageRecursorsWorker, a, b]

theorem staging_keeps_task_family_source_order
    (environment : PsKernelEnvironment) (parent : PsKernelDagGeneratedState)
    (info : PsKernelRecursorInfo) (later : List PsKernelRecursorInfo)
    (first tail : PsKernelExprV2MutualStagedRecursors)
    (a : psKernelExprV2MutualStageRecursor environment parent info = .ok first)
    (b : psKernelExprV2MutualStageRecursorsWorker later first.environment first.owner = .ok tail) :
    psKernelExprV2MutualStageRecursorsWorker (info :: later) environment parent = .ok
      (PsKernelExprV2MutualStagedRecursors.mk tail.environment tail.owner
        (psKernelExprV2MutualRecursorTasksAppend first.tasks tail.tasks)) := by
  simp only [psKernelExprV2MutualStageRecursorsWorker, a, b]

theorem resuming_next_fresh_owner_keeps_only_arena_prefix_and_authoritative_refs
    (references : List PsKernelExprV2DeclarationRef) (checked : PsKernelExprV2OrdinaryRuleState)
    (decoded : PsKernelExprV2Decoded)
    (extended : psKernelExprV2OrdinaryExtendDecoded checked.state.whnf.arena checked.built = .ok decoded) :
    psKernelExprV2MutualResumeRecursorOwner references checked =
      .ok (PsKernelDagGeneratedState.mk checked.state.whnf.arena decoded references) := by
  simp only [psKernelExprV2MutualResumeRecursorOwner, extended]

theorem empty_tasks_succeed_at_zero_without_checking
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat) :
    psKernelExprV2MutualCheckRecursorTasksWorker [] check whnf defeq 0 environment
      depth maxNat unsafeFlag plan parent index = some (.ok parent) := rfl

theorem task_check_error_precedes_mandatory_sort_and_rules
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat)
    (task : PsKernelExprV2MutualRecursorTask) (later : List PsKernelExprV2MutualRecursorTask)
    (error : String)
    (failed : check fuel
      (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat)
      (psKernelExprV2OrdinaryFreshState parent) task.type = some (.error error)) :
    psKernelExprV2MutualCheckRecursorTasksWorker (task :: later) check whnf defeq fuel
      environment depth maxNat unsafeFlag plan parent index = some (.error error) := by
  simp only [psKernelExprV2MutualCheckRecursorTasksWorker, failed]

theorem all_staging_precedes_any_type_check
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (error : String)
    (failed : psKernelExprV2MutualStageRecursorsWorker plan.infos environment parent = .error error) :
    psKernelExprV2MutualCheckRecursorsWith check whnf defeq fuel environment depth maxNat unsafeFlag parent plan =
      some (.error error) := by
  simp only [psKernelExprV2MutualCheckRecursorsWith, failed]

theorem task_failure_returns_no_successful_private_environment
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (staged : PsKernelExprV2MutualStagedRecursors) (error : String)
    (a : psKernelExprV2MutualStageRecursorsWorker plan.infos environment parent = .ok staged)
    (b : psKernelExprV2MutualCheckRecursorTasksWorker staged.tasks check whnf defeq fuel
      staged.environment depth maxNat unsafeFlag plan staged.owner 0 = some (.error error)) :
    psKernelExprV2MutualCheckRecursorsWith check whnf defeq fuel environment depth maxNat unsafeFlag parent plan =
      some (.error error) := by
  simp only [psKernelExprV2MutualCheckRecursorsWith, a, b]

theorem all_task_success_returns_exact_final_staged_environment_and_owner
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent finalOwner : PsKernelDagGeneratedState) (staged : PsKernelExprV2MutualStagedRecursors)
    (a : psKernelExprV2MutualStageRecursorsWorker plan.infos environment parent = .ok staged)
    (b : psKernelExprV2MutualCheckRecursorTasksWorker staged.tasks check whnf defeq fuel
      staged.environment depth maxNat unsafeFlag plan staged.owner 0 = some (.ok finalOwner)) :
    psKernelExprV2MutualCheckRecursorsWith check whnf defeq fuel environment depth maxNat unsafeFlag parent plan =
      some (.ok (PsKernelExprV2OrdinaryAdmissionResult.mk staged.environment finalOwner)) := by
  simp only [psKernelExprV2MutualCheckRecursorsWith, a, b]

theorem actual_wrapper_uses_owned_check_whnf_and_defeq_callbacks
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) :
    psKernelExprV2MutualCheckRecursorsWithFuel fuel environment depth maxNat unsafeFlag parent plan =
      psKernelExprV2MutualCheckRecursorsWith psKernelExprV2TryCheckStateWithFuel
        psKernelExprV2TryWhnfCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
        fuel environment depth maxNat unsafeFlag parent plan := rfl

theorem task_check_decline_precedes_sort_and_rules
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat)
    (task : PsKernelExprV2MutualRecursorTask) (later : List PsKernelExprV2MutualRecursorTask)
    (failed : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) (psKernelExprV2OrdinaryFreshState parent) task.type = none) :
    psKernelExprV2MutualCheckRecursorTasksWorker (task :: later) check whnf defeq fuel environment depth maxNat unsafeFlag plan parent index = none := by
  simp only [psKernelExprV2MutualCheckRecursorTasksWorker, failed]

theorem task_sort_decline_precedes_rule_checks
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat)
    (task : PsKernelExprV2MutualRecursorTask) (later : List PsKernelExprV2MutualRecursorTask)
    (next : PsKernelExprV2CheckState) (type : Nat) 
    (checked : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) (psKernelExprV2OrdinaryFreshState parent) task.type = some (.ok (next,type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) next type = none) :
    psKernelExprV2MutualCheckRecursorTasksWorker (task :: later) check whnf defeq fuel environment depth maxNat unsafeFlag plan parent index = none := by
  simp only [psKernelExprV2MutualCheckRecursorTasksWorker, checked, sorted]

theorem task_sort_error_precedes_rule_checks
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat)
    (task : PsKernelExprV2MutualRecursorTask) (later : List PsKernelExprV2MutualRecursorTask)
    (next : PsKernelExprV2CheckState) (type : Nat) (error : String)
    (checked : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) (psKernelExprV2OrdinaryFreshState parent) task.type = some (.ok (next,type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) next type = some (.error error)) :
    psKernelExprV2MutualCheckRecursorTasksWorker (task :: later) check whnf defeq fuel environment depth maxNat unsafeFlag plan parent index = some (.error error) := by
  simp only [psKernelExprV2MutualCheckRecursorTasksWorker, checked, sorted]

theorem task_rules_decline_precedes_next_fresh_task
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat)
    (task : PsKernelExprV2MutualRecursorTask) (later : List PsKernelExprV2MutualRecursorTask)
    (next sortedState : PsKernelExprV2CheckState) (type : Nat) (sortLevel : PsKernelLevel)
    
    (checked : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) (psKernelExprV2OrdinaryFreshState parent) task.type = some (.ok (next,type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) next type = some (.ok (sortedState,sortLevel)))
    (rules : psKernelExprV2MutualValidateRulesWith check defeq fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) sortedState parent.built plan index task.rules = none) :
    psKernelExprV2MutualCheckRecursorTasksWorker (task :: later) check whnf defeq fuel environment depth maxNat unsafeFlag plan parent index = none := by
  simp only [psKernelExprV2MutualCheckRecursorTasksWorker, checked, sorted, rules]

theorem task_rules_error_precedes_next_fresh_task
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat)
    (task : PsKernelExprV2MutualRecursorTask) (later : List PsKernelExprV2MutualRecursorTask)
    (next sortedState : PsKernelExprV2CheckState) (type : Nat) (sortLevel : PsKernelLevel)
    (error : String)
    (checked : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) (psKernelExprV2OrdinaryFreshState parent) task.type = some (.ok (next,type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) next type = some (.ok (sortedState,sortLevel)))
    (rules : psKernelExprV2MutualValidateRulesWith check defeq fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) sortedState parent.built plan index task.rules = some (.error error)) :
    psKernelExprV2MutualCheckRecursorTasksWorker (task :: later) check whnf defeq fuel environment depth maxNat unsafeFlag plan parent index = some (.error error) := by
  simp only [psKernelExprV2MutualCheckRecursorTasksWorker, checked, sorted, rules]

theorem task_resume_error_uses_authoritative_refs_and_fixed_fuel
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat)
    (task : PsKernelExprV2MutualRecursorTask) (later : List PsKernelExprV2MutualRecursorTask)
    (next sortedState : PsKernelExprV2CheckState) (type : Nat) (sortLevel : PsKernelLevel)
    (checkedRules : PsKernelExprV2OrdinaryRuleState) (error : String)
    (checked : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) (psKernelExprV2OrdinaryFreshState parent) task.type = some (.ok (next,type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) next type = some (.ok (sortedState,sortLevel)))
    (rules : psKernelExprV2MutualValidateRulesWith check defeq fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) sortedState parent.built plan index task.rules = some (.ok checkedRules))
    (resumed : psKernelExprV2MutualResumeRecursorOwner parent.declarations checkedRules = .error error) :
    psKernelExprV2MutualCheckRecursorTasksWorker (task :: later) check whnf defeq fuel environment depth maxNat unsafeFlag plan parent index = some (.error error) := by
  simp only [psKernelExprV2MutualCheckRecursorTasksWorker, checked, sorted, rules, resumed]

theorem task_resume_success_uses_authoritative_refs_and_fixed_fuel
    (environment : PsKernelEnvironment) (depth maxNat : Nat) (unsafeFlag : Bool)
    (parent : PsKernelDagGeneratedState) (index : Nat)
    (task : PsKernelExprV2MutualRecursorTask) (later : List PsKernelExprV2MutualRecursorTask)
    (next sortedState : PsKernelExprV2CheckState) (type : Nat) (sortLevel : PsKernelLevel)
    (checkedRules : PsKernelExprV2OrdinaryRuleState) (nextOwner : PsKernelDagGeneratedState)
    (checked : check fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) (psKernelExprV2OrdinaryFreshState parent) task.type = some (.ok (next,type)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) next type = some (.ok (sortedState,sortLevel)))
    (rules : psKernelExprV2MutualValidateRulesWith check defeq fuel (psKernelExprV2OrdinaryFreshContext environment plan.recLevelParams unsafeFlag depth maxNat) sortedState parent.built plan index task.rules = some (.ok checkedRules))
    (resumed : psKernelExprV2MutualResumeRecursorOwner parent.declarations checkedRules = .ok nextOwner) :
    psKernelExprV2MutualCheckRecursorTasksWorker (task :: later) check whnf defeq fuel environment depth maxNat unsafeFlag plan parent index = psKernelExprV2MutualCheckRecursorTasksWorker later check whnf defeq fuel environment depth maxNat unsafeFlag plan nextOwner (Nat.succ index) := by
  simp only [psKernelExprV2MutualCheckRecursorTasksWorker, checked, sorted, rules, resumed]

#print axioms empty_shapes_and_rules_keep_exact_owner_even_at_zero
#print axioms extra_pending_rule_is_original_count_error
#print axioms nonowner_shape_skips_callbacks_and_preserves_pending_and_fuel
#print axioms matching_shape_requires_rule_before_check
#print axioms rule_check_decline_precedes_expected_syntax
#print axioms rule_check_error_precedes_expected_syntax
#print axioms expected_syntax_error_uses_checked_owner_before_defeq
#print axioms rule_defeq_decline_preserves_original_result
#print axioms rule_defeq_error_preserves_original_result
#print axioms rule_defeq_false_preserves_original_result
#print axioms rule_success_threads_whole_owner_and_known_decoded_prefix_at_fixed_fuel
#print axioms empty_staging_keeps_exact_private_environment_and_owner
#print axioms staging_type_import_error_precedes_rule_import_and_metadata
#print axioms staging_rule_import_error_precedes_metadata
#print axioms staging_success_binds_exact_live_metadata_type_root_and_rule_refs
#print axioms staging_tail_error_returns_no_partial_environment
#print axioms staging_keeps_task_family_source_order
#print axioms resuming_next_fresh_owner_keeps_only_arena_prefix_and_authoritative_refs
#print axioms empty_tasks_succeed_at_zero_without_checking
#print axioms task_check_error_precedes_mandatory_sort_and_rules
#print axioms all_staging_precedes_any_type_check
#print axioms task_failure_returns_no_successful_private_environment
#print axioms all_task_success_returns_exact_final_staged_environment_and_owner
#print axioms actual_wrapper_uses_owned_check_whnf_and_defeq_callbacks
#print axioms task_check_decline_precedes_sort_and_rules
#print axioms task_sort_decline_precedes_rule_checks
#print axioms task_sort_error_precedes_rule_checks
#print axioms task_rules_decline_precedes_next_fresh_task
#print axioms task_rules_error_precedes_next_fresh_task
#print axioms task_resume_error_uses_authoritative_refs_and_fixed_fuel
#print axioms task_resume_success_uses_authoritative_refs_and_fixed_fuel
end PsKernelMutualRecursorValidationProofs
