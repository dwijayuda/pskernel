import Lean

/-!
# A Dynamic Epistemic Model of Mutual Acquaintance — Dynamics v0.2

A self-contained Lean 4 extension of `MutualAcquaintance.lean`, built around
Tractatus de Perceptione et Amore §§1.12, 2.7, 3.23, 4.53, 5.31,
6.63–6.64 and 6.91–6.92.

Formalization status: working research. See CI for the exact revision checked.
No `sorry`, `admit`, `axiom`, or Mathlib dependency is intended.

Interpretation:
* Every encounter has an action by A, an action by B, and an external input.
* Both participants may observe, learn, and change preferences separately.
* A relational state may change as a function of the pre-encounter state.
* The transition is simultaneous: all fields use the same PRE-state.
* Concrete Boolean examples prove logical possibility, not psychological fact.
* The abstract no-profile-predictor theorem is conditional on two histories
  that agree on the terminal individual profile but differ relationally.

The stochastic Markov kernel and normalized Bayesian posterior in the full
mathematical working draft remain OUTSIDE this module. Here beliefs are
Boolean placeholders for an explicitly finite deterministic transition model.
-/

namespace MutualAcquaintanceDynamics

/-! ## A. Typed state, two actions, observations and a transition model -/

structure State where
  traitA : Bool
  traitB : Bool
  beliefA : Bool
  beliefB : Bool
  preferenceA : Bool
  preferenceB : Bool
  relation : Bool
  deriving Repr, DecidableEq

structure JointAction where
  a : Bool
  b : Bool
  deriving Repr, DecidableEq

structure Event where
  action : JointAction
  shock : Bool
  deriving Repr, DecidableEq

/-- Each transition component may respond to a shared PRE-state and event.
    Each participant has an independent observation and learning function. -/
structure Model where
  observeA : State → Event → Bool
  observeB : State → Event → Bool
  learnA : Bool → Bool → Bool
  learnB : Bool → Bool → Bool
  traitStepA : State → Event → Bool
  traitStepB : State → Event → Bool
  preferenceStepA : State → Event → Bool
  preferenceStepB : State → Event → Bool
  relationStep : State → Event → Bool

/-- An encounter is a simultaneous update, not a sequential mutation
    of the seven fields. -/
def step (m : Model) (s : State) (e : Event) : State :=
  { traitA := m.traitStepA s e
    traitB := m.traitStepB s e
    beliefA := m.learnA s.beliefA (m.observeA s e)
    beliefB := m.learnB s.beliefB (m.observeB s e)
    preferenceA := m.preferenceStepA s e
    preferenceB := m.preferenceStepB s e
    relation := m.relationStep s e }

/-- A chronological list of encounters; the first element occurs first. -/
def run (m : Model) (s : State) : List Event → State
  | [] => s
  | e :: es => run m (step m s e) es

/-- State after the first `t` encounters of a given history. -/
def stateAt (m : Model) (s : State) (history : List Event)
    (t : Nat) : State :=
  run m s (history.take t)

/-- The empty history changes nothing. -/
theorem run_empty (m : Model) (s : State) : run m s [] = s := rfl

/-- The state at time zero is the initial state. -/
theorem stateAt_zero (m : Model) (s : State) (history : List Event) :
    stateAt m s history 0 = s := by
  rfl

/-- A run decomposes into a prefix and a continuation.
    This is the algebraic law needed for multi-stage reasoning. -/
theorem run_append (m : Model) (s : State) (first second : List Event) :
    run m s (first ++ second) =
      run m (run m s first) second := by
  induction first generalizing s with
  | nil => rfl
  | cons e rest ih =>
      change run m (step m s e) (rest ++ second) =
        run m (run m (step m s e) rest) second
      exact ih (step m s e)

/-- Every run is the state after all events in the given history. -/
theorem stateAt_length (m : Model) (s : State) (history : List Event) :
    stateAt m s history history.length = run m s history := by
  simp [stateAt]

/-! ## B. Independent observation channels and conditional invariants -/

/-- Identical current beliefs and identical observations imply identical
    next beliefs, GIVEN the learner's stipulated update function. -/
theorem same_signal_same_next_beliefA
    (m : Model) (s₁ s₂ : State) (e₁ e₂ : Event)
    (hb : s₁.beliefA = s₂.beliefA)
    (ho : m.observeA s₁ e₁ = m.observeA s₂ e₂) :
    (step m s₁ e₁).beliefA = (step m s₂ e₂).beliefA := by
  change m.learnA s₁.beliefA (m.observeA s₁ e₁) =
    m.learnA s₂.beliefA (m.observeA s₂ e₂)
  rw [hb, ho]

theorem same_signal_same_next_beliefB
    (m : Model) (s₁ s₂ : State) (e₁ e₂ : Event)
    (hb : s₁.beliefB = s₂.beliefB)
    (ho : m.observeB s₁ e₁ = m.observeB s₂ e₂) :
    (step m s₁ e₁).beliefB = (step m s₂ e₂).beliefB := by
  change m.learnB s₁.beliefB (m.observeB s₁ e₁) =
    m.learnB s₂.beliefB (m.observeB s₂ e₂)
  rw [hb, ho]

/-- Optional stability assumption: this theorem does NOT pretend
    individual dispositions must remain constant during acquaintance. -/
def StableTraits (m : Model) : Prop :=
  ∀ s e, m.traitStepA s e = s.traitA ∧
         m.traitStepB s e = s.traitB

theorem run_preserves_traitA
    (m : Model) (stable : StableTraits m)
    (s : State) (history : List Event) :
    (run m s history).traitA = s.traitA := by
  induction history generalizing s with
  | nil => rfl
  | cons e rest ih =>
      change (run m (step m s e) rest).traitA = s.traitA
      calc
        (run m (step m s e) rest).traitA = (step m s e).traitA :=
          ih (step m s e)
        _ = s.traitA := (stable s e).1

theorem run_preserves_traitB
    (m : Model) (stable : StableTraits m)
    (s : State) (history : List Event) :
    (run m s history).traitB = s.traitB := by
  induction history generalizing s with
  | nil => rfl
  | cons e rest ih =>
      change (run m (step m s e) rest).traitB = s.traitB
      calc
        (run m (step m s e) rest).traitB = (step m s e).traitB :=
          ih (step m s e)
        _ = s.traitB := (stable s e).2

/-! ## C. A general obstruction to individual-profile-only prediction -/

/-- The modeled individual profile deliberately excludes the relational
    component. Unlike a traits-only predictor, it includes BOTH beliefs
    and BOTH operative preferences as well. -/
abbrev Profile := Bool × Bool × Bool × Bool × Bool × Bool

def profile (s : State) : Profile :=
  (s.traitA, s.traitB, s.beliefA, s.beliefB,
   s.preferenceA, s.preferenceB)

/-- If two possible histories produce identical terminal individual
    profiles but distinct relational outcomes, no single-valued function
    of that profile predicts the relation for every admissible history.

    This is the main abstract theorem. It says nothing about the empirical
    frequency or desirability of any particular history. -/
theorem no_profile_only_predictor
    (m : Model) (initial : State) (h₁ h₂ : List Event)
    (heq : profile (run m initial h₁) = profile (run m initial h₂))
    (hne : (run m initial h₁).relation ≠
           (run m initial h₂).relation) :
    ¬ ∃ predict : Profile → Bool,
        ∀ h : List Event,
          predict (profile (run m initial h)) =
            (run m initial h).relation := by
  intro hp
  obtain ⟨predict, hpred⟩ := hp
  apply hne
  calc
    (run m initial h₁).relation =
        predict (profile (run m initial h₁)) := (hpred h₁).symm
    _ = predict (profile (run m initial h₂)) := congrArg predict heq
    _ = (run m initial h₂).relation := hpred h₂

/-- A Boolean target can be recovered exactly from an arbitrary summary
    precisely when it is constant on the histories sharing that summary.
    The values of the predictor off the reachable summaries are arbitrary. -/
theorem exact_bool_predictor_iff
    {History : Type u} {Summary : Type v} (summarize : History → Summary)
    (target : History → Bool) :
    (∃ predict : Summary → Bool, ∀ h, predict (summarize h) = target h) ↔
      ∀ h₁ h₂, summarize h₁ = summarize h₂ → target h₁ = target h₂ := by
  classical
  constructor
  · rintro ⟨predict, correct⟩ h₁ h₂ same
    exact (correct h₁).symm.trans ((congrArg predict same).trans (correct h₂))
  · intro constantOnFibers
    let predict := fun summary : Summary =>
      if ∃ h, summarize h = summary ∧ target h = true then true else false
    refine ⟨predict, ?_⟩
    intro h
    change (if ∃ k, summarize k = summarize h ∧ target k = true
      then true else false) = target h
    split
    · rename_i witness
      obtain ⟨k, same, yes⟩ := witness
      exact yes.symm.trans (constantOnFibers k h same)
    · rename_i noWitness
      cases eq : target h with
      | false => rfl
      | true => exact (noWitness ⟨h, rfl, eq⟩).elim

/-- Specialization to terminal individual profiles. -/
theorem profile_only_predictor_iff (m : Model) (initial : State) :
    (∃ predict : Profile → Bool, ∀ h : List Event,
      predict (profile (run m initial h)) = (run m initial h).relation) ↔
    ∀ h₁ h₂ : List Event,
      profile (run m initial h₁) = profile (run m initial h₂) →
      (run m initial h₁).relation = (run m initial h₂).relation :=
  exact_bool_predictor_iff (fun h => profile (run m initial h))
    (fun h => (run m initial h).relation)

#print axioms exact_bool_predictor_iff
#print axioms profile_only_predictor_iff

/-! ## D. Constructive model: different histories, same profiles -/

/-- In this illustrative model, an asymmetric signal can update A's belief.
    A subsequent jointly undertaken step sets the relational bit to A's
    PRE-step belief. An external shock toggles A's operative preference.
    These are invented transition rules, not empirical hypotheses. -/
def toyModel : Model where
  observeA := fun _ e => e.action.a && !e.action.b
  observeB := fun _ _ => false
  learnA := fun prior observation => if observation then true else prior
  learnB := fun prior _ => prior
  traitStepA := fun s _ => s.traitA
  traitStepB := fun s _ => s.traitB
  preferenceStepA := fun s e => if e.shock then !s.preferenceA else s.preferenceA
  preferenceStepB := fun s _ => s.preferenceB
  relationStep := fun s e =>
    if e.action.a then
      if e.action.b then s.beliefA else s.relation
    else s.relation

def initial : State :=
  { traitA := false
    traitB := false
    beliefA := false
    beliefB := false
    preferenceA := false
    preferenceB := false
    relation := false }

/-- A can receive a signal without a joint relational transition. -/
def listen : Event :=
  { action := { a := true, b := false }, shock := false }

/-- Both participants act; the toy relational transition uses the
    previously held belief, not the post-update belief. -/
def jointlyAct : Event :=
  { action := { a := true, b := true }, shock := false }

def noAction : Event :=
  { action := { a := false, b := false }, shock := false }

def shockEvent : Event :=
  { action := { a := false, b := false }, shock := true }

theorem toy_stable_traits : StableTraits toyModel := by
  intro s e
  exact ⟨rfl, rfl⟩

/-- A shared encounter need not produce identical observations. -/
theorem unequal_signals_in_one_encounter :
    toyModel.observeA initial listen ≠
      toyModel.observeB initial listen := by
  decide

/-- A learning-only encounter does not automatically change the relation. -/
theorem learning_without_relational_change :
    (step toyModel initial listen).beliefA ≠ initial.beliefA ∧
    (step toyModel initial listen).relation = initial.relation := by
  decide

/-- Conversely, a relation may change while both beliefs remain fixed. -/
def informed : State := { initial with beliefA := true }

theorem relational_change_without_learning :
    (step toyModel informed jointlyAct).relation ≠ informed.relation ∧
    (step toyModel informed jointlyAct).beliefA = informed.beliefA ∧
    (step toyModel informed jointlyAct).beliefB = informed.beliefB := by
  decide

/-- Operative preference can change even when the relation and beliefs do not. -/
theorem preference_change_without_learning_or_relational_change :
    (step toyModel initial shockEvent).preferenceA ≠ initial.preferenceA ∧
    (step toyModel initial shockEvent).beliefA = initial.beliefA ∧
    (step toyModel initial shockEvent).beliefB = initial.beliefB ∧
    (step toyModel initial shockEvent).relation = initial.relation := by
  decide

/-- Two chronological histories. -/
def listenThenAct : State := run toyModel initial [listen, jointlyAct]
def actThenListen : State := run toyModel initial [jointlyAct, listen]

/-- Despite equal FINAL dispositions, beliefs and preferences ... -/
theorem same_terminal_profile :
    profile listenThenAct = profile actThenListen := by
  decide

/-- ... the final relational states differ in this explicit model. -/
theorem different_terminal_relation :
    listenThenAct.relation ≠ actThenListen.relation := by
  decide

/-- A sequence is not interchangeable with its reversal in this model. -/
theorem encounter_order_matters :
    listenThenAct ≠ actThenListen := by
  decide

/-- Concrete corollary of the general theorem: NO exact function of
    both agents' final individual profiles predicts the relation across
    all histories of this toy model. -/
theorem toy_has_no_profile_only_predictor :
    ¬ ∃ predict : Profile → Bool,
      ∀ h : List Event,
        predict (profile (run toyModel initial h)) =
          (run toyModel initial h).relation := by
  exact no_profile_only_predictor toyModel initial
    [listen, jointlyAct] [jointlyAct, listen]
    (by decide) (by decide)

/-! ## E. Active information may have an assumed relational cost -/

/-- Variant toy model: a unilateral probe sends a fixed positive signal to A but,
    BY STIPULATION, resets the relational bit to false. -/
def probeModel : Model where
  observeA := fun _ e => e.action.a && !e.action.b
  observeB := fun _ _ => false
  learnA := fun prior observation => if observation then true else prior
  learnB := fun prior _ => prior
  traitStepA := fun s _ => s.traitA
  traitStepB := fun s _ => s.traitB
  preferenceStepA := fun s _ => s.preferenceA
  preferenceStepB := fun s _ => s.preferenceB
  relationStep := fun s e =>
    if e.action.a then
      if e.action.b then s.relation else false
    else s.relation

/-- A simple illustrative score: one point for the modeled belief-bit,
    two for the relational bit. These weights are arbitrary. -/
def illustrativeScore (s : State) : Nat :=
  (if s.beliefA then 1 else 0) +
  (if s.relation then 2 else 0)

def relationInitiallyPresent : State := { initial with relation := true }

/-- An intervention that updates a belief bit can score worse under a stipulated adverse
    relation transition. It does NOT refute the value-of-passive-information
    theorem from the original mathematical working draft. -/
theorem informative_probe_can_have_lower_total_value :
    (step probeModel relationInitiallyPresent listen).beliefA = true ∧
    illustrativeScore (step probeModel relationInitiallyPresent listen) <
      illustrativeScore (step probeModel relationInitiallyPresent noAction) := by
  decide

/-! ## F. Scope of the verified mathematical claim (once compiled)

The run and impossibility theorems hold for the explicitly defined class
of deterministic two-agent models. They do not assert that real people's
preferences are Boolean, that all encounters are beneficial or harmful,
that any particular counterfactual actually happened, or that a relationship
can be inferred from a short observation history.

Future work:
* normalized finite probability distributions and stochastic kernels;
* action-conditioned Bayesian filtering and identifiability;
* genuinely strategic two-sided policies and changing utilities;
* a theorem under transparent regularity conditions that makes a
  prediction differentiating the coupled model from a static competitor;
* empirical validation with longitudinal dyadic observations.
-/

end MutualAcquaintanceDynamics