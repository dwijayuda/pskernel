import Ps.Syntax.Pscv0.Read
import Ps.Syntax.Pscv0.Data

-- The annotation parser owns nested terms; the declaration consumes only its
-- own assignment token. No scan to the first top-level := is involved.
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
            else psPscv0ParameterGroups (psPscv0ParseTerm true) (psPscv0ParseTerm false)
              (Nat.succ (psParseListLength name.cursor.remaining)) true
              (psStringEq keyword.token.text "function") false name.cursor [];
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
                    match psPscv0ReadAnnotation true colon.cursor with
                    | Except.error error => Except.error error
                    | Except.ok resultType =>
                        match psPscv0Expect resultType.cursor ":=" with
                        | Except.error error => Except.error error
                        | Except.ok assign =>
                            match psPscv0ParseDefinitionBody assign.cursor with
                            | Except.error error => Except.error (psPscv0ParseError error)
                            | Except.ok body =>
                                let span := PsSourceSpan.mk keyword.token.span.start
                                  (psProofScriptTermStop body.value);
                                let declaration : PsSyntaxDeclaration :=
                                  if psStringEq keyword.token.text "theorem" then
                                    PsSyntaxDeclaration.theoremDecl name.value binders.value
                                      resultType.value body.value span
                                  else PsSyntaxDeclaration.definition name.value binders.value
                                    resultType.value body.value span;
                                Except.ok (PsParseResult.mk declaration body.cursor)
              else Except.error "PSCV0-NULLARY-DECLARATION-NOT-YET-SUPPORTED"

def psPscv0ReadSelectedDeclaration (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) :=
  (psPscv0ReadDataDeclaration cursor).mapError psPscv0ParseError

def psPscv0ReadDeclaration (cursor : PsTokenCursor) :
    Except String (PsParseResult PsSyntaxDeclaration) :=
  if psTokenCursorAtText cursor "partial" then Except.error "PSCV0-PARTIAL-EXCLUDED"
  else if psTokenCursorAtText cursor "unsafe" then Except.error "PSCV0-UNSAFE-EXCLUDED"
  else if psTokenCursorAtText cursor "axiom" then Except.error "PSCV0-SOURCE-AXIOM-EXCLUDED"
  else if psTokenCursorAtText cursor "verify" then Except.error "PSCV0-VERIFY-REMOVED"
  else if psTokenCursorAtText cursor "ghost" then Except.error "PSCV0-GHOST-REMOVED"
  else if psTokenCursorAtText cursor "def" then psPscv0ReadValueDeclaration cursor
  else if psTokenCursorAtText cursor "const" then psPscv0ReadValueDeclaration cursor
  else if psTokenCursorAtText cursor "function" then psPscv0ReadValueDeclaration cursor
  else if psTokenCursorAtText cursor "structure" then psPscv0ReadSelectedDeclaration cursor
  else if psTokenCursorAtText cursor "inductive" then psPscv0ReadSelectedDeclaration cursor
  else if psTokenCursorAtText cursor "theorem" then psPscv0ReadValueDeclaration cursor
  else Except.error "PSCV0-V7-COMMAND-NOT-YET-SUPPORTED"

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
