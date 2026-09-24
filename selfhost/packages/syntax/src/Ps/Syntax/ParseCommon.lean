import Ps.Syntax.Ast
import Ps.Syntax.ParserState

def psSyntaxSpanJoin (start : PsSourceSpan) (stop : PsSourceSpan) : PsSourceSpan :=
  { start := start.start, stop := stop.stop }

def psSyntaxTermSpan : PsSyntaxTerm -> PsSourceSpan
  | .reference name => name.span
  | .natural _ span => span
  | .string _ span => span
  | .character _ span => span
  | .bool _ span => span
  | .unit span => span
  | .app _ _ span => span
  | .lambda _ _ span => span
  | .forallE _ _ span => span
  | .letE _ _ _ _ span => span
  | .ifE _ _ _ span => span

def psParseSyntaxNameTail
    (segmentsRev : List String)
    (start : PsSourcePos)
    (stop : PsSourcePos) :
    List PsToken -> Except PsParseError (PsParseResult PsSyntaxName)
  | [] =>
      Except.ok {
        value := {
          segments := segmentsRev.reverse
          span := { start := start, stop := stop }
        }
        cursor := { remaining := [] }
      }
  | dot :: rest =>
      if dot.text == "." then
        match rest with
        | [] => Except.error (PsParseError.unexpectedEnd "identifier")
        | next :: after =>
            if psTokenKindEq next.kind PsTokenKind.identifier then
              psParseSyntaxNameTail
                (next.text :: segmentsRev)
                start
                next.span.stop
                after
            else
              Except.error
                (PsParseError.expectedKind
                  PsTokenKind.identifier
                  next.kind
                  next.span)
      else
        Except.ok {
          value := {
            segments := segmentsRev.reverse
            span := { start := start, stop := stop }
          }
          cursor := { remaining := dot :: rest }
        }

def psParseSyntaxName
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxName) :=
  match cursor.remaining with
  | [] => Except.error (PsParseError.unexpectedEnd "identifier")
  | token :: rest =>
      if psTokenKindEq token.kind PsTokenKind.identifier then
        psParseSyntaxNameTail
          [token.text]
          token.span.start
          token.span.stop
          rest
      else
        Except.error
          (PsParseError.expectedKind
            PsTokenKind.identifier
            token.kind
            token.span)

def psParseSimpleTerm
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "term")
  | some token =>
      if psTokenKindEq token.kind PsTokenKind.identifier then
        if token.text == "true" then
          match psTokenCursorAdvance cursor with
          | none => Except.error (PsParseError.unexpectedEnd "term")
          | some read =>
              Except.ok {
                value := PsSyntaxTerm.bool true token.span
                cursor := read.cursor
              }
        else if token.text == "false" then
          match psTokenCursorAdvance cursor with
          | none => Except.error (PsParseError.unexpectedEnd "term")
          | some read =>
              Except.ok {
                value := PsSyntaxTerm.bool false token.span
                cursor := read.cursor
              }
        else
          match psParseSyntaxName cursor with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              Except.ok {
                value := PsSyntaxTerm.reference parsed.value
                cursor := parsed.cursor
              }
      else if psTokenKindEq token.kind PsTokenKind.natural then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "term")
        | some read =>
            Except.ok {
              value := PsSyntaxTerm.natural token.text token.span
              cursor := read.cursor
            }
      else if psTokenKindEq token.kind PsTokenKind.string then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "term")
        | some read =>
            Except.ok {
              value := PsSyntaxTerm.string token.text token.span
              cursor := read.cursor
            }
      else if psTokenKindEq token.kind PsTokenKind.character then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "term")
        | some read =>
            Except.ok {
              value := PsSyntaxTerm.character token.text token.span
              cursor := read.cursor
            }
      else
        Except.error
          (PsParseError.expectedText "term" token.text token.span)

structure PsSyntaxBinderOpening where
  kind : PsSyntaxBinderKind
  start : PsSourcePos
  closeText : String
  closeCount : Nat
  cursor : PsTokenCursor

def psParseBinderOpening
    (cursor : PsTokenCursor) :
    Except PsParseError PsSyntaxBinderOpening :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "binder")
  | some token =>
      if token.text == "(" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "binder")
        | some opening =>
            Except.ok {
              kind := PsSyntaxBinderKind.explicit
              start := opening.token.span.start
              closeText := ")"
              closeCount := 1
              cursor := opening.cursor
            }
      else if token.text == "{" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "binder")
        | some first =>
            if psTokenCursorAtText first.cursor "{" then
              match psTokenCursorAdvance first.cursor with
              | none => Except.error (PsParseError.unexpectedEnd "binder")
              | some second =>
                  Except.ok {
                    kind := PsSyntaxBinderKind.strictImplicit
                    start := first.token.span.start
                    closeText := "}"
                    closeCount := 2
                    cursor := second.cursor
                  }
            else
              Except.ok {
                kind := PsSyntaxBinderKind.implicit
                start := first.token.span.start
                closeText := "}"
                closeCount := 1
                cursor := first.cursor
              }
      else if token.text == "[" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "binder")
        | some opening =>
            Except.ok {
              kind := PsSyntaxBinderKind.instanceImplicit
              start := opening.token.span.start
              closeText := "]"
              closeCount := 1
              cursor := opening.cursor
            }
      else
        Except.error
          (PsParseError.expectedText "binder" token.text token.span)

def psParseBinderClosing
    (opening : PsSyntaxBinderOpening)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSourceSpan) :=
  match psTokenCursorExpectText cursor opening.closeText with
  | Except.error error => Except.error error
  | Except.ok firstClose =>
      if opening.closeCount == 2 then
        match psTokenCursorExpectText firstClose.cursor opening.closeText with
        | Except.error error => Except.error error
        | Except.ok secondClose =>
            Except.ok {
              value := {
                start := opening.start
                stop := secondClose.token.span.stop
              }
              cursor := secondClose.cursor
            }
      else
        Except.ok {
          value := {
            start := opening.start
            stop := firstClose.token.span.stop
          }
          cursor := firstClose.cursor
        }

def psTokenCursorAtBinderStart (cursor : PsTokenCursor) : Bool :=
  psTokenCursorAtText cursor "("
    || psTokenCursorAtText cursor "{"
    || psTokenCursorAtText cursor "["

def psTokenCursorAtArrow (cursor : PsTokenCursor) : Bool :=
  psTokenCursorAtText cursor "->" || psTokenCursorAtText cursor "→"

def psTokenCursorExpectArrow
    (cursor : PsTokenCursor) :
    Except PsParseError PsTokenRead :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "->")
  | some token =>
      if token.text == "->" || token.text == "→" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "->")
        | some read => Except.ok read
      else
        Except.error
          (PsParseError.expectedText "->" token.text token.span)

def psSyntaxAnonymousExplicitBinder
    (span : PsSourceSpan) : PsSyntaxBinderHead :=
  {
    name := {
      segments := ["_"]
      span := span
    }
    kind := PsSyntaxBinderKind.explicit
    span := span
  }
