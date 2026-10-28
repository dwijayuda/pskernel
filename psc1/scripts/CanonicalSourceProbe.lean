import Ps.Syntax.ParseLean
import Lean.Data.Json

namespace Ps.CanonicalSourceProbe

def position (p : PsSourcePos) : Lean.Json :=
  Lean.Json.mkObj [("byteOffset", Lean.toJson p.byteOffset),
    ("line", Lean.toJson p.line), ("column", Lean.toJson p.column)]
def span (s : PsSourceSpan) : Lean.Json :=
  Lean.Json.mkObj [("start", position s.start), ("stop", position s.stop)]
def kind : PsTokenKind → String
  | .identifier => "identifier"
  | .natural => "natural"
  | .string => "string"
  | .character => "character"
  | .symbol => "symbol"
  | .endOfInput => "endOfInput"
def parseError : PsParseError → Lean.Json
  | .fuelExhausted => Lean.Json.mkObj [("code", .str "fuelExhausted")]
  | .unexpectedEnd expected => Lean.Json.mkObj [
      ("code", .str "unexpectedEnd"), ("expected", .str expected)]
  | .expectedText expected actual location => Lean.Json.mkObj [
      ("code", .str "expectedText"), ("expected", .str expected),
      ("actual", .str actual), ("span", span location)]
  | .expectedKind expected actual location => Lean.Json.mkObj [
      ("code", .str "expectedKind"), ("expected", .str (kind expected)),
      ("actual", .str (kind actual)), ("span", span location)]
def lexError : PsLexError → Lean.Json
  | .unterminatedBlockComment s => Lean.Json.mkObj [("code", .str "unterminatedBlockComment"), ("span", span s)]
  | .unterminatedString s => Lean.Json.mkObj [("code", .str "unterminatedString"), ("span", span s)]
  | .newlineInString s => Lean.Json.mkObj [("code", .str "newlineInString"), ("span", span s)]
  | .unterminatedCharacter s => Lean.Json.mkObj [("code", .str "unterminatedCharacter"), ("span", span s)]
  | .fuelExhausted => Lean.Json.mkObj [("code", .str "fuelExhausted")]
  | .invalidSource reason s => Lean.Json.mkObj [
      ("code", .str "invalidSource"), ("reason", .str reason), ("span", span s)]
def inspect (file source : String) : Lean.Json :=
  match psParseLeanSource source with
  | .ok parsed => Lean.Json.mkObj [("path", .str file), ("status", .str "accepted-parse-only"),
      ("declarations", Lean.toJson parsed.declarations.length),
      ("imports", Lean.toJson (parsed.imports.map (fun i => String.intercalate "." i.moduleName.segments)))]
  | .error (.lex error) => Lean.Json.mkObj [("path", .str file),
      ("status", .str "refused"), ("phase", .str "lex"), ("error", lexError error)]
  | .error (.parse error) => Lean.Json.mkObj [("path", .str file),
      ("status", .str "refused"), ("phase", .str "parse"), ("error", parseError error)]
end Ps.CanonicalSourceProbe

def main (args : List String) : IO Unit := do
  let output :: files := args | throw (IO.userError "canonical parse probe requires output path and input paths")
  let mut rows : Array Lean.Json := #[]
  for file in files do
    let bytes ← IO.FS.readBinFile file
    if bytes.size > 1048576 then throw (IO.userError ("source too large: " ++ file))
    let some source := String.fromUTF8? bytes | throw (IO.userError ("invalid UTF8: " ++ file))
    rows := rows.push (Ps.CanonicalSourceProbe.inspect file source)
  let result := Lean.Json.mkObj [("schema", .str "psc1-canonical-parse-probe/1"),
    ("admissionAuthority", .bool false), ("files", .arr rows)]
  IO.FS.writeFile output result.compress
  (← IO.getStdout).putStrLn ("PSC1_CANONICAL_PARSE_PROBE: " ++ result.compress)
