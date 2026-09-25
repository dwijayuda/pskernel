def psJsonConcat2
    (left right : String) : String :=
  String.Internal.append left right

def psJsonConcat3
    (first second third : String) : String :=
  psJsonConcat2 first (psJsonConcat2 second third)

def psJsonCharCode (char : Char) : Nat :=
  Char.toNat char

def psJsonCharEq (left right : Char) : Bool :=
  Nat.beq (psJsonCharCode left) (psJsonCharCode right)

def psJsonStringAtEnd
    (value : String)
    (position : Nat) : Bool :=
  String.Internal.atEnd value (String.Pos.Raw.mk position)

def psJsonStringGet
    (value : String)
    (position : Nat) : Char :=
  String.Internal.get value (String.Pos.Raw.mk position)

def psJsonStringNext
    (value : String)
    (position : Nat) : Nat :=
  String.Pos.Raw.byteIdx
    (String.Internal.next value (String.Pos.Raw.mk position))

def psJsonStringCharsWithFuel
    (fuel : Nat) : String -> Nat -> List Char :=
  match fuel with
  | Nat.zero =>
      fun (_value : String) (_position : Nat) =>
        List.nil
  | Nat.succ remaining =>
      let smaller : String -> Nat -> List Char :=
        psJsonStringCharsWithFuel remaining;
      fun (value : String) (position : Nat) =>
        if psJsonStringAtEnd value position then
          List.nil
        else
          List.cons
            (psJsonStringGet value position)
            (smaller value (psJsonStringNext value position))

def psJsonStringToChars (value : String) : List Char :=
  psJsonStringCharsWithFuel
    (Nat.succ (String.utf8ByteSize value))
    value
    0

def psJsonStringOfCharsAcc
    (chars : List Char) : String -> String :=
  match chars with
  | List.nil =>
      fun (acc : String) => acc
  | List.cons head tail =>
      let smaller : String -> String :=
        psJsonStringOfCharsAcc tail;
      fun (acc : String) =>
        smaller (String.push acc head)

def psJsonStringOfChars (chars : List Char) : String :=
  psJsonStringOfCharsAcc chars ""

def psJsonCharListEq
    (left : List Char) : List Char -> Bool :=
  match left with
  | List.nil =>
      fun (right : List Char) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller : List Char -> Bool :=
        psJsonCharListEq leftTail;
      fun (right : List Char) =>
        match right with
        | List.nil => false
        | List.cons rightHead rightTail =>
            if psJsonCharEq leftHead rightHead then
              smaller rightTail
            else
              false

def psJsonStringEq (left right : String) : Bool :=
  psJsonCharListEq (psJsonStringToChars left) (psJsonStringToChars right)

def psJsonNatInRange
    (value lower upper : Nat) : Bool :=
  if Nat.ble lower value then
    Nat.ble value upper
  else
    false

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
  let value : Nat := Char.toNat char;
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
    psJsonStringOfChars (List.cons char List.nil)

def psJsonEscapeChars (chars : List Char) : String :=
  match chars with
  | List.nil =>
      ""
  | List.cons char rest =>
      psJsonConcat2 (psJsonEscapeChar char) (psJsonEscapeChars rest)

def psJsonQuote (value : String) : String :=
  psJsonConcat3 "\"" (psJsonEscapeChars (psJsonStringToChars value)) "\""

def psJsonJoin
    (separator : String)
    (values : List String) : String :=
  match values with
  | List.nil =>
      ""
  | List.cons value rest =>
      match rest with
      | List.nil =>
          value
      | List.cons _ _ =>
          psJsonConcat3 value separator (psJsonJoin separator rest)

def psJsonArray (values : List String) : String :=
  psJsonConcat3 "[" (psJsonJoin "," values) "]"

def psJsonField (key value : String) : String :=
  psJsonConcat3 (psJsonQuote key) ":" value

def psJsonMapObjectFields
    (fields : List (String × String)) : List String :=
  match fields with
  | List.nil =>
      List.nil
  | List.cons field rest =>
      List.cons
        (psJsonField (Prod.fst field) (Prod.snd field))
        (psJsonMapObjectFields rest)

def psJsonObject (sortedFields : List (String × String)) : String :=
  psJsonConcat3
    "{"
    (psJsonJoin "," (psJsonMapObjectFields sortedFields))
    "}"



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
  if psJsonCharEq char ' ' then
    true
  else if psJsonCharEq char '\n' then
    true
  else if psJsonCharEq char '\r' then
    true
  else
    psJsonCharEq char '\t'

def psJsonSkipWhitespace (chars : List Char) : List Char :=
  match chars with
  | List.nil =>
      List.nil
  | List.cons char rest =>
      if psJsonWhitespace char then
        psJsonSkipWhitespace rest
      else
        List.cons char rest

def psJsonHexValue (char : Char) : Option Nat :=
  let value : Nat := psJsonCharCode char;
  if psJsonNatInRange value 48 57 then
    Option.some (Nat.sub value 48)
  else if psJsonNatInRange value 65 70 then
    Option.some (Nat.sub value 55)
  else if psJsonNatInRange value 97 102 then
    Option.some (Nat.sub value 87)
  else
    Option.none

def psJsonDecodeUnicode4
    (chars : List Char) :
    Except PsJsonParseError (Char × List Char) :=
  match chars with
  | List.nil =>
      Except.error PsJsonParseError.unexpectedEnd
  | List.cons a rest1 =>
      match rest1 with
      | List.nil =>
          Except.error PsJsonParseError.unexpectedEnd
      | List.cons b rest2 =>
          match rest2 with
          | List.nil =>
              Except.error PsJsonParseError.unexpectedEnd
          | List.cons c rest3 =>
              match rest3 with
              | List.nil =>
                  Except.error PsJsonParseError.unexpectedEnd
              | List.cons d rest =>
                  match psJsonHexValue a with
                  | Option.none =>
                      Except.error PsJsonParseError.invalidUnicodeEscape
                  | Option.some av =>
                      match psJsonHexValue b with
                      | Option.none =>
                          Except.error PsJsonParseError.invalidUnicodeEscape
                      | Option.some bv =>
                          match psJsonHexValue c with
                          | Option.none =>
                              Except.error PsJsonParseError.invalidUnicodeEscape
                          | Option.some cv =>
                              match psJsonHexValue d with
                              | Option.none =>
                                  Except.error PsJsonParseError.invalidUnicodeEscape
                              | Option.some dv =>
                                  let value : Nat :=
                                    Nat.add
                                      (Nat.add
                                        (Nat.mul av 4096)
                                        (Nat.mul bv 256))
                                      (Nat.add
                                        (Nat.mul cv 16)
                                        dv);
                                  if
                                      psJsonNatInRange
                                        value
                                        55296
                                        57343 then
                                    Except.error
                                      PsJsonParseError.invalidUnicodeEscape
                                  else
                                    Except.ok
                                      (Prod.mk (Char.ofNat value) rest)

def psJsonReverseCharsAcc
    (values : List Char) : List Char -> List Char :=
  match values with
  | List.nil =>
      fun (acc : List Char) => acc
  | List.cons head tail =>
      let smaller : List Char -> List Char :=
        psJsonReverseCharsAcc tail;
      fun (acc : List Char) =>
        smaller (List.cons head acc)

def psJsonReverseChars (values : List Char) : List Char :=
  psJsonReverseCharsAcc values List.nil

def psJsonParseStringChars
    (fuel : Nat) :
    List Char ->
    List Char ->
    Except PsJsonParseError (String × List Char) :=
  match fuel with
  | Nat.zero =>
      fun (_chars : List Char) (_charsRev : List Char) =>
        Except.error PsJsonParseError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          List Char ->
          List Char ->
          Except PsJsonParseError (String × List Char) :=
        psJsonParseStringChars remaining;
      fun (chars : List Char) (charsRev : List Char) =>
        match chars with
        | List.nil =>
            Except.error PsJsonParseError.unexpectedEnd
        | List.cons char rest =>
            if psJsonCharEq char '"' then
              Except.ok
                (Prod.mk
                  (psJsonStringOfChars (psJsonReverseChars charsRev))
                  rest)
            else if psJsonCharEq char '\\' then
              match rest with
              | List.nil =>
                  Except.error PsJsonParseError.unexpectedEnd
              | List.cons escaped tail =>
                  if psJsonCharEq escaped '"' then
                    smaller tail (List.cons '"' charsRev)
                  else if psJsonCharEq escaped '\\' then
                    smaller tail (List.cons '\\' charsRev)
                  else if psJsonCharEq escaped '/' then
                    smaller tail (List.cons '/' charsRev)
                  else if psJsonCharEq escaped 'b' then
                    smaller tail (List.cons (Char.ofNat 8) charsRev)
                  else if psJsonCharEq escaped 'f' then
                    smaller tail (List.cons (Char.ofNat 12) charsRev)
                  else if psJsonCharEq escaped 'n' then
                    smaller tail (List.cons '\n' charsRev)
                  else if psJsonCharEq escaped 'r' then
                    smaller tail (List.cons '\r' charsRev)
                  else if psJsonCharEq escaped 't' then
                    smaller tail (List.cons '\t' charsRev)
                  else if psJsonCharEq escaped 'u' then
                    match psJsonDecodeUnicode4 tail with
                    | Except.error error =>
                        Except.error error
                    | Except.ok decodedResult =>
                        let decoded := Prod.fst decodedResult;
                        let afterUnicode := Prod.snd decodedResult;
                        smaller
                          afterUnicode
                          (List.cons decoded charsRev)
                  else
                    Except.error PsJsonParseError.invalidEscape
            else if Nat.blt (psJsonCharCode char) 32 then
              Except.error PsJsonParseError.invalidEscape
            else
              smaller rest (List.cons char charsRev)

def psJsonDigit (char : Char) : Bool :=
  let value : Nat := psJsonCharCode char;
  psJsonNatInRange value 48 57

def psJsonTakeDigits
    (chars : List Char) : List Char -> List Char × List Char :=
  match chars with
  | List.nil =>
      fun (digitsRev : List Char) =>
        Prod.mk (psJsonReverseChars digitsRev) List.nil
  | List.cons char rest =>
      let smaller : List Char -> List Char × List Char :=
        psJsonTakeDigits rest;
      fun (digitsRev : List Char) =>
        if psJsonDigit char then
          smaller (List.cons char digitsRev)
        else
          Prod.mk
            (psJsonReverseChars digitsRev)
            (List.cons char rest)

def psJsonParseNumber
    (chars : List Char) :
    Except PsJsonParseError PsJsonParseResult :=
  let parseUnsigned :
      Bool ->
        List Char ->
          Except PsJsonParseError PsJsonParseResult :=
    fun (negative : Bool) (rest : List Char) =>
      let taken := psJsonTakeDigits rest List.nil;
      let digits := Prod.fst taken;
      let afterDigits := Prod.snd taken;
      match digits with
      | List.nil =>
          Except.error PsJsonParseError.invalidNumber
      | List.cons first more =>
          let hasMore : Bool :=
            match more with
            | List.nil => false
            | List.cons _ _ => true;
          if psJsonCharEq first '0' then
            if hasMore then
              Except.error PsJsonParseError.invalidNumber
            else
              let body := psJsonStringOfChars (List.cons first more);
              let text :=
                if negative then psJsonConcat2 "-" body else body;
              Except.ok {
                value := PsJsonValue.number text
                rest := afterDigits
              }
          else
            let body := psJsonStringOfChars (List.cons first more);
            let text :=
              if negative then psJsonConcat2 "-" body else body;
            Except.ok {
              value := PsJsonValue.number text
              rest := afterDigits
            };
  match chars with
  | List.nil =>
      parseUnsigned false chars
  | List.cons first rest =>
      if psJsonCharEq first '-' then
        parseUnsigned true rest
      else
        parseUnsigned false chars

def psJsonConsumeLiteral
    (expected : List Char) : List Char -> Option (List Char) :=
  match expected with
  | List.nil =>
      fun (chars : List Char) =>
        Option.some chars
  | List.cons expectedChar expectedRest =>
      let smaller : List Char -> Option (List Char) :=
        psJsonConsumeLiteral expectedRest;
      fun (chars : List Char) =>
        match chars with
        | List.nil =>
            Option.none
        | List.cons char rest =>
            if psJsonCharEq expectedChar char then
              smaller rest
            else
              Option.none

def psJsonReverseValuesAcc
    (values : List PsJsonValue) :
    List PsJsonValue -> List PsJsonValue :=
  match values with
  | List.nil =>
      fun (acc : List PsJsonValue) => acc
  | List.cons head tail =>
      let smaller : List PsJsonValue -> List PsJsonValue :=
        psJsonReverseValuesAcc tail;
      fun (acc : List PsJsonValue) =>
        smaller (List.cons head acc)

def psJsonReverseValues
    (values : List PsJsonValue) : List PsJsonValue :=
  psJsonReverseValuesAcc values List.nil

def psJsonParseArrayWith
    (parseValue :
      Nat -> List Char -> Except PsJsonParseError PsJsonParseResult)
    (fuel : Nat) :
    List Char ->
    List PsJsonValue ->
    Except PsJsonParseError PsJsonParseResult :=
  match fuel with
  | Nat.zero =>
      fun (_input : List Char) (_valuesRev : List PsJsonValue) =>
        Except.error PsJsonParseError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          List Char ->
          List PsJsonValue ->
          Except PsJsonParseError PsJsonParseResult :=
        psJsonParseArrayWith parseValue remaining;
      fun (input : List Char) (valuesRev : List PsJsonValue) =>
        let chars := psJsonSkipWhitespace input;
        match chars with
        | List.nil =>
            match parseValue remaining chars with
            | Except.error error => Except.error error
            | Except.ok parsed =>
                let afterValue := psJsonSkipWhitespace parsed.rest;
                match afterValue with
                | List.nil =>
                    Except.error
                      (PsJsonParseError.expected ", or ]")
                | List.cons separator rest =>
                    if psJsonCharEq separator ',' then
                      smaller
                        rest
                        (List.cons parsed.value valuesRev)
                    else if psJsonCharEq separator ']' then
                      Except.ok {
                        value :=
                          PsJsonValue.array
                            (psJsonReverseValues
                              (List.cons parsed.value valuesRev))
                        rest := rest
                      }
                    else
                      Except.error
                        (PsJsonParseError.expected ", or ]")
        | List.cons first rest =>
            if psJsonCharEq first ']' then
              Except.ok {
                value := PsJsonValue.array (psJsonReverseValues valuesRev)
                rest := rest
              }
            else
              match parseValue remaining chars with
              | Except.error error => Except.error error
              | Except.ok parsed =>
                  let afterValue := psJsonSkipWhitespace parsed.rest;
                  match afterValue with
                  | List.nil =>
                      Except.error
                        (PsJsonParseError.expected ", or ]")
                  | List.cons separator afterSeparator =>
                      if psJsonCharEq separator ',' then
                        smaller
                          afterSeparator
                          (List.cons parsed.value valuesRev)
                      else if psJsonCharEq separator ']' then
                        Except.ok {
                          value :=
                            PsJsonValue.array
                              (psJsonReverseValues
                                (List.cons parsed.value valuesRev))
                          rest := afterSeparator
                        }
                      else
                        Except.error
                          (PsJsonParseError.expected ", or ]")

def psJsonReverseFieldsAcc
    (fields : List (String × PsJsonValue)) :
    List (String × PsJsonValue) ->
      List (String × PsJsonValue) :=
  match fields with
  | List.nil =>
      fun (acc : List (String × PsJsonValue)) => acc
  | List.cons head tail =>
      let smaller :
          List (String × PsJsonValue) ->
            List (String × PsJsonValue) :=
        psJsonReverseFieldsAcc tail;
      fun (acc : List (String × PsJsonValue)) =>
        smaller (List.cons head acc)

def psJsonReverseFields
    (fields : List (String × PsJsonValue)) :
    List (String × PsJsonValue) :=
  psJsonReverseFieldsAcc fields List.nil

def psJsonParseObjectWith
    (parseValue :
      Nat -> List Char -> Except PsJsonParseError PsJsonParseResult)
    (fuel : Nat) :
    List Char ->
    List (String × PsJsonValue) ->
    Except PsJsonParseError PsJsonParseResult :=
  match fuel with
  | Nat.zero =>
      fun
          (_input : List Char)
          (_fieldsRev : List (String × PsJsonValue)) =>
        Except.error PsJsonParseError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          List Char ->
          List (String × PsJsonValue) ->
          Except PsJsonParseError PsJsonParseResult :=
        psJsonParseObjectWith parseValue remaining;
      fun
          (input : List Char)
          (fieldsRev : List (String × PsJsonValue)) =>
        let chars := psJsonSkipWhitespace input;
        match chars with
        | List.nil =>
            Except.error (PsJsonParseError.expected "object key")
        | List.cons first rest =>
            if psJsonCharEq first '}' then
              Except.ok {
                value := PsJsonValue.object (psJsonReverseFields fieldsRev)
                rest := rest
              }
            else if psJsonCharEq first '"' then
              match psJsonParseStringChars remaining rest List.nil with
              | Except.error error => Except.error error
              | Except.ok keyResult =>
                  let key := Prod.fst keyResult;
                  let afterKey := Prod.snd keyResult;
                  match psJsonSkipWhitespace afterKey with
                  | List.nil =>
                      Except.error (PsJsonParseError.expected ":")
                  | List.cons colon afterColon =>
                      if psJsonCharEq colon ':' then
                        match parseValue remaining afterColon with
                        | Except.error error => Except.error error
                        | Except.ok parsed =>
                            let afterValue :=
                              psJsonSkipWhitespace parsed.rest;
                            match afterValue with
                            | List.nil =>
                                Except.error
                                  (PsJsonParseError.expected ", or }")
                            | List.cons separator tail =>
                                if psJsonCharEq separator ',' then
                                  smaller
                                    tail
                                    (List.cons
                                      (Prod.mk key parsed.value)
                                      fieldsRev)
                                else if psJsonCharEq separator '}' then
                                  Except.ok {
                                    value :=
                                      PsJsonValue.object
                                        (psJsonReverseFields
                                          (List.cons
                                            (Prod.mk key parsed.value)
                                            fieldsRev))
                                    rest := tail
                                  }
                                else
                                  Except.error
                                    (PsJsonParseError.expected ", or }")
                      else
                        Except.error (PsJsonParseError.expected ":")
            else
              Except.error (PsJsonParseError.expected "object key")

partial def psJsonParseValueWithFuel
    (fallback : Except PsJsonParseError PsJsonParseResult)
    (fuel : Nat)
    (input : List Char) :
    Except PsJsonParseError PsJsonParseResult :=
  match fuel with
  | Nat.zero =>
      Except.error PsJsonParseError.fuelExhausted
  | Nat.succ remaining =>
      let chars := psJsonSkipWhitespace input;
      match chars with
      | List.nil =>
          Except.error PsJsonParseError.unexpectedEnd
      | List.cons first rest =>
          if psJsonCharEq first '"' then
            match psJsonParseStringChars remaining rest List.nil with
            | Except.error error => Except.error error
            | Except.ok stringResult =>
                let value := Prod.fst stringResult;
                let afterString := Prod.snd stringResult;
                Except.ok {
                  value := PsJsonValue.string value
                  rest := afterString
                }
          else if psJsonCharEq first '[' then
            psJsonParseArrayWith
              (psJsonParseValueWithFuel fallback)
              remaining
              rest
              List.nil
          else if psJsonCharEq first '{' then
            psJsonParseObjectWith
              (psJsonParseValueWithFuel fallback)
              remaining
              rest
              List.nil
          else if psJsonCharEq first 't' then
            match psJsonConsumeLiteral ['t','r','u','e'] chars with
            | Option.none => Except.error PsJsonParseError.invalidLiteral
            | Option.some afterLiteral =>
                Except.ok {
                  value := PsJsonValue.bool true
                  rest := afterLiteral
                }
          else if psJsonCharEq first 'f' then
            match
                psJsonConsumeLiteral
                  ['f','a','l','s','e']
                  chars with
            | Option.none => Except.error PsJsonParseError.invalidLiteral
            | Option.some afterLiteral =>
                Except.ok {
                  value := PsJsonValue.bool false
                  rest := afterLiteral
                }
          else if psJsonCharEq first 'n' then
            match psJsonConsumeLiteral ['n','u','l','l'] chars with
            | Option.none => Except.error PsJsonParseError.invalidLiteral
            | Option.some afterLiteral =>
                Except.ok {
                  value := PsJsonValue.nullE
                  rest := afterLiteral
                }
          else if psJsonCharEq first '-' then
            psJsonParseNumber chars
          else if psJsonDigit first then
            psJsonParseNumber chars
          else
            Except.error
              (PsJsonParseError.expected "JSON value")

def psJsonCharListLength (chars : List Char) : Nat :=
  match chars with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ (psJsonCharListLength rest)

def psJsonParse
    (source : String) :
    Except PsJsonParseError PsJsonValue :=
  let chars := psJsonStringToChars source;
  match
      psJsonParseValueWithFuel
        (Except.error PsJsonParseError.fuelExhausted)
        (Nat.add (Nat.mul (psJsonCharListLength chars) 4) 32)
        chars with
  | Except.error error => Except.error error
  | Except.ok parsed =>
      match psJsonSkipWhitespace parsed.rest with
      | List.nil =>
          Except.ok parsed.value
      | List.cons _ _ =>
          Except.error PsJsonParseError.trailingInput

def psJsonObjectFind
    (fields : List (String × PsJsonValue)) :
    String -> Option PsJsonValue :=
  match fields with
  | List.nil =>
      fun (_key : String) => Option.none
  | List.cons field rest =>
      let smaller : String -> Option PsJsonValue :=
        psJsonObjectFind rest;
      fun (key : String) =>
        if psJsonStringEq (Prod.fst field) key then
          Option.some (Prod.snd field)
        else
          smaller key

def psJsonGetField
    (value : PsJsonValue)
    (key : String) : Option PsJsonValue :=
  match value with
  | .object fields => psJsonObjectFind fields key
  | _ => Option.none

def psJsonAsString : PsJsonValue -> Option String
  | .string value => Option.some value
  | _ => Option.none

def psJsonAsBool : PsJsonValue -> Option Bool
  | .bool value => Option.some value
  | _ => Option.none

def psJsonAsNumberText : PsJsonValue -> Option String
  | .number text => Option.some text
  | _ => Option.none

def psJsonAsArray : PsJsonValue -> Option (List PsJsonValue)
  | .array values => Option.some values
  | _ => Option.none

def psJsonAsObject :
    PsJsonValue -> Option (List (String × PsJsonValue))
  | .object fields => Option.some fields
  | _ => Option.none


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
      let leftValue : Nat := psJsonCharCode left;
      let rightValue : Nat := psJsonCharCode right;
      if Nat.blt leftValue rightValue then
        PsJsonKeyOrder.lt
      else if Nat.blt rightValue leftValue then
        PsJsonKeyOrder.gt
      else
        psJsonCompareCharLists leftRest rightRest

def psJsonCompareKeys
    (left right : String) : PsJsonKeyOrder :=
  psJsonCompareCharLists (psJsonStringToChars left) (psJsonStringToChars right)

def psJsonInsertObjectField
    (field : String × PsJsonValue) :
    List (String × PsJsonValue) ->
    Except PsJsonEncodeError (List (String × PsJsonValue))
  | [] => Except.ok [field]
  | current :: rest =>
      match
          psJsonCompareKeys
            (Prod.fst field)
            (Prod.fst current) with
      | PsJsonKeyOrder.lt =>
          Except.ok
            (List.cons field (List.cons current rest))
      | PsJsonKeyOrder.eq =>
          Except.error
            (PsJsonEncodeError.duplicateObjectKey
              (Prod.fst field))
      | PsJsonKeyOrder.gt =>
          match psJsonInsertObjectField field rest with
          | Except.error error => Except.error error
          | Except.ok sortedRest =>
              Except.ok (List.cons current sortedRest)

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
  match psJsonParseNumber (psJsonStringToChars text) with
  | Except.error _ => false
  | Except.ok parsed =>
      match parsed.rest with
      | List.nil => true
      | List.cons _ _ => false

def psJsonEncodeValueList
    (encodeValue :
      PsJsonValue -> Except PsJsonEncodeError String)
    (values : List PsJsonValue) :
    Except PsJsonEncodeError (List String) :=
  match values with
  | List.nil =>
      Except.ok List.nil
  | List.cons value rest =>
      match encodeValue value with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match psJsonEncodeValueList encodeValue rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok (List.cons encodedHead encodedTail)

def psJsonEncodeFieldList
    (encodeValue :
      PsJsonValue -> Except PsJsonEncodeError String)
    (fields : List (String × PsJsonValue)) :
    Except PsJsonEncodeError (List (String × String)) :=
  match fields with
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      match encodeValue (Prod.snd field) with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match psJsonEncodeFieldList encodeValue rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok
                (List.cons
                  (Prod.mk (Prod.fst field) encodedHead)
                  encodedTail)

partial def psJsonEncodeCanonical
    (value : PsJsonValue) :
    Except PsJsonEncodeError String :=
  match value with
  | PsJsonValue.nullE => Except.ok "null"
  | PsJsonValue.bool boolValue =>
      if boolValue then
        Except.ok "true"
      else
        Except.ok "false"
  | PsJsonValue.number text =>
      if psJsonValidateCanonicalNumber text then
        Except.ok text
      else
        Except.error (PsJsonEncodeError.invalidNumber text)
  | PsJsonValue.string text =>
      Except.ok (psJsonQuote text)
  | PsJsonValue.array values =>
      match
          psJsonEncodeValueList
            psJsonEncodeCanonical
            values with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok (psJsonArray encoded)
  | PsJsonValue.object fields =>
      match psJsonSortObjectFields fields with
      | Except.error error => Except.error error
      | Except.ok sorted =>
          match
              psJsonEncodeFieldList
                psJsonEncodeCanonical
                sorted with
          | Except.error error => Except.error error
          | Except.ok encodedFields =>
              Except.ok (psJsonObject encodedFields)

def psJsonEncodeCanonicalText
    (value : PsJsonValue) :
    Except PsJsonEncodeError String :=
  match psJsonEncodeCanonical value with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonConcat2 encoded "\n")
