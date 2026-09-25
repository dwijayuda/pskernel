import Ps.Syntax.Lexer
import Ps.Syntax.ParseCommon

def psLeanTermStop
    (term : PsSyntaxTerm) : PsSourcePos :=
  let span := psSyntaxTermSpan term;
  span.stop

def psLeanTokenCursor
    (remaining : List PsToken) : PsTokenCursor :=
  { remaining := remaining }

def psLeanBoolNot (value : Bool) : Bool :=
  if value then false else true

def psLeanPatternParseResult
    (value : PsSyntaxPattern)
    (remaining : List PsToken) :
    PsParseResult PsSyntaxPattern :=
  {
    value := value
    cursor := psLeanTokenCursor remaining
  }


def psParseLeanImport
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxImport) :=
  match psTokenCursorExpectText cursor "import" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseSyntaxName keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok name =>
          Except.ok {
            value := {
              moduleName := name.value
              span := {
                start := keyword.token.span.start
                stop := name.value.span.stop
              }
            }
            cursor := name.cursor
          }

def psLeanReservedApplicationToken (token : PsToken) : Bool :=
  if psStringEq token.text "def" then
    true
  else if psStringEq token.text "partial" then
    true
  else if psStringEq token.text "theorem" then
    true
  else if psStringEq token.text "import" then
    true
  else if psStringEq token.text "inductive" then
    true
  else if psStringEq token.text "structure" then
    true
  else if psStringEq token.text "where" then
    true
  else if psStringEq token.text "then" then
    true
  else if psStringEq token.text "else" then
    true
  else if psStringEq token.text "fun" then
    true
  else if psStringEq token.text "let" then
    true
  else if psStringEq token.text "if" then
    true
  else if psStringEq token.text "match" then
    true
  else
    psStringEq token.text "with"


def psLeanApplicationWithArgument
    (current : PsSyntaxTerm)
    (argument : PsSyntaxTerm) : PsSyntaxTerm :=
  let span :=
    psSyntaxSpanJoin
      (psSyntaxTermSpan current)
      (psSyntaxTermSpan argument);
  match current with
  | .app fn args _ =>
      PsSyntaxTerm.app
        fn
        (psParseListAppend
          args
          (List.cons argument List.nil))
        span
  | _ =>
      PsSyntaxTerm.app
        current
        (List.cons argument List.nil)
        span

def psLeanListConstructorName
    (constructor : String)
    (span : PsSourceSpan) : PsSyntaxName :=
  {
    segments :=
      List.cons
        "List"
        (List.cons constructor List.nil)
    span := span
  }

def psLeanBuildListLiteral
    (elements : List PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  match elements with
  | List.nil =>
      PsSyntaxTerm.reference
        (psLeanListConstructorName "nil" span)
  | List.cons head rest =>
      let tail :=
        psLeanBuildListLiteral rest span;
      PsSyntaxTerm.app
        (PsSyntaxTerm.reference
          (psLeanListConstructorName "cons" span))
        (List.cons
          head
          (List.cons tail List.nil))
        span

def psParseLeanListLiteralWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsSourcePos ->
    PsTokenCursor ->
    List PsSyntaxTerm ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun
          (_start : PsSourcePos)
          (_cursor : PsTokenCursor)
          (_elementsRev : List PsSyntaxTerm) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsSourcePos ->
          PsTokenCursor ->
          List PsSyntaxTerm ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseLeanListLiteralWithFuel
          parseTerm
          remaining;
      fun
          (start : PsSourcePos)
          (cursor : PsTokenCursor)
          (elementsRev : List PsSyntaxTerm) =>
        if psTokenCursorAtText cursor "]" then
          match psTokenCursorAdvance cursor with
          | Option.none =>
              Except.error
                (PsParseError.unexpectedEnd "]")
          | Option.some close =>
              let span : PsSourceSpan := {
                start := start
                stop := close.token.span.stop
              };
              Except.ok {
                value :=
                  psLeanBuildListLiteral
                    (psParseListReverse elementsRev)
                    span
                cursor := close.cursor
              }
        else
          match parseTerm cursor with
          | Except.error error => Except.error error
          | Except.ok element =>
              let nextElements :=
                List.cons element.value elementsRev;
              if psTokenCursorAtText element.cursor "," then
                match psTokenCursorAdvance element.cursor with
                | Option.none =>
                    Except.error
                      (PsParseError.unexpectedEnd
                        "list element")
                | Option.some afterComma =>
                    smaller
                      start
                      afterComma.cursor
                      nextElements
              else if
                  psTokenCursorAtText
                    element.cursor
                    "]" then
                smaller
                  start
                  element.cursor
                  nextElements
              else
                match psTokenCursorPeek element.cursor with
                | Option.none =>
                    Except.error
                      (PsParseError.unexpectedEnd "]")
                | Option.some token =>
                    Except.error
                      (PsParseError.expectedText
                        "]"
                        token.text
                        token.span)

def psParseLeanListLiteral
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (opening : PsTokenRead) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseLeanListLiteralWithFuel
    parseTerm
    (Nat.add
      (psParseListLength opening.cursor.remaining)
      1)
    opening.token.span.start
    opening.cursor
    List.nil

def psLeanCanStartSimpleArgument
    (current : PsSyntaxTerm)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | Option.none => false
  | Option.some token =>
      let currentSpan := psSyntaxTermSpan current;
      let startsLaterAssignment :=
        if psTokenCursorStartsNamedAssignment cursor then
          Nat.ble
            (Nat.add currentSpan.stop.line 1)
            token.span.start.line
        else
          false;
      if psLeanReservedApplicationToken token then
        false
      else if startsLaterAssignment then
        false
      else if psStringEq token.text "(" then
        true
      else if psStringEq token.text "[" then
        true
      else if
          psTokenKindEq
            token.kind
            PsTokenKind.identifier then
        true
      else if
          psTokenKindEq
            token.kind
            PsTokenKind.natural then
        true
      else if
          psTokenKindEq
            token.kind
            PsTokenKind.string then
        true
      else
        psTokenKindEq
          token.kind
          PsTokenKind.character

def psParseLeanApplicationTailWithFuel
    (parseParenthesized :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsSyntaxTerm ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun
          (current : PsSyntaxTerm)
          (cursor : PsTokenCursor) =>
        Except.ok { value := current, cursor := cursor }
  | remaining + 1 =>
      let smaller :
          PsSyntaxTerm ->
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseLeanApplicationTailWithFuel
          parseParenthesized
          remaining;
      fun
          (current : PsSyntaxTerm)
          (cursor : PsTokenCursor) =>
      if psLeanCanStartSimpleArgument current cursor then
        if psTokenCursorAtText cursor "(" then
          match psTokenCursorAdvance cursor with
          | Option.none => Except.error (PsParseError.unexpectedEnd "(")
          | Option.some opening =>
              if psTokenCursorAtText opening.cursor ")" then
                match psTokenCursorAdvance opening.cursor with
                | Option.none => Except.error (PsParseError.unexpectedEnd ")")
                | Option.some close =>
                    let argument :=
                      PsSyntaxTerm.unit {
                        start := opening.token.span.start
                        stop := close.token.span.stop
                      };
                    let next :=
                      psLeanApplicationWithArgument
                        current
                        argument;
                    smaller
                      next
                      close.cursor
              else
                match parseParenthesized opening.cursor with
                | Except.error error => Except.error error
                | Except.ok inner =>
                    match psTokenCursorExpectText inner.cursor ")" with
                    | Except.error error => Except.error error
                    | Except.ok close =>
                        let next :=
                          psLeanApplicationWithArgument
                            current
                            inner.value;
                        smaller
                          next
                          close.cursor
        else if psTokenCursorAtText cursor "[" then
          match psTokenCursorAdvance cursor with
          | Option.none =>
              Except.error
                (PsParseError.unexpectedEnd "[")
          | Option.some opening =>
              match
                  psParseLeanListLiteral
                    parseParenthesized
                    opening with
              | Except.error error => Except.error error
              | Except.ok argument =>
                  let next :=
                    psLeanApplicationWithArgument
                      current
                      argument.value;
                  smaller
                    next
                    argument.cursor
        else
          match psParseSimpleTerm cursor with
          | Except.error error => Except.error error
          | Except.ok argument =>
              let next :=
                psLeanApplicationWithArgument
                  current
                  argument.value;
              smaller
                next
                argument.cursor
      else
        Except.ok { value := current, cursor := cursor }

def psParseLeanApplicationWithFuel
    (parseParenthesized :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      match psParseSimpleTerm cursor with
      | Except.error error => Except.error error
      | Except.ok first =>
          psParseLeanApplicationTailWithFuel
            parseParenthesized
            remaining
            first.value
            first.cursor

def psParseLeanSimpleApplicationWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseLeanSimpleApplicationWithFuel remaining;
      fun (cursor : PsTokenCursor) =>
        psParseLeanApplicationWithFuel
          smaller
          (Nat.add remaining 1)
          cursor

def psParseLeanSimpleApplication
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseLeanSimpleApplicationWithFuel
    (Nat.add (psParseListLength cursor.remaining) 1)
    cursor

def psParseLeanProductWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseLeanProductWithFuel remaining;
      fun (cursor : PsTokenCursor) =>
        match
            psParseLeanApplicationWithFuel
              smaller
              (Nat.add remaining 1)
              cursor with
        | Except.error error => Except.error error
        | Except.ok left =>
            if psTokenCursorAtText left.cursor "×" then
              match psTokenCursorAdvance left.cursor with
              | Option.none =>
                  Except.error
                    (PsParseError.unexpectedEnd "product type")
              | Option.some afterProduct =>
                  match smaller afterProduct.cursor with
                  | Except.error error => Except.error error
                  | Except.ok right =>
                      let span :=
                        psSyntaxSpanJoin
                          (psSyntaxTermSpan left.value)
                          (psSyntaxTermSpan right.value);
                      let prodName : PsSyntaxName := {
                        segments :=
                          List.cons "Prod" List.nil
                        span := afterProduct.token.span
                      };
                      Except.ok {
                        value :=
                          PsSyntaxTerm.app
                            (PsSyntaxTerm.reference prodName)
                            (List.cons
                              left.value
                              (List.cons right.value List.nil))
                            span
                        cursor := right.cursor
                      }
            else
              Except.ok left

def psParseLeanProduct
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseLeanProductWithFuel
    (Nat.add (psParseListLength cursor.remaining) 1)
    cursor

def psParseLeanBinderTypeWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseLeanBinderTypeWithFuel remaining;
      fun (cursor : PsTokenCursor) =>
        match psParseLeanProductWithFuel remaining cursor with
        | Except.error error => Except.error error
        | Except.ok domain =>
            if psTokenCursorAtArrow domain.cursor then
              match psTokenCursorExpectArrow domain.cursor with
              | Except.error error => Except.error error
              | Except.ok afterArrow =>
                  match smaller afterArrow.cursor with
                  | Except.error error => Except.error error
                  | Except.ok codomain =>
                      let domainSpan :=
                        psSyntaxTermSpan domain.value;
                      Except.ok {
                        value :=
                          PsSyntaxTerm.forallE
                            (List.cons
                              (Prod.mk
                                (psSyntaxAnonymousExplicitBinder
                                  domainSpan)
                                domain.value)
                              List.nil)
                            codomain.value
                            (psSyntaxSpanJoin
                              domainSpan
                              (psSyntaxTermSpan codomain.value))
                        cursor := codomain.cursor
                      }
            else
              Except.ok domain

def psParseLeanBinderType
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseLeanBinderTypeWithFuel
    (Nat.add (psParseListLength cursor.remaining) 1)
    cursor

def psParseLeanBinderNamesWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxName ->
    Except PsParseError
      (PsParseResult (List PsSyntaxName)) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_namesRev : List PsSyntaxName) =>
      Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      fun
        (cursor : PsTokenCursor)
        (namesRev : List PsSyntaxName) =>
      match
          psTokenCursorExpectKind
            cursor
            PsTokenKind.identifier with
      | Except.error error => Except.error error
      | Except.ok name =>
          let sourceName : PsSyntaxName := {
            segments := List.cons name.token.text List.nil
            span := name.token.span
          };
          let nextNames :=
            List.cons sourceName namesRev;
          if psTokenCursorAtText name.cursor ":" then
            Except.ok {
              value := psParseListReverse nextNames
              cursor := name.cursor
            }
          else
            match psTokenCursorPeek name.cursor with
            | Option.none =>
                Except.error
                  (PsParseError.unexpectedEnd ":")
            | Option.some next =>
                if
                    psTokenKindEq
                      next.kind
                      PsTokenKind.identifier then
                  let smaller :
                      PsTokenCursor ->
                      List PsSyntaxName ->
                      Except PsParseError
                        (PsParseResult (List PsSyntaxName)) :=
                    psParseLeanBinderNamesWithFuel remaining;
                  smaller name.cursor nextNames
                else
                  Except.error
                    (PsParseError.expectedText
                      ":"
                      next.text
                      next.span)

def psLeanBinderPairsFromNames
    (kind : PsSyntaxBinderKind)
    (span : PsSourceSpan)
    (type : PsSyntaxTerm)
    (names : List PsSyntaxName) :
    List
      (Prod PsSyntaxBinderHead PsSyntaxTerm) :=
  match names with
  | List.nil => List.nil
  | List.cons name rest =>
      let head : PsSyntaxBinderHead := {
        name := name
        kind := kind
        span := span
      };
      List.cons
        (Prod.mk head type)
        (psLeanBinderPairsFromNames
          kind
          span
          type
          rest)

def psParseLeanBinderGroup
    (cursor : PsTokenCursor) :
    Except PsParseError
      (PsParseResult
        (List
          (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
  match psParseBinderOpening cursor with
  | Except.error error => Except.error error
  | Except.ok opening =>
      match
          psParseLeanBinderNamesWithFuel
            (psParseListLength opening.cursor.remaining)
            opening.cursor
            List.nil with
      | Except.error error => Except.error error
      | Except.ok names =>
          match
              psTokenCursorExpectText
                names.cursor
                ":" with
          | Except.error error => Except.error error
          | Except.ok afterColon =>
              match
                  psParseLeanBinderType
                    afterColon.cursor with
              | Except.error error => Except.error error
              | Except.ok type =>
                  match
                      psParseBinderClosing
                        opening
                        type.cursor with
                  | Except.error error => Except.error error
                  | Except.ok closing =>
                      Except.ok {
                        value :=
                          psLeanBinderPairsFromNames
                            opening.kind
                            closing.value
                            type.value
                            names.value
                        cursor := closing.cursor
                      }

def psLeanPrependBinderGroupReverse
    (group :
      List
        (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    List
      (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
    List
      (Prod PsSyntaxBinderHead PsSyntaxTerm) :=
  match group with
  | List.nil =>
      fun
        (bindersRev :
          List
            (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        bindersRev
  | List.cons binder rest =>
      let smaller :
          List
            (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
          List
            (Prod PsSyntaxBinderHead PsSyntaxTerm) :=
        psLeanPrependBinderGroupReverse rest;
      fun
        (bindersRev :
          List
            (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        smaller (List.cons binder bindersRev)

def psParseLeanBinder
    (cursor : PsTokenCursor) :
    Except PsParseError
      (PsParseResult (PsSyntaxBinderHead × PsSyntaxTerm)) :=
  match psParseBinderOpening cursor with
  | Except.error error => Except.error error
  | Except.ok opening =>
      match psTokenCursorExpectKind opening.cursor PsTokenKind.identifier with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psTokenCursorExpectText name.cursor ":" with
          | Except.error error => Except.error error
          | Except.ok afterColon =>
              match psParseLeanBinderType afterColon.cursor with
              | Except.error error => Except.error error
              | Except.ok type =>
                  match psParseBinderClosing opening type.cursor with
                  | Except.error error => Except.error error
                  | Except.ok closing =>
                      let binderName : PsSyntaxName := {
                        segments := List.cons name.token.text List.nil
                        span := name.token.span
                      };
                      let binder : PsSyntaxBinderHead := {
                        name := binderName
                        kind := opening.kind
                        span := closing.value
                      };
                      Except.ok {
                        value := Prod.mk binder type.value
                        cursor := closing.cursor
                      }

def psParseLeanBindersWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List (PsSyntaxBinderHead × PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (bindersRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) =>
        Except.ok {
          value := psParseListReverse bindersRev
          cursor := cursor
        }
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List (PsSyntaxBinderHead × PsSyntaxTerm) ->
          Except PsParseError
            (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
        psParseLeanBindersWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (bindersRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) =>
        if psTokenCursorAtBinderStart cursor then
          match psParseLeanBinderGroup cursor with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              smaller
                parsed.cursor
                (psLeanPrependBinderGroupReverse
                  parsed.value
                  bindersRev)
        else
          Except.ok {
            value := psParseListReverse bindersRev
            cursor := cursor
          }

def psParseLeanArrowTail
    (parseCodomain :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (domain : PsParseResult PsSyntaxTerm) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  if psTokenCursorAtArrow domain.cursor then
    match psTokenCursorExpectArrow domain.cursor with
    | Except.error error => Except.error error
    | Except.ok afterArrow =>
        match parseCodomain afterArrow.cursor with
        | Except.error error => Except.error error
        | Except.ok codomain =>
            let domainSpan := psSyntaxTermSpan domain.value;
            let span := psSyntaxSpanJoin domainSpan (psSyntaxTermSpan codomain.value);
            Except.ok {
              value :=
                PsSyntaxTerm.forallE
                  (List.cons
                    (Prod.mk
                      (psSyntaxAnonymousExplicitBinder domainSpan)
                      domain.value)
                    List.nil)
                  codomain.value
                  span
              cursor := codomain.cursor
            }
  else
    Except.ok domain

def psParseLeanDependentArrowTail
    (parseCodomain :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (binder :
      PsParseResult (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  if psTokenCursorAtArrow binder.cursor then
    match psTokenCursorExpectArrow binder.cursor with
    | Except.error error => Except.error error
    | Except.ok afterArrow =>
        match parseCodomain afterArrow.cursor with
        | Except.error error => Except.error error
        | Except.ok codomain =>
            let codomainSpan := psSyntaxTermSpan codomain.value;
            let span : PsSourceSpan := {
              start := binder.value.fst.span.start
              stop := codomainSpan.stop
            };
            Except.ok {
              value :=
                PsSyntaxTerm.forallE
                  (List.cons binder.value List.nil)
                  codomain.value
                  span
              cursor := codomain.cursor
            }
  else
    match psTokenCursorPeek binder.cursor with
    | Option.none =>
        Except.error
          (PsParseError.expectedText
            "->"
            ""
            binder.value.fst.span)
    | Option.some token =>
        Except.error
          (PsParseError.expectedText
            "->"
            token.text
            token.span)

def psLeanPatternBinderName
    (token : PsToken)
    (fallback : String) : PsSyntaxName :=
  let segment :=
    if psStringEq token.text "_" then
      fallback
    else
      token.text;
  {
    segments :=
      List.cons segment List.nil
    span := token.span
  }

def psParseLeanListPattern
    (cursor : PsTokenCursor) :
    Option
      (Except
        PsParseError
        (PsParseResult PsSyntaxPattern)) :=
  match cursor.remaining with
  | List.nil => Option.none
  | List.cons first afterFirst =>
      match afterFirst with
      | List.nil => Option.none
      | List.cons second afterSecond =>
          if psStringEq first.text "[" then
            if psStringEq second.text "]" then
              let span :=
                psSyntaxSpanJoin first.span second.span;
              let name : PsSyntaxName := {
                segments :=
                  List.cons
                    "List"
                    (List.cons "nil" List.nil)
                span := span
              };
              let value :=
                PsSyntaxPattern.constructor
                  name
                  List.nil
                  span;
              Option.some
                (Except.ok
                  (psLeanPatternParseResult
                    value
                    afterSecond))
            else if psStringEq second.text "::" then
              match afterSecond with
              | List.nil => Option.none
              | List.cons third rest =>
                  if
                      psTokenKindEq
                        first.kind
                        PsTokenKind.identifier then
                    if
                        psTokenKindEq
                          third.kind
                          PsTokenKind.identifier then
                      let span :=
                        psSyntaxSpanJoin first.span third.span;
                      let name : PsSyntaxName := {
                        segments :=
                          List.cons
                            "List"
                            (List.cons "cons" List.nil)
                        span := span
                      };
                      let headBinder :=
                        psLeanPatternBinderName
                          first
                          "_listHead";
                      let tailBinder :=
                        psLeanPatternBinderName
                          third
                          "_listTail";
                      let value :=
                        PsSyntaxPattern.constructor
                          name
                          (List.cons
                            headBinder
                            (List.cons
                              tailBinder
                              List.nil))
                          span;
                      Option.some
                        (Except.ok
                          (psLeanPatternParseResult
                            value
                            rest))
                    else
                      Option.none
                  else
                    Option.none
            else
              Option.none
          else if psStringEq second.text "::" then
            match afterSecond with
            | List.nil => Option.none
            | List.cons third rest =>
                if
                    psTokenKindEq
                      first.kind
                      PsTokenKind.identifier then
                  if
                      psTokenKindEq
                        third.kind
                        PsTokenKind.identifier then
                    let span :=
                      psSyntaxSpanJoin first.span third.span;
                    let name : PsSyntaxName := {
                      segments :=
                        List.cons
                          "List"
                          (List.cons "cons" List.nil)
                      span := span
                    };
                    let headBinder :=
                      psLeanPatternBinderName first "_listHead";
                    let tailBinder :=
                      psLeanPatternBinderName third "_listTail";
                    let value :=
                      PsSyntaxPattern.constructor
                        name
                        (List.cons
                          headBinder
                          (List.cons tailBinder List.nil))
                        span;
                    Option.some
                      (Except.ok
                        (psLeanPatternParseResult
                          value
                          rest))
                  else
                    Option.none
                else
                  Option.none
          else
            Option.none

def psLeanNatPatternName
    (constructor : String)
    (span : PsSourceSpan) : PsSyntaxName :=
  {
    segments :=
      List.cons
        "Nat"
        (List.cons constructor List.nil)
    span := span
  }

def psParseLeanNatPattern
    (cursor : PsTokenCursor) :
    Option
      (Except
        PsParseError
        (PsParseResult PsSyntaxPattern)) :=
  match cursor.remaining with
  | List.nil => Option.none
  | List.cons first rest =>
      if
          psTokenKindEq
            first.kind
            PsTokenKind.natural then
        if psStringEq first.text "0" then
          let value :=
            PsSyntaxPattern.constructor
              (psLeanNatPatternName
                "zero"
                first.span)
              List.nil
              first.span;
          Option.some
            (Except.ok
              (psLeanPatternParseResult
                value
                rest))
        else
          Option.none
      else
        match rest with
        | List.nil => Option.none
        | List.cons plus afterPlus =>
            match afterPlus with
            | List.nil => Option.none
            | List.cons one afterOne =>
                if
                    psTokenKindEq
                      first.kind
                      PsTokenKind.identifier then
                  if psStringEq plus.text "+" then
                    if
                        psTokenKindEq
                          one.kind
                          PsTokenKind.natural then
                      if psStringEq one.text "1" then
                        let span :=
                          psSyntaxSpanJoin
                            first.span
                            one.span;
                        let binder :=
                          psLeanPatternBinderName
                            first
                            "_natPred";
                        let value :=
                          PsSyntaxPattern.constructor
                            (psLeanNatPatternName
                              "succ"
                              span)
                            (List.cons binder List.nil)
                            span;
                        Option.some
                          (Except.ok
                            (psLeanPatternParseResult
                              value
                              afterOne))
                      else
                        Option.none
                    else
                      Option.none
                  else
                    Option.none
                else
                  Option.none

def psParseLeanPattern
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) :=
  match psParseLeanNatPattern cursor with
  | Option.some result => result
  | Option.none =>
      match psParseLeanListPattern cursor with
      | Option.some result => result
      | Option.none => psParseBasicPattern cursor

def psParseLeanMatchAlternativesAtColumnWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (branchColumn : Nat)
    (fuel : Nat) :
    Nat ->
    PsTokenCursor ->
    List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan) ->
    Except PsParseError
      (PsParseResult
        (List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))) :=
  match fuel with
  | 0 =>
      fun
        (_previousBranchLine : Nat)
        (cursor : PsTokenCursor)
        (alternativesRev :
          List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan)) =>
        Except.ok {
          value := psParseListReverse alternativesRev
          cursor := cursor
        }
  | remaining + 1 =>
      let smaller :
          Nat ->
          PsTokenCursor ->
          List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan) ->
          Except PsParseError
            (PsParseResult
              (List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))) :=
        psParseLeanMatchAlternativesAtColumnWithFuel
          parseTerm
          branchColumn
          remaining;
      fun
        (previousBranchLine : Nat)
        (cursor : PsTokenCursor)
        (alternativesRev :
          List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan)) =>
        match psTokenCursorPeek cursor with
        | Option.none =>
            Except.ok {
              value := psParseListReverse alternativesRev
              cursor := cursor
            }
        | Option.some token =>
            let sameLine :=
              Nat.beq token.span.start.line previousBranchLine;
            let belongsToMatch :=
              if psStringEq token.text "|" then
                if sameLine then
                  true
                else
                  Nat.ble branchColumn token.span.start.column
              else
                false;
            if belongsToMatch then
              match psTokenCursorAdvance cursor with
              | Option.none =>
                  Except.error (PsParseError.unexpectedEnd "match pattern")
              | Option.some bar =>
                  match psParseLeanPattern bar.cursor with
                  | Except.error error => Except.error error
                  | Except.ok pattern =>
                      match psTokenCursorExpectText pattern.cursor "=>" with
                      | Except.error error => Except.error error
                      | Except.ok afterArrow =>
                          match parseTerm afterArrow.cursor with
                          | Except.error error => Except.error error
                          | Except.ok body =>
                              let span : PsSourceSpan := {
                                start := bar.token.span.start
                                stop := psLeanTermStop body.value
                              };
                              let alternative :
                                  Prod
                                    PsSyntaxPattern
                                    (Prod PsSyntaxTerm PsSourceSpan) :=
                                Prod.mk
                                  pattern.value
                                  (Prod.mk body.value span);
                              smaller
                                bar.token.span.start.line
                                body.cursor
                                (List.cons
                                  alternative
                                  alternativesRev)
            else
              Except.ok {
                value := psParseListReverse alternativesRev
                cursor := cursor
              }

def psParseLeanMatchAlternativesWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (alternativesRev :
      List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan)) :
    Except PsParseError
      (PsParseResult
        (List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))) :=
  match psTokenCursorPeek cursor with
  | Option.none =>
      Except.ok {
        value := psParseListReverse alternativesRev
        cursor := cursor
      }
  | Option.some token =>
      if psStringEq token.text "|" then
        psParseLeanMatchAlternativesAtColumnWithFuel
          parseTerm
          token.span.start.column
          fuel
          token.span.start.line
          cursor
          alternativesRev
      else
        Except.ok {
          value := psParseListReverse alternativesRev
          cursor := cursor
        }

def psParseLeanDoWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsSourcePos ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun
        (_start : PsSourcePos)
        (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsSourcePos ->
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseLeanDoWithFuel parseTerm remaining;
      fun
        (start : PsSourcePos)
        (cursor : PsTokenCursor) =>
      if psTokenCursorAtText cursor "return" then
        match psTokenCursorAdvance cursor with
        | Option.none =>
            Except.error
              (PsParseError.unexpectedEnd "do return value")
        | Option.some returnKeyword =>
            match parseTerm returnKeyword.cursor with
            | Except.error error => Except.error error
            | Except.ok value =>
                let finalCursor : PsTokenCursor :=
                  if psTokenCursorAtText value.cursor ";" then
                    match psTokenCursorAdvance value.cursor with
                    | Option.none => value.cursor
                    | Option.some afterSemi => afterSemi.cursor
                  else
                    value.cursor;
                let span : PsSourceSpan := {
                  start := start
                  stop := psLeanTermStop value.value
                };
                Except.ok {
                  value := psSyntaxCompilerPure value.value span
                  cursor := finalCursor
                }
      else if psTokenCursorAtText cursor "let" then
        match psTokenCursorAdvance cursor with
        | Option.none =>
            Except.error
              (PsParseError.unexpectedEnd "do binding name")
        | Option.some letKeyword =>
            match psTokenCursorExpectKind
                letKeyword.cursor
                PsTokenKind.identifier with
            | Except.error error => Except.error error
            | Except.ok name =>
                match psTokenCursorExpectText name.cursor ":" with
                | Except.error error => Except.error error
                | Except.ok afterColon =>
                    match parseTerm afterColon.cursor with
                    | Except.error error => Except.error error
                    | Except.ok binderType =>
                        match
                            psTokenCursorExpectText
                              binderType.cursor
                              "<-" with
                        | Except.error error => Except.error error
                        | Except.ok afterArrow =>
                            match parseTerm afterArrow.cursor with
                            | Except.error error => Except.error error
                            | Except.ok action =>
                                match
                                    psTokenCursorExpectText
                                      action.cursor
                                      ";" with
                                | Except.error error => Except.error error
                                | Except.ok afterSemi =>
                                    match
                                        smaller
                                          start
                                          afterSemi.cursor with
                                    | Except.error error => Except.error error
                                    | Except.ok body =>
                                        let nameSyntax : PsSyntaxName := {
                                          segments :=
                                            List.cons
                                              name.token.text
                                              List.nil
                                          span := name.token.span
                                        };
                                        let binderStop : PsSourcePos :=
                                          psLeanTermStop binderType.value;
                                        let binder : PsSyntaxBinderHead := {
                                          name := nameSyntax
                                          kind := PsSyntaxBinderKind.explicit
                                          span := {
                                            start := name.token.span.start
                                            stop := binderStop
                                          }
                                        };
                                        let span : PsSourceSpan := {
                                          start := start
                                          stop :=
                                            psLeanTermStop body.value
                                        };
                                        Except.ok {
                                          value :=
                                            psSyntaxCompilerBind
                                              binder
                                              binderType.value
                                              action.value
                                              body.value
                                              span
                                          cursor := body.cursor
                                        }
      else
        match psTokenCursorPeek cursor with
        | Option.none =>
            Except.error
              (PsParseError.unexpectedEnd "do statement")
        | Option.some token =>
            Except.error
              (PsParseError.expectedText
                "let or return"
                token.text
                token.span)

def psParseLeanRecordApplicationTailWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsSyntaxTerm ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun
        (_current : PsSyntaxTerm)
        (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsSyntaxTerm ->
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseLeanRecordApplicationTailWithFuel
          parseTerm
          remaining;
      fun
        (current : PsSyntaxTerm)
        (cursor : PsTokenCursor) =>
        if psTokenCursorAtText cursor "{" then
          match psParseRecordLiteral parseTerm cursor with
          | Except.error error => Except.error error
          | Except.ok argument =>
              let next :=
                psLeanApplicationWithArgument
                  current
                  argument.value;
              smaller
                next
                argument.cursor
        else
          Except.ok {
            value := current
            cursor := cursor
          }

def psParseLeanTermWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseLeanTermWithFuel remaining;
      fun (cursor : PsTokenCursor) =>
      if psTokenCursorAtText cursor "do" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "do statement")
        | Option.some keyword =>
            psParseLeanDoWithFuel
              (smaller)
              remaining
              keyword.token.span.start
              keyword.cursor
      else if psTokenCursorAtText cursor "match" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "match scrutinee")
        | Option.some keyword =>
            match smaller keyword.cursor with
            | Except.error error => Except.error error
            | Except.ok scrutinee =>
                match psTokenCursorExpectText scrutinee.cursor "with" with
                | Except.error error => Except.error error
                | Except.ok afterWith =>
                    match psParseLeanMatchAlternativesWithFuel
                        (smaller)
                        (psParseListLength afterWith.cursor.remaining)
                        afterWith.cursor
                        [] with
                    | Except.error error => Except.error error
                    | Except.ok alternatives =>
                        match alternatives.value with
                        | [] =>
                            match psTokenCursorPeek alternatives.cursor with
                            | Option.none =>
                                Except.error
                                  (PsParseError.unexpectedEnd "match alternative")
                            | Option.some token =>
                                Except.error
                                  (PsParseError.expectedText
                                    "|"
                                    token.text
                                    token.span)
                        | _ =>
                            let stop : PsSourcePos :=
                              match
                                  psParseListReverse
                                    alternatives.value with
                              | List.nil =>
                                  psLeanTermStop scrutinee.value
                              | List.cons alternative _ =>
                                  match alternative with
                                  | Prod.mk _ bodyAndSpan =>
                                      match bodyAndSpan with
                                      | Prod.mk _ span =>
                                          span.stop;
                            Except.ok {
                              value :=
                                PsSyntaxTerm.matchE
                                  scrutinee.value
                                  alternatives.value
                                  {
                                    start := keyword.token.span.start
                                    stop := stop
                                  }
                              cursor := alternatives.cursor
                            }
      else if psTokenCursorAtText cursor "if" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "if condition")
        | Option.some keyword =>
            match smaller keyword.cursor with
            | Except.error error => Except.error error
            | Except.ok condition =>
                match psTokenCursorExpectText condition.cursor "then" with
                | Except.error error => Except.error error
                | Except.ok afterThen =>
                    match smaller afterThen.cursor with
                    | Except.error error => Except.error error
                    | Except.ok thenBranch =>
                        match psTokenCursorExpectText thenBranch.cursor "else" with
                        | Except.error error => Except.error error
                        | Except.ok afterElse =>
                            match smaller afterElse.cursor with
                            | Except.error error => Except.error error
                            | Except.ok elseBranch =>
                                Except.ok {
                                  value :=
                                    PsSyntaxTerm.ifE
                                      condition.value
                                      thenBranch.value
                                      elseBranch.value
                                      {
                                        start := keyword.token.span.start
                                        stop := psLeanTermStop elseBranch.value
                                      }
                                  cursor := elseBranch.cursor
                                }
      else if psTokenCursorAtText cursor "let" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "let binding name")
        | Option.some keyword =>
            match psTokenCursorExpectKind
                keyword.cursor
                PsTokenKind.identifier with
            | Except.error error => Except.error error
            | Except.ok name =>
                let sourceName : PsSyntaxName := {
                  segments := [name.token.text]
                  span := name.token.span
                };
                if psTokenCursorAtText name.cursor ":" then
                  match psTokenCursorAdvance name.cursor with
                  | Option.none =>
                      Except.error
                        (PsParseError.unexpectedEnd "let binding type")
                  | Option.some afterColon =>
                      match smaller
                                                    afterColon.cursor with
                      | Except.error error => Except.error error
                      | Except.ok declaredType =>
                          match psTokenCursorExpectText
                              declaredType.cursor
                              ":=" with
                          | Except.error error => Except.error error
                          | Except.ok afterAssign =>
                              match smaller
                                                                    afterAssign.cursor with
                              | Except.error error => Except.error error
                              | Except.ok value =>
                                  match psTokenCursorExpectText
                                      value.cursor
                                      ";" with
                                  | Except.error error => Except.error error
                                  | Except.ok afterSemi =>
                                      match smaller
                                                                                    afterSemi.cursor with
                                      | Except.error error => Except.error error
                                      | Except.ok body =>
                                          Except.ok {
                                            value :=
                                              PsSyntaxTerm.letE
                                                sourceName
                                                (Option.some declaredType.value)
                                                value.value
                                                body.value
                                                {
                                                  start := keyword.token.span.start
                                                  stop :=
                                                    psLeanTermStop body.value
                                                }
                                            cursor := body.cursor
                                          }
                else
                  match psTokenCursorExpectText name.cursor ":=" with
                  | Except.error error => Except.error error
                  | Except.ok afterAssign =>
                      match smaller
                                                    afterAssign.cursor with
                      | Except.error error => Except.error error
                      | Except.ok value =>
                          match psTokenCursorExpectText value.cursor ";" with
                          | Except.error error => Except.error error
                          | Except.ok afterSemi =>
                              match smaller
                                                                    afterSemi.cursor with
                              | Except.error error => Except.error error
                              | Except.ok body =>
                                  Except.ok {
                                    value :=
                                      PsSyntaxTerm.letE
                                        sourceName
                                        Option.none
                                        value.value
                                        body.value
                                        {
                                          start := keyword.token.span.start
                                          stop :=
                                            psLeanTermStop body.value
                                        }
                                    cursor := body.cursor
                                  }
      else if psTokenCursorAtText cursor "fun" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "lambda binder")
        | Option.some keyword =>
            match psParseLeanBindersWithFuel
                (psParseListLength keyword.cursor.remaining)
                keyword.cursor
                [] with
            | Except.error error => Except.error error
            | Except.ok binders =>
                match binders.value with
                | [] =>
                    match psTokenCursorPeek binders.cursor with
                    | Option.none =>
                        Except.error
                          (PsParseError.unexpectedEnd "lambda binder")
                    | Option.some token =>
                        Except.error
                          (PsParseError.expectedText
                            "typed lambda binder"
                            token.text
                            token.span)
                | _ =>
                    match psTokenCursorExpectText binders.cursor "=>" with
                    | Except.error error => Except.error error
                    | Except.ok afterArrow =>
                        match smaller
                                                        afterArrow.cursor with
                        | Except.error error => Except.error error
                        | Except.ok body =>
                            Except.ok {
                              value :=
                                PsSyntaxTerm.lambda
                                  binders.value
                                  body.value
                                  {
                                    start := keyword.token.span.start
                                    stop := psLeanTermStop body.value
                                  }
                              cursor := body.cursor
                            }
      else if psTokenCursorAtText cursor "[" then
        match psTokenCursorAdvance cursor with
        | Option.none =>
            Except.error
              (PsParseError.unexpectedEnd "[")
        | Option.some opening =>
            psParseLeanListLiteral
              (smaller)
              opening
      else if psTokenCursorAtText cursor "{" then
        psParseRecordLiteral
          (smaller)
          cursor
      else if psTokenCursorAtText cursor "(" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "(")
        | Option.some opening =>
            if psTokenCursorAtText opening.cursor ")" then
              match psTokenCursorAdvance opening.cursor with
              | Option.none => Except.error (PsParseError.unexpectedEnd ")")
              | Option.some close =>
                  Except.ok {
                    value :=
                      PsSyntaxTerm.unit {
                        start := opening.token.span.start
                        stop := close.token.span.stop
                      }
                    cursor := close.cursor
                  }
            else
              match psParseLeanBinder cursor with
              | Except.ok binder =>
                  if psTokenCursorAtArrow binder.cursor then
                    psParseLeanDependentArrowTail
                      (smaller)
                      binder
                  else
                    match smaller opening.cursor with
                    | Except.error error => Except.error error
                    | Except.ok grouped =>
                        match psTokenCursorExpectText grouped.cursor ")" with
                        | Except.error error => Except.error error
                        | Except.ok close =>
                            psParseLeanArrowTail
                              (smaller)
                              {
                                value := grouped.value
                                cursor := close.cursor
                              }
              | Except.error _ =>
                  match smaller opening.cursor with
                  | Except.error error => Except.error error
                  | Except.ok grouped =>
                      match psTokenCursorExpectText grouped.cursor ")" with
                      | Except.error error => Except.error error
                      | Except.ok close =>
                          psParseLeanArrowTail
                            (smaller)
                            {
                              value := grouped.value
                              cursor := close.cursor
                            }
      else
        match psParseLeanProductWithFuel remaining cursor with
        | Except.error error => Except.error error
        | Except.ok domain =>
            match
                psParseLeanRecordApplicationTailWithFuel
                  (smaller)
                  remaining
                  domain.value
                  domain.cursor with
            | Except.error error => Except.error error
            | Except.ok withRecords =>
                psParseLeanArrowTail
                  (smaller)
                  withRecords

def psParseLeanTerm
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseLeanTermWithFuel (Nat.add (psParseListLength cursor.remaining) 1) cursor

def psParseLeanInductiveConstructorsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxInductiveConstructor ->
    Except PsParseError
      (PsParseResult (List PsSyntaxInductiveConstructor)) :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (constructorsRev : List PsSyntaxInductiveConstructor) =>
        Except.ok {
          value := psParseListReverse constructorsRev
          cursor := cursor
        }
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsSyntaxInductiveConstructor ->
          Except PsParseError
            (PsParseResult (List PsSyntaxInductiveConstructor)) :=
        psParseLeanInductiveConstructorsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (constructorsRev : List PsSyntaxInductiveConstructor) =>
        if psTokenCursorAtText cursor "|" then
          match psTokenCursorAdvance cursor with
          | Option.none =>
              Except.error
                (PsParseError.unexpectedEnd "inductive constructor")
          | Option.some bar =>
              match psTokenCursorExpectKind
                  bar.cursor
                  PsTokenKind.identifier with
              | Except.error error => Except.error error
              | Except.ok name =>
                  match psParseLeanBindersWithFuel
                      (psParseListLength name.cursor.remaining)
                      name.cursor
                      [] with
                  | Except.error error => Except.error error
                  | Except.ok fields =>
                      let sourceName : PsSyntaxName := {
                        segments := List.cons name.token.text List.nil
                        span := name.token.span
                      };
                      let stop : PsSourcePos :=
                        match psParseListReverse fields.value with
                        | List.nil => name.token.span.stop
                        | List.cons pair _ => pair.fst.span.stop;
                      let constructor : PsSyntaxInductiveConstructor := {
                        name := sourceName
                        fields := fields.value
                        span := {
                          start := bar.token.span.start
                          stop := stop
                        }
                      };
                      smaller
                        fields.cursor
                        (List.cons constructor constructorsRev)
        else
          Except.ok {
            value := psParseListReverse constructorsRev
            cursor := cursor
          }

def psLeanTopLevelDeclarationToken (token : PsToken) : Bool :=
  if psStringEq token.text "def" then
    true
  else if psStringEq token.text "partial" then
    true
  else if psStringEq token.text "theorem" then
    true
  else if psStringEq token.text "inductive" then
    true
  else if psStringEq token.text "structure" then
    true
  else
    psStringEq token.text "import"

def psSplitTokensThroughLine
    (line : Nat)
    (tokens : List PsToken) :
    Prod (List PsToken) (List PsToken) :=
  match tokens with
  | List.nil =>
      Prod.mk List.nil List.nil
  | List.cons token rest =>
      if
          psTokenKindEq
            token.kind
            PsTokenKind.endOfInput then
        Prod.mk
          List.nil
          (List.cons token rest)
      else if Nat.blt line token.span.start.line then
        Prod.mk
          List.nil
          (List.cons token rest)
      else
        let tail :=
          psSplitTokensThroughLine line rest;
        Prod.mk
          (List.cons token tail.fst)
          tail.snd

def psParseLeanStructureField
    (cursor : PsTokenCursor) :
    Except PsParseError
      (PsParseResult (PsSyntaxBinderHead × PsSyntaxTerm)) :=
  if psTokenCursorAtBinderStart cursor then
    psParseLeanBinder cursor
  else
    match psTokenCursorExpectKind cursor PsTokenKind.identifier with
    | Except.error error => Except.error error
    | Except.ok name =>
        match psTokenCursorExpectText name.cursor ":" with
        | Except.error error => Except.error error
        | Except.ok afterColon =>
            match psTokenCursorPeek afterColon.cursor with
            | Option.none =>
                Except.error
                  (PsParseError.unexpectedEnd "structure field type")
            | Option.some firstType =>
                let split :=
                  psSplitTokensThroughLine
                    firstType.span.start.line
                    afterColon.cursor.remaining;
                match psParseLeanTerm (psLeanTokenCursor split.fst) with
                | Except.error error => Except.error error
                | Except.ok type =>
                    if psTokenCursorDone type.cursor then
                      let fieldName : PsSyntaxName := {
                        segments :=
                          List.cons
                            name.token.text
                            List.nil
                        span := name.token.span
                      };
                      let head : PsSyntaxBinderHead := {
                        name := fieldName
                        kind := PsSyntaxBinderKind.explicit
                        span := {
                          start := name.token.span.start
                          stop := psLeanTermStop type.value
                        }
                      };
                      Except.ok {
                        value := Prod.mk head type.value
                        cursor := psLeanTokenCursor split.snd
                      }
                    else
                      match psTokenCursorPeek type.cursor with
                      | Option.none =>
                          Except.error
                            (PsParseError.unexpectedEnd
                              "end of structure field")
                      | Option.some token =>
                          Except.error
                            (PsParseError.expectedText
                              "end of structure field"
                              token.text
                              token.span)

def psParseLeanStructureFieldsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List (PsSyntaxBinderHead × PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult
        (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (fieldsRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) =>
        Except.ok {
          value := psParseListReverse fieldsRev
          cursor := cursor
        }
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List (PsSyntaxBinderHead × PsSyntaxTerm) ->
          Except PsParseError
            (PsParseResult
              (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
        psParseLeanStructureFieldsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (fieldsRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) =>
        match psTokenCursorPeek cursor with
        | Option.none =>
            Except.ok {
              value := psParseListReverse fieldsRev
              cursor := cursor
            }
        | Option.some token =>
            if
                psTokenKindEq
                  token.kind
                  PsTokenKind.endOfInput then
              Except.ok {
                value := psParseListReverse fieldsRev
                cursor := cursor
              }
            else if psLeanTopLevelDeclarationToken token then
              Except.ok {
                value := psParseListReverse fieldsRev
                cursor := cursor
              }
            else
              match psParseLeanStructureField cursor with
              | Except.error error => Except.error error
              | Except.ok field =>
                  smaller
                    field.cursor
                    (List.cons field.value fieldsRev)

def psParseLeanStructureDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorExpectText cursor "structure" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseSyntaxName keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psParseLeanBindersWithFuel
              (psParseListLength name.cursor.remaining)
              name.cursor
              [] with
          | Except.error error => Except.error error
          | Except.ok params =>
              match psTokenCursorExpectText params.cursor "where" with
              | Except.error error => Except.error error
              | Except.ok afterWhere =>
                  match
                      psParseLeanStructureFieldsWithFuel
                        (psParseListLength afterWhere.cursor.remaining)
                        afterWhere.cursor
                        [] with
                  | Except.error error => Except.error error
                  | Except.ok fields =>
                      match psParseListReverse fields.value with
                      | [] =>
                          match psTokenCursorPeek fields.cursor with
                          | Option.none =>
                              Except.error
                                (PsParseError.unexpectedEnd
                                  "structure field")
                          | Option.some token =>
                              Except.error
                                (PsParseError.expectedText
                                  "structure field"
                                  token.text
                                  token.span)
                      | List.cons lastField _ =>
                          match lastField with
                          | Prod.mk lastHead _ =>
                              Except.ok {
                                value :=
                                  PsSyntaxDeclaration.structureDecl
                                    name.value
                                    params.value
                                    fields.value
                                    {
                                      start := keyword.token.span.start
                                      stop := lastHead.span.stop
                                    }
                                cursor := fields.cursor
                              }

def psParseLeanInductiveDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorExpectText cursor "inductive" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseSyntaxName keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psParseLeanBindersWithFuel
              (psParseListLength name.cursor.remaining)
              name.cursor
              [] with
          | Except.error error => Except.error error
          | Except.ok params =>
              let parseAfterResult :
                  Option PsSyntaxTerm ->
                  PsTokenCursor ->
                  Except PsParseError
                    (PsParseResult PsSyntaxDeclaration) :=
                fun
                  (resultType : Option PsSyntaxTerm)
                  (afterResult : PsTokenCursor) =>
                match psTokenCursorExpectText afterResult "where" with
                | Except.error error => Except.error error
                | Except.ok afterWhere =>
                    match psParseLeanInductiveConstructorsWithFuel
                        (psParseListLength afterWhere.cursor.remaining)
                        afterWhere.cursor
                        [] with
                    | Except.error error => Except.error error
                    | Except.ok constructors =>
                        match constructors.value with
                        | [] =>
                            match psTokenCursorPeek constructors.cursor with
                            | Option.none =>
                                Except.error
                                  (PsParseError.unexpectedEnd
                                    "inductive constructor")
                            | Option.some token =>
                                Except.error
                                  (PsParseError.expectedText
                                    "|"
                                    token.text
                                    token.span)
                        | _ =>
                            let stop : PsSourcePos :=
                              match psParseListReverse constructors.value with
                              | [] => name.value.span.stop
                              | List.cons constructor _ =>
                                  constructor.span.stop;
                            Except.ok {
                              value :=
                                PsSyntaxDeclaration.inductiveDecl
                                  name.value
                                  params.value
                                  resultType
                                  constructors.value
                                  {
                                    start := keyword.token.span.start
                                    stop := stop
                                  }
                              cursor := constructors.cursor
                            };
              if psTokenCursorAtText params.cursor ":" then
                match psTokenCursorAdvance params.cursor with
                | Option.none =>
                    Except.error
                      (PsParseError.unexpectedEnd "inductive result type")
                | Option.some afterColon =>
                    match psParseLeanTerm afterColon.cursor with
                    | Except.error error => Except.error error
                    | Except.ok resultType =>
                        parseAfterResult
                          (Option.some resultType.value)
                          resultType.cursor
              else
                parseAfterResult Option.none params.cursor

structure PsLeanEquationClause where
  patterns : List PsSyntaxPattern
  body : PsSyntaxTerm
  span : PsSourceSpan

def psParseLeanEquationPatternsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxPattern ->
    Except PsParseError
      (PsParseResult (List PsSyntaxPattern)) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_patternsRev : List PsSyntaxPattern) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsSyntaxPattern ->
          Except PsParseError
            (PsParseResult (List PsSyntaxPattern)) :=
        psParseLeanEquationPatternsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (patternsRev : List PsSyntaxPattern) =>
        match psParseLeanPattern cursor with
        | Except.error error => Except.error error
        | Except.ok pattern =>
            let nextPatterns := List.cons pattern.value patternsRev;
            if psTokenCursorAtText pattern.cursor "," then
              match psTokenCursorAdvance pattern.cursor with
              | Option.none =>
                  Except.error
                    (PsParseError.unexpectedEnd "equation pattern")
              | Option.some afterComma =>
                  smaller
                    afterComma.cursor
                    nextPatterns
            else
              Except.ok {
                value := psParseListReverse nextPatterns
                cursor := pattern.cursor
              }

def psParseLeanEquationClausesWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsTokenCursor ->
    List PsLeanEquationClause ->
    Except PsParseError
      (PsParseResult (List PsLeanEquationClause)) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_clausesRev : List PsLeanEquationClause) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsLeanEquationClause ->
          Except PsParseError
            (PsParseResult (List PsLeanEquationClause)) :=
        psParseLeanEquationClausesWithFuel
          parseTerm
          remaining;
      fun
        (cursor : PsTokenCursor)
        (clausesRev : List PsLeanEquationClause) =>
        if psLeanBoolNot (psTokenCursorAtText cursor "|") then
          Except.ok {
            value := psParseListReverse clausesRev
            cursor := cursor
          }
        else
          match psTokenCursorAdvance cursor with
          | Option.none =>
              Except.error
                (PsParseError.unexpectedEnd "equation pattern")
          | Option.some bar =>
              match
                  psParseLeanEquationPatternsWithFuel
                    (psParseListLength bar.cursor.remaining)
                    bar.cursor
                    [] with
              | Except.error error => Except.error error
              | Except.ok patterns =>
                  match
                      psTokenCursorExpectText
                        patterns.cursor
                        "=>" with
                  | Except.error error => Except.error error
                  | Except.ok afterArrow =>
                      match parseTerm afterArrow.cursor with
                      | Except.error error => Except.error error
                      | Except.ok body =>
                          let clause : PsLeanEquationClause := {
                            patterns := patterns.value
                            body := body.value
                            span := {
                              start := bar.token.span.start
                              stop := psLeanTermStop body.value
                            }
                          };
                          smaller
                            body.cursor
                            (List.cons clause clausesRev)

def psLeanPatternIsWildcard
    (pattern : PsSyntaxPattern) : Bool :=
  match pattern with
  | .wildcard _ => true
  | _ => false

def psLeanStringListEq
    (left : List String) :
    List String -> Bool :=
  match left with
  | List.nil =>
      fun (right : List String) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller : List String -> Bool :=
        psLeanStringListEq leftTail;
      fun (right : List String) =>
        match right with
        | List.nil => false
        | List.cons rightHead rightTail =>
            if psStringEq leftHead rightHead then
              smaller rightTail
            else
              false

def psLeanBoolEq (left : Bool) (right : Bool) : Bool :=
  match left with
  | true =>
      match right with
      | true => true
      | false => false
  | false =>
      match right with
      | true => false
      | false => true

def psLeanPatternHeadEq
    (left : PsSyntaxPattern)
    (right : PsSyntaxPattern) : Bool :=
  match left with
  | .bool leftValue _ =>
      match right with
      | .bool rightValue _ =>
          psLeanBoolEq leftValue rightValue
      | _ => false
  | .wildcard _ =>
      match right with
      | .wildcard _ => true
      | _ => false
  | .constructor leftName _ _ =>
      match right with
      | .constructor rightName _ _ =>
          psLeanStringListEq
            leftName.segments
            rightName.segments
      | _ => false

def psLeanPatternListContainsHead
    (patterns : List PsSyntaxPattern)
    (target : PsSyntaxPattern) : Bool :=
  match patterns with
  | List.nil => false
  | List.cons pattern rest =>
      if psLeanPatternHeadEq pattern target then
        true
      else
        psLeanPatternListContainsHead
          rest
          target

def psLeanEquationHeadPatternsAcc
    (clauses : List PsLeanEquationClause) :
    List PsSyntaxPattern ->
    List PsSyntaxPattern :=
  match clauses with
  | [] =>
      fun (patternsRev : List PsSyntaxPattern) =>
        psParseListReverse patternsRev
  | List.cons clause rest =>
      let smaller :
          List PsSyntaxPattern ->
          List PsSyntaxPattern :=
        psLeanEquationHeadPatternsAcc rest;
      fun (patternsRev : List PsSyntaxPattern) =>
        match clause.patterns with
        | [] =>
            smaller patternsRev
        | List.cons pattern _ =>
            if
                psLeanPatternListContainsHead
                  patternsRev
                  pattern then
              smaller patternsRev
            else
              smaller (List.cons pattern patternsRev)

def psLeanEquationHeadPatterns
    (clauses : List PsLeanEquationClause) :
    List PsSyntaxPattern :=
  psLeanEquationHeadPatternsAcc clauses []

def psLeanEquationClauseForBranch
    (branch : PsSyntaxPattern)
    (clause : PsLeanEquationClause) :
    Option PsLeanEquationClause :=
  match clause.patterns with
  | [] => Option.none
  | List.cons pattern rest =>
      let applicable :=
        if psLeanPatternIsWildcard branch then
          psLeanPatternIsWildcard pattern
        else
          if psLeanPatternIsWildcard pattern then
            true
          else
            psLeanPatternHeadEq pattern branch;
      if applicable then
        Option.some {
          patterns := rest
          body := clause.body
          span := clause.span
        }
      else
        Option.none

def psLeanEquationClausesForBranchAcc
    (branch : PsSyntaxPattern)
    (clauses : List PsLeanEquationClause) :
    List PsLeanEquationClause ->
    List PsLeanEquationClause :=
  match clauses with
  | [] =>
      fun (resultRev : List PsLeanEquationClause) =>
        psParseListReverse resultRev
  | List.cons clause rest =>
      let smaller :
          List PsLeanEquationClause ->
          List PsLeanEquationClause :=
        psLeanEquationClausesForBranchAcc
          branch
          rest;
      fun (resultRev : List PsLeanEquationClause) =>
        match
            psLeanEquationClauseForBranch
              branch
              clause with
        | Option.none =>
            smaller resultRev
        | Option.some stripped =>
            smaller (List.cons stripped resultRev)

def psLeanEquationClausesForBranch
    (branch : PsSyntaxPattern)
    (clauses : List PsLeanEquationClause) :
    List PsLeanEquationClause :=
  psLeanEquationClausesForBranchAcc branch clauses []

def psLeanFirstCompletedEquation
    (clauses : List PsLeanEquationClause) :
    Option PsLeanEquationClause :=
  match clauses with
  | [] => Option.none
  | List.cons clause rest =>
      if clause.patterns.isEmpty then
        Option.some clause
      else
        psLeanFirstCompletedEquation rest

partial def psLeanLowerEquationClauses
    (arguments : List PsSyntaxName)
    (clauses : List PsLeanEquationClause) :
    Option PsSyntaxTerm :=
  match arguments with
  | [] =>
      match psLeanFirstCompletedEquation clauses with
      | Option.none => Option.none
      | Option.some clause => Option.some clause.body
  | List.cons argument rest =>
      let patterns :=
        psLeanEquationHeadPatterns clauses;
      if patterns.isEmpty then
        Option.none
      else
        let lowerAlternative :=
          fun (pattern : PsSyntaxPattern) =>
            let branchClauses :=
              psLeanEquationClausesForBranch
                pattern
                clauses;
            match
                psLeanLowerEquationClauses
                  rest
                  branchClauses with
            | Option.none => Option.none
            | Option.some body =>
                Option.some
                  (Prod.mk
                    pattern
                    (Prod.mk
                      body
                      (psSyntaxSpanJoin
                        (psSyntaxPatternSpan pattern)
                        (psSyntaxTermSpan body))));
        match patterns.mapM lowerAlternative with
        | Option.none => Option.none
        | Option.some alternatives =>
            match psParseListReverse alternatives with
            | [] => Option.none
            | List.cons alternative _ =>
                match alternative with
                | Prod.mk _ bodyAndSpan =>
                    match bodyAndSpan with
                    | Prod.mk body _ =>
                        let matchSpan : PsSourceSpan := {
                          start := argument.span.start
                          stop := psLeanTermStop body
                        };
                        Option.some
                          (PsSyntaxTerm.matchE
                            (PsSyntaxTerm.reference argument)
                            alternatives
                            matchSpan)

def psLeanFlattenForallBinders
    (type : PsSyntaxTerm) :
    Prod (List (Prod PsSyntaxBinderHead PsSyntaxTerm)) PsSyntaxTerm :=
  match type with
  | .forallE binders body _ =>
      let tail := psLeanFlattenForallBinders body;
      Prod.mk (psParseListAppend binders tail.fst) tail.snd
  | _ => Prod.mk List.nil type

def psLeanEquationBinderName
    (index : Nat)
    (head : PsSyntaxBinderHead) :
    PsSyntaxName :=
  match head.name.segments with
  | List.cons segment rest =>
      match rest with
      | List.nil =>
          if psStringEq segment "_" then
            let generated :=
              String.Internal.append
                "_eq"
                (psNatToString index);
            {
              segments :=
                List.cons generated List.nil
              span := head.name.span
            }
          else
            head.name
      | _ => head.name
  | _ => head.name

def psLeanPrepareEquationBindersAcc
    (remaining : Nat)
    (index : Nat)
    (available :
      List
        (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (bindersRev :
      List
        (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (namesRev : List PsSyntaxName) :
    Option
      (Prod
        (List
          (Prod PsSyntaxBinderHead PsSyntaxTerm))
        (List PsSyntaxName)) :=
  if Nat.beq remaining 0 then
    Option.some (Prod.mk (psParseListReverse bindersRev) (psParseListReverse namesRev))
  else
    match available with
    | [] => Option.none
    | List.cons binder rest =>
        let name :=
          psLeanEquationBinderName index binder.fst;
        let head : PsSyntaxBinderHead := {
          name := name
          kind := binder.fst.kind
          span := binder.fst.span
        };
        psLeanPrepareEquationBindersAcc
          (Nat.sub remaining 1)
          (Nat.add index 1)
          rest
          (List.cons (Prod.mk head binder.snd) bindersRev)
          (List.cons name namesRev)

def psLeanEquationClausesHaveArity
    (arity : Nat)
    (clauses : List PsLeanEquationClause) : Bool :=
  match clauses with
  | List.nil => true
  | List.cons clause rest =>
      if
          Nat.beq
            (psParseListLength clause.patterns)
            arity then
        psLeanEquationClausesHaveArity
          arity
          rest
      else
        false

def psLeanEquationArity
    (clauses : List PsLeanEquationClause) :
    Option Nat :=
  match clauses with
  | List.nil => Option.none
  | List.cons clause rest =>
      let arity :=
        psParseListLength clause.patterns;
      if psLeanEquationClausesHaveArity arity rest then
        Option.some arity
      else
        Option.none

def psLeanLowerEquationValue
    (type : PsSyntaxTerm)
    (clauses : List PsLeanEquationClause) :
    Option PsSyntaxTerm :=
  match psLeanEquationArity clauses with
  | Option.none => Option.none
  | Option.some arity =>
      let flattened :=
        psLeanFlattenForallBinders type;
      match
          psLeanPrepareEquationBindersAcc
            arity
            0
            flattened.fst
            []
            [] with
      | Option.none => Option.none
      | Option.some prepared =>
          match
              psLeanLowerEquationClauses
                prepared.snd
                clauses with
          | Option.none => Option.none
          | Option.some body =>
              match clauses with
              | [] => Option.none
              | List.cons first _ =>
                  let lambdaSpan : PsSourceSpan := {
                    start := first.span.start
                    stop := psLeanTermStop body
                  };
                  Option.some
                    (PsSyntaxTerm.lambda
                      prepared.fst
                      body
                      lambdaSpan)

def psFinishLeanValueDeclaration
    (keyword : PsToken)
    (isPartial : Bool)
    (isDefinition : Bool)
    (name : PsSyntaxName)
    (binders :
      List
        (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (type : PsSyntaxTerm)
    (value : PsSyntaxTerm)
    (cursor : PsTokenCursor) :
    PsParseResult PsSyntaxDeclaration :=
  let span := {
    start := keyword.span.start
    stop := psLeanTermStop value
  };
  let declaration :=
    if isPartial then
      PsSyntaxDeclaration.partialDefinition
        name binders type value span
    else if isDefinition then
      PsSyntaxDeclaration.definition
        name binders type value span
    else
      PsSyntaxDeclaration.theoremDecl
        name binders type value span;
  {
    value := declaration
    cursor := cursor
  }

def psParseLeanDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorPeek cursor with
  | Option.none => Except.error (PsParseError.unexpectedEnd "declaration")
  | Option.some keyword =>
      if psStringEq keyword.text "inductive" then
        psParseLeanInductiveDeclaration cursor
      else if psStringEq keyword.text "structure" then
        psParseLeanStructureDeclaration cursor
      else
        let isPartial := psStringEq keyword.text "partial";
        let isDefinition := psStringEq keyword.text "def";
        let isTheorem := psStringEq keyword.text "theorem";
        if
            if isPartial then
              false
            else if isDefinition then
              false
            else
              psLeanBoolNot isTheorem then
          Except.error
            (PsParseError.expectedText
              "partial def, def, theorem, inductive, or structure"
              keyword.text
              keyword.span)
        else
          let afterKind :=
            if isPartial then
              match psTokenCursorAdvance cursor with
              | Option.none =>
                  Except.error
                    (PsParseError.unexpectedEnd "def after partial")
              | Option.some afterPartial =>
                  match psTokenCursorExpectText afterPartial.cursor "def" with
                  | Except.error error => Except.error error
                  | Except.ok afterDef => Except.ok afterDef.cursor
            else
              match psTokenCursorAdvance cursor with
              | Option.none =>
                  Except.error
                    (PsParseError.unexpectedEnd "declaration name")
              | Option.some afterKeyword => Except.ok afterKeyword.cursor;
          match afterKind with
          | Except.error error => Except.error error
          | Except.ok afterKeyword =>
              match psParseSyntaxName afterKeyword with
              | Except.error error => Except.error error
              | Except.ok name =>
                  match psParseLeanBindersWithFuel
                      (psParseListLength name.cursor.remaining)
                      name.cursor
                      [] with
                  | Except.error error => Except.error error
                  | Except.ok binders =>
                      match psTokenCursorExpectText binders.cursor ":" with
                      | Except.error error => Except.error error
                      | Except.ok afterColon =>
                          match psParseLeanTerm afterColon.cursor with
                          | Except.error error => Except.error error
                          | Except.ok type =>
                              if psTokenCursorAtText type.cursor ":=" then
                                match psTokenCursorAdvance type.cursor with
                                | Option.none =>
                                    Except.error
                                      (PsParseError.unexpectedEnd
                                        "declaration value")
                                | Option.some afterAssign =>
                                    match
                                        psParseLeanTerm
                                          afterAssign.cursor with
                                    | Except.error error =>
                                        Except.error error
                                    | Except.ok value =>
                                        Except.ok
                                          (psFinishLeanValueDeclaration
                                            keyword
                                            isPartial
                                            isDefinition
                                            name.value
                                            binders.value
                                            type.value
                                            value.value
                                            value.cursor)
                              else if psTokenCursorAtText type.cursor "|" then
                                match
                                    psParseLeanEquationClausesWithFuel
                                      psParseLeanTerm
                                      (psParseListLength type.cursor.remaining)
                                      type.cursor
                                      [] with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok clauses =>
                                    match
                                        psLeanLowerEquationValue
                                          type.value
                                          clauses.value with
                                    | Option.none =>
                                        match psTokenCursorPeek type.cursor with
                                        | Option.none =>
                                            Except.error
                                              (PsParseError.unexpectedEnd
                                                "supported equation clauses")
                                        | Option.some token =>
                                            Except.error
                                              (PsParseError.expectedText
                                                "supported equation clauses"
                                                token.text
                                                token.span)
                                    | Option.some value =>
                                        Except.ok
                                          (psFinishLeanValueDeclaration
                                            keyword
                                            isPartial
                                            isDefinition
                                            name.value
                                            binders.value
                                            type.value
                                            value
                                            clauses.cursor)
                              else
                                match psTokenCursorPeek type.cursor with
                                | Option.none =>
                                    Except.error
                                      (PsParseError.unexpectedEnd
                                        ":= or equation clause")
                                | Option.some token =>
                                    Except.error
                                      (PsParseError.expectedText
                                        ":= or equation clause"
                                        token.text
                                        token.span)


def psParseLeanImportsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxImport ->
    Except PsParseError (PsParseResult (List PsSyntaxImport)) :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (importsRev : List PsSyntaxImport) =>
        Except.ok {
          value := psParseListReverse importsRev
          cursor := cursor
        }
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsSyntaxImport ->
          Except PsParseError (PsParseResult (List PsSyntaxImport)) :=
        psParseLeanImportsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (importsRev : List PsSyntaxImport) =>
        if psTokenCursorAtText cursor "import" then
          match psParseLeanImport cursor with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              smaller
                parsed.cursor
                (List.cons parsed.value importsRev)
        else
          Except.ok {
            value := psParseListReverse importsRev
            cursor := cursor
          }

def psParseLeanDeclarationsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxDeclaration ->
    Except PsParseError (PsParseResult (List PsSyntaxDeclaration)) :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (declarationsRev : List PsSyntaxDeclaration) =>
        if psTokenCursorDone cursor then
          Except.ok {
            value := psParseListReverse declarationsRev
            cursor := cursor
          }
        else
          match psTokenCursorPeek cursor with
          | Option.none => Except.ok {
              value := psParseListReverse declarationsRev
              cursor := cursor
            }
          | Option.some token =>
              Except.error
                (PsParseError.expectedText
                  "end of input"
                  token.text
                  token.span)
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsSyntaxDeclaration ->
          Except PsParseError (PsParseResult (List PsSyntaxDeclaration)) :=
        psParseLeanDeclarationsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (declarationsRev : List PsSyntaxDeclaration) =>
        if psTokenCursorDone cursor then
          Except.ok {
            value := psParseListReverse declarationsRev
            cursor := cursor
          }
        else
          match psParseLeanDeclaration cursor with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              smaller
                parsed.cursor
                (List.cons parsed.value declarationsRev)

def psParseLeanTokens
    (tokens : List PsToken) :
    Except PsParseError PsSyntaxModule :=
  let cursor := psTokenCursorFromTokens tokens;
  match psParseLeanImportsWithFuel (psParseListLength tokens) cursor [] with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match psParseLeanDeclarationsWithFuel
          (psParseListLength tokens)
          imports.cursor
          [] with
      | Except.error error => Except.error error
      | Except.ok declarations =>
          Except.ok {
            imports := imports.value
            declarations := declarations.value
          }

inductive PsLeanFrontendError where
  | lex (error : PsLexError)
  | parse (error : PsParseError)

def psParseLeanSource
    (source : String) :
    Except PsLeanFrontendError PsSyntaxModule :=
  match psLex source with
  | Except.error error => Except.error (PsLeanFrontendError.lex error)
  | Except.ok tokens =>
      match psParseLeanTokens tokens with
      | Except.error error => Except.error (PsLeanFrontendError.parse error)
      | Except.ok module => Except.ok module
