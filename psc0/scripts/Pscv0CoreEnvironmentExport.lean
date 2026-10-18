import Ps.Host.StandardExport

def main (args : List String) : IO Unit := do
  match args with
  | ["bootstrap", output] =>
      PsV7Native.exportCoreBootstrapCandidate (System.FilePath.mk output)
  | ["byte-word", output] =>
      PsV7Native.exportCoreByteWordCandidate (System.FilePath.mk output)
  | _ =>
      throw (IO.userError "usage: pscv0_core_environment_export (bootstrap|byte-word) OUTPUT")
