import ProofScript.Data.Option
import ProofScript.Data.Ordering
import ProofScript.Data.Prod
import ProofScript.Data.Result

inductive JsonError where
  | unexpectedEnd
  | expected (text : String)
  | invalidEscape
  | invalidUnicode
  | invalidNumber
  | duplicateKey (key : String)
  | invalidShape
  | trailingInput
  | fuelExhausted

inductive JsonValue where
  | nullE
  | bool (value : Bool)
  | number (text : String)
  | string (value : String)
  | arrayNil
  | arrayCons (head : JsonValue) (tail : JsonValue)
  | objectNil
  | objectField
      (key : String)
      (value : JsonValue)
      (tail : JsonValue)

structure JsonParseResult where
  value : JsonValue
  position : Nat

def jsonCharCodeEq (char : Char) (code : Nat) : Bool :=
  Nat.beq (Char.toNat char) code

def jsonCharIsDigit (char : Char) : Bool :=
  let code : Nat := Char.toNat char;
  if Nat.blt code 48 then
    false
  else
    Nat.blt code 58

def jsonCharIsWhitespace (char : Char) : Bool :=
  if jsonCharCodeEq char 32 then
    true
  else if jsonCharCodeEq char 10 then
    true
  else if jsonCharCodeEq char 13 then
    true
  else
    jsonCharCodeEq char 9

def jsonAppend (left : String) (right : String) : String :=
  String.Internal.append left right

partial def orderingStringFrom
    (left : String)
    (right : String)
    (leftPos : Nat)
    (rightPos : Nat) : Ordering :=
  if String.Internal.atEnd left leftPos then
    if String.Internal.atEnd right rightPos then
      Ordering.eq
    else
      Ordering.lt
  else if String.Internal.atEnd right rightPos then
    Ordering.gt
  else
    let leftChar : Char := String.Internal.get left leftPos;
    let rightChar : Char := String.Internal.get right rightPos;
    let leftCode : Nat := Char.toNat leftChar;
    let rightCode : Nat := Char.toNat rightChar;
    if Nat.blt leftCode rightCode then
      Ordering.lt
    else if Nat.blt rightCode leftCode then
      Ordering.gt
    else
      orderingStringFrom
        left
        right
        (String.Internal.next left leftPos)
        (String.Internal.next right rightPos)

def orderingString (left : String) (right : String) : Ordering :=
  orderingStringFrom left right 0 0

partial def jsonSkipWhitespace
    (source : String)
    (position : Nat) : Nat :=
  if String.Internal.atEnd source position then
    position
  else
    let char : Char := String.Internal.get source position;
    if jsonCharIsWhitespace char then
      jsonSkipWhitespace
        source
        (String.Internal.next source position)
    else
      position

def jsonHexDigitValue (char : Char) : Option Nat :=
  let code : Nat := Char.toNat char;
  if Nat.blt code 48 then
    Option.none
  else if Nat.blt code 58 then
    Option.some (Nat.sub code 48)
  else if Nat.blt code 65 then
    Option.none
  else if Nat.blt code 71 then
    Option.some (Nat.sub code 55)
  else if Nat.blt code 97 then
    Option.none
  else if Nat.blt code 103 then
    Option.some (Nat.sub code 87)
  else
    Option.none

def jsonReadHexDigit
    (source : String)
    (position : Nat) : Result (Prod Nat Nat) JsonError :=
  if String.Internal.atEnd source position then
    Result.error JsonError.unexpectedEnd
  else
    let char : Char := String.Internal.get source position;
    match jsonHexDigitValue char with
    | Option.none => Result.error JsonError.invalidUnicode
    | Option.some value =>
        Result.ok
          (Prod.mk
            value
            (String.Internal.next source position))

def jsonUnicodeScalarValid (value : Nat) : Bool :=
  if Nat.blt value 55296 then
    true
  else if Nat.blt value 57344 then
    false
  else
    Nat.blt value 1114112

def jsonReadUnicode4
    (source : String)
    (position : Nat) : Result (Prod Char Nat) JsonError :=
  match jsonReadHexDigit source position with
  | Result.error error => Result.error error
  | Result.ok a =>
      match jsonReadHexDigit source a.snd with
      | Result.error error => Result.error error
      | Result.ok b =>
          match jsonReadHexDigit source b.snd with
          | Result.error error => Result.error error
          | Result.ok c =>
              match jsonReadHexDigit source c.snd with
              | Result.error error => Result.error error
              | Result.ok d =>
                  let value : Nat :=
                    Nat.add
                      (Nat.mul a.fst 4096)
                      (Nat.add
                        (Nat.mul b.fst 256)
                        (Nat.add
                          (Nat.mul c.fst 16)
                          d.fst));
                  if jsonUnicodeScalarValid value then
                    Result.ok (Prod.mk (Char.ofNat value) d.snd)
                  else
                    Result.error JsonError.invalidUnicode

partial def jsonParseStringBody
    (source : String)
    (position : Nat)
    (acc : String) : Result (Prod String Nat) JsonError :=
  if String.Internal.atEnd source position then
    Result.error JsonError.unexpectedEnd
  else
    let char : Char := String.Internal.get source position;
    let next : Nat := String.Internal.next source position;
    if jsonCharCodeEq char 34 then
      Result.ok (Prod.mk acc next)
    else if jsonCharCodeEq char 92 then
      if String.Internal.atEnd source next then
        Result.error JsonError.unexpectedEnd
      else
        let escaped : Char := String.Internal.get source next;
        let afterEscape : Nat := String.Internal.next source next;
        if jsonCharCodeEq escaped 34 then
          jsonParseStringBody
            source
            afterEscape
            (String.push acc (Char.ofNat 34))
        else if jsonCharCodeEq escaped 92 then
          jsonParseStringBody
            source
            afterEscape
            (String.push acc (Char.ofNat 92))
        else if jsonCharCodeEq escaped 47 then
          jsonParseStringBody
            source
            afterEscape
            (String.push acc (Char.ofNat 47))
        else if jsonCharCodeEq escaped 98 then
          jsonParseStringBody
            source
            afterEscape
            (String.push acc (Char.ofNat 8))
        else if jsonCharCodeEq escaped 102 then
          jsonParseStringBody
            source
            afterEscape
            (String.push acc (Char.ofNat 12))
        else if jsonCharCodeEq escaped 110 then
          jsonParseStringBody
            source
            afterEscape
            (String.push acc (Char.ofNat 10))
        else if jsonCharCodeEq escaped 114 then
          jsonParseStringBody
            source
            afterEscape
            (String.push acc (Char.ofNat 13))
        else if jsonCharCodeEq escaped 116 then
          jsonParseStringBody
            source
            afterEscape
            (String.push acc (Char.ofNat 9))
        else if jsonCharCodeEq escaped 117 then
          match jsonReadUnicode4 source afterEscape with
          | Result.error error => Result.error error
          | Result.ok decoded =>
              jsonParseStringBody
                source
                decoded.snd
                (String.push acc decoded.fst)
        else
          Result.error JsonError.invalidEscape
    else if Nat.blt (Char.toNat char) 32 then
      Result.error JsonError.invalidEscape
    else
      jsonParseStringBody source next (String.push acc char)

partial def jsonMatchTextFrom
    (source : String)
    (position : Nat)
    (expected : String)
    (expectedPos : Nat) : Option Nat :=
  if String.Internal.atEnd expected expectedPos then
    Option.some position
  else if String.Internal.atEnd source position then
    Option.none
  else
    let actualChar : Char := String.Internal.get source position;
    let expectedChar : Char := String.Internal.get expected expectedPos;
    if Nat.beq (Char.toNat actualChar) (Char.toNat expectedChar) then
      jsonMatchTextFrom
        source
        (String.Internal.next source position)
        expected
        (String.Internal.next expected expectedPos)
    else
      Option.none

def jsonMatchText
    (source : String)
    (position : Nat)
    (expected : String) : Option Nat :=
  jsonMatchTextFrom source position expected 0

partial def jsonReadDigits
    (source : String)
    (position : Nat)
    (acc : String) : Prod String Nat :=
  if String.Internal.atEnd source position then
    Prod.mk acc position
  else
    let char : Char := String.Internal.get source position;
    if jsonCharIsDigit char then
      jsonReadDigits
        source
        (String.Internal.next source position)
        (String.push acc char)
    else
      Prod.mk acc position

def jsonParseUnsignedNumber
    (source : String)
    (position : Nat)
    (prefix : String) : Result JsonParseResult JsonError :=
  if String.Internal.atEnd source position then
    Result.error JsonError.invalidNumber
  else
    let first : Char := String.Internal.get source position;
    if jsonCharIsDigit first then
      let afterFirst : Nat := String.Internal.next source position;
      let firstText : String := String.push prefix first;
      if jsonCharCodeEq first 48 then
        if String.Internal.atEnd source afterFirst then
          Result.ok
            (JsonParseResult.mk
              (JsonValue.number firstText)
              afterFirst)
        else
          let nextChar : Char := String.Internal.get source afterFirst;
          if jsonCharIsDigit nextChar then
            Result.error JsonError.invalidNumber
          else
            Result.ok
              (JsonParseResult.mk
                (JsonValue.number firstText)
                afterFirst)
      else
        let digits : Prod String Nat :=
          jsonReadDigits source afterFirst firstText;
        Result.ok
          (JsonParseResult.mk
            (JsonValue.number digits.fst)
            digits.snd)
    else
      Result.error JsonError.invalidNumber

def jsonParseNumberAt
    (source : String)
    (position : Nat) : Result JsonParseResult JsonError :=
  if String.Internal.atEnd source position then
    Result.error JsonError.invalidNumber
  else
    let char : Char := String.Internal.get source position;
    if jsonCharCodeEq char 45 then
      jsonParseUnsignedNumber
        source
        (String.Internal.next source position)
        "-"
    else
      jsonParseUnsignedNumber source position ""

def jsonArrayAppend
    (array : JsonValue)
    (value : JsonValue) : Result JsonValue JsonError :=
  match array with
  | JsonValue.arrayNil =>
      Result.ok
        (JsonValue.arrayCons value JsonValue.arrayNil)
  | JsonValue.arrayCons head tail =>
      match jsonArrayAppend tail value with
      | Result.error error => Result.error error
      | Result.ok nextTail =>
          Result.ok (JsonValue.arrayCons head nextTail)
  | _ => Result.error JsonError.invalidShape

def jsonObjectInsert
    (key : String)
    (value : JsonValue)
    (fields : JsonValue) : Result JsonValue JsonError :=
  match fields with
  | JsonValue.objectNil =>
      Result.ok
        (JsonValue.objectField
          key
          value
          JsonValue.objectNil)
  | JsonValue.objectField current currentValue tail =>
      match orderingString key current with
      | Ordering.lt =>
          Result.ok
            (JsonValue.objectField
              key
              value
              fields)
      | Ordering.eq =>
          Result.error (JsonError.duplicateKey key)
      | Ordering.gt =>
          match jsonObjectInsert key value tail with
          | Result.error error => Result.error error
          | Result.ok nextTail =>
              Result.ok
                (JsonValue.objectField
                  current
                  currentValue
                  nextTail)
  | _ => Result.error JsonError.invalidShape

def jsonObjectFind
    (value : JsonValue)
    (key : String) : Option JsonValue :=
  match value with
  | JsonValue.objectNil => Option.none
  | JsonValue.objectField current currentValue tail =>
      match orderingString key current with
      | Ordering.lt => Option.none
      | Ordering.eq => Option.some currentValue
      | Ordering.gt => jsonObjectFind tail key
  | _ => Option.none

partial def jsonParseArrayWith
    (parseValue :
      Nat -> String -> Nat -> Result JsonParseResult JsonError)
    (fuel : Nat)
    (source : String)
    (position : Nat)
    (values : JsonValue) :
    Result JsonParseResult JsonError :=
  if Nat.beq fuel 0 then
    Result.error JsonError.fuelExhausted
  else
    let remaining : Nat := Nat.sub fuel 1;
    let start : Nat := jsonSkipWhitespace source position;
    if String.Internal.atEnd source start then
      Result.error JsonError.unexpectedEnd
    else
      let char : Char := String.Internal.get source start;
      if jsonCharCodeEq char 93 then
        Result.ok
          (JsonParseResult.mk
            values
            (String.Internal.next source start))
      else
        match parseValue remaining source start with
        | Result.error error => Result.error error
        | Result.ok parsed =>
            match jsonArrayAppend values parsed.value with
            | Result.error error => Result.error error
            | Result.ok nextValues =>
                let afterValue : Nat :=
                  jsonSkipWhitespace source parsed.position;
                if String.Internal.atEnd source afterValue then
                  Result.error JsonError.unexpectedEnd
                else
                  let separator : Char :=
                    String.Internal.get source afterValue;
                  let next : Nat :=
                    String.Internal.next source afterValue;
                  if jsonCharCodeEq separator 44 then
                    jsonParseArrayWith
                      parseValue
                      remaining
                      source
                      next
                      nextValues
                  else if jsonCharCodeEq separator 93 then
                    Result.ok
                      (JsonParseResult.mk nextValues next)
                  else
                    Result.error (JsonError.expected ", or ]")

partial def jsonParseObjectWith
    (parseValue :
      Nat -> String -> Nat -> Result JsonParseResult JsonError)
    (fuel : Nat)
    (source : String)
    (position : Nat)
    (fields : JsonValue) :
    Result JsonParseResult JsonError :=
  if Nat.beq fuel 0 then
    Result.error JsonError.fuelExhausted
  else
    let remaining : Nat := Nat.sub fuel 1;
    let start : Nat := jsonSkipWhitespace source position;
    if String.Internal.atEnd source start then
      Result.error JsonError.unexpectedEnd
    else
      let char : Char := String.Internal.get source start;
      if jsonCharCodeEq char 125 then
        Result.ok
          (JsonParseResult.mk
            fields
            (String.Internal.next source start))
      else if jsonCharCodeEq char 34 then
        match
            jsonParseStringBody
              source
              (String.Internal.next source start)
              "" with
        | Result.error error => Result.error error
        | Result.ok parsedKey =>
            let colonPos : Nat :=
              jsonSkipWhitespace source parsedKey.snd;
            if String.Internal.atEnd source colonPos then
              Result.error JsonError.unexpectedEnd
            else
              let colon : Char :=
                String.Internal.get source colonPos;
              if jsonCharCodeEq colon 58 then
                match
                    parseValue
                      remaining
                      source
                      (String.Internal.next source colonPos) with
                | Result.error error => Result.error error
                | Result.ok parsed =>
                    match
                        jsonObjectInsert
                          parsedKey.fst
                          parsed.value
                          fields with
                    | Result.error error => Result.error error
                    | Result.ok nextFields =>
                        let afterValue : Nat :=
                          jsonSkipWhitespace source parsed.position;
                        if String.Internal.atEnd source afterValue then
                          Result.error JsonError.unexpectedEnd
                        else
                          let separator : Char :=
                            String.Internal.get source afterValue;
                          let next : Nat :=
                            String.Internal.next source afterValue;
                          if jsonCharCodeEq separator 44 then
                            jsonParseObjectWith
                              parseValue
                              remaining
                              source
                              next
                              nextFields
                          else if jsonCharCodeEq separator 125 then
                            Result.ok
                              (JsonParseResult.mk
                                nextFields
                                next)
                          else
                            Result.error
                              (JsonError.expected ", or }")
              else
                Result.error (JsonError.expected ":")
      else
        Result.error (JsonError.expected "object key")

partial def jsonParseValueWithFuel
    (fallback : Result JsonParseResult JsonError)
    (fuel : Nat)
    (source : String)
    (position : Nat) : Result JsonParseResult JsonError :=
  if Nat.beq fuel 0 then
    Result.error JsonError.fuelExhausted
  else
    let remaining : Nat := Nat.sub fuel 1;
    let start : Nat := jsonSkipWhitespace source position;
    if String.Internal.atEnd source start then
      Result.error JsonError.unexpectedEnd
    else
      let char : Char := String.Internal.get source start;
      let next : Nat := String.Internal.next source start;
      if jsonCharCodeEq char 34 then
        match jsonParseStringBody source next "" with
        | Result.error error => Result.error error
        | Result.ok parsed =>
            Result.ok
              (JsonParseResult.mk
                (JsonValue.string parsed.fst)
                parsed.snd)
      else if jsonCharCodeEq char 91 then
        jsonParseArrayWith
          (jsonParseValueWithFuel fallback)
          remaining
          source
          next
          JsonValue.arrayNil
      else if jsonCharCodeEq char 123 then
        jsonParseObjectWith
          (jsonParseValueWithFuel fallback)
          remaining
          source
          next
          JsonValue.objectNil
      else if jsonCharCodeEq char 116 then
        match jsonMatchText source start "true" with
        | Option.none => Result.error (JsonError.expected "true")
        | Option.some after =>
            Result.ok
              (JsonParseResult.mk
                (JsonValue.bool true)
                after)
      else if jsonCharCodeEq char 102 then
        match jsonMatchText source start "false" with
        | Option.none => Result.error (JsonError.expected "false")
        | Option.some after =>
            Result.ok
              (JsonParseResult.mk
                (JsonValue.bool false)
                after)
      else if jsonCharCodeEq char 110 then
        match jsonMatchText source start "null" with
        | Option.none => Result.error (JsonError.expected "null")
        | Option.some after =>
            Result.ok
              (JsonParseResult.mk JsonValue.nullE after)
      else if jsonCharCodeEq char 45 then
        jsonParseNumberAt source start
      else if jsonCharIsDigit char then
        jsonParseNumberAt source start
      else
        fallback

def jsonParse (source : String) : Result JsonValue JsonError :=
  match
      jsonParseValueWithFuel
        (Result.error (JsonError.expected "JSON value"))
        (Nat.add (String.Internal.length source) 32)
        source
        0 with
  | Result.error error => Result.error error
  | Result.ok parsed =>
      let rest : Nat :=
        jsonSkipWhitespace source parsed.position;
      if String.Internal.atEnd source rest then
        Result.ok parsed.value
      else
        Result.error JsonError.trailingInput

def jsonHexDigit (value : Nat) : String :=
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

def jsonEscapeControl (value : Nat) : String :=
  jsonAppend
    "\\u00"
    (jsonAppend
      (jsonHexDigit (Nat.div value 16))
      (jsonHexDigit (Nat.mod value 16)))

def jsonEscapeChar (char : Char) : String :=
  let code : Nat := Char.toNat char;
  if Nat.beq code 8 then "\\b"
  else if Nat.beq code 9 then "\\t"
  else if Nat.beq code 10 then "\\n"
  else if Nat.beq code 12 then "\\f"
  else if Nat.beq code 13 then "\\r"
  else if Nat.beq code 34 then "\\\""
  else if Nat.beq code 92 then "\\\\"
  else if Nat.blt code 32 then jsonEscapeControl code
  else String.singleton char

partial def jsonEscapeStringFrom
    (value : String)
    (position : Nat)
    (acc : String) : String :=
  if String.Internal.atEnd value position then
    acc
  else
    let char : Char := String.Internal.get value position;
    jsonEscapeStringFrom
      value
      (String.Internal.next value position)
      (jsonAppend acc (jsonEscapeChar char))

def jsonQuote (value : String) : String :=
  jsonAppend
    "\""
    (jsonAppend
      (jsonEscapeStringFrom value 0 "")
      "\"")

def jsonEncodeArrayBodyWith
    (encode : JsonValue -> Result String JsonError)
    (values : JsonValue) : Result String JsonError :=
  match values with
  | JsonValue.arrayNil => Result.ok ""
  | JsonValue.arrayCons head tail =>
      match encode head with
      | Result.error error => Result.error error
      | Result.ok encodedHead =>
          match tail with
          | JsonValue.arrayNil => Result.ok encodedHead
          | JsonValue.arrayCons next rest =>
              match
                  jsonEncodeArrayBodyWith
                    encode
                    (JsonValue.arrayCons next rest) with
              | Result.error error => Result.error error
              | Result.ok encodedTail =>
                  Result.ok
                    (jsonAppend
                      encodedHead
                      (jsonAppend "," encodedTail))
          | _ => Result.error JsonError.invalidShape
  | _ => Result.error JsonError.invalidShape

def jsonNormalizeObject
    (source : JsonValue) : Result JsonValue JsonError :=
  match source with
  | JsonValue.objectNil => Result.ok JsonValue.objectNil
  | JsonValue.objectField key value tail =>
      match jsonNormalizeObject tail with
      | Result.error error => Result.error error
      | Result.ok normalized =>
          jsonObjectInsert key value normalized
  | _ => Result.error JsonError.invalidShape

def jsonEncodeObjectBodyWith
    (encode : JsonValue -> Result String JsonError)
    (fields : JsonValue) : Result String JsonError :=
  match fields with
  | JsonValue.objectNil => Result.ok ""
  | JsonValue.objectField key value tail =>
      match encode value with
      | Result.error error => Result.error error
      | Result.ok encoded =>
          match tail with
          | JsonValue.objectNil =>
              Result.ok
                (jsonAppend
                  (jsonQuote key)
                  (jsonAppend ":" encoded))
          | JsonValue.objectField nextKey nextValue rest =>
              match
                  jsonEncodeObjectBodyWith
                    encode
                    (JsonValue.objectField
                      nextKey
                      nextValue
                      rest) with
              | Result.error error => Result.error error
              | Result.ok encodedTail =>
                  Result.ok
                    (jsonAppend
                      (jsonQuote key)
                      (jsonAppend
                        ":"
                        (jsonAppend
                          encoded
                          (jsonAppend "," encodedTail))))
          | _ => Result.error JsonError.invalidShape
  | _ => Result.error JsonError.invalidShape

def jsonNumberTextValid (text : String) : Bool :=
  match jsonParseNumberAt text 0 with
  | Result.error error => false
  | Result.ok parsed =>
      String.Internal.atEnd text parsed.position

partial def jsonEncodeCanonical
    (value : JsonValue) : Result String JsonError :=
  match value with
  | JsonValue.nullE => Result.ok "null"
  | JsonValue.bool flag =>
      if flag then
        Result.ok "true"
      else
        Result.ok "false"
  | JsonValue.number text =>
      if jsonNumberTextValid text then
        Result.ok text
      else
        Result.error JsonError.invalidNumber
  | JsonValue.string text =>
      Result.ok (jsonQuote text)
  | JsonValue.arrayNil =>
      Result.ok "[]"
  | JsonValue.arrayCons head tail =>
      match
          jsonEncodeArrayBodyWith
            jsonEncodeCanonical
            (JsonValue.arrayCons head tail) with
      | Result.error error => Result.error error
      | Result.ok body =>
          Result.ok
            (jsonAppend
              "["
              (jsonAppend body "]"))
  | JsonValue.objectNil =>
      Result.ok "{}"
  | JsonValue.objectField key fieldValue tail =>
      match
          jsonNormalizeObject
            (JsonValue.objectField
              key
              fieldValue
              tail) with
      | Result.error error => Result.error error
      | Result.ok normalized =>
          match
              jsonEncodeObjectBodyWith
                jsonEncodeCanonical
                normalized with
          | Result.error error => Result.error error
          | Result.ok body =>
              Result.ok
                (jsonAppend
                  "{"
                  (jsonAppend body "}"))

def jsonObjectFromTwo
    (firstKey : String)
    (firstValue : JsonValue)
    (secondKey : String)
    (secondValue : JsonValue) :
    Result JsonValue JsonError :=
  match
      jsonObjectInsert
        firstKey
        firstValue
        JsonValue.objectNil with
  | Result.error error => Result.error error
  | Result.ok first =>
      jsonObjectInsert
        secondKey
        secondValue
        first
