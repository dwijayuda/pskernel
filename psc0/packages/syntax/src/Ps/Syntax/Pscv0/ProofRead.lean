import Ps.Syntax.Pscv0.LocalRead

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
    return {
      value := PsSyntaxName.mk [name.token.text] name.token.span :: rest.value
      cursor := rest.cursor }

def psPscv0CaseNames (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxName)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "=>" then return { value := [], cursor }
    let name ← psTokenCursorExpectKind cursor .identifier
    let rest ← psPscv0CaseNames fuel name.cursor
    return {
      value := PsSyntaxName.mk [name.token.text] name.token.span :: rest.value
      cursor := rest.cursor }

def psPscv0ReadTactics (read readType : PsPscv0TermReader) (fuel : Nat)
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
      else if token.text == "cases" || token.text == "induction" then do
        let value ← read head.cursor
        pure (.eliminate value.value (token.text == "induction")
          (psSyntaxSpanJoin token.span (psSyntaxTermSpan value.value)), value.cursor)
      else if token.text == "case" || token.text == "next" then do
        let (tag, cursor) ← if token.text == "next" then pure (none, head.cursor) else do
          let name ← psParseSyntaxName head.cursor
          pure (if name.value.segments == ["_"] then none else some name.value, name.cursor)
        let names ← psPscv0CaseNames fuel cursor
        let arrow ← psTokenCursorExpectText names.cursor "=>"
        let body ← psPscv0ReadTactics read readType fuel (some token.span.start) arrow.cursor
        if body.value.isEmpty then throw (psProofScriptExpectedError "case tactic body" arrow.cursor)
        pure (.caseE tag names.value body.value token.span, body.cursor)
      else if token.text == "have" || token.text == "let" then do
        let fact ← psPscv0ReadLocal read readType cursor
        pure (.localE fact.value.name fact.value.type fact.value.value
          (token.text == "let") fact.value.span, fact.cursor)
      else if token.text == "change" || token.text == "show" then do
        let type ← readType head.cursor
        pure (.change type.value (token.text == "show")
          (psSyntaxSpanJoin token.span (psSyntaxTermSpan type.value)), type.cursor)
      else if token.text == "intro" then do
        let names ← psPscv0IntroNames fuel token.span.start.line head.cursor
        pure (.intro names.value token.span, names.cursor)
      else if token.text == "assumption" then pure (.assumption token.span, head.cursor)
      else if token.text == "rfl" then pure (.reflexivity token.span, head.cursor)
      else if token.text == "constructor" then pure (.constructor token.span, head.cursor)
      else if ["·", "focus", "all_goals", "any_goals"].contains token.text then do
        let body ← psPscv0ReadTactics read readType fuel (some token.span.start) head.cursor
        if body.value.isEmpty then throw (psProofScriptExpectedError "focused tactic" head.cursor)
        let tactic := if token.text == "all_goals" || token.text == "any_goals" then
          PsSyntaxTactic.each body.value (token.text == "any_goals") token.span
          else .focus body.value (token.text == "·") token.span
        pure (tactic, body.cursor)
      else throw (psProofScriptExpectedError "selected tactic" cursor)
    let consumed := cursor.remaining.take (cursor.remaining.length - next.remaining.length)
    let stop := (consumed.getLast?).map (·.span.stop) |>.getD token.span.stop
    if !psTokenCursorAtText next "}" && !psProofScriptLaterLine stop next then
      throw (psProofScriptExpectedError "newline-separated tactic" next)
    let rest ← psPscv0ReadTactics read readType fuel boundary next
    return { value := tactic :: rest.value, cursor := rest.cursor }

def psPscv0ReadProof (read readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "by"
  let opening ← psTokenCursorExpectText keyword.cursor "{"
  let tactics ← psPscv0ReadTactics read readType fuel none opening.cursor
  let close ← psTokenCursorExpectText tactics.cursor "}"
  return {
    value := .byE tactics.value {} (psSyntaxSpanJoin keyword.token.span close.token.span)
    cursor := close.cursor }
