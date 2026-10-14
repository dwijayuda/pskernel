import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedInferenceDispatch

/-!
One closed-form source-exact inference/checking dispatch.

The successful direct heads are scalar Sort, Nat/String literals, local FVar,
and source-warmed constant cache entries. Everything else (including cold
constants) takes exactly one source fallback. Every successful checked result
carries the full source-operation equality and preserves its cache state.
-/

def main : IO Unit := do
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "head dispatch source genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "head dispatch work certification failed")
  let sort0 : PsKernelExpr := .sort .zero
  let nat : PsKernelExpr := .lit (.nat 8)
  let str : PsKernelExpr := .lit (.str "σ🚀")
  let scalar : List (PsKernelExpr × PsKernelExpr) := [
    (sort0, .sort (.succ .zero)),
    (nat, .const psKernelNatName []),
    (str, .const psKernelStringName [])
  ]
  for (expr, expected) in scalar do
    if (psKernelC0QualifiedInferHeadWithFuel 4096
        source.context source.state expr false).isNone then
      throw (IO.userError "selected scalar head was not handled directly")
    let checked ← match psKernelC0CertifiedWorkCheckDirectOwned 4096 work expr with
      | .ok receipt => pure receipt
      | .error e => throw (IO.userError ("direct scalar checked failed: " ++ e))
    let _eq : psKernelC0CertifiedWorkCheck 4096 work expr =
      .ok checked.val := checked.property
    if !psKernelExprEqual checked.val.fst expected then
      throw (IO.userError "direct scalar source-equivalent type changed")

  -- An explicitly source-owned local is checked by the same unified
  -- dispatcher; the provider without that local still rejects it.
  let localName : PsKernelName := .str .anonymous "UnifiedLocal"
  let localExpr : PsKernelExpr := .fvar localName
  let locals := psKernelLocalContextAddLocal source.context.localContext
    localName localName sort0 .default
  let localSession : PsKernelCheckerSession := {
    source with
    context := psKernelCheckerContextWithLocalContext source.context locals
  }
  let some localRaw := psKernelC0ArchitectureBegin localSession
    | throw (IO.userError "local dispatch source snapshot failed")
  let some localWork := psKernelC0ArchitectureCertifyWork localRaw
    | throw (IO.userError "local dispatch work snapshot failed")
  let checkedLocal ← match psKernelC0CertifiedWorkCheckDirectOwned
      4096 localWork localExpr with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("direct local checked failed: " ++ e))
  let _localEq : psKernelC0CertifiedWorkCheck 4096 localWork localExpr =
    .ok checkedLocal.val := checkedLocal.property
  if !psKernelExprEqual checkedLocal.val.fst sort0 then
    throw (IO.userError "unified direct source local type mismatch")

  -- Safe constant has to be admitted by the original checker first.
  -- Cold lookup must not be mistaken for a proven direct cache hit.
  let constName : PsKernelName := .str .anonymous "UnifiedCheckedDefinition"
  let constInfo : PsKernelDefinitionInfo := {
    base := {
      name := constName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := sort0
    hints := .abbrevHint
    safety := .safe
  }
  let env ← match psKernelAddDefinition 4096
      psKernelEnvironmentEmpty constInfo 4096 psKernelLeanNatMaxSizeDefault with
    | .ok result => pure result
    | .error e => throw (IO.userError ("dispatch source admission failed: " ++ e))
  let constantSession := psKernelMkCheckerSession env
    [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let constant : PsKernelExpr := .const constName []
  if (psKernelC0QualifiedInferHeadWithFuel 4096
      constantSession.context constantSession.state constant false).isSome then
    throw (IO.userError "cold constant bypassed source checking")
  let (constantType, warm) ← match psKernelSessionCheck
      4096 constantSession constant with
    | .ok value => pure value
    | .error e => throw (IO.userError ("source warm constant failed: " ++ e))
  if (psKernelC0QualifiedInferHeadWithFuel 4096
      warm.context warm.state constant false).isNone then
    throw (IO.userError "warm constant did not use unified direct cache")
  let some warmRaw := psKernelC0ArchitectureBegin warm
    | throw (IO.userError "warm constant source snapshot failed")
  let some warmWork := psKernelC0ArchitectureCertifyWork warmRaw
    | throw (IO.userError "warm constant certified snapshot failed")
  let warmed ← match psKernelC0CertifiedWorkCheckDirectOwned
      4096 warmWork constant with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("unified warm constant failed: " ++ e))
  let _warmEq : psKernelC0CertifiedWorkCheck 4096 warmWork constant =
    .ok warmed.val := warmed.property
  if !psKernelExprEqual warmed.val.fst constantType then
    throw (IO.userError "warm checked constant type differs from source")

  -- The source checker owns all context-sensitive terms and exact errors.
  let notQualified : PsKernelExpr :=
    .app (.lam (.str .anonymous "x") sort0 (.bvar 0) .default) sort0
  if (psKernelC0QualifiedInferHeadWithFuel 4096
      source.context source.state notQualified false).isSome then
    throw (IO.userError "context-sensitive app was incorrectly direct")
  let result := psKernelC0CertifiedWorkCheckDirectOwned
    4096 work notQualified
  match result with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "unchecked application bypassed full checking")
  if (psKernelC0QualifiedInferHeadWithFuel 0
      source.context source.state sort0 false).isSome then
    throw (IO.userError "unified direct head bypassed zero source fuel")
  match psKernelC0CertifiedWorkCheckDirectOwned 0 work sort0 with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "source error was changed into direct check")

  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok value => pure value
    | .error _ => throw (IO.userError "verified direct genesis failed")
  match psKernelC0VerifiedProviderCheck genesis localExpr with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider imported low-level local state")
  let admitted ← match psKernelC0VerifiedProviderAdmit
      genesis (.definitionDecl constInfo) with
    | .ok next => pure next
    | .error _ => throw (IO.userError "verified source constant admission failed")
  let (ty, afterCheck) ← match psKernelC0VerifiedProviderCheck
      admitted constant with
    | .ok next => pure next
    | .error _ => throw (IO.userError "verified source constant checking failed")
  if !psKernelExprEqual ty constantType ||
      !(psKernelC0HistoryAxiomSignatures
        afterCheck.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "unified verified checked result altered trust foundation")

  IO.println "C0_INFER_DISPATCH single_source_proved_head_selection=pass"
  IO.println "C0_INFER_DISPATCH cold_contextual_source_fallback=pass"
  IO.println "C0_INFER_DISPATCH checked_provider_state_and_error_equivalence=pass"
