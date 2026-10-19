import Ps.Host.DirectSourceMap

-- An unmapped span emits one VLQ field without affecting the previous
-- source-coordinate deltas, including when the gap is on the same line.
def main : IO Unit := do
  let position := PsJsGeneratedPosition.mk 7 0 7 false
  let span : PsJsGeneratedDeclarationSpan := {
    name := "generated"
    start := position
    stop := position
  }
  let previous : PsDirectMapState := {
    generatedLine := 0
    generatedColumn := 2
    sourceLine := 3
    sourceColumn := 5
    hasSegmentOnLine := true
  }
  let unmapped := psDirectMapUnmapped span previous
  if unmapped.1 != ",K" || unmapped.2.generatedColumn != 7
    || unmapped.2.sourceLine != 3 || unmapped.2.sourceColumn != 5 then
    throw (IO.userError "PSC1_DIRECT_UNMAPPED_SEGMENT_FAILED")
  if psDirectMapSegments "" [] [span] {} != "O" then
    throw (IO.userError "PSC1_DIRECT_UNMAPPED_ONLY_FAILED")
  IO.println "PSC1_DIRECT_SOURCE_MAP_REGRESSION: PASS"
