import Ps.Syntax.Pscv0.Operators

-- RC4 explicitBinders is either typed parenthesized groups, or one unbracketed
-- group with an optional annotation. Mixing those grammars is not admitted.
def psPscv0ExistsGroups (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) (acc : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsParseError (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if !psTokenCursorAtText cursor "(" then
      return { value := acc.reverse, cursor }
    let opening ← psParseBinderOpening cursor
    let group ← psPscv0BinderGroup read read (fuel + 1) opening false true false
    psPscv0ExistsGroups read fuel group.cursor (group.value.reverse ++ acc)

def psPscv0ReadExists (readType readBody : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let some keyword := psTokenCursorAdvance cursor | throw (.unexpectedEnd "existential")
  let binders ← if psTokenCursorAtText keyword.cursor "(" then
      psPscv0ExistsGroups readType fuel keyword.cursor []
    else do
      let binder ← psPscv0BinderEntry readType readType fuel .explicit false false true keyword.cursor
      pure (PsParseResult.mk [binder.value] binder.cursor)
  let comma ← psTokenCursorExpectText binders.cursor ","
  let body ← readBody comma.cursor
  let span := psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan body.value)
  -- Preserve the pinned expandExplicitBinders macro: each nested lambda has
  -- its own copied annotation; this is distinct from a native forall group.
  let value := binders.value.foldr (fun (head, type) body =>
    (psSyntaxBinderNames head).foldr (fun name body =>
      psPscv0NotationCall "Exists"
        [.lambda [(PsSyntaxBinderHead.mk name .explicit head.span, type)] body span] span) body) body.value
  return { value, cursor := body.cursor }
