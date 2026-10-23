import Lean

private def transform (source : String) : Except String String := do
  let object ← Lean.Json.parse source
  let text ← (← object.getObjVal? "text").getStr?
  pure ((Lean.Json.mkObj [("text",.str ("processed:" ++ text))]).compress)

def main : IO Unit := do
  let rendered ← match transform "{\"text\":\"A😀\\nZ\"}" with
    | .ok value => pure value
    | .error message => throw (IO.userError message)
  let begin := (Lean.Json.mkObj [("op",.str "readUtf8"),("path",.str "input.json")]).compress
  let next := (Lean.Json.mkObj
    [("op",.str "writeUtf8"),("path",.str "output.json"),("text",.str rendered)]).compress
  let line := (Lean.Json.mkObj [("op",.str "writeLine"),("text",.str "echo:😀")]).compress
  IO.println ("PSC1_TYPED_IO_ORACLE: " ++ (Lean.Json.mkObj [
    ("version",Lean.toJson Lean.versionString),("commit",Lean.toJson Lean.githash),
    ("begin",.str begin),("next",.str next),("finish",Lean.toJson true),("line",.str line)
  ]).compress)
