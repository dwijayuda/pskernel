import Ps.Syntax.ParseProofScript

-- V7 term dispatch owns assignment boundaries. In an annotation, the caller
-- owns :=; an identifier immediately before it is still a type argument.
-- Value/call/record subterms retain their own ordinary-expression boundary.
-- Arrow codomains and let/lambda result terms inherit the enclosing category.
-- Tokens, spans, fuel, AST constructors and category-neutral readers are shared
-- with the frozen predecessor. This bounded dispatcher is adapted from its
-- ParseProofScript.lean at 0e8996d2; that historical source remains unchanged.
-- Adding a syntax family here requires an explicit v7 selection and checks.

def psPscv0CanStartNativeArgument
    (annotation : Bool)
    (span : PsSourceSpan)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | Option.none => false
  | Option.some token =>
      if psProofScriptReservedArgument token.text then
        false
      else if (if annotation then false else psTokenCursorStartsNamedAssignment cursor) then
        false
      else if psProofScriptBoolNot
          (Nat.ble (Nat.succ span.stop.byteOffset) token.span.start.byteOffset) then
        false
      else if
          if Nat.ble (Nat.succ span.stop.line) token.span.start.line then
            psProofScriptBoolNot
              (Nat.ble (Nat.succ span.start.column) token.span.start.column)
          else
            false then
        false
      else if psTokenCursorAtText cursor "(" then true
      else if psTokenCursorAtText cursor "{" then true
      else if psTokenKindEq token.kind PsTokenKind.identifier then true
      else if psTokenKindEq token.kind PsTokenKind.natural then true
      else if psTokenKindEq token.kind PsTokenKind.string then true
      else psTokenKindEq token.kind PsTokenKind.character

def psPscv0ParseNativeTailWithFuel
    (annotation : Bool)
    (parseArgument :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (head : PsSyntaxTerm)
    (fuel : Nat) :
    List PsSyntaxTerm ->
    PsSourcePos ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun
        (_argsRev : List PsSyntaxTerm)
        (_stop : PsSourcePos)
        (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      fun
        (argsRev : List PsSyntaxTerm)
        (stop : PsSourcePos)
        (cursor : PsTokenCursor) =>
        let smaller :
            List PsSyntaxTerm ->
            PsSourcePos ->
            PsTokenCursor ->
            Except PsParseError (PsParseResult PsSyntaxTerm) :=
          psPscv0ParseNativeTailWithFuel annotation parseArgument head remaining;
        let span : PsSourceSpan := {
          start := psProofScriptTermStart head
          stop := stop
        };
        if psPscv0CanStartNativeArgument annotation span cursor then
          match psParseProofScriptPrimary parseArgument cursor with
          | Except.error error => Except.error error
          | Except.ok primary =>
              match psParseProofScriptPostfixTailWithFuel
                  parseArgument
                  (Nat.succ remaining)
                  primary.value
                  primary.cursor with
              | Except.error error => Except.error error
              | Except.ok argument =>
                  smaller
                    (List.cons argument.value argsRev)
                    (psProofScriptTermStop argument.value)
                    argument.cursor
        else
          let value : PsSyntaxTerm :=
            match argsRev with
            | [] => head
            | _ => PsSyntaxTerm.app head (psParseListReverse argsRev) span;
          Except.ok { value := value, cursor := cursor }

def psPscv0ParseApplicationAfterPrimary
    (annotation : Bool)
    (parseArgument :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (primary : PsParseResult PsSyntaxTerm) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psParseProofScriptPostfixTailWithFuel
      parseArgument
      fuel
      primary.value
      primary.cursor with
  | Except.error error => Except.error error
  | Except.ok postfixResult =>
      psPscv0ParseNativeTailWithFuel annotation
        parseArgument
        postfixResult.value
        fuel
        []
        (psProofScriptTermStop postfixResult.value)
        postfixResult.cursor

def psPscv0ParseApplicationWithFuel
    (annotation : Bool)
    (parseArgument :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 => Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      match psParseProofScriptPrimary parseArgument cursor with
      | Except.error error => Except.error error
      | Except.ok primary =>
          psPscv0ParseApplicationAfterPrimary annotation
            parseArgument (Nat.succ remaining) primary

def psPscv0ParseGroupedContinuation
    (annotation : Bool)
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (parseContinuation : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (opening : PsTokenRead)
    (grouped : PsParseResult PsSyntaxTerm)
    (close : PsTokenRead) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  let primary : PsParseResult PsSyntaxTerm := {
    value := psProofScriptTermWithSpan grouped.value {
      start := opening.token.span.start
      stop := close.token.span.stop
    }
    cursor := close.cursor
  };
  match psPscv0ParseApplicationAfterPrimary annotation parseTerm fuel primary with
  | Except.error error => Except.error error
  | Except.ok application =>
      psParseProofScriptArrowTail parseContinuation application

def psPscv0ParseTermWithFuel
    (annotation : Bool)
    (fuel : Nat) :
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      fun (cursor : PsTokenCursor) =>
        let smaller :
            PsTokenCursor ->
            Except PsParseError (PsParseResult PsSyntaxTerm) :=
          psPscv0ParseTermWithFuel false remaining;
        let readAnnotation : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm) :=
          psPscv0ParseTermWithFuel true remaining;
        let continuation : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm) :=
          psPscv0ParseTermWithFuel annotation remaining;
        if psTokenCursorAtText cursor "do" then
          Except.error
            (psProofScriptExpectedError
              "supported pure term; do is not enabled in this source subset" cursor)
      else if psTokenCursorAtText cursor "match" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "match scrutinee")
        | Option.some keyword =>
            match smaller keyword.cursor with
            | Except.error error => Except.error error
            | Except.ok scrutinee =>
                match psTokenCursorExpectText scrutinee.cursor "with" with
                | Except.error error => Except.error error
                | Except.ok afterWith =>
                    match psTokenCursorExpectText afterWith.cursor "{" with
                    | Except.error error => Except.error error
                    | Except.ok afterOpen =>
                        match psParseProofScriptMatchAlternativesWithFuel
                            (smaller)
                            (psParseListLength afterOpen.cursor.remaining)
                            afterOpen.cursor
                            [] with
                        | Except.error error => Except.error error
                        | Except.ok alternatives =>
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
        | Option.none => Except.error (PsParseError.unexpectedEnd "(")
        | Option.some keyword =>
            match psTokenCursorExpectText keyword.cursor "(" with
            | Except.error error => Except.error error
            | Except.ok afterOpen =>
                match smaller afterOpen.cursor with
                | Except.error error => Except.error error
                | Except.ok condition =>
                    match psTokenCursorExpectText condition.cursor ")" with
                    | Except.error error => Except.error error
                    | Except.ok afterCondition =>
                        match psTokenCursorExpectText afterCondition.cursor "{" with
                        | Except.error error => Except.error error
                        | Except.ok afterThenOpen =>
                            match smaller afterThenOpen.cursor with
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
                                            match smaller afterElseOpen.cursor with
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
        | Option.none => Except.error (PsParseError.unexpectedEnd "let binding name")
        | Option.some keyword =>
            match psTokenCursorExpectKind
                keyword.cursor
                PsTokenKind.identifier with
            | Except.error error => Except.error error
            | Except.ok name =>
                let sourceName : PsSyntaxName := {
                  segments := [name.token.text]
                  span := name.token.span
                };
                if psTokenCursorAtText name.cursor ":" then
                  match psTokenCursorAdvance name.cursor with
                  | Option.none =>
                      Except.error
                        (PsParseError.unexpectedEnd "let binding type")
                  | Option.some afterColon =>
                      match readAnnotation afterColon.cursor with
                      | Except.error error => Except.error error
                      | Except.ok declaredType =>
                          match psTokenCursorExpectText
                              declaredType.cursor
                              ":=" with
                          | Except.error error => Except.error error
                          | Except.ok afterAssign =>
                              match smaller afterAssign.cursor with
                              | Except.error error => Except.error error
                              | Except.ok value =>
                                  match psParseProofScriptBodySeparator
                                       (psProofScriptTermStop value.value)
                                       value.cursor with
                                  | Except.error error => Except.error error
                                  | Except.ok afterLine =>
                                      match continuation afterLine with
                                      | Except.error error => Except.error error
                                      | Except.ok body =>
                                          Except.ok {
                                            value :=
                                              PsSyntaxTerm.letE
                                                sourceName
                                                (Option.some declaredType.value)
                                                value.value
                                                body.value
                                                {
                                                  start := keyword.token.span.start
                                                  stop :=
                                                    psProofScriptTermStop body.value
                                                }
                                            cursor := body.cursor
                                          }
                else
                  match psTokenCursorExpectText name.cursor ":=" with
                  | Except.error error => Except.error error
                  | Except.ok afterAssign =>
                      match smaller afterAssign.cursor with
                      | Except.error error => Except.error error
                      | Except.ok value =>
                          match psParseProofScriptBodySeparator
                               (psProofScriptTermStop value.value) value.cursor with
                          | Except.error error => Except.error error
                          | Except.ok afterLine =>
                              match continuation afterLine with
                              | Except.error error => Except.error error
                              | Except.ok body =>
                                  Except.ok {
                                    value :=
                                      PsSyntaxTerm.letE
                                        sourceName
                                        Option.none
                                        value.value
                                        body.value
                                        {
                                          start := keyword.token.span.start
                                          stop :=
                                            psProofScriptTermStop body.value
                                        }
                                    cursor := body.cursor
                                  }
      else if psTokenCursorAtText cursor "fun" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "lambda binder")
        | Option.some keyword =>
            match psParseProofScriptBindersWithFuel
                (psParseListLength keyword.cursor.remaining)
                keyword.cursor
                [] with
            | Except.error error => Except.error error
            | Except.ok binders =>
                match binders.value with
                | [] =>
                    match psTokenCursorPeek binders.cursor with
                    | Option.none =>
                        Except.error
                          (PsParseError.unexpectedEnd "lambda binder")
                    | Option.some token =>
                        Except.error
                          (PsParseError.expectedText
                            "typed lambda binder"
                            token.text
                            token.span)
                | _ =>
                    match psTokenCursorExpectText binders.cursor "=>" with
                    | Except.error error => Except.error error
                    | Except.ok afterArrow =>
                        match continuation afterArrow.cursor with
                        | Except.error error => Except.error error
                        | Except.ok body =>
                            Except.ok {
                              value :=
                                PsSyntaxTerm.lambda
                                  binders.value
                                  body.value
                                  {
                                    start := keyword.token.span.start
                                    stop := psProofScriptTermStop body.value
                                  }
                              cursor := body.cursor
                            }
      else if psTokenCursorAtText cursor "{" then
        psParseProofScriptRecordLiteral
          (smaller)
          cursor
      else if psTokenCursorAtText cursor "(" then
        match psTokenCursorAdvance cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd "(")
        | Option.some opening =>
            if psTokenCursorAtText opening.cursor ")" then
              match psTokenCursorAdvance opening.cursor with
              | Option.none => Except.error (PsParseError.unexpectedEnd ")")
              | Option.some close =>
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
                      continuation
                      binder
                  else
                    match smaller opening.cursor with
                    | Except.error error => Except.error error
                    | Except.ok grouped =>
                        match psTokenCursorExpectText grouped.cursor ")" with
                        | Except.error error => Except.error error
                        | Except.ok close =>
                            psPscv0ParseGroupedContinuation annotation
                              smaller continuation (Nat.succ remaining) opening grouped close
              | Except.error _ =>
                  match smaller opening.cursor with
                  | Except.error error => Except.error error
                  | Except.ok grouped =>
                      match psTokenCursorExpectText grouped.cursor ")" with
                      | Except.error error => Except.error error
                      | Except.ok close =>
                          psPscv0ParseGroupedContinuation annotation
                            smaller continuation (Nat.succ remaining) opening grouped close
      else
        match
            psPscv0ParseApplicationWithFuel annotation
              (smaller)
              (Nat.add remaining 1)
              cursor with
        | Except.error error => Except.error error
        | Except.ok domain =>
            psParseProofScriptArrowTail
              continuation
              domain

def psPscv0ParseTerm (annotation : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psPscv0ParseTermWithFuel annotation (Nat.succ (psParseListLength cursor.remaining)) cursor

