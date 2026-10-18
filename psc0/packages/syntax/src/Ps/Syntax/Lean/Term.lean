import Ps.Syntax.ParseLean
import Ps.Syntax.Pscv0.TermRead

-- Lean 4.35.0 Parser.Term.argument requires whitespace and indentation.
-- The complete primary span includes closing delimiters; adjacent comma calls
-- remain exclusively a ProofScript grammar choice.
def psLeanTermArgumentStart (annotation : Bool) (head : PsSyntaxTerm)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
    let span := psSyntaxTermSpan head
    !psLeanReservedApplicationToken token && !psPscv0ReservedArgument token.text &&
      (psPscv0InfixToken cursor).isNone &&
      (annotation || !psTokenCursorStartsNamedAssignment cursor) &&
      token.span.start.byteOffset > span.stop.byteOffset &&
      (token.span.start.line == span.stop.line || token.span.start.column > span.start.column) &&
      (["(", "[", "{", "#"].contains token.text ||
        psTokenKindEq token.kind .identifier || psTokenKindEq token.kind .natural ||
        psTokenKindEq token.kind .scientific || psTokenKindEq token.kind .string ||
        psTokenKindEq token.kind .character)

def psLeanTermApplicationTail (read : PsPscv0TermReader) (annotation : Bool)
    (fuel : Nat) (head : PsSyntaxTerm)
    (argumentsRev : List (Option PsSyntaxName × PsSyntaxTerm))
    (stop : PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let span := PsSourceSpan.mk (psSyntaxTermSpan head).start stop
    let current := psProofScriptTermWithSpan head span
    if !psLeanTermArgumentStart annotation current cursor then
      let arguments := argumentsRev.reverse
      let value := if arguments.isEmpty then head
        else if arguments.any (fun item => item.fst.isSome) then
          PsSyntaxTerm.call head arguments span
        else .app head (arguments.map Prod.snd) span
      return { value, cursor }
    let named := match cursor.remaining with
      | opening :: name :: assign :: _ =>
        opening.text == "(" && psTokenKindEq name.kind .identifier && assign.text == ":="
      | _ => false
    let argument ← if named then do
      let opening ← psTokenCursorExpectText cursor "("
      let name ← psParseSyntaxName opening.cursor
      let assign ← psTokenCursorExpectText name.cursor ":="
      let value ← read assign.cursor
      let close ← psTokenCursorExpectText value.cursor ")"
      pure (some name.value, value.value, close.cursor, close.token.span.stop)
    else do
      let primary ← psPscv0Primary read cursor
      let value ← psPscv0PostfixFor false read fuel primary.value primary.cursor
      pure (none, value.value, value.cursor, (psSyntaxTermSpan value.value).stop)
    psLeanTermApplicationTail read annotation fuel head
      ((argument.1, argument.2.1) :: argumentsRev) argument.2.2.2 argument.2.2.1

def psLeanTermApplication (read : PsPscv0TermReader) (annotation : Bool)
    (fuel : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let primary ← psPscv0Primary read cursor
  let head ← psPscv0PostfixFor false read fuel primary.value primary.cursor
  psLeanTermApplicationTail read annotation fuel head.value []
    (psSyntaxTermSpan head.value).stop head.cursor

def psLeanTermConditional (read : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "if"
  let (proofName, cursor) ← match keyword.cursor.remaining with
    | name :: colon :: _ =>
      if psTokenKindEq name.kind .identifier && colon.text == ":" then do
        let name ← psParseSyntaxName keyword.cursor
        let colon ← psTokenCursorExpectText name.cursor ":"
        pure (some name.value, colon.cursor)
      else pure (none, keyword.cursor)
    | _ => pure (none, keyword.cursor)
  let condition ← read cursor
  let thenToken ← psTokenCursorExpectText condition.cursor "then"
  let yes ← read thenToken.cursor
  let elseToken ← psTokenCursorExpectText yes.cursor "else"
  let no ← read elseToken.cursor
  let span := psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan no.value)
  let value := PsSyntaxTerm.ifE proofName condition.value yes.value no.value span
  return { value, cursor := no.cursor }

def psLeanTermMatchRows (read : PsPscv0TermReader) (fuel : Nat) (anchor : PsSourcePos)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List (List PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | return { value := [], cursor }
    if token.text != "|" || (token.span.start.line > anchor.line && token.span.start.column != anchor.column) then
      return { value := [], cursor }
    let bar ← psTokenCursorExpectText cursor "|"
    let patterns ← psPscv0Patterns fuel bar.cursor
    let arrow ← psTokenCursorExpectText patterns.cursor "=>"
    let body ← read arrow.cursor
    let rest ← psLeanTermMatchRows read fuel anchor body.cursor
    let span := psSyntaxSpanJoin bar.token.span (psSyntaxTermSpan body.value)
    let row := (patterns.value, body.value, span)
    return { value := row :: rest.value, cursor := rest.cursor }

def psLeanTermMatch (read : PsPscv0TermReader) (fuel : Nat) (impossible : Bool)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let some keyword := psTokenCursorAdvance cursor | throw (.unexpectedEnd "match")
  let inputs ← psPscv0Discriminants read fuel keyword.cursor
  let some last := inputs.value.getLast? | throw (.unexpectedEnd "match discriminant")
  if impossible then return {
    value := .matchMany inputs.value [] (psSyntaxSpanJoin keyword.token.span (psSyntaxTermSpan last))
    cursor := inputs.cursor }
  let withToken ← psTokenCursorExpectText inputs.cursor "with"
  let some first := psTokenCursorPeek withToken.cursor | throw (.unexpectedEnd "native match alternatives")
  let rows ← psLeanTermMatchRows read fuel first.span.start withToken.cursor
  let some (_, _, lastSpan) := rows.value.getLast? | throw (.unexpectedEnd "native match alternatives")
  let span := psSyntaxSpanJoin keyword.token.span lastSpan
  let value := PsSyntaxTerm.matchMany inputs.value rows.value span
  return { value, cursor := rows.cursor }

def psLeanTermProof (read readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText cursor "by"
  let some first := psTokenCursorPeek keyword.cursor | throw (.unexpectedEnd "native tactic sequence")
  let braced := first.text == "{"
  let start ← if braced then pure (← psTokenCursorExpectText keyword.cursor "{").cursor
    else pure keyword.cursor
  let boundary := if braced then none else
    some { first.span.start with line := 0, column := first.span.start.column - 1 }
  let tactics ← psPscv0ReadTacticsFor true read readType fuel boundary start
  if tactics.value.isEmpty then throw (.unexpectedEnd "native tactic sequence")
  let finalCursor ← if braced then pure (← psTokenCursorExpectText tactics.cursor "}").cursor
    else pure tactics.cursor
  let consumed := cursor.remaining.take (cursor.remaining.length - finalCursor.remaining.length)
  let stop := (consumed.getLast?).map (·.span.stop) |>.getD keyword.token.span.stop
  let span := PsSourceSpan.mk keyword.token.span.start stop
  let value := PsSyntaxTerm.byE tactics.value {} span
  return { value, cursor := finalCursor }

def psLeanTermLocal (read readType continuation : PsPscv0TermReader)
    (isHave : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let fact ← psPscv0ReadLocal read readType cursor
  let next ← if psTokenCursorAtText fact.cursor ";" then
    pure (← psTokenCursorExpectText fact.cursor ";").cursor
  else psParseProofScriptBodySeparator fact.value.span.stop fact.cursor
  let body ← continuation next
  let span := psSyntaxSpanJoin fact.value.span (psSyntaxTermSpan body.value)
  let value := if isHave then
    PsSyntaxTerm.haveE fact.value.name fact.value.type fact.value.value body.value span
  else .letE fact.value.name fact.value.type fact.value.value body.value span
  return { value, cursor := body.cursor }

def psLeanTermAtPrecedence (annotation : Bool) (minimum fuel : Nat) :
    PsPscv0TermReader := fun cursor => do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let read := psLeanTermAtPrecedence false 0 fuel
    let readType := psLeanTermAtPrecedence true 0 fuel
    let continuation := psLeanTermAtPrecedence annotation 0 fuel
    let primary ←
      if psTokenCursorAtText cursor "if" then psLeanTermConditional read cursor
      else if psTokenCursorAtText cursor "match" then psLeanTermMatch read fuel false cursor
      else if psTokenCursorAtText cursor "nomatch" then psLeanTermMatch read fuel true cursor
      else if psTokenCursorAtText cursor "by" then psLeanTermProof read readType fuel cursor
      else if psTokenCursorAtText cursor "let" then
        psLeanTermLocal read readType continuation false cursor
      else if psTokenCursorAtText cursor "have" then
        psLeanTermLocal read readType continuation true cursor
      else if psTokenCursorAtText cursor "show" then psPscv0ReadShow read readType cursor
      else if ["fun", "λ"].any (psTokenCursorAtText cursor) then
        psPscv0BoundTerm readType continuation false fuel cursor
      else if ["forall", "∀"].any (psTokenCursorAtText cursor) then
        psPscv0BoundTerm readType continuation true fuel cursor
      else if ["exists", "∃"].any (psTokenCursorAtText cursor) then
        psPscv0ReadExists readType continuation fuel cursor
      else if psTokenCursorAtText cursor "-" then do
        let sign ← psTokenCursorExpectText cursor "-"
        let value ← psLeanTermAtPrecedence annotation 75 fuel sign.cursor
        let span := psSyntaxSpanJoin sign.token.span (psSyntaxTermSpan value.value)
        let term := psPscv0OperatorTerm .unary "Neg.neg" "-" [value.value] span
        pure { value := term, cursor := value.cursor }
      else if psTokenCursorAtText cursor "¬" then do
        let sign ← psTokenCursorExpectText cursor "¬"
        let value ← psLeanTermAtPrecedence annotation 40 fuel sign.cursor
        let span := psSyntaxSpanJoin sign.token.span (psSyntaxTermSpan value.value)
        let term := psPscv0NotationCall "Not" [value.value] span
        pure { value := term, cursor := value.cursor }
      else if psTokenCursorAtText cursor "(" then
        match psPscv0DependentBinder readType fuel cursor with
        | .ok binder =>
          if psTokenCursorAtArrow binder.cursor then
            psParseProofScriptDependentArrowTail
              (psLeanTermAtPrecedence annotation 25 fuel) binder
          else psLeanTermApplication read annotation fuel cursor
        | .error _ => psLeanTermApplication read annotation fuel cursor
      else psLeanTermApplication read annotation fuel cursor
    psPscv0OperatorTail (fun precedence =>
      psLeanTermAtPrecedence annotation precedence fuel) minimum fuel primary

def psLeanReadTerm (annotation : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psLeanTermAtPrecedence annotation 0 (cursor.remaining.length + 1) cursor
