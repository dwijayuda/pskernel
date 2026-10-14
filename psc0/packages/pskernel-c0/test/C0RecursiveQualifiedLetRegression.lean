import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedRecursiveLetInference

/-!
E.4AB: real source-checked let children use the already proven independent
recursive checker where eligible, with exact source state, errors, resource
bounds and audited root publication. No compiler or self-host work.
-/

def main : IO Unit := do
  let binder : PsKernelName := .str .anonymous "RecursiveCheckedLet"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let valid : PsKernelExpr :=
    .letE binder sort1 sort0 (.bvar 0) false
  let unused : PsKernelExpr :=
    .letE binder sort1 sort0 sort0 true
  let wrong : PsKernelExpr :=
    .letE binder sort0 sort0 (.bvar 0) false
  let invalid : PsKernelExpr :=
    .letE binder sort1 sort0
      (.mvar (.str .anonymous "UnknownLetValue")) false
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "qualified recursive let genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "qualified recursive let certification failed")

  -- All three checked children (annotation, value, opened body) are
  -- independently accepted by the previous recursive inference fragment.
  let some (annotationType, _) :=
      psKernelC0RecursiveCheckedWithFuel
        4095 source.context source.state sort1
    | throw (IO.userError "let annotation independent child declined")
  if !psKernelExprEqual annotationType (.sort (.succ (.succ .zero))) then
    throw (IO.userError "let annotation child type changed")
  let some (valueType, _) :=
      psKernelC0RecursiveCheckedWithFuel
        4095 source.context source.state sort0
    | throw (IO.userError "let value independent child declined")
  if !psKernelExprEqual valueType sort1 then
    throw (IO.userError "let value child type changed")

  for term in [valid, unused] do
    let (ty, checkedState) ← match psKernelC0QualifiedLetHeadWithFuel
        4096 (some psKernelC0CheckAppRecursiveResummarized)
        (psKernelWhnfWithRecursorFuel 4096 (psKernelIsDefEqWithFuel 4096))
        (psKernelIsDefEqWithFuel 4096)
        source.context source.state binder sort1 sort0
        (if psKernelExprEqual term valid then (.bvar 0) else sort0)
        (!psKernelExprEqual term valid) false with
      | .ok result => pure result
      | .error e => throw (IO.userError ("qualified let head failed: " ++ e))
    if !psKernelExprEqual ty sort1 then
      throw (IO.userError "qualified let head changed accepted type")
    let exact ← match psKernelC0CertifiedWorkCheckRecursiveLetOwned
        4096 work term with
      | .ok receipt => pure receipt
      | .error e =>
          throw (IO.userError ("source-refined let receipt failed: " ++ e))
    let _sourceProof :
        psKernelC0CertifiedWorkCheck 4096 work term = .ok exact.val :=
      exact.property
    if !psKernelExprEqual exact.val.fst ty then
      throw (IO.userError "refined let differs from source checker")
    if (psKernelC0RecursiveCheckedWithFuel 1
        source.context source.state term).isSome then
      throw (IO.userError "unqualified recursive let bypassed source fallback")
    if (psKernelExprMapGet checkedState.checkedInfer term).isNone then
      throw (IO.userError "qualified let did not publish checked cache")

  -- Error precedence is retained for wrong type, unknown body, zero fuel
  -- and recursion-budget exhaustion; invalid roots cannot be published.
  for term in [wrong, invalid] do
    match psKernelC0CertifiedWorkCheckRecursiveLetOwned 4096 work term,
          psKernelC0CertifiedWorkCheck 4096 work term with
    | .error actual, .error expected =>
        if actual != expected then
          throw (IO.userError "qualified let changed rejection reason")
    | _, _ => throw (IO.userError "qualified let accepted a bad declaration")
  match psKernelC0CertifiedWorkCheckRecursiveLetOwned 0 work valid,
        psKernelC0CertifiedWorkCheck 0 work valid with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "qualified let changed zero-fuel error")
  | _, _ => throw (IO.userError "qualified let escaped fuel limit")
  let blocked : PsKernelCheckerSession := {
    source with
    context := { source.context with recDepth := 1000000, maxRecDepth := 1 }
  }
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "qualified let blocked genesis failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "qualified let blocked work failed")
  match psKernelC0CertifiedWorkCheckRecursiveLetOwned 4096 blockedWork valid,
        psKernelC0CertifiedWorkCheck 4096 blockedWork valid with
  | .error actual, .error expected =>
      if actual != expected then
        throw (IO.userError "qualified let changed depth-limit error")
  | _, _ => throw (IO.userError "qualified let escaped recursion limit")

  let policy : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      policy psKernelProviderDefault with
    | .ok provider => pure provider
    | .error _ => throw (IO.userError "qualified let provider genesis failed")
  let publication ← match psKernelC0VerifiedProviderPublishRoots
      genesis [valid, unused] with
    | .ok receipt => pure receipt
    | .error _ => throw (IO.userError "qualified let publication failed")
  let _checked := psKernelC0VerifiedProviderPublicationCheckExact publication
  if publication.checked.roots.length != 2 ||
      !(psKernelC0HistoryAxiomSignatures
        publication.staged.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "qualified let changed audited assumptions/roots")
  match psKernelC0VerifiedProviderPublishRoots genesis [valid, wrong] with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "invalid qualified let root published")

  IO.println "C0_REFINED_RECURSIVE_LET source_exact_type_state_and_errors=pass"
  IO.println "C0_REFINED_RECURSIVE_LET independent_children_and_fallback=pass"
  IO.println "C0_REFINED_RECURSIVE_LET verified_atomic_publication=pass"
