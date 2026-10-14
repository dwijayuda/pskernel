import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedIndependentCheckedApp

/-!
E.4W: prove source-exact checked application with BOTH children inferred
without the historical recursive source worker. Unsupported applications
remain exclusively source checked. No new assumptions or unchecked roots.
-/

def main : IO Unit := do
  let binder : PsKernelName := .str .anonymous "IndependentAppBinder"
  let identity : PsKernelName := .str .anonymous "IndependentAppId"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let idType : PsKernelExpr := .forallE binder sort1 sort1 .default
  let idValue : PsKernelExpr := .lam binder sort1 (.bvar 0) .default
  let info : PsKernelDefinitionInfo := {
    base := { name := identity, levelParams := [], type := idType }
    value := idValue
    hints := .abbrevHint
    safety := .safe
  }
  let curry : PsKernelName := .str .anonymous "IndependentCurriedApp"
  let curryType : PsKernelExpr :=
    .forallE binder sort1 (.forallE binder sort1 sort1 .default) .default
  let curryValue : PsKernelExpr :=
    .lam binder sort1 (.lam binder sort1 (.bvar 1) .default) .default
  let curryInfo : PsKernelDefinitionInfo := {
    base := { name := curry, levelParams := [], type := curryType }
    value := curryValue
    hints := .abbrevHint
    safety := .safe
  }
  let firstEnv ← match psKernelAddDefinition 4096 psKernelEnvironmentEmpty
      info 4096 psKernelLeanNatMaxSizeDefault with
    | .ok result => pure result
    | .error e =>
        throw (IO.userError ("independent checked app setup failed: " ++ e))
  let env ← match psKernelAddDefinition 4096 firstEnv
      curryInfo 4096 psKernelLeanNatMaxSizeDefault with
    | .ok result => pure result
    | .error e =>
        throw (IO.userError ("curried checked app setup failed: " ++ e))
  let source := psKernelMkCheckerSession env []
    .safe 4096 psKernelLeanNatMaxSizeDefault
  let application : PsKernelExpr := .app (.const identity []) sort0
  let wrapped : PsKernelExpr :=
    .app (.mdata 7 (.const identity [])) (.mdata 8 sort0)
  let nestedFn : PsKernelExpr :=
    .app (.app (.const curry []) sort0) sort0
  let nestedArg : PsKernelExpr :=
    .app (.const identity []) (.app (.const identity []) sort0)
  for expr in [application, wrapped] do
    let (.app fn arg) := expr
      | throw (IO.userError "independent checked app malformed test")
    let some (independentType, _) := psKernelC0CheckedAppLeafWithFuel
        4096 source.context source.state fn arg
      | throw (IO.userError "valid independent checked children declined")
    if !psKernelExprEqual independentType sort1 then
      throw (IO.userError "independent checked app computed wrong type")
    let some raw := psKernelC0ArchitectureBegin source
      | throw (IO.userError "independent checked app work failed")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "independent checked app certification failed")
    let checked ← match psKernelC0CertifiedWorkCheckIndependentAppOwned
        4096 work expr with
      | .ok proof => pure proof
      | .error e => throw (IO.userError ("checked receipt failed: " ++ e))
    let _exact :
        psKernelC0CertifiedWorkCheck 4096 work expr = .ok checked.val :=
      checked.property
    if !psKernelExprEqual checked.val.fst sort1 then
      throw (IO.userError "certified independent app type differs from source")
    let sourceChecked ← match psKernelCheckerCheck
        4096 source.context source.state expr with
      | .ok value => pure value
      | .error e => throw (IO.userError ("source comparison failed: " ++ e))
    if !psKernelExprEqual sourceChecked.fst independentType then
      throw (IO.userError "independent child inference differs from source")
    if (psKernelC0CheckedAppLeafWithFuel 0
        source.context source.state fn arg).isSome then
      throw (IO.userError "independent checked app bypassed zero fuel")
    let blocked : PsKernelCheckerContext := {
      source.context with recDepth := 1000000, maxRecDepth := 1
    }
    if (psKernelC0CheckedAppLeafWithFuel 4096
        blocked source.state fn arg).isSome then
      throw (IO.userError "independent checked app bypassed recursion bounds")

  -- Actual application trees need the independent recursive checker
  -- on BOTH function and argument subtrees; the former leaf-only
  -- fragment must correctly decline rather than skip checked children.
  for expr in [nestedFn, nestedArg] do
    let (.app fn arg) := expr
      | throw (IO.userError "recursive app fixture is not an application")
    if (psKernelC0CheckedAppLeafWithFuel 4096
        source.context source.state fn arg).isSome then
      throw (IO.userError "old shallow app path unexpectedly checked nested tree")
    let some (qualifiedType, _) := psKernelC0RecursiveCheckedAppWithFuel
        4096 source.context source.state expr
      | throw (IO.userError "recursive independent app tree declined valid input")
    if !psKernelExprEqual qualifiedType sort1 then
      throw (IO.userError "recursive independent app returned wrong type")
    let some raw := psKernelC0ArchitectureBegin source
      | throw (IO.userError "recursive app checked work unavailable")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "recursive app checked work not certified")
    let receipt ← match psKernelC0CertifiedWorkCheckIndependentAppOwned
        4096 work expr with
      | .ok value => pure value
      | .error e =>
          throw (IO.userError ("recursive checked app proof failed: " ++ e))
    let _source :
        psKernelC0CertifiedWorkCheck 4096 work expr = .ok receipt.val :=
      receipt.property
    if !psKernelExprEqual receipt.val.fst sort1 then
      throw (IO.userError "recursive app source equation changed type")
    if (psKernelC0RecursiveCheckedAppWithFuel 1
        source.context source.state expr).isSome then
      throw (IO.userError "recursive app bypassed nested fuel accounting")

  let mismatch : PsKernelExpr :=
    .app (.const identity []) sort1
  let unknown : PsKernelExpr :=
    .app (.const (.str .anonymous "UnknownFunction") []) sort0
  for bad in [mismatch, unknown] do
    let (.app fn arg) := bad
      | throw (IO.userError "invalid checked app malformed")
    if (psKernelC0CheckedAppLeafWithFuel 4096
        source.context source.state fn arg).isSome then
      throw (IO.userError "independent app accepted invalid child")
    let some raw := psKernelC0ArchitectureBegin source
      | throw (IO.userError "negative checked app source setup failed")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "negative checked app source proof failed")
    match psKernelC0CertifiedWorkCheckIndependentAppOwned 4096 work bad,
          psKernelC0CertifiedWorkCheck 4096 work bad with
    | .error observed, .error authoritative =>
        if observed != authoritative then
          throw (IO.userError "invalid app error classification changed")
    | _, _ => throw (IO.userError "invalid checked app was accepted")

  let policy : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 16
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      policy psKernelProviderDefault with
    | .ok session => pure session
    | .error _ => throw (IO.userError "independent app provider genesis failed")
  let admitted ← match psKernelC0VerifiedProviderAdmit
      genesis (.definitionDecl info) with
    | .ok session => pure session
    | .error _ => throw (IO.userError "independent app provider admission failed")
  let admittedCurry ← match psKernelC0VerifiedProviderAdmit
      admitted (.definitionDecl curryInfo) with
    | .ok session => pure session
    | .error _ => throw (IO.userError "curried provider admission failed")
  let (type, _) ← match psKernelC0VerifiedProviderCheck
      admittedCurry application with
    | .ok result => pure result
    | .error _ => throw (IO.userError "independent app provider checked rejection")
  if !psKernelExprEqual type sort1 then
    throw (IO.userError "independent app provider type wrong")
  match psKernelC0VerifiedProviderCheck admittedCurry mismatch with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "provider accepted mismatched app")
  let publication ← match psKernelC0VerifiedProviderPublishRoots
      admittedCurry [application, wrapped, nestedFn, nestedArg] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "independent app root publication failed")
  let _exactPublication :=
    psKernelC0VerifiedProviderPublicationCheckExact publication
  if publication.checked.roots.length != 4 ||
      !(psKernelC0HistoryAxiomSignatures
        publication.staged.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "independent app weakened atomic audited roots")

  IO.println "C0_INDEPENDENT_CHECKED_APP two_independent_child_judgments=pass"
  IO.println "C0_RECURSIVE_CHECKED_APP function_argument_trees_source_proved=pass"
  IO.println "C0_INDEPENDENT_CHECKED_APP exact_source_errors_states_fuel=pass"
  IO.println "C0_INDEPENDENT_CHECKED_APP audited_publication=pass"
