import Ps.Syntax.ParseLean
import Ps.Syntax.Pscv0.TermRead

-- Pinned Parser.Term let/if and Parser.Do own surface boundaries only.
-- Shared syntax, pattern matrices and typed do continuations own semantics.
def psLeanBodySeparator (stop : PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError PsTokenCursor := do
  if psTokenCursorAtText cursor ";" then
    return (← psTokenCursorExpectText cursor ";").cursor
  psParseProofScriptBodySeparator stop cursor

structure PsLeanConditionalHead where
  pattern : Option PsSyntaxPattern
  proofName : Option PsSyntaxName
  condition : PsSyntaxTerm
  span : PsSourceSpan

def psLeanConditionalHead (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsLeanConditionalHead) := do
  let keyword ← psTokenCursorExpectText cursor "if"
  let (pattern, proofName, condition, next) ←
    if psTokenCursorAtText keyword.cursor "let" then do
      let binding ← psTokenCursorExpectText keyword.cursor "let"
      let pattern ← psPscv0Pattern fuel binding.cursor
      let assign ← psTokenCursorExpectText pattern.cursor ":="
      let value ← read assign.cursor
      pure (some pattern.value, none, value.value, value.cursor)
    else do
      let (name, start) ← match keyword.cursor.remaining with
        | name :: colon :: _ =>
          if psTokenKindEq name.kind .identifier && colon.text == ":" then do
            let name ← psParseSyntaxName keyword.cursor
            let colon ← psTokenCursorExpectText name.cursor ":"
            pure (some name.value, colon.cursor)
          else pure (none, keyword.cursor)
        | _ => pure (none, keyword.cursor)
      let value ← read start
      pure (none, name, value.value, value.cursor)
  let thenToken ← psTokenCursorExpectText next "then"
  let value : PsLeanConditionalHead := { pattern, proofName, condition, span := keyword.token.span }
  return { value, cursor := thenToken.cursor }

def psLeanTermConditional (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let head ← psLeanConditionalHead read fuel cursor
  let yes ← read head.cursor
  let elseToken ← psTokenCursorExpectText yes.cursor "else"
  let no ← read elseToken.cursor
  let span := psSyntaxSpanJoin head.value.span (psSyntaxTermSpan no.value)
  let value := match head.value.pattern with
    | none => PsSyntaxTerm.ifE head.value.proofName head.value.condition yes.value no.value span
    | some pattern => .matchE head.value.condition
        [(pattern, yes.value, psSyntaxTermSpan yes.value),
         (.wildcard elseToken.token.span, no.value, psSyntaxTermSpan no.value)] span
  return { value, cursor := no.cursor }

-- many1Indent anchors subsequent items at the first item's column. A native
-- semicolon is optional, including before EOF. Delimiters remain caller-owned.
def psLeanDoEnd (column : Option Nat) (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => true
  | some token =>
    psTokenCursorDone cursor || ["}", ")", "]", ",", "|", "else"].contains token.text ||
      column.any (fun minimum => token.span.start.column < minimum) ||
      (psLeanReservedApplicationToken token &&
        !["let", "if", "do", "match", "nomatch", "fun"].contains token.text)

mutual
def psLeanDoSequence (read annotation : PsPscv0TermReader) (fuel : Nat)
    (column : Option Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxDoItem)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psLeanDoEnd column cursor then return { value := [], cursor }
    let item ← psLeanDoStatement read annotation fuel cursor
    let next ← if psTokenCursorAtText item.cursor ";" then
      pure (← psTokenCursorExpectText item.cursor ";").cursor
    else pure item.cursor
    let rest ← psLeanDoSequence read annotation fuel column next
    return { value := item.value :: rest.value, cursor := rest.cursor }

def psLeanDoBlock (read annotation : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List PsSyntaxDoItem × PsSourceSpan)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some first := psTokenCursorPeek cursor | throw (.unexpectedEnd "native do sequence")
    let braced := first.text == "{"
    let start ← if braced then pure (← psTokenCursorExpectText cursor "{").cursor
      else pure cursor
    let column := if braced then none else some first.span.start.column
    let body ← psLeanDoSequence read annotation fuel column start
    let some last := body.value.getLast? | throw (psProofScriptExpectedError "nonempty native do sequence" start)
    let (next, stop) ← if braced then do
      let close ← psTokenCursorExpectText body.cursor "}"
      pure (close.cursor, close.token.span.stop)
    else pure (body.cursor, (psSyntaxDoSpan last).stop)
    let span := PsSourceSpan.mk first.span.start stop
    return { value := (body.value, span), cursor := next }

def psLeanDoConditional (read annotation : PsPscv0TermReader) (fuel column : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxDoItem) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let head ← psLeanConditionalHead read fuel cursor
    let yes ← psLeanDoBlock read annotation fuel head.cursor
    let alternative := (psTokenCursorPeek yes.cursor).any fun token =>
      token.text == "else" && token.span.start.column >= column
    let (no, stop, next) ← if alternative then do
      let keyword ← psTokenCursorExpectText yes.cursor "else"
      -- Pinned elseIf uses the enclosing if column, not the later if token.
      if (psTokenCursorPeek keyword.cursor).any (fun token =>
          token.text == "if" && token.span.start.line == keyword.token.span.stop.line) then
        let item ← psLeanDoConditional read annotation fuel column keyword.cursor
        pure ([item.value], psSyntaxDoSpan item.value, item.cursor)
      else
        let body ← psLeanDoBlock read annotation fuel keyword.cursor
        pure (body.value.fst, body.value.snd, body.cursor)
    else pure ([], yes.value.snd, yes.cursor)
    let span := psSyntaxSpanJoin head.value.span stop
    let value := match head.value.pattern with
      | none => PsSyntaxDoItem.conditional head.value.proofName head.value.condition yes.value.fst no span
      | some pattern => .conditionalPattern pattern head.value.condition yes.value.fst no span
    return { value, cursor := next }

def psLeanDoStatement (read annotation : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxDoItem) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some first := psTokenCursorPeek cursor | throw (.unexpectedEnd "native do statement")
    if first.text == "if" then
      psLeanDoConditional read annotation fuel first.span.start.column cursor
    else
      -- Bindings, annotations, returns and actions use the existing selected
      -- statement owner with native term readers. Unsupported control refuses.
      psPscv0DoStatement read annotation fuel cursor
end

def psLeanReadDo (read annotation : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "do"
  let body ← psLeanDoBlock read annotation fuel keyword.cursor
  let value := PsSyntaxTerm.doE body.value.fst (psSyntaxSpanJoin keyword.token.span body.value.snd)
  return { value, cursor := body.cursor }
