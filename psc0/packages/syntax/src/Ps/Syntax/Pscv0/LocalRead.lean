import Ps.Syntax.Pscv0.TermParts

structure PsPscv0LocalDeclaration where
  name : PsSyntaxName
  type : Option PsSyntaxTerm
  value : PsSyntaxTerm
  span : PsSourceSpan

-- Shared header for term and tactic facts. The body is owned by the caller.
def psPscv0ReadLocal (read readType : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsPscv0LocalDeclaration) := do
  let some keyword := psTokenCursorAdvance cursor | throw (.unexpectedEnd "local declaration")
  let named ← if psTokenCursorAtText keyword.cursor ":" ||
      psTokenCursorAtText keyword.cursor ":=" then
      pure (PsParseResult.mk (PsSyntaxName.mk ["this"] keyword.token.span) keyword.cursor)
    else do
      let name ← psTokenCursorExpectKind keyword.cursor .identifier
      pure (PsParseResult.mk ((psSyntaxNameFromToken name.token)) name.cursor)
  let type ← if psTokenCursorAtText named.cursor ":" then do
      let colon ← psTokenCursorExpectText named.cursor ":"
      let type ← readType colon.cursor
      pure (PsParseResult.mk (some type.value) type.cursor)
    else pure (PsParseResult.mk none named.cursor)
  let assign ← psTokenCursorExpectText type.cursor ":="
  let value ← read assign.cursor
  return {
    value := {
      name := named.value
      type := type.value
      value := value.value
      span := psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan value.value) }
    cursor := value.cursor }

def psPscv0ReadHave (read readType continuation : PsPscv0TermReader)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let fact ← psPscv0ReadLocal read readType cursor
  let next ← psParseProofScriptBodySeparator fact.value.span.stop fact.cursor
  let body ← continuation next
  return {
    value := .haveE fact.value.name fact.value.type fact.value.value body.value
      (psSyntaxSpanJoin fact.value.span (psSyntaxTermSpan body.value))
    cursor := body.cursor }

-- Pinned Parser.Term.sufficesDecl has an optional binder and mandatory type.
-- Its term macro lowers to have with the continuation as its value.
def psPscv0ReadSuffices (read readType : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsPscv0LocalDeclaration) := do
  let keyword ← psTokenCursorExpectText cursor "suffices"
  let (name, cursor) ← match psTokenCursorAdvance keyword.cursor with
    | some next =>
      if psTokenKindEq next.token.kind .identifier && psTokenCursorAtText next.cursor ":" then do
        let colon ← psTokenCursorExpectText next.cursor ":"
        pure (psSyntaxNameFromToken next.token, colon.cursor)
      else pure (PsSyntaxName.mk ["this"] keyword.token.span, keyword.cursor)
    | none => throw (.unexpectedEnd "suffices type")
  let type ← readType cursor
  let value ← if psTokenCursorAtText type.cursor "from" then do
      let fromToken ← psTokenCursorExpectText type.cursor "from"
      read fromToken.cursor
    else if psTokenCursorAtText type.cursor "by" then read type.cursor
    else throw (psProofScriptExpectedError "from or by after suffices type" type.cursor)
  return {
    value := {
      name := name
      type := some type.value
      value := value.value
      span := psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan value.value) }
    cursor := value.cursor }

def psPscv0ReadSufficesTerm (read readType continuation : PsPscv0TermReader)
    (separator : PsSourcePos → PsTokenCursor → Except PsParseError PsTokenCursor)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let fact ← psPscv0ReadSuffices read readType cursor
  let next ← separator fact.value.span.stop fact.cursor
  let witness ← continuation next
  return {
    value := .haveE fact.value.name fact.value.type witness.value fact.value.value
      (psSyntaxSpanJoin fact.value.span (psSyntaxTermSpan witness.value))
    cursor := witness.cursor }

def psPscv0ReadShow (read readType : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "show"
  let type ← readType keyword.cursor
  let value ← if psTokenCursorAtText type.cursor "from" then do
      let fromToken ← psTokenCursorExpectText type.cursor "from"
      read fromToken.cursor
    else if psTokenCursorAtText type.cursor "by" then read type.cursor
    else throw (psProofScriptExpectedError "from or by after show type" type.cursor)
  return {
    value := .ascription value.value type.value
      (psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan value.value))
    cursor := value.cursor }
