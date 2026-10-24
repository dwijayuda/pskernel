import Lean
import Ps.KernelCore.API.DagOrdinaryRecursiveArgument

/-
Universal fuel, callback-order, occurrence and full-owner equations.
Premises describe subordinate operations; none assumes this worker's result.
These are local protocol proofs, not full admission equivalence or a proof
that untrusted input establishes the canonical arena invariant.
-/
namespace PsKernelOrdinaryRecursiveArgumentProofs

abbrev Callback :=
  Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String (Prod PsKernelExprV2CheckState Nat))

variable (check whnf : Callback) (fuel : Nat)
variable (context : PsKernelExprV2CheckContext)
variable (state next domainState : PsKernelExprV2CheckState)
variable (target : PsKernelName) (levels : List PsKernelLevel)
variable (parameters revArgs : List PsKernelExprV2OrdinaryOpenBinder)
variable (numIndices type reduced domainReduced : Nat)
variable (indices : List Nat) (error : String)

theorem zero_precedes_lookup_and_callbacks :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker 0 check whnf
        context state target levels parameters numIndices type revArgs =
      Option.some
        (Except.error "simple inductive recursive-argument budget exhausted") := by
  rfl

theorem wrapper_adds_one_and_starts_empty_arguments :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWith check whnf fuel
        context state target levels parameters numIndices type =
      psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type List.nil := by
  rfl

theorem with_fuel_uses_full_owner_callbacks :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWithFuel fuel
        context state target levels parameters numIndices type =
      psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWith
        psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
        fuel context state target levels parameters numIndices type := by
  rfl

theorem whnf_decline_stops_before_selector
    (h : whnf fuel context state type = Option.none) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.none := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker, h]

theorem whnf_error_stops_before_selector
    (h : whnf fuel context state type = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker, h]

theorem selector_error_uses_whnf_owner
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.error error) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker, h, selected]

theorem selected_branch_retains_complete_whnf_owner
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.ok (Option.some indices)) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.some
        (psKernelExprV2OrdinaryRecursiveArgumentSelected
          context next target revArgs indices) := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker, h, selected]

theorem lookup_error_after_selector_miss
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.ok Option.none)
    (found : psKernelExprV2PagedRequire next.whnf.arena reduced = Except.error error) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker, h, selected, found]

theorem original_occurrence_error_precedes_reduced_scan
    (h : psKernelExprV2OrdinaryContainsConstOnCanonical
      state.whnf.arena target type = Except.error error) :
    psKernelExprV2OrdinaryAnyRecursiveOccurrence
        state.whnf.arena target type reduced = Except.error error := by
  simp only [psKernelExprV2OrdinaryAnyRecursiveOccurrence, h]

theorem original_occurrence_hit_skips_reduced_scan
    (h : psKernelExprV2OrdinaryContainsConstOnCanonical
      state.whnf.arena target type = Except.ok true) :
    psKernelExprV2OrdinaryAnyRecursiveOccurrence
        state.whnf.arena target type reduced = Except.ok true := by
  simp only [psKernelExprV2OrdinaryAnyRecursiveOccurrence, h] <;> rfl

theorem original_occurrence_miss_uses_reduced_scan
    (h : psKernelExprV2OrdinaryContainsConstOnCanonical
      state.whnf.arena target type = Except.ok false) :
    psKernelExprV2OrdinaryAnyRecursiveOccurrence
        state.whnf.arena target type reduced =
      psKernelExprV2OrdinaryContainsConstOnCanonical state.whnf.arena target reduced := by
  simp only [psKernelExprV2OrdinaryAnyRecursiveOccurrence, h] <;> rfl

theorem unsafe_recursion_guard_skips_arena_and_environment
    (h : psKernelDefinitionSafetyIsUnsafe context.scalar.safety = true) :
    psKernelExprV2OrdinaryInvalidRecursorOccurrence context state target reduced =
      Except.ok false := by
  simp only [psKernelExprV2OrdinaryInvalidRecursorOccurrence, h] <;> rfl

theorem absent_reduced_occurrence_skips_head_metadata
    (safe : psKernelDefinitionSafetyIsUnsafe context.scalar.safety = false)
    (h : psKernelExprV2OrdinaryContainsConstOnCanonical
      state.whnf.arena target reduced = Except.ok false) :
    psKernelExprV2OrdinaryInvalidRecursorOccurrence context state target reduced =
      Except.ok false := by
  simp only [psKernelExprV2OrdinaryInvalidRecursorOccurrence, safe, h] <;> rfl

theorem terminal_nonrecursive_preserves_context_and_complete_owner
    (h : psKernelExprV2OrdinaryAnyRecursiveOccurrence
      state.whnf.arena target type reduced = Except.ok false) :
    psKernelExprV2OrdinaryRecursiveArgumentTerminal context state target type reduced =
      Except.ok
        (PsKernelExprV2OrdinaryRecursiveArgumentResult.mk context state Option.none) := by
  simp only [psKernelExprV2OrdinaryRecursiveArgumentTerminal, h] <;> rfl

theorem terminal_safe_invalid_rec_head_rejects
    (h : psKernelExprV2OrdinaryAnyRecursiveOccurrence
      state.whnf.arena target type reduced = Except.ok true)
    (invalid : psKernelExprV2OrdinaryInvalidRecursorOccurrence
      context state target reduced = Except.ok true) :
    psKernelExprV2OrdinaryRecursiveArgumentTerminal context state target type reduced =
      Except.error
        "simple inductive field has an invalid recursor-headed recursive occurrence" := by
  simp only [psKernelExprV2OrdinaryRecursiveArgumentTerminal, h, invalid] <;> rfl

theorem terminal_other_occurrence_retains_nested_error
    (h : psKernelExprV2OrdinaryAnyRecursiveOccurrence
      state.whnf.arena target type reduced = Except.ok true)
    (invalid : psKernelExprV2OrdinaryInvalidRecursorOccurrence
      context state target reduced = Except.ok false) :
    psKernelExprV2OrdinaryRecursiveArgumentTerminal context state target type reduced =
      Except.error
        "simple inductive admission does not yet support nested recursive occurrences" := by
  simp only [psKernelExprV2OrdinaryRecursiveArgumentTerminal, h, invalid] <;> rfl

theorem selected_success_preserves_owner_names_and_exact_indices
    (h : psKernelExprV2OrdinaryIndicesContainTarget
      state.whnf.arena target indices = Except.ok false) :
    psKernelExprV2OrdinaryRecursiveArgumentSelected context state target revArgs indices =
      Except.ok
        (PsKernelExprV2OrdinaryRecursiveArgumentResult.mk context state
          (Option.some
            (Prod.mk (psKernelExprV2OrdinaryReverseOpenBinders revArgs) indices))) := by
  simp only [psKernelExprV2OrdinaryRecursiveArgumentSelected, h] <;> rfl

theorem selected_recursive_index_rejects
    (h : psKernelExprV2OrdinaryIndicesContainTarget
      state.whnf.arena target indices = Except.ok true) :
    psKernelExprV2OrdinaryRecursiveArgumentSelected context state target revArgs indices =
      Except.error "recursive argument index contains a recursive occurrence" := by
  simp only [psKernelExprV2OrdinaryRecursiveArgumentSelected, h] <;> rfl

variable (entry : PsKernelExprV2Entry)
variable (userName : PsKernelName) (domain body : Nat) (binderInfo : PsKernelBinderInfo)

theorem forall_domain_whnf_decline_precedes_occurrence_and_check
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.ok Option.none)
    (found : psKernelExprV2PagedRequire next.whnf.arena reduced = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (domainWhnf : whnf fuel context next domain = Option.none) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.none := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker,
    h, selected, found, node, domainWhnf]

theorem forall_domain_whnf_error_precedes_occurrence_and_check
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.ok Option.none)
    (found : psKernelExprV2PagedRequire next.whnf.arena reduced = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (domainWhnf : whnf fuel context next domain = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker,
    h, selected, found, node, domainWhnf]

theorem negative_domain_precedes_check_sort_allocation_and_recursion
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.ok Option.none)
    (found : psKernelExprV2PagedRequire next.whnf.arena reduced = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (domainWhnf : whnf fuel context next domain =
      Option.some (Except.ok (Prod.mk domainState domainReduced)))
    (negative : psKernelExprV2OrdinaryAnyRecursiveOccurrence
      domainState.whnf.arena target domain domainReduced = Except.ok true) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.some
        (Except.error "recursive function argument contains a negative recursive occurrence") := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker,
    h, selected, found, node, domainWhnf, negative] <;> rfl

theorem binder_decline_uses_domain_whnf_owner
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.ok Option.none)
    (found : psKernelExprV2PagedRequire next.whnf.arena reduced = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (domainWhnf : whnf fuel context next domain =
      Option.some (Except.ok (Prod.mk domainState domainReduced)))
    (negative : psKernelExprV2OrdinaryAnyRecursiveOccurrence
      domainState.whnf.arena target domain domainReduced = Except.ok false)
    (opened : psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel
      context domainState userName domain body binderInfo = Option.none) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.none := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker,
    h, selected, found, node, domainWhnf, negative, opened] <;> rfl

theorem binder_error_stops_before_recursion
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.ok Option.none)
    (found : psKernelExprV2PagedRequire next.whnf.arena reduced = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (domainWhnf : whnf fuel context next domain =
      Option.some (Except.ok (Prod.mk domainState domainReduced)))
    (negative : psKernelExprV2OrdinaryAnyRecursiveOccurrence
      domainState.whnf.arena target domain domainReduced = Except.ok false)
    (opened : psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel
      context domainState userName domain body binderInfo = Option.some (Except.error error)) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      Option.some (Except.error error) := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker,
    h, selected, found, node, domainWhnf, negative, opened] <;> rfl

theorem binder_success_threads_complete_owner_body_name_and_predecessor
    (opened : PsKernelExprV2OpenedCheckBinder)
    (argument : PsKernelExprV2OrdinaryOpenBinder)
    (h : whnf fuel context state type = Option.some (Except.ok (Prod.mk next reduced)))
    (selected : psKernelExprV2OrdinaryInductiveAppIndices next.whnf.arena
      target levels parameters numIndices reduced = Except.ok Option.none)
    (found : psKernelExprV2PagedRequire next.whnf.arena reduced = Except.ok entry)
    (node : entry.node = PsKernelExprV2Node.forallE userName domain body binderInfo)
    (domainWhnf : whnf fuel context next domain =
      Option.some (Except.ok (Prod.mk domainState domainReduced)))
    (negative : psKernelExprV2OrdinaryAnyRecursiveOccurrence
      domainState.whnf.arena target domain domainReduced = Except.ok false)
    (openedResult : psKernelExprV2OrdinaryOpenHeaderBinderWith check whnf fuel
      context domainState userName domain body binderInfo =
        Option.some (Except.ok (Prod.mk opened argument))) :
    psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker (Nat.succ fuel)
        check whnf context state target levels parameters numIndices type revArgs =
      psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker fuel check whnf
        opened.context opened.parent target levels parameters numIndices opened.body
        (List.cons argument revArgs) := by
  simp only [psKernelExprV2OrdinaryAnalyzeRecursiveArgumentWorker,
    h, selected, found, node, domainWhnf, negative, openedResult] <;> rfl

#print axioms zero_precedes_lookup_and_callbacks
#print axioms wrapper_adds_one_and_starts_empty_arguments
#print axioms with_fuel_uses_full_owner_callbacks
#print axioms whnf_decline_stops_before_selector
#print axioms whnf_error_stops_before_selector
#print axioms selector_error_uses_whnf_owner
#print axioms selected_branch_retains_complete_whnf_owner
#print axioms lookup_error_after_selector_miss
#print axioms original_occurrence_error_precedes_reduced_scan
#print axioms original_occurrence_hit_skips_reduced_scan
#print axioms original_occurrence_miss_uses_reduced_scan
#print axioms unsafe_recursion_guard_skips_arena_and_environment
#print axioms absent_reduced_occurrence_skips_head_metadata
#print axioms terminal_nonrecursive_preserves_context_and_complete_owner
#print axioms terminal_safe_invalid_rec_head_rejects
#print axioms terminal_other_occurrence_retains_nested_error
#print axioms selected_success_preserves_owner_names_and_exact_indices
#print axioms selected_recursive_index_rejects
#print axioms forall_domain_whnf_decline_precedes_occurrence_and_check
#print axioms forall_domain_whnf_error_precedes_occurrence_and_check
#print axioms negative_domain_precedes_check_sort_allocation_and_recursion
#print axioms binder_decline_uses_domain_whnf_owner
#print axioms binder_error_stops_before_recursion
#print axioms binder_success_threads_complete_owner_body_name_and_predecessor

end PsKernelOrdinaryRecursiveArgumentProofs
