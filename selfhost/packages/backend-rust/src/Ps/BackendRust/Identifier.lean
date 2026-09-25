import Ps.Bridge.Json

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

def psRustIdentifierCharAllowed
    (char : Char) : Bool :=
  char.isAlphanum || char == '_'

def psRustIdentifierEncodeChars :
    List Char -> Prod String Bool
  | List.nil =>
      Prod.mk "" false
  | List.cons char rest =>
      let encodedRest :=
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
              (toString (Char.toNat char))
              "_")
            (Prod.fst encodedRest))
          true

def psRustIdentifierCharsStartWith :
    List Char -> List Char -> Bool
  | _, List.nil =>
      true
  | List.nil, List.cons _ _ =>
      false
  | List.cons value valueRest,
      List.cons expected expectedRest =>
      if value == expected then
        psRustIdentifierCharsStartWith
          valueRest
          expectedRest
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
      first.isAlpha || first == '_'

def psRustIdentifierReservedPrefix
    (value : String) : Bool :=
  psRustIdentifierStartsWith value "__psr_"
    || psRustIdentifierStartsWith value "__ps_kw_"

def psRustIdentifierSpecialKeyword
    (value : String) : Bool :=
  psStringEq value "self"
    || psStringEq value "Self"
    || psStringEq value "super"
    || psStringEq value "crate"

def psRustIdentifierKeyword
    (value : String) : Bool :=
  psStringEq value "as"
    || psStringEq value "async"
    || psStringEq value "await"
    || psStringEq value "become"
    || psStringEq value "box"
    || psStringEq value "break"
    || psStringEq value "const"
    || psStringEq value "continue"
    || psStringEq value "crate"
    || psStringEq value "do"
    || psStringEq value "dyn"
    || psStringEq value "else"
    || psStringEq value "enum"
    || psStringEq value "extern"
    || psStringEq value "false"
    || psStringEq value "final"
    || psStringEq value "fn"
    || psStringEq value "for"
    || psStringEq value "gen"
    || psStringEq value "if"
    || psStringEq value "impl"
    || psStringEq value "in"
    || psStringEq value "let"
    || psStringEq value "loop"
    || psStringEq value "macro"
    || psStringEq value "match"
    || psStringEq value "mod"
    || psStringEq value "move"
    || psStringEq value "mut"
    || psStringEq value "override"
    || psStringEq value "priv"
    || psStringEq value "pub"
    || psStringEq value "ref"
    || psStringEq value "return"
    || psStringEq value "self"
    || psStringEq value "Self"
    || psStringEq value "static"
    || psStringEq value "struct"
    || psStringEq value "super"
    || psStringEq value "trait"
    || psStringEq value "true"
    || psStringEq value "try"
    || psStringEq value "type"
    || psStringEq value "typeof"
    || psStringEq value "unsafe"
    || psStringEq value "unsized"
    || psStringEq value "use"
    || psStringEq value "virtual"
    || psStringEq value "where"
    || psStringEq value "while"
    || psStringEq value "yield"

def psRustIdentifier
    (value : String) : String :=
  let chars :=
    psJsonStringToChars value;
  let encoded :=
    psRustIdentifierEncodeChars chars;
  let encodedText :=
    Prod.fst encoded;
  let changed :=
    Prod.snd encoded;
  if changed
      || !psRustIdentifierFirstAllowed chars
      || psRustIdentifierReservedPrefix value then
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
