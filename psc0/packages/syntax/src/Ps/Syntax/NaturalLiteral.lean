import Ps.Syntax.Cursor
import Ps.Syntax.Lexer

def psCharCodeEq (char : Char) (code : Nat) : Bool :=
  Nat.beq (Char.toNat char) code

def psDecimalDigitValue (char : Char) : Option Nat :=
  if psCharCodeEq char 48 then
    Option.some 0
  else if psCharCodeEq char 49 then
    Option.some 1
  else if psCharCodeEq char 50 then
    Option.some 2
  else if psCharCodeEq char 51 then
    Option.some 3
  else if psCharCodeEq char 52 then
    Option.some 4
  else if psCharCodeEq char 53 then
    Option.some 5
  else if psCharCodeEq char 54 then
    Option.some 6
  else if psCharCodeEq char 55 then
    Option.some 7
  else if psCharCodeEq char 56 then
    Option.some 8
  else if psCharCodeEq char 57 then
    Option.some 9
  else
    Option.none

def psParseNaturalChars
    (chars : List Char) :
    Nat -> Option Nat :=
  match chars with
  | [] =>
      fun (value : Nat) =>
        Option.some value
  | char :: rest =>
      let smaller : Nat -> Option Nat :=
        psParseNaturalChars rest;
      fun (value : Nat) =>
        if psCharCodeEq char 95 then
          smaller value
        else
          match psDecimalDigitValue char with
          | Option.none =>
              Option.none
          | Option.some digit =>
              smaller (Nat.add (Nat.mul value 10) digit)

def psHexDigitValue (char : Char) : Option Nat :=
  if psCharCodeEq char 48 then
    Option.some 0
  else if psCharCodeEq char 49 then
    Option.some 1
  else if psCharCodeEq char 50 then
    Option.some 2
  else if psCharCodeEq char 51 then
    Option.some 3
  else if psCharCodeEq char 52 then
    Option.some 4
  else if psCharCodeEq char 53 then
    Option.some 5
  else if psCharCodeEq char 54 then
    Option.some 6
  else if psCharCodeEq char 55 then
    Option.some 7
  else if psCharCodeEq char 56 then
    Option.some 8
  else if psCharCodeEq char 57 then
    Option.some 9
  else if psCharCodeEq char 97 then
    Option.some 10
  else if psCharCodeEq char 98 then
    Option.some 11
  else if psCharCodeEq char 99 then
    Option.some 12
  else if psCharCodeEq char 100 then
    Option.some 13
  else if psCharCodeEq char 101 then
    Option.some 14
  else if psCharCodeEq char 102 then
    Option.some 15
  else if psCharCodeEq char 65 then
    Option.some 10
  else if psCharCodeEq char 66 then
    Option.some 11
  else if psCharCodeEq char 67 then
    Option.some 12
  else if psCharCodeEq char 68 then
    Option.some 13
  else if psCharCodeEq char 69 then
    Option.some 14
  else if psCharCodeEq char 70 then
    Option.some 15
  else
    Option.none

-- Numeral values are parsed independently of source spelling. This is
-- also the single validity gate for grouped decimal and radix literals.
def psParseRadixChars (base : Nat) (chars : List Char) (value digits : Nat)
    (trailingSeparator : Bool) : Option Nat :=
  match chars with
  | [] =>
    if digits == 0 || trailingSeparator then none else some value
  | char :: rest =>
    if psCharCodeEq char 95 then
      psParseRadixChars base rest value digits true
    else
      match psHexDigitValue char with
      | none => none
      | some digit =>
        if digit >= base then none
        else psParseRadixChars base rest (value * base + digit) (digits + 1) false

def psParseNaturalText (text : String) : Option Nat :=
  let chars := psLexStringToList text
  match chars with
  | first :: radix :: rest =>
    if psCharCodeEq first 48 then
      let base :=
        if psCharCodeEq radix 98 || psCharCodeEq radix 66 then some 2
        else if psCharCodeEq radix 111 || psCharCodeEq radix 79 then some 8
        else if psCharCodeEq radix 120 || psCharCodeEq radix 88 then some 16
        else none
      match base with
      | some selected => psParseRadixChars selected rest 0 0 false
      | none => psParseRadixChars 10 chars 0 0 false
    else psParseRadixChars 10 chars 0 0 false
  | _ => psParseRadixChars 10 chars 0 0 false

