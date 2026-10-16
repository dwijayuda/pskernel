import Ps.KernelCore.API.VerifiedProvider

/-!
Phase B — Lean 4.35 application-versus-lambda eta equivalence.
The actual first false conversion in Lean Init record 86383 includes
Option.some α versus (fun x => Option.some α x). The shape-dispatch
correction is tested independently of that library or its definitions.
-/

-- Pinned Lean checks this eta law independently of C0.
example (f : Nat → Nat → Nat) (n : Nat) :
    f n = (fun x => f n x) := rfl

def main : IO Unit := do
  let fName : PsKernelName := .str .anonymous "EtaFunction"
  let gName : PsKernelName := .str .anonymous "EtaOtherFunction"
  let xName : PsKernelName := .str .anonymous "EtaParameter"
  let sort0 : PsKernelExpr := .sort .zero
  let sort1 : PsKernelExpr := .sort (.succ .zero)
  let fnType : PsKernelExpr :=
    .forallE xName sort1
      (.forallE xName sort1 sort0 .default) .default
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let locals := psKernelLocalContextAddLocal
    source.context.localContext fName fName fnType .default
  let checked : PsKernelCheckerSession := {
    source with context :=
      psKernelCheckerContextWithLocalContext source.context locals
  }
  let left : PsKernelExpr := .app (.fvar fName) sort0
  let right : PsKernelExpr :=
    .lam xName sort1 (.app left (.bvar 0)) .default
  if psKernelExprEq left right then
    throw (IO.userError "eta terms unexpectedly syntactically equal")
  let (positive, converted) ← match psKernelIsDefEq
      4096 checked.context checked.state left right with
    | .ok pair => pure pair
    | .error reason =>
        throw (IO.userError ("eta conversion returned error: " ++ reason))
  if !positive then
    throw (IO.userError "eta did not match the official Lean 4.35 rule")
  -- Eta remains valid, but its local-FVar operands may not populate a
  -- cross-scope reusable positive-conversion cache.
  if psKernelExprPairSetContains converted.success left right then
    throw (IO.userError "eta cached an expression containing a local FVar")
  let (reverse, _) ← match psKernelIsDefEq
      4096 checked.context checked.state right left with
    | .ok pair => pure pair
    | .error reason =>
        throw (IO.userError ("reverse eta returned error: " ++ reason))
  if !reverse then
    throw (IO.userError "eta source conversion is asymmetric")

  -- Another well-typed local function is not the same function.
  let bothLocals := psKernelLocalContextAddLocal
    checked.context.localContext gName gName fnType .default
  let both : PsKernelCheckerSession := {
    checked with context :=
      psKernelCheckerContextWithLocalContext checked.context bothLocals
  }
  let other : PsKernelExpr :=
    .lam xName sort1
      (.app (.app (.fvar gName) sort0) (.bvar 0)) .default
  let (different, _) ← match psKernelIsDefEq
      4096 both.context both.state left other with
    | .ok pair => pure pair
    | .error reason =>
        throw (IO.userError ("distinct functions returned error: " ++ reason))
  if different then
    throw (IO.userError "eta equated distinct functions")

  let some raw := psKernelC0ArchitectureBegin checked
    | throw (IO.userError "eta certified-work origin unavailable")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "eta certified-work invariant failed")
  let receipt ← match psKernelC0CertifiedWorkDefEqQualifiedOwned
      4096 work left right with
    | .ok value => pure value
    | .error reason =>
        throw (IO.userError ("eta checked-source operation failed: " ++ reason))
  let _source : psKernelC0CertifiedWorkDefEq 4096 work left right =
      .ok receipt.val := receipt.property
  if !receipt.val.fst then
    throw (IO.userError "eta certified source verdict changed")

  let resources : PsKernelResourcePolicy := {
    fuel := 4096, maxRecDepth := 4096
    maxNatSize := psKernelLeanNatMaxSizeDefault
    cancelled := false, maxDeclarations := 8
  }
  let verified ← match psKernelC0VerifiedProviderBegin
      resources psKernelProviderDefault with
    | .ok session => pure session
    | .error _ => throw (IO.userError "eta verified genesis unavailable")
  match psKernelC0VerifiedProviderDefEq verified left right with
  | .error (.rejectedInvalid _) => pure ()
  | _ => throw (IO.userError "unchecked local expression was accepted")

  IO.println "C0_INIT_ETA application_lambda_parity_and_reverse=pass"
  IO.println "C0_INIT_ETA distinct_function_negative=pass"
  IO.println "C0_INIT_ETA verified_source_checking_and_receipt=pass"
