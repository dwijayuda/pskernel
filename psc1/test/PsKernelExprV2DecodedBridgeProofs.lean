import PsKernelExprV2DecodedNodeProofs

/-!
The actual production paged decoder preserves an internally established
64-entry storage layout and the validator's shared interpretation.

DecodedLayout is a physical invariant for the decoder's own buffers.
It is established from DecodedEmpty and preserved by DecodedPush; it is never
assumed of untrusted external input. DecodedPrefix refers to the real
DecodedRequire operation. No research decoder or caller-built expression
certificate replaces these operations.
-/
namespace PsKernelExprV2DecodedBridgeProofs

open PsKernelExprV2MetadataProofs
open PsKernelExprV2PagedModelProofs
open PsKernelExprV2SemanticPrefixProofs
open PsKernelExprV2DecodedNodeProofs

structure DecodedLayout (built : PsKernelExprV2Decoded) : Prop where
  full : ∀ page, page < built.pages.size →
    (built.pages.getD page (Array.emptyWithCapacity 0)).size = 64
  active : built.active.size ≤ 64
  size : built.size = 64 * built.pages.size + built.active.size

theorem decoded_empty_layout : DecodedLayout psKernelExprV2DecodedEmpty := by
  constructor
  · intro page before
    simp [psKernelExprV2DecodedEmpty] at before
  · simp [psKernelExprV2DecodedEmpty]
  · simp [psKernelExprV2DecodedEmpty]

theorem decoded_push_size (built : PsKernelExprV2Decoded) (expr : PsKernelExpr) :
    (psKernelExprV2DecodedPush built expr).size = built.size + 1 := by
  unfold psKernelExprV2DecodedPush
  split <;> rfl

private theorem decoded_push_growing (built : PsKernelExprV2Decoded) (expr : PsKernelExpr)
    (space : built.active.size < 64) :
    psKernelExprV2DecodedPush built expr =
      PsKernelExprV2Decoded.mk built.pages (built.active.push expr) (built.size + 1) := by
  simp [psKernelExprV2DecodedPush, Nat.blt_eq, space, Nat.succ_eq_add_one]

private theorem decoded_push_rollover (built : PsKernelExprV2Decoded) (expr : PsKernelExpr)
    (full : ¬ built.active.size < 64) :
    psKernelExprV2DecodedPush built expr =
      PsKernelExprV2Decoded.mk (built.pages.push built.active) #[expr] (built.size + 1) := by
  simp [psKernelExprV2DecodedPush, Nat.blt_eq, full, Nat.succ_eq_add_one]

theorem decoded_push_layout (built : PsKernelExprV2Decoded) (expr : PsKernelExpr)
    (layout : DecodedLayout built) :
    DecodedLayout (psKernelExprV2DecodedPush built expr) := by
  by_cases space : built.active.size < 64
  · rw [decoded_push_growing built expr space]
    constructor
    · exact layout.full
    · simpa only [Array.size_push] using Nat.succ_le_of_lt space
    · simp only [Array.size_push]
      rw [layout.size]
      omega
  · have full : built.active.size = 64 := by
      have bounded := layout.active
      omega
    rw [decoded_push_rollover built expr space]
    constructor
    · intro page before
      simp only [Array.size_push] at before
      by_cases old : page < built.pages.size
      · rw [array_getD_push_old built.pages built.active (Array.emptyWithCapacity 0) page old]
        exact layout.full page old
      · have same : page = built.pages.size := by omega
        subst page
        rw [array_getD_push_new]
        exact full
    · simp only [Array.size_singleton]
      omega
    · simp only [Array.size_push, Array.size_singleton]
      rw [layout.size, full]
      omega

private theorem decoded_id_location (built : PsKernelExprV2Decoded)
    (layout : DecodedLayout built) (id : Nat) (inside : id < built.size) :
    id / 64 < built.pages.size ∨
      (id / 64 = built.pages.size ∧ id % 64 < built.active.size) := by
  have total := layout.size
  have active := layout.active
  have upper : id < (built.pages.size + 1) * 64 := by omega
  have quotient : id / 64 ≤ built.pages.size := by
    have less := (Nat.div_lt_iff_lt_mul (by decide : 0 < 64)).2 upper
    omega
  by_cases completed : id / 64 < built.pages.size
  · exact Or.inl completed
  · have atActive : id / 64 = built.pages.size := by omega
    have division := Nat.div_add_mod id 64
    rw [atActive] at division
    exact Or.inr ⟨atActive, by omega⟩

private theorem decoded_require_completed (built : PsKernelExprV2Decoded) (id : Nat)
    (inside : id < built.size) (completed : id / 64 < built.pages.size)
    (offset : id % 64 < (built.pages.getD (id / 64) (Array.emptyWithCapacity 0)).size) :
    psKernelExprV2DecodedRequire built id =
      Except.ok ((built.pages.getD (id / 64) (Array.emptyWithCapacity 0)).getD
        (id % 64) (PsKernelExpr.bvar 0)) := by
  dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
    HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
  simp only [psKernelExprV2DecodedRequire, Nat.blt_eq,
    inside, completed, offset, ite_true]

private theorem decoded_require_active (built : PsKernelExprV2Decoded) (id : Nat)
    (inside : id < built.size) (atActive : id / 64 = built.pages.size)
    (offset : id % 64 < built.active.size) :
    psKernelExprV2DecodedRequire built id =
      Except.ok (built.active.getD (id % 64) (PsKernelExpr.bvar 0)) := by
  dsimp only [HDiv.hDiv, instHDiv, Div.div, Nat.instDiv,
    HMod.hMod, instHMod, Mod.mod, Nat.instMod] at *
  simp only [psKernelExprV2DecodedRequire, Nat.blt_eq, Nat.beq_eq,
    inside, atActive, Nat.lt_irrefl, offset, ite_false, ite_true]

theorem decoded_push_require_old (built : PsKernelExprV2Decoded)
    (expr : PsKernelExpr) (layout : DecodedLayout built)
    (id : Nat) (inside : id < built.size) :
    psKernelExprV2DecodedRequire (psKernelExprV2DecodedPush built expr) id =
      psKernelExprV2DecodedRequire built id := by
  have nextInside : id < built.size + 1 := by omega
  by_cases space : built.active.size < 64
  · rw [decoded_push_growing built expr space]
    let next := PsKernelExprV2Decoded.mk built.pages (built.active.push expr) (built.size + 1)
    change psKernelExprV2DecodedRequire next id = psKernelExprV2DecodedRequire built id
    rcases decoded_id_location built layout id inside with completed | ⟨atActive, offset⟩
    · have size := layout.full (id / 64) completed
      have offset : id % 64 <
          (built.pages.getD (id / 64) (Array.emptyWithCapacity 0)).size := by
        rw [size]
        exact Nat.mod_lt id (by decide)
      rw [decoded_require_completed next id nextInside completed offset,
        decoded_require_completed built id inside completed offset]
    · have nextOffset : id % 64 < (built.active.push expr).size := by
        simp only [Array.size_push]
        omega
      rw [decoded_require_active next id nextInside atActive nextOffset,
        decoded_require_active built id inside atActive offset]
      exact congrArg (fun value => (Except.ok value : Except String PsKernelExpr))
        (array_getD_push_old built.active expr (PsKernelExpr.bvar 0) (id % 64) offset)
  · rw [decoded_push_rollover built expr space]
    let next := PsKernelExprV2Decoded.mk (built.pages.push built.active) #[expr] (built.size + 1)
    change psKernelExprV2DecodedRequire next id = psKernelExprV2DecodedRequire built id
    rcases decoded_id_location built layout id inside with completed | ⟨atActive, offset⟩
    · have size := layout.full (id / 64) completed
      have offset : id % 64 <
          (built.pages.getD (id / 64) (Array.emptyWithCapacity 0)).size := by
        rw [size]
        exact Nat.mod_lt id (by decide)
      have completedNext : id / 64 < (built.pages.push built.active).size := by
        simp only [Array.size_push]
        omega
      have sameChunk :
          (built.pages.push built.active).getD (id / 64) (Array.emptyWithCapacity 0) =
            built.pages.getD (id / 64) (Array.emptyWithCapacity 0) :=
        array_getD_push_old built.pages built.active (Array.emptyWithCapacity 0) (id / 64) completed
      have nextOffset : id % 64 <
          ((built.pages.push built.active).getD (id / 64) (Array.emptyWithCapacity 0)).size := by
        rw [sameChunk]
        exact offset
      rw [decoded_require_completed next id nextInside completedNext nextOffset,
        decoded_require_completed built id inside completed offset]
      change Except.ok
          (((built.pages.push built.active).getD (id / 64) (Array.emptyWithCapacity 0)).getD
            (id % 64) (PsKernelExpr.bvar 0)) =
        (Except.ok ((built.pages.getD (id / 64) (Array.emptyWithCapacity 0)).getD
          (id % 64) (PsKernelExpr.bvar 0)) : Except String PsKernelExpr)
      rw [sameChunk]
    · have completedNext : id / 64 < (built.pages.push built.active).size := by
        simp only [Array.size_push]
        omega
      have sameChunk :
          (built.pages.push built.active).getD (id / 64) (Array.emptyWithCapacity 0) =
            built.active := by
        rw [atActive, array_getD_push_new]
      have nextOffset : id % 64 <
          ((built.pages.push built.active).getD (id / 64) (Array.emptyWithCapacity 0)).size := by
        rw [sameChunk]
        exact offset
      rw [decoded_require_completed next id nextInside completedNext nextOffset,
        decoded_require_active built id inside atActive offset]
      change Except.ok
          (((built.pages.push built.active).getD (id / 64) (Array.emptyWithCapacity 0)).getD
            (id % 64) (PsKernelExpr.bvar 0)) =
        (Except.ok (built.active.getD (id % 64) (PsKernelExpr.bvar 0)) : Except String PsKernelExpr)
      rw [sameChunk]

theorem decoded_push_require_new (built : PsKernelExprV2Decoded)
    (expr : PsKernelExpr) (layout : DecodedLayout built) :
    psKernelExprV2DecodedRequire (psKernelExprV2DecodedPush built expr) built.size =
      Except.ok expr := by
  have nextInside : built.size < built.size + 1 := by omega
  by_cases space : built.active.size < 64
  · have lower : built.pages.size * 64 ≤ built.size := by
      have total := layout.size
      omega
    have upper : built.size < (built.pages.size + 1) * 64 := by
      have total := layout.size
      omega
    have page : built.size / 64 = built.pages.size :=
      Nat.div_eq_of_lt_le lower upper
    have offset : built.size % 64 = built.active.size := by
      have total := layout.size
      have division := Nat.div_add_mod built.size 64
      rw [page] at division
      omega
    rw [decoded_push_growing built expr space]
    let next := PsKernelExprV2Decoded.mk built.pages (built.active.push expr) (built.size + 1)
    change psKernelExprV2DecodedRequire next built.size = Except.ok expr
    have nextOffset : built.size % 64 < (built.active.push expr).size := by
      simp only [Array.size_push]
      omega
    rw [decoded_require_active next built.size nextInside page nextOffset]
    change Except.ok ((built.active.push expr).getD (built.size % 64) (PsKernelExpr.bvar 0)) =
      (Except.ok expr : Except String PsKernelExpr)
    rw [offset, array_getD_push_new]
  · have full : built.active.size = 64 := by
      have bounded := layout.active
      omega
    have total : built.size = (built.pages.size + 1) * 64 := by
      have sized := layout.size
      omega
    have page : built.size / 64 = built.pages.size + 1 := by
      rw [total]
      exact Nat.mul_div_cancel _ (by decide)
    have offset : built.size % 64 = 0 := by
      rw [total, Nat.mul_mod_left]
    rw [decoded_push_rollover built expr space]
    let next := PsKernelExprV2Decoded.mk (built.pages.push built.active) #[expr] (built.size + 1)
    change psKernelExprV2DecodedRequire next built.size = Except.ok expr
    have atActive : built.size / 64 = (built.pages.push built.active).size := by
      simpa only [Array.size_push] using page
    have nextOffset : built.size % 64 < (#[expr] : Array PsKernelExpr).size := by
      simp only [offset, Array.size_singleton]
      omega
    rw [decoded_require_active next built.size nextInside atActive nextOffset]
    change Except.ok ((#[expr] : Array PsKernelExpr).getD (built.size % 64) (PsKernelExpr.bvar 0)) =
      (Except.ok expr : Except String PsKernelExpr)
    simp [offset, Array.getD_eq_getD_getElem?]

theorem decoded_empty_prefix (meaning : Nat → PsKernelExpr) :
    DecodedPrefix psKernelExprV2DecodedEmpty meaning := by
  intro id inside
  simp [psKernelExprV2DecodedEmpty] at inside

theorem decoded_prefix_push (built : PsKernelExprV2Decoded)
    (meaning : Nat → PsKernelExpr) (layout : DecodedLayout built)
    (decoded : DecodedPrefix built meaning) :
    DecodedPrefix (psKernelExprV2DecodedPush built (meaning built.size)) meaning := by
  intro id inside
  have growth := decoded_push_size built (meaning built.size)
  by_cases isNew : id = built.size
  · subst id
    exact decoded_push_require_new built (meaning built.size) layout
  · have before : id < built.size := by omega
    exact (decoded_push_require_old built (meaning built.size) layout id before).trans
      (decoded id before)

/- This explicitly connects the five source metadata fields to the exact
   recursive expressions returned by production DecodedRequire. -/
theorem decoded_prefix_metadata
    (source : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix source meaning)
    (decoded : DecodedPrefix built meaning)
    (sameSize : built.size = source.size) :
    ∀ id, id < source.size →
      ∃ entry : PsKernelExprV2Entry,
        psKernelExprV2PagedFind source id = some entry ∧
        psKernelExprV2DecodedRequire built id = Except.ok (meaning id) ∧
        Corresponds entry (meaning id) := by
  intro id inside
  rcases semantic id inside with ⟨entry, found, _children, _interpretation, metadata⟩
  have insideBuilt : id < built.size := by omega
  exact ⟨entry, found, decoded id insideBuilt, metadata⟩

/- Conditional preservation covers every successful actual worker execution;
   it does not assume a bound sufficient to make that execution succeed. -/
theorem decode_canonical_fuel_ok_preserves
    (fuel : Nat) (source : PsKernelExprV2PagedArena)
    (built result : PsKernelExprV2Decoded) (id : Nat) (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix source meaning)
    (layout : DecodedLayout built) (decoded : DecodedPrefix built meaning)
    (position : built.size = id)
    (accepted : psKernelExprV2DecodeCanonicalFuel fuel source built id = Except.ok result) :
    DecodedLayout result ∧ DecodedPrefix result meaning ∧ result.size = source.size := by
  induction fuel generalizing built id with
  | zero =>
      simp [psKernelExprV2DecodeCanonicalFuel] at accepted
  | succ remaining ih =>
      simp only [psKernelExprV2DecodeCanonicalFuel] at accepted
      split at accepted
      · rename_i finished
        have atEnd : id = source.size := by
          simpa only [Nat.beq_eq] using finished
        have same : built = result := Except.ok.inj accepted
        subst result
        exact ⟨layout, decoded, position.trans atEnd⟩
      · cases found : psKernelExprV2PagedFind source id with
        | none =>
            simp [psKernelExprV2PagedRequire, found] at accepted
        | some entry =>
            have inside := found_id_is_in_bounds source id entry found
            have node := decoded_entry_interprets source built meaning id entry
              semantic decoded position inside found
            simp only [psKernelExprV2PagedRequire, found, node] at accepted
            have nextLayout := decoded_push_layout built (meaning id) layout
            have nextDecoded :
                DecodedPrefix (psKernelExprV2DecodedPush built (meaning id)) meaning := by
              simpa only [position] using decoded_prefix_push built meaning layout decoded
            have nextPosition :
                (psKernelExprV2DecodedPush built (meaning id)).size = Nat.succ id := by
              rw [decoded_push_size, position]
              rfl
            exact ih (psKernelExprV2DecodedPush built (meaning id)) (Nat.succ id)
              nextLayout nextDecoded nextPosition accepted

/- With one fuel unit per remaining source entry plus the terminal check,
   the real worker succeeds. All storage and lookup invariants are carried
   from its actual starting owner and the fixed shared source interpretation. -/
theorem decode_canonical_fuel_succeeds
    (fuel : Nat) (source : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded) (id : Nat) (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix source meaning)
    (layout : DecodedLayout built) (decoded : DecodedPrefix built meaning)
    (position : built.size = id) (within : id ≤ source.size)
    (enough : source.size - id < fuel) :
    ∃ result : PsKernelExprV2Decoded,
      psKernelExprV2DecodeCanonicalFuel fuel source built id = Except.ok result ∧
      DecodedLayout result ∧ DecodedPrefix result meaning ∧ result.size = source.size := by
  induction fuel generalizing built id with
  | zero => omega
  | succ remaining ih =>
      by_cases finished : id = source.size
      · refine ⟨built, ?_, layout, decoded, position.trans finished⟩
        simp [psKernelExprV2DecodeCanonicalFuel, Nat.beq_eq, finished]
      · have inside : id < source.size := by omega
        rcases semantic id inside with ⟨entry, found, _children, _interpretation, _metadata⟩
        have node := decoded_entry_interprets source built meaning id entry
          semantic decoded position inside found
        have nextLayout := decoded_push_layout built (meaning id) layout
        have nextDecoded :
            DecodedPrefix (psKernelExprV2DecodedPush built (meaning id)) meaning := by
          simpa only [position] using decoded_prefix_push built meaning layout decoded
        have nextPosition :
            (psKernelExprV2DecodedPush built (meaning id)).size = Nat.succ id := by
          rw [decoded_push_size, position]
          rfl
        have nextWithin : Nat.succ id ≤ source.size := by omega
        have nextEnough : source.size - Nat.succ id < remaining := by omega
        rcases ih (psKernelExprV2DecodedPush built (meaning id)) (Nat.succ id)
            nextLayout nextDecoded nextPosition nextWithin nextEnough with
          ⟨result, ran, resultLayout, resultDecoded, resultSize⟩
        refine ⟨result, ?_, resultLayout, resultDecoded, resultSize⟩
        simpa only [psKernelExprV2DecodeCanonicalFuel, Nat.beq_eq, finished, ite_false,
          psKernelExprV2PagedRequire, found, node] using ran

/- No layout, prefix, semantic-map or decoded-buffer premise is imposed on
   the external source. Its successful public validation establishes the map;
   the public decoder itself creates and preserves its empty 64-entry owner. -/
theorem decode_checked_succeeds_after_validate
    (source canonical : PsKernelExprV2PagedArena)
    (validated : psKernelExprV2PagedValidate source = Except.ok canonical) :
    ∃ built : PsKernelExprV2Decoded, ∃ meaning : Nat → PsKernelExpr,
      psKernelExprV2DecodeChecked source = Except.ok built ∧
      DecodedLayout built ∧
      built.size = source.size ∧
      SemanticPrefix source meaning ∧
      DecodedPrefix built meaning ∧
      (∀ id, id < source.size →
        ∃ entry : PsKernelExprV2Entry,
          psKernelExprV2PagedFind source id = some entry ∧
          psKernelExprV2DecodedRequire built id = Except.ok (meaning id) ∧
          Corresponds entry (meaning id)) := by
  rcases validate_ok_establishes_semantic_prefixes source canonical validated with
    ⟨meaning, _canonicalLayout, sameSize, canonicalSemantic, sourceSemantic, _aligned⟩
  rcases decode_canonical_fuel_succeeds (Nat.succ canonical.size) canonical
      psKernelExprV2DecodedEmpty 0 meaning canonicalSemantic
      decoded_empty_layout (decoded_empty_prefix meaning) rfl (Nat.zero_le _) (by omega) with
    ⟨built, ran, layout, decoded, size⟩
  have sourceSize : built.size = source.size := size.trans sameSize
  refine ⟨built, meaning, ?_, layout, sourceSize, sourceSemantic, decoded, ?_⟩
  · simpa only [psKernelExprV2DecodeChecked, validated] using ran
  · exact decoded_prefix_metadata source built meaning sourceSemantic decoded sourceSize

/- Every successful public decoded result has the same internally derived
   guarantees, even when the caller supplies no validation evidence separately. -/
theorem decode_checked_ok_corresponds
    (source : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (accepted : psKernelExprV2DecodeChecked source = Except.ok built) :
    DecodedLayout built ∧ built.size = source.size ∧
      ∃ meaning : Nat → PsKernelExpr,
        SemanticPrefix source meaning ∧
        DecodedPrefix built meaning ∧
        (∀ id, id < source.size →
          ∃ entry : PsKernelExprV2Entry,
            psKernelExprV2PagedFind source id = some entry ∧
            psKernelExprV2DecodedRequire built id = Except.ok (meaning id) ∧
            Corresponds entry (meaning id)) := by
  cases validated : psKernelExprV2PagedValidate source with
  | error error =>
      simp [psKernelExprV2DecodeChecked, validated] at accepted
  | ok canonical =>
      rcases decode_checked_succeeds_after_validate source canonical validated with
        ⟨result, meaning, ran, layout, size, semantic, decoded, metadata⟩
      have same : result = built := Except.ok.inj (ran.symm.trans accepted)
      subst result
      exact ⟨layout, size, meaning, semantic, decoded, metadata⟩

end PsKernelExprV2DecodedBridgeProofs

#print axioms PsKernelExprV2DecodedBridgeProofs.decoded_empty_layout
#print axioms PsKernelExprV2DecodedBridgeProofs.decoded_push_size
#print axioms PsKernelExprV2DecodedBridgeProofs.decoded_push_layout
#print axioms PsKernelExprV2DecodedBridgeProofs.decoded_push_require_old
#print axioms PsKernelExprV2DecodedBridgeProofs.decoded_push_require_new
#print axioms PsKernelExprV2DecodedBridgeProofs.decoded_empty_prefix
#print axioms PsKernelExprV2DecodedBridgeProofs.decoded_prefix_push
#print axioms PsKernelExprV2DecodedBridgeProofs.decoded_prefix_metadata
#print axioms PsKernelExprV2DecodedBridgeProofs.decode_canonical_fuel_ok_preserves
#print axioms PsKernelExprV2DecodedBridgeProofs.decode_canonical_fuel_succeeds
#print axioms PsKernelExprV2DecodedBridgeProofs.decode_checked_succeeds_after_validate
#print axioms PsKernelExprV2DecodedBridgeProofs.decode_checked_ok_corresponds
