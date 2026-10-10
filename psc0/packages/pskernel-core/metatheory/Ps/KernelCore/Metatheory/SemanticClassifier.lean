import Ps.KernelCore.Metatheory.SemanticDomain
import Ps.KernelCore.Metatheory.SemanticLevel
import Ps.KernelCore.Metatheory.DefEqClassifierTrace

/-!
A semantic bridge for the actual proposition classifier and the calls in the
proof-irrelevance branch. No legacy typing/equality judgments are imported.

These are modular theorems: the callback obligations below are parameters, NOT
axioms or already-proved properties of the concrete checker knot. Configuration
preservation cannot instantiate them. In particular infer-only must receive
valid input evidence and connect the input to its actual returned type.
-/

namespace PsKernelSemantics

universe u
variable {Value : Type u} {D : ProofDomain Value}

abbrev InferOperation :=
  PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
    Except String (PsKernelExpr × PsKernelCheckerState)

abbrev DefEqOperation :=
  PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr → PsKernelExpr →
    Except String (Bool × PsKernelCheckerState)

/-- Successful checked inference establishes typing without an input-typing premise. -/
def CheckedInferenceSound (I : Interpretation D)
    (context : PsKernelCheckerContext) (StateValid : PsKernelCheckerState → Prop)
    (infer : InferOperation) : Prop :=
  ∀ state next e A, StateValid state →
    infer context state e = .ok (A, next) →
    I.HasType e A ∧ I.WellTyped A ∧ StateValid next

/-- Infer-only needs input validity, including when used to infer a type's type. -/
def InferOnlySoundOn (I : Interpretation D)
    (context : PsKernelCheckerContext) (StateValid : PsKernelCheckerState → Prop)
    (infer : InferOperation) : Prop :=
  ∀ state next e A, StateValid state → I.WellTyped e →
    infer context state e = .ok (A, next) →
    I.HasType e A ∧ I.WellTyped A ∧ StateValid next

/-- Reduction preserves actual denotation on the valid inputs supplied to it. -/
def WhnfSoundOn (I : Interpretation D)
    (context : PsKernelCheckerContext) (StateValid : PsKernelCheckerState → Prop)
    (whnf : InferOperation) : Prop :=
  ∀ state next e result, StateValid state → I.WellTyped e →
    whnf context state e = .ok (result, next) →
    (∀ v, I.denote e = some v → I.denote result = some v) ∧
      I.WellTyped result ∧ StateValid next

/-- Equality success connects the two denotations; it cannot compare undefined values. -/
def DefEqSoundOn (I : Interpretation D)
    (context : PsKernelCheckerContext) (StateValid : PsKernelCheckerState → Prop)
    (defeq : DefEqOperation) : Prop :=
  ∀ state next a b answer, StateValid state → I.WellTyped a → I.WellTyped b →
    defeq context state a b = .ok (answer, next) →
    StateValid next ∧ (answer = true → I.Equal a b)

theorem checkedInference_implies_inferOnly (I : Interpretation D)
    (context : PsKernelCheckerContext) (StateValid : PsKernelCheckerState → Prop)
    (infer : InferOperation)
    (h : CheckedInferenceSound I context StateValid infer) :
    InferOnlySoundOn I context StateValid infer := by
  intro state next e A hs _ run
  exact h state next e A hs run

/-- A valuation-based full model can discharge the zero-sort interpretation law. -/
theorem propCompatible_of_sort_valuation (I : Interpretation D)
    (params metavariables : PsKernelName → Nat) (sortValue : Nat → Value)
    (hZero : sortValue 0 = D.propSort)
    (hSort : ∀ level,
      I.denote (.sort level) = some (sortValue (evalLevel params metavariables level))) :
    I.PropCompatible := by
  intro level h
  rw [hSort, normalizesToZero_eval params metavariables level h, hZero]

/-- Positive classification now has a semantic conclusion, under explicit callbacks. -/
theorem classifier_true_sound (I : Interpretation D)
    (context : PsKernelCheckerContext) (StateValid : PsKernelCheckerState → Prop)
    (infer whnf : InferOperation)
    (hSort : I.PropCompatible)
    (hInfer : InferOnlySoundOn I context StateValid infer)
    (hWhnf : WhnfSoundOn I context StateValid whnf)
    (state next : PsKernelCheckerState) (e : PsKernelExpr)
    (hs : StateValid state) (he : I.WellTyped e)
    (run : psKernelDefEqIsPropWith infer whnf context state e = .ok (true, next)) :
    I.IsProp e ∧ StateValid next := by
  obtain ⟨A, inferredState, level, hi, hw, hz⟩ :=
    (psKernelDefEqIsPropWith_true_iff_trace infer whnf context state next e).mp run
  obtain ⟨hTyped, hAValid, hState⟩ := hInfer state inferredState e A hs he hi
  obtain ⟨hValues, _, hNext⟩ :=
    hWhnf inferredState next A (.sort level) hState hAValid hw
  obtain ⟨v, a, hev, hAa, _, hva⟩ := hTyped
  have hReduced := hValues a hAa
  have ha : a = D.propSort :=
    Option.some.inj (hReduced.symm.trans (hSort level hz))
  cases ha
  exact ⟨⟨v, hev, hva⟩, hNext⟩

/-- The exact four calls in the knot's positive proof-irrelevance branch.

The classifier runs on the LEFT TYPE, not on the left proof. Input typing,
both returned types, all intermediate states, and the recursive type comparison
remain connected. Reduction to the core terms and cache publication are separate
obligations; this theorem does not claim full-knot soundness.
-/
theorem proofIrrelevance_calls_sound (I : Interpretation D)
    (context : PsKernelCheckerContext) (StateValid : PsKernelCheckerState → Prop)
    (infer whnf : InferOperation) (defeq : DefEqOperation)
    (hSort : I.PropCompatible)
    (hInfer : InferOnlySoundOn I context StateValid infer)
    (hWhnf : WhnfSoundOn I context StateValid whnf)
    (hDefEq : DefEqSoundOn I context StateValid defeq)
    (state leftState propState rightState next : PsKernelCheckerState)
    (left right leftType rightType : PsKernelExpr)
    (hs : StateValid state) (hl : I.WellTyped left) (hr : I.WellTyped right)
    (hLeft : infer context state left = .ok (leftType, leftState))
    (hProp : psKernelDefEqIsPropWith infer whnf context leftState leftType =
      .ok (true, propState))
    (hRight : infer context propState right = .ok (rightType, rightState))
    (hCompare : defeq context rightState leftType rightType = .ok (true, next)) :
    I.Equal left right ∧ StateValid next := by
  obtain ⟨hlTyped, hlTypeValid, hlState⟩ :=
    hInfer state leftState left leftType hs hl hLeft
  obtain ⟨hp, hpState⟩ :=
    classifier_true_sound I context StateValid infer whnf hSort hInfer hWhnf
      leftState propState leftType hlState hlTypeValid hProp
  obtain ⟨hrTyped, hrTypeValid, hrState⟩ :=
    hInfer propState rightState right rightType hpState hr hRight
  obtain ⟨hNext, hEq⟩ :=
    hDefEq rightState next leftType rightType true hrState hlTypeValid hrTypeValid hCompare
  exact ⟨I.proof_irrelevance hlTyped hrTyped hp (hEq rfl), hNext⟩

/- A concrete negative check on the interface: an operational trace alone can
   classify a proof as a proposition when its inference callback lies. -/
namespace PropositionDomain

def forgedInfer : InferOperation :=
  fun _ state _ => .ok (.sort .zero, state)

def identityWhnf : InferOperation :=
  fun _ state e => .ok (e, state)

theorem forged_classifier_succeeds (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState) :
    psKernelDefEqIsPropWith forgedInfer identityWhnf context state (.bvar 1) =
      .ok (true, state) := rfl

theorem proof_is_not_proposition : ¬ witness.IsProp (.bvar 1) := by
  rintro ⟨v, hv, hp⟩
  have he : v = Value.proof := (Option.some.inj hv).symm
  cases he
  exact hp

theorem operational_success_is_insufficient (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState) :
    psKernelDefEqIsPropWith forgedInfer identityWhnf context state (.bvar 1) =
        .ok (true, state) ∧
      ¬ witness.IsProp (.bvar 1) :=
  ⟨forged_classifier_succeeds context state, proof_is_not_proposition⟩

theorem forgedInfer_not_sound (context : PsKernelCheckerContext) :
    ¬ InferOnlySoundOn witness context (fun _ => True) forgedInfer := by
  intro h
  have valid : witness.WellTyped (.bvar 1) := ⟨.bvar 0, witness_inhabited⟩
  -- An arbitrary state is enough; the contract must hold for all states.
  let state : PsKernelCheckerState := psKernelCheckerStateEmpty
  obtain ⟨⟨v, a, hv, ha, _, hmem⟩, _, _⟩ :=
    h state state (.bvar 1) (.sort .zero) True.intro valid rfl
  have hv' : v = Value.proof := (Option.some.inj hv).symm
  have ha' : a = Value.propSort := (Option.some.inj ha).symm
  cases hv'
  cases ha'
  exact hmem

end PropositionDomain
end PsKernelSemantics

#print axioms PsKernelSemantics.classifier_true_sound
#print axioms PsKernelSemantics.proofIrrelevance_calls_sound
#print axioms PsKernelSemantics.PropositionDomain.forgedInfer_not_sound
