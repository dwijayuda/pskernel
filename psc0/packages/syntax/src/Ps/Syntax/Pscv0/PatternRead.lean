import Ps.Syntax.Pscv0.TermParts

def psPscv0PatternStart (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
      !psPscv0ReservedArgument token.text && token.text != "matches" &&
        (psTokenKindEq token.kind .identifier || psTokenKindEq token.kind .natural ||
          token.text == "." || token.text == "(" || token.text == "[")

def psPscv0PatternTuple (patterns : List PsSyntaxPattern) (span : PsSourceSpan) :
    Except PsParseError PsSyntaxPattern := do
  match patterns with
  | [] => throw (.unexpectedEnd "tuple pattern")
  | [pattern] => return pattern
  | pattern :: rest =>
    return .ctor (PsSyntaxName.mk ["_root_", "Prod", "mk"] span)
      [pattern, ← psPscv0PatternTuple rest span] span

-- Built-in list patterns use only the pinned List constructors.
def psPscv0PatternList (patterns : List PsSyntaxPattern) (span : PsSourceSpan) :
    PsSyntaxPattern :=
  patterns.foldr (fun head tail =>
    .ctor (PsSyntaxName.mk ["_root_", "List", "cons"] span) [head, tail] span)
      (.ctor (PsSyntaxName.mk ["_root_", "List", "nil"] span) [] span)

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
      let value ← psPscv0PatternTuple fields.value span
      let value : PsSyntaxPattern := match value with
        | .natural n _ => .natural n span
        | .bool b _ => .bool b span
        | .wildcard _ => .wildcard span
        | .variable name => .variable { name with span }
        | .ctor name fields _ => .ctor name fields span
      return { value, cursor := close.cursor }
    if token.text == "[" then
      let opening ← psTokenCursorExpectText cursor "["
      let fields ← psPscv0ListPatterns fuel opening.cursor
      let close ← psTokenCursorExpectText fields.cursor "]"
      let span := psSyntaxSpanJoin opening.token.span close.token.span
      return { value := psPscv0PatternList fields.value span, cursor := close.cursor }
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
      let name ← psParseSyntaxNameWith true dot.cursor
      return { value := .ctor name.value [] (psSyntaxSpanJoin token.span name.value.span)
               cursor := name.cursor }
    let name ← psParseSyntaxNameWith true cursor
    return { value := if name.value.segments.length == 1 then .variable name.value
                      else .ctor name.value [] name.value.span
             cursor := name.cursor }

def psPscv0PatternArguments (fuel : Nat) (headSpan : PsSourceSpan) (cursor : PsTokenCursor)
    (fields : List PsSyntaxPattern) : Except PsParseError (PsParseResult (List PsSyntaxPattern)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !psPscv0PatternStart cursor then return { value := fields.reverse, cursor }
    let some token := psTokenCursorPeek cursor | return { value := fields.reverse, cursor }
    if (token.text == "(" || token.text == "[") &&
        token.span.start.byteOffset == headSpan.stop.byteOffset then
      throw (psProofScriptExpectedError "native pattern arguments; expression calls are not patterns" cursor)
    if token.span.start.line > headSpan.stop.line &&
        token.span.start.column <= headSpan.start.column then
      return { value := fields.reverse, cursor }
    let field ← psPscv0PatternAtom fuel cursor
    psPscv0PatternArguments fuel
      { headSpan with stop := (psSyntaxPatternSpan field.value).stop }
      field.cursor (field.value :: fields)

def psPscv0PatternTail (minimum fuel : Nat) (head : PsSyntaxPattern)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if minimum <= 67 && psTokenCursorAtText cursor "::" then
      let cons ← psTokenCursorExpectText cursor "::"
      let tail ← psPscv0PatternAtPrecedence 67 fuel cons.cursor
      let span := psSyntaxSpanJoin (psSyntaxPatternSpan head) (psSyntaxPatternSpan tail.value)
      let value := PsSyntaxPattern.ctor (PsSyntaxName.mk ["_root_", "List", "cons"] span)
        [head, tail.value] span
      return ← psPscv0PatternTail minimum fuel value tail.cursor
    if minimum <= 65 && psTokenCursorAtText cursor "+" then
      let plus ← psTokenCursorExpectText cursor "+"
      let right ← psPscv0PatternAtPrecedence 66 fuel plus.cursor
      let .natural 1 _ := right.value |
        throw (psProofScriptExpectedError "selected Nat successor pattern with literal 1" plus.cursor)
      let span := psSyntaxSpanJoin (psSyntaxPatternSpan head) (psSyntaxPatternSpan right.value)
      let value := PsSyntaxPattern.ctor (PsSyntaxName.mk ["_root_", "Nat", "succ"] span) [head] span
      return ← psPscv0PatternTail minimum fuel value right.cursor
    return { value := head, cursor }

def psPscv0PatternAtPrecedence (minimum fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let head ← psPscv0PatternAtom fuel cursor
    let fields ← psPscv0PatternArguments fuel (psSyntaxPatternSpan head.value) head.cursor []
    let parsed ← if fields.value.isEmpty then pure head else do
      let name ← match head.value with
        | .variable name => pure name
        | .ctor name [] _ => pure name
        | _ => throw (psProofScriptExpectedError "constructor pattern head" cursor)
      let some last := fields.value.getLast? | throw (.unexpectedEnd "pattern argument")
      let span := psSyntaxSpanJoin (psSyntaxPatternSpan head.value) (psSyntaxPatternSpan last)
      pure { value := PsSyntaxPattern.ctor name fields.value span, cursor := fields.cursor }
    psPscv0PatternTail minimum fuel parsed.value parsed.cursor

def psPscv0Pattern (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) :=
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 => psPscv0PatternAtPrecedence 0 fuel cursor

def psPscv0ListPatterns (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxPattern)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "]" then return { value := [], cursor }
    let pattern ← psPscv0Pattern fuel cursor
    if psTokenCursorAtText pattern.cursor "," then
      let comma ← psTokenCursorExpectText pattern.cursor ","
      let rest ← psPscv0ListPatterns fuel comma.cursor
      return { value := pattern.value :: rest.value, cursor := rest.cursor }
    return { value := [pattern.value], cursor := pattern.cursor }

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

-- Every alternative pattern list keeps its own source binder scope.
def psPscv0AlternativePatterns (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List (List PsSyntaxPattern))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let patterns ← psPscv0Patterns fuel cursor
    if psTokenCursorAtText patterns.cursor "|" then
      let bar ← psTokenCursorExpectText patterns.cursor "|"
      let rest ← psPscv0AlternativePatterns fuel bar.cursor
      return { value := patterns.value :: rest.value, cursor := rest.cursor }
    return { value := [patterns.value], cursor := patterns.cursor }

def psPscv0MatchRows (read : PsPscv0TermReader) (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "}" then return { value := [], cursor }
    let bar ← psTokenCursorExpectText cursor "|"
    let patterns ← psPscv0AlternativePatterns fuel bar.cursor
    let arrow ← psTokenCursorExpectText patterns.cursor "=>"
    let body ← read arrow.cursor
    let rest ← psPscv0MatchRows read fuel body.cursor
    return {
      value := patterns.value.map (fun row => (row, body.value,
        psSyntaxSpanJoin bar.token.span (psSyntaxTermSpan body.value))) ++ rest.value
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

-- Pattern-derived term forms all lower to the same matrix node.
def psPscv0IfLetStart (cursor : PsTokenCursor) : Bool :=
  match cursor.remaining with
  | _ :: token :: _ => token.text == "let"
  | _ => false

def psPscv0ReadIfLet (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "if"
  let binding ← psTokenCursorExpectText keyword.cursor "let"
  let pattern ← psPscv0Pattern fuel binding.cursor
  let assign ← psTokenCursorExpectText pattern.cursor ":="
  let value ← read assign.cursor
  let yesOpen ← psTokenCursorExpectText value.cursor "{"
  let yes ← read yesOpen.cursor
  let yesClose ← psTokenCursorExpectText yes.cursor "}"
  let otherwise ← psTokenCursorExpectText yesClose.cursor "else"
  let noOpen ← psTokenCursorExpectText otherwise.cursor "{"
  let no ← read noOpen.cursor
  let close ← psTokenCursorExpectText no.cursor "}"
  let span := psSyntaxSpanJoin keyword.token.span close.token.span
  return {
    value := .matchE value.value
      [(pattern.value, yes.value, psSyntaxTermSpan yes.value),
       (.wildcard noOpen.token.span, no.value, psSyntaxTermSpan no.value)] span
    cursor := close.cursor }

def psPscv0ReadLetWithSeparator (read readAnnotation continuation : PsPscv0TermReader)
    (separator : PsSourcePos → PsTokenCursor → Except PsParseError PsTokenCursor)
    (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "let"
  let pattern ← psPscv0Pattern fuel keyword.cursor
  let annotation ← if psTokenCursorAtText pattern.cursor ":" then do
      let colon ← psTokenCursorExpectText pattern.cursor ":"
      let type ← readAnnotation colon.cursor
      pure (PsParseResult.mk (some type.value) type.cursor)
    else pure (PsParseResult.mk none pattern.cursor)
  let assign ← psTokenCursorExpectText annotation.cursor ":="
  let value ← read assign.cursor
  let next ← separator (psSyntaxTermSpan value.value).stop value.cursor
  let body ← continuation next
  let span := psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan body.value)
  let term := match pattern.value with
    | .variable name => PsSyntaxTerm.letE name annotation.value value.value body.value span
    | pattern =>
      let value := match annotation.value with
        | none => value.value
        | some type => .ascription value.value type (psSyntaxTermSpan value.value)
      .matchE value [(pattern, body.value, psSyntaxTermSpan body.value)] span
  return { value := term, cursor := body.cursor }

-- Surface readers own separators; pattern scope and annotation ownership are shared.
def psPscv0ReadLet (read readAnnotation continuation : PsPscv0TermReader)
    (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psPscv0ReadLetWithSeparator read readAnnotation continuation
    psParseProofScriptBodySeparator fuel cursor

def psPscv0MatchesTail (value : PsParseResult PsSyntaxTerm) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  if !psTokenCursorAtText value.cursor "matches" then return value
  let keyword ← psTokenCursorExpectText value.cursor "matches"
  let pattern ← psPscv0Pattern (keyword.cursor.remaining.length + 1) keyword.cursor
  let span := psSyntaxSpanJoin (psSyntaxTermSpan value.value) (psSyntaxPatternSpan pattern.value)
  let test := PsSyntaxTerm.matchE value.value
    [(pattern.value, .bool true span, span), (.wildcard span, .bool false span, span)] span
  return {
    value := .ascription test (.reference (PsSyntaxName.mk ["_root_", "Bool"] span)) span
    cursor := pattern.cursor }

