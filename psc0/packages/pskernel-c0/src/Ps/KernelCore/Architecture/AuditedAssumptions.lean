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

/- The exact declaration signature, including nested source expression
   binder metadata, is the unit of ordinary-axiom authorization. A name
   match alone does NOT approve a different proposition or universe. -/
deriving instance DecidableEq for PsKernelConstantBase
deriving instance DecidableEq for PsKernelAxiomInfo

/-- One source request contributes an actual, fully typed ordinary axiom
    signature, not just an identifier string. -/
def psKernelC0RequestAxiomSignatures :
    PsKernelC0ArchitectureDeclaration → List PsKernelAxiomInfo
  | .axiomDecl info => [info]
  | _ => []

/-- Exact checked signatures in the immutable source history. This is used
    only for initial/changed policy re-audits; admission increments proofs. -/
def psKernelC0HistoryAxiomSignatures :
    {env : PsKernelEnvironment} →
      PsKernelC0SourceEnvironmentHistory env → List PsKernelAxiomInfo
  | _, .genesis => []
  | _, .admitted earlier step =>
      psKernelC0RequestAxiomSignatures step.request ++
        psKernelC0HistoryAxiomSignatures earlier

/-- Human-facing ordinary axiom names are derived from the fully typed
    signatures but never used to authorize a declaration. -/
def psKernelC0HistoryOrdinaryAxioms
    {env : PsKernelEnvironment}
    (history : PsKernelC0SourceEnvironmentHistory env) :
    List PsKernelName :=
  (psKernelC0HistoryAxiomSignatures history).map
    (fun info => info.base.name)

/-- Each exact axiom declaration—name, permitted universe parameters,
    proposition syntax including binder metadata, and unsafe flag—must be
    present in the explicitly approved signature manifest. An identically
    named axiom with a different type is therefore NOT approved. -/
def psKernelC0HistoryAxiomsApproved
    {env : PsKernelEnvironment}
    (history : PsKernelC0SourceEnvironmentHistory env)
    (allowed : List PsKernelAxiomInfo) : Prop :=
  (psKernelC0HistoryAxiomSignatures history).all
    (fun info => decide (info ∈ allowed)) = true

instance {env : PsKernelEnvironment}
    (history : PsKernelC0SourceEnvironmentHistory env)
    (allowed : List PsKernelAxiomInfo) :
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
  | .mutualDefinitions values =>
      values.flatMap (fun info =>
        match info.safety with
        | .safe => []
        | .unsafeDef => [.unsafeDefinition info.base.name]
        | .partialDef => [.partialDefinition info.base.name])
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
  allowedAxioms : List PsKernelAxiomInfo
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
    (allowedAxioms : List PsKernelAxiomInfo)
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
    (allowedAxioms : List PsKernelAxiomInfo) :
    Option PsKernelC0AuditedSourceWork :=
  psKernelC0AuditTrustedSourceWithCapabilities trusted allowedAxioms []

/-- Only an actual canonical genesis can begin this audited profile. -/
def psKernelC0AuditedSourceBeginWithCapabilities
    (maxRecDepth maxNatSize : Nat)
    (allowedAxioms : List PsKernelAxiomInfo)
    (allowedCapabilities : List PsKernelC0TrustCapability) :
    Option PsKernelC0AuditedSourceWork := do
  let genesis ← psKernelC0TrustedSourceBegin maxRecDepth maxNatSize
  psKernelC0AuditTrustedSourceWithCapabilities genesis
    allowedAxioms allowedCapabilities

def psKernelC0AuditedSourceBegin
    (maxRecDepth maxNatSize : Nat)
    (allowedAxioms : List PsKernelAxiomInfo) :
    Option PsKernelC0AuditedSourceWork :=
  psKernelC0AuditedSourceBeginWithCapabilities
    maxRecDepth maxNatSize allowedAxioms []

def psKernelC0OrdinaryAxiomRequestApproved
    (request : PsKernelC0ArchitectureDeclaration)
    (allowed : List PsKernelAxiomInfo) : Bool :=
  (psKernelC0RequestAxiomSignatures request).all
    (fun info => decide (info ∈ allowed))

/-- Incremental all-of proof: a new event batch and the previously
    certified entire history suffice to certify their concatenation.
    Runtime audit work is proportional to this request, not history size. -/
private theorem psKernelC0AllAppendTrue
    {α : Type} (predicate : α → Bool)
    (current previous : List α)
    (currentOk : current.all predicate = true)
    (previousOk : previous.all predicate = true) :
    (current ++ previous).all predicate = true := by
  simpa [List.all_append, currentOk, previousOk]

/-- Preflight only the incoming trust events, then prove permission over
    the *complete* resulting history by extending the previous certificate.
    The source admission function remains the only accepting authority.
    No whole-history O(n) rescans occur on steady-state admissions; an
    explicit change of policy still validates the full history once. -/
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
  let step ← psKernelC0SourceAdmitWithProof
    fuel work.trusted.certified request
  -- An exact source-admission receipt owns the *actual* checked request.
  -- Check that event again before extending the proof; no weaker
  -- requested-name heuristic determines what may enter the history.
  if hA : psKernelC0OrdinaryAxiomRequestApproved
      step.request work.allowedAxioms = true then
    if hC : psKernelC0RequestCapabilitiesApproved
        step.request work.allowedCapabilities = true then
      let next : PsKernelC0TrustedSourceWork := {
        certified := step.result
        history := .admitted work.trusted.history step
      }
      let completeAxioms :
          psKernelC0HistoryAxiomsApproved
            next.history work.allowedAxioms := by
        unfold psKernelC0HistoryAxiomsApproved
        change (psKernelC0RequestAxiomSignatures step.request ++
            psKernelC0HistoryAxiomSignatures work.trusted.history).all
          (fun info => decide (info ∈ work.allowedAxioms)) = true
        exact psKernelC0AllAppendTrue _
          (psKernelC0RequestAxiomSignatures step.request)
          (psKernelC0HistoryAxiomSignatures work.trusted.history)
          hA work.approved
      let completeCapabilities :
          psKernelC0HistoryCapabilitiesApproved
            next.history work.allowedCapabilities := by
        unfold psKernelC0HistoryCapabilitiesApproved
        change (psKernelC0RequestTrustCapabilities step.request ++
            psKernelC0HistoryTrustCapabilities work.trusted.history).all
          (fun cap => decide (cap ∈ work.allowedCapabilities)) = true
        exact psKernelC0AllAppendTrue _
          (psKernelC0RequestTrustCapabilities step.request)
          (psKernelC0HistoryTrustCapabilities work.trusted.history)
          hC work.capabilitiesApproved
      return {
        trusted := next
        allowedAxioms := work.allowedAxioms
        allowedCapabilities := work.allowedCapabilities
        approved := completeAxioms
        capabilitiesApproved := completeCapabilities
      }
    else
      throw "source admission returned a disallowed trust capability"
  else
    throw "source admission returned an unapproved ordinary axiom"

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

/-- Every exact ordinary-axiom signature in the checked history
    is a member of the explicit, structurally matched approval manifest. -/
theorem psKernelC0AuditedAxiomSignatureAllowed
    (work : PsKernelC0AuditedSourceWork)
    (info : PsKernelAxiomInfo)
    (member :
      info ∈ psKernelC0HistoryAxiomSignatures work.trusted.history) :
    info ∈ work.allowedAxioms := by
  have h := List.all_eq_true.mp work.approved info member
  exact of_decide_eq_true h

/-- Every trust-bearing quotient/unsafe/partial event in the checked
    history is similarly present in the caller's explicit capabilities. -/
theorem psKernelC0AuditedCapabilityAllowed
    (work : PsKernelC0AuditedSourceWork)
    (event : PsKernelC0TrustCapability)
    (member :
      event ∈ psKernelC0HistoryTrustCapabilities work.trusted.history) :
    event ∈ work.allowedCapabilities := by
  have h := List.all_eq_true.mp work.capabilitiesApproved event member
  exact of_decide_eq_true h

/-- Empty ordinary-axiom permission means the entire source-checked
    history contains NO ordinary axiom declarations at all. This is a
    mathematical consequence of the pinned full-signature manifest. -/
theorem psKernelC0AuditedNoOrdinaryAxioms
    (work : PsKernelC0AuditedSourceWork)
    (hEmpty : work.allowedAxioms = []) :
    psKernelC0HistoryAxiomSignatures work.trusted.history = [] := by
  cases h : psKernelC0HistoryAxiomSignatures work.trusted.history with
  | nil => rfl
  | cons head tail =>
      have hMember :
          head ∈ psKernelC0HistoryAxiomSignatures work.trusted.history := by
        rw [h]
        simp
      have approved :=
        psKernelC0AuditedAxiomSignatureAllowed work head hMember
      simp [hEmpty] at approved

/-- With no additional capability permissions, no Quot/unsafe/partial
    trust event can have entered a successful source-admission history. -/
theorem psKernelC0AuditedNoTrustCapabilities
    (work : PsKernelC0AuditedSourceWork)
    (hEmpty : work.allowedCapabilities = []) :
    psKernelC0HistoryTrustCapabilities work.trusted.history = [] := by
  cases h : psKernelC0HistoryTrustCapabilities work.trusted.history with
  | nil => rfl
  | cons head tail =>
      have hMember :
          head ∈ psKernelC0HistoryTrustCapabilities work.trusted.history := by
        rw [h]
        simp
      have approved :=
        psKernelC0AuditedCapabilityAllowed work head hMember
      simp [hEmpty] at approved

/-- A checked state or staged syntax may change, but its exact
    source environment is fixed. Transport the *whole* approved history
    package across that environment equality, rather than rescanning every
    previously admitted declaration after each WHNF/DefEq/check operation.

    This uses only Lean equality transport; neither a hash nor a Boolean
    approximation authorizes the result. The old certified admission chain
    and both audit proofs remain preserved. -/
private def psKernelC0AuditedSourceRebind
    (work : PsKernelC0AuditedSourceWork)
    (certified : PsKernelC0CertifiedWork)
    (unchanged :
      certified.raw.checker.context.environment =
        work.trusted.certified.raw.checker.context.environment) :
    PsKernelC0AuditedSourceWork :=
  let prior :
      { h : PsKernelC0SourceEnvironmentHistory
          work.trusted.certified.raw.checker.context.environment //
        psKernelC0HistoryAxiomsApproved h work.allowedAxioms ∧
          psKernelC0HistoryCapabilitiesApproved h work.allowedCapabilities } :=
    ⟨work.trusted.history,
      ⟨work.approved, work.capabilitiesApproved⟩⟩
  let next :
      { h : PsKernelC0SourceEnvironmentHistory
          certified.raw.checker.context.environment //
        psKernelC0HistoryAxiomsApproved h work.allowedAxioms ∧
          psKernelC0HistoryCapabilitiesApproved h work.allowedCapabilities } :=
    cast
      (congrArg (fun env : PsKernelEnvironment =>
        { h : PsKernelC0SourceEnvironmentHistory env //
          psKernelC0HistoryAxiomsApproved h work.allowedAxioms ∧
            psKernelC0HistoryCapabilitiesApproved
              h work.allowedCapabilities }) unchanged.symm)
      prior
  {
    trusted := { certified := certified, history := next.val }
    allowedAxioms := work.allowedAxioms
    allowedCapabilities := work.allowedCapabilities
    approved := next.property.1
    capabilitiesApproved := next.property.2
  }

/-- The one state-only rebinding operation for audited checked judgments.
    Neither independently verified direct WHNF nor source-first candidate
    observation may change the environment, foundation ledger or permissions. -/
private def psKernelC0AuditedSourceWithState
    (work : PsKernelC0AuditedSourceWork)
    (state : PsKernelCheckerState) : PsKernelC0AuditedSourceWork :=
  let ⟨certified, unchanged⟩ :=
    psKernelC0CertifiedWorkWithStateOwned work.trusted.certified state
  psKernelC0AuditedSourceRebind work certified unchanged

/-- Checked source judgments update only their checked state. One exact
    environment-equality witness transports the previous admission history
    and both permissions, avoiding a full history scan. -/
private def psKernelC0AuditedSourceContinue
    {α : Type}
    (work : PsKernelC0AuditedSourceWork)
    (source :
      PsKernelCheckerContext → PsKernelCheckerState →
        Except String (α × PsKernelCheckerState)) :
    Except String (α × PsKernelC0AuditedSourceWork) := do
  let (result, state) ← source
    work.trusted.certified.raw.checker.context
    work.trusted.certified.raw.checker.state
  return (result, psKernelC0AuditedSourceWithState work state)

/-- Default audited WHNF now uses the independently proved direct-head
    fragment, falling back to the authoritative source on all contextual
    forms. It consumes no speculative candidate budget or unchecked cache.
    The exact source-equation witness is required by the operation's
    dependent-typed result, then erased after sound history transport. -/
def psKernelC0AuditedSourceWhnf
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0AuditedSourceWork) := do
  let receipt ← psKernelC0CertifiedWorkWhnfCanonicalFastOwned
    fuel work.trusted.certified expr
  let (value, checked) := receipt.val
  return (value,
    psKernelC0AuditedSourceWithState work checked.raw.checker.state)

/-- Optional source-first, exact-proved candidate WHNF observations. The
    ordinary audited WHNF above does NOT execute candidates, so inspection
    overhead and stricter candidate quota cannot alter accepting behavior. -/
def psKernelC0AuditedSourceWhnfQualified
    (fuel quota : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0AuditedSourceWork) := do
  let receipt ← psKernelC0CertifiedWorkWhnfQualified
    fuel quota work.trusted.certified expr
  let (value, checked) := receipt.val
  return (value,
    psKernelC0AuditedSourceWithState work checked.raw.checker.state)

def psKernelC0AuditedSourceInfer
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0AuditedSourceWork) :=
  match psKernelC0CertifiedWorkInferProjectionOwned
      fuel work.trusted.certified expr with
  | .error reason => .error reason
  | .ok receipt =>
      let (ty, certified) := receipt.val
      .ok (ty, psKernelC0AuditedSourceWithState
        work certified.raw.checker.state)

def psKernelC0AuditedSourceCheck
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0AuditedSourceWork) :=
  match psKernelC0CertifiedWorkCheckRecursiveOwned
      fuel work.trusted.certified expr with
  | .error reason => .error reason
  | .ok receipt =>
      let (ty, certified) := receipt.val
      .ok (ty, psKernelC0AuditedSourceWithState
        work certified.raw.checker.state)

/-- Source-equivalent independent reflexive DefEq plus exact checked
    state and assumption-proof transport. All non-reflexive and
    resource-declined cases remain source-authoritative. -/
def psKernelC0AuditedSourceDefEq
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork)
    (left right : PsKernelExpr) :
    Except String (Bool × PsKernelC0AuditedSourceWork) :=
  match psKernelC0CertifiedWorkDefEqQualifiedOwned
      fuel work.trusted.certified left right with
  | .error reason => .error reason
  | .ok receipt =>
      let (same, certified) := receipt.val
      .ok (same, psKernelC0AuditedSourceWithState
        work certified.raw.checker.state)

/-- Staging changes only syntax and the working store. The certified
    staging operation supplies the SAME environment-equality proof so the
    complete audit survives without a second full-history traversal. -/
def psKernelC0AuditedSourceStage
    (work : PsKernelC0AuditedSourceWork)
    (expr : PsKernelExpr) : Option PsKernelC0AuditedSourceWork := do
  let ⟨certified, unchanged⟩ ←
    psKernelC0CertifiedWorkStageWithEnvProof work.trusted.certified expr
  some (psKernelC0AuditedSourceRebind work certified unchanged)

/-- Axiom auditing never substitutes for actual closed-source validation.
    The source root checker still must accept every staged root before
    an atomic immutable result is published. -/
def psKernelC0AuditedSourceCommitChecked
    (fuel : Nat)
    (work : PsKernelC0AuditedSourceWork) :
    Except String
      (PsKernelC0CertifiedStore × List PsKernelC0SourceCheckedRoot) :=
  psKernelC0TrustedSourceCommitChecked fuel work.trusted
