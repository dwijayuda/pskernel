import Ps.Syntax.Lean.Term

def psLeanProgramBinders (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  psPscv0ParameterGroups (psLeanReadTerm true) (psLeanReadTerm false) 4096 false false false cursor []

-- Groups retain syntax ownership; shared scope/elaboration processes their
-- binder views in native order, including annotation/default shadowing.
def psLeanProgramResult (required : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  if !required && psTokenCursorAtText cursor ":=" then
    let some token := psTokenCursorPeek cursor | throw (.unexpectedEnd "result")
    return { value := .omittedType { start := token.span.start, stop := token.span.start }, cursor }
  let colon ← psTokenCursorExpectText cursor ":"
  psLeanReadTerm true colon.cursor

