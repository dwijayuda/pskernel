import Lean

/-
Formal proof scope: this file proves finite Boolean toy statements only.
General metric (MA-1), network locality (MA-3), translation symmetry (MA-4),
exact summary factorization (MA-5, already elsewhere), contraction (MA-6),
and conditional information (MA-9) are NOT proved by this file.
-/

/-!
Multi-agent acquaintance: finite formalization candidate for proposed Tractatus v1.2.0.
Separate from the philosophical source and earlier kernel-checked Lean modules.
Source taken from the proposed companion v0.4; status is determined by exact-head GitHub Actions, not by this comment.
All results are about Boolean toy models and do not establish psychological laws.
-/

namespace MultiAgentAcquaintance

structure State where
  traitA : Bool
  traitB : Bool
  perceptionAB : Bool
  perceptionBA : Bool
  idealA : Bool
  idealB : Bool
  relationAB : Bool
  deriving DecidableEq, Repr

def matchA (s : State) : Bool := s.perceptionAB == s.idealA

def meetingX (s : State) : State := {s with idealA := !s.idealA}

/-- The relational bit reacts to the BEFORE-event represented match. -/
def meetingAB (s : State) : State := {s with relationAB := matchA s}

def initial : State := {
  traitA := false
  traitB := false
  perceptionAB := true
  perceptionBA := true
  idealA := false
  idealB := false
  relationAB := false
}

def profile (s : State) : Bool × Bool × Bool × Bool × Bool × Bool :=
  (s.traitA, s.traitB, s.perceptionAB, s.perceptionBA, s.idealA, s.idealB)

def xThenAB := meetingAB (meetingX initial)
def abThenX := meetingX (meetingAB initial)

/-- Constructive witness: meeting X can reverse the toy evaluation of B
without updating any modeled characteristic or representation of B. -/
theorem third_party_reversal :
    matchA initial = false ∧ matchA (meetingX initial) = true := by
  decide

theorem absent_B_unchanged :
    (meetingX initial).traitB = initial.traitB ∧
    (meetingX initial).perceptionAB = initial.perceptionAB := by
  decide

/-- The same final individual profiles do not force equal relational bits. -/
theorem order_sensitive :
    profile xThenAB = profile abThenX ∧
    xThenAB.relationAB ≠ abThenX.relationAB := by
  decide

theorem no_predictor_for_two_histories :
    ¬ ∃ f : (Bool × Bool × Bool × Bool × Bool × Bool) → Bool,
        f (profile xThenAB) = xThenAB.relationAB ∧
        f (profile abThenX) = abThenX.relationAB := by
  rintro ⟨f, h₁, h₂⟩
  have eq : profile xThenAB = profile abThenX := by decide
  have ne : xThenAB.relationAB ≠ abThenX.relationAB := by decide
  apply ne
  calc
    xThenAB.relationAB = f (profile xThenAB) := h₁.symm
    _ = f (profile abThenX) := congrArg f eq
    _ = abThenX.relationAB := h₂

/-! Two observationally equivalent SCMs with different causal effects.
    U is unobserved, E is encounter exposure, Y is the observed outcome.
    Under observation E=U. The intervention fixes E independently of U.
-/
structure ExposureReport where
  exposure : Bool
  outcome : Bool
  deriving DecidableEq, Repr

def selectionObserved (u : Bool) : ExposureReport :=
  {exposure := u, outcome := u}

def influenceObserved (u : Bool) : ExposureReport :=
  {exposure := u, outcome := u}

def selectionDo (u _e : Bool) : Bool := u

def influenceDo (_u e : Bool) : Bool := e

theorem observational_equivalence (u : Bool) :
    selectionObserved u = influenceObserved u := by
  rfl

/-- Intervention has no effect under selection-only SCM. -/
theorem selection_has_no_effect (u : Bool) :
    selectionDo u true = selectionDo u false := by
  rfl

/-- Intervention has an effect under causal-influence SCM. -/
theorem influence_has_effect (u : Bool) :
    influenceDo u true ≠ influenceDo u false := by
  cases u <;> decide

/- Restricted four-agent matching witness (MA-7): the only candidate
    blocking pair is A and C; B and D rank their assigned partners highest. -/
def blocksAC (prefersA_C prefersC_A : Bool) : Bool :=
  prefersA_C && prefersC_A

theorem initial_matching_has_no_blocking_AC :
    blocksAC false false = false := by
  decide

theorem changing_both_preferences_creates_blocking_AC :
    blocksAC true true = true := by
  decide

/-- Report identity under all values of the latent bit in both SCMs.
This alone does not formalize the population probability distribution. -/
theorem all_binary_observations_equal :
    (∀ u : Bool, selectionObserved u = influenceObserved u) := by
  intro u
  rfl

end MultiAgentAcquaintance