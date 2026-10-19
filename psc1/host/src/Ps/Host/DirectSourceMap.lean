import Ps.BackendJs.Print
import Ps.Host.ProjectCompiler
import Ps.Bridge.Json

structure PsDirectSourceOrigin where
  name : String
  position : PsSourcePos

def psDirectSourceOrigins (module : PsSyntaxModule) : List PsDirectSourceOrigin :=
  module.declarations.map fun declaration => {
    name := psHostSyntaxDeclarationName declaration
    position := (psElabOriginSource declaration).2.start
  }

-- Parser columns are 1-based Unicode scalar positions; maps require zero-based
-- UTF-16 columns. Invalid zero coordinates cannot become a valid origin.
def psDirectSourceUtf16Column
    (source : String) (position : PsSourcePos) : Option Nat := do
  if position.line == 0 || position.column == 0 then none else do
    let line ← (source.splitOn "\n")[position.line - 1]?
    let prefixSize := position.column - 1
    if prefixSize > line.toList.length then none
    else some ((line.toList.take prefixSize).foldl
      (fun n c => n + (if c.toNat > 65535 then 2 else 1)) 0)

def psDirectBase64Digit (n : Nat) : String :=
  String.singleton ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".toList[n % 64]!)

partial def psDirectVLQDigits (n : Nat) : String :=
  let digit := n % 32
  let remaining := n / 32
  psDirectBase64Digit (digit + (if remaining == 0 then 0 else 32)) ++
    (if remaining == 0 then "" else psDirectVLQDigits remaining)

def psDirectVLQ (value : Int) : String :=
  -- Negative values set the low sign bit; they do not subtract from magnitude.
  -- Signed -2^31 has the specification's special code 1.
  psDirectVLQDigits (if value == -2147483648 then 1
    else if value < 0 then value.natAbs * 2 + 1 else value.natAbs * 2)

structure PsDirectMapState where
  generatedLine : Nat := 0
  generatedColumn : Nat := 0
  sourceLine : Nat := 0
  sourceColumn : Nat := 0
  hasSegmentOnLine : Bool := false

def psDirectMapUnmapped
    (span : PsJsGeneratedDeclarationSpan)
    (state : PsDirectMapState) : String × PsDirectMapState :=
  let generatedLine := span.start.line
  let nextLine := generatedLine > state.generatedLine
  let semicolons := String.join (List.replicate (generatedLine - state.generatedLine) ";")
  let columnBase := if nextLine then 0 else state.generatedColumn
  let comma := if !nextLine && state.hasSegmentOnLine then "," else ""
  let entry := psDirectVLQ (Int.ofNat span.start.column - Int.ofNat columnBase)
  let updated : PsDirectMapState := {
    state with
    generatedLine := generatedLine
    generatedColumn := span.start.column
    hasSegmentOnLine := true
  }
  (semicolons ++ comma ++ entry, updated)

def psDirectMapSegments
    (sourceText : String) (origins : List PsDirectSourceOrigin) :
    List PsJsGeneratedDeclarationSpan → PsDirectMapState → String
  | [], _ => ""
  | span :: rest, state =>
    match origins.find? (fun origin => origin.name == span.name) with
    | none =>
      let unmapped := psDirectMapUnmapped span state
      unmapped.1 ++ psDirectMapSegments sourceText origins rest unmapped.2
    | some origin =>
      match psDirectSourceUtf16Column sourceText origin.position with
      | none =>
        let unmapped := psDirectMapUnmapped span state
        unmapped.1 ++ psDirectMapSegments sourceText origins rest unmapped.2
      | some sourceColumn =>
        let sourceLine := origin.position.line - 1
        let generatedLine := span.start.line
        let nextLine := generatedLine > state.generatedLine
        let semicolons := String.join (List.replicate (generatedLine - state.generatedLine) ";")
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
          hasSegmentOnLine := true
        }
        semicolons ++ comma ++ entry ++ psDirectMapSegments sourceText origins rest updated

-- Compatibility API. Production DirectJS/TS maps observe the final formatted
-- AST and the complete captured source closure in the host-tools package.
def psDirectSourceMap
    (sourcePath sourceText outputName : String)
    (parsed : PsSyntaxModule) (printed : PsJsPrintedModule) : String :=
  let mapping := psDirectMapSegments sourceText (psDirectSourceOrigins parsed) printed.spans {}
  "{\"version\":3,\"file\":" ++ psJsonQuote outputName ++
    ",\"sources\":[" ++ psJsonQuote sourcePath ++
    "],\"sourcesContent\":[" ++ psJsonQuote sourceText ++
    "],\"names\":[],\"mappings\":" ++ psJsonQuote mapping ++ "}\n"
