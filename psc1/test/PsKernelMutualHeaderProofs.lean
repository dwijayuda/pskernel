import Lean
import Ps.KernelCore.API.DagMutualHeader

/- Universal scope/protocol equations for the private mutual-header stage.
   These do not claim complete mutual admission or global soundness. -/
namespace PsKernelMutualHeaderProofs

abbrev Check := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat →
  Option (Except String (PsKernelExprV2CheckState × Nat))
abbrev DefEq := Nat → PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →
  Option (Except String (PsKernelExprV2CheckState × Bool))

theorem closed_state_resets_all_semantic_fields
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef) :
    psKernelExprV2MutualClosedState arena declarations =
      PsKernelExprV2CheckState.mk
        (psKernelExprV2WhnfStateForDeclarations arena declarations)
        0 [] [] [] [] [] := rfl

theorem closed_context_has_no_shared_locals
    (environment : PsKernelEnvironment) (value : PsKernelDagInductiveGroup)
    (depth maxNat : Nat) :
    (psKernelExprV2MutualClosedContext environment value depth maxNat).locals = [] := rfl

theorem resume_keeps_every_shared_semantic_field
    (parameters : PsKernelExprV2OrdinaryOpenResult) (arena : PsKernelExprV2PagedArena) :
    psKernelExprV2MutualResumeParameters parameters arena =
      PsKernelExprV2CheckState.mk
        (PsKernelExprV2WhnfState.mk arena parameters.state.whnf.coreCache
          parameters.state.whnf.publicCache parameters.state.whnf.declarations)
        parameters.state.nextFresh parameters.state.checkedInfer parameters.state.success
        parameters.state.inferOnly parameters.state.unfold parameters.state.failure := rfl

theorem resume_discards_all_other_owner_state
    (parameters : PsKernelExprV2OrdinaryOpenResult)
    (left right : PsKernelExprV2CheckState) (sameArena : left.whnf.arena = right.whnf.arena) :
    psKernelExprV2MutualResumeParameters parameters left.whnf.arena =
      psKernelExprV2MutualResumeParameters parameters right.whnf.arena := by rw [sameArena]

variable (check whnf : Check) (defeq : DefEq) (fuel type : Nat)
variable (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
variable (parameters : PsKernelExprV2OrdinaryOpenResult) (level : PsKernelLevel)

theorem closed_check_decline_precedes_all_shared_work
    (step : check fuel context state type = none) :
    psKernelExprV2MutualRemainingPhasesWith check whnf defeq fuel context state
      parameters type level = none := by
  simp only [psKernelExprV2MutualRemainingPhasesWith, step]

theorem closed_check_error_precedes_all_shared_work
    (error : String) (step : check fuel context state type = some (.error error)) :
    psKernelExprV2MutualRemainingPhasesWith check whnf defeq fuel context state
      parameters type level = some (.error error) := by
  simp only [psKernelExprV2MutualRemainingPhasesWith, step]

theorem closed_public_sort_decline_precedes_alignment
    (next : PsKernelExprV2CheckState) (typeType : Nat)
    (checked : check fuel context state type = some (.ok (next,typeType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context next typeType = none) :
    psKernelExprV2MutualRemainingPhasesWith check whnf defeq fuel context state
      parameters type level = none := by
  simp only [psKernelExprV2MutualRemainingPhasesWith, checked, sorted]

theorem closed_public_sort_error_precedes_alignment
    (next : PsKernelExprV2CheckState) (typeType : Nat) (error : String)
    (checked : check fuel context state type = some (.ok (next,typeType)))
    (sorted : psKernelExprV2AdmissionEnsureSortOwnedWith
      (whnf fuel) context next typeType = some (.error error)) :
    psKernelExprV2MutualRemainingPhasesWith check whnf defeq fuel context state
      parameters type level = some (.error error) := by
  simp only [psKernelExprV2MutualRemainingPhasesWith, checked, sorted]

theorem finish_requires_owning_sort
    (indices : PsKernelExprV2OrdinaryOpenResult) (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedRequire indices.state.whnf.arena indices.result = .ok entry)
    (node : entry.node = .sort level)
    (equivalent : psKernelLevelEquivalent level level = true) :
    psKernelExprV2MutualFinishIndices level indices = .ok indices := by
  simp [psKernelExprV2MutualFinishIndices, found, node, equivalent]

theorem finish_universe_mismatch_preserves_exact_error
    (indices : PsKernelExprV2OrdinaryOpenResult) (entry : PsKernelExprV2Entry)
    (other : PsKernelLevel)
    (found : psKernelExprV2PagedRequire indices.state.whnf.arena indices.result = .ok entry)
    (node : entry.node = .sort other)
    (different : psKernelLevelEquivalent other level = false) :
    psKernelExprV2MutualFinishIndices level indices =
      .error "mutually inductive types must live in the same universe" := by
  simp [psKernelExprV2MutualFinishIndices, found, node, different]

theorem empty_tail_keeps_exact_arena
    (declarations : List PsKernelExprV2DeclarationRef) (arena : PsKernelExprV2PagedArena) :
    psKernelExprV2MutualRemainingHeadersWith [] check whnf defeq fuel context declarations
      parameters level arena = some (.ok ([],arena)) := rfl

theorem group_error_precedes_first_check
    (environment : PsKernelEnvironment) (depth maxNat : Nat)
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef)
    (value : PsKernelDagInductiveGroup) (error : String)
    (guard : psKernelExprV2MutualHeaderGuardsOnCanonical arena environment value = .error error) :
    psKernelExprV2MutualAnalyzeHeaderWith check whnf defeq fuel environment depth maxNat
      arena declarations value = some (.error error) := by
  simp only [psKernelExprV2MutualAnalyzeHeaderWith, guard]

#print axioms closed_state_resets_all_semantic_fields
#print axioms closed_context_has_no_shared_locals
#print axioms resume_keeps_every_shared_semantic_field
#print axioms resume_discards_all_other_owner_state
#print axioms closed_check_decline_precedes_all_shared_work
#print axioms closed_check_error_precedes_all_shared_work
#print axioms closed_public_sort_decline_precedes_alignment
#print axioms closed_public_sort_error_precedes_alignment
#print axioms finish_requires_owning_sort
#print axioms finish_universe_mismatch_preserves_exact_error
#print axioms empty_tail_keeps_exact_arena
#print axioms group_error_precedes_first_check
end PsKernelMutualHeaderProofs
