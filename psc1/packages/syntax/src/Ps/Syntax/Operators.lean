import Ps.Syntax.ParseCommon

/-- Fixed v7.2 binding powers. This table does not enable extensible notation. -/
def psOperatorPrecedence (operator : String) : Option Nat :=
  if psStringEq operator "||" then Option.some 30
  else if psStringEq operator "&&" || psStringEq operator "×" then Option.some 35
  else if psStringEq operator "=" || psStringEq operator "==" || psStringEq operator "!=" ||
      psStringEq operator "<" || psStringEq operator "<=" || psStringEq operator "≤" ||
      psStringEq operator ">" || psStringEq operator ">=" || psStringEq operator "≥" then Option.some 50
  else if psStringEq operator "+" || psStringEq operator "-" then Option.some 65
  else if psStringEq operator "*" || psStringEq operator "/" || psStringEq operator "%" then Option.some 70
  else Option.none

def psOperatorNode
    (operator : String) (left right : PsSyntaxTerm) (tokenSpan : PsSourceSpan) :
    PsSyntaxTerm :=
  let span := psSyntaxSpanJoin (psSyntaxTermSpan left) (psSyntaxTermSpan right);
  if psStringEq operator "×" then
    PsSyntaxTerm.app (psSyntaxRootReference ["Prod"] tokenSpan) [left, right] span
  else
    PsSyntaxTerm.binary operator left right span

/-- The nonassociative flag belongs to this parse level, not the AST. Parentheses
therefore permit explicitly grouped equality without permitting a < b < c. -/
def psParseOperatorTailWithFuel
    (parseOperand : Nat -> PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    Nat -> Bool -> PsParseResult PsSyntaxTerm ->
    Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | Nat.zero =>
      fun (_minimum : Nat) (_comparisonUsed : Bool)
          (_left : PsParseResult PsSyntaxTerm) =>
        Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (minimum : Nat) (comparisonUsed : Bool)
          (left : PsParseResult PsSyntaxTerm) =>
        let smaller :
            Nat -> Bool -> PsParseResult PsSyntaxTerm ->
            Except PsParseError (PsParseResult PsSyntaxTerm) :=
          psParseOperatorTailWithFuel parseOperand remaining;
        match psTokenCursorPeek left.cursor with
        | Option.none => Except.ok left
        | Option.some token =>
            match psOperatorPrecedence token.text with
            | Option.none => Except.ok left
            | Option.some precedence =>
                if Nat.ble (Nat.succ precedence) minimum then Except.ok left
                else if comparisonUsed && Nat.beq precedence 50 then
                  Except.error (PsParseError.expectedText
                    "parentheses around nonassociative comparison" token.text token.span)
                else
                  match psTokenCursorAdvance left.cursor with
                  | Option.none => Except.error (PsParseError.unexpectedEnd "operator right operand")
                  | Option.some afterOperator =>
                      let rightMinimum :=
                        if psStringEq token.text "×" then precedence else Nat.succ precedence;
                      match parseOperand rightMinimum afterOperator.cursor with
                      | Except.error error => Except.error error
                      | Except.ok right =>
                          smaller minimum (Nat.beq precedence 50)
                            { value := psOperatorNode token.text left.value right.value token.span
                              cursor := right.cursor }

/-- Pratt parsing over the existing source-specific application parser. The
callback owns parentheses/calls; this layer owns only the fixed operator table. -/
def psParseOperatorsWithFuel
    (parseAtom : PsTokenCursor ->
      Except PsParseError (PsParseResult PsSyntaxTerm))
    (fuel : Nat) :
    Nat -> PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm) :=
  match fuel with
  | Nat.zero =>
      fun (_minimum : Nat) (_cursor : PsTokenCursor) =>
        Except.error PsParseError.fuelExhausted
  | Nat.succ remaining =>
      fun (minimum : Nat) (cursor : PsTokenCursor) =>
        let parseOperand :
            Nat -> PsTokenCursor -> Except PsParseError (PsParseResult PsSyntaxTerm) :=
          psParseOperatorsWithFuel parseAtom remaining;
        let primary : Except PsParseError (PsParseResult PsSyntaxTerm) :=
          match psTokenCursorPeek cursor with
          | Option.some token =>
              if psStringEq token.text "-" || psStringEq token.text "!" then
                match psTokenCursorAdvance cursor with
                | Option.none => Except.error (PsParseError.unexpectedEnd "prefix operand")
                | Option.some afterPrefix =>
                    let operandMinimum := if psStringEq token.text "-" then 75 else 40;
                    match parseOperand operandMinimum afterPrefix.cursor with
                    | Except.error error => Except.error error
                    | Except.ok operand =>
                        Except.ok
                          { value := PsSyntaxTerm.unary token.text operand.value
                              (psSyntaxSpanJoin token.span (psSyntaxTermSpan operand.value))
                            cursor := operand.cursor }
              else parseAtom cursor
          | Option.none => parseAtom cursor;
        match primary with
        | Except.error error => Except.error error
        | Except.ok left =>
            psParseOperatorTailWithFuel parseOperand (Nat.succ remaining) minimum false left
