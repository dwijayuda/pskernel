import Ps.Host.StandardExport

-- Native-only authoring; the output remains unselected until exact replay,
-- immutable manifest and complete compiler qualification have succeeded.
def main (args : List String) : IO Unit := do
  let [output] := args | throw (IO.userError "usage: Pscv0M3MutualWellFoundedExport OUTPUT")
  PsV7Native.exportMutualWellFoundedCandidate (System.FilePath.mk output)
  IO.println "PSCV0_M3_PSUM_EXPORT: PASS pinned standalone closure and recursor comparison; selection pending"
