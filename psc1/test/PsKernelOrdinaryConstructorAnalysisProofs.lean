import Lean
import Ps.KernelCore.API.DagOrdinaryConstructorAnalysis

/-
Universal phase-order and ownership equations for private single-constructor
analysis. Component premises describe static guards, callbacks and subordinate
workers; no premise assumes the result of the composed analysis.
The canonical-arena and established provisional-owner boundary remains explicit.
These local equations are not whole-admission soundness or publication proofs.
-/
namespace PsKernelOrdinaryConstructorAnalysisProofs

abbrev CheckCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat))

abbrev DefEqCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Bool))

variable (check whnf : CheckCallback) (defeq : DefEqCallback) (phaseFuel : Nat)
variable (context : PsKernelExprV2CheckContext)
variable (header closed next : PsKernelExprV2CheckState)
variable (target : PsKernelName) (levels : List PsKernelLevel)
variable (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices : Nat)
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
    (opened : PsKernelExprV2OrdinaryOpenFieldsResult)
    (validated : psKernelExprV2OrdinaryValidateConstructorResult
      opened.state.whnf.arena target levels parameters numIndices opened.result =
        Except.error error) :
    psKernelExprV2OrdinaryFinishConstructorAnalysis
        target levels parameters numIndices ctor opened =
      Except.error error := by
  simp only [psKernelExprV2OrdinaryFinishConstructorAnalysis, validated]

theorem result_validation_success_retains_exact_shape_and_complete_owner
    (opened : PsKernelExprV2OrdinaryOpenFieldsResult) (indices : List Nat)
    (validated : psKernelExprV2OrdinaryValidateConstructorResult
      opened.state.whnf.arena target levels parameters numIndices opened.result =
        Except.ok indices) :
    psKernelExprV2OrdinaryFinishConstructorAnalysis
        target levels parameters numIndices ctor opened =
      Except.ok
        (PsKernelExprV2OrdinaryConstructorAnalysis.mk opened.context opened.state
          (PsKernelExprV2OrdinaryConstructorShape.mk
            ctor opened.fields opened.recursiveFields indices)) := by
  simp only [psKernelExprV2OrdinaryFinishConstructorAnalysis, validated]

theorem static_error_precedes_fresh_owner_and_all_callbacks
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.error error) :
    psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf defeq phaseFuel
        context header target levels parameters numIndices resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeConstructorWith, guard]

theorem closed_check_decline_precedes_sort_and_opening
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type = Option.none) :
    psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf defeq phaseFuel
        context header target levels parameters numIndices resultLevel ctor =
      Option.none := by
  simp only [psKernelExprV2OrdinaryAnalyzeConstructorWith, guard, checked]

theorem closed_check_error_precedes_sort_and_opening
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type =
        Option.some (Except.error error)) :
    psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf defeq phaseFuel
        context header target levels parameters numIndices resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeConstructorWith, guard, checked]

theorem mandatory_sort_uses_closed_returned_owner_and_unchanged_phase_fuel
    (guard : psKernelExprV2AdmissionStaticOnCanonical
      header.whnf.arena ctor.type context.scalar.levelParams = Except.ok ())
    (checked : check phaseFuel
      (psKernelExprV2OrdinaryClosedConstructorContext context)
      (psKernelExprV2OrdinaryClosedConstructorState header) ctor.type =
        Option.some (Except.ok (Prod.mk next checkedType))) :
    psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf defeq phaseFuel
        context header target levels parameters numIndices resultLevel ctor =
      match psKernelExprV2AdmissionEnsureSortOwnedWith
          (whnf phaseFuel) (psKernelExprV2OrdinaryClosedConstructorContext context)
          next checkedType with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error message => Option.some (Except.error message)
          | Except.ok sorted =>
              psKernelExprV2OrdinaryConstructorAfterClosedWith
                check whnf defeq phaseFuel context header (Prod.fst sorted)
                target levels parameters numIndices resultLevel ctor := by
  simp only [psKernelExprV2OrdinaryAnalyzeConstructorWith, guard, checked] <;> rfl

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
    psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf defeq phaseFuel
        context header target levels parameters numIndices resultLevel ctor =
      Option.none := by
  simp only [psKernelExprV2OrdinaryAnalyzeConstructorWith, guard, checked, sorted]

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
    psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf defeq phaseFuel
        context header target levels parameters numIndices resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeConstructorWith, guard, checked, sorted]

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
    psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf defeq phaseFuel
        context header target levels parameters numIndices resultLevel ctor =
      psKernelExprV2OrdinaryConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed target levels parameters numIndices resultLevel ctor := by
  simp only [psKernelExprV2OrdinaryAnalyzeConstructorWith, guard, checked, sorted]

theorem parameter_decline_uses_resumed_owner_and_original_constructor_type
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.none) :
    psKernelExprV2OrdinaryConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed target levels parameters numIndices resultLevel ctor =
      Option.none := by
  simp only [psKernelExprV2OrdinaryConstructorAfterClosedWith, opened]

theorem parameter_error_precedes_fields_and_result_validation
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.some (Except.error error)) :
    psKernelExprV2OrdinaryConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed target levels parameters numIndices resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryConstructorAfterClosedWith, opened]

theorem field_decline_uses_complete_parameter_owner_and_same_phase_fuel
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.some (Except.ok (Prod.mk next openedType)))
    (fields : psKernelExprV2OrdinaryOpenConstructorFieldsWith
      check whnf phaseFuel context next target levels parameters numIndices
      resultLevel openedType = Option.none) :
    psKernelExprV2OrdinaryConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed target levels parameters numIndices resultLevel ctor =
      Option.none := by
  simp only [psKernelExprV2OrdinaryConstructorAfterClosedWith, opened, fields]

theorem field_error_precedes_result_validation
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.some (Except.ok (Prod.mk next openedType)))
    (fields : psKernelExprV2OrdinaryOpenConstructorFieldsWith
      check whnf phaseFuel context next target levels parameters numIndices
      resultLevel openedType = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed target levels parameters numIndices resultLevel ctor =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryConstructorAfterClosedWith, opened, fields]

theorem field_success_validates_original_result_with_final_field_owner
    (fieldResult : PsKernelExprV2OrdinaryOpenFieldsResult)
    (opened : psKernelExprV2OrdinaryOpenConstructorParamsWith
      defeq phaseFuel context
      (psKernelExprV2OrdinaryResumeConstructorState header closed) parameters ctor.type =
        Option.some (Except.ok (Prod.mk next openedType)))
    (fields : psKernelExprV2OrdinaryOpenConstructorFieldsWith
      check whnf phaseFuel context next target levels parameters numIndices
      resultLevel openedType = Option.some (Except.ok fieldResult)) :
    psKernelExprV2OrdinaryConstructorAfterClosedWith check whnf defeq phaseFuel
        context header closed target levels parameters numIndices resultLevel ctor =
      Option.some
        (psKernelExprV2OrdinaryFinishConstructorAnalysis
          target levels parameters numIndices ctor fieldResult) := by
  simp only [psKernelExprV2OrdinaryConstructorAfterClosedWith, opened, fields]

theorem actual_wrapper_selects_checked_callbacks_without_outer_fuel_change :
    psKernelExprV2OrdinaryAnalyzeConstructorWithFuel phaseFuel
        context header target levels parameters numIndices resultLevel ctor =
      psKernelExprV2OrdinaryAnalyzeConstructorWith
        psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
        psKernelExprV2TryDefEqStateWithFuel phaseFuel
        context header target levels parameters numIndices resultLevel ctor := by
  rfl

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

end PsKernelOrdinaryConstructorAnalysisProofs
