import Ps.KernelCore.Metatheory.SemanticAbstraction
import Ps.KernelCore.Checker.State

/-!
Scope and fresh-name invariants for the binder operations. These are syntax
theorems for all constructors; preservation by the recursive checker and its
initial API context remains a separate obligation.
-/

namespace PsKernelSemantics
namespace AnnotatedExpr

theorem scoped_mono (e : AnnotatedExpr) {n m : Nat}
    (h : e.Scoped n) (hn : n ≤ m) : e.Scoped m := by
  induction e generalizing n m with
  | bvar i => exact Nat.lt_of_lt_of_le h hn
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => trivial
  | app f a ihf iha => exact ⟨ihf h.1 hn, iha h.2 hn⟩
  | lam n A b bi v ihA ihb | forallE n A b bi v ihA ihb =>
      exact ⟨ihA h.1 hn, ihb h.2 (by omega)⟩
  | letE n A a b nd ihA iha ihb =>
      exact ⟨ihA h.1 hn, iha h.2.1 hn, ihb h.2.2 (by omega)⟩
  | mdata md e ih | proj n i e ih => exact ih h hn

theorem scoped_liftN (e : AnnotatedExpr) (n amount cut : Nat)
    (h : e.Scoped n) (hc : cut ≤ n) :
    (liftN amount e cut).Scoped (n + amount) := by
  induction e generalizing n cut with
  | bvar i =>
      simp only [liftN]
      split <;> simp only [Scoped] <;> change i < n at h <;> omega
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => trivial
  | app f a ihf iha => exact ⟨ihf n cut h.1 hc, iha n cut h.2 hc⟩
  | lam name A b bi v ihA ihb | forallE name A b bi v ihA ihb =>
      refine ⟨ihA n cut h.1 hc, ?_⟩
      simpa [Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using
        ihb (n + 1) (cut + 1) h.2 (by omega)
  | letE name A a b nd ihA iha ihb =>
      refine ⟨ihA n cut h.1 hc, iha n cut h.2.1 hc, ?_⟩
      simpa [Nat.add_assoc, Nat.add_comm, Nat.add_left_comm] using
        ihb (n + 1) (cut + 1) h.2.2 (by omega)
  | mdata md e ih | proj name i e ih => exact ih n cut h hc

/-- The replacement is scoped below the binders traversed by substitution. -/
theorem scoped_inst (e a : AnnotatedExpr) (n cut : Nat)
    (he : e.Scoped (n + 1)) (ha : a.Scoped (n - cut)) (hc : cut ≤ n) :
    (inst a e cut).Scoped n := by
  induction e generalizing n cut with
  | bvar i =>
      simp only [inst]
      split
      · simp only [Scoped]; omega
      · split
        · have h := scoped_liftN a (n - cut) cut 0 ha (Nat.zero_le _)
          simpa only [Nat.sub_add_cancel hc] using h
        · simp only [Scoped]
          change i < n + 1 at he
          omega
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => trivial
  | app f b ihf ihb => exact ⟨ihf n cut he.1 ha hc, ihb n cut he.2 ha hc⟩
  | lam name A b bi v ihA ihb | forallE name A b bi v ihA ihb =>
      refine ⟨ihA n cut he.1 ha hc, ?_⟩
      exact ihb (n + 1) (cut + 1) he.2 (by simpa using ha) (by omega)
  | letE name A b c nd ihA ihb ihc =>
      refine ⟨ihA n cut he.1 ha hc, ihb n cut he.2.1 ha hc, ?_⟩
      exact ihc (n + 1) (cut + 1) he.2.2 (by simpa using ha) (by omega)
  | mdata md e ih | proj name i e ih => exact ih n cut he ha hc

theorem scoped_close (e : AnnotatedExpr) (name : PsKernelName) (n cut : Nat)
    (h : e.Scoped n) (hc : cut ≤ n) : (close name e cut).Scoped (n + 1) := by
  induction e generalizing n cut with
  | bvar i => exact Nat.lt_trans h (Nat.lt_succ_self n)
  | fvar i => simp only [close]; split <;> simp only [Scoped] <;> omega
  | mvar _ | sort _ | const _ _ | lit _ => trivial
  | app f a ihf iha => exact ⟨ihf n cut h.1 hc, iha n cut h.2 hc⟩
  | lam nm A b bi v ihA ihb | forallE nm A b bi v ihA ihb =>
      exact ⟨ihA n cut h.1 hc, ihb (n + 1) (cut + 1) h.2 (by omega)⟩
  | letE nm A a b nd ihA iha ihb =>
      exact ⟨ihA n cut h.1 hc, iha n cut h.2.1 hc,
        ihb (n + 1) (cut + 1) h.2.2 (by omega)⟩
  | mdata md e ih | proj nm i e ih => exact ih n cut h hc

/-- Numeric free-variable identities in the expression precede the counter.
Non-numeric free names cannot collide with the allocator's numeric result. -/
def NamesBelow (limit : Nat) : AnnotatedExpr → Prop
  | .fvar (.num _ i) => i < limit
  | .app f a => NamesBelow limit f ∧ NamesBelow limit a
  | .lam _ A b _ _ | .forallE _ A b _ _ => NamesBelow limit A ∧ NamesBelow limit b
  | .letE _ A a b _ => NamesBelow limit A ∧ NamesBelow limit a ∧ NamesBelow limit b
  | .mdata _ e | .proj _ _ e => NamesBelow limit e
  | _ => True

theorem namesBelow_fresh (e : AnnotatedExpr) (limit : Nat)
    (h : NamesBelow limit e) (base : PsKernelName) : Fresh (.num base limit) e := by
  induction e with
  | fvar n =>
      change psKernelNameEq n (.num base limit) = false
      cases he : psKernelNameEq n (.num base limit) with
      | false => rfl
      | true =>
          have hn := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435
            n (.num base limit) he
          cases hn
          change limit < limit at h
          exact False.elim (Nat.lt_irrefl _ h)
  | bvar _ | mvar _ | sort _ | const _ _ | lit _ => trivial
  | app f a ihf iha => exact ⟨ihf h.1, iha h.2⟩
  | lam n A b bi v ihA ihb | forallE n A b bi v ihA ihb =>
      exact ⟨ihA h.1, ihb h.2⟩
  | letE n A a b nd ihA iha ihb => exact ⟨ihA h.1, iha h.2.1, ihb h.2.2⟩
  | mdata md e ih | proj n i e ih => exact ih h

theorem allocator_fresh (state : PsKernelCheckerState) (base : PsKernelName)
    (e : AnnotatedExpr) (h : NamesBelow state.nextFresh e) :
    Fresh (psKernelCheckerStateFreshName state base).1 e :=
  namesBelow_fresh e state.nextFresh h base

/-- The native loose-variable check sees the proven scope after opening. -/
theorem opened_has_no_loose (e : AnnotatedExpr) (name : PsKernelName)
    (h : e.Scoped 1) :
    psKernelExprHasLooseAt (psKernelExprInstantiate1 e.erase (.fvar name)) 0 = false := by
  change psKernelExprHasLooseAt
    (psKernelExprInstantiate1 e.erase (AnnotatedExpr.fvar name).erase) 0 = false
  rw [← erase_instantiate1 e (.fvar name)]
  exact (scoped_iff_noLoose _ 0).mp
    (scoped_inst e (.fvar name) 0 0 h True.intro (Nat.zero_le _))

theorem closed_has_one_binder (e : AnnotatedExpr) (name : PsKernelName)
    (h : e.Scoped 0) :
    psKernelExprHasLooseAt (psKernelExprAbstractFVars e.erase [name]) 1 = false := by
  rw [← erase_abstractFVar e name]
  exact (scoped_iff_noLoose _ 1).mp
    (scoped_close e name 0 0 h (Nat.zero_le _))

theorem namesBelow_mono (e : AnnotatedExpr) {n m : Nat}
    (h : NamesBelow n e) (hn : n ≤ m) : NamesBelow m e := by
  induction e with
  | fvar name =>
      cases name with
      | anonymous | str _ _ => trivial
      | num _ i => exact Nat.lt_of_lt_of_le h hn
  | bvar _ | mvar _ | sort _ | const _ _ | lit _ => trivial
  | app f a ihf iha => exact ⟨ihf h.1, iha h.2⟩
  | lam name A b bi v ihA ihb | forallE name A b bi v ihA ihb =>
      exact ⟨ihA h.1, ihb h.2⟩
  | letE name A a b nd ihA iha ihb => exact ⟨ihA h.1, iha h.2.1, ihb h.2.2⟩
  | mdata md e ih | proj name i e ih => exact ih h

theorem namesBelow_liftN (e : AnnotatedExpr) (limit amount cut : Nat) :
    NamesBelow limit (liftN amount e cut) ↔ NamesBelow limit e := by
  induction e generalizing cut with
  | bvar i => simp only [liftN]; split <;> trivial
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => rfl
  | app f a ihf iha => exact and_congr (ihf cut) (iha cut)
  | lam name A b bi v ihA ihb | forallE name A b bi v ihA ihb =>
      exact and_congr (ihA cut) (ihb (cut + 1))
  | letE name A a b nd ihA iha ihb =>
      exact and_congr (ihA cut) (and_congr (iha cut) (ihb (cut + 1)))
  | mdata md e ih | proj name i e ih => exact ih cut

theorem namesBelow_inst (e a : AnnotatedExpr) (limit cut : Nat)
    (he : NamesBelow limit e) (ha : NamesBelow limit a) :
    NamesBelow limit (inst a e cut) := by
  induction e generalizing cut with
  | bvar i =>
      simp only [inst]
      split
      · trivial
      · split
        · exact (namesBelow_liftN a limit cut 0).mpr ha
        · trivial
  | fvar _ | mvar _ | sort _ | const _ _ | lit _ => exact he
  | app f b ihf ihb => exact ⟨ihf cut he.1, ihb cut he.2⟩
  | lam name A b bi v ihA ihb | forallE name A b bi v ihA ihb =>
      exact ⟨ihA cut he.1, ihb (cut + 1) he.2⟩
  | letE name A b c nd ihA ihb ihc =>
      exact ⟨ihA cut he.1, ihb cut he.2.1, ihc (cut + 1) he.2.2⟩
  | mdata md e ih | proj name i e ih => exact ih cut he

/-- The allocation/opening pair used by inference establishes both parts of the
child frame: no loose bound indices, and all numeric free identities below the
new counter. The theorem is about the actual allocated name and actual native
instantiation, not a separately chosen fresh symbol. -/
theorem allocated_open_frame (state : PsKernelCheckerState) (base : PsKernelName)
    (e : AnnotatedExpr) (hs : e.Scoped 1) (hn : NamesBelow state.nextFresh e) :
    ∃ opened : AnnotatedExpr,
      opened.erase = psKernelExprInstantiate1 e.erase
        (.fvar (psKernelCheckerStateFreshName state base).1) ∧
      opened.Scoped 0 ∧
      NamesBelow (psKernelCheckerStateFreshName state base).2.nextFresh opened := by
  let name := (psKernelCheckerStateFreshName state base).1
  refine ⟨inst (.fvar name) e 0, erase_instantiate1 e (.fvar name),
    scoped_inst e (.fvar name) 0 0 hs True.intro (Nat.zero_le _), ?_⟩
  apply namesBelow_inst
  · exact namesBelow_mono e hn (Nat.le_succ _)
  · change state.nextFresh < state.nextFresh + 1
    omega

end AnnotatedExpr
end PsKernelSemantics
