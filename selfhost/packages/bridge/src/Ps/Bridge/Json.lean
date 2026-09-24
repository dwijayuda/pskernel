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
    psJsonEscapeControl value
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
