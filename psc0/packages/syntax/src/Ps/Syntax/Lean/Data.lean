import Ps.Syntax.Lean.Binders
import Ps.Syntax.Pscv0.Instances

-- Native command layout follows pinned Parser.Command.structFields and
-- Parser.Extra.manyIndent/sepByIndent. Field annotations and instance values
-- reuse the common v7 nodes and their single semantic elaborators.
def psLeanFieldStart (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
    !psTokenCursorDone cursor && !psLeanReservedApplicationToken token &&
      !psPscv0ReservedArgument token.text &&
      (psTokenKindEq token.kind .identifier || psTokenCursorAtBinderStart cursor)

def psLeanStructureFields (fuel : Nat) (column : Option Nat) (cursor : PsTokenCursor)
    (accRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | return { value := accRev.reverse, cursor }
    if !psLeanFieldStart cursor || column.any (token.span.start.column < ·) then
      return { value := accRev.reverse, cursor }
    let field ← psPscv0StructureFieldHead (psLeanReadTerm true) (psLeanReadTerm false) fuel cursor
    if !psTokenCursorDone field.cursor &&
        !psProofScriptLaterLine field.value.1.span.stop field.cursor then
      throw (psProofScriptExpectedError "newline after native structure field" field.cursor)
    psLeanStructureFields fuel (some (column.getD token.span.start.column)) field.cursor
      (field.value :: accRev)

def psLeanConstructors (fuel : Nat) (cursor : PsTokenCursor)
    (accRev : List PsSyntaxInductiveConstructor) :
    Except PsParseError (PsParseResult (List PsSyntaxInductiveConstructor)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !psTokenCursorAtText cursor "|" then return { value := accRev.reverse, cursor }
    let bar ← psTokenCursorExpectText cursor "|"
    let name ← psParseProofScriptDeclaredName bar.cursor
    let fields ← psLeanProgramBinders name.cursor
    let result ← if psTokenCursorAtText fields.cursor ":" then do
      let colon ← psTokenCursorExpectText fields.cursor ":"
      let type ← psLeanReadTerm true colon.cursor
      pure (PsParseResult.mk (some type.value) type.cursor)
    else pure (PsParseResult.mk none fields.cursor)
    let stop := result.value.map (fun term => (psSyntaxTermSpan term).stop) |>.getD
      (psProofScriptLastBinderStop name.value.span.stop fields.value)
    let entry : PsSyntaxInductiveConstructor := {
      name := name.value, fields := fields.value, resultType := result.value
      span := { start := bar.token.span.start, stop } }
    psLeanConstructors fuel result.cursor (entry :: accRev)

def psLeanReadData (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) := do
  let some keyword := psTokenCursorAdvance cursor | throw (.unexpectedEnd "native data declaration")
  let name ← psParseSyntaxName keyword.cursor
  let params ← psLeanProgramBinders name.cursor
  let result ← if psTokenCursorAtText params.cursor ":" then do
    let colon ← psTokenCursorExpectText params.cursor ":"
    let type ← psLeanReadTerm true colon.cursor
    pure (PsParseResult.mk (some type.value) type.cursor)
  else pure (PsParseResult.mk none params.cursor)
  let headerStop := result.value.map (fun term => (psSyntaxTermSpan term).stop) |>.getD
    (psProofScriptLastBinderStop name.value.span.stop params.value)
  let (body, headerStop) ← if psTokenCursorAtText result.cursor "where" then do
    let marker ← psTokenCursorExpectText result.cursor "where"
    pure (marker.cursor, marker.token.span.stop)
  else pure (result.cursor, headerStop)
  if keyword.token.text == "inductive" then
    let constructors ← psLeanConstructors 4096 body []
    let stop := constructors.value.getLast?.map (·.span.stop) |>.getD headerStop
    let span := PsSourceSpan.mk keyword.token.span.start stop
    let value := PsSyntaxDeclaration.inductiveDecl name.value params.value result.value constructors.value span
    return { value, cursor := constructors.cursor }
  else
    let fields ← psLeanStructureFields 4096 none body []
    let stop := psProofScriptLastBinderStop headerStop fields.value
    let span := PsSourceSpan.mk keyword.token.span.start stop
    let value := PsSyntaxDeclaration.structureDecl name.value params.value result.value fields.value span
    return { value, cursor := fields.cursor }

-- Native instance field parameters may omit annotations; their types come
-- from the checked class-field telescope through the shared lambda elaborator.
def psLeanInstanceFieldBinders (fuel : Nat) (cursor : PsTokenCursor)
    (accRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtBinderStart cursor then
      let opening ← psParseBinderOpening cursor
      let group ← psPscv0BinderGroup (psLeanReadTerm true) (psLeanReadTerm false)
        fuel opening false false false
      psLeanInstanceFieldBinders fuel group.cursor (group.value.reverse ++ accRev)
    else
      let some token := psTokenCursorPeek cursor | return { value := accRev.reverse, cursor }
      if !psTokenKindEq token.kind .identifier || psPscv0ReservedArgument token.text then
        return { value := accRev.reverse, cursor }
      let name ← psTokenCursorExpectKind cursor .identifier
      let head := PsSyntaxBinderHead.mk (PsSyntaxName.mk [name.token.text] name.token.span)
        .explicit name.token.span
      psLeanInstanceFieldBinders fuel name.cursor ((head, .hole name.token.span) :: accRev)

def psLeanInstanceFields (fuel : Nat) (column : Option Nat) (cursor : PsTokenCursor)
    (accRev : List (PsSyntaxName × PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (PsSyntaxName × PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | return { value := accRev.reverse, cursor }
    if !psLeanFieldStart cursor || column.any (token.span.start.column < ·) then
      return { value := accRev.reverse, cursor }
    let field ← psPscv0InstanceField (fun cursor => psLeanInstanceFieldBinders fuel cursor [])
      (psLeanReadTerm true) (psLeanReadTerm false) cursor
    if accRev.any (fun entry => entry.1.segments == field.value.1.segments) then
      throw (psProofScriptExpectedError "unique instance field" cursor)
    let column := column.getD token.span.start.column
    let next ← if psTokenCursorAtText field.cursor ";" then
      pure (← psTokenCursorExpectText field.cursor ";").cursor
    else
      if let some next := psTokenCursorPeek field.cursor then
        if !psTokenCursorDone field.cursor && psLeanFieldStart field.cursor &&
            (!psProofScriptLaterLine (psSyntaxTermSpan field.value.2).stop field.cursor ||
              next.span.start.column > column) then
          throw (psProofScriptExpectedError "aligned native instance field or semicolon" field.cursor)
      pure field.cursor
    psLeanInstanceFields fuel (some column) next (field.value :: accRev)

def psLeanReadInstance (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (PsSyntaxDeclaration × Nat)) := do
  let keyword ← psTokenCursorExpectText cursor "instance"
  let priority ← psPscv0InstancePriority keyword.cursor
  let name ← match psTokenCursorPeek priority.cursor with
    | some token =>
      if psTokenKindEq token.kind .identifier && !psPscv0ReservedArgument token.text then
        psParseSyntaxName priority.cursor
      else pure (PsParseResult.mk
        (PsSyntaxName.mk ["$psc0Instance" ++ psNatToString keyword.token.span.start.byteOffset]
          keyword.token.span) priority.cursor)
    | none => throw (.unexpectedEnd "native instance header")
  let binders ← psLeanProgramBinders name.cursor
  let colon ← psTokenCursorExpectText binders.cursor ":"
  let type ← psLeanReadTerm true colon.cursor
  let marker ← psTokenCursorExpectText type.cursor "where"
  let fields ← psLeanInstanceFields 4096 none marker.cursor []
  let stop := fields.value.getLast?.map (fun entry => (psSyntaxTermSpan entry.2).stop)
    |>.getD marker.token.span.stop
  let span := PsSourceSpan.mk keyword.token.span.start stop
  let value := PsSyntaxDeclaration.definition name.value binders.value type.value
    (.record fields.value span) span
  return { value := (value, priority.value), cursor := fields.cursor }
