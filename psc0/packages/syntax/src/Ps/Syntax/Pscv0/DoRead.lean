import Ps.Syntax.Pscv0.PatternRead

-- The sequence reader delegates terms/annotations to the enclosing category.
-- No token substitution, assumed effect, or declaration-position restriction.
mutual
def psPscv0DoSequence (read annotation : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult (List PsSyntaxDoItem)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "}" then return { value := [], cursor }
    let item ← psPscv0DoStatement read annotation fuel cursor
    if !psTokenCursorAtText item.cursor "}" then
      let some token := psTokenCursorPeek item.cursor | throw (.unexpectedEnd "do sequence")
      if token.span.start.line <= (psSyntaxDoSpan item.value).stop.line then
        throw (psProofScriptExpectedError "newline between do statements" item.cursor)
    let rest ← psPscv0DoSequence read annotation fuel item.cursor
    return { value := item.value :: rest.value, cursor := rest.cursor }

def psPscv0DoBraced (read annotation : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxDoItem × PsSourceSpan)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let opening ← psTokenCursorExpectText cursor "{"
    let body ← psPscv0DoSequence read annotation fuel opening.cursor
    let close ← psTokenCursorExpectText body.cursor "}"
    return { value := (body.value, psSyntaxSpanJoin opening.token.span close.token.span)
             cursor := close.cursor }

def psPscv0DoStatement (read annotation : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxDoItem) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | throw (.unexpectedEnd "do statement")
    if token.text == "let" then
      let keyword ← psTokenCursorExpectText cursor "let"
      if psTokenCursorAtText keyword.cursor "mut" then
        throw (psProofScriptExpectedError "registered mutable do control" keyword.cursor)
      let pattern ← psPscv0Pattern fuel keyword.cursor
      let (type, cursor) ← if psTokenCursorAtText pattern.cursor ":" then do
          let colon ← psTokenCursorExpectText pattern.cursor ":"
          let type ← annotation colon.cursor
          pure (some type.value, type.cursor)
        else pure (none, pattern.cursor)
      let some operator := psTokenCursorAdvance cursor | throw (.unexpectedEnd "do binding")
      if ![":=", "←", "<-"].contains operator.token.text then
        throw (psProofScriptExpectedError "do binding operator" cursor)
      let value ← read operator.cursor
      return { value := .binding pattern.value type value.value (operator.token.text != ":=")
                (psSyntaxSpanJoin token.span (psSyntaxTermSpan value.value))
               cursor := value.cursor }
    if token.text == "return" then
      let keyword ← psTokenCursorExpectText cursor "return"
      let value ← read keyword.cursor
      return { value := .returnValue value.value
                (psSyntaxSpanJoin token.span (psSyntaxTermSpan value.value))
               cursor := value.cursor }
    if token.text == "if" then
      let keyword ← psTokenCursorExpectText cursor "if"
      let (pattern, name, condition, cursor) ←
        if psTokenCursorAtText keyword.cursor "let" then do
          let letToken ← psTokenCursorExpectText keyword.cursor "let"
          let pattern ← psPscv0Pattern fuel letToken.cursor
          let assign ← psTokenCursorExpectText pattern.cursor ":="
          let value ← read assign.cursor
          pure (some pattern.value, none, value.value, value.cursor)
        else do
          let opening ← psTokenCursorExpectText keyword.cursor "("
          let (name, cursor) ← match psTokenCursorAdvance opening.cursor with
            | some next =>
              if psTokenKindEq next.token.kind .identifier && psTokenCursorAtText next.cursor ":" then do
                let colon ← psTokenCursorExpectText next.cursor ":"
                pure (some (PsSyntaxName.mk [next.token.text] next.token.span), colon.cursor)
              else pure (none, opening.cursor)
            | none => pure (none, opening.cursor)
          let value ← read cursor
          let closed ← psTokenCursorExpectText value.cursor ")"
          pure (none, name, value.value, closed.cursor)
      let yes ← psPscv0DoBraced read annotation fuel cursor
      let (no, stop, cursor) ← if psTokenCursorAtText yes.cursor "else" then do
          let alternative ← psTokenCursorExpectText yes.cursor "else"
          let no ← psPscv0DoBraced read annotation fuel alternative.cursor
          pure (no.value.fst, no.value.snd, no.cursor)
        else pure ([], yes.value.snd, yes.cursor)
      let span := psSyntaxSpanJoin token.span stop
      return { value := match pattern with
                 | none => .conditional name condition yes.value.fst no span
                 | some pattern => .conditionalPattern pattern condition yes.value.fst no span
               cursor }
    if ["mut", "for", "while", "try", "catch", "finally", "throw", "break",
        "continue", "erased", "assert"].contains token.text then
      throw (psProofScriptExpectedError "registered do statement" cursor)
    let value ← read cursor
    return { value := .action value.value (psSyntaxTermSpan value.value), cursor := value.cursor }
end

def psPscv0ReadTypedDo (read annotation : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "do"
  let body ← psPscv0DoBraced read annotation fuel keyword.cursor
  if body.value.fst.isEmpty then throw (psProofScriptExpectedError "nonempty do sequence" keyword.cursor)
  return { value := .doE body.value.fst (psSyntaxSpanJoin keyword.token.span body.value.snd)
           cursor := body.cursor }
