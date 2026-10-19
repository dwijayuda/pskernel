import Ps.Syntax.Pscv0.LocalRead
import Ps.Syntax.Pscv0.Operators

/-!
Closed shared calc layout from pinned Lean 4.35.0 Init/NotationExtra.lean.
The first step may be a bare term; later steps require := and a proof.
Terms, adjacent-call policy and proof bodies remain owned by the caller's
selected reader. Native calc uses a linebreak before each later step.
-/

def psPscv0CalcBoundary (cursor : PsTokenCursor) : Bool :=
  psTokenCursorDone cursor ||
    [")", "]", "}", ",", ";", "<;>"].any (psTokenCursorAtText cursor) ||
    (psTokenCursorPeek cursor).any (fun token =>
      psTokenCursorAtText cursor token.text && psLexReservedIdentifier token.text &&
        !["by", "calc", "do", "nomatch", "match", "if", "have", "suffices", "show",
          "exists", "let", "fun", "forall", "Prop", "Type", "Sort", "true", "false"].contains token.text)

def psPscv0ReadCalcTail (read readType : PsPscv0TermReader) (fuel : Nat)
    (column : Option Nat) (previousStop : PsSourcePos) (cursor : PsTokenCursor) :
    Except PsParseError (PsParseResult (List (PsSyntaxTerm × PsSyntaxTerm))) := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    let some token := psTokenCursorPeek cursor | return { value := [], cursor }
    if psPscv0CalcBoundary cursor || token.span.start.line <= previousStop.line ||
        column.any (fun first => token.span.start.column < first) then
      return { value := [], cursor }
    -- Native many(calcStep) leaves an outer command/tactic untouched when
    -- it does not form an annotated calculation step.
    let annotation ← match readType cursor with
      | .ok value => pure value
      | .error .fuelExhausted => throw .fuelExhausted
      | .error _ => return { value := [], cursor }
    if !psTokenCursorAtText annotation.cursor ":=" then return { value := [], cursor }
    let assign ← psTokenCursorExpectText annotation.cursor ":="
    let proof ← read assign.cursor
    let rest ← psPscv0ReadCalcTail read readType fuel
      (some (column.getD token.span.start.column)) (psSyntaxTermSpan proof.value).stop proof.cursor
    return { value := (annotation.value, proof.value) :: rest.value, cursor := rest.cursor }

def psPscv0ReadCalc (read readType : PsPscv0TermReader) (fuel : Nat)
    (cursor : PsTokenCursor) : Except PsParseError (PsParseResult PsSyntaxTerm) := do
  let head ← psTokenCursorExpectText cursor "calc"
  if psPscv0CalcBoundary head.cursor then
    throw (psProofScriptExpectedError "first calc step" head.cursor)
  let first ← readType head.cursor
  let (annotation, proof, cursor) ← if psTokenCursorAtText first.cursor ":=" then do
      let assign ← psTokenCursorExpectText first.cursor ":="
      let proof ← read assign.cursor
      pure (first.value, proof.value, proof.cursor)
    else do
      let span := psSyntaxTermSpan first.value
      let annotation := psPscv0OperatorTerm .relation "Eq" "=" [first.value, .hole span] span
      pure (annotation, PsSyntaxTerm.byE [.reflexivity span] {} span, first.cursor)
  let rest ← psPscv0ReadCalcTail read readType fuel none (psSyntaxTermSpan proof).stop cursor
  let steps := (annotation, proof) :: rest.value
  let stop := match steps.getLast? with
    | some (_, proof) => (psSyntaxTermSpan proof).stop
    | none => (psSyntaxTermSpan first.value).stop
  return { value := .calcE steps { start := head.token.span.start, stop }, cursor := rest.cursor }
