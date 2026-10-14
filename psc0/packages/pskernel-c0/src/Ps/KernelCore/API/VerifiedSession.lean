import Ps.KernelCore.Architecture.SealedAuditedState

/-!
Phase E.4: provenance-qualified public API facade.

Every accepting operation is mediated by the sealed audited state lineage.
This interface does not expose a constructor that accepts arbitrary checker
caches, raw work, or a user-provided environment. Only genesis and exact
source-checked transitions are constructors of this facade's operational
workflow. It is an opt-in API; legacy raw C0 APIs remain available.

The source kernel is still the authority for theorem and declaration checking,
and the foundation policy must explicitly authorize trusted events.
-/

/-- The public verified session carries an exact complete checked-state
    lineage and the source-admission/foundation evidence beneath it. -/
structure PsKernelC0VerifiedSession where
  sealed : PsKernelC0SealedAuditedSourceWork

/-- Begin from the literal empty environment and a caller-selected
    explicit foundation manifest. This never imports a caller's cache. -/
def psKernelC0VerifiedBegin
    (maxRecDepth maxNatSize : Nat)
    (axioms : List PsKernelAxiomInfo := [])
    (capabilities : List PsKernelC0TrustCapability := []) :
    Option PsKernelC0VerifiedSession := do
  let sealed ← psKernelC0SealedAuditedBegin
    maxRecDepth maxNatSize axioms capabilities
  some ⟨sealed⟩

/-- The only declaration admission route checks the source kernel and
    every capability permission before producing a successor. -/
def psKernelC0VerifiedAdmit
    (fuel : Nat)
    (session : PsKernelC0VerifiedSession)
    (declaration : PsKernelC0ArchitectureDeclaration) :
    Except String PsKernelC0VerifiedSession := do
  let next ← psKernelC0SealedAuditedAdmit fuel session.sealed declaration
  return ⟨next⟩

def psKernelC0VerifiedWhnf
    (fuel : Nat)
    (session : PsKernelC0VerifiedSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0VerifiedSession) := do
  let (result, next) ← psKernelC0SealedAuditedWhnf
    fuel session.sealed expr
  return (result, ⟨next⟩)

/-- Type synthesis alone is NOT a proof-admission judgment. -/
def psKernelC0VerifiedInfer
    (fuel : Nat)
    (session : PsKernelC0VerifiedSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0VerifiedSession) := do
  let (result, next) ← psKernelC0SealedAuditedInfer
    fuel session.sealed expr
  return (result, ⟨next⟩)

/-- Full checking must succeed before a root is considered checked. -/
def psKernelC0VerifiedCheck
    (fuel : Nat)
    (session : PsKernelC0VerifiedSession)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0VerifiedSession) := do
  let (result, next) ← psKernelC0SealedAuditedCheck
    fuel session.sealed expr
  return (result, ⟨next⟩)

def psKernelC0VerifiedDefEq
    (fuel : Nat)
    (session : PsKernelC0VerifiedSession)
    (left right : PsKernelExpr) :
    Except String (Bool × PsKernelC0VerifiedSession) := do
  let (result, next) ← psKernelC0SealedAuditedDefEq
    fuel session.sealed left right
  return (result, ⟨next⟩)

def psKernelC0VerifiedStage
    (session : PsKernelC0VerifiedSession)
    (expr : PsKernelExpr) : Option PsKernelC0VerifiedSession := do
  let next ← psKernelC0SealedAuditedStage session.sealed expr
  some ⟨next⟩

/-- Reauthorize a history under a different exact foundation manifest.
    Policy widening never substitutes for source admission. -/
def psKernelC0VerifiedChangePolicy
    (session : PsKernelC0VerifiedSession)
    (axioms : List PsKernelAxiomInfo)
    (capabilities : List PsKernelC0TrustCapability) :
    Option PsKernelC0VerifiedSession := do
  let next ← psKernelC0SealedAuditedChangePolicy
    session.sealed axioms capabilities
  some ⟨next⟩

/-- All-or-nothing publication of source-checked, closed staged roots.
    The successful receipt proves this exact audited checker operation. -/
def psKernelC0VerifiedCommitChecked
    (fuel : Nat)
    (session : PsKernelC0VerifiedSession) :
    Except String
      (PsKernelC0SealedAuditedPublication fuel session.sealed) :=
  psKernelC0SealedAuditedCommitChecked fuel session.sealed

/-- Foundation authorization is carried through every successful
    operation in this verified-session API. -/
theorem psKernelC0VerifiedAxiomsApproved
    (session : PsKernelC0VerifiedSession) :
    psKernelC0HistoryAxiomsApproved
      session.sealed.audited.trusted.history
      session.sealed.audited.allowedAxioms :=
  psKernelC0SealedAuditedAxiomsApproved session.sealed

theorem psKernelC0VerifiedCapabilitiesApproved
    (session : PsKernelC0VerifiedSession) :
    psKernelC0HistoryCapabilitiesApproved
      session.sealed.audited.trusted.history
      session.sealed.audited.allowedCapabilities :=
  psKernelC0SealedAuditedCapabilitiesApproved session.sealed
