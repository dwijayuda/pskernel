import PSKernelFast.Spec.SetEncoding

/-!
P1f proof-first TAGGED POINT CANDIDATE, independent of the old P1d/P1e
truth-value model and the collision-prone V2 candidate.

The construction follows the structural anti-data requirements studied in
con-leche, but is independently proved in our SetTheoryBasis interface:
  e := empty
  tag := {e, {{e}}}
  pt  := {tag}
  True := {pt}
  Prop := power True

Theorems are proved BEFORE changing any source-level interpreter.
We prove that pt is neither a Kuratowski pair, nor a function graph,
nor any von Neumann natural number, nor a proposition truth value.
The tag itself is not a pair. Prop has exactly two truth values.

CRITICAL LIMIT: no claim of unconditional freshness from arbitrary
quotient sets is possible. A deliberately chosen arbitrary IMAGE can
equal the proof point itself, so typed writable-value restrictions
are necessary for eventual quotient rules. This is NOT yet proof
irrelevance, full Lean model, model existence, or kernel admission.
-/

namespace PSKernelFast.Spec

universe u
variable {V : Type u} [SetTheoryBasis V]

/-- The guarded tag {empty, {{empty}}}. -/
noncomputable def taggedPointTag (V : Type u) [SetTheoryBasis V] : V :=
  SetTheoryBasis.pair (SetTheoryBasis.emptySet V)
    (modelSingleton (modelSingleton (SetTheoryBasis.emptySet V)))

/-- The distinguished proof value, distinct from any model proposition. -/
noncomputable def taggedPoint (V : Type u) [SetTheoryBasis V] : V :=
  modelSingleton (taggedPointTag V)

/-- The true truth-value, a singleton of the proof point. -/
noncomputable def taggedTrue (V : Type u) [SetTheoryBasis V] : V :=
  modelSingleton (taggedPoint V)

/-- A genuinely two-valued candidate Prop carrier. -/
noncomputable def taggedProp (V : Type u) [SetTheoryBasis V] : V :=
  SetTheoryBasis.powerset (taggedTrue V)

theorem empty_member_tag (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.member (SetTheoryBasis.emptySet V)
      (taggedPointTag V) :=
  (SetTheoryBasis.member_pair).mpr (Or.inl rfl)

/-- Both different elements of the tag have established membership. -/
theorem doubleSingleton_member_tag (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.member
      (modelSingleton (modelSingleton (SetTheoryBasis.emptySet V)))
      (taggedPointTag V) :=
  (SetTheoryBasis.member_pair).mpr (Or.inr rfl)

/--
The tag contains TWO DISTINCT elements; it is NOT any singleton.
This is the principal anti-Kuratowski invariant.
-/
theorem taggedPointTag_ne_singleton (V : Type u)
    [SetTheoryBasis V] (a : V) :
    taggedPointTag V ≠ modelSingleton a := by
  intro h
  let e : V := SetTheoryBasis.emptySet V
  let d : V := modelSingleton (modelSingleton e)
  have he : e = a := (member_modelSingleton e a).mp
    (h ▸ (empty_member_tag V))
  have hd : d = a := (member_modelSingleton d a).mp
    (h ▸ (doubleSingleton_member_tag V))
  have hde : d = e := hd.trans he.symm
  have hw : SetTheoryBasis.member (modelSingleton e) d :=
    modelSingleton_member (modelSingleton e)
  have hEmpty : SetTheoryBasis.member
      (modelSingleton e) e := by
    rw [← hde]
    exact hw
  exact (SetTheoryBasis.not_member_empty V (modelSingleton e)) hEmpty

/-- The tag is NOT a Kuratowski pair: a pair has no empty members. -/
theorem taggedPointTag_ne_orderedPair (V : Type u)
    [SetTheoryBasis V] (a b : V) :
    taggedPointTag V ≠ modelOrderedPair a b := by
  intro h
  have hEmptyInPair : SetTheoryBasis.member
      (SetTheoryBasis.emptySet V) (modelOrderedPair a b) :=
    h ▸ empty_member_tag V
  obtain ⟨w, hw⟩ :=
    member_orderedPair_nonempty a b (SetTheoryBasis.emptySet V)
      hEmptyInPair
  exact (SetTheoryBasis.not_member_empty V w) hw

/-- The tag is actually a member of the proof point. -/
theorem tag_member_point (V : Type u) [SetTheoryBasis V] :
    SetTheoryBasis.member (taggedPointTag V) (taggedPoint V) :=
  modelSingleton_member (taggedPointTag V)

/-- The point cannot be empty because it contains the tag. -/
theorem taggedPoint_ne_empty (V : Type u)
    [SetTheoryBasis V] :
    taggedPoint V ≠ SetTheoryBasis.emptySet V := by
  intro h
  have hm : SetTheoryBasis.member
      (taggedPointTag V) (SetTheoryBasis.emptySet V) :=
    h ▸ tag_member_point V
  exact (SetTheoryBasis.not_member_empty V (taggedPointTag V)) hm

/--
The point itself is not an ordered pair: the first member of any
Kuratowski pair is a singleton, while the unique point member
is the NON-singleton tag.
-/
theorem taggedPoint_ne_orderedPair (V : Type u)
    [SetTheoryBasis V] (a b : V) :
    taggedPoint V ≠ modelOrderedPair a b := by
  intro h
  have hFirstMember : SetTheoryBasis.member
      (modelSingleton a) (taggedPoint V) := by
    rw [h]
    exact (member_modelOrderedPair (modelSingleton a) a b).mpr
      (Or.inl rfl)
  have heq : modelSingleton a = taggedPointTag V :=
    (member_modelSingleton (modelSingleton a) (taggedPointTag V)).mp
      hFirstMember
  exact taggedPointTag_ne_singleton V a heq.symm

/--
Graph freshness is a THEOREM of the precise modelGraph operator,
since every graph member is an actual Kuratowski pair.
-/
theorem taggedPoint_ne_graph (V : Type u) [SetTheoryBasis V]
    (F : V → V) (A : V) :
    taggedPoint V ≠ modelGraph F A := by
  intro h
  have hTagInGraph : SetTheoryBasis.member
      (taggedPointTag V) (modelGraph F A) :=
    h ▸ tag_member_point V
  obtain ⟨x, _, hx⟩ :=
    (member_modelGraph F A (taggedPointTag V)).mp hTagInGraph
  exact taggedPointTag_ne_orderedPair V x (F x) hx

/--
No finite von Neumann ordinal collides with the proof point:
zero is empty, and every positive ordinal contains empty,
whereas the point contains ONLY its nonempty tag.
-/
theorem taggedPoint_ne_nat (V : Type u) [SetTheoryBasis V]
    (n : Nat) :
    taggedPoint V ≠ modelNat V n := by
  cases n with
  | zero =>
      exact taggedPoint_ne_empty V
  | succ n =>
      intro h
      have hempty : SetTheoryBasis.member
          (SetTheoryBasis.emptySet V) (taggedPoint V) :=
        h.symm ▸ empty_member_modelNat_succ V n
      have hEq : SetTheoryBasis.emptySet V = taggedPointTag V :=
        (member_modelSingleton (SetTheoryBasis.emptySet V)
          (taggedPointTag V)).mp hempty
      have hSelf : SetTheoryBasis.member
          (SetTheoryBasis.emptySet V) (SetTheoryBasis.emptySet V) :=
        hEq ▸ empty_member_tag V
      exact SetTheoryBasis.not_member_empty V _ hSelf

/-- The point is an actual inhabitant of the candidate True proposition. -/
theorem taggedPoint_member_true (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.member (taggedPoint V) (taggedTrue V) :=
  modelSingleton_member (taggedPoint V)

/--
A distinct proof point cannot itself be a proposition truth value.
Otherwise the point is a subset of {point}; its tag must EQUAL point,
forcing the tag to be a singleton, a proved impossibility.
-/
theorem taggedPoint_not_prop (V : Type u)
    [SetTheoryBasis V] :
    ¬ SetTheoryBasis.member (taggedPoint V) (taggedProp V) := by
  intro h
  have hSub := (SetTheoryBasis.member_powerset).mp h
  have hTagInTrue : SetTheoryBasis.member
      (taggedPointTag V) (taggedTrue V) :=
    hSub _ (tag_member_point V)
  have hTagEqPoint : taggedPointTag V = taggedPoint V :=
    (member_modelSingleton (taggedPointTag V) (taggedPoint V)).mp
      hTagInTrue
  have hTagSingleton : taggedPointTag V =
      modelSingleton (taggedPointTag V) := by
    simpa only [taggedPoint] using hTagEqPoint
  exact taggedPointTag_ne_singleton V (taggedPointTag V)
    hTagSingleton

/-- False is in the revised Prop carrier. -/
theorem taggedFalse_member_prop (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.member (SetTheoryBasis.emptySet V)
      (taggedProp V) := by
  apply (SetTheoryBasis.member_powerset).mpr
  intro z hz
  exact False.elim (SetTheoryBasis.not_member_empty V z hz)

/-- True is in the revised Prop carrier. -/
theorem taggedTrue_member_prop (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.member (taggedTrue V) (taggedProp V) :=
  (SetTheoryBasis.member_powerset).mpr (fun _ h => h)

/-- The two truth values differ because True contains the proof point. -/
theorem taggedTrue_ne_empty (V : Type u)
    [SetTheoryBasis V] :
    taggedTrue V ≠ SetTheoryBasis.emptySet V := by
  intro h
  have hWrong : SetTheoryBasis.member (taggedPoint V)
      (SetTheoryBasis.emptySet V) := h ▸ taggedPoint_member_true V
  exact SetTheoryBasis.not_member_empty V _ hWrong

/-- Every value of this Prop carrier is exactly true or false. -/
theorem taggedProp_exactly_two (V : Type u)
    [SetTheoryBasis V] (x : V) :
    SetTheoryBasis.member x (taggedProp V) ↔
      (x = SetTheoryBasis.emptySet V ∨ x = taggedTrue V) := by
  constructor
  · intro hx
    have hSub := (SetTheoryBasis.member_powerset).mp hx
    by_cases hOccupied : ∃ z : V, SetTheoryBasis.member z x
    · obtain ⟨z, hz⟩ := hOccupied
      have hzInTrue : SetTheoryBasis.member z (taggedTrue V) :=
        hSub z hz
      have hzPoint : z = taggedPoint V :=
        (member_modelSingleton z (taggedPoint V)).mp hzInTrue
      have hPointInX : SetTheoryBasis.member (taggedPoint V) x := by
        simpa only [hzPoint] using hz
      right
      apply SetTheoryBasis.ext
      intro y
      constructor
      · intro hy
        exact hSub y hy
      · intro hy
        have hyPoint : y = taggedPoint V :=
          (member_modelSingleton y (taggedPoint V)).mp hy
        have hRaw : SetTheoryBasis.member
            (taggedPoint V) x := hPointInX
        simpa only [hyPoint] using hRaw
    · left
      apply SetTheoryBasis.ext
      intro z
      constructor
      · intro hz
        exact False.elim (hOccupied ⟨z, hz⟩)
      · intro hz
        exact False.elim (SetTheoryBasis.not_member_empty V z hz)
  · intro h
    rcases h with hFalse | hTrue
    · subst x
      exact taggedFalse_member_prop V
    · subst x
      exact taggedTrue_member_prop V

/--
UNCONDITIONAL IMAGE FRESHNESS IS FALSE: the image of any nonempty tag
under the CONSTANT tag function equals singleton(tag), i.e. the point.
Therefore a quotient represented as an arbitrary image cannot be
declared fresh by an unproved universal equation; context- and
kind-checked quotients require their own interpretation theorem.
-/
theorem taggedPoint_is_arbitrary_image (V : Type u)
    [SetTheoryBasis V] :
    SetTheoryBasis.image (fun _ : V => taggedPointTag V)
      (taggedPointTag V) = taggedPoint V := by
  apply SetTheoryBasis.ext
  intro z
  constructor
  · intro hz
    obtain ⟨w, _, hzw⟩ :=
      (SetTheoryBasis.member_image).mp hz
    exact (member_modelSingleton z (taggedPointTag V)).mpr hzw
  · intro hz
    have hEq : z = taggedPointTag V :=
      (member_modelSingleton z (taggedPointTag V)).mp hz
    exact (SetTheoryBasis.member_image).mpr
      ⟨SetTheoryBasis.emptySet V, empty_member_tag V, hEq⟩

#print axioms taggedPointTag_ne_singleton
#print axioms taggedPointTag_ne_orderedPair
#print axioms taggedPoint_ne_orderedPair
#print axioms taggedPoint_ne_graph
#print axioms taggedPoint_ne_nat
#print axioms taggedPoint_not_prop
#print axioms taggedProp_exactly_two
#print axioms taggedPoint_is_arbitrary_image

end PSKernelFast.Spec
