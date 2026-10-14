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

/-- Change ONLY the source-checker state and retain an explicit
    equality witness that the immutable environment was not replaced.
    Source-authoritative query paths may reuse this to preserve checked
    admission history without rebuilding the canonical store certificate. -/
def psKernelC0CertifiedWorkWithStateOwned
    (work : PsKernelC0CertifiedWork)
    (state : PsKernelCheckerState) :
    { next : PsKernelC0CertifiedWork //
      next.raw.checker.context.environment =
        work.raw.checker.context.environment } :=
  ⟨psKernelC0CertifiedWorkWithSession work
    { work.raw.checker with state := state }, rfl⟩

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

/-- Staging changes the canonical syntax store, requiring fresh replay
    certification. It preserves the EXACT admitted environment through
    source-validated staging and dependent recertification, without
    relying on fingerprints or relaxing source type checking. -/
def psKernelC0CertifiedWorkStageWithEnvProof
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Option { next : PsKernelC0CertifiedWork //
      next.raw.checker.context.environment =
        work.raw.checker.context.environment } := do
  let ⟨rawNext, checkedOwner⟩ ←
    psKernelC0ArchitectureStageWithOwner work.raw expr
  let ⟨next, sourceOwner⟩ ←
    psKernelC0ArchitectureCertifyWorkOwned rawNext
  let unchanged :
      next.raw.checker.context.environment =
        work.raw.checker.context.environment := by
    rw [sourceOwner, checkedOwner]
  some ⟨next, unchanged⟩

def psKernelC0CertifiedWorkStage
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) : Option PsKernelC0CertifiedWork :=
  (psKernelC0CertifiedWorkStageWithEnvProof work expr).map Subtype.val

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


/-!
Phase E: direct source-exact irreducible-head WHNF.

Lean 4.35's native checker returns BVar, Sort, MVar, Pi and literal heads
without consulting a cache or reducing an environment declaration. C0's
source WHNF has the same direct cases (Reduction/Whnf.lean). They can be
implemented without calling the source reduction worker, provided a source
equivalence theorem preserves the complete checked transaction and fuel
behavior. Constants, local free variables, lambdas and projections are
*excluded*: their reduction and cache effects are context-dependent.
-/

/-- A fuel-accounted, context-free WHNF fragment: erase arbitrary nested
    metadata and stop ONLY at source-irreducible heads. Each wrapper and the
    terminal head consume one source WHNF recursive step. All other heads
    decline, including names requiring delta, locals, lambdas, applications,
    recursors, projections and lets. No source callback or checker cache is
    read or modified by this operation. -/
def psKernelC0IrreducibleWhnfWithFuel : Nat → PsKernelExpr → Option PsKernelExpr
  | 0, _ => none
  | Nat.succ remaining, expr =>
      match expr with
      | .mdata _ body => psKernelC0IrreducibleWhnfWithFuel remaining body
      | .bvar _ => some expr
      | .sort _ => some expr
      | .mvar _ => some expr
      | .forallE _ _ _ _ => some expr
      | .lit _ => some expr
      | _ => none

/-- The complete *public source WHNF algorithm* agrees with the pure
    metadata/head fragment under ANY context, checker state and recursor
    callback. This avoids relying on a bounded set of source differential
    examples: the evaluator never touches environment-sensitive rules. -/
theorem psKernelC0IrreducibleWhnf_source
    (fuel : Nat)
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (h : psKernelC0IrreducibleWhnfWithFuel fuel expr = some result) :
    psKernelWhnfWithFuel fuel reduceRecursor context state expr =
      .ok (result, state) := by
  induction fuel generalizing expr result with
  | zero =>
      simp [psKernelC0IrreducibleWhnfWithFuel] at h
  | succ remaining ih =>
      cases expr with
      | mdata data body =>
          have hbody :
              psKernelC0IrreducibleWhnfWithFuel remaining body =
                some result := by
            simpa only [psKernelC0IrreducibleWhnfWithFuel] using h
          change psKernelWhnfWithFuel remaining reduceRecursor
            context state body = .ok (result, state)
          exact ih body result hbody
      | bvar index =>
          have heq : PsKernelExpr.bvar index = result :=
            Option.some.inj
              (by simpa only [psKernelC0IrreducibleWhnfWithFuel] using h)
          subst result
          rfl
      | sort level =>
          have heq : PsKernelExpr.sort level = result :=
            Option.some.inj
              (by simpa only [psKernelC0IrreducibleWhnfWithFuel] using h)
          subst result
          rfl
      | mvar name =>
          have heq : PsKernelExpr.mvar name = result :=
            Option.some.inj
              (by simpa only [psKernelC0IrreducibleWhnfWithFuel] using h)
          subst result
          rfl
      | forallE name ty body binder =>
          have heq : PsKernelExpr.forallE name ty body binder = result :=
            Option.some.inj
              (by simpa only [psKernelC0IrreducibleWhnfWithFuel] using h)
          subst result
          rfl
      | lit literal =>
          have heq : PsKernelExpr.lit literal = result :=
            Option.some.inj
              (by simpa only [psKernelC0IrreducibleWhnfWithFuel] using h)
          subst result
          rfl
      | fvar _ => simp [psKernelC0IrreducibleWhnfWithFuel] at h
      | const _ _ => simp [psKernelC0IrreducibleWhnfWithFuel] at h
      | app _ _ => simp [psKernelC0IrreducibleWhnfWithFuel] at h
      | lam _ _ _ _ => simp [psKernelC0IrreducibleWhnfWithFuel] at h
      | letE _ _ _ _ _ => simp [psKernelC0IrreducibleWhnfWithFuel] at h
      | proj _ _ _ => simp [psKernelC0IrreducibleWhnfWithFuel] at h

/-- A successful pure fragment reduction is exactly the original checked
    session WHNF, including its full source state. In particular, eliminating
    metadata here does not create a source-cache entry or proof judgment. -/
theorem psKernelC0IrreducibleWhnf_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr result : PsKernelExpr)
    (h : psKernelC0IrreducibleWhnfWithFuel fuel expr = some result) :
    psKernelC0CertifiedWorkWhnf fuel work expr = .ok (result, work) := by
  have hsource :
      psKernelCheckerWhnf fuel work.raw.checker.context
        work.raw.checker.state expr =
          .ok (result, work.raw.checker.state) := by
    change psKernelWhnfWithFuel fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr =
        .ok (result, work.raw.checker.state)
    exact psKernelC0IrreducibleWhnf_source fuel
      (psKernelReduceRecursorBoundedWithFuel fuel
        (psKernelIsDefEqWithFuel fuel))
      work.raw.checker.context work.raw.checker.state expr result h
  unfold psKernelC0CertifiedWorkWhnf psKernelSessionWhnf
  simp only [hsource]
  rfl

/-- The accepting fast path chooses independently evaluated nested-metadata
    and irreducible heads ONLY under an all-context source-refinement theorem.
    All context-sensitive forms and insufficient source fuel are delegated
    unchanged to the source checker, including its error classification. -/
def psKernelC0CertifiedWorkWhnfCanonicalFast
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0CertifiedWork) :=
  match psKernelC0IrreducibleWhnfWithFuel fuel expr with
  | some value => .ok (value, work)
  | none => psKernelC0CertifiedWorkWhnf fuel work expr

/-- Exact successful and failed source behavior for every input fuel,
    environment, expression, and checker/cache state. -/
theorem psKernelC0CertifiedWorkWhnfCanonicalFast_exact
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    psKernelC0CertifiedWorkWhnfCanonicalFast fuel work expr =
      psKernelC0CertifiedWorkWhnf fuel work expr := by
  unfold psKernelC0CertifiedWorkWhnfCanonicalFast
  cases h : psKernelC0IrreducibleWhnfWithFuel fuel expr with
  | none => rfl
  | some value =>
      exact (psKernelC0IrreducibleWhnf_certified
        fuel work expr value h).symm

/-- A successful WHNF output with its exact source-evaluation equality.
    Unlike an observational candidate, this can be carried through checked
    work APIs without guessing a cache key or changing the source state. -/
abbrev PsKernelC0SourceExactWhnfOutput
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :=
  { result : PsKernelExpr × PsKernelC0CertifiedWork //
      psKernelC0CertifiedWorkWhnf fuel work expr = .ok result }

/-- The direct-head implementation returns a source-exact certificate
    WITHOUT invoking the source WHNF evaluator for positive-fuel direct
    heads. The theorem above establishes the result in every context. -/
def psKernelC0CertifiedWorkWhnfCanonicalFastOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0SourceExactWhnfOutput fuel work expr) :=
  match h : psKernelC0CertifiedWorkWhnfCanonicalFast fuel work expr with
  | .error error => .error error
  | .ok result =>
      .ok ⟨result, by
        rw [← psKernelC0CertifiedWorkWhnfCanonicalFast_exact fuel work expr]
        exact h⟩

/-!
Phase E: proof-carrying, source-exact candidate-to-accepting WHNF bridge.

A candidate can be selected as the returned WHNF expression ONLY when Lean's
propositional equality proves that it is exactly the value of the successful
source WHNF operation. Source checking runs first and provides the only state
transition. Candidate decline or disagreement is never a kernel rejection.
This conservatively establishes an accepting integration seam, not an
independent or faster kernel; eliminating the source check will require a
general source-refinement theorem for the selected optimized evaluator.
-/

/-- An observation whose successful branch has a *propositional* source-
    expression equality witness. Boolean equality or matching hashes are
    deliberately insufficient. Declines and mismatches are not verdicts. -/
inductive PsKernelC0WhnfCrossCheck (source : PsKernelExpr) where
  | agreed (candidate : { value : PsKernelExpr // value = source })
  | mismatch (candidate : PsKernelExpr)
  | declined (reason : String)

/-- The exact result of the source-owned, certified WHNF operation, paired
    with independent candidate evidence. Constructing this receipt without
    a source-result proof is impossible in Lean's ordinary safe fragment. -/
structure PsKernelC0WhnfRefinementReceipt
    (fuel : Nat)
    (before : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) where
  sourceValue : PsKernelExpr
  sourceWork : PsKernelC0CertifiedWork
  sourceCheck :
    psKernelC0CertifiedWorkWhnf fuel before expr =
      .ok (sourceValue, sourceWork)
  candidate : PsKernelC0WhnfCrossCheck sourceValue

/-- Run source WHNF *once*, then independently evaluate the bounded
    closure/demand implementation under the same starting context.
    The candidate must have exactly the same source expression, including
    binder names, annotations and metadata. A mismatch or budget decline
    does not change the source checker session or its error classification. -/
def psKernelC0CertifiedWorkRefineWhnf
    (fuel quota : Nat)
    (before : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0WhnfRefinementReceipt fuel before expr) :=
  match h : psKernelC0CertifiedWorkWhnf fuel before expr with
  | .error reason => .error reason
  | .ok (sourceValue, sourceWork) =>
      let crossCheck : PsKernelC0WhnfCrossCheck sourceValue :=
        match psKernelC0ArchitectureCandidateDemandMetered
            fuel quota before.raw.checker.context expr with
        | .error reason => .declined reason
        | .ok (candidate, _, _) =>
            if eq : candidate = sourceValue then
              .agreed ⟨candidate, eq⟩
            else
              .mismatch candidate
      .ok {
        sourceValue := sourceValue
        sourceWork := sourceWork
        sourceCheck := h
        candidate := crossCheck
      }

/-- Selecting a candidate changes the returned expression only when an
    exact source-equality proof accompanies it. Otherwise return the source
    expression directly, with the already source-checked session. -/
def psKernelC0WhnfReceiptValue
    {fuel : Nat}
    {before : PsKernelC0CertifiedWork}
    {expr : PsKernelExpr}
    (receipt : PsKernelC0WhnfRefinementReceipt fuel before expr) :
    PsKernelExpr :=
  match receipt.candidate with
  | .agreed proof => proof.val
  | .mismatch _ => receipt.sourceValue
  | .declined _ => receipt.sourceValue

/-- The candidate-selected WHNF is definitionally no more powerful than
    source WHNF: Lean equality (not an external candidate bit) is required. -/
theorem psKernelC0WhnfReceiptValue_source
    {fuel : Nat}
    {before : PsKernelC0CertifiedWork}
    {expr : PsKernelExpr}
    (receipt : PsKernelC0WhnfRefinementReceipt fuel before expr) :
    psKernelC0WhnfReceiptValue receipt = receipt.sourceValue := by
  cases receipt with
  | mk sourceValue sourceWork sourceCheck candidate =>
      cases candidate with
      | agreed proof => exact proof.property
      | mismatch _ => rfl
      | declined _ => rfl

/-- Exact successful source WHNF and its checker state are preserved by
    the candidate selection; the receipt is *not* a theorem/proof verdict. -/
theorem psKernelC0WhnfReceipt_sourceCheck
    {fuel : Nat}
    {before : PsKernelC0CertifiedWork}
    {expr : PsKernelExpr}
    (receipt : PsKernelC0WhnfRefinementReceipt fuel before expr) :
    psKernelC0CertifiedWorkWhnf fuel before expr =
      .ok (psKernelC0WhnfReceiptValue receipt, receipt.sourceWork) := by
  rw [psKernelC0WhnfReceiptValue_source receipt]
  exact receipt.sourceCheck

/-- A checked nontrivial WHNF candidate is permitted to return only a
    result carrying the source evaluator's exact successful equation.
    Source errors and candidate declines remain separate conditions. -/
def psKernelC0CertifiedWorkWhnfRefinedOwned
    (fuel quota : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0SourceExactWhnfOutput fuel work expr) := do
  let receipt ← psKernelC0CertifiedWorkRefineWhnf fuel quota work expr
  return ⟨(psKernelC0WhnfReceiptValue receipt, receipt.sourceWork),
    psKernelC0WhnfReceipt_sourceCheck receipt⟩

/-- Direct immutable WHNF forms can be independently decided. All other
    forms stay on the source-first, exact-refinement observation path.
    In both cases the *return type* forbids a successful result without
    an exact source-WHNF proof for this environment and this fuel.
    This is a qualified work API, NOT a complete independent type checker. -/
def psKernelC0WhnfIrreducibleHead (expr : PsKernelExpr) : Bool :=
  match expr with
  | .bvar _ => true
  | .sort _ => true
  | .mvar _ => true
  | .forallE _ _ _ _ => true
  | .lit _ => true
  | _ => false

def psKernelC0CertifiedWorkWhnfQualified
    (fuel quota : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0SourceExactWhnfOutput fuel work expr) :=
  match psKernelC0IrreducibleWhnfWithFuel fuel expr with
  | some _ => psKernelC0CertifiedWorkWhnfCanonicalFastOwned fuel work expr
  | none => psKernelC0CertifiedWorkWhnfRefinedOwned fuel quota work expr

/-- A drop-in, fully source-equivalent checked WHNF result. Unlike the
    historical source-only entry, its five direct heads avoid the source
    evaluator; other heads remain explicitly source qualified. -/
def psKernelC0CertifiedWorkWhnfQualifiedValue
    (fuel quota : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0CertifiedWork) := do
  let receipt ← psKernelC0CertifiedWorkWhnfQualified fuel quota work expr
  return receipt.val

/-- Opt-in checked work entry. Only the exact-proved candidate value can
    replace source WHNF; a declined or mismatched candidate never rejects,
    authorizes a proof, or mutates the source-checked environment. -/
def psKernelC0CertifiedWorkWhnfRefined
    (fuel quota : Nat)
    (work : PsKernelC0CertifiedWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0CertifiedWork) := do
  let receipt ← psKernelC0CertifiedWorkRefineWhnf fuel quota work expr
  return (psKernelC0WhnfReceiptValue receipt, receipt.sourceWork)


/-!
Phase E.4G: proof-qualified reflexive definitional equality.

Lean 4.35's quick DefEq path recognizes structural equality before
normalization, but the C0 native source algorithm first consumes its fuel
and checks the recursion-depth policy; on success, it also inserts the
exact original comparison into the positive-pair cache.

The independent path below reproduces all those observable steps without
running the source DefEq worker for qualifying terms. Every other input,
including a resource-declined query, remains source authoritative.
-/

/-- Complete structurally reflexive quick-DefEq fragment. Not a typing
    judgment. Its positive result is valid only for this exact algorithm's
    checked recursion-depth and fuel boundary; it never uses imported
    unqualified cache pairs or computes their transitive closure. -/
def psKernelC0DefEqReflexiveWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    Option (Bool × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ _ =>
      match psKernelCheckerContextEnterRecDepth context with
      | .error _ => none
      | .ok _ =>
          if psKernelExprEq left right then
            some (psKernelDefEqFinish state left right true)
          else none

/-- Exact result and positive-cache state preservation against the full
    original source DefEq worker for every context/state, including
    source recursion guards. This theorem requires no candidate oracle. -/
theorem psKernelC0DefEqReflexive_source
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (result : Bool × PsKernelCheckerState)
    (h : psKernelC0DefEqReflexiveWithFuel
      fuel context state left right = some result) :
    psKernelIsDefEq fuel context state left right = .ok result := by
  cases fuel with
  | zero =>
      simp [psKernelC0DefEqReflexiveWithFuel] at h
  | succ remaining =>
      cases depth : psKernelCheckerContextEnterRecDepth context with
      | error reason =>
          simp [psKernelC0DefEqReflexiveWithFuel, depth] at h
      | ok entered =>
          by_cases same : psKernelExprEq left right = true
          · have hresult :
                result = psKernelDefEqFinish state left right true := by
              have hsome : some (psKernelDefEqFinish state left right true) =
                  some result := by
                simpa [psKernelC0DefEqReflexiveWithFuel, depth, same] using h
              exact (Option.some.inj hsome).symm
            rw [hresult]
            change psKernelIsDefEqWithFuel (Nat.succ remaining)
              context state left right =
                .ok (psKernelDefEqFinish state left right true)
            simp [psKernelIsDefEqWithFuel, depth, same]
          · simp [psKernelC0DefEqReflexiveWithFuel, depth, same] at h

/-- Qualified accepting DefEq execution for reflexive inputs; no candidate
    or externally built cache is authoritative. Every declined pure case
    delegates unchanged to source DefEq and its original error taxonomy. -/
def psKernelC0CertifiedWorkDefEqCanonicalFast
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (left right : PsKernelExpr) :
    Except String (Bool × PsKernelC0CertifiedWork) :=
  match psKernelC0DefEqReflexiveWithFuel fuel
      work.raw.checker.context work.raw.checker.state left right with
  | none => psKernelC0CertifiedWorkDefEq fuel work left right
  | some (same, checkedState) =>
      .ok (same,
        psKernelC0CertifiedWorkWithSession work
          { work.raw.checker with state := checkedState })

/-- The optimized/reflexive and original checked-session DefEq operations
    are identical for ALL inputs, including source failures, state updates
    and positive-cache results. -/
theorem psKernelC0CertifiedWorkDefEqCanonicalFast_exact
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (left right : PsKernelExpr) :
    psKernelC0CertifiedWorkDefEqCanonicalFast fuel work left right =
      psKernelC0CertifiedWorkDefEq fuel work left right := by
  unfold psKernelC0CertifiedWorkDefEqCanonicalFast
  cases h : psKernelC0DefEqReflexiveWithFuel fuel
      work.raw.checker.context work.raw.checker.state left right with
  | none => rfl
  | some result =>
      cases result with
      | mk same checkedState =>
          have hsource :
              psKernelIsDefEq fuel
                work.raw.checker.context work.raw.checker.state
                left right = .ok (same, checkedState) :=
            psKernelC0DefEqReflexive_source fuel
              work.raw.checker.context work.raw.checker.state
              left right (same, checkedState) h
          unfold psKernelC0CertifiedWorkDefEq psKernelSessionIsDefEq
          simp only [hsource]
          rfl

/-- A successfully selected DefEq result carries its exact source
    checked-session equation. A cache hint or Boolean verdict alone is
    insufficient to construct this receipt. -/
def psKernelC0CertifiedWorkDefEqCanonicalFastOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (left right : PsKernelExpr) :
    Except String
      { result : Bool × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkDefEq fuel work left right = .ok result } :=
  match h : psKernelC0CertifiedWorkDefEqCanonicalFast fuel work left right with
  | .error reason => .error reason
  | .ok result =>
      .ok ⟨result, by
        rw [← psKernelC0CertifiedWorkDefEqCanonicalFast_exact
          fuel work left right]
        exact h⟩


/-!
Phase E.4H: independent closed-form Sort/universe DefEq.

The original Lean 4.35 kernel's quick_is_def_eq handles Sort levels
without full normalization. Preserve C0's exact source algorithm:
fuel and recursion guards, early syntactic equality, already-successful
cache lookup (even for arbitrary raw source state), source level
equivalence, and positive-only cache publication.
-/

/-- Fully independent Sort-head source evaluation for a qualified context.
    It never invokes the source DefEq worker. On declined resources the
    source operation must be used for the exact original error. -/
def psKernelC0SortDefEqWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (leftLevel rightLevel : PsKernelLevel) :
    Option (Bool × PsKernelCheckerState) :=
  match fuel with
  | 0 => none
  | Nat.succ _ =>
      match psKernelCheckerContextEnterRecDepth context with
      | .error _ => none
      | .ok _ =>
          let left : PsKernelExpr := .sort leftLevel
          let right : PsKernelExpr := .sort rightLevel
          if psKernelExprEq left right then
            some (psKernelDefEqFinish state left right true)
          else if psKernelExprPairSetContains state.success left right then
            some (true, state)
          else
            some (psKernelDefEqFinish state left right
              (psKernelLevelEquivalent leftLevel rightLevel))

/-- For ANY input source cache/context and Sort universe levels, a
    successful direct-head result equals the full source DefEq judgment
    AND the complete source checker state. This includes source's
    successful-pair memo semantics and is not a general consistency proof. -/
theorem psKernelC0SortDefEq_source
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (leftLevel rightLevel : PsKernelLevel)
    (result : Bool × PsKernelCheckerState)
    (h : psKernelC0SortDefEqWithFuel fuel context state
      leftLevel rightLevel = some result) :
    psKernelIsDefEq fuel context state
      (.sort leftLevel) (.sort rightLevel) = .ok result := by
  cases fuel with
  | zero =>
      simp [psKernelC0SortDefEqWithFuel] at h
  | succ remaining =>
      cases depth : psKernelCheckerContextEnterRecDepth context with
      | error reason =>
          simp [psKernelC0SortDefEqWithFuel, depth] at h
      | ok entered =>
          by_cases same :
              psKernelExprEq (.sort leftLevel) (.sort rightLevel) = true
          · have hresult :
                result = psKernelDefEqFinish state
                  (.sort leftLevel) (.sort rightLevel) true := by
              have hsome : some (psKernelDefEqFinish state
                  (.sort leftLevel) (.sort rightLevel) true) = some result := by
                simpa [psKernelC0SortDefEqWithFuel, depth, same] using h
              exact (Option.some.inj hsome).symm
            rw [hresult]
            change psKernelIsDefEqWithFuel (Nat.succ remaining)
              context state (.sort leftLevel) (.sort rightLevel) =
                .ok (psKernelDefEqFinish state
                  (.sort leftLevel) (.sort rightLevel) true)
            simp [psKernelIsDefEqWithFuel, depth, same]
          · by_cases cached :
                psKernelExprPairSetContains state.success
                  (.sort leftLevel) (.sort rightLevel) = true
            · have hresult : result = (true, state) := by
                have hsome : some (true, state) = some result := by
                  simpa [psKernelC0SortDefEqWithFuel, depth, same, cached]
                    using h
                exact (Option.some.inj hsome).symm
              rw [hresult]
              change psKernelIsDefEqWithFuel (Nat.succ remaining)
                context state (.sort leftLevel) (.sort rightLevel) =
                  .ok (true, state)
              simp [psKernelIsDefEqWithFuel, depth, same, cached]
            · have hresult :
                  result = psKernelDefEqFinish state
                    (.sort leftLevel) (.sort rightLevel)
                    (psKernelLevelEquivalent leftLevel rightLevel) := by
                have hsome : some (psKernelDefEqFinish state
                    (.sort leftLevel) (.sort rightLevel)
                    (psKernelLevelEquivalent leftLevel rightLevel)) =
                      some result := by
                  simpa [psKernelC0SortDefEqWithFuel, depth, same, cached]
                    using h
                exact (Option.some.inj hsome).symm
              rw [hresult]
              change psKernelIsDefEqWithFuel (Nat.succ remaining)
                context state (.sort leftLevel) (.sort rightLevel) =
                  .ok (psKernelDefEqFinish state
                    (.sort leftLevel) (.sort rightLevel)
                    (psKernelLevelEquivalent leftLevel rightLevel))
              simp [psKernelIsDefEqWithFuel, depth, same, cached,
                psKernelDefEqQuickAfterCommon]

/-- A source-equation-carrying Sort comparison. Every successful direct
    result is independently source-proved. Other cases use the already
    qualified reflexive/source fallback and preserve resource/error paths. -/
def psKernelC0CertifiedWorkDefEqSortOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (leftLevel rightLevel : PsKernelLevel) :
    Except String
      { result : Bool × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkDefEq fuel work
          (.sort leftLevel) (.sort rightLevel) = .ok result } :=
  match h : psKernelC0SortDefEqWithFuel fuel
      work.raw.checker.context work.raw.checker.state
      leftLevel rightLevel with
  | none =>
      psKernelC0CertifiedWorkDefEqCanonicalFastOwned fuel work
        (.sort leftLevel) (.sort rightLevel)
  | some (same, checkedState) =>
      .ok ⟨(same,
        psKernelC0CertifiedWorkWithSession work
          { work.raw.checker with state := checkedState }), by
        have source :
            psKernelIsDefEq fuel work.raw.checker.context
              work.raw.checker.state
              (.sort leftLevel) (.sort rightLevel) =
                .ok (same, checkedState) :=
          psKernelC0SortDefEq_source fuel work.raw.checker.context
            work.raw.checker.state leftLevel rightLevel
            (same, checkedState) h
        unfold psKernelC0CertifiedWorkDefEq psKernelSessionIsDefEq
        simp only [source]
        rfl⟩
