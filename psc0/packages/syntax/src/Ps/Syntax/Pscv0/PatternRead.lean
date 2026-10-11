import Ps.Syntax.Pscv0.TermParts

def psPscv0PatternStart (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token => psTokenKindEq token.kind .identifier ||
      psTokenKindEq token.kind .natural || token.text == "." || token.text == "("

def psPscv0PatternTuple (patterns : List PsSyntaxPattern) (span : PsSourceSpan) :
    Except PsParseError PsSyntaxPattern := do
  match patterns with
  | [] => throw (.unexpectedEnd "tuple pattern")
  | [pattern] => return pattern
  | pattern :: rest =>
    return .ctor (PsSyntaxName.mk ["_root_", "Prod", "mk"] span)
      [pattern, ← psPscv0PatternTuple rest span] span

-- Pattern application owns native whitespace arguments. Comma-call syntax
-- belongs exclusively to expressions; parentheses group one nested pattern or
-- a tuple pattern.
mutual
def psPscv0PatternAtom (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | throw (.unexpectedEnd "pattern")
    if token.text == "(" then
      let opening ← psTokenCursorExpectText cursor "("
      let fields ← psPscv0Patterns fuel opening.cursor
      let close ← psTokenCursorExpectText fields.cursor ")"
      let span := psSyntaxSpanJoin opening.token.span close.token.span
      return { value := ← psPscv0PatternTuple fields.value span, cursor := close.cursor }
    if token.text == "_" then
      let read ← psTokenCursorExpectText cursor "_"
      return { value := .wildcard token.span, cursor := read.cursor }
    if token.text == "true" || token.text == "false" then
      let read ← psTokenCursorExpectText cursor token.text
      return { value := .bool (token.text == "true") token.span, cursor := read.cursor }
    if psTokenKindEq token.kind .natural then
      let read ← psTokenCursorExpectKind cursor .natural
      let some value := token.text.toNat? | throw (psProofScriptExpectedError "natural pattern" cursor)
      return { value := .natural value token.span, cursor := read.cursor }
    if token.text == "." then
      let dot ← psTokenCursorExpectText cursor "."
      let name ← psParseSyntaxName dot.cursor
      return { value := .ctor name.value [] (psSyntaxSpanJoin token.span name.value.span)
               cursor := name.cursor }
    let name ← psParseSyntaxName cursor
    return { value := if name.value.segments.length == 1 then .variable name.value
                      else .ctor name.value [] name.value.span
             cursor := name.cursor }

def psPscv0PatternArguments (fuel : Nat) (cursor : PsTokenCursor)
    (fields : List PsSyntaxPattern) : Except PsParseError (PsParseResult (List PsSyntaxPattern)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !psPscv0PatternStart cursor then return { value := fields.reverse, cursor }
    let field ← psPscv0PatternAtom fuel cursor
    psPscv0PatternArguments fuel field.cursor (field.value :: fields)

def psPscv0Pattern (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let head ← psPscv0PatternAtom fuel cursor
    let some token := psTokenCursorPeek head.cursor | return head
    if token.text == "+" then
      let plus ← psTokenCursorExpectText head.cursor "+"
      let one ← psTokenCursorExpectText plus.cursor "1"
      let span := psSyntaxSpanJoin (psSyntaxPatternSpan head.value) one.token.span
      return { value := .ctor (PsSyntaxName.mk ["_root_", "Nat", "succ"] span)
                [head.value] span, cursor := one.cursor }
    if token.text == "(" && token.span.start.byteOffset == (psSyntaxPatternSpan head.value).stop.byteOffset then
      throw (psProofScriptExpectedError "native pattern arguments; expression calls are not patterns" head.cursor)
    let fields ← psPscv0PatternArguments fuel head.cursor []
    if fields.value.isEmpty then return head
    let name ← match head.value with
      | .variable name => pure name
      | .ctor name [] _ => pure name
      | _ => throw (psProofScriptExpectedError "constructor pattern head" cursor)
    let some last := fields.value.getLast? | throw (.unexpectedEnd "pattern argument")
    let span := psSyntaxSpanJoin (psSyntaxPatternSpan head.value) (psSyntaxPatternSpan last)
    return { value := .ctor name fields.value span, cursor := fields.cursor }

def psPscv0Patterns (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxPattern)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let pattern ← psPscv0Pattern fuel cursor
    if psTokenCursorAtText pattern.cursor "," then
      let comma ← psTokenCursorExpectText pattern.cursor ","
      let rest ← psPscv0Patterns fuel comma.cursor
      return { value := pattern.value :: rest.value, cursor := rest.cursor }
    return { value := [pattern.value], cursor := pattern.cursor }
end

def psPscv0Discriminants (read : PsPscv0TermReader) (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxTerm)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let value ← read cursor
    if psTokenCursorAtText value.cursor "," then
      let comma ← psTokenCursorExpectText value.cursor ","
      let rest ← psPscv0Discriminants read fuel comma.cursor
      return { value := value.value :: rest.value, cursor := rest.cursor }
    return { value := [value.value], cursor := value.cursor }

def psPscv0MatchRows (read : PsPscv0TermReader) (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "}" then return { value := [], cursor }
    let bar ← psTokenCursorExpectText cursor "|"
    let patterns ← psPscv0Patterns fuel bar.cursor
    let arrow ← psTokenCursorExpectText patterns.cursor "=>"
    let body ← read arrow.cursor
    let rest ← psPscv0MatchRows read fuel body.cursor
    return {
      value := (patterns.value, body.value,
        psSyntaxSpanJoin bar.token.span (psSyntaxTermSpan body.value)) :: rest.value
      cursor := rest.cursor }

def psPscv0ReadMatch (read : PsPscv0TermReader) (fuel : Nat) (impossible : Bool)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let some keyword := psTokenCursorAdvance cursor | throw (.unexpectedEnd "match")
  let inputs ← psPscv0Discriminants read fuel keyword.cursor
  if impossible then
    let some last := inputs.value.getLast? | throw (.unexpectedEnd "nomatch discriminant")
    return { value := .matchMany inputs.value []
               (psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan last))
             cursor := inputs.cursor }
  let withToken ← psTokenCursorExpectText inputs.cursor "with"
  let opening ← psTokenCursorExpectText withToken.cursor "{"
  let rows ← psPscv0MatchRows read fuel opening.cursor
  let close ← psTokenCursorExpectText rows.cursor "}"
  return { value := .matchMany inputs.value rows.value
             (psSyntaxSpanJoin keyword.token.span close.token.span)
           cursor := close.cursor }
