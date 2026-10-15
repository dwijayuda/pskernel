import Ps.Syntax.Pscv0.PatternRead

inductive PsPscv0InfixKind where
  | constant (name : String)
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
  ("=", { kind := .constant "Eq", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("==", { kind := .constant "BEq.beq", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("!=", { kind := .booleanNotEqual, precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("<", { kind := .constant "LT.lt", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("<=", { kind := .constant "LE.le", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("≤", { kind := .constant "LE.le", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  (">", { kind := .constant "GT.gt", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  (">=", { kind := .constant "GE.ge", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("≥", { kind := .constant "GE.ge", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
  ("≠", { kind := .constant "Ne", precedence := 50, rightPrecedence := 51, nonAssociative := true }),
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
  ("+", { kind := .constant "HAdd.hAdd", precedence := 65, rightPrecedence := 66 }),
  ("++", { kind := .constant "HAppend.hAppend", precedence := 65, rightPrecedence := 66 }),
  ("-", { kind := .constant "HSub.hSub", precedence := 65, rightPrecedence := 66 }),
  ("*", { kind := .constant "HMul.hMul", precedence := 70, rightPrecedence := 71 }),
  ("/", { kind := .constant "HDiv.hDiv", precedence := 70, rightPrecedence := 71 }),
  ("%", { kind := .constant "HMod.hMod", precedence := 70, rightPrecedence := 71 }),
  ("→", { kind := .arrow, precedence := 25, rightPrecedence := 25 }),
  ("->", { kind := .arrow, precedence := 25, rightPrecedence := 25 }),
  ("matches", { kind := .matches, precedence := 50, rightPrecedence := 51, nonAssociative := true })
]

def psPscv0InfixInfo (token : String) : Option PsPscv0Infix :=
  (psPscv0InfixRegistry.find? fun entry => entry.1 == token).map Prod.snd

-- The common lexer already splits the multi-symbol ASCII aliases. Join only
-- adjacent registered spellings; whitespace can never manufacture an operator.
def psPscv0InfixToken (cursor : PsTokenCursor) :
    Option (PsPscv0Infix × PsSourceSpan × PsTokenCursor) :=
  match cursor.remaining with
  | [] => none
  | first :: rest =>
    -- Maximal adjacent operator recognition must precede single-token
    -- selection. Otherwise enabling '/' steals the first token of '/\\',
    -- and similarly other longer registered spellings can change meaning.
    let combined := match rest with
      | second :: tail =>
        if first.span.stop.byteOffset == second.span.start.byteOffset then
          (psPscv0InfixInfo (first.text ++ second.text)).map fun info =>
            (info, psSyntaxSpanJoin first.span second.span, { remaining := tail })
        else none
      | [] => none
    match combined with
    | some result => some result
    | none => (psPscv0InfixInfo first.text).map fun info =>
        (info, first.span, { remaining := rest })

def psPscv0NotationCall (name : String) (arguments : List PsSyntaxTerm)
    (span : PsSourceSpan) : PsSyntaxTerm :=
  .call (.reference (PsSyntaxName.mk ("_root_" :: name.splitOn ".") span))
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
          | .booleanAnd => .ifE none left.value right.value (.bool false span) span
          | .booleanOr => .ifE none left.value (.bool true span) right.value span
          | .booleanNotEqual =>
            .ifE none (psPscv0NotationCall "BEq.beq" [left.value, right.value] span)
              (.bool false span) (.bool true span) span
          | .matches => left.value
        pure { value, cursor := right.cursor }
    if info.nonAssociative then
      if (psPscv0InfixToken combined.cursor).any (fun next => next.1.precedence == info.precedence) then
        throw (psProofScriptExpectedError "parentheses around chained non-associative operators" combined.cursor)
    psPscv0OperatorTail read minimum fuel combined
