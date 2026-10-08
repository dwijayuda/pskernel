import Pscv.Core.Model
import Pscv.Extensions.Policy
import Pscv.Kernel.ProviderCatalog

/-!
Small native Lean-authored development CLI. Deliberately does not import
Lean.Declaration, Lean.Environment or the Lean elaborator. The checker is a
separately packaged native provider; this CLI is not a PSCV-CERT issuer.
-/
def main (args : List String) : IO UInt32 := do
  match args with
  | ["--version"] =>
      IO.println "pscv-v6-dev 0.0.1 (Lean 4.35.0-rc3 build host)"
      return 0
  | ["capabilities"] =>
      IO.println "P0: Lean-native lightweight source profiles and extension policy"
      IO.println "Logical checking is delegated to an isolated kernel provider"
      IO.println "NOT AVAILABLE: .ps parser, elaborator, PSCV-CERT, .proof.lean, backends"
      return 0
  | ["providers"] =>
      for provider in Pscv.Kernel.availableProviders do
        IO.println s!"{provider.npmPackage}@{provider.leanVersion} ({provider.kernelProfile})"
      IO.println "Lean 4.34 providers do not certify Lean 4.35 / V6 pscv-v1."
      return 0
  | ["core-smoke"] =>
      let profile := Pscv.Profile.verified
      IO.println s!"Source profile: {profile.identity}; no Core declarations checked or certified"
      return 0
  | _ =>
      IO.eprintln "PSCV_V6_COMPILATION_NOT_IMPLEMENTED: only --version, capabilities, providers, core-smoke"
      return 2
