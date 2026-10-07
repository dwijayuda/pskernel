import PSC1Kernel.ReplayJson

namespace PsKernelCoreArenaLegacy

def normalizeMeta : PSC1Kernel.Replay.Record -> PSC1Kernel.Replay.Record
  | .metaR value =>
      .metaR {
        leanVersion := PSC1Kernel.Replay.pinnedLeanVersion
        leanGitHash := PSC1Kernel.Replay.pinnedLeanGitHash
        formatVersion := value.formatVersion
      }
  | record => record

def diagnosticReplayLineLimit : Nat := 200000

partial def replayStream
    (stream : IO.FS.Stream)
    (state : PSC1Kernel.Replay.State)
    (lineNo : Nat) : IO (Except String PSC1Kernel.Replay.Stats) := do
  if Nat.beq lineNo (Nat.succ diagnosticReplayLineLimit) then
    pure (.error ("diagnostic replay prefix complete at line " ++ toString lineNo))
  else
    let line ← stream.getLine
    if line.isEmpty then
      pure state.finish
    else if line.trimAscii.isEmpty then
      replayStream stream state (lineNo + 1)
    else
      match PSC1Kernel.ReplayJson.decodeLine line with
      | .error error =>
          pure (.error ("line " ++ toString lineNo ++ ": " ++ error))
      | .ok record =>
          match state.replay (normalizeMeta record) with
          | .error error =>
              pure (.error ("line " ++ toString lineNo ++ ": " ++ error))
          | .ok next =>
              replayStream stream next (lineNo + 1)
  
def run : IO UInt32 := do
  let stream ← IO.getStdin
  match ← replayStream stream PSC1Kernel.Replay.State.empty 1 with
  | .ok stats =>
      IO.eprintln (
        "legacy-accepted records=" ++ toString stats.records ++
        " declarations=" ++ toString stats.declarations)
      pure 0
  | .error error =>
      IO.eprintln ("legacy-diagnostic: " ++ error)
      pure 1

end PsKernelCoreArenaLegacy

def main (_args : List String) : IO UInt32 :=
  PsKernelCoreArenaLegacy.run
