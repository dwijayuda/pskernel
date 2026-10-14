import Ps.KernelCore.Architecture.QualifiedRecursiveInference

/-!
Phase E: proof-carrying SOURCE admission provenance.

An arbitrary checker session may contain unchecked imported metadata. A
checked-work receipt therefore must not be conflated with a proof that the
environment was built through a closed sequence of valid declarations.

This module records a source-checking transition with an exact Lean equality
witness, and a provenance chain beginning ONLY at the canonical empty
environment. The chain does not claim the underlying source kernel is sound
or make the independent optimized checker complete.
-/

/-- One independently source-admitted declaration, bound to the exact
    original and result transactions and all original checking parameters.
    Neither a candidate WHNF nor a mere declared name can construct it. -/
structure PsKernelC0SourceAdmissionStep
    (before : PsKernelC0CertifiedWork) where
  fuel : Nat
  request : PsKernelC0ArchitectureDeclaration
  result : PsKernelC0CertifiedWork
  sourceAdmission :
    psKernelC0ArchitectureAdmit fuel before.raw request = .ok result.raw

/-- Run the *same* source admission used elsewhere in C0. Capture its exact
    successful result and recertify immutable store ownership; an error
    cannot publish a transition or a proof receipt. -/
def psKernelC0SourceAdmitWithProof
    (fuel : Nat)
    (before : PsKernelC0CertifiedWork)
    (request : PsKernelC0ArchitectureDeclaration) :
    Except String (PsKernelC0SourceAdmissionStep before) :=
  match h : psKernelC0ArchitectureAdmit fuel before.raw request with
  | .error reason => .error reason
  | .ok rawResult =>
      match psKernelC0ArchitectureCertifyWorkOwned rawResult with
      | none => .error "checked source admission lost canonical store ownership"
      | some ⟨result, ownership⟩ =>
          .ok {
            fuel := fuel
            request := request
            result := result
            sourceAdmission := by
              rw [ownership]
              exact h
          }

theorem psKernelC0SourceAdmissionExact
    {before : PsKernelC0CertifiedWork}
    (step : PsKernelC0SourceAdmissionStep before) :
    psKernelC0ArchitectureAdmit step.fuel before.raw step.request =
      .ok step.result.raw :=
  step.sourceAdmission

/-- An environment is provenance-qualified only by starting from the
    literal empty source environment and following exact successful source
    admissions. Checker-state changes that do not change the environment
    do not affect the meaning of this history. -/
inductive PsKernelC0SourceEnvironmentHistory :
    PsKernelEnvironment → Type where
  | genesis : PsKernelC0SourceEnvironmentHistory psKernelEnvironmentEmpty
  | admitted
      {before : PsKernelC0CertifiedWork}
      (previous :
        PsKernelC0SourceEnvironmentHistory
          before.raw.checker.context.environment)
      (step : PsKernelC0SourceAdmissionStep before) :
      PsKernelC0SourceEnvironmentHistory
        step.result.raw.checker.context.environment

structure PsKernelC0TrustedSourceWork where
  certified : PsKernelC0CertifiedWork
  history :
    PsKernelC0SourceEnvironmentHistory
      certified.raw.checker.context.environment

/-- Canonical genesis does not permit a caller to inject an arbitrary
    environment or a forged initial admission receipt. -/
def psKernelC0TrustedSourceBegin
    (maxRecDepth maxNatSize : Nat) :
    Option PsKernelC0TrustedSourceWork := do
  let checker := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe maxRecDepth maxNatSize
  let initial : PsKernelC0ArchitectureWork := {
    checker := checker
    scratch := psKernelC0ScratchBegin psKernelC0StoreEmpty
    stagedRoots := []
  }
  let ⟨certified, owner⟩ ←
    psKernelC0ArchitectureCertifyWorkOwned initial
  let history :
      PsKernelC0SourceEnvironmentHistory
        certified.raw.checker.context.environment := by
    rw [owner]
    exact .genesis
  some { certified := certified, history := history }

/-- Append exactly one source-checked declaration to a previously checked
    environment history; all stages are immutable and a failed admission
    returns no successor. This is source-checking provenance, not a theorem
    that the optimized candidate accepts independently. -/
def psKernelC0TrustedSourceAdmit
    (fuel : Nat)
    (work : PsKernelC0TrustedSourceWork)
    (request : PsKernelC0ArchitectureDeclaration) :
    Except String PsKernelC0TrustedSourceWork := do
  let step ← psKernelC0SourceAdmitWithProof
    fuel work.certified request
  return {
    certified := step.result
    history := .admitted work.history step
  }

/-- A single owner for environment-equality proof transport across
    source and source-equivalent fast WHNF state transitions. The exact
    checked admission history is carried, not reconstructed or re-audited. -/
private def psKernelC0TrustedSourceWithState
    (work : PsKernelC0TrustedSourceWork)
    (state : PsKernelCheckerState) : PsKernelC0TrustedSourceWork :=
  let ⟨certified, unchanged⟩ :=
    psKernelC0CertifiedWorkWithStateOwned work.certified state
  let history :
      PsKernelC0SourceEnvironmentHistory
        certified.raw.checker.context.environment := by
    rw [unchanged]
    exact work.history
  { certified := certified, history := history }

/-- Source checking may advance caches and other checker STATE, but must not
    replace its ENVIRONMENT. Proof transport shares the same owner as the
    independently refined canonical WHNF path. -/
private def psKernelC0TrustedSourceRun
    {α : Type}
    (work : PsKernelC0TrustedSourceWork)
    (source :
      PsKernelCheckerContext → PsKernelCheckerState →
        Except String (α × PsKernelCheckerState)) :
    Except String (α × PsKernelC0TrustedSourceWork) := do
  let (value, state) ← source
    work.certified.raw.checker.context work.certified.raw.checker.state
  return (value, psKernelC0TrustedSourceWithState work state)

/-- Source-equivalent checked WHNF. Five irreducible syntactic heads are
    handled independently without source WHNF execution when fuel is positive;
    contextual forms and zero fuel retain the original checker. The
    dependent-typed receipt proves that the complete successful result is
    exactly source WHNF in the original context/state. No term admission
    follows from WHNF, and trusted history is preserved unchanged. -/
def psKernelC0TrustedSourceWhnf
    (fuel : Nat)
    (work : PsKernelC0TrustedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0TrustedSourceWork) := do
  let receipt ← psKernelC0CertifiedWorkWhnfCanonicalFastOwned
    fuel work.certified expr
  let (value, checked) := receipt.val
  return (value,
    psKernelC0TrustedSourceWithState work checked.raw.checker.state)

/-- Source inference synthesizes types but does not certify arbitrary
    applications; full checking must still be used for accepting roots. -/
def psKernelC0TrustedSourceInfer
    (fuel : Nat)
    (work : PsKernelC0TrustedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0TrustedSourceWork) :=
  match psKernelC0CertifiedWorkInferProjectionOwned
      fuel work.certified expr with
  | .error reason => .error reason
  | .ok receipt =>
      let (ty, certified) := receipt.val
      .ok (ty, psKernelC0TrustedSourceWithState
        work certified.raw.checker.state)

/-- Only the original FULL source checker may approve a term. Neither
    metadata, candidate reduction nor provenance alone authorizes it. -/
def psKernelC0TrustedSourceCheck
    (fuel : Nat)
    (work : PsKernelC0TrustedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0TrustedSourceWork) :=
  match psKernelC0CertifiedWorkCheckRecursiveOwned
      fuel work.certified expr with
  | .error reason => .error reason
  | .ok receipt =>
      let (ty, certified) := receipt.val
      .ok (ty, psKernelC0TrustedSourceWithState
        work certified.raw.checker.state)

/-- The source-proved structurally reflexive DefEq fragment now runs
    independently on valid fuel/context, with exact original cache updates.
    Other comparisons retain full source semantics and error classification.
    This is a convertibility observation, never full term validation. -/
def psKernelC0TrustedSourceDefEq
    (fuel : Nat)
    (work : PsKernelC0TrustedSourceWork)
    (left right : PsKernelExpr) :
    Except String (Bool × PsKernelC0TrustedSourceWork) :=
  match psKernelC0CertifiedWorkDefEqQualifiedOwned
      fuel work.certified left right with
  | .error reason => .error reason
  | .ok receipt =>
      let (same, certified) := receipt.val
      .ok (same, psKernelC0TrustedSourceWithState
        work certified.raw.checker.state)

/-- Stage syntax without discarding proven source-admission provenance.
    The stage operation carries an exact proof that the checked environment
    did not change, while recertification validates the new immutable store. -/
def psKernelC0TrustedSourceStage
    (work : PsKernelC0TrustedSourceWork)
    (expr : PsKernelExpr) : Option PsKernelC0TrustedSourceWork := do
  let ⟨certified, unchanged⟩ ←
    psKernelC0CertifiedWorkStageWithEnvProof work.certified expr
  let history :
      PsKernelC0SourceEnvironmentHistory
        certified.raw.checker.context.environment := by
    rw [unchanged]
    exact work.history
  some { certified := certified, history := history }

/-- Publish exact owner-bound source-check results only after every staged
    root is closed, uses declared universe parameters, and passes full source
    checking. This operation leaves the trusted input untouched on failure.
    The optional temporary checker cache returned by checked publication is
    intentionally not transported into admission history: the immutable
    original work still carries its independently validated provenance. -/
def psKernelC0TrustedSourceCommitChecked
    (fuel : Nat)
    (work : PsKernelC0TrustedSourceWork) :
    Except String
      (PsKernelC0CertifiedStore × List PsKernelC0SourceCheckedRoot) := do
  let (owner, receipts, _) ← psKernelC0CertifiedWorkCommitChecked
    fuel work.certified
  return (owner, receipts)
