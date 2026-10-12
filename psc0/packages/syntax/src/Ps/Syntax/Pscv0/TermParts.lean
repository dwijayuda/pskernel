import Ps.Syntax.Pscv0.Binders
import Ps.Syntax.Pscv0.Universe

-- Records keep their source and replacement fields distinct until elaboration.
def psPscv0RecordUpdateAfterSource (read : PsPscv0TermReader)
    (opening : PsSourceSpan) (source : PsParseResult PsSyntaxTerm) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText source.cursor "with"
  let fields ← psParseProofScriptRecordFieldsWithFuel read
    (keyword.cursor.remaining.length + 1) keyword.cursor []
  let close ← psTokenCursorExpectText fields.cursor "}"
  return {
    value := .recordUpdate source.value fields.value (psSyntaxSpanJoin opening close.token.span)
    cursor := close.cursor }

def psPscv0ReadRecord (read : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let opening ← psTokenCursorExpectText cursor "{"
  if psTokenCursorAtText opening.cursor "}" || psTokenCursorStartsNamedAssignment opening.cursor then
    return ← psParseProofScriptRecordLiteral read cursor
  let source ← read opening.cursor
  psPscv0RecordUpdateAfterSource read opening.token.span source

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

-- Tuple values share the same right-nested Prod meaning as tuple patterns.
-- One comma introduces a tuple; a trailing comma is allowed only after
-- at least two terms. The type/application elaborator supplies implicit
-- Prod.mk type arguments instead of inventing a second tuple type system.
def psPscv0TupleConstruct (span : PsSourceSpan) :
    List PsSyntaxTerm → Except PsParseError PsSyntaxTerm
  | first :: second :: rest => do
    let right ← if rest.isEmpty then pure second
      else psPscv0TupleConstruct span (second :: rest)
    return .call (.reference (PsSyntaxName.mk ["_root_", "Prod", "mk"] span))
      [(none, first), (none, right)] span
  | _ => throw (.unexpectedEnd "tuple requires at least two elements")

def psPscv0TupleElements (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) (elementsRev : List PsSyntaxTerm) :
    Except PsParseError (PsParseResult (List PsSyntaxTerm)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor ")" then
      return { value := elementsRev.reverse, cursor }
    let next ← read cursor
    let elementsRev := next.value :: elementsRev
    if psTokenCursorAtText next.cursor "," then
      let comma ← psTokenCursorExpectText next.cursor ","
      psPscv0TupleElements read fuel comma.cursor elementsRev
    else
      return { value := elementsRev.reverse, cursor := next.cursor }

def psPscv0Primary (read : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  if psTokenCursorAtText cursor "{" then return ← psPscv0ReadRecord read cursor
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
  if psTokenCursorAtText annotated.cursor "," then
    let comma ← psTokenCursorExpectText annotated.cursor ","
    let elements ← psPscv0TupleElements read (cursor.remaining.length + 1)
      comma.cursor [annotated.value]
    let close ← psTokenCursorExpectText elements.cursor ")"
    let span := psSyntaxSpanJoin opening.token.span close.token.span
    return { value := ← psPscv0TupleConstruct span elements.value, cursor := close.cursor }
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

