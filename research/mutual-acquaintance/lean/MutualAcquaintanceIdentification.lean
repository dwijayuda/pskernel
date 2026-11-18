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

end MutualAcquaintanceIdentification
