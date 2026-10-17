import Ps.CompilerIr.Check

-- This function checks and consumes the same immutable module. A report is
-- diagnostic data, never a caller-supplied authorization token.
def psWithCheckedIr {α : Type} (options : PsIrCheckOptions)
    (ir : PsVerifiedIrModule) (emit : PsVerifiedIrModule → Except String α) :
    Except String (PsIrCheckReport × α) := do
  let report := psCheckVerifiedIrModule options ir
  if !report.accepted || !report.traversalComplete then
    let details := report.findings.map fun finding =>
      finding.owner ++ ":" ++ finding.path ++ ": " ++ finding.code ++ " " ++ finding.detail
    throw ("PSCV0-IR-CHECK: " ++ String.intercalate "\n" details)
  let output ← emit ir
  pure (report, output)
