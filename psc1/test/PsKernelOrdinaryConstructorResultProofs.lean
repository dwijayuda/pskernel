import Ps.KernelCore.API.DagOrdinaryConstructorResult
import Ps.KernelCore.Admission.Inductive.Ordinary.Constructor
import PsKernelOrdinaryOccurrenceProofs

/-!
Future native-only proof draft for constructor-result analysis.

The occurrence correspondence uses the existing noncircular ArenaModel:
node decoding, child validity and sound structural depth. It does not assume
an occurrence result. Successful replay validation establishing that model
remains a separate obligation; this file does not claim that bridge or full
constructor admission. The source has not yet been compiled in Actions.
-/
namespace PsKernelOrdinaryConstructorResultProofs

open PsKernelOrdinaryOccurrenceProofs

theorem consume_empty_preserves_exact_tail
    (arena : PsKernelExprV2PagedArena) (args : List Nat) :
    psKernelExprV2OrdinaryConsumeResultParams [] arena args =
      Except.ok (some args) := rfl

theorem consume_missing_argument_is_mismatch
    (arena : PsKernelExprV2PagedArena)
    (parameter : PsKernelExprV2OrdinaryOpenBinder)
    (rest : List PsKernelExprV2OrdinaryOpenBinder) :
    psKernelExprV2OrdinaryConsumeResultParams (parameter :: rest) arena [] =
      Except.ok none := rfl

theorem consume_fvar_compares_only_internal_name
    (arena : PsKernelExprV2PagedArena)
    (parameter : PsKernelExprV2OrdinaryOpenBinder)
    (rest : List PsKernelExprV2OrdinaryOpenBinder) (arg : Nat) (tail : List Nat)
    (entry : PsKernelExprV2Entry) (name : PsKernelName)
    (lookup : psKernelExprV2PagedFind arena arg = some entry)
    (node : entry.node = PsKernelExprV2Node.fvar name) :
    psKernelExprV2OrdinaryConsumeResultParams (parameter :: rest) arena (arg :: tail) =
      if psKernelNameEq name parameter.internalName then
        psKernelExprV2OrdinaryConsumeResultParams rest arena tail
      else Except.ok none := by
  simp only [psKernelExprV2OrdinaryConsumeResultParams,
    psKernelExprV2PagedRequire, lookup, node]

theorem contains_zero_precedes_lookup
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName) (root : Nat) :
    psKernelExprV2OrdinaryContainsConstWithFuel 0 arena target root =
      Except.error "PSKERNEL_V2_ORDINARY_CONTAINS_CONST_FUEL" := rfl

theorem contains_projection_name_precedes_receiver
    (arena : PsKernelExprV2PagedArena) (target typeName : PsKernelName)
    (remaining root index body : Nat) (entry : PsKernelExprV2Entry)
    (lookup : psKernelExprV2PagedFind arena root = some entry)
    (node : entry.node = PsKernelExprV2Node.proj typeName index body)
    (sameName : psKernelNameEq typeName target = true) :
    psKernelExprV2OrdinaryContainsConstWithFuel (Nat.succ remaining)
        arena target root = Except.ok true := by
  simp only [psKernelExprV2OrdinaryContainsConstWithFuel,
    psKernelExprV2PagedRequire, lookup, node, sameName] <;> rfl

theorem contains_application_hit_precedes_argument
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName)
    (remaining root fn arg : Nat) (entry : PsKernelExprV2Entry)
    (lookup : psKernelExprV2PagedFind arena root = some entry)
    (node : entry.node = PsKernelExprV2Node.app fn arg)
    (found : psKernelExprV2OrdinaryContainsConstWithFuel remaining
      arena target fn = Except.ok true) :
    psKernelExprV2OrdinaryContainsConstWithFuel (Nat.succ remaining)
        arena target root = Except.ok true := by
  simp only [psKernelExprV2OrdinaryContainsConstWithFuel,
    psKernelExprV2PagedRequire, lookup, node, found] <;> rfl

theorem contains_application_error_precedes_argument
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName)
    (remaining root fn arg : Nat) (entry : PsKernelExprV2Entry) (error : String)
    (lookup : psKernelExprV2PagedFind arena root = some entry)
    (node : entry.node = PsKernelExprV2Node.app fn arg)
    (failed : psKernelExprV2OrdinaryContainsConstWithFuel remaining
      arena target fn = Except.error error) :
    psKernelExprV2OrdinaryContainsConstWithFuel (Nat.succ remaining)
        arena target root = Except.error error := by
  simp only [psKernelExprV2OrdinaryContainsConstWithFuel,
    psKernelExprV2PagedRequire, lookup, node, failed]

theorem contains_const_with_fuel_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (target : PsKernelName) (fuel : Nat) :
    forall root,
      validId arena root ->
      psKernelExprV2LegacyDepth (decode root) <= fuel ->
      psKernelExprV2OrdinaryContainsConstWithFuel fuel arena target root =
        Except.ok (psKernelExprContainsConst target (decode root)) := by
  induction fuel with
  | zero =>
      intro root _ bound
      have positive := legacy_depth_positive (decode root)
      omega
  | succ remaining ih =>
      intro root rootValid bound
      rcases rootValid with ⟨entry, lookup⟩
      have shape := model.shape root entry lookup
      have children := model.children root entry lookup
      cases node : entry.node
      case app fn arg =>
          have fnValid := children fn
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          have argValid := children arg
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff, Nat.max_le] at bound
          have fnEqual := ih fn fnValid bound.1
          have argEqual := ih arg argValid bound.2
          cases hit : psKernelExprContainsConst target (decode fn) <;>
            simp [psKernelExprV2OrdinaryContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelExprContainsConst, fnEqual, argEqual, hit]
      case lam name type body info =>
          have typeValid := children type
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff, Nat.max_le] at bound
          have typeEqual := ih type typeValid bound.1
          have bodyEqual := ih body bodyValid bound.2
          cases hit : psKernelExprContainsConst target (decode type) <;>
            simp [psKernelExprV2OrdinaryContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelExprContainsConst, typeEqual, bodyEqual, hit]
      case forallE name type body info =>
          have typeValid := children type
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff, Nat.max_le] at bound
          have typeEqual := ih type typeValid bound.1
          have bodyEqual := ih body bodyValid bound.2
          cases hit : psKernelExprContainsConst target (decode type) <;>
            simp [psKernelExprV2OrdinaryContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelExprContainsConst, typeEqual, bodyEqual, hit]
      case letE name type value body nondep =>
          have typeValid := children type
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          have valueValid := children value
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff, Nat.max_le] at bound
          have typeEqual := ih type typeValid bound.1.1
          have valueEqual := ih value valueValid bound.1.2
          have bodyEqual := ih body bodyValid bound.2
          cases typeHit : psKernelExprContainsConst target (decode type) <;>
            cases valueHit : psKernelExprContainsConst target (decode value) <;>
            simp [psKernelExprV2OrdinaryContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelExprContainsConst, typeEqual, valueEqual, bodyEqual,
              typeHit, valueHit]
      case mdata tag body =>
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff] at bound
          simpa only [psKernelExprV2OrdinaryContainsConstWithFuel,
            psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
            psKernelExprContainsConst] using ih body bodyValid bound
      case proj name index body =>
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff] at bound
          have bodyEqual := ih body bodyValid bound
          cases hit : psKernelNameEq name target <;>
            simp [psKernelExprV2OrdinaryContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelExprContainsConst, bodyEqual, hit]
      all_goals
        simp only [psKernelExprV2OrdinaryContainsConstWithFuel,
          psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
          psKernelExprContainsConst]

theorem contains_const_on_canonical_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (target : PsKernelName) (root : Nat)
    (rootValid : validId arena root) :
    psKernelExprV2OrdinaryContainsConstOnCanonical arena target root =
      Except.ok (psKernelExprContainsConst target (decode root)) := by
  rcases rootValid with ⟨entry, lookup⟩
  have bound := model.depth root entry lookup
  have sufficient : psKernelExprV2LegacyDepth (decode root) <= Nat.succ entry.depth := by
    omega
  simpa only [psKernelExprV2OrdinaryContainsConstOnCanonical,
    psKernelExprV2PagedRequire, lookup] using
    contains_const_with_fuel_correspondence arena decode model target
      (Nat.succ entry.depth) root ⟨entry, lookup⟩ sufficient

theorem indices_contain_target_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (target : PsKernelName) (indices : List Nat)
    (indicesValid : validIds arena indices) :
    psKernelExprV2OrdinaryIndicesContainTarget arena target indices =
      Except.ok (psKernelSimpleIndicesContainTarget target (indices.map decode)) := by
  induction indices with
  | nil => rfl
  | cons first rest ih =>
      have firstValid := indicesValid first (by simp)
      have restValid : validIds arena rest := by
        intro id member
        exact indicesValid id (by simp [member])
      have firstEqual := contains_const_on_canonical_correspondence
        arena decode model target first firstValid
      cases hit : psKernelExprContainsConst target (decode first) <;>
        simp [psKernelExprV2OrdinaryIndicesContainTarget, List.map_cons,
          psKernelSimpleIndicesContainTarget, firstEqual, ih restValid, hit]

theorem validate_shape_mismatch_precedes_occurrence
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices root : Nat)
    (mismatch : psKernelExprV2OrdinaryInductiveAppIndices
      arena target levels parameters numIndices root = Except.ok none) :
    psKernelExprV2OrdinaryValidateConstructorResult
        arena target levels parameters numIndices root =
      Except.error
        "simple inductive constructor must return the declared datatype with matching parameters and index arity" := by
  simp only [psKernelExprV2OrdinaryValidateConstructorResult, mismatch]

theorem validate_recursive_index_rejected
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices root : Nat) (indices : List Nat)
    (matched : psKernelExprV2OrdinaryInductiveAppIndices
      arena target levels parameters numIndices root = Except.ok (some indices))
    (recursive : psKernelExprV2OrdinaryIndicesContainTarget
      arena target indices = Except.ok true) :
    psKernelExprV2OrdinaryValidateConstructorResult
        arena target levels parameters numIndices root =
      Except.error "simple inductive constructor return index contains a recursive occurrence" := by
  simp only [psKernelExprV2OrdinaryValidateConstructorResult, matched, recursive] <;> rfl

theorem validate_preserves_exact_index_ids
    (arena : PsKernelExprV2PagedArena) (target : PsKernelName)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices root : Nat) (indices : List Nat)
    (matched : psKernelExprV2OrdinaryInductiveAppIndices
      arena target levels parameters numIndices root = Except.ok (some indices))
    (nonrecursive : psKernelExprV2OrdinaryIndicesContainTarget
      arena target indices = Except.ok false) :
    psKernelExprV2OrdinaryValidateConstructorResult
        arena target levels parameters numIndices root = Except.ok indices := by
  simp only [psKernelExprV2OrdinaryValidateConstructorResult, matched, nonrecursive] <;> rfl

/- Only the internal name is inspected by the frozen V1 prefix consumer.
   Decoding the remaining binder fields makes the reference input explicit;
   no validity assumption on an unused parameter type is needed here. -/
def decodeBinder (decode : Nat -> PsKernelExpr)
    (parameter : PsKernelExprV2OrdinaryOpenBinder) : PsKernelOpenBinder :=
  {
    internalName := parameter.internalName
    userName := parameter.userName
    type := decode parameter.type
    binderInfo := parameter.binderInfo
  }

theorem consume_result_params_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) :
    forall args,
      validIds arena args ->
      Exists (fun selected : Option (List Nat) =>
        psKernelExprV2OrdinaryConsumeResultParams parameters arena args =
          Except.ok selected /\
        selected.map (List.map decode) =
          psKernelConsumeSimpleResultParams (parameters.map (decodeBinder decode))
            (args.map decode) /\
        forall indices, selected = some indices -> validIds arena indices) := by
  induction parameters with
  | nil =>
      intro args argsValid
      refine ⟨some args, rfl, rfl, ?_⟩
      intro indices same
      cases same
      exact argsValid
  | cons parameter rest ih =>
      intro args argsValid
      cases args with
      | nil =>
          refine ⟨none, rfl, rfl, ?_⟩
          intro indices impossible
          cases impossible
      | cons arg tail =>
          rcases argsValid arg (by simp) with ⟨entry, lookup⟩
          have tailValid : validIds arena tail := by
            intro id member
            exact argsValid id (by simp [member])
          have shape := model.shape arg entry lookup
          cases node : entry.node
          case fvar name =>
              cases sameName : psKernelNameEq name parameter.internalName with
              | false =>
                  refine ⟨none, ?_, ?_, ?_⟩
                  · simp [psKernelExprV2OrdinaryConsumeResultParams,
                      psKernelExprV2PagedRequire, lookup, node, sameName]
                  · simp [List.map_cons, psKernelConsumeSimpleResultParams,
                      decodeBinder, shape, node, nodeExpr, psKernelExprEq, sameName]
                  · intro indices impossible
                    cases impossible
              | true =>
                  rcases ih tail tailValid with
                    ⟨selected, consumed, decoded, selectedValid⟩
                  refine ⟨selected, ?_, ?_, selectedValid⟩
                  · simpa [psKernelExprV2OrdinaryConsumeResultParams,
                      psKernelExprV2PagedRequire, lookup, node, sameName] using consumed
                  · simpa [List.map_cons, psKernelConsumeSimpleResultParams,
                      decodeBinder, shape, node, nodeExpr, psKernelExprEq, sameName]
                      using decoded
          all_goals
            refine ⟨none, ?_, ?_, ?_⟩
            · simp [psKernelExprV2OrdinaryConsumeResultParams,
                psKernelExprV2PagedRequire, lookup, node]
            · simp [List.map_cons, psKernelConsumeSimpleResultParams,
                decodeBinder, shape, node, nodeExpr, psKernelExprEq]
            · intro indices impossible
              cases impossible

theorem inductive_app_indices_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (target : PsKernelName)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices root : Nat) (rootValid : validId arena root) :
    Exists (fun selected : Option (List Nat) =>
      psKernelExprV2OrdinaryInductiveAppIndices
          arena target levels parameters numIndices root = Except.ok selected /\
      selected.map (List.map decode) =
        psKernelSimpleInductiveAppIndices target levels
          (parameters.map (decodeBinder decode)) numIndices (decode root) /\
      forall indices, selected = some indices -> validIds arena indices) := by
  rcases app_spine_on_canonical_correspondence arena decode model root rootValid with
    ⟨head, args, spine, headValid, headExpr, argExprs, argsValid⟩
  rcases headValid with ⟨entry, lookup⟩
  have shape := model.shape head entry lookup
  have headShape : psKernelExprGetAppFn (decode root) = nodeExpr decode entry.node :=
    headExpr.symm.trans shape
  have oldArgs : psKernelExprGetAppArgs (decode root) = args.map decode := argExprs.symm
  cases node : entry.node
  case const resultName resultLevels =>
      cases sameName : psKernelNameEq resultName target with
      | false =>
          refine ⟨none, ?_, ?_, ?_⟩
          · simp [psKernelExprV2OrdinaryInductiveAppIndices, spine,
              psKernelExprV2PagedRequire, lookup, node, sameName]
          · simp [psKernelSimpleInductiveAppIndices, headShape, node, nodeExpr, sameName]
          · intro indices impossible
            cases impossible
      | true =>
          cases sameLevels : psKernelLevelListEq resultLevels levels with
          | false =>
              refine ⟨none, ?_, ?_, ?_⟩
              · simp [psKernelExprV2OrdinaryInductiveAppIndices, spine,
                  psKernelExprV2PagedRequire, lookup, node, sameName, sameLevels]
              · simp [psKernelSimpleInductiveAppIndices, headShape, node,
                  nodeExpr, sameName, sameLevels]
              · intro indices impossible
                cases impossible
          | true =>
              rcases consume_result_params_correspondence arena decode model
                  parameters args argsValid with
                ⟨selected, consumed, decoded, selectedValid⟩
              cases selected with
              | none =>
                  have oldConsumed :
                      psKernelConsumeSimpleResultParams
                        (parameters.map (decodeBinder decode)) (args.map decode) = none := by
                    simpa using decoded.symm
                  refine ⟨none, ?_, ?_, ?_⟩
                  · simp [psKernelExprV2OrdinaryInductiveAppIndices, spine,
                      psKernelExprV2PagedRequire, lookup, node, sameName, sameLevels,
                      consumed]
                  · simp [psKernelSimpleInductiveAppIndices, headShape, node,
                      nodeExpr, sameName, sameLevels, oldArgs, oldConsumed]
                  · intro indices impossible
                    cases impossible
              | some indices =>
                  have oldConsumed :
                      psKernelConsumeSimpleResultParams
                        (parameters.map (decodeBinder decode)) (args.map decode) =
                          some (indices.map decode) := by
                    simpa using decoded.symm
                  have oldLength : psKernelExprListLength (indices.map decode) =
                      psKernelExprV2TransformNatLength indices :=
                    (uniform_argument_count_correspondence decode indices).symm
                  cases sameArity :
                      Nat.beq (psKernelExprV2TransformNatLength indices) numIndices with
                  | false =>
                      refine ⟨none, ?_, ?_, ?_⟩
                      · simp [psKernelExprV2OrdinaryInductiveAppIndices, spine,
                          psKernelExprV2PagedRequire, lookup, node, sameName, sameLevels,
                          consumed, sameArity]
                      · simp [psKernelSimpleInductiveAppIndices, headShape, node,
                          nodeExpr, sameName, sameLevels, oldArgs, oldConsumed,
                          oldLength, sameArity]
                      · intro values impossible
                        cases impossible
                  | true =>
                      refine ⟨some indices, ?_, ?_, selectedValid⟩
                      · simp [psKernelExprV2OrdinaryInductiveAppIndices, spine,
                          psKernelExprV2PagedRequire, lookup, node, sameName, sameLevels,
                          consumed, sameArity]
                      · simp [psKernelSimpleInductiveAppIndices, headShape, node,
                          nodeExpr, sameName, sameLevels, oldArgs, oldConsumed,
                          oldLength, sameArity]
  all_goals
    refine ⟨none, ?_, ?_, ?_⟩
    · simp [psKernelExprV2OrdinaryInductiveAppIndices, spine,
        psKernelExprV2PagedRequire, lookup, node]
    · simp [psKernelSimpleInductiveAppIndices, headShape, node, nodeExpr]
    · intro indices impossible
      cases impossible

theorem validate_constructor_result_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (target : PsKernelName)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (numIndices root : Nat) (rootValid : validId arena root) :
    (match psKernelExprV2OrdinaryValidateConstructorResult
        arena target levels parameters numIndices root with
      | Except.error error => Except.error error
      | Except.ok indices => Except.ok (indices.map decode)) =
      psKernelValidateSimpleConstructorResult target levels
        (parameters.map (decodeBinder decode)) numIndices (decode root) := by
  rcases inductive_app_indices_correspondence arena decode model
      target levels parameters numIndices root rootValid with
    ⟨selected, computed, decoded, selectedValid⟩
  cases selected with
  | none =>
      have oldSelected : psKernelSimpleInductiveAppIndices target levels
          (parameters.map (decodeBinder decode)) numIndices (decode root) = none := by
        simpa using decoded.symm
      simp only [psKernelExprV2OrdinaryValidateConstructorResult, computed,
        psKernelValidateSimpleConstructorResult, oldSelected]
  | some indices =>
      have oldSelected : psKernelSimpleInductiveAppIndices target levels
          (parameters.map (decodeBinder decode)) numIndices (decode root) =
            some (indices.map decode) := by
        simpa using decoded.symm
      have occurrence := indices_contain_target_correspondence arena decode model
        target indices (selectedValid indices rfl)
      cases hit : psKernelSimpleIndicesContainTarget target (indices.map decode) <;>
        simp [psKernelExprV2OrdinaryValidateConstructorResult, computed,
          psKernelValidateSimpleConstructorResult, oldSelected, occurrence, hit]

end PsKernelOrdinaryConstructorResultProofs

#print axioms PsKernelOrdinaryConstructorResultProofs.consume_empty_preserves_exact_tail
#print axioms PsKernelOrdinaryConstructorResultProofs.consume_missing_argument_is_mismatch
#print axioms PsKernelOrdinaryConstructorResultProofs.consume_fvar_compares_only_internal_name
#print axioms PsKernelOrdinaryConstructorResultProofs.contains_zero_precedes_lookup
#print axioms PsKernelOrdinaryConstructorResultProofs.contains_projection_name_precedes_receiver
#print axioms PsKernelOrdinaryConstructorResultProofs.contains_application_hit_precedes_argument
#print axioms PsKernelOrdinaryConstructorResultProofs.contains_application_error_precedes_argument
#print axioms PsKernelOrdinaryConstructorResultProofs.contains_const_with_fuel_correspondence
#print axioms PsKernelOrdinaryConstructorResultProofs.contains_const_on_canonical_correspondence
#print axioms PsKernelOrdinaryConstructorResultProofs.indices_contain_target_correspondence
#print axioms PsKernelOrdinaryConstructorResultProofs.validate_shape_mismatch_precedes_occurrence
#print axioms PsKernelOrdinaryConstructorResultProofs.validate_recursive_index_rejected
#print axioms PsKernelOrdinaryConstructorResultProofs.validate_preserves_exact_index_ids
#print axioms PsKernelOrdinaryConstructorResultProofs.consume_result_params_correspondence
#print axioms PsKernelOrdinaryConstructorResultProofs.inductive_app_indices_correspondence
#print axioms PsKernelOrdinaryConstructorResultProofs.validate_constructor_result_correspondence
