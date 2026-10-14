import Ps.KernelCore.API.VerifiedProvider
import Ps.KernelCore.Architecture.QualifiedInference

/-!
Phase E.4J mandatory conformance for exact scalar inference/checking.

This checks independently evaluated Sort/Nat/String scalar source typing,
the TWO distinct inference caches, the exact full-check result equation,
resource decline and rejection of caller-supplied raw cache contamination.
No type synthesis result alone is treated as proof admission.
-/

def main : IO Unit := do
  let checker := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some workRaw := psKernelC0ArchitectureBegin checker
    | throw (IO.userError "qualified scalar empty work failed")
  let some work := psKernelC0ArchitectureCertifyWork workRaw
    | throw (IO.userError "qualified scalar work certification failed")

  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let natValue : PsKernelExpr := .lit (.nat 17)
  let stringValue : PsKernelExpr := .lit (.str "α🚀 Z")
  let checkedInputs : List (PsKernelExpr × PsKernelExpr) := [
    (sort0, sort1),
    (sort1, .sort (.succ (.succ .zero))),
    (natValue, .const psKernelNatName []),
    (stringValue, .const psKernelStringName [])
  ]
  for (expr, expected) in checkedInputs do
    let inferred ← match psKernelC0CertifiedWorkInferQualifiedOwned
        4096 work expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("scalar inference failed: " ++ e))
    let _exactInfer :
        psKernelC0CertifiedWorkInfer 4096 work expr = .ok inferred.val :=
      inferred.property
    if !psKernelExprEqual inferred.val.fst expected then
      throw (IO.userError "independent scalar inferred wrong source type")
    let checked ← match psKernelC0CertifiedWorkCheckQualifiedOwned
        4096 work expr with
      | .ok result => pure result
      | .error e => throw (IO.userError ("scalar full checking failed: " ++ e))
    let _exactCheck :
        psKernelC0CertifiedWorkCheck 4096 work expr = .ok checked.val :=
      checked.property
    if !psKernelExprEqual checked.val.fst expected then
      throw (IO.userError "independent scalar full checker changed source type")

  -- Source inference-only and fully checked cache modes are DISTINCT.
  let pureSortInfer := psKernelC0ScalarInferWithFuel
    4096 checker.context checker.state sort0 true
  let pureSortCheck := psKernelC0ScalarInferWithFuel
    4096 checker.context checker.state sort0 false
  match pureSortInfer, pureSortCheck with
  | some (tyInfer, inferState), some (tyCheck, checkState) =>
      if !psKernelExprEqual tyInfer sort1 ||
          !psKernelExprEqual tyCheck sort1 then
        throw (IO.userError "two scalar inference modes disagreed with source")
      if (psKernelExprMapGet inferState.inferOnly sort0).isNone ||
          (psKernelExprMapGet inferState.checkedInfer sort0).isSome ||
          (psKernelExprMapGet checkState.checkedInfer sort0).isNone ||
          (psKernelExprMapGet checkState.inferOnly sort0).isSome then
        throw (IO.userError "scalar rule mixed inference-only and checked caches")
  | _, _ => throw (IO.userError "source-equivalent scalar direct path declined")

  -- A raw caller can forge a cached inference type. Exact source operational
  -- refinement must preserve this behavior for the RAW low-level source;
  -- a verified provider cannot import the forged state at all.
  let forged : PsKernelExpr := .sort (.succ (.succ (.succ .zero)))
  let poisonedInfer :=
    psKernelExprMapInsert checker.state.inferOnly sort0 forged
  let poisonState :=
    psKernelCheckerStateWithInferOnly checker.state poisonedInfer
  match psKernelC0ScalarInferWithFuel
      4096 checker.context poisonState sort0 true with
  | some (observed, _) =>
      if !psKernelExprEqual observed forged then
        throw (IO.userError "raw cache compatibility fixture not exercised")
  | none => throw (IO.userError "raw poisoned cache source fixture declined")

  -- Zero source fuel is an error, not a proof or inferred type.
  for expr in [sort0, natValue, stringValue] do
    if (psKernelC0ScalarInferWithFuel 0
        checker.context checker.state expr true).isSome then
      throw (IO.userError "scalar inference ignored source zero fuel")
    match psKernelC0CertifiedWorkInferQualifiedOwned 0 work expr with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "source inference fuel became type admission")
    match psKernelC0CertifiedWorkCheckQualifiedOwned 0 work expr with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "source full checking ignored zero fuel")

  -- Nat resource limit is the ORIGINAL source limit, not a speculative
  -- literal conversion: the source must classify and reject oversized Nats.
  let constrained := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 0
  let some constrainedRaw := psKernelC0ArchitectureBegin constrained
    | throw (IO.userError "constrained work genesis failed")
  let some constrainedWork := psKernelC0ArchitectureCertifyWork constrainedRaw
    | throw (IO.userError "constrained work certification failed")
  if (psKernelC0ScalarInferWithFuel 4096 constrained.context
      constrained.state natValue false).isSome then
    throw (IO.userError "source Nat byte-limit bypassed by direct typing")
  match psKernelC0CertifiedWorkCheckQualifiedOwned
      4096 constrainedWork natValue with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "oversize Nat acquired checked source type")

  let exhaustedContext := {
    checker.context with
    maxRecDepth := 1
    recDepth := 1000000
  : PsKernelCheckerContext }
  if (psKernelC0ScalarInferWithFuel 4096
      exhaustedContext checker.state sort0 false).isSome then
    throw (IO.userError "scalar inference bypassed source recursion depth")

  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 16
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok result => pure result
    | .error _ => throw (IO.userError "scalar verified-provider genesis failed")
  for (expr, expected) in checkedInputs do
    let (inferred, afterInfer) ← match psKernelC0VerifiedProviderInfer
        genesis expr with
      | .ok result => pure result
      | .error _ => throw (IO.userError "provider scalar inference failed")
    let (checked, afterCheck) ← match psKernelC0VerifiedProviderCheck
        afterInfer expr with
      | .ok result => pure result
      | .error _ => throw (IO.userError "provider scalar full checking failed")
    if !psKernelExprEqual inferred expected ||
        !psKernelExprEqual checked expected then
      throw (IO.userError "verified source scalar typing disagreed")
    if !(psKernelC0HistoryAxiomSignatures
        afterCheck.verified.sealed.audited.trusted.history).isEmpty then
      throw (IO.userError "scalar source typing introduced a trusted axiom")
  match psKernelC0VerifiedProviderCheck genesis (.bvar 0) with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified full checking accepted loose bvar")
  match psKernelC0VerifiedProviderCheck genesis
      (.mvar (.str .anonymous "unknown")) with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified full checking accepted metavariable")
  let cancelled : PsKernelResourcePolicy := { resources with cancelled := true }
  match psKernelC0VerifiedProviderInfer
      { genesis with resources := cancelled } sort0 with
  | .error (.resourceExhausted .cancelled _) => pure ()
  | _ => throw (IO.userError "scalar provider bypassed cancellation")

  IO.println "C0_SCALAR_TYPING source_infer_and_checked_cache_equations=pass"
  IO.println "C0_SCALAR_TYPING Nat_String_Sort_resource_boundaries=pass"
  IO.println "C0_SCALAR_TYPING provider_provenance_and_negative_typing=pass"
