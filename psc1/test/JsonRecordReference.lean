import Lean

def recordReference (sources : List String) : Nat :=
  let values : Except String (List Nat) := sources.mapM fun source => do
    let object ← Lean.Json.parse source
    let text ← (← object.getObjVal? "text").getStr?
    match text.toList with
    | [] => throw "empty text"
    | char :: _ => pure char.toNat
  match values with
  | .ok codes => codes.foldl (· + ·) 0
  | .error _ => 2

-- Valid inputs use Lean's JSON parser. Malformed surrogate inputs use PSC1's
-- retained strict scalar policy: invalidUnicode (Lean permits replacement).
def main : IO Unit := do
  IO.println ("PSC1_COMPILERM_ORACLE: " ++ (Lean.Json.mkObj [
    ("leanVersion",Lean.toJson Lean.versionString),
    ("leanCommit",Lean.toJson Lean.githash),
    ("pairCaseFalse",Lean.toJson (toString (recordReference ["{\"text\":\"\\uD800\\uDC00\"}", "{\"text\":\"\\uDBFF\\uDFFF\"}"]))),
    ("pairCaseTrue",Lean.toJson (toString (recordReference ["{\"text\":\"\\uD83D\\uDE00\"}", "{\"text\":\"\\u0061\"}"]))),
    ("scalarCaseFalse",Lean.toJson (toString (recordReference ["{\"text\":\"\\uD7FF\"}", "{\"text\":\"\\uE000\"}"]))),
    ("scalarCaseTrue",Lean.toJson (toString (recordReference ["{\"text\":\"😀\"}", "{\"text\":\"a\"}"]))),
    ("loneCaseFalse",Lean.toJson (toString ((1 : Nat)))),
    ("loneCaseTrue",Lean.toJson (toString ((1 : Nat)))),
    ("badPairCaseFalse",Lean.toJson (toString ((1 : Nat)))),
    ("badPairCaseTrue",Lean.toJson (toString ((1 : Nat)))),
    ("truncatedCaseFalse",Lean.toJson (toString ((1 : Nat)))),
    ("truncatedCaseTrue",Lean.toJson (toString ((1 : Nat)))),
    ("mixedCaseFalse",Lean.toJson (toString (recordReference ["{\"text\":\"\\uDBFF\\udfff\"}"]))),
    ("scalarDecoderCaseFalse",Lean.toJson (toString (1 : Nat))),
    ("scalarDecoderCaseTrue",Lean.toJson (toString (1 : Nat))),
    ("mixedCaseTrue",Lean.toJson (toString (recordReference ["{\"text\":\"\\ud83d\\uDE00\"}"])))
  ]).compress)
