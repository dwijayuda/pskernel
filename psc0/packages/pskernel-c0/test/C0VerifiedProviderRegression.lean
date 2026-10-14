import Ps.KernelCore.API.VerifiedProvider

def main : IO Unit := do
  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 1
  }
  let provider := psKernelProviderDefault
  let first ← match psKernelC0VerifiedProviderBegin resources provider with
    | .ok session => pure session
    | .error _ => throw (IO.userError "verified provider genesis refused valid policy")
  let beta : PsKernelExpr :=
    .app (.lam (.str .anonymous "betaArgument") (.sort .zero)
      (.bvar 0) .default) (.sort .zero)
  -- These are reductions/comparisons of CHECKED expressions; an invalid
  -- application may not become a provider-authorized WHNF or DefEq result.
  let (normalized, _) ← match psKernelC0VerifiedProviderWhnf
      first (.sort .zero) with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified provider WHNF rejected Sort")
  if !psKernelExprEqual normalized (.sort .zero) then
    throw (IO.userError "verified provider WHNF changed source Sort")
  let (sameSort, _) ← match psKernelC0VerifiedProviderDefEq
      first (.sort .zero) (.sort .zero) with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified provider DefEq rejected Sorts")
  if !sameSort then
    throw (IO.userError "verified provider DefEq denied checked identical inputs")
  match psKernelC0VerifiedProviderWhnf first beta with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "verified provider WHNF accepted a malformed typed beta")
  match psKernelC0VerifiedProviderDefEq first beta beta with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "verified provider DefEq accepted malformed arguments")
  let (ty, afterCheck) ← match psKernelC0VerifiedProviderCheck first (.sort .zero) with
    | .ok value => pure value
    | .error _ => throw (IO.userError "verified provider rejected well-typed Sort")
  if !psKernelExprEqual ty (.sort (.succ .zero)) then
    throw (IO.userError "verified provider returned incorrect checked type")
  match psKernelC0VerifiedProviderCheck afterCheck (.bvar 0) with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider did not reject loose bound variable")

  -- Negative cache-provenance conformance: raw caller-built checker states
  -- are not a source of verified judgments. A fabricated positive DefEq
  -- cache entry can alter a raw query, but the verified provider must start
  -- with its independently generated checked-state lineage.
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let raw := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe
    resources.maxRecDepth resources.maxNatSize
  let fabricatedCache :=
    psKernelExprPairSetInsert raw.state.success sort0 sort1
  let contaminated : PsKernelCheckerSession := {
    raw with
    state := psKernelCheckerStateWithSuccess raw.state fabricatedCache
  }
  let (rawResult, _) ← match psKernelSessionIsDefEq
      resources.fuel contaminated sort0 sort1 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("raw cache fixture failed: " ++ e))
  if !rawResult then
    throw (IO.userError "negative fixture did not reach raw success-cache lookup")
  let (verifiedResult, cleanSession) ← match
      psKernelC0VerifiedProviderDefEq first sort0 sort1 with
    | .ok result => pure result
    | .error _ =>
        throw (IO.userError "verified source DefEq unexpectedly declined sorts")
  if verifiedResult then
    throw (IO.userError "verified provider adopted an externally supplied cache entry")
  if !(psKernelC0HistoryAxiomSignatures
      cleanSession.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "negative cache test introduced a trusted axiom")

  let name : PsKernelName := .str .anonymous "VerifiedProviderAxiom"
  let signedAxiom : PsKernelAxiomInfo := {
    base := {
      name := name
      levelParams := []
      type := .sort .zero
    }
    isUnsafe := false
  }
  match psKernelC0VerifiedProviderAdmit first (.axiomDecl signedAxiom) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "verified provider admitted unsigned signedAxiom")

  match psKernelC0VerifiedProviderAdmit first (.mutualDefinitions []) with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider admitted an invalid empty mutual family")
  let some policySession := psKernelC0VerifiedChangePolicy first.verified [signedAxiom] []
    | throw (IO.userError "verified policy expansion failed")
  let withPolicy : PsKernelC0VerifiedProviderSession :=
    { first with verified := policySession }
  let accepted ← match psKernelC0VerifiedProviderAdmit withPolicy (.axiomDecl signedAxiom) with
    | .ok session => pure session
    | .error _ => throw (IO.userError "verified provider rejected approved checked signedAxiom")
  if psKernelEnvironmentSize
      accepted.verified.sealed.audited.trusted.certified.raw.checker.context.environment != 1 then
    throw (IO.userError "verified provider lost checked declaration")
  let second : PsKernelAxiomInfo := {
    base := {
      name := .str .anonymous "VerifiedProviderSecondAxiom"
      levelParams := []
      type := .sort .zero
    }
    isUnsafe := false
  }
  let some widened := psKernelC0VerifiedChangePolicy accepted.verified [signedAxiom, second] []
    | throw (IO.userError "verified provider second explicit policy expansion failed")
  let full : PsKernelC0VerifiedProviderSession := { accepted with verified := widened }
  match psKernelC0VerifiedProviderAdmit full (.axiomDecl second) with
  | .error (.resourceExhausted .declarationLimit _) => pure ()
  | _ => throw (IO.userError "verified provider failed declaration limit")
  if psKernelEnvironmentSize
      accepted.verified.sealed.audited.trusted.certified.raw.checker.context.environment != 1 then
    throw (IO.userError "resource failure mutated immutable checked state")

  -- Atomic mutual families require one approval for EVERY unsafe member.
  let mutualResources : PsKernelResourcePolicy :=
    { resources with maxDeclarations := 2 }
  let mutualGenesis ← match psKernelC0VerifiedProviderBegin
      mutualResources provider with
    | .ok session => pure session
    | .error _ => throw (IO.userError "verified mutual genesis failed")
  let mutualOne : PsKernelName := .str .anonymous "VerifiedMutualOne"
  let mutualTwo : PsKernelName := .str .anonymous "VerifiedMutualTwo"
  let mutualType : PsKernelExpr := .sort (.succ .zero)
  let mutualFirst : PsKernelDefinitionInfo := {
    base := {
      name := mutualOne
      levelParams := []
      type := mutualType
    }
    value := .sort .zero
    hints := .abbrevHint
    safety := .unsafeDef
  }
  let mutualSecond : PsKernelDefinitionInfo := {
    base := {
      name := mutualTwo
      levelParams := []
      type := mutualType
    }
    value := .sort .zero
    hints := .abbrevHint
    safety := .unsafeDef
  }
  let mutualRequest : PsKernelDeclarationRequest :=
    .mutualDefinitions [mutualFirst, mutualSecond]
  match psKernelC0VerifiedProviderAdmit mutualGenesis mutualRequest with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "unapproved mutual family entered trusted environment")
  let some halfPolicy := psKernelC0VerifiedChangePolicy
      mutualGenesis.verified [] [.unsafeDefinition mutualOne]
    | throw (IO.userError "one-member policy review failed")
  let halfSession : PsKernelC0VerifiedProviderSession :=
    { mutualGenesis with verified := halfPolicy }
  match psKernelC0VerifiedProviderAdmit halfSession mutualRequest with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "one permission authorized entire unsafe mutual family")
  let some bothPolicy := psKernelC0VerifiedChangePolicy
      mutualGenesis.verified []
        [.unsafeDefinition mutualOne, .unsafeDefinition mutualTwo]
    | throw (IO.userError "full mutual policy review failed")
  let bothSession : PsKernelC0VerifiedProviderSession :=
    { mutualGenesis with verified := bothPolicy }
  let mutualAccepted ← match psKernelC0VerifiedProviderAdmit bothSession
      mutualRequest with
    | .ok result => pure result
    | .error _ => throw (IO.userError "fully approved source mutual family rejected")
  if psKernelEnvironmentSize
      mutualAccepted.verified.sealed.audited.trusted.certified.raw.checker.context.environment != 2 then
    throw (IO.userError "atomic mutual admission lost a checked member")
  if (psKernelC0HistoryTrustCapabilities
      mutualAccepted.verified.sealed.audited.trusted.history).length != 2 then
    throw (IO.userError "mutual family did not record both trust capabilities")
  if (psKernelC0VerifiedChangePolicy mutualAccepted.verified [] []).isSome then
    throw (IO.userError "mutual trust ledger could be silently downgraded")

  -- The provider record is constructible; it may not claim a runtime
  -- policy with different recursion/numeral limits than the checker used.
  let modifiedRecursion : PsKernelResourcePolicy :=
    { resources with maxRecDepth := resources.maxRecDepth + 1 }
  match psKernelC0VerifiedProviderCheck
      { first with resources := modifiedRecursion } (.sort .zero) with
  | .error (.declinedUnsupported _) => pure ()
  | _ => throw (IO.userError "provider resource mismatch reached accepting checker")
  let modifiedNumerals : PsKernelResourcePolicy :=
    { resources with maxNatSize := resources.maxNatSize + 1 }
  match psKernelC0VerifiedProviderCheck
      { first with resources := modifiedNumerals } (.sort .zero) with
  | .error (.declinedUnsupported _) => pure ()
  | _ => throw (IO.userError "modified numeral policy bypassed checked genesis")
  let cancelled : PsKernelResourcePolicy := { resources with cancelled := true }
  match psKernelC0VerifiedProviderBegin cancelled provider with
  | .error (.resourceExhausted .cancelled _) => pure ()
  | _ => throw (IO.userError "verified provider ignored cancellation")
  IO.println "C0_VERIFIED_PROVIDER checked_genesis_and_expression=pass"
  IO.println "C0_VERIFIED_PROVIDER unsigned_axiom_and_unsupported_decline=pass"
  IO.println "C0_VERIFIED_PROVIDER resource_preflight_and_atomicity=pass"
