import Ps.Syntax.Pscv0.TermRead

-- Data declarations own their delimiters; every annotation and parameter
-- telescope uses the same v7 readers as value declarations.
def psPscv0DataParameters (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
  psPscv0ParameterGroups (psPscv0ParseTerm true) (psPscv0ParseTerm false)
    fuel true false false cursor []

-- Structure fields have native named groups, not declaration comma groups.
-- Defaults and field methods require their own structure semantics later.
def psPscv0StructureField (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (Prod PsSyntaxBinderHead PsSyntaxTerm)) := do
  let field ←
    if psTokenCursorAtBinderStart cursor then do
      let opening ← psParseBinderOpening cursor
      match opening.kind with
      | .strictImplicit =>
        throw (psProofScriptExpectedError "explicit, implicit or named instance structure field" cursor)
      | _ => pure ()
      let entry ← psPscv0BinderEntry (psPscv0ParseTerm true) (psPscv0ParseTerm false)
        fuel opening.kind true false true opening.cursor
      let close ← psParseBinderClosing opening entry.cursor
      pure (PsParseResult.mk ({ entry.value.fst with span := close.value }, entry.value.snd) close.cursor)
    else
      psPscv0BinderEntry (psPscv0ParseTerm true) (psPscv0ParseTerm false)
        fuel .explicit true false false cursor
  if psTokenCursorAtText field.cursor "}" then return field
  if psTokenCursorAtText field.cursor ";" || psTokenCursorAtText field.cursor "," then
    throw (psProofScriptExpectedError "newline-separated structure field" field.cursor)
  if !psProofScriptLaterLine field.value.fst.span.stop field.cursor then
    throw (psProofScriptExpectedError "newline or closing structure brace" field.cursor)
  return field

def psPscv0StructureFields (fuel : Nat) (cursor : PsTokenCursor)
    (accRev : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "}" then return { value := accRev.reverse, cursor }
    let field ← psPscv0StructureField (fuel + 1) cursor
    psPscv0StructureFields fuel field.cursor (field.value :: accRev)

def psPscv0Constructors (fuel : Nat) (cursor : PsTokenCursor)
    (accRev : List PsSyntaxInductiveConstructor) :
    Except PsParseError (PsParseResult (List PsSyntaxInductiveConstructor)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "}" then return { value := accRev.reverse, cursor }
    let bar ← psTokenCursorExpectText cursor "|"
    let name ← psParseProofScriptDeclaredName bar.cursor
    let fields ← psPscv0DataParameters (fuel + 1) name.cursor
    let result ←
      if psTokenCursorAtText fields.cursor ":" then do
        let colon ← psTokenCursorExpectText fields.cursor ":"
        let type ← psPscv0ParseTerm true colon.cursor
        pure (PsParseResult.mk (some type.value) type.cursor)
      else pure (PsParseResult.mk none fields.cursor)
    if !psTokenCursorAtText result.cursor "|" && !psTokenCursorAtText result.cursor "}" then
      throw (psProofScriptExpectedError "next constructor bar or closing brace" result.cursor)
    let constructor : PsSyntaxInductiveConstructor := {
      name := name.value
      fields := fields.value
      resultType := result.value
      span := { start := bar.token.span.start
                stop := match result.value with
                  | some type => (psSyntaxTermSpan type).stop
                  | none => psProofScriptLastBinderStop name.value.span.stop fields.value } }
    psPscv0Constructors fuel result.cursor (constructor :: accRev)

def psPscv0ReadDataDeclaration (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) := do
  let some keyword := psTokenCursorAdvance cursor | throw (.unexpectedEnd "data declaration")
  let isStructure := ["structure", "class"].contains keyword.token.text
  let name ← psParseProofScriptDeclaredName keyword.cursor
  let fuel := Nat.succ (psParseListLength name.cursor.remaining)
  let params ← psPscv0DataParameters fuel name.cursor
  let result ←
    if psTokenCursorAtText params.cursor ":" then do
      let colon ← psTokenCursorExpectText params.cursor ":"
      let type ← psPscv0ParseTerm true colon.cursor
      pure (PsParseResult.mk (some type.value) type.cursor)
    else pure (PsParseResult.mk none params.cursor)
  let afterWhere ← psTokenCursorExpectText result.cursor "where"
  let opening ← psTokenCursorExpectText afterWhere.cursor "{"
  if isStructure then
    let fields ← psPscv0StructureFields fuel opening.cursor []
    let close ← psTokenCursorExpectText fields.cursor "}"
    return {
      value := .structureDecl name.value params.value result.value fields.value
        (psSyntaxSpanJoin keyword.token.span close.token.span)
      cursor := close.cursor }
  else
    let constructors ← psPscv0Constructors fuel opening.cursor []
    let close ← psTokenCursorExpectText constructors.cursor "}"
    return {
      value := .inductiveDecl name.value params.value result.value constructors.value
        (psSyntaxSpanJoin keyword.token.span close.token.span)
      cursor := close.cursor }
