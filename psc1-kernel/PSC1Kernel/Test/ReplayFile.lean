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
    (lines : List String)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) :
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
          go shared' (some (Replay.State.empty shared' maxRecDepth maxNatSize nativeEvaluator)) totals'
            (lineNo + 1) rest
        else
          let state :=
            match current with
            | some value => value
            | none => Replay.State.empty shared maxRecDepth maxNatSize nativeEvaluator
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
    (path : String)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) :
    IO (Environment × ReplayTotals) := do
  let content ← IO.FS.readFile path
  match replaySegmentedLinesFrom
      base (content.splitOn "\n") maxRecDepth maxNatSize nativeEvaluator with
  | .ok value => pure value
  | .error err =>
      throw <| IO.userError (
        "Lean4Export replay failed for " ++ path ++ ": " ++ err)

def replayExcept
    (path : String)
    (lineNo : Nat)
    (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error err =>
      throw <| IO.userError (
        "Lean4Export replay failed for " ++ path ++
        " at line " ++ toString lineNo ++ ": " ++ err)

partial def replayFileFromStreaming
    (base : Environment)
    (path : String)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) :
    IO (Environment × ReplayTotals) :=
  IO.FS.withFile path IO.FS.Mode.read fun handle => do
    let rec go
        (shared : Environment)
        (current : Option Replay.State)
        (totals : ReplayTotals)
        (lineNo : Nat) :
        IO (Environment × ReplayTotals) := do
      let line ← handle.getLine
      if line.isEmpty then
        replayExcept path lineNo
          (finishReplaySegment shared current totals)
      else
        let trimmed := line.trim
        if trimmed.isEmpty then
          go shared current totals (lineNo + 1)
        else if isReplayContainerMarker trimmed then
          go shared current totals (lineNo + 1)
        else if isReplaySegmentMarker trimmed then
          let (shared', totals') ←
            replayExcept path lineNo
              (finishReplaySegment shared current totals)
          go shared'
            (some (Replay.State.empty shared' maxRecDepth maxNatSize nativeEvaluator))
            totals' (lineNo + 1)
        else
          let state :=
            match current with
            | some value => value
            | none => Replay.State.empty shared maxRecDepth maxNatSize nativeEvaluator
          let next ←
            replayExcept path lineNo (ReplayJson.replayLine state line)
          go shared (some next) totals (lineNo + 1)
    go base none {} 1

def printReplayTotals (path : String) (totals : ReplayTotals) : IO Unit :=
  IO.println s!"PSC1 Lean replay PASS file={path} records={totals.records} names={totals.names} levels={totals.levels} exprs={totals.expressions} declarations={totals.declarations} segments={totals.segments}"

partial def replayTargets
    (base : Environment)
    (paths : List String)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : IO Unit := do
  match paths with
  | [] => pure ()
  | path :: rest => do
      let (_, totals) ←
        replayFileFrom base path maxRecDepth maxNatSize nativeEvaluator
      printReplayTotals path totals
      replayTargets base rest maxRecDepth maxNatSize nativeEvaluator

def main (args : List String) : IO Unit := do
  match args with
  | ["--stream", path] => do
      let (_, totals) ← replayFileFromStreaming .empty path
      printReplayTotals path totals
  | [path] => do
      let (_, totals) ← replayFileFrom .empty path
      printReplayTotals path totals
  | "--base" :: basePath :: target :: rest => do
      let (baseEnv, _) ← replayFileFrom .empty basePath
      replayTargets baseEnv (target :: rest)
  | ["--native-map", mapPath, path] => do
      let provider ← PSC1Kernel.NativeMap.loadNativeMap mapPath
      let (_, totals) ←
        replayFileFrom .empty path 0 leanNatMaxSizeDefault (some provider)
      printReplayTotals path totals
  | "--native-map" :: mapPath :: "--base" :: basePath :: target :: rest => do
      let provider ← PSC1Kernel.NativeMap.loadNativeMap mapPath
      let (baseEnv, _) ←
        replayFileFrom .empty basePath 0 leanNatMaxSizeDefault (some provider)
      replayTargets
        baseEnv (target :: rest) 0 leanNatMaxSizeDefault (some provider)
  | _ =>
      throw <| IO.userError (
        "usage: ReplayFile [--stream] <lean4export.ndjson> | " ++
        "ReplayFile --base <base.ndjson> <delta.ndjson> [delta.ndjson ...] | " ++
        "ReplayFile --native-map <native.tsv> <lean4export.ndjson> | " ++
        "ReplayFile --native-map <native.tsv> --base <base.ndjson> " ++
        "<delta.ndjson> [delta.ndjson ...]")
