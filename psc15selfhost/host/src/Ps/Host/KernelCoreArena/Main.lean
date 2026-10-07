import Ps.Host.KernelCoreArena.Replay

namespace PsKernelCoreArena

partial def replayStream
    (stream : IO.FS.Stream)
    (state : State)
    (lineNo : Nat) : IO (Except Failure Stats) := do
  let line ← stream.getLine
  if line.isEmpty then
    pure state.finish
  else
    match state.replayLine line with
    | .error failure =>
        pure (.error (failure.withContext ("line " ++ toString lineNo ++ ": ")))
    | .ok next =>
        replayStream stream next (lineNo + 1)

def statsLine (stats : Stats) : String :=
  "accepted" ++
    " lean=" ++ stats.leanVersion ++
    " records=" ++ toString stats.records ++
    " declarations=" ++ toString stats.declarations ++
    " constants=" ++ toString stats.constants

def runChecker
    (allowHistoricalMetadata : Bool := false) : IO UInt32 := do
  let stderr ← IO.getStderr
  match State.empty allowHistoricalMetadata with
  | .error failure =>
      stderr.putStrLn ("pskernel-core arena initialization failed: " ++ failure.message)
      pure failure.exitCode
  | .ok initial =>
      let stream ← IO.getStdin
      match ← replayStream stream initial 1 with
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
  | ["--version"] =>
      IO.println "pskernel-core-arena/1 lean-profile=4.34.0+4.34.1 export=3.1.0"
      pure 0
  | _ =>
      IO.eprintln "usage: psc_kernel_core_arena [--check|--check-historical|--version] < export.ndjson"
      pure 3
