import Ps.Host.StandardExport

def main (args : List String) : IO Unit := do
  match args with
  | ["ext", output] =>
      PsV7Native.exportCoreExtCandidate (System.FilePath.mk output)
  | ["bootstrap", output] =>
      PsV7Native.exportCoreBootstrapCandidate (System.FilePath.mk output)
  | ["foundation-metadata", output] =>
      PsV7Native.auditCoreFoundationCandidateMetadata (System.FilePath.mk output)
  | ["foundation", output] =>
      PsV7Native.exportCoreFoundationCandidate (System.FilePath.mk output)
  | ["byte-word", output] =>
      PsV7Native.exportCoreByteWordCandidate (System.FilePath.mk output)
  | ["compiler", output] =>
      PsV7Native.exportCoreCompilerCandidate (System.FilePath.mk output)
  | _ =>
      throw (IO.userError "usage: pscv0_core_environment_export (ext|bootstrap|foundation|foundation-metadata|byte-word|compiler) OUTPUT")
