import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedRecursiveProjectionInference

/-!
E.4AC: verified projections use independently checked constructor
application major terms and the unchanged source projection validator.
All results carry exact checker-state/source proofs.
-/

private def recProjName (s : String) : PsKernelName :=
  .str .anonymous s

private def recProjBox : PsKernelName :=
  recProjName "RecursiveCheckedProjectionBox"

private def recProjCtor : PsKernelName :=
  .str recProjBox "mk"

private def recProjDecl : PsKernelSimpleInductiveDecl := {
  levelParams := []
  name := recProjBox
  type := .sort (.succ (.succ .zero))
  ctors := [
    {
      name := recProjCtor
      type := .forallE (recProjName "fst")
          (.sort (.succ .zero))
        (.forallE (recProjName "snd")
          (.sort (.succ .zero))
          (.const recProjBox []) .default) .default
    }
  ]
  isUnsafe := false
  numParams := 0
}

def main : IO Unit := do
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let constructor : PsKernelExpr :=
    .app (.app (.const recProjCtor []) sort0) sort0
  let first : PsKernelExpr := .proj recProjBox 0 constructor
  let second : PsKernelExpr := .proj recProjBox 1 constructor
  let invalidIndex : PsKernelExpr := .proj recProjBox 2 constructor
  let invalidFamily : PsKernelExpr :=
    .proj (recProjName "WrongProjectionBox") 0 constructor
  let invalidMajor : PsKernelExpr := .proj recProjBox 0 sort0
  let unknownMajor : PsKernelExpr :=
    .proj recProjBox 0 (.mvar (recProjName "unknownMajor"))

  let start := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 8192 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin start
    | throw (IO.userError "recursive projection genesis failed")
  let admitted ← match psKernelC0ArchitectureAdmit 8192 raw
      (.ordinaryInductive recProjDecl) with
    | .ok next => pure next
    | .error e => throw (IO.userError ("checked structure rejected: " ++ e))
  let some work := psKernelC0ArchitectureCertifyWork admitted
    | throw (IO.userError "admitted projection work failed certification")

  -- The real two-application constructor major term, not fabricated
  -- structure metadata, must be independently typed.
  let some (majorType, _) := psKernelC0RecursiveCheckedWithFuel 8191
      admitted.checker.context admitted.checker.state constructor
    | throw (IO.userError "independent projection major declined")
  if !psKernelExprEqual majorType (.const recProjBox []) then
    throw (IO.userError "independent major returned wrong structure type")

  for (idx, expr) in [(0, first), (1, second)] do
    let result ← match psKernelC0QualifiedProjectionHeadWithFuel 8192
        (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel 8192 (psKernelIsDefEqWithFuel 8192))
        (psKernelIsDefEqWithFuel 8192)
        admitted.checker.context admitted.checker.state
        recProjBox idx constructor false with
      | .ok result => pure result
      | .error e => throw (IO.userError ("refined projection rejected: " ++ e))
    if !psKernelExprEqual result.fst sort1 then
      throw (IO.userError "refined projection field type changed")
    let receipt ← match psKernelC0CertifiedWorkCheckRecursiveProjectionOwned
        8192 work expr with
      | .ok proof => pure proof
      | .error e =>
          throw (IO.userError ("refined projection receipt failed: " ++ e))
    let _source : psKernelC0CertifiedWorkCheck 8192 work expr =
        .ok receipt.val := receipt.property
    if !psKernelExprEqual receipt.val.fst sort1 then
      throw (IO.userError "projection source equation changed field type")
    if (psKernelExprMapGet result.snd.checkedInfer expr).isNone then
      throw (IO.userError "qualified projection omitted source checked cache")

  for expr in [invalidIndex, invalidFamily, invalidMajor, unknownMajor] do
    match psKernelC0CertifiedWorkCheckRecursiveProjectionOwned 8192 work expr,
          psKernelC0CertifiedWorkCheck 8192 work expr with
    | .error actual, .error expected =>
        if actual != expected then
          throw (IO.userError "projection source rejection category changed")
    | _, _ => throw (IO.userError "qualified projection accepted invalid term")
  match psKernelC0CertifiedWorkCheckRecursiveProjectionOwned 0 work first,
        psKernelC0CertifiedWorkCheck 0 work first with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "projection zero-fuel diagnostic changed")
  | _, _ => throw (IO.userError "projection bypassed source zero fuel")
  -- Arbitrarily exhausted original checker recursion must not become
  -- an independent accepted projection or a forged cached result.
  let blocked : PsKernelCheckerSession := {
    admitted.checker with
    context := {
      admitted.checker.context with
      recDepth := 1000000
      maxRecDepth := 1
    }
  }
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "blocked projection source work unavailable")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "blocked projection proof unavailable")
  match psKernelC0CertifiedWorkCheckRecursiveProjectionOwned
          8192 blockedWork first,
        psKernelC0CertifiedWorkCheck 8192 blockedWork first with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "qualified projection changed recursion diagnostic")
  | _, _ => throw (IO.userError "qualified projection bypassed depth guard")

  let policy : PsKernelResourcePolicy := {
    fuel := 8192
    maxRecDepth := 8192
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 32
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      policy psKernelProviderDefault with
    | .ok provider => pure provider
    | .error _ => throw (IO.userError "verified projection genesis failed")
  let verified ← match psKernelC0VerifiedProviderAdmit genesis
      (.ordinaryInductive recProjDecl) with
    | .ok next => pure next
    | .error _ => throw (IO.userError "verified structure admission failed")
  let published ← match psKernelC0VerifiedProviderPublishRoots
      verified [first, second] with
    | .ok receipt => pure receipt
    | .error _ => throw (IO.userError "verified projection publication failed")
  let _proof := psKernelC0VerifiedProviderPublicationCheckExact published
  if published.checked.roots.length != 2 ||
      !(psKernelC0HistoryAxiomSignatures
        published.staged.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "verified projection changed trusted assumptions")
  match psKernelC0VerifiedProviderPublishRoots
      verified [first, invalidIndex] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "invalid field published as checked root")

  IO.println "C0_REFINED_PROJECTION independent_major_source_equivalence=pass"
  IO.println "C0_REFINED_PROJECTION exact_errors_cache_fuel=pass"
  IO.println "C0_REFINED_PROJECTION audited_publication=pass"
