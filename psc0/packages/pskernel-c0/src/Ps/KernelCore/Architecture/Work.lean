import Ps.KernelCore.Architecture.Execution
import Ps.KernelCore.Core.IndexedScratch

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
