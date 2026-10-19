import Ps.Syntax.Pscv0.TermParts

-- Both readers share the native rule list and location syntax. ASCII arrows
-- and turnstiles retain their required token adjacency.
def psPscv0ProofPairToken (left right : String) (cursor : PsTokenCursor) :
    Option PsTokenCursor :=
  match cursor.remaining with
  | first :: second :: rest =>
    if first.text == left && second.text == right &&
        first.span.stop.byteOffset == second.span.start.byteOffset then
      some { remaining := rest }
    else none
  | _ => none

def psPscv0RewriteArrow (cursor : PsTokenCursor) :
    Except PsParseError (Bool × PsTokenCursor) := do
  if psTokenCursorAtText cursor "←" then
    return (true, (← psTokenCursorExpectText cursor "←").cursor)
  if psTokenCursorAtText cursor "<-" then
    return (true, (← psTokenCursorExpectText cursor "<-").cursor)
  if let some next := psPscv0ProofPairToken "<" "-" cursor then
    return (true, next)
  return (false, cursor)

def psPscv0RewriteRules (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError
      (PsParseResult (List (PsSyntaxTerm × Bool))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "]" then return { value := [], cursor }
    let (reverse, next) ← psPscv0RewriteArrow cursor
    let term ← read next
    if psTokenCursorAtText term.cursor "," then
      let comma ← psTokenCursorExpectText term.cursor ","
      let rest ← psPscv0RewriteRules read fuel comma.cursor
      return { value := (term.value, reverse) :: rest.value, cursor := rest.cursor }
    let _ ← psTokenCursorExpectText term.cursor "]"
    return { value := [(term.value, reverse)], cursor := term.cursor }

def psPscv0ProofLocationEnd (start : PsSourcePos) (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => true
  | some token => psTokenCursorDone cursor ||
    ["}", ")", "]", ",", ";", "<;>"].contains token.text ||
    (token.span.start.line > start.line && token.span.start.column <= start.column)

def psPscv0ProofLocationTerms (read : PsPscv0TermReader) (fuel : Nat)
    (start : PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxTerm × Bool)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psPscv0ProofLocationEnd start cursor then
      return { value := ([], false), cursor }
    let turnstile ← if psTokenCursorAtText cursor "⊢" then
        pure (some (← psTokenCursorExpectText cursor "⊢").cursor)
      else if psTokenCursorAtText cursor "|-" then
        pure (some (← psTokenCursorExpectText cursor "|-").cursor)
      else pure (psPscv0ProofPairToken "|" "-" cursor)
    if let some next := turnstile then
      let rest ← psPscv0ProofLocationTerms read fuel start next
      return { value := (rest.value.1, true), cursor := rest.cursor }
    let term ← psPscv0Primary read cursor
    let term ← psPscv0Postfix read fuel term.value term.cursor
    let rest ← psPscv0ProofLocationTerms read fuel start term.cursor
    return { value := (term.value :: rest.value.1, rest.value.2), cursor := rest.cursor }

def psPscv0ProofLocation (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (PsSyntaxProofLocation PsSyntaxTerm)) := do
  if !psTokenCursorAtText cursor "at" then
    return { value := .targets [] true, cursor }
  let keyword ← psTokenCursorExpectText cursor "at"
  if psTokenCursorAtText keyword.cursor "*" then
    let star ← psTokenCursorExpectText keyword.cursor "*"
    return { value := .all, cursor := star.cursor }
  let terms ← psPscv0ProofLocationTerms read fuel keyword.token.span.start keyword.cursor
  if terms.value.1.isEmpty && !terms.value.2 then
    throw (psProofScriptExpectedError "local hypothesis or goal location" keyword.cursor)
  return { value := .targets terms.value.1 terms.value.2, cursor := terms.cursor }

def psPscv0ReadRewrite (read : PsPscv0TermReader) (fuel : Nat)
    (head : PsTokenRead) (close : Bool) :
    Except PsParseError (PsParseResult PsSyntaxTactic) := do
  let opening ← psTokenCursorExpectText head.cursor "["
  let rules ← psPscv0RewriteRules read fuel opening.cursor
  let closing ← psTokenCursorExpectText rules.cursor "]"
  let location ← psPscv0ProofLocation read fuel closing.cursor
  let consumed := head.cursor.remaining.take
    (head.cursor.remaining.length - location.cursor.remaining.length)
  let stop := (consumed.getLast?).map (·.span.stop) |>.getD closing.token.span.stop
  return {
    value := .rewriteE rules.value location.value close
      { start := head.token.span.start, stop }
    cursor := location.cursor }
