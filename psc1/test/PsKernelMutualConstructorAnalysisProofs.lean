import Lean
import Ps.KernelCore.API.DagMutualConstructorAnalysis

/-
Universal phase-order and ownership equations for private single-constructor
analysis. Component premises describe static guards, callbacks and subordinate
workers; no premise assumes the result of the composed analysis.
The canonical-arena and established provisional-owner boundary remains explicit.
These local equations are not whole-admission soundness or publication proofs.
-/
namespace PsKernelMutualConstructorAnalysisProofs

abbrev CheckCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat))

abbrev DefEqCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool))

variable (check whnf : CheckCallback) (defeq : DefEqCallback) (phaseFuel : Nat)
variable (context : PsKernelExprV2CheckContext)
variable (header closed next : PsKernelExprV2CheckState)
variable (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
variable (owner : Nat) (levels : List PsKernelLevel)
variable (parameters : List PsKernelExprV2OrdinaryOpenBinder)
variable (resultLevel level : PsKernelLevel) (ctor : PsKernelDagConstructor)
variable (checkedType openedType : Nat) (error : String)

theorem closed_context_is_fresh_and_retains_established_declaration_inputs :
    (psKernelExprV2OrdinaryClosedConstructorContext context).locals = List.nil ∧
    (psKernelExprV2OrdinaryClosedConstructorContext context).scalar.localContext =
      psKernelLocalContextEmpty ∧
    (psKernelExprV2OrdinaryClosedConstructorContext context).scalar.environment =
      context.scalar.environment ∧
    (psKernelExprV2OrdinaryClosedConstructorContext context).scalar.levelParams =
      context.scalar.levelParams ∧
    (psKernelExprV2OrdinaryClosedConstructorContext context).scalar.safety =
      context.scalar.safety ∧
    (psKernelExprV2OrdinaryClosedConstructorContext context).scalar.maxRecDepth =
      context.scalar.maxRecDepth ∧
    (psKernelExprV2OrdinaryClosedConstructorContext context).scalar.maxNatSize =
      context.scalar.maxNatSize ∧
    (psKernelExprV2OrdinaryClosedConstructorContext context).scalar.recDepth = 0 ∧
    (psKernelExprV2OrdinaryClosedConstructorContext context).scalar.eagerReduce = false := by
  exact ⟨rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl, rfl⟩

theorem closed_state_is_fresh_with_same_arena_and_owned_references :
    psKernelExprV2OrdinaryClosedConstructorState header =
      PsKernelExprV2CheckState.mk
        (PsKernelExprV2WhnfState.mk header.whnf.arena List.nil List.nil
          header.whnf.declarations)
        0 List.nil List.nil List.nil List.nil List.nil := by
  rfl

theorem resume_retains_only_closed_arena_and_every_original_semantic_field :
    psKernelExprV2OrdinaryResumeConstructorState header closed =
      PsKernelExprV2CheckState.mk
        (PsKernelExprV2WhnfState.mk closed.whnf.arena header.whnf.coreCache
          header.whnf.publicCache header.whnf.declarations)
        header.nextFresh header.checkedInfer header.success header.inferOnly
        header.unfold header.failure := by
  rfl

/- A local-scope exit would retain the greater child freshness. This independent
   closed-check fork deliberately resumes the original header freshness. -/
theorem resume_discards_closed_freshness_even_when_it_grew
    (growth : header.nextFresh < closed.nextFresh) :
    (psKernelExprV2OrdinaryResumeConstructorState header closed).nextFresh <
      closed.nextFresh := by
  exact growth

theorem result_validation_error_precedes_shape_return
    (opened : PsKernelExprV2MutualOpenFieldsResult)
    (validated : psKernelExprV2MutualValidateConstructorResult
      opened.state.whnf.arena targets types owner levels parameters opened.result =
        Except.error error) :
    psKernelExprV2MutualFinishConstructorAnalysis
        targets types owner levels parameters ctor opened =
      Except.error error := by
  simp only [psKernelExprV2MutualFinishConstructorAnalysis, validated]

theorem result_validation_success_retains_exact_shape_and_complete_owner
    (opened : PsKernelExprV2MutualOpenFieldsResult) (indices : List Nat)
    (validated : psKernelExprV2MutualValidateConstructorResult
      opened.state.whnf.arena targets types owner levels parameters opened.result =
        Except.ok indices) :
    psKernelExprV2MutualFinishConstructorAnalysis
        targets types owner levels parameters ctor opened =
      Except.ok
        (PsKernelExprV2MutualConstructorAnalysis.mk opened.context opened.state
          (PsKernelExprV2MutualConstructorShape.mk
            owner ctor opened.fields opened.recursiveFields indices)) := by
  simp only [psKernelExprV2MutualFinishConstructorAnalysis, validated]

theorem static_error_precedes_fresh_owner_and_all_callbacks
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.error error) :
    psKernelExprV2MutualAnalyzeConstructorWith check whnf defeq phaseFuel
        context header targets types owner levels parameters resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualAnalyzeConstructorWith, guard]

theorem closed_check_decline_precedes_sort_and_opening
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type = Option.none) :
    psKernelExprV2MutualAnalyzeConstructorWith check whnf defeq phaseFuel
        context header targets types owner levels parameters resultLevel ctor =
      Option.none := by
  simp only [psKernelExprV2MutualAnalyzeConstructorWith, guard, checked]

theorem closed_check_error_precedes_sort_and_opening
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type =
        Option.some (Except.error error)) :
    psKernelExprV2MutualAnalyzeConstructorWith check whnf defeq phaseFuel
        context header targets types owner levels parameters resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualAnalyzeConstructorWith, guard, checked]

theorem mandatory_sort_uses_closed_returned_owner_and_unchanged_phase_fuel
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type =
        Option.some (Except.ok (Prod.mk next checkedType))) :
    psKernelExprV2MutualAnalyzeConstructorWith check whnf defeq phaseFuel
        context header targets types owner levels parameters resultLevel ctor =
      match psKernelExprV2AdmissionEnsureSortOwnedWith
          (whnf phaseFuel) (psKernelExprV2OrdinaryClosedConstructorContext context)
          next checkedType with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error message => Option.some (Except.error message)
          | Except.ok sorted =>
              psKernelExprV2MutualConstructorAfterClosedWith
                check whnf defeq phaseFuel context header (Prod.fst sorted)
                targets types owner levels parameters resultLevel ctor := by
  simp only [psKernelExprV2MutualAnalyzeConstructorWith, guard, checked] <;> rfl

theorem mandatory_sort_decline_precedes_parameter_owner_resume
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type =
        Option.some (Except.ok (Prod.mk next checkedType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf phaseFuel) (psKernelExprV2OrdinaryClosedConstructorContext context)
      next checkedType = Option.none) :
    psKernelExprV2MutualAnalyzeConstructorWith check whnf defeq phaseFuel
        context header targets types owner levels parameters resultLevel ctor =
      Option.none := by
  simp only [psKernelExprV2MutualAnalyzeConstructorWith, guard, checked, sorted]

theorem mandatory_sort_error_precedes_parameter_owner_resume
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type =
        Option.some (Except.ok (Prod.mk next checkedType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf phaseFuel) (psKernelExprV2OrdinaryClosedConstructorContext context)
      next checkedType = Option.some (Except.error error)) :
    psKernelExprV2MutualAnalyzeConstructorWith check whnf defeq phaseFuel
        context header targets types owner levels parameters resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualAnalyzeConstructorWith, guard, checked, sorted]

theorem mandatory_sort_success_resumes_header_against_final_closed_owner
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type =
        Option.some (Except.ok (Prod.mk next checkedType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf phaseFuel) (psKernelExprV2OrdinaryClosedConstructorContext context)
      next checkedType = Option.some (Except.ok (Prod.mk closed level))) :
    psKernelExprV2MutualAnalyzeConstructorWith check whnf defeq phaseFuel
        context header targets types owner levels parameters resultLevel ctor =
      psKernelExprV2MutualConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed targets types owner levels parameters resultLevel ctor := by
  simp only [psKernelExprV2MutualAnalyzeConstructorWith, guard, checked, sorted]

theorem parameter_decline_uses_resumed_owner_and_original_constructor_type
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.none) :
    psKernelExprV2MutualConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed targets types owner levels parameters resultLevel ctor =
      Option.none := by
  simp only [psKernelExprV2MutualConstructorAfterClosedWith, opened]

theorem parameter_error_precedes_fields_and_result_validation
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.some (Except.error error)) :
    psKernelExprV2MutualConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed targets types owner levels parameters resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualConstructorAfterClosedWith, opened]

theorem field_decline_uses_complete_parameter_owner_and_same_phase_fuel
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.some (Except.ok (Prod.mk next openedType)))
    (fields : psKernelExprV2MutualOpenConstructorFieldsWith
      check whnf phaseFuel context next targets types levels parameters
      resultLevel openedType = Option.none) :
    psKernelExprV2MutualConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed targets types owner levels parameters resultLevel ctor =
      Option.none := by
  simp only [psKernelExprV2MutualConstructorAfterClosedWith, opened, fields]

theorem field_error_precedes_result_validation
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.some (Except.ok (Prod.mk next openedType)))
    (fields : psKernelExprV2MutualOpenConstructorFieldsWith
      check whnf phaseFuel context next targets types levels parameters
      resultLevel openedType = Option.some (Except.error error)) :
    psKernelExprV2MutualConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed targets types owner levels parameters resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualConstructorAfterClosedWith, opened, fields]

theorem field_success_validates_original_result_with_final_field_owner
    (fieldResult : PsKernelExprV2MutualOpenFieldsResult)
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.some (Except.ok (Prod.mk next openedType)))
    (fields : psKernelExprV2MutualOpenConstructorFieldsWith
      check whnf phaseFuel context next targets types levels parameters
      resultLevel openedType = Option.some (Except.ok fieldResult)) :
    psKernelExprV2MutualConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed targets types owner levels parameters resultLevel ctor =
      Option.some
        (psKernelExprV2MutualFinishConstructorAnalysis
          targets types owner levels parameters ctor fieldResult) := by
  simp only [psKernelExprV2MutualConstructorAfterClosedWith, opened, fields]

theorem actual_wrapper_selects_checked_callbacks_without_outer_fuel_change :
    psKernelExprV2MutualAnalyzeConstructorWithFuel phaseFuel
        context header targets types owner levels parameters resultLevel ctor =
      psKernelExprV2MutualAnalyzeConstructorWith
        psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
        psKernelExprV2TryDefEqStateWithFuel phaseFuel
        context header targets types owner levels parameters resultLevel ctor := by
  rfl

theorem invalid_family_result_precedes_owner_comparison
    (arena : PsKernelExprV2PagedArena) (root : Nat)
    (absent : psKernelExprV2MutualAppInfoOnCanonical arena targets types levels parameters root = .ok none) :
    psKernelExprV2MutualValidateConstructorResult arena targets types owner levels parameters root =
      .error "mutual constructor has invalid return type" := by
  simp only [psKernelExprV2MutualValidateConstructorResult, absent]

theorem wrong_family_has_distinct_error
    (arena : PsKernelExprV2PagedArena) (root : Nat) (info : PsKernelExprV2MutualAppInfo)
    (selected : psKernelExprV2MutualAppInfoOnCanonical arena targets types levels parameters root = .ok (some info))
    (wrong : Nat.beq info.target owner = false) :
    psKernelExprV2MutualValidateConstructorResult arena targets types owner levels parameters root =
      .error "mutual constructor returns the wrong datatype" := by
  simp only [psKernelExprV2MutualValidateConstructorResult, selected, wrong] <;> rfl

theorem matching_family_retains_original_index_ids
    (arena : PsKernelExprV2PagedArena) (root : Nat) (info : PsKernelExprV2MutualAppInfo)
    (selected : psKernelExprV2MutualAppInfoOnCanonical arena targets types levels parameters root = .ok (some info))
    (matching : Nat.beq info.target owner = true) :
    psKernelExprV2MutualValidateConstructorResult arena targets types owner levels parameters root =
      .ok info.indices := by
  simp only [psKernelExprV2MutualValidateConstructorResult, selected, matching] <;> rfl

#print axioms closed_context_is_fresh_and_retains_established_declaration_inputs
#print axioms closed_state_is_fresh_with_same_arena_and_owned_references
#print axioms resume_retains_only_closed_arena_and_every_original_semantic_field
#print axioms resume_discards_closed_freshness_even_when_it_grew
#print axioms result_validation_error_precedes_shape_return
#print axioms result_validation_success_retains_exact_shape_and_complete_owner
#print axioms static_error_precedes_fresh_owner_and_all_callbacks
#print axioms closed_check_decline_precedes_sort_and_opening
#print axioms closed_check_error_precedes_sort_and_opening
#print axioms mandatory_sort_uses_closed_returned_owner_and_unchanged_phase_fuel
#print axioms mandatory_sort_decline_precedes_parameter_owner_resume
#print axioms mandatory_sort_error_precedes_parameter_owner_resume
#print axioms mandatory_sort_success_resumes_header_against_final_closed_owner
#print axioms parameter_decline_uses_resumed_owner_and_original_constructor_type
#print axioms parameter_error_precedes_fields_and_result_validation
#print axioms field_decline_uses_complete_parameter_owner_and_same_phase_fuel
#print axioms field_error_precedes_result_validation
#print axioms field_success_validates_original_result_with_final_field_owner
#print axioms actual_wrapper_selects_checked_callbacks_without_outer_fuel_change

#print axioms invalid_family_result_precedes_owner_comparison
#print axioms wrong_family_has_distinct_error
#print axioms matching_family_retains_original_index_ids
end PsKernelMutualConstructorAnalysisProofs
