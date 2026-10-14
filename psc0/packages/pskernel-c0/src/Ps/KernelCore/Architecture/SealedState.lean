import Ps.KernelCore.Architecture.TrustedAdmission

/-!
Phase E.3: proof-carrying checked-state provenance.

Environment admission history alone does not justify arbitrary contents of
WHNF, inference or DefEq caches. This indexed lineage starts at the *actual*
empty checker state and records exact successful checked-session transitions.
A raw source checker session is not automatically a qualified session.

All transition constructors require equality to a concrete, already
source-authoritative operation. The native syntax-only staging transition
also requires the actual checked staging result. The source-free WHNF
fragment is included through its previously proved exact source equation.

This is an opt-in provenance boundary. Existing raw/legacy public APIs
are not yet sealed or made unconstructible. This certificate also does not
prove source kernel soundness or the semantic validity of imported caches.
-/

/-- Reachable checked sessions, indexed by the ENTIRE trusted work value,
    including checker state and exact certified syntax snapshot. -/
inductive PsKernelC0CheckedStateLineage :
    PsKernelC0TrustedSourceWork → Prop where
  | genesis
      (maxRecDepth maxNatSize : Nat)
      (work : PsKernelC0TrustedSourceWork)
      (exact : psKernelC0TrustedSourceBegin maxRecDepth maxNatSize = some work) :
      PsKernelC0CheckedStateLineage work
  | admitted
      {before after : PsKernelC0TrustedSourceWork}
      (previous : PsKernelC0CheckedStateLineage before)
      (fuel : Nat)
      (request : PsKernelC0ArchitectureDeclaration)
      (exact : psKernelC0TrustedSourceAdmit fuel before request = .ok after) :
      PsKernelC0CheckedStateLineage after
  | whnf
      {before after : PsKernelC0TrustedSourceWork}
      (previous : PsKernelC0CheckedStateLineage before)
      (fuel : Nat)
      (expr value : PsKernelExpr)
      (exact : psKernelC0TrustedSourceWhnf fuel before expr = .ok (value, after)) :
      PsKernelC0CheckedStateLineage after
  | inferred
      {before after : PsKernelC0TrustedSourceWork}
      (previous : PsKernelC0CheckedStateLineage before)
      (fuel : Nat)
      (expr value : PsKernelExpr)
      (exact : psKernelC0TrustedSourceInfer fuel before expr = .ok (value, after)) :
      PsKernelC0CheckedStateLineage after
  | checked
      {before after : PsKernelC0TrustedSourceWork}
      (previous : PsKernelC0CheckedStateLineage before)
      (fuel : Nat)
      (expr value : PsKernelExpr)
      (exact : psKernelC0TrustedSourceCheck fuel before expr = .ok (value, after)) :
      PsKernelC0CheckedStateLineage after
  | defeq
      {before after : PsKernelC0TrustedSourceWork}
      (previous : PsKernelC0CheckedStateLineage before)
      (fuel : Nat)
      (left right : PsKernelExpr)
      (same : Bool)
      (exact : psKernelC0TrustedSourceDefEq fuel before left right =
        .ok (same, after)) :
      PsKernelC0CheckedStateLineage after
  | staged
      {before after : PsKernelC0TrustedSourceWork}
      (previous : PsKernelC0CheckedStateLineage before)
      (expr : PsKernelExpr)
      (exact : psKernelC0TrustedSourceStage before expr = some after) :
      PsKernelC0CheckedStateLineage after

/-- A caller cannot turn an arbitrary raw checker cache into this work
    without supplying a Lean proof of a complete lineage from genesis. -/
structure PsKernelC0SealedSourceWork where
  trusted : PsKernelC0TrustedSourceWork
  lineage : PsKernelC0CheckedStateLineage trusted

/-- The only genesis constructor executes the actual source empty-state
    initializer and retains an equality proof of the exact returned work. -/
def psKernelC0SealedSourceBegin
    (maxRecDepth maxNatSize : Nat) : Option PsKernelC0SealedSourceWork :=
  match h : psKernelC0TrustedSourceBegin maxRecDepth maxNatSize with
  | none => none
  | some work =>
      some ⟨work, .genesis maxRecDepth maxNatSize work h⟩

/-- Failed source admission is atomic: there is no successor certificate. -/
def psKernelC0SealedSourceAdmit
    (fuel : Nat)
    (work : PsKernelC0SealedSourceWork)
    (request : PsKernelC0ArchitectureDeclaration) :
    Except String PsKernelC0SealedSourceWork :=
  match h : psKernelC0TrustedSourceAdmit fuel work.trusted request with
  | .error reason => .error reason
  | .ok next =>
      .ok ⟨next, .admitted work.lineage fuel request h⟩

/-- Only the already qualified source-exact WHNF entry can advance this
    state; the candidate observer is not an allowed lineage transition. -/
def psKernelC0SealedSourceWhnf
    (fuel : Nat)
    (work : PsKernelC0SealedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0SealedSourceWork) :=
  match h : psKernelC0TrustedSourceWhnf fuel work.trusted expr with
  | .error reason => .error reason
  | .ok (value, next) =>
      .ok (value, ⟨next, .whnf work.lineage fuel expr value h⟩)

def psKernelC0SealedSourceInfer
    (fuel : Nat)
    (work : PsKernelC0SealedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0SealedSourceWork) :=
  match h : psKernelC0TrustedSourceInfer fuel work.trusted expr with
  | .error reason => .error reason
  | .ok (value, next) =>
      .ok (value, ⟨next, .inferred work.lineage fuel expr value h⟩)

def psKernelC0SealedSourceCheck
    (fuel : Nat)
    (work : PsKernelC0SealedSourceWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0SealedSourceWork) :=
  match h : psKernelC0TrustedSourceCheck fuel work.trusted expr with
  | .error reason => .error reason
  | .ok (value, next) =>
      .ok (value, ⟨next, .checked work.lineage fuel expr value h⟩)

def psKernelC0SealedSourceDefEq
    (fuel : Nat)
    (work : PsKernelC0SealedSourceWork)
    (left right : PsKernelExpr) :
    Except String (Bool × PsKernelC0SealedSourceWork) :=
  match h : psKernelC0TrustedSourceDefEq fuel work.trusted left right with
  | .error reason => .error reason
  | .ok (same, next) =>
      .ok (same, ⟨next, .defeq work.lineage fuel left right same h⟩)

/-- Staging retains the checked cache/environment state exactly as before;
    the new syntax snapshot is revalidated by the existing checked API. -/
def psKernelC0SealedSourceStage
    (work : PsKernelC0SealedSourceWork)
    (expr : PsKernelExpr) : Option PsKernelC0SealedSourceWork :=
  match h : psKernelC0TrustedSourceStage work.trusted expr with
  | none => none
  | some next =>
      some ⟨next, .staged work.lineage expr h⟩

/-- A sealed session also carries the existing, separately proved exact
    source-environment admission history. -/
def psKernelC0SealedSourceEnvironmentHistory
    (work : PsKernelC0SealedSourceWork) :
    PsKernelC0SourceEnvironmentHistory
      work.trusted.certified.raw.checker.context.environment :=
  work.trusted.history

/-- No independent cache judgment is made by staging or lineage receipt.
    Every successful step is tied to one exact checked operation equation. -/
def psKernelC0SealedSourceHasLineage
    (work : PsKernelC0SealedSourceWork) :
    PsKernelC0CheckedStateLineage work.trusted :=
  work.lineage
