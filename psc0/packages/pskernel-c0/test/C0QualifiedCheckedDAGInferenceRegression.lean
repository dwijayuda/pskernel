import Ps.KernelCore.Architecture.QualifiedCheckedDAGInference

/-!
Executable independent, source-proof-backed checked inference for bounded
canonical DAG roots. We must exercise a successful recursive app/lambda
family, ordinary source fallback and negative/resource behavior.
-/

def main : IO Unit := do
  let binder : PsKernelName := .str .anonymous "independent"
  let sortZero : PsKernelExpr := .sort .zero
  let sortOne : PsKernelExpr := .sort (.succ .zero)
  let identity : PsKernelExpr :=
    .lam binder sortOne (.bvar 0) .default
  let application : PsKernelExpr := .app identity sortZero
  let bad : PsKernelExpr := .bvar 0
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let initial := psKernelC0IndexedSessionNew source
  let some withApp := psKernelC0IndexedSessionRetain initial application
    | throw (IO.userError "qualified DAG: application syntax retention failed")
  let some withBad := psKernelC0IndexedSessionRetain withApp bad
    | throw (IO.userError "qualified DAG: malformed syntax retention failed")
  let some (_, appId) := psKernelC0EncodeExpr withBad.store application
    | throw (IO.userError "qualified DAG: missing canonical application ID")
  let some (_, badId) := psKernelC0EncodeExpr withBad.store bad
    | throw (IO.userError "qualified DAG: missing canonical bvar ID")

  if !psKernelC0QualifiedDAGCandidateEligible application then
    throw (IO.userError "qualified DAG: small recursive app incorrectly declined")
  let some independent := psKernelC0RecursiveCheckedWithFuel
      4096 source.context source.state application
    | throw (IO.userError "qualified DAG: independent recursive app declined")
  let sourceApp ← match psKernelCheckerCheck
      4096 source.context source.state application with
    | .ok result => pure result
    | .error reason => throw (IO.userError
        ("qualified DAG: authoritative valid app declined: " ++ reason))
  if !psKernelExprEqual independent.1 sourceApp.1 then
    throw (IO.userError "qualified DAG: independently inferred wrong application type")

  let some owner := psKernelC0CertifyStore withBad.store
    | throw (IO.userError "qualified DAG: input store certification failed")
  let checked ← match psKernelC0ScopedQualifiedDAGCapture
      owner 4096 source.context source.state appId with
    | .ok value => pure value
    | .error reason => throw (IO.userError
        ("qualified DAG: checked recursive root failed: " ++ reason))
  let _sourceEquation :
      psKernelCheckerCheck 4096 source.context source.state
        checked.val.expression =
          .ok (checked.val.inferredType, checked.val.finalState) :=
    checked.val.source
  if !psKernelExprEqual checked.val.inferredType sourceApp.1 then
    throw (IO.userError "qualified DAG: checked root type/source discrepancy")

  let run ← match psKernelC0IndexedSessionCheckQualifiedTrace
      4096 withBad [appId, appId] with
    | .ok value => pure value
    | .error reason => throw (IO.userError
        ("qualified DAG: state-threaded independent trace failed: " ++ reason))
  let _exactStore : run.owner.store = withBad.store := run.ownerExact
  let _exactFold :
      psKernelC0IndexedDAGReferenceFold run.owner 4096
        withBad.checker.context
        (psKernelC0CheckedDAGTraceIds run.checkedTrace)
        withBad.checker.state = .ok run.finalState :=
    psKernelC0CertifiedIndexedSourceRun_source run
  if psKernelC0CheckedDAGTraceIds run.checkedTrace != [appId, appId] then
    throw (IO.userError "qualified DAG: returned wrong source handle trace")
  match psKernelC0IndexedSessionCheckQualifiedTrace 4096 withBad [appId, badId] with
  | .ok _ => throw (IO.userError
      "qualified DAG: invalid second root was accepted")
  | .error _ => pure ()
  match psKernelC0IndexedSessionCheckQualifiedTrace 0 withBad [appId] with
  | .ok _ => throw (IO.userError "qualified DAG: zero fuel was accepted")
  | .error _ => pure ()
  match psKernelC0IndexedSessionCheckQualifiedTrace 4096 withBad
      [appId, withBad.store.nodes.size + 9] with
  | .ok _ => throw (IO.userError
      "qualified DAG: missing node was accepted")
  | .error _ => pure ()

  let hugeSyntax := (List.range 2100).foldl
    (fun e (_ : Nat) => PsKernelExpr.mdata 1 e) sortZero
  if psKernelC0QualifiedDAGCandidateEligible hugeSyntax then
    throw (IO.userError
      "qualified DAG: expanded syntax quota failed to decline huge candidate")
  IO.println "C0_QUALIFIED_DAG independent_recursive_app=pass exact_source=pass ordered_states=pass resource_and_invalid=declined bounded_candidate=pass"
