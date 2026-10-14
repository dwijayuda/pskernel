import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedRecursiveInference

/-!
E.4AA: source-exact recursive checked applications, metadata and binders
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
  let nestedMetadata : PsKernelExpr :=
    .mdata 101 (.mdata 102 nestedFn)
  let metadataArgument : PsKernelExpr :=
    .app (.const identity []) nestedMetadata
  let piSimple : PsKernelExpr :=
    .forallE binder sort1 sort1 .default
  let piDependent : PsKernelExpr :=
    .forallE binder sort1
      (.forallE binder (.bvar 0) (.bvar 1) .default) .default
  let piWrapped : PsKernelExpr := .mdata 201 piDependent
  let lambdaSimple : PsKernelExpr :=
    .lam binder sort1 (.bvar 0) .default
  let lambdaDependent : PsKernelExpr :=
    .lam binder sort1
      (.lam binder (.bvar 0) (.bvar 0) .default) .default
  let lambdaApplied : PsKernelExpr := .app lambdaSimple sort0
  let lambdaMetadata : PsKernelExpr := .mdata 211 lambdaApplied
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
    let checked ← match psKernelC0CertifiedWorkCheckRecursiveOwned
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
    let some (qualifiedType, _) := psKernelC0RecursiveCheckedWithFuel
        4096 source.context source.state expr
      | throw (IO.userError "recursive independent app tree declined valid input")
    if !psKernelExprEqual qualifiedType sort1 then
      throw (IO.userError "recursive independent app returned wrong type")
    let some raw := psKernelC0ArchitectureBegin source
      | throw (IO.userError "recursive app checked work unavailable")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "recursive app checked work not certified")
    let receipt ← match psKernelC0CertifiedWorkCheckRecursiveOwned
        4096 work expr with
      | .ok value => pure value
      | .error e =>
          throw (IO.userError ("recursive checked app proof failed: " ++ e))
    let _source :
        psKernelC0CertifiedWorkCheck 4096 work expr = .ok receipt.val :=
      receipt.property
    if !psKernelExprEqual receipt.val.fst sort1 then
      throw (IO.userError "recursive app source equation changed type")
    if (psKernelC0RecursiveCheckedWithFuel 1
        source.context source.state expr).isSome then
      throw (IO.userError "recursive app bypassed nested fuel accounting")

  -- This family was previously declined because metadata terminated at
  -- an application rather than a scalar/local/constant. Each wrapper must
  -- charge one source fuel/depth step and publish the checked outer cache.
  for expr in [nestedMetadata, metadataArgument] do
    if (psKernelC0MetadataInferWithFuel 4096
        source.context source.state expr false).isSome then
      throw (IO.userError "old metadata-only fragment unexpectedly qualified app")
    let some (qualifiedType, qualifiedState) :=
        psKernelC0RecursiveCheckedWithFuel
          4096 source.context source.state expr
      | throw (IO.userError "metadata-wrapped app tree unexpectedly declined")
    if !psKernelExprEqual qualifiedType sort1 then
      throw (IO.userError "metadata-wrapped independent app has wrong type")
    if (psKernelExprMapGet qualifiedState.checkedInfer nestedMetadata).isNone then
      throw (IO.userError "metadata app lost exact outer checked cache")
    let some raw := psKernelC0ArchitectureBegin source
      | throw (IO.userError "metadata app source work unavailable")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "metadata app canonical work unavailable")
    let proof ← match psKernelC0CertifiedWorkCheckRecursiveOwned
        4096 work expr with
      | .ok value => pure value
      | .error e => throw (IO.userError ("metadata independent app failed: " ++ e))
    let _exact :
        psKernelC0CertifiedWorkCheck 4096 work expr = .ok proof.val :=
      proof.property
    if !psKernelExprEqual proof.val.fst sort1 then
      throw (IO.userError "metadata source type mismatch")
    if (psKernelC0RecursiveCheckedWithFuel 1
        source.context source.state expr).isSome then
      throw (IO.userError "metadata app bypassed fuel")

  -- Checked Pi formation is recursively qualified without historical
  -- inference for either the domain or opened body, including a dependent
  -- domain/body under two successive fresh local contexts.
  for expr in [piSimple, piDependent, piWrapped] do
    let some (qualifiedType, _) := psKernelC0RecursiveCheckedWithFuel
        4096 source.context source.state expr
      | throw (IO.userError "independent recursive Pi formation declined")
    let (sourceType, _) ← match psKernelCheckerCheck
        4096 source.context source.state expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("source Pi check failed: " ++ e))
    if !psKernelExprEqual qualifiedType sourceType then
      throw (IO.userError "independent dependent Pi type changed")
    let some raw := psKernelC0ArchitectureBegin source
      | throw (IO.userError "dependent Pi source genesis failed")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "dependent Pi certified work unavailable")
    let checked ← match psKernelC0CertifiedWorkCheckRecursiveOwned
        4096 work expr with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("dependent Pi check failed: " ++ e))
    let _sourceEquation :
        psKernelC0CertifiedWorkCheck 4096 work expr = .ok checked.val :=
      checked.property
    if !psKernelExprEqual checked.val.fst sourceType then
      throw (IO.userError "dependent Pi exact source receipt changed type")
    if (psKernelC0RecursiveCheckedWithFuel 1
        source.context source.state expr).isSome then
      throw (IO.userError "dependent Pi bypassed recursive fuel")

  -- The independent checker opens real local binders, validates
  -- domain sorts and recursively checks lambda bodies, including
  -- dependent nested lambdas whose second domain is the outer local.
  for expr in [lambdaSimple, lambdaDependent, lambdaApplied,
      lambdaMetadata] do
    let some (qualifiedType, _) := psKernelC0RecursiveCheckedWithFuel
        4096 source.context source.state expr
      | throw (IO.userError "independent recursive lambda declined")
    let (sourceType, _) ← match psKernelCheckerCheck
        4096 source.context source.state expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("source lambda failed: " ++ e))
    if !psKernelExprEqual qualifiedType sourceType then
      throw (IO.userError "independent lambda result differs from source")
    let some raw := psKernelC0ArchitectureBegin source
      | throw (IO.userError "independent lambda genesis failed")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "independent lambda certification failed")
    let proof ← match psKernelC0CertifiedWorkCheckRecursiveOwned
        4096 work expr with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("independent lambda checked error: " ++ e))
    let _exact :
        psKernelC0CertifiedWorkCheck 4096 work expr = .ok proof.val :=
      proof.property
    if !psKernelExprEqual proof.val.fst sourceType then
      throw (IO.userError "independent lambda source receipt diverged")
    if (psKernelC0RecursiveCheckedWithFuel 1
        source.context source.state expr).isSome then
      throw (IO.userError "independent lambda bypassed child fuel")

  -- The original source binder-spine accelerator has different
  -- operation-local frame semantics on long lambda/Pi prefixes. The
  -- independent checker must decline rather than reconstruct guesses.
  let mut longLambda : PsKernelExpr := sort0
  let mut longPi : PsKernelExpr := sort0
  for _ in [:12] do
    longLambda := .lam binder sort1 longLambda .default
    longPi := .forallE binder sort1 longPi .default
  for expr in [longLambda, longPi] do
    if (psKernelC0RecursiveCheckedWithFuel
        4096 source.context source.state expr).isSome then
      throw (IO.userError "independent checker bypassed long binder guard")
    let some raw := psKernelC0ArchitectureBegin source
      | throw (IO.userError "long binder genesis failed")
    let some work := psKernelC0ArchitectureCertifyWork raw
      | throw (IO.userError "long binder certified work unavailable")
    let original ← match psKernelC0CertifiedWorkCheck 4096 work expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("source long binder failed: " ++ e))
    let accepted ← match psKernelC0CertifiedWorkCheckRecursiveOwned
        4096 work expr with
      | .ok proof => pure proof
      | .error e => throw (IO.userError ("qualified fallback long binder failed: " ++ e))
    let _exact :
        psKernelC0CertifiedWorkCheck 4096 work expr = .ok accepted.val :=
      accepted.property
    if !psKernelExprEqual original.fst accepted.val.fst then
      throw (IO.userError "long binder fallback changed checked type")

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
    match psKernelC0CertifiedWorkCheckRecursiveOwned 4096 work bad,
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
      admittedCurry [application, wrapped, nestedFn, nestedArg,
        nestedMetadata, metadataArgument, piSimple, piDependent, piWrapped,
        lambdaSimple, lambdaDependent, lambdaApplied, lambdaMetadata] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "independent app root publication failed")
  let _exactPublication :=
    psKernelC0VerifiedProviderPublicationCheckExact publication
  if publication.checked.roots.length != 13 ||
      !(psKernelC0HistoryAxiomSignatures
        publication.staged.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "independent app weakened atomic audited roots")

  IO.println "C0_INDEPENDENT_CHECKED_APP two_independent_child_judgments=pass"
  IO.println "C0_RECURSIVE_CHECKED_APP function_argument_trees_source_proved=pass"
  IO.println "C0_RECURSIVE_CHECKED_METADATA wrapped_application_trees_source_proved=pass"
  IO.println "C0_RECURSIVE_CHECKED_PI dependent_binders_and_source_states=pass"
  IO.println "C0_RECURSIVE_CHECKED_LAMBDA dependent_local_bodies_and_applications=pass"
  IO.println "C0_RECURSIVE_CHECKED_BINDERS long_spines_original_source_fallback=pass"
  IO.println "C0_INDEPENDENT_CHECKED_APP exact_source_errors_states_fuel=pass"
  IO.println "C0_INDEPENDENT_CHECKED_APP audited_publication=pass"
