import Pscv.Kernel.Checker
import Pscv.Extensions.Policy

/-! Native Lean-built development tool. Not the completed PSCV compiler. -/
def main (args : List String) : IO UInt32 := do
  match args with
  | ["--version"] =>
      IO.println "pscv-v6-dev 0.0.1 (Lean 4.35.0-rc3 build host)"
      return 0
  | ["capabilities"] =>
      IO.println "P0: native Lean-built Core models, extension policy, kernel candidate checking"
      IO.println "NOT AVAILABLE: .ps parsing, elaboration, PSCV-CERT, .proof.lean, target backends"
      return 0
  | ["kernel-empty-smoke"] =>
      let candidate : Pscv.CoreCandidate := {sourceId := "internal-smoke", declarations := #[]}
      match ← Pscv.Kernel.checkCandidate candidate with
      | .ok report =>
          IO.println s!"Kernel accepted {report.checkedDeclarations} declarations (not PSCV-certified)"
          return 0
      | .error error =>
          IO.eprintln error
          return 1
  | _ =>
      IO.eprintln "PSCV_V6_COMPILATION_NOT_IMPLEMENTED: only --version, capabilities, kernel-empty-smoke"
      return 2
