import Ps.KernelCore.Metatheory.SemanticInterpretation
import Ps.KernelCore.Metatheory.Comparator

/-!
The production structural comparator preserves set denotation when the two
semantic readings agree on every binder's Prop/Type regime. This is the precise
extra obligation exposed by erasure_is_not_semantic_coherence. A full checker
proof must derive regime agreement from valid-input evidence; this module does
not assume that equal erased syntax alone supplies it.
-/

namespace PsKernelSemantics.SetModel
open ConLeche ConLeche.SetModel
open AnnotatedExpr

universe u
variable {V : Type u} [SetTheory V]

/-- Only binder regimes are additional semantic data. Shape and leaf equality
are checked separately by the actual PSKernel comparator. -/
def RegimesAgree (M : Reading V) : AnnotatedExpr → AnnotatedExpr → Prop
  | .lam _ A b _ v, .lam _ A' b' _ v' =>
      (M.level v = 0 ↔ M.level v' = 0) ∧ RegimesAgree M A A' ∧ RegimesAgree M b b'
  | .forallE _ A B _ v, .forallE _ A' B' _ v' =>
      (M.level v = 0 ↔ M.level v' = 0) ∧ RegimesAgree M A A' ∧ RegimesAgree M B B'
  | .app f a, .app f' a' => RegimesAgree M f f' ∧ RegimesAgree M a a'
  | .letE _ A a b _, .letE _ A' a' b' _ =>
      RegimesAgree M A A' ∧ RegimesAgree M a a' ∧ RegimesAgree M b b'
  | .mdata _ e, .mdata _ e' => RegimesAgree M e e'
  | .proj _ _ e, .proj _ _ e' => RegimesAgree M e e'
  | _, _ => True

private theorem andBool_true {a b : Bool}
    (h : (if a then b else false) = true) : a = true ∧ b = true := by
  cases a <;> simp_all

private theorem literal_eq {a b : PsKernelLiteral}
    (h : psKernelLiteralEq a b = true) : a = b := by
  cases a <;> cases b <;> simp [psKernelLiteralEq, psKernelStringEq] at h <;>
    cases h <;> rfl

/-- All constructors, names, levels, literal values and metadata are covered.
No legacy declarative typing/equality relation is imported. -/
theorem exprEq_preserves_interp (M : Reading V) (a other : AnnotatedExpr)
    (hEq : psKernelExprEq a.erase other.erase = true)
    (hRegimes : RegimesAgree M a other) (ρ : Nat → V) :
    interp M ρ a = interp M ρ other := by
  induction a generalizing other ρ with
  | bvar i =>
      cases other <;> simp [erase, psKernelExprEq] at hEq
      cases hEq
      rfl
  | fvar n =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i n'
      have hn := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 n n' hEq
      cases hn
      rfl
  | mvar n =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i n'
      have hn := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 n n' hEq
      cases hn
      rfl
  | sort l =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i l'
      have hl := psKernelLevelEq_sound_of_string_law psKernelStringEq_sound_lean435 l l' hEq
      cases hl
      rfl
  | const n ls =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i n' ls'
      obtain ⟨hn, hl⟩ := andBool_true hEq
      have hn' := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 n n' hn
      have hl' := psKernelLevelListEq_sound_of_string_law psKernelStringEq_sound_lean435 ls ls' hl
      cases hn'
      cases hl'
      rfl
  | app f a ihf iha =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i f' a'
      obtain ⟨hf, ha⟩ := andBool_true hEq
      simp only [interp]
      rw [ihf f' hf hRegimes.1 ρ, iha a' ha hRegimes.2 ρ]
  | lam n A b bi v ihA ihb =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i n' A' b' bi' v'
      obtain ⟨hA, hb⟩ := andBool_true hEq
      simp only [interp]
      rw [ihA A' hA hRegimes.2.1 ρ]
      exact lamR_zero_agree hRegimes.1
        (fun x _ => ihb b' hb hRegimes.2.2 (extend x ρ))
  | forallE n A B bi v ihA ihB =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i n' A' B' bi' v'
      obtain ⟨hA, hB⟩ := andBool_true hEq
      simp only [interp]
      rw [ihA A' hA hRegimes.2.1 ρ]
      exact piR_zero_agree hRegimes.1
        (fun x _ => ihB B' hB hRegimes.2.2 (extend x ρ))
  | letE n A a b nd ihA iha ihb =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i n' A' a' b' nd'
      obtain ⟨_, ht⟩ := andBool_true hEq
      obtain ⟨ha, ht⟩ := andBool_true ht
      obtain ⟨hb, _⟩ := andBool_true ht
      simp only [interp]
      rw [iha a' ha hRegimes.2.1 ρ]
      exact ihb b' hb hRegimes.2.2 _
  | lit l =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      have hl := literal_eq hEq
      cases hl
      rfl
  | mdata md e ih =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i md' e'
      obtain ⟨_, he⟩ := andBool_true hEq
      exact ih e' he hRegimes ρ
  | proj n i e ih =>
      cases other <;> simp only [erase, psKernelExprEq, Bool.false_eq_true] at hEq
      rename_i n' i' e'
      obtain ⟨hn, ht⟩ := andBool_true hEq
      obtain ⟨hi, he⟩ := andBool_true ht
      have hn' := psKernelNameEq_sound_of_string_law psKernelStringEq_sound_lean435 n n' hn
      have hi' := Nat.eq_of_beq_eq_true hi
      cases hn'
      cases hi'
      exact congrArg _ (ih e' he hRegimes ρ)

end PsKernelSemantics.SetModel
