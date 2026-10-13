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

/-- The entire finite history must satisfy *decidable structural*
    membership in the approved list. The result is a Lean proposition
    asserting every Boolean `decide (name ∈ allowed)` was true, not the
    portable `psKernelNameMember` comparator. -/
def psKernelC0HistoryAxiomsApproved
    {env : PsKernelEnvironment}
    (history : PsKernelC0SourceEnvironmentHistory env)
    (allowed : List PsKernelName) : Prop :=
  (psKernelC0HistoryOrdinaryAxioms history).all
    (fun name => decide (name ∈ allowed)) = true

instance {env : PsKernelEnvironment}
    (history : PsKernelC0SourceEnvironmentHistory env)
    (allowed : List PsKernelName) :
    Decidable (psKernelC0HistoryAxiomsApproved history allowed) := by
  unfold psKernelC0HistoryAxiomsApproved
  infer_instance

/-- Trust-bearing events other than ordinary axioms. The ordinary
    axiom ledger remains separately name-scoped; quotient bootstrap,
    unsafe and partial declarations require explicit additional approval.
    The exact source admission request, not environment-name inference,
    determines which capabilities a successful step contributes. -/
inductive PsKernelC0TrustCapability where
  | quotientBootstrap
  | unsafeAxiom (name : PsKernelName)
  | unsafeDefinition (name : PsKernelName)
  | partialDefinition (name : PsKernelName)
  | unsafeOpaque (name : PsKernelName)
  | unsafeInductive (name : PsKernelName)
deriving DecidableEq

def psKernelC0RequestTrustCapabilities :
    PsKernelC0ArchitectureDeclaration → List PsKernelC0TrustCapability
  | .axiomDecl info =>
      if info.isUnsafe then [.unsafeAxiom info.base.name] else []
  | .definition info =>
      match info.safety with
      | .safe => []
      | .unsafeDef => [.unsafeDefinition info.base.name]
      | .partialDef => [.partialDefinition info.base.name]
  | .opaqueDecl info =>
      if info.isUnsafe then [.unsafeOpaque info.base.name] else []
  | .ordinaryInductive info =>
      if info.isUnsafe then [.unsafeInductive info.name] else []
  | .mutualInductive info =>
      if info.isUnsafe then
        info.types.map (fun ty => .unsafeInductive ty.name)
      else []
  | .nestedInductive info =>
      if info.isUnsafe then
        info.types.map (fun ty => .unsafeInductive ty.name)
      else []
  | .quotient => [.quotientBootstrap]
  | .theoremDecl _ => []

/-- Read only exact successfully checked requests from the immutable
    proof-carrying history, accumulating each trust event once per source
    admission. No rejected or forged transaction extends this ledger. -/
def psKernelC0HistoryTrustCapabilities :
    {env : PsKernelEnvironment} →
      PsKernelC0SourceEnvironmentHistory env →
      List PsKernelC0TrustCapability
  | _, .genesis => []
  | _, .admitted earlier step =>
      psKernelC0RequestTrustCapabilities step.request ++
        psKernelC0HistoryTrustCapabilities earlier

/-- A mathematical proposition (decidable finite structural membership)
    over EVERY trust event ever successfully source-admitted. A permitted
    capability is transparently still an assumption, never a derivation. -/
def psKernelC0HistoryCapabilitiesApproved
    {env : PsKernelEnvironment}
    (history : PsKernelC0SourceEnvironmentHistory env)
    (allowed : List PsKernelC0TrustCapability) : Prop :=
  (psKernelC0HistoryTrustCapabilities history).all
    (fun capability => decide (capability ∈ allowed)) = true

instance {env : PsKernelEnvironment}
    (history : PsKernelC0SourceEnvironmentHistory env)
    (allowed : List PsKernelC0TrustCapability) :
    Decidable (psKernelC0HistoryCapabilitiesApproved history allowed) := by
  unfold psKernelC0HistoryCapabilitiesApproved
  infer_instance

def psKernelC0RequestCapabilitiesApproved
    (request : PsKernelC0ArchitectureDeclaration)
    (allowed : List PsKernelC0TrustCapability) : Bool :=
  (psKernelC0RequestTrustCapabilities request).all
    (fun capability => decide (capability ∈ allowed))

/-- The authorization is a Lean proof about the complete immutable
    source-admission history, not about any cache or untrusted snapshot. -/
structure PsKernelC0AuditedSourceWork where
  trusted : PsKernelC0TrustedSourceWork
  allowedAxioms : List PsKernelName
  allowedCapabilities : List PsKernelC0TrustCapability
  approved :
    psKernelC0HistoryAxiomsApproved trusted.history allowedAxioms
  capabilitiesApproved :
    psKernelC0HistoryCapabilitiesApproved trusted.history allowedCapabilities

/-- The complete audit is one exact source history plus two explicit
    independently checked permission lists. No allowed capability can be
    silently added by inference, normalization or staging. -/
def psKernelC0AuditTrustedSourceWithCapabilities
    (trusted : PsKernelC0TrustedSourceWork)
    (allowedAxioms : List PsKernelName)
    (allowedCapabilities : List PsKernelC0TrustCapability) :
    Option PsKernelC0AuditedSourceWork :=
  if h : psKernelC0HistoryAxiomsApproved
      trusted.history allowedAxioms then
    if hc : psKernelC0HistoryCapabilitiesApproved
        trusted.history allowedCapabilities then
      some {
        trusted := trusted
        allowedAxioms := allowedAxioms
        allowedCapabilities := allowedCapabilities
        approved := h
        capabilitiesApproved := hc
      }
    else none
  else none

/-- Legacy convenience profile remains default-deny for every
    nonordinary trust capability, including quotient bootstrap. -/
def psKernelC0AuditTrustedSource
    (trusted : PsKernelC0TrustedSourceWork)
    (allowedAxioms : List PsKernelName) :
    Option PsKernelC0AuditedSourceWork :=
  psKernelC0AuditTrustedSourceWithCapabilities trusted allowedAxioms []

/-- Only an actual canonical genesis can begin this audited profile. -/
def psKernelC0AuditedSourceBeginWithCapabilities
    (maxRecDepth maxNatSize : Nat)
    (allowedAxioms : List PsKernelName)
    (allowedCapabilities : List PsKernelC0TrustCapability) :
    Option PsKernelC0AuditedSourceWork := do
  let genesis ← psKernelC0TrustedSourceBegin maxRecDepth maxNatSize
  psKernelC0AuditTrustedSourceWithCapabilities genesis
    allowedAxioms allowedCapabilities

def psKernelC0AuditedSourceBegin
    (maxRecDepth maxNatSize : Nat)
    (allowedAxioms : List PsKernelName) :
    Option PsKernelC0AuditedSourceWork :=
  psKernelC0AuditedSourceBeginWithCapabilities
    maxRecDepth maxNatSize allowedAxioms []

def psKernelC0OrdinaryAxiomRequestApproved
    (request : PsKernelC0ArchitectureDeclaration)
    (allowed : List PsKernelName) : Bool :=
  match request with
  | .axiomDecl info => decide (info.base.name ∈ allowed)
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
  if !psKernelC0RequestCapabilitiesApproved
      request work.allowedCapabilities then
    throw "trust-bearing declaration capability requires explicit approval"
  let next ← psKernelC0TrustedSourceAdmit fuel work.trusted request
  let some checked := psKernelC0AuditTrustedSourceWithCapabilities
      next work.allowedAxioms work.allowedCapabilities
    | throw "checked admission would exceed explicit trust assumptions"
  return checked

theorem psKernelC0AuditedSourceAxiomsApproved
    (work : PsKernelC0AuditedSourceWork) :
    psKernelC0HistoryAxiomsApproved
      work.trusted.history work.allowedAxioms :=
  work.approved

theorem psKernelC0AuditedSourceCapabilitiesApproved
    (work : PsKernelC0AuditedSourceWork) :
    psKernelC0HistoryCapabilitiesApproved
      work.trusted.history work.allowedCapabilities :=
  work.capabilitiesApproved

/-- Source judgments do not add axioms, but a returned checked state must
    still satisfy the *entire* immutable axiom-history allowance. -/
private def psKernelC0AuditedSourceContinue
    {α : Type}
    (work : PsKernelC0AuditedSourceWork)
    (response :
      Except String (α × PsKernelC0TrustedSourceWork)) :
    Except String (α × PsKernelC0AuditedSourceWork) := do
  let (result, trusted) ← response
  let some next := psKernelC0AuditTrustedSourceWithCapabilities
      trusted work.allowedAxioms work.allowedCapabilities
    | throw "source query lost approved trust-provenance history"
  return (result, next)

/-- The same source checker remains authoritative for WHNF, inference,
    full term checking and DefEq. Every operation retains the exact
    approved source-environment assumption history. -/
def psKernelC0AuditedSourceWhnf
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0AuditedSourceWork) :=
  psKernelC0AuditedSourceContinue work
    (psKernelC0TrustedSourceWhnf fuel work.trusted expr)

def psKernelC0AuditedSourceInfer
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0AuditedSourceWork) :=
  psKernelC0AuditedSourceContinue work
    (psKernelC0TrustedSourceInfer fuel work.trusted expr)

def psKernelC0AuditedSourceCheck
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0AuditedSourceWork) :=
  psKernelC0AuditedSourceContinue work
    (psKernelC0TrustedSourceCheck fuel work.trusted expr)

def psKernelC0AuditedSourceDefEq
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (left right : PsKernelExpr) :
    Except String (Bool × PsKernelC0AuditedSourceWork) :=
  psKernelC0AuditedSourceContinue work
    (psKernelC0TrustedSourceDefEq fuel work.trusted left right)

/-- Staging changes only immutable syntax, not the admitted source
    environment. Both the StoreWF certificate and full axiom-history
    authorization are recertified before exposing the new work. -/
def psKernelC0AuditedSourceStage
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) : Option PsKernelC0AuditedSourceWork := do
  let staged ← psKernelC0TrustedSourceStage work.trusted expr
  psKernelC0AuditTrustedSourceWithCapabilities
    staged work.allowedAxioms work.allowedCapabilities

/-- Axiom auditing never substitutes for actual closed-source validation.
    The source root checker still must accept every staged root before
    an atomic immutable result is published. -/
def psKernelC0AuditedSourceCommitChecked
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork) :
    Except String
      (PsKernelC0CertifiedStore × List PsKernelC0SourceCheckedRoot) :=
  psKernelC0TrustedSourceCommitChecked fuel work.trusted
