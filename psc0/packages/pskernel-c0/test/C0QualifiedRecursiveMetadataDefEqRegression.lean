import Ps.KernelCore.Architecture.AuditedAssumptions

/-!
E.4AJ: source-checked nested metadata DefEq and leaf recursion.

The independent engine must reproduce the entire original conversion
result/state for positive and negative comparisons, including each
nested positive cache insertion, arbitrary raw source cached pairs
and exact budget/depth error fallback. DefEq is not term validation.
-/
def main : IO Unit := do
  let s0 : PsKernelExpr := .sort .zero
  let s1 : PsKernelExpr := .sort (.succ .zero)
  let equivalent : PsKernelExpr := .sort (.max .zero .zero)
  let a : PsKernelExpr := .mdata 11 (.mdata 22 equivalent)
  let b : PsKernelExpr := .mdata 31 (.mdata 42 s0)
  let c : PsKernelExpr := .mdata 51 (.mdata 62 s1)
  let natA : PsKernelExpr := .mdata 71 (.mdata 72 (.lit (.nat 17)))
  let natB : PsKernelExpr := .mdata 81 (.mdata 82 (.lit (.nat 17)))
  let strA : PsKernelExpr := .mdata 91 (.mdata 92 (.lit (.str "λ世界")))
  let strB : PsKernelExpr := .mdata 101 (.mdata 102 (.lit (.str "λ世界")))
  let source := psKernelMkCheckerSession
    psKernelEnvironmentEmpty [] .safe 4096 psKernelLeanNatMaxSizeDefault
  let some raw := psKernelC0ArchitectureBegin source
    | throw (IO.userError "recursive metadata DefEq genesis failed")
  let some work := psKernelC0ArchitectureCertifyWork raw
    | throw (IO.userError "recursive metadata DefEq certification failed")

  for (left, right, expected) in
      [(a, b, true), (a, c, false),
       (natA, natB, true), (strA, strB, true)] do
    let some (equal, nextState) :=
        psKernelC0RecursiveMetadataDefEqWithFuel
          4096 source.context source.state left right
      | throw (IO.userError "recursive independent metadata DefEq declined")
    if equal != expected then
      throw (IO.userError "recursive independent metadata verdict wrong")
    let receipt ← match psKernelC0CertifiedWorkDefEqRecursiveMetadataOwned
        4096 work left right with
      | .ok proof => pure proof
      | .error e => throw (IO.userError ("qualified metadata DefEq failed: " ++ e))
    let _exact : psKernelC0CertifiedWorkDefEq
        4096 work left right = .ok receipt.val := receipt.property
    if receipt.val.fst != expected then
      throw (IO.userError "qualified metadata source receipt disagreed")
    let (original, _) ← match psKernelIsDefEq
        4096 source.context source.state left right with
      | .ok value => pure value
      | .error e => throw (IO.userError ("original DefEq failed: " ++ e))
    if original != equal then
      throw (IO.userError "full source metadata DefEq verdict diverged")
    if expected &&
        !psKernelExprPairSetContains nextState.success left right then
      throw (IO.userError "recursive metadata result lost source success cache")
    if !expected &&
        psKernelExprPairSetContains nextState.success left right then
      throw (IO.userError "negative metadata gained forged success cache")
    if (psKernelC0RecursiveMetadataDefEqWithFuel
        1 source.context source.state left right).isSome then
      throw (IO.userError "recursive metadata skipped source nested fuel")
    if (psKernelC0RecursiveMetadataDefEqWithFuel
        0 source.context source.state left right).isSome then
      throw (IO.userError "recursive metadata bypassed zero fuel")

  let forgedState := psKernelCheckerStateWithSuccess source.state
    (psKernelExprPairSetInsert source.state.success a c)
  match psKernelC0RecursiveMetadataDefEqWithFuel
      4096 source.context forgedState a c with
  | some (true, nextState) =>
      if !psKernelExprPairSetContains nextState.success a c then
        throw (IO.userError "raw source cache hit not preserved")
  | _ =>
      throw (IO.userError "source-success cache was not faithfully modeled")

  -- No pair with an unqualified recursion/shape may falsely acquire a
  -- direct verdict: full source algorithm remains the fallback.
  let unsupported : PsKernelExpr :=
    .mdata 2 (.app (.const (.str .anonymous "UnknownFunction") []) s0)
  if (psKernelC0RecursiveMetadataDefEqWithFuel
      4096 source.context source.state unsupported a).isSome then
    throw (IO.userError "unsupported heterogeneous metadata acquired verdict")

  match psKernelC0CertifiedWorkDefEqRecursiveMetadataOwned
      0 work a b, psKernelC0CertifiedWorkDefEq 0 work a b with
  | .error observed, .error original =>
      if observed != original then
        throw (IO.userError "metadata zero-fuel source error changed")
  | _, _ => throw (IO.userError "zero fuel allowed metadata conversion")
  let blocked : PsKernelCheckerSession := {
    source with
    context := { source.context with recDepth := 1000000, maxRecDepth := 1 }
  }
  if (psKernelC0RecursiveMetadataDefEqWithFuel
      4096 blocked.context blocked.state a b).isSome then
    throw (IO.userError "metadata DefEq bypassed depth policy")

  let some genesis := psKernelC0AuditedSourceBegin
      4096 psKernelLeanNatMaxSizeDefault []
    | throw (IO.userError "audited metadata DefEq genesis failed")
  let (same, after) ← match psKernelC0AuditedSourceDefEq
      4096 genesis a b with
    | .ok x => pure x
    | .error e => throw (IO.userError ("audited metadata DefEq failed: " ++ e))
  if !same ||
      !(psKernelC0HistoryAxiomSignatures after.trusted.history).isEmpty ||
      !(psKernelC0HistoryTrustCapabilities after.trusted.history).isEmpty then
    throw (IO.userError "metadata DefEq altered audited foundation")
  let _axioms := psKernelC0AuditedSourceAxiomsApproved after
  let _caps := psKernelC0AuditedSourceCapabilitiesApproved after
  IO.println "C0_METADATA_DEFEQ recursive_quick_comparison_exact_source=pass"
  IO.println "C0_METADATA_DEFEQ nested_success_cache_resource_and_negative=pass"
  IO.println "C0_METADATA_DEFEQ trusted_audited_source_foundation=pass"
