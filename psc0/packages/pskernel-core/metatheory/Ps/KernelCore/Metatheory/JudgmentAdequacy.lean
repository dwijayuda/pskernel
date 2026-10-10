import Ps.KernelCore.Metatheory.Judgments

/-
Adequacy audit of the legacy operational relations.

These theorems expose a specification gap, not a successful run of the
executable checker. In particular, they must never be used as admission or
checker correctness evidence. They establish that the legacy relations cannot
serve as the semantic typing/equality judgment of a consistency proof.

The algorithmic proof-irrelevance constructor forgets how its candidate types
were obtained. Its premises can therefore be supplied independently of the
two terms. Merely restricting the environment or context does not repair this:
the counterexample works for every environment and local context.
-/

namespace PsKernelJudgmentAdequacy

theorem legacy_defeq_is_universal
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (left right : PsKernelExpr) :
    PsKernelDefEqJudgment environment localContext left right :=
  PsKernelDefEqJudgment.proofIrrelevanceAlgorithmic
    left right
    (PsKernelExpr.sort PsKernelLevel.zero)
    (PsKernelExpr.sort PsKernelLevel.zero)
    (PsKernelExpr.sort PsKernelLevel.zero)
    PsKernelLevel.zero
    (PsKernelReductionClosure.refl _)
    rfl
    (PsKernelDefEqJudgment.refl _)

theorem legacy_typing_has_every_type
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (type : PsKernelExpr) :
    PsKernelTypingJudgment environment localContext
      (PsKernelExpr.sort PsKernelLevel.zero) type :=
  PsKernelTypingJudgment.convert
    (PsKernelExpr.sort PsKernelLevel.zero)
    (PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero))
    type
    (PsKernelTypingJudgment.sort PsKernelLevel.zero)
    (legacy_defeq_is_universal environment localContext _ _)

/-- Any equality interpretation of the legacy relation identifies all terms. -/
theorem legacy_defeq_forces_constant_interpretation
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    {Value : Sort u}
    (interpret : PsKernelExpr → Value)
    (sound : ∀ left right,
      PsKernelDefEqJudgment environment localContext left right →
      interpret left = interpret right) :
    ∀ left right, interpret left = interpret right :=
  fun left right => sound left right
    (legacy_defeq_is_universal environment localContext left right)

/--
No interpretation in which some type is empty can validate every legacy
typing derivation. This rules out using this relation alone as the missing
model-soundness bridge. It assumes neither a checker bug nor a new axiom.
-/
theorem legacy_typing_cannot_validate_an_empty_type
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (InhabitedType : PsKernelExpr → Prop)
    (emptyType : PsKernelExpr)
    (empty : ¬ InhabitedType emptyType) :
    ¬ (∀ expr type,
      PsKernelTypingJudgment environment localContext expr type →
      InhabitedType type) := by
  intro sound
  exact empty (sound _ emptyType
    (legacy_typing_has_every_type environment localContext emptyType))

end PsKernelJudgmentAdequacy

/-- info: 'PsKernelJudgmentAdequacy.legacy_defeq_is_universal' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms PsKernelJudgmentAdequacy.legacy_defeq_is_universal

/-- info: 'PsKernelJudgmentAdequacy.legacy_typing_has_every_type' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms PsKernelJudgmentAdequacy.legacy_typing_has_every_type

/--
info: 'PsKernelJudgmentAdequacy.legacy_typing_cannot_validate_an_empty_type' depends on axioms: [propext,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in
#print axioms PsKernelJudgmentAdequacy.legacy_typing_cannot_validate_an_empty_type
