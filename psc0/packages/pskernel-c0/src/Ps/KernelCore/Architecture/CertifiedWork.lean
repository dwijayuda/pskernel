import Ps.KernelCore.Architecture.Work
import Ps.KernelCore.Core.CertifiedStore

/-!
Phase C/E proof-carrying validated work transactions.

`ArchitectureWorkValid` performs the full scratch/whole-store replay on
each call. A source-authored immutable `CertifiedWork` carries a proof of
this exact predicate across source checking, inference, DefEq and WHNF,
where ONLY the checker state changes. The syntax/store never changes under
those operations, so full replay need not be repeated. The work now owns
the same mathematical StoreWF certificate as its immutable working store.

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
  working : PsKernelC0CertifiedStore
  owned : working.store = raw.scratch.working

/-- Preserve dependent equality to the exact work supplied by the
    caller. Admission receipts need this equality to prove that their
    certified result is precisely the source checker's successful result. -/
def psKernelC0ArchitectureCertifyWorkOwned
    (work : PsKernelC0ArchitectureWork) :
    Option { cert : PsKernelC0CertifiedWork // cert.raw = work } :=
  if h : psKernelC0ArchitectureWorkValid work = true then
    match psKernelC0CertifyStoreOwned work.scratch.working with
    | some ⟨working, owned⟩ =>
        some ⟨{
          raw := work, valid := h, working := working, owned := owned
        }, rfl⟩
    | none => none
  else none

def psKernelC0ArchitectureCertifyWork
    (work : PsKernelC0ArchitectureWork) :
    Option PsKernelC0CertifiedWork :=
  (psKernelC0ArchitectureCertifyWorkOwned work).map Subtype.val

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
    working := work.working
    owned := by
      change work.working.store = work.raw.scratch.working
      exact work.owned
  }

/-- Every validated work transaction now carries the exact full
    mathematical StoreWF proof for its CURRENT immutable working snapshot.
    It is retained without rechecking on source operations that change
    only the checker session. This is syntax integrity, not a typing proof. -/
theorem psKernelC0CertifiedWorkStoreWF
    (work : PsKernelC0CertifiedWork) :
    psKernelC0StoreWF work.raw.scratch.working := by
  rw [← work.owned]
  exact work.working.wellFormed

theorem psKernelC0CertifiedWorkCanonical
    (work : PsKernelC0CertifiedWork) :
    psKernelC0ReplayValidateStore work.raw.scratch.working = true := by
  rw [← work.owned]
  exact work.working.canonical

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

/-- Source proposition classification shares the immutable certificate
    and advances only the source-owned checker state. -/
def psKernelC0CertifiedWorkIsProp
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (Bool × PsKernelC0CertifiedWork) := do
  let (isProp, session) ← psKernelSessionIsProp fuel work.raw.checker expr
  return (isProp, psKernelC0CertifiedWorkWithSession work session)

/-- Typed K/structure-eta is an observation from the original checker,
    not a new proof. An immutable validated scratch store does not need
    another full replay to receive the source-owned observer state. -/
def psKernelC0CertifiedWorkObserveTypedMajor
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (recName : PsKernelName)
    (major : PsKernelExpr) :
    Except String
      (PsKernelC0TypedMajorObservation × PsKernelC0CertifiedWork) := do
  let (observation, session) ←
    psKernelC0ArchitectureObserveTypedMajor fuel work.raw.checker recName major
  return (observation, psKernelC0CertifiedWorkWithSession work session)

/-- Source-authoritative typed-demand preview with the existing operation
    work quota. It cannot change the replay certificate or admit a term. -/
def psKernelC0CertifiedWorkPreviewTypedDemand
    (fuel quota : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String
      (PsKernelC0ExecutionObservation × PsKernelC0CertifiedWork) := do
  let (observation, session) ←
    psKernelC0ArchitectureObserveTypedDemand
      fuel quota work.raw.checker expr
  return (observation, psKernelC0CertifiedWorkWithSession work session)

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
  -- Stage already produced a certificate for this exact immutable
  -- working snapshot; reuse its proof rather than replaying a second time.
  let bound ← psKernelC0CertifyRootIn staged.working root
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

/-- A proof-carrying RECORD of a full source checker success.
    The equality is tied to the exact certified decoded syntax, source
    environment/local context, pre-check state and fuel. This is stronger
    than an easily substituted (expression, reportedType) tuple.

    It proves the specified executable source checker returned `.ok`;
    it does not prove the source checker sound, the environment consistent,
    or the source expression a closed theorem in every context. -/
structure PsKernelC0SourceCheckedRoot where
  root : PsKernelC0CertifiedRoot
  context : PsKernelCheckerContext
  stateBefore : PsKernelCheckerState
  fuel : Nat
  checkedType : PsKernelExpr
  stateAfter : PsKernelCheckerState
  sourceCheck :
    psKernelCheckerCheck fuel context stateBefore root.expression =
      .ok (checkedType, stateAfter)

/-- Produce the checked-result witness in the SAME run as source checking,
    not from a candidate reduction, type synthesis, or an assumed hash. -/
def psKernelC0SourceCheckCertifiedRoot
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (root : PsKernelC0CertifiedRoot) :
    Except String (PsKernelC0SourceCheckedRoot × PsKernelCheckerSession) :=
  match h : psKernelCheckerCheck fuel session.context session.state
      root.expression with
  | .error reason => .error reason
  | .ok (ty, nextState) =>
      .ok ({
        root := root
        context := session.context
        stateBefore := session.state
        fuel := fuel
        checkedType := ty
        stateAfter := nextState
        sourceCheck := h
      }, { session with state := nextState })

theorem psKernelC0SourceCheckedRootExact
    (checked : PsKernelC0SourceCheckedRoot) :
    psKernelCheckerCheck checked.fuel checked.context
        checked.stateBefore checked.root.expression =
      .ok (checked.checkedType, checked.stateAfter) :=
  checked.sourceCheck

/-- Atomic source-checked publication of selected staged expressions.
    Unlike syntax-only `CertifiedWorkCommit`, EVERY selected root must
    pass independent full source checking before this operation returns a
    published store and its checked source type. A single error rejects the
    complete result; the input work and persistent prefix are immutable.

    The returned types are observational checked-session results, not
    forge-resistant public proof receipts: nothing here allows candidates
    or root hashes to authorize theorem/declaration admission. -/
def psKernelC0CertifiedWorkCommitChecked
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork) :
    Except String
      (PsKernelC0CertifiedStore ×
        List PsKernelC0SourceCheckedRoot ×
        PsKernelC0CertifiedWork) := do
  let some (owner, roots) := psKernelC0CertifiedWorkCommit work
    | throw "source-certified root promotion failed canonical validation"
  let mut checkedWork := work
  let mut typed : List PsKernelC0SourceCheckedRoot := []
  for root in roots do
    -- A locally well-typed fvar is NOT a closed proof/executable root.
    -- Source declaration validation owns these exact closure and universe
    -- rules; do not turn a locally inferred term into a published artifact.
    let _ ← psKernelCheckNoMVarNoFVar root.expression
    let _ ← psKernelCheckLevelParams
      root.expression checkedWork.raw.checker.context.levelParams
    let (receipt, nextSession) ← psKernelC0SourceCheckCertifiedRoot
      fuel checkedWork.raw.checker root
    checkedWork := psKernelC0CertifiedWorkWithSession
      checkedWork nextSession
    typed := receipt :: typed
  return (owner, typed.reverse, checkedWork)
