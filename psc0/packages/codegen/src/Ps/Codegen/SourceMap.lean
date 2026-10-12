import Ps.Codegen.Provenance
import Ps.Codegen.Names
import Ps.Codegen.Doc
import Ps.Bridge.Json

-- ECMA-426 source-map v3. Coordinates are computed from final layout, not
-- character-count guesses or generated-byte ranges masquerading as mappings.
structure PsMapSegment where
  line : Nat
  column : Nat
  source : Option (PsSourceCoordinate × Nat) := none

def psMapBase64 : String := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
def psMapVlqDigits : Nat → Nat → String
  | 0, _ => ""
  | fuel + 1, value =>
    let digit := value % 32
    let rest := value / 32
    let char := psMapBase64.toList[digit + (if rest == 0 then 0 else 32)]!
    String.singleton char ++ (if rest == 0 then "" else psMapVlqDigits fuel rest)

def psMapVlq (value : Int) : String :=
  psMapVlqDigits (value.natAbs + 1).log2.succ
    (2 * value.natAbs + (if value < 0 then 1 else 0))

structure PsMapState where
  line : Nat := 0
  column : Nat := 0
  originalLine : Nat := 0
  originalColumn : Nat := 0
  name : Nat := 0
  hasSegment : Bool := false
  chunks : List String := []

def psMapEncode (segments : List PsMapSegment) : String :=
  let state := segments.foldl (fun state segment =>
    let newline := segment.line != state.line
    let separator := if newline then String.ofList (List.replicate (segment.line - state.line) ';')
      else if state.hasSegment then "," else ""
    let column := if newline then 0 else state.column
    let start := separator ++ psMapVlq (Int.ofNat segment.column - Int.ofNat column)
    let state := { state with line := segment.line, column := segment.column, hasSegment := true }
    match segment.source with
    | none => { state with chunks := start :: state.chunks }
    | some (original,name) =>
      let text := start ++ "A" ++
        psMapVlq (Int.ofNat original.line - Int.ofNat state.originalLine) ++
        psMapVlq (Int.ofNat original.column - Int.ofNat state.originalColumn) ++
        psMapVlq (Int.ofNat name - Int.ofNat state.name)
      { state with
        originalLine := original.line
        originalColumn := original.column
        name := name
        chunks := text :: state.chunks }) ({} : PsMapState)
  String.join state.chunks.reverse

def psSourceMap (context : PsEmissionContext) (symbols : List PsCodegenSymbol)
    (rendered : PsRenderedDoc) : Except String String := do
  let input := psSourceCoordinates context.sourceText
  let output := psSourceCoordinates rendered.text
  let mut segments : List PsMapSegment := []
  for range in rendered.ranges do
    let some symbol := symbols.find? (fun s => s.outputName == range.symbol) | continue
    let some origin := psSourceOriginFor context symbol.semanticName | continue
    let original ← psSourceCoordinateAt input origin.span.start.byteOffset
    let start ← psSourceCoordinateAt output range.startByte
    let stop ← psSourceCoordinateAt output range.endByte
    let name := (symbols.map (·.semanticName)).idxOf symbol.semanticName
    for line in List.range (stop.line - start.line + 1) do
      segments := {
        line := start.line + line
        column := if line == 0 then start.column else 0
        source := some (original, name) } :: segments
    segments := { line := stop.line, column := stop.column } :: segments
  let mappings := psMapEncode segments.reverse
  return "{\"version\":3,\"file\":" ++ psJsonQuote (context.outputStem ++ ".js") ++
    ",\"sources\":[" ++ psJsonQuote context.sourceName ++ "],\"sourcesContent\":[" ++
    psJsonQuote context.sourceText ++ "],\"names\":[" ++
    String.intercalate "," (symbols.map fun s => psJsonQuote s.semanticName) ++
    "],\"mappings\":" ++ psJsonQuote mappings ++ "}"
