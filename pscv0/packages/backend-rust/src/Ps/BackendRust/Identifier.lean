import Ps.Bridge.Json
import Ps.Foundation.Name

def psRustIdentifierConcat2
    (left right : String) : String :=
  String.Internal.append left right

def psRustIdentifierConcat3
    (first second third : String) : String :=
  psRustIdentifierConcat2
    (psRustIdentifierConcat2 first second)
    third

def psRustIdentifierSingleChar
    (char : Char) : String :=
  psJsonStringOfChars
    (List.cons char List.nil)

def psRustIdentifierNatBetween
    (lower value upper : Nat) : Bool :=
  if Nat.ble lower value then
    Nat.ble value upper
  else
    false

def psRustIdentifierCharAllowed
    (char : Char) : Bool :=
  let code : Nat := Char.toNat char;
  if psRustIdentifierNatBetween 48 code 57 then
    true
  else if psRustIdentifierNatBetween 65 code 90 then
    true
  else if psRustIdentifierNatBetween 97 code 122 then
    true
  else
    Nat.beq code 95

def psRustIdentifierEncodeChars
    (chars : List Char) : Prod String Bool :=
  match chars with
  | List.nil =>
      Prod.mk "" false
  | List.cons char rest =>
      let encodedRest : Prod String Bool :=
        psRustIdentifierEncodeChars rest;
      if psRustIdentifierCharAllowed char then
        Prod.mk
          (psRustIdentifierConcat2
            (psRustIdentifierSingleChar char)
            (Prod.fst encodedRest))
          (Prod.snd encodedRest)
      else
        Prod.mk
          (psRustIdentifierConcat2
            (psRustIdentifierConcat3
              "_u"
              (psNatToString (Char.toNat char))
              "_")
            (Prod.fst encodedRest))
          true

def psRustIdentifierCharsStartWith
    (value : List Char) :
    List Char -> Bool :=
  match value with
  | List.nil =>
      fun (expected : List Char) =>
        match expected with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons valueHead valueRest =>
      let smaller : List Char -> Bool :=
        psRustIdentifierCharsStartWith valueRest;
      fun (expected : List Char) =>
        match expected with
        | List.nil =>
            true
        | List.cons expectedHead expectedRest =>
            if Nat.beq
                (Char.toNat valueHead)
                (Char.toNat expectedHead) then
              smaller expectedRest
            else
              false

def psRustIdentifierStartsWith
    (value expected : String) : Bool :=
  psRustIdentifierCharsStartWith
    (psJsonStringToChars value)
    (psJsonStringToChars expected)

def psRustIdentifierFirstAllowed
    (chars : List Char) : Bool :=
  match chars with
  | List.nil =>
      false
  | List.cons first _ =>
      let code : Nat := Char.toNat first;
      if psRustIdentifierNatBetween 65 code 90 then
        true
      else if psRustIdentifierNatBetween 97 code 122 then
        true
      else
        Nat.beq code 95

def psRustIdentifierReservedPrefix
    (value : String) : Bool :=
  if psRustIdentifierStartsWith value "__psr_" then
    true
  else if psRustIdentifierStartsWith value "__ps_kw_" then
    true
  else
    psRustIdentifierStartsWith value "__ps_internal_"

def psRustIdentifierStringIn
    (value : String)
    (options : List String) : Bool :=
  match options with
  | List.nil =>
      false
  | List.cons option rest =>
      if psStringEq value option then
        true
      else
        psRustIdentifierStringIn value rest

def psRustIdentifierSpecialKeyword
    (value : String) : Bool :=
  psRustIdentifierStringIn
    value
    ["self", "Self", "super", "crate"]

def psRustIdentifierKeyword
    (value : String) : Bool :=
  psRustIdentifierStringIn
    value
    [
      "as", "async", "await", "become", "box", "break", "const",
      "continue", "crate", "do", "dyn", "else", "enum", "extern",
      "false", "final", "fn", "for", "gen", "if", "impl", "in",
      "let", "loop", "macro", "match", "mod", "move", "mut",
      "override", "priv", "pub", "ref", "return", "self", "Self",
      "static", "struct", "super", "trait", "true", "try", "type",
      "typeof", "unsafe", "unsized", "use", "virtual", "where",
      "while", "yield"
    ]

def psRustIdentifier
    (value : String) : String :=
  let chars : List Char :=
    psJsonStringToChars value;
  let encoded : Prod String Bool :=
    psRustIdentifierEncodeChars chars;
  let encodedText : String :=
    Prod.fst encoded;
  let changed : Bool :=
    Prod.snd encoded;
  let mustEncode : Bool :=
    if changed then
      true
    else if psRustIdentifierFirstAllowed chars then
      psRustIdentifierReservedPrefix value
    else
      true;
  if mustEncode then
    psRustIdentifierConcat2
      "__psr_"
      encodedText
  else if psRustIdentifierSpecialKeyword value then
    psRustIdentifierConcat2
      "__ps_kw_"
      value
  else if psRustIdentifierKeyword value then
    psRustIdentifierConcat2
      "r#"
      value
  else
    value
