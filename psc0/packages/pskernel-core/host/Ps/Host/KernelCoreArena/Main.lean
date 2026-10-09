import Ps.Host.KernelCoreArena.Replay

namespace PsKernelCoreArena

partial def replayStream
    (stream : IO.FS.Stream)
    (state : State)
    (lineNo : Nat) : IO (Except Failure Stats) := do
  if Nat.beq (Nat.mod lineNo 100000) 0 then
    IO.eprintln (
      "pskernel-core arena progress: records=" ++ toString state.records ++
      " declarations=" ++ toString state.declarations ++
      " names=" ++ toString state.coreTransport.names.count ++
      "/" ++ toString state.coreTransport.names.dense.size ++
      " levels=" ++ toString state.coreTransport.levels.count ++
      "/" ++ toString state.coreTransport.levels.dense.size ++
      " exprs=" ++ toString state.coreTransport.exprs.count ++
      "/" ++ toString state.coreTransport.exprs.dense.size)
  let line ← stream.getLine
  if line.isEmpty then
    pure state.finish
  else
    match state.replayLine line with
    | .error failure =>
        pure (.error (failure.withContext ("line " ++ toString lineNo ++ ": ")))
    | .ok next =>
        replayStream stream next (lineNo + 1)

/--
Host-only slow-record profiler. Production replay remains a separate executable
path, so timing instrumentation cannot change an ordinary Arena verdict.
-/
partial def replayStreamProfile
    (stream : IO.FS.Stream)
    (state : State)
    (lineNo : Nat) : IO (Except Failure Stats) := do
  if Nat.ble 330000 lineNo && Nat.beq (Nat.mod lineNo 100) 0 then
    IO.eprintln (
      "arena-profile entering record=" ++ toString lineNo ++
      " declarations=" ++ toString state.declarations)
  let line ← stream.getLine
  if line.isEmpty then
    pure state.finish
  else
    let startMs ← IO.monoMsNow
    match state.replayLine line with
    | .error failure =>
        let endMs ← IO.monoMsNow
        IO.eprintln (
          "arena-profile failed record=" ++ toString lineNo ++
          " elapsed_ms=" ++ toString (endMs - startMs))
        pure (.error (failure.withContext ("line " ++ toString lineNo ++ ": ")))
    | .ok next =>
        let endMs ← IO.monoMsNow
        let elapsed := endMs - startMs
        if Nat.ble 150 elapsed then
          IO.eprintln (
            "arena-profile slow record=" ++ toString lineNo ++
            " elapsed_ms=" ++ toString elapsed ++
            " declarations=" ++ toString next.declarations)
        replayStreamProfile stream next (lineNo + 1)

def statsLine (stats : Stats) : String :=
  "accepted" ++
    " lean=" ++ stats.leanVersion ++
    " records=" ++ toString stats.records ++
    " declarations=" ++ toString stats.declarations ++
    " constants=" ++ toString stats.constants

def runChecker
    (allowHistoricalMetadata : Bool := false)
    (profile : Bool := false) : IO UInt32 := do
  let stderr ← IO.getStderr
  match State.empty allowHistoricalMetadata with
  | .error failure =>
      stderr.putStrLn ("pskernel-core arena initialization failed: " ++ failure.message)
      pure failure.exitCode
  | .ok initial =>
      let stream ← IO.getStdin
      match ← (if profile then replayStreamProfile stream initial 1
                else replayStream stream initial 1) with
      | .ok stats =>
          stderr.putStrLn (statsLine stats)
          pure 0
      | .error failure =>
          stderr.putStrLn ("pskernel-core arena: " ++ failure.message)
          pure failure.exitCode

end PsKernelCoreArena

def main (args : List String) : IO UInt32 := do
  match args with
  | [] | ["--check"] =>
      PsKernelCoreArena.runChecker false
  | ["--check-historical"] =>
      PsKernelCoreArena.runChecker true
  | ["--profile"] =>
      PsKernelCoreArena.runChecker false true
  | ["--version"] =>
      IO.println "pskernel-core-arena/1 lean-profile=4.35.0-rc4 export=3.1.0"
      pure 0
  | _ =>
      IO.eprintln "usage: psc_kernel_core_arena [--check|--check-historical|--profile|--version] < export.ndjson"
      pure 3
