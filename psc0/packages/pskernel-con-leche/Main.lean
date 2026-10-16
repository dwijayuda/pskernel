import PsKernelConLeche
import Lean.Data.Json
import Std.Async.System

open PsKernelConLeche
open Lean (Json toJson)

private def usage : String :=
  "usage: pskernel-con-leche --identity | --ndjson FILE; no trusted mode or canonical-v2 adapter"

private def identityFields : List (String × Json) := [
  ("protocol", toJson protocol),
  ("provider", toJson provider),
  ("upstreamCommit", toJson upstreamCommit),
  ("leanVersion", toJson leanVersion),
  ("leanCommit", toJson leanCommit),
  ("profile", toJson semanticProfile),
  ("inputDialect", toJson inputDialect),
  ("mode", toJson ("verified" : String)),
  ("canAuthorizePublication", toJson false)]

private def emit (fields : List (String × Json)) : IO Unit := do
  IO.println (Json.mkObj (identityFields ++ fields)).compress

private def errorResult (phase message : String) : IO UInt32 := do
  emit [("status", toJson ("error" : String)), ("phase", toJson phase),
    ("message", toJson message)]
  pure 3

private def runFile (path : String) : IO UInt32 := do
  let limits : Limits := {}
  -- Check before and after reading. The second bound covers file growth;
  -- process-level memory/CPU limits remain the caller's responsibility.
  if (← System.FilePath.metadata path).byteSize.toNat > limits.maxInputBytes then
    return ← errorResult "resource" "input byte budget exceeded"
  let bytes ← IO.FS.readBinFile path
  match check [bytes] limits with
  | .error d =>
    emit [("status", toJson d.status), ("phase", toJson d.phase.label),
      ("message", toJson (toString d.error)), ("position", toJson d.position),
      ("positionUnit", toJson d.positionUnit)]
    pure d.exitCode
  | .ok _ =>
    -- Serialized output is diagnostic, never a reconstructible CheckedInput.
    emit [("status", toJson ("accepted" : String)),
      ("inputBytes", toJson bytes.size),
      ("scope", toJson ("independent-export-check-only" : String))]
    pure 0

private def run (args : List String) : IO UInt32 := do
  try
    -- Match the upstream CLI's fail-closed panic convention before checking.
    Std.Async.System.setEnvVar "LEAN_ABORT_ON_PANIC" "1"
    Std.Async.System.setEnvVar "LEAN_ABORT_ON_NONLINEAR" "1"
    match args with
    | ["--identity"] =>
      emit [("status", toJson ("identity" : String))]
      pure 0
    | ["--ndjson", file] => runFile file
    | _ => errorResult "request" usage
  catch e =>
    -- A host/IO exception is never an invalid-declaration verdict (exit 1).
    try
      errorResult "io" (toString e)
    catch _ => pure 3

def main (args : List String) : IO UInt32 := run args
