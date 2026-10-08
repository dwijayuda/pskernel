import Pscv.Core.Model
import Pscv.Extensions.Policy

/-!
Small native development CLI. Deliberately DOES NOT import the Lean kernel
checker/Environment: a selected checker belongs in an isolated provider tool.
No user source parsing or PSCV-CERT is implemented in this development CLI.
-/
def main (args : List String) : IO UInt32 := do
  match args with
  | ["--version"] =>
      IO.println "pscv-v6-dev 0.0.1 (Lean 4.35.0-rc3 build host)"
      return 0
  | ["capabilities"] =>
      IO.println "P0: native Lean-written Core models and declarative extension policy"
      IO.println "Kernel checking lives in a separate native provider executable"
      IO.println "NOT AVAILABLE: .ps parser, elaborator, PSCV-CERT, .proof.lean, backends"
      return 0
  | ["core-smoke"] =>
      let candidate : Pscv.CoreCandidate := {sourceId := "internal-smoke", declarations := #[]}
      IO.println s!"Candidate declarations: {candidate.declarations.size}; NOT checked or certified"
      return 0
  | _ =>
      IO.eprintln "PSCV_V6_COMPILATION_NOT_IMPLEMENTED: only --version, capabilities, core-smoke"
      return 2
