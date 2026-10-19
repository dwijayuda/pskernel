import Ps.BackendJs.Print
import Ps.Host.ProjectCompiler
import Ps.Bridge.Json

-- Coordinates are attached only to actual source declarations with names that
-- match emitted JSIR declarations. Generated helper code is deliberately unmapped.
structure PsDirectSourceOrigin where
  name : String
  position : PsSourcePos

def psDirectSourceOrigins (module : PsSyntaxModule) : List PsDirectSourceOrigin :=
  module.declarations.map fun declaration =>
    let original := psElabOriginSource declaration
    { name := psHostSyntaxDeclarationName declaration
      position := original.2.start }

-- A partial source map is preferable to fictitious coordinates. The older
-- lexer measures source columns in code points, not UTF-16; ASCII is the
-- precisely supported correspondence until origin coordinates are normalized.
def psDirectMapSourceCoordinatesSupported (source : String) : Bool :=
  source.toList.all fun c => c.toNat < 128

def psDirectBase64Digit (n : Nat) : String :=
  String.singleton ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".toList[n % 64]!)

partial def psDirectVLQDigits (n : Nat) : String :=
  let digit := n % 32
  let remaining := n / 32
  psDirectBase64Digit (digit + (if remaining == 0 then 0 else 32)) ++
    (if remaining == 0 then "" else psDirectVLQDigits remaining)

def psDirectVLQ (value : Int) : String :=
  let magnitude := value.natAbs
  psDirectVLQDigits (if value < 0 then magnitude * 2 - 1 else magnitude * 2)

structure PsDirectMapState where
  generatedLine : Nat := 0
  generatedColumn : Nat := 0
  sourceLine : Nat := 0
  sourceColumn : Nat := 0
  hasSegmentOnLine : Bool := false

def psDirectMapSegments
    (origins : List PsDirectSourceOrigin) :
    List PsJsGeneratedDeclarationSpan → PsDirectMapState → String
  | [], _ => ""
  | span :: rest, state =>
    match origins.find? (fun origin => origin.name == span.name) with
    | none => psDirectMapSegments origins rest state
    | some origin =>
      let sourceLine := origin.position.line - 1
      let sourceColumn := origin.position.column - 1
      let generatedLine := span.start.line
      let nextLine := generatedLine > state.generatedLine
      let semicolons :=
        String.join (List.replicate (generatedLine - state.generatedLine) ";")
      let columnBase := if nextLine then 0 else state.generatedColumn
      let comma := if !nextLine && state.hasSegmentOnLine then "," else ""
      let entry :=
        psDirectVLQ (Int.ofNat span.start.column - Int.ofNat columnBase) ++
        psDirectVLQ 0 ++
        psDirectVLQ (Int.ofNat sourceLine - Int.ofNat state.sourceLine) ++
        psDirectVLQ (Int.ofNat sourceColumn - Int.ofNat state.sourceColumn)
      let updated : PsDirectMapState := {
        generatedLine := generatedLine
        generatedColumn := span.start.column
        sourceLine := sourceLine
        sourceColumn := sourceColumn
        hasSegmentOnLine := true }
      semicolons ++ comma ++ entry ++ psDirectMapSegments origins rest updated

def psDirectSourceMap
    (sourcePath sourceText outputName : String)
    (parsed : PsSyntaxModule)
    (printed : PsJsPrintedModule) : String :=
  let mapping :=
    if psDirectMapSourceCoordinatesSupported sourceText then
      psDirectMapSegments (psDirectSourceOrigins parsed) printed.spans {}
    else ""
  "{\"version\":3,\"file\":" ++ psJsonQuote outputName ++
    ",\"sources\":[" ++ psJsonQuote sourcePath ++
    "],\"sourcesContent\":[" ++ psJsonQuote sourceText ++
    "],\"names\":[],\"mappings\":" ++ psJsonQuote mapping ++ "}\n"
