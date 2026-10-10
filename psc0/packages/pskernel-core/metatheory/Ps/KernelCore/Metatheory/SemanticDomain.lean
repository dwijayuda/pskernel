import Ps.KernelCore.Core.Expr
import Ps.KernelCore.Metatheory.SemanticLevel

/-!
The semantic algebra needed by conversion and proof irrelevance.

This is a LOCAL interface, not a model of the whole kernel. In particular it
does not postulate a universe hierarchy, dependent function spaces, constants,
or inductives. Its laws concern values, never successful checker calls.
PropositionDomain below constructs an inhabitant of the interface rather than
assuming one. A full set model must later implement this interface together
with the additional structure required by the rest of the kernel.
-/

namespace PsKernelSemantics

universe u

structure ProofDomain (Value : Type u) where
  mem : Value → Value → Prop
  isType : Value → Prop
  propSort : Value
  propSort_isType : isType propSort
  prop_isType : ∀ {p}, mem p propSort → isType p
  proof_irrel : ∀ {p a b}, mem p propSort → mem a p → mem b p → a = b
  empty : Value
  empty_isProp : mem empty propSort
  empty_elim : ∀ {a}, mem a empty → False

/-- A partial interpretation is data, not a certificate that syntax is sound. -/
structure Interpretation {Value : Type u} (D : ProofDomain Value) where
  denote : PsKernelExpr → Option Value

namespace Interpretation

variable {Value : Type u} {D : ProofDomain Value} (I : Interpretation D)

/-- Both expressions must denote, and the second value must be a type. -/
def HasType (e A : PsKernelExpr) : Prop :=
  ∃ v a, I.denote e = some v ∧ I.denote A = some a ∧
    D.isType a ∧ D.mem v a

def WellTyped (e : PsKernelExpr) : Prop := ∃ A, I.HasType e A

/-- This equality does not equate two undefined interpretations. -/
def Equal (a b : PsKernelExpr) : Prop :=
  ∃ v, I.denote a = some v ∧ I.denote b = some v

def IsProp (p : PsKernelExpr) : Prop :=
  ∃ v, I.denote p = some v ∧ D.mem v D.propSort

/-- Only the zero-sort part of syntax interpretation is required here. -/
def PropCompatible : Prop :=
  ∀ level, psKernelLevelNormalizesToZero level = true →
    I.denote (.sort level) = some D.propSort

theorem equal_symm {a b} (h : I.Equal a b) : I.Equal b a := by
  obtain ⟨v, ha, hb⟩ := h
  exact ⟨v, hb, ha⟩

/-- Semantic equality is transitive; this is NOT a rule for the defeq cache. -/
theorem equal_trans {a b c} (hab : I.Equal a b) (hbc : I.Equal b c) :
    I.Equal a c := by
  obtain ⟨v, ha, hb⟩ := hab
  obtain ⟨w, hb', hc⟩ := hbc
  have hvw : v = w := Option.some.inj (hb.symm.trans hb')
  cases hvw
  exact ⟨v, ha, hc⟩

theorem convert {e A B} (h : I.HasType e A) (hAB : I.Equal A B) :
    I.HasType e B := by
  obtain ⟨v, a, he, hA, ha, hv⟩ := h
  obtain ⟨b, hA', hB⟩ := hAB
  have hab : a = b := Option.some.inj (hA.symm.trans hA')
  cases hab
  exact ⟨v, a, he, hB, ha, hv⟩

/-- Unlike the legacy rule, every term is connected to its actual type. -/
theorem proof_irrelevance {a b A B}
    (ha : I.HasType a A) (hb : I.HasType b B)
    (hp : I.IsProp A) (hAB : I.Equal A B) :
    I.Equal a b := by
  have hbA := I.convert hb (I.equal_symm hAB)
  obtain ⟨x, p, hax, hAp, _, hxp⟩ := ha
  obtain ⟨y, q, hby, hAq, _, hyq⟩ := hbA
  obtain ⟨r, hAr, hr⟩ := hp
  have hpq : p = q := Option.some.inj (hAp.symm.trans hAq)
  have hpr : p = r := Option.some.inj (hAp.symm.trans hAr)
  cases hpq
  cases hpr
  have hxy : x = y := D.proof_irrel hr hxp hyq
  cases hxy
  exact ⟨x, hax, hby⟩

/-- An actual empty denotation rules out all semantic typing inhabitants. -/
theorem no_empty_inhabitant {emptyExpr}
    (hEmpty : I.denote emptyExpr = some D.empty) :
    ¬ ∃ e, I.HasType e emptyExpr := by
  rintro ⟨e, v, a, _, hA, _, hv⟩
  have ha : a = D.empty := Option.some.inj (hA.symm.trans hEmpty)
  cases ha
  exact D.empty_elim hv

theorem not_equal_of_undefined {a b}
    (ha : I.denote a = none) : ¬ I.Equal a b := by
  rintro ⟨v, hv, _⟩
  rw [ha] at hv
  cases hv

end Interpretation

/-!
A concrete proposition algebra: propositions are truth conditions, proofs have
one erased value, and Prop contains the proposition values. This witnesses the
local interface's consistency and supports impredicative products into Prop.
It also represents the successor chain of sorts. It does NOT construct the
function spaces or inductives needed for a model of all PSKernel expressions.
-/
namespace PropositionDomain

inductive Value where
  | proof
  | proposition (truth : Prop)
  | propSort
  | typeSort (index : Nat)

def mem : Value → Value → Prop
  | .proof, .proposition truth => truth
  | .proposition _, .propSort => True
  | .propSort, .typeSort 0 => True
  | .typeSort n, .typeSort m => m = n + 1
  | _, _ => False

def isType : Value → Prop
  | .proof => False
  | _ => True

def domain : ProofDomain Value where
  mem := mem
  isType := isType
  propSort := .propSort
  propSort_isType := True.intro
  prop_isType := by
    intro p hp
    cases p <;> simp_all [mem, isType]
  proof_irrel := by
    intro p a b hp ha hb
    cases p <;> cases a <;> cases b <;> simp_all [mem]
  empty := .proposition False
  empty_isProp := True.intro
  empty_elim := by
    intro a ha
    cases a <;> exact ha

/-- The quantified domain may itself be Prop. -/
def pi (a : Value) (body : Value → Prop) : Value :=
  .proposition (∀ v, mem v a → body v)

theorem pi_isProp (a : Value) (body : Value → Prop) :
    mem (pi a body) .propSort := True.intro

theorem pi_intro (a : Value) (body : Value → Prop)
    (h : ∀ v, mem v a → body v) : mem .proof (pi a body) := h

theorem pi_elim {a : Value} {body : Value → Prop}
    (h : mem .proof (pi a body)) {v : Value} (hv : mem v a) :
    body v := h v hv

/-- The impredicative proposition forall p : Prop, p is empty in this algebra. -/
theorem no_proof_of_all_props :
    ¬ mem .proof (pi .propSort (fun p => mem .proof p)) := by
  intro h
  exact h (.proposition False) True.intro

def sortValue : Nat → Value
  | 0 => .propSort
  | n + 1 => .typeSort n

theorem sortValue_isType (n : Nat) : isType (sortValue n) := by
  cases n <;> trivial

theorem sortValue_mem_succ (n : Nat) : mem (sortValue n) (sortValue (n + 1)) := by
  cases n <;> simp [sortValue, mem]

theorem sortValue_not_mem_self (n : Nat) : ¬ mem (sortValue n) (sortValue n) := by
  cases n <;> simp [sortValue, mem]

/-- A small local valuation, used only to establish adequacy of the interface. -/
def witness : Interpretation domain where
  denote
    | .sort level =>
        some (sortValue (evalLevel (fun _ => 0) (fun _ => 0) level))
    | .bvar 0 => some (.proposition True)
    | .bvar 1 => some .proof
    | .bvar 2 => some (.proposition False)
    | .bvar 3 => some .proof
    | _ => none

theorem witness_propCompatible : witness.PropCompatible := by
  intro level h
  simp [witness, normalizesToZero_eval (fun _ => 0) (fun _ => 0) level h,
    sortValue, domain]

/-- Concrete interpretation of the kernel's sort-successor typing rule. -/
theorem witness_sort_hasType (level : PsKernelLevel) :
    witness.HasType (.sort level) (.sort (.succ level)) := by
  let n := evalLevel (fun _ => 0) (fun _ => 0) level
  exact ⟨sortValue n, sortValue (n + 1), rfl, rfl,
    sortValue_isType (n + 1), sortValue_mem_succ n⟩

theorem witness_no_type_in_type (level : PsKernelLevel) :
    ¬ witness.HasType (.sort level) (.sort level) := by
  rintro ⟨v, a, hv, ha, _, hmem⟩
  have hv' : v = sortValue (evalLevel (fun _ => 0) (fun _ => 0) level) :=
    (Option.some.inj hv).symm
  have ha' : a = sortValue (evalLevel (fun _ => 0) (fun _ => 0) level) :=
    (Option.some.inj ha).symm
  cases hv'
  cases ha'
  exact sortValue_not_mem_self _ hmem

theorem witness_proposition : witness.IsProp (.bvar 0) :=
  ⟨.proposition True, rfl, True.intro⟩

theorem witness_inhabited : witness.HasType (.bvar 1) (.bvar 0) :=
  ⟨.proof, .proposition True, rfl, rfl, True.intro, True.intro⟩

theorem witness_proof_irrelevance : witness.Equal (.bvar 1) (.bvar 3) := by
  apply witness.proof_irrelevance witness_inhabited
    (show witness.HasType (.bvar 3) (.bvar 0) from
      ⟨.proof, .proposition True, rfl, rfl, True.intro, True.intro⟩)
    witness_proposition
  exact ⟨.proposition True, rfl, rfl⟩

theorem witness_empty : ¬ ∃ e, witness.HasType e (.bvar 2) :=
  witness.no_empty_inhabitant rfl

theorem witness_not_universal : ¬ witness.Equal (.bvar 0) (.bvar 2) := by
  rintro ⟨v, hTrue, hFalse⟩
  have h : Value.proposition True = Value.proposition False :=
    Option.some.inj (hTrue.trans hFalse.symm)
  have hTF : True = False := Value.proposition.inj h
  exact hTF.mp True.intro

theorem undefined_not_equal : ¬ witness.Equal (.bvar 4) (.bvar 4) :=
  witness.not_equal_of_undefined rfl

end PropositionDomain
end PsKernelSemantics

#print axioms PsKernelSemantics.Interpretation.proof_irrelevance
#print axioms PsKernelSemantics.Interpretation.no_empty_inhabitant
#print axioms PsKernelSemantics.PropositionDomain.witness_sort_hasType
#print axioms PsKernelSemantics.PropositionDomain.witness_no_type_in_type
#print axioms PsKernelSemantics.PropositionDomain.witness_empty
#print axioms PsKernelSemantics.PropositionDomain.witness_not_universal
#print axioms PsKernelSemantics.PropositionDomain.no_proof_of_all_props
