import Lean

-- Independent native JSON and String APIs; no PSC1 source or runtime imported.
def transformReference (source : String) : Except String String := do
  let records ← (← Lean.Json.parse source).getArr?
  let transformed ← records.mapM fun record => do
    let text ← (← record.getObjVal? "text").getStr?
    let count ← record.getObjVal? "count"
    match count with
    | .num _ => pure (Lean.Json.mkObj [("count",count),("text",.str ("processed:" ++ text))])
    | _ => throw "count must be a JSON number"
  pure (Lean.Json.arr transformed).compress

def main : IO Unit := do
  let source ← (← IO.getStdin).readToEnd
  match transformReference source with
  | .error message => throw (IO.userError message)
  | .ok output =>
      IO.println ("PSC1_PRACTICAL_APPLICATION_REFERENCE: " ++ (Lean.Json.mkObj [
        ("leanVersion",Lean.toJson Lean.versionString),
        ("leanCommit",Lean.toJson Lean.githash),("output",Lean.toJson output)]).compress)
