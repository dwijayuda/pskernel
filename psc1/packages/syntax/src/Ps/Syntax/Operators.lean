import Ps.Syntax.ParseCommon

/-- Fixed v7.2 binding powers. This table does not enable extensible notation. -/
def psOperatorPrecedence (operator : String) : Option Nat :=
  if operator == "||" then some 30
  else if operator == "&&" || operator == "×" then some 35
  else if operator == "=" || operator == "==" || operator == "!=" ||
      operator == "<" || operator == "<=" || operator == "≤" ||
      operator == ">" || operator == ">=" || operator == "≥" then some 50
  else if operator == "+" || operator == "-" then some 65
  else if operator == "*" || operator == "/" || operator == "%" then some 70
  else none

def psOperatorNode
    (operator : String) (left right : PsSyntaxTerm) (tokenSpan : PsSourceSpan) :
    PsSyntaxTerm :=
  let span := psSyntaxSpanJoin (psSyntaxTermSpan left) (psSyntaxTermSpan right)
  if operator == "×" then
    .app (psSyntaxRootReference ["Prod"] tokenSpan) [left, right] span
  else
    .binary operator left right span

/-- The nonassociative flag belongs to this parse level, not the AST. Parentheses
therefore permit explicitly grouped equality without permitting a < b < c. -/
def psParseOperatorTailWithFuel
    (parseOperand : Nat -> PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) (minimum : Nat) (comparisonUsed : Bool)
    (left : PsParseResult PsSyntaxTerm) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 => .error .fuelExhausted
  | remaining + 1 =>
      match psTokenCursorPeek left.cursor with
      | none => .ok left
      | some token =>
          match psOperatorPrecedence token.text with
          | none => .ok left
          | some precedence =>
              if precedence < minimum then .ok left
              else if comparisonUsed && precedence == 50 then
                .error (.expectedText
                  "parentheses around nonassociative comparison" token.text token.span)
              else
                match psTokenCursorAdvance left.cursor with
                | none => .error (.unexpectedEnd "operator right operand")
                | some afterOperator =>
                    let rightMinimum :=
                      if token.text == "×" then precedence else precedence + 1
                    match parseOperand rightMinimum afterOperator.cursor with
                    | .error error => .error error
                    | .ok right =>
                        psParseOperatorTailWithFuel parseOperand remaining minimum
                          (precedence == 50)
                          { value := psOperatorNode token.text left.value right.value token.span
                            cursor := right.cursor }

/-- Pratt parsing over the existing source-specific application parser. The
callback owns parentheses/calls; this layer owns only the fixed operator table. -/
def psParseOperatorsWithFuel
    (parseAtom : PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) (minimum : Nat) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | 0 => .error .fuelExhausted
  | remaining + 1 =>
      let parseOperand := psParseOperatorsWithFuel parseAtom remaining
      let primary : Except PsParseError (PsParseResult PsSyntaxTerm) :=
        match psTokenCursorPeek cursor with
        | some token =>
            if token.text == "-" || token.text == "!" then
              match psTokenCursorAdvance cursor with
              | none => .error (.unexpectedEnd "prefix operand")
              | some afterPrefix =>
                  let operandMinimum := if token.text == "-" then 75 else 40
                  match parseOperand operandMinimum afterPrefix.cursor with
                  | .error error => .error error
                  | .ok operand =>
                      .ok { value := .unary token.text operand.value
                              (psSyntaxSpanJoin token.span (psSyntaxTermSpan operand.value))
                            cursor := operand.cursor }
            else parseAtom cursor
        | none => parseAtom cursor
      match primary with
      | .error error => .error error
      | .ok left =>
          psParseOperatorTailWithFuel parseOperand (remaining + 1) minimum false left
