import Lean

/-!
# A Dynamic Epistemic Model of Mutual Acquaintance

A Lean 4 *working formalization* of the interpretive research draft,
not a verification of a psychological theory.

Source: A Dynamic Epistemic Model of Mutual Acquaintance, working draft v0.1,
18 November 2026, interpreting Tractatus de Perceptione et Amore.

Dependency: Lean 4 core (`import Lean`), no Mathlib.

STATUS: This file has NOT been compiled in the creating environment.
All proofs are supplied without `sorry` or custom axioms, but only a successful
`lean MutualAcquaintance.lean` run can establish kernel verification.

Modeling convention:
  * `Nat` values in the decision sections represent NONNEGATIVE WEIGHTED
    utility contributions, not normalized probabilities.
  * Boolean models are counterexamples and small formal witnesses.
  * The general stochastic Bayesian model in the paper is NOT yet formalized.
  * A consequence of a definition is not advertised as an empirical discovery.
-/


namespace MutualAcquaintance

/-! ## 0. Typed state and a finite unnormalized observation interface -/

/-- Two participants, each with a separate information history. -/
inductive Person where
  | a
  | b
  deriving DecidableEq, Repr

/-- Toy state separating latent dispositions, beliefs, preferences, and dyadic state.
    Booleans deliberately do not stand for real personality measurements. -/
structure DyadState where
  traitA : Bool
  traitB : Bool
  beliefA : Bool
  beliefB : Bool
  preferenceA : Bool
  preferenceB : Bool
  relation : Bool
  deriving DecidableEq, Repr

/-- Nonnegative integer weights support finite examples, without claiming
    that they are already normalized probability distributions. -/
structure BinaryObservationKernel where
  transitionWeight : Bool → Bool → Nat
  observeAWeight : Bool → Bool → Nat
  observeBWeight : Bool → Bool → Nat

/-- Two-state prediction, prior to normalizing weights. -/
def predictWeight (k : BinaryObservationKernel)
    (prior : Bool → Nat) (nextState : Bool) : Nat :=
  prior false * k.transitionWeight false nextState +
  prior true * k.transitionWeight true nextState

/-- Unnormalized observation score for one agent. -/
def updateWeight (k : BinaryObservationKernel)
    (p : Person) (prior : Bool → Nat) (nextState observed : Bool) : Nat :=
  predictWeight k prior nextState *
    (match p with
     | .a => k.observeAWeight nextState observed
     | .b => k.observeBWeight nextState observed)

/-! ## 1. Representation and asymmetric learning (C1, Tractatus 1.12, 1.4) -/

/-- A public observation masks a hidden bit using a private bit. -/
def publicSignal (hidden key : Bool) : Bool := hidden != key

/-- The signal and private key together recover the hidden bit. -/
theorem recover_hidden_with_key (hidden key : Bool) :
    (publicSignal hidden key != key) = hidden := by
  cases hidden <;> cases key <;> decide

/-- Both hidden values can account for either public signal when the key
    is unavailable. This is an ambiguity witness, not an entropy theorem. -/
theorem same_public_signal_compatible_with_both (observed : Bool) :
    ∃ key0 key1 : Bool,
      publicSignal false key0 = observed ∧
      publicSignal true key1 = observed := by
  cases observed with
  | false => exact ⟨false, true, rfl, rfl⟩
  | true => exact ⟨true, false, rfl, rfl⟩

/-! ## 2. Non-identification and decision-relative sufficiency
    (T2 and T3, Tractatus 2.61, 2.7) -/

/-- Bayesian posterior numerators before normalization. -/
def posteriorNumerator (prior likelihood : Nat) : Nat :=
  prior * likelihood

/-- T2 core: identical full-history likelihoods preserve prior odds, here
    expressed as a cross-product equality to avoid division by zero.

    This alone does NOT prove equality of the laws of all histories; that is
    an explicit assumption in Theorem T2 of the working draft. -/
theorem identical_likelihood_preserves_cross_products
    (prior0 prior1 like0 like1 : Nat) (h : like0 = like1) :
    posteriorNumerator prior0 like0 * prior1 =
    posteriorNumerator prior1 like1 * prior0 := by
  rw [h]
  simp [posteriorNumerator, Nat.mul_comm, Nat.mul_left_comm]

/-- With two possible states and two available actions, the following
    values are sums of nonnegative, already weighted payoff contributions.

    a0, b0: contributions for actions A and B in state 0;
    a1, b1: contributions for actions A and B in state 1.
    There is no assumption that the states have equal probabilities. -/
def valueNoInformation (a0 b0 a1 b1 : Nat) : Nat :=
  max (a0 + a1) (b0 + b1)

def valuePerfectInformation (a0 b0 a1 b1 : Nat) : Nat :=
  max a0 b0 + max a1 b1

/-- T3, one direction: if one action is optimal in both supported states,
    perfect information cannot improve its aggregate decision value. -/
theorem perfect_information_unneeded_if_actionA_common_best
    (a0 b0 a1 b1 : Nat) (h0 : b0 ≤ a0) (h1 : b1 ≤ a1) :
    valuePerfectInformation a0 b0 a1 b1 =
    valueNoInformation a0 b0 a1 b1 := by
  unfold valuePerfectInformation valueNoInformation
  rw [Nat.max_eq_left h0, Nat.max_eq_left h1,
      Nat.max_eq_left (Nat.add_le_add h0 h1)]

/-- T3, full two-state/two-action criterion, including ties.
    Equality of decision value does not require identification of the state. -/
theorem zero_information_value_iff_common_best_action
    (a0 b0 a1 b1 : Nat) :
    valuePerfectInformation a0 b0 a1 b1 =
      valueNoInformation a0 b0 a1 b1 ↔
    ((b0 ≤ a0 ∧ b1 ≤ a1) ∨ (a0 ≤ b0 ∧ a1 ≤ b1)) := by
  unfold valuePerfectInformation valueNoInformation
  omega

/-- Explicit residual uncertainty with zero value of perfect information. -/
theorem uncertain_state_can_have_zero_information_value :
    valuePerfectInformation 2 1 2 1 =
    valueNoInformation 2 1 2 1 := by
  decide

/-! ## 3. Preference formation versus a change in reporting (C2) -/

/-- A context-dependent binary report. -/
def preferenceReport (operativePreference context : Bool) : Bool :=
  operativePreference != context

/-- The same pair of reports can arise from changing operative preference
    or from changing context while operative preference stays fixed. -/
theorem preference_formation_and_reporting_can_look_identical :
    (preferenceReport false false, preferenceReport true false) =
    (preferenceReport false false, preferenceReport false true) := by
  decide

/-! ## 4. Communication and ambiguous observation (C3) -/

/-- A single silent observation is compatible with either intention.
    This is a toy countermodel, not a claim that intentions cannot be known. -/
def silentObservation (_intention : Bool) : Bool := false

theorem one_silent_observation_does_not_identify_intention :
    silentObservation false = silentObservation true := rfl

/-! ## 5. Mutual choice and dependent willingness (D1, T4) -/

/-- Willingness is modeled symmetrically in this simple constitutive account. -/
def freelyJoint (willingA willingB : Bool) : Bool :=
  willingA && willingB

/-- D1: a freely joint step, by the definition above, requires both parties.
    This is explicitly a DEFINITONAL result, not a behavioral prediction. -/
theorem jointly_undertaken_requires_both (willingA willingB : Bool) :
    freelyJoint willingA willingB = true →
    willingA = true ∧ willingB = true := by
  cases willingA <;> cases willingB <;> decide

/-- Four nonnegative cell counts of a binary joint willingness table.
    The upper and lower Frechet bounds follow after division by the positive
    total count; this avoids a dependency on real-valued probability theory. -/
theorem dependent_willingness_cell_bounds
    (n00 n01 n10 n11 : Nat) :
    n11 ≤ n10 + n11 ∧
    n11 ≤ n01 + n11 ∧
    (n10 + n11) + (n01 + n11) ≤
      (n00 + n01 + n10 + n11) + n11 := by
  omega

/-- Knowing preferences can coexist with absence of joint willingness. -/
theorem individual_information_does_not_force_joint_choice :
    freelyJoint true false = false := by
  decide

/-! ## 6. Dynamic interaction, information value and counterfactuals
    (T5, C4, C5, C6; Tractatus 6.41-6.43 and 6.92) -/

/-- T5, finite two-signal/two-action value of passive information.
    The four inputs are nonnegative probability-weighted utility sums.
    The theorem is a decision result for a FIXED utility table, not a
    claim that every active encounter benefits the people involved. -/
theorem passive_information_never_reduces_optimal_value
    (a0 b0 a1 b1 : Nat) :
    valueNoInformation a0 b0 a1 b1 ≤
    valuePerfectInformation a0 b0 a1 b1 := by
  unfold valueNoInformation valuePerfectInformation
  exact Nat.max_le_of_le_of_le
    (Nat.add_le_add (Nat.le_max_left a0 b0) (Nat.le_max_left a1 b1))
    (Nat.add_le_add (Nat.le_max_right a0 b0) (Nat.le_max_right a1 b1))

/-- T5 equality condition is the same common-optimal-action condition
    proved as T3, specialized to binary states and actions. -/
theorem passive_information_equality_criterion
    (a0 b0 a1 b1 : Nat) :
    valueNoInformation a0 b0 a1 b1 =
      valuePerfectInformation a0 b0 a1 b1 ↔
    ((b0 ≤ a0 ∧ b1 ≤ a1) ∨ (a0 ≤ b0 ∧ a1 ≤ b1)) := by
  rw [eq_comm]
  exact zero_information_value_iff_common_best_action a0 b0 a1 b1

/-- Separate belief updating from a relation-constituting transition. -/
def learningOnly (s : DyadState) : DyadState :=
  { s with beliefA := !s.beliefA }

def relationOnly (s : DyadState) : DyadState :=
  { s with relation := !s.relation }

theorem learning_only_preserves_relation (s : DyadState) :
    (learningOnly s).relation = s.relation := rfl

theorem relation_only_preserves_beliefA (s : DyadState) :
    (relationOnly s).beliefA = s.beliefA := rfl

theorem relation_only_preserves_beliefB (s : DyadState) :
    (relationOnly s).beliefB = s.beliefB := rfl

/-- C4: a change in the relational state can occur with both modeled
    belief components unchanged, in a constructed state transition. -/
theorem relationship_can_change_without_belief_change :
    ∃ s : DyadState,
      (relationOnly s).relation ≠ s.relation ∧
      (relationOnly s).beliefA = s.beliefA ∧
      (relationOnly s).beliefB = s.beliefB := by
  refine ⟨{
    traitA := false, traitB := false,
    beliefA := false, beliefB := true,
    preferenceA := false, preferenceB := false,
    relation := false
  }, ?_, ?_, ?_⟩
  · decide
  · rfl
  · rfl

/-- Integer-scaled toy payoffs matching the working draft's C4 example:
    quiet = 5/4, active probe = 1, passive free signal = 7/4.
    The adverse relational transition is an ASSUMED part of the example. -/
def quietScore : Nat := 5

def activeProbeScore : Nat := 4

def passiveSignalScore : Nat := 7

theorem active_probe_can_underperform_quiet :
    activeProbeScore < quietScore := by decide

theorem passive_signal_can_outperform_quiet :
    quietScore < passiveSignalScore := by decide

/-- C5: with the same personal traits, relational state can depend
    on the interaction history. -/
def relationFromHistory (_traitA _traitB : Bool) (history : Bool) : Bool :=
  history

theorem no_universal_trait_only_relation
    (g : Bool → Bool → Bool) :
    ¬ (g false false = relationFromHistory false false false ∧
       g false false = relationFromHistory false false true) := by
  intro h
  have hf : g false false = false := by
    simpa [relationFromHistory] using h.1
  have ht : g false false = true := by
    simpa [relationFromHistory] using h.2
  have contra : false = true := hf.symm.trans ht
  cases contra

/-- C6: two causal models agree on the observed action, but disagree about
    the alternative action that was not taken. -/
def counterfactualModelM (action : Bool) : Bool := action

def counterfactualModelN (_action : Bool) : Bool := false

theorem actual_observation_agrees :
    counterfactualModelM false = counterfactualModelN false := rfl

theorem unchosen_action_disagrees :
    counterfactualModelM true ≠ counterfactualModelN true := by decide

/-! ## 7. Limits of this formal interpretation

No theorem here states that experience is ineffable or that another person
cannot be known. The model only entails what is stated under the chosen
formal definitions. A future version needs a normalized stochastic model,
Bayesian filtering proofs, dynamically changing utilities, and a causal
identification analysis. It would also need independent empirical validation
before making claims about actual relationships.
-/

end MutualAcquaintance