import PSKernelFast.Spec.SetTheoryBasis

/-!
P1f: model-level DATA ENCODING CONTRACT, independent of the checker.

Do not add disjointness assumptions: derive all equations directly from
the explicitly supplied SetTheoryBasis V. A tagged proof point can be
fresh from graph values ONLY relative to these precise constructors.
Other encodings (quotient classes, data representations) require a
separate, source-matched theorem, not a guessed global freshness law.
-/

namespace PSKernelFast.Spec

universe u
variable {V : Type u} [SetTheoryBasis V]

/-- Unordered pair {a,a}, derived from the ONE given set pairing law. -/
noncomputable def modelSingleton (a : V) : V :=
  SetTheoryBasis.pair a a

theorem member_modelSingleton (z a : V) :
    SetTheoryBasis.member z (modelSingleton a) ↔ z = a := by
  unfold modelSingleton
  constructor
  · intro hz
    rcases (SetTheoryBasis.member_pair).mp hz with h | h
    · exact h
    · exact h
  · intro hz
    subst z
    exact (SetTheoryBasis.member_pair).mpr (Or.inl rfl)

theorem modelSingleton_member (a : V) :
    SetTheoryBasis.member a (modelSingleton a) :=
  (member_modelSingleton a a).mpr rfl

theorem modelSingleton_inj {a b : V}
    (h : modelSingleton a = modelSingleton b) : a = b :=
  (member_modelSingleton a b).mp
    (h ▸ modelSingleton_member a)

/--
Standard Kuratowski pair of two model values: {{a}, {a,b}}.
The proof point must not equal any such pair or any image of pairs.
-/
noncomputable def modelOrderedPair (a b : V) : V :=
  SetTheoryBasis.pair (modelSingleton a) (SetTheoryBasis.pair a b)

theorem member_modelOrderedPair (z a b : V) :
    SetTheoryBasis.member z (modelOrderedPair a b) ↔
      z = modelSingleton a ∨ z = SetTheoryBasis.pair a b := by
  unfold modelOrderedPair
  exact SetTheoryBasis.member_pair

/-- Every direct member of a Kuratowski pair is itself NONEMPTY. -/
theorem member_orderedPair_nonempty (a b z : V)
    (hz : SetTheoryBasis.member z (modelOrderedPair a b)) :
    ∃ w : V, SetTheoryBasis.member w z := by
  rcases (member_modelOrderedPair z a b).mp hz with h | h
  · subst z
    exact ⟨a, modelSingleton_member a⟩
  · subst z
    exact ⟨a, (SetTheoryBasis.member_pair).mpr (Or.inl rfl)⟩

/-- Every occurrence in the model graph is an actual pair. -/
noncomputable def modelGraph (F : V → V) (A : V) : V :=
  SetTheoryBasis.image (fun x => modelOrderedPair x (F x)) A

theorem member_modelGraph (F : V → V) (A z : V) :
    SetTheoryBasis.member z (modelGraph F A) ↔
      ∃ x : V, SetTheoryBasis.member x A ∧
        z = modelOrderedPair x (F x) := by
  unfold modelGraph
  exact SetTheoryBasis.member_image

/-- Von Neumann successor, defined from the same underlying set operations. -/
noncomputable def modelNatSucc (n : V) : V :=
  SetTheoryBasis.union (SetTheoryBasis.pair n (modelSingleton n))

theorem member_modelNatSucc (z n : V) :
    SetTheoryBasis.member z (modelNatSucc n) ↔
      SetTheoryBasis.member z n ∨ z = n := by
  constructor
  · intro hz
    obtain ⟨w, hw, hzw⟩ :=
      (SetTheoryBasis.member_union).mp hz
    rcases (SetTheoryBasis.member_pair).mp hw with h | h
    · left
      simpa only [h] using hzw
    · right
      exact (member_modelSingleton z n).mp (by simpa only [h] using hzw)
  · intro h
    rcases h with hz | hz
    · exact (SetTheoryBasis.member_union).mpr
        ⟨n, (SetTheoryBasis.member_pair).mpr (Or.inl rfl), hz⟩
    · subst z
      exact (SetTheoryBasis.member_union).mpr
        ⟨modelSingleton n,
          (SetTheoryBasis.member_pair).mpr (Or.inr rfl),
          modelSingleton_member n⟩

/-- Model finite ordinals, with no new arithmetic/induction axiom. -/
noncomputable def modelNat (V : Type u) [SetTheoryBasis V] : Nat → V
  | 0 => SetTheoryBasis.emptySet V
  | n + 1 => modelNatSucc (modelNat V n)

/-- Empty is a member of every strictly positive finite ordinal. -/
theorem empty_member_modelNat_succ (V : Type u)
    [SetTheoryBasis V] (n : Nat) :
    SetTheoryBasis.member (SetTheoryBasis.emptySet V)
      (modelNat V (n + 1)) := by
  induction n with
  | zero =>
      exact (member_modelNatSucc (SetTheoryBasis.emptySet V)
        (SetTheoryBasis.emptySet V)).mpr (Or.inr rfl)
  | succ k ih =>
      exact (member_modelNatSucc (SetTheoryBasis.emptySet V)
        (modelNat V (k + 1))).mpr (Or.inl ih)

/-- Singleton closure in a Grothendieck universe, derived by powerset. -/
theorem universe_modelSingleton_closed (V : Type u)
    [SetTheoryBasis V] (n : Nat) (x : V)
    (hx : SetTheoryBasis.member x (SetTheoryBasis.univ n)) :
    SetTheoryBasis.member (modelSingleton x) (SetTheoryBasis.univ n) := by
  have hp : SetTheoryBasis.member (SetTheoryBasis.powerset x)
      (SetTheoryBasis.univ n) :=
    SetTheoryBasis.universe_powerset_closed (V := V) n x hx
  apply SetTheoryBasis.universe_subset_closed (V := V)
    n (SetTheoryBasis.powerset x) (modelSingleton x) hp
  intro z hz
  have heq : z = x := (member_modelSingleton z x).mp hz
  subst z
  exact (SetTheoryBasis.member_powerset).mpr (fun w hw => hw)

#print axioms member_modelSingleton
#print axioms modelSingleton_inj
#print axioms member_orderedPair_nonempty
#print axioms member_modelGraph
#print axioms member_modelNatSucc
#print axioms empty_member_modelNat_succ
#print axioms universe_modelSingleton_closed

end PSKernelFast.Spec
