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
  let line ← stream.getLine
  if line.isEmpty then
    pure state.finish
  else if line.trimAscii.isEmpty then
    replayStreamProfile stream state (lineNo + 1)
  else
    match PSC1Kernel.ReplayJson.decodeLine line with
    | .error err => pure (.error (.rejected ("line " ++ toString lineNo ++ ": " ++ err)))
    | .ok record =>
      let label := (state.declarationLabel record).toOption.getD "unresolved"
      if label != "non-declaration" then
        IO.eprintln ("arena-profile enter record=" ++ toString lineNo ++ " " ++ label)
      let startMs ← IO.monoMsNow
      match state.replayRecord record with
      | .error failure =>
          IO.eprintln ("arena-profile failed record=" ++ toString lineNo ++ " " ++ label)
          pure (.error (failure.withContext ("line " ++ toString lineNo ++ ": ")))
      | .ok next =>
          let endMs ← IO.monoMsNow
          if Nat.ble 150 (endMs - startMs) then
            IO.eprintln ("arena-profile slow record=" ++ toString lineNo ++
              " elapsed_ms=" ++ toString (endMs - startMs) ++ " " ++ label)
          replayStreamProfile stream next (lineNo + 1)

def statsLine (stats : Stats) : String :=
  "accepted" ++
    " lean=" ++ stats.leanVersion ++
    " records=" ++ toString stats.records ++
    " declarations=" ++ toString stats.declarations ++
    " constants=" ++ toString stats.constants

def runChecker
    (allowHistoricalMetadata : Bool := false)
    (profile : Bool := false)
    (referenceMode : Bool := false) : IO UInt32 := do
  let stderr ← IO.getStderr
  if referenceMode then IO.eprintln "pskernel-core checking-mode=reference semantic-caches=disabled"
  match State.empty allowHistoricalMetadata referenceMode with
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
  | ["--profile-historical"] =>
      PsKernelCoreArena.runChecker true true
  | ["--profile"] =>
      PsKernelCoreArena.runChecker false true
  | ["--reference"] =>
      PsKernelCoreArena.runChecker false false true
  | ["--reference-historical"] =>
      PsKernelCoreArena.runChecker true false true
  | ["--version"] =>
      IO.println "pskernel-core-arena/1 lean-profile=4.35.0-rc4 export=3.1.0"
      pure 0
  | _ =>
      IO.eprintln "usage: psc_kernel_core_arena [--check|--check-historical|--profile-historical|--profile|--reference|--reference-historical|--version] < export.ndjson"
      pure 3
