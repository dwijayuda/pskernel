import Ps.Syntax.Pscv0.PatternRead

inductive PsPscv0InfixKind where
  | constant (name : String)
  | operator (kind : PsSyntaxOperatorKind) (name : String)
  | arrow
  | booleanAnd
  | booleanOr
  | booleanNotEqual
  | matches

structure PsPscv0Infix where
  kind : PsPscv0InfixKind
  precedence : Nat
  rightPrecedence : Nat
  nonAssociative : Bool := false

-- Enumerated closed source registry. Parser lookup and exhaustive native
-- manifest auditing consume this single list; the independently pinned ledger
-- still rejects unreviewed additions. Lean 4.35.0 Init/Notation.lean supplies
-- precedence/targets; GT/GE are the reducible reversed LT/LE in Init/Prelude.
-- Source comparisons stay non-associative; adjacent-call rules are unchanged.
def psPscv0InfixRegistry : List (String × PsPscv0Infix) := [
  ("=", { kind := .operator .relation "Eq", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("==", { kind := .operator .booleanRelation "BEq.beq", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("!=", { kind := .booleanNotEqual, precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("<", { kind := .operator .relation "LT.lt", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("<=", { kind := .operator .relation "LE.le", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("≤", { kind := .operator .relation "LE.le", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  (">", { kind := .operator .relation "GT.gt", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  (">=", { kind := .operator .relation "GE.ge", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("≥", { kind := .operator .relation "GE.ge", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("≠", { kind := .operator .relation "Ne", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("∧", { kind := .constant "And", precedence := 35, rightPrecedence := 35 }),
  ("/\\", { kind := .constant "And", precedence := 35, rightPrecedence := 35 }),
  ("∨", { kind := .constant "Or", precedence := 30, rightPrecedence := 30 }),
  ("\\/", { kind := .constant "Or", precedence := 30, rightPrecedence := 30 }),
  ("&&", { kind := .booleanAnd, precedence := 35, rightPrecedence := 36 }),
  ("||", { kind := .booleanOr, precedence := 30, rightPrecedence := 31 }),
  ("↔", { kind := .constant "Iff", precedence := 20, rightPrecedence := 21, nonAssociative := true }),
  ("<->", { kind := .constant "Iff", precedence := 20, rightPrecedence := 21, nonAssociative := true }),
  ("×", { kind := .constant "Prod", precedence := 35, rightPrecedence := 35 }),
  ("::", { kind := .constant "List.cons", precedence := 67, rightPrecedence := 67 }),
  ("+", { kind := .operator .binary "HAdd.hAdd", precedence := 65, rightPrecedence := 66 }),
  ("++", { kind := .operator .binary "HAppend.hAppend", precedence := 65, rightPrecedence := 66 }),
  ("-", { kind := .operator .binary "HSub.hSub", precedence := 65, rightPrecedence := 66 }),
  ("*", { kind := .operator .binary "HMul.hMul", precedence := 70, rightPrecedence := 71 }),
  ("/", { kind := .operator .binary "HDiv.hDiv", precedence := 70, rightPrecedence := 71 }),
  ("%", { kind := .operator .binary "HMod.hMod", precedence := 70, rightPrecedence := 71 }),
  ("→", { kind := .arrow, precedence := 25, rightPrecedence := 25 }),
  ("->", { kind := .arrow, precedence := 25, rightPrecedence := 25 }),
  ("<<<", { kind := .constant "HShiftLeft.hShiftLeft", precedence := 75, rightPrecedence := 76 }),
  (">>>", { kind := .constant "HShiftRight.hShiftRight", precedence := 75, rightPrecedence := 76 }),
  ("^", { kind := .operator .rightAction "HPow.hPow", precedence := 80, rightPrecedence := 80 }),
  ("matches", { kind := .matches, precedence := 50, rightPrecedence := 51, nonAssociative := true })
]

def psPscv0InfixInfo (token : String) : Option PsPscv0Infix :=
  (psPscv0InfixRegistry.find? fun entry => entry.1 == token).map Prod.snd

structure PsPscv0ParsedInfix where
  spelling : String
  info : PsPscv0Infix
  span : PsSourceSpan
  cursor : PsTokenCursor

-- Longest registered adjacent spelling wins. Bound the scan by the longest
-- spelling in the actual registry; spaces can never create an operator.
private def psPscv0InfixScan (fuel : Nat) (cursor : PsTokenCursor)
    (spellingSoFar : String) (span : PsSourceSpan)
    (best : Option PsPscv0ParsedInfix) : Option PsPscv0ParsedInfix :=
  match fuel, cursor.remaining with
  | 0, _ | _, [] => best
  | fuel + 1, token :: rest =>
    if !spellingSoFar.isEmpty && span.stop.byteOffset != token.span.start.byteOffset then best else
    let spelling := spellingSoFar ++ token.text
    let span := if spellingSoFar.isEmpty then token.span else psSyntaxSpanJoin span token.span
    let cursor : PsTokenCursor := { remaining := rest }
    let best := match psPscv0InfixInfo spelling with
      | none => best
      | some info => some { spelling, info, span, cursor }
    psPscv0InfixScan fuel cursor spelling span best

private def psPscv0InfixMaximumLength : Nat :=
  psPscv0InfixRegistry.foldl (fun n entry => max n entry.1.length) 0

def psPscv0InfixToken (cursor : PsTokenCursor) : Option PsPscv0ParsedInfix :=
  match cursor.remaining with
  | [] => none
  | first :: _ =>
    psPscv0InfixScan psPscv0InfixMaximumLength cursor "" first.span none

def psPscv0OperatorTerm (kind : PsSyntaxOperatorKind) (name spelling : String)
    (arguments : List PsSyntaxTerm) (span : PsSourceSpan) : PsSyntaxTerm :=
  .operatorE kind (PsSyntaxName.mk ("_root_" :: name.splitOn ".") span) spelling arguments span

def psPscv0NotationCall (name : String) (arguments : List PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  .call (.reference (PsSyntaxName.mk ("_root_" :: name.splitOn ".") span))
    (arguments.map fun argument => (none, argument)) span

def psPscv0OperatorTail (read : Nat → PsPscv0TermReader) (minimum fuel : Nat)
    (left : PsParseResult PsSyntaxTerm) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psPscv0InfixToken left.cursor | return left
    let info := token.info
    let after := token.cursor
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
          | .operator kind name =>
            psPscv0OperatorTerm kind name token.spelling [left.value, right.value] span
          | .booleanAnd => .ifE none left.value right.value (.bool false span) span
          | .booleanOr => .ifE none left.value (.bool true span) right.value span
          | .booleanNotEqual =>
            .ifE none (psPscv0OperatorTerm .booleanRelation "BEq.beq" "==" [left.value, right.value] span)
              (.bool false span) (.bool true span) span
          | .matches => left.value
        pure { value, cursor := right.cursor }
    if info.nonAssociative then
      if (psPscv0InfixToken combined.cursor).any (fun next => next.info.precedence == info.precedence) then
        throw (psProofScriptExpectedError "parentheses around chained non-associative operators" combined.cursor)
    psPscv0OperatorTail read minimum fuel combined
