import PSC1Kernel

open PSC1Kernel

def main (args : List String) : IO Unit := do
  let path ←
    match args with
    | [path] => pure path
    | _ => throw <| IO.userError "usage: ReplayFile <lean4export.ndjson>"
  let text ← IO.FS.readFile path
  let final ←
    match ReplayJson.replayText Replay.State.empty text with
    | .ok state => pure state
    | .error err => throw <| IO.userError ("Lean4Export replay failed: " ++ err)
  let stats ←
    match final.finish with
    | .ok value => pure value
    | .error err => throw <| IO.userError ("Lean4Export replay finish failed: " ++ err)
  IO.println s!"PSC1 Lean replay PASS records={stats.records} names={stats.names} levels={stats.levels} exprs={stats.expressions} declarations={stats.declarations}"
