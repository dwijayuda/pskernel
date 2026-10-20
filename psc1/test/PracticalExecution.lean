import Ps.Host.LeanChecked
import Ps.Compiler.Ordinary
import Ps.BackendCommon.Plan
import Ps.BackendJs.Print

private def practicalExecutionFail (label detail : String) : IO α :=
  throw (IO.userError ("PSC1_PRACTICAL_EXECUTION_FAIL: " ++ label ++ ": " ++ detail))

private def psPracticalCompareRaw (label : String) (raw : PsVerifiedIrModule) : IO Unit := do
  let validated ← match psStrictValidateModule raw with
    | .error _ =>
        let report := psCheckVerifiedIrModule psIrCheckDefaultOptions raw
        let findings := report.findings.map (fun finding => finding.code ++ ":" ++ finding.detail)
        practicalExecutionFail label ("strict typed IR: " ++ String.intercalate ", " findings)
    | .ok value => pure value
  let plan ← match psBackendClosedPlan validated ["result", "psPracticalExpected"] with
    | .error error => practicalExecutionFail label error
    | .ok value => pure value
  let jsIr ← match psJsLowerSpecializedModule plan.raw with
    | .error _ => practicalExecutionFail label "JS lowering"
    | .ok value => pure value
  match psJsValidateModule jsIr with
  | .error _ => practicalExecutionFail label "JS target validation"
  | .ok _ => pure ()
  let declarations ← match psJsPrintDeclarationsWith
      (psJsPrintDeclarationStackSafeWithVisibility false) jsIr.declarations psTextBuilderEmpty with
    | .error _ => practicalExecutionFail label "JS printing"
    | .ok value => pure value
  let program := psJsPrintStackSafePrelude jsIr ++ declarations ++
    "\nimport { deepStrictEqual as __ps$practicalAssert } from 'node:assert/strict';\n" ++
    "__ps$practicalAssert(result, psPracticalExpected, " ++ psJsonQuote label ++ ");\n"
  let output ← IO.Process.output
    { cmd := "timeout", args := #["--kill-after=5s", "30s", "node", "--input-type=module"] } (some program)
  if output.exitCode != 0 then
    practicalExecutionFail label ("Node comparison: " ++ output.stdout ++ output.stderr)
  IO.println ("PSC1_PRACTICAL_EXECUTION_PASS: " ++ label ++
    " independently admitted, typed IR, private JS result comparison")

/-- Independent admission and typed IR checking are distinct from this executable
comparison. The expected value is a closed, typed Core definition; it introduces
no equality axiom. All generated declarations remain private to one Node module,
so aggregate comparisons do not claim a supported public aggregate ABI. -/
def psPracticalCheckExecuted (label : String)
    (prepared : PsCompilerAdmissionReadyModule) (type expected : PsExpr) : IO Unit := do
  let expectedName := psRootName "psPracticalExpected"
  let combined := PsCompilerAdmissionReadyModule.mk (prepared.declarations ++
    [PsDeclaration.definitionDecl expectedName [] type expected])
  match ← psHostLeanCheckPrepared combined with
  | .error error => practicalExecutionFail label ("independent admission: " ++ error)
  | .ok _ => pure ()
  let raw ← match psCompilerVerifiedIrFromPrepared combined with
    | .error _ => practicalExecutionFail label "erasure"
    | .ok value => pure value
  psPracticalCompareRaw label raw

/-- Ordinary fixtures retain independently admitted opaque witnesses and their
exact checked recursive bodies. No partial body is evaluated by the kernel. -/
def psPracticalCheckExecutedOrdinary (label : String)
    (elaborated : PsElabModuleResult) (type expected : PsExpr) : IO Unit := do
  let expectedName := psRootName "psPracticalExpected"
  let combined := PsElabModuleResult.mk elaborated.environment
    (elaborated.declarations ++
      [PsDeclaration.definitionDecl expectedName [] type expected])
  let prepared ← match psCompilerPrepareOrdinary combined with
    | .error error => practicalExecutionFail label ("ordinary preparation: " ++ error)
    | .ok value => pure value
  match psCompilerPrepareElaborated combined with
  | .ok _ => practicalExecutionFail label "checked mode accepted a partial fixture"
  | .error _ => pure ()
  match ← psHostLeanCheckPrepared prepared.logical with
  | .error error => practicalExecutionFail label ("independent ordinary admission: " ++ error)
  | .ok _ => pure ()
  let raw ← match psCompilerOrdinaryIr prepared with
    | .error error => practicalExecutionFail label ("ordinary erasure: " ++ error)
    | .ok value => pure value
  psPracticalCompareRaw label raw
