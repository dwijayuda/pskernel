import Ps.Syntax.Pscv0.PatternRead

inductive PsPscv0InfixKind where
  | constant (name : String)
  | arrow
  | matches

structure PsPscv0Infix where
  kind : PsPscv0InfixKind
  precedence : Nat
  rightPrecedence : Nat
  nonAssociative : Bool := false

-- Closed source registry; extending notation does not change call or binder
-- grammar. Precedence comes from the pinned RC4 parser/notation declarations.
def psPscv0InfixInfo : String → Option PsPscv0Infix
  | "=" => some { kind := .constant "Eq", precedence := 50, rightPrecedence := 51, nonAssociative := true }
  | "∧" | "/\\" => some { kind := .constant "And", precedence := 35, rightPrecedence := 35 }
  | "∨" | "\\/" => some { kind := .constant "Or", precedence := 30, rightPrecedence := 30 }
  | "↔" | "<->" => some { kind := .constant "Iff", precedence := 20, rightPrecedence := 21, nonAssociative := true }
  | "→" | "->" => some { kind := .arrow, precedence := 25, rightPrecedence := 25 }
  | "matches" => some { kind := .matches, precedence := 50, rightPrecedence := 51, nonAssociative := true }
  | _ => none

-- The common lexer already splits the multi-symbol ASCII aliases. Join only
-- adjacent registered spellings; whitespace can never manufacture an operator.
def psPscv0InfixToken (cursor : PsTokenCursor) :
    Option (PsPscv0Infix × PsSourceSpan × PsTokenCursor) :=
  match cursor.remaining with
  | [] => none
  | first :: rest =>
    match psPscv0InfixInfo first.text with
    | some info => some (info, first.span, { remaining := rest })
    | none => match rest with
      | second :: tail =>
        if first.span.stop.byteOffset != second.span.start.byteOffset then none else
        (psPscv0InfixInfo (first.text ++ second.text)).map fun info =>
          (info, psSyntaxSpanJoin first.span second.span, { remaining := tail })
      | [] => none

def psPscv0NotationCall (name : String) (arguments : List PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  .call (.reference (PsSyntaxName.mk ["_root_", name] span))
    (arguments.map fun argument => (none, argument)) span

def psPscv0OperatorTail (read : Nat → PsPscv0TermReader) (minimum fuel : Nat)
    (left : PsParseResult PsSyntaxTerm) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some (info, _, after) := psPscv0InfixToken left.cursor | return left
    if info.precedence < minimum then return left
    let combined ← match info.kind with
      | .matches => psPscv0MatchesTail left
      | _ => do
        let right ← read info.rightPrecedence after
        let span := psSyntaxSpanJoin (psSyntaxTermSpan left.value) (psSyntaxTermSpan right.value)
        let value := match info.kind with
          | .arrow => PsSyntaxTerm.forallE
              [(psSyntaxAnonymousExplicitBinder (psSyntaxTermSpan left.value), left.value)] right.value span
          | .constant name => psPscv0NotationCall name [left.value, right.value] span
          | .matches => left.value
        pure { value, cursor := right.cursor }
    if info.nonAssociative then
      if (psPscv0InfixToken combined.cursor).any (fun next => next.1.precedence == info.precedence) then
        throw (psProofScriptExpectedError "parentheses around chained non-associative operators" combined.cursor)
    psPscv0OperatorTail read minimum fuel combined
