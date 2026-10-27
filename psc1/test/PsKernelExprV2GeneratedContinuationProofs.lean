import PsKernelExprV2ArenaModelBridgeProofs
import Ps.KernelCore.API.DagOrdinaryGenerated

/-!
The actual generated-owner synchronization completes an already established
decoded prefix against one shared semantic map. Its input relation is derived
from public decoding at entry; subsequent checker transitions still have to
preserve that relation. No invariant about a returned owner, declaration
judgment, or cache answer is assumed as a premise.

These are structural continuation theorems, not successful-checking soundness.
Declaration references are retained exactly; their logical validity remains a
separate obligation. Equality of buffer sizes alone supplies no semantics.
-/
namespace PsKernelExprV2GeneratedContinuationProofs

open PsKernelExprV2SemanticPrefixProofs
open PsKernelExprV2DecodedNodeProofs
open PsKernelExprV2DecodedBridgeProofs
open PsKernelExprV2ArenaModelBridgeProofs
open PsKernelOrdinaryOccurrenceProofs

theorem public_decode_establishes_continuation
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (accepted : psKernelExprV2DecodeChecked arena = Except.ok built) :
    ∃ meaning : Nat → PsKernelExpr,
      SemanticPrefix arena meaning ∧ ArenaModel arena meaning ∧
      DecodedLayout built ∧ DecodedPrefix built meaning ∧ built.size = arena.size := by
  rcases decode_checked_ok_corresponds arena built accepted with
    ⟨layout, size, meaning, semantic, decoded, _metadata⟩
  exact ⟨meaning, semantic, semantic_prefix_establishes_arena_model arena meaning semantic,
    layout, decoded, size⟩

theorem extend_decoded_succeeds_with_shared_meaning
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix arena meaning)
    (layout : DecodedLayout built) (decoded : DecodedPrefix built meaning)
    (within : built.size ≤ arena.size) :
    ∃ result : PsKernelExprV2Decoded,
      psKernelExprV2OrdinaryExtendDecoded arena built = Except.ok result ∧
      DecodedLayout result ∧ DecodedPrefix result meaning ∧ result.size = arena.size := by
  rcases decode_canonical_fuel_succeeds (Nat.succ (arena.size - built.size)) arena
      built built.size meaning semantic layout decoded rfl within (by omega) with
    ⟨result, ran, resultLayout, resultDecoded, size⟩
  refine ⟨result, ?_, resultLayout, resultDecoded, size⟩
  simpa only [psKernelExprV2OrdinaryExtendDecoded, Nat.ble_eq, within, ite_true,
    HSub.hSub, instHSub, Sub.sub, Nat.instSub] using ran

theorem extend_decoded_ok_preserves_shared_meaning
    (arena : PsKernelExprV2PagedArena) (built result : PsKernelExprV2Decoded)
    (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix arena meaning)
    (layout : DecodedLayout built) (decoded : DecodedPrefix built meaning)
    (accepted : psKernelExprV2OrdinaryExtendDecoded arena built = Except.ok result) :
    DecodedLayout result ∧ DecodedPrefix result meaning ∧ result.size = arena.size := by
  unfold psKernelExprV2OrdinaryExtendDecoded at accepted
  split at accepted
  · exact decode_canonical_fuel_ok_preserves (Nat.succ (arena.size - built.size))
      arena built result built.size meaning semantic layout decoded rfl accepted
  · simp at accepted

theorem extend_decoded_preserves_every_old_lookup
    (arena : PsKernelExprV2PagedArena) (built result : PsKernelExprV2Decoded)
    (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix arena meaning)
    (layout : DecodedLayout built) (decoded : DecodedPrefix built meaning)
    (within : built.size ≤ arena.size)
    (accepted : psKernelExprV2OrdinaryExtendDecoded arena built = Except.ok result)
    (id : Nat) (old : id < built.size) :
    psKernelExprV2DecodedRequire result id = psKernelExprV2DecodedRequire built id := by
  rcases extend_decoded_ok_preserves_shared_meaning arena built result meaning
      semantic layout decoded accepted with ⟨_layout, resultDecoded, size⟩
  have inside : id < result.size := by omega
  exact (resultDecoded id inside).trans (decoded id old).symm

theorem synchronize_owner_succeeds_with_arena_model
    (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded)
    (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix state.whnf.arena meaning)
    (layout : DecodedLayout built) (decoded : DecodedPrefix built meaning)
    (within : built.size ≤ state.whnf.arena.size) :
    ∃ owner : PsKernelDagGeneratedState,
      psKernelExprV2OrdinarySynchronizeOwner state built = Except.ok owner ∧
      owner.arena = state.whnf.arena ∧ owner.declarations = state.whnf.declarations ∧
      ArenaModel owner.arena meaning ∧ DecodedLayout owner.built ∧
      DecodedPrefix owner.built meaning ∧ owner.built.size = owner.arena.size := by
  rcases extend_decoded_succeeds_with_shared_meaning state.whnf.arena built meaning
      semantic layout decoded within with ⟨result, ran, resultLayout, resultDecoded, size⟩
  refine ⟨PsKernelDagGeneratedState.mk state.whnf.arena result state.whnf.declarations,
    ?_, rfl, rfl, ?_, resultLayout, resultDecoded, size⟩
  · simp only [psKernelExprV2OrdinarySynchronizeOwner, ran]
  · exact semantic_prefix_establishes_arena_model state.whnf.arena meaning semantic

theorem synchronize_owner_ok_has_exact_owner_and_meaning
    (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded)
    (owner : PsKernelDagGeneratedState) (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix state.whnf.arena meaning)
    (layout : DecodedLayout built) (decoded : DecodedPrefix built meaning)
    (accepted : psKernelExprV2OrdinarySynchronizeOwner state built = Except.ok owner) :
    owner.arena = state.whnf.arena ∧ owner.declarations = state.whnf.declarations ∧
      ArenaModel owner.arena meaning ∧ DecodedLayout owner.built ∧
      DecodedPrefix owner.built meaning ∧ owner.built.size = owner.arena.size := by
  cases ran : psKernelExprV2OrdinaryExtendDecoded state.whnf.arena built with
  | error error => simp [psKernelExprV2OrdinarySynchronizeOwner, ran] at accepted
  | ok result =>
      have same : PsKernelDagGeneratedState.mk state.whnf.arena result state.whnf.declarations = owner := by
        exact Except.ok.inj (by simpa only [psKernelExprV2OrdinarySynchronizeOwner, ran] using accepted)
      subst owner
      rcases extend_decoded_ok_preserves_shared_meaning state.whnf.arena built result meaning
          semantic layout decoded ran with ⟨resultLayout, resultDecoded, size⟩
      exact ⟨rfl, rfl, semantic_prefix_establishes_arena_model state.whnf.arena meaning semantic,
        resultLayout, resultDecoded, size⟩

/- The public boundary uses its separately retained table. Synchronization of
the private owner preserves all established earlier lookups as a theorem; it
does not expand the external namespace or make private roots public. -/
theorem synchronize_owner_preserves_original_decoded_prefix
    (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded)
    (owner : PsKernelDagGeneratedState) (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix state.whnf.arena meaning)
    (layout : DecodedLayout built) (decoded : DecodedPrefix built meaning)
    (within : built.size ≤ state.whnf.arena.size)
    (accepted : psKernelExprV2OrdinarySynchronizeOwner state built = Except.ok owner) :
    ∀ id, id < built.size →
      psKernelExprV2DecodedRequire owner.built id = psKernelExprV2DecodedRequire built id := by
  rcases synchronize_owner_ok_has_exact_owner_and_meaning state built owner meaning
      semantic layout decoded accepted with ⟨arena, _declarations, _model, _layout, resultDecoded, size⟩
  intro id old
  have inside : id < owner.built.size := by rw [size, arena]; omega
  exact (resultDecoded id inside).trans (decoded id old).symm

end PsKernelExprV2GeneratedContinuationProofs

#print axioms PsKernelExprV2GeneratedContinuationProofs.public_decode_establishes_continuation
#print axioms PsKernelExprV2GeneratedContinuationProofs.extend_decoded_succeeds_with_shared_meaning
#print axioms PsKernelExprV2GeneratedContinuationProofs.extend_decoded_ok_preserves_shared_meaning
#print axioms PsKernelExprV2GeneratedContinuationProofs.extend_decoded_preserves_every_old_lookup
#print axioms PsKernelExprV2GeneratedContinuationProofs.synchronize_owner_succeeds_with_arena_model
#print axioms PsKernelExprV2GeneratedContinuationProofs.synchronize_owner_ok_has_exact_owner_and_meaning
#print axioms PsKernelExprV2GeneratedContinuationProofs.synchronize_owner_preserves_original_decoded_prefix
