import Lean

private def stringField (object : Lean.Json) (key : String) : Except String String := do
  (← object.getObjVal? key).getStr?

private def lineReference (source : String) : Nat :=
  match Lean.Json.parse source with
  | .error _ => 0
  | .ok object =>
      match object.getObjVal? "text" with
      | .ok .null => 1
      | .ok (.str text) =>
          match text.toList with
          | char :: _ => char.toNat
          | [] => 0
      | _ => 0

private def errorReference (source : String) : Nat :=
  match Lean.Json.parse source with
  | .error _ => 2
  | .ok object =>
      match stringField object "error" with
      | .ok "capabilityDenied" => 1
      | _ => 2

private def shapeReference (source : String) : Nat :=
  match Lean.Json.parse source with
  | .error _ => 1
  | .ok object =>
      match stringField object "kind", object.getObjVal? "text" with
      | .ok "line", .ok (.str _) => 0
      | .ok "line", .ok .null => 0
      | _, _ => 1

private def requestReference (flag : Bool) : Nat :=
  let operation := if flag then "writeUtf8" else "readLine"
  let source := (Lean.Json.mkObj [("op",.str operation)]).compress
  match Lean.Json.parse source with
  | .error _ => 0
  | .ok object =>
      match stringField object "op" with
      | .ok actual => if actual == operation then 1 else 0
      | .error _ => 0

def main : IO Unit := do
  let fields := [
    ("requestCaseFalse",requestReference false),("requestCaseTrue",requestReference true),
    ("responseCaseFalse",lineReference "{\"kind\":\"line\",\"text\":\"😀\"}"),
    ("responseCaseTrue",lineReference "{\"kind\":\"line\",\"text\":null}"),
    ("errorCaseFalse",errorReference "{\"kind\":\"error\",\"error\":\"unknown\"}"),
    ("errorCaseTrue",errorReference "{\"kind\":\"error\",\"error\":\"capabilityDenied\"}"),
    ("shapeCaseFalse",shapeReference "{"),
    ("shapeCaseTrue",shapeReference "{\"kind\":\"line\",\"text\":true}")]
  IO.println ("PSC1_COMPILERM_ORACLE: " ++ (Lean.Json.mkObj
    ([("leanVersion",Lean.toJson Lean.versionString),("leanCommit",Lean.toJson Lean.githash)] ++
     fields.map (fun (name,value) => (name,Lean.toJson (toString value))))).compress)
