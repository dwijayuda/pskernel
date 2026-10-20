import Ps.Syntax.ParseCommon

def PsBindingTermParser : Type :=
  PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm)

structure PsParsedBindingPatterns where
  values : List PsSyntaxBindingPattern
  separated : Bool
  span : PsSourceSpan
  cursor : PsTokenCursor

def psParseBindingPatternsWithFuel
    (parsePattern : PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxBindingPattern))
    (fuel : Nat) : PsSourcePos -> PsTokenCursor ->
    List PsSyntaxBindingPattern -> Bool -> Except PsParseError PsParsedBindingPatterns :=
  match fuel with
  | Nat.zero =>
      fun (_start : PsSourcePos) (_cursor : PsTokenCursor)
          (_valuesRev : List PsSyntaxBindingPattern) (_separated : Bool) =>
        Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (start : PsSourcePos) (cursor : PsTokenCursor)
          (valuesRev : List PsSyntaxBindingPattern) (separated : Bool) =>
        let smaller :
            PsSourcePos -> PsTokenCursor -> List PsSyntaxBindingPattern ->
            Bool -> Except PsParseError PsParsedBindingPatterns :=
          psParseBindingPatternsWithFuel parsePattern remaining;
        if psTokenCursorAtText cursor ")" then
          match psTokenCursorExpectText cursor ")" with
          | Except.error error => Except.error error
          | Except.ok closing =>
              Except.ok
                { values := psParseListReverse valuesRev, separated := separated
                  span := { start := start, stop := closing.token.span.stop }
                  cursor := closing.cursor }
        else
          match parsePattern cursor with
          | Except.error error => Except.error error
          | Except.ok value =>
              if psTokenCursorAtText value.cursor "," then
                match psTokenCursorExpectText value.cursor "," with
                | Except.error error => Except.error error
                | Except.ok comma =>
                    smaller start comma.cursor (List.cons value.value valuesRev) true
              else
                match psTokenCursorExpectText value.cursor ")" with
                | Except.error error => Except.error error
                | Except.ok closing =>
                    Except.ok
                      { values := psParseListReverse (List.cons value.value valuesRev)
                        separated := separated
                        span := { start := start, stop := closing.token.span.stop }
                        cursor := closing.cursor }

def psSyntaxBindingTuple (values : List PsSyntaxBindingPattern)
    (span : PsSourceSpan) : PsSyntaxBindingPattern :=
  match values with
  | List.nil => PsSyntaxBindingPattern.unit span
  | List.cons first rest =>
      match rest with
      | List.nil => first
      | List.cons _ _ =>
          PsSyntaxBindingPattern.pair first (psSyntaxBindingTuple rest span) span

def psParseBindingPatternWithFuel (fuel : Nat) :
    PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxBindingPattern) :=
  match fuel with
  | Nat.zero =>
      fun (_cursor : PsTokenCursor) => Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (cursor : PsTokenCursor) =>
        let smaller :
            PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxBindingPattern) :=
          psParseBindingPatternWithFuel remaining;
        if psTokenCursorAtText cursor "(" then
          match psTokenCursorExpectText cursor "(" with
          | Except.error error => Except.error error
          | Except.ok opening =>
              match psParseBindingPatternsWithFuel smaller remaining
                  opening.token.span.start opening.cursor List.nil false with
              | Except.error error => Except.error error
              | Except.ok parsed =>
                  let result : PsParseResult PsSyntaxBindingPattern :=
                    { value := psSyntaxBindingTuple parsed.values parsed.span
                      cursor := parsed.cursor };
                  match parsed.values with
                  | List.nil => Except.ok result
                  | List.cons _ rest =>
                      match rest with
                      | List.nil =>
                          if parsed.separated then
                            Except.error (PsParseError.expectedText
                              "at least two tuple pattern elements" ")" parsed.span)
                          else Except.ok result
                      | List.cons _ _ => Except.ok result
        else if psTokenCursorAtText cursor "_" then
          match psTokenCursorExpectText cursor "_" with
          | Except.error error => Except.error error
          | Except.ok wildcard =>
              Except.ok
                { value := PsSyntaxBindingPattern.wildcard wildcard.token.span
                  cursor := wildcard.cursor }
        else
          match psTokenCursorExpectKind cursor PsTokenKind.identifier with
          | Except.error error => Except.error error
          | Except.ok name =>
              Except.ok
                { value := PsSyntaxBindingPattern.name
                    { segments := List.cons name.token.text List.nil, span := name.token.span }
                  cursor := name.cursor }

structure PsParsedBindingPattern where
  pattern : PsSyntaxBindingPattern
  annotation : Option PsSyntaxTerm
  cursor : PsTokenCursor

def psParseBindingPatternHeader (parseTerm : PsBindingTermParser)
    (cursor : PsTokenCursor) : Except PsParseError PsParsedBindingPattern :=
  match psParseBindingPatternWithFuel
      (Nat.succ (psParseListLength cursor.remaining)) cursor with
  | Except.error error => Except.error error
  | Except.ok pattern =>
      if psTokenCursorAtText pattern.cursor ":" then
        match psTokenCursorExpectText pattern.cursor ":" with
        | Except.error error => Except.error error
        | Except.ok colon =>
            match parseTerm colon.cursor with
            | Except.error error => Except.error error
            | Except.ok annotation =>
                Except.ok
                  { pattern := pattern.value, annotation := Option.some annotation.value
                    cursor := annotation.cursor }
      else
        Except.ok
          { pattern := pattern.value, annotation := Option.none, cursor := pattern.cursor }

def psParseAtBindingPatternLet (cursor : PsTokenCursor) : Bool :=
  if psTokenCursorAtText cursor "let" then
    match psTokenCursorAdvance cursor with
    | Option.none => false
    | Option.some keyword => psTokenCursorAtText keyword.cursor "("
  else false

/-- Both surfaces retain one explicit pattern binding node. Its elaborator owns
hygienic single evaluation; parsing never invents source-visible local names. -/
def psParseBindingLet (parseTerm : PsBindingTermParser)
    (separator : PsSourcePos -> PsTokenCursor -> Except PsParseError PsTokenCursor)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match psTokenCursorExpectText cursor "let" with
  | Except.error error => Except.error error
  | Except.ok keyword =>
      match psParseBindingPatternHeader parseTerm keyword.cursor with
      | Except.error error => Except.error error
      | Except.ok header =>
          match psTokenCursorExpectText header.cursor ":=" with
          | Except.error error => Except.error error
          | Except.ok assign =>
              match parseTerm assign.cursor with
              | Except.error error => Except.error error
              | Except.ok value =>
                  let valueSpan := psSyntaxTermSpan value.value;
                  match separator valueSpan.stop value.cursor with
                  | Except.error error => Except.error error
                  | Except.ok afterSeparator =>
                      match parseTerm afterSeparator with
                      | Except.error error => Except.error error
                      | Except.ok body =>
                          let bodySpan := psSyntaxTermSpan body.value;
                          Except.ok
                            { value := PsSyntaxTerm.letPatternE
                                header.pattern header.annotation value.value body.value
                                { start := keyword.token.span.start, stop := bodySpan.stop }
                              cursor := body.cursor }
