import Ps.BackendEcma.Module

-- Compatibility name for the native readable emitter. Legacy bootstrap APIs
-- remain separate; their string emitter is outside the active native closure.
def psTsEmitReadable (ir : PsVerifiedIrModule) (stem : String := "module") :
    Except String PsEmissionArtifact :=
  PsEcma.emit ir .typescript { outputStem := stem }
