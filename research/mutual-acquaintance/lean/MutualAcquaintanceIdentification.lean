import Lean

namespace MutualAcquaintanceIdentification

/-- A binary probability law represented exactly by counts divided by their positive sum. -/
structure BinaryLaw where
  no : Nat
  yes : Nat
  positive : 0 < no + yes

def BinaryLaw.total (law : BinaryLaw) : Nat := law.no + law.yes

def BinaryLaw.mass (law : BinaryLaw) (value : Bool) : Nat :=
  match value with
  | false => law.no
  | true => law.yes

/-- Both mechanisms use the same measurement channel. Each row has the same
    positive denominator. `yes r` is the numerator for a positive report. -/
structure Channel where
  scale : Nat
  positive : 0 < scale
  yes : Bool → Nat
  bounded : ∀ r, yes r ≤ scale

def Channel.mass (channel : Channel) (relation report : Bool) : Nat :=
  match report with
  | false => channel.scale - channel.yes relation
  | true => channel.yes relation

theorem Channel.row_total (channel : Channel) (relation : Bool) :
    channel.mass relation false + channel.mass relation true = channel.scale := by
  simpa [Channel.mass] using Nat.sub_add_cancel (channel.bounded relation)

/-- The joint and marginal observation numerators share denominator
    `law.total * channel.scale`. -/
def jointWeight (law : BinaryLaw) (channel : Channel)
    (relation report : Bool) : Nat :=
  law.mass relation * channel.mass relation report

def reportWeight (law : BinaryLaw) (channel : Channel) (report : Bool) : Nat :=
  jointWeight law channel false report + jointWeight law channel true report

theorem report_total (law : BinaryLaw) (channel : Channel) :
    reportWeight law channel false + reportWeight law channel true =
      law.total * channel.scale := by
  calc
    _ = law.no * (channel.mass false false + channel.mass false true) +
        law.yes * (channel.mass true false + channel.mass true true) := by
      simp only [reportWeight, jointWeight, BinaryLaw.mass, Nat.mul_add]
      omega
    _ = _ := by rw [channel.row_total, channel.row_total, BinaryLaw.total, Nat.add_mul]

/-- A finite Bayes correction. The posterior's denominator is the observed
    report's joint mass, so zero-probability reports require no posterior here. -/
def posterior (law : BinaryLaw) (channel : Channel) (report : Bool)
    (evidence : 0 < reportWeight law channel report) : BinaryLaw :=
  ⟨jointWeight law channel false report, jointWeight law channel true report, evidence⟩

theorem posterior_total (law : BinaryLaw) (channel : Channel) (report : Bool)
    (evidence : 0 < reportWeight law channel report) :
    (posterior law channel report evidence).total = reportWeight law channel report := rfl

/-- A policy offers a step. An individual approval cannot implement it alone.
    The passive policy does not offer it. Approvals in this model are fixed
    inputs for the compared context, rather than measurements of latent state. -/
structure Policy where
  offer : Bool
  approvalA : Bool
  approvalB : Bool

def Policy.proceed (policy : Policy) : Bool :=
  policy.offer && policy.approvalA && policy.approvalB

theorem Policy.proceed_requires_both (policy : Policy)
    (h : policy.proceed = true) :
    policy.approvalA = true ∧ policy.approvalB = true := by
  rcases policy with ⟨offer, a, b⟩
  cases offer <;> cases a <;> cases b <;> simp_all [Policy.proceed]

/-- Both mechanisms start at the same law. The stable mechanism leaves every
    latent state fixed. The change mechanism moves `movable` units of false
    mass to true if the step proceeds. For positive false mass this corresponds
    to a false-to-true transition with probability `movable / prior.no`;
    true stays true. -/
structure Scenario where
  prior : BinaryLaw
  movable : Nat
  bounded : movable ≤ prior.no

def Scenario.moved (scenario : Scenario) (policy : Policy) : Nat :=
  if policy.proceed = true then scenario.movable else 0

theorem Scenario.moved_bounded (scenario : Scenario) (policy : Policy) :
    scenario.moved policy ≤ scenario.prior.no := by
  unfold Scenario.moved
  split
  · exact scenario.bounded
  · exact Nat.zero_le _

def Scenario.changed (scenario : Scenario) (policy : Policy) : BinaryLaw where
  no := scenario.prior.no - scenario.moved policy
  yes := scenario.prior.yes + scenario.moved policy
  positive := by
    have bounded := scenario.moved_bounded policy
    have positive := scenario.prior.positive
    omega

theorem Scenario.same_total (scenario : Scenario) (policy : Policy) :
    (scenario.changed policy).total = scenario.prior.total := by
  have bounded := scenario.moved_bounded policy
  simp only [Scenario.changed, BinaryLaw.total]
  omega

/-- The two report numerators have the same positive denominator. Thus equality
    for both reports is equality of their observed probability laws. -/
def SameReportLaw (scenario : Scenario) (channel : Channel) (policy : Policy) : Prop :=
  ∀ report : Bool,
    reportWeight scenario.prior channel report =
      reportWeight (scenario.changed policy) channel report

private theorem reportWeight_decomposition (scenario : Scenario) (channel : Channel)
    (policy : Policy) (report : Bool) :
    reportWeight scenario.prior channel report +
        scenario.moved policy * channel.mass true report =
      reportWeight (scenario.changed policy) channel report +
        scenario.moved policy * channel.mass false report := by
  have h := Nat.sub_add_cancel (scenario.moved_bounded policy)
  simp only [reportWeight, jointWeight, BinaryLaw.mass, Scenario.changed]
  have expand :
      (scenario.prior.no - scenario.moved policy) * channel.mass false report +
          scenario.moved policy * channel.mass false report =
        scenario.prior.no * channel.mass false report := by
    simpa only [Nat.add_mul] using congrArg (fun n => n * channel.mass false report) h
  rw [Nat.add_mul]
  omega

/-- A policy distinguishes the models exactly when it moves positive mass
    and the shared measurement distinguishes the two latent states. -/
theorem same_report_law_iff (scenario : Scenario) (channel : Channel) (policy : Policy) :
    SameReportLaw scenario channel policy ↔
      scenario.moved policy = 0 ∨ channel.yes false = channel.yes true := by
  constructor
  · intro same
    by_cases zero : scenario.moved policy = 0
    · exact Or.inl zero
    · right
      have equal := same true
      have dec := reportWeight_decomposition scenario channel policy true
      have masses : scenario.moved policy * channel.mass false true =
          scenario.moved policy * channel.mass true true := by omega
      exact (Nat.mul_left_cancel_iff (by omega : 0 < scenario.moved policy)).mp masses
  · rintro (zero | same) report
    · have dec := reportWeight_decomposition scenario channel policy report
      simpa [zero] using dec
    · have rows : channel.mass false report = channel.mass true report := by
        cases report <;> simp [Channel.mass, same]
      have dec := reportWeight_decomposition scenario channel policy report
      rw [rows] at dec
      omega

theorem passive_agreement (scenario : Scenario) (channel : Channel) (policy : Policy)
    (closed : policy.proceed = false) : SameReportLaw scenario channel policy :=
  (same_report_law_iff scenario channel policy).mpr
    (Or.inl (by simp [Scenario.moved, closed]))

theorem accepted_step_separates (scenario : Scenario) (channel : Channel) (policy : Policy)
    (accepted : policy.proceed = true) (positive : 0 < scenario.movable)
    (informative : channel.yes false ≠ channel.yes true) :
    ¬ SameReportLaw scenario channel policy := by
  intro same
  rcases (same_report_law_iff scenario channel policy).mp same with zero | equal
  · simp [Scenario.moved, accepted] at zero
    omega
  · exact informative equal

def exampleScenario : Scenario := ⟨⟨3, 1, by decide⟩, 2, by decide⟩

def exampleChannel : Channel :=
  ⟨4, by decide, (fun r => if r then 3 else 1), by intro r; cases r <;> decide⟩

def passive : Policy := ⟨false, true, true⟩
def accepted : Policy := ⟨true, true, true⟩

/-- Passive positive-report probability is 6/16 for both models. After
    acceptance it is 6/16 for the stable model and 10/16 for the change model. -/
theorem example_observation :
    SameReportLaw exampleScenario exampleChannel passive ∧
    reportWeight exampleScenario.prior exampleChannel true = 6 ∧
    reportWeight (exampleScenario.changed accepted) exampleChannel true = 10 ∧
    exampleScenario.prior.total * exampleChannel.scale = 16 := by
  refine ⟨passive_agreement _ _ _ rfl, ?_⟩
  decide

/-- In the change model after acceptance, a positive report makes the
    posterior probability of the true latent state 9/10. -/
theorem example_posterior :
    let law := posterior (exampleScenario.changed accepted) exampleChannel true (by decide)
    law.yes = 9 ∧ law.total = 10 := by decide

#print axioms report_total
#print axioms posterior_total
#print axioms same_report_law_iff
#print axioms accepted_step_separates

/-! ## What measurement calibration and comparable participation buy -/

/-- With an oriented common channel, the increase in positive-report mass
    is the moved mass times the channel's discrimination. -/
theorem positive_report_increase (scenario : Scenario) (channel : Channel)
    (policy : Policy) (oriented : channel.yes false ≤ channel.yes true) :
    reportWeight (scenario.changed policy) channel true =
      reportWeight scenario.prior channel true +
        scenario.moved policy * (channel.yes true - channel.yes false) := by
  have balance := reportWeight_decomposition scenario channel policy true
  change reportWeight scenario.prior channel true +
      scenario.moved policy * channel.yes true =
    reportWeight (scenario.changed policy) channel true +
      scenario.moved policy * channel.yes false at balance
  have contrast :
      scenario.moved policy * (channel.yes true - channel.yes false) +
        scenario.moved policy * channel.yes false =
      scenario.moved policy * channel.yes true := by
    rw [← Nat.mul_add, Nat.sub_add_cancel oriented]
  omega

/-- For a common prior and a calibrated strictly oriented channel, equal
    observed positive-report numerators force equal moved mass. The prior
    and channel fix the common positive denominator. -/
theorem calibrated_movement_unique (first second : Scenario) (channel : Channel)
    (firstPolicy secondPolicy : Policy)
    (prior : first.prior = second.prior)
    (informative : channel.yes false < channel.yes true)
    (observed : reportWeight (first.changed firstPolicy) channel true =
      reportWeight (second.changed secondPolicy) channel true) :
    first.moved firstPolicy = second.moved secondPolicy := by
  have a := positive_report_increase first channel firstPolicy (Nat.le_of_lt informative)
  have b := positive_report_increase second channel secondPolicy (Nat.le_of_lt informative)
  rw [prior] at a
  have equal :
      first.moved firstPolicy * (channel.yes true - channel.yes false) =
      second.moved secondPolicy * (channel.yes true - channel.yes false) := by omega
  exact (Nat.mul_right_cancel_iff (by omega : 0 < channel.yes true - channel.yes false)).mp equal

/-- The denominator and positive numerator determine the full binary report law. -/
def reportSignature (law : BinaryLaw) (channel : Channel) : Nat × Nat :=
  (reportWeight law channel true, law.total * channel.scale)

def twoPolicyReports (passivePrior activePrior : BinaryLaw)
    (passiveChannel activeChannel : Channel) : (Nat × Nat) × (Nat × Nat) :=
  (reportSignature passivePrior passiveChannel, reportSignature activePrior activeChannel)

private def studyPrior : BinaryLaw := ⟨9, 3, by decide⟩

private def studyMovement : Scenario := ⟨studyPrior, 6, by decide⟩

private def alternativeMovement : Scenario := ⟨studyPrior, 8, by decide⟩

private def positiveChannel (low high : Nat) (hlo : low ≤ 32) (hhi : high ≤ 32) : Channel :=
  ⟨32, by decide, (fun r => if r then high else low), by
    intro r
    cases r
    · exact hlo
    · exact hhi⟩

private def calibratedChannel := positiveChannel 8 24 (by decide) (by decide)
private def unknownChannel := positiveChannel 9 21 (by decide) (by decide)
private def shiftedChannel := positiveChannel 16 32 (by decide) (by decide)
private def selectedPrior : BinaryLaw := ⟨3, 9, by decide⟩

/-- Different magnitudes of change fit the same report data when calibration
    is unknown, even with the same initial law and invariant measurement
    across policies within each model. -/
theorem uncalibrated_magnitudes_agree :
    twoPolicyReports studyPrior (studyMovement.changed accepted)
      calibratedChannel calibratedChannel =
    twoPolicyReports studyPrior (alternativeMovement.changed accepted)
      unknownChannel unknownChannel ∧
    studyMovement.moved accepted ≠ alternativeMovement.moved accepted := by decide

/-- A model with no latent transition matches both report laws if measurement
    may depend on policy. -/
theorem reporting_shift_agrees :
    twoPolicyReports studyPrior (studyMovement.changed accepted)
      calibratedChannel calibratedChannel =
    twoPolicyReports studyPrior studyPrior calibratedChannel shiftedChannel := by decide

/-- A model with no latent transition matches both report laws if the active
    group can have a different initial population. -/
theorem selection_shift_agrees :
    twoPolicyReports studyPrior (studyMovement.changed accepted)
      calibratedChannel calibratedChannel =
    twoPolicyReports studyPrior selectedPrior calibratedChannel calibratedChannel := by decide

theorem sensitivity_example_signature :
    twoPolicyReports studyPrior (studyMovement.changed accepted)
      calibratedChannel calibratedChannel = ((144, 384), (240, 384)) := by decide

#print axioms positive_report_increase
#print axioms calibrated_movement_unique
#print axioms uncalibrated_magnitudes_agree
#print axioms reporting_shift_agrees
#print axioms selection_shift_agrees

/-! ## Sharp bounds with unknown calibration -/

/-- Cross-multiplied lower bounds on moved mass. The two inequalities
    come from the lower bound on the false-state reported-positive rate
    and the upper bound on the true-state reported-positive rate. -/
theorem movement_lower_bounds (scenario : Scenario) (channel : Channel)
    (policy : Policy) (oriented : channel.yes false ≤ channel.yes true) :
    let delta := reportWeight (scenario.changed policy) channel true -
      reportWeight scenario.prior channel true
    scenario.prior.yes * delta ≤
        scenario.moved policy * reportWeight scenario.prior channel true ∧
    scenario.prior.no * delta ≤
        scenario.moved policy * reportWeight scenario.prior channel false := by
  let gap := channel.yes true - channel.yes false
  have increment := positive_report_increase scenario channel policy oriented
  have delta : reportWeight (scenario.changed policy) channel true -
      reportWeight scenario.prior channel true = scenario.moved policy * gap := by
    change reportWeight (scenario.changed policy) channel true =
      reportWeight scenario.prior channel true + scenario.moved policy * gap at increment
    omega
  have hi : scenario.prior.yes * gap ≤ reportWeight scenario.prior channel true := by
    change scenario.prior.yes * gap ≤
      scenario.prior.no * channel.yes false + scenario.prior.yes * channel.yes true
    have := Nat.mul_le_mul_left scenario.prior.yes (show gap ≤ channel.yes true by
      dsimp [gap]
      omega)
    omega
  have lo : scenario.prior.no * gap ≤ reportWeight scenario.prior channel false := by
    change scenario.prior.no * gap ≤
      scenario.prior.no * (channel.scale - channel.yes false) +
        scenario.prior.yes * (channel.scale - channel.yes true)
    have := Nat.mul_le_mul_left scenario.prior.no
      (show gap ≤ channel.scale - channel.yes false by
        have bound := channel.bounded true
        dsimp [gap]
        omega)
    omega
  dsimp only
  rw [delta]
  constructor
  · calc
      _ = scenario.moved policy * (scenario.prior.yes * gap) := by ac_rfl
      _ ≤ _ := Nat.mul_le_mul_left _ hi
  · calc
      _ = scenario.moved policy * (scenario.prior.no * gap) := by ac_rfl
      _ ≤ _ := Nat.mul_le_mul_left _ lo

/-- Construct an invariant channel for any positive candidate moved mass
    satisfying the two cross-multiplied lower bounds. The scenario's
    boundedness field supplies the upper bound. Passive and active observed
    probabilities are exactly baseline/denominator and
    (baseline + increase)/denominator, respectively. -/
theorem construct_sharp_channel (scenario : Scenario) (baseline increase denominator : Nat)
    (massPositive : 0 < scenario.movable) (denPositive : 0 < denominator)
    (increasePositive : 0 < increase) (baselineBound : baseline ≤ denominator)
    (positiveBound : scenario.prior.yes * increase ≤ scenario.movable * baseline)
    (negativeBound : scenario.prior.no * increase ≤
      scenario.movable * (denominator - baseline)) :
    ∃ channel : Channel,
      channel.yes false < channel.yes true ∧
      reportSignature scenario.prior channel =
        (scenario.prior.total * (scenario.movable * baseline),
         scenario.prior.total * (scenario.movable * denominator)) ∧
      reportSignature (scenario.changed accepted) channel =
        (scenario.prior.total * (scenario.movable * (baseline + increase)),
         scenario.prior.total * (scenario.movable * denominator)) := by
  let low := scenario.movable * baseline - scenario.prior.yes * increase
  let gap := scenario.prior.total * increase
  have lowSum : low + scenario.prior.yes * increase = scenario.movable * baseline :=
    Nat.sub_add_cancel positiveBound
  have gapSum : gap = scenario.prior.no * increase + scenario.prior.yes * increase := by
    simp only [gap, BinaryLaw.total, Nat.add_mul]
  have numeratorSum : scenario.movable * (denominator - baseline) +
      scenario.movable * baseline = scenario.movable * denominator := by
    rw [← Nat.mul_add, Nat.sub_add_cancel baselineBound]
  have highBound : low + gap ≤ scenario.movable * denominator := by omega
  let channel : Channel :=
    { scale := scenario.movable * denominator
      positive := Nat.mul_pos massPositive denPositive
      yes := fun r => match r with
        | false => low
        | true => low + gap
      bounded := by
        intro r
        cases r
        · change low ≤ scenario.movable * denominator
          omega
        · exact highBound }
  have strict : channel.yes false < channel.yes true := by
    have gapPositive : 0 < gap := Nat.mul_pos scenario.prior.positive increasePositive
    change low < low + gap
    omega
  have stable : reportWeight scenario.prior channel true =
      scenario.prior.total * (scenario.movable * baseline) := by
    change scenario.prior.no * low + scenario.prior.yes * (low + gap) =
      scenario.prior.total * (scenario.movable * baseline)
    calc
      _ = scenario.prior.total * (low + scenario.prior.yes * increase) := by
        simp only [gap, BinaryLaw.total, Nat.mul_add, Nat.add_mul]
        ac_rfl
      _ = _ := congrArg (fun n => scenario.prior.total * n) lowSum
  have active := positive_report_increase scenario channel accepted (Nat.le_of_lt strict)
  have gapEq : channel.yes true - channel.yes false = gap := by
    change low + gap - low = gap
    omega
  have moveEq : scenario.moved accepted = scenario.movable := rfl
  rw [stable, gapEq, moveEq] at active
  refine ⟨channel, strict, ?_, ?_⟩
  · unfold reportSignature
    rw [stable]
  · unfold reportSignature
    rw [scenario.same_total, active]
    congr 1
    simp only [gap, Nat.mul_add]
    ac_rfl

#print axioms movement_lower_bounds
#print axioms construct_sharp_channel

end MutualAcquaintanceIdentification
