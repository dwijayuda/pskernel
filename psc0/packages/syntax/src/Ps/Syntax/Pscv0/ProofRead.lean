import Ps.Syntax.Pscv0.TermParts

def psPscv0IntroNames (fuel line : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxName)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | return { value := [], cursor }
    if token.span.start.line != line || token.text == "}" then
      return { value := [], cursor }
    let name ← psTokenCursorExpectKind cursor .identifier
    let rest ← psPscv0IntroNames fuel line name.cursor
    return { value := PsSyntaxName.mk [name.token.text] name.token.span :: rest.value
      cursor := rest.cursor }

def psPscv0ReadTactics (read : PsPscv0TermReader) (fuel : Nat)
    (boundary : Option PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxTactic)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | throw (.unexpectedEnd "tactic block")
    if token.text == "}" || boundary.any (fun pos =>
        token.span.start.line > pos.line && token.span.start.column <= pos.column) then
      return { value := [], cursor }
    let head ← psTokenCursorExpectText cursor token.text
    let (tactic, next) ←
      if token.text == "exact" || token.text == "refine" || token.text == "apply" then do
        let value ← read head.cursor
        let span := psSyntaxSpanJoin token.span (psSyntaxTermSpan value.value)
        pure (if token.text == "apply" then PsSyntaxTactic.applyE value.value span
          else .exactE value.value (token.text == "refine") span, value.cursor)
      else if token.text == "intro" then do
        let names ← psPscv0IntroNames fuel token.span.start.line head.cursor
        pure (.intro names.value token.span, names.cursor)
      else if token.text == "assumption" then pure (.assumption token.span, head.cursor)
      else if token.text == "rfl" then pure (.reflexivity token.span, head.cursor)
      else if token.text == "constructor" then pure (.constructor token.span, head.cursor)
      else if token.text == "·" || token.text == "focus" then do
        let body ← psPscv0ReadTactics read fuel (some token.span.start) head.cursor
        if body.value.isEmpty then throw (psProofScriptExpectedError "focused tactic" head.cursor)
        pure (.focus body.value (token.text == "·") token.span, body.cursor)
      else throw (psProofScriptExpectedError "selected tactic" cursor)
    let consumed := cursor.remaining.take (cursor.remaining.length - next.remaining.length)
    let stop := (consumed.getLast?).map (·.span.stop) |>.getD token.span.stop
    if !psTokenCursorAtText next "}" && !psProofScriptLaterLine stop next then
      throw (psProofScriptExpectedError "newline-separated tactic" next)
    let rest ← psPscv0ReadTactics read fuel boundary next
    return { value := tactic :: rest.value, cursor := rest.cursor }

def psPscv0ReadProof (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "by"
  let opening ← psTokenCursorExpectText keyword.cursor "{"
  let tactics ← psPscv0ReadTactics read fuel none opening.cursor
  let close ← psTokenCursorExpectText tactics.cursor "}"
  return { value := .byE tactics.value {} (psSyntaxSpanJoin keyword.token.span close.token.span)
    cursor := close.cursor }
