import Ps.Syntax.Ast
import Ps.Syntax.ParserState


def psParseListLength {α : Type} (xs : List α) : Nat :=
  match xs with
  | List.nil => 0
  | List.cons _ tail =>
      Nat.add 1 (psParseListLength tail)

def psParseListReverseAcc {α : Type}
    (xs : List α) : List α -> List α :=
  match xs with
  | List.nil =>
      fun (acc : List α) => acc
  | List.cons head tail =>
      let smaller : List α -> List α :=
        psParseListReverseAcc tail;
      fun (acc : List α) =>
        smaller (List.cons head acc)

def psParseListReverse {α : Type}
    (xs : List α) : List α :=
  psParseListReverseAcc xs List.nil


def psParseListAppend {α : Type}
    (xs : List α) : List α -> List α :=
  match xs with
  | List.nil =>
      fun (ys : List α) => ys
  | List.cons head tail =>
      let smaller : List α -> List α :=
        psParseListAppend tail;
      fun (ys : List α) =>
        List.cons head (smaller ys)

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
  | .unary _ _ span => span
  | .binary _ _ _ span => span
  | .doE _ span => span
  | .doBindE _ _ _ _ span => span
  | .doThenE _ _ span => span
  | .doReturnE _ span => span
  | .doLetMutE _ _ _ _ span => span
  | .doAssignE _ _ _ span => span
  | .doIfE _ _ _ _ span => span
  | .arrayGetOptionE _ _ span => span
  | .doEndE span => span
  | .doForE _ _ _ _ span => span
  | .doForRangeE _ _ _ _ _ span => span
  | .doTryE _ _ _ _ span => span
  | .doWhileE _ _ _ span => span
  | .lambda _ _ span => span
  | .forallE _ _ span => span
  | .letE _ _ _ _ span => span
  | .letPatternE _ _ _ _ span => span
  | .ifE _ _ _ span => span
  | .matchE _ _ span => span

def psSyntaxSyntheticName
    (text : String)
    (span : PsSourceSpan) : PsSyntaxName :=
  psSyntaxGeneratedName (List.cons text List.nil) (span)

def psSyntaxSyntheticReference
    (text : String)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  PsSyntaxTerm.reference (psSyntaxSyntheticName text span)

def psSyntaxRootName (segments : List String) (span : PsSourceSpan) : PsSyntaxName :=
  psSyntaxGeneratedName (List.cons "_root_" segments) (span)

def psSyntaxRootReference (segments : List String) (span : PsSourceSpan) : PsSyntaxTerm :=
  PsSyntaxTerm.reference (psSyntaxRootName segments span)

def psSyntaxCompilerPure
    (value : PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  PsSyntaxTerm.app
    (psSyntaxRootReference ["compilerPure"] span)
    (List.cons value List.nil)
    span

def psSyntaxCompilerBind
    (binder : PsSyntaxBinderHead)
    (binderType : PsSyntaxTerm)
    (action : PsSyntaxTerm)
    (body : PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  let bodySpan := psSyntaxTermSpan body;
  let lambda :=
    PsSyntaxTerm.lambda
      (List.cons (Prod.mk binder binderType) List.nil)
      body
      {
        start := binder.span.start
        stop := bodySpan.stop
      };
  PsSyntaxTerm.app
    (psSyntaxRootReference ["compilerBind"] span)
    (List.cons action (List.cons lambda List.nil))
    span

-- The owned cursor keeps the exact count while a qualified name consumes tokens.
def psParseSyntaxNameCursorTailWithFuel
    (fuel : Nat) :
    List String -> PsSourcePos -> PsSourcePos -> PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxName) :=
  match fuel with
  | Nat.zero =>
      fun (_segmentsRev : List String) (_start : PsSourcePos)
          (_stop : PsSourcePos) (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (segmentsRev : List String) (start : PsSourcePos)
          (stop : PsSourcePos) (cursor : PsTokenCursor) =>
        let smaller : List String -> PsSourcePos -> PsSourcePos -> PsTokenCursor ->
            Except PsParseError (PsParseResult PsSyntaxName) :=
          psParseSyntaxNameCursorTailWithFuel remaining;
        if psTokenCursorAtText cursor "." then
          match psTokenCursorAdvance cursor with
          | Option.none => Except.error (PsParseError.unexpectedEnd "identifier")
          | Option.some dot =>
              match psTokenCursorAdvance dot.cursor with
              | Option.none => Except.error (PsParseError.unexpectedEnd "identifier")
              | Option.some next =>
                  if psTokenKindEq next.token.kind PsTokenKind.identifier then
                    smaller (List.cons next.token.text segmentsRev) start
                      next.token.span.stop next.cursor
                  else
                    Except.error (PsParseError.expectedKind PsTokenKind.identifier
                      next.token.kind next.token.span)
        else
          Except.ok {
            value := psSyntaxSourceName (psParseListReverse segmentsRev) ({ start := start, stop := stop })
            cursor := cursor
          }

-- Retain the raw-list entrypoints and their original zero/positive fuel behavior.
def psParseSyntaxNameTailWithFuel
    (fuel : Nat) (segmentsRev : List String) (start stop : PsSourcePos)
    (tokens : List PsToken) :
    Except PsParseError (PsParseResult PsSyntaxName) :=
  if Nat.beq fuel 0 then Except.error PsParseError.fuelExhausted
  else psParseSyntaxNameCursorTailWithFuel fuel segmentsRev start stop
    (psTokenCursorFromTokens tokens)

def psParseSyntaxNameTail
    (segmentsRev : List String) (start stop : PsSourcePos)
    (tokens : List PsToken) :
    Except PsParseError (PsParseResult PsSyntaxName) :=
  let cursor := psTokenCursorFromTokens tokens;
  psParseSyntaxNameCursorTailWithFuel
    (Nat.add (psTokenCursorLength cursor) 1) segmentsRev start stop cursor

def psParseSyntaxName
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxName) :=
  match psTokenCursorAdvance cursor with
  | Option.none => Except.error (PsParseError.unexpectedEnd "identifier")
  | Option.some first =>
      if psTokenKindEq first.token.kind PsTokenKind.identifier then
        if psStringEq first.token.text "_root_" then
          Except.error (PsParseError.expectedText
            "_root_ escapes are allowed only in references"
            first.token.text first.token.span)
        else
          psParseSyntaxNameCursorTailWithFuel
            (Nat.add (psTokenCursorLength first.cursor) 1)
            (List.cons first.token.text List.nil)
            first.token.span.start first.token.span.stop first.cursor
      else
        Except.error (PsParseError.expectedKind PsTokenKind.identifier
          first.token.kind first.token.span)

-- Root escapes are permitted only where a name denotes a reference.
-- Declarations, namespace commands, imports and ordinary binder/field names
-- continue through psParseSyntaxName and retain its explicit root refusal.
def psParseSyntaxReferenceName
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxName) :=
  if psTokenCursorAtText cursor "_root_" then
    match psTokenCursorExpectText cursor "_root_" with
    | .error error => Except.error error
    | .ok rootToken =>
        match psTokenCursorExpectText rootToken.cursor "." with
        | .error error => Except.error error
        | .ok dot =>
            match psParseSyntaxName dot.cursor with
            | .error error => Except.error error
            | .ok parsed =>
                Except.ok {
                  value := psSyntaxSourceName (List.cons "_root_" parsed.value.segments)
                    { start := rootToken.token.span.start, stop := parsed.value.span.stop }
                  cursor := parsed.cursor
                }
  else psParseSyntaxName cursor

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
    (fuel : Nat) :
    PsTokenCursor ->
    List (Prod PsSyntaxName PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult
        (List (Prod PsSyntaxName PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      fun
          (_cursor : PsTokenCursor)
          (_fieldsRev :
            List (Prod PsSyntaxName PsSyntaxTerm)) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      fun
          (cursor : PsTokenCursor)
          (fieldsRev :
            List (Prod PsSyntaxName PsSyntaxTerm)) =>
        let smaller :
            PsTokenCursor ->
            List (Prod PsSyntaxName PsSyntaxTerm) ->
            Except PsParseError
              (PsParseResult
                (List (Prod PsSyntaxName PsSyntaxTerm))) :=
          psParseRecordFieldsWithFuel parseTerm remaining;
        if psTokenCursorAtText cursor "}" then
          Except.ok {
            value := psParseListReverse fieldsRev
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
                        Prod.mk name.value value.value;
                      if psTokenCursorAtText value.cursor "," then
                        match psTokenCursorAdvance value.cursor with
                        | none =>
                            Except.error
                              (PsParseError.unexpectedEnd
                                "record field")
                        | some afterComma =>
                            smaller
                              afterComma.cursor
                              (List.cons nextField fieldsRev)
                      else if
                          if psTokenCursorAtText value.cursor "}" then
                            true
                          else
                            psTokenCursorStartsNamedAssignment
                              value.cursor then
                        smaller
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
            (psTokenCursorLength opening.cursor)
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
          match psParseSyntaxReferenceName cursor with
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
    name := psSyntaxGeneratedName (List.cons "_" List.nil) (span)
    kind := PsSyntaxBinderKind.explicit
    span := span
  }

def psSyntaxPatternSpan : PsSyntaxPattern -> PsSourceSpan
  | .bool _ span => span
  | .wildcard span => span
  | .constructor _ _ span => span

def psParsePatternBindersWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxName ->
    Except PsParseError (PsParseResult (List PsSyntaxName)) :=
  match fuel with
  | 0 =>
      fun
          (cursor : PsTokenCursor)
          (bindersRev : List PsSyntaxName) =>
        Except.ok {
          value := psParseListReverse bindersRev
          cursor := cursor
        }
  | remaining + 1 =>
      fun
          (cursor : PsTokenCursor)
          (bindersRev : List PsSyntaxName) =>
        let smaller :
            PsTokenCursor ->
            List PsSyntaxName ->
            Except PsParseError
              (PsParseResult (List PsSyntaxName)) :=
          psParsePatternBindersWithFuel remaining;
        match psTokenCursorPeek cursor with
        | none =>
            Except.ok {
              value := psParseListReverse bindersRev
              cursor := cursor
            }
        | some token =>
            if
                psTokenKindEq
                  token.kind
                  PsTokenKind.identifier then
              if psStringEq token.text "true" then
                Except.ok {
                  value := psParseListReverse bindersRev
                  cursor := cursor
                }
              else if psStringEq token.text "false" then
                Except.ok {
                  value := psParseListReverse bindersRev
                  cursor := cursor
                }
              else
                match psTokenCursorAdvance cursor with
                | none =>
                    Except.ok {
                      value := psParseListReverse bindersRev
                      cursor := cursor
                    }
                | some read =>
                    let binder : PsSyntaxName := psSyntaxSourceName (List.cons token.text List.nil) (token.span);
                    smaller
                      read.cursor
                      (List.cons binder bindersRev)
            else
              Except.ok {
                value := psParseListReverse bindersRev
                cursor := cursor
              }

def psParseConstructorPatternTail
    (constructorName : PsSyntaxName)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) :=
  match psParsePatternBindersWithFuel
      (psTokenCursorLength cursor)
      cursor
      List.nil with
  | Except.error error => Except.error error
  | Except.ok binders =>
      let span : PsSourceSpan :=
        match psParseListReverse binders.value with
        | [] => constructorName.span
        | lastBinder :: _ =>
            psSyntaxSpanJoin
              constructorName.span
              lastBinder.span;
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
            match psParseSyntaxReferenceName dot.cursor with
            | Except.error error => Except.error error
            | Except.ok constructorName =>
                let shorthandName : PsSyntaxName := PsSyntaxName.mk (constructorName.value.segments) ({
                    start := token.span.start
                    stop := constructorName.value.span.stop
                  }) constructorName.value.sourceSpan;
                psParseConstructorPatternTail
                  shorthandName
                  constructorName.cursor
      else
        match psParseSyntaxReferenceName cursor with
        | Except.error error => Except.error error
        | Except.ok constructorName =>
            psParseConstructorPatternTail
              constructorName.value
              constructorName.cursor

def psParseNamespaceText (segments : List String) : String :=
  match segments with
  | List.nil => ""
  | List.cons segment rest =>
      match rest with
      | List.nil => segment
      | List.cons _ _ =>
          String.Internal.append segment
            (String.Internal.append "." (psParseNamespaceText rest))

def psParseNamespaceEq (left : List String) : List String -> Bool :=
  match left with
  | List.nil =>
      fun (right : List String) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons first rest =>
      let smaller : List String -> Bool := psParseNamespaceEq rest;
      fun (right : List String) =>
        match right with
        | List.nil => false
        | List.cons other tail =>
            if psStringEq first other then smaller tail else false

def psParseNamespacePath (scopes : List PsSyntaxName) : List String :=
  match scopes with
  | List.nil => List.nil
  | List.cons name rest =>
      psSyntaxNamespaceAppend (psParseNamespacePath rest) name.segments

def psParseScopedDeclarationsFinish
    (cursor : PsTokenCursor) (scopes : List PsSyntaxName)
    (declarationsRev : List PsSyntaxDeclaration) :
    Except PsParseError (PsParseResult (List PsSyntaxDeclaration)) :=
  match scopes with
  | [] => Except.ok { value := psParseListReverse declarationsRev, cursor := cursor }
  | name :: _ => Except.error (PsParseError.unexpectedEnd
      (String.Internal.append "end " (psParseNamespaceText name.segments)))

def psParseScopedDeclarationsWithFuel
    (parseDeclaration : PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxDeclaration))
    (separator : PsSourcePos -> PsTokenCursor -> Except PsParseError PsTokenCursor)
    (fuel : Nat) :
    PsTokenCursor -> List PsSyntaxName -> List PsSyntaxDeclaration ->
    Except PsParseError (PsParseResult (List PsSyntaxDeclaration)) :=
  match fuel with
  | Nat.zero =>
      fun (cursor : PsTokenCursor) (scopes : List PsSyntaxName)
          (declarationsRev : List PsSyntaxDeclaration) =>
        if psTokenCursorDone cursor then
          psParseScopedDeclarationsFinish cursor scopes declarationsRev
        else Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (cursor : PsTokenCursor) (scopes : List PsSyntaxName)
          (declarationsRev : List PsSyntaxDeclaration) =>
        let smaller :
            PsTokenCursor -> List PsSyntaxName -> List PsSyntaxDeclaration ->
            Except PsParseError (PsParseResult (List PsSyntaxDeclaration)) :=
          psParseScopedDeclarationsWithFuel parseDeclaration separator remaining;
        if psTokenCursorDone cursor then
          psParseScopedDeclarationsFinish cursor scopes declarationsRev
        else if psTokenCursorAtText cursor "namespace" then
          match psTokenCursorExpectText cursor "namespace" with
          | Except.error error => Except.error error
          | Except.ok keyword =>
              match psParseSyntaxName keyword.cursor with
              | Except.error error => Except.error error
              | Except.ok name =>
                  match separator name.value.span.stop name.cursor with
                  | Except.error error => Except.error error
                  | Except.ok next =>
                      smaller next (List.cons name.value scopes) declarationsRev
        else if psTokenCursorAtText cursor "end" then
          match psTokenCursorExpectText cursor "end" with
          | Except.error error => Except.error error
          | Except.ok keyword =>
              match scopes with
              | List.nil => Except.error (PsParseError.expectedText
                  "namespace declaration" "end" keyword.token.span)
              | List.cons opened outer =>
                  match psParseSyntaxName keyword.cursor with
                  | Except.error error => Except.error error
                  | Except.ok name =>
                      if psParseNamespaceEq opened.segments name.value.segments then
                        match separator name.value.span.stop name.cursor with
                        | Except.error error => Except.error error
                        | Except.ok next => smaller next outer declarationsRev
                      else Except.error (PsParseError.expectedText
                        (psParseNamespaceText opened.segments)
                        (psParseNamespaceText name.value.segments) name.value.span)
        else
          match parseDeclaration cursor with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              let declarationSpan := psSyntaxDeclarationSpan parsed.value;
              match separator declarationSpan.stop parsed.cursor with
              | Except.error error => Except.error error
              | Except.ok next =>
                  let path := psParseNamespacePath scopes;
                  let declaration : PsSyntaxDeclaration :=
                    match path with
                    | List.nil => parsed.value
                    | List.cons _ _ => PsSyntaxDeclaration.scopedDecl path parsed.value;
                  smaller next scopes (List.cons declaration declarationsRev)

-- Bare lambda binders carry a local annotation marker. Only lambda checking
-- consumes it, from an expected function domain; it is not a general term hole.
def psParseSingleLambdaBinder
    (parseTyped : PsTokenCursor ->
      Except PsParseError (PsParseResult (Prod PsSyntaxBinderHead PsSyntaxTerm)))
    (cursor : PsTokenCursor) :
    Except PsParseError
      (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
  match parseTyped cursor with
  | Except.error error => Except.error error
  | Except.ok binder =>
      Except.ok (PsParseResult.mk (List.cons binder.value List.nil) binder.cursor)

def psParseLambdaBindersWithFuel
    (parseTyped : PsTokenCursor ->
      Except PsParseError
        (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))))
    (fuel : Nat) :
    PsTokenCursor ->
    List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
  match fuel with
  | Nat.zero =>
      fun (_cursor : PsTokenCursor)
          (_bindersRev : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (cursor : PsTokenCursor)
          (bindersRev : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        let smaller := psParseLambdaBindersWithFuel parseTyped remaining;
        if psTokenCursorAtText cursor "=>" then
          Except.ok (PsParseResult.mk (psParseListReverse bindersRev) cursor)
        else if psTokenCursorAtBinderStart cursor then
          match parseTyped cursor with
          | Except.error error => Except.error error
          | Except.ok binder =>
              smaller binder.cursor
                (psParseListAppend (psParseListReverse binder.value) bindersRev)
        else
          match psTokenCursorExpectKind cursor PsTokenKind.identifier with
          | Except.error error => Except.error error
          | Except.ok token =>
              let name := psSyntaxSourceName
                (List.cons token.token.text List.nil) token.token.span;
              let head := PsSyntaxBinderHead.mk name
                PsSyntaxBinderKind.explicit token.token.span;
              let annotation := psSyntaxSyntheticReference "_" token.token.span;
              smaller token.cursor
                (List.cons (Prod.mk head annotation) bindersRev)
