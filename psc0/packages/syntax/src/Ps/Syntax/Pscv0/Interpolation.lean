import Ps.Syntax.Pscv0.Binders
import Ps.Syntax.Lexer

-- Interpolation is ordinary expression elaboration through the checked
-- ToString dictionary and HAppend instance. There is no host substitution,
-- unchecked constant folding or second term grammar.
def psPscv0InterpolationPart (read : PsPscv0TermReader)
    (token : PsToken) (part : PsLexInterpolationPart) :
    Except PsParseError PsSyntaxTerm := do
  match part with
  | .literal source =>
    return .string ("\"" ++ source ++ "\"") token.span
  | .expression source =>
    let tokens ← (psLexProofScript source).mapError fun _ =>
      PsParseError.expectedText "valid embedded interpolation source" source token.span
    let parsed ← read (PsTokenCursor.mk tokens)
    if !psTokenCursorDone parsed.cursor then
      throw (psProofScriptExpectedError "end of interpolated expression" parsed.cursor)
    return .call .positionalPrefix
      (.reference (PsSyntaxName.mk ["_root_", "ToString", "toString"] token.span))
      [(none, parsed.value)] token.span

def psPscv0Interpolate (read : PsPscv0TermReader)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let value ← psTokenCursorExpectKind cursor .string
  let some parts := psLexInterpolationParts? value.token.text
    | throw (PsParseError.expectedText
      "well-formed s! interpolation" value.token.text value.token.span)
  let terms ← parts.mapM (psPscv0InterpolationPart read value.token)
  let append := fun (left right : PsSyntaxTerm) =>
    PsSyntaxTerm.call .positionalPrefix
      (.reference (PsSyntaxName.mk ["_root_", "HAppend", "hAppend"] value.token.span))
      [(none, left), (none, right)] value.token.span
  let result := match terms with
    | [] => PsSyntaxTerm.string "\"\"" value.token.span
    | first :: rest => rest.foldl append first
  return { value := result, cursor := value.cursor }
