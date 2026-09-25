def psJsonConcat2
    (left right : String) : String :=
  String.Internal.append left right

def psJsonConcat3
    (first second third : String) : String :=
  psJsonConcat2 first (psJsonConcat2 second third)

def psJsonHexDigit (value : Nat) : String :=
  if Nat.beq value 0 then "0"
  else if Nat.beq value 1 then "1"
  else if Nat.beq value 2 then "2"
  else if Nat.beq value 3 then "3"
  else if Nat.beq value 4 then "4"
  else if Nat.beq value 5 then "5"
  else if Nat.beq value 6 then "6"
  else if Nat.beq value 7 then "7"
  else if Nat.beq value 8 then "8"
  else if Nat.beq value 9 then "9"
  else if Nat.beq value 10 then "a"
  else if Nat.beq value 11 then "b"
  else if Nat.beq value 12 then "c"
  else if Nat.beq value 13 then "d"
  else if Nat.beq value 14 then "e"
  else "f"

def psJsonEscapeControl (value : Nat) : String :=
  psJsonConcat3
    "\\u00"
    (psJsonHexDigit (Nat.div value 16))
    (psJsonHexDigit (Nat.mod value 16))

def psJsonEscapeChar (char : Char) : String :=
  let value : Nat := char.val.toNat;
  if Nat.beq value 8 then
    "\\b"
  else if Nat.beq value 9 then
    "\\t"
  else if Nat.beq value 10 then
    "\\n"
  else if Nat.beq value 12 then
    "\\f"
  else if Nat.beq value 13 then
    "\\r"
  else if Nat.beq value 34 then
    "\\\""
  else if Nat.beq value 92 then
    "\\\\"
  else if Nat.blt value 32 then
    psJsonEscapeControl value
  else
    String.ofList [char]

def psJsonEscapeChars : List Char -> String
  | [] => ""
  | char :: rest =>
      psJsonConcat2 (psJsonEscapeChar char) (psJsonEscapeChars rest)

def psJsonQuote (value : String) : String :=
  psJsonConcat3 "\"" (psJsonEscapeChars value.toList) "\""

def psJsonJoin (separator : String) : List String -> String
  | [] => ""
  | [value] => value
  | value :: rest =>
      psJsonConcat3 value separator (psJsonJoin separator rest)

def psJsonArray (values : List String) : String :=
  psJsonConcat3 "[" (psJsonJoin "," values) "]"

def psJsonField (key value : String) : String :=
  psJsonConcat3 (psJsonQuote key) ":" value

def psJsonObject (sortedFields : List (String × String)) : String :=
  let fields :=
    sortedFields.map
      (fun field => psJsonField field.1 field.2)
  psJsonConcat3 "{" (psJsonJoin "," fields) "}"



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
              psJsonParseStringChars fuel tail (Char.ofNat 8 :: charsRev)
            else if escaped == 'f' then
              psJsonParseStringChars fuel tail (Char.ofNat 12 :: charsRev)
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
            let text := if negative then psJsonConcat2 "-" body else body
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

def psJsonParseArrayWith
    (parseValue :
      Nat -> List Char -> Except PsJsonParseError PsJsonParseResult) :
    Nat ->
    List Char ->
    List PsJsonValue ->
    Except PsJsonParseError PsJsonParseResult
  | 0, _, _ => Except.error PsJsonParseError.fuelExhausted
  | remaining + 1, input, valuesRev =>
      let chars := psJsonSkipWhitespace input
      match chars with
      | ']' :: rest =>
          Except.ok {
            value := PsJsonValue.array valuesRev.reverse
            rest := rest
          }
      | _ =>
          match parseValue remaining chars with
          | Except.error error => Except.error error
          | Except.ok parsed =>
              let afterValue := psJsonSkipWhitespace parsed.rest
              match afterValue with
              | ',' :: rest =>
                  psJsonParseArrayWith
                    parseValue
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

def psJsonParseObjectWith
    (parseValue :
      Nat -> List Char -> Except PsJsonParseError PsJsonParseResult) :
    Nat ->
    List Char ->
    List (String × PsJsonValue) ->
    Except PsJsonParseError PsJsonParseResult
  | 0, _, _ => Except.error PsJsonParseError.fuelExhausted
  | remaining + 1, input, fieldsRev =>
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
                  match parseValue remaining afterColon with
                  | Except.error error => Except.error error
                  | Except.ok parsed =>
                      let afterValue :=
                        psJsonSkipWhitespace parsed.rest
                      match afterValue with
                      | ',' :: tail =>
                          psJsonParseObjectWith
                            parseValue
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

partial def psJsonParseValueWithFuel
    (fallback : Except PsJsonParseError PsJsonParseResult)
    (fuel : Nat)
    (input : List Char) :
    Except PsJsonParseError PsJsonParseResult :=
  match fuel with
  | 0 => Except.error PsJsonParseError.fuelExhausted
  | remaining + 1 =>
      let chars := psJsonSkipWhitespace input
      match chars with
      | [] => Except.error PsJsonParseError.unexpectedEnd
      | '"' :: rest =>
          match psJsonParseStringChars remaining rest [] with
          | Except.error error => Except.error error
          | Except.ok (value, afterString) =>
              Except.ok {
                value := PsJsonValue.string value
                rest := afterString
              }
      | '[' :: rest =>
          psJsonParseArrayWith
            (psJsonParseValueWithFuel fallback)
            remaining
            rest
            []
      | '{' :: rest =>
          psJsonParseObjectWith
            (psJsonParseValueWithFuel fallback)
            remaining
            rest
            []
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

def psJsonParse
    (source : String) :
    Except PsJsonParseError PsJsonValue :=
  let chars := source.toList
  match
      psJsonParseValueWithFuel
        (Except.error PsJsonParseError.fuelExhausted)
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


inductive PsJsonEncodeError where
  | invalidNumber (text : String)
  | duplicateObjectKey (key : String)

inductive PsJsonKeyOrder where
  | lt
  | eq
  | gt

def psJsonCompareCharLists :
    List Char -> List Char -> PsJsonKeyOrder
  | [], [] => PsJsonKeyOrder.eq
  | [], _ :: _ => PsJsonKeyOrder.lt
  | _ :: _, [] => PsJsonKeyOrder.gt
  | left :: leftRest, right :: rightRest =>
      let leftValue := left.val.toNat
      let rightValue := right.val.toNat
      if leftValue < rightValue then
        PsJsonKeyOrder.lt
      else if rightValue < leftValue then
        PsJsonKeyOrder.gt
      else
        psJsonCompareCharLists leftRest rightRest

def psJsonCompareKeys
    (left right : String) : PsJsonKeyOrder :=
  psJsonCompareCharLists left.toList right.toList

def psJsonInsertObjectField
    (field : String × PsJsonValue) :
    List (String × PsJsonValue) ->
    Except PsJsonEncodeError (List (String × PsJsonValue))
  | [] => Except.ok [field]
  | current :: rest =>
      match psJsonCompareKeys field.1 current.1 with
      | PsJsonKeyOrder.lt =>
          Except.ok (field :: current :: rest)
      | PsJsonKeyOrder.eq =>
          Except.error
            (PsJsonEncodeError.duplicateObjectKey field.1)
      | PsJsonKeyOrder.gt =>
          match psJsonInsertObjectField field rest with
          | Except.error error => Except.error error
          | Except.ok sortedRest =>
              Except.ok (current :: sortedRest)

def psJsonSortObjectFields :
    List (String × PsJsonValue) ->
    Except PsJsonEncodeError (List (String × PsJsonValue))
  | [] => Except.ok []
  | field :: rest =>
      match psJsonSortObjectFields rest with
      | Except.error error => Except.error error
      | Except.ok sortedRest =>
          psJsonInsertObjectField field sortedRest

def psJsonValidateCanonicalNumber
    (text : String) : Bool :=
  match psJsonParseNumber text.toList with
  | Except.error _ => false
  | Except.ok parsed => parsed.rest.isEmpty

partial def psJsonEncodeCanonical
    (value : PsJsonValue) :
    Except PsJsonEncodeError String :=
  match value with
  | PsJsonValue.nullE => Except.ok "null"
  | PsJsonValue.bool true => Except.ok "true"
  | PsJsonValue.bool false => Except.ok "false"
  | PsJsonValue.number text =>
      if psJsonValidateCanonicalNumber text then
        Except.ok text
      else
        Except.error (PsJsonEncodeError.invalidNumber text)
  | PsJsonValue.string text =>
      Except.ok (psJsonQuote text)
  | PsJsonValue.array values =>
      match values.mapM psJsonEncodeCanonical with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok (psJsonArray encoded)
  | PsJsonValue.object fields =>
      match psJsonSortObjectFields fields with
      | Except.error error => Except.error error
      | Except.ok sorted =>
          let encodeField :=
            fun field =>
              match psJsonEncodeCanonical field.2 with
              | Except.error error => Except.error error
              | Except.ok encoded =>
                  Except.ok (field.1, encoded)
          match sorted.mapM encodeField with
          | Except.error error => Except.error error
          | Except.ok encodedFields =>
              Except.ok (psJsonObject encodedFields)

def psJsonEncodeCanonicalText
    (value : PsJsonValue) :
    Except PsJsonEncodeError String :=
  match psJsonEncodeCanonical value with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonConcat2 encoded "\n")
