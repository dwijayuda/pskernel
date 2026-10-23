import ProofScript.System.IO

inductive MiniExpr where
  | add (left right : Nat)

inductive MiniError where
  | unexpectedToken
  | expectedPlus
  | expectedNumber
  | expectedSemicolon
  | unexpectedEnd

structure MiniDiagnostic where
  kind : MiniError
  offset : Nat
  line : Nat
  column : Nat

structure MiniSummary where
  statements : Nat
  total : Nat

def miniFold (expression : MiniExpr) : Nat :=
  match expression with
  | MiniExpr.add left right => left + right

def miniIsDigit (code : Nat) : Bool :=
  if code < 48 then false
  else if code > 57 then false
  else true

def miniWhitespace (code : Nat) : Bool :=
  Nat.beq code 32 || Nat.beq code 9 || Nat.beq code 10 || Nat.beq code 13

-- One streaming lexer/parser. Each completed statement constructs an add AST;
-- the total transformation folds it immediately, retaining bounded parser state.
-- There is no runtime fuel or host parsing of the input.
partial def miniCompile (source : String) : Id (Result MiniSummary MiniDiagnostic) := do
  let mut position : Nat := 0
  let mut line : Nat := 1
  let mut column : Nat := 1
  let mut phase : Nat := 0
  let mut left : Nat := 0
  let mut right : Nat := 0
  let mut statements : Nat := 0
  let mut total : Nat := 0
  while !(String.Internal.atEnd source position) do
    let code : Nat := Char.toNat (String.Internal.get source position)
    if miniWhitespace code then
      if phase == 1 then phase := 2
      else if phase == 4 then phase := 5
      else pure ()
    else if code == 43 then
      if phase == 1 || phase == 2 then phase := 3
      else return Result.error (MiniDiagnostic.mk MiniError.expectedNumber position line column)
    else if code == 59 then
      if phase == 4 || phase == 5 then
        let expression : MiniExpr := MiniExpr.add left right
        total := total + miniFold expression
        statements := statements + 1
        left := 0
        right := 0
        phase := 0
      else return Result.error (MiniDiagnostic.mk MiniError.expectedNumber position line column)
    else
      if !(miniIsDigit code) then
        return Result.error (MiniDiagnostic.mk MiniError.unexpectedToken position line column)
      else
        let digit : Nat := code - 48
        if phase == 0 || phase == 1 then
          left := left * 10 + digit
          phase := 1
        else if phase == 3 || phase == 4 then
          right := right * 10 + digit
          phase := 4
        else if phase == 2 then
          return Result.error (MiniDiagnostic.mk MiniError.expectedPlus position line column)
        else
          return Result.error (MiniDiagnostic.mk MiniError.expectedSemicolon position line column)
    if code == 10 then
      line := line + 1
      column := 1
    else column := column + 1
    position := String.Internal.next source position
  if phase == 0 then return Result.ok (MiniSummary.mk statements total)
  else return Result.error (MiniDiagnostic.mk MiniError.unexpectedEnd position line column)

def miniErrorName (kind : MiniError) : String :=
  match kind with
  | MiniError.unexpectedToken => "unexpected-token"
  | MiniError.expectedPlus => "expected-plus"
  | MiniError.expectedNumber => "expected-number"
  | MiniError.expectedSemicolon => "expected-semicolon"
  | MiniError.unexpectedEnd => "unexpected-end"

def miniNatText (value : Nat) : String := Int.repr (Int.ofNat value)

def miniDiagnosticText (diagnostic : MiniDiagnostic) : String :=
  jsonAppend (miniErrorName diagnostic.kind)
    (jsonAppend "@" (jsonAppend (miniNatText diagnostic.offset)
      (jsonAppend ":" (jsonAppend (miniNatText diagnostic.line)
        (jsonAppend ":" (miniNatText diagnostic.column))))))

def miniRender (summary : MiniSummary) : Result String JsonError :=
  match jsonObjectFromTwo "statements" (JsonValue.number (miniNatText summary.statements))
      "total" (JsonValue.number (miniNatText summary.total)) with
  | Result.error error => Result.error error
  | Result.ok value => jsonEncodeCanonical value
