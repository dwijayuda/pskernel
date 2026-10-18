import Ps.Host.StandardExport
import Ps.Host.StandardManifest
import Ps.Environment.StandardPSum

-- Native-only authoring; the output remains unselected until exact replay,
-- immutable manifest and complete compiler qualification have succeeded.
def main (args : List String) : IO Unit := do
  let [output] := args | throw (IO.userError "usage: Pscv0M3MutualWellFoundedExport OUTPUT")
  PsV7Native.exportMutualWellFoundedCandidate (System.FilePath.mk output)
  IO.println "PSCV0_M3_PSUM_EXPORT: PASS pinned standalone closure and exact recursor comparison; independent candidate digests follow"
  let before := psSelfHostProdPreMutualWellFoundedPreludeEnvironment
  let candidate := psStandardPSumExtend before
  if candidate.declarations.length != before.declarations.length + 5 ||
      candidate.classes.length != before.classes.length ||
      candidate.instances.entries.length != before.instances.entries.length then
    throw (IO.userError "PSum candidate changed more than its exact five-declaration roster")
  IO.println ("PSCV0_M3_PSUM_CANDIDATE_FNV " ++ psStandardSnapshotFingerprint candidate)
  IO.println ("PSCV0_M3_PSUM_CANDIDATE_SNAPSHOT " ++ psStandardSnapshotSHA256Fingerprint candidate)
  IO.println ("PSCV0_M3_PSUM_CANDIDATE_SURFACE " ++ PsV7Native.standardSurfaceManifestSHA256 candidate)
