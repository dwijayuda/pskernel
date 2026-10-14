import Ps.KernelCore.API.VerifiedProvider

/-!
Phase E.4G: proof-qualified, independent structurally reflexive DefEq.

The original C0 source DefEq consumes its configured fuel/recursion depth
before its quick syntactic equality decision. On success it inserts the
exact pair in the success cache. These effects are preserved; all other
cases remain source checked. DefEq alone does not validate malformed terms.
-/

def main : IO Unit := do
  let checker := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin checker
    | throw (IO.userError "reflexive source transaction genesis failed")
  let some certified := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "reflexive empty work lost canonical certificate")
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)

  -- These are actual Lean equalities for the entire checked operation:
  -- expression result, state, success-cache updates and source errors.
  let _reflexiveExact :
      psKernelC0CertifiedWorkDefEqCanonicalFast 4096 certified sort0 sort0 =
        psKernelC0CertifiedWorkDefEq 4096 certified sort0 sort0 :=
    psKernelC0CertifiedWorkDefEqCanonicalFast_exact
      4096 certified sort0 sort0
  let _distinctExact :
      psKernelC0CertifiedWorkDefEqCanonicalFast 4096 certified sort0 sort1 =
        psKernelC0CertifiedWorkDefEq 4096 certified sort0 sort1 :=
    psKernelC0CertifiedWorkDefEqCanonicalFast_exact
      4096 certified sort0 sort1
  let _fuelExact :
      psKernelC0CertifiedWorkDefEqCanonicalFast 0 certified sort0 sort0 =
        psKernelC0CertifiedWorkDefEq 0 certified sort0 sort0 :=
    psKernelC0CertifiedWorkDefEqCanonicalFast_exact 0 certified sort0 sort0

  let positive ← match psKernelC0CertifiedWorkDefEqCanonicalFastOwned
      4096 certified sort0 sort0 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("reflexive source result failed: " ++ e))
  let _sourceEquation :
      psKernelC0CertifiedWorkDefEq 4096 certified sort0 sort0 =
        .ok positive.val :=
    positive.property
  if !positive.val.fst ||
      !psKernelExprPairSetContains
        positive.val.snd.raw.checker.state.success sort0 sort0 then
    throw (IO.userError "reflexive DefEq skipped exact success-cache insertion")
  if !(psKernelC0DefEqReflexiveWithFuel 4096
      checker.context checker.state sort0 sort0).isSome then
    throw (IO.userError "independent reflexive execution was not selected")
  if (psKernelC0DefEqReflexiveWithFuel 4096
      checker.context checker.state sort0 sort1).isSome then
    throw (IO.userError "independent reflexivity misclassified unequal Sorts")
  let (different, _) ← match psKernelC0CertifiedWorkDefEqCanonicalFast
      4096 certified sort0 sort1 with
    | .ok value => pure value
    | .error e => throw (IO.userError ("distinct Sort source comparison failed: " ++ e))
  if different then
    throw (IO.userError "source fallback equated unequal universe levels")
  match psKernelC0CertifiedWorkDefEqCanonicalFast 0 certified sort0 sort0 with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "reflexive DefEq bypassed zero source fuel")

  -- Recursion exhaustion must fail by the original checker; a superficial
  -- structural equality cannot bypass the actual current context limit.
  let exhaustedChecker : PsKernelCheckerSession := {
    checker with
    context := {
      checker.context with
      maxRecDepth := 1
      recDepth := 1000000
    }
  }
  let some exhaustedRaw := psKernelC0ArchitectureBegin exhaustedChecker
    | throw (IO.userError "resource-negative source genesis failed")
  let some exhausted := psKernelC0ArchitectureCertifyWork exhaustedRaw
    | throw (IO.userError "resource-negative cert validation failed")
  if (psKernelC0DefEqReflexiveWithFuel 4096 exhaustedChecker.context
      exhaustedChecker.state sort0 sort0).isSome then
    throw (IO.userError "reflexive DefEq ignored source recursion policy")
  match psKernelC0CertifiedWorkDefEqCanonicalFast
      4096 exhausted sort0 sort0 with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "source recursion exhausted but DefEq accepted")

  -- A verified provider always FULL-CHECKS its inputs before DefEq.
  -- Its state retains an exact signed genesis/checked lineage.
  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let begin ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok session => pure session
    | .error _ => throw (IO.userError "verified DefEq genesis failed")
  let (sameSort, afterSame) ← match psKernelC0VerifiedProviderDefEq
      begin sort0 sort0 with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified checked reflexive DefEq failed")
  if !sameSort ||
      !psKernelExprPairSetContains
        afterSame.verified.sealed.audited.trusted.certified.raw.checker.state.success
        sort0 sort0 then
    throw (IO.userError "verified source-exact reflexivity lost success cache")
  let (differentSort, _) ← match psKernelC0VerifiedProviderDefEq
      begin sort0 sort1 with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified distinct Sort comparison failed")
  if differentSort then
    throw (IO.userError "verified DefEq admitted unequal checked Sorts")
  match psKernelC0VerifiedProviderDefEq begin (.bvar 0) (.bvar 0) with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "verified provider bypassed full checking on reflexive bvar")

  IO.println "C0_REFL_DEFEQ all_contexts_source_equation_and_cache=pass"
  IO.println "C0_REFL_DEFEQ fallback_and_resource_error_preservation=pass"
  IO.println "C0_REFL_DEFEQ verified_provider_full_check_boundary=pass"
