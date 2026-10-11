import Ps.Syntax.Pscv0.Surface

structure PsPscv0Collected where
  tokens : List PsToken
  cursor : PsTokenCursor
  stop : PsSourcePos
structure PsPscv0DoRead where
  block : PsPscv0DoBlock
  cursor : PsTokenCursor
structure PsPscv0Rewritten where
  tokens : List PsToken
  blocks : List PsPscv0DoBlock

def psPscv0Expect (cursor : PsTokenCursor) (text : String) : Except String PsTokenRead :=
  match psTokenCursorExpectText cursor text with
  | Except.error error => Except.error (psPscv0ParseError error)
  | Except.ok value => Except.ok value

def psPscv0ClosingFor (text : String) : Option String :=
  if psStringEq text "(" then Option.some ")"
  else if psStringEq text "{" then Option.some "}"
  else if psStringEq text "[" then Option.some "]"
  else Option.none

def psPscv0IsClosing (text : String) : Bool :=
  if psStringEq text ")" then true
  else if psStringEq text "}" then true
  else psStringEq text "]"

def psPscv0CollectItem (braced : Bool) (indent : Nat) (fuel : Nat)
    (cursor : PsTokenCursor) (closing : List String) (tokensRev : List PsToken)
    (stop : PsSourcePos) : Except String PsPscv0Collected :=
  match fuel with
  | 0 => Except.error "PSCV0-DO-TOKEN-BUDGET"
  | remaining + 1 =>
      let finished : Except String PsPscv0Collected :=
        match closing with
        | _ :: _ => Except.error "PSCV0-DO-UNCLOSED-DELIMITER"
        | [] => Except.ok (PsPscv0Collected.mk (psListReverse tokensRev) cursor stop);
      if psTokenCursorDone cursor then finished
      else
        match psTokenCursorAdvance cursor with
        | none => finished
        | some next =>
            let token := next.token;
            let lineBoundary :=
              if Nat.ble (Nat.succ stop.line) token.span.start.line then
                if braced then true else Nat.ble token.span.start.column indent
              else false;
            let hasTokens := if psListIsEmpty tokensRev then false else true;
            let boundary :=
              if psListIsEmpty closing then
                if psStringEq token.text "}" then true
                else if hasTokens then lineBoundary else false
              else false;
            if boundary then finished
            else if psStringEq token.text ";" then Except.error "PSCV0-DO-NEWLINE-REQUIRED"
            else if psStringEq token.text "do" then Except.error "PSCV0-DO-NESTING-NOT-YET-SUPPORTED"
            else
              match psPscv0ClosingFor token.text with
              | some close =>
                  if Nat.ble 64 (psListLength closing) then Except.error "PSCV0-DO-DELIMITER-BUDGET"
                  else psPscv0CollectItem braced indent remaining next.cursor
                    (List.cons close closing) (List.cons token tokensRev) token.span.stop
              | none =>
                  if psPscv0IsClosing token.text then
                    match closing with
                    | [] => Except.error "PSCV0-DO-UNEXPECTED-DELIMITER"
                    | expected :: rest =>
                        if psStringEq expected token.text then
                          psPscv0CollectItem braced indent remaining next.cursor
                            rest (List.cons token tokensRev) token.span.stop
                        else Except.error "PSCV0-DO-MISMATCHED-DELIMITER"
                  else psPscv0CollectItem braced indent remaining next.cursor
                    closing (List.cons token tokensRev) token.span.stop

def psPscv0DoUnsupportedHead (text : String) : Bool :=
  if psStringEq text "mut" then true
  else if psStringEq text "for" then true
  else if psStringEq text "while" then true
  else if psStringEq text "try" then true
  else if psStringEq text "catch" then true
  else if psStringEq text "finally" then true
  else if psStringEq text "throw" then true
  else if psStringEq text "break" then true
  else if psStringEq text "continue" then true
  else if psStringEq text "erased" then true
  else psStringEq text "assert"

def psPscv0ReadDoBinding (proofScript : Bool) (span : PsSourceSpan)
    (cursor : PsTokenCursor) : Except String PsPscv0DoItem :=
  match psTokenCursorExpectKind cursor PsTokenKind.identifier with
  | Except.error error => Except.error (psPscv0ParseError error)
  | Except.ok nameToken =>
      if psStringEq nameToken.token.text "mut" then Except.error "PSCV0-DO-MUTATION-NOT-YET-SUPPORTED"
      else
        let name := PsSyntaxName.mk [nameToken.token.text] nameToken.token.span;
        if psTokenCursorAtText nameToken.cursor ":" then
          match psPscv0Expect nameToken.cursor ":" with
          | Except.error error => Except.error error
          | Except.ok colon =>
              match psPscv0ReadAnnotation proofScript colon.cursor with
              | Except.error error => Except.error error
              | Except.ok annotation =>
                  match psPscv0Expect annotation.cursor ":=" with
                  | Except.error _ => Except.error "PSCV0-DO-TYPED-BIND-NOT-YET-SUPPORTED"
                  | Except.ok assign =>
                      match psPscv0ReadCompleteTerm proofScript assign.cursor with
                      | Except.error error => Except.error error
                      | Except.ok value => Except.ok (PsPscv0DoItem.letValue name (Option.some annotation.value) value span)
        else
          match psTokenCursorAdvance nameToken.cursor with
          | none => Except.error "PSCV0-DO-BINDING-OPERATOR"
          | some operator =>
              match psPscv0ReadCompleteTerm proofScript operator.cursor with
              | Except.error error => Except.error error
              | Except.ok value =>
                  if psStringEq operator.token.text ":=" then Except.ok (PsPscv0DoItem.letValue name Option.none value span)
                  else if psStringEq operator.token.text "←" then Except.ok (PsPscv0DoItem.bind name value span)
                  else if psStringEq operator.token.text "<-" then Except.ok (PsPscv0DoItem.bind name value span)
                  else Except.error "PSCV0-DO-BINDING-OPERATOR"

def psPscv0ReadDoItem (proofScript : Bool) (collected : PsPscv0Collected) : Except String PsPscv0DoItem :=
  let cursor := PsTokenCursor.mk collected.tokens;
  match psTokenCursorAdvance cursor with
  | none => Except.error "PSCV0-DO-EMPTY-ITEM"
  | some first =>
      let span := PsSourceSpan.mk first.token.span.start collected.stop;
      if psPscv0TokenNamesContain first.cursor.remaining "return" then Except.error "PSCV0-DO-NESTED-RETURN-NOT-YET-SUPPORTED"
      else if psPscv0DoUnsupportedHead first.token.text then Except.error (psPscv0Cat ["PSCV0-DO-UNSUPPORTED: ", first.token.text])
      else if psStringEq first.token.text "let" then psPscv0ReadDoBinding proofScript span first.cursor
      else if psStringEq first.token.text "return" then
        match psPscv0ReadCompleteTerm proofScript first.cursor with
        | Except.error error => Except.error error
        | Except.ok value => Except.ok (PsPscv0DoItem.returnValue value span)
      else
        match psPscv0ReadCompleteTerm proofScript cursor with
        | Except.error error => Except.error error
        | Except.ok value => Except.ok (PsPscv0DoItem.action value span)

def psPscv0ReadDoSeq (proofScript braced : Bool) (declarationColumn indent : Nat)
    (start : PsSourcePos) (fuel : Nat) (cursor : PsTokenCursor)
    (itemsRev : List PsPscv0DoItem) (stop : PsSourcePos) : Except String PsPscv0DoRead :=
  match fuel with
  | 0 => Except.error "PSCV0-DO-ITEM-BUDGET"
  | remaining + 1 =>
      let nativeEnd :=
        if braced then false
        else if psTokenCursorDone cursor then true
        else
          match psTokenCursorPeek cursor with
          | none => true
          | some token => Nat.ble token.span.start.column declarationColumn;
      if nativeEnd then
        if psListIsEmpty itemsRev then Except.error "PSCV0-DO-EMPTY"
        else Except.ok (PsPscv0DoRead.mk
          (PsPscv0DoBlock.mk (psListReverse itemsRev) (PsSourceSpan.mk start stop)) cursor)
      else if psTokenCursorAtText cursor "}" then
        if braced then
          if psListIsEmpty itemsRev then Except.error "PSCV0-DO-EMPTY"
          else
            match psPscv0Expect cursor "}" with
            | Except.error error => Except.error error
            | Except.ok close => Except.ok (PsPscv0DoRead.mk
                (PsPscv0DoBlock.mk (psListReverse itemsRev)
                  (PsSourceSpan.mk start close.token.span.stop)) close.cursor)
        else Except.error "PSCV0-DO-NATIVE-UNEXPECTED-CLOSE"
      else if psTokenCursorDone cursor then Except.error "PSCV0-DO-MISSING-CLOSE"
      else
        match psPscv0CollectItem braced indent 65536 cursor [] [] stop with
        | Except.error error => Except.error error
        | Except.ok collected =>
            match psPscv0ReadDoItem proofScript collected with
            | Except.error error => Except.error error
            | Except.ok item => psPscv0ReadDoSeq proofScript braced declarationColumn indent start
                remaining collected.cursor (List.cons item itemsRev) collected.stop

def psPscv0ReadDo (proofScript : Bool) (declarationColumn : Nat)
    (keyword : PsTokenRead) : Except String PsPscv0DoRead :=
  let hasBrace := psTokenCursorAtText keyword.cursor "{";
  if proofScript then
    if hasBrace then
      match psPscv0Expect keyword.cursor "{" with
      | Except.error error => Except.error error
      | Except.ok opening => psPscv0ReadDoSeq true true declarationColumn 0 keyword.token.span.start
          513 opening.cursor [] opening.token.span.stop
    else Except.error "PSCV0-DO-BRACES-REQUIRED"
  else if hasBrace then
    match psPscv0Expect keyword.cursor "{" with
    | Except.error error => Except.error error
    | Except.ok opening => psPscv0ReadDoSeq false true declarationColumn 0 keyword.token.span.start
        513 opening.cursor [] opening.token.span.stop
  else
    match psTokenCursorPeek keyword.cursor with
    | none => Except.error "PSCV0-DO-EMPTY"
    | some first =>
        if Nat.ble (Nat.succ keyword.token.span.stop.line) first.span.start.line then
          psPscv0ReadDoSeq false false declarationColumn first.span.start.column
            keyword.token.span.start 513 keyword.cursor [] keyword.token.span.stop
        else Except.error "PSCV0-DO-NATIVE-LAYOUT-REQUIRED"

def psPscv0DoSlot : String := "$pscv0Do"

def psPscv0RewriteTokens (proofScript : Bool) (fuel : Nat)
    (cursor : PsTokenCursor) (previous : String) (declarationColumn : Nat)
    (tokensRev : List PsToken) (blocksRev : List PsPscv0DoBlock) : Except String PsPscv0Rewritten :=
  match fuel with
  | 0 => Except.error "PSCV0-SOURCE-TOKEN-BUDGET"
  | remaining + 1 =>
      if psTokenCursorDone cursor then Except.ok (PsPscv0Rewritten.mk
          (psListAppend (psListReverse tokensRev) cursor.remaining) (psListReverse blocksRev))
      else
        match psTokenCursorAdvance cursor with
        | none => Except.error "PSCV0-SOURCE-UNEXPECTED-END"
        | some next =>
            let token := next.token;
            if psStringEq token.text "do" then
              if psStringEq previous ":=" then
                match psPscv0ReadDo proofScript declarationColumn next with
                | Except.error error => Except.error error
                | Except.ok parsed =>
                    let marker := PsToken.mk PsTokenKind.identifier psPscv0DoSlot parsed.block.span;
                    psPscv0RewriteTokens proofScript remaining parsed.cursor "do-body"
                      declarationColumn (List.cons marker tokensRev) (List.cons parsed.block blocksRev)
              else Except.error "PSCV0-DO-DECLARATION-BODY-ONLY"
            else
              let column :=
                if psStringEq token.text "def" then token.span.start.column
                else if psStringEq token.text "function" then token.span.start.column
                else if psStringEq token.text "const" then token.span.start.column
                else if psStringEq token.text "theorem" then token.span.start.column
                else declarationColumn;
              psPscv0RewriteTokens proofScript remaining next.cursor token.text column
                (List.cons token tokensRev) blocksRev
