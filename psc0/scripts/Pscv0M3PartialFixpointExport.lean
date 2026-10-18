import Ps.Host.StandardExport

/-!
Native-only P1 order-library export probe.

Run from psc0/v7-native using Lake's owned host module dependencies:
  lake build pscv0_m3_partial_fixpoint_export
  .lake/build/bin/pscv0_m3_partial_fixpoint_export OUTPUT

The native reference environment is used only to collect pinned declarations.
Every emitted portable declaration is converted and replayed through the
existing Standard authoring checks, including complete proof dependencies,
the approved logical-axiom boundary, and recursor-rule comparison. A refused
candidate raises an error and does not produce a successful export marker.

The output is a candidate asset, not an installed Standard extension.
No recursive P1 program is executed by this probe.
-/

def main (args : List String) : IO Unit := do
  match args with
  | [output] =>
    PsV7Native.exportPartialFixpointCandidate (System.FilePath.mk output)
    IO.println
      "PSCV0_M3_P1_EXPORT: PASS checked pinned logical closure; elaborator, registration and runtime qualification remain pending"
  | ["--option-bind", output] =>
    PsV7Native.exportOptionBindCandidate (System.FilePath.mk output)
    IO.println
      "PSCV0_M3_OPTION_BIND_EXPORT: PASS checked additive pinned logical closure; selection, registration and runtime qualification remain pending"
  | _ =>
    throw (IO.userError
      "usage: Pscv0M3PartialFixpointExport.lean [--option-bind] OUTPUT")
