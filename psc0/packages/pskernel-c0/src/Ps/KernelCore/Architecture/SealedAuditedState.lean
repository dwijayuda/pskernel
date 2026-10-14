import Ps.KernelCore.Architecture.SealedState
import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
Phase E.3: exact checked-state lineage AND audited foundation policies.

The existing audited work records exact signed axiom and capability approval,
but permits an externally assembled checker cache to be packaged. This
opt-in API requires a *separate indexed checked-state history* from the
literal audited genesis, following only the precise audited checked
operations. A new history node carries the exact successful result equation.

We do not reinterpret a successful cache lookup as a proof, and changing
the audit policy never replaces the underlying immutable checked session.
The prior legacy constructors remain public until their migration completes.
-/

/-- An audited session is reachable only from a real checked source genesis
    through the listed exact checked/query/admission/staging operations.
    A standalone raw PsKernelCheckerState or approved axiom list cannot
    construct such a history without a proof of these equations. -/
inductive PsKernelC0AuditedStateLineage :
    PsKernelC0AuditedSourceWork → Type where
  | genesis
      (maxRecDepth maxNatSize : Nat)
      (axioms : List PsKernelAxiomInfo)
      (capabilities : List PsKernelC0TrustCapability)
      (work : PsKernelC0AuditedSourceWork)
      (exact : psKernelC0AuditedSourceBeginWithCapabilities
        maxRecDepth maxNatSize axioms capabilities = some work) :
      PsKernelC0AuditedStateLineage work
  | admitted
      {before after : PsKernelC0AuditedSourceWork}
      (previous : PsKernelC0AuditedStateLineage before)
      (fuel : Nat)
      (request : PsKernelC0ArchitectureDeclaration)
      (exact : psKernelC0AuditedSourceAdmit fuel before request = .ok after) :
      PsKernelC0AuditedStateLineage after
  | whnf
      {before after : PsKernelC0AuditedSourceWork}
      (previous : PsKernelC0AuditedStateLineage before)
      (fuel : Nat)
      (expr value : PsKernelExpr)
      (exact : psKernelC0AuditedSourceWhnf fuel before expr =
        .ok (value, after)) :
      PsKernelC0AuditedStateLineage after
  | inferred
      {before after : PsKernelC0AuditedSourceWork}
      (previous : PsKernelC0AuditedStateLineage before)
      (fuel : Nat)
      (expr value : PsKernelExpr)
      (exact : psKernelC0AuditedSourceInfer fuel before expr =
        .ok (value, after)) :
      PsKernelC0AuditedStateLineage after
  | checked
      {before after : PsKernelC0AuditedSourceWork}
      (previous : PsKernelC0AuditedStateLineage before)
      (fuel : Nat)
      (expr value : PsKernelExpr)
      (exact : psKernelC0AuditedSourceCheck fuel before expr =
        .ok (value, after)) :
      PsKernelC0AuditedStateLineage after
  | defeq
      {before after : PsKernelC0AuditedSourceWork}
      (previous : PsKernelC0AuditedStateLineage before)
      (fuel : Nat)
      (left right : PsKernelExpr)
      (same : Bool)
      (exact : psKernelC0AuditedSourceDefEq fuel before left right =
        .ok (same, after)) :
      PsKernelC0AuditedStateLineage after
  | staged
      {before after : PsKernelC0AuditedSourceWork}
      (previous : PsKernelC0AuditedStateLineage before)
      (expr : PsKernelExpr)
      (exact : psKernelC0AuditedSourceStage before expr = some after) :
      PsKernelC0AuditedStateLineage after
  | policy
      {before after : PsKernelC0AuditedSourceWork}
      (previous : PsKernelC0AuditedStateLineage before)
      (axioms : List PsKernelAxiomInfo)
      (capabilities : List PsKernelC0TrustCapability)
      (exact : psKernelC0AuditTrustedSourceWithCapabilities
        before.trusted axioms capabilities = some after) :
      PsKernelC0AuditedStateLineage after

structure PsKernelC0SealedAuditedSourceWork where
  audited : PsKernelC0AuditedSourceWork
  lineage : PsKernelC0AuditedStateLineage audited

/-- The entire genesis (including exact audit permissions) is verified
    before any caller can obtain an audited state-lineage certificate. -/
def psKernelC0SealedAuditedBegin
    (maxRecDepth maxNatSize : Nat)
    (axioms : List PsKernelAxiomInfo)
    (capabilities : List PsKernelC0TrustCapability) :
    Option PsKernelC0SealedAuditedSourceWork :=
  match h : psKernelC0AuditedSourceBeginWithCapabilities
      maxRecDepth maxNatSize axioms capabilities with
  | none => none
  | some work =>
      some ⟨work, .genesis maxRecDepth maxNatSize
        axioms capabilities work h⟩

/-- Neither an unapproved trust event nor a failed source declaration
    creates a new checker-state or foundation-policy history. -/
def psKernelC0SealedAuditedAdmit
    (fuel : Nat)
    (work : PsKernelC0SealedAuditedSourceWork)
    (request : PsKernelC0ArchitectureDeclaration) :
    Except String PsKernelC0SealedAuditedSourceWork :=
  match h : psKernelC0AuditedSourceAdmit fuel work.audited request with
  | .error reason => .error reason
  | .ok next =>
      .ok ⟨next, .admitted work.lineage fuel request h⟩

def psKernelC0SealedAuditedWhnf
    (fuel : Nat)
    (work : PsKernelC0SealedAuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0SealedAuditedSourceWork) :=
  match h : psKernelC0AuditedSourceWhnf fuel work.audited expr with
  | .error reason => .error reason
  | .ok (value, next) =>
      .ok (value, ⟨next, .whnf work.lineage fuel expr value h⟩)

def psKernelC0SealedAuditedInfer
    (fuel : Nat)
    (work : PsKernelC0SealedAuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0SealedAuditedSourceWork) :=
  match h : psKernelC0AuditedSourceInfer fuel work.audited expr with
  | .error reason => .error reason
  | .ok (value, next) =>
      .ok (value, ⟨next, .inferred work.lineage fuel expr value h⟩)

def psKernelC0SealedAuditedCheck
    (fuel : Nat)
    (work : PsKernelC0SealedAuditedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0SealedAuditedSourceWork) :=
  match h : psKernelC0AuditedSourceCheck fuel work.audited expr with
  | .error reason => .error reason
  | .ok (value, next) =>
      .ok (value, ⟨next, .checked work.lineage fuel expr value h⟩)

def psKernelC0SealedAuditedDefEq
    (fuel : Nat)
    (work : PsKernelC0SealedAuditedSourceWork)
    (left right : PsKernelExpr) :
    Except String (Bool × PsKernelC0SealedAuditedSourceWork) :=
  match h : psKernelC0AuditedSourceDefEq fuel work.audited left right with
  | .error reason => .error reason
  | .ok (same, next) =>
      .ok (same, ⟨next, .defeq work.lineage fuel left right same h⟩)

def psKernelC0SealedAuditedStage
    (work : PsKernelC0SealedAuditedSourceWork)
    (expr : PsKernelExpr) : Option PsKernelC0SealedAuditedSourceWork :=
  match h : psKernelC0AuditedSourceStage work.audited expr with
  | none => none
  | some next =>
      some ⟨next, .staged work.lineage expr h⟩

/-- An explicit policy change is permitted ONLY if the entire previous
    trusted history can be successfully re-audited under the new policy.
    No checker state or declaration is changed during this operation. -/
def psKernelC0SealedAuditedChangePolicy
    (work : PsKernelC0SealedAuditedSourceWork)
    (axioms : List PsKernelAxiomInfo)
    (capabilities : List PsKernelC0TrustCapability) :
    Option PsKernelC0SealedAuditedSourceWork :=
  match h : psKernelC0AuditTrustedSourceWithCapabilities
      work.audited.trusted axioms capabilities with
  | none => none
  | some next =>
      some ⟨next, .policy work.lineage axioms capabilities h⟩

/-- The exact checked-state lineage and both foundation authorization
    theorems survive the composed audited session boundary. -/
def psKernelC0SealedAuditedHasLineage
    (work : PsKernelC0SealedAuditedSourceWork) :
    PsKernelC0AuditedStateLineage work.audited :=
  work.lineage

theorem psKernelC0SealedAuditedAxiomsApproved
    (work : PsKernelC0SealedAuditedSourceWork) :
    psKernelC0HistoryAxiomsApproved
      work.audited.trusted.history work.audited.allowedAxioms :=
  work.audited.approved

theorem psKernelC0SealedAuditedCapabilitiesApproved
    (work : PsKernelC0SealedAuditedSourceWork) :
    psKernelC0HistoryCapabilitiesApproved
      work.audited.trusted.history work.audited.allowedCapabilities :=
  work.audited.capabilitiesApproved
