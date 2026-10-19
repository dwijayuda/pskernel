import Ps.Host.DirectSourceMap

def psMapSpan (name : String) (line column : Nat) :
    PsJsGeneratedDeclarationSpan :=
  let pos : PsJsGeneratedPosition := {
    byteOffset := 0
    line := line
    column := column
    previousCR := false }
  { name := name, start := pos, stop := pos }

def psMapOrigin (name : String) : PsDirectSourceOrigin :=
  { name := name
    position := { byteOffset := 0, line := 1, column := 1 } }

def main : IO Unit := do
  let origins := [psMapOrigin "first", psMapOrigin "second"]
  let sameLine := psDirectMapSegments "a" origins
    [psMapSpan "first" 0 0, psMapSpan "generatedOnly" 0 5,
     psMapSpan "second" 0 10] {}
  if sameLine != "AAAA,K,KAAA" then
    throw (IO.userError ("PSC1_UNMAPPED_SAME_LINE: " ++ sameLine))
  let nextLine := psDirectMapSegments "a" origins
    [psMapSpan "first" 0 0, psMapSpan "generatedOnly" 1 0,
     psMapSpan "second" 1 2] {}
  if nextLine != "AAAA;A,EAAA" then
    throw (IO.userError ("PSC1_UNMAPPED_NEXT_LINE: " ++ nextLine))
  let unknownStart := psDirectMapSegments "a" origins
    [psMapSpan "generatedOnly" 0 0, psMapSpan "second" 0 4] {}
  if unknownStart != "A,IAAA" then
    throw (IO.userError ("PSC1_UNMAPPED_START: " ++ unknownStart))
  IO.println "PSC1_DIRECT_SOURCE_MAP_UNMAPPED_GAPS: PASS"
