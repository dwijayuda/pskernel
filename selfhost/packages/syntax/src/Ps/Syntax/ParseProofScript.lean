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

def psParseProofScriptExplicitBinder
    (cursor : PsTokenCursor) :
    Except PsParseError
      (PsParseResult (PsSyntaxBinderHead × PsSyntaxTerm)) :=
  match psTokenCursorExpectText cursor "(" with
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
                  match psTokenCursorExpectText type.cursor ")" with
                  | Except.error error => Except.error error
                  | Except.ok close =>
                      let binderName : PsSyntaxName := {
                        segments := [name.token.text]
                        span := name.token.span
                      }
                      let binder : PsSyntaxBinderHead := {
                        name := binderName
                        kind := PsSyntaxBinderKind.explicit
                        span := {
                          start := opening.token.span.start
                          stop := close.token.span.stop
                        }
                      }
                      Except.ok {
                        value := (binder, type.value)
                        cursor := close.cursor
                      }

def psParseProofScriptExplicitBindersWithFuel
    (fuel : Nat)
    (cursor : PsTokenCursor)
    (bindersRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) :
    Except PsParseError
      (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      Except.ok { value := bindersRev.reverse, cursor := cursor }
  | remaining + 1 =>
      if psTokenCursorAtText cursor "(" then
        match psParseProofScriptExplicitBinder cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseProofScriptExplicitBindersWithFuel
              remaining
              parsed.cursor
              (parsed.value :: bindersRev)
      else
        Except.ok { value := bindersRev.reverse, cursor := cursor }

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
                match psParseProofScriptExplicitBindersWithFuel
                    name.cursor.remaining.length
                    name.cursor
                    [] with
                | Except.error error => Except.error error
                | Except.ok binders =>
                    match psTokenCursorExpectText binders.cursor ":" with
                    | Except.error error => Except.error error
                    | Except.ok afterColon =>
                        match psParseProofScriptSimpleApplication afterColon.cursor with
                        | Except.error error => Except.error error
                        | Except.ok type =>
                            match psTokenCursorExpectText type.cursor ":=" with
                            | Except.error error => Except.error error
                            | Except.ok afterAssign =>
                                match psParseProofScriptSimpleApplication afterAssign.cursor with
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
