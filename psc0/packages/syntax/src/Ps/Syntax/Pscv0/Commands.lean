import Ps.Syntax.Pscv0.Read

-- A declaration type owns the tokens before its top-level :=. The ordinary
-- expression parser's record-field/named-argument lookahead cannot own that :=.
-- Parse this bounded token slice with the SAME PSCV0 term parser and spans.
def psPscv0CollectDeclaredType (fuel : Nat) (cursor : PsTokenCursor)
    (closing : List String) (tokensRev : List PsToken) (stop : PsSourcePos) :
    Except String PsPscv0Collected :=
  match fuel with
  | 0 => Except.error "PSCV0-DECLARATION-TYPE-BUDGET"
  | remaining + 1 =>
      if psTokenCursorDone cursor then Except.error "PSCV0-DECLARATION-ASSIGN-MISSING"
      else
        match psTokenCursorAdvance cursor with
        | none => Except.error "PSCV0-DECLARATION-ASSIGN-MISSING"
        | some next =>
            let token := next.token;
            if psListIsEmpty closing then
              if psStringEq token.text ":=" then
                if psListIsEmpty tokensRev then Except.error "PSCV0-DECLARATION-TYPE-MISSING"
                else Except.ok (PsPscv0Collected.mk (psListReverse tokensRev) next.cursor stop)
              else
                match psPscv0ClosingFor token.text with
                | some close => psPscv0CollectDeclaredType remaining next.cursor
                    [close] (List.cons token tokensRev) token.span.stop
                | none =>
                    if psPscv0IsClosing token.text then Except.error "PSCV0-DECLARATION-TYPE-DELIMITER"
                    else psPscv0CollectDeclaredType remaining next.cursor []
                      (List.cons token tokensRev) token.span.stop
            else
              match psPscv0ClosingFor token.text with
              | some close => psPscv0CollectDeclaredType remaining next.cursor
                  (List.cons close closing) (List.cons token tokensRev) token.span.stop
              | none =>
                  if psPscv0IsClosing token.text then
                    match closing with
                    | [] => Except.error "PSCV0-DECLARATION-TYPE-DELIMITER"
                    | expected :: rest =>
                        if psStringEq expected token.text then
                          psPscv0CollectDeclaredType remaining next.cursor rest
                            (List.cons token tokensRev) token.span.stop
                        else Except.error "PSCV0-DECLARATION-TYPE-DELIMITER"
                  else psPscv0CollectDeclaredType remaining next.cursor closing
                    (List.cons token tokensRev) token.span.stop

def psPscv0ReadValueDeclaration (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorAdvance cursor with
  | none => Except.error "PSCV0-DECLARATION-MISSING"
  | some keyword =>
      match psParseProofScriptDeclaredName keyword.cursor with
      | Except.error error => Except.error (psPscv0ParseError error)
      | Except.ok name =>
          let bindersResult : Except PsParseError
              (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
            if psStringEq keyword.token.text "const" then
              Except.ok (PsParseResult.mk [] name.cursor)
            else psParseProofScriptDeclarationBindersWithFuel
              (Nat.succ (psParseListLength name.cursor.remaining)) name.cursor [];
          match bindersResult with
          | Except.error error => Except.error (psPscv0ParseError error)
          | Except.ok binders =>
              let signatureValid :=
                if psStringEq keyword.token.text "function" then
                  psProofScriptBindersHaveExplicit binders.value
                else true;
              if signatureValid then
                match psPscv0Expect binders.cursor ":" with
                | Except.error error => Except.error error
                | Except.ok colon =>
                    match psPscv0CollectDeclaredType 65536 colon.cursor [] [] colon.token.span.stop with
                    | Except.error error => Except.error error
                    | Except.ok typeTokens =>
                        match psPscv0ReadCompleteTerm true (PsTokenCursor.mk typeTokens.tokens) with
                        | Except.error error => Except.error error
                        | Except.ok resultType =>
                            match psParseProofScriptDefinitionBody typeTokens.cursor with
                            | Except.error error => Except.error (psPscv0ParseError error)
                            | Except.ok body =>
                                let span := PsSourceSpan.mk keyword.token.span.start
                                  (psProofScriptTermStop body.value);
                                Except.ok (PsParseResult.mk
                                  (PsSyntaxDeclaration.definition name.value binders.value resultType body.value span)
                                  body.cursor)
              else Except.error "PSCV0-NULLARY-DECLARATION-NOT-YET-SUPPORTED"

def psPscv0ReadDeclaration (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) :=
  let selected :=
    if psTokenCursorAtText cursor "def" then true
    else if psTokenCursorAtText cursor "const" then true
    else psTokenCursorAtText cursor "function";
  if selected then psPscv0ReadValueDeclaration cursor
  else
    match psParseProofScriptDeclaration cursor with
    | Except.error error => Except.error (psPscv0ParseError error)
    | Except.ok value => Except.ok value

def psPscv0ReadDeclarations (fuel : Nat) (cursor : PsTokenCursor)
    (declarationsRev : List PsSyntaxDeclaration) : Except String (List PsSyntaxDeclaration) :=
  match fuel with
  | 0 => Except.error "PSCV0-DECLARATION-COUNT-BUDGET"
  | remaining + 1 =>
      if psTokenCursorDone cursor then Except.ok (psListReverse declarationsRev)
      else
        match psPscv0ReadDeclaration cursor with
        | Except.error error => Except.error error
        | Except.ok parsed =>
            match psParseProofScriptCommandSeparator (psProofScriptDeclarationStop parsed.value) parsed.cursor with
            | Except.error error => Except.error (psPscv0ParseError error)
            | Except.ok next =>
                psPscv0ReadDeclarations remaining next (List.cons parsed.value declarationsRev)

def psPscv0ParseTokens (tokens : List PsToken) : Except String PsSyntaxModule :=
  match psParseProofScriptImportsWithFuel (psParseListLength tokens)
      (psTokenCursorFromTokens tokens) [] with
  | Except.error error => Except.error (psPscv0ParseError error)
  | Except.ok imports =>
      match psPscv0ReadDeclarations 4096 imports.cursor [] with
      | Except.error error => Except.error error
      | Except.ok declarations => Except.ok (PsSyntaxModule.mk imports.value declarations)
