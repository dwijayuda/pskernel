import PSC1Kernel

open PSC1Kernel

private def isContainer (line : String) : Bool :=
  line.startsWith "{\"environment\":" || line.startsWith "{\"batch\":"

private def isSegment (line : String) : Bool :=
  line.startsWith "{\"segment\":"

private def padName (i : Nat) : Name :=
  .num (.str .anonymous "_psc1_pad") i

private def padInfo (i : Nat) : ConstantInfo :=
  .axiomInfo {
    base := {
      name := padName i
      levelParams := []
      type := .sort .zero
    }
    isUnsafe := false
  }

private def padEnvironment (count : Nat) : Environment :=
  let rec go (i : Nat) (env : Environment) : Environment :=
    if i < count then
      go (i + 1) (env.addUnchecked (padInfo i))
    else
      env
  go 0 .empty

private def maxBucketSize (env : Environment) : Nat :=
  env.constantIndex.foldl (fun m bucket => Nat.max m bucket.length) 0

private def nonemptyBuckets (env : Environment) : Nat :=
  env.constantIndex.foldl (fun n bucket => if bucket.isEmpty then n else n + 1) 0

private def replayLinesFrom (base : Environment) (lines : List String) : Except String Environment := do
  let rec go
      (shared : Environment)
      (current : Option Replay.State)
      (lineNo : Nat)
      (remaining : List String) : Except String Environment := do
    match remaining with
    | [] =>
        match current with
        | none => pure shared
        | some state =>
            let _ ← state.finish
            pure state.env
    | raw :: rest =>
        let trimmed := raw.trim
        if trimmed.isEmpty || isContainer trimmed then
          go shared current (lineNo + 1) rest
        else if isSegment trimmed then
          let shared' ←
            match current with
            | none => pure shared
            | some state =>
                let _ ← state.finish
                pure state.env
          go shared' (some (Replay.State.empty shared')) (lineNo + 1) rest
        else
          let state :=
            match current with
            | some value => value
            | none => Replay.State.empty shared
          let record ←
            match ReplayJson.decodeLine raw with
            | .ok value => pure value
            | .error err => throw s!"line {lineNo}: decode failed: {err}"
          let next ← state.replay record
          go shared (some next) (lineNo + 1) rest
  go base none 1 lines

private def runOne (path : String) (padding : Nat) : IO Unit := do
  let baseStart ← IO.monoMsNow
  let base := padEnvironment padding
  let baseStop ← IO.monoMsNow
  IO.println s!"ENV padding={padding} env={base.size} buckets={nonemptyBuckets base} maxBucket={maxBucketSize base} buildMs={baseStop - baseStart}"
  let content ← IO.FS.readFile path
  let start ← IO.monoMsNow
  match replayLinesFrom base (content.splitOn "\n") with
  | .error err => throw <| IO.userError s!"padding={padding}: {err}"
  | .ok env =>
      let stop ← IO.monoMsNow
      IO.println s!"REPLAY padding={padding} ms={stop - start} finalEnv={env.size} maxBucket={maxBucketSize env}"

def main (args : List String) : IO Unit := do
  match args with
  | [path] =>
      runOne path 0
      runOne path 256
      runOne path 1024
      runOne path 4096
  | _ => throw <| IO.userError "usage: ReplayEnvScaling <hot-declaration.ndjson>"
