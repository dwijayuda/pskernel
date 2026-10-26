import Lean
import Ps.KernelCore.API.DagMutualConstructorFields

/-
Universal field-worker fuel, callback-order and complete-owner equations.
Premises describe component results, not the conclusion of the composed
worker. They preserve the explicit canonical-arena boundary and do not claim
whole admission equivalence, positivity completeness or external replay.
-/
namespace PsKernelMutualConstructorFieldsProofs

abbrev CheckCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat))

abbrev AnalyzeCallback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    List PsKernelName -> List PsKernelExprV2MutualTypeHeader -> List PsKernelLevel ->
    List PsKernelExprV2OrdinaryOpenBinder -> PsKernelExprV2OrdinaryOpenBinder -> Nat -> Option (Except String PsKernelExprV2MutualRecursiveArgumentResult)

variable (check whnf : CheckCallback) (analyze : AnalyzeCallback) (fuel : Nat)
variable (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
variable (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
variable (levels : List PsKernelLevel)
variable (parameters revFields : List PsKernelExprV2OrdinaryOpenBinder)
variable (revRecursive : List PsKernelExprV2MutualRecursiveField)
variable (type : Nat) (resultLevel : PsKernelLevel)
variable (userName : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo)

theorem zero_fuel_precedes_lookup_and_every_callback :
    psKernelExprV2MutualOpenConstructorFieldsWorker 0 check whnf analyze
        context state targets types levels parameters resultLevel type
        revFields revRecursive =
      Option.some (Except.error "mutual constructor field budget exhausted") := by
  rfl

theorem lookup_error_precedes_field_callbacks
    (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.error error) :
    psKernelExprV2MutualOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state targets types levels parameters resultLevel type
        revFields revRecursive = Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualOpenConstructorFieldsWorker, found]

theorem syntactic_nonforall_finishes_without_whnf_or_body_change
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (notForall : ∀ name dom cod info,
      entry.node ≠ PsKernelExprV2Node.forallE name dom cod info) :
    psKernelExprV2MutualOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state targets types levels parameters resultLevel type
        revFields revRecursive =
      Option.some (Except.ok
        (PsKernelExprV2MutualOpenFieldsResult.mk context state
          (psKernelExprV2OrdinaryReverseOpenBinders revFields)
          (psKernelExprV2MutualReverseRecursiveFieldsWorker revRecursive []) type)) := by
  cases node : entry.node <;>
    first
    | exact False.elim (notForall _ _ _ _ node)
    | simp only [psKernelExprV2MutualOpenConstructorFieldsWorker, found, node]

theorem field_step_decline_uses_predecessor_fuel
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (stepped : psKernelExprV2MutualOpenConstructorFieldWith check whnf analyze fuel
      context state targets types levels parameters resultLevel
      userName domain body binderInfo = Option.none) :
    psKernelExprV2MutualOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state targets types levels parameters resultLevel type
        revFields revRecursive = Option.none := by
  simp only [psKernelExprV2MutualOpenConstructorFieldsWorker, found, node, stepped]

theorem field_step_error_precedes_next_field
    (entry : PsKernelExprV2Entry) (error : String)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (stepped : psKernelExprV2MutualOpenConstructorFieldWith check whnf analyze fuel
      context state targets types levels parameters resultLevel
      userName domain body binderInfo = Option.some (Except.error error)) :
    psKernelExprV2MutualOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state targets types levels parameters resultLevel type
        revFields revRecursive = Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualOpenConstructorFieldsWorker, found, node, stepped]

theorem field_step_success_threads_complete_owner_and_ordered_descriptors
    (entry : PsKernelExprV2Entry) (opened : PsKernelExprV2MutualOpenedField)
    (found : psKernelExprV2PagedRequire state.whnf.arena type = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (stepped : psKernelExprV2MutualOpenConstructorFieldWith check whnf analyze fuel
      context state targets types levels parameters resultLevel
      userName domain body binderInfo = Option.some (Except.ok opened)) :
    psKernelExprV2MutualOpenConstructorFieldsWorker (Nat.succ fuel) check whnf analyze
        context state targets types levels parameters resultLevel type
        revFields revRecursive =
      psKernelExprV2MutualOpenConstructorFieldsWorker fuel check whnf analyze
        opened.context opened.state targets types levels parameters resultLevel
        opened.body (List.cons opened.field revFields)
        (match opened.recursiveField with
          | Option.none => revRecursive
          | Option.some recursiveField => List.cons recursiveField revRecursive) := by
  simp only [psKernelExprV2MutualOpenConstructorFieldsWorker, found, node, stepped] <;> rfl

theorem prepare_check_decline_precedes_whnf_and_local_allocation
    (checked : check fuel context state domain = Option.none) :
    psKernelExprV2MutualPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo = Option.none := by
  simp only [psKernelExprV2MutualPrepareFieldWith, checked]

theorem prepare_check_error_precedes_whnf_and_local_allocation
    (error : String)
    (checked : check fuel context state domain = Option.some (Except.error error)) :
    psKernelExprV2MutualPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualPrepareFieldWith, checked]

theorem prepare_mandatory_sort_uses_checked_owner_and_type
    (checkedState : PsKernelExprV2CheckState) (checkedType : Nat)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk checkedState checkedType))) :
    psKernelExprV2MutualPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo =
      match psKernelExprV2AdmissionEnsureSortOwnedWith
          (whnf fuel) context checkedState checkedType with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok sorted =>
              Option.some (psKernelExprV2MutualPrepareFieldAfterSort
                context sorted resultLevel userName domain binderInfo) := by
  simp only [psKernelExprV2MutualPrepareFieldWith, checked] <;> rfl

theorem prepare_sort_decline_precedes_universe_and_annotations
    (checkedState : PsKernelExprV2CheckState) (checkedType : Nat)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk checkedState checkedType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context checkedState checkedType = Option.none) :
    psKernelExprV2MutualPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo = Option.none := by
  simp only [psKernelExprV2MutualPrepareFieldWith, checked, sorted]

theorem prepare_sort_error_precedes_universe_and_annotations
    (checkedState : PsKernelExprV2CheckState) (checkedType : Nat) (error : String)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk checkedState checkedType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context checkedState checkedType = Option.some (Except.error error)) :
    psKernelExprV2MutualPrepareFieldWith check whnf fuel context state
        resultLevel userName domain binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualPrepareFieldWith, checked, sorted]

theorem universe_rejection_precedes_annotations_and_freshness
    (fieldLevel : PsKernelLevel)
    (tooLarge : psKernelLevelLe fieldLevel resultLevel = false)
    (notProp : psKernelLevelNormalizesToZero resultLevel = false) :
    psKernelExprV2MutualPrepareFieldAfterSort context (Prod.mk state fieldLevel)
        resultLevel userName domain binderInfo =
      Except.error "mutual inductive constructor field universe is too large" := by
  simp only [psKernelExprV2MutualPrepareFieldAfterSort, tooLarge, notProp] <;> rfl

theorem annotation_error_precedes_local_allocation
    (fieldLevel : PsKernelLevel) (error : String)
    (allowed : (if psKernelLevelLe fieldLevel resultLevel then true
      else psKernelLevelNormalizesToZero resultLevel) = true)
    (annotations : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      state.whnf.arena domain = Except.error error) :
    psKernelExprV2MutualPrepareFieldAfterSort context (Prod.mk state fieldLevel)
        resultLevel userName domain binderInfo = Except.error error := by
  simp only [psKernelExprV2MutualPrepareFieldAfterSort, allowed, annotations] <;> rfl

theorem prop_universe_exception_still_consumes_annotations
    (fieldLevel : PsKernelLevel) (error : String)
    (tooLarge : psKernelLevelLe fieldLevel resultLevel = false)
    (isProp : psKernelLevelNormalizesToZero resultLevel = true)
    (annotations : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      state.whnf.arena domain = Except.error error) :
    psKernelExprV2MutualPrepareFieldAfterSort context (Prod.mk state fieldLevel)
        resultLevel userName domain binderInfo = Except.error error := by
  simp only [psKernelExprV2MutualPrepareFieldAfterSort, tooLarge, isProp, annotations] <;> rfl

theorem preparation_allocates_only_local_and_freshness_before_analysis
    (fieldLevel : PsKernelLevel) (localDomain : Nat)
    (allowed : (if psKernelLevelLe fieldLevel resultLevel then true
      else psKernelLevelNormalizesToZero resultLevel) = true)
    (annotations : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      state.whnf.arena domain = Except.ok localDomain) :
    psKernelExprV2MutualPrepareFieldAfterSort context (Prod.mk state fieldLevel)
        resultLevel userName domain binderInfo =
      Except.ok (PsKernelExprV2OrdinaryPreparedField.mk
        (psKernelExprV2CheckContextWithLocal context
          (PsKernelName.num userName state.nextFresh) userName localDomain binderInfo)
        (PsKernelExprV2CheckState.mk state.whnf (Nat.succ state.nextFresh)
          state.checkedInfer state.success state.inferOnly state.unfold state.failure)
        (PsKernelExprV2OrdinaryOpenBinder.mk
          (PsKernelName.num userName state.nextFresh) userName localDomain binderInfo)) := by
  simp only [psKernelExprV2MutualPrepareFieldAfterSort, allowed, annotations,
    psKernelExprV2CheckStateFreshName] <;> rfl

theorem analysis_decline_precedes_body_instantiation
    (prepared : PsKernelExprV2OrdinaryPreparedField)
    (ready : psKernelExprV2MutualPrepareFieldWith check whnf fuel context state
      resultLevel userName domain binderInfo = Option.some (Except.ok prepared))
    (analyzed : analyze fuel prepared.context prepared.state targets types levels
      parameters prepared.field domain = Option.none) :
    psKernelExprV2MutualOpenConstructorFieldWith check whnf analyze fuel
        context state targets types levels parameters resultLevel
        userName domain body binderInfo = Option.none := by
  simp only [psKernelExprV2MutualOpenConstructorFieldWith, ready, analyzed]

theorem analysis_error_precedes_body_instantiation
    (prepared : PsKernelExprV2OrdinaryPreparedField) (error : String)
    (ready : psKernelExprV2MutualPrepareFieldWith check whnf fuel context state
      resultLevel userName domain binderInfo = Option.some (Except.ok prepared))
    (analyzed : analyze fuel prepared.context prepared.state targets types levels
      parameters prepared.field domain = Option.some (Except.error error)) :
    psKernelExprV2MutualOpenConstructorFieldWith check whnf analyze fuel
        context state targets types levels parameters resultLevel
        userName domain body binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2MutualOpenConstructorFieldWith, ready, analyzed]

theorem analysis_success_uses_post_field_owner_original_domain_and_original_body
    (prepared : PsKernelExprV2OrdinaryPreparedField)
    (analysis : PsKernelExprV2MutualRecursiveArgumentResult)
    (ready : psKernelExprV2MutualPrepareFieldWith check whnf fuel context state
      resultLevel userName domain binderInfo = Option.some (Except.ok prepared))
    (analyzed : analyze fuel prepared.context prepared.state targets types levels
      parameters prepared.field domain = Option.some (Except.ok analysis)) :
    psKernelExprV2MutualOpenConstructorFieldWith check whnf analyze fuel
        context state targets types levels parameters resultLevel
        userName domain body binderInfo =
      Option.some (psKernelExprV2MutualFinishField prepared analysis body) := by
  simp only [psKernelExprV2MutualOpenConstructorFieldWith, ready, analyzed]

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
end PsKernelMutualConstructorFieldsProofs
