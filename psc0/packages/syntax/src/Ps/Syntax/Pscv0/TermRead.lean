import Ps.Syntax.Pscv0.PatternRead
import Ps.Syntax.Pscv0.ProofRead

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
      if psProofScriptReservedArgument token.text || token.text == "matches" then
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
      else if psTokenCursorAtText cursor "{" then annotation
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
          match psPscv0Primary parseArgument cursor with
          | Except.error error => Except.error error
          | Except.ok primary =>
              match psPscv0Postfix
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
  match psPscv0Postfix
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
      match psPscv0Primary parseArgument cursor with
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
      psPscv0TermTail parseContinuation application

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
        if psTokenCursorAtText cursor "by" then
          psPscv0ReadProof smaller (remaining + 1) cursor
      else if psTokenCursorAtText cursor "do" then
          Except.error
            (psProofScriptExpectedError
              "supported pure term; do is not enabled in this source subset" cursor)
      else if psTokenCursorAtText cursor "nomatch" then
        psPscv0ReadMatch smaller remaining true cursor
      else if psTokenCursorAtText cursor "match" then
        psPscv0ReadMatch smaller remaining false cursor
      else if psTokenCursorAtText cursor "if" && psPscv0IfLetStart cursor then
        psPscv0ReadIfLet smaller remaining cursor
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
        psPscv0ReadLet smaller readAnnotation continuation remaining cursor
      else if psTokenCursorAtText cursor "fun" || psTokenCursorAtText cursor "λ" then
        psPscv0BoundTerm readAnnotation continuation false (remaining + 1) cursor
      else if psTokenCursorAtText cursor "forall" || psTokenCursorAtText cursor "∀" then
        psPscv0BoundTerm readAnnotation continuation true (remaining + 1) cursor
      else if psTokenCursorAtText cursor "{" then
        psParseProofScriptRecordLiteral
          (smaller)
          cursor
      else if psTokenCursorAtText cursor "(" then
        match psPscv0DependentBinder readAnnotation (remaining + 1) cursor with
        | Except.ok binder =>
            if psTokenCursorAtArrow binder.cursor then
              psParseProofScriptDependentArrowTail continuation binder
            else
              match psPscv0Primary smaller cursor with
              | .error error => .error error
              | .ok primary =>
                  match psPscv0ParseApplicationAfterPrimary annotation smaller (remaining + 1) primary with
                  | .error error => .error error
                  | .ok application => psPscv0TermTail continuation application
        | Except.error _ =>
            match psPscv0Primary smaller cursor with
            | .error error => .error error
            | .ok primary =>
                match psPscv0ParseApplicationAfterPrimary annotation smaller (remaining + 1) primary with
                | .error error => .error error
                | .ok application => psPscv0TermTail continuation application
      else
        match
            psPscv0ParseApplicationWithFuel annotation
              (smaller)
              (Nat.add remaining 1)
              cursor with
        | Except.error error => Except.error error
        | Except.ok domain =>
            psPscv0TermTail
              continuation
              domain

def psPscv0ParseTerm (annotation : Bool) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psPscv0ParseTermWithFuel annotation (Nat.succ (psParseListLength cursor.remaining)) cursor

def psPscv0ParseDefinitionBody
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  if psTokenCursorAtText cursor "{" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "definition body")
    | Option.some opening =>
        if psProofScriptBoolOr
            (psTokenCursorAtText opening.cursor "}")
            (psTokenCursorStartsNamedAssignment opening.cursor) then
          psPscv0ParseTerm false cursor
        else
          match psPscv0ParseTerm false opening.cursor with
          | Except.error error => Except.error error
          | Except.ok inner =>
              match psTokenCursorExpectText inner.cursor "}" with
              | Except.error error => Except.error error
              | Except.ok close =>
                  Except.ok {
                    value := psProofScriptTermWithSpan inner.value {
                      start := opening.token.span.start
                      stop := close.token.span.stop
                    }
                    cursor := close.cursor
                  }
  else
    psPscv0ParseTerm false cursor

