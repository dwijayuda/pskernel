import Ps.Syntax.ParseCommon

-- Delimiters belong to the source grammar; the resulting do AST is shared.
-- At depth zero, aligned/newly outdented lines delimit completed statements.
-- Grouped, braced and bracketed subterms retain all their internal newlines.
def psParseDoExpected (expected : String) (cursor : PsTokenCursor) : PsParseError :=
  match psTokenCursorPeek cursor with
  | Option.none => PsParseError.unexpectedEnd expected
  | Option.some token => PsParseError.expectedText expected token.text token.span

def psParseDoOpenToken (text : String) : Bool :=
  if psStringEq text "(" then true
  else if psStringEq text "[" then true
  else psStringEq text "{"

def psParseDoCloseToken (text : String) : Bool :=
  if psStringEq text ")" then true
  else if psStringEq text "]" then true
  else psStringEq text "}"

def psParseDoArrow (cursor : PsTokenCursor) : Bool :=
  if psTokenCursorAtText cursor "<-" then true
  else psTokenCursorAtText cursor "←"

def psParseDoTakeStatement
    (fuel : Nat) (start : PsSourcePos) :
    Nat -> PsTokenCursor -> List PsToken ->
    PsParseResult (List PsToken) :=
  match fuel with
  | Nat.zero =>
      fun (_depth : Nat) (cursor : PsTokenCursor) (tokensRev : List PsToken) =>
        PsParseResult.mk (psParseListReverse tokensRev) cursor
  | Nat.succ remaining =>
      fun (depth : Nat) (cursor : PsTokenCursor) (tokensRev : List PsToken) =>
        let smaller :
            Nat -> PsTokenCursor -> List PsToken ->
            PsParseResult (List PsToken) :=
          psParseDoTakeStatement remaining start;
        match psTokenCursorPeek cursor with
        | Option.none => PsParseResult.mk (psParseListReverse tokensRev) cursor
        | Option.some token =>
            let stop :=
              if psTokenKindEq token.kind PsTokenKind.endOfInput then true
              else if Nat.beq depth 0 then
                if psParseDoCloseToken token.text then true
                else if psStringEq token.text ";" then true
                else if Nat.ble (Nat.succ start.line) token.span.start.line then
                  Nat.ble token.span.start.column start.column
                else false
              else false;
            if stop then PsParseResult.mk (psParseListReverse tokensRev) cursor
            else
              match psTokenCursorAdvance cursor with
              | Option.none => PsParseResult.mk (psParseListReverse tokensRev) cursor
              | Option.some read =>
                  let nextDepth :=
                    if psParseDoOpenToken token.text then Nat.succ depth
                    else if psParseDoCloseToken token.text then Nat.sub depth 1
                    else depth;
                  smaller nextDepth read.cursor (List.cons token tokensRev)

inductive PsParseDoHead where
  | binding
      (name : PsSyntaxName) (annotation : Option PsSyntaxTerm)
      (value : PsSyntaxTerm) (monadic : Bool) (span : PsSourceSpan)
  | action (value : PsSyntaxTerm)
  | returnValue (value : PsSyntaxTerm) (span : PsSourceSpan)

def psParseDoCompleteTerm
    (parseTerm :
      PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (cursor : PsTokenCursor) : Except PsParseError PsSyntaxTerm :=
  match parseTerm cursor with
  | Except.error error => Except.error error
  | Except.ok value =>
      if psTokenCursorDone value.cursor then Except.ok value.value
      else Except.error (psParseDoExpected "end of do statement" value.cursor)

def psParseDoBindingValue
    (parseTerm :
      PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (start : PsSourcePos) (name : PsSyntaxName)
    (annotation : Option PsSyntaxTerm) (cursor : PsTokenCursor) :
    Except PsParseError PsParseDoHead :=
  let monadic := psParseDoArrow cursor;
  if if monadic then true else psTokenCursorAtText cursor ":=" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "do binding value")
    | Option.some separator =>
        match psParseDoCompleteTerm parseTerm separator.cursor with
        | Except.error error => Except.error error
        | Except.ok value =>
            Except.ok
              (PsParseDoHead.binding name annotation value monadic
                { start := start, stop := (psSyntaxTermSpan value).stop })
  else Except.error (psParseDoExpected ":= or <-" cursor)

def psParseDoStatement
    (parseTerm :
      PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (cursor : PsTokenCursor) : Except PsParseError PsParseDoHead :=
  if psTokenCursorAtText cursor "return" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "return value")
    | Option.some keyword =>
        match psParseDoCompleteTerm parseTerm keyword.cursor with
        | Except.error error => Except.error error
        | Except.ok value =>
            Except.ok (PsParseDoHead.returnValue value
              { start := keyword.token.span.start, stop := (psSyntaxTermSpan value).stop })
  else if psTokenCursorAtText cursor "let" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "do binding")
    | Option.some keyword =>
        match psTokenCursorExpectKind keyword.cursor PsTokenKind.identifier with
        | Except.error error => Except.error error
        | Except.ok name =>
            let sourceName : PsSyntaxName := {
              segments := [name.token.text]
              span := name.token.span
            };
            if psStringEq name.token.text "mut" then
              Except.error (psParseDoExpected "immutable do binding" keyword.cursor)
            else if psTokenCursorAtText name.cursor ":" then
              match psTokenCursorAdvance name.cursor with
              | Option.none => Except.error (PsParseError.unexpectedEnd "binding type")
              | Option.some colon =>
                  match parseTerm colon.cursor with
                  | Except.error error => Except.error error
                  | Except.ok annotation =>
                      psParseDoBindingValue parseTerm keyword.token.span.start sourceName
                        (Option.some annotation.value) annotation.cursor
            else
              psParseDoBindingValue parseTerm keyword.token.span.start sourceName
                Option.none name.cursor
  else
    match psParseDoCompleteTerm parseTerm cursor with
    | Except.error error => Except.error error
    | Except.ok value => Except.ok (PsParseDoHead.action value)

def psParseDoHeadSpan (head : PsParseDoHead) : PsSourceSpan :=
  match head with
  | PsParseDoHead.binding _ _ _ _ span => span
  | PsParseDoHead.returnValue _ span => span
  | PsParseDoHead.action value => psSyntaxTermSpan value

def psParseDoCloseHead
    (head : PsParseDoHead) (tail : Option PsSyntaxTerm) :
    Except PsParseError PsSyntaxTerm :=
  match head with
  | PsParseDoHead.returnValue value span =>
      match tail with
      | Option.none => Except.ok (PsSyntaxTerm.doReturnE value span)
      | Option.some rest =>
          Except.error (PsParseError.expectedText
            "terminal return in the current do subset" "following statement"
            (psSyntaxTermSpan rest))
  | PsParseDoHead.action value =>
      match tail with
      | Option.none => Except.ok value
      | Option.some rest =>
          Except.ok (PsSyntaxTerm.doThenE value rest
            (psSyntaxSpanJoin (psSyntaxTermSpan value) (psSyntaxTermSpan rest)))
  | PsParseDoHead.binding name annotation value monadic span =>
      match tail with
      | Option.none =>
          Except.error (PsParseError.unexpectedEnd "statement after do binding")
      | Option.some rest =>
          let span := psSyntaxSpanJoin span (psSyntaxTermSpan rest);
          if monadic then
            Except.ok (PsSyntaxTerm.doBindE name annotation value rest span)
          else Except.ok (PsSyntaxTerm.letE name annotation value rest span)

def psParseDoBody
    (parseTerm :
      PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (allowSemicolon braced : Bool) (column : Nat) (fuel : Nat) :
    PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | Nat.zero =>
      fun (_cursor : PsTokenCursor) => Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (cursor : PsTokenCursor) =>
        let smaller :
            PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm) :=
          psParseDoBody parseTerm allowSemicolon braced column remaining;
        match psTokenCursorPeek cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "do statement")
        | Option.some first =>
            let chunk := psParseDoTakeStatement
              (Nat.succ (psParseListLength cursor.remaining)) first.span.start 0 cursor [];
            match psParseDoStatement parseTerm (PsTokenCursor.mk chunk.value) with
            | Except.error error => Except.error error
            | Except.ok head =>
                let next :
                    Except PsParseError (Prod Bool PsTokenCursor) :=
                  if psTokenCursorAtText chunk.cursor ";" then
                    if allowSemicolon then
                      match psTokenCursorAdvance chunk.cursor with
                      | Option.none => Except.error (PsParseError.unexpectedEnd "do statement")
                      | Option.some separator => Except.ok (Prod.mk true separator.cursor)
                    else Except.error
                      (psParseDoExpected "newline-separated do statements, without semicolon" chunk.cursor)
                  else Except.ok (Prod.mk false chunk.cursor);
                match next with
                | Except.error error => Except.error error
                | Except.ok next =>
                    let hasNext :=
                      if psTokenCursorDone next.snd then false
                      else if psTokenCursorAtText next.snd "}" then false
                      else if braced then true
                      else
                        match psTokenCursorPeek next.snd with
                        | Option.none => false
                        | Option.some token =>
                            if psParseDoCloseToken token.text then false
                            else if next.fst then
                              if Nat.beq token.span.start.line (psParseDoHeadSpan head).stop.line then true
                              else Nat.ble column token.span.start.column
                            else
                              if Nat.ble (Nat.succ (psParseDoHeadSpan head).stop.line)
                                  token.span.start.line then
                                Nat.beq column token.span.start.column
                              else false;
                    if hasNext then
                      match smaller next.snd with
                      | Except.error error => Except.error error
                      | Except.ok tail =>
                          match psParseDoCloseHead head (Option.some tail.value) with
                          | Except.error error => Except.error error
                          | Except.ok value => Except.ok (PsParseResult.mk value tail.cursor)
                    else
                      match psParseDoCloseHead head Option.none with
                      | Except.error error => Except.error error
                      | Except.ok value => Except.ok (PsParseResult.mk value next.snd)

def psParseDo
    (parseTerm :
      PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (allowSemicolon requireBraces : Bool)
    (start : PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  let braced := psTokenCursorAtText cursor "{";
  if if requireBraces then if braced then false else true else false then
    Except.error (psParseDoExpected "{" cursor)
  else
    let bodyCursor :=
      if braced then
        match psTokenCursorAdvance cursor with
        | Option.none => cursor
        | Option.some opening => opening.cursor
      else cursor;
    match psTokenCursorPeek bodyCursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "do statement")
    | Option.some first =>
        match psParseDoBody parseTerm allowSemicolon braced first.span.start.column
            (Nat.succ (psParseListLength bodyCursor.remaining)) bodyCursor with
        | Except.error error => Except.error error
        | Except.ok body =>
            if braced then
              match psTokenCursorExpectText body.cursor "}" with
              | Except.error error => Except.error error
              | Except.ok close =>
                  Except.ok (PsParseResult.mk
                    (PsSyntaxTerm.doE body.value
                      { start := start, stop := close.token.span.stop }) close.cursor)
            else
              Except.ok (PsParseResult.mk
                (PsSyntaxTerm.doE body.value
                  { start := start, stop := (psSyntaxTermSpan body.value).stop }) body.cursor)
