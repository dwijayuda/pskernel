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
    || token.text == "where"
    || token.text == "then"
    || token.text == "else"

def psLeanCanStartSimpleArgument (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | none => false
  | some token =>
      !psLeanReservedApplicationToken token
        && (psTokenKindEq token.kind PsTokenKind.identifier
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

def psParseLeanExplicitBinder
    (cursor : PsTokenCursor) :
    Except PsParseError
      (PsParseResult (PsSyntaxBinderHead × PsSyntaxTerm)) :=
  match psTokenCursorExpectText cursor "(" with
  | Except.error error => Except.error error
  | Except.ok open =>
      match psTokenCursorExpectKind open.cursor PsTokenKind.identifier with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psTokenCursorExpectText name.cursor ":" with
          | Except.error error => Except.error error
          | Except.ok afterColon =>
              match psParseLeanSimpleApplication afterColon.cursor with
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
                          start := open.token.span.start
                          stop := close.token.span.stop
                        }
                      }
                      Except.ok {
                        value := (binder, type.value)
                        cursor := close.cursor
                      }

def psParseLeanExplicitBindersWithFuel
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
        match psParseLeanExplicitBinder cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            psParseLeanExplicitBindersWithFuel
              remaining
              parsed.cursor
              (parsed.value :: bindersRev)
      else
        Except.ok { value := bindersRev.reverse, cursor := cursor }

def psParseLeanDeclaration
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
                match psParseLeanExplicitBindersWithFuel
                    name.cursor.remaining.length
                    name.cursor
                    [] with
                | Except.error error => Except.error error
                | Except.ok binders =>
                    match psTokenCursorExpectText binders.cursor ":" with
                    | Except.error error => Except.error error
                    | Except.ok afterColon =>
                        match psParseLeanSimpleApplication afterColon.cursor with
                        | Except.error error => Except.error error
                        | Except.ok type =>
                            match psTokenCursorExpectText type.cursor ":=" with
                            | Except.error error => Except.error error
                            | Except.ok afterAssign =>
                                match psParseLeanSimpleApplication afterAssign.cursor with
                                | Except.error error => Except.error error
                                | Except.ok value =>
                                    let span := {
                                      start := keyword.span.start
                                      stop := (psSyntaxTermSpan value.value).stop
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
