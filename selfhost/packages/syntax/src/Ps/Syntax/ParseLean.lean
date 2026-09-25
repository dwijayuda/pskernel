import Ps.Syntax.Lexer
import Ps.Syntax.ParseCommon

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
          | none =>
              Except.error
                (PsParseError.unexpectedEnd "]")
          | some close =>
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
                | none =>
                    Except.error
                      (PsParseError.unexpectedEnd
                        "list element")
                | some afterComma =>
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
                | none =>
                    Except.error
                      (PsParseError.unexpectedEnd "]")
                | some token =>
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
  | none => false
  | some token =>
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
          | none => Except.error (PsParseError.unexpectedEnd "(")
          | some opening =>
              if psTokenCursorAtText opening.cursor ")" then
                match psTokenCursorAdvance opening.cursor with
                | none => Except.error (PsParseError.unexpectedEnd ")")
                | some close =>
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
          | none =>
              Except.error
                (PsParseError.unexpectedEnd "[")
          | some opening =>
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
              | none =>
                  Except.error
                    (PsParseError.unexpectedEnd "product type")
              | some afterProduct =>
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
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (namesRev : List PsSyntaxName) :
    Except PsParseError
      (PsParseResult (List PsSyntaxName)) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
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
            | none =>
                Except.error
                  (PsParseError.unexpectedEnd ":")
            | some next =>
                if
                    psTokenKindEq
                      next.kind
                      PsTokenKind.identifier then
                  psParseLeanBinderNamesWithFuel
                    remaining
                    name.cursor
                    nextNames
                else
                  Except.error
                    (PsParseError.expectedText
                      ":"
                      next.text
                      next.span)

def psLeanBinderPairsFromNames
    (kind : PsSyntaxBinderKind)
    (span : PsSourceSpan)
    (type : PsSyntaxTerm) :
    List PsSyntaxName ->
    List
      (Prod PsSyntaxBinderHead PsSyntaxTerm)
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
        (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (bindersRev :
      List
        (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    List
      (Prod PsSyntaxBinderHead PsSyntaxTerm) :=
  match group with
  | List.nil => bindersRev
  | List.cons binder rest =>
      psLeanPrependBinderGroupReverse
        rest
        (List.cons binder bindersRev)

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
                        segments := [name.token.text]
                        span := name.token.span
                      }
                      let binder : PsSyntaxBinderHead := {
                        name := binderName
                        kind := opening.kind
                        span := closing.value
                      }
                      Except.ok {
                        value := (binder, type.value)
                        cursor := closing.cursor
                      }

def psParseLeanBindersWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (bindersRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsParseError
      (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      Except.ok { value := psParseListReverse bindersRev, cursor := cursor }
  | remaining + 1 =>
      if psTokenCursorAtBinderStart cursor then
        match psParseLeanBinderGroup cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseLeanBindersWithFuel
              remaining
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
                  [(psSyntaxAnonymousExplicitBinder domainSpan, domain.value)]
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
            Except.ok {
              value :=
                PsSyntaxTerm.forallE
                  [binder.value]
                  codomain.value
                  {
                    start := binder.value.1.span.start
                    stop := (psSyntaxTermSpan codomain.value).stop
                  }
              cursor := codomain.cursor
            }
  else
    Except.error
      (PsParseError.expectedText
        "->"
        (match psTokenCursorPeek binder.cursor with
         | none => ""
         | some token => token.text)
        (match psTokenCursorPeek binder.cursor with
         | none => binder.value.1.span
         | some token => token.span))

def psLeanPatternBinderName
    (token : PsToken)
    (fallback : String) : PsSyntaxName :=
  {
    segments :=
      [if token.text == "_" then fallback else token.text]
    span := token.span
  }

def psParseLeanListPattern
    (cursor : PsTokenCursor) :
    Option
      (Except
        PsParseError
        (PsParseResult PsSyntaxPattern)) :=
  match cursor.remaining with
  | List.nil => none
  | List.cons first afterFirst =>
      match afterFirst with
      | List.nil => none
      | List.cons second afterSecond =>
          if first.text == "[" && second.text == "]" then
            let span :=
              psSyntaxSpanJoin first.span second.span
            let name : PsSyntaxName := {
              segments :=
                List.cons
                  "List"
                  (List.cons "nil" List.nil)
              span := span
            }
            some
              (Except.ok {
                value :=
                  PsSyntaxPattern.constructor
                    name
                    List.nil
                    span
                cursor := { remaining := afterSecond }
              })
          else if second.text == "::" then
            match afterSecond with
            | List.nil => none
            | List.cons third rest =>
                if
                    psTokenKindEq
                      first.kind
                      PsTokenKind.identifier
                      && psTokenKindEq
                        third.kind
                        PsTokenKind.identifier then
                  let span :=
                    psSyntaxSpanJoin first.span third.span
                  let name : PsSyntaxName := {
                    segments :=
                      List.cons
                        "List"
                        (List.cons "cons" List.nil)
                    span := span
                  }
                  let headBinder :=
                    psLeanPatternBinderName
                      first
                      "_listHead"
                  let tailBinder :=
                    psLeanPatternBinderName
                      third
                      "_listTail"
                  some
                    (Except.ok {
                      value :=
                        PsSyntaxPattern.constructor
                          name
                          (List.cons
                            headBinder
                            (List.cons
                              tailBinder
                              List.nil))
                          span
                      cursor := { remaining := rest }
                    })
                else
                  none
          else
            none

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
  | List.nil => none
  | List.cons first rest =>
      if
          psTokenKindEq
            first.kind
            PsTokenKind.natural
            && first.text == "0" then
        some
          (Except.ok {
            value :=
              PsSyntaxPattern.constructor
                (psLeanNatPatternName
                  "zero"
                  first.span)
                List.nil
                first.span
            cursor := { remaining := rest }
          })
      else
        match rest with
        | List.nil => none
        | List.cons plus afterPlus =>
            match afterPlus with
            | List.nil => none
            | List.cons one afterOne =>
                if
                    psTokenKindEq
                      first.kind
                      PsTokenKind.identifier
                      && plus.text == "+"
                      && psTokenKindEq
                        one.kind
                        PsTokenKind.natural
                      && one.text == "1" then
                  let span :=
                    psSyntaxSpanJoin
                      first.span
                      one.span
                  let binder :=
                    psLeanPatternBinderName
                      first
                      "_natPred"
                  some
                    (Except.ok {
                      value :=
                        PsSyntaxPattern.constructor
                          (psLeanNatPatternName
                            "succ"
                            span)
                          (List.cons binder List.nil)
                          span
                      cursor := {
                        remaining := afterOne
                      }
                    })
                else
                  none

def psParseLeanPattern
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxPattern) :=
  match psParseLeanNatPattern cursor with
  | some result => result
  | none =>
      match psParseLeanListPattern cursor with
      | some result => result
      | none => psParseBasicPattern cursor

def psParseLeanMatchAlternativesAtColumnWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (branchColumn : Nat)
    (previousBranchLine : Nat)
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (alternativesRev :
      List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan)) :
    Except PsParseError
      (PsParseResult
        (List (PsSyntaxPattern × PsSyntaxTerm × PsSourceSpan))) :=
  match fuel with
  | 0 =>
      Except.ok {
        value := psParseListReverse alternativesRev
        cursor := cursor
      }
  | remaining + 1 =>
      match psTokenCursorPeek cursor with
      | none =>
          Except.ok {
            value := psParseListReverse alternativesRev
            cursor := cursor
          }
      | some token =>
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
            | none =>
                Except.error (PsParseError.unexpectedEnd "match pattern")
            | some bar =>
                match psParseLeanPattern bar.cursor with
                | Except.error error => Except.error error
                | Except.ok pattern =>
                    match psTokenCursorExpectText pattern.cursor "=>" with
                    | Except.error error => Except.error error
                    | Except.ok afterArrow =>
                        match parseTerm afterArrow.cursor with
                        | Except.error error => Except.error error
                        | Except.ok body =>
                            let span := {
                              start := bar.token.span.start
                              stop := (psSyntaxTermSpan body.value).stop
                            }
                            psParseLeanMatchAlternativesAtColumnWithFuel
                              parseTerm
                              branchColumn
                              bar.token.span.start.line
                              remaining
                              body.cursor
                              ((pattern.value, body.value, span) :: alternativesRev)
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
  | none =>
      Except.ok {
        value := psParseListReverse alternativesRev
        cursor := cursor
      }
  | some token =>
      if token.text == "|" then
        psParseLeanMatchAlternativesAtColumnWithFuel
          parseTerm
          token.span.start.column
          token.span.start.line
          fuel
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
    (fuel : Nat)
    (start : PsSourcePos)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      if psTokenCursorAtText cursor "return" then
        match psTokenCursorAdvance cursor with
        | none =>
            Except.error
              (PsParseError.unexpectedEnd "do return value")
        | some returnKeyword =>
            match parseTerm returnKeyword.cursor with
            | Except.error error => Except.error error
            | Except.ok value =>
                let finalCursor :=
                  if psTokenCursorAtText value.cursor ";" then
                    match psTokenCursorAdvance value.cursor with
                    | none => value.cursor
                    | some afterSemi => afterSemi.cursor
                  else
                    value.cursor
                let span := {
                  start := start
                  stop := (psSyntaxTermSpan value.value).stop
                }
                Except.ok {
                  value := psSyntaxCompilerPure value.value span
                  cursor := finalCursor
                }
      else if psTokenCursorAtText cursor "let" then
        match psTokenCursorAdvance cursor with
        | none =>
            Except.error
              (PsParseError.unexpectedEnd "do binding name")
        | some letKeyword =>
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
                                        psParseLeanDoWithFuel
                                          parseTerm
                                          remaining
                                          start
                                          afterSemi.cursor with
                                    | Except.error error => Except.error error
                                    | Except.ok body =>
                                        let nameSyntax : PsSyntaxName := {
                                          segments := [name.token.text]
                                          span := name.token.span
                                        }
                                        let binder : PsSyntaxBinderHead := {
                                          name := nameSyntax
                                          kind := PsSyntaxBinderKind.explicit
                                          span := {
                                            start := name.token.span.start
                                            stop :=
                                              (psSyntaxTermSpan
                                                binderType.value).stop
                                          }
                                        }
                                        let span := {
                                          start := start
                                          stop :=
                                            (psSyntaxTermSpan body.value).stop
                                        }
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
        | none =>
            Except.error
              (PsParseError.unexpectedEnd "do statement")
        | some token =>
            Except.error
              (PsParseError.expectedText
                "let or return"
                token.text
                token.span)

def psParseLeanRecordApplicationTailWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (current : PsSyntaxTerm)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      if psTokenCursorAtText cursor "{" then
        match psParseRecordLiteral parseTerm cursor with
        | Except.error error => Except.error error
        | Except.ok argument =>
            let next :=
              psLeanApplicationWithArgument
                current
                argument.value
            psParseLeanRecordApplicationTailWithFuel
              parseTerm
              remaining
              next
              argument.cursor
      else
        Except.ok {
          value := current
          cursor := cursor
        }

def psParseLeanTermWithFuel :
    Nat ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm)
  | 0, _ => Except.error PsParseError.fuelExhausted
  | remaining + 1, cursor =>
      if psTokenCursorAtText cursor "do" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "do statement")
        | some keyword =>
            psParseLeanDoWithFuel
              (psParseLeanTermWithFuel remaining)
              remaining
              keyword.token.span.start
              keyword.cursor
      else if psTokenCursorAtText cursor "match" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "match scrutinee")
        | some keyword =>
            match psParseLeanTermWithFuel remaining keyword.cursor with
            | Except.error error => Except.error error
            | Except.ok scrutinee =>
                match psTokenCursorExpectText scrutinee.cursor "with" with
                | Except.error error => Except.error error
                | Except.ok afterWith =>
                    match psParseLeanMatchAlternativesWithFuel
                        (psParseLeanTermWithFuel remaining)
                        (psParseListLength afterWith.cursor.remaining)
                        afterWith.cursor
                        [] with
                    | Except.error error => Except.error error
                    | Except.ok alternatives =>
                        match alternatives.value with
                        | [] =>
                            match psTokenCursorPeek alternatives.cursor with
                            | none =>
                                Except.error
                                  (PsParseError.unexpectedEnd "match alternative")
                            | some token =>
                                Except.error
                                  (PsParseError.expectedText
                                    "|"
                                    token.text
                                    token.span)
                        | _ =>
                            let stop :=
                              match psParseListReverse alternatives.value with
                              | [] => (psSyntaxTermSpan scrutinee.value).stop
                              | (_, _, span) :: _ => span.stop
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
        | none => Except.error (PsParseError.unexpectedEnd "if condition")
        | some keyword =>
            match psParseLeanTermWithFuel remaining keyword.cursor with
            | Except.error error => Except.error error
            | Except.ok condition =>
                match psTokenCursorExpectText condition.cursor "then" with
                | Except.error error => Except.error error
                | Except.ok afterThen =>
                    match psParseLeanTermWithFuel remaining afterThen.cursor with
                    | Except.error error => Except.error error
                    | Except.ok thenBranch =>
                        match psTokenCursorExpectText thenBranch.cursor "else" with
                        | Except.error error => Except.error error
                        | Except.ok afterElse =>
                            match psParseLeanTermWithFuel remaining afterElse.cursor with
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
                                        stop := (psSyntaxTermSpan elseBranch.value).stop
                                      }
                                  cursor := elseBranch.cursor
                                }
      else if psTokenCursorAtText cursor "let" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "let binding name")
        | some keyword =>
            match psTokenCursorExpectKind
                keyword.cursor
                PsTokenKind.identifier with
            | Except.error error => Except.error error
            | Except.ok name =>
                let sourceName : PsSyntaxName := {
                  segments := [name.token.text]
                  span := name.token.span
                }
                if psTokenCursorAtText name.cursor ":" then
                  match psTokenCursorAdvance name.cursor with
                  | none =>
                      Except.error
                        (PsParseError.unexpectedEnd "let binding type")
                  | some afterColon =>
                      match psParseLeanTermWithFuel
                          remaining
                          afterColon.cursor with
                      | Except.error error => Except.error error
                      | Except.ok declaredType =>
                          match psTokenCursorExpectText
                              declaredType.cursor
                              ":=" with
                          | Except.error error => Except.error error
                          | Except.ok afterAssign =>
                              match psParseLeanTermWithFuel
                                  remaining
                                  afterAssign.cursor with
                              | Except.error error => Except.error error
                              | Except.ok value =>
                                  match psTokenCursorExpectText
                                      value.cursor
                                      ";" with
                                  | Except.error error => Except.error error
                                  | Except.ok afterSemi =>
                                      match psParseLeanTermWithFuel
                                          remaining
                                          afterSemi.cursor with
                                      | Except.error error => Except.error error
                                      | Except.ok body =>
                                          Except.ok {
                                            value :=
                                              PsSyntaxTerm.letE
                                                sourceName
                                                (some declaredType.value)
                                                value.value
                                                body.value
                                                {
                                                  start := keyword.token.span.start
                                                  stop :=
                                                    (psSyntaxTermSpan body.value).stop
                                                }
                                            cursor := body.cursor
                                          }
                else
                  match psTokenCursorExpectText name.cursor ":=" with
                  | Except.error error => Except.error error
                  | Except.ok afterAssign =>
                      match psParseLeanTermWithFuel
                          remaining
                          afterAssign.cursor with
                      | Except.error error => Except.error error
                      | Except.ok value =>
                          match psTokenCursorExpectText value.cursor ";" with
                          | Except.error error => Except.error error
                          | Except.ok afterSemi =>
                              match psParseLeanTermWithFuel
                                  remaining
                                  afterSemi.cursor with
                              | Except.error error => Except.error error
                              | Except.ok body =>
                                  Except.ok {
                                    value :=
                                      PsSyntaxTerm.letE
                                        sourceName
                                        none
                                        value.value
                                        body.value
                                        {
                                          start := keyword.token.span.start
                                          stop :=
                                            (psSyntaxTermSpan body.value).stop
                                        }
                                    cursor := body.cursor
                                  }
      else if psTokenCursorAtText cursor "fun" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "lambda binder")
        | some keyword =>
            match psParseLeanBindersWithFuel
                (psParseListLength keyword.cursor.remaining)
                keyword.cursor
                [] with
            | Except.error error => Except.error error
            | Except.ok binders =>
                match binders.value with
                | [] =>
                    match psTokenCursorPeek binders.cursor with
                    | none =>
                        Except.error
                          (PsParseError.unexpectedEnd "lambda binder")
                    | some token =>
                        Except.error
                          (PsParseError.expectedText
                            "typed lambda binder"
                            token.text
                            token.span)
                | _ =>
                    match psTokenCursorExpectText binders.cursor "=>" with
                    | Except.error error => Except.error error
                    | Except.ok afterArrow =>
                        match psParseLeanTermWithFuel
                            remaining
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
                                    stop := (psSyntaxTermSpan body.value).stop
                                  }
                              cursor := body.cursor
                            }
      else if psTokenCursorAtText cursor "[" then
        match psTokenCursorAdvance cursor with
        | none =>
            Except.error
              (PsParseError.unexpectedEnd "[")
        | some opening =>
            psParseLeanListLiteral
              (psParseLeanTermWithFuel remaining)
              opening
      else if psTokenCursorAtText cursor "{" then
        psParseRecordLiteral
          (psParseLeanTermWithFuel remaining)
          cursor
      else if psTokenCursorAtText cursor "(" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "(")
        | some opening =>
            if psTokenCursorAtText opening.cursor ")" then
              match psTokenCursorAdvance opening.cursor with
              | none => Except.error (PsParseError.unexpectedEnd ")")
              | some close =>
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
                      (psParseLeanTermWithFuel remaining)
                      binder
                  else
                    match psParseLeanTermWithFuel remaining opening.cursor with
                    | Except.error error => Except.error error
                    | Except.ok grouped =>
                        match psTokenCursorExpectText grouped.cursor ")" with
                        | Except.error error => Except.error error
                        | Except.ok close =>
                            psParseLeanArrowTail
                              (psParseLeanTermWithFuel remaining)
                              {
                                value := grouped.value
                                cursor := close.cursor
                              }
              | Except.error _ =>
                  match psParseLeanTermWithFuel remaining opening.cursor with
                  | Except.error error => Except.error error
                  | Except.ok grouped =>
                      match psTokenCursorExpectText grouped.cursor ")" with
                      | Except.error error => Except.error error
                      | Except.ok close =>
                          psParseLeanArrowTail
                            (psParseLeanTermWithFuel remaining)
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
                  (psParseLeanTermWithFuel remaining)
                  remaining
                  domain.value
                  domain.cursor with
            | Except.error error => Except.error error
            | Except.ok withRecords =>
                psParseLeanArrowTail
                  (psParseLeanTermWithFuel remaining)
                  withRecords

def psParseLeanTerm
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseLeanTermWithFuel (Nat.add (psParseListLength cursor.remaining) 1) cursor

def psParseLeanInductiveConstructorsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (constructorsRev : List PsSyntaxInductiveConstructor) :
    Except PsParseError
      (PsParseResult (List PsSyntaxInductiveConstructor)) :=
  match fuel with
  | 0 =>
      Except.ok {
        value := psParseListReverse constructorsRev
        cursor := cursor
      }
  | remaining + 1 =>
      if psTokenCursorAtText cursor "|" then
        match psTokenCursorAdvance cursor with
        | none =>
            Except.error
              (PsParseError.unexpectedEnd "inductive constructor")
        | some bar =>
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
                    let stop :=
                      match psParseListReverse fields.value with
                      | List.nil => name.token.span.stop
                      | List.cons pair _ => pair.1.span.stop;
                    let constructor : PsSyntaxInductiveConstructor := {
                      name := sourceName
                      fields := fields.value
                      span := {
                        start := bar.token.span.start
                        stop := stop
                      }
                    };
                    psParseLeanInductiveConstructorsWithFuel
                      remaining
                      fields.cursor
                      (constructor :: constructorsRev)
      else
        Except.ok {
          value := psParseListReverse constructorsRev
          cursor := cursor
        }

def psLeanTopLevelDeclarationToken (token : PsToken) : Bool :=
  token.text == "def"
    || token.text == "partial"
    || token.text == "theorem"
    || token.text == "inductive"
    || token.text == "structure"
    || token.text == "import"

def psSplitTokensThroughLine
    (line : Nat) :
    List PsToken -> List PsToken × List PsToken
  | [] => ([], [])
  | token :: rest =>
      if
          psTokenKindEq token.kind PsTokenKind.endOfInput
            || token.span.start.line > line then
        ([], token :: rest)
      else
        let tail := psSplitTokensThroughLine line rest
        (token :: tail.1, tail.2)

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
            | none =>
                Except.error
                  (PsParseError.unexpectedEnd "structure field type")
            | some firstType =>
                let split :=
                  psSplitTokensThroughLine
                    firstType.span.start.line
                    afterColon.cursor.remaining
                match psParseLeanTerm { remaining := split.1 } with
                | Except.error error => Except.error error
                | Except.ok type =>
                    if !psTokenCursorDone type.cursor then
                      match psTokenCursorPeek type.cursor with
                      | none =>
                          Except.error
                            (PsParseError.unexpectedEnd
                              "end of structure field")
                      | some token =>
                          Except.error
                            (PsParseError.expectedText
                              "end of structure field"
                              token.text
                              token.span)
                    else
                      let fieldName : PsSyntaxName := {
                        segments := [name.token.text]
                        span := name.token.span
                      }
                      let head : PsSyntaxBinderHead := {
                        name := fieldName
                        kind := PsSyntaxBinderKind.explicit
                        span := {
                          start := name.token.span.start
                          stop := (psSyntaxTermSpan type.value).stop
                        }
                      }
                      Except.ok {
                        value := (head, type.value)
                        cursor := { remaining := split.2 }
                      }

def psParseLeanStructureFieldsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (fieldsRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsParseError
      (PsParseResult
        (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      Except.ok {
        value := psParseListReverse fieldsRev
        cursor := cursor
      }
  | remaining + 1 =>
      match psTokenCursorPeek cursor with
      | none =>
          Except.ok {
            value := psParseListReverse fieldsRev
            cursor := cursor
          }
      | some token =>
          if
              psTokenKindEq token.kind PsTokenKind.endOfInput
                || psLeanTopLevelDeclarationToken token then
            Except.ok {
              value := psParseListReverse fieldsRev
              cursor := cursor
            }
          else
            match psParseLeanStructureField cursor with
            | Except.error error => Except.error error
            | Except.ok field =>
                psParseLeanStructureFieldsWithFuel
                  remaining
                  field.cursor
                  (field.value :: fieldsRev)

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
                          | none =>
                              Except.error
                                (PsParseError.unexpectedEnd
                                  "structure field")
                          | some token =>
                              Except.error
                                (PsParseError.expectedText
                                  "structure field"
                                  token.text
                                  token.span)
                      | (lastHead, _) :: _ =>
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
              let parseAfterResult
                  (resultType : Option PsSyntaxTerm)
                  (afterResult : PsTokenCursor) :=
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
                            | none =>
                                Except.error
                                  (PsParseError.unexpectedEnd
                                    "inductive constructor")
                            | some token =>
                                Except.error
                                  (PsParseError.expectedText
                                    "|"
                                    token.text
                                    token.span)
                        | _ =>
                            let stop :=
                              match psParseListReverse constructors.value with
                              | [] => name.value.span.stop
                              | constructor :: _ =>
                                  constructor.span.stop
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
                            }
              if psTokenCursorAtText params.cursor ":" then
                match psTokenCursorAdvance params.cursor with
                | none =>
                    Except.error
                      (PsParseError.unexpectedEnd "inductive result type")
                | some afterColon =>
                    match psParseLeanTerm afterColon.cursor with
                    | Except.error error => Except.error error
                    | Except.ok resultType =>
                        parseAfterResult
                          (some resultType.value)
                          resultType.cursor
              else
                parseAfterResult none params.cursor

structure PsLeanEquationClause where
  patterns : List PsSyntaxPattern
  body : PsSyntaxTerm
  span : PsSourceSpan

def psParseLeanEquationPatternsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (patternsRev : List PsSyntaxPattern) :
    Except PsParseError
      (PsParseResult (List PsSyntaxPattern)) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      match psParseLeanPattern cursor with
      | Except.error error => Except.error error
      | Except.ok pattern =>
          let nextPatterns := pattern.value :: patternsRev
          if psTokenCursorAtText pattern.cursor "," then
            match psTokenCursorAdvance pattern.cursor with
            | none =>
                Except.error
                  (PsParseError.unexpectedEnd "equation pattern")
            | some afterComma =>
                psParseLeanEquationPatternsWithFuel
                  remaining
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
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (clausesRev : List PsLeanEquationClause) :
    Except PsParseError
      (PsParseResult (List PsLeanEquationClause)) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      if !psTokenCursorAtText cursor "|" then
        Except.ok {
          value := psParseListReverse clausesRev
          cursor := cursor
        }
      else
        match psTokenCursorAdvance cursor with
        | none =>
            Except.error
              (PsParseError.unexpectedEnd "equation pattern")
        | some bar =>
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
                            stop := (psSyntaxTermSpan body.value).stop
                          }
                        }
                        psParseLeanEquationClausesWithFuel
                          parseTerm
                          remaining
                          body.cursor
                          (clause :: clausesRev)

def psLeanPatternIsWildcard
    (pattern : PsSyntaxPattern) : Bool :=
  match pattern with
  | .wildcard _ => true
  | _ => false

def psLeanPatternHeadEq
    (left : PsSyntaxPattern)
    (right : PsSyntaxPattern) : Bool :=
  match left, right with
  | .bool leftValue _, .bool rightValue _ =>
      leftValue == rightValue
  | .wildcard _, .wildcard _ => true
  | .constructor leftName _ _,
      .constructor rightName _ _ =>
      leftName.segments == rightName.segments
  | _, _ => false

def psLeanPatternListContainsHead
    (patterns : List PsSyntaxPattern)
    (target : PsSyntaxPattern) : Bool :=
  patterns.any
    (fun pattern =>
      psLeanPatternHeadEq pattern target)

def psLeanEquationHeadPatternsAcc
    (clauses : List PsLeanEquationClause)
    (patternsRev : List PsSyntaxPattern) :
    List PsSyntaxPattern :=
  match clauses with
  | [] => psParseListReverse patternsRev
  | clause :: rest =>
      match clause.patterns with
      | [] =>
          psLeanEquationHeadPatternsAcc rest patternsRev
      | pattern :: _ =>
          if
              psLeanPatternListContainsHead
                patternsRev
                pattern then
            psLeanEquationHeadPatternsAcc rest patternsRev
          else
            psLeanEquationHeadPatternsAcc
              rest
              (pattern :: patternsRev)

def psLeanEquationHeadPatterns
    (clauses : List PsLeanEquationClause) :
    List PsSyntaxPattern :=
  psLeanEquationHeadPatternsAcc clauses []

def psLeanEquationClauseForBranch
    (branch : PsSyntaxPattern)
    (clause : PsLeanEquationClause) :
    Option PsLeanEquationClause :=
  match clause.patterns with
  | [] => none
  | pattern :: rest =>
      let applicable :=
        if psLeanPatternIsWildcard branch then
          psLeanPatternIsWildcard pattern
        else
          psLeanPatternIsWildcard pattern
            || psLeanPatternHeadEq pattern branch
      if applicable then
        some {
          patterns := rest
          body := clause.body
          span := clause.span
        }
      else
        none

def psLeanEquationClausesForBranchAcc
    (branch : PsSyntaxPattern)
    (clauses : List PsLeanEquationClause)
    (resultRev : List PsLeanEquationClause) :
    List PsLeanEquationClause :=
  match clauses with
  | [] => psParseListReverse resultRev
  | clause :: rest =>
      match
          psLeanEquationClauseForBranch
            branch
            clause with
      | none =>
          psLeanEquationClausesForBranchAcc
            branch
            rest
            resultRev
      | some stripped =>
          psLeanEquationClausesForBranchAcc
            branch
            rest
            (stripped :: resultRev)

def psLeanEquationClausesForBranch
    (branch : PsSyntaxPattern)
    (clauses : List PsLeanEquationClause) :
    List PsLeanEquationClause :=
  psLeanEquationClausesForBranchAcc branch clauses []

def psLeanFirstCompletedEquation
    (clauses : List PsLeanEquationClause) :
    Option PsLeanEquationClause :=
  match clauses with
  | [] => none
  | clause :: rest =>
      if clause.patterns.isEmpty then
        some clause
      else
        psLeanFirstCompletedEquation rest

partial def psLeanLowerEquationClauses
    (arguments : List PsSyntaxName)
    (clauses : List PsLeanEquationClause) :
    Option PsSyntaxTerm :=
  match arguments with
  | [] =>
      match psLeanFirstCompletedEquation clauses with
      | none => none
      | some clause => some clause.body
  | argument :: rest =>
      let patterns :=
        psLeanEquationHeadPatterns clauses
      if patterns.isEmpty then
        none
      else
        let lowerAlternative :=
          fun pattern =>
            let branchClauses :=
              psLeanEquationClausesForBranch
                pattern
                clauses
            match
                psLeanLowerEquationClauses
                  rest
                  branchClauses with
            | none => none
            | some body =>
                some
                  (pattern,
                    body,
                    psSyntaxSpanJoin
                      (psSyntaxPatternSpan pattern)
                      (psSyntaxTermSpan body))
        match patterns.mapM lowerAlternative with
        | none => none
        | some alternatives =>
            match psParseListReverse alternatives with
            | [] => none
            | (_, body, _) :: _ =>
                some
                  (PsSyntaxTerm.matchE
                    (PsSyntaxTerm.reference argument)
                    alternatives
                    {
                      start := argument.span.start
                      stop := (psSyntaxTermSpan body).stop
                    })

def psLeanFlattenForallBinders
    (type : PsSyntaxTerm) :
    Prod
      (List
        (Prod PsSyntaxBinderHead PsSyntaxTerm))
      PsSyntaxTerm :=
  match type with
  | .forallE binders body _ =>
      let tail := psLeanFlattenForallBinders body
      (binders ++ tail.1, tail.2)
  | _ => ([], type)

def psLeanEquationBinderName
    (index : Nat)
    (head : PsSyntaxBinderHead) :
    PsSyntaxName :=
  if head.name.segments == ["_"] then
    {
      segments := ["_eq" ++ toString index]
      span := head.name.span
    }
  else
    head.name

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
  if remaining == 0 then
    some (psParseListReverse bindersRev, psParseListReverse namesRev)
  else
    match available with
    | [] => none
    | binder :: rest =>
        let name :=
          psLeanEquationBinderName index binder.1
        let head : PsSyntaxBinderHead := {
          name := name
          kind := binder.1.kind
          span := binder.1.span
        }
        psLeanPrepareEquationBindersAcc
          (Nat.sub remaining 1)
          (Nat.add index 1)
          rest
          ((head, binder.2) :: bindersRev)
          (name :: namesRev)

def psLeanEquationArity
    (clauses : List PsLeanEquationClause) :
    Option Nat :=
  match clauses with
  | [] => none
  | clause :: rest =>
      let arity := psParseListLength clause.patterns
      if
          rest.all
            (fun next =>
              (psParseListLength next.patterns) == arity) then
        some arity
      else
        none

def psLeanLowerEquationValue
    (type : PsSyntaxTerm)
    (clauses : List PsLeanEquationClause) :
    Option PsSyntaxTerm :=
  match psLeanEquationArity clauses with
  | none => none
  | some arity =>
      let flattened :=
        psLeanFlattenForallBinders type
      match
          psLeanPrepareEquationBindersAcc
            arity
            0
            flattened.1
            []
            [] with
      | none => none
      | some prepared =>
          match
              psLeanLowerEquationClauses
                prepared.2
                clauses with
          | none => none
          | some body =>
              match clauses with
              | [] => none
              | first :: _ =>
                  some
                    (PsSyntaxTerm.lambda
                      prepared.1
                      body
                      {
                        start := first.span.start
                        stop := (psSyntaxTermSpan body).stop
                      })

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
    stop := (psSyntaxTermSpan value).stop
  }
  let declaration :=
    if isPartial then
      PsSyntaxDeclaration.partialDefinition
        name binders type value span
    else if isDefinition then
      PsSyntaxDeclaration.definition
        name binders type value span
    else
      PsSyntaxDeclaration.theoremDecl
        name binders type value span
  {
    value := declaration
    cursor := cursor
  }

def psParseLeanDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "declaration")
  | some keyword =>
      if keyword.text == "inductive" then
        psParseLeanInductiveDeclaration cursor
      else if keyword.text == "structure" then
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
              !isTheorem then
          Except.error
            (PsParseError.expectedText
              "partial def, def, theorem, inductive, or structure"
              keyword.text
              keyword.span)
        else
          let afterKind :=
            if isPartial then
              match psTokenCursorAdvance cursor with
              | none =>
                  Except.error
                    (PsParseError.unexpectedEnd "def after partial")
              | some afterPartial =>
                  match psTokenCursorExpectText afterPartial.cursor "def" with
                  | Except.error error => Except.error error
                  | Except.ok afterDef => Except.ok afterDef.cursor
            else
              match psTokenCursorAdvance cursor with
              | none =>
                  Except.error
                    (PsParseError.unexpectedEnd "declaration name")
              | some afterKeyword => Except.ok afterKeyword.cursor
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
                                | none =>
                                    Except.error
                                      (PsParseError.unexpectedEnd
                                        "declaration value")
                                | some afterAssign =>
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
                                    | none =>
                                        match psTokenCursorPeek type.cursor with
                                        | none =>
                                            Except.error
                                              (PsParseError.unexpectedEnd
                                                "supported equation clauses")
                                        | some token =>
                                            Except.error
                                              (PsParseError.expectedText
                                                "supported equation clauses"
                                                token.text
                                                token.span)
                                    | some value =>
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
                                | none =>
                                    Except.error
                                      (PsParseError.unexpectedEnd
                                        ":= or equation clause")
                                | some token =>
                                    Except.error
                                      (PsParseError.expectedText
                                        ":= or equation clause"
                                        token.text
                                        token.span)


def psParseLeanImportsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (importsRev : List PsSyntaxImport) :
    Except PsParseError (PsParseResult (List PsSyntaxImport)) :=
  match fuel with
  | 0 =>
      Except.ok {
        value := psParseListReverse importsRev
        cursor := cursor
      }
  | remaining + 1 =>
      if psTokenCursorAtText cursor "import" then
        match psParseLeanImport cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseLeanImportsWithFuel
              remaining
              parsed.cursor
              (parsed.value :: importsRev)
      else
        Except.ok {
          value := psParseListReverse importsRev
          cursor := cursor
        }

def psParseLeanDeclarationsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (declarationsRev : List PsSyntaxDeclaration) :
    Except PsParseError (PsParseResult (List PsSyntaxDeclaration)) :=
  match fuel with
  | 0 =>
      if psTokenCursorDone cursor then
        Except.ok {
          value := psParseListReverse declarationsRev
          cursor := cursor
        }
      else
        match psTokenCursorPeek cursor with
        | none => Except.ok {
            value := psParseListReverse declarationsRev
            cursor := cursor
          }
        | some token =>
            Except.error
              (PsParseError.expectedText
                "end of input"
                token.text
                token.span)
  | remaining + 1 =>
      if psTokenCursorDone cursor then
        Except.ok {
          value := psParseListReverse declarationsRev
          cursor := cursor
        }
      else
        match psParseLeanDeclaration cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseLeanDeclarationsWithFuel
              remaining
              parsed.cursor
              (parsed.value :: declarationsRev)

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
