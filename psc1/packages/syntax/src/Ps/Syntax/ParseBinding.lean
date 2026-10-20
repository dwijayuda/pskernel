import Ps.Syntax.ParseCommon

abbrev PsBindingTermParser :=
  PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm)

structure PsParsedBindingPatterns where
  values : List PsSyntaxBindingPattern
  separated : Bool
  span : PsSourceSpan
  cursor : PsTokenCursor

def psParseBindingPatternsWithFuel
    (parsePattern : PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxBindingPattern))
    (fuel : Nat) : PsSourcePos -> PsTokenCursor ->
    List PsSyntaxBindingPattern -> Bool -> Except PsParseError PsParsedBindingPatterns :=
  match fuel with
  | 0 => fun _ _ _ _ => .error .fuelExhausted
  | remaining + 1 => fun start cursor valuesRev separated => do
      if psTokenCursorAtText cursor ")" then
        let closing ← psTokenCursorExpectText cursor ")"
        return { values := psParseListReverse valuesRev, separated := separated
                 span := { start := start, stop := closing.token.span.stop }
                 cursor := closing.cursor }
      else
        let value ← parsePattern cursor
        if psTokenCursorAtText value.cursor "," then
          let comma ← psTokenCursorExpectText value.cursor ","
          psParseBindingPatternsWithFuel parsePattern remaining start comma.cursor
            (value.value :: valuesRev) true
        else
          let closing ← psTokenCursorExpectText value.cursor ")"
          return { values := psParseListReverse (value.value :: valuesRev)
                   separated := separated
                   span := { start := start, stop := closing.token.span.stop }
                   cursor := closing.cursor }

def psSyntaxBindingTuple (values : List PsSyntaxBindingPattern)
    (span : PsSourceSpan) : PsSyntaxBindingPattern :=
  match values with
  | [] => .unit span
  | [value] => value
  | first :: rest => .pair first (psSyntaxBindingTuple rest span) span

def psParseBindingPatternWithFuel (fuel : Nat) :
    PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxBindingPattern) :=
  match fuel with
  | 0 => fun _ => .error .fuelExhausted
  | remaining + 1 => fun cursor => do
      if psTokenCursorAtText cursor "(" then
        let opening ← psTokenCursorExpectText cursor "("
        let parsed ← psParseBindingPatternsWithFuel
          (psParseBindingPatternWithFuel remaining) remaining
          opening.token.span.start opening.cursor [] false
        match parsed.values with
        | [_] =>
            if parsed.separated then
              throw (.expectedText "at least two tuple pattern elements" ")" parsed.span)
            else
              return { value := psSyntaxBindingTuple parsed.values parsed.span
                       cursor := parsed.cursor }
        | _ =>
            return { value := psSyntaxBindingTuple parsed.values parsed.span
                     cursor := parsed.cursor }
      else if psTokenCursorAtText cursor "_" then
        let wildcard ← psTokenCursorExpectText cursor "_"
        return { value := .wildcard wildcard.token.span, cursor := wildcard.cursor }
      else
        let name ← psTokenCursorExpectKind cursor PsTokenKind.identifier
        return { value := .name { segments := [name.token.text], span := name.token.span }
                 cursor := name.cursor }

structure PsParsedBindingPattern where
  pattern : PsSyntaxBindingPattern
  annotation : Option PsSyntaxTerm
  cursor : PsTokenCursor

def psParseBindingPatternHeader (parseTerm : PsBindingTermParser)
    (cursor : PsTokenCursor) : Except PsParseError PsParsedBindingPattern := do
  let pattern ← psParseBindingPatternWithFuel
    (Nat.succ (psParseListLength cursor.remaining)) cursor
  if psTokenCursorAtText pattern.cursor ":" then
    let colon ← psTokenCursorExpectText pattern.cursor ":"
    let annotation ← parseTerm colon.cursor
    return { pattern := pattern.value, annotation := some annotation.value
             cursor := annotation.cursor }
  else
    return { pattern := pattern.value, annotation := none, cursor := pattern.cursor }

def psParseAtBindingPatternLet (cursor : PsTokenCursor) : Bool :=
  if psTokenCursorAtText cursor "let" then
    match psTokenCursorAdvance cursor with
    | none => false
    | some keyword => psTokenCursorAtText keyword.cursor "("
  else false

/-- Both surfaces retain one explicit pattern binding node. Its elaborator owns
hygienic single evaluation; parsing never invents source-visible local names. -/
def psParseBindingLet (parseTerm : PsBindingTermParser)
    (separator : PsSourcePos -> PsTokenCursor -> Except PsParseError PsTokenCursor)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "let"
  let header ← psParseBindingPatternHeader parseTerm keyword.cursor
  let assign ← psTokenCursorExpectText header.cursor ":="
  let value ← parseTerm assign.cursor
  let afterSeparator ← separator (psSyntaxTermSpan value.value).stop value.cursor
  let body ← parseTerm afterSeparator
  return {
    value := .letPatternE header.pattern header.annotation value.value body.value
      { start := keyword.token.span.start, stop := (psSyntaxTermSpan body.value).stop }
    cursor := body.cursor
  }
