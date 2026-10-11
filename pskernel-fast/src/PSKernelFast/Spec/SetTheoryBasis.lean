import PSKernelFast.Spec.ErasedExpr

/-!
P1d proof-only set-theoretic *basis*. Inspired by standard ZF-minus-infinity
and the con-leche assumption boundary, but independently specified.

WARNING: a SetTheoryBasis instance is a mathematical ASSUMPTION, not an
instance proved from Lean's own unrestricted logic. No implementation,
SetTheoryBasis instance, impredicative Pi interpretation, typed semantic
soundness, declaration-model extension, or consistency theorem is claimed.

The desired model requires a chain of Grothendieck universes. Existence of
such a chain is stronger than Lean's internal consistency assumptions and
must not be conjured by a new global axiom.
-/

namespace PSKernelFast.Spec

universe u

/-- Pure set-theoretic equinumerosity, with the membership relation explicit. -/
def Equinumerous {V : Type u} (mem : V → V → Prop) (a b : V) : Prop :=
  ∃ f : V → V,
    (∀ x, mem x a → mem (f x) b) ∧
    (∀ x y, mem x a → mem y a → f x = f y → x = y) ∧
    (∀ z, mem z b → ∃ x, mem x a ∧ f x = z)

/--
Tarski-style universe laws: transitivity, subset closure, power-subset
coverage, and a size alternative. These are hypotheses about V, not
constructed inhabitants, and they do not by themselves interpret Pi.
-/
def GrothUniverse {V : Type u} (mem : V → V → Prop) (U : V) : Prop :=
  (∀ x y, mem x U → mem y x → mem y U) ∧
  (∀ x y, mem x U → (∀ z, mem z y → mem z x) → mem y U) ∧
  (∀ x, mem x U →
    ∃ p, mem p U ∧ ∀ z, (∀ w, mem w z → mem w x) → mem z p) ∧
  (∀ x, (∀ z, mem z x → mem z U) → Equinumerous mem x U ∨ mem x U)

/--
The *explicit* relative set-theory assumptions available to P1d proofs.
No global instance is provided; conclusions quantify over a caller-supplied
model. Six ZF-style laws plus the omega-indexed universe tower.
-/
class SetTheoryBasis (V : Type u) where
  member : V → V → Prop
  ext : ∀ {x y : V}, (∀ z, member z x ↔ member z y) → x = y
  pair : V → V → V
  member_pair : ∀ {z x y : V}, member z (pair x y) ↔ z = x ∨ z = y
  union : V → V
  member_union :
    ∀ {z x : V}, member z (union x) ↔ ∃ y, member y x ∧ member z y
  powerset : V → V
  member_powerset :
    ∀ {z x : V}, member z (powerset x) ↔ ∀ y, member y z → member y x
  regularity :
    ∀ x : V, (∃ y, member y x) →
      ∃ y, member y x ∧ ¬ ∃ z, member z y ∧ member z x
  image : (V → V) → V → V
  member_image :
    ∀ {f : V → V} {x y : V},
      member y (image f x) ↔ ∃ z, member z x ∧ y = f z
  univ : Nat → V
  univ_step : ∀ n : Nat, member (univ n) (univ (n + 1))
  univ_groth : ∀ n : Nat, GrothUniverse member (univ n)

namespace SetTheoryBasis

variable {V : Type u} [SetTheoryBasis V]

/-- A syntactic convention: set membership is always the supplied model's. -/
def Mem (x y : V) : Prop := SetTheoryBasis.member x y

/-- A universe stage is a member of the immediately following stage. -/
theorem universe_step (n : Nat) :
    Mem (SetTheoryBasis.univ n : V)
      (SetTheoryBasis.univ (n + 1)) :=
  SetTheoryBasis.univ_step n

/-- Every supplied Grothendieck-universe stage is transitive. -/
theorem universe_transitive (n : Nat) (a b : V)
    (ha : Mem a (SetTheoryBasis.univ n))
    (hb : Mem b a) :
    Mem b (SetTheoryBasis.univ n) :=
  (SetTheoryBasis.univ_groth n).1 a b ha hb

/--
A nontrivial consequence of the assumed universe tower: the stage at
n belongs to the stage at n+2, *derived from transitivity* rather than
assuming all higher-stage memberships.
-/
theorem universe_two_steps (n : Nat) :
    Mem (SetTheoryBasis.univ n : V)
      (SetTheoryBasis.univ (n + 2)) := by
  have first : Mem (SetTheoryBasis.univ n : V)
      (SetTheoryBasis.univ (n + 1)) := universe_step n
  have second : Mem (SetTheoryBasis.univ (n + 1) : V)
      (SetTheoryBasis.univ (n + 2)) := by
    simpa [Nat.add_assoc] using (universe_step (V := V) (n + 1))
  exact universe_transitive (V := V) (n + 2)
    (SetTheoryBasis.univ (n + 1)) (SetTheoryBasis.univ n)
    second first


/--
There is an empty set, DERIVED from regularity and the transitivity of
the supplied first universe stage. No extra empty-set axiom is added:
if the stage has a member, regularity chooses a minimal one and the
universe's transitivity proves it has no members; otherwise the stage
itself is empty.
-/
theorem exists_empty (V : Type u) [SetTheoryBasis V] :
    ∃ e : V, ∀ z : V, ¬ Mem z e := by
  let U : V := SetTheoryBasis.univ 0
  by_cases hNonempty : ∃ x : V, Mem x U
  · obtain ⟨x, hx, hMinimal⟩ :=
      SetTheoryBasis.regularity U hNonempty
    refine ⟨x, ?_⟩
    intro z hz
    exact hMinimal ⟨z, hz,
      universe_transitive (V := V) 0 x z hx hz⟩
  · refine ⟨U, ?_⟩
    intro z hz
    exact hNonempty ⟨z, hz⟩

/-- A canonical model-level empty set chosen from a proved existence result. -/
noncomputable def emptySet (V : Type u) [SetTheoryBasis V] : V :=
  Classical.choose (exists_empty V)

/-- A fact about a constructed set, NOT a new axiom. -/
theorem not_member_empty (V : Type u) [SetTheoryBasis V] (z : V) :
    ¬ Mem z (emptySet V) :=
  Classical.choose_spec (exists_empty V) z

/-- Downward subset closure of every supplied Grothendieck universe. -/
theorem universe_subset_closed (n : Nat) (x y : V)
    (hx : Mem x (SetTheoryBasis.univ n))
    (hSub : ∀ z : V, Mem z y → Mem z x) :
    Mem y (SetTheoryBasis.univ n) :=
  (SetTheoryBasis.univ_groth n).2.1 x y hx hSub

/--
The POWERSET closure needed to place the two truth-value sets inside
the next universe. Derived from the Tarski covering clause and the
universe's subset closure, rather than posited as a new law.
-/
theorem universe_powerset_closed (n : Nat) (x : V)
    (hx : Mem x (SetTheoryBasis.univ n)) :
    Mem (SetTheoryBasis.powerset x) (SetTheoryBasis.univ n) := by
  obtain ⟨p, hp, hCover⟩ :=
    (SetTheoryBasis.univ_groth n).2.2.1 x hx
  exact universe_subset_closed (V := V) n p
    (SetTheoryBasis.powerset x) hp
    (fun z hz => hCover z
      ((SetTheoryBasis.member_powerset).mp hz))

end SetTheoryBasis
end PSKernelFast.Spec
