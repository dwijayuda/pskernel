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
        match psParseSimpleTerm cursor with
        | Except.error error => Except.error error
        | Except.ok argument =>
            if psTokenCursorAtText argument.cursor "," then
              match psTokenCursorAdvance argument.cursor with
              | none => Except.error (PsParseError.unexpectedEnd "term")
              | some comma =>
                  psParseProofScriptCallArgsWithFuel
                    remaining
                    comma.cursor
                    (argument.value :: argsRev)
            else
              match psTokenCursorExpectText argument.cursor ")" with
              | Except.error error => Except.error error
              | Except.ok close =>
                  Except.ok {
                    args := (argument.value :: argsRev).reverse
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

def psParseProofScriptSimpleApplication
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psParseSimpleTerm cursor with
  | Except.error error => Except.error error
  | Except.ok first =>
      if psTokenCursorAtText first.cursor "("
          && psProofScriptCallAdjacent first.value first.cursor then
        match psTokenCursorAdvance first.cursor with
        | none => Except.error (PsParseError.unexpectedEnd "(")
        | some opening =>
            match psParseProofScriptCallArgsWithFuel
                first.cursor.remaining.length
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
              match psParseProofScriptSimpleApplication afterColon.cursor with
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
              (parsed.value :: bindersRev)
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

def psParseProofScriptTermWithFuel :
    Nat ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm)
  | 0, _ => Except.error PsParseError.fuelExhausted
  | remaining + 1, cursor =>
      if psTokenCursorAtText cursor "let" then
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
      else if psTokenCursorAtText cursor "(" then
        match psParseProofScriptBinder cursor with
        | Except.ok binder =>
            if psTokenCursorAtArrow binder.cursor then
              psParseProofScriptDependentArrowTail
                (psParseProofScriptTermWithFuel remaining)
                binder
            else
              match psParseProofScriptSimpleApplication cursor with
              | Except.error error => Except.error error
              | Except.ok domain =>
                  psParseProofScriptArrowTail
                    (psParseProofScriptTermWithFuel remaining)
                    domain
        | Except.error _ =>
            match psParseProofScriptSimpleApplication cursor with
            | Except.error error => Except.error error
            | Except.ok domain =>
                psParseProofScriptArrowTail
                  (psParseProofScriptTermWithFuel remaining)
                  domain
      else
        match psParseProofScriptSimpleApplication cursor with
        | Except.error error => Except.error error
        | Except.ok domain =>
            psParseProofScriptArrowTail
              (psParseProofScriptTermWithFuel remaining)
              domain

def psParseProofScriptTerm
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseProofScriptTermWithFuel (cursor.remaining.length + 1) cursor

def psParseProofScriptDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorPeek cursor with
  | none => Except.error (PsParseError.unexpectedEnd "declaration")
  | some keyword =>
      let isDefinition := keyword.text == "def"
      let isTheorem := keyword.text == "theorem"
      if !(isDefinition || isTheorem) then
        Except.error
          (PsParseError.expectedText
            "def or theorem"
            keyword.text
            keyword.span)
      else
        match psTokenCursorAdvance cursor with
        | none => Except.error (PsParseError.unexpectedEnd "declaration name")
        | some afterKeyword =>
            match psParseSyntaxName afterKeyword.cursor with
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
                            match psTokenCursorExpectText type.cursor ":=" with
                            | Except.error error => Except.error error
                            | Except.ok afterAssign =>
                                match psParseProofScriptTerm afterAssign.cursor with
                                | Except.error error => Except.error error
                                | Except.ok value =>
                                    match psTokenCursorExpectText value.cursor ";" with
                                    | Except.error error => Except.error error
                                    | Except.ok afterSemi =>
                                        let span := {
                                          start := keyword.span.start
                                          stop := afterSemi.token.span.stop
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
                                            cursor := afterSemi.cursor
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
              (parsed.value :: importsRev)
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
              (parsed.value :: declarationsRev)

def psParseProofScriptTokens
    (tokens : List PsToken) :
    Except PsParseError PsSyntaxModule :=
  let cursor := psTokenCursorFromTokens tokens
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
