import Ps.KernelCore.Architecture.TrustedAdmission

/-!
CDE-10: explicit ordinary-axiom assumptions for source-checked histories.

Exact source-admission provenance does not imply consistency if an arbitrary
axiom was intentionally admitted. This optional *audited* profile records
the names of user-provided ordinary axiom declarations and requires each to
be authorized by a caller-supplied allowlist. The allowlist is a formal
proof-carrying property of the entire immutable source admission history,
not a mutable boolean flag.

It does not by itself audit built-in quotient primitives, imported external
kernel packages, or metatheoretic axioms; those require separate manifests
and independent proof obligations. A permitted axiom remains an explicit
assumption, not a theorem the checker derived.
-/

/-- The source history contains the exact original admission request for
    every step. Collect ordinary axiom declarations rather than inferring
    trust from names currently present in the environment. -/
def psKernelC0HistoryOrdinaryAxioms :
    {env : PsKernelEnvironment} →
      PsKernelC0SourceEnvironmentHistory env → List PsKernelName
  | _, .genesis => []
  | _, .admitted earlier step =>
      match step.request with
      | .axiomDecl info =>
          info.base.name :: psKernelC0HistoryOrdinaryAxioms earlier
      | _ =>
          psKernelC0HistoryOrdinaryAxioms earlier

def psKernelC0HistoryAxiomsApproved
    {env : PsKernelEnvironment}
    (history : PsKernelC0SourceEnvironmentHistory env)
    (allowed : List PsKernelName) : Bool :=
  (psKernelC0HistoryOrdinaryAxioms history).all
    (fun name => psKernelNameMember name allowed)

/-- The authorization is a Lean proof about the complete immutable
    source-admission history, not about any cache or untrusted snapshot. -/
structure PsKernelC0AuditedSourceWork where
  trusted : PsKernelC0TrustedSourceWork
  allowedAxioms : List PsKernelName
  approved :
    psKernelC0HistoryAxiomsApproved trusted.history allowedAxioms = true

def psKernelC0AuditTrustedSource
    (trusted : PsKernelC0TrustedSourceWork)
    (allowedAxioms : List PsKernelName) :
    Option PsKernelC0AuditedSourceWork :=
  if h : psKernelC0HistoryAxiomsApproved
      trusted.history allowedAxioms = true then
    some {
      trusted := trusted
      allowedAxioms := allowedAxioms
      approved := h
    }
  else none

/-- Only an actual canonical genesis can begin this audited profile. -/
def psKernelC0AuditedSourceBegin
    (maxRecDepth maxNatSize : Nat)
    (allowedAxioms : List PsKernelName) :
    Option PsKernelC0AuditedSourceWork := do
  let genesis ← psKernelC0TrustedSourceBegin maxRecDepth maxNatSize
  psKernelC0AuditTrustedSource genesis allowedAxioms

def psKernelC0OrdinaryAxiomRequestApproved
    (request : PsKernelC0ArchitectureDeclaration)
    (allowed : List PsKernelName) : Bool :=
  match request with
  | .axiomDecl info => psKernelNameMember info.base.name allowed
  | _ => true

/-- Verify the assumption policy BEFORE calling source admission, then
    independently recheck the policy over the ENTIRE new history. This
    cannot promote a candidate evaluation or bypass actual kernel checks. -/
def psKernelC0AuditedSourceAdmit
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (request : PsKernelC0ArchitectureDeclaration) :
    Except String PsKernelC0AuditedSourceWork := do
  if !psKernelC0OrdinaryAxiomRequestApproved
      request work.allowedAxioms then
    throw "ordinary axiom was not explicitly approved for this source history"
  let next ← psKernelC0TrustedSourceAdmit fuel work.trusted request
  let some checked ←
      psKernelC0AuditTrustedSource next work.allowedAxioms
    | throw "checked admission would exceed explicit axiom allowance"
  return checked

theorem psKernelC0AuditedSourceAxiomsApproved
    (work : PsKernelC0AuditedSourceWork) :
    psKernelC0HistoryAxiomsApproved
      work.trusted.history work.allowedAxioms = true :=
  work.approved
