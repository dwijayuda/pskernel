import Ps.Host.StandardExport
import Ps.Host.MonotonicityProbe

-- Audits use the retained candidate extension without changing selected pins.
-- Source construction and runtime qualification have their own executable.
def main (args : List String) : IO Unit := do
  match args with
  | ["foundation"] => PsV7Native.checkPartialFixpointFoundation
  | ["monotonicity"] =>
    PsV7Native.checkPartialFixpointMonotonicity
      (psStandardPartialFixpointExtend psSelfHostProdPrePartialFixpointPreludeEnvironment)
  | _ => throw (IO.userError "usage: pscv0_m3_partial_fixpoint_probe foundation|monotonicity")
