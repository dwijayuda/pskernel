import Ps.KernelCore.Architecture.Typed
import Ps.KernelCore.Core.IndexedScratch
import Ps.KernelCore.Admission.Declaration.Admission
import Ps.KernelCore.Admission.Inductive.Ordinary.Admission
import Ps.KernelCore.Admission.Inductive.Mutual.Admission
import Ps.KernelCore.Admission.Inductive.Nested.Admission

/-!
Architecture-first Phase C/E operation boundary.

A transaction may stage syntax in a scratch arena and may *observe* lazy
execution, but it cannot turn either into a checked judgment. Only an
independently checked source term can advance the checker session. Publication
is a syntax-only, explicitly replay-validated operation.
-/

structure PsKernelC0ArchitectureWork where
  checker : PsKernelCheckerSession
  scratch : PsKernelC0Scratch
  stagedRoots : List Nat := []

/-- Never trust an externally constructed indexed store or work object.
    This operation does not claim formal StoreWF or ownership sealing. -/
def psKernelC0ArchitectureWorkValid
    (work : PsKernelC0ArchitectureWork) : Bool :=
  psKernelC0ScratchValid work.scratch &&
    work.stagedRoots.all (psKernelC0StoreValid work.scratch.working)

def psKernelC0ArchitectureBegin
    (checker : PsKernelCheckerSession)
    (persistent : PsKernelC0TermStore := psKernelC0StoreEmpty) :
    Option PsKernelC0ArchitectureWork :=
  if psKernelC0ReplayValidateStore persistent then
    some {
      checker := checker
      scratch := psKernelC0ScratchBegin persistent
      stagedRoots := []
    }
  else none

/-- Stage source syntax by exact validated readback. This can also stage an
    ill-typed expression; no typing or proof approval follows from storage. -/
def psKernelC0ArchitectureStage
    (work : PsKernelC0ArchitectureWork)
    (expr : PsKernelExpr) : Option PsKernelC0ArchitectureWork := do
  if !psKernelC0ArchitectureWorkValid work then none
  else do
    let (next, id) ← psKernelC0ScratchEncode work.scratch expr
    if !psKernelC0ScratchValid next then none
    else do
      let found ← psKernelC0DecodeExpr next.working id
      if !psKernelExprEqual found expr then none
      else
        some { work with scratch := next
                         stagedRoots := id :: work.stagedRoots }

/-- Candidate preview is an observation. The source checker WHNF remains the
    authority even if the lazy evaluator declines or disagrees. -/
def psKernelC0ArchitecturePreview
    (fuel : Nat)
    (work : PsKernelC0ArchitectureWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelC0ArchitectureWork) := do
  if !psKernelC0ArchitectureWorkValid work then
    throw "invalid candidate architecture transaction"
  let (observation, session) ←
    psKernelC0ObserveWhnf fuel work.checker expr
  return (observation, { work with checker := session })

/-- Environment-aware lazy evaluation is still *observational*:
    checked WHNF runs first and retains exclusive judgment authority.
    No candidate result enters cached source judgments or admission. -/
def psKernelC0ArchitecturePreviewDelta
    (fuel : Nat)
    (work : PsKernelC0ArchitectureWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelC0ArchitectureWork) := do
  if !psKernelC0ArchitectureWorkValid work then
    throw "invalid candidate architecture transaction"
  let (observation, session) ←
    psKernelC0ArchitectureObserveDelta fuel work.checker expr
  return (observation, { work with checker := session })

/-- Source-authoritative structural candidate preview. This observation can
    never populate source WHNF/DefEq caches or admit a declaration. -/
def psKernelC0ArchitecturePreviewStructural
    (fuel : Nat)
    (work : PsKernelC0ArchitectureWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelC0ArchitectureWork) := do
  if !psKernelC0ArchitectureWorkValid work then
    throw "invalid candidate architecture transaction"
  let (observation, session) ←
    psKernelC0ArchitectureObserveStructural fuel work.checker expr
  return (observation, { work with checker := session })

/-- Fuel-accounted, nested-demand candidate preview. The source checker
    WHNF is still the only authoritative observation or cache producer. -/
def psKernelC0ArchitecturePreviewDemand
    (fuel : Nat)
    (work : PsKernelC0ArchitectureWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelC0ArchitectureWork) := do
  if !psKernelC0ArchitectureWorkValid work then
    throw "invalid candidate architecture transaction"
  let (observation, session) ←
    psKernelC0ArchitectureObserveDemand fuel work.checker expr
  return (observation, { work with checker := session })

/-- Opt-in, quota-bounded candidate readback. The trusted source WHNF
    is computed first and remains the only checked session result. A quota
    decline is reported as candidate absence, never rejection of a proof. -/
def psKernelC0ArchitecturePreviewDemandMetered
    (fuel quoteQuota : Nat)
    (work : PsKernelC0ArchitectureWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelC0ExecutionObservation × PsKernelC0ArchitectureWork) := do
  if !psKernelC0ArchitectureWorkValid work then
    throw "invalid candidate architecture transaction"
  let (observation, session) ←
    psKernelC0ArchitectureObserveDemandMetered
      fuel quoteQuota work.checker expr
  return (observation, { work with checker := session })

/-- Typed major observation reuses source K/eta inference and DefEq.
    It is intentionally absent from the declaration-admission constructor
    and cannot approve an expression from a candidate conversion. -/
def psKernelC0ArchitecturePreviewTypedMajor
    (fuel : Nat)
    (work : PsKernelC0ArchitectureWork)
    (recName : PsKernelName)
    (major : PsKernelExpr) :
    Except String (PsKernelC0TypedMajorObservation × PsKernelC0ArchitectureWork) := do
  if !psKernelC0ArchitectureWorkValid work then
    throw "invalid candidate architecture transaction"
  let (observation, session) ←
    psKernelC0ArchitectureObserveTypedMajor fuel work.checker recName major
  return (observation, { work with checker := session })

/-- Phase E authority seam. On failure no next work exists: the caller retains
    the original immutable transaction. No candidate or arena result enters
    the source judgment. -/
def psKernelC0ArchitectureCheckWork
    (fuel : Nat)
    (work : PsKernelC0ArchitectureWork)
    (expr : PsKernelExpr) :
    Except String (PsKernelExpr × PsKernelC0ArchitectureWork) := do
  if !psKernelC0ArchitectureWorkValid work then
    throw "invalid candidate architecture transaction"
  let (ty, session) ← psKernelC0ArchitectureChecked fuel work.checker expr
  return (ty, { work with checker := session })

/-- Atomic selective promotion: unselected scratch nodes never enter the
    persistent result. This returns syntax, not a trusted kernel verdict. -/
def psKernelC0ArchitectureCommitSyntax
    (work : PsKernelC0ArchitectureWork) :
    Option (PsKernelC0TermStore × List PsKernelExpr) := do
  if !psKernelC0ArchitectureWorkValid work then none
  else do
    let (committed, ids) ← psKernelC0ScratchPromoteVerifiedRoots
      work.scratch work.stagedRoots.reverse
    let roots ← ids.mapM (psKernelC0DecodeExpr committed)
    some (committed, roots)

/-- Abort returns the unchanged persistent prefix. -/
def psKernelC0ArchitectureAbort
    (work : PsKernelC0ArchitectureWork) : PsKernelC0TermStore :=
  psKernelC0ScratchAbort work.scratch

/-- Every supported source declaration family is checked atomically by its
    existing source admission operation. Experimental candidate syntax never
    becomes an admission request or proof receipt. -/
inductive PsKernelC0ArchitectureDeclaration where
  | axiomDecl (info : PsKernelAxiomInfo)
  | definition (info : PsKernelDefinitionInfo)
  | theoremDecl (info : PsKernelTheoremInfo)
  | opaqueDecl (info : PsKernelOpaqueInfo)
  | quotient
  | ordinaryInductive (info : PsKernelSimpleInductiveDecl)
  | mutualInductive (info : PsKernelSimpleMutualInductiveDecl)
  | nestedInductive (info : PsKernelSimpleMutualInductiveDecl)

/-- Atomic, checked ordinary/mutual/nested/quotient and declaration admission with mandatory cache invalidation.
    It never publishes a partially checked environment: only existing source
    admission functions can return the next environment. Constructing a fresh
    checker session discards environment-dependent WHNF/DefEq/infer caches.
    Scratch syntax is retained as syntax, not treated as validated judgments. -/
def psKernelC0ArchitectureAdmit
    (fuel : Nat)
    (work : PsKernelC0ArchitectureWork)
    (decl : PsKernelC0ArchitectureDeclaration) :
    Except String PsKernelC0ArchitectureWork := do
  if !psKernelC0ArchitectureWorkValid work then
    throw "invalid candidate architecture transaction"
  let prior := work.checker.context
  let environment := prior.environment
  let next ← match decl with
    | .axiomDecl info =>
        psKernelAddAxiom fuel environment info prior.maxRecDepth prior.maxNatSize
    | .definition info =>
        psKernelAddDefinition fuel environment info prior.maxRecDepth prior.maxNatSize
    | .theoremDecl info =>
        psKernelAddTheorem fuel environment info prior.maxRecDepth prior.maxNatSize
    | .opaqueDecl info =>
        psKernelAddOpaque fuel environment info prior.maxRecDepth prior.maxNatSize
    | .quotient =>
        psKernelAddQuot environment
    | .ordinaryInductive info =>
        psKernelAddSimpleInductive fuel environment info
          prior.maxRecDepth prior.maxNatSize
    | .mutualInductive info =>
        psKernelAddSimpleMutualInductive fuel environment info
          prior.maxRecDepth prior.maxNatSize
    | .nestedInductive info =>
        psKernelAddSimpleNestedInductive fuel environment info
          prior.maxRecDepth prior.maxNatSize
  let newSession := psKernelMkCheckerSession next
    prior.levelParams prior.safety prior.maxRecDepth prior.maxNatSize
  return { work with checker := newSession }
