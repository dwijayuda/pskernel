import Ps.Syntax.ParseLean
import Lean.Data.Json

/-! Host-only native reference spelling adapter. Input is ordinary generated Lean.
It inserts constructor shorthand dots at parser-owned pattern-name spans only.
It neither admits a graph nor grants publication or reference-replacement authority. -/

namespace Ps.NativeReferenceProjection

private def position (p : PsSourcePos) : Lean.Json :=
  Lean.Json.mkObj [("byteOffset", Lean.toJson p.byteOffset),
    ("line", Lean.toJson p.line), ("column", Lean.toJson p.column)]
private def span (s : PsSourceSpan) : Lean.Json :=
  Lean.Json.mkObj [("start", position s.start), ("stop", position s.stop)]
private def kind : PsTokenKind → String
  | .identifier => "identifier"
  | .natural => "natural"
  | .string => "string"
  | .character => "character"
  | .symbol => "symbol"
  | .endOfInput => "endOfInput"
private def parseError : PsParseError → Lean.Json
  | .fuelExhausted => Lean.Json.mkObj [("code", .str "fuelExhausted")]
  | .unexpectedEnd expected => Lean.Json.mkObj [
      ("code", .str "unexpectedEnd"), ("expected", .str expected)]
  | .expectedText expected actual location => Lean.Json.mkObj [
      ("code", .str "expectedText"), ("expected", .str expected),
      ("actual", .str actual), ("span", span location)]
  | .expectedKind expected actual location => Lean.Json.mkObj [
      ("code", .str "expectedKind"), ("expected", .str (kind expected)),
      ("actual", .str (kind actual)), ("span", span location)]
private def lexError : PsLexError → Lean.Json
  | .unterminatedBlockComment s => Lean.Json.mkObj [("code", .str "unterminatedBlockComment"), ("span", span s)]
  | .unterminatedString s => Lean.Json.mkObj [("code", .str "unterminatedString"), ("span", span s)]
  | .newlineInString s => Lean.Json.mkObj [("code", .str "newlineInString"), ("span", span s)]
  | .unterminatedCharacter s => Lean.Json.mkObj [("code", .str "unterminatedCharacter"), ("span", span s)]
  | .fuelExhausted => Lean.Json.mkObj [("code", .str "fuelExhausted")]
  | .invalidSource reason s => Lean.Json.mkObj [
      ("code", .str "invalidSource"), ("reason", .str reason), ("span", span s)]

private def patternNames : PsSyntaxPattern → List PsSyntaxName
  | .constructor name _ _ =>
      match name.segments with
      | [_] => [name]
      | _ => []
  | .bool _ _ => []
  | .wildcard _ => []

private partial def termNames : PsSyntaxTerm → List PsSyntaxName
  | .reference _ => []
  | .natural _ _ => []
  | .string _ _ => []
  | .character _ _ => []
  | .bool _ _ => []
  | .unit _ => []
  | .record fields _ => fields.flatMap (fun field => termNames field.2)
  | .app fn args _ => termNames fn ++ args.flatMap termNames
  | .arrayGetOptionE array index _ => termNames array ++ termNames index
  | .unary _ operand _ => termNames operand
  | .binary _ left right _ => termNames left ++ termNames right
  | .doE body _ => termNames body
  | .doBindE _ annotation action body _ =>
      annotation.toList.flatMap termNames ++ termNames action ++ termNames body
  | .doThenE action body _ => termNames action ++ termNames body
  | .doReturnE value _ => termNames value
  | .doLetMutE _ annotation value body _ =>
      annotation.toList.flatMap termNames ++ termNames value ++ termNames body
  | .doAssignE _ value body _ => termNames value ++ termNames body
  | .doIfE condition thenBody elseBody rest _ =>
      termNames condition ++ termNames thenBody ++ termNames elseBody ++ termNames rest
  | .doTryE body _ handler rest _ =>
      termNames body ++ termNames handler ++ termNames rest
  | .doEndE _ => []
  | .doForE _ collection body rest _ =>
      termNames collection ++ termNames body ++ termNames rest
  | .doForRangeE _ lower upper body rest _ =>
      termNames lower ++ termNames upper ++ termNames body ++ termNames rest
  | .doWhileE condition body rest _ =>
      termNames condition ++ termNames body ++ termNames rest
  | .lambda binders body _ =>
      binders.flatMap (fun binder => termNames binder.2) ++ termNames body
  | .forallE binders body _ =>
      binders.flatMap (fun binder => termNames binder.2) ++ termNames body
  | .letPatternE _ annotation value body _ =>
      annotation.toList.flatMap termNames ++ termNames value ++ termNames body
  | .letE _ annotation value body _ =>
      annotation.toList.flatMap termNames ++ termNames value ++ termNames body
  | .ifE condition thenBody elseBody _ =>
      termNames condition ++ termNames thenBody ++ termNames elseBody
  | .matchE scrutinee alternatives _ =>
      termNames scrutinee ++ alternatives.flatMap (fun alternative =>
        patternNames alternative.1 ++ termNames alternative.2.1)

private partial def declarationNames : PsSyntaxDeclaration → List PsSyntaxName
  | .definition _ binders type value _ =>
      binders.flatMap (fun binder => termNames binder.2) ++ termNames type ++ termNames value
  | .partialDefinition _ binders type value _ =>
      binders.flatMap (fun binder => termNames binder.2) ++ termNames type ++ termNames value
  | .theoremDecl _ binders type value _ =>
      binders.flatMap (fun binder => termNames binder.2) ++ termNames type ++ termNames value
  | .inductiveDecl _ parameters resultType constructors _ =>
      parameters.flatMap (fun binder => termNames binder.2) ++
        resultType.toList.flatMap termNames ++
        constructors.flatMap (fun item => item.fields.flatMap (fun field => termNames field.2))
  | .structureDecl _ parameters fields _ =>
      parameters.flatMap (fun binder => termNames binder.2) ++ fields.flatMap (fun field => termNames field.2)
  | .scopedDecl _ declaration => declarationNames declaration

private def moduleNames (parsed : PsSyntaxModule) : List PsSyntaxName :=
  parsed.declarations.flatMap declarationNames

private structure DotInsertion where
  offset : Nat
  stop : Nat
  name : String
  deriving BEq

private def insertionJson (edit : DotInsertion) : Lean.Json :=
  Lean.Json.mkObj [("byteOffset", Lean.toJson edit.offset),
    ("nameStopByteOffset", Lean.toJson edit.stop), ("name", .str edit.name)]

private def insertionFor (bytes : ByteArray) (name : PsSyntaxName) :
    Except String (Option DotInsertion) := do
  let [segment] := name.segments | throw "non-singleton pattern reached adapter"
  let some leaf := name.sourceSpan | throw "constructor pattern lacks a source span"
  let first := leaf.start.byteOffset
  let last := leaf.stop.byteOffset
  if first >= last || last > bytes.size then throw "constructor source span out of bounds"
  let some spelling := String.fromUTF8? (bytes.extract first last)
    | throw "constructor source span splits UTF8"
  if spelling != segment then throw "constructor source span does not equal its parsed name"
  if name.span.stop.byteOffset != last then throw "constructor outer span does not end at its name"
  if name.span.start.byteOffset == first then
    return some { offset := first, stop := last, name := segment }
  if name.span.start.byteOffset + 1 == first then
    let some punctuation := String.fromUTF8? (bytes.extract name.span.start.byteOffset first)
      | throw "constructor punctuation is not UTF8"
    if punctuation == "." then return none
  throw "unexpected constructor shorthand span"

private def insertDots (source : String) (names : List PsSyntaxName) :
    Except String (String × List DotInsertion) := do
  let bytes := source.toUTF8
  let mut requested : List DotInsertion := []
  for name in names do
    let candidate ← insertionFor bytes name
    if let some edit := candidate then requested := edit :: requested
  let sorted := requested.mergeSort (fun left right => decide (left.offset ≤ right.offset))
  let mut previous : Option DotInsertion := none
  let mut cursor := 0
  let mut output : ByteArray := ByteArray.empty
  let mut retained : List DotInsertion := []
  for edit in sorted do
    if let some prior := previous then
      if prior.offset == edit.offset then
        if prior != edit then throw "conflicting constructor source spans"
        continue
    if edit.offset < cursor then throw "overlapping constructor source spans"
    output := output ++ bytes.extract cursor edit.offset
    output := output.push 46
    output := output ++ bytes.extract edit.offset edit.stop
    cursor := edit.stop
    previous := some edit
    retained := edit :: retained
  output := output ++ bytes.extract cursor bytes.size
  if output.size > 1048576 then throw "projected source exceeds 1MiB"
  let some text := String.fromUTF8? output | throw "projected source is not UTF8"
  return (text, retained.reverse)

def project (moduleName source : String) : Except String Lean.Json := do
  if source.utf8ByteSize > 1048576 then throw "source exceeds 1MiB"
  let parsed ← (psParseLeanSource source).mapError (fun error =>
    "input parse refused: " ++ (match error with
      | .lex failure => (lexError failure).compress
      | .parse failure => (parseError failure).compress))
  let originalNames := moduleNames parsed
  let (projected, insertions) ← insertDots source originalNames
  let reparsed ← (psParseLeanSource projected).mapError (fun error =>
    "projected parse refused: " ++ (match error with
      | .lex failure => (lexError failure).compress
      | .parse failure => (parseError failure).compress))
  let newNames := moduleNames reparsed
  if originalNames.map (fun name => name.segments) != newNames.map (fun name => name.segments) then
    throw "constructor identities changed during projection"
  let (idempotent, extra) ← insertDots projected newNames
  if idempotent != projected || !extra.isEmpty then throw "projection is not idempotent"
  if parsed.declarations.length != reparsed.declarations.length then
    throw "declaration count changed during projection"
  if parsed.imports.map (fun item => item.moduleName.segments) !=
      reparsed.imports.map (fun item => item.moduleName.segments) then
    throw "imports changed during projection"
  return Lean.Json.mkObj [
    ("module", .str moduleName), ("text", .str projected),
    ("inputBytes", Lean.toJson source.utf8ByteSize), ("outputBytes", Lean.toJson projected.utf8ByteSize),
    ("constructorDots", Lean.toJson (insertions.map insertionJson)),
    ("reparsed", .bool true), ("idempotent", .bool true)]

end Ps.NativeReferenceProjection

private def demandProjection (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("PSC1_NATIVE_REFERENCE_PROJECTION:" ++ message))

def main (args : List String) : IO Unit := do
  let [inputPath, outputPath] := args
    | throw (IO.userError "PSC1_NATIVE_REFERENCE_PROJECTION:usage: request.json response.json")
  let bytes ← IO.FS.readBinFile inputPath
  demandProjection (bytes.size ≤ 33554432) "request exceeds 32MiB"
  let some input := String.fromUTF8? bytes
    | throw (IO.userError "PSC1_NATIVE_REFERENCE_PROJECTION:request is not UTF8")
  let value ← match Lean.Json.parse input with
    | .ok parsed => pure parsed
    | .error _ => throw (IO.userError "PSC1_NATIVE_REFERENCE_PROJECTION:invalid JSON")
  let rows ← match value with
    | .arr values =>
        match values.toList with
        | [.str "psc1-native-reference-projection/1", .arr sources] => pure sources
        | _ => throw (IO.userError "PSC1_NATIVE_REFERENCE_PROJECTION:request shape")
    | _ => throw (IO.userError "PSC1_NATIVE_REFERENCE_PROJECTION:request shape")
  demandProjection (rows.size > 0 && rows.size ≤ 256) "module count"
  let mut seen : List String := []
  let mut modules : Array Lean.Json := #[]
  for row in rows do
    let (moduleName, source) ← match row with
      | .arr values =>
          match values.toList with
          | [.str name, .str text] => pure (name, text)
          | _ => throw (IO.userError "PSC1_NATIVE_REFERENCE_PROJECTION:source row shape")
      | _ => throw (IO.userError "PSC1_NATIVE_REFERENCE_PROJECTION:source row shape")
    demandProjection (!moduleName.isEmpty && moduleName.utf8ByteSize ≤ 1024) "module name"
    demandProjection (!seen.contains moduleName) "duplicate module"
    seen := moduleName :: seen
    let projected ← match Ps.NativeReferenceProjection.project moduleName source with
      | .ok result => pure result
      | .error message =>
          throw (IO.userError ("PSC1_NATIVE_REFERENCE_PROJECTION:" ++ moduleName ++ ":" ++ message))
    modules := modules.push projected
  let result := (Lean.Json.mkObj [
    ("schema", .str "psc1-native-reference-projection/1"), ("status", .str "candidate-only"),
    ("sourceGrammar", .str "lean"), ("inputKind", .str "ordinary-source-printer-output"),
    ("modules", .arr modules), ("admissionAuthority", .bool false),
    ("sourceFilesWritten", .bool false), ("formalSourcePreservationProof", .bool false)]).compress
  demandProjection (result.utf8ByteSize ≤ 33554432) "response exceeds 32MiB"
  IO.FS.writeFile outputPath result
  (← IO.getStdout).putStrLn ("PSC1_NATIVE_REFERENCE_PROJECTION: " ++
    toString modules.size ++ " candidate modules; fresh graph admission and native build still required")
