import Ps.KernelCore.API.VerifiedProvider

/-!
E.4AK: checked-source-equivalent reflection through independently
evaluated multi-step beta/zeta/delta WHNF, with source budget/cache
and verified-provider typing boundaries preserved.
-/
def main : IO Unit := do
  let x : PsKernelName := .str .anonymous "ReflectionBinder"
  let ty : PsKernelExpr := .sort (.succ .zero)
  let trueExpr : PsKernelExpr := .const psKernelBoolTrueName []
  let id : PsKernelExpr := .lam x ty (.bvar 0) .default
  let basic : PsKernelExpr := .app id trueExpr
  let nested : PsKernelExpr := .app id (.app id trueExpr)
  let zeta : PsKernelExpr :=
    .app id (.letE x ty trueExpr (.bvar 0) false)
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "reflected WHNF DefEq genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "reflected WHNF DefEq certification failed")
  for left in [basic, nested, zeta] do
    let some (same, after) :=
        psKernelC0ReflectedBoolTrueDefEqWithFuel
          4096 source.context source.state left trueExpr
      | throw (IO.userError "source-proved independent reflection declined")
    if !same ||
        !psKernelExprPairSetContains after.success left trueExpr then
      throw (IO.userError "reflection verdict or source pair cache changed")
    let receipt ← match psKernelC0CertifiedWorkDefEqReflectedOwned
        4096 work left trueExpr with
      | .ok proof => pure proof
      | .error e => throw (IO.userError ("reflected DefEq failed: " ++ e))
    let _exact : psKernelC0CertifiedWorkDefEq
        4096 work left trueExpr = .ok receipt.val := receipt.property
    let (reference, _) ← match psKernelIsDefEq
        4096 source.context source.state left trueExpr with
      | .ok value => pure value
      | .error e => throw (IO.userError ("original reflection failed: " ++ e))
    if !reference || !receipt.val.fst then
      throw (IO.userError "independent reflection diverged from source")
    if (psKernelC0ReflectedBoolTrueDefEqWithFuel
        0 source.context source.state left trueExpr).isSome then
      throw (IO.userError "reflection skipped zero DefEq budget")
    if (psKernelC0ReflectedBoolTrueDefEqWithFuel
        1 source.context source.state left trueExpr).isSome then
      throw (IO.userError "reflection skipped recursive WHNF budget")

  let falseExpr : PsKernelExpr :=
    .const (.str (.str .anonymous "Bool") "false") []
  if (psKernelC0ReflectedBoolTrueDefEqWithFuel
      4096 source.context source.state basic falseExpr).isSome then
    throw (IO.userError "unqualified reflection on Bool.false")
  let dependsOnLocal : PsKernelExpr := .app id (.fvar x)
  if (psKernelC0ReflectedBoolTrueDefEqWithFuel
      4096 source.context source.state dependsOnLocal trueExpr).isSome then
    throw (IO.userError "nonclosed reflected expression was independently accepted")
  let rawCachedState := psKernelCheckerStateWithSuccess source.state
    (psKernelExprPairSetInsert source.state.success basic trueExpr)
  if (psKernelC0ReflectedBoolTrueDefEqWithFuel
      4096 source.context rawCachedState basic trueExpr).isSome then
    throw (IO.userError "prior source-success cache was not delegated")

  let blocked : PsKernelCheckerSession := {
    source with context :=
      { source.context with recDepth := 1000000, maxRecDepth := 1 }
  }
  if (psKernelC0ReflectedBoolTrueDefEqWithFuel
      4096 blocked.context blocked.state basic trueExpr).isSome then
    throw (IO.userError "reflection bypassed source recursion limit")
  let some blockedRaw := psKernelC0ArchitectureBegin blocked
    | throw (IO.userError "blocked reflection genesis failed")
  let some blockedWork := psKernelC0ArchitectureCertifyWork blockedRaw
    | throw (IO.userError "blocked reflection work failed")
  match psKernelC0CertifiedWorkDefEqReflectedOwned
      4096 blockedWork basic trueExpr,
    psKernelC0CertifiedWorkDefEq 4096 blockedWork basic trueExpr with
  | .error observed, .error expected =>
      if observed != expected then
        throw (IO.userError "reflection resource-error provenance changed")
  | _, _ => throw (IO.userError "reflection bypassed depth denial")

  let some genesis := psKernelC0AuditedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "audited reflection genesis failed")
  let (same, after) ← match psKernelC0AuditedSourceDefEq
      4096 genesis nested trueExpr with
    | .ok output => pure output
    | .error e => throw (IO.userError ("audited reflection failed: " ++ e))
  if !same ||
      !(psKernelC0HistoryAxiomSignatures after.trusted.history).isEmpty ||
      !(psKernelC0HistoryTrustCapabilities after.trusted.history).isEmpty then
    throw (IO.userError "reflection unexpectedly enlarged trusted foundation")
  let _axioms := psKernelC0AuditedSourceAxiomsApproved after
  let _caps := psKernelC0AuditedSourceCapabilitiesApproved after

  -- Raw DefEq is *not* term checking. The fully verified provider must
  -- reject the unbound Bool.true constant, despite a source-equal WHNF.
  let resources : PsKernelResourcePolicy := {
    fuel := 4096, maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false, maxDeclarations := 8
  }
  let verified ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok x => pure x
    | .error _ => throw (IO.userError "verified reflection genesis failed")
  match psKernelC0VerifiedProviderDefEq verified basic trueExpr with
  | .error (.rejectedInvalid _) => pure ()
  | _ =>
      throw (IO.userError "verified provider admitted unbound reflected term")
  IO.println "C0_REFLECTED_DEFEQ recursive_whnf_source_result_state=pass"
  IO.println "C0_REFLECTED_DEFEQ fuel_depth_negative_positive_cache=pass"
  IO.println "C0_REFLECTED_DEFEQ audited_and_verified_admission_boundary=pass"
