import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedApplicationInference

/-!
Phase E.4T native conformance for independently selected full CHECKED and
INFER-ONLY application heads.

The same full source-checked app rule is used with exact result/state
equations, including Pi domain equality, eager reduction, dependent
instantiation, checked-argument validation and ≥16-argument source hook.
Infer-only caching is NOT full proof validation. Atomic root publication
still requires original source checking and audited checked-state lineage.
-/

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "CheckedApp"
  let sort0 : PsKernelExpr := .sort .zero
  let dependent : PsKernelExpr :=
    .forallE name sort0 (.bvar 0) .default
  let lambda : PsKernelExpr := .lam name sort0 (.bvar 0) .default
  let valid : PsKernelExpr := .app lambda dependent
  let mismatched : PsKernelExpr := .app lambda sort0
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "direct app source genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "direct app source work certificate failed")

  let checked ← match psKernelC0CertifiedWorkCheckAppOwned 4096 work valid with
    | .ok proof => pure proof
    | .error e => throw (IO.userError ("direct checked app failed: " ++ e))
  let _sourceChecked :
      psKernelC0CertifiedWorkCheck 4096 work valid =
        .ok checked.val :=
    checked.property
  if !psKernelExprEqual checked.val.fst sort0 then
    throw (IO.userError "direct app returned incorrect checked type")
  let inferred ← match psKernelC0CertifiedWorkInferAppOwned 4096 work valid with
    | .ok proof => pure proof
    | .error e => throw (IO.userError ("direct infer-only app failed: " ++ e))
  let _sourceInfer :
      psKernelC0CertifiedWorkInfer 4096 work valid =
        .ok inferred.val :=
    inferred.property
  if !psKernelExprEqual inferred.val.fst sort0 then
    throw (IO.userError "infer-only app type changed source result")
  if (psKernelExprMapGet
      inferred.val.snd.raw.checker.state.inferOnly valid).isNone ||
      (psKernelExprMapGet
        checked.val.snd.raw.checker.state.checkedInfer valid).isSome then
    throw (IO.userError "direct app mixed infer-only and checked cache policy")

  let mut fn : PsKernelExpr := dependent
  for _ in [:16] do
    fn := .lam name sort0 fn .default
  let mut longApp : PsKernelExpr := fn
  for _ in [:16] do
    longApp := .app longApp dependent
  let longChecked ← match psKernelC0CertifiedWorkCheckAppOwned
      4096 work longApp with
    | .ok proof => pure proof
    | .error e => throw (IO.userError ("direct long checked app failed: " ++ e))
  let _longSource :
      psKernelC0CertifiedWorkCheck 4096 work longApp =
        .ok longChecked.val :=
    longChecked.property
  if !psKernelExprEqual longChecked.val.fst sort0 then
    throw (IO.userError "direct checked app long spine changed source type")
  let longInferred ← match psKernelC0CertifiedWorkInferAppOwned
      4096 work longApp with
    | .ok proof => pure proof
    | .error e => throw (IO.userError ("direct infer-only app spine failed: " ++ e))
  let _longInferSource :
      psKernelC0CertifiedWorkInfer 4096 work longApp =
        .ok longInferred.val :=
    longInferred.property

  -- Checked mismatches retain EXACT source rejection text, whereas an
  -- infer-only exposed result is not by itself proof of validity.
  match psKernelC0CertifiedWorkCheckAppOwned 4096 work mismatched,
        psKernelC0CertifiedWorkCheck 4096 work mismatched with
  | .error left, .error right =>
      if left != right then
        throw (IO.userError "checked app source error classification changed")
  | _, _ => throw (IO.userError "application mismatch bypassed full checker")
  for term in [valid, longApp] do
    match psKernelC0CertifiedWorkCheckAppOwned 0 work term,
          psKernelC0CertifiedWorkCheck 0 work term with
    | .error left, .error right =>
        if left != right then
          throw (IO.userError "checked app source zero-fuel error changed")
    | _, _ => throw (IO.userError "direct app bypassed zero source fuel")
  let blocked : PsKernelCheckerSession := {
    source with
    context := {
      source.context with
      maxRecDepth := 1
      recDepth := 1000000
    }
  }
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "app blocked source work failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "app blocked checked work failed")
  match psKernelC0CertifiedWorkCheckAppOwned 4096 blockedWork valid,
        psKernelC0CertifiedWorkCheck 4096 blockedWork valid with
  | .error left, .error right =>
      if left != right then
        throw (IO.userError "checked app recursion error changed")
  | _, _ => throw (IO.userError "direct checked app bypassed source depth")

  -- Low-level raw infer-only cache contents are NOT proof certificates.
  -- A source-equivalent behavior for that raw input is retained but the
  -- public provider never imports an arbitrary poisoned session.
  let bogus : PsKernelExpr :=
    .app (.const (.str .anonymous "ForgedAppFunction") []) dependent
  let forgedState := psKernelCheckerStateWithInferOnly source.state
    (psKernelExprMapInsert source.state.inferOnly bogus sort0)
  match psKernelC0AppInferOnlyWithFuel 4096
      (psKernelWhnfWithRecursorFuel 4096 (psKernelIsDefEqWithFuel 4096))
      (psKernelIsDefEqWithFuel 4096)
      source.context forgedState
      (.const (.str .anonymous "ForgedAppFunction") []) dependent with
  | .ok (ty, _) =>
      if !psKernelExprEqual ty sort0 then
        throw (IO.userError "raw poisoned infer cache fidelity changed")
  | .error _ => throw (IO.userError "raw cached app source fixture declined")

  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok work => pure work
    | .error _ => throw (IO.userError "direct app verified genesis failed")
  let (checkedTy, _) ← match psKernelC0VerifiedProviderCheck genesis valid with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified direct app checking declined")
  if !psKernelExprEqual checkedTy sort0 then
    throw (IO.userError "verified direct app type was altered")
  match psKernelC0VerifiedProviderCheck genesis bogus with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider imported raw app cache")
  let published ← match psKernelC0VerifiedProviderPublishRoots
      genesis [valid, longApp] with
    | .ok result => pure result
    | .error _ => throw (IO.userError "checked application publication failed")
  let _exactSource :=
    psKernelC0VerifiedProviderPublicationCheckExact published
  if published.checked.roots.length != 2 then
    throw (IO.userError "verified app checked publication lost roots")
  match psKernelC0VerifiedProviderPublishRoots genesis [valid, mismatched] with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "verified app source allowed partial bad publication")
  if !(psKernelC0HistoryAxiomSignatures
      published.staged.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "direct app inserted a trusted assumption")

  IO.println "C0_APP_QUALIFIED checked_infer_only_exact_source_states=pass"
  IO.println "C0_APP_QUALIFIED long_app_spines_resource_and_cache_fidelity=pass"
  IO.println "C0_APP_QUALIFIED verified_atomic_publication_and_poison_isolation=pass"
