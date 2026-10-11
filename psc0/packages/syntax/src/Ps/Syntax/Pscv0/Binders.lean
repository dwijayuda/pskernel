import Ps.Syntax.Pscv0.TermRead

-- Declaration comma groups and native variable groups share entries but keep
-- distinct group rules. Defaults stay attached to their own binder annotation.
def psPscv0ParameterEntries (fuel : Nat) (opening : PsSyntaxBinderOpening)
    (commaGroup : Bool) (cursor : PsTokenCursor)
    (acc : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let name ← psTokenCursorExpectKind cursor .identifier
    let colon ← psTokenCursorExpectText name.cursor ":"
    let type ← psPscv0ParseTerm true colon.cursor
    let annotation ←
      if psTokenCursorAtText type.cursor ":=" then do
        match opening.kind with
        | .explicit => pure ()
        | _ => throw (psProofScriptExpectedError "default on explicit parameter" type.cursor)
        let assign ← psTokenCursorExpectText type.cursor ":="
        let value ← psPscv0ParseTerm false assign.cursor
        pure (PsParseResult.mk
          (.optionalType type.value value.value
            (psSyntaxSpanJoin (psSyntaxTermSpan type.value) (psSyntaxTermSpan value.value)))
          value.cursor)
      else pure type
    let head := PsSyntaxBinderHead.mk
      (PsSyntaxName.mk [name.token.text] name.token.span) opening.kind
      (psSyntaxSpanJoin name.token.span (psSyntaxTermSpan annotation.value))
    let acc := (head, annotation.value) :: acc
    if commaGroup && psTokenCursorAtText annotation.cursor "," then
      let comma ← psTokenCursorExpectText annotation.cursor ","
      if psTokenCursorAtText comma.cursor ")" then
        let close ← psParseBinderClosing opening comma.cursor
        return { value := acc.reverse, cursor := close.cursor }
      psPscv0ParameterEntries fuel opening commaGroup comma.cursor acc
    else
      let close ← psParseBinderClosing opening annotation.cursor
      return { value := acc.reverse, cursor := close.cursor }

def psPscv0ParameterGroups (fuel : Nat) (declaration nullary previousExplicit : Bool)
    (cursor : PsTokenCursor) (acc : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !psTokenCursorAtBinderStart cursor then return { value := acc, cursor }
    let opening ← psParseBinderOpening cursor
    let explicit := match opening.kind with | .explicit => true | _ => false
    if declaration && previousExplicit && explicit then
      throw (psProofScriptExpectedError "PSCV0-BIND-02: one explicit comma group" cursor)
    if explicit && psTokenCursorAtText opening.cursor ")" then
      if !nullary then throw (psProofScriptExpectedError "nonempty binder group" opening.cursor)
      let close ← psParseBinderClosing opening opening.cursor
      if psTokenCursorAtBinderStart close.cursor then
        throw (psProofScriptExpectedError "final nullary function group" close.cursor)
      let name := PsSyntaxName.mk ["_"] close.value
      let head := PsSyntaxBinderHead.mk name .explicit close.value
      let type := PsSyntaxTerm.reference (PsSyntaxName.mk ["_root_", "Unit"] close.value)
      return { value := acc ++ [(head, type)], cursor := close.cursor }
    let group ← psPscv0ParameterEntries (fuel + 1) opening
      (declaration && explicit) opening.cursor []
    psPscv0ParameterGroups fuel declaration nullary explicit group.cursor (acc ++ group.value)
