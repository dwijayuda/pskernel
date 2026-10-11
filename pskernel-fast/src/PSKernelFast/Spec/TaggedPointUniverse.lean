import PSKernelFast.Spec.TaggedProofPoint
import PSKernelFast.Spec.FiniteUniverseClosure

/-!
P1f: proof-first universe-rank validation for the TAGGED point,
not the old collision-prone P1d/P1e model.

NO extra "tag ∈ Type1" assumption. Derive the tag, point, True and Prop
membership in the shifted first positive universe from the Tarski
hierarchy, finite pair/singleton closure and powerset closure.
The actual interpreter/checked syntax have NOT been migrated.
-/

namespace PSKernelFast.Spec

open PSKernelFast.Core

universe u

/-- The tag set is a member of the first positive carrier universe. -/
theorem taggedPointTag_mem_typeOne (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.member (taggedPointTag V)
      (SetTheoryBasis.univ 2) := by
  let e : V := SetTheoryBasis.emptySet V
  let s : V := modelSingleton e
  let t : V := modelSingleton s
  let U : V := SetTheoryBasis.univ 2
  have hSeed : SetTheoryBasis.member
      (SetTheoryBasis.univ 1 : V) U :=
    SetTheoryBasis.universe_step (V := V) 1
  have he : SetTheoryBasis.member e U :=
    SetTheoryBasis.universe_subset_closed (V := V) 2
      (SetTheoryBasis.univ 1) e hSeed
      (fun z hz =>
        False.elim (SetTheoryBasis.not_member_empty V z hz))
  have hs : SetTheoryBasis.member s U :=
    universe_modelSingleton_closed V 2 e he
  have ht : SetTheoryBasis.member t U :=
    universe_modelSingleton_closed V 2 s hs
  exact universe_modelPair_closed V 2 (SetTheoryBasis.univ 1)
    e t hSeed he ht

/-- A singleton of the tag remains inside Type1. -/
theorem taggedPoint_mem_typeOne (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.member (taggedPoint V)
      (SetTheoryBasis.univ 2) :=
  universe_modelSingleton_closed V 2 (taggedPointTag V)
    (taggedPointTag_mem_typeOne V)

/-- The candidate true proposition belongs to Type1. -/
theorem taggedTrue_mem_typeOne (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.member (taggedTrue V)
      (SetTheoryBasis.univ 2) :=
  universe_modelSingleton_closed V 2 (taggedPoint V)
    (taggedPoint_mem_typeOne V)

/-- The candidate Prop carrier itself belongs to Type1. -/
theorem taggedProp_mem_typeOne (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.member (taggedProp V)
      (SetTheoryBasis.univ 2) :=
  SetTheoryBasis.universe_powerset_closed (V := V)
    2 (taggedTrue V) (taggedTrue_mem_typeOne V)

/-- Proof-only alternate tower, not yet the runtime model. -/
noncomputable def taggedSortSet (V : Type u)
    [SetTheoryBasis V] : Nat → V
  | 0 => taggedProp V
  | n + 1 => SetTheoryBasis.univ (n + 2)

/--
The exact Sort u : Sort (succ u) membership law survives a tagged
proof-point representation, for every ground universe valuation.
-/
theorem taggedSort_member_succ (V : Type u)
    [SetTheoryBasis V] (ρ : KName → Nat) (level : ULevel) :
    SetTheoryBasis.member
      (taggedSortSet V (level.denote ρ))
      (taggedSortSet V ((ULevel.succ level).denote ρ)) := by
  cases hLevel : level.denote ρ with
  | zero =>
      simpa [taggedSortSet, ULevel.denote, hLevel] using
        (taggedProp_mem_typeOne V)
  | succ n =>
      simpa [taggedSortSet, ULevel.denote, hLevel, Nat.add_assoc] using
        (SetTheoryBasis.univ_step (V := V) (n + 2))

#print axioms taggedPointTag_mem_typeOne
#print axioms taggedPoint_mem_typeOne
#print axioms taggedTrue_mem_typeOne
#print axioms taggedProp_mem_typeOne
#print axioms taggedSort_member_succ

end PSKernelFast.Spec
