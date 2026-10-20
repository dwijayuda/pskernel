import Ps.Syntax.ParseCommon

/-- Surface data uses the checked Type0 Prod and Array operations. -/
def PsDataTermParser : Type :=
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
  | 0 => fun _ _ _ _ => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      fun (start : PsSourcePos) (cursor : PsTokenCursor)
          (elementsRev : List PsSyntaxTerm) (separated : Bool) =>
        let smaller : PsSourcePos -> PsTokenCursor -> List PsSyntaxTerm -> Bool ->
            Except PsParseError PsDataDelimited :=
          psParseDataElementsWithFuel parseTerm closeText remaining;
        if psTokenCursorAtText cursor closeText then
          match psTokenCursorExpectText cursor closeText with
          | Except.error error => Except.error error
          | Except.ok close =>
              Except.ok {
                elements := psParseListReverse elementsRev
                separated := separated
                span := { start := start, stop := close.token.span.stop }
                cursor := close.cursor
              }
        else
          match parseTerm cursor with
          | Except.error error => Except.error error
          | Except.ok element =>
              if psTokenCursorAtText element.cursor "," then
                match psTokenCursorExpectText element.cursor "," with
                | Except.error error => Except.error error
                | Except.ok comma =>
                    smaller start comma.cursor (element.value :: elementsRev) true
              else
                match psTokenCursorExpectText element.cursor closeText with
                | Except.error error => Except.error error
                | Except.ok close =>
                    Except.ok {
                      elements := psParseListReverse (element.value :: elementsRev)
                      separated := separated
                      span := { start := start, stop := close.token.span.stop }
                      cursor := close.cursor
                    }

def psSyntaxDataReference (root member : String)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  psSyntaxRootReference [root, member] span

def psSyntaxTupleValue (elements : List PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  match elements with
  | [] => PsSyntaxTerm.unit span
  | first :: rest =>
      match rest with
      | [] => first
      | _ :: _ =>
          PsSyntaxTerm.app (psSyntaxDataReference "Prod" "mk" span)
            [first, psSyntaxTupleValue rest span] span

/-- A comma requires at least two fields; larger tuples associate right. -/
def psParseDataParen (parseTerm : PsDataTermParser)
    (groupSpan : PsSyntaxTerm -> PsSourceSpan -> PsSyntaxTerm)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psTokenCursorExpectText cursor "(" with
  | Except.error error => Except.error error
  | Except.ok opening =>
      match psParseDataElementsWithFuel parseTerm ")"
          (Nat.succ (psParseListLength opening.cursor.remaining))
          opening.token.span.start opening.cursor [] false with
      | Except.error error => Except.error error
      | Except.ok parsed =>
          match parsed.elements with
          | [] =>
              Except.ok { value := psSyntaxTupleValue parsed.elements parsed.span
                          cursor := parsed.cursor }
          | _ :: rest =>
              match rest with
              | [] =>
                  if parsed.separated then
                    Except.error (PsParseError.expectedText
                      "at least two tuple elements" ")" parsed.span)
                  else
                    Except.ok {
                      value := groupSpan (psSyntaxTupleValue parsed.elements parsed.span) parsed.span
                      cursor := parsed.cursor
                    }
              | _ :: _ =>
                  Except.ok { value := psSyntaxTupleValue parsed.elements parsed.span
                              cursor := parsed.cursor }

/-- Earlier elements evaluate before later ones in the nested push expression.
Capacity is only an allocation hint. -/
def psSyntaxArrayPushes (elements : List PsSyntaxTerm) :
    PsSyntaxTerm -> PsSourceSpan -> PsSyntaxTerm :=
  match elements with
  | [] => fun (current : PsSyntaxTerm) (_ : PsSourceSpan) => current
  | value :: rest =>
      fun (current : PsSyntaxTerm) (span : PsSourceSpan) =>
        let smaller : PsSyntaxTerm -> PsSourceSpan -> PsSyntaxTerm :=
          psSyntaxArrayPushes rest;
        smaller (PsSyntaxTerm.app (psSyntaxDataReference "Array" "push" span)
          [current, value] span) span

def psParseDataArray (parseTerm : PsDataTermParser)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psTokenCursorExpectText cursor "#" with
  | Except.error error => Except.error error
  | Except.ok hashToken =>
      match psTokenCursorExpectText hashToken.cursor "[" with
      | Except.error error => Except.error error
      | Except.ok opening =>
          if !(Nat.beq hashToken.token.span.stop.byteOffset opening.token.span.start.byteOffset) then
            Except.error (PsParseError.expectedText "adjacent #[" "[" opening.token.span)
          else
            match psParseDataElementsWithFuel parseTerm "]"
                (Nat.succ (psParseListLength opening.cursor.remaining))
                hashToken.token.span.start opening.cursor [] false with
            | Except.error error => Except.error error
            | Except.ok parsed =>
                let initial : PsSyntaxTerm :=
                  PsSyntaxTerm.app (psSyntaxDataReference "Array" "emptyWithCapacity" parsed.span)
                    [PsSyntaxTerm.natural "0" parsed.span] parsed.span;
                Except.ok {
                  value := psSyntaxArrayPushes parsed.elements initial parsed.span
                  cursor := parsed.cursor
                }

def psDataAtAdjacentIndex (surfaceSpan : PsSourceSpan)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
      if psStringEq token.text "[" then
        Nat.beq surfaceSpan.stop.byteOffset token.span.start.byteOffset
      else false

/-- Only optional indexing is accepted, with adjacent brackets and suffix. -/
def psParseDataOptionalIndexTailWithFuel
    (parseTerm : PsDataTermParser) (fuel : Nat) :
    PsSyntaxTerm -> PsSourceSpan -> PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 => fun _ _ _ => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      fun (current : PsSyntaxTerm) (surfaceSpan : PsSourceSpan) (cursor : PsTokenCursor) =>
        let smaller : PsSyntaxTerm -> PsSourceSpan -> PsTokenCursor ->
            Except PsParseError (PsParseResult PsSyntaxTerm) :=
          psParseDataOptionalIndexTailWithFuel parseTerm remaining;
        if psDataAtAdjacentIndex surfaceSpan cursor then
          match psTokenCursorExpectText cursor "[" with
          | Except.error error => Except.error error
          | Except.ok opening =>
              match parseTerm opening.cursor with
              | Except.error error => Except.error error
              | Except.ok index =>
                  match psTokenCursorExpectText index.cursor "]" with
                  | Except.error error => Except.error error
                  | Except.ok close =>
                      match psTokenCursorExpectText close.cursor "?" with
                      | Except.error error => Except.error error
                      | Except.ok optional =>
                          if !(Nat.beq close.token.span.stop.byteOffset optional.token.span.start.byteOffset) then
                            Except.error (PsParseError.expectedText
                              "adjacent ]? for optional indexing" "?" optional.token.span)
                          else
                            let span : PsSourceSpan := {
                              start := surfaceSpan.start
                              stop := optional.token.span.stop
                            };
                            let next : PsSyntaxTerm :=
                              PsSyntaxTerm.arrayGetOptionE current index.value span;
                            smaller next span optional.cursor
        else
          Except.ok { value := current, cursor := cursor }
