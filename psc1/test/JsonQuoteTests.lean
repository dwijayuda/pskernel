import Ps.Bridge.Json
import Lean.Data.Json

def quoteLegacy (value : String) : String :=
  "\"" ++ value.toList.foldr (fun char tail => psJsonEscapeChar char ++ tail) "" ++ "\""

def main : IO Unit := do
  let controls := String.ofList ((List.range 128).map Char.ofNat)
  let examples := ["", "plain", "λ🙂", "é", "\"\\\n\t", controls,
    ("prefix" ++ String.singleton (Char.ofNat 0) ++ "middle🙂" ++ String.singleton (Char.ofNat 31) ++ "suffix"), String.ofList (List.replicate 1024 'a')]
  for value in examples do
    let actual := psJsonQuote value
    unless actual == quoteLegacy value do
      throw (IO.userError "PSC1_JSON_QUOTE_LEGACY_BYTES_CHANGED")
    unless actual == "\"" ++ psJsonEscapeChars value.toList ++ "\"" do
      throw (IO.userError "PSC1_JSON_QUOTE_LIST_API_CHANGED")
    match Lean.Json.parse actual with
    | .error message => throw (IO.userError message)
    | .ok parsed =>
        unless parsed.compress == (Lean.Json.str value).compress do
          throw (IO.userError "PSC1_JSON_QUOTE_SCALAR_CHANGED")
  let required := String.ofList ([34, 92, 8, 9, 10, 12, 13].map Char.ofNat)
  unless psJsonQuote required == "\"\\\"\\\\\\b\\t\\n\\f\\r\"" do
    throw (IO.userError "PSC1_JSON_QUOTE_REQUIRED_ESCAPES")
  IO.println "PSC1_JSON_QUOTE_TESTS: exact legacy bytes, controls, Unicode and independent JSON parse passed"
