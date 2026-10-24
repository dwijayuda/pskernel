import Lean
import Ps.KernelCore.API.DagOrdinaryConstructorFields

/-
Universal field-worker fuel, callback-order and complete-owner equations.
Premises describe component results, not the conclusion of the composed
worker. They preserve the explicit canonical-arena boundary and do not claim
whole admission equivalence, positivity completeness or external replay.
-/
namespace PsKernelOrdinaryConstructorFieldsProofs

abbrev CheckCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat))

abbrev AnalyzeCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
    Nat -> Nat -> Option (Except String PsKernelExprV2OrdinaryRecursiveArgumentResult)

variable (check whnf : CheckCallback) (analyze : AnalyzeCallback) (fuel : Nat)
variable (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
variable (target : PsKernelName) (levels : List PsKernelLevel)
variable (parameters revFields : List PsKernelExprV2OrdinaryOpenBinder)
variable (revRecursive : List PsKernelExprV2OrdinaryRecursiveField)
variable (numIndices type : Nat) (resultLevel : PsKernelLevel)
variable (userName : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo)

theorem zero_fuel_precedes_lookup_and_every_callback :
    psKernelExprV2OrdinaryOpenConstructorFieldsWorker 0 check whnf analyze
        context state target levels parameters numIndices resultLevel type
        revFields revRecursive =
      Option.some (Except.error "simple inductive field budget exhausted") := by
  rfl

theorem lookup_error_precedes_field_callbacks
    (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.error error) :
    psKernelExprV2OrdinaryOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state target levels parameters numIndices resultLevel type
        revFields revRecursive = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorFieldsWorker, found]

theorem syntactic_nonforall_finishes_without_whnf_or_body_change
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (notForall : ∀ name dom cod info,
      entry.node ≠ PsKernelExprV2Node.forallE name dom cod info) :
    psKernelExprV2OrdinaryOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state target levels parameters numIndices resultLevel type
        revFields revRecursive =
      Option.some (Except.ok
        (PsKernelExprV2OrdinaryOpenFieldsResult.mk context state
          (psKernelExprV2OrdinaryReverseOpenBinders revFields)
          (psKernelExprV2OrdinaryReverseRecursiveFields revRecursive) type)) := by
  cases node : entry.node <;>
    first
    | exact False.elim (notForall _ _ _ _ node)
    | simp only [psKernelExprV2OrdinaryOpenConstructorFieldsWorker, found, node]

theorem field_step_decline_uses_predecessor_fuel
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (stepped : psKernelExprV2OrdinaryOpenConstructorFieldWith check whnf analyze fuel
      context state target levels parameters numIndices resultLevel
      userName domain body binderInfo = Option.none) :
    psKernelExprV2OrdinaryOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state target levels parameters numIndices resultLevel type
        revFields revRecursive = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenConstructorFieldsWorker, found, node, stepped]

theorem field_step_error_precedes_next_field
    (entry : PsKernelExprV2Entry) (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (stepped : psKernelExprV2OrdinaryOpenConstructorFieldWith check whnf analyze fuel
      context state target levels parameters numIndices resultLevel
      userName domain body binderInfo = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state target levels parameters numIndices resultLevel type
        revFields revRecursive = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorFieldsWorker, found, node, stepped]

theorem field_step_success_threads_complete_owner_and_ordered_descriptors
    (entry : PsKernelExprV2Entry) (opened : PsKernelExprV2OrdinaryOpenedField)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (stepped : psKernelExprV2OrdinaryOpenConstructorFieldWith check whnf analyze fuel
      context state target levels parameters numIndices resultLevel
      userName domain body binderInfo = Option.some (Except.ok opened)) :
    psKernelExprV2OrdinaryOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state target levels parameters numIndices resultLevel type
        revFields revRecursive =
      psKernelExprV2OrdinaryOpenConstructorFieldsWorker fuel check whnf analyze
        opened.context opened.state target levels parameters numIndices resultLevel
        opened.body (List.cons opened.field revFields)
        (match opened.recursiveField with
          | Option.none => revRecursive
          | Option.some recursiveField => List.cons recursiveField revRecursive) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorFieldsWorker, found, node, stepped] <;> rfl

theorem prepare_check_decline_precedes_whnf_and_local_allocation
    (checked : check fuel context state domain = Option.none) :
    psKernelExprV2OrdinaryPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo = Option.none := by
  simp only [psKernelExprV2OrdinaryPrepareFieldWith, checked]

theorem prepare_check_error_precedes_whnf_and_local_allocation
    (error : String)
    (checked : check fuel context state domain = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryPrepareFieldWith, checked]

theorem prepare_mandatory_sort_uses_checked_owner_and_type
    (checkedState : PsKernelExprV2CheckState) (checkedType : Nat)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk checkedState checkedType))) :
    psKernelExprV2OrdinaryPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo =
      match psKernelExprV2AdmissionEnsureSortOwnedWith
          (whnf fuel) context checkedState checkedType with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok sorted =>
              Option.some (psKernelExprV2OrdinaryPrepareFieldAfterSort
                context sorted resultLevel userName domain binderInfo) := by
  simp only [psKernelExprV2OrdinaryPrepareFieldWith, checked] <;> rfl

theorem prepare_sort_decline_precedes_universe_and_annotations
    (checkedState : PsKernelExprV2CheckState) (checkedType : Nat)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk checkedState checkedType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context checkedState checkedType = Option.none) :
    psKernelExprV2OrdinaryPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo = Option.none := by
  simp only [psKernelExprV2OrdinaryPrepareFieldWith, checked, sorted]

theorem prepare_sort_error_precedes_universe_and_annotations
    (checkedState : PsKernelExprV2CheckState) (checkedType : Nat) (error : String)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk checkedState checkedType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context checkedState checkedType = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryPrepareFieldWith, checked, sorted]

theorem universe_rejection_precedes_annotations_and_freshness
    (fieldLevel : PsKernelLevel)
    (tooLarge : psKernelLevelLe fieldLevel resultLevel = false)
    (notProp : psKernelLevelNormalizesToZero resultLevel = false) :
    psKernelExprV2OrdinaryPrepareFieldAfterSort context (Prod.mk state fieldLevel)
        resultLevel userName domain binderInfo =
      Except.error "simple inductive constructor field universe is too large" := by
  simp only [psKernelExprV2OrdinaryPrepareFieldAfterSort, tooLarge, notProp] <;> rfl

theorem annotation_error_precedes_local_allocation
    (fieldLevel : PsKernelLevel) (error : String)
    (allowed : (if psKernelLevelLe fieldLevel resultLevel then true
      else psKernelLevelNormalizesToZero resultLevel) = true)
    (annotations : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      state.whnf.arena domain = Except.error error) :
    psKernelExprV2OrdinaryPrepareFieldAfterSort context (Prod.mk state fieldLevel)
        resultLevel userName domain binderInfo = Except.error error := by
  simp only [psKernelExprV2OrdinaryPrepareFieldAfterSort, allowed, annotations] <;> rfl

theorem prop_universe_exception_still_consumes_annotations
    (fieldLevel : PsKernelLevel) (error : String)
    (tooLarge : psKernelLevelLe fieldLevel resultLevel = false)
    (isProp : psKernelLevelNormalizesToZero resultLevel = true)
    (annotations : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      state.whnf.arena domain = Except.error error) :
    psKernelExprV2OrdinaryPrepareFieldAfterSort context (Prod.mk state fieldLevel)
        resultLevel userName domain binderInfo = Except.error error := by
  simp only [psKernelExprV2OrdinaryPrepareFieldAfterSort, tooLarge, isProp, annotations] <;> rfl

theorem preparation_allocates_only_local_and_freshness_before_analysis
    (fieldLevel : PsKernelLevel) (localDomain : Nat)
    (allowed : (if psKernelLevelLe fieldLevel resultLevel then true
      else psKernelLevelNormalizesToZero resultLevel) = true)
    (annotations : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      state.whnf.arena domain = Except.ok localDomain) :
    psKernelExprV2OrdinaryPrepareFieldAfterSort context (Prod.mk state fieldLevel)
        resultLevel userName domain binderInfo =
      Except.ok (PsKernelExprV2OrdinaryPreparedField.mk
        (psKernelExprV2CheckContextWithLocal context
          (PsKernelName.num userName state.nextFresh) userName localDomain binderInfo)
        (PsKernelExprV2CheckState.mk state.whnf (Nat.succ state.nextFresh)
          state.checkedInfer state.success state.inferOnly state.unfold state.failure)
        (PsKernelExprV2OrdinaryOpenBinder.mk
          (PsKernelName.num userName state.nextFresh) userName localDomain binderInfo)) := by
  simp only [psKernelExprV2OrdinaryPrepareFieldAfterSort, allowed, annotations,
    psKernelExprV2CheckStateFreshName] <;> rfl

theorem analysis_decline_precedes_body_instantiation
    (prepared : PsKernelExprV2OrdinaryPreparedField)
    (ready : psKernelExprV2OrdinaryPrepareFieldWith check whnf fuel context state
      resultLevel userName domain binderInfo = Option.some (Except.ok prepared))
    (analyzed : analyze fuel prepared.context prepared.state target levels
      parameters numIndices domain = Option.none) :
    psKernelExprV2OrdinaryOpenConstructorFieldWith check whnf analyze fuel
        context state target levels parameters numIndices resultLevel
        userName domain body binderInfo = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenConstructorFieldWith, ready, analyzed]

theorem analysis_error_precedes_body_instantiation
    (prepared : PsKernelExprV2OrdinaryPreparedField) (error : String)
    (ready : psKernelExprV2OrdinaryPrepareFieldWith check whnf fuel context state
      resultLevel userName domain binderInfo = Option.some (Except.ok prepared))
    (analyzed : analyze fuel prepared.context prepared.state target levels
      parameters numIndices domain = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenConstructorFieldWith check whnf analyze fuel
        context state target levels parameters numIndices resultLevel
        userName domain body binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorFieldWith, ready, analyzed]

theorem analysis_success_uses_post_field_owner_original_domain_and_original_body
    (prepared : PsKernelExprV2OrdinaryPreparedField)
    (analysis : PsKernelExprV2OrdinaryRecursiveArgumentResult)
    (ready : psKernelExprV2OrdinaryPrepareFieldWith check whnf fuel context state
      resultLevel userName domain binderInfo = Option.some (Except.ok prepared))
    (analyzed : analyze fuel prepared.context prepared.state target levels
      parameters numIndices domain = Option.some (Except.ok analysis)) :
    psKernelExprV2OrdinaryOpenConstructorFieldWith check whnf analyze fuel
        context state target levels parameters numIndices resultLevel
        userName domain body binderInfo =
      Option.some (psKernelExprV2OrdinaryFinishField prepared analysis body) := by
  simp only [psKernelExprV2OrdinaryOpenConstructorFieldWith, ready, analyzed]

theorem body_instantiation_error_uses_retained_child_arena_and_field_name
    (prepared : PsKernelExprV2OrdinaryPreparedField)
    (analysis : PsKernelExprV2OrdinaryRecursiveArgumentResult)
    (builtArena : PsKernelExprV2PagedArena) (fvarId : Nat) (error : String)
    (built : psKernelExprV2PagedMkFVar analysis.state.whnf.arena
      prepared.field.internalName = Except.ok (Prod.mk builtArena fvarId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons fvarId List.nil))
      builtArena body 0 = Except.error error) :
    psKernelExprV2OrdinaryFinishField prepared analysis body = Except.error error := by
  simp only [psKernelExprV2OrdinaryFinishField, psKernelExprV2CheckStateExitLocalScope,
    psKernelExprV2WhnfStateWithArena, built, instantiated]

theorem finish_restores_post_field_semantics_and_keeps_child_arena_freshness
    (prepared : PsKernelExprV2OrdinaryPreparedField)
    (analysis : PsKernelExprV2OrdinaryRecursiveArgumentResult)
    (builtArena openedArena : PsKernelExprV2PagedArena) (fvarId openedBody : Nat)
    (built : psKernelExprV2PagedMkFVar analysis.state.whnf.arena
      prepared.field.internalName = Except.ok (Prod.mk builtArena fvarId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons fvarId List.nil))
      builtArena body 0 = Except.ok (Prod.mk openedArena openedBody)) :
    psKernelExprV2OrdinaryFinishField prepared analysis body =
      Except.ok (PsKernelExprV2OrdinaryOpenedField.mk
        prepared.context
        (PsKernelExprV2CheckState.mk
          (PsKernelExprV2WhnfState.mk openedArena prepared.state.whnf.coreCache
            prepared.state.whnf.publicCache prepared.state.whnf.declarations)
          (psKernelStateNatMax prepared.state.nextFresh analysis.state.nextFresh)
          prepared.state.checkedInfer prepared.state.success prepared.state.inferOnly
          prepared.state.unfold prepared.state.failure)
        prepared.field openedBody
        (match analysis.recursiveInfo with
          | Option.none => Option.none
          | Option.some info => Option.some
              (PsKernelExprV2OrdinaryRecursiveField.mk prepared.field
                (Prod.fst info) (Prod.snd info)))) := by
  simp only [psKernelExprV2OrdinaryFinishField, psKernelExprV2CheckStateExitLocalScope,
    psKernelExprV2CheckStateWithArena, psKernelExprV2CheckStateWithWhnf,
    psKernelExprV2WhnfStateWithArena, built, instantiated] <;> rfl

theorem successful_last_field_still_reaches_zero_fuel
    (entry : PsKernelExprV2Entry) (opened : PsKernelExprV2OrdinaryOpenedField)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (stepped : psKernelExprV2OrdinaryOpenConstructorFieldWith check whnf analyze 0
      context state target levels parameters numIndices resultLevel
      userName domain body binderInfo = Option.some (Except.ok opened)) :
    psKernelExprV2OrdinaryOpenConstructorFieldsWorker 1 check whnf analyze
        context state target levels parameters numIndices resultLevel type
        revFields revRecursive =
      Option.some (Except.error "simple inductive field budget exhausted") := by
  simp only [psKernelExprV2OrdinaryOpenConstructorFieldsWorker, found, node, stepped] <;> rfl

theorem wrapper_adds_one_and_uses_owned_recursive_analysis :
    psKernelExprV2OrdinaryOpenConstructorFieldsWith check whnf fuel context state
        target levels parameters numIndices resultLevel type =
      psKernelExprV2OrdinaryOpenConstructorFieldsWorker (Nat.succ fuel)
        check whnf (psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWith check whnf)
        context state target levels parameters numIndices resultLevel type
        List.nil List.nil := by
  rfl

theorem with_fuel_uses_actual_complete_owner_callbacks :
    psKernelExprV2OrdinaryOpenConstructorFieldsWithFuel fuel context state
        target levels parameters numIndices resultLevel type =
      psKernelExprV2OrdinaryOpenConstructorFieldsWith
        psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
        fuel context state target levels parameters numIndices resultLevel type := by
  rfl

#print axioms zero_fuel_precedes_lookup_and_every_callback
#print axioms lookup_error_precedes_field_callbacks
#print axioms syntactic_nonforall_finishes_without_whnf_or_body_change
#print axioms field_step_decline_uses_predecessor_fuel
#print axioms field_step_error_precedes_next_field
#print axioms field_step_success_threads_complete_owner_and_ordered_descriptors
#print axioms prepare_check_decline_precedes_whnf_and_local_allocation
#print axioms prepare_check_error_precedes_whnf_and_local_allocation
#print axioms prepare_mandatory_sort_uses_checked_owner_and_type
#print axioms prepare_sort_decline_precedes_universe_and_annotations
#print axioms prepare_sort_error_precedes_universe_and_annotations
#print axioms universe_rejection_precedes_annotations_and_freshness
#print axioms annotation_error_precedes_local_allocation
#print axioms prop_universe_exception_still_consumes_annotations
#print axioms preparation_allocates_only_local_and_freshness_before_analysis
#print axioms analysis_decline_precedes_body_instantiation
#print axioms analysis_error_precedes_body_instantiation
#print axioms analysis_success_uses_post_field_owner_original_domain_and_original_body
#print axioms body_instantiation_error_uses_retained_child_arena_and_field_name
#print axioms finish_restores_post_field_semantics_and_keeps_child_arena_freshness
#print axioms successful_last_field_still_reaches_zero_fuel
#print axioms wrapper_adds_one_and_uses_owned_recursive_analysis
#print axioms with_fuel_uses_actual_complete_owner_callbacks

end PsKernelOrdinaryConstructorFieldsProofs
