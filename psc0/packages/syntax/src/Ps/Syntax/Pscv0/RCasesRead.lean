import Ps.Syntax.Pscv0.LocalRead
import Ps.Syntax.Pscv0.PatternRead

-- Adapted from Lean 4.35.0 Init/RCases.lean at
-- eb6cafb7290e8bd5f2937522d8d804f58f02bafc (Apache-2.0).
-- These are tactic patterns, not expression applications. Their annotations
-- and elimination targets still use the selected shared term readers.
def psPscv0ProofArgumentBoundary (start : PsSourcePos) (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => true
  | some token => psTokenCursorDone cursor ||
      ["}", ")", "]", ",", ";", "<;>"].contains token.text ||
      (token.span.start.line > start.line && token.span.start.column <= start.column)

mutual
def psPscv0RCasesPatternAtom (readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxRCasesPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor
      | throw (.unexpectedEnd "recursive elimination pattern")
    if token.text == "-" then
      let next ← psTokenCursorExpectText cursor "-"
      return { value := .clear token.span, cursor := next.cursor }
    if token.text == "@" then
      let next ← psTokenCursorExpectText cursor "@"
      let some following := psTokenCursorPeek next.cursor
        | throw (.unexpectedEnd "pattern after @")
      if following.span.start.byteOffset != token.span.stop.byteOffset then
        throw (psProofScriptExpectedError "adjacent pattern after @" next.cursor)
      let pattern ← psPscv0RCasesPatternAtom readType fuel next.cursor
      let span := psSyntaxSpanJoin token.span (psSyntaxRCasesPatternSpan pattern.value)
      return { value := .explicit pattern.value span, cursor := pattern.cursor }
    if token.text == "⟨" then
      let next ← psTokenCursorExpectText cursor "⟨"
      let patterns ← psPscv0RCasesTuple readType fuel next.cursor
      let close ← psTokenCursorExpectText patterns.cursor "⟩"
      return {
        value := .tuple patterns.value (psSyntaxSpanJoin token.span close.token.span)
        cursor := close.cursor }
    if token.text == "(" then
      let next ← psTokenCursorExpectText cursor "("
      let pattern ← psPscv0RCasesPatternLow readType fuel next.cursor
      let close ← psTokenCursorExpectText pattern.cursor ")"
      return {
        value := .paren pattern.value (psSyntaxSpanJoin token.span close.token.span)
        cursor := close.cursor }
    let name ← psParseSyntaxNameWith true cursor
    return { value := .one name.value, cursor := name.cursor }

def psPscv0RCasesAlternatives (readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxRCasesPattern)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let pattern ← psPscv0RCasesPatternAtom readType fuel cursor
    if psTokenCursorAtText pattern.cursor "|" then
      let bar ← psTokenCursorExpectText pattern.cursor "|"
      let rest ← psPscv0RCasesAlternatives readType fuel bar.cursor
      return { value := pattern.value :: rest.value, cursor := rest.cursor }
    return { value := [pattern.value], cursor := pattern.cursor }

def psPscv0RCasesPatternMedium (readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxRCasesPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let patterns ← psPscv0RCasesAlternatives readType fuel cursor
    match patterns.value with
    | [] => throw (.unexpectedEnd "recursive elimination pattern")
    | [pattern] => return { value := pattern, cursor := patterns.cursor }
    | first :: rest =>
      let last := rest.getLastD first
      let span := psSyntaxSpanJoin (psSyntaxRCasesPatternSpan first) (psSyntaxRCasesPatternSpan last)
      return { value := .alternatives patterns.value span, cursor := patterns.cursor }

def psPscv0RCasesPatternLow (readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxRCasesPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let pattern ← psPscv0RCasesPatternMedium readType fuel cursor
    if !psTokenCursorAtText pattern.cursor ":" then return pattern
    let colon ← psTokenCursorExpectText pattern.cursor ":"
    let type ← readType colon.cursor
    let span := psSyntaxSpanJoin (psSyntaxRCasesPatternSpan pattern.value) (psSyntaxTermSpan type.value)
    return { value := .typed pattern.value type.value span, cursor := type.cursor }

def psPscv0RCasesTuple (readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxRCasesPattern)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "⟩" then return { value := [], cursor }
    let pattern ← psPscv0RCasesPatternLow readType fuel cursor
    if psTokenCursorAtText pattern.cursor "," then
      let comma ← psTokenCursorExpectText pattern.cursor ","
      let rest ← psPscv0RCasesTuple readType fuel comma.cursor
      return { value := pattern.value :: rest.value, cursor := rest.cursor }
    return { value := [pattern.value], cursor := pattern.cursor }
end

mutual
def psPscv0RIntroPattern (readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxRIntroPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "(" then
      let opening ← psTokenCursorExpectText cursor "("
      let attempt : Except PsParseError (PsParseResult PsSyntaxRIntroPattern) := do
        let patterns ← psPscv0RIntroPatterns readType fuel none opening.cursor
        if patterns.value.isEmpty then
          throw (psProofScriptExpectedError "rintro binder pattern" opening.cursor)
        let (annotation, next) ← if psTokenCursorAtText patterns.cursor ":" then do
          let colon ← psTokenCursorExpectText patterns.cursor ":"
          let type ← readType colon.cursor
          pure (some type.value, type.cursor)
        else pure (none, patterns.cursor)
        let close ← psTokenCursorExpectText next ")"
        let span := psSyntaxSpanJoin opening.token.span close.token.span
        pure { value := PsSyntaxRIntroPattern.group patterns.value annotation span, cursor := close.cursor }
      match attempt with
      | .ok result => return result
      | .error .fuelExhausted => throw .fuelExhausted
      | .error _ => pure ()
    let pattern ← psPscv0RCasesPatternAtom readType fuel cursor
    return { value := .pattern pattern.value, cursor := pattern.cursor }

def psPscv0RIntroPatterns (readType : PsPscv0TermReader) (fuel : Nat)
    (boundary : Option PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxRIntroPattern)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorDone cursor || psTokenCursorAtText cursor ":" ||
        psTokenCursorAtText cursor ")" || psTokenCursorAtText cursor "|" ||
        boundary.any (fun start => psPscv0ProofArgumentBoundary start cursor) then
      return { value := [], cursor }
    let pattern ← psPscv0RIntroPattern readType fuel cursor
    let rest ← psPscv0RIntroPatterns readType fuel boundary pattern.cursor
    return { value := pattern.value :: rest.value, cursor := rest.cursor }
end

def psPscv0ReadRCases (read readType : PsPscv0TermReader) (fuel : Nat)
    (head : PsTokenRead) : Except PsParseError (PsParseResult PsSyntaxTactic) := do
  let targets ← if psTokenCursorAtText head.cursor "with" ||
      psPscv0ProofArgumentBoundary head.token.span.start head.cursor then
    pure { value := [], cursor := head.cursor }
  else psPscv0MatchDiscriminants read fuel head.cursor
  let (pattern, next) ← if psTokenCursorAtText targets.cursor "with" then do
    let keyword ← psTokenCursorExpectText targets.cursor "with"
    let pattern ← psPscv0RCasesPatternLow readType fuel keyword.cursor
    pure (some pattern.value, pattern.cursor)
  else pure (none, targets.cursor)
  return { value := .rcasesE targets.value pattern head.token.span, cursor := next }

def psPscv0ReadRIntro (readType : PsPscv0TermReader) (fuel : Nat)
    (head : PsTokenRead) : Except PsParseError (PsParseResult PsSyntaxTactic) := do
  let patterns ← psPscv0RIntroPatterns readType fuel (some head.token.span.start) head.cursor
  if patterns.value.isEmpty then
    throw (psProofScriptExpectedError "rintro pattern" head.cursor)
  let (annotation, next) ← if psTokenCursorAtText patterns.cursor ":" then do
    let colon ← psTokenCursorExpectText patterns.cursor ":"
    let type ← readType colon.cursor
    pure (some type.value, type.cursor)
  else pure (none, patterns.cursor)
  return { value := .rintroE patterns.value annotation head.token.span, cursor := next }

def psPscv0ReadObtain (read readType : PsPscv0TermReader) (fuel : Nat)
    (head : PsTokenRead) : Except PsParseError (PsParseResult PsSyntaxTactic) := do
  let (pattern, next) ← if psTokenCursorAtText head.cursor ":" ||
      psTokenCursorAtText head.cursor ":=" ||
      psPscv0ProofArgumentBoundary head.token.span.start head.cursor then
    pure (none, head.cursor)
  else do
    let pattern ← psPscv0RCasesPatternMedium readType fuel head.cursor
    pure (some pattern.value, pattern.cursor)
  let (annotation, next) ← if psTokenCursorAtText next ":" then do
    let colon ← psTokenCursorExpectText next ":"
    let type ← readType colon.cursor
    pure (some type.value, type.cursor)
  else pure (none, next)
  let (values, next) ← if psTokenCursorAtText next ":=" then do
    let assign ← psTokenCursorExpectText next ":="
    let values ← psPscv0Discriminants read fuel assign.cursor
    pure (some values.value, values.cursor)
  else pure (none, next)
  return { value := .obtainE pattern annotation values head.token.span, cursor := next }
