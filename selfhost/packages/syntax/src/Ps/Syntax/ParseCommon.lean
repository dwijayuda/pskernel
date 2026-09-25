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
  | .record _ span => span
  | .app _ _ span => span
  | .lambda _ _ span => span
  | .forallE _ _ span => span
  | .letE _ _ _ _ span => span
  | .ifE _ _ _ span => span
  | .matchE _ _ span => span

def psSyntaxSyntheticName
    (text : String)
    (span : PsSourceSpan) : PsSyntaxName :=
  {
    segments := List.cons text List.nil
    span := span
  }

def psSyntaxSyntheticReference
    (text : String)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  PsSyntaxTerm.reference (psSyntaxSyntheticName text span)

def psSyntaxCompilerPure
    (value : PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  PsSyntaxTerm.app
    (psSyntaxSyntheticReference "compilerPure" span)
    (List.cons value List.nil)
    span

def psSyntaxCompilerBind
    (binder : PsSyntaxBinderHead)
    (binderType : PsSyntaxTerm)
    (action : PsSyntaxTerm)
    (body : PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  let bodySpan := psSyntaxTermSpan body
  let lambda :=
    PsSyntaxTerm.lambda
      (List.cons (Prod.mk binder binderType) List.nil)
      body
      {
        start := binder.span.start
        stop := bodySpan.stop
      }
  PsSyntaxTerm.app
    (psSyntaxSyntheticReference "compilerBind" span)
    (List.cons action (List.cons lambda List.nil))
    span

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
        cursor := { remaining := List.nil }
      }
  | dot :: rest =>
      if psStringEq dot.text "." then
        match rest with
        | [] => Except.error (PsParseError.unexpectedEnd "identifier")
        | next :: after =>
            if psTokenKindEq next.kind PsTokenKind.identifier then
              psParseSyntaxNameTail
                (List.cons next.text segmentsRev)
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
          cursor := { remaining := List.cons dot rest }
        }

def psParseSyntaxName
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxName) :=
  match cursor.remaining with
  | [] => Except.error (PsParseError.unexpectedEnd "identifier")
  | token :: rest =>
      if psTokenKindEq token.kind PsTokenKind.identifier then
        psParseSyntaxNameTail
          (List.cons token.text List.nil)
          token.span.start
          token.span.stop
          rest
      else
        Except.error
          (PsParseError.expectedKind
            PsTokenKind.identifier
            token.kind
            token.span)

def psTokenCursorStartsNamedAssignment
    (cursor : PsTokenCursor) : Bool :=
  match cursor.remaining with
  | List.nil => false
  | List.cons name rest =>
      match rest with
      | List.nil => false
      | List.cons assign _ =>
          if
              psTokenKindEq
                name.kind
                PsTokenKind.identifier then
            psStringEq assign.text ":="
          else
            false

def psParseRecordFieldsWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (fieldsRev :
      List (Prod PsSyntaxName PsSyntaxTerm)) :
    Except PsParseError
      (PsParseResult
        (List (Prod PsSyntaxName PsSyntaxTerm))) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      if psTokenCursorAtText cursor "}" then
        Except.ok {
          value := fieldsRev.reverse
          cursor := cursor
        }
      else
        match psParseSyntaxName cursor with
        | Except.error error => Except.error error
        | Except.ok name =>
            match psTokenCursorExpectText name.cursor ":=" with
            | Except.error error => Except.error error
            | Except.ok afterAssign =>
                match parseTerm afterAssign.cursor with
                | Except.error error => Except.error error
                | Except.ok value =>
                    let nextField :=
                      Prod.mk name.value value.value
                    if psTokenCursorAtText value.cursor "," then
                      match psTokenCursorAdvance value.cursor with
                      | none =>
                          Except.error
                            (PsParseError.unexpectedEnd
                              "record field")
                      | some afterComma =>
                          psParseRecordFieldsWithFuel
                            parseTerm
                            remaining
                            afterComma.cursor
                            (List.cons nextField fieldsRev)
                    else if
                        if psTokenCursorAtText value.cursor "}" then
                          true
                        else
                          psTokenCursorStartsNamedAssignment
                            value.cursor then
                      psParseRecordFieldsWithFuel
                        parseTerm
                        remaining
                        value.cursor
                        (List.cons nextField fieldsRev)
                    else
                      match psTokenCursorPeek value.cursor with
                      | none =>
                          Except.error
                            (PsParseError.unexpectedEnd
                              ", or }")
                      | some token =>
                          Except.error
                            (PsParseError.expectedText
                              ", or }"
                              token.text
                              token.span)

def psParseRecordLiteral
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psTokenCursorExpectText cursor "{" with
  | Except.error error => Except.error error
  | Except.ok opening =>
      match
          psParseRecordFieldsWithFuel
            parseTerm
            opening.cursor.remaining.length
            opening.cursor
            List.nil with
      | Except.error error => Except.error error
      | Except.ok fields =>
          match psTokenCursorExpectText fields.cursor "}" with
          | Except.error error => Except.error error
          | Except.ok close =>
              Except.ok {
                value :=
                  PsSyntaxTerm.record
                    fields.value
                    {
                      start := opening.token.span.start
                      stop := close.token.span.stop
                    }
                cursor := close.cursor
              }

def psParseSimpleTerm
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "term")
  | some token =>
      if psTokenKindEq token.kind PsTokenKind.identifier then
        if psStringEq token.text "true" then
          match psTokenCursorAdvance cursor with
          | none => Except.error (PsParseError.unexpectedEnd "term")
          | some read =>
              Except.ok {
                value := PsSyntaxTerm.bool true token.span
                cursor := read.cursor
              }
        else if psStringEq token.text "false" then
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
      if psStringEq token.text "(" then
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
      else if psStringEq token.text "{" then
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
      else if psStringEq token.text "[" then
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
      if Nat.beq opening.closeCount 2 then
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
  if psTokenCursorAtText cursor "(" then
    true
  else if psTokenCursorAtText cursor "{" then
    true
  else
    psTokenCursorAtText cursor "["

def psTokenCursorAtArrow (cursor : PsTokenCursor) : Bool :=
  if psTokenCursorAtText cursor "->" then
    true
  else
    psTokenCursorAtText cursor "→"

def psTokenCursorExpectArrow
    (cursor : PsTokenCursor) :
    Except PsParseError PsTokenRead :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "->")
  | some token =>
      if psStringEq token.text "->" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "->")
        | some read => Except.ok read
      else if psStringEq token.text "→" then
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
      segments := List.cons "_" List.nil
      span := span
    }
    kind := PsSyntaxBinderKind.explicit
    span := span
  }

def psSyntaxPatternSpan : PsSyntaxPattern -> PsSourceSpan
  | .bool _ span => span
  | .wildcard span => span
  | .constructor _ _ span => span

def psParsePatternBindersWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (bindersRev : List PsSyntaxName) :
    Except PsParseError (PsParseResult (List PsSyntaxName)) :=
  match fuel with
  | 0 =>
      Except.ok {
        value := bindersRev.reverse
        cursor := cursor
      }
  | remaining + 1 =>
      match psTokenCursorPeek cursor with
      | none =>
          Except.ok {
            value := bindersRev.reverse
            cursor := cursor
          }
      | some token =>
          if
              psTokenKindEq
                token.kind
                PsTokenKind.identifier then
            if psStringEq token.text "true" then
              Except.ok {
                value := bindersRev.reverse
                cursor := cursor
              }
            else if psStringEq token.text "false" then
              Except.ok {
                value := bindersRev.reverse
                cursor := cursor
              }
            else
              match psTokenCursorAdvance cursor with
              | none =>
                  Except.ok {
                    value := bindersRev.reverse
                    cursor := cursor
                  }
              | some read =>
                  let binder : PsSyntaxName := {
                    segments := List.cons token.text List.nil
                    span := token.span
                  }
                  psParsePatternBindersWithFuel
                    remaining
                    read.cursor
                    (List.cons binder bindersRev)
          else
            Except.ok {
              value := bindersRev.reverse
              cursor := cursor
            }

def psParseConstructorPatternTail
    (constructorName : PsSyntaxName)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) :=
  match psParsePatternBindersWithFuel
      cursor.remaining.length
      cursor
      List.nil with
  | Except.error error => Except.error error
  | Except.ok binders =>
      let span :=
        match binders.value.reverse with
        | [] => constructorName.span
        | lastBinder :: _ =>
            psSyntaxSpanJoin
              constructorName.span
              lastBinder.span
      Except.ok {
        value :=
          PsSyntaxPattern.constructor
            constructorName
            binders.value
            span
        cursor := binders.cursor
      }

def psParseBasicPattern
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "match pattern")
  | some token =>
      if psStringEq token.text "true" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "match pattern")
        | some read =>
            Except.ok {
              value := PsSyntaxPattern.bool true token.span
              cursor := read.cursor
            }
      else if psStringEq token.text "false" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "match pattern")
        | some read =>
            Except.ok {
              value := PsSyntaxPattern.bool false token.span
              cursor := read.cursor
            }
      else if psStringEq token.text "_" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "match pattern")
        | some read =>
            Except.ok {
              value := PsSyntaxPattern.wildcard token.span
              cursor := read.cursor
            }
      else if psStringEq token.text "." then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "constructor name")
        | some dot =>
            match psParseSyntaxName dot.cursor with
            | Except.error error => Except.error error
            | Except.ok constructorName =>
                let shorthandName : PsSyntaxName := {
                  segments := constructorName.value.segments
                  span := {
                    start := token.span.start
                    stop := constructorName.value.span.stop
                  }
                }
                psParseConstructorPatternTail
                  shorthandName
                  constructorName.cursor
      else
        match psParseSyntaxName cursor with
        | Except.error error => Except.error error
        | Except.ok constructorName =>
            psParseConstructorPatternTail
              constructorName.value
              constructorName.cursor
