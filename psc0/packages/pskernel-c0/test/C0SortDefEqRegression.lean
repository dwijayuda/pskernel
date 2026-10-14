import Ps.KernelCore.API.VerifiedProvider

/-!
Phase E.4H: independently source-equivalent Sort-level DefEq, including
algorithmically equivalent but syntactically distinct universe levels.
The original source cache hit and recursion/fuel policies are preserved.
-/

def main : IO Unit := do
  let checker := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin checker
    | throw (IO.userError "Sort DefEq work genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "Sort DefEq work certification failed")
  let u0 : PsKernelLevel := .zero
  let u1 : PsKernelLevel := .succ .zero
  let uMax : PsKernelLevel := .max .zero .zero
  let s0 : PsKernelExpr := .sort u0
  let s1 : PsKernelExpr := .sort u1
  let sMax : PsKernelExpr := .sort uMax

  -- Proof results are equalities of the WHOLE source checked-session
  -- operation, including the original source success/failure cache state.
  let distinct ← match psKernelC0CertifiedWorkDefEqSortOwned
      4096 work u0 u1 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("source Sort inequality failed: " ++ e))
  let _distinctProof :
      psKernelC0CertifiedWorkDefEq 4096 work s0 s1 =
        .ok distinct.val :=
    distinct.property
  if distinct.val.fst then
    throw (IO.userError "independent Sort DefEq equated 0 and 1")
  if (psKernelC0SortDefEqWithFuel 4096
      checker.context checker.state u0 u1).isNone then
    throw (IO.userError "distinct Sort heads failed direct source-complete rule")

  -- Max(0,0) is definitionally equivalent to 0 under level normalization.
  -- This must be checked by the level-equivalence rule, not by guessing
  -- syntactic constructor equality.
  let equivalent ← match psKernelC0CertifiedWorkDefEqSortOwned
      4096 work uMax u0 with
    | .ok result => pure result
    | .error e => throw (IO.userError ("equivalent Sort comparison failed: " ++ e))
  let _equivalentProof :
      psKernelC0CertifiedWorkDefEq 4096 work sMax s0 =
        .ok equivalent.val :=
    equivalent.property
  if !equivalent.val.fst ||
      !psKernelExprPairSetContains
        equivalent.val.snd.raw.checker.state.success sMax s0 then
    throw (IO.userError "source-equivalent universe comparison lost success cache")

  -- A raw source checker may be given an externally forged success pair.
  -- The direct fragment MUST model the source result for arbitrary state,
  -- but the real verified provider must never IMPORT that raw cache.
  let forgedSuccess := psKernelExprPairSetInsert
    checker.state.success s0 s1
  let forgedState := psKernelCheckerStateWithSuccess checker.state forgedSuccess
  let rawCached := psKernelC0SortDefEqWithFuel 4096
    checker.context forgedState u0 u1
  match rawCached with
  | some (true, returnedState) =>
      if !psKernelExprPairSetContains returnedState.success s0 s1 then
        throw (IO.userError "raw source cache hit was not retained")
  | _ => throw (IO.userError "direct Sort rule diverged on raw success-cache hit")

  match psKernelC0CertifiedWorkDefEqSortOwned 0 work u0 u0 with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "Sort fast path bypassed source zero fuel")
  let exhaustedChecker : PsKernelCheckerSession := {
    checker with
    context := {
      checker.context with
      maxRecDepth := 1
      recDepth := 1000000
    }
  }
  if (psKernelC0SortDefEqWithFuel 4096 exhaustedChecker.context
      exhaustedChecker.state u0 u0).isSome then
    throw (IO.userError "Sort fast path bypassed source recursion guard")

  let resources : PsKernelResourcePolicy := {
    fuel := 4096
    maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false
    maxDeclarations := 8
  }
  let genesis ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok checked => pure checked
    | .error _ => throw (IO.userError "verified Sort provider genesis failed")
  let (isDifferent, _) ← match psKernelC0VerifiedProviderDefEq
      genesis s0 s1 with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified unequal Sorts failed checking")
  if isDifferent then
    throw (IO.userError "verified provider imported raw poisoned success cache")
  let (isEquivalent, next) ← match psKernelC0VerifiedProviderDefEq
      genesis sMax s0 with
    | .ok result => pure result
    | .error _ => throw (IO.userError "verified equivalent universes failed checking")
  if !isEquivalent ||
      !psKernelExprPairSetContains
        next.verified.sealed.audited.trusted.certified.raw.checker.state.success
        sMax s0 then
    throw (IO.userError "verified source-equivalent universe pair not cached")
  if !(psKernelC0HistoryAxiomSignatures
      next.verified.sealed.audited.trusted.history).isEmpty then
    throw (IO.userError "universe DefEq enlarged trusted foundation")
  match psKernelC0VerifiedProviderDefEq genesis
      (.bvar 0) (.bvar 0) with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "qualified DefEq skipped full term validation")

  IO.println "C0_SORT_DEFEQ complete_source_level_rule_and_state_equations=pass"
  IO.println "C0_SORT_DEFEQ positive_cache_forged_raw_isolation=pass"
  IO.println "C0_SORT_DEFEQ verified_provider_and_resource_semantics=pass"
