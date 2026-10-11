import Ps.Syntax.Pscv0.Binders
import Ps.Syntax.Pscv0.Universe

-- These readers preserve source intent. Semantic argument insertion belongs to
-- the application elaborator, never to parsing or token rewriting.
def psPscv0ReadAscription (read : PsPscv0TermReader)
    (value : PsParseResult PsSyntaxTerm) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  if !psTokenCursorAtText value.cursor ":" then return value
  let colon ← psTokenCursorExpectText value.cursor ":"
  let type ← read colon.cursor
  return {
    value := .ascription value.value type.value
      (psSyntaxSpanJoin (psSyntaxTermSpan value.value) (psSyntaxTermSpan type.value))
    cursor := type.cursor }

def psPscv0Primary (read : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  if ["Type", "Sort", "Prop"].any (psTokenCursorAtText cursor) then
    return ← psPscv0ReadSort cursor
  if psTokenCursorAtText cursor "_" then
    let token ← psTokenCursorExpectText cursor "_"
    return { value := .hole token.token.span, cursor := token.cursor }
  if !psTokenCursorAtText cursor "(" then
    return ← psParseProofScriptPrimary read cursor
  let opening ← psTokenCursorExpectText cursor "("
  if psTokenCursorAtText opening.cursor ")" then
    return ← psParseProofScriptPrimary read cursor
  let inner ← read opening.cursor
  let annotated ← psPscv0ReadAscription read inner
  let close ← psTokenCursorExpectText annotated.cursor ")"
  return {
    value := psProofScriptTermWithSpan annotated.value
      (psSyntaxSpanJoin opening.token.span close.token.span)
    cursor := close.cursor }

def psPscv0CallArguments (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) (named : Bool)
    (acc : List (Prod (Option PsSyntaxName) PsSyntaxTerm)) :
    Except PsParseError
      (PsParseResult (List (Prod (Option PsSyntaxName) PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor ")" then
      return { value := acc.reverse, cursor }
    let (label, start) ←
      if psTokenCursorStartsNamedAssignment cursor then do
        let name ← psTokenCursorExpectKind cursor .identifier
        let assign ← psTokenCursorExpectText name.cursor ":="
        pure (some (PsSyntaxName.mk [name.token.text] name.token.span), assign.cursor)
      else if named then
        throw (psProofScriptExpectedError "named argument after named argument" cursor)
      else pure (none, cursor)
    let value ← read start
    let next := (label, value.value) :: acc
    if psTokenCursorAtText value.cursor "," then
      let comma ← psTokenCursorExpectText value.cursor ","
      psPscv0CallArguments read fuel comma.cursor (named || label.isSome) next
    else
      let _ ← psTokenCursorExpectText value.cursor ")"
      return { value := next.reverse, cursor := value.cursor }

def psPscv0Postfix (read : PsPscv0TermReader) (fuel : Nat)
    (current : PsSyntaxTerm) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !(psTokenCursorAtText cursor "(" && psProofScriptCallAdjacent current cursor) then
      return { value := current, cursor }
    let opening ← psTokenCursorExpectText cursor "("
    let args ← psPscv0CallArguments read (fuel + 1) opening.cursor false []
    let close ← psTokenCursorExpectText args.cursor ")"
    psPscv0Postfix read fuel
      (.call current args.value (psSyntaxSpanJoin (psSyntaxTermSpan current) close.token.span))
      close.cursor

