import Ps.KernelCore.API.VerifiedSession
import Ps.KernelCore.API.Session

/-!
Provider-compatible, opt-in verified acceptance facade.

The existing KernelContract-v1 API can accept raw environment records and
does not establish source-admission lineage. This separate entry point begins
at source-checked empty genesis, retains the certified checker-state lineage
and explicit trust manifest, and checks the provider/resource policy on each
operation. Unimplemented requests are declined rather than silently admitted.

A successful response is still a source-checked declaration, NOT an independent
kernel soundness or cross-backend compiler-correctness theorem.
-/

structure PsKernelC0VerifiedProviderSession where
  verified : PsKernelC0VerifiedSession
  resources : PsKernelResourcePolicy
  provider : PsKernelProviderCapability

/-- Reject incompatible providers and exhausted/cancelled resource policy
    before constructing any checked session. Never import a raw environment. -/
def psKernelC0VerifiedProviderBegin
    (resources : PsKernelResourcePolicy)
    (provider : PsKernelProviderCapability)
    (axioms : List PsKernelAxiomInfo := [])
    (capabilities : List PsKernelC0TrustCapability := []) :
    Except PsKernelError PsKernelC0VerifiedProviderSession := do
  if !psKernelProviderCompatible provider then
    throw (.declinedUnsupported "provider target does not match KernelContract-v1")
  if let some resource := psKernelResourcePreflight resources then
    throw (.resourceExhausted resource
      "resource policy declined operation before entry")
  let some checked := psKernelC0VerifiedBegin
      resources.maxRecDepth resources.maxNatSize axioms capabilities
    | throw (.internalError "verified checked genesis failed")
  return ⟨checked, resources, provider⟩

/-- The exact same preflight categories used by KernelContract-v1. -/
def psKernelC0VerifiedProviderPreflight
    (session : PsKernelC0VerifiedProviderSession) :
    Except PsKernelError Unit := do
  if !psKernelProviderCompatible session.provider then
    throw (.declinedUnsupported "provider target does not match KernelContract-v1")
  if let some resource := psKernelResourcePreflight session.resources then
    throw (.resourceExhausted resource
      "resource policy declined operation before entry")
  let checkedContext :=
    session.verified.sealed.audited.trusted.certified.raw.checker.context
  if checkedContext.maxRecDepth != session.resources.maxRecDepth ||
      checkedContext.maxNatSize != session.resources.maxNatSize then
    throw (.declinedUnsupported
      "verified resource limits do not match source checked-session genesis")

/-- Map only explicitly implemented kernel declaration families. No guessed
    mutual-definition transaction can bypass its dedicated checked semantics. -/
def psKernelC0VerifiedProviderRequest
    (request : PsKernelDeclarationRequest) :
    Except PsKernelError PsKernelC0ArchitectureDeclaration :=
  match request with
  | .axiomDecl info => .ok (.axiomDecl info)
  | .definitionDecl info => .ok (.definition info)
  | .theoremDecl info => .ok (.theoremDecl info)
  | .opaqueDecl info => .ok (.opaqueDecl info)
  | .quot => .ok .quotient
  | .ordinaryInductive info => .ok (.ordinaryInductive info)
  | .mutualInductive info => .ok (.mutualInductive info)
  | .nestedInductive info => .ok (.nestedInductive info)
  | .mutualDefinitions values => .ok (.mutualDefinitions values)
  | .unsupported feature => .error (.declinedUnsupported feature)

/-- Source checking, signed foundation permission and complete-state lineage
    must ALL succeed. Failed admission never yields a successor. -/
def psKernelC0VerifiedProviderAdmit
    (session : PsKernelC0VerifiedProviderSession)
    (request : PsKernelDeclarationRequest) :
    Except PsKernelError PsKernelC0VerifiedProviderSession := do
  psKernelC0VerifiedProviderPreflight session
  let checkedRequest ← psKernelC0VerifiedProviderRequest request
  -- Policy denials are deliberate unsupported/unauthorized requests, not
  -- internal checker faults. The audited admission separately rechecks both
  -- permissions and source validity before it extends any trusted history.
  let audited := session.verified.sealed.audited
  if !psKernelC0OrdinaryAxiomRequestApproved
      checkedRequest audited.allowedAxioms then
    throw (.declinedUnsupported
      "ordinary axiom was not explicitly approved for this source history")
  if !psKernelC0RequestCapabilitiesApproved
      checkedRequest audited.allowedCapabilities then
    throw (.declinedUnsupported
      "trust-bearing declaration capability requires explicit approval")
  let next ← match psKernelC0VerifiedAdmit session.resources.fuel
      session.verified checkedRequest with
    | .ok result => pure result
    | .error reason => throw (psKernelErrorFromMessage reason)
  let count := psKernelEnvironmentSize
    next.sealed.audited.trusted.certified.raw.checker.context.environment
  if !psKernelResourceAllowsSize session.resources count then
    throw (.resourceExhausted .declarationLimit "declaration limit exceeded")
  return { session with verified := next }

/-- Source full-term validation under the same typed resource policy and
    proof-carrying session history. Type synthesis alone is not accepted. -/
def psKernelC0VerifiedProviderCheck
    (session : PsKernelC0VerifiedProviderSession)
    (expr : PsKernelExpr) :
    Except PsKernelError (PsKernelExpr × PsKernelC0VerifiedProviderSession) := do
  psKernelC0VerifiedProviderPreflight session
  let (ty, next) ← match psKernelC0VerifiedCheck session.resources.fuel
      session.verified expr with
    | .ok result => pure result
    | .error reason => throw (psKernelErrorFromMessage reason)
  return (ty, { session with verified := next })

/-- Provider-level WHNF matches KernelContract-v1's checked-expression
    precondition. Normalization alone is not evidence of well-typedness:
    first run the full checked-expression operation, then source-equivalent
    WHNF under the SAME verified checker-state lineage. -/
def psKernelC0VerifiedProviderWhnf
    (session : PsKernelC0VerifiedProviderSession)
    (expr : PsKernelExpr) :
    Except PsKernelError (PsKernelExpr × PsKernelC0VerifiedProviderSession) := do
  let (_, checked) ← psKernelC0VerifiedProviderCheck session expr
  let (value, next) ← match psKernelC0VerifiedWhnf
      session.resources.fuel checked.verified expr with
    | .ok result => pure result
    | .error reason => throw (psKernelErrorFromMessage reason)
  return (value, { checked with verified := next })

/-- As with the v1 provider, DefEq is never used as a stand-alone
    certificate for malformed expressions. Both inputs must first pass
    full term checking under the same audited state-lineage session. -/
def psKernelC0VerifiedProviderDefEq
    (session : PsKernelC0VerifiedProviderSession)
    (left right : PsKernelExpr) :
    Except PsKernelError (Bool × PsKernelC0VerifiedProviderSession) := do
  let (_, first) ← psKernelC0VerifiedProviderCheck session left
  let (_, second) ← psKernelC0VerifiedProviderCheck first right
  let (same, next) ← match psKernelC0VerifiedDefEq
      session.resources.fuel second.verified left right with
    | .ok result => pure result
    | .error reason => throw (psKernelErrorFromMessage reason)
  return (same, { second with verified := next })


/-!
Phase E.4F: complete the provider-facing verified operation family.

Source-compatible full inference is an observation, not proof admission.
Syntax staging never confers checked status. Only the final atomically
source-checked publication has a dependent proof of the exact source
decision, tied to the actual staged session and full trust manifest.
-/\

/-- Provider-level source type synthesis. The returned type is NOT a
    validated proof or a declaration-admission certificate; callers must
    use full Check or checked publication to establish term validity. -/
def psKernelC0VerifiedProviderInfer
    (session : PsKernelC0VerifiedProviderSession)
    (expr : PsKernelExpr) :
    Except PsKernelError (PsKernelExpr × PsKernelC0VerifiedProviderSession) := do
  psKernelC0VerifiedProviderPreflight session
  let (inferred, next) ← match psKernelC0VerifiedInfer
      session.resources.fuel session.verified expr with
    | .ok value => pure value
    | .error message => throw (psKernelErrorFromMessage message)
  return (inferred, { session with verified := next })

/-- Explicit foundation policy changes are independently rechecked against
    the ENTIRE source-admitted history; they never insert an assumption or
    alter checker caches. Failed narrowing/widening has no successor. -/
def psKernelC0VerifiedProviderChangePolicy
    (session : PsKernelC0VerifiedProviderSession)
    (axioms : List PsKernelAxiomInfo)
    (capabilities : List PsKernelC0TrustCapability) :
    Except PsKernelError PsKernelC0VerifiedProviderSession := do
  psKernelC0VerifiedProviderPreflight session
  let some next :=
      psKernelC0VerifiedChangePolicy session.verified axioms capabilities
    | throw (.declinedUnsupported
        "foundation policy does not authorize the full checked source history")
  return { session with verified := next }

/-- Syntax-only staging, preserving actual genesis/state-lineage evidence.
    It deliberately permits an ill-typed input at this point: checked root
    publication will reject the entire batch if ANY staged root is invalid.
    No root is emitted by this operation. -/
def psKernelC0VerifiedProviderStage
    (session : PsKernelC0VerifiedProviderSession)
    (expr : PsKernelExpr) :
    Except PsKernelError PsKernelC0VerifiedProviderSession := do
  psKernelC0VerifiedProviderPreflight session
  let some next := psKernelC0VerifiedStage session.verified expr
    | throw (.internalError "certified syntax staging failed")
  return { session with verified := next }

/-- Stage one complete root selection in the immutable checked work.
    A staging failure abandons the local successor; the original session
    remains unchanged. Partial staging never constitutes publication. -/
def psKernelC0VerifiedProviderStageRoots
    (session : PsKernelC0VerifiedProviderSession)
    (roots : List PsKernelExpr) :
    Except PsKernelError PsKernelC0VerifiedProviderSession := do
  let mut current := session
  for root in roots do
    current ← psKernelC0VerifiedProviderStage current root
  return current

/-- The kernel's existing all-or-nothing closed-root checking must accept
    every staged root. The resulting dependent-typed receipt refers to the
    EXACT source-checked operation on this session and fuel. -/
def psKernelC0VerifiedProviderCommitChecked
    (session : PsKernelC0VerifiedProviderSession) :
    Except PsKernelError
      (PsKernelC0SealedAuditedPublication
        session.resources.fuel session.verified.sealed) := do
  psKernelC0VerifiedProviderPreflight session
  match psKernelC0VerifiedCommitChecked
      session.resources.fuel session.verified with
  | .ok publication => return publication
  | .error message => throw (psKernelErrorFromMessage message)

/-- One provider-publication receipt records BOTH exact selected-root
    staging and exact source checking. A canonical syntax store, assumption
    permission or WHNF observation alone cannot construct this result. -/
structure PsKernelC0VerifiedProviderPublication
    (before : PsKernelC0VerifiedProviderSession)
    (roots : List PsKernelExpr) where
  staged : PsKernelC0VerifiedProviderSession
  exactStaging :
    psKernelC0VerifiedProviderStageRoots before roots = .ok staged
  checked : PsKernelC0SealedAuditedPublication
    staged.resources.fuel staged.verified.sealed

/-- Atomic provider publishing: no output at all if staging fails, any
    selected root is open or ill typed, or resources/policy do not qualify.
    The caller's immutable original work is never replaced on failure. -/
def psKernelC0VerifiedProviderPublishRoots
    (session : PsKernelC0VerifiedProviderSession)
    (roots : List PsKernelExpr) :
    Except PsKernelError (PsKernelC0VerifiedProviderPublication session roots) :=
  match h : psKernelC0VerifiedProviderStageRoots session roots with
  | .error reason => .error reason
  | .ok staged =>
      match psKernelC0VerifiedProviderCommitChecked staged with
      | .error reason => .error reason
      | .ok checked =>
          .ok ⟨staged, h, checked⟩

/-- Exact staged-root source provenance is part of the successful result. -/
theorem psKernelC0VerifiedProviderPublicationStagingExact
    {session : PsKernelC0VerifiedProviderSession}
    {roots : List PsKernelExpr}
    (result : PsKernelC0VerifiedProviderPublication session roots) :
    psKernelC0VerifiedProviderStageRoots session roots = .ok result.staged :=
  result.exactStaging

/-- Exact source-checked publication is also part of the result, with
    source closure, typing and universe validation enforced on EVERY root. -/
theorem psKernelC0VerifiedProviderPublicationCheckExact
    {session : PsKernelC0VerifiedProviderSession}
    {roots : List PsKernelExpr}
    (result : PsKernelC0VerifiedProviderPublication session roots) :
    psKernelC0AuditedSourceCommitChecked
      result.staged.resources.fuel result.staged.verified.sealed.audited =
        .ok (result.checked.store, result.checked.roots) :=
  psKernelC0SealedAuditedPublicationExact result.checked
