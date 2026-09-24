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
                match psTokenCursorExpectText name.cursor ":" with
                | Except.error error => Except.error error
                | Except.ok afterColon =>
                    match psParseSimpleTerm afterColon.cursor with
                    | Except.error error => Except.error error
                    | Except.ok type =>
                        match psTokenCursorExpectText type.cursor ":=" with
                        | Except.error error => Except.error error
                        | Except.ok afterAssign =>
                            match psParseSimpleTerm afterAssign.cursor with
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
                                            []
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
                                            []
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
