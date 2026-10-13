import Ps.KernelCore.Architecture.Work
import Ps.KernelCore.Core.CertifiedStore

/-!
Phase C/E proof-carrying validated work transactions.

`ArchitectureWorkValid` performs the full scratch/whole-store replay on
each call. A source-authored immutable `CertifiedWork` carries a proof of
this exact predicate across source checking, inference, DefEq and WHNF,
where ONLY the checker state changes. The syntax/store never changes under
those four operations, so full replay need not be repeated.

Staging, admission and promotion remain their existing atomic and
independently validated operations. This wrapper does not turn syntax into
typing evidence and cannot use experimental demand for proof acceptance.
-/

/-- Full replay validation of a specific immutable transaction, including
    staged roots. The proof is about the actual raw transaction, not a
    guessed hash, store pointer or numeric handle. -/
structure PsKernelC0CertifiedWork where
  raw : PsKernelC0ArchitectureWork
  valid : psKernelC0ArchitectureWorkValid raw = true

def psKernelC0ArchitectureCertifyWork
    (work : PsKernelC0ArchitectureWork) :
    Option PsKernelC0CertifiedWork :=
  if h : psKernelC0ArchitectureWorkValid work = true then
    some { raw := work, valid := h }
  else none

/-- Source-checked sessions may update only the checker field. Store and
    staged-root predicates are structurally unchanged, so the original
    replay-validation proof remains valid by definitional reduction. -/
private def psKernelC0CertifiedWorkWithSession
    (work : PsKernelC0CertifiedWork)
    (session : PsKernelCheckerSession) : PsKernelC0CertifiedWork :=
  {
    raw := { work.raw with checker := session }
    valid := by
      change psKernelC0ArchitectureWorkValid work.raw = true
      exact work.valid
  }

/-- The checked source WHNF is used without revalidating an immutable store
    on every normalization call. It remains a reduction observation, not a
    proof that an arbitrary input term is well typed. -/
def psKernelC0CertifiedWorkWhnf
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0CertifiedWork) := do
  let (value, session) ← psKernelSessionWhnf fuel work.raw.checker expr
  return (value, psKernelC0CertifiedWorkWithSession work session)

/-- Source type synthesis; this is NOT full term checking. -/
def psKernelC0CertifiedWorkInfer
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0CertifiedWork) := do
  let (ty, session) ← psKernelSessionInfer fuel work.raw.checker expr
  return (ty, psKernelC0CertifiedWorkWithSession work session)

/-- Source DefEq on the current source-owned context. -/
def psKernelC0CertifiedWorkDefEq
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (left right : PsKernelExpr) :
    Except String (Bool × PsKernelC0CertifiedWork) := do
  let (same, session) ←
    psKernelSessionIsDefEq fuel work.raw.checker left right
  return (same, psKernelC0CertifiedWorkWithSession work session)

/-- Full source expression check: the only term-validation operation here.
    An indexed store certificate never suffices for this judgment. -/
def psKernelC0CertifiedWorkCheck
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0CertifiedWork) := do
  let (ty, session) ← psKernelSessionCheck fuel work.raw.checker expr
  return (ty, psKernelC0CertifiedWorkWithSession work session)

/-- The source admission operation is still the only environment authority.
    Its exact checked result gets a *new* work certificate, preventing
    transfer of a proof to any unvalidated transaction. -/
def psKernelC0CertifiedWorkAdmit
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (decl : PsKernelC0ArchitectureDeclaration) :
    Except String PsKernelC0CertifiedWork := do
  let next ← psKernelC0ArchitectureAdmit fuel work.raw decl
  let some certified := psKernelC0ArchitectureCertifyWork next
    | throw "source-admitted work did not validate its scratch store"
  return certified

/-- A syntax stage can change the store, so replay and certify the entire
    new state again. Unchecked/ill-typed syntax may be staged but never
    becomes a checked term by being present in a certified snapshot. -/
def psKernelC0CertifiedWorkStage
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) : Option PsKernelC0CertifiedWork := do
  let next ← psKernelC0ArchitectureStage work.raw expr
  psKernelC0ArchitectureCertifyWork next

/-- Return proof-carrying root certificates for the atomically promoted
    stage. No source type or DefEq judgment is created by this operation. -/
def psKernelC0CertifiedWorkCommit
    (work : PsKernelC0CertifiedWork) :
    Option (PsKernelC0CertifiedStore × List PsKernelC0CertifiedRoot) :=
  psKernelC0CertifyPromotedRoots
    work.raw.scratch work.raw.stagedRoots.reverse

/-- Stage exact source syntax in an immutable transaction, then certify
    the resulting *owned* working root. The root proof is about syntax
    readback only; type approval still requires a separate source check. -/
def psKernelC0CertifiedWorkStageRoot
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Option (PsKernelC0CertifiedWork × PsKernelC0CertifiedRoot) := do
  let staged ← psKernelC0CertifiedWorkStage work expr
  let root ← staged.raw.stagedRoots.head?
  let owner ← psKernelC0CertifyStore staged.raw.scratch.working
  let bound ← psKernelC0CertifyRootIn owner root
  if psKernelExprEqual bound.expression expr then
    some (staged, bound)
  else none

/-- Check the *exact decoded* expression of a certified immutable source
    root. The root certificate is NOT a type certificate: the existing
    independent source checker must still perform the full check. -/
def psKernelC0CertifiedWorkCheckRoot
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (root : PsKernelC0CertifiedRoot) :
    Except String (PsKernelExpr × PsKernelC0CertifiedWork) :=
  psKernelC0CertifiedWorkCheck fuel work root.expression

/-- The same deliberate distinction holds for type synthesis: a
    certified expression can be inferable while not fully well typed. -/
def psKernelC0CertifiedWorkInferRoot
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (root : PsKernelC0CertifiedRoot) :
    Except String (PsKernelExpr × PsKernelC0CertifiedWork) :=
  psKernelC0CertifiedWorkInfer fuel work root.expression
