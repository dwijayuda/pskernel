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
  | .mutualDefinitions _ =>
      .error (.declinedUnsupported
        "verified provider mutual definitions require exact atomic admission lineage")
  | .unsupported feature => .error (.declinedUnsupported feature)

/-- Source checking, signed foundation permission and complete-state lineage
    must ALL succeed. Failed admission never yields a successor. -/
def psKernelC0VerifiedProviderAdmit
    (session : PsKernelC0VerifiedProviderSession)
    (request : PsKernelDeclarationRequest) :
    Except PsKernelError PsKernelC0VerifiedProviderSession := do
  psKernelC0VerifiedProviderPreflight session
  let checkedRequest ← psKernelC0VerifiedProviderRequest request
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
