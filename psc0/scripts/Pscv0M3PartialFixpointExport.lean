import Ps.Host.StandardExport

/-!
Native-only P1 order-library export probe.

Run from psc0/v7-native after building Ps.Host.StandardExport:
  lake env lean --run ../scripts/Pscv0M3PartialFixpointExport.lean OUTPUT

The native reference environment is used only to collect pinned declarations.
Every emitted portable declaration is converted and replayed through the
existing Standard authoring checks, including complete proof dependencies,
the approved logical-axiom boundary, and recursor-rule comparison. A refused
candidate raises an error and does not produce a successful export marker.

The output is a candidate asset, not an installed Standard extension.
No recursive P1 program is executed by this probe.
-/

def main (args : List String) : IO Unit := do
  let [output] := args
    | throw (IO.userError
        "usage: Pscv0M3PartialFixpointExport.lean OUTPUT")
  PsV7Native.exportPartialFixpointCandidate (System.FilePath.mk output)
  IO.println
    "PSCV0_M3_P1_EXPORT: PASS checked pinned logical closure; elaborator, registration and runtime qualification remain pending"
