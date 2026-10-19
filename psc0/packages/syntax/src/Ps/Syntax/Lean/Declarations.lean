import Ps.Syntax.Lean.Data

-- Pinned Parser.Term.Termination owns suffix order; native decreasing_by
-- supplies a tactic sequence, whereas .ps owns the explicit by { ... } spelling.
def psLeanReadTermination (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxTermination) := do
  let keyword ← psPscv0Expect cursor "termination_by"
  if psTokenCursorAtText keyword.cursor "structural" then
    throw "PSCV0-TERM-01: termination_by structural is not selected"
  let measure ← (psLeanReadTerm false keyword.cursor).mapError psPscv0ParseError
  let (decreasing, next, stop) ← if psTokenCursorAtText measure.cursor "decreasing_by" then do
    let decrease ← psPscv0Expect measure.cursor "decreasing_by"
    let some first := psTokenCursorPeek decrease.cursor | throw "PSCV0-TERM-01: decreasing tactic required"
    if first.text != "{" && first.span.start.column <= decrease.token.span.start.column then
      throw "PSCV0-TERM-01: indented native decreasing tactic required"
    let proof ← (psLeanTermTactics (psLeanReadTerm false) (psLeanReadTerm true)
      (decrease.cursor.remaining.length + 1) decrease.token.span decrease.cursor).mapError psPscv0ParseError
    pure (some proof.value, proof.cursor, (psSyntaxTermSpan proof.value).stop)
  else pure (none, measure.cursor, (psSyntaxTermSpan measure.value).stop)
  if ["termination_by", "decreasing_by", "partial_fixpoint", "monotonicity"].any
      (psTokenCursorAtText next) then
    throw "PSCV0-REC-STRATEGY-01: duplicate or incompatible native recursion suffix"
  let value : PsSyntaxTermination := {
    measure := measure.value, decreasing
    span := { start := keyword.token.span.start, stop } }
  return { value, cursor := next }

def psLeanProgramValueWithoutWhere (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) := do
  let some first := psTokenCursorAdvance cursor | throw "PSCV0-LEAN-DECLARATION"
  let modifier := first.token.text
  let head ← if ["partial", "noncomputable"].contains modifier then
    psPscv0Expect first.cursor "def"
  else pure first
  if !["def", "theorem", "abbrev", "opaque"].contains head.token.text then
    throw "PSCV0-LEAN-DECLARATION: selected value declaration required"
  let name ← (psParseSyntaxName head.cursor).mapError psPscv0ParseError
  let binders ← (psLeanProgramBinders name.cursor).mapError psPscv0ParseError
  let type ← (psLeanProgramResult (!["def", "abbrev"].contains head.token.text) binders.cursor).mapError
    psPscv0ParseError
  let assign ← psPscv0Expect type.cursor ":="
  let body ← (psLeanReadTerm false assign.cursor).mapError psPscv0ParseError
  let span := PsSourceSpan.mk first.token.span.start (psLeanTermStop body.value)
  let declaration :=
    if modifier == "partial" then
      PsSyntaxDeclaration.partialDefinition name.value binders.value type.value body.value span
    else if modifier == "noncomputable" then
      .noncomputableDefinition name.value binders.value type.value body.value span
    else if head.token.text == "theorem" then
      .theoremDecl name.value binders.value type.value body.value span
    else .definition name.value binders.value type.value body.value span
  if psTokenCursorAtText body.cursor "decreasing_by" then
    throw "PSCV0-TERM-01: decreasing_by requires a preceding termination_by measure"
  if psTokenCursorAtText body.cursor "partial_fixpoint" then
    if modifier != "def" then
      throw "PSCV0-REC-STRATEGY-01: partial_fixpoint requires an ordinary def"
    let suffix ← psPscv0Expect body.cursor "partial_fixpoint"
    if ["partial_fixpoint", "termination_by", "decreasing_by", "monotonicity"].any
        (psTokenCursorAtText suffix.cursor) then
      throw "PSCV0-FIXPOINT-01: duplicate, incompatible or unselected fixedpoint suffix"
    let declaration := PsSyntaxDeclaration.fixedpointDefinition
      name.value binders.value type.value body.value { span with stop := suffix.token.span.stop }
    return { value := declaration, cursor := suffix.cursor }
  if psTokenCursorAtText body.cursor "termination_by" then
    if !["def", "abbrev", "opaque"].contains modifier then
      throw "PSCV0-REC-STRATEGY-01: termination_by requires a total value declaration"
    let suffix ← psLeanReadTermination body.cursor
    let sourceSpan := { span with stop := suffix.value.span.stop }
    let declaration := PsSyntaxDeclaration.wellFoundedDefinition
      name.value binders.value type.value body.value suffix.value sourceSpan
    return { value := declaration, cursor := suffix.cursor }
  return { value := declaration, cursor := body.cursor }

def psLeanReadLocalDefinition (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxLocalDefinition) := do
  let name ← (psParseProofScriptDeclaredName cursor).mapError psPscv0ParseError
  let binders ← (psLeanProgramBinders name.cursor).mapError psPscv0ParseError
  let (type, next) ← if psTokenCursorAtText binders.cursor ":" then do
    let colon ← psPscv0Expect binders.cursor ":"
    let type ← (psLeanReadTerm true colon.cursor).mapError psPscv0ParseError
    pure (some type.value, type.cursor)
  else pure (none, binders.cursor)
  let assign ← psPscv0Expect next ":="
  let body ← (psLeanReadTerm false assign.cursor).mapError psPscv0ParseError
  let (recursion, next, stop) ← if psTokenCursorAtText body.cursor "termination_by" then do
    let suffix ← psLeanReadTermination body.cursor
    pure (some (PsSyntaxLocalRecursion.total suffix.value), suffix.cursor, suffix.value.span.stop)
  else if psTokenCursorAtText body.cursor "partial_fixpoint" then do
    let suffix ← psPscv0Expect body.cursor "partial_fixpoint"
    pure (some (PsSyntaxLocalRecursion.fixedpoint suffix.token.span), suffix.cursor, suffix.token.span.stop)
  else pure (none, body.cursor, psLeanTermStop body.value)
  if ["termination_by", "decreasing_by", "partial_fixpoint", "monotonicity"].any (psTokenCursorAtText next) then
    throw "PSCV0-REC-STRATEGY-01: duplicate, incompatible or unselected local suffix"
  if psTokenCursorAtText next "where" then
    throw "PSCV0-D-WHERE-01: nested local where declarations are not selected"
  let value : PsSyntaxLocalDefinition := {
    name := name.value, binders := binders.value, type, value := body.value, recursion
    span := { start := name.value.span.start, stop } }
  return { value, cursor := next }

-- Like pinned sepByIndent, a semicolon separates same-line helpers; newline
-- separators keep the first helper's column. The parser creates no captures or
-- provisional global declarations: shared Where/PreDefinition owns those.
def psLeanReadLocalDefinitions (fuel column : Nat) (cursor : PsTokenCursor)
    (accRev : List PsSyntaxLocalDefinition) :
    Except String (PsParseResult (List PsSyntaxLocalDefinition)) := do
  match fuel with
  | 0 => throw "PSCV0-D-WHERE-BUDGET"
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | return { value := accRev.reverse, cursor }
    if psTokenCursorDone cursor || !psTokenKindEq token.kind .identifier ||
        psLeanReservedApplicationToken token || psPscv0ReservedArgument token.text ||
        token.span.start.column < column then return { value := accRev.reverse, cursor }
    let localDefinition ← psLeanReadLocalDefinition cursor
    let next ← if psTokenCursorAtText localDefinition.cursor ";" then
      pure (← psPscv0Expect localDefinition.cursor ";").cursor
    else
      if let some next := psTokenCursorPeek localDefinition.cursor then
        if !psTokenCursorDone localDefinition.cursor && !psLeanReservedApplicationToken next &&
            !psPscv0ReservedArgument next.text &&
            (!psProofScriptLaterLine localDefinition.value.span.stop localDefinition.cursor ||
              next.span.start.column > column) then
          throw "PSCV0-D-WHERE-01: aligned helper or native semicolon required"
      pure localDefinition.cursor
    psLeanReadLocalDefinitions fuel column next (localDefinition.value :: accRev)

def psLeanProgramValue (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) := do
  let parsed ← psLeanProgramValueWithoutWhere cursor
  if !psTokenCursorAtText parsed.cursor "where" then return parsed
  let marker ← psPscv0Expect parsed.cursor "where"
  let some first := psTokenCursorPeek marker.cursor | throw "PSCV0-D-WHERE-01: local definition required"
  let locals ← psLeanReadLocalDefinitions 4096 first.span.start.column marker.cursor []
  let some last := locals.value.getLast? | throw "PSCV0-D-WHERE-01: local definition required"
  if ["termination_by", "decreasing_by", "partial_fixpoint", "where"].any
      (psTokenCursorAtText locals.cursor) then
    throw "PSCV0-REC-STRATEGY-01: recursion suffix belongs before where"
  let span := PsSourceSpan.mk marker.token.span.start last.span.stop
  let value := PsSyntaxDeclaration.whereDeclaration parsed.value locals.value span
  return { value, cursor := locals.cursor }

