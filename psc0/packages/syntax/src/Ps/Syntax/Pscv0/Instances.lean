import Ps.Syntax.Pscv0.Commands

def psPscv0PriorityValue (text : String) (cursor : PsTokenCursor) :
    Except PsParseError Nat := do
  match text with
  | "low" => pure 100
  | "mid" => pure 500
  | "default" => pure 1000
  | "high" => pure 10000
  | text =>
    if text.isEmpty || !text.toList.all Char.isDigit then
      throw (psProofScriptExpectedError "decimal or named instance priority" cursor)
    match text.toNat? with
    | some value => pure value
    | none => throw (psProofScriptExpectedError "natural instance priority" cursor)

def psPscv0InstancePriority (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult Nat) := do
  let named := match psTokenCursorAdvance cursor with
    | some opening => opening.token.text == "(" && psTokenCursorAtText opening.cursor "priority"
    | none => false
  if !named then return { value := 1000, cursor }
  let opening ← psTokenCursorExpectText cursor "("
  let keyword ← psTokenCursorExpectText opening.cursor "priority"
  let assign ← psTokenCursorExpectText keyword.cursor ":="
  let some atom := psTokenCursorAdvance assign.cursor
    | throw (.unexpectedEnd "instance priority")
  let priority ← psPscv0PriorityValue atom.token.text assign.cursor
  let close ← psTokenCursorExpectText atom.cursor ")"
  return { value := priority, cursor := close.cursor }

-- Field headers are declarations, not calls. Lower their result annotation
-- inside the lambda so it sees every preceding field parameter.
def psPscv0InstanceField
    (readBinders : PsTokenCursor → Except PsParseError
      (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))))
    (readType readBody : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (PsSyntaxName × PsSyntaxTerm)) := do
  let name ← psTokenCursorExpectKind cursor .identifier
  let fieldName := (psSyntaxNameFromToken name.token)
  let binders ← readBinders name.cursor
  let annotation ←
    if psTokenCursorAtText binders.cursor ":" then do
      let colon ← psTokenCursorExpectText binders.cursor ":"
      let type ← readType colon.cursor
      pure (PsParseResult.mk (some type.value) type.cursor)
    else pure (PsParseResult.mk none binders.cursor)
  let assign ← psTokenCursorExpectText annotation.cursor ":="
  let body ← readBody assign.cursor
  let span := psSyntaxSpanJoin name.token.span (psSyntaxTermSpan body.value)
  let value := match annotation.value with
    | none => body.value
    | some type => .ascription body.value type span
  let value := if binders.value.isEmpty then value else .lambda binders.value value span
  return { value := (fieldName, value), cursor := body.cursor }

def psPscv0InstanceFields (fuel : Nat) (cursor : PsTokenCursor)
    (acc : List (PsSyntaxName × PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (PsSyntaxName × PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "}" then return { value := acc.reverse, cursor }
    let field ← psPscv0InstanceField (psPscv0DataParameters (fuel + 1))
      (psPscv0ParseTerm true) psPscv0ParseDefinitionBody cursor
    if acc.any (fun entry => entry.fst.segments == field.value.1.segments) then
      throw (psProofScriptExpectedError "unique instance field" cursor)
    if !psTokenCursorAtText field.cursor "}" then
      if psTokenCursorAtText field.cursor "," || psTokenCursorAtText field.cursor ";" ||
          !psProofScriptLaterLine (psSyntaxTermSpan field.value.2).stop field.cursor then
        throw (psProofScriptExpectedError "newline-separated instance field" field.cursor)
    psPscv0InstanceFields fuel field.cursor (field.value :: acc)

def psPscv0ReadInstance (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxCommand) := do
  let keyword ← psTokenCursorExpectText cursor "instance"
  let priority ← psPscv0InstancePriority keyword.cursor
  let name ← match psTokenCursorPeek priority.cursor with
    | some token =>
      if psTokenKindEq token.kind .identifier && !psProofScriptReservedArgument token.text then
        psParseProofScriptDeclaredName priority.cursor
      else pure (PsParseResult.mk
        (PsSyntaxName.mk ["$psc0Instance" ++ psNatToString keyword.token.span.start.byteOffset]
          keyword.token.span) priority.cursor)
    | none => throw (.unexpectedEnd "instance header")
  let binders ← psPscv0DataParameters 4096 name.cursor
  let colon ← psTokenCursorExpectText binders.cursor ":"
  let type ← psPscv0ParseTerm true colon.cursor
  let keywordWhere ← psTokenCursorExpectText type.cursor "where"
  let opening ← psTokenCursorExpectText keywordWhere.cursor "{"
  let fields ← psPscv0InstanceFields 4096 opening.cursor []
  let close ← psTokenCursorExpectText fields.cursor "}"
  let span := psSyntaxSpanJoin keyword.token.span close.token.span
  return {
    value := .registeredDeclaration
      (.definition name.value binders.value type.value (.record fields.value span) span)
      (.instanceDecl priority.value)
    cursor := close.cursor }
