import PSC1Kernel

open PSC1Kernel

structure ReplayTotals where
  records : Nat := 0
  names : Nat := 0
  levels : Nat := 0
  expressions : Nat := 0
  declarations : Nat := 0
  segments : Nat := 0

def ReplayTotals.add (totals : ReplayTotals) (stats : Replay.Stats) : ReplayTotals :=
  {
    records := totals.records + stats.records
    names := totals.names + stats.names
    levels := totals.levels + stats.levels
    expressions := totals.expressions + stats.expressions
    declarations := totals.declarations + stats.declarations
    segments := totals.segments + 1
  }

def isReplayContainerMarker (line : String) : Bool :=
  line.startsWith "{\"environment\":" ||
    line.startsWith "{\"batch\":"

def isReplaySegmentMarker (line : String) : Bool :=
  line.startsWith "{\"segment\":"

def finishReplaySegment
    (shared : Environment)
    (current : Option Replay.State)
    (totals : ReplayTotals) :
    Except String (Environment × ReplayTotals) := do
  match current with
  | none => pure (shared, totals)
  | some state =>
      let stats ← state.finish
      pure (state.env, totals.add stats)

partial def replaySegmentedLinesFrom
    (base : Environment)
    (lines : List String) :
    Except String (Environment × ReplayTotals) := do
  let rec go
      (shared : Environment)
      (current : Option Replay.State)
      (totals : ReplayTotals)
      (lineNo : Nat)
      (remaining : List String) :
      Except String (Environment × ReplayTotals) := do
    match remaining with
    | [] =>
        finishReplaySegment shared current totals
    | line :: rest =>
        let trimmed := line.trim
        if trimmed.isEmpty then
          go shared current totals (lineNo + 1) rest
        else if isReplayContainerMarker trimmed then
          go shared current totals (lineNo + 1) rest
        else if isReplaySegmentMarker trimmed then
          let (shared', totals') ←
            finishReplaySegment shared current totals
          go shared' (some (Replay.State.empty shared')) totals'
            (lineNo + 1) rest
        else
          let state :=
            match current with
            | some value => value
            | none => Replay.State.empty shared
          let next ←
            match ReplayJson.replayLine state line with
            | .ok value => pure value
            | .error err =>
                throw ("line " ++ toString lineNo ++ ": " ++ err)
          go shared (some next) totals (lineNo + 1) rest
  go base none {} 1 lines

def replaySegmentedLines
    (lines : List String) :
    Except String (Environment × ReplayTotals) :=
  replaySegmentedLinesFrom .empty lines

def replayFileFrom
    (base : Environment)
    (path : String) : IO (Environment × ReplayTotals) := do
  let content ← IO.FS.readFile path
  match replaySegmentedLinesFrom base (content.splitOn "\n") with
  | .ok value => pure value
  | .error err =>
      throw <| IO.userError (
        "Lean4Export replay failed for " ++ path ++ ": " ++ err)

def printReplayTotals (path : String) (totals : ReplayTotals) : IO Unit :=
  IO.println s!"PSC1 Lean replay PASS file={path} records={totals.records} names={totals.names} levels={totals.levels} exprs={totals.expressions} declarations={totals.declarations} segments={totals.segments}"

partial def replayTargets
    (base : Environment)
    (paths : List String) : IO Unit := do
  match paths with
  | [] => pure ()
  | path :: rest => do
      let (_, totals) ← replayFileFrom base path
      printReplayTotals path totals
      replayTargets base rest

def main (args : List String) : IO Unit := do
  match args with
  | [path] => do
      let (_, totals) ← replayFileFrom .empty path
      printReplayTotals path totals
  | "--base" :: basePath :: target :: rest => do
      let (baseEnv, _) ← replayFileFrom .empty basePath
      replayTargets baseEnv (target :: rest)
  | _ =>
      throw <| IO.userError (
        "usage: ReplayFile <lean4export.ndjson> | " ++
        "ReplayFile --base <base.ndjson> <delta.ndjson> [delta.ndjson ...]")
