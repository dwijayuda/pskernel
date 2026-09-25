import Ps.Syntax.Lexer
import Ps.Syntax.ParseCommon

def psParseOptionalSemicolon
    (cursor : PsTokenCursor) : PsTokenCursor :=
  if psTokenCursorAtText cursor ";" then
    match psTokenCursorAdvance cursor with
    | none => cursor
    | some read => read.cursor
  else
    cursor

def psProofScriptBoolNot (value : Bool) : Bool :=
  match value with
  | true => false
  | false => true

def psParseProofScriptImport
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
            cursor := psParseOptionalSemicolon name.cursor
          }

structure PsProofScriptCallArgs where
  args : List PsSyntaxTerm
  closeSpan : PsSourceSpan
  cursor : PsTokenCursor

def psParseProofScriptCallArgsWithFuel
    (parseArgument :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (argsRev : List PsSyntaxTerm) :
    Except PsParseError PsProofScriptCallArgs :=
  match fuel with
  | 0 =>
      match psTokenCursorPeek cursor with
      | none => Except.error (PsParseError.unexpectedEnd ")")
      | some token =>
          Except.error
            (PsParseError.expectedText ")" token.text token.span)
  | remaining + 1 =>
      if psTokenCursorAtText cursor ")" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd ")")
        | some close =>
            Except.ok {
              args := argsRev.reverse
              closeSpan := close.token.span
              cursor := close.cursor
            }
      else
        match parseArgument cursor with
        | Except.error error => Except.error error
        | Except.ok argument =>
            if psTokenCursorAtText argument.cursor "," then
              match psTokenCursorAdvance argument.cursor with
              | none => Except.error (PsParseError.unexpectedEnd "term")
              | some comma =>
                  psParseProofScriptCallArgsWithFuel
                    parseArgument
                    remaining
                    comma.cursor
                    (List.cons argument.value argsRev)
            else
              match psTokenCursorExpectText argument.cursor ")" with
              | Except.error error => Except.error error
              | Except.ok close =>
                  Except.ok {
                    args := (List.cons argument.value argsRev).reverse
                    closeSpan := close.token.span
                    cursor := close.cursor
                  }

def psProofScriptCallAdjacent
    (term : PsSyntaxTerm)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
      token.span.start.byteOffset == (psSyntaxTermSpan term).stop.byteOffset

def psParseProofScriptApplicationWithFuel
    (parseArgument :
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
          if psTokenCursorAtText first.cursor "("
              && psProofScriptCallAdjacent first.value first.cursor then
            match psTokenCursorAdvance first.cursor with
            | none => Except.error (PsParseError.unexpectedEnd "(")
            | some opening =>
                match psParseProofScriptCallArgsWithFuel
                    parseArgument
                    remaining
                    opening.cursor
                    [] with
                | Except.error error => Except.error error
                | Except.ok call =>
                    let span := {
                      start := (psSyntaxTermSpan first.value).start
                      stop := call.closeSpan.stop
                    }
                    let args :=
                      match call.args with
                      | [] =>
                          [PsSyntaxTerm.unit {
                            start := opening.token.span.start
                            stop := call.closeSpan.stop
                          }]
                      | _ => call.args
                    Except.ok {
                      value := PsSyntaxTerm.app first.value args span
                      cursor := call.cursor
                    }
          else
            Except.ok first

def psParseProofScriptSimpleApplicationWithFuel :
    Nat ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm)
  | 0, _ => Except.error PsParseError.fuelExhausted
  | remaining + 1, cursor =>
      psParseProofScriptApplicationWithFuel
        (psParseProofScriptSimpleApplicationWithFuel remaining)
        (remaining + 1)
        cursor

def psParseProofScriptSimpleApplication
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseProofScriptSimpleApplicationWithFuel
    (cursor.remaining.length + 1)
    cursor

def psParseProofScriptBinderTypeWithFuel :
    Nat ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm)
  | 0, _ => Except.error PsParseError.fuelExhausted
  | remaining + 1, cursor =>
      match psParseProofScriptSimpleApplication cursor with
      | Except.error error => Except.error error
      | Except.ok domain =>
          if psTokenCursorAtArrow domain.cursor then
            match psTokenCursorExpectArrow domain.cursor with
            | Except.error error => Except.error error
            | Except.ok afterArrow =>
                match
                    psParseProofScriptBinderTypeWithFuel
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

def psParseProofScriptBinderType
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseProofScriptBinderTypeWithFuel
    (cursor.remaining.length + 1)
    cursor

def psParseProofScriptBinder
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
              match psParseProofScriptBinderType afterColon.cursor with
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

def psParseProofScriptBindersWithFuel
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
        match psParseProofScriptBinder cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseProofScriptBindersWithFuel
              remaining
              parsed.cursor
              (List.cons parsed.value bindersRev)
      else
        Except.ok { value := bindersRev.reverse, cursor := cursor }

def psParseProofScriptArrowTail
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

def psParseProofScriptDependentArrowTail
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
                    start := binder.value.fst.span.start
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
         | none => binder.value.fst.span
         | some token => token.span))

def psParseProofScriptMatchAlternativesWithFuel
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
      Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      if psTokenCursorAtText cursor "}" then
        Except.ok {
          value := alternativesRev.reverse
          cursor := cursor
        }
      else
        match psTokenCursorExpectText cursor "|" with
        | Except.error error => Except.error error
        | Except.ok bar =>
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
                        if psTokenCursorAtText body.cursor ";" then
                          match psTokenCursorAdvance body.cursor with
                          | none =>
                              Except.error
                                (PsParseError.unexpectedEnd "match alternative")
                          | some afterSemi =>
                              psParseProofScriptMatchAlternativesWithFuel
                                parseTerm
                                remaining
                                afterSemi.cursor
                                (List.cons (Prod.mk pattern.value (Prod.mk body.value span)) alternativesRev)
                        else if psTokenCursorAtText body.cursor "}" then
                          psParseProofScriptMatchAlternativesWithFuel
                            parseTerm
                            remaining
                            body.cursor
                            (List.cons (Prod.mk pattern.value (Prod.mk body.value span)) alternativesRev)
                        else
                          match psTokenCursorPeek body.cursor with
                          | none =>
                              Except.error
                                (PsParseError.unexpectedEnd "; or }")
                          | some token =>
                              Except.error
                                (PsParseError.expectedText
                                  "; or }"
                                  token.text
                                  token.span)

def psParseProofScriptDoWithFuel
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
                let afterValue :=
                  if psTokenCursorAtText value.cursor ";" then
                    match psTokenCursorAdvance value.cursor with
                    | none => value.cursor
                    | some afterSemi => afterSemi.cursor
                  else
                    value.cursor
                match psTokenCursorExpectText afterValue "}" with
                | Except.error error => Except.error error
                | Except.ok close =>
                    let span := {
                      start := start
                      stop := close.token.span.stop
                    }
                    Except.ok {
                      value := psSyntaxCompilerPure value.value span
                      cursor := close.cursor
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
                                        psParseProofScriptDoWithFuel
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

def psParseProofScriptTermWithFuel :
    Nat ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm)
  | 0, _ => Except.error PsParseError.fuelExhausted
  | remaining + 1, cursor =>
      if psTokenCursorAtText cursor "do" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "{")
        | some keyword =>
            match psTokenCursorExpectText keyword.cursor "{" with
            | Except.error error => Except.error error
            | Except.ok afterOpen =>
                psParseProofScriptDoWithFuel
                  (psParseProofScriptTermWithFuel remaining)
                  remaining
                  keyword.token.span.start
                  afterOpen.cursor
      else if psTokenCursorAtText cursor "match" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "match scrutinee")
        | some keyword =>
            match psParseProofScriptTermWithFuel remaining keyword.cursor with
            | Except.error error => Except.error error
            | Except.ok scrutinee =>
                match psTokenCursorExpectText scrutinee.cursor "with" with
                | Except.error error => Except.error error
                | Except.ok afterWith =>
                    match psTokenCursorExpectText afterWith.cursor "{" with
                    | Except.error error => Except.error error
                    | Except.ok afterOpen =>
                        match psParseProofScriptMatchAlternativesWithFuel
                            (psParseProofScriptTermWithFuel remaining)
                            afterOpen.cursor.remaining.length
                            afterOpen.cursor
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
                                match psTokenCursorExpectText
                                    alternatives.cursor
                                    "}" with
                                | Except.error error => Except.error error
                                | Except.ok close =>
                                    Except.ok {
                                      value :=
                                        PsSyntaxTerm.matchE
                                          scrutinee.value
                                          alternatives.value
                                          {
                                            start := keyword.token.span.start
                                            stop := close.token.span.stop
                                          }
                                      cursor := close.cursor
                                    }
      else if psTokenCursorAtText cursor "if" then
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "(")
        | some keyword =>
            match psTokenCursorExpectText keyword.cursor "(" with
            | Except.error error => Except.error error
            | Except.ok afterOpen =>
                match psParseProofScriptTermWithFuel remaining afterOpen.cursor with
                | Except.error error => Except.error error
                | Except.ok condition =>
                    match psTokenCursorExpectText condition.cursor ")" with
                    | Except.error error => Except.error error
                    | Except.ok afterCondition =>
                        match psTokenCursorExpectText afterCondition.cursor "{" with
                        | Except.error error => Except.error error
                        | Except.ok afterThenOpen =>
                            match psParseProofScriptTermWithFuel
                                remaining
                                afterThenOpen.cursor with
                            | Except.error error => Except.error error
                            | Except.ok thenBranch =>
                                match psTokenCursorExpectText thenBranch.cursor "}" with
                                | Except.error error => Except.error error
                                | Except.ok afterThenClose =>
                                    match psTokenCursorExpectText
                                        afterThenClose.cursor
                                        "else" with
                                    | Except.error error => Except.error error
                                    | Except.ok afterElse =>
                                        match psTokenCursorExpectText
                                            afterElse.cursor
                                            "{" with
                                        | Except.error error => Except.error error
                                        | Except.ok afterElseOpen =>
                                            match psParseProofScriptTermWithFuel
                                                remaining
                                                afterElseOpen.cursor with
                                            | Except.error error => Except.error error
                                            | Except.ok elseBranch =>
                                                match psTokenCursorExpectText
                                                    elseBranch.cursor
                                                    "}" with
                                                | Except.error error => Except.error error
                                                | Except.ok close =>
                                                    Except.ok {
                                                      value :=
                                                        PsSyntaxTerm.ifE
                                                          condition.value
                                                          thenBranch.value
                                                          elseBranch.value
                                                          {
                                                            start :=
                                                              keyword.token.span.start
                                                            stop :=
                                                              close.token.span.stop
                                                          }
                                                      cursor := close.cursor
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
                      match psParseProofScriptTermWithFuel
                          remaining
                          afterColon.cursor with
                      | Except.error error => Except.error error
                      | Except.ok declaredType =>
                          match psTokenCursorExpectText
                              declaredType.cursor
                              ":=" with
                          | Except.error error => Except.error error
                          | Except.ok afterAssign =>
                              match psParseProofScriptTermWithFuel
                                  remaining
                                  afterAssign.cursor with
                              | Except.error error => Except.error error
                              | Except.ok value =>
                                  match psTokenCursorExpectText
                                      value.cursor
                                      ";" with
                                  | Except.error error => Except.error error
                                  | Except.ok afterSemi =>
                                      match psParseProofScriptTermWithFuel
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
                      match psParseProofScriptTermWithFuel
                          remaining
                          afterAssign.cursor with
                      | Except.error error => Except.error error
                      | Except.ok value =>
                          match psTokenCursorExpectText value.cursor ";" with
                          | Except.error error => Except.error error
                          | Except.ok afterSemi =>
                              match psParseProofScriptTermWithFuel
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
            match psParseProofScriptBindersWithFuel
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
                        match psParseProofScriptTermWithFuel
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
      else if psTokenCursorAtText cursor "{" then
        psParseRecordLiteral
          (psParseProofScriptTermWithFuel remaining)
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
              match psParseProofScriptBinder cursor with
              | Except.ok binder =>
                  if psTokenCursorAtArrow binder.cursor then
                    psParseProofScriptDependentArrowTail
                      (psParseProofScriptTermWithFuel remaining)
                      binder
                  else
                    match psParseProofScriptTermWithFuel remaining opening.cursor with
                    | Except.error error => Except.error error
                    | Except.ok grouped =>
                        match psTokenCursorExpectText grouped.cursor ")" with
                        | Except.error error => Except.error error
                        | Except.ok close =>
                            psParseProofScriptArrowTail
                              (psParseProofScriptTermWithFuel remaining)
                              {
                                value := grouped.value
                                cursor := close.cursor
                              }
              | Except.error _ =>
                  match psParseProofScriptTermWithFuel remaining opening.cursor with
                  | Except.error error => Except.error error
                  | Except.ok grouped =>
                      match psTokenCursorExpectText grouped.cursor ")" with
                      | Except.error error => Except.error error
                      | Except.ok close =>
                          psParseProofScriptArrowTail
                            (psParseProofScriptTermWithFuel remaining)
                            {
                              value := grouped.value
                              cursor := close.cursor
                            }
      else
        match
            psParseProofScriptApplicationWithFuel
              (psParseProofScriptTermWithFuel remaining)
              (remaining + 1)
              cursor with
        | Except.error error => Except.error error
        | Except.ok domain =>
            psParseProofScriptArrowTail
              (psParseProofScriptTermWithFuel remaining)
              domain

def psParseProofScriptTerm
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseProofScriptTermWithFuel (cursor.remaining.length + 1) cursor

def psParseProofScriptInductiveConstructorsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (constructorsRev : List PsSyntaxInductiveConstructor) :
    Except PsParseError
      (PsParseResult (List PsSyntaxInductiveConstructor)) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      if psTokenCursorAtText cursor "}" then
        Except.ok {
          value := constructorsRev.reverse
          cursor := cursor
        }
      else
        match psTokenCursorExpectText cursor "|" with
        | Except.error error => Except.error error
        | Except.ok bar =>
            match psTokenCursorExpectKind
                bar.cursor
                PsTokenKind.identifier with
            | Except.error error => Except.error error
            | Except.ok name =>
                match psParseProofScriptBindersWithFuel
                    name.cursor.remaining.length
                    name.cursor
                    [] with
                | Except.error error => Except.error error
                | Except.ok fields =>
                    match psTokenCursorExpectText fields.cursor ";" with
                    | Except.error error => Except.error error
                    | Except.ok semi =>
                        let sourceName : PsSyntaxName := {
                          segments := [name.token.text]
                          span := name.token.span
                        }
                        let constructor : PsSyntaxInductiveConstructor := {
                          name := sourceName
                          fields := fields.value
                          span := {
                            start := bar.token.span.start
                            stop := semi.token.span.stop
                          }
                        }
                        psParseProofScriptInductiveConstructorsWithFuel
                          remaining
                          semi.cursor
                          (List.cons constructor constructorsRev)

def psParseProofScriptStructureField
    (cursor : PsTokenCursor) :
    Except PsParseError
      (PsParseResult (PsSyntaxBinderHead × PsSyntaxTerm)) :=
  if psTokenCursorAtBinderStart cursor then
    match psParseProofScriptBinder cursor with
    | Except.error error => Except.error error
    | Except.ok field =>
        match psTokenCursorExpectText field.cursor ";" with
        | Except.error error => Except.error error
        | Except.ok semi =>
            Except.ok {
              value := field.value
              cursor := semi.cursor
            }
  else
    match psTokenCursorExpectKind cursor PsTokenKind.identifier with
    | Except.error error => Except.error error
    | Except.ok name =>
        match psTokenCursorExpectText name.cursor ":" with
        | Except.error error => Except.error error
        | Except.ok afterColon =>
            match psParseProofScriptTerm afterColon.cursor with
            | Except.error error => Except.error error
            | Except.ok type =>
                match psTokenCursorExpectText type.cursor ";" with
                | Except.error error => Except.error error
                | Except.ok semi =>
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
                      value := Prod.mk head type.value
                      cursor := semi.cursor
                    }

def psParseProofScriptStructureFieldsWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (fieldsRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsParseError
      (PsParseResult
        (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      if psTokenCursorAtText cursor "}" then
        Except.ok {
          value := fieldsRev.reverse
          cursor := cursor
        }
      else
        match psParseProofScriptStructureField cursor with
        | Except.error error => Except.error error
        | Except.ok field =>
            psParseProofScriptStructureFieldsWithFuel
              remaining
              field.cursor
              (List.cons field.value fieldsRev)

def psParseProofScriptStructureDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorExpectText cursor "structure" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseSyntaxName keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psParseProofScriptBindersWithFuel
              name.cursor.remaining.length
              name.cursor
              [] with
          | Except.error error => Except.error error
          | Except.ok params =>
              match psTokenCursorExpectText params.cursor "where" with
              | Except.error error => Except.error error
              | Except.ok afterWhere =>
                  match psTokenCursorExpectText afterWhere.cursor "{" with
                  | Except.error error => Except.error error
                  | Except.ok afterOpen =>
                      match
                          psParseProofScriptStructureFieldsWithFuel
                            afterOpen.cursor.remaining.length
                            afterOpen.cursor
                            [] with
                      | Except.error error => Except.error error
                      | Except.ok fields =>
                          match fields.value with
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
                          | _ =>
                              match psTokenCursorExpectText
                                  fields.cursor
                                  "}" with
                              | Except.error error => Except.error error
                              | Except.ok close =>
                                  let finalCursor :=
                                    psParseOptionalSemicolon close.cursor
                                  Except.ok {
                                    value :=
                                      PsSyntaxDeclaration.structureDecl
                                        name.value
                                        params.value
                                        fields.value
                                        {
                                          start := keyword.token.span.start
                                          stop := close.token.span.stop
                                        }
                                    cursor := finalCursor
                                  }

def psParseProofScriptInductiveDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorExpectText cursor "inductive" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseSyntaxName keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psParseProofScriptBindersWithFuel
              name.cursor.remaining.length
              name.cursor
              [] with
          | Except.error error => Except.error error
          | Except.ok params =>
              let parseAfterResult :=
                fun
                  (resultType : Option PsSyntaxTerm)
                  (afterResult : PsTokenCursor) =>
                match psTokenCursorExpectText afterResult "where" with
                | Except.error error => Except.error error
                | Except.ok afterWhere =>
                    match psTokenCursorExpectText afterWhere.cursor "{" with
                    | Except.error error => Except.error error
                    | Except.ok afterOpen =>
                        match psParseProofScriptInductiveConstructorsWithFuel
                            afterOpen.cursor.remaining.length
                            afterOpen.cursor
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
                                match psTokenCursorExpectText
                                    constructors.cursor
                                    "}" with
                                | Except.error error => Except.error error
                                | Except.ok close =>
                                    let finalCursor :=
                                      psParseOptionalSemicolon close.cursor;
                                    Except.ok {
                                      value :=
                                        PsSyntaxDeclaration.inductiveDecl
                                          name.value
                                          params.value
                                          resultType
                                          constructors.value
                                          {
                                            start := keyword.token.span.start
                                            stop := close.token.span.stop
                                          }
                                      cursor := finalCursor
                                    };
              if psTokenCursorAtText params.cursor ":" then
                match psTokenCursorAdvance params.cursor with
                | none =>
                    Except.error
                      (PsParseError.unexpectedEnd "inductive result type")
                | some afterColon =>
                    match psParseProofScriptTerm afterColon.cursor with
                    | Except.error error => Except.error error
                    | Except.ok resultType =>
                        parseAfterResult
                          (some resultType.value)
                          resultType.cursor
              else
                parseAfterResult none params.cursor

def psParseProofScriptDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "declaration")
  | some keyword =>
      if keyword.text == "inductive" then
        psParseProofScriptInductiveDeclaration cursor
      else if keyword.text == "structure" then
        psParseProofScriptStructureDeclaration cursor
      else
        let isPartial := keyword.text == "partial";
        let isDefinition := keyword.text == "def";
        let isTheorem := keyword.text == "theorem";
        if psProofScriptBoolNot (isPartial || isDefinition || isTheorem) then
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
              | some afterKeyword => Except.ok afterKeyword.cursor;
          match afterKind with
          | Except.error error => Except.error error
          | Except.ok afterKeyword =>
              match psParseSyntaxName afterKeyword with
              | Except.error error => Except.error error
              | Except.ok name =>
                  match psParseProofScriptBindersWithFuel
                      name.cursor.remaining.length
                      name.cursor
                      [] with
                  | Except.error error => Except.error error
                  | Except.ok binders =>
                      match psTokenCursorExpectText binders.cursor ":" with
                      | Except.error error => Except.error error
                      | Except.ok afterColon =>
                          match psParseProofScriptTerm afterColon.cursor with
                          | Except.error error => Except.error error
                          | Except.ok type =>
                              match psTokenCursorExpectText
                                  type.cursor
                                  ":=" with
                              | Except.error error => Except.error error
                              | Except.ok afterAssign =>
                                  match psParseProofScriptTerm
                                      afterAssign.cursor with
                                  | Except.error error =>
                                      Except.error error
                                  | Except.ok value =>
                                      match psTokenCursorExpectText
                                          value.cursor
                                          ";" with
                                      | Except.error error =>
                                          Except.error error
                                      | Except.ok afterSemi =>
                                          let span := {
                                            start := keyword.span.start
                                            stop := afterSemi.token.span.stop
                                          }
                                          let declaration :=
                                            if isPartial then
                                              PsSyntaxDeclaration.partialDefinition
                                                name.value binders.value type.value value.value span
                                            else if isDefinition then
                                              PsSyntaxDeclaration.definition
                                                name.value binders.value type.value value.value span
                                            else
                                              PsSyntaxDeclaration.theoremDecl
                                                name.value binders.value type.value value.value span
                                          Except.ok {
                                            value := declaration
                                            cursor := afterSemi.cursor
                                          }


def psParseProofScriptImportsWithFuel
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
        match psParseProofScriptImport cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseProofScriptImportsWithFuel
              remaining
              parsed.cursor
              (List.cons parsed.value importsRev)
      else
        Except.ok {
          value := importsRev.reverse
          cursor := cursor
        }

def psParseProofScriptDeclarationsWithFuel
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
        match psParseProofScriptDeclaration cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseProofScriptDeclarationsWithFuel
              remaining
              parsed.cursor
              (List.cons parsed.value declarationsRev)

def psParseProofScriptTokens
    (tokens : List PsToken) :
    Except PsParseError PsSyntaxModule :=
  let cursor := psTokenCursorFromTokens tokens;
  match psParseProofScriptImportsWithFuel tokens.length cursor [] with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match psParseProofScriptDeclarationsWithFuel
          tokens.length
          imports.cursor
          [] with
      | Except.error error => Except.error error
      | Except.ok declarations =>
          Except.ok {
            imports := imports.value
            declarations := declarations.value
          }

inductive PsProofScriptFrontendError where
  | lex (error : PsLexError)
  | parse (error : PsParseError)

def psParseProofScriptSource
    (source : String) :
    Except PsProofScriptFrontendError PsSyntaxModule :=
  match psLex source with
  | Except.error error =>
      Except.error (PsProofScriptFrontendError.lex error)
  | Except.ok tokens =>
      match psParseProofScriptTokens tokens with
      | Except.error error =>
          Except.error (PsProofScriptFrontendError.parse error)
      | Except.ok module => Except.ok module
