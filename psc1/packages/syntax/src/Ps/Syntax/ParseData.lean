import Ps.Syntax.ParseCommon

/-- Surface data notation reuses the already checked Type0 Prod and Array
operations. No additional logical constant, effect or runtime representation is
introduced here. Dotted builtin names cannot be introduced as local binders. -/
abbrev PsDataTermParser :=
  PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm)

structure PsDataDelimited where
  elements : List PsSyntaxTerm
  separated : Bool
  span : PsSourceSpan
  cursor : PsTokenCursor

def psParseDataElementsWithFuel
    (parseTerm : PsDataTermParser) (closeText : String) (fuel : Nat) :
    PsSourcePos -> PsTokenCursor -> List PsSyntaxTerm -> Bool ->
    Except PsParseError PsDataDelimited :=
  match fuel with
  | 0 => fun _ _ _ _ => .error .fuelExhausted
  | remaining + 1 => fun start cursor elementsRev separated => do
      if psTokenCursorAtText cursor closeText then
        let close ← psTokenCursorExpectText cursor closeText
        return {
          elements := psParseListReverse elementsRev
          separated := separated
          span := { start := start, stop := close.token.span.stop }
          cursor := close.cursor
        }
      else
        let element ← parseTerm cursor
        if psTokenCursorAtText element.cursor "," then
          let comma ← psTokenCursorExpectText element.cursor ","
          psParseDataElementsWithFuel parseTerm closeText remaining start
            comma.cursor (element.value :: elementsRev) true
        else
          let close ← psTokenCursorExpectText element.cursor closeText
          return {
            elements := psParseListReverse (element.value :: elementsRev)
            separated := separated
            span := { start := start, stop := close.token.span.stop }
            cursor := close.cursor
          }

def psSyntaxDataReference (root member : String)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  .reference { segments := [root, member], span := span }

def psSyntaxTupleValue (elements : List PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  match elements with
  | [] => .unit span
  | [value] => value
  | first :: rest =>
      .app (psSyntaxDataReference "Prod" "mk" span)
        [first, psSyntaxTupleValue rest span] span

/-- Grouping remains distinct from tuples. A comma requires at least two fields;
larger tuples associate to the right, following the pinned Lean parser. -/
def psParseDataParen (parseTerm : PsDataTermParser)
    (groupSpan : PsSyntaxTerm -> PsSourceSpan -> PsSyntaxTerm)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let opening ← psTokenCursorExpectText cursor "("
  let parsed ← psParseDataElementsWithFuel parseTerm ")"
    (Nat.succ (psParseListLength opening.cursor.remaining))
    opening.token.span.start opening.cursor [] false
  match parsed.elements with
  | [_] =>
      if parsed.separated then
        throw (.expectedText "at least two tuple elements" ")" parsed.span)
      else
        return { value := groupSpan (psSyntaxTupleValue parsed.elements parsed.span) parsed.span
                 cursor := parsed.cursor }
  | _ =>
      return { value := psSyntaxTupleValue parsed.elements parsed.span
               cursor := parsed.cursor }

/-- The nested push expression evaluates earlier elements before later ones.
Capacity is an allocation hint only; it is not a semantic iteration limit. -/
def psSyntaxArrayPushes (elements : List PsSyntaxTerm)
    (current : PsSyntaxTerm) (span : PsSourceSpan) : PsSyntaxTerm :=
  match elements with
  | [] => current
  | value :: rest =>
      psSyntaxArrayPushes rest
        (.app (psSyntaxDataReference "Array" "push" span) [current, value] span) span

def psParseDataArray (parseTerm : PsDataTermParser)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let hashToken ← psTokenCursorExpectText cursor "#"
  let opening ← psTokenCursorExpectText hashToken.cursor "["
  if !(Nat.beq hashToken.token.span.stop.byteOffset opening.token.span.start.byteOffset) then
    throw (.expectedText "adjacent #[" "[" opening.token.span)
  let parsed ← psParseDataElementsWithFuel parseTerm "]"
    (Nat.succ (psParseListLength opening.cursor.remaining))
    hashToken.token.span.start opening.cursor [] false
  let initial : PsSyntaxTerm := .app (psSyntaxDataReference "Array" "emptyWithCapacity" parsed.span)
    [.natural "0" parsed.span] parsed.span
  return { value := psSyntaxArrayPushes parsed.elements initial parsed.span
           cursor := parsed.cursor }

def psDataAtAdjacentIndex (surfaceSpan : PsSourceSpan)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
      if psStringEq token.text "[" then
        Nat.beq surfaceSpan.stop.byteOffset token.span.start.byteOffset
      else false

/-- Only the selected optional form is accepted. Plain, proof-bearing and panic
indexing cannot silently use a default or a host exception. -/
def psParseDataOptionalIndexTailWithFuel
    (parseTerm : PsDataTermParser) (fuel : Nat) :
    PsSyntaxTerm -> PsSourceSpan -> PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 => fun _ _ _ => .error .fuelExhausted
  | remaining + 1 => fun current surfaceSpan cursor => do
      if psDataAtAdjacentIndex surfaceSpan cursor then
        let opening ← psTokenCursorExpectText cursor "["
        let index ← parseTerm opening.cursor
        let close ← psTokenCursorExpectText index.cursor "]"
        let optional ← psTokenCursorExpectText close.cursor "?"
        if !(Nat.beq close.token.span.stop.byteOffset optional.token.span.start.byteOffset) then
          throw (.expectedText "adjacent ]? for optional indexing" "?" optional.token.span)
        let span : PsSourceSpan := {
          start := surfaceSpan.start
          stop := optional.token.span.stop
        }
        let next := PsSyntaxTerm.arrayGetOptionE current index.value span
        psParseDataOptionalIndexTailWithFuel parseTerm remaining next span optional.cursor
      else
        return { value := current, cursor := cursor }
