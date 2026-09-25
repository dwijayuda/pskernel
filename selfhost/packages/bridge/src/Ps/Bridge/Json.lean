def psJsonHexDigit (value : Nat) : String :=
  match value with
  | 0 => "0"
  | 1 => "1"
  | 2 => "2"
  | 3 => "3"
  | 4 => "4"
  | 5 => "5"
  | 6 => "6"
  | 7 => "7"
  | 8 => "8"
  | 9 => "9"
  | 10 => "a"
  | 11 => "b"
  | 12 => "c"
  | 13 => "d"
  | 14 => "e"
  | _ => "f"

def psJsonEscapeControl (value : Nat) : String :=
  "\\u00" ++
    psJsonHexDigit (value / 16) ++
    psJsonHexDigit (value % 16)

def psJsonEscapeChar (char : Char) : String :=
  let value := char.val
  if value == 8 then
    "\\b"
  else if value == 9 then
    "\\t"
  else if value == 10 then
    "\\n"
  else if value == 12 then
    "\\f"
  else if value == 13 then
    "\\r"
  else if value == 34 then
    "\\\""
  else if value == 92 then
    "\\\\"
  else if value < 32 then
    psJsonEscapeControl value.toNat
  else
    String.ofList [char]

def psJsonEscapeChars : List Char -> String
  | [] => ""
  | char :: rest =>
      psJsonEscapeChar char ++ psJsonEscapeChars rest

def psJsonQuote (value : String) : String :=
  "\"" ++ psJsonEscapeChars value.toList ++ "\""

def psJsonJoin (separator : String) : List String -> String
  | [] => ""
  | [value] => value
  | value :: rest =>
      value ++ separator ++ psJsonJoin separator rest

def psJsonArray (values : List String) : String :=
  "[" ++ psJsonJoin "," values ++ "]"

def psJsonField (key value : String) : String :=
  psJsonQuote key ++ ":" ++ value

def psJsonObject (sortedFields : List (String × String)) : String :=
  let fields :=
    sortedFields.map
      (fun field => psJsonField field.1 field.2)
  "{" ++ psJsonJoin "," fields ++ "}"


inductive PsJsonValue where
  | nullE
  | bool (value : Bool)
  | number (text : String)
  | string (value : String)
  | array (values : List PsJsonValue)
  | object (fields : List (String × PsJsonValue))

inductive PsJsonParseError where
  | fuelExhausted
  | unexpectedEnd
  | expected (text : String)
  | invalidEscape
  | invalidUnicodeEscape
  | invalidNumber
  | invalidLiteral
  | trailingInput

structure PsJsonParseResult where
  value : PsJsonValue
  rest : List Char

def psJsonWhitespace (char : Char) : Bool :=
  char == ' '
    || char == '\n'
    || char == '\r'
    || char == '\t'

def psJsonSkipWhitespace : List Char -> List Char
  | [] => []
  | char :: rest =>
      if psJsonWhitespace char then
        psJsonSkipWhitespace rest
      else
        char :: rest

def psJsonHexValue (char : Char) : Option Nat :=
  let value := char.val.toNat
  if value >= 48 && value <= 57 then
    some (value - 48)
  else if value >= 65 && value <= 70 then
    some (value - 55)
  else if value >= 97 && value <= 102 then
    some (value - 87)
  else
    none

def psJsonDecodeUnicode4
    (chars : List Char) :
    Except PsJsonParseError (Char × List Char) :=
  match chars with
  | a :: b :: c :: d :: rest =>
      match
          psJsonHexValue a,
          psJsonHexValue b,
          psJsonHexValue c,
          psJsonHexValue d with
      | some av, some bv, some cv, some dv =>
          let value :=
            av * 4096 + bv * 256 + cv * 16 + dv
          if value >= 55296 && value <= 57343 then
            Except.error PsJsonParseError.invalidUnicodeEscape
          else
            Except.ok (Char.ofNat value, rest)
      | _, _, _, _ =>
          Except.error PsJsonParseError.invalidUnicodeEscape
  | _ => Except.error PsJsonParseError.unexpectedEnd

def psJsonParseStringChars :
    Nat ->
    List Char ->
    List Char ->
    Except PsJsonParseError (String × List Char)
  | 0, _, _ => Except.error PsJsonParseError.fuelExhausted
  | _ + 1, [], _ => Except.error PsJsonParseError.unexpectedEnd
  | fuel + 1, char :: rest, charsRev =>
      if char == '"' then
        Except.ok (String.ofList charsRev.reverse, rest)
      else if char == '\\' then
        match rest with
        | [] => Except.error PsJsonParseError.unexpectedEnd
        | escaped :: tail =>
            if escaped == '"' then
              psJsonParseStringChars fuel tail ('"' :: charsRev)
            else if escaped == '\\' then
              psJsonParseStringChars fuel tail ('\\' :: charsRev)
            else if escaped == '/' then
              psJsonParseStringChars fuel tail ('/' :: charsRev)
            else if escaped == 'b' then
              psJsonParseStringChars fuel tail ('\b' :: charsRev)
            else if escaped == 'f' then
              psJsonParseStringChars fuel tail ('\f' :: charsRev)
            else if escaped == 'n' then
              psJsonParseStringChars fuel tail ('\n' :: charsRev)
            else if escaped == 'r' then
              psJsonParseStringChars fuel tail ('\r' :: charsRev)
            else if escaped == 't' then
              psJsonParseStringChars fuel tail ('\t' :: charsRev)
            else if escaped == 'u' then
              match psJsonDecodeUnicode4 tail with
              | Except.error error => Except.error error
              | Except.ok (decoded, afterUnicode) =>
                  psJsonParseStringChars
                    fuel
                    afterUnicode
                    (decoded :: charsRev)
            else
              Except.error PsJsonParseError.invalidEscape
      else if char.val.toNat < 32 then
        Except.error PsJsonParseError.invalidEscape
      else
        psJsonParseStringChars fuel rest (char :: charsRev)

def psJsonDigit (char : Char) : Bool :=
  let value := char.val.toNat
  value >= 48 && value <= 57

def psJsonTakeDigits :
    List Char -> List Char -> List Char × List Char
  | [], digitsRev => (digitsRev.reverse, [])
  | char :: rest, digitsRev =>
      if psJsonDigit char then
        psJsonTakeDigits rest (char :: digitsRev)
      else
        (digitsRev.reverse, char :: rest)

def psJsonParseNumber
    (chars : List Char) :
    Except PsJsonParseError PsJsonParseResult :=
  let parseUnsigned :=
    fun negative rest =>
      let taken := psJsonTakeDigits rest []
      match taken.1 with
      | [] => Except.error PsJsonParseError.invalidNumber
      | first :: more =>
          if first == '0' && !more.isEmpty then
            Except.error PsJsonParseError.invalidNumber
          else
            let body := String.ofList (first :: more)
            let text := if negative then "-" ++ body else body
            Except.ok {
              value := PsJsonValue.number text
              rest := taken.2
            }
  match chars with
  | '-' :: rest => parseUnsigned true rest
  | _ => parseUnsigned false chars

def psJsonConsumeLiteral
    (expected : List Char)
    (chars : List Char) :
    Option (List Char) :=
  match expected, chars with
  | [], rest => some rest
  | expectedChar :: expectedRest, char :: rest =>
      if expectedChar == char then
        psJsonConsumeLiteral expectedRest rest
      else
        none
  | _, _ => none

def psJsonParseValueWithFuel :
    Nat -> List Char -> Except PsJsonParseError PsJsonParseResult
  | 0, _ => Except.error PsJsonParseError.fuelExhausted
  | fuel + 1, input =>
      let chars := psJsonSkipWhitespace input
      match chars with
      | [] => Except.error PsJsonParseError.unexpectedEnd
      | '"' :: rest =>
          match psJsonParseStringChars fuel rest [] with
          | Except.error error => Except.error error
          | Except.ok (value, afterString) =>
              Except.ok {
                value := PsJsonValue.string value
                rest := afterString
              }
      | '[' :: rest =>
          psJsonParseArrayWithFuel fuel rest []
      | '{' :: rest =>
          psJsonParseObjectWithFuel fuel rest []
      | 't' :: _ =>
          match psJsonConsumeLiteral ['t','r','u','e'] chars with
          | none => Except.error PsJsonParseError.invalidLiteral
          | some rest =>
              Except.ok {
                value := PsJsonValue.bool true
                rest := rest
              }
      | 'f' :: _ =>
          match
              psJsonConsumeLiteral
                ['f','a','l','s','e']
                chars with
          | none => Except.error PsJsonParseError.invalidLiteral
          | some rest =>
              Except.ok {
                value := PsJsonValue.bool false
                rest := rest
              }
      | 'n' :: _ =>
          match psJsonConsumeLiteral ['n','u','l','l'] chars with
          | none => Except.error PsJsonParseError.invalidLiteral
          | some rest =>
              Except.ok {
                value := PsJsonValue.nullE
                rest := rest
              }
      | '-' :: _ => psJsonParseNumber chars
      | char :: _ =>
          if psJsonDigit char then
            psJsonParseNumber chars
          else
            Except.error
              (PsJsonParseError.expected "JSON value")

def psJsonParseArrayWithFuel
    (fuel : Nat)
    (input : List Char)
    (valuesRev : List PsJsonValue) :
    Except PsJsonParseError PsJsonParseResult :=
  match fuel with
  | 0 => Except.error PsJsonParseError.fuelExhausted
  | remaining + 1 =>
      let chars := psJsonSkipWhitespace input
      match chars with
      | ']' :: rest =>
          Except.ok {
            value := PsJsonValue.array valuesRev.reverse
            rest := rest
          }
      | _ =>
          match psJsonParseValueWithFuel remaining chars with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              let afterValue := psJsonSkipWhitespace parsed.rest
              match afterValue with
              | ',' :: rest =>
                  psJsonParseArrayWithFuel
                    remaining
                    rest
                    (parsed.value :: valuesRev)
              | ']' :: rest =>
                  Except.ok {
                    value :=
                      PsJsonValue.array
                        (parsed.value :: valuesRev).reverse
                    rest := rest
                  }
              | _ =>
                  Except.error
                    (PsJsonParseError.expected ", or ]")

def psJsonParseObjectWithFuel
    (fuel : Nat)
    (input : List Char)
    (fieldsRev : List (String × PsJsonValue)) :
    Except PsJsonParseError PsJsonParseResult :=
  match fuel with
  | 0 => Except.error PsJsonParseError.fuelExhausted
  | remaining + 1 =>
      let chars := psJsonSkipWhitespace input
      match chars with
      | '}' :: rest =>
          Except.ok {
            value := PsJsonValue.object fieldsRev.reverse
            rest := rest
          }
      | '"' :: rest =>
          match psJsonParseStringChars remaining rest [] with
          | Except.error error => Except.error error
          | Except.ok (key, afterKey) =>
              match psJsonSkipWhitespace afterKey with
              | ':' :: afterColon =>
                  match
                      psJsonParseValueWithFuel
                        remaining
                        afterColon with
                  | Except.error error => Except.error error
                  | Except.ok parsed =>
                      let afterValue :=
                        psJsonSkipWhitespace parsed.rest
                      match afterValue with
                      | ',' :: tail =>
                          psJsonParseObjectWithFuel
                            remaining
                            tail
                            ((key, parsed.value) :: fieldsRev)
                      | '}' :: tail =>
                          Except.ok {
                            value :=
                              PsJsonValue.object
                                ((key, parsed.value) ::
                                  fieldsRev).reverse
                            rest := tail
                          }
                      | _ =>
                          Except.error
                            (PsJsonParseError.expected ", or }")
              | _ =>
                  Except.error (PsJsonParseError.expected ":")
      | _ =>
          Except.error (PsJsonParseError.expected "object key")

def psJsonParse
    (source : String) :
    Except PsJsonParseError PsJsonValue :=
  let chars := source.toList
  match
      psJsonParseValueWithFuel
        (chars.length * 4 + 32)
        chars with
  | Except.error error => Except.error error
  | Except.ok parsed =>
      if (psJsonSkipWhitespace parsed.rest).isEmpty then
        Except.ok parsed.value
      else
        Except.error PsJsonParseError.trailingInput

def psJsonObjectFind :
    List (String × PsJsonValue) ->
    String ->
    Option PsJsonValue
  | [], _ => none
  | field :: rest, key =>
      if field.1 == key then
        some field.2
      else
        psJsonObjectFind rest key

def psJsonGetField
    (value : PsJsonValue)
    (key : String) : Option PsJsonValue :=
  match value with
  | .object fields => psJsonObjectFind fields key
  | _ => none

def psJsonAsString : PsJsonValue -> Option String
  | .string value => some value
  | _ => none

def psJsonAsBool : PsJsonValue -> Option Bool
  | .bool value => some value
  | _ => none

def psJsonAsNumberText : PsJsonValue -> Option String
  | .number text => some text
  | _ => none

def psJsonAsArray : PsJsonValue -> Option (List PsJsonValue)
  | .array values => some values
  | _ => none

def psJsonAsObject :
    PsJsonValue -> Option (List (String × PsJsonValue))
  | .object fields => some fields
  | _ => none
