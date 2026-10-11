import Ps.Host.NativeV7

open Lean (toJson)
open PsV7Native

private def run (paths : List String) (output? : Option String) : IO UInt32 := do
  let requests ← paths.toArray.mapM fun (path : String) => do
    if !path.endsWith ".ps" then
      throw (IO.userError "PSCV0-NATIVE-INPUT: expected .ps application input")
    return { source := ← IO.FS.readFile (System.FilePath.mk path), targets := if output?.isSome then [.typescript] else [] : Request }
  match ← runBatch requests with
  | .error error =>
      IO.eprintln (error.phase ++ ": " ++ error.message)
      return 1
  | .ok batch =>
      IO.println (Lean.Json.mkObj [
        ("phase", toJson ("prelude" : String)),
        ("elapsedMs", toJson batch.preludeMs)]).compress
      let mut failed := false
      for (path, result) in paths.toArray.zip batch.results do
        IO.println (resultJson path result).compress
        match result with
        | .error _ => failed := true
        | .ok value =>
            if let some output := output? then
              let some artifact := value.artifacts.head?
                | throw (IO.userError "PSCV0-NATIVE-OUTPUT-MISSING")
              if let some parent := (System.FilePath.mk output).parent then
                IO.FS.createDirAll parent
              IO.FS.writeFile output artifact.source.text
              let symbols := artifact.symbols.map fun s => Lean.Json.mkObj [
                ("semantic", toJson s.semanticName), ("output", toJson s.outputName)]
              let ranges := artifact.source.ranges.map fun r => Lean.Json.mkObj [
                ("output", toJson r.symbol), ("startByte", toJson r.startByte),
                ("endByte", toJson r.endByte)]
              IO.FS.writeFile (output ++ ".origins.json") (Lean.Json.mkObj [
                ("schema", toJson ("pscv0-origins/1" : String)),
                ("target", toJson (psEmissionTargetName artifact.target)),
                ("kernel", toJson ("official-lean4-cpp" : String)),
                ("leanCommit", toJson Lean.githash), ("profile", toJson profile),
                ("coordinates", toJson ("utf8-bytes" : String)),
                ("symbols", toJson symbols), ("ranges", toJson ranges)]).pretty
      return if failed then 1 else 0

def main (args : List String) : IO UInt32 := do
  try
    match args with
    | ["--version"] =>
        IO.println (Lean.Json.mkObj [
          ("leanVersion", toJson Lean.versionString), ("leanCommit", toJson Lean.githash),
          ("profile", toJson profile)]).compress
        return 0
    | "--check" :: first :: rest => run (first :: rest) none
    | ["--emit", input, output] =>
        if !output.endsWith ".ts" then
          throw (IO.userError "PSCV0-NATIVE-OUTPUT: expected .ts output")
        run [input] (some output)
    | _ =>
        IO.eprintln "usage: pscv0_native --check <application.ps>... | --emit <application.ps> <output.ts> | --version"
        return 2
  catch error =>
    IO.eprintln (toString error)
    return 1
