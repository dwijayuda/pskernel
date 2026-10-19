import Ps.Environment.Bootstrap
import Ps.Host.StandardExport

def main (args : List String) : IO Unit := do
  let [output] := args
    | throw (IO.userError "usage: pscv0_bootstrap_compatibility REPORT.json")
  PsV7Native.auditCoreCandidateAgainstFull "Bootstrap"
    psCoreBootstrapCandidateDeclarations psCoreBootstrapCandidateReducibility
    (System.FilePath.mk output)
