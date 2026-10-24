import Lean
import Ps.KernelCore.API.DagOrdinaryParameters
import Ps.KernelCore.API.DagOrdinaryHeader

/-
Universal carrier, ordering and fuel equations for the private ordinary-header
slice. These statements do not assert whole-admission equivalence or kernel
soundness. No execution oracle is used in their proofs.
-/
namespace PsKernelOrdinaryHeaderStateProofs

abbrev Callback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat))

variable (check whnf : Callback)
variable (fuel remaining : Nat)
variable (context : PsKernelExprV2CheckContext)
variable (state : PsKernelExprV2CheckState)
variable (type : Nat)
variable (revBinders : List PsKernelExprV2OrdinaryOpenBinder)

theorem reverse_worker_eq
    (values acc : List PsKernelExprV2OrdinaryOpenBinder) :
    psKernelExprV2OrdinaryReverseOpenBindersWorker values acc = values.reverse ++ acc := by
  induction values generalizing acc with
  | nil => rfl
  | cons head tail ih =>
      simp [psKernelExprV2OrdinaryReverseOpenBindersWorker, ih,
        List.reverse_cons, List.append_assoc]

theorem reverse_eq
    (values : List PsKernelExprV2OrdinaryOpenBinder) :
    psKernelExprV2OrdinaryReverseOpenBinders values = values.reverse := by
  simp [psKernelExprV2OrdinaryReverseOpenBinders, reverse_worker_eq]

theorem finish_keeps_complete_returned_owner
    (next : PsKernelExprV2CheckState) (result : Nat)
    (step : whnf fuel context state type =
      Option.some (Except.ok (Prod.mk next result))) :
    psKernelExprV2OrdinaryFinishOpenBindersWithWhnf
        whnf fuel context state type revBinders =
      Option.some (Except.ok (PsKernelExprV2OrdinaryOpenResult.mk
        context next (psKernelExprV2OrdinaryReverseOpenBinders revBinders) result)) := by
  simp only [psKernelExprV2OrdinaryFinishOpenBindersWithWhnf, step,
    psKernelExprV2OrdinaryOpenResult]

theorem finish_decline
    (step : whnf fuel context state type = Option.none) :
    psKernelExprV2OrdinaryFinishOpenBindersWithWhnf
        whnf fuel context state type revBinders = Option.none := by
  simp only [psKernelExprV2OrdinaryFinishOpenBindersWithWhnf, step]

theorem finish_error
    (error : String)
    (step : whnf fuel context state type = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryFinishOpenBindersWithWhnf
        whnf fuel context state type revBinders =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryFinishOpenBindersWithWhnf, step]

theorem mandatory_sort_keeps_complete_returned_owner
    (next : PsKernelExprV2CheckState) (result : Nat)
    (entry : PsKernelExprV2Entry) (level : PsKernelLevel)
    (step : whnf fuel context state type =
      Option.some (Except.ok (Prod.mk next result)))
    (found : psKernelExprV2PagedRequire next.whnf.arena result = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.sort level) :
    psKernelExprV2AdmissionEnsureSortOwnedWith (whnf fuel) context state type =
      Option.some (Except.ok (Prod.mk next level)) := by
  simp only [psKernelExprV2AdmissionEnsureSortOwnedWith, step, found, node]

variable (userName : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo)

theorem binder_check_decline_precedes_whnf_and_opening
    (step : check fuel context state domain = Option.none) :
    psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel context state
        userName domain body binderInfo = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenHeaderBinderWith, step]

theorem binder_check_error_precedes_whnf_and_opening
    (error : String)
    (step : check fuel context state domain = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel context state
        userName domain body binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderBinderWith, step]

theorem binder_public_whnf_decline_precedes_annotations
    (afterCheck : PsKernelExprV2CheckState) (domainType : Nat)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk afterCheck domainType)))
    (normalized : whnf fuel context afterCheck domainType = Option.none) :
    psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel context state
        userName domain body binderInfo = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenHeaderBinderWith, checked,
    psKernelExprV2AdmissionEnsureSortOwnedWith, normalized]

theorem binder_public_whnf_error_precedes_annotations
    (afterCheck : PsKernelExprV2CheckState) (domainType : Nat) (error : String)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk afterCheck domainType)))
    (normalized : whnf fuel context afterCheck domainType =
      Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel context state
        userName domain body binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderBinderWith, checked,
    psKernelExprV2AdmissionEnsureSortOwnedWith, normalized]

theorem binder_annotation_error_precedes_allocation
    (afterCheck next : PsKernelExprV2CheckState)
    (domainType : Nat) (level : PsKernelLevel) (error : String)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk afterCheck domainType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context afterCheck domainType =
        Option.some (Except.ok (Prod.mk next level)))
    (consumed : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      next.whnf.arena domain = Except.error error) :
    psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel context state
        userName domain body binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderBinderWith, checked, sorted, consumed]

theorem binder_opening_error_preserved
    (afterCheck next : PsKernelExprV2CheckState)
    (domainType localDomain : Nat) (level : PsKernelLevel) (error : String)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk afterCheck domainType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context afterCheck domainType =
        Option.some (Except.ok (Prod.mk next level)))
    (consumed : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      next.whnf.arena domain = Except.ok localDomain)
    (opened : psKernelExprV2CheckOpenBinder context next
      userName localDomain body binderInfo = Except.error error) :
    psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel context state
        userName domain body binderInfo = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderBinderWith, checked, sorted, consumed, opened]

theorem binder_success_keeps_post_opening_owner_and_original_domain
    (afterCheck next : PsKernelExprV2CheckState)
    (domainType localDomain : Nat) (level : PsKernelLevel)
    (opened : PsKernelExprV2OpenedCheckBinder)
    (checked : check fuel context state domain =
      Option.some (Except.ok (Prod.mk afterCheck domainType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context afterCheck domainType =
        Option.some (Except.ok (Prod.mk next level)))
    (consumed : psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical
      next.whnf.arena domain = Except.ok localDomain)
    (opening : psKernelExprV2CheckOpenBinder context next
      userName localDomain body binderInfo = Except.ok opened) :
    psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel context state
        userName domain body binderInfo =
      Option.some (Except.ok (Prod.mk opened
        (PsKernelExprV2OrdinaryOpenBinder.mk opened.fresh userName localDomain binderInfo))) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderBinderWith, checked, sorted, consumed, opening]

theorem binder_allocation_preserves_every_semantic_field
    (localDomain : Nat) (builtArena openedArena : PsKernelExprV2PagedArena)
    (fvarId openedBody : Nat)
    (built : psKernelExprV2PagedMkFVar state.whnf.arena
      (PsKernelName.num userName state.nextFresh) = Except.ok (Prod.mk builtArena fvarId))
    (instantiated : psKernelExprV2TransformOnCanonical
      (PsKernelExprV2Transform.instantiate 0 (List.cons fvarId List.nil))
      builtArena body 0 = Except.ok (Prod.mk openedArena openedBody)) :
    psKernelExprV2CheckOpenBinder context state userName localDomain body binderInfo =
      Except.ok (PsKernelExprV2OpenedCheckBinder.mk
        (psKernelExprV2CheckContextWithLocalValue context
          (PsKernelName.num userName state.nextFresh) userName localDomain binderInfo Option.none)
        (PsKernelExprV2CheckState.mk
          (PsKernelExprV2WhnfState.mk openedArena state.whnf.coreCache
            state.whnf.publicCache state.whnf.declarations)
          (Nat.succ state.nextFresh) state.checkedInfer state.success state.inferOnly
          state.unfold state.failure)
        (PsKernelName.num userName state.nextFresh) openedBody) := by
  simp only [psKernelExprV2CheckOpenBinder, psKernelExprV2CheckOpenLocal,
    psKernelExprV2CheckStateFreshName, built, instantiated,
    psKernelExprV2CheckStateWithArena, psKernelExprV2CheckStateWithWhnf,
    psKernelExprV2WhnfStateWithArena]

theorem param_step_whnf_decline_precedes_lookup
    (step : whnf fuel context state type = Option.none) :
    psKernelExprV2OrdinaryOpenHeaderParamStepWith
      check whnf fuel context state type = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenHeaderParamStepWith, step]

theorem param_step_whnf_error_precedes_lookup
    (error : String)
    (step : whnf fuel context state type = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenHeaderParamStepWith
      check whnf fuel context state type = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderParamStepWith, step]

theorem param_step_lookup_error_precedes_check
    (next : PsKernelExprV2CheckState) (result : Nat) (error : String)
    (step : whnf fuel context state type =
      Option.some (Except.ok (Prod.mk next result)))
    (found : psKernelExprV2PagedRequire next.whnf.arena result = Except.error error) :
    psKernelExprV2OrdinaryOpenHeaderParamStepWith
      check whnf fuel context state type = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderParamStepWith, step, found]

theorem param_step_uses_returned_owner_and_original_fuel
    (next : PsKernelExprV2CheckState) (result : Nat) (entry : PsKernelExprV2Entry)
    (step : whnf fuel context state type =
      Option.some (Except.ok (Prod.mk next result)))
    (found : psKernelExprV2PagedRequire next.whnf.arena result = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo) :
    psKernelExprV2OrdinaryOpenHeaderParamStepWith
        check whnf fuel context state type =
      psKernelExprV2OrdinaryOpenHeaderBinderWith
        check whnf fuel context next userName domain body binderInfo := by
  simp only [psKernelExprV2OrdinaryOpenHeaderParamStepWith, step, found, node]

theorem params_zero_still_performs_final_whnf :
    psKernelExprV2OrdinaryOpenHeaderParamsWorker 0
        check whnf fuel context state type revBinders =
      psKernelExprV2OrdinaryFinishOpenBindersWithWhnf
        whnf fuel context state type revBinders := by
  rfl

theorem params_successor_keeps_original_fuel
    (opened : PsKernelExprV2OpenedCheckBinder) (binder : PsKernelExprV2OrdinaryOpenBinder)
    (step : psKernelExprV2OrdinaryOpenHeaderParamStepWith
      check whnf fuel context state type = Option.some (Except.ok (Prod.mk opened binder))) :
    psKernelExprV2OrdinaryOpenHeaderParamsWorker (Nat.succ remaining)
        check whnf fuel context state type revBinders =
      psKernelExprV2OrdinaryOpenHeaderParamsWorker remaining check whnf fuel
        opened.context opened.parent opened.body (List.cons binder revBinders) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderParamsWorker, step]

theorem params_successor_decline
    (step : psKernelExprV2OrdinaryOpenHeaderParamStepWith
      check whnf fuel context state type = Option.none) :
    psKernelExprV2OrdinaryOpenHeaderParamsWorker (Nat.succ remaining)
      check whnf fuel context state type revBinders = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenHeaderParamsWorker, step]

theorem params_successor_error
    (error : String)
    (step : psKernelExprV2OrdinaryOpenHeaderParamStepWith
      check whnf fuel context state type = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenHeaderParamsWorker (Nat.succ remaining)
      check whnf fuel context state type revBinders = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderParamsWorker, step]

theorem params_wrapper_starts_empty (numParams : Nat) :
    psKernelExprV2OrdinaryOpenHeaderParamsWith
        check whnf fuel context state type numParams =
      psKernelExprV2OrdinaryOpenHeaderParamsWorker numParams
        check whnf fuel context state type List.nil := by
  rfl

theorem indices_zero_precedes_callbacks_and_lookup :
    psKernelExprV2OrdinaryOpenHeaderIndicesWorker 0
        check whnf context state type revBinders =
      Option.some (Except.error "simple inductive index budget exhausted") := by
  rfl

theorem indices_successor_whnf_decline_uses_predecessor
    (step : whnf remaining context state type = Option.none) :
    psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ remaining)
      check whnf context state type revBinders = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenHeaderIndicesWorker, step]

theorem indices_successor_whnf_error_uses_predecessor
    (error : String)
    (step : whnf remaining context state type = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ remaining)
      check whnf context state type revBinders = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderIndicesWorker, step]

theorem indices_successor_lookup_error_precedes_check
    (next : PsKernelExprV2CheckState) (result : Nat) (error : String)
    (step : whnf remaining context state type =
      Option.some (Except.ok (Prod.mk next result)))
    (found : psKernelExprV2PagedRequire next.whnf.arena result = Except.error error) :
    psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ remaining)
      check whnf context state type revBinders = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderIndicesWorker, step, found]

theorem indices_successor_binder_threads_post_opening_owner
    (next : PsKernelExprV2CheckState) (result : Nat) (entry : PsKernelExprV2Entry)
    (opened : PsKernelExprV2OpenedCheckBinder) (binder : PsKernelExprV2OrdinaryOpenBinder)
    (normalized : whnf remaining context state type =
      Option.some (Except.ok (Prod.mk next result)))
    (found : psKernelExprV2PagedRequire next.whnf.arena result = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (step : psKernelExprV2OrdinaryOpenHeaderBinderWith
      check whnf remaining context next userName domain body binderInfo =
        Option.some (Except.ok (Prod.mk opened binder))) :
    psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ remaining)
        check whnf context state type revBinders =
      psKernelExprV2OrdinaryOpenHeaderIndicesWorker remaining check whnf
        opened.context opened.parent opened.body (List.cons binder revBinders) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderIndicesWorker, normalized, found, node, step]

theorem indices_successor_binder_decline
    (next : PsKernelExprV2CheckState) (result : Nat) (entry : PsKernelExprV2Entry)
    (normalized : whnf remaining context state type =
      Option.some (Except.ok (Prod.mk next result)))
    (found : psKernelExprV2PagedRequire next.whnf.arena result = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (step : psKernelExprV2OrdinaryOpenHeaderBinderWith
      check whnf remaining context next userName domain body binderInfo = Option.none) :
    psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ remaining)
      check whnf context state type revBinders = Option.none := by
  simp only [psKernelExprV2OrdinaryOpenHeaderIndicesWorker, normalized, found, node, step]

theorem indices_successor_binder_error
    (next : PsKernelExprV2CheckState) (result : Nat) (entry : PsKernelExprV2Entry) (error : String)
    (normalized : whnf remaining context state type =
      Option.some (Except.ok (Prod.mk next result)))
    (found : psKernelExprV2PagedRequire next.whnf.arena result = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (step : psKernelExprV2OrdinaryOpenHeaderBinderWith
      check whnf remaining context next userName domain body binderInfo =
        Option.some (Except.error error)) :
    psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ remaining)
      check whnf context state type revBinders = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderIndicesWorker, normalized, found, node, step]

theorem indices_terminal_sort_keeps_complete_returned_owner
    (next : PsKernelExprV2CheckState) (result : Nat)
    (entry : PsKernelExprV2Entry) (level : PsKernelLevel)
    (normalized : whnf remaining context state type =
      Option.some (Except.ok (Prod.mk next result)))
    (found : psKernelExprV2PagedRequire next.whnf.arena result = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.sort level) :
    psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ remaining)
        check whnf context state type revBinders =
      Option.some (Except.ok (PsKernelExprV2OrdinaryOpenResult.mk context next
        (psKernelExprV2OrdinaryReverseOpenBinders revBinders) result)) := by
  simp only [psKernelExprV2OrdinaryOpenHeaderIndicesWorker, normalized, found, node,
    psKernelExprV2OrdinaryOpenResult]

theorem indices_wrapper_adds_one_before_callbacks :
    psKernelExprV2OrdinaryOpenHeaderIndicesWith check whnf fuel context state type =
      psKernelExprV2OrdinaryOpenHeaderIndicesWorker (Nat.succ fuel)
        check whnf context state type List.nil := by
  rfl

theorem constructor_context_is_parameter_context
    (analysis : PsKernelExprV2OrdinaryHeaderAnalysis) :
    psKernelExprV2OrdinaryConstructorContext analysis = analysis.parameters.context := by
  rfl

theorem constructor_fork_preserves_parameter_semantics_and_freshness
    (analysis : PsKernelExprV2OrdinaryHeaderAnalysis) :
    psKernelExprV2OrdinaryConstructorState analysis =
      PsKernelExprV2CheckState.mk
        (PsKernelExprV2WhnfState.mk analysis.indices.state.whnf.arena
          analysis.parameters.state.whnf.coreCache
          analysis.parameters.state.whnf.publicCache
          analysis.parameters.state.whnf.declarations)
        analysis.parameters.state.nextFresh
        analysis.parameters.state.checkedInfer analysis.parameters.state.success
        analysis.parameters.state.inferOnly analysis.parameters.state.unfold
        analysis.parameters.state.failure := by
  rfl

theorem constructor_fork_ignores_index_semantic_state
    (parameters left right : PsKernelExprV2OrdinaryOpenResult)
    (leftLevel rightLevel : PsKernelLevel)
    (arena : left.state.whnf.arena = right.state.whnf.arena) :
    psKernelExprV2OrdinaryConstructorState
        (PsKernelExprV2OrdinaryHeaderAnalysis.mk parameters left leftLevel) =
      psKernelExprV2OrdinaryConstructorState
        (PsKernelExprV2OrdinaryHeaderAnalysis.mk parameters right rightLevel) := by
  simp only [psKernelExprV2OrdinaryConstructorState, arena]

/- Composition with the owning V1 guard order and the private header phases. -/
theorem header_finish_sort_keeps_both_owners
    (parameters indices : PsKernelExprV2OrdinaryOpenResult)
    (entry : PsKernelExprV2Entry) (level : PsKernelLevel)
    (found : psKernelExprV2PagedRequire indices.state.whnf.arena indices.result =
      Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.sort level) :
    psKernelExprV2OrdinaryHeaderFinish parameters indices =
      Except.ok (PsKernelExprV2OrdinaryHeaderAnalysis.mk parameters indices level) := by
  simp only [psKernelExprV2OrdinaryHeaderFinish, found, node]

theorem header_finish_lookup_error
    (parameters indices : PsKernelExprV2OrdinaryOpenResult) (error : String)
    (found : psKernelExprV2PagedRequire indices.state.whnf.arena indices.result =
      Except.error error) :
    psKernelExprV2OrdinaryHeaderFinish parameters indices = Except.error error := by
  simp only [psKernelExprV2OrdinaryHeaderFinish, found]

theorem header_finish_nonsort_error
    (parameters indices : PsKernelExprV2OrdinaryOpenResult)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire indices.state.whnf.arena indices.result =
      Except.ok entry)
    (notSort : ∀ level, entry.node ≠ PsKernelExprV2Node.sort level) :
    psKernelExprV2OrdinaryHeaderFinish parameters indices =
      Except.error "simple inductive result must be a sort" := by
  simp only [psKernelExprV2OrdinaryHeaderFinish, found]

theorem header_check_decline_precedes_whnf
    (numParams : Nat)
    (checked : check fuel context state type = Option.none) :
    psKernelExprV2OrdinaryHeaderPhasesWith
      check whnf fuel context state type numParams = Option.none := by
  simp only [psKernelExprV2OrdinaryHeaderPhasesWith, checked]

theorem header_check_error_precedes_whnf
    (numParams : Nat) (error : String)
    (checked : check fuel context state type = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryHeaderPhasesWith
      check whnf fuel context state type numParams = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryHeaderPhasesWith, checked]

theorem header_public_whnf_decline_precedes_opening
    (numParams : Nat) (afterCheck : PsKernelExprV2CheckState) (headerType : Nat)
    (checked : check fuel context state type =
      Option.some (Except.ok (Prod.mk afterCheck headerType)))
    (normalized : whnf fuel context afterCheck headerType = Option.none) :
    psKernelExprV2OrdinaryHeaderPhasesWith
      check whnf fuel context state type numParams = Option.none := by
  simp only [psKernelExprV2OrdinaryHeaderPhasesWith, checked,
    psKernelExprV2AdmissionEnsureSortOwnedWith, normalized]

theorem header_public_whnf_error_precedes_opening
    (numParams : Nat) (afterCheck : PsKernelExprV2CheckState)
    (headerType : Nat) (error : String)
    (checked : check fuel context state type =
      Option.some (Except.ok (Prod.mk afterCheck headerType)))
    (normalized : whnf fuel context afterCheck headerType = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryHeaderPhasesWith
      check whnf fuel context state type numParams = Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryHeaderPhasesWith, checked,
    psKernelExprV2AdmissionEnsureSortOwnedWith, normalized]

theorem header_after_sort_composition
    (numParams : Nat) (afterCheck afterSort : PsKernelExprV2CheckState)
    (headerType : Nat) (level : PsKernelLevel)
    (checked : check fuel context state type =
      Option.some (Except.ok (Prod.mk afterCheck headerType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context afterCheck headerType =
        Option.some (Except.ok (Prod.mk afterSort level))) :
    psKernelExprV2OrdinaryHeaderPhasesWith
        check whnf fuel context state type numParams =
      match psKernelExprV2OrdinaryOpenHeaderParamsWith
          check whnf fuel context afterSort type numParams with
      | Option.none => Option.none
      | Option.some attemptedParameters =>
          match attemptedParameters with
          | Except.error error => Option.some (Except.error error)
          | Except.ok parameters =>
              match psKernelExprV2OrdinaryOpenHeaderIndicesWith
                  check whnf fuel parameters.context parameters.state parameters.result with
              | Option.none => Option.none
              | Option.some attemptedIndices =>
                  match attemptedIndices with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok indices =>
                      Option.some (psKernelExprV2OrdinaryHeaderFinish parameters indices) := by
  simp only [psKernelExprV2OrdinaryHeaderPhasesWith, checked, sorted]
  rfl

variable (arena : PsKernelExprV2PagedArena) (environment : PsKernelEnvironment)
variable (levelParams : List PsKernelName) (numParams : Nat) (value : PsKernelDagInductive)

theorem header_guard_error_precedes_callbacks
    (maxRecDepth maxNatSize : Nat) (declarations : List PsKernelExprV2DeclarationRef)
    (isUnsafe : Bool) (error : String)
    (guards : psKernelExprV2OrdinaryHeaderGuardsOnCanonical
      arena environment levelParams numParams value = Except.error error) :
    psKernelExprV2OrdinaryAnalyzeHeaderWith check whnf fuel environment
        maxRecDepth maxNatSize arena declarations levelParams numParams value isUnsafe =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeHeaderWith, guards]

theorem header_duplicate_levels_precede_all_other_guards
    (duplicate : psKernelNameHasDuplicates levelParams = true) :
    psKernelExprV2OrdinaryHeaderGuardsOnCanonical
        arena environment levelParams numParams value =
      Except.error "duplicate universe parameter" := by
  simp [psKernelExprV2OrdinaryHeaderGuardsOnCanonical, duplicate]

theorem header_duplicate_names_precede_freshness_and_types
    (levels : psKernelNameHasDuplicates levelParams = false)
    (names : psKernelSimpleNameListUnique
      (List.cons value.name (List.cons (psKernelSimpleRecName value.name)
        (psKernelExprV2OrdinaryCtorNames value.ctors))) = false) :
    psKernelExprV2OrdinaryHeaderGuardsOnCanonical
        arena environment levelParams numParams value =
      Except.error "duplicate inductive, constructor, or recursor name" := by
  simp [psKernelExprV2OrdinaryHeaderGuardsOnCanonical, levels, names]

theorem header_freshness_error_precedes_uniform_and_header
    (error : String)
    (levels : psKernelNameHasDuplicates levelParams = false)
    (names : psKernelSimpleNameListUnique
      (List.cons value.name (List.cons (psKernelSimpleRecName value.name)
        (psKernelExprV2OrdinaryCtorNames value.ctors))) = true)
    (fresh : psKernelCheckFreshInductiveNames
      (List.cons value.name (List.cons (psKernelSimpleRecName value.name)
        (psKernelExprV2OrdinaryCtorNames value.ctors))) environment = Except.error error) :
    psKernelExprV2OrdinaryHeaderGuardsOnCanonical
      arena environment levelParams numParams value = Except.error error := by
  simp [psKernelExprV2OrdinaryHeaderGuardsOnCanonical, levels, names, fresh]

theorem header_uniform_error_precedes_static_header
    (error : String)
    (levels : psKernelNameHasDuplicates levelParams = false)
    (names : psKernelSimpleNameListUnique
      (List.cons value.name (List.cons (psKernelSimpleRecName value.name)
        (psKernelExprV2OrdinaryCtorNames value.ctors))) = true)
    (fresh : psKernelCheckFreshInductiveNames
      (List.cons value.name (List.cons (psKernelSimpleRecName value.name)
        (psKernelExprV2OrdinaryCtorNames value.ctors))) environment = Except.ok ())
    (uniform : psKernelExprV2OrdinaryUniformOccurrences
      (psKernelExprV2OrdinaryCtorTypes value.ctors) arena (List.cons value.name List.nil)
      (psKernelLevelParamsToLevels levelParams) numParams = Except.error error) :
    psKernelExprV2OrdinaryHeaderGuardsOnCanonical
      arena environment levelParams numParams value = Except.error error := by
  simp [psKernelExprV2OrdinaryHeaderGuardsOnCanonical, levels, names, fresh, uniform]

theorem header_successful_guards_initialize_one_fresh_owner
    (maxRecDepth maxNatSize : Nat) (declarations : List PsKernelExprV2DeclarationRef)
    (isUnsafe : Bool)
    (guards : psKernelExprV2OrdinaryHeaderGuardsOnCanonical
      arena environment levelParams numParams value = Except.ok ()) :
    psKernelExprV2OrdinaryAnalyzeHeaderWith check whnf fuel environment
        maxRecDepth maxNatSize arena declarations levelParams numParams value isUnsafe =
      psKernelExprV2OrdinaryHeaderPhasesWith check whnf fuel
        (psKernelExprV2CheckContextEmpty
          (psKernelMkCheckerSession environment levelParams
            (if isUnsafe then PsKernelDefinitionSafety.unsafeDef
             else PsKernelDefinitionSafety.safe) maxRecDepth maxNatSize).context)
        (PsKernelExprV2CheckState.mk
          (PsKernelExprV2WhnfState.mk arena List.nil List.nil declarations)
          0 List.nil List.nil List.nil List.nil List.nil)
        value.type numParams := by
  simp only [psKernelExprV2OrdinaryAnalyzeHeaderWith, guards,
    psKernelExprV2CheckStateWithWhnf, psKernelExprV2CheckStateEmpty,
    psKernelExprV2WhnfStateForDeclarations]

#print axioms reverse_worker_eq
#print axioms reverse_eq
#print axioms finish_keeps_complete_returned_owner
#print axioms finish_decline
#print axioms finish_error
#print axioms mandatory_sort_keeps_complete_returned_owner
#print axioms binder_check_decline_precedes_whnf_and_opening
#print axioms binder_check_error_precedes_whnf_and_opening
#print axioms binder_public_whnf_decline_precedes_annotations
#print axioms binder_public_whnf_error_precedes_annotations
#print axioms binder_annotation_error_precedes_allocation
#print axioms binder_opening_error_preserved
#print axioms binder_success_keeps_post_opening_owner_and_original_domain
#print axioms binder_allocation_preserves_every_semantic_field
#print axioms param_step_whnf_decline_precedes_lookup
#print axioms param_step_whnf_error_precedes_lookup
#print axioms param_step_lookup_error_precedes_check
#print axioms param_step_uses_returned_owner_and_original_fuel
#print axioms params_zero_still_performs_final_whnf
#print axioms params_successor_keeps_original_fuel
#print axioms params_successor_decline
#print axioms params_successor_error
#print axioms params_wrapper_starts_empty
#print axioms indices_zero_precedes_callbacks_and_lookup
#print axioms indices_successor_whnf_decline_uses_predecessor
#print axioms indices_successor_whnf_error_uses_predecessor
#print axioms indices_successor_lookup_error_precedes_check
#print axioms indices_successor_binder_threads_post_opening_owner
#print axioms indices_successor_binder_decline
#print axioms indices_successor_binder_error
#print axioms indices_terminal_sort_keeps_complete_returned_owner
#print axioms indices_wrapper_adds_one_before_callbacks
#print axioms constructor_context_is_parameter_context
#print axioms constructor_fork_preserves_parameter_semantics_and_freshness
#print axioms constructor_fork_ignores_index_semantic_state
#print axioms header_finish_sort_keeps_both_owners
#print axioms header_finish_lookup_error
#print axioms header_finish_nonsort_error
#print axioms header_check_decline_precedes_whnf
#print axioms header_check_error_precedes_whnf
#print axioms header_public_whnf_decline_precedes_opening
#print axioms header_public_whnf_error_precedes_opening
#print axioms header_after_sort_composition
#print axioms header_guard_error_precedes_callbacks
#print axioms header_duplicate_levels_precede_all_other_guards
#print axioms header_duplicate_names_precede_freshness_and_types
#print axioms header_freshness_error_precedes_uniform_and_header
#print axioms header_uniform_error_precedes_static_header
#print axioms header_successful_guards_initialize_one_fresh_owner

end PsKernelOrdinaryHeaderStateProofs
