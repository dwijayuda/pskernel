import PsKernelExprV2DecodedBridgeProofs
import PsKernelOrdinaryOccurrenceProofs

/-!
Connect successful public production validation and decoding to the existing
ordinary-inductive ArenaModel. The model's shape, sound-depth and child-ID
premises are established from replay; none is assumed of untrusted input.
The final two theorems instantiate existing worker correspondence using that
established model. This is a structural-worker bridge, not a global kernel
soundness or backend-preservation theorem.
-/
namespace PsKernelExprV2ArenaModelBridgeProofs

open PsKernelExprV2MetadataProofs
open PsKernelExprV2PagedModelProofs
open PsKernelExprV2SemanticPrefixProofs
open PsKernelExprV2DecodedNodeProofs
open PsKernelExprV2DecodedBridgeProofs
open PsKernelOrdinaryOccurrenceProofs

theorem interpret_eq_node_expr (meaning : Nat → PsKernelExpr)
    (node : PsKernelExprV2Node) :
    Interpret meaning node = nodeExpr meaning node := by
  cases node <;> rfl

theorem children_before_child_ids (bound : Nat) (node : PsKernelExprV2Node)
    (before : ChildrenBefore bound node) (child : Nat)
    (member : child ∈ childIds node) : child < bound := by
  cases node <;>
    simp_all [ChildrenBefore, childIds, psKernelExprV2TransformChildren] <;> omega

private theorem semantic_lookup
    (arena : PsKernelExprV2PagedArena) (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix arena meaning) (root : Nat)
    (entry : PsKernelExprV2Entry)
    (found : psKernelExprV2PagedFind arena root = some entry) :
    ChildrenBefore root entry.node ∧
      meaning root = Interpret meaning entry.node ∧
      Corresponds entry (meaning root) := by
  have inside := found_id_is_in_bounds arena root entry found
  rcases semantic root inside with ⟨witness, lookup, children, value, metadata⟩
  have same : witness = entry := Option.some.inj (lookup.symm.trans found)
  subst witness
  exact ⟨children, value, metadata⟩

theorem semantic_prefix_establishes_arena_model
    (arena : PsKernelExprV2PagedArena) (meaning : Nat → PsKernelExpr)
    (semantic : SemanticPrefix arena meaning) :
    ArenaModel arena meaning := by
  constructor
  · intro root entry found
    rcases semantic_lookup arena meaning semantic root entry found with
      ⟨_children, value, _metadata⟩
    exact value.trans (interpret_eq_node_expr meaning entry.node)
  · intro root entry found
    rcases semantic_lookup arena meaning semantic root entry found with
      ⟨_children, _value, metadata⟩
    exact Nat.le_of_eq metadata.depth.symm
  · intro root entry found child member
    have inside := found_id_is_in_bounds arena root entry found
    rcases semantic_lookup arena meaning semantic root entry found with
      ⟨children, _value, _metadata⟩
    have earlier := children_before_child_ids root entry.node children child member
    rcases semantic child (Nat.lt_trans earlier inside) with
      ⟨childEntry, childLookup, _children, _value, _metadata⟩
    exact ⟨childEntry, childLookup⟩

theorem validate_ok_establishes_arena_models
    (source canonical : PsKernelExprV2PagedArena)
    (validated : psKernelExprV2PagedValidate source = Except.ok canonical) :
    ∃ meaning : Nat → PsKernelExpr,
      ArenaModel source meaning ∧ ArenaModel canonical meaning ∧
      canonical.size = source.size := by
  rcases validate_ok_establishes_semantic_prefixes source canonical validated with
    ⟨meaning, _layout, size, canonicalSemantic, sourceSemantic, _aligned⟩
  exact ⟨meaning,
    semantic_prefix_establishes_arena_model source meaning sourceSemantic,
    semantic_prefix_establishes_arena_model canonical meaning canonicalSemantic, size⟩

theorem decode_checked_ok_establishes_arena_model
    (source : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (accepted : psKernelExprV2DecodeChecked source = Except.ok built) :
    ∃ meaning : Nat → PsKernelExpr,
      ArenaModel source meaning ∧ DecodedPrefix built meaning ∧
      built.size = source.size := by
  rcases decode_checked_ok_corresponds source built accepted with
    ⟨_layout, size, meaning, semantic, decoded, _metadata⟩
  exact ⟨meaning, semantic_prefix_establishes_arena_model source meaning semantic,
    decoded, size⟩

/- The external caller supplies only public validation success and a real
   in-range root lookup, not the structural model used by the older theorem. -/
theorem validated_uniform_occurrence_correspondence
    (source canonical : PsKernelExprV2PagedArena)
    (validated : psKernelExprV2PagedValidate source = Except.ok canonical)
    (root : Nat) (rootValid : validId source root)
    (declaredNames : List PsKernelName) (expectedLevels : List PsKernelLevel)
    (numParams offset : Nat) :
    ∃ meaning : Nat → PsKernelExpr,
      ArenaModel source meaning ∧
      psKernelExprV2OrdinaryUniformOccurrenceOnCanonical source
          declaredNames expectedLevels numParams root offset =
        psKernelSimpleCheckUniformOccurrence
          declaredNames expectedLevels numParams (meaning root) offset := by
  rcases validate_ok_establishes_arena_models source canonical validated with
    ⟨meaning, model, _canonicalModel, _size⟩
  exact ⟨meaning, model,
    uniform_occurrence_on_canonical_correspondence source meaning model root
      rootValid declaredNames expectedLevels numParams offset⟩

/- Connect the worker's returned ID to the actual production decoded value.
   A well-formed abstract map alone is not used as a decoder certificate. -/
theorem decoded_annotations_correspondence
    (source : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (accepted : psKernelExprV2DecodeChecked source = Except.ok built)
    (root : Nat) (rootValid : validId source root) :
    ∃ meaning : Nat → PsKernelExpr, ∃ result : Nat,
      ArenaModel source meaning ∧
      psKernelExprV2DecodedRequire built root = Except.ok (meaning root) ∧
      psKernelExprV2OrdinaryConsumeTypeAnnotationsOnCanonical source root =
        Except.ok result ∧
      validId source result ∧
      psKernelExprV2DecodedRequire built result =
        Except.ok (psKernelExprConsumeTypeAnnotations (meaning root)) := by
  rcases decode_checked_ok_establishes_arena_model source built accepted with
    ⟨meaning, model, decoded, size⟩
  rcases annotations_on_canonical_correspondence source meaning model root rootValid with
    ⟨result, ran, resultValid, resultValue⟩
  rcases rootValid with ⟨rootEntry, rootLookup⟩
  rcases resultValid with ⟨resultEntry, resultLookup⟩
  have rootInside := found_id_is_in_bounds source root rootEntry rootLookup
  have resultInside := found_id_is_in_bounds source result resultEntry resultLookup
  have rootDecoded := decoded root (by omega)
  have resultDecoded := decoded result (by omega)
  refine ⟨meaning, result, model, rootDecoded, ran, ⟨resultEntry, resultLookup⟩, ?_⟩
  exact resultDecoded.trans
    (congrArg (fun expr => (Except.ok expr : Except String PsKernelExpr)) resultValue)

end PsKernelExprV2ArenaModelBridgeProofs

#print axioms PsKernelExprV2ArenaModelBridgeProofs.interpret_eq_node_expr
#print axioms PsKernelExprV2ArenaModelBridgeProofs.children_before_child_ids
#print axioms PsKernelExprV2ArenaModelBridgeProofs.semantic_prefix_establishes_arena_model
#print axioms PsKernelExprV2ArenaModelBridgeProofs.validate_ok_establishes_arena_models
#print axioms PsKernelExprV2ArenaModelBridgeProofs.decode_checked_ok_establishes_arena_model
#print axioms PsKernelExprV2ArenaModelBridgeProofs.validated_uniform_occurrence_correspondence
#print axioms PsKernelExprV2ArenaModelBridgeProofs.decoded_annotations_correspondence
