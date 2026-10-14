import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedConstantInference

/-!
Phase E.4M: independently source-exact C0 cached constant infer/check.
This regression distinguishes warm checked cache (independent) from cold
constant/safety/universe lookup (original source authority), and asserts the
checked provider never imports arbitrary raw state.
-/

def main : IO Unit := do
  let safeName : PsKernelName := .str .anonymous "CachedSourceConstant"
  let safeInfo : PsKernelDefinitionInfo := {
    base := {
      name := safeName
      levelParams := []
      type := .sort (.succ .zero)
    }
    value := .sort .zero
    hints := .abbrevHint
    safety := .safe
  }
  let sourceEnv ← match psKernelAddDefinition 4096
      psKernelEnvironmentEmpty safeInfo 4096 psKernelLeanNatMaxSizeDefault with
    | .ok result => pure result
    | .error e => throw (IO.userError ("constant source definition failed: " ++ e))
  let source := psKernelMkCheckerSession sourceEnv
    [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let value : PsKernelExpr := .const safeName []
  let expected : PsKernelExpr := .sort (.succ .zero)
  if (psKernelC0ConstantCachedInferWithFuel 4096
      source.context source.state safeName [] false).isSome then
    throw (IO.userError "cold constant was promoted without source validation")

  let (checkedType, warm) ← match psKernelSessionCheck 4096 source value with
    | .ok result => pure result
    | .error e => throw (IO.userError ("warm source full checking failed: " ++ e))
  if !psKernelExprEqual checkedType expected then
    throw (IO.userError "source admitted wrong constant type")
  let warmDirect := psKernelC0ConstantCachedInferWithFuel
    4096 warm.context warm.state safeName [] false
  match warmDirect with
  | some (ty, checkedState) =>
      if !psKernelExprEqual ty expected ||
          (psKernelExprMapGet checkedState.checkedInfer value).isNone then
        throw (IO.userError "independent checked constant cache diverged")
  | none =>
      throw (IO.userError "independent source cached constant lookup declined")
  if (psKernelC0ConstantCachedInferWithFuel
      4096 warm.context warm.state safeName [] true).isSome then
    throw (IO.userError "checked-only source cache leaked to infer-only lookup")

  let (inferredType, inferred) ← match
      psKernelSessionInfer 4096 source value with
    | .ok result => pure result
    | .error e => throw (IO.userError ("source infer-only warmup failed: " ++ e))
  if !psKernelExprEqual inferredType expected then
    throw (IO.userError "source inferred wrong type for checked constant")
  if (psKernelC0ConstantCachedInferWithFuel
      4096 inferred.context inferred.state safeName [] true).isNone then
    throw (IO.userError "separate source infer-only cache not selected")

  let some beforeRaw := psKernelC0ArchitectureBegin warm
    | throw (IO.userError "warm cached source work construction failed")
  let some work := psKernelC0ArchitectureCertifyWork beforeRaw
    | throw (IO.userError "warm cached work lost certification")
  let checkedReceipt ← match psKernelC0CertifiedWorkCheckWithConstantsOwned
      4096 work value with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("cached source checked receipt failed: " ++ e))
  let _exactCheck :
      psKernelC0CertifiedWorkCheck 4096 work value =
        .ok checkedReceipt.val :=
    checkedReceipt.property
  if !psKernelExprEqual checkedReceipt.val.fst expected then
    throw (IO.userError "direct cached constant returned wrong checked type")
  let some coldRaw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "cold source work construction failed")
  let some coldWork := psKernelC0ArchitectureCertifyWork coldRaw
    | throw (IO.userError "cold work certification failed")
  let coldReceipt ← match psKernelC0CertifiedWorkCheckWithConstantsOwned
      4096 coldWork value with
    | .ok receipt => pure receipt
    | .error e => throw (IO.userError ("cold source fallback failed: " ++ e))
  let _exactColdCheck :
      psKernelC0CertifiedWorkCheck 4096 coldWork value =
        .ok coldReceipt.val :=
    coldReceipt.property
  if !psKernelExprEqual coldReceipt.val.fst expected then
    throw (IO.userError "cold source fallback changed original constant type")

  -- Exact source recursion and fuel exhaustion remain authoritative.
  if (psKernelC0ConstantCachedInferWithFuel 0
      warm.context warm.state safeName [] false).isSome then
    throw (IO.userError "cached constant bypassed zero source fuel")
  match psKernelC0CertifiedWorkCheckWithConstantsOwned 0 work value with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "cached constant accepted zero source fuel")
  let blockedContext : PsKernelCheckerContext := {
    warm.context with maxRecDepth := 1
    recDepth := 1000000
  }
  if (psKernelC0ConstantCachedInferWithFuel
      4096 blockedContext warm.state safeName [] false).isSome then
    throw (IO.userError "cached constant bypassed source recursion depth")

  -- Raw checked caches are constructible at the trusted integration layer;
  -- their contents are NOT independent proof certificates.
  let forgedName : PsKernelName := .str .anonymous "CallerForgedConstant"
  let forgedExpr : PsKernelExpr := .const forgedName []
  let wrongType : PsKernelExpr := .sort (.succ (.succ .zero))
  let forgedState := psKernelCheckerStateWithCheckedInfer
    source.state (psKernelExprMapInsert source.state.checkedInfer forgedExpr wrongType)
  match psKernelC0ConstantCachedInferWithFuel 4096
      source.context forgedState forgedName [] false with
  | some (ty, _) =>
      if !psKernelExprEqual ty wrongType then
        throw (IO.userError "raw source cache compatibility was not preserved")
  | none => throw (IO.userError "raw cache negative fixture was not exercised")

  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin resources
      psKernelProviderDefault with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified cached-constant genesis failed")
  match psKernelC0VerifiedProviderCheck genesis forgedExpr with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified checker imported raw fabricated cache")
  let admitted ← match psKernelC0VerifiedProviderAdmit genesis
      (.definitionDecl safeInfo) with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified provider rejected safe constant")
  let (firstType, afterFirst) ← match psKernelC0VerifiedProviderCheck
      admitted value with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified cold source constant failed")
  let (secondType, afterSecond) ← match psKernelC0VerifiedProviderCheck
      afterFirst value with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified warm source constant failed")
  if !psKernelExprEqual firstType expected ||
      !psKernelExprEqual secondType expected then
    throw (IO.userError "verified constant cold/warm type disagreement")
  if !(psKernelC0HistoryAxiomSignatures
      afterSecond.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "warm checked constant introduced trusted assumption")

  IO.println "C0_CONSTANT_CACHE independent_source_cache_hit_equations=pass"
  IO.println "C0_CONSTANT_CACHE cold_fallback_resource_policy=pass"
  IO.println "C0_CONSTANT_CACHE verified_provider_and_raw_cache_isolation=pass"
