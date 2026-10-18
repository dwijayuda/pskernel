import Ps.Host.StandardExport

-- Native-only candidate authoring. The selected foundation and its strict
-- fingerprints remain unchanged until independently qualified publication.
def main (args : List String) : IO Unit := do
  let [output] := args
    | throw (IO.userError "usage: Pscv0M3RecursorSurfaceExport OUTPUT")
  PsV7Native.exportRecursorSurfaceCandidate (System.FilePath.mk output)
  IO.println "PSCV0_M3_RECURSOR_SOURCE_CANDIDATE: PASS pinned complete binder metadata, preserved selected logical types, fresh kernel replay and symbolic iota rules and independently measured candidate digests; unselected"
