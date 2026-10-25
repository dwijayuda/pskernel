import PsKernelExprV2ReplayMetadataProofs

/-!
A consistent semantic witness for the actual paged replay validator.

Meaning is one total map from node IDs to recursive expressions. Every in-range
node is interpreted from that same map, and every child is strictly earlier
than its parent. The five cached fields correspond to that interpretation.
No equality of expressions is inferred from cached hashes or metadata.

Layout remains a separate physical storage invariant. This module connects
successful production ReplayNode and ValidateFuel to complete source and
canonical semantic prefixes. It does not prove correspondence with the
executable paged decoder, nor a checker-wide ArenaModel or soundness theorem.
-/
namespace PsKernelExprV2SemanticPrefixProofs

open PsKernelExprV2MetadataProofs
open PsKernelExprV2PagedModelProofs
open PsKernelExprV2ReplayMetadataProofs

def Interpret (meaning : Nat → PsKernelExpr) : PsKernelExprV2Node → PsKernelExpr
  | .bvar index => .bvar index
  | .fvar name => .fvar name
  | .mvar name => .mvar name
  | .sort level => .sort level
  | .const name levels => .const name levels
  | .lit literal => .lit literal
  | .app fn arg => .app (meaning fn) (meaning arg)
  | .lam name type body info => .lam name (meaning type) (meaning body) info
  | .forallE name type body info => .forallE name (meaning type) (meaning body) info
  | .letE name type value body nondep =>
      .letE name (meaning type) (meaning value) (meaning body) nondep
  | .mdata tag body => .mdata tag (meaning body)
  | .proj name index body => .proj name index (meaning body)

def ChildrenBefore (bound : Nat) : PsKernelExprV2Node → Prop
  | .app fn arg => fn < bound ∧ arg < bound
  | .lam _ type body _ => type < bound ∧ body < bound
  | .forallE _ type body _ => type < bound ∧ body < bound
  | .letE _ type value body _ => type < bound ∧ value < bound ∧ body < bound
  | .mdata _ body => body < bound
  | .proj _ _ body => body < bound
  | _ => True

def SemanticPrefix (arena : PsKernelExprV2PagedArena)
    (meaning : Nat → PsKernelExpr) : Prop :=
  ∀ id, id < arena.size →
    ∃ entry : PsKernelExprV2Entry,
      psKernelExprV2PagedFind arena id = some entry ∧
      ChildrenBefore id entry.node ∧
      meaning id = Interpret meaning entry.node ∧
      Corresponds entry (meaning id)

def AlignedPrefix (source canonical : PsKernelExprV2PagedArena) : Prop :=
  ∀ id, id < canonical.size →
    ∃ original computed : PsKernelExprV2Entry,
      psKernelExprV2PagedFind source id = some original ∧
      psKernelExprV2PagedFind canonical id = some computed ∧
      original.node = computed.node ∧
      psKernelExprV2PortableSameMetadata original computed = true

def ExtendMeaning (meaning : Nat → PsKernelExpr) (fresh : Nat)
    (value : PsKernelExpr) : Nat → PsKernelExpr :=
  fun id => if id = fresh then value else meaning id

theorem interpret_congr_below
    (bound : Nat) (node : PsKernelExprV2Node)
    (first second : Nat → PsKernelExpr)
    (before : ChildrenBefore bound node)
    (agree : ∀ id, id < bound → first id = second id) :
    Interpret first node = Interpret second node := by
  cases node with
  | bvar index => rfl
  | fvar name => rfl
  | mvar name => rfl
  | sort level => rfl
  | const name levels => rfl
  | lit literal => rfl
  | app fn arg =>
      change PsKernelExpr.app (first fn) (first arg) =
        PsKernelExpr.app (second fn) (second arg)
      rw [agree fn before.1, agree arg before.2]
  | lam name type body info =>
      change PsKernelExpr.lam name (first type) (first body) info =
        PsKernelExpr.lam name (second type) (second body) info
      rw [agree type before.1, agree body before.2]
  | forallE name type body info =>
      change PsKernelExpr.forallE name (first type) (first body) info =
        PsKernelExpr.forallE name (second type) (second body) info
      rw [agree type before.1, agree body before.2]
  | letE name type value body nondep =>
      change PsKernelExpr.letE name (first type) (first value) (first body) nondep =
        PsKernelExpr.letE name (second type) (second value) (second body) nondep
      rw [agree type before.1, agree value before.2.1, agree body before.2.2]
  | mdata tag body =>
      change PsKernelExpr.mdata tag (first body) = PsKernelExpr.mdata tag (second body)
      rw [agree body before]
  | proj name index body =>
      change PsKernelExpr.proj name index (first body) =
        PsKernelExpr.proj name index (second body)
      rw [agree body before]

theorem extend_meaning_preserves_old
    (meaning : Nat → PsKernelExpr) (fresh id : Nat) (value : PsKernelExpr)
    (before : id < fresh) :
    ExtendMeaning meaning fresh value id = meaning id := by
  simp only [ExtendMeaning, if_neg (Nat.ne_of_lt before)]

private theorem empty_size (limit : Nat) :
    (psKernelExprV2PagedEmptyWithLimit limit).size = 0 := by
  unfold psKernelExprV2PagedEmptyWithLimit
  split <;> rfl

theorem empty_semantic_prefix (limit : Nat) (meaning : Nat → PsKernelExpr) :
    SemanticPrefix (psKernelExprV2PagedEmptyWithLimit limit) meaning := by
  intro id inside
  have size := empty_size limit
  omega

private theorem empty_aligned_prefix (source : PsKernelExprV2PagedArena) (limit : Nat) :
    AlignedPrefix source (psKernelExprV2PagedEmptyWithLimit limit) := by
  intro id inside
  have size := empty_size limit
  omega

private theorem metadata_of_find
    (arena : PsKernelExprV2PagedArena) (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix arena meaning)
    (id : Nat) (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedFind arena id = some entry) :
    Corresponds entry (meaning id) := by
  have inside := found_id_is_in_bounds arena id entry found
  rcases semantic id inside with ⟨other, lookup, _, _, metadata⟩
  have same : other = entry := Option.some.inj (lookup.symm.trans found)
  cases same
  exact metadata

private theorem with1_success_lookup
    (arena : PsKernelExprV2PagedArena) (child : Nat)
    (make : PsKernelExprV2Entry → PsKernelExprV2Entry)
    (inserted : PsKernelExprV2PagedArena × Nat)
    (accepted : psKernelExprV2PagedWith1 arena child make = Except.ok inserted) :
    ∃ entry, psKernelExprV2PagedFind arena child = some entry := by
  cases found : psKernelExprV2PagedFind arena child with
  | none =>
      simp [psKernelExprV2PagedWith1, psKernelExprV2PagedRequire, found] at accepted
  | some entry => exact ⟨entry, rfl⟩

private theorem with2_success_lookups
    (arena : PsKernelExprV2PagedArena) (left right : Nat)
    (make : PsKernelExprV2Entry → PsKernelExprV2Entry → PsKernelExprV2Entry)
    (inserted : PsKernelExprV2PagedArena × Nat)
    (accepted : psKernelExprV2PagedWith2 arena left right make = Except.ok inserted) :
    ∃ a b, psKernelExprV2PagedFind arena left = some a ∧
      psKernelExprV2PagedFind arena right = some b := by
  cases first : psKernelExprV2PagedFind arena left with
  | none =>
      simp [psKernelExprV2PagedWith2, psKernelExprV2PagedRequire, first] at accepted
  | some a =>
      cases second : psKernelExprV2PagedFind arena right with
      | none =>
          simp [psKernelExprV2PagedWith2, psKernelExprV2PagedRequire, first, second] at accepted
      | some b => exact ⟨a, b, rfl, rfl⟩

private theorem with3_success_lookups
    (arena : PsKernelExprV2PagedArena) (first second third : Nat)
    (make : PsKernelExprV2Entry → PsKernelExprV2Entry →
      PsKernelExprV2Entry → PsKernelExprV2Entry)
    (inserted : PsKernelExprV2PagedArena × Nat)
    (accepted : psKernelExprV2PagedWith3 arena first second third make = Except.ok inserted) :
    ∃ a b c, psKernelExprV2PagedFind arena first = some a ∧
      psKernelExprV2PagedFind arena second = some b ∧
      psKernelExprV2PagedFind arena third = some c := by
  cases firstFound : psKernelExprV2PagedFind arena first with
  | none =>
      simp [psKernelExprV2PagedWith3, psKernelExprV2PagedRequire, firstFound] at accepted
  | some a =>
      cases secondFound : psKernelExprV2PagedFind arena second with
      | none =>
          simp [psKernelExprV2PagedWith3, psKernelExprV2PagedRequire,
            firstFound, secondFound] at accepted
      | some b =>
          cases thirdFound : psKernelExprV2PagedFind arena third with
          | none =>
              simp [psKernelExprV2PagedWith3, psKernelExprV2PagedRequire,
                firstFound, secondFound, thirdFound] at accepted
          | some c => exact ⟨a, b, c, rfl, rfl, rfl⟩

/- Success obtains child witnesses from actual production lookups. The caller
   does not supply a new node's metadata or an arbitrary expression witness. -/
theorem replay_success_inputs
    (arena : PsKernelExprV2PagedArena) (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix arena meaning) (node : PsKernelExprV2Node)
    (inserted : PsKernelExprV2PagedArena × Nat)
    (accepted : psKernelExprV2PagedReplayNode arena node = Except.ok inserted) :
    ReplayInputs arena node (Interpret meaning node) ∧ ChildrenBefore arena.size node := by
  cases node with
  | bvar index => exact ⟨ReplayInputs.bvar index, True.intro⟩
  | fvar name => exact ⟨ReplayInputs.fvar name, True.intro⟩
  | mvar name => exact ⟨ReplayInputs.mvar name, True.intro⟩
  | sort level => exact ⟨ReplayInputs.sort level, True.intro⟩
  | const name levels => exact ⟨ReplayInputs.const name levels, True.intro⟩
  | lit literal => exact ⟨ReplayInputs.lit literal, True.intro⟩
  | app fn arg =>
      rcases with2_success_lookups arena fn arg (psKernelExprV2AppEntry fn arg)
        inserted accepted with ⟨f, a, fnLookup, argLookup⟩
      exact ⟨ReplayInputs.app fn arg f a (meaning fn) (meaning arg)
        fnLookup argLookup
        (metadata_of_find arena meaning semantic fn f fnLookup)
        (metadata_of_find arena meaning semantic arg a argLookup),
        found_id_is_in_bounds arena fn f fnLookup,
        found_id_is_in_bounds arena arg a argLookup⟩
  | lam name type body info =>
      rcases with2_success_lookups arena type body (psKernelExprV2LamEntry name type body info)
        inserted accepted with ⟨t, b, typeLookup, bodyLookup⟩
      exact ⟨ReplayInputs.lam name type body info t b (meaning type) (meaning body)
        typeLookup bodyLookup
        (metadata_of_find arena meaning semantic type t typeLookup)
        (metadata_of_find arena meaning semantic body b bodyLookup),
        found_id_is_in_bounds arena type t typeLookup,
        found_id_is_in_bounds arena body b bodyLookup⟩
  | forallE name type body info =>
      rcases with2_success_lookups arena type body (psKernelExprV2ForallEntry name type body info)
        inserted accepted with ⟨t, b, typeLookup, bodyLookup⟩
      exact ⟨ReplayInputs.forallE name type body info t b (meaning type) (meaning body)
        typeLookup bodyLookup
        (metadata_of_find arena meaning semantic type t typeLookup)
        (metadata_of_find arena meaning semantic body b bodyLookup),
        found_id_is_in_bounds arena type t typeLookup,
        found_id_is_in_bounds arena body b bodyLookup⟩
  | letE name type value body nondep =>
      rcases with3_success_lookups arena type value body
        (psKernelExprV2LetEntry name type value body nondep) inserted accepted with
        ⟨t, v, b, typeLookup, valueLookup, bodyLookup⟩
      exact ⟨ReplayInputs.letE name type value body nondep t v b
        (meaning type) (meaning value) (meaning body) typeLookup valueLookup bodyLookup
        (metadata_of_find arena meaning semantic type t typeLookup)
        (metadata_of_find arena meaning semantic value v valueLookup)
        (metadata_of_find arena meaning semantic body b bodyLookup),
        found_id_is_in_bounds arena type t typeLookup,
        found_id_is_in_bounds arena value v valueLookup,
        found_id_is_in_bounds arena body b bodyLookup⟩
  | mdata tag body =>
      rcases with1_success_lookup arena body (psKernelExprV2MDataEntry tag body)
        inserted accepted with ⟨b, bodyLookup⟩
      exact ⟨ReplayInputs.mdata tag body b (meaning body) bodyLookup
        (metadata_of_find arena meaning semantic body b bodyLookup),
        found_id_is_in_bounds arena body b bodyLookup⟩
  | proj name index body =>
      rcases with1_success_lookup arena body (psKernelExprV2ProjEntry name index body)
        inserted accepted with ⟨b, bodyLookup⟩
      exact ⟨ReplayInputs.proj name index body b (meaning body) bodyLookup
        (metadata_of_find arena meaning semantic body b bodyLookup),
        found_id_is_in_bounds arena body b bodyLookup⟩

/- Replay extends the same map only at its fresh ID; old syntax equations,
   metadata witnesses and actual lookups all remain valid. -/
theorem replay_preserves_semantic_prefix
    (arena : PsKernelExprV2PagedArena) (meaning : Nat → PsKernelExpr)
    (layout : Layout arena) (semantic : SemanticPrefix arena meaning)
    (node : PsKernelExprV2Node) (inserted : PsKernelExprV2PagedArena × Nat)
    (accepted : psKernelExprV2PagedReplayNode arena node = Except.ok inserted) :
    ∃ nextMeaning : Nat → PsKernelExpr,
      inserted.snd = arena.size ∧
      inserted.fst.size = arena.size + 1 ∧
      Layout inserted.fst ∧
      SemanticPrefix inserted.fst nextMeaning ∧
      (∀ id, id < arena.size → nextMeaning id = meaning id) ∧
      (∀ id, id < arena.size →
        psKernelExprV2PagedFind inserted.fst id = psKernelExprV2PagedFind arena id) ∧
      (∀ entry, psKernelExprV2PagedFind inserted.fst inserted.snd = some entry →
        entry.node = node) := by
  rcases replay_success_inputs arena meaning semantic node inserted accepted with
    ⟨inputs, children⟩
  rcases replay_node_preserves_layout_and_metadata arena node
      (Interpret meaning node) inserted layout inputs accepted with
    ⟨fresh, growth, _limit, nextLayout, frame, entry, entryLookup, nodeEq, metadata⟩
  let nextMeaning := ExtendMeaning meaning arena.size (Interpret meaning node)
  have agreement : ∀ id, id < arena.size → nextMeaning id = meaning id := by
    intro id before
    exact extend_meaning_preserves_old meaning arena.size id (Interpret meaning node) before
  have newValue : nextMeaning arena.size = Interpret meaning node := by
    simp [nextMeaning, ExtendMeaning]
  have nodeStable : Interpret nextMeaning node = Interpret meaning node :=
    interpret_congr_below arena.size node nextMeaning meaning children agreement
  have newLookup : psKernelExprV2PagedFind inserted.fst arena.size = some entry := by
    simpa only [fresh] using entryLookup
  refine ⟨nextMeaning, fresh, growth, nextLayout, ?_, agreement, frame, ?_⟩
  · intro id inside
    by_cases isNew : id = arena.size
    · subst id
      refine ⟨entry, newLookup, ?_, ?_, ?_⟩
      · simpa only [nodeEq] using children
      · rw [nodeEq]
        exact newValue.trans nodeStable.symm
      · rw [newValue]
        exact metadata
    · have before : id < arena.size := by omega
      rcases semantic id before with ⟨oldEntry, oldLookup, oldChildren, oldValue, oldMetadata⟩
      refine ⟨oldEntry, (frame id before).trans oldLookup, oldChildren, ?_, ?_⟩
      · have stable : Interpret nextMeaning oldEntry.node = Interpret meaning oldEntry.node :=
          interpret_congr_below id oldEntry.node nextMeaning meaning oldChildren
            (fun child earlier => agreement child (by omega))
        exact (agreement id before).trans (oldValue.trans stable.symm)
      · rw [agreement id before]
        exact oldMetadata
  · intro computed lookup
    have same : computed = entry := Option.some.inj (lookup.symm.trans entryLookup)
    exact (congrArg PsKernelExprV2Entry.node same).trans nodeEq

private theorem aligned_prefix_extend
    (source canonical next : PsKernelExprV2PagedArena)
    (original computed : PsKernelExprV2Entry)
    (aligned : AlignedPrefix source canonical)
    (growth : next.size = canonical.size + 1)
    (frame : ∀ id, id < canonical.size →
      psKernelExprV2PagedFind next id = psKernelExprV2PagedFind canonical id)
    (originalLookup : psKernelExprV2PagedFind source canonical.size = some original)
    (computedLookup : psKernelExprV2PagedFind next canonical.size = some computed)
    (sameNode : original.node = computed.node)
    (sameMetadata : psKernelExprV2PortableSameMetadata original computed = true) :
    AlignedPrefix source next := by
  intro id inside
  by_cases isNew : id = canonical.size
  · subst id
    exact ⟨original, computed, originalLookup, computedLookup, sameNode, sameMetadata⟩
  · have before : id < canonical.size := by omega
    rcases aligned id before with ⟨oldOriginal, oldComputed, oldSource, oldCanonical, oldNode, oldMetadata⟩
    exact ⟨oldOriginal, oldComputed, oldSource, (frame id before).trans oldCanonical,
      oldNode, oldMetadata⟩

/- Metadata transfer alone is insufficient: the alignment premise also carries
   exact node equality. Both arenas then have the same structural interpretation. -/
theorem aligned_prefix_transfers_semantics
    (source canonical : PsKernelExprV2PagedArena) (meaning : Nat → PsKernelExpr)
    (sameSize : canonical.size = source.size)
    (semantic : SemanticPrefix canonical meaning)
    (aligned : AlignedPrefix source canonical) :
    SemanticPrefix source meaning := by
  intro id inside
  have insideCanonical : id < canonical.size := by omega
  rcases semantic id insideCanonical with ⟨entry, lookup, children, interpretation, metadata⟩
  rcases aligned id insideCanonical with
    ⟨original, computed, originalLookup, computedLookup, nodeEq, metadataEq⟩
  have same : computed = entry := Option.some.inj (computedLookup.symm.trans lookup)
  subst computed
  refine ⟨original, originalLookup, ?_, ?_, ?_⟩
  · simpa only [nodeEq] using children
  · simpa only [nodeEq] using interpretation
  · exact portable_same_metadata_transfers_correspondence original entry
      (meaning id) metadata metadataEq

/- The induction starts from an internally established prefix, never from
   an assumed correspondence for the untrusted source. Each accepted source
   entry is paired with the exact node independently replayed at the same ID. -/
theorem validate_fuel_preserves_semantic_prefix
    (fuel : Nat) (source canonical result : PsKernelExprV2PagedArena)
    (id : Nat) (meaning : Nat → PsKernelExpr)
    (position : canonical.size = id)
    (layout : Layout canonical)
    (semantic : SemanticPrefix canonical meaning)
    (aligned : AlignedPrefix source canonical)
    (accepted : psKernelExprV2PagedValidateFuel fuel source canonical id = Except.ok result) :
    ∃ finalMeaning : Nat → PsKernelExpr,
      Layout result ∧
      SemanticPrefix result finalMeaning ∧
      AlignedPrefix source result ∧
      result.size = source.size ∧
      (∀ oldId, oldId < canonical.size → finalMeaning oldId = meaning oldId) := by
  induction fuel generalizing canonical id meaning with
  | zero =>
      simp [psKernelExprV2PagedValidateFuel] at accepted
  | succ remaining ih =>
      simp only [psKernelExprV2PagedValidateFuel] at accepted
      split at accepted
      · rename_i finished
        have atEnd : id = source.size := by
          simpa only [Nat.beq_eq] using finished
        have same : canonical = result := Except.ok.inj accepted
        subst result
        refine ⟨meaning, layout, semantic, aligned, position.trans atEnd, ?_⟩
        intro oldId before
        rfl
      · cases found : psKernelExprV2PagedFind source id with
        | none =>
            simp [found] at accepted
        | some original =>
            simp only [found] at accepted
            cases replayed : psKernelExprV2PagedReplayNode canonical original.node with
            | error error =>
                simp [replayed] at accepted
            | ok inserted =>
                simp only [replayed] at accepted
                rcases replay_preserves_semantic_prefix canonical meaning layout semantic
                    original.node inserted replayed with
                  ⟨nextMeaning, fresh, growth, nextLayout, nextPrefix, agreement, frame, nodeAt⟩
                split at accepted
                · cases foundNext : psKernelExprV2PagedFind inserted.fst inserted.snd with
                  | none =>
                      simp [foundNext] at accepted
                  | some computed =>
                      simp only [foundNext] at accepted
                      split at accepted
                      · rename_i sameMetadata
                        have originalAtSize :
                            psKernelExprV2PagedFind source canonical.size = some original := by
                          simpa only [position] using found
                        have computedAtSize :
                            psKernelExprV2PagedFind inserted.fst canonical.size = some computed := by
                          simpa only [fresh] using foundNext
                        have nextAligned : AlignedPrefix source inserted.fst :=
                          aligned_prefix_extend source canonical inserted.fst original computed
                            aligned growth frame originalAtSize computedAtSize
                            (nodeAt computed foundNext).symm sameMetadata
                        have nextPosition : inserted.fst.size = Nat.succ id := by omega
                        rcases ih inserted.fst (Nat.succ id) nextMeaning nextPosition
                            nextLayout nextPrefix nextAligned accepted with
                          ⟨finalMeaning, finalLayout, finalPrefix, finalAligned, finalSize, tailAgreement⟩
                        refine ⟨finalMeaning, finalLayout, finalPrefix, finalAligned, finalSize, ?_⟩
                        intro oldId before
                        have nextBefore : oldId < inserted.fst.size := by omega
                        exact (tailAgreement oldId nextBefore).trans (agreement oldId before)
                      · contradiction
                · contradiction

/- The public fail-closed entry establishes both complete semantic prefixes
   from its actual successful result. No validity premise is imposed on source.
   Executable decoder correspondence and checker semantics remain separate. -/
theorem validate_ok_establishes_semantic_prefixes
    (source canonical : PsKernelExprV2PagedArena)
    (accepted : psKernelExprV2PagedValidate source = Except.ok canonical) :
    ∃ meaning : Nat → PsKernelExpr,
      Layout canonical ∧
      canonical.size = source.size ∧
      SemanticPrefix canonical meaning ∧
      SemanticPrefix source meaning ∧
      AlignedPrefix source canonical := by
  cases shape : psKernelExprV2PagedShapeValid source with
  | false =>
      simp [psKernelExprV2PagedValidate, shape] at accepted
  | true =>
      have validated :
          psKernelExprV2PagedValidateFuel (Nat.succ source.size) source
            (psKernelExprV2PagedEmptyWithLimit source.pageLimit) 0 = Except.ok canonical := by
        simpa only [psKernelExprV2PagedValidate, shape, ite_true] using accepted
      rcases validate_fuel_preserves_semantic_prefix (Nat.succ source.size) source
          (psKernelExprV2PagedEmptyWithLimit source.pageLimit) canonical 0
          (fun _ => PsKernelExpr.bvar 0)
          (empty_size source.pageLimit) (empty_layout source.pageLimit)
          (empty_semantic_prefix source.pageLimit (fun _ => PsKernelExpr.bvar 0))
          (empty_aligned_prefix source source.pageLimit) validated with
        ⟨meaning, layout, semantic, aligned, size, _agreement⟩
      exact ⟨meaning, layout, size, semantic,
        aligned_prefix_transfers_semantics source canonical meaning size semantic aligned, aligned⟩

end PsKernelExprV2SemanticPrefixProofs

#print axioms PsKernelExprV2SemanticPrefixProofs.interpret_congr_below
#print axioms PsKernelExprV2SemanticPrefixProofs.extend_meaning_preserves_old
#print axioms PsKernelExprV2SemanticPrefixProofs.empty_semantic_prefix
#print axioms PsKernelExprV2SemanticPrefixProofs.replay_success_inputs
#print axioms PsKernelExprV2SemanticPrefixProofs.replay_preserves_semantic_prefix
#print axioms PsKernelExprV2SemanticPrefixProofs.aligned_prefix_transfers_semantics
#print axioms PsKernelExprV2SemanticPrefixProofs.validate_fuel_preserves_semantic_prefix
#print axioms PsKernelExprV2SemanticPrefixProofs.validate_ok_establishes_semantic_prefixes
