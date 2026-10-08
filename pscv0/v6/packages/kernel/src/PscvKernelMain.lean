import Pscv.Kernel.Checker

/-! Explicit independent Lean-kernel host, not the default compiler CLI. -/
def main (args : List String) : IO UInt32 := do
  match args with
  | ["--version"] =>
      IO.println "pscv-v6-kernel-dev 0.0.1 (official Lean 4.35.0-rc3)"
      return 0
  | ["kernel-empty-smoke"] =>
      let candidate : Pscv.CoreCandidate := {sourceId := "internal-checker-smoke", declarations := #[]}
      match ← Pscv.Kernel.checkCandidate candidate with
      | .ok report =>
          IO.println s!"Kernel accepted {report.checkedDeclarations} declarations (not PSCV-certified)"
          return 0
      | .error error =>
          IO.eprintln error
          return 1
  | _ =>
      IO.eprintln "PSCV_V6_KERNEL_HOST_UNSUPPORTED: only --version, kernel-empty-smoke"
      return 2
