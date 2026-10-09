import Ps.Syntax.Lexer
import Ps.Syntax.ParseCommon

-- Current host tools authenticate this source format before reading or emitting PS.
-- Historical seed recovery calls its own immutable compiler on raw Lean source.
def psProofScriptGrammarEdition : String := "ps-0.9-r3"
def psProofScriptGrammarMode : String := "new-only"
def psProofScriptGrammarReferenceSha256 : String :=
  "4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71"

def psProofScriptTermStart
    (term : PsSyntaxTerm) : PsSourcePos :=
  let span := psSyntaxTermSpan term;
  span.start

def psProofScriptTermStop
    (term : PsSyntaxTerm) : PsSourcePos :=
  let span := psSyntaxTermSpan term;
  span.stop

def psProofScriptBoolNot (value : Bool) : Bool :=
  if value then false else true

def psProofScriptBoolAnd
    (left : Bool)
    (right : Bool) : Bool :=
  if left then right else false

def psProofScriptBoolOr
    (left : Bool)
    (right : Bool) : Bool :=
  if left then true else right

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
            cursor := name.cursor
          }

structure PsProofScriptCallArgs where
  args : List PsSyntaxTerm
  closeSpan : PsSourceSpan
  cursor : PsTokenCursor


def psParseProofScriptCallArgsWithFuel
    (parseArgument :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxTerm ->
    Except PsParseError PsProofScriptCallArgs :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (_argsRev : List PsSyntaxTerm) =>
        match psTokenCursorPeek cursor with
        | Option.none => Except.error (PsParseError.unexpectedEnd ")")
        | Option.some token =>
            Except.error
              (PsParseError.expectedText ")" token.text token.span)
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsSyntaxTerm ->
          Except PsParseError PsProofScriptCallArgs :=
        psParseProofScriptCallArgsWithFuel
          parseArgument
          remaining;
      fun
        (cursor : PsTokenCursor)
        (argsRev : List PsSyntaxTerm) =>
        if psTokenCursorAtText cursor ")" then
          match psTokenCursorAdvance cursor with
          | Option.none => Except.error (PsParseError.unexpectedEnd ")")
          | Option.some close =>
              Except.ok {
                args := psParseListReverse argsRev
                closeSpan := close.token.span
                cursor := close.cursor
              }
        else
          match parseArgument cursor with
          | Except.error error => Except.error error
          | Except.ok argument =>
              if psTokenCursorAtText argument.cursor "," then
                match psTokenCursorAdvance argument.cursor with
                | Option.none =>
                    Except.error (PsParseError.unexpectedEnd "term")
                | Option.some comma =>
                    smaller
                      comma.cursor
                      (List.cons argument.value argsRev)
              else
                match psTokenCursorExpectText argument.cursor ")" with
                | Except.error error => Except.error error
                | Except.ok close =>
                    Except.ok {
                      args := psParseListReverse (List.cons argument.value argsRev)
                      closeSpan := close.token.span
                      cursor := close.cursor
                    }

def psProofScriptCallAdjacent
    (term : PsSyntaxTerm)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | Option.none => false
  | Option.some token =>
      let stop := psProofScriptTermStop term;
      Nat.beq token.span.start.byteOffset stop.byteOffset


def psProofScriptExpectedError
    (expected : String)
    (cursor : PsTokenCursor) : PsParseError :=
  match psTokenCursorPeek cursor with
  | Option.none => PsParseError.unexpectedEnd expected
  | Option.some token =>
      PsParseError.expectedText expected token.text token.span

def psProofScriptTermWithSpan
    (term : PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  match term with
  | .reference name =>
      PsSyntaxTerm.reference { segments := name.segments, span := span }
  | .natural value _ => PsSyntaxTerm.natural value span
  | .string value _ => PsSyntaxTerm.string value span
  | .character value _ => PsSyntaxTerm.character value span
  | .bool value _ => PsSyntaxTerm.bool value span
  | .unit _ => PsSyntaxTerm.unit span
  | .record fields _ => PsSyntaxTerm.record fields span
  | .app fn args _ => PsSyntaxTerm.app fn args span
  | .lambda binders body _ => PsSyntaxTerm.lambda binders body span
  | .forallE binders body _ => PsSyntaxTerm.forallE binders body span
  | .letE name type value body _ =>
      PsSyntaxTerm.letE name type value body span
  | .ifE condition yes no _ => PsSyntaxTerm.ifE condition yes no span
  | .matchE scrutinee alternatives _ =>
      PsSyntaxTerm.matchE scrutinee alternatives span

def psProofScriptLaterLine
    (previous : PsSourcePos)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | Option.none => false
  | Option.some token =>
      Nat.ble (Nat.succ previous.line) token.span.start.line

def psParseProofScriptBodySeparator
    (previous : PsSourcePos)
    (cursor : PsTokenCursor) : Except PsParseError PsTokenCursor :=
  if psProofScriptLaterLine previous cursor then
    if psTokenCursorDone cursor then
      Except.error (psProofScriptExpectedError "term after newline" cursor)
    else if psTokenCursorAtText cursor ";" then
      Except.error (psProofScriptExpectedError "newline-separated term without semicolon" cursor)
    else
      Except.ok cursor
  else
    Except.error (psProofScriptExpectedError "newline after complete term" cursor)

def psParseProofScriptCommandSeparator
    (previous : PsSourcePos)
    (cursor : PsTokenCursor) : Except PsParseError PsTokenCursor :=
  if psTokenCursorDone cursor then
    Except.ok cursor
  else if psTokenCursorAtText cursor ";" then
    Except.error (psProofScriptExpectedError "newline or end of input, without semicolon" cursor)
  else if psProofScriptLaterLine previous cursor then
    Except.ok cursor
  else
    Except.error (psProofScriptExpectedError "newline or end of input" cursor)

def psParseProofScriptRecordFieldsWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsTokenCursor ->
    List (Prod PsSyntaxName PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult (List (Prod PsSyntaxName PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_fieldsRev : List (Prod PsSyntaxName PsSyntaxTerm)) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List (Prod PsSyntaxName PsSyntaxTerm) ->
          Except PsParseError
            (PsParseResult (List (Prod PsSyntaxName PsSyntaxTerm))) :=
        psParseProofScriptRecordFieldsWithFuel parseTerm remaining;
      fun
        (cursor : PsTokenCursor)
        (fieldsRev : List (Prod PsSyntaxName PsSyntaxTerm)) =>
        if psTokenCursorAtText cursor "}" then
          Except.ok {
            value := psParseListReverse fieldsRev
            cursor := cursor
          }
        else
          match psTokenCursorExpectKind cursor PsTokenKind.identifier with
          | Except.error error => Except.error error
          | Except.ok name =>
              match psTokenCursorExpectText name.cursor ":=" with
              | Except.error error => Except.error error
              | Except.ok afterAssign =>
                  match parseTerm afterAssign.cursor with
                  | Except.error error => Except.error error
                  | Except.ok value =>
                      let fieldName : PsSyntaxName := {
                        segments := [name.token.text]
                        span := name.token.span
                      };
                      let nextFields := List.cons (Prod.mk fieldName value.value) fieldsRev;
                      if psTokenCursorAtText value.cursor "," then
                        match psTokenCursorAdvance value.cursor with
                        | Option.none => Except.error (PsParseError.unexpectedEnd "record field")
                        | Option.some comma => smaller comma.cursor nextFields
                      else if psTokenCursorAtText value.cursor "}" then
                        smaller value.cursor nextFields
                      else
                        Except.error
                          (psProofScriptExpectedError "comma or closing record brace" value.cursor)

def psParseProofScriptRecordLiteral
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psTokenCursorExpectText cursor "{" with
  | Except.error error => Except.error error
  | Except.ok opening =>
      match psParseProofScriptRecordFieldsWithFuel
          parseTerm
          (Nat.succ (psParseListLength opening.cursor.remaining))
          opening.cursor
          [] with
      | Except.error error => Except.error error
      | Except.ok fields =>
          match psTokenCursorExpectText fields.cursor "}" with
          | Except.error error => Except.error error
          | Except.ok close =>
              Except.ok {
                value := PsSyntaxTerm.record fields.value {
                  start := opening.token.span.start
                  stop := close.token.span.stop
                }
                cursor := close.cursor
              }

def psProofScriptReservedArgument (text : String) : Bool :=
  if psStringEq text "def" then true
  else if psStringEq text "partial" then true
  else if psStringEq text "theorem" then true
  else if psStringEq text "const" then true
  else if psStringEq text "function" then true
  else if psStringEq text "import" then true
  else if psStringEq text "public" then true
  else if psStringEq text "structure" then true
  else if psStringEq text "inductive" then true
  else if psStringEq text "where" then true
  else if psStringEq text "with" then true
  else if psStringEq text "else" then true
  else if psStringEq text "fun" then true
  else if psStringEq text "let" then true
  else if psStringEq text "if" then true
  else if psStringEq text "match" then true
  else if psStringEq text "do" then true
  else if psStringEq text "requires" then true
  else if psStringEq text "ensures" then true
  else if psStringEq text "given" then true
  else if psStringEq text "termination_by" then true
  else if psStringEq text "decreasing_by" then true
  else if psStringEq text "namespace" then true
  else if psStringEq text "section" then true
  else if psStringEq text "end" then true
  else if psStringEq text "class" then true
  else if psStringEq text "instance" then true
  else if psStringEq text "axiom" then true
  else if psStringEq text "abbrev" then true
  else if psStringEq text "opaque" then true
  else if psStringEq text "noncomputable" then true
  else if psStringEq text "unsafe" then true
  else if psStringEq text "verify" then true
  else false

def psProofScriptCanStartNativeArgument
    (span : PsSourceSpan)
    (cursor : PsTokenCursor) : Bool :=
  match psTokenCursorPeek cursor with
  | Option.none => false
  | Option.some token =>
      if psProofScriptReservedArgument token.text then
        false
      else if psTokenCursorStartsNamedAssignment cursor then
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

def psParseProofScriptPrimary
    (parseInner :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  if psTokenCursorAtText cursor "{" then
    psParseProofScriptRecordLiteral parseInner cursor
  else if psTokenCursorAtText cursor "(" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "parenthesized term")
    | Option.some opening =>
        if psTokenCursorAtText opening.cursor ")" then
          match psTokenCursorAdvance opening.cursor with
          | Option.none => Except.error (PsParseError.unexpectedEnd ")")
          | Option.some close =>
              Except.ok {
                value := PsSyntaxTerm.unit {
                  start := opening.token.span.start
                  stop := close.token.span.stop
                }
                cursor := close.cursor
              }
        else
          match parseInner opening.cursor with
          | Except.error error => Except.error error
          | Except.ok inner =>
              match psTokenCursorExpectText inner.cursor ")" with
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
    psParseSimpleTerm cursor

def psParseProofScriptPostfixTailWithFuel
    (parseArgument :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsSyntaxTerm ->
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun (_current : PsSyntaxTerm) (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsSyntaxTerm ->
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseProofScriptPostfixTailWithFuel parseArgument remaining;
      fun (current : PsSyntaxTerm) (cursor : PsTokenCursor) =>
        if psProofScriptBoolAnd
            (psTokenCursorAtText cursor "(")
            (psProofScriptCallAdjacent current cursor) then
          match psTokenCursorAdvance cursor with
          | Option.none => Except.error (PsParseError.unexpectedEnd "(")
          | Option.some opening =>
              match psParseProofScriptCallArgsWithFuel
                  parseArgument
                  (Nat.succ remaining)
                  opening.cursor
                  [] with
              | Except.error error => Except.error error
              | Except.ok call =>
                  let span : PsSourceSpan := {
                    start := psProofScriptTermStart current
                    stop := call.closeSpan.stop
                  };
                  smaller
                    (PsSyntaxTerm.app current call.args span)
                    call.cursor
        else
          Except.ok { value := current, cursor := cursor }


def psParseProofScriptNativeTailWithFuel
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
      let smaller :
          List PsSyntaxTerm ->
          PsSourcePos ->
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseProofScriptNativeTailWithFuel parseArgument head remaining;
      fun
        (argsRev : List PsSyntaxTerm)
        (stop : PsSourcePos)
        (cursor : PsTokenCursor) =>
        let span : PsSourceSpan := {
          start := psProofScriptTermStart head
          stop := stop
        };
        if psProofScriptCanStartNativeArgument span cursor then
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

def psParseProofScriptApplicationAfterPrimary
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
      psParseProofScriptNativeTailWithFuel
        parseArgument
        postfixResult.value
        fuel
        []
        (psProofScriptTermStop postfixResult.value)
        postfixResult.cursor

def psParseProofScriptApplicationWithFuel
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
          psParseProofScriptApplicationAfterPrimary
            parseArgument (Nat.succ remaining) primary

def psParseProofScriptSimpleApplicationWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      fun (cursor : PsTokenCursor) =>
        psParseProofScriptApplicationWithFuel
          (psParseProofScriptSimpleApplicationWithFuel remaining)
          (Nat.add remaining 1)
          cursor

def psParseProofScriptSimpleApplication
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseProofScriptSimpleApplicationWithFuel
    (Nat.add (psParseListLength cursor.remaining) 1)
    cursor

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
            let domainSpan := psSyntaxTermSpan domain.value;
            let domainBinder :
                Prod PsSyntaxBinderHead PsSyntaxTerm :=
              Prod.mk
                (psSyntaxAnonymousExplicitBinder domainSpan)
                domain.value;
            let binders :
                List (Prod PsSyntaxBinderHead PsSyntaxTerm) :=
              List.cons domainBinder List.nil;
            let span := psSyntaxSpanJoin domainSpan (psSyntaxTermSpan codomain.value);
            Except.ok {
              value :=
                PsSyntaxTerm.forallE
                  binders
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
                  (List.cons binder.value List.nil)
                  codomain.value
                  {
                    start := binder.value.fst.span.start
                    stop := psProofScriptTermStop codomain.value
                  }
              cursor := codomain.cursor
            }
  else
    let actualText : String :=
      match psTokenCursorPeek binder.cursor with
      | Option.none => ""
      | Option.some token => token.text;
    let actualSpan : PsSourceSpan :=
      match psTokenCursorPeek binder.cursor with
      | Option.none => binder.value.fst.span
      | Option.some token => token.span;
    Except.error
      (PsParseError.expectedText
        "->"
        actualText
        actualSpan)



def psParseProofScriptGroupedType
    (parseType : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (opening : PsSyntaxBinderOpening) : Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match parseType opening.cursor with
  | Except.error error => Except.error error
  | Except.ok inner =>
      match psParseBinderClosing opening inner.cursor with
      | Except.error error => Except.error error
      | Except.ok closing =>
          let primary : PsParseResult PsSyntaxTerm := {
            value := psProofScriptTermWithSpan inner.value closing.value
            cursor := closing.cursor
          };
          match psParseProofScriptApplicationAfterPrimary parseType fuel primary with
          | Except.error error => Except.error error
          | Except.ok application =>
              psParseProofScriptArrowTail parseType application

def psParseProofScriptNestedBinderType
    (parseType : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psParseBinderOpening cursor with
  | Except.error error => Except.error error
  | Except.ok opening =>
      match psTokenCursorExpectKind opening.cursor PsTokenKind.identifier with
      | Except.error _ => psParseProofScriptGroupedType parseType fuel opening
      | Except.ok name =>
          if psTokenCursorAtText name.cursor ":" then
            match psTokenCursorExpectText name.cursor ":" with
            | Except.error error => Except.error error
            | Except.ok colon =>
                match parseType colon.cursor with
                | Except.error error => Except.error error
                | Except.ok type =>
                    match psParseBinderClosing opening type.cursor with
                    | Except.error error => Except.error error
                    | Except.ok closing =>
                        let binderName := PsSyntaxName.mk (List.cons name.token.text List.nil) name.token.span;
                        let binder := PsSyntaxBinderHead.mk binderName opening.kind closing.value;
                        psParseProofScriptDependentArrowTail parseType
                          (PsParseResult.mk (Prod.mk binder type.value) closing.cursor)
          else psParseProofScriptGroupedType parseType fuel opening

def psParseProofScriptBinderTypeWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | Nat.zero =>
      fun (_cursor : PsTokenCursor) => Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseProofScriptBinderTypeWithFuel remaining;
      fun (cursor : PsTokenCursor) =>
        if psTokenCursorAtBinderStart cursor then
          psParseProofScriptNestedBinderType smaller (Nat.succ remaining) cursor
        else
          match psParseProofScriptApplicationWithFuel smaller (Nat.succ remaining) cursor with
          | Except.error error => Except.error error
          | Except.ok domain => psParseProofScriptArrowTail smaller domain


def psParseProofScriptBinderType
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseProofScriptBinderTypeWithFuel
    (Nat.add (psParseListLength cursor.remaining) 1)
    cursor

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
              match psParseProofScriptBinderType afterColon.cursor with
              | Except.error error => Except.error error
              | Except.ok type =>
                  match psParseBinderClosing opening type.cursor with
                  | Except.error error => Except.error error
                  | Except.ok closing =>
                      let binderName : PsSyntaxName := {
                        segments := [name.token.text]
                        span := name.token.span
                      };
                      let binder : PsSyntaxBinderHead := {
                        name := binderName
                        kind := opening.kind
                        span := closing.value
                      };
                      Except.ok {
                        value := Prod.mk binder type.value
                        cursor := closing.cursor
                      }


def psParseProofScriptBindersWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List (PsSyntaxBinderHead × PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (bindersRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) =>
        Except.ok {
          value := psParseListReverse bindersRev
          cursor := cursor
        }
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List (PsSyntaxBinderHead × PsSyntaxTerm) ->
          Except PsParseError
            (PsParseResult (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
        psParseProofScriptBindersWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (bindersRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) =>
        if psTokenCursorAtBinderStart cursor then
          match psParseProofScriptBinder cursor with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              smaller
                parsed.cursor
                (List.cons parsed.value bindersRev)
        else
          Except.ok {
            value := psParseListReverse bindersRev
            cursor := cursor
          }


def psParseProofScriptExplicitEntriesWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_entriesRev : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
          Except PsParseError
            (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
        psParseProofScriptExplicitEntriesWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (entriesRev : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        if psTokenCursorAtText cursor ")" then
          match entriesRev with
          | [] =>
              Except.error
                (psProofScriptExpectedError "nonempty typed explicit parameter group" cursor)
          | last :: previous =>
              match psTokenCursorAdvance cursor with
              | Option.none => Except.error (PsParseError.unexpectedEnd ")")
              | Option.some close =>
                  let head : PsSyntaxBinderHead := last.fst;
                  let closedHead : PsSyntaxBinderHead := {
                    name := head.name
                    kind := head.kind
                    span := {
                      start := head.span.start
                      stop := close.token.span.stop
                    }
                  };
                  Except.ok {
                    value := psParseListReverse
                      (List.cons (Prod.mk closedHead last.snd) previous)
                    cursor := close.cursor
                  }
        else
          match psTokenCursorExpectKind cursor PsTokenKind.identifier with
          | Except.error error => Except.error error
          | Except.ok name =>
              match psTokenCursorExpectText name.cursor ":" with
              | Except.error error => Except.error error
              | Except.ok afterColon =>
                  match psParseProofScriptBinderType afterColon.cursor with
                  | Except.error error => Except.error error
                  | Except.ok type =>
                      let binderName : PsSyntaxName := {
                        segments := [name.token.text]
                        span := name.token.span
                      };
                      let head : PsSyntaxBinderHead := {
                        name := binderName
                        kind := PsSyntaxBinderKind.explicit
                        span := {
                          start := name.token.span.start
                          stop := psProofScriptTermStop type.value
                        }
                      };
                      let nextEntries :=
                        List.cons (Prod.mk head type.value) entriesRev;
                      if psTokenCursorAtText type.cursor "," then
                        match psTokenCursorAdvance type.cursor with
                        | Option.none => Except.error (PsParseError.unexpectedEnd "parameter")
                        | Option.some comma => smaller comma.cursor nextEntries
                      else if psTokenCursorAtText type.cursor ")" then
                        smaller type.cursor nextEntries
                      else
                        Except.error
                          (psProofScriptExpectedError "comma or closing parameter parenthesis" type.cursor)

def psParseProofScriptDeclarationBindersWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_prefixRev : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
          Except PsParseError
            (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
        psParseProofScriptDeclarationBindersWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (prefixRev : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        if psTokenCursorAtText cursor "(" then
          match psTokenCursorAdvance cursor with
          | Option.none => Except.error (PsParseError.unexpectedEnd "parameter")
          | Option.some opening =>
              match psParseProofScriptExplicitEntriesWithFuel
                  (Nat.succ remaining) opening.cursor [] with
              | Except.error error => Except.error error
              | Except.ok explicit =>
                  Except.ok {
                    value := psParseListAppend
                      (psParseListReverse prefixRev) explicit.value
                    cursor := explicit.cursor
                  }
        else if psTokenCursorAtBinderStart cursor then
          match psParseProofScriptBinder cursor with
          | Except.error error => Except.error error
          | Except.ok binder =>
              smaller binder.cursor (List.cons binder.value prefixRev)
        else
          Except.ok {
            value := psParseListReverse prefixRev
            cursor := cursor
          }

def psProofScriptBindersHaveExplicit
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) : Bool :=
  match binders with
  | [] => false
  | binder :: rest =>
      let head := binder.fst;
      match head.kind with
      | .explicit => true
      | _ => psProofScriptBindersHaveExplicit rest

def psParseProofScriptMatchAlternativesWithFuel
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    PsTokenCursor ->
    List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)) ->
    Except PsParseError
      (PsParseResult (List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_alternativesRev : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)) ->
          Except PsParseError
            (PsParseResult (List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))) :=
        psParseProofScriptMatchAlternativesWithFuel parseTerm remaining;
      fun
        (cursor : PsTokenCursor)
        (alternativesRev : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) =>
        if psTokenCursorAtText cursor "}" then
          Except.ok {
            value := psParseListReverse alternativesRev
            cursor := cursor
          }
        else
          match psTokenCursorExpectText cursor "|" with
          | Except.error error => Except.error error
          | Except.ok bar =>
              match psParseBasicPattern bar.cursor with
              | Except.error error => Except.error error
              | Except.ok pattern =>
                  match psTokenCursorExpectText pattern.cursor "=>" with
                  | Except.error error => Except.error error
                  | Except.ok afterArrow =>
                      match parseTerm afterArrow.cursor with
                      | Except.error error => Except.error error
                      | Except.ok body =>
                          let span : PsSourceSpan := {
                            start := bar.token.span.start
                            stop := psProofScriptTermStop body.value
                          };
                          let alternative := Prod.mk pattern.value (Prod.mk body.value span);
                          if psProofScriptBoolOr
                              (psTokenCursorAtText body.cursor "|")
                              (psTokenCursorAtText body.cursor "}") then
                            smaller body.cursor (List.cons alternative alternativesRev)
                          else
                            Except.error
                              (psProofScriptExpectedError
                                "next match bar or closing brace, without semicolon" body.cursor)

def psParseProofScriptGroupedContinuation
    (parseTerm :
      PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
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
  match psParseProofScriptApplicationAfterPrimary parseTerm fuel primary with
  | Except.error error => Except.error error
  | Except.ok application =>
      psParseProofScriptArrowTail parseTerm application

def psParseProofScriptTermWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 =>
      fun (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          Except PsParseError (PsParseResult PsSyntaxTerm) :=
        psParseProofScriptTermWithFuel remaining;
      fun (cursor : PsTokenCursor) =>
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
                            match alternatives.value with
                            | [] =>
                                match psTokenCursorPeek alternatives.cursor with
                                | Option.none =>
                                    Except.error
                                      (PsParseError.unexpectedEnd "match alternative")
                                | Option.some token =>
                                    Except.error
                                      (PsParseError.expectedText
                                        "|"
                                        token.text
                                        token.span)
                            | _ =>
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
                      match smaller afterColon.cursor with
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
                                      match smaller afterLine with
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
                              match smaller afterLine with
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
                        match smaller afterArrow.cursor with
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
                      (smaller)
                      binder
                  else
                    match smaller opening.cursor with
                    | Except.error error => Except.error error
                    | Except.ok grouped =>
                        match psTokenCursorExpectText grouped.cursor ")" with
                        | Except.error error => Except.error error
                        | Except.ok close =>
                            psParseProofScriptGroupedContinuation
                              smaller (Nat.succ remaining) opening grouped close
              | Except.error _ =>
                  match smaller opening.cursor with
                  | Except.error error => Except.error error
                  | Except.ok grouped =>
                      match psTokenCursorExpectText grouped.cursor ")" with
                      | Except.error error => Except.error error
                      | Except.ok close =>
                          psParseProofScriptGroupedContinuation
                            smaller (Nat.succ remaining) opening grouped close
      else
        match
            psParseProofScriptApplicationWithFuel
              (smaller)
              (Nat.add remaining 1)
              cursor with
        | Except.error error => Except.error error
        | Except.ok domain =>
            psParseProofScriptArrowTail
              (smaller)
              domain

def psParseProofScriptTerm
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  psParseProofScriptTermWithFuel (Nat.add (psParseListLength cursor.remaining) 1) cursor



def psProofScriptLastBinderStop
    (fallback : PsSourcePos)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) : PsSourcePos :=
  match psParseListReverse binders with
  | [] => fallback
  | last :: _ =>
      let head : PsSyntaxBinderHead := last.fst;
      head.span.stop

def psParseProofScriptInductiveConstructorsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxInductiveConstructor ->
    Except PsParseError (PsParseResult (List PsSyntaxInductiveConstructor)) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_constructorsRev : List PsSyntaxInductiveConstructor) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsSyntaxInductiveConstructor ->
          Except PsParseError (PsParseResult (List PsSyntaxInductiveConstructor)) :=
        psParseProofScriptInductiveConstructorsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (constructorsRev : List PsSyntaxInductiveConstructor) =>
        if psTokenCursorAtText cursor "}" then
          Except.ok { value := psParseListReverse constructorsRev, cursor := cursor }
        else
          match psTokenCursorExpectText cursor "|" with
          | Except.error error => Except.error error
          | Except.ok bar =>
              match psTokenCursorExpectKind bar.cursor PsTokenKind.identifier with
              | Except.error error => Except.error error
              | Except.ok name =>
                  match psParseProofScriptDeclarationBindersWithFuel
                      (Nat.succ remaining) name.cursor [] with
                  | Except.error error => Except.error error
                  | Except.ok fields =>
                      if psProofScriptBoolOr
                          (psTokenCursorAtText fields.cursor "|")
                          (psTokenCursorAtText fields.cursor "}") then
                        let sourceName : PsSyntaxName := {
                          segments := [name.token.text]
                          span := name.token.span
                        };
                        let constructor : PsSyntaxInductiveConstructor := {
                          name := sourceName
                          fields := fields.value
                          span := {
                            start := bar.token.span.start
                            stop := psProofScriptLastBinderStop name.token.span.stop fields.value
                          }
                        };
                        smaller fields.cursor (List.cons constructor constructorsRev)
                      else
                        Except.error
                          (psProofScriptExpectedError
                            "next constructor bar or closing brace, without semicolon" fields.cursor)

def psParseProofScriptStructureField
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (Prod PsSyntaxBinderHead PsSyntaxTerm)) :=
  let parsed : Except PsParseError (PsParseResult (Prod PsSyntaxBinderHead PsSyntaxTerm)) :=
    if psTokenCursorAtBinderStart cursor then
      psParseProofScriptBinder cursor
    else
      match psTokenCursorExpectKind cursor PsTokenKind.identifier with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psTokenCursorExpectText name.cursor ":" with
          | Except.error error => Except.error error
          | Except.ok afterColon =>
              match psParseProofScriptTerm afterColon.cursor with
              | Except.error error => Except.error error
              | Except.ok type =>
                  let fieldName : PsSyntaxName := {
                    segments := [name.token.text]
                    span := name.token.span
                  };
                  let head : PsSyntaxBinderHead := {
                    name := fieldName
                    kind := PsSyntaxBinderKind.explicit
                    span := {
                      start := name.token.span.start
                      stop := psProofScriptTermStop type.value
                    }
                  };
                  Except.ok { value := Prod.mk head type.value, cursor := type.cursor };
  match parsed with
  | Except.error error => Except.error error
  | Except.ok field =>
      let pair := field.value;
      let head := pair.fst;
      if psTokenCursorAtText field.cursor "}" then
        Except.ok field
      else if psTokenCursorAtText field.cursor ";" then
        Except.error
          (psProofScriptExpectedError "newline-separated structure field, without semicolon" field.cursor)
      else if psProofScriptLaterLine head.span.stop field.cursor then
        Except.ok field
      else
        Except.error
          (psProofScriptExpectedError "newline or closing structure brace" field.cursor)

def psParseProofScriptStructureFieldsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List (PsSyntaxBinderHead × PsSyntaxTerm) ->
    Except PsParseError
      (PsParseResult
        (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
  match fuel with
  | 0 =>
      fun
        (_cursor : PsTokenCursor)
        (_fieldsRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) =>
        Except.error PsParseError.fuelExhausted
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List (PsSyntaxBinderHead × PsSyntaxTerm) ->
          Except PsParseError
            (PsParseResult
              (List (PsSyntaxBinderHead × PsSyntaxTerm))) :=
        psParseProofScriptStructureFieldsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (fieldsRev : List (PsSyntaxBinderHead × PsSyntaxTerm)) =>
        if psTokenCursorAtText cursor "}" then
          Except.ok {
            value := psParseListReverse fieldsRev
            cursor := cursor
          }
        else
          match psParseProofScriptStructureField cursor with
          | Except.error error => Except.error error
          | Except.ok field =>
              smaller
                field.cursor
                (List.cons field.value fieldsRev)

def psParseProofScriptDeclaredName
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxName) :=
  match psTokenCursorExpectKind cursor PsTokenKind.identifier with
  | Except.error error => Except.error error
  | Except.ok name =>
      Except.ok {
        value := { segments := [name.token.text], span := name.token.span }
        cursor := name.cursor
      }

def psParseProofScriptStructureDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorExpectText cursor "structure" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseProofScriptDeclaredName keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psParseProofScriptDeclarationBindersWithFuel
              (psParseListLength name.cursor.remaining)
              name.cursor
              [] with
          | Except.error error => Except.error error
          | Except.ok params =>
              match psTokenCursorExpectText params.cursor "where" with
              | Except.error error => Except.error error
              | Except.ok afterWhere =>
                  match psTokenCursorExpectText afterWhere.cursor "{" with
                  | Except.error error => Except.error error
                  | Except.ok afterOpen =>
                      match
                          psParseProofScriptStructureFieldsWithFuel
                            (psParseListLength afterOpen.cursor.remaining)
                            afterOpen.cursor
                            [] with
                      | Except.error error => Except.error error
                      | Except.ok fields =>
                          match fields.value with
                          | [] =>
                              match psTokenCursorPeek fields.cursor with
                              | Option.none =>
                                  Except.error
                                    (PsParseError.unexpectedEnd
                                      "structure field")
                              | Option.some token =>
                                  Except.error
                                    (PsParseError.expectedText
                                      "structure field"
                                      token.text
                                      token.span)
                          | _ =>
                              match psTokenCursorExpectText
                                  fields.cursor
                                  "}" with
                              | Except.error error => Except.error error
                              | Except.ok close =>
                                  let finalCursor := close.cursor;
                                  Except.ok {
                                    value :=
                                      PsSyntaxDeclaration.structureDecl
                                        name.value
                                        params.value
                                        fields.value
                                        {
                                          start := keyword.token.span.start
                                          stop := close.token.span.stop
                                        }
                                    cursor := finalCursor
                                  }

def psParseProofScriptInductiveDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorExpectText cursor "inductive" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseProofScriptDeclaredName keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok name =>
          match psParseProofScriptDeclarationBindersWithFuel
              (psParseListLength name.cursor.remaining)
              name.cursor
              [] with
          | Except.error error => Except.error error
          | Except.ok params =>
              let parseAfterResult :
                  Option PsSyntaxTerm ->
                  PsTokenCursor ->
                  Except PsParseError
                    (PsParseResult PsSyntaxDeclaration) :=
                fun
                  (resultType : Option PsSyntaxTerm)
                  (afterResult : PsTokenCursor) =>
                match psTokenCursorExpectText afterResult "where" with
                | Except.error error => Except.error error
                | Except.ok afterWhere =>
                    match psTokenCursorExpectText afterWhere.cursor "{" with
                    | Except.error error => Except.error error
                    | Except.ok afterOpen =>
                        match psParseProofScriptInductiveConstructorsWithFuel
                            (psParseListLength afterOpen.cursor.remaining)
                            afterOpen.cursor
                            [] with
                        | Except.error error => Except.error error
                        | Except.ok constructors =>
                            match constructors.value with
                            | [] =>
                                match psTokenCursorPeek constructors.cursor with
                                | Option.none =>
                                    Except.error
                                      (PsParseError.unexpectedEnd
                                        "inductive constructor")
                                | Option.some token =>
                                    Except.error
                                      (PsParseError.expectedText
                                        "|"
                                        token.text
                                        token.span)
                            | _ =>
                                match psTokenCursorExpectText
                                    constructors.cursor
                                    "}" with
                                | Except.error error => Except.error error
                                | Except.ok close =>
                                    let finalCursor : PsTokenCursor := close.cursor;
                                    Except.ok {
                                      value :=
                                        PsSyntaxDeclaration.inductiveDecl
                                          name.value
                                          params.value
                                          resultType
                                          constructors.value
                                          {
                                            start := keyword.token.span.start
                                            stop := close.token.span.stop
                                          }
                                      cursor := finalCursor
                                    };
              if psTokenCursorAtText params.cursor ":" then
                match psTokenCursorAdvance params.cursor with
                | Option.none =>
                    Except.error
                      (PsParseError.unexpectedEnd "inductive result type")
                | Option.some afterColon =>
                    match psParseProofScriptTerm afterColon.cursor with
                    | Except.error error => Except.error error
                    | Except.ok resultType =>
                        parseAfterResult
                          (Option.some resultType.value)
                          resultType.cursor
              else
                parseAfterResult Option.none params.cursor


def psParseProofScriptDefinitionBody
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  if psTokenCursorAtText cursor "{" then
    match psTokenCursorAdvance cursor with
    | Option.none => Except.error (PsParseError.unexpectedEnd "definition body")
    | Option.some opening =>
        if psProofScriptBoolOr
            (psTokenCursorAtText opening.cursor "}")
            (psTokenCursorStartsNamedAssignment opening.cursor) then
          psParseProofScriptTerm cursor
        else
          match psParseProofScriptTerm opening.cursor with
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
    psParseProofScriptTerm cursor

def psParseProofScriptDeclaration
    (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxDeclaration) :=
  match psTokenCursorPeek cursor with
  | Option.none => Except.error (PsParseError.unexpectedEnd "declaration")
  | Option.some keyword =>
      if psStringEq keyword.text "inductive" then
        psParseProofScriptInductiveDeclaration cursor
      else if psStringEq keyword.text "structure" then
        psParseProofScriptStructureDeclaration cursor
      else
        let isPartial := psStringEq keyword.text "partial";
        let isDefinition := psStringEq keyword.text "def";
        let isTheorem := psStringEq keyword.text "theorem";
        let isConst := psStringEq keyword.text "const";
        let isFunction := psStringEq keyword.text "function";
        let isValue :=
          psProofScriptBoolOr isDefinition
            (psProofScriptBoolOr isConst isFunction);
        if psProofScriptBoolNot
            (psProofScriptBoolOr isPartial
              (psProofScriptBoolOr isValue isTheorem)) then
          Except.error
            (psProofScriptExpectedError
              "typed def, const, function, theorem, inductive, or structure" cursor)
        else
          let afterKind : Except PsParseError PsTokenCursor :=
            if isPartial then
              match psTokenCursorAdvance cursor with
              | Option.none => Except.error (PsParseError.unexpectedEnd "def after partial")
              | Option.some afterPartial =>
                  match psTokenCursorExpectText afterPartial.cursor "def" with
                  | Except.error error => Except.error error
                  | Except.ok afterDef => Except.ok afterDef.cursor
            else
              match psTokenCursorAdvance cursor with
              | Option.none => Except.error (PsParseError.unexpectedEnd "declaration name")
              | Option.some afterKeyword => Except.ok afterKeyword.cursor;
          match afterKind with
          | Except.error error => Except.error error
          | Except.ok afterKeyword =>
              match psParseProofScriptDeclaredName afterKeyword with
              | Except.error error => Except.error error
              | Except.ok name =>
                  let bindersResult :
                      Except PsParseError
                        (PsParseResult (List (Prod PsSyntaxBinderHead PsSyntaxTerm))) :=
                    if isConst then
                      Except.ok { value := [], cursor := name.cursor }
                    else
                      psParseProofScriptDeclarationBindersWithFuel
                        (Nat.succ (psParseListLength name.cursor.remaining))
                        name.cursor [];
                  match bindersResult with
                  | Except.error error => Except.error error
                  | Except.ok binders =>
                      if
                          if isFunction then
                            psProofScriptBoolNot (psProofScriptBindersHaveExplicit binders.value)
                          else false then
                        Except.error
                          (psProofScriptExpectedError
                            "nonempty typed explicit function parameter group" binders.cursor)
                      else
                        match psTokenCursorExpectText binders.cursor ":" with
                        | Except.error error => Except.error error
                        | Except.ok afterColon =>
                            match psParseProofScriptTerm afterColon.cursor with
                            | Except.error error => Except.error error
                            | Except.ok type =>
                                match psTokenCursorExpectText type.cursor ":=" with
                                | Except.error error => Except.error error
                                | Except.ok afterAssign =>
                                    match psParseProofScriptDefinitionBody afterAssign.cursor with
                                    | Except.error error => Except.error error
                                    | Except.ok value =>
                                        let span : PsSourceSpan := {
                                          start := keyword.span.start
                                          stop := psProofScriptTermStop value.value
                                        };
                                        let declaration : PsSyntaxDeclaration :=
                                          if isPartial then
                                            PsSyntaxDeclaration.partialDefinition
                                              name.value binders.value type.value value.value span
                                          else if isValue then
                                            PsSyntaxDeclaration.definition
                                              name.value binders.value type.value value.value span
                                          else
                                            PsSyntaxDeclaration.theoremDecl
                                              name.value binders.value type.value value.value span;
                                        Except.ok {
                                          value := declaration
                                          cursor := value.cursor
                                        }

def psProofScriptDeclarationStop
    (declaration : PsSyntaxDeclaration) : PsSourcePos :=
  match declaration with
  | .definition _ _ _ _ span => span.stop
  | .partialDefinition _ _ _ _ span => span.stop
  | .theoremDecl _ _ _ _ span => span.stop
  | .inductiveDecl _ _ _ _ span => span.stop
  | .structureDecl _ _ _ span => span.stop

def psParseProofScriptImportsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxImport ->
    Except PsParseError (PsParseResult (List PsSyntaxImport)) :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (importsRev : List PsSyntaxImport) =>
        Except.ok {
          value := psParseListReverse importsRev
          cursor := cursor
        }
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsSyntaxImport ->
          Except PsParseError (PsParseResult (List PsSyntaxImport)) :=
        psParseProofScriptImportsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (importsRev : List PsSyntaxImport) =>
        if psTokenCursorAtText cursor "import" then
          match psParseProofScriptImport cursor with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              let imported : PsSyntaxImport := parsed.value;
              let span : PsSourceSpan := imported.span;
              match psParseProofScriptCommandSeparator span.stop parsed.cursor with
              | Except.error error => Except.error error
              | Except.ok next =>
                  smaller next (List.cons imported importsRev)
        else
          Except.ok {
            value := psParseListReverse importsRev
            cursor := cursor
          }


def psParseProofScriptDeclarationsWithFuel
    (fuel : Nat) :
    PsTokenCursor ->
    List PsSyntaxDeclaration ->
    Except PsParseError (PsParseResult (List PsSyntaxDeclaration)) :=
  match fuel with
  | 0 =>
      fun
        (cursor : PsTokenCursor)
        (declarationsRev : List PsSyntaxDeclaration) =>
        if psTokenCursorDone cursor then
          Except.ok {
            value := psParseListReverse declarationsRev
            cursor := cursor
          }
        else
          match psTokenCursorPeek cursor with
          | Option.none =>
              Except.ok {
                value := psParseListReverse declarationsRev
                cursor := cursor
              }
          | Option.some token =>
              Except.error
                (PsParseError.expectedText
                  "end of input"
                  token.text
                  token.span)
  | remaining + 1 =>
      let smaller :
          PsTokenCursor ->
          List PsSyntaxDeclaration ->
          Except PsParseError
            (PsParseResult (List PsSyntaxDeclaration)) :=
        psParseProofScriptDeclarationsWithFuel remaining;
      fun
        (cursor : PsTokenCursor)
        (declarationsRev : List PsSyntaxDeclaration) =>
        if psTokenCursorDone cursor then
          Except.ok {
            value := psParseListReverse declarationsRev
            cursor := cursor
          }
        else
          match psParseProofScriptDeclaration cursor with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              match psParseProofScriptCommandSeparator
                  (psProofScriptDeclarationStop parsed.value) parsed.cursor with
              | Except.error error => Except.error error
              | Except.ok next =>
                  smaller next (List.cons parsed.value declarationsRev)

def psParseProofScriptTokens
    (tokens : List PsToken) :
    Except PsParseError PsSyntaxModule :=
  let cursor := psTokenCursorFromTokens tokens;
  match psParseProofScriptImportsWithFuel (psParseListLength tokens) cursor [] with
  | Except.error error => Except.error error
  | Except.ok imports =>
      match psParseProofScriptDeclarationsWithFuel
          (psParseListLength tokens)
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
  match psLexProofScript source with
  | Except.error error =>
      Except.error (PsProofScriptFrontendError.lex error)
  | Except.ok tokens =>
      match psParseProofScriptTokens tokens with
      | Except.error error =>
          Except.error (PsProofScriptFrontendError.parse error)
      | Except.ok module => Except.ok module
