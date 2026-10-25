import Ps.KernelCore.API.DagMutualConstructorResult
import PsKernelOrdinaryOccurrenceProofs

/- Local all-family occurrence correspondence conditional on the existing
   noncircular owning ArenaModel; not global soundness or full admission. -/
namespace PsKernelMutualConstructorResultProofs
open PsKernelOrdinaryOccurrenceProofs

theorem contains_zero_precedes_lookup
    (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName) (root : Nat) :
    psKernelExprV2MutualContainsConstWithFuel 0 arena targets root =
      Except.error "PSKERNEL_V2_MUTUAL_CONTAINS_CONST_FUEL" := rfl

theorem contains_projection_name_precedes_receiver
    (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName) (typeName : PsKernelName)
    (remaining root index body : Nat) (entry : PsKernelExprV2Entry)
    (lookup : psKernelExprV2PagedFind arena root = some entry)
    (node : entry.node = PsKernelExprV2Node.proj typeName index body)
    (sameName : psKernelNameMember typeName targets = true) :
    psKernelExprV2MutualContainsConstWithFuel (Nat.succ remaining)
        arena targets root = Except.ok true := by
  simp only [psKernelExprV2MutualContainsConstWithFuel,
    psKernelExprV2PagedRequire, lookup, node, sameName] <;> rfl

theorem contains_application_hit_precedes_argument
    (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName)
    (remaining root fn arg : Nat) (entry : PsKernelExprV2Entry)
    (lookup : psKernelExprV2PagedFind arena root = some entry)
    (node : entry.node = PsKernelExprV2Node.app fn arg)
    (found : psKernelExprV2MutualContainsConstWithFuel remaining
      arena targets fn = Except.ok true) :
    psKernelExprV2MutualContainsConstWithFuel (Nat.succ remaining)
        arena targets root = Except.ok true := by
  simp only [psKernelExprV2MutualContainsConstWithFuel,
    psKernelExprV2PagedRequire, lookup, node, found] <;> rfl

theorem contains_application_error_precedes_argument
    (arena : PsKernelExprV2PagedArena) (targets : List PsKernelName)
    (remaining root fn arg : Nat) (entry : PsKernelExprV2Entry) (error : String)
    (lookup : psKernelExprV2PagedFind arena root = some entry)
    (node : entry.node = PsKernelExprV2Node.app fn arg)
    (failed : psKernelExprV2MutualContainsConstWithFuel remaining
      arena targets fn = Except.error error) :
    psKernelExprV2MutualContainsConstWithFuel (Nat.succ remaining)
        arena targets root = Except.error error := by
  simp only [psKernelExprV2MutualContainsConstWithFuel,
    psKernelExprV2PagedRequire, lookup, node, failed]

theorem contains_const_with_fuel_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (targets : List PsKernelName) (fuel : Nat) :
    forall root,
      validId arena root ->
      psKernelExprV2LegacyDepth (decode root) <= fuel ->
      psKernelExprV2MutualContainsConstWithFuel fuel arena targets root =
        Except.ok (psKernelSimpleMutualContainsConst targets (decode root)) := by
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
          cases hit : psKernelSimpleMutualContainsConst targets (decode fn) <;>
            simp [psKernelExprV2MutualContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelSimpleMutualContainsConst, psKernelSimpleMutualContainsConstWorker, fnEqual, argEqual, hit]
      case lam name type body info =>
          have typeValid := children type
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff, Nat.max_le] at bound
          have typeEqual := ih type typeValid bound.1
          have bodyEqual := ih body bodyValid bound.2
          cases hit : psKernelSimpleMutualContainsConst targets (decode type) <;>
            simp [psKernelExprV2MutualContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelSimpleMutualContainsConst, psKernelSimpleMutualContainsConstWorker, typeEqual, bodyEqual, hit]
      case forallE name type body info =>
          have typeValid := children type
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff, Nat.max_le] at bound
          have typeEqual := ih type typeValid bound.1
          have bodyEqual := ih body bodyValid bound.2
          cases hit : psKernelSimpleMutualContainsConst targets (decode type) <;>
            simp [psKernelExprV2MutualContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelSimpleMutualContainsConst, psKernelSimpleMutualContainsConstWorker, typeEqual, bodyEqual, hit]
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
          cases typeHit : psKernelSimpleMutualContainsConst targets (decode type) <;>
            cases valueHit : psKernelSimpleMutualContainsConst targets (decode value) <;>
            simp [psKernelExprV2MutualContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelSimpleMutualContainsConst, psKernelSimpleMutualContainsConstWorker, typeEqual, valueEqual, bodyEqual,
              typeHit, valueHit]
      case mdata tag body =>
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff] at bound
          simpa only [psKernelExprV2MutualContainsConstWithFuel,
            psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
            psKernelSimpleMutualContainsConst, psKernelSimpleMutualContainsConstWorker] using ih body bodyValid bound
      case proj name index body =>
          have bodyValid := children body
            (by simp [childIds, node, psKernelExprV2TransformChildren])
          simp only [shape, node, nodeExpr, psKernelExprV2LegacyDepth,
            Nat.succ_le_succ_iff] at bound
          have bodyEqual := ih body bodyValid bound
          cases hit : psKernelNameMember name targets <;>
            simp [psKernelExprV2MutualContainsConstWithFuel,
              psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
              psKernelSimpleMutualContainsConst, psKernelSimpleMutualContainsConstWorker, bodyEqual, hit]
      all_goals
        simp only [psKernelExprV2MutualContainsConstWithFuel,
          psKernelExprV2PagedRequire, lookup, node, shape, nodeExpr,
          psKernelSimpleMutualContainsConst, psKernelSimpleMutualContainsConstWorker]

theorem contains_const_on_canonical_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (targets : List PsKernelName) (root : Nat)
    (rootValid : validId arena root) :
    psKernelExprV2MutualContainsConstOnCanonical arena targets root =
      Except.ok (psKernelSimpleMutualContainsConst targets (decode root)) := by
  rcases rootValid with ⟨entry, lookup⟩
  have bound := model.depth root entry lookup
  have sufficient : psKernelExprV2LegacyDepth (decode root) <= Nat.succ entry.depth := by
    omega
  simpa only [psKernelExprV2MutualContainsConstOnCanonical,
    psKernelExprV2PagedRequire, lookup] using
    contains_const_with_fuel_correspondence arena decode model targets
      (Nat.succ entry.depth) root ⟨entry, lookup⟩ sufficient

theorem indices_contain_target_correspondence
    (arena : PsKernelExprV2PagedArena) (decode : Nat -> PsKernelExpr)
    (model : ArenaModel arena decode) (targets : List PsKernelName) (indices : List Nat)
    (indicesValid : validIds arena indices) :
    psKernelExprV2MutualIndicesContainTarget arena targets indices =
      Except.ok (psKernelSimpleMutualIndicesContainTarget targets (indices.map decode)) := by
  induction indices with
  | nil => rfl
  | cons first rest ih =>
      have firstValid := indicesValid first (by simp)
      have restValid : validIds arena rest := by
        intro id member
        exact indicesValid id (by simp [member])
      have firstEqual := contains_const_on_canonical_correspondence
        arena decode model targets first firstValid
      cases hit : psKernelSimpleMutualContainsConst targets (decode first) <;>
        simp [psKernelExprV2MutualIndicesContainTarget, List.map_cons,
          psKernelSimpleMutualIndicesContainTarget, firstEqual, ih restValid, hit]


#print axioms contains_zero_precedes_lookup
#print axioms contains_projection_name_precedes_receiver
#print axioms contains_application_hit_precedes_argument
#print axioms contains_application_error_precedes_argument
#print axioms contains_const_with_fuel_correspondence
#print axioms contains_const_on_canonical_correspondence
#print axioms indices_contain_target_correspondence

theorem selector_empty (name : PsKernelName) (index : Nat) :
    psKernelExprV2MutualFindTargetHeader [] name index = none := rfl

theorem selector_first_hit_keeps_exact_header_and_index
    (first : PsKernelExprV2MutualTypeHeader) (rest : List PsKernelExprV2MutualTypeHeader)
    (name : PsKernelName) (index : Nat)
    (hit : psKernelNameEq name first.declaration.name = true) :
    psKernelExprV2MutualFindTargetHeader (first :: rest) name index = some (index,first) := by
  simp [psKernelExprV2MutualFindTargetHeader, hit]

theorem selector_miss_advances_once
    (first : PsKernelExprV2MutualTypeHeader) (rest : List PsKernelExprV2MutualTypeHeader)
    (name : PsKernelName) (index : Nat)
    (miss : psKernelNameEq name first.declaration.name = false) :
    psKernelExprV2MutualFindTargetHeader (first :: rest) name index =
      psKernelExprV2MutualFindTargetHeader rest name (Nat.succ index) := by
  simp [psKernelExprV2MutualFindTargetHeader, miss]

#print axioms selector_empty
#print axioms selector_first_hit_keeps_exact_header_and_index
#print axioms selector_miss_advances_once

end PsKernelMutualConstructorResultProofs
