import Lean
import TypedErrorFixtures
import TypedErrorWhileFixture

private def encode (result : Except Nat Nat) : Lean.Json :=
  match result with
  | .error value => Lean.Json.mkObj
      [("error", Lean.toJson true), ("value", Lean.toJson (toString value))]
  | .ok value => Lean.Json.mkObj
      [("error", Lean.toJson false), ("value", Lean.toJson (toString value))]

def main : IO Unit := do
  let cases : List (String × (Bool -> Except Nat Nat)) := [
    ("errorCaught", errorCaught), ("errorUncaught", errorUncaught),
    ("errorAfter", errorAfter), ("errorEarly", errorEarly),
    ("errorTerminal", errorTerminal), ("errorNested", errorNested),
    ("errorHandlerRethrow", errorHandlerRethrow), ("errorShadow", errorShadow),
    ("errorCapture", errorCapture), ("errorFor", errorFor),
    ("errorForReturn", errorForReturn), ("errorNestedDo", errorNestedDo),
    ("errorBoundThrow", errorBoundThrow), ("errorThrowShadow", errorThrowShadow),
    ("errorResultPayload", errorResultPayload), ("errorWhile", errorWhile)
  ]
  let observed := cases.flatMap fun (name, program) =>
    [(name ++ "False", encode (program false)), (name ++ "True", encode (program true))]
  IO.println (Lean.Json.mkObj (
    [("leanVersion", Lean.toJson Lean.versionString),
     ("leanCommit", Lean.toJson Lean.githash)] ++ observed)).compress
