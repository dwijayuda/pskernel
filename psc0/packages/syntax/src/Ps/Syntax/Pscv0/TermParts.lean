import Ps.Syntax.Pscv0.Interpolation
import Ps.Syntax.Pscv0.Universe

-- Records keep their source and replacement fields distinct until elaboration.
def psPscv0RecordUpdateAfterSource (read : PsPscv0TermReader)
    (opening : PsSourceSpan) (source : PsParseResult PsSyntaxTerm) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let keyword ← psTokenCursorExpectText source.cursor "with"
  let fields ← psParseProofScriptRecordFieldsWithFuel read
    (keyword.cursor.remaining.length + 1) keyword.cursor []
  let close ← psTokenCursorExpectText fields.cursor "}"
  return {
    value := .recordUpdate source.value fields.value (psSyntaxSpanJoin opening close.token.span)
    cursor := close.cursor }

def psPscv0ReadRecord (read : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let opening ← psTokenCursorExpectText cursor "{"
  if psTokenCursorAtText opening.cursor "}" || psTokenCursorStartsNamedAssignment opening.cursor then
    return ← psParseProofScriptRecordLiteral read cursor
  let source ← read opening.cursor
  psPscv0RecordUpdateAfterSource read opening.token.span source

-- These readers preserve source intent. Semantic argument insertion belongs to
-- the application elaborator, never to parsing or token rewriting.
def psPscv0ReadAscription (read : PsPscv0TermReader)
    (value : PsParseResult PsSyntaxTerm) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  if !psTokenCursorAtText value.cursor ":" then return value
  let colon ← psTokenCursorExpectText value.cursor ":"
  let type ← read colon.cursor
  return {
    value := .ascription value.value type.value
      (psSyntaxSpanJoin (psSyntaxTermSpan value.value) (psSyntaxTermSpan type.value))
    cursor := type.cursor }

-- Tuple values share the same right-nested Prod meaning as tuple patterns.
-- One comma introduces a tuple; a trailing comma is allowed only after
-- at least two terms. The type/application elaborator supplies implicit
-- Prod.mk type arguments instead of inventing a second tuple type system.
def psPscv0TupleConstruct (span : PsSourceSpan) :
    List PsSyntaxTerm → Except PsParseError PsSyntaxTerm
  | first :: second :: rest => do
    let right ← if rest.isEmpty then pure second
      else psPscv0TupleConstruct span (second :: rest)
    return .call (.reference (PsSyntaxName.mk ["_root_", "Prod", "mk"] span))
      [(none, first), (none, right)] span
  | _ => throw (.unexpectedEnd "tuple requires at least two elements")

-- One delimiter-owned sequence reader serves tuple, List and Array
-- values. A comma is required between elements and optionally trails the
-- final element. A terminator is always consumed by the enclosing construct.
def psPscv0DelimitedElements (read : PsPscv0TermReader) (closing : String)
    (fuel : Nat) (cursor : PsTokenCursor) (acc : List PsSyntaxTerm) :
    Except PsParseError (PsParseResult (List PsSyntaxTerm)) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor closing then
      return { value := acc.reverse, cursor }
    let next ← read cursor
    let acc := next.value :: acc
    if psTokenCursorAtText next.cursor "," then
      let comma ← psTokenCursorExpectText next.cursor ","
      psPscv0DelimitedElements read closing fuel comma.cursor acc
    else
      return { value := acc.reverse, cursor := next.cursor }

def psPscv0ReadArrayLiteral (read : PsPscv0TermReader)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let marker ← psTokenCursorExpectText cursor "#"
  let some bracket := psTokenCursorPeek marker.cursor
    | throw (.unexpectedEnd "array literal opening")
  if bracket.text != "[" || marker.token.span.stop.byteOffset != bracket.span.start.byteOffset then
    throw (psProofScriptExpectedError "adjacent #[ array literal" marker.cursor)
  let opening ← psTokenCursorExpectText marker.cursor "["
  let values ← psPscv0DelimitedElements read "]" (cursor.remaining.length + 1) opening.cursor []
  let close ← psTokenCursorExpectText values.cursor "]"
  let span := psSyntaxSpanJoin marker.token.span close.token.span
  let name := fun (text : String) =>
    PsSyntaxTerm.reference (PsSyntaxName.mk ["_root_", "Array", text] span)
  let empty := PsSyntaxTerm.call (name "emptyWithCapacity")
    [(none, .natural "0" span)] span
  let result := values.value.foldl (fun current element =>
    PsSyntaxTerm.call (name "push") [(none, current), (none, element)] span) empty
  return { value := result, cursor := close.cursor }

-- Ordinary lists retain the existing inductive semantics. The empty
-- constructor remains a reference (not a nullary call), allowing its implicit
-- element type to be determined from the expected List type.
def psPscv0ReadListLiteral (read : PsPscv0TermReader)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let opening ← psTokenCursorExpectText cursor "["
  let values ← psPscv0DelimitedElements read "]" (cursor.remaining.length + 1) opening.cursor []
  let close ← psTokenCursorExpectText values.cursor "]"
  let span := psSyntaxSpanJoin opening.token.span close.token.span
  let name := fun (field : String) =>
    PsSyntaxTerm.reference (PsSyntaxName.mk ["_root_", "List", field] span)
  let result := values.value.foldr (fun element tail =>
    PsSyntaxTerm.call (name "cons") [(none, element), (none, tail)] span) (name "nil")
  return { value := result, cursor := close.cursor }

def psPscv0Primary (read : PsPscv0TermReader) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  if let some token := psTokenCursorPeek cursor then
    if psTokenKindEq token.kind .scientific then
      let literal ← psTokenCursorExpectKind cursor .scientific
      return { value := .scientific literal.token.text literal.token.span, cursor := literal.cursor }
    if psTokenKindEq token.kind .string && token.text.startsWith "s!\"" then
      return ← psPscv0Interpolate read cursor
  if psTokenCursorAtText cursor "#" then return ← psPscv0ReadArrayLiteral read cursor
  if psTokenCursorAtText cursor "[" then return ← psPscv0ReadListLiteral read cursor
  if psTokenCursorAtText cursor "{" then return ← psPscv0ReadRecord read cursor
  if ["Type", "Sort", "Prop"].any (psTokenCursorAtText cursor) then
    return ← psPscv0ReadSort cursor
  if psTokenCursorAtText cursor "_" then
    let token ← psTokenCursorExpectText cursor "_"
    return { value := .hole token.token.span, cursor := token.cursor }
  if !psTokenCursorAtText cursor "(" then
    return ← psParseProofScriptPrimary read cursor
  let opening ← psTokenCursorExpectText cursor "("
  if psTokenCursorAtText opening.cursor ")" then
    return ← psParseProofScriptPrimary read cursor
  let inner ← read opening.cursor
  let annotated ← psPscv0ReadAscription read inner
  if psTokenCursorAtText annotated.cursor "," then
    let comma ← psTokenCursorExpectText annotated.cursor ","
    let elements ← psPscv0DelimitedElements read ")" (cursor.remaining.length + 1)
      comma.cursor [annotated.value]
    let close ← psTokenCursorExpectText elements.cursor ")"
    let span := psSyntaxSpanJoin opening.token.span close.token.span
    return { value := ← psPscv0TupleConstruct span elements.value, cursor := close.cursor }
  let close ← psTokenCursorExpectText annotated.cursor ")"
  return {
    value := psProofScriptTermWithSpan annotated.value
      (psSyntaxSpanJoin opening.token.span close.token.span)
    cursor := close.cursor }

def psPscv0CallArguments (read : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) (named : Bool)
    (acc : List (Prod (Option PsSyntaxName) PsSyntaxTerm)) :
    Except PsParseError
      (PsParseResult (List (Prod (Option PsSyntaxName) PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor ")" then
      return { value := acc.reverse, cursor }
    let (label, start) ←
      if psTokenCursorStartsNamedAssignment cursor then do
        let name ← psTokenCursorExpectKind cursor .identifier
        let assign ← psTokenCursorExpectText name.cursor ":="
        pure (some ((psSyntaxNameFromToken name.token)), assign.cursor)
      else if named then
        throw (psProofScriptExpectedError "named argument after named argument" cursor)
      else pure (none, cursor)
    let value ← read start
    let next := (label, value.value) :: acc
    if psTokenCursorAtText value.cursor "," then
      let comma ← psTokenCursorExpectText value.cursor ","
      psPscv0CallArguments read fuel comma.cursor (named || label.isSome) next
    else
      let _ ← psTokenCursorExpectText value.cursor ")"
      return { value := next.reverse, cursor := value.cursor }

-- All four Lean GetElem spellings share one postfix owner and ordinary
-- typed application. Proofs are never discarded or translated to Bool.
-- The implicit validity proof remains a typed goal. A bounded Lean-style
-- index tactic attempts only checked local evidence/reflexivity/trivial
-- constructors; arithmetic and extensible simplification remain explicit
-- conformance obligations, never assumed away.
def psPscv0IndexMethod (name : String) (args : List PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  .call (.reference (PsSyntaxName.mk ("_root_" :: name.splitOn ".") span))
    (args.map fun arg => (none, arg)) span

def psPscv0PostfixFor (commaCalls : Bool) (read : PsPscv0TermReader) (fuel : Nat)
    (current : PsSyntaxTerm) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    if psTokenCursorAtText cursor "[" && psProofScriptCallAdjacent current cursor then
      let opening ← psTokenCursorExpectText cursor "["
      let index ← read opening.cursor
      let close ← psTokenCursorExpectText index.cursor "]"
      let suffix := psTokenCursorPeek close.cursor
      let adjacent := suffix.any fun token =>
        token.span.start.byteOffset == close.token.span.stop.byteOffset
      let (method, args, finalCursor, lastSpan) ←
        if adjacent && psTokenCursorAtText close.cursor "?" then do
          let question ← psTokenCursorExpectText close.cursor "?"
          pure ("GetElem?.getElem?", [current, index.value], question.cursor,
            question.token.span)
        else if adjacent && psTokenCursorAtText close.cursor "!" then do
          let bang ← psTokenCursorExpectText close.cursor "!"
          pure ("GetElem?.getElem!", [current, index.value], bang.cursor,
            bang.token.span)
        else if adjacent && psTokenCursorAtText close.cursor "'" then do
          let quote ← psTokenCursorExpectText close.cursor "'"
          let primary ← psPscv0Primary read quote.cursor
          let proof ← psPscv0PostfixFor commaCalls read fuel primary.value primary.cursor
          pure ("GetElem.getElem", [current, index.value, proof.value],
            proof.cursor, psSyntaxTermSpan proof.value)
        else
          let assumption : PsSyntaxTerm :=
            .byE [.indexValidity close.token.span] {} close.token.span
          pure ("GetElem.getElem", [current, index.value, assumption],
            close.cursor, close.token.span)
      let span := psSyntaxSpanJoin (psSyntaxTermSpan current) lastSpan
      return ← psPscv0PostfixFor commaCalls read fuel
        (psPscv0IndexMethod method args span) finalCursor
    -- Lean 4.35.0 Parser.Term.proj accepts a no-whitespace trailing
    -- projection on ANY term, not only on a bare identifier. PSCV0 keeps
    -- exactly one typed projection elaborator (psElabProjectionChain).
    -- Bind the receiver once under a source-inaccessible hygienic name and
    -- reuse that elaborator, preserving evaluation count, dependent field
    -- types and the existing projection diagnostics. No new parser-only
    -- field lookup, untyped IR node or backend-specific implementation.
    if psTokenCursorAtText cursor "." &&
        psProofScriptCallAdjacent current cursor then
      let dot ← psTokenCursorExpectText cursor "."
      let field ← psTokenCursorExpectKind dot.cursor .identifier
      if field.token.span.start.byteOffset != dot.token.span.stop.byteOffset then
        throw (psProofScriptExpectedError "adjacent field name" dot.cursor)
      let span := psSyntaxSpanJoin (psSyntaxTermSpan current) field.token.span
      let binderText := "$psc0PostfixProjection" ++
        toString dot.token.span.start.byteOffset
      let binder := PsSyntaxName.mk [binderText] dot.token.span
      let projected := PsSyntaxTerm.reference
        { segments := [binderText, psTokenIdentifierText field.token]
          span, escaped := psTokenIdentifierEscaped field.token }
      let result := PsSyntaxTerm.letE binder none current projected span
      return ← psPscv0PostfixFor commaCalls read fuel result field.cursor
    if !commaCalls || !(psTokenCursorAtText cursor "(" && psProofScriptCallAdjacent current cursor) then
      return { value := current, cursor }
    let opening ← psTokenCursorExpectText cursor "("
    let args ← psPscv0CallArguments read (fuel + 1) opening.cursor false []
    let close ← psTokenCursorExpectText args.cursor ")"
    psPscv0PostfixFor commaCalls read fuel
      (.call current args.value (psSyntaxSpanJoin (psSyntaxTermSpan current) close.token.span))
      close.cursor


-- Existing ProofScript readers select comma-call syntax. Native readers share
-- indexing/projection ownership but select native application separately.
def psPscv0Postfix := psPscv0PostfixFor true
