import Lean

/-!
# Permission-relative binary testing

Two latent models R (revelation) and C (constitution) generate a binary
report. Their common positive denominator makes exact finite comparisons
possible. These conditional results do not establish psychological laws.

Error mass is the sum of the two model-specific mistakes. Divide by
twice the common denominator to obtain risk with equal model priors.
This is a standard special case of optimal binary hypothesis testing.
-/

namespace MutualAcquaintanceDecision

structure BinaryExperiment where
  total : Nat
  positive : 0 < total
  revelationYes : Nat
  constitutionYes : Nat
  revelationBound : revelationYes ≤ total
  constitutionBound : constitutionYes ≤ total

/-- True predicts model C; false predicts model R. -/
def BinaryExperiment.errorMass (e : BinaryExperiment)
    (predictNo predictYes : Bool) : Nat :=
  (if predictNo then e.total - e.revelationYes
    else e.total - e.constitutionYes) +
  (if predictYes then e.revelationYes else e.constitutionYes)

def BinaryExperiment.discrimination (e : BinaryExperiment) : Nat :=
  (e.revelationYes - e.constitutionYes) +
    (e.constitutionYes - e.revelationYes)

/-- For every classifier, error + separation >= the denominator. -/
theorem every_rule_bound (e : BinaryExperiment) (predictNo predictYes : Bool) :
    e.total ≤ e.errorMass predictNo predictYes + e.discrimination := by
  have hR := e.revelationBound
  have hC := e.constitutionBound
  cases predictNo <;> cases predictYes <;>
    simp [BinaryExperiment.errorMass, BinaryExperiment.discrimination] <;>
      omega

/-- The bound is sharp, with a possibly nonunique optimal rule. -/
theorem optimal_rule_exists (e : BinaryExperiment) :
    ∃ predictNo predictYes : Bool,
      e.errorMass predictNo predictYes + e.discrimination = e.total := by
  have hR := e.revelationBound
  have hC := e.constitutionBound
  by_cases h : e.revelationYes ≤ e.constitutionYes
  · refine ⟨false, true, ?_⟩
    simp [BinaryExperiment.errorMass, BinaryExperiment.discrimination]
    omega
  · refine ⟨true, false, ?_⟩
    simp [BinaryExperiment.errorMass, BinaryExperiment.discrimination]
    omega

/-- Equality of the full binary laws is exactly zero separation. -/
theorem same_law_iff_zero_gap (e : BinaryExperiment) :
    e.discrimination = 0 ↔
      e.revelationYes = e.constitutionYes := by
  constructor
  · intro h
    dsimp [BinaryExperiment.discrimination] at h
    omega
  · intro h
    simp [BinaryExperiment.discrimination, h]

theorem every_rule_chance_when_same (e : BinaryExperiment)
    (same : e.revelationYes = e.constitutionYes)
    (predictNo predictYes : Bool) :
    e.errorMass predictNo predictYes = e.total := by
  have hR := e.revelationBound
  have hC := e.constitutionBound
  cases predictNo <;> cases predictYes <;>
    simp [BinaryExperiment.errorMass, same] <;>
      omega

/-- Approval is an exogenous, fixed input under both models. The
refusal itself conveys no modeled information about latent identity. -/
structure Offer where
  offered : Bool
  approvalA : Bool
  approvalB : Bool

def Offer.proceed (p : Offer) : Bool :=
  p.offered && p.approvalA && p.approvalB

def passiveExperiment : BinaryExperiment :=
  ⟨16, by decide, 6, 6, by decide, by decide⟩

/-- R produces 6/16 positive reports, C produces 10/16. These are
stipulated counts for a toy comparison, not empirical estimates. -/
def activeExperiment : BinaryExperiment :=
  ⟨16, by decide, 6, 10, by decide, by decide⟩

def experimentOffered (p : Offer) : BinaryExperiment :=
  if p.proceed then activeExperiment else passiveExperiment

theorem missing_approval_blocks_test (p : Offer)
    (refused : p.approvalA = false ∨ p.approvalB = false) :
    (experimentOffered p).discrimination = 0 := by
  have no : p.proceed = false := by
    rcases refused with a | b
    · simp [Offer.proceed, a]
    · simp [Offer.proceed, b]
  simp [experimentOffered, no, passiveExperiment,
    BinaryExperiment.discrimination]

/-- After an accepted encounter, optimal error is 12/32 = 3/8,
versus 16/32 = 1/2 for the passive policy. -/
theorem accepted_example :
    passiveExperiment.discrimination = 0 ∧
      activeExperiment.discrimination = 4 ∧
      activeExperiment.errorMass false true = 12 ∧
      passiveExperiment.errorMass false true = 16 := by decide

theorem joint_approval_enables_example (p : Offer)
    (offered : p.offered = true)
    (a : p.approvalA = true)
    (b : p.approvalB = true) :
    (experimentOffered p).discrimination = 4 := by
  have yes : p.proceed = true := by
    simp [Offer.proceed, offered, a, b]
  simp [experimentOffered, yes, activeExperiment,
    BinaryExperiment.discrimination]

#print axioms every_rule_bound
#print axioms optimal_rule_exists
#print axioms same_law_iff_zero_gap
#print axioms missing_approval_blocks_test
#print axioms joint_approval_enables_example

end MutualAcquaintanceDecision
