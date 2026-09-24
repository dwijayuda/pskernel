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
  token.text == "def"
    || token.text == "theorem"
    || token.text == "import"
    || token.text == "inductive"
    || token.text == "structure"
    || token.text == "where"
    || token.text == "then"
    || token.text == "else"
    || token.text == "fun"
    || token.text == "let"
    || token.text == "if"
    || token.text == "match"
    || token.text == "with"

def psLeanCanStartSimpleArgument (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
      !psLeanReservedApplicationToken token
        && (token.text == "("
          || psTokenKindEq token.kind PsTokenKind.identifier
          || psTokenKindEq token.kind PsTokenKind.natural
          || psTokenKindEq token.kind PsTokenKind.string
          || psTokenKindEq token.kind PsTokenKind.character)

def psParseLeanApplicationTailWithFuel
    (fuel : Nat)
    (current : PsSyntaxTerm)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      Except.ok { value := current, cursor := cursor }
  | remaining + 1 =>
      if psLeanCanStartSimpleArgument cursor then
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
                      }
                    let span :=
                      psSyntaxSpanJoin
                        (psSyntaxTermSpan current)
                        (psSyntaxTermSpan argument)
                    let next :=
                      match current with
                      | .app fn args _ =>
                          PsSyntaxTerm.app fn (args ++ [argument]) span
                      | _ =>
                          PsSyntaxTerm.app current [argument] span
                    psParseLeanApplicationTailWithFuel
                      remaining
                      next
                      close.cursor
              else
                match psParseSimpleTerm opening.cursor with
                | Except.error error => Except.error error
                | Except.ok first =>
                    match psParseLeanApplicationTailWithFuel
                        remaining
                        first.value
                        first.cursor with
                    | Except.error error => Except.error error
                    | Except.ok inner =>
                        match psTokenCursorExpectText inner.cursor ")" with
                        | Except.error error => Except.error error
                        | Except.ok close =>
                            let span :=
                              psSyntaxSpanJoin
                                (psSyntaxTermSpan current)
                                (psSyntaxTermSpan inner.value)
                            let next :=
                              match current with
                              | .app fn args _ =>
                                  PsSyntaxTerm.app
                                    fn
                                    (args ++ [inner.value])
                                    span
                              | _ =>
                                  PsSyntaxTerm.app
                                    current
                                    [inner.value]
                                    span
                            psParseLeanApplicationTailWithFuel
                              remaining
                              next
                              close.cursor
        else
          match psParseSimpleTerm cursor with
          | Except.error error => Except.error error
          | Except.ok argument =>
              let span :=
                psSyntaxSpanJoin
                  (psSyntaxTermSpan current)
                  (psSyntaxTermSpan argument.value)
              let next :=
                match current with
                | .app fn args _ =>
                    PsSyntaxTerm.app fn (args ++ [argument.value]) span
                | _ =>
                    PsSyntaxTerm.app current [argument.value] span
              psParseLeanApplicationTailWithFuel
                remaining
                next
                argument.cursor
      else
        Except.ok { value := current, cursor := cursor }

def psParseLeanSimpleApplication
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psParseSimpleTerm cursor with
  | Except.error error => Except.error error
  | Except.ok first =>
      psParseLeanApplicationTailWithFuel
        cursor.remaining.length
        first.value
        first.cursor

def psParseLeanBinderTypeWithFuel :
    Nat ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm)
  | 0, _ => Except.error PsParseError.fuelExhausted
  | remaining + 1, cursor =>
      match psParseLeanSimpleApplication cursor with
      | Except.error error => Except.error error
      | Except.ok domain =>
          if psTokenCursorAtArrow domain.cursor then
            match psTokenCursorExpectArrow domain.cursor with
            | Except.error error => Except.error error
            | Except.ok afterArrow =>
                match
                    psParseLeanBinderTypeWithFuel
                      remaining
                      afterArrow.cursor with
                | Except.error error => Except.error error
                | Except.ok codomain =>
                    let domainSpan := psSyntaxTermSpan domain.value
                    Except.ok {
                      value :=
                        PsSyntaxTerm.forallE
                          [(psSyntaxAnonymousExplicitBinder
                            domainSpan,
                            domain.value)]
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
    (cursor.remaining.length + 1)
    cursor

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
      Except.ok { value := bindersRev.reverse, cursor := cursor }
  | remaining + 1 =>
      if psTokenCursorAtBinderStart cursor then
        match psParseLeanBinder cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseLeanBindersWithFuel
              remaining
              parsed.cursor
              (parsed.value :: bindersRev)
      else
        Except.ok { value := bindersRev.reverse, cursor := cursor }

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
            let domainSpan := psSyntaxTermSpan domain.value
            let span := psSyntaxSpanJoin domainSpan (psSyntaxTermSpan codomain.value)
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
  match fuel with
  | 0 =>
      Except.ok {
        value := alternativesRev.reverse
        cursor := cursor
      }
  | remaining + 1 =>
      if psTokenCursorAtText cursor "|" then
        match psTokenCursorAdvance cursor with
        | none =>
            Except.error (PsParseError.unexpectedEnd "match pattern")
        | some bar =>
            match psParseBasicPattern bar.cursor with
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
                        psParseLeanMatchAlternativesWithFuel
                          parseTerm
                          remaining
                          body.cursor
                          ((pattern.value, body.value, span) :: alternativesRev)
      else
        Except.ok {
          value := alternativesRev.reverse
          cursor := cursor
        }

def psParseLeanTermWithFuel :
    Nat ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm)
  | 0, _ => Except.error PsParseError.fuelExhausted
  | remaining + 1, cursor =>
      if psTokenCursorAtText cursor "match" then
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
                        afterWith.cursor.remaining.length
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
                              match alternatives.value.reverse with
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
                keyword.cursor.remaining.length
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
        match psParseLeanSimpleApplication cursor with
        | Except.error error => Except.error error
        | Except.ok domain =>
            psParseLeanArrowTail
              (psParseLeanTermWithFuel remaining)
              domain

def psParseLeanTerm
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseLeanTermWithFuel (cursor.remaining.length + 1) cursor

def psParseLeanInductiveConstructorsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (constructorsRev : List PsSyntaxInductiveConstructor) :
    Except PsParseError
      (PsParseResult (List PsSyntaxInductiveConstructor)) :=
  match fuel with
  | 0 =>
      Except.ok {
        value := constructorsRev.reverse
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
                    name.cursor.remaining.length
                    name.cursor
                    [] with
                | Except.error error => Except.error error
                | Except.ok fields =>
                    let sourceName : PsSyntaxName := {
                      segments := [name.token.text]
                      span := name.token.span
                    }
                    let stop :=
                      match fields.value.reverse with
                      | [] => name.token.span.stop
                      | (head, _) :: _ => head.span.stop
                    let constructor : PsSyntaxInductiveConstructor := {
                      name := sourceName
                      fields := fields.value
                      span := {
                        start := bar.token.span.start
                        stop := stop
                      }
                    }
                    psParseLeanInductiveConstructorsWithFuel
                      remaining
                      fields.cursor
                      (constructor :: constructorsRev)
      else
        Except.ok {
          value := constructorsRev.reverse
          cursor := cursor
        }

def psLeanTopLevelDeclarationToken (token : PsToken) : Bool :=
  token.text == "def"
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
        value := fieldsRev.reverse
        cursor := cursor
      }
  | remaining + 1 =>
      match psTokenCursorPeek cursor with
      | none =>
          Except.ok {
            value := fieldsRev.reverse
            cursor := cursor
          }
      | some token =>
          if
              psTokenKindEq token.kind PsTokenKind.endOfInput
                || psLeanTopLevelDeclarationToken token then
            Except.ok {
              value := fieldsRev.reverse
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
              name.cursor.remaining.length
              name.cursor
              [] with
          | Except.error error => Except.error error
          | Except.ok params =>
              match psTokenCursorExpectText params.cursor "where" with
              | Except.error error => Except.error error
              | Except.ok afterWhere =>
                  match
                      psParseLeanStructureFieldsWithFuel
                        afterWhere.cursor.remaining.length
                        afterWhere.cursor
                        [] with
                  | Except.error error => Except.error error
                  | Except.ok fields =>
                      match fields.value.reverse with
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
              name.cursor.remaining.length
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
                        afterWhere.cursor.remaining.length
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
                              match constructors.value.reverse with
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
        let isDefinition := keyword.text == "def"
        let isTheorem := keyword.text == "theorem"
        if !(isDefinition || isTheorem) then
          Except.error
            (PsParseError.expectedText
              "def, theorem, inductive, or structure"
              keyword.text
              keyword.span)
        else
          match psTokenCursorAdvance cursor with
          | none =>
              Except.error
                (PsParseError.unexpectedEnd "declaration name")
          | some afterKeyword =>
              match psParseSyntaxName afterKeyword.cursor with
              | Except.error error => Except.error error
              | Except.ok name =>
                  match psParseLeanBindersWithFuel
                      name.cursor.remaining.length
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
                              match psTokenCursorExpectText
                                  type.cursor
                                  ":=" with
                              | Except.error error => Except.error error
                              | Except.ok afterAssign =>
                                  match psParseLeanTerm
                                      afterAssign.cursor with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok value =>
                                      let span := {
                                        start := keyword.span.start
                                        stop :=
                                          (psSyntaxTermSpan value.value).stop
                                      }
                                      if isDefinition then
                                        Except.ok {
                                          value :=
                                            PsSyntaxDeclaration.definition
                                              name.value
                                              binders.value
                                              type.value
                                              value.value
                                              span
                                          cursor := value.cursor
                                        }
                                      else
                                        Except.ok {
                                          value :=
                                            PsSyntaxDeclaration.theoremDecl
                                              name.value
                                              binders.value
                                              type.value
                                              value.value
                                              span
                                          cursor := value.cursor
                                        }

def psParseLeanImportsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (importsRev : List PsSyntaxImport) :
    Except PsParseError (PsParseResult (List PsSyntaxImport)) :=
  match fuel with
  | 0 =>
      Except.ok {
        value := importsRev.reverse
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
          value := importsRev.reverse
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
          value := declarationsRev.reverse
          cursor := cursor
        }
      else
        match psTokenCursorPeek cursor with
        | none => Except.ok {
            value := declarationsRev.reverse
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
          value := declarationsRev.reverse
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
  let cursor := psTokenCursorFromTokens tokens
  match psParseLeanImportsWithFuel tokens.length cursor [] with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match psParseLeanDeclarationsWithFuel
          tokens.length
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
