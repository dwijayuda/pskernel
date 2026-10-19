import Ps.Syntax.ParseProofScript

-- RC4 Parser.Level: atoms/max/imax, parentheses and trailing numeral offsets.
-- This parser consumes levels only where a sort explicitly owns that category.
def psPscv0LevelStart (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
    token.text == "(" || token.text == "_" || psTokenKindEq token.kind .natural ||
      (psTokenKindEq token.kind .identifier && !psProofScriptReservedArgument token.text &&
        !(["where", "then", "else", "with", "matches"] : List String).contains token.text)

def psPscv0LevelNumber (token : PsToken) : Except PsParseError Nat := do
  let some value := token.text.toNat?
    | throw (PsParseError.expectedText "universe numeral" token.text token.span)
  if value > 32 then
    throw (PsParseError.expectedText "universe offset at most 32" token.text token.span)
  return value

def psPscv0ReadLevel (fuel : Nat) (offsets : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxLevel) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor
      | throw (.unexpectedEnd "universe level")
    let next ← psTokenCursorExpectText cursor token.text
    let mut parsed ←
      if token.text == "(" then do
        let inner ← psPscv0ReadLevel fuel true next.cursor
        let close ← psTokenCursorExpectText inner.cursor ")"
        pure { inner with cursor := close.cursor }
      else if token.text == "max" || token.text == "imax" then do
        let first ← psPscv0ReadLevel fuel false next.cursor
        let mut current := first.cursor
        let mut levels := [first.value]
        for _ in [:fuel] do
          if !psPscv0LevelStart current then break
          else
            let arg ← psPscv0ReadLevel fuel false current
            levels := arg.value :: levels
            current := arg.cursor
        let level := match levels with
          | last :: prior => prior.foldl (fun acc item =>
              if token.text == "max" then PsSyntaxLevel.max item acc else .imax item acc) last
          | [] => first.value
        pure { value := level, cursor := current }
      else if token.text == "_" then pure { value := PsSyntaxLevel.hole, cursor := next.cursor }
      else if psTokenKindEq token.kind .natural then
        pure { value := PsSyntaxLevel.number (← psPscv0LevelNumber token), cursor := next.cursor }
      else if psTokenKindEq token.kind .identifier && psPscv0LevelStart cursor then
        pure { value := PsSyntaxLevel.name (psTokenIdentifierText token), cursor := next.cursor }
      else throw (psProofScriptExpectedError "universe level" cursor)
    if offsets then
      for _ in [:fuel] do
        if !psTokenCursorAtText parsed.cursor "+" then break
        else
          let plus ← psTokenCursorExpectText parsed.cursor "+"
          let number ← psTokenCursorExpectKind plus.cursor .natural
          parsed := {
            value := .offset parsed.value (← psPscv0LevelNumber number.token)
            cursor := number.cursor }
    return parsed

def psPscv0ReadSort (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let some token := psTokenCursorPeek cursor | throw (.unexpectedEnd "sort")
  let head ← psTokenCursorExpectText cursor token.text
  let isType := token.text == "Type"
  if token.text == "Prop" then
    return { value := .sortE false (.number 0) token.span, cursor := head.cursor }
  let hasLevel := match psTokenCursorPeek head.cursor with
    | some next => next.span.start.line == token.span.start.line && psPscv0LevelStart head.cursor
    | none => false
  if isType && !hasLevel then
    return { value := .sortE true (.number 0) token.span, cursor := head.cursor }
  let level ← psPscv0ReadLevel 4096 true head.cursor
  let consumed := head.cursor.remaining.take (head.cursor.remaining.length - level.cursor.remaining.length)
  let stop := (consumed.getLast?).map (·.span.stop) |>.getD token.span.stop
  return { value := .sortE isType level.value { start := token.span.start, stop }, cursor := level.cursor }
