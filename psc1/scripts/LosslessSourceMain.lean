import Ps.Syntax.Lossless
import Lean.Data.Json

/-! Native lexical transport only. This executable cannot admit proofs, emit a
compiler artifact, choose a checker, or publish edits. The host owns all paths. -/

def losslessPosition (p : PsSourcePos) : Lean.Json :=
  Lean.Json.mkObj [("byteOffset", Lean.toJson p.byteOffset),
    ("line", Lean.toJson p.line), ("column", Lean.toJson p.column)]

def losslessSpan (s : PsSourceSpan) : Lean.Json :=
  Lean.Json.mkObj [("start", losslessPosition s.start), ("stop", losslessPosition s.stop)]

def losslessTokenKind : PsTokenKind → String
  | .identifier => "identifier"
  | .natural => "natural"
  | .string => "string"
  | .character => "character"
  | .symbol => "symbol"
  | .endOfInput => "endOfInput"

def losslessToken (t : PsToken) : Lean.Json :=
  Lean.Json.mkObj [("kind", Lean.toJson (losslessTokenKind t.kind)),
    ("text", Lean.toJson t.text), ("span", losslessSpan t.span)]

def losslessKind : PsSourcePieceKind → String
  | .token => "token"
  | .whitespace => "whitespace"
  | .lineComment => "lineComment"
  | .blockComment => "blockComment"
  | .byteOrderMark => "byteOrderMark"
  | .unlexed => "unlexed"

def losslessPiece (p : PsSourcePiece) : Lean.Json :=
  Lean.Json.mkObj [("ordinal", Lean.toJson p.ordinal),
    ("kind", Lean.toJson (losslessKind p.kind)), ("span", losslessSpan p.span),
    ("raw", Lean.toJson p.raw), ("token", match p.token with
      | none => .null
      | some t => losslessToken t)]

def losslessDiagnostic : PsLexError → Lean.Json
  | .unterminatedBlockComment s => Lean.Json.mkObj [
      ("code", .str "unterminatedBlockComment"), ("span", losslessSpan s)]
  | .unterminatedString s => Lean.Json.mkObj [
      ("code", .str "unterminatedString"), ("span", losslessSpan s)]
  | .newlineInString s => Lean.Json.mkObj [
      ("code", .str "newlineInString"), ("span", losslessSpan s)]
  | .unterminatedCharacter s => Lean.Json.mkObj [
      ("code", .str "unterminatedCharacter"), ("span", losslessSpan s)]
  | .fuelExhausted => Lean.Json.mkObj [("code", .str "fuelExhausted"), ("span", .null)]
  | .invalidSource reason s => Lean.Json.mkObj [
      ("code", .str "invalidSource"), ("span", losslessSpan s), ("reason", .str reason)]

def losslessResponse (grammar : String) (t : PsLosslessTape) : Lean.Json :=
  Lean.Json.mkObj [("protocol", .str "psc1-lossless-capture/1"),
    ("grammar", .str grammar),
    ("status", .str (if t.lexicalError.isSome then "lexically-refused" else "accepted")),
    ("byteLength", Lean.toJson t.byteLength),
    ("pieces", .arr (t.pieces.toArray.map losslessPiece)),
    ("tokens", .arr (t.tokens.toArray.map losslessToken)),
    ("diagnostic", match t.lexicalError with
      | none => .null
      | some error => losslessDiagnostic error)]

def main (args : List String) : IO Unit := do
  let [grammar, inputPath, outputPath] := args
    | throw (IO.userError "PSC1_LOSSLESS_USAGE")
  let kind ← match grammar with
    | "lean" => pure PsLosslessGrammar.lean
    | "ps" => pure PsLosslessGrammar.proofScript
    | _ => throw (IO.userError "PSC1_LOSSLESS_GRAMMAR")
  let bytes ← IO.FS.readBinFile inputPath
  if bytes.size > 1048576 then throw (IO.userError "PSC1_LOSSLESS_SOURCE_LIMIT")
  let some source := String.fromUTF8? bytes
    | throw (IO.userError "PSC1_LOSSLESS_UTF8")
  let tape ← match psCaptureLossless kind source with
    | .ok value => pure value
    | .error .budgetExhausted => throw (IO.userError "PSC1_LOSSLESS_PIECE_LIMIT")
    | .error .invalidSpan => throw (IO.userError "PSC1_LOSSLESS_INVALID_SPAN")
  let response := (losslessResponse grammar tape).compress
  if response.utf8ByteSize > 33554432 then
    throw (IO.userError "PSC1_LOSSLESS_RESPONSE_LIMIT")
  IO.FS.writeFile outputPath response
