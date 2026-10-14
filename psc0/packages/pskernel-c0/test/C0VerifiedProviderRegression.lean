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
  | .error (.declinedUnsupported _) => pure ()
  | _ => throw (IO.userError "verified provider invented mutual-definition admission")
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

  let cancelled : PsKernelResourcePolicy := { resources with cancelled := true }
  match psKernelC0VerifiedProviderBegin cancelled provider with
  | .error (.resourceExhausted .cancelled _) => pure ()
  | _ => throw (IO.userError "verified provider ignored cancellation")
  IO.println "C0_VERIFIED_PROVIDER checked_genesis_and_expression=pass"
  IO.println "C0_VERIFIED_PROVIDER unsigned_axiom_and_unsupported_decline=pass"
  IO.println "C0_VERIFIED_PROVIDER resource_preflight_and_atomicity=pass"
