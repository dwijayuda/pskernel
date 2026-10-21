import Ps.KernelCore.Checker.ExprV2.RecursorMajor

/- Local equations for the major-normalization boundary. These establish guard
   and callback-state placement, not global soundness or complete equivalence
   of the recursive-expression and DAG checkers. -/
namespace PsKernelExprV2RecursorMajorProofs

abbrev Callback := PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
  Option (Except String (PsKernelExprV2CheckState × Nat))

theorem major_family_zero_precedes_root
    (arena : PsKernelExprV2PagedArena) (root index : Nat) :
    psKernelExprV2RecursorMajorInductWithFuel 0 arena root index = .ok none := rfl

theorem structure_fields_zero_preserves_arena
    (arena : PsKernelExprV2PagedArena) (name : PsKernelName) (major count index : Nat) :
    psKernelExprV2RecursorStructureFieldsWithFuel 0 arena name major count index =
      .ok (arena,[]) := rfl

theorem no_type_owner_in_empty_index (recursor : PsKernelRecursorInfo) :
    psKernelExprV2RecursorTypeOwner [] recursor = none := rfl

theorem constructor_shortcut_precedes_owner_and_callbacks
    (whnf inferType : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (recursor : PsKernelRecursorInfo) (major : Nat)
    (isCtor : psKernelExprV2RecursorIsConstructorApp context.scalar state.whnf.arena major = .ok true) :
    psKernelExprV2RecursorToStructureOwnedWith whnf inferType context state recursor major =
      some (.ok (state,major)) := by
  simp [psKernelExprV2RecursorToStructureOwnedWith, isCtor]

theorem missing_family_owner_declines
    (whnf inferType : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (recursor : PsKernelRecursorInfo) (major : Nat)
    (notCtor : psKernelExprV2RecursorIsConstructorApp context.scalar state.whnf.arena major = .ok false)
    (missing : psKernelExprV2RecursorMajorInduct state recursor = none) :
    psKernelExprV2RecursorToStructureOwnedWith whnf inferType context state recursor major = none := by
  simp [psKernelExprV2RecursorToStructureOwnedWith, notCtor, missing]

theorem non_structure_major_is_supported_unchanged
    (whnf inferType : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (recursor : PsKernelRecursorInfo)
    (major : Nat) (family : PsKernelName)
    (notCtor : psKernelExprV2RecursorIsConstructorApp context.scalar state.whnf.arena major = .ok false)
    (found : psKernelExprV2RecursorMajorInduct state recursor = some (.ok (some family)))
    (notStructure : psKernelEnvironmentIsNonRecStructure context.scalar.environment family = false) :
    psKernelExprV2RecursorToStructureOwnedWith whnf inferType context state recursor major =
      some (.ok (state,major)) := by
  simp [psKernelExprV2RecursorToStructureOwnedWith, notCtor, found, notStructure]

theorem structure_inference_decline_preserved
    (whnf inferType : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (recursor : PsKernelRecursorInfo)
    (major : Nat) (family : PsKernelName)
    (notCtor : psKernelExprV2RecursorIsConstructorApp context.scalar state.whnf.arena major = .ok false)
    (found : psKernelExprV2RecursorMajorInduct state recursor = some (.ok (some family)))
    (structureFamily : psKernelEnvironmentIsNonRecStructure context.scalar.environment family = true)
    (declined : inferType context state major = none) :
    psKernelExprV2RecursorToStructureOwnedWith whnf inferType context state recursor major = none := by
  simp [psKernelExprV2RecursorToStructureOwnedWith, notCtor, found, structureFamily, declined]

theorem structure_inference_error_precedes_type_whnf
    (whnf inferType : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (recursor : PsKernelRecursorInfo)
    (major : Nat) (family : PsKernelName) (error : String)
    (notCtor : psKernelExprV2RecursorIsConstructorApp context.scalar state.whnf.arena major = .ok false)
    (found : psKernelExprV2RecursorMajorInduct state recursor = some (.ok (some family)))
    (structureFamily : psKernelEnvironmentIsNonRecStructure context.scalar.environment family = true)
    (failed : inferType context state major = some (.error error)) :
    psKernelExprV2RecursorToStructureOwnedWith whnf inferType context state recursor major =
      some (.error error) := by
  simp [psKernelExprV2RecursorToStructureOwnedWith, notCtor, found, structureFamily, failed]

theorem string_uses_public_callback_after_exact_construction
    (whnf inferType : Callback) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (recursor : PsKernelRecursorInfo)
    (major root : Nat) (value : String) (entry : PsKernelExprV2Entry)
    (arena : PsKernelExprV2PagedArena)
    (source : psKernelExprV2PagedRequire state.whnf.arena major = .ok entry)
    (literal : entry.node = PsKernelExprV2Node.lit (.str value))
    (built : psKernelExprV2StringLitToConstructorOnCanonical state.whnf.arena value = .ok (arena,root)) :
    psKernelExprV2RecursorNormalizeMajorOwnedWith whnf inferType context state recursor major =
      whnf context (psKernelExprV2CheckStateWithArena state arena) root := by
  simp [psKernelExprV2RecursorNormalizeMajorOwnedWith, source, literal, built]

theorem is_prop_retains_complete_last_callback_state
    (whnf inferType : Callback) (context : PsKernelExprV2CheckContext)
    (before afterInfer afterWhnf : PsKernelExprV2CheckState)
    (root type normalized : Nat) (entry : PsKernelExprV2Entry) (level : PsKernelLevel)
    (inferred : inferType context before root = some (.ok (afterInfer,type)))
    (reduced : whnf context afterInfer type = some (.ok (afterWhnf,normalized)))
    (source : psKernelExprV2PagedRequire afterWhnf.whnf.arena normalized = .ok entry)
    (isSort : entry.node = PsKernelExprV2Node.sort level) :
    psKernelExprV2RecursorIsPropOwnedWith whnf inferType context before root =
      some (.ok (afterWhnf,psKernelLevelNormalizesToZero level)) := by
  simp [psKernelExprV2RecursorIsPropOwnedWith, inferred, reduced, source, isSort]

#print axioms major_family_zero_precedes_root
#print axioms structure_fields_zero_preserves_arena
#print axioms no_type_owner_in_empty_index
#print axioms constructor_shortcut_precedes_owner_and_callbacks
#print axioms missing_family_owner_declines
#print axioms non_structure_major_is_supported_unchanged
#print axioms structure_inference_decline_preserved
#print axioms structure_inference_error_precedes_type_whnf
#print axioms string_uses_public_callback_after_exact_construction
#print axioms is_prop_retains_complete_last_callback_state

end PsKernelExprV2RecursorMajorProofs
