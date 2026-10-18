import Ps.Host.StandardExport
import Ps.Host.MonotonicityProbe

-- Audits use retained candidate extensions without changing selected pins.
-- The original Order audit keeps its own frozen base. Option bind is replayed
-- independently after the frozen recursor and LawfulBEq stage.
def main (args : List String) : IO Unit := do
  match args with
  | ["foundation"] => PsV7Native.checkPartialFixpointFoundation
  | ["option-bind"] =>
    PsV7Native.checkOptionBindFoundation
      (System.FilePath.mk "../packages/environment/src/Ps/Environment/StandardOptionBindData.lean")
  | ["monotonicity"] =>
    PsV7Native.checkPartialFixpointMonotonicity
      (psStandardOptionBindExtend psSelfHostProdPreOptionBindPreludeEnvironment)
  | _ => throw (IO.userError
      "usage: pscv0_m3_partial_fixpoint_probe foundation|option-bind|monotonicity")
